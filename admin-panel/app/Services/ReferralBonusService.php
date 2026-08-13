<?php

namespace App\Services;

use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyReferralTracking;
use App\Models\DeliveryBoyTransaction;
use App\Models\Setting;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\AdminNotificationService;
use App\Services\DriverNotificationService;

class ReferralBonusService
{
    /**
     * Process referral tracking when a delivery boy completes an order
     *
     * @param DeliveryBoy $deliveryBoy
     * @param int $orderId
     * @return array
     */
    public static function processOrderCompletion(DeliveryBoy $deliveryBoy, $orderId)
    {
        try {
            // Check if this driver was referred by someone
            if (!$deliveryBoy->referred_by) {
                return [
                    'success' => true,
                    'message' => 'No referral tracking needed'
                ];
            }

            // Find the referral tracking record
            $tracking = DeliveryBoyReferralTracking::where('referred_delivery_boy_id', $deliveryBoy->id)
                ->where('is_bonus_paid', false)
                ->first();

            if (!$tracking) {
                Log::warning('Referral tracking record not found', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'referred_by' => $deliveryBoy->referred_by
                ]);
                return [
                    'success' => false,
                    'message' => 'Referral tracking record not found'
                ];
            }

            // Increment completed orders count
            $tracking->completed_orders_count += 1;
            $tracking->save();

            Log::info('Referral tracking updated', [
                'tracking_id' => $tracking->id,
                'referred_delivery_boy_id' => $deliveryBoy->id,
                'completed_orders' => $tracking->completed_orders_count,
                'required_orders' => $tracking->required_orders_count
            ]);

            // Check if bonus should be paid
            if ($tracking->shouldPayBonus()) {
                // Pay the bonus
                $bonusResult = self::payReferralBonus($tracking);

                if ($bonusResult['success']) {
                    // Send notifications (after transaction commits in parent)
                    // Store notification flag in result for parent to handle
                    $bonusResult['should_send_notifications'] = true;
                    $bonusResult['tracking_id'] = $tracking->id;
                }

                return $bonusResult;
            } else {
                return [
                    'success' => true,
                    'message' => 'Order tracked successfully',
                    'completed_orders' => $tracking->completed_orders_count,
                    'required_orders' => $tracking->required_orders_count,
                    'bonus_pending' => true
                ];
            }

        } catch (\Exception $e) {
            Log::error('Failed to process referral order completion', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'delivery_boy_id' => $deliveryBoy->id,
                'order_id' => $orderId
            ]);

            return [
                'success' => false,
                'message' => 'Failed to process referral tracking: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Pay referral bonus to the referring delivery boy
     *
     * @param DeliveryBoyReferralTracking $tracking
     * @return array
     */
    private static function payReferralBonus(DeliveryBoyReferralTracking $tracking)
    {
        try {
            // Create transaction for the referring driver
            $transaction = new DeliveryBoyTransaction();
            $transaction->delivery_boy_id = $tracking->referring_delivery_boy_id;
            $transaction->user_id = null;
            $transaction->order_id = null;
            $transaction->type = 'referral_bonus';
            $transaction->amount = $tracking->bonus_amount;
            $transaction->driver_earnings = $tracking->bonus_amount;
            $transaction->admin_cash = -$tracking->bonus_amount; // Admin owes driver
            $transaction->status = DeliveryBoyTransaction::$statusSuccess;
            $transaction->message = 'Referral bonus earned! Driver #' . $tracking->referred_delivery_boy_id . ' completed ' . $tracking->required_orders_count . ' orders.';
            $transaction->transaction_date = now()->toDateTimeString();
            $transaction->settled_with_admin = false;
            $transaction->save();

            // Update tracking record
            $tracking->is_bonus_paid = true;
            $tracking->bonus_transaction_id = $transaction->id;
            $tracking->bonus_paid_at = now();
            $tracking->save();

            Log::info('Referral bonus paid successfully', [
                'tracking_id' => $tracking->id,
                'referring_delivery_boy_id' => $tracking->referring_delivery_boy_id,
                'referred_delivery_boy_id' => $tracking->referred_delivery_boy_id,
                'bonus_amount' => $tracking->bonus_amount,
                'transaction_id' => $transaction->id
            ]);

            return [
                'success' => true,
                'message' => 'Referral bonus paid successfully',
                'bonus_amount' => $tracking->bonus_amount,
                'transaction_id' => $transaction->id,
                'referring_delivery_boy_id' => $tracking->referring_delivery_boy_id
            ];

        } catch (\Exception $e) {
            Log::error('Failed to pay referral bonus', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'tracking_id' => $tracking->id
            ]);

            return [
                'success' => false,
                'message' => 'Failed to pay referral bonus: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Send notifications when referral bonus is paid
     *
     * @param DeliveryBoyReferralTracking $tracking
     */
    public static function sendBonusPaidNotifications(DeliveryBoyReferralTracking $tracking)
    {
        try {
            // Get referring delivery boy
            $referringDriver = DeliveryBoy::find($tracking->referring_delivery_boy_id);
            $referredDriver = DeliveryBoy::find($tracking->referred_delivery_boy_id);

            if (!$referringDriver || !$referredDriver) {
                Log::warning('Could not send referral bonus notifications - drivers not found');
                return;
            }

            // Send notification to referring driver
            try {
                DriverNotificationService::send(
                    driverId: $referringDriver->id,
                    title: 'Referral Bonus Earned! 🎉',
                    message: "Congratulations! You've earned ₹{$tracking->bonus_amount} referral bonus! {$referredDriver->name} completed {$tracking->required_orders_count} orders.",
                    type: 'referral_bonus',
                    extraData: [
                        'bonus_amount' => $tracking->bonus_amount,
                        'referred_driver_id' => $referredDriver->id,
                        'referred_driver_name' => $referredDriver->name
                    ]
                );

                Log::info('Referral bonus notification sent to referring driver', [
                    'referring_delivery_boy_id' => $referringDriver->id
                ]);
            } catch (\Exception $e) {
                Log::error('Failed to send notification to referring driver', [
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                    'referring_delivery_boy_id' => $referringDriver->id
                ]);
                // Continue execution - notification failure should not break the flow
            }

            // Send notification to admin
            try {
                AdminNotificationService::send(
                    adminIds: null, // Send to all admins
                    title: 'Referral Bonus Paid',
                    message: "Referral bonus of ₹{$tracking->bonus_amount} paid to {$referringDriver->name} (ID: {$referringDriver->id}) for referring {$referredDriver->name} (ID: {$referredDriver->id})",
                    type: 'referral_bonus_paid',
                    data: [
                        'referring_delivery_boy_id' => $referringDriver->id,
                        'referred_delivery_boy_id' => $referredDriver->id,
                        'bonus_amount' => $tracking->bonus_amount,
                        'transaction_id' => $tracking->bonus_transaction_id
                    ]
                );

                Log::info('Referral bonus notification sent to admin');
            } catch (\Exception $e) {
                Log::error('Failed to send notification to admin', [
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                // Continue execution - notification failure should not break the flow
            }

        } catch (\Exception $e) {
            Log::error('Failed to send referral bonus notifications', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'tracking_id' => $tracking->id
            ]);
            // Continue execution - notification failure should not break the flow
        }
    }
}
