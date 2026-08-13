<?php

namespace App\Services;

use App\Helpers\CommonHelper;
use App\Models\UserOrderReward;
use App\Models\CustomerClaimedMilestone;
use App\Models\Order;
use App\Models\User;
use App\Models\WalletTransaction;

class UserOfferClaimService
{
    /**
     * Claim all eligible milestones for a customer after order completion
     *
     * @param int $order_id The order ID that triggered this claim
     * @param int $customer_id The customer ID
     * @return array Result with claimed milestones info
     */
    public static function claimWithOrder($order_id, $customer_id)
    {
        // Verify the order belongs to this customer and is completed
        $order = Order::where('id', $order_id)
            ->where('user_id', $customer_id)
            // ->where('active_status', 6)
            ->first();

        if (!$order) {
            return [
                'success' => false,
                'message' => 'Order not found',
                'data' => null,
            ];
        }

        // Get completed orders count
        $completedOrdersCount = Order::where('user_id', $customer_id)
            ->where('active_status', 6)
            ->count();

        // Get all milestones
        $allMilestones = UserOrderReward::where('status', 1)
            ->orderBy('order_count', 'ASC')
            ->get();

        // Get already claimed milestone IDs
        $claimedMilestoneIds = CustomerClaimedMilestone::where('customer_id', $customer_id)
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
                $claimedMilestone->customer_id = $customer_id;
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

                // Pay the reward into the wallet. Previously the row was written
                // as claimed AND used against the order that merely triggered it,
                // while no money ever moved -- no wallet credit and no discount on
                // that order -- so the customer saw "Claimed" and received nothing.
                self::creditMilestoneToWallet($customer_id, $milestone, $order_id);

                $claimed[] = [
                    'milestone_id' => $milestone->id,
                    'order_count' => $milestone->order_count,
                    'amount' => $milestone->amount,
                ];

                $totalClaimedAmount += $milestone->amount;
            }
        }

        if (count($claimed) === 0) {
            return [
                'success' => true,
                'message' => 'No new milestones to claim',
                'data' => [
                    'claimed_count' => 0,
                    'claimed_milestones' => [],
                    'total_claimed_amount' => 0,
                ],
            ];
        }

        return [
            'success' => true,
            'message' => 'Successfully claimed ' . count($claimed) . ' milestone(s) worth ₹' . number_format($totalClaimedAmount, 2),
            'data' => [
                'claimed_count' => count($claimed),
                'claimed_milestones' => $claimed,
                'total_claimed_amount' => $totalClaimedAmount,
            ],
        ];
    }

    /**
     * Wallet message for a loyalty milestone. Also the idempotency key — the
     * order_count is unique per milestone, and a milestone is claimable once
     * per customer, so user + message identifies the payout exactly.
     */
    public static function milestoneWalletMessage($orderCount): string
    {
        return 'Loyalty Reward - ' . $orderCount . ' Orders';
    }

    /**
     * Credit a claimed milestone into the customer's wallet, mirroring how the
     * referral bonus pays out. Returns false when it was already credited.
     */
    public static function creditMilestoneToWallet($customer_id, $milestone, $order_id = 0): bool
    {
        $message = self::milestoneWalletMessage($milestone->order_count);

        $alreadyCredited = WalletTransaction::where('user_id', $customer_id)
            ->where('message', $message)
            ->exists();
        if ($alreadyCredited) {
            return false;
        }

        $user = User::find($customer_id);
        if (!$user) {
            return false;
        }

        $amount = (float) $milestone->amount;
        if ($amount <= 0) {
            return false;
        }

        CommonHelper::updateUserWalletBalance((float) $user->balance + $amount, $user->id);
        CommonHelper::addWalletTransaction($order_id ?: 0, 0, $user->id, 'credit', $amount, $message);

        return true;
    }
}
