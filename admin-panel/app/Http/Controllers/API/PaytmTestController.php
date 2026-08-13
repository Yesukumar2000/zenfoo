<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\PaytmTransaction;
use App\Models\Transaction;
use App\Services\PaytmRefundService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

/**
 * TEST CONTROLLER - FOR DEVELOPMENT/TESTING ONLY
 *
 * This controller simulates Paytm payment verification WITHOUT calling actual Paytm API
 * Use this ONLY for testing database storage and API responses
 *
 * DELETE THIS FILE IN PRODUCTION!
 */
class PaytmTestController extends Controller
{
    /**
     * Create a test/mock Paytm transaction for testing
     *
     * POST /api/paytm/test/create-mock-payment
     *
     * This endpoint simulates a successful Paytm payment WITHOUT calling Paytm API
     * Useful for testing database storage and response format
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function createMockPayment(Request $request)
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'amount' => 'required|numeric|min:1|max:99999',
                'type_of_payment' => 'nullable|in:order_placing,wallet_topup'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = auth()->user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            $amount = floatval($request->amount);
            $typeOfPayment = $request->type_of_payment ?? PaytmTransaction::$typeOrderPlacing;

            // Generate mock transaction IDs
            $mockTransactionId = 'TEST_TXN_' . time() . '_' . $user->id;
            $mockPaytmTxnId = 'PAYTM_' . time() . rand(1000, 9999);
            $mockBankTxnId = 'BANK_' . time() . rand(1000, 9999);

            DB::beginTransaction();
            try {
                // Create mock transaction
                $transaction = PaytmTransaction::create([
                    'user_id' => $user->id,
                    'order_id' => null,
                    'txn_id' => $mockTransactionId,
                    'paytm_txn_id' => $mockPaytmTxnId,
                    'bank_txn_id' => $mockBankTxnId,
                    'amount' => $amount,
                    'payment_mode' => 'UPI',
                    'bank_name' => 'HDFC Bank',
                    'gateway_name' => 'PAYTM',
                    'status' => PaytmTransaction::$statusSuccess,
                    'response_code' => '01',
                    'response_msg' => 'Txn Success (MOCK)',
                    'is_captured' => 1,
                    'type_of_payment' => $typeOfPayment,
                    'transaction_date' => now(),
                    'metadata' => json_encode([
                        'test_mode' => true,
                        'created_by' => 'test_endpoint',
                        'ip_address' => $request->ip()
                    ])
                ]);

                DB::commit();

                Log::info('TEST: Mock Paytm transaction created', [
                    'transaction_id' => $mockTransactionId,
                    'amount' => $amount,
                    'user_id' => $user->id
                ]);

                return response()->json([
                    'status' => true,
                    'message' => 'Mock payment created successfully (TEST MODE)',
                    'data' => [
                        'transaction_id' => $mockTransactionId,
                        'paytm_transaction_id' => $mockPaytmTxnId,
                        'bank_transaction_id' => $mockBankTxnId,
                        'amount' => $amount,
                        'payment_status' => PaytmTransaction::$statusSuccess,
                        'payment_mode' => 'UPI',
                        'bank_name' => 'HDFC Bank',
                        'transaction_date' => $transaction->transaction_date->format('Y-m-d H:i:s'),
                        'captured' => true,
                        'type_of_payment' => $typeOfPayment,
                        'test_mode' => true
                    ],
                    'note' => 'This is a MOCK transaction for testing. Use transaction_id to test verify-payment endpoint.'
                ], 200);

            } catch (\Exception $e) {
                DB::rollBack();

                Log::error('TEST: Failed to create mock transaction', [
                    'error' => $e->getMessage()
                ]);

                return response()->json([
                    'status' => false,
                    'message' => 'Failed to create mock transaction',
                    'error' => $e->getMessage()
                ], 500);
            }

        } catch (\Exception $e) {
            Log::error('TEST: Mock payment creation exception', [
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get all test transactions for current user
     *
     * GET /api/paytm/test/transactions
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getTestTransactions(Request $request)
    {
        try {
            $user = auth()->user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            $transactions = PaytmTransaction::where('user_id', $user->id)
                ->orderBy('created_at', 'desc')
                ->limit(20)
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Transactions retrieved successfully',
                'data' => [
                    'transactions' => $transactions,
                    'count' => $transactions->count()
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to retrieve transactions',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Clear all test transactions
     *
     * DELETE /api/paytm/test/clear-transactions
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function clearTestTransactions(Request $request)
    {
        try {
            $user = auth()->user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            $deleted = PaytmTransaction::where('user_id', $user->id)
                ->where('txn_id', 'LIKE', 'TEST_TXN_%')
                ->delete();

            return response()->json([
                'status' => true,
                'message' => "Deleted {$deleted} test transactions",
                'data' => [
                    'deleted_count' => $deleted
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status' => false,
                'message' => 'Failed to clear transactions',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Check Paytm refund status
     *
     * GET /api/paytm/test/check-refund-status
     *
     * Query params:
     *   - order_id (required): Order ID to check refund status
     *
     * This endpoint calls Paytm's Refund Status API to check if a refund is completed
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function checkRefundStatus(Request $request)
    {
        try {
            Log::info('Paytm Refund Status Check: Request received', [
                'params' => $request->all(),
                'ip' => $request->ip(),
            ]);

            // Validate request
            $validator = Validator::make($request->all(), [
                'order_id' => 'required|integer|exists:orders,id',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => false,
                    'message' => $validator->errors()->first(),
                    'errors' => $validator->errors()
                ], 400);
            }

            $orderId = $request->order_id;

            // Find the transaction for this order
            $transaction = Transaction::where('order_id', $orderId)
                ->where('type', 'Paytm')
                ->first();

            if (!$transaction) {
                return response()->json([
                    'status' => false,
                    'message' => 'No Paytm transaction found for this order',
                    'data' => [
                        'order_id' => $orderId,
                    ]
                ], 404);
            }

            // Check if refund was initiated
            if (empty($transaction->refund_transaction_id)) {
                return response()->json([
                    'status' => false,
                    'message' => 'No refund initiated for this order yet',
                    'data' => [
                        'order_id' => $orderId,
                        'transaction_id' => $transaction->id,
                        'transaction_amount' => $transaction->amount,
                        'refund_initiated' => false,
                    ]
                ], 404);
            }

            // Find Paytm transaction record
            $paytmTransaction = PaytmTransaction::where('order_id', $orderId)
                ->where('status', PaytmTransaction::$statusSuccess)
                ->first();

            if (!$paytmTransaction) {
                return response()->json([
                    'status' => false,
                    'message' => 'Paytm transaction record not found',
                    'data' => [
                        'order_id' => $orderId,
                    ]
                ], 404);
            }

            Log::info('Paytm Refund Status Check: Found refund details', [
                'order_id' => $orderId,
                'paytm_order_id' => $paytmTransaction->txn_id,
                'internal_refund_id' => $paytmTransaction->internal_refund_id,
                'refund_amount' => $transaction->refund_amount,
                'paytm_refund_id' => $paytmTransaction->refund_id,
            ]);

            // Call Paytm Refund Status API
            $refundService = new PaytmRefundService();
            $refundStatusResult = $refundService->checkRefundStatus(
                $paytmTransaction->internal_refund_id ?? $transaction->refund_transaction_id,  // Our internal refund ID
                $paytmTransaction->txn_id             // Paytm order ID
            );

            Log::info('Paytm Refund Status Check: API response', [
                'order_id' => $orderId,
                'result' => $refundStatusResult,
            ]);

            // Build comprehensive response
            $responseData = [
                'order_id' => $orderId,
                'our_transaction_id' => $transaction->id,
                'paytm_order_id' => $paytmTransaction->txn_id,
                'paytm_txn_id' => $paytmTransaction->paytm_txn_id,
                'original_amount' => $paytmTransaction->amount,
                'refund_amount' => $transaction->refund_amount,
                'refund_initiated_at' => $transaction->updated_at->format('Y-m-d H:i:s'),
                'our_internal_refund_id' => $paytmTransaction->internal_refund_id,
                'paytm_refund_id' => $paytmTransaction->refund_id,
                'paytm_api_response' => $refundStatusResult,
            ];

            if ($refundStatusResult['success']) {
                $status = $refundStatusResult['status'] ?? 'UNKNOWN';
                $message = $refundStatusResult['message'] ?? 'Status retrieved';

                return response()->json([
                    'status' => true,
                    'message' => "Refund status: {$status}",
                    'refund_status' => $status,
                    'refund_message' => $message,
                    'data' => $responseData,
                ], 200);
            } else {
                return response()->json([
                    'status' => false,
                    'message' => 'Failed to check refund status from Paytm',
                    'error' => $refundStatusResult['error'] ?? 'Unknown error',
                    'data' => $responseData,
                ], 500);
            }

        } catch (\Exception $e) {
            Log::error('Paytm Refund Status Check: Exception', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while checking refund status',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
