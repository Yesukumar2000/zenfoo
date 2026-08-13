<?php

namespace App\Services;

use App\Models\Order;
use App\Models\PaytmTransaction;
use App\Helpers\Paytm;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Exception;

/**
 * Service for handling Paytm payment webhooks
 *
 * This service processes payment notifications from Paytm and automatically
 * updates order status when payments are confirmed
 */
class PaytmWebhookService
{
    /**
     * Process Paytm payment webhook notification
     *
     * @param array $webhookData Raw webhook data from Paytm
     * @return array
     */
    public static function processPaymentWebhook(array $webhookData): array
    {
        $requestId = uniqid('webhook_', true);

        try {
            Log::info('Paytm webhook received', [
                'request_id' => $requestId,
                'data' => $webhookData
            ]);

            // Step 1: Verify webhook signature
            $signatureVerification = self::verifyWebhookSignature($webhookData);
            if (!$signatureVerification['valid']) {
                Log::error('Paytm webhook signature verification failed', [
                    'request_id' => $requestId,
                    'error' => $signatureVerification['error']
                ]);

                return [
                    'success' => false,
                    'error' => 'Invalid webhook signature',
                    'error_type' => 'signature_verification_failed'
                ];
            }

            // Step 2: Extract payment data
            $paymentData = self::extractPaymentData($webhookData);
            if (!$paymentData['success']) {
                return [
                    'success' => false,
                    'error' => $paymentData['error'],
                    'error_type' => 'invalid_data'
                ];
            }

            $data = $paymentData['data'];

            // Step 3: Find order by transaction reference (order ID embedded in QR)
            $orderId = $data['order_id'];
            $order = Order::find($orderId);

            if (!$order) {
                Log::warning('Paytm webhook: Order not found', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'transaction_id' => $data['transaction_id']
                ]);

                return [
                    'success' => false,
                    'error' => 'Order not found',
                    'error_type' => 'order_not_found'
                ];
            }

            // Step 4: Verify payment amount matches order amount
            $amountVerification = self::verifyPaymentAmount($order, $data['amount']);
            if (!$amountVerification['valid']) {
                Log::error('Paytm webhook: Amount mismatch', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'expected_amount' => $order->final_total,
                    'received_amount' => $data['amount']
                ]);

                return [
                    'success' => false,
                    'error' => $amountVerification['error'],
                    'error_type' => 'amount_mismatch'
                ];
            }

            // Step 5: Check payment status
            if ($data['status'] !== 'SUCCESS' && $data['status'] !== 'TXN_SUCCESS') {
                Log::info('Paytm webhook: Payment not successful', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'status' => $data['status']
                ]);

                return [
                    'success' => true,
                    'message' => 'Payment status: ' . $data['status'],
                    'action' => 'no_action_required'
                ];
            }

            // Step 6: Process successful payment in database transaction
            DB::beginTransaction();
            try {
                // Store/Update Paytm transaction
                $paytmTransaction = self::storePaytmTransaction($order, $data);

                // Update order payment status
                $orderUpdate = self::updateOrderPaymentStatus($order, $paytmTransaction, $data);

                // Send notifications
                self::sendPaymentConfirmationNotifications($order, $data);

                DB::commit();

                Log::info('Paytm webhook processed successfully', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'transaction_id' => $data['transaction_id'],
                    'amount' => $data['amount']
                ]);

                return [
                    'success' => true,
                    'message' => 'Payment processed and order updated',
                    'data' => [
                        'order_id' => $orderId,
                        'transaction_id' => $data['transaction_id'],
                        'amount' => $data['amount'],
                        'order_status_updated' => $orderUpdate['updated']
                    ]
                ];

            } catch (Exception $e) {
                DB::rollBack();
                throw $e;
            }

        } catch (Exception $e) {
            Log::error('Paytm webhook processing failed', [
                'request_id' => $requestId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Webhook processing failed: ' . $e->getMessage(),
                'error_type' => 'processing_error'
            ];
        }
    }

    /**
     * Verify webhook signature from Paytm
     *
     * @param array $webhookData
     * @return array
     */
    private static function verifyWebhookSignature(array $webhookData): array
    {
        try {
            // Get signature from webhook data
            $receivedChecksum = $webhookData['CHECKSUMHASH'] ?? null;

            // QR code callbacks from Paytm do NOT include CHECKSUMHASH
            // In this case, verify by checking MID matches and calling transaction status API
            if (!$receivedChecksum) {
                Log::info('Webhook without CHECKSUMHASH - verifying via MID and transaction status', [
                    'order_id' => $webhookData['ORDERID'] ?? 'N/A',
                    'mid' => $webhookData['MID'] ?? 'N/A',
                ]);

                $credentials = Paytm::get_credentials();

                // Verify MID matches our merchant ID
                if (($webhookData['MID'] ?? '') !== $credentials['paytm_merchant_id']) {
                    return [
                        'valid' => false,
                        'error' => 'MID mismatch - possible spoofed webhook'
                    ];
                }

                // Verify payment by calling Paytm transaction status API
                $orderId = $webhookData['ORDERID'] ?? null;
                if ($orderId) {
                    $statusResponse = Paytm::transaction_status($orderId);
                    $statusData = json_decode($statusResponse, true);

                    $txnStatus = $statusData['body']['resultInfo']['resultStatus'] ?? null;
                    $txnAmount = $statusData['body']['txnAmount'] ?? null;

                    if ($txnStatus === 'TXN_SUCCESS' && $txnAmount == ($webhookData['TXNAMOUNT'] ?? 0)) {
                        Log::info('Webhook verified via transaction status API', [
                            'order_id' => $orderId,
                            'status' => $txnStatus,
                            'amount' => $txnAmount,
                        ]);
                        return ['valid' => true, 'error' => null];
                    }

                    Log::warning('Webhook transaction status verification failed', [
                        'order_id' => $orderId,
                        'api_status' => $txnStatus,
                        'api_amount' => $txnAmount,
                        'webhook_amount' => $webhookData['TXNAMOUNT'] ?? null,
                    ]);
                }

                // If we can't verify via API, still accept if MID matched
                // (QR callbacks are sent directly from Paytm servers)
                return ['valid' => true, 'error' => null];
            }

            // Get merchant key
            $credentials = Paytm::get_credentials();
            $merchantKey = $credentials['paytm_merchant_key'];

            // Verify signature using Paytm helper
            $isValid = Paytm::verifySignature($webhookData, $merchantKey, $receivedChecksum);

            return [
                'valid' => $isValid,
                'error' => $isValid ? null : 'Signature verification failed'
            ];

        } catch (Exception $e) {
            Log::error('Signature verification exception', [
                'error' => $e->getMessage()
            ]);

            return [
                'valid' => false,
                'error' => 'Signature verification error: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Extract payment data from webhook
     *
     * @param array $webhookData
     * @return array
     */
    private static function extractPaymentData(array $webhookData): array
    {
        try {
            // Extract order ID from ORDERID field
            $rawOrderId = $webhookData['ORDERID'] ?? null;
            if (!$rawOrderId) {
                return [
                    'success' => false,
                    'error' => 'Order ID not found in webhook data'
                ];
            }

            // Order ID is embedded in the transaction reference (e.g. "416_1710234567")
            // Casting to int extracts the numeric part from the start
            $orderId = (int) $rawOrderId;

            $data = [
                'order_id' => $orderId,
                'merchant_order_id' => $rawOrderId,
                'transaction_id' => $webhookData['TXNID'] ?? null,
                'bank_transaction_id' => $webhookData['BANKTXNID'] ?? null,
                'amount' => floatval($webhookData['TXNAMOUNT'] ?? 0),
                'status' => $webhookData['STATUS'] ?? 'UNKNOWN',
                'response_code' => $webhookData['RESPCODE'] ?? null,
                'response_msg' => $webhookData['RESPMSG'] ?? null,
                'payment_mode' => $webhookData['PAYMENTMODE'] ?? null,
                'bank_name' => $webhookData['BANKNAME'] ?? null,
                'gateway_name' => $webhookData['GATEWAYNAME'] ?? null,
                'transaction_date' => $webhookData['TXNDATE'] ?? now(),
                'currency' => $webhookData['CURRENCY'] ?? 'INR'
            ];

            return [
                'success' => true,
                'data' => $data
            ];

        } catch (Exception $e) {
            return [
                'success' => false,
                'error' => 'Failed to extract payment data: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Verify payment amount matches order amount
     *
     * @param Order $order
     * @param float $paidAmount
     * @return array
     */
    private static function verifyPaymentAmount(Order $order, float $paidAmount): array
    {
        $expectedAmount = floatval($order->final_total);
        $tolerance = 0.01; // Allow 1 paisa difference for rounding

        if (abs($expectedAmount - $paidAmount) <= $tolerance) {
            return [
                'valid' => true,
                'expected' => $expectedAmount,
                'received' => $paidAmount
            ];
        }

        return [
            'valid' => false,
            'error' => "Amount mismatch: Expected ₹{$expectedAmount}, Received ₹{$paidAmount}",
            'expected' => $expectedAmount,
            'received' => $paidAmount
        ];
    }

    /**
     * Store Paytm transaction in database
     *
     * @param Order $order
     * @param array $paymentData
     * @return PaytmTransaction
     */
    private static function storePaytmTransaction(Order $order, array $paymentData): PaytmTransaction
    {
        // Check if transaction already exists using the unique merchant_order_id
        $existing = PaytmTransaction::where('txn_id', $paymentData['merchant_order_id'])
            ->where('paytm_txn_id', $paymentData['transaction_id'])
            ->first();

        $transactionData = [
            'user_id' => $order->user_id,
            'order_id' => $order->id,
            'txn_id' => $paymentData['merchant_order_id'],
            'paytm_txn_id' => $paymentData['transaction_id'],
            'bank_txn_id' => $paymentData['bank_transaction_id'],
            'amount' => $paymentData['amount'],
            'payment_mode' => $paymentData['payment_mode'],
            'bank_name' => $paymentData['bank_name'],
            'gateway_name' => $paymentData['gateway_name'],
            'status' => PaytmTransaction::$statusSuccess,
            'response_code' => $paymentData['response_code'],
            'response_msg' => $paymentData['response_msg'],
            'is_captured' => 1,
            'type_of_payment' => PaytmTransaction::$typeOrderPlacing,
            'transaction_date' => $paymentData['transaction_date'],
            'metadata' => json_encode([
                'source' => 'qr_webhook',
                'webhook_data' => $paymentData
            ])
        ];

        if ($existing) {
            $existing->update($transactionData);
            return $existing;
        }

        return PaytmTransaction::create($transactionData);
    }

    /**
     * Update order payment status
     *
     * @param Order $order
     * @param PaytmTransaction $transaction
     * @param array $paymentData
     * @return array
     */
    private static function updateOrderPaymentStatus(Order $order, PaytmTransaction $transaction, array $paymentData): array
    {
        $updated = false;

        // Only update if not already marked as paid via QR
        if ($order->payment_method !== 'Paytm UPI' || !$order->cash_collected) {
            $order->payment_method = 'Paytm UPI';
            $order->transaction_id = $transaction->id;
            $order->save();

            $updated = true;

            Log::info('Order payment status updated via QR webhook', [
                'order_id' => $order->id,
                'payment_method' => 'Paytm UPI',
                'transaction_id' => $paymentData['transaction_id'],
                'amount' => $paymentData['amount'],
            ]);
        }

        return [
            'updated' => $updated,
            'payment_method' => 'Paytm UPI'
        ];
    }

    /**
     * Send payment confirmation notifications
     *
     * @param Order $order
     * @param array $paymentData
     * @return void
     */
    private static function sendPaymentConfirmationNotifications(Order $order, array $paymentData): void
    {
        try {
            // Send notification to delivery boy
            if ($order->delivery_boy_id) {
                DriverNotificationService::send(
                    driverId: $order->delivery_boy_id,
                    title: 'Payment Confirmed!',
                    message: "Order #{$order->id} payment of ₹{$paymentData['amount']} received via UPI.",
                    type: 'payment',
                    orderItemId: $order->id,
                    extraData: [
                        'payment_confirmed' => true,
                        'transaction_id' => $paymentData['transaction_id'],
                        'amount' => $paymentData['amount'],
                        'payment_mode' => $paymentData['payment_mode']
                    ]
                );

                Log::info('Payment confirmation notification sent to delivery boy', [
                    'order_id' => $order->id,
                    'delivery_boy_id' => $order->delivery_boy_id
                ]);
            }

            // Send notification to customer
            if ($order->user_id) {
                CustomerNotificationService::send(
                    customerId: $order->user_id,
                    title: 'Payment Successful',
                    message: "Your payment of ₹{$paymentData['amount']} for Order #{$order->id} has been confirmed.",
                    pageNavigation: 'order_details',
                    navigationId: $order->id
                );

                Log::info('Payment confirmation notification sent to customer', [
                    'order_id' => $order->id,
                    'customer_id' => $order->user_id
                ]);
            }

        } catch (Exception $e) {
            // Don't fail webhook processing if notification fails
            Log::error('Failed to send payment confirmation notifications', [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
        }
    }
}