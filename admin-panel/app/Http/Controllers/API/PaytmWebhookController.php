<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\PaytmWebhookService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Controller for handling Paytm payment webhooks
 *
 * This controller receives payment notifications from Paytm when customers
 * pay via UPI QR codes and automatically updates order status
 */
class PaytmWebhookController extends Controller
{
    /**
     * Handle Paytm payment webhook
     *
     * POST /api/paytm/payment-webhook
     *
     * This endpoint is called by Paytm servers when a payment is completed
     * NO authentication required (called by Paytm, not users)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function handlePaymentWebhook(Request $request)
    {
        $requestId = uniqid('paytm_webhook_', true);

        try {
            Log::info('Paytm webhook request received', [
                'request_id' => $requestId,
                'ip' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'all_data' => $request->all()
            ]);

            // Get all webhook data
            $webhookData = $request->all();

            // Validate webhook has minimum required data
            if (empty($webhookData['ORDERID']) || empty($webhookData['TXNID'])) {
                Log::error('Paytm webhook missing required fields', [
                    'request_id' => $requestId,
                    'received_data' => $webhookData
                ]);

                return response()->json([
                    'status' => 'ERROR',
                    'message' => 'Missing required webhook fields'
                ], 400);
            }

            // Process webhook using service
            $result = PaytmWebhookService::processPaymentWebhook($webhookData);

            if ($result['success']) {
                Log::info('Paytm webhook processed successfully', [
                    'request_id' => $requestId,
                    'order_id' => $result['data']['order_id'] ?? 'N/A',
                    'transaction_id' => $result['data']['transaction_id'] ?? 'N/A'
                ]);

                // Return success response to Paytm
                return response()->json([
                    'status' => 'OK',
                    'message' => $result['message']
                ], 200);
            } else {
                Log::error('Paytm webhook processing failed', [
                    'request_id' => $requestId,
                    'error' => $result['error'],
                    'error_type' => $result['error_type'] ?? 'unknown'
                ]);

                // Still return 200 to Paytm to prevent retries for invalid data
                return response()->json([
                    'status' => 'ERROR',
                    'message' => $result['error']
                ], 200);
            }

        } catch (\Exception $e) {
            Log::critical('Paytm webhook exception', [
                'request_id' => $requestId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            // Return 200 to prevent Paytm from retrying
            return response()->json([
                'status' => 'ERROR',
                'message' => 'Internal server error'
            ], 200);
        }
    }

    /**
     * Test webhook endpoint (for testing without Paytm)
     *
     * POST /api/paytm/test-webhook
     *
     * Use this to test webhook processing with sample data
     * Should be disabled in production
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function testWebhook(Request $request)
    {
        // Only allow in non-production environments
        if (app()->environment('production')) {
            return response()->json([
                'status' => 'ERROR',
                'message' => 'Test endpoint disabled in production'
            ], 403);
        }

        Log::info('Test webhook called', [
            'data' => $request->all()
        ]);

        // Sample webhook data for testing
        $sampleData = [
            'ORDERID' => $request->input('order_id', '123'), // Order ID
            'TXNID' => $request->input('txn_id', 'TEST' . time()),
            'BANKTXNID' => $request->input('bank_txn_id', 'BANK' . time()),
            'TXNAMOUNT' => $request->input('amount', '450.50'),
            'STATUS' => $request->input('status', 'TXN_SUCCESS'),
            'RESPCODE' => '01',
            'RESPMSG' => 'Txn Success',
            'PAYMENTMODE' => $request->input('payment_mode', 'UPI'),
            'BANKNAME' => $request->input('bank_name', 'PAYTM'),
            'GATEWAYNAME' => 'PAYTM',
            'TXNDATE' => now()->format('Y-m-d H:i:s'),
            'CURRENCY' => 'INR',
            'CHECKSUMHASH' => 'test_checksum_' . md5(time()) // For testing, will be verified
        ];

        // Merge with request data
        $webhookData = array_merge($sampleData, $request->all());

        Log::info('Processing test webhook', [
            'webhook_data' => $webhookData
        ]);

        // Process webhook
        $result = PaytmWebhookService::processPaymentWebhook($webhookData);

        return response()->json([
            'status' => $result['success'] ? 'OK' : 'ERROR',
            'message' => $result['success'] ? $result['message'] : $result['error'],
            'result' => $result
        ], $result['success'] ? 200 : 400);
    }

    /**
     * Webhook status/health check
     *
     * GET /api/paytm/webhook-status
     *
     * Check if webhook endpoint is accessible
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function webhookStatus()
    {
        return response()->json([
            'status' => 'OK',
            'message' => 'Paytm webhook endpoint is active',
            'timestamp' => now()->toIso8601String(),
            'endpoints' => [
                'payment_webhook' => url('/api/paytm/payment-webhook'),
                'test_webhook' => url('/api/paytm/test-webhook'),
                'status' => url('/api/paytm/webhook-status')
            ]
        ], 200);
    }
}