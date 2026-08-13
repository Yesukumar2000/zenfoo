<?php

namespace App\Services;

use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyManualPayment;
use App\Models\DeliveryBoyTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\AdminNotificationService;
use App\Services\DriverNotificationService;

class ManualPaymentService
{
    /**
     * Approve manual payment and settle transactions
     *
     * @param DeliveryBoyManualPayment $payment
     * @param int $adminUserId
     * @param string|null $adminNotes
     * @param float|null $amountReceived - Actual amount received by admin (defaults to payment amount if not provided)
     * @return array
     */
    public static function approvePayment(DeliveryBoyManualPayment $payment, $adminUserId, $adminNotes = null, $amountReceived = null)
    {
        try {
            DB::beginTransaction();

            // Use amount received if provided, otherwise use the submitted amount
            $actualAmountReceived = $amountReceived ?? $payment->amount;

            // Update payment status
            $payment->status = 'approved';
            $payment->approved_by = $adminUserId;
            $payment->approved_at = now();
            $payment->admin_notes = $adminNotes;
            $payment->save();

            // Get the delivery boy
            $deliveryBoy = DeliveryBoy::find($payment->delivery_boy_id);
            if (!$deliveryBoy) {
                throw new \Exception("Delivery boy not found");
            }

            // Settle transactions with the actual amount received
            $settledAmount = self::settleTransactions($deliveryBoy->id, $actualAmountReceived);

            DB::commit();

            // Send notifications
            self::sendApprovalNotifications($deliveryBoy, $payment, $settledAmount, $actualAmountReceived);

            Log::info('Manual payment approved and settled', [
                'payment_id' => $payment->id,
                'delivery_boy_id' => $deliveryBoy->id,
                'submitted_amount' => $payment->amount,
                'amount_received' => $actualAmountReceived,
                'settled_amount' => $settledAmount,
            ]);

            return [
                'success' => true,
                'message' => 'Payment approved and transactions settled successfully',
                'settled_amount' => $settledAmount,
                'amount_received' => $actualAmountReceived,
            ];
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error approving manual payment: ' . $e->getMessage(), [
                'payment_id' => $payment->id ?? null,
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to approve payment: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Settle delivery boy transactions with the paid amount
     *
     * @param int $deliveryBoyId
     * @param float $paidAmount
     * @return float Amount actually settled
     */
    private static function settleTransactions($deliveryBoyId, $paidAmount)
    {
        // Get unsettled transactions where driver owes admin (admin_cash > 0)
        $unsettledTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoyId)
            ->where('settled_with_admin', 0)
            ->where('admin_cash', '>', 0)
            ->orderBy('created_at', 'asc')
            ->get();

        $remainingAmount = $paidAmount;
        $settledAmount = 0;

        foreach ($unsettledTransactions as $transaction) {
            if ($remainingAmount <= 0) {
                break;
            }

            $originalDebt = $transaction->admin_cash;

            if ($remainingAmount >= $transaction->admin_cash) {
                // Fully settle this transaction
                $settledNow = $transaction->admin_cash;
                $transaction->admin_cash = 0; // Clear the debt
                $transaction->settled_with_admin = 1;
                $transaction->partial_payment = null; // Clear partial payment since it's fully settled
                $transaction->save();

                $remainingAmount -= $settledNow;
                $settledAmount += $settledNow;

                Log::info('Transaction fully settled', [
                    'transaction_id' => $transaction->id,
                    'original_debt' => $originalDebt,
                    'settled_now' => $settledNow,
                    'remaining_admin_cash' => 0,
                ]);
            } else {
                // Partial payment - reduce admin_cash by the amount paid
                $transaction->admin_cash = $transaction->admin_cash - $remainingAmount;
                $transaction->partial_payment = ($transaction->partial_payment ?? 0) + $remainingAmount;
                $transaction->save();

                $settledAmount += $remainingAmount;

                Log::info('Transaction partially settled', [
                    'transaction_id' => $transaction->id,
                    'original_debt' => $originalDebt,
                    'paid_now' => $remainingAmount,
                    'total_paid_so_far' => $transaction->partial_payment,
                    'remaining_admin_cash' => $transaction->admin_cash,
                ]);

                $remainingAmount = 0;
                break;
            }
        }

        return $settledAmount;
    }

    /**
     * Reject manual payment
     *
     * @param DeliveryBoyManualPayment $payment
     * @param int $adminUserId
     * @param string|null $adminNotes
     * @return array
     */
    public static function rejectPayment(DeliveryBoyManualPayment $payment, $adminUserId, $adminNotes = null)
    {
        try {
            $payment->status = 'rejected';
            $payment->approved_by = $adminUserId;
            $payment->approved_at = now();
            $payment->admin_notes = $adminNotes;
            $payment->save();

            // Get the delivery boy
            $deliveryBoy = DeliveryBoy::find($payment->delivery_boy_id);

            // Send notification
            self::sendRejectionNotification($deliveryBoy, $payment);

            Log::info('Manual payment rejected', [
                'payment_id' => $payment->id,
                'delivery_boy_id' => $payment->delivery_boy_id,
                'reason' => $adminNotes,
            ]);

            return [
                'success' => true,
                'message' => 'Payment rejected successfully',
            ];
        } catch (\Exception $e) {
            Log::error('Error rejecting manual payment: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to reject payment: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Manually reduce hand cash for a delivery boy (direct admin action)
     *
     * @param int $deliveryBoyId
     * @param float $amount
     * @param int $adminUserId
     * @param string|null $reason
     * @return array
     */
    public static function manuallyReduceHandCash($deliveryBoyId, $amount, $adminUserId, $reason = null)
    {
        try {
            DB::beginTransaction();

            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            if (!$deliveryBoy) {
                throw new \Exception("Delivery boy not found");
            }

            // Settle transactions with the amount
            $settledAmount = self::settleTransactions($deliveryBoyId, $amount);

            // Create a record for tracking (optional - for audit trail)
            DeliveryBoyManualPayment::create([
                'delivery_boy_id' => $deliveryBoyId,
                'transaction_id' => 'MANUAL_REDUCTION_' . time(),
                'amount' => $amount,
                'status' => 'approved',
                'approved_by' => $adminUserId,
                'approved_at' => now(),
                'admin_notes' => $reason ?? 'Manual hand cash reduction by admin',
            ]);

            DB::commit();

            Log::info('Manual hand cash reduction', [
                'delivery_boy_id' => $deliveryBoyId,
                'amount' => $amount,
                'settled_amount' => $settledAmount,
                'admin_user_id' => $adminUserId,
            ]);

            return [
                'success' => true,
                'message' => 'Hand cash reduced successfully',
                'settled_amount' => $settledAmount,
            ];
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error reducing hand cash manually: ' . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Failed to reduce hand cash: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Send approval notifications
     *
     * @param DeliveryBoy $deliveryBoy
     * @param DeliveryBoyManualPayment $payment
     * @param float $settledAmount
     * @param float $amountReceived
     * @return void
     */
    private static function sendApprovalNotifications($deliveryBoy, $payment, $settledAmount, $amountReceived)
    {
        try {
            // Notify driver
            DriverNotificationService::send(
                $deliveryBoy->id,
                "Payment Approved",
                "Your payment of ₹{$amountReceived} has been approved and ₹{$settledAmount} has been settled from your hand cash.",
                '', // image
                'manual_payment_approved',
                null, // orderItemId
                ['payment_id' => $payment->id]
            );

            // Notify admin
            AdminNotificationService::send(
                adminIds: null,
                title: "Manual Payment Approved",
                message: "Driver #{$deliveryBoy->id} - {$deliveryBoy->name}: Payment of ₹{$amountReceived} approved, ₹{$settledAmount} settled.",
                type: 'manual_payment_approved',
                data: ['payment_id' => $payment->id, 'delivery_boy_id' => $deliveryBoy->id]
            );
        } catch (\Exception $e) {
            Log::warning('Failed to send approval notifications: ' . $e->getMessage());
        }
    }

    /**
     * Send rejection notification
     *
     * @param DeliveryBoy $deliveryBoy
     * @param DeliveryBoyManualPayment $payment
     * @return void
     */
    private static function sendRejectionNotification($deliveryBoy, $payment)
    {
        try {
            $reason = $payment->admin_notes ?? 'No reason provided';

            DriverNotificationService::send(
                $deliveryBoy->id,
                "Payment Rejected",
                "Your payment of ₹{$payment->amount} was rejected. Reason: {$reason}",
                '', // image
                'manual_payment_rejected',
                null, // orderItemId
                ['payment_id' => $payment->id]
            );
        } catch (\Exception $e) {
            Log::warning('Failed to send rejection notification: ' . $e->getMessage());
        }
    }
}
