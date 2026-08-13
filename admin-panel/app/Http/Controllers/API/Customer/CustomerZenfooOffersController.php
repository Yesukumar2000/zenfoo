<?php

namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\ZenfooOffer;
use App\Models\Order;
use App\Models\CustomerClaimedOffer;
use Illuminate\Http\Request;
use Carbon\Carbon;

class CustomerZenfooOffersController extends Controller
{
    /**
     * Get all valid offers for customers
     * Valid means: start_date <= now() <= end_date and status = 1
     */
    public function getOffers()
    {
        $today = now()->format('Y-m-d');

        $offers = ZenfooOffer::where('status', 1)
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('id', 'DESC')
            ->get();

        return CommonHelper::responseWithData($offers);
    }

    /**
     * Get customer's offer progress for a specific offer
     * Check completed orders within offer period
     */
    public function getOfferProgress(Request $request)
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $offer_id = $request->offer_id;

        if (!$offer_id) {
            return CommonHelper::responseError("Offer ID is required");
        }

        $offer = ZenfooOffer::find($offer_id);

        if (!$offer) {
            return CommonHelper::responseError("Offer not found");
        }

        $user_id = $auth_user->id;

        // Get completed orders (active_status == 6) for this user
        $orders = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->get();

        $orders_completed = $this->countOrdersInOfferPeriod($orders, $offer);

        $total_orders = $offer->order_count;
        $remaining_orders = max(0, $total_orders - $orders_completed);
        $is_completed = $orders_completed >= $total_orders;

        // Generate status message
        if ($is_completed) {
            $status_message = "Completed! You have unlocked ₹" . number_format($offer->amount, 2) . " reward.";
        } else {
            $status_message = "Complete " . $remaining_orders . " more order" . ($remaining_orders > 1 ? "s" : "") . " to unlock ₹" . number_format($offer->amount, 2) . " reward.";
        }

        $response = [
            'offer_id' => $offer->id,
            'title' => $offer->title,
            'description' => $offer->description,
            'img_url' => $offer->img_url,
            'orders_completed' => $orders_completed,
            'total_orders' => $total_orders,
            'remaining_orders' => $remaining_orders,
            'amount' => $offer->amount,
            'start_date' => $offer->start_date,
            'end_date' => $offer->end_date,
            'is_completed' => $is_completed,
            'status_message' => $status_message,
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Get all valid offers with customer progress (merged API)
     * Returns all valid offers along with customer's progress for each
     */
    public function getOffersWithProgress()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $today = now()->format('Y-m-d');

        $offers = ZenfooOffer::where('status', 1)
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('id', 'DESC')
            ->get();

        $user_id = $auth_user->id;

        // Get all completed orders (active_status == 6) for this user
        $completedOrders = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->get();

        $result = [];

        foreach ($offers as $offer) {
            $orders_completed = $this->countOrdersInOfferPeriod($completedOrders, $offer);

            $total_orders = $offer->order_count;
            $remaining_orders = max(0, $total_orders - $orders_completed);
            $is_completed = $orders_completed >= $total_orders;

            // Generate status message
            if ($is_completed) {
                $status_message = "Completed! You have unlocked ₹" . number_format($offer->amount, 2) . " reward.";
            } else {
                $status_message = "Complete " . $remaining_orders . " more order" . ($remaining_orders > 1 ? "s" : "") . " to unlock ₹" . number_format($offer->amount, 2) . " reward.";
            }

            $result[] = [
                'offer_id' => $offer->id,
                'title' => $offer->title,
                'description' => $offer->description,
                'img_url' => $offer->img_url,
                'orders_completed' => $orders_completed,
                'total_orders' => $total_orders,
                'remaining_orders' => $remaining_orders,
                'amount' => $offer->amount,
                'start_date' => $offer->start_date,
                'end_date' => $offer->end_date,
                'is_completed' => $is_completed,
                'status_message' => $status_message,
            ];
        }

        return CommonHelper::responseWithData($result);
    }

    /**
     * Claim an offer - store the claimed offer data
     */
    public function claimOffer(Request $request)
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        // dd($auth_user);

        $offer_id = $request->offer_id;

        if (!$offer_id) {
            return CommonHelper::responseError("Offer ID is required");
        }

        $offer = ZenfooOffer::find($offer_id);

        if (!$offer) {
            return CommonHelper::responseError("Offer not found");
        }

        $user_id = $auth_user->id;

        // Check if already claimed this offer
        $alreadyClaimed = CustomerClaimedOffer::where('customer_id', $user_id)
            ->whereJsonContains('offer_meta_data->offer_id', $offer->id)
            ->first();

        if ($alreadyClaimed) {
            return CommonHelper::responseError("You have already claimed this offer");
        }

        // Verify the customer has completed the required orders
        $orders = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->get();

        $orders_completed = $this->countOrdersInOfferPeriod($orders, $offer);

        if ($orders_completed < $offer->order_count) {
            return CommonHelper::responseError("You have not completed enough orders to claim this offer");
        }

        // Store the claimed offer
        $claimedOffer = new CustomerClaimedOffer();
        $claimedOffer->customer_id = $user_id;
        $claimedOffer->offer_meta_data = [
            'offer_id' => $offer->id,
            'title' => $offer->title,
            'description' => $offer->description,
            'img_url' => $offer->img_url,
            'order_count' => $offer->order_count,
            'start_date' => $offer->start_date,
            'end_date' => $offer->end_date,
        ];
        $claimedOffer->date = now()->format('Y-m-d');
        $claimedOffer->offer_amount = $offer->amount;
        $claimedOffer->save();

        return CommonHelper::responseSuccess("Offer claimed successfully!");
    }

    /**
     * Claim all eligible offers - loops through all valid offers and claims any that are eligible
     * Returns detailed status for each offer
     */
    public function claimAllOffers(Request $request)
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;
        $today = now()->format('Y-m-d');

        // Get all valid offers
        $offers = ZenfooOffer::where('status', 1)
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('id', 'DESC')
            ->get();

        // Get all completed orders for this user
        $completedOrders = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->get();

        // Get all already claimed offer IDs for this user
        $claimedOfferIds = CustomerClaimedOffer::where('customer_id', $user_id)
            ->get()
            ->pluck('offer_meta_data')
            ->map(function ($meta) {
                return $meta['offer_id'] ?? null;
            })
            ->filter()
            ->toArray();

        $already_claimed = [];
        $not_yet_completed = [];
        $newly_claimed = [];

        foreach ($offers as $offer) {
            // Check if already claimed
            if (in_array($offer->id, $claimedOfferIds)) {
                $already_claimed[] = [
                    'offer_id' => $offer->id,
                    'title' => $offer->title,
                    'amount' => $offer->amount,
                    'status_message' => "Already claimed"
                ];
                continue;
            }

            // Count orders in offer period
            $orders_completed = $this->countOrdersInOfferPeriod($completedOrders, $offer);
            $total_orders = $offer->order_count;
            $remaining_orders = max(0, $total_orders - $orders_completed);

            // Check if eligible to claim
            if ($orders_completed >= $total_orders) {
                // Claim this offer
                $claimedOffer = new CustomerClaimedOffer();
                $claimedOffer->customer_id = $user_id;
                $claimedOffer->offer_meta_data = [
                    'offer_id' => $offer->id,
                    'title' => $offer->title,
                    'description' => $offer->description,
                    'img_url' => $offer->img_url,
                    'order_count' => $offer->order_count,
                    'start_date' => $offer->start_date,
                    'end_date' => $offer->end_date,
                ];
                $claimedOffer->date = now()->format('Y-m-d');
                $claimedOffer->offer_amount = $offer->amount;
                $claimedOffer->save();

                // Credit offer amount to customer wallet
                CommonHelper::addUserWalletBalance($offer->amount, $user_id);
                CommonHelper::addWalletTransaction(null, null, $user_id, 'credit', $offer->amount, 'Zenfoo Offer Claimed: ' . $offer->title);

                $newly_claimed[] = [
                    'offer_id' => $offer->id,
                    'title' => $offer->title,
                    'amount' => $offer->amount,
                    'status_message' => "Successfully claimed ₹" . number_format($offer->amount, 2) . " reward! Amount credited to wallet."
                ];
            } else {
                // Not yet completed
                $not_yet_completed[] = [
                    'offer_id' => $offer->id,
                    'title' => $offer->title,
                    'amount' => $offer->amount,
                    'orders_completed' => $orders_completed,
                    'total_orders' => $total_orders,
                    'remaining_orders' => $remaining_orders,
                    'status_message' => "Complete " . $remaining_orders . " more order" . ($remaining_orders > 1 ? "s" : "") . " to unlock ₹" . number_format($offer->amount, 2) . " reward"
                ];
            }
        }

        // Calculate total amount credited to wallet
        $total_credited = array_sum(array_column($newly_claimed, 'amount'));

        $response = [
            'already_claimed' => $already_claimed,
            'not_yet_completed' => $not_yet_completed,
            'newly_claimed' => $newly_claimed,
            'summary' => [
                'total_offers' => count($offers),
                'already_claimed_count' => count($already_claimed),
                'not_yet_completed_count' => count($not_yet_completed),
                'newly_claimed_count' => count($newly_claimed),
                'total_amount_credited' => $total_credited,
            ]
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Get all claimed offers for the authenticated customer
     */
    public function getClaimedOffers()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        $claimedOffers = CustomerClaimedOffer::where('customer_id', $user_id)
            ->orderBy('id', 'DESC')
            ->get();

        $total_amount = $claimedOffers->sum('offer_amount');

        $response = [
            'claimed_offers' => $claimedOffers,
            'total_claimed_amount' => $total_amount,
            'total_claimed_count' => count($claimedOffers),
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Get all offers data for customer - combines offers with progress and claimed offers
     * Returns: active offers with progress, claimed offers history, and summary
     */
    public function getAllOffersData()
    {
        $auth_user = auth()->guard('api-customers')->user();

        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;
        $today = now()->format('Y-m-d');

        // Get all valid offers
        $offers = ZenfooOffer::where('status', 1)
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('id', 'DESC')
            ->get();

        // Get all completed orders (active_status == 6) for this user
        $completedOrders = Order::where('user_id', $user_id)
            ->where('active_status', 6)
            ->get();

        // Get all already claimed offer IDs for this user
        $claimedOfferIds = CustomerClaimedOffer::where('customer_id', $user_id)
            ->get()
            ->pluck('offer_meta_data')
            ->map(function ($meta) {
                return $meta['offer_id'] ?? null;
            })
            ->filter()
            ->toArray();

        // Build offers with progress
        $offersWithProgress = [];
        foreach ($offers as $offer) {
            $orders_completed = $this->countOrdersInOfferPeriod($completedOrders, $offer);
            $total_orders = $offer->order_count;
            $remaining_orders = max(0, $total_orders - $orders_completed);
            $is_completed = $orders_completed >= $total_orders;
            $is_claimed = in_array($offer->id, $claimedOfferIds);

            // Generate status message
            if ($is_claimed) {
                $status_message = "Claimed! ₹" . number_format($offer->amount, 2) . " reward credited to wallet.";
            } elseif ($is_completed) {
                $status_message = "Completed! Claim your ₹" . number_format($offer->amount, 2) . " reward now.";
            } else {
                $status_message = "Complete " . $remaining_orders . " more order" . ($remaining_orders > 1 ? "s" : "") . " to unlock ₹" . number_format($offer->amount, 2) . " reward.";
            }

            $offersWithProgress[] = [
                'offer_id' => $offer->id,
                'title' => $offer->title,
                'description' => $offer->description,
                'img_url' => $offer->img_url,
                'orders_completed' => $orders_completed,
                'total_orders' => $total_orders,
                'remaining_orders' => $remaining_orders,
                'amount' => $offer->amount,
                'start_date' => $offer->start_date,
                'end_date' => $offer->end_date,
                'is_completed' => $is_completed,
                'is_claimed' => $is_claimed,
                'status_message' => $status_message,
            ];
        }

        // Get claimed offers history
        $claimedOffers = CustomerClaimedOffer::where('customer_id', $user_id)
            ->orderBy('id', 'DESC')
            ->get();

        $total_claimed_amount = $claimedOffers->sum('offer_amount');

        $response = [
            'active_offers' => $offersWithProgress,
            'claimed_offers' => $claimedOffers,
            'summary' => [
                'total_active_offers' => count($offersWithProgress),
                'total_claimed_offers' => count($claimedOffers),
                'total_claimed_amount' => $total_claimed_amount,
            ]
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Count orders completed within offer period
     */
    private function countOrdersInOfferPeriod($orders, $offer)
    {
        $orders_completed = 0;

        foreach ($orders as $order) {
            // Parse the status column to get the delivery date
            // Format: [[6,"18-12-2025 06:02:00am"]]
            $status = $order->status;

            if ($status) {
                $statusArray = json_decode($status, true);

                if (is_array($statusArray)) {
                    foreach ($statusArray as $statusItem) {
                        // Check if status is 6 (delivered)
                        if (isset($statusItem[0]) && $statusItem[0] == 6 && isset($statusItem[1])) {
                            // Parse the date from status
                            $deliveryDateStr = $statusItem[1];

                            try {
                                // Parse date format "18-12-2025 06:02:00am"
                                $deliveryDate = Carbon::createFromFormat('d-m-Y h:i:sa', $deliveryDateStr);

                                // Check if delivery date is within offer period
                                $offerStart = Carbon::parse($offer->start_date)->startOfDay();
                                $offerEnd = Carbon::parse($offer->end_date)->endOfDay();

                                if ($deliveryDate->between($offerStart, $offerEnd)) {
                                    $orders_completed++;
                                }
                            } catch (\Exception $e) {
                                // Try alternative date format if first one fails
                                try {
                                    $deliveryDate = Carbon::parse($deliveryDateStr);

                                    $offerStart = Carbon::parse($offer->start_date)->startOfDay();
                                    $offerEnd = Carbon::parse($offer->end_date)->endOfDay();

                                    if ($deliveryDate->between($offerStart, $offerEnd)) {
                                        $orders_completed++;
                                    }
                                } catch (\Exception $e) {
                                    // Skip if date parsing fails
                                    continue;
                                }
                            }
                        }
                    }
                }
            }
        }

        return $orders_completed;
    }
}
