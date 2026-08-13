<?php

namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\UserOrderReward;
use App\Models\UserOfferBanner;
use App\Models\CustomerClaimedMilestone;
use App\Models\Order;
use App\Models\Setting;
use Illuminate\Http\Request;

class CustomerUserOffersController extends Controller
{
    /**
     * Simple GET API - Get customer's completed order count, milestones, and claimable rewards
     */
    public function getMilestonesSimple()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        // Get completed orders count
        $completedOrdersCount = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->count();

        // Get all milestones
        $allMilestones = UserOrderReward::where('status', 1)
            ->orderBy('order_count', 'ASC')
            ->get();

        // Get already claimed milestone IDs
        $claimedMilestoneIds = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->pluck('milestone_id')
            ->toArray();

        // Build milestones with claim status
        $milestones = [];
        $claimable = [];
        $totalClaimableAmount = 0;

        foreach ($allMilestones as $milestone) {
            $isClaimed = in_array($milestone->id, $claimedMilestoneIds);
            $isEligible = $completedOrdersCount >= $milestone->order_count;
            $canClaim = $isEligible && !$isClaimed;

            $milestoneData = [
                'id' => $milestone->id,
                'order_count' => $milestone->order_count,
                'amount' => $milestone->amount,
                'is_eligible' => $isEligible,
                'is_claimed' => $isClaimed,
                'can_claim' => $canClaim,
            ];

            $milestones[] = $milestoneData;

            if ($canClaim) {
                $claimable[] = $milestoneData;
                $totalClaimableAmount += $milestone->amount;
            }
        }

        // Get active banners
        $banners = UserOfferBanner::where('status', 1)
            ->orderBy('sort_order', 'ASC')
            ->get();

        // Get claimed milestones for this customer
        $claimedMilestones = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->orderBy('id', 'DESC')
            ->get();

        // Get the last (biggest) milestone
        $lastMilestone = $allMilestones->last();
        $lastMilestoneData = null;
        if ($lastMilestone) {
            $isClaimed = in_array($lastMilestone->id, $claimedMilestoneIds);
            $isEligible = $completedOrdersCount >= $lastMilestone->order_count;
            $lastMilestoneData = [
                'id' => $lastMilestone->id,
                'order_count' => $lastMilestone->order_count,
                'amount' => $lastMilestone->amount,
                'is_eligible' => $isEligible,
                'is_claimed' => $isClaimed,
                'can_claim' => $isEligible && !$isClaimed,
            ];
        }

        // Get claimable banner from settings
        $claimableBanner = Setting::get_value('offer_claimable_banner');

        $response = [
            'completed_orders_count' => $completedOrdersCount,
            'last_milestone' => $lastMilestoneData,
            'milestones' => $milestones,
            // 'can_claim_reward' => count($claimable) > 0,
            // 'claimable_milestones' => $claimable,
            // 'total_claimable_amount' => $totalClaimableAmount,
            'banners' => $banners,
            'claimable_banner' => $claimableBanner,
            'claimed_milestones' => $claimedMilestones,
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * POST API - Claim milestones after order completion
     * Takes order_id and claims all eligible milestones for the customer
     */
    public function claimWithOrder(Request $request)
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $order_id = $request->order_id;

        if (!$order_id) {
            return CommonHelper::responseError("Order ID is required");
        }

        // Verify the order belongs to this customer and is completed
        $order = Order::where('id', $order_id)
            ->where('user_id', $auth_user->id)
            ->where('active_status', 6)
            ->first();

        if (!$order) {
            return CommonHelper::responseError("Order not found or not completed");
        }

        $user_id = $auth_user->id;

        // Get completed orders count
        $completedOrdersCount = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->count();

        // Get all milestones
        $allMilestones = UserOrderReward::where('status', 1)
            ->orderBy('order_count', 'ASC')
            ->get();

        // Get already claimed milestone IDs
        $claimedMilestoneIds = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->pluck('milestone_id')
            ->toArray();

        $claimed = [];
        $totalClaimedAmount = 0;

        foreach ($allMilestones as $milestone) {
            $isClaimed = in_array($milestone->id, $claimedMilestoneIds);
            $isEligible = $completedOrdersCount >= $milestone->order_count;

            // If eligible and not already claimed, claim it
            if ($isEligible && !$isClaimed) {
                $claimedMilestone = new CustomerClaimedMilestone();
                $claimedMilestone->customer_id = $user_id;
                $claimedMilestone->milestone_id = $milestone->id;
                $claimedMilestone->milestone_meta_data = [
                    'milestone_id' => $milestone->id,
                    'order_count' => $milestone->order_count,
                    'amount' => $milestone->amount,
                    'claimed_at_orders_count' => $completedOrdersCount,
                    'triggered_by_order_id' => $order_id,
                ];
                $claimedMilestone->claimed_date = now()->format('Y-m-d');
                $claimedMilestone->reward_amount = $milestone->amount;
                $claimedMilestone->status = 'claimed';
                $claimedMilestone->used_date = now()->format('Y-m-d');
                $claimedMilestone->used_in_order_id = $order_id;
                
                $claimedMilestone->save();

                $claimed[] = [
                    'milestone_id' => $milestone->id,
                    'order_count' => $milestone->order_count,
                    'amount' => $milestone->amount,
                ];

                $totalClaimedAmount += $milestone->amount;
            }
        }

        if (count($claimed) === 0) {
            return CommonHelper::responseWithData([
                'claimed_count' => 0,
                'claimed_milestones' => [],
                'total_claimed_amount' => 0,
                'message' => 'No new milestones to claim',
            ]);
        }

        $response = [
            'claimed_count' => count($claimed),
            'claimed_milestones' => $claimed,
            'total_claimed_amount' => $totalClaimedAmount,
            'message' => 'Successfully claimed ' . count($claimed) . ' milestone(s) worth ₹' . number_format($totalClaimedAmount, 2),
        ];

        return CommonHelper::responseWithData($response);
    }

    public function getOrderMilestones()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        // Get all completed orders (active_status == 6) for this user
        $completedOrdersCount = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->count();

        // Get all active order rewards sorted by order_count
        $rewards = UserOrderReward::where('status', 1)
            ->orderBy('order_count', 'ASC')
            ->get();

        // Get already claimed milestone IDs for this user
        $claimedMilestones = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->get();

        $claimedMilestoneIds = $claimedMilestones->pluck('milestone_id')->toArray();

        $milestones = [];
        $completed_milestones = [];
        $pending_milestones = [];
        $claimable_milestones = [];
        $next_milestone = null;

        foreach ($rewards as $reward) {
            $is_completed = $completedOrdersCount >= $reward->order_count;
            $is_claimed = in_array($reward->id, $claimedMilestoneIds);
            $orders_remaining = max(0, $reward->order_count - $completedOrdersCount);

            // Get claim details if claimed
            $claim_details = null;
            if ($is_claimed) {
                $claim = $claimedMilestones->where('milestone_id', $reward->id)->first();
                if ($claim) {
                    $claim_details = [
                        'claim_id' => $claim->id,
                        'claimed_date' => $claim->claimed_date,
                        'status' => $claim->status,
                        'used_in_order_id' => $claim->used_in_order_id,
                        'used_date' => $claim->used_date,
                    ];
                }
            }

            $milestone = [
                'id' => $reward->id,
                'order_count' => $reward->order_count,
                'amount' => $reward->amount,
                'is_completed' => $is_completed,
                'is_claimed' => $is_claimed,
                'is_used' => $claim_details ? ($claim_details['status'] === 'used') : false,
                'orders_remaining' => $orders_remaining,
                'claim_details' => $claim_details,
            ];

            if ($is_claimed) {
                if ($claim_details && $claim_details['status'] === 'used') {
                    $milestone['status_message'] = "Used! ₹" . number_format($reward->amount, 2) . " reward was applied to order.";
                } else {
                    $milestone['status_message'] = "Claimed! ₹" . number_format($reward->amount, 2) . " reward available to use.";
                }
                $completed_milestones[] = $milestone;
            } elseif ($is_completed) {
                $milestone['status_message'] = "Completed! Claim your ₹" . number_format($reward->amount, 2) . " reward now.";
                $completed_milestones[] = $milestone;
                $claimable_milestones[] = $milestone;
            } else {
                $milestone['status_message'] = "Complete " . $orders_remaining . " more order" . ($orders_remaining > 1 ? "s" : "") . " to unlock ₹" . number_format($reward->amount, 2) . " reward.";
                $pending_milestones[] = $milestone;

                // Set next milestone (first pending one)
                if ($next_milestone === null) {
                    $next_milestone = $milestone;
                }
            }

            $milestones[] = $milestone;
        }

        // Calculate totals
        $total_rewards_earned = 0;
        $total_rewards_claimed = 0;
        $total_rewards_used = 0;
        $total_rewards_available = 0;

        foreach ($claimedMilestones as $cm) {
            $total_rewards_claimed += $cm->reward_amount;
            if ($cm->status === 'used') {
                $total_rewards_used += $cm->reward_amount;
            } else {
                $total_rewards_available += $cm->reward_amount;
            }
        }

        foreach ($completed_milestones as $cm) {
            $total_rewards_earned += $cm['amount'];
        }

        $response = [
            'customer_orders_count' => $completedOrdersCount,
            'milestones' => $milestones,
            'completed_milestones' => $completed_milestones,
            'pending_milestones' => $pending_milestones,
            'claimable_milestones' => $claimable_milestones,
            'next_milestone' => $next_milestone,
            'summary' => [
                'total_milestones' => count($milestones),
                'completed_count' => count($completed_milestones),
                'pending_count' => count($pending_milestones),
                'claimable_count' => count($claimable_milestones),
                'total_rewards_earned' => $total_rewards_earned,
                'total_rewards_claimed' => $total_rewards_claimed,
                'total_rewards_used' => $total_rewards_used,
                'total_rewards_available' => $total_rewards_available,
            ]
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Claim a milestone reward
     */
    public function claimMilestone(Request $request)
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $milestone_id = $request->milestone_id;

        if (!$milestone_id) {
            return CommonHelper::responseError("Milestone ID is required");
        }

        $milestone = UserOrderReward::find($milestone_id);

        if (!$milestone) {
            return CommonHelper::responseError("Milestone not found");
        }

        $user_id = $auth_user->id;

        // Check if already claimed this milestone
        $alreadyClaimed = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->where('milestone_id', $milestone->id)
            ->first();

        if ($alreadyClaimed) {
            return CommonHelper::responseError("You have already claimed this milestone reward");
        }

        // Get completed orders for this user
        $completedOrders = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->orderBy('id', 'ASC')
            ->get();

        $completedOrdersCount = $completedOrders->count();

        if ($completedOrdersCount < $milestone->order_count) {
            return CommonHelper::responseError("You have not completed enough orders to claim this milestone");
        }

        // Get the orders that contributed to this milestone
        $contributingOrders = $completedOrders->take($milestone->order_count);
        $orderIds = $contributingOrders->pluck('id')->toArray();
        $orderDetails = $contributingOrders->map(function ($order) {
            return [
                'order_id' => $order->id,
                'order_number' => $order->order_number ?? $order->id,
                'total' => $order->total,
                'created_at' => $order->created_at,
            ];
        })->toArray();

        // Store the claimed milestone
        $claimedMilestone = new CustomerClaimedMilestone();
        $claimedMilestone->customer_id = $user_id;
        $claimedMilestone->milestone_id = $milestone->id;
        $claimedMilestone->milestone_meta_data = [
            'milestone_id' => $milestone->id,
            'order_count' => $milestone->order_count,
            'amount' => $milestone->amount,
            'claimed_at_orders_count' => $completedOrdersCount,
            'contributing_order_ids' => $orderIds,
            'contributing_orders' => $orderDetails,
        ];
        $claimedMilestone->claimed_date = now()->format('Y-m-d');
        $claimedMilestone->reward_amount = $milestone->amount;
        $claimedMilestone->status = 'claimed';
        $claimedMilestone->save();

        return CommonHelper::responseSuccess("Milestone reward of ₹" . number_format($milestone->amount, 2) . " claimed successfully!");
    }

    /**
     * Claim all eligible milestones
     */
    public function claimAllMilestones()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        // Get completed orders for this user
        $completedOrders = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->orderBy('id', 'ASC')
            ->get();

        $completedOrdersCount = $completedOrders->count();

        // Get all active milestones
        $milestones = UserOrderReward::where('status', 1)
            ->orderBy('order_count', 'ASC')
            ->get();

        // Get already claimed milestone IDs
        $claimedMilestoneIds = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->pluck('milestone_id')
            ->toArray();

        $newly_claimed = [];
        $already_claimed = [];
        $not_eligible = [];

        foreach ($milestones as $milestone) {
            // Check if already claimed
            if (in_array($milestone->id, $claimedMilestoneIds)) {
                $already_claimed[] = [
                    'milestone_id' => $milestone->id,
                    'order_count' => $milestone->order_count,
                    'amount' => $milestone->amount,
                    'status_message' => "Already claimed"
                ];
                continue;
            }

            // Check if eligible
            if ($completedOrdersCount >= $milestone->order_count) {
                // Get the orders that contributed to this milestone
                $contributingOrders = $completedOrders->take($milestone->order_count);
                $orderIds = $contributingOrders->pluck('id')->toArray();
                $orderDetails = $contributingOrders->map(function ($order) {
                    return [
                        'order_id' => $order->id,
                        'order_number' => $order->order_number ?? $order->id,
                        'total' => $order->total,
                        'created_at' => $order->created_at,
                    ];
                })->toArray();

                // Claim this milestone
                $claimedMilestone = new CustomerClaimedMilestone();
                $claimedMilestone->customer_id = $user_id;
                $claimedMilestone->milestone_id = $milestone->id;
                $claimedMilestone->milestone_meta_data = [
                    'milestone_id' => $milestone->id,
                    'order_count' => $milestone->order_count,
                    'amount' => $milestone->amount,
                    'claimed_at_orders_count' => $completedOrdersCount,
                    'contributing_order_ids' => $orderIds,
                    'contributing_orders' => $orderDetails,
                ];
                $claimedMilestone->claimed_date = now()->format('Y-m-d');
                $claimedMilestone->reward_amount = $milestone->amount;
                $claimedMilestone->status = 'claimed';
                $claimedMilestone->save();

                $newly_claimed[] = [
                    'milestone_id' => $milestone->id,
                    'order_count' => $milestone->order_count,
                    'amount' => $milestone->amount,
                    'contributing_order_ids' => $orderIds,
                    'status_message' => "Successfully claimed ₹" . number_format($milestone->amount, 2) . " reward!"
                ];
            } else {
                $orders_remaining = $milestone->order_count - $completedOrdersCount;
                $not_eligible[] = [
                    'milestone_id' => $milestone->id,
                    'order_count' => $milestone->order_count,
                    'amount' => $milestone->amount,
                    'orders_remaining' => $orders_remaining,
                    'status_message' => "Complete " . $orders_remaining . " more order" . ($orders_remaining > 1 ? "s" : "") . " to unlock"
                ];
            }
        }

        $total_claimed_amount = array_sum(array_column($newly_claimed, 'amount'));

        $response = [
            'newly_claimed' => $newly_claimed,
            'already_claimed' => $already_claimed,
            'not_eligible' => $not_eligible,
            'summary' => [
                'newly_claimed_count' => count($newly_claimed),
                'already_claimed_count' => count($already_claimed),
                'not_eligible_count' => count($not_eligible),
                'total_claimed_amount' => $total_claimed_amount,
            ]
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Get claimed milestones history
     */
    public function getClaimedMilestones()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        $claimedMilestones = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->orderBy('id', 'DESC')
            ->get();

        $total_claimed = $claimedMilestones->sum('reward_amount');
        $total_used = $claimedMilestones->where('status', 'used')->sum('reward_amount');
        $total_available = $claimedMilestones->where('status', 'claimed')->sum('reward_amount');

        $response = [
            'claimed_milestones' => $claimedMilestones,
            // 'summary' => [
            //     'total_claimed_count' => count($claimedMilestones),
            //     'total_claimed_amount' => $total_claimed,
            //     'total_used_amount' => $total_used,
            //     'total_available_amount' => $total_available,
            // ]
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Get available (unclaimed) milestone rewards for use in order
     */
    public function getAvailableRewards()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        $availableRewards = CustomerClaimedMilestone::where('customer_id', $user_id)
            ->where('status', 'claimed')
            ->orderBy('reward_amount', 'DESC')
            ->get();

        $total_available = $availableRewards->sum('reward_amount');

        $response = [
            'available_rewards' => $availableRewards,
            'total_available_amount' => $total_available,
            'total_available_count' => count($availableRewards),
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Get offer banners for customers
     * Returns all active banners sorted by sort_order
     */
    public function getOfferBanners()
    {
        $banners = UserOfferBanner::where('status', 1)
            ->orderBy('sort_order', 'ASC')
            ->get();

        return CommonHelper::responseWithData($banners);
    }

    /**
     * Get all user offers data - combines milestones and banners
     */
    public function getAllUserOffersData()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        // Get completed orders count
        $completedOrdersCount = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->count();

        // Get all active order rewards
        $rewards = UserOrderReward::where('status', 1)
            ->orderBy('order_count', 'ASC')
            ->get();

        // Get claimed milestones
        $claimedMilestones = CustomerClaimedMilestone::where('customer_id', $user_id)->get();
        $claimedMilestoneIds = $claimedMilestones->pluck('milestone_id')->toArray();

        $milestones = [];
        $completed_milestones = [];
        $pending_milestones = [];
        $claimable_milestones = [];
        $next_milestone = null;

        foreach ($rewards as $reward) {
            $is_completed = $completedOrdersCount >= $reward->order_count;
            $is_claimed = in_array($reward->id, $claimedMilestoneIds);
            $orders_remaining = max(0, $reward->order_count - $completedOrdersCount);

            $claim_details = null;
            if ($is_claimed) {
                $claim = $claimedMilestones->where('milestone_id', $reward->id)->first();
                if ($claim) {
                    $claim_details = [
                        'claim_id' => $claim->id,
                        'claimed_date' => $claim->claimed_date,
                        'status' => $claim->status,
                        'used_in_order_id' => $claim->used_in_order_id,
                        'used_date' => $claim->used_date,
                    ];
                }
            }

            $milestone = [
                'id' => $reward->id,
                'order_count' => $reward->order_count,
                'amount' => $reward->amount,
                'is_completed' => $is_completed,
                'is_claimed' => $is_claimed,
                'is_used' => $claim_details ? ($claim_details['status'] === 'used') : false,
                'orders_remaining' => $orders_remaining,
                'claim_details' => $claim_details,
            ];

            if ($is_claimed) {
                if ($claim_details && $claim_details['status'] === 'used') {
                    $milestone['status_message'] = "Used! ₹" . number_format($reward->amount, 2) . " reward was applied.";
                } else {
                    $milestone['status_message'] = "Claimed! ₹" . number_format($reward->amount, 2) . " reward available.";
                }
                $completed_milestones[] = $milestone;
            } elseif ($is_completed) {
                $milestone['status_message'] = "Completed! Claim your ₹" . number_format($reward->amount, 2) . " reward.";
                $completed_milestones[] = $milestone;
                $claimable_milestones[] = $milestone;
            } else {
                $milestone['status_message'] = "Complete " . $orders_remaining . " more order" . ($orders_remaining > 1 ? "s" : "") . " to unlock ₹" . number_format($reward->amount, 2) . ".";
                $pending_milestones[] = $milestone;

                if ($next_milestone === null) {
                    $next_milestone = $milestone;
                }
            }

            $milestones[] = $milestone;
        }

        // Calculate totals
        $total_rewards_earned = 0;
        foreach ($completed_milestones as $cm) {
            $total_rewards_earned += $cm['amount'];
        }

        $total_rewards_claimed = $claimedMilestones->sum('reward_amount');
        $total_rewards_used = $claimedMilestones->where('status', 'used')->sum('reward_amount');
        $total_rewards_available = $claimedMilestones->where('status', 'claimed')->sum('reward_amount');

        // Get banners
        $banners = UserOfferBanner::where('status', 1)
            ->orderBy('sort_order', 'ASC')
            ->get();

        $response = [
            'customer_orders_count' => $completedOrdersCount,
            'milestones' => $milestones,
            'completed_milestones' => $completed_milestones,
            'pending_milestones' => $pending_milestones,
            'claimable_milestones' => $claimable_milestones,
            'next_milestone' => $next_milestone,
            'banners' => $banners,
            'summary' => [
                'total_milestones' => count($milestones),
                'completed_count' => count($completed_milestones),
                'pending_count' => count($pending_milestones),
                'claimable_count' => count($claimable_milestones),
                'total_rewards_earned' => $total_rewards_earned,
                'total_rewards_claimed' => $total_rewards_claimed,
                'total_rewards_used' => $total_rewards_used,
                'total_rewards_available' => $total_rewards_available,
                'total_banners' => count($banners),
            ]
        ];

        return CommonHelper::responseWithData($response);
    }
}
