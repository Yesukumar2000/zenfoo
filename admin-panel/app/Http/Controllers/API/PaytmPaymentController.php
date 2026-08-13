<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\PaytmTransaction;
use App\Services\PaytmPaymentCaptureService;
use App\Services\PaytmWebhookService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class PaytmPaymentController extends Controller
{
    /**
     * Verify Paytm transaction, capture payment, and store in database
     *
     * POST /api/paytm/verify-payment
     *
     * IMPORTANT FLOW:
     * 1. Customer pays via Paytm in Flutter app
     * 2. Flutter receives transaction_id from Paytm
     * 3. Flutter calls THIS endpoint to verify and capture payment
     * 4. If payment is successful, Flutter then calls Place Order API
     *
     * NOTE: order_id is NOT sent in this request for order_placing flow
     * The order hasn't been created yet at this point!
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyPayment(Request $request)
    {
        // Start tracking request time for performance monitoring
        $startTime = microtime(true);
        $requestId = uniqid('paytm_', true);

        try {
            // Validate request with comprehensive rules
            $validator = Validator::make($request->all(), [
                'transaction_id' => [
                    'required',
                    'string',
                    'min:3',
                    'max:255',
                    'regex:/^[a-zA-Z0-9_-]+$/' // Only alphanumeric, underscore, hyphen
                ],
                'amount' => [
                    'nullable',
                    'numeric',
                    'min:0.01',
                    'max:999999.99'
                ],
                'type_of_payment' => [
                    'nullable',
                    Rule::in([PaytmTransaction::$typeOrderPlacing, PaytmTransaction::$typeWalletTopup])
                ]
            ], [
                'transaction_id.required' => 'Transaction ID is required',
                'transaction_id.regex' => 'Transaction ID contains invalid characters',
                'transaction_id.min' => 'Transaction ID is too short',
                'transaction_id.max' => 'Transaction ID is too long',
                'amount.numeric' => 'Amount must be a valid number',
                'amount.min' => 'Amount must be greater than zero',
                'amount.max' => 'Amount exceeds maximum allowed limit',
                'type_of_payment.in' => 'Invalid payment type'
            ]);

            if ($validator->fails()) {
                Log::warning('Paytm: Validation failed', [
                    'request_id' => $requestId,
                    'errors' => $validator->errors()->toArray(),
                    'input' => $request->only(['transaction_id', 'type_of_payment'])
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get authenticated user
            $user = auth()->user();
            if (!$user) {
                Log::error('Paytm: Unauthenticated request', [
                    'request_id' => $requestId
                ]);
                return response()->json([
                    'status' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            // Sanitize and extract inputs
            $transactionId = trim($request->transaction_id);
            $expectedAmount = $request->amount ? floatval($request->amount) : null;
            $typeOfPayment = $request->type_of_payment ?? PaytmTransaction::$typeOrderPlacing;

            Log::info('Paytm: Payment verification requested', [
                'request_id' => $requestId,
                'transaction_id' => $transactionId,
                'expected_amount' => $expectedAmount,
                'type_of_payment' => $typeOfPayment,
                'user_id' => $user->id,
                'ip_address' => $request->ip()
            ]);

            // Check if transaction already exists in our database
            $existingTransaction = PaytmTransaction::where('txn_id', $transactionId)
                ->where('user_id', $user->id)
                ->lockForUpdate() // Prevent race conditions
                ->first();

            // If transaction exists and is already successful and captured, return success
            if ($existingTransaction && $existingTransaction->isSuccessful() && $existingTransaction->isCaptured()) {
                Log::info('Paytm: Transaction already verified and captured', [
                    'request_id' => $requestId,
                    'transaction_id' => $transactionId,
                    'existing_id' => $existingTransaction->id
                ]);

                return response()->json([
                    'status' => true,
                    'message' => 'Payment already verified and captured',
                    'data' => [
                        'transaction_id' => $transactionId,
                        'paytm_transaction_id' => $existingTransaction->paytm_txn_id,
                        'bank_transaction_id' => $existingTransaction->bank_txn_id,
                        'amount' => $existingTransaction->amount,
                        'payment_status' => $existingTransaction->status,
                        'payment_mode' => $existingTransaction->payment_mode,
                        'bank_name' => $existingTransaction->bank_name,
                        'transaction_date' => $existingTransaction->transaction_date->format('Y-m-d H:i:s'),
                        'captured' => true,
                        'type_of_payment' => $existingTransaction->type_of_payment
                    ]
                ], 200);
            }

            // Verify payment with Paytm using the service
            $verificationResult = PaytmPaymentCaptureService::verifyPayment($transactionId, $expectedAmount);

            if (!$verificationResult['success']) {
                $errorType = $verificationResult['error_type'] ?? 'unknown';

                Log::error('Paytm: Payment verification failed', [
                    'request_id' => $requestId,
                    'transaction_id' => $transactionId,
                    'error' => $verificationResult['error'],
                    'error_type' => $errorType,
                    'user_id' => $user->id
                ]);

                // Update existing transaction if it exists
                if ($existingTransaction) {
                    try {
                        $existingTransaction->update([
                            'status' => PaytmTransaction::$statusFailed,
                            'response_msg' => $verificationResult['error'] ?? 'Payment verification failed',
                            'is_captured' => 0
                        ]);
                    } catch (\Exception $e) {
                        Log::error('Paytm: Failed to update existing transaction', [
                            'request_id' => $requestId,
                            'transaction_id' => $transactionId,
                            'error' => $e->getMessage()
                        ]);
                    }
                }

                // Return appropriate HTTP status code based on error type
                $httpStatusCode = match ($errorType) {
                    'validation_error' => 422,
                    'connection_error', 'request_error' => 503,
                    'payment_failed', 'amount_mismatch' => 400,
                    default => 400
                };

                return response()->json([
                    'status' => false,
                    'message' => $verificationResult['error'] ?? 'Payment verification failed',
                    'error_type' => $errorType,
                    'data' => [
                        'transaction_id' => $transactionId,
                        'payment_status' => 'FAILED',
                        'captured' => false
                    ]
                ], $httpStatusCode);
            }

            // Payment verified successfully - Store/Update in database with transaction
            $paymentData = $verificationResult['data'];

            DB::beginTransaction();
            try {
                // Prepare transaction data
                $transactionData = [
                    'user_id' => $user->id,
                    'order_id' => null, // Order hasn't been created yet
                    'txn_id' => $transactionId,
                    'paytm_txn_id' => $paymentData['transaction_id'] ?? null,
                    'bank_txn_id' => $paymentData['bank_transaction_id'] ?? null,
                    'amount' => floatval($paymentData['amount']),
                    'payment_mode' => $paymentData['payment_mode'] ?? null,
                    'bank_name' => $paymentData['bank_name'] ?? null,
                    'gateway_name' => $paymentData['gateway_name'] ?? null,
                    'status' => PaytmTransaction::$statusSuccess,
                    'response_code' => $paymentData['response_code'] ?? null,
                    'response_msg' => $paymentData['response_msg'] ?? 'Payment successful',
                    'is_captured' => 1, // Paytm auto-captures
                    'type_of_payment' => $typeOfPayment,
                    'transaction_date' => $paymentData['transaction_date'] ?? now(),
                    'metadata' => json_encode([
                        'payment_data' => $paymentData,
                        'request_id' => $requestId,
                        'ip_address' => $request->ip(),
                        'user_agent' => $request->userAgent()
                    ])
                ];

                // Validate critical data before saving
                if (empty($transactionData['paytm_txn_id'])) {
                    throw new \Exception('Paytm transaction ID is missing in response');
                }

                if ($transactionData['amount'] <= 0) {
                    throw new \Exception('Invalid transaction amount received from Paytm');
                }

                // Create or update transaction
                if ($existingTransaction) {
                    $existingTransaction->update($transactionData);
                    $paytmTransaction = $existingTransaction;
                    Log::info('Paytm: Updated existing transaction', [
                        'request_id' => $requestId,
                        'transaction_id' => $transactionId,
                        'db_id' => $paytmTransaction->id
                    ]);
                } else {
                    $paytmTransaction = PaytmTransaction::create($transactionData);
                    Log::info('Paytm: Created new transaction', [
                        'request_id' => $requestId,
                        'transaction_id' => $transactionId,
                        'db_id' => $paytmTransaction->id
                    ]);
                }

                DB::commit();

                // Calculate processing time
                $processingTime = round((microtime(true) - $startTime) * 1000, 2);

                Log::info('Paytm: Payment verified and stored successfully', [
                    'request_id' => $requestId,
                    'transaction_id' => $transactionId,
                    'paytm_txn_id' => $paymentData['transaction_id'],
                    'amount' => $paymentData['amount'],
                    'status' => PaytmTransaction::$statusSuccess,
                    'user_id' => $user->id,
                    'processing_time_ms' => $processingTime
                ]);

                return response()->json([
                    'status' => true,
                    'message' => 'Payment verified and captured successfully',
                    'data' => [
                        'transaction_id' => $transactionId,
                        'paytm_transaction_id' => $paymentData['transaction_id'],
                        'bank_transaction_id' => $paymentData['bank_transaction_id'],
                        'amount' => floatval($paymentData['amount']),
                        'payment_status' => PaytmTransaction::$statusSuccess,
                        'payment_mode' => $paymentData['payment_mode'],
                        'bank_name' => $paymentData['bank_name'],
                        'transaction_date' => $paymentData['transaction_date'],
                        'captured' => true,
                        'type_of_payment' => $typeOfPayment
                    ]
                ], 200);

            } catch (\Illuminate\Database\QueryException $e) {
                DB::rollBack();

                Log::error('Paytm: Database error while storing transaction', [
                    'request_id' => $requestId,
                    'transaction_id' => $transactionId,
                    'error' => $e->getMessage(),
                    'sql_code' => $e->getCode()
                ]);

                return response()->json([
                    'status' => false,
                    'message' => 'Payment verified but failed to save in database. Please contact support.',
                    'error_type' => 'database_error',
                    'data' => [
                        'transaction_id' => $transactionId,
                        'paytm_transaction_id' => $paymentData['transaction_id'] ?? null
                    ]
                ], 500);

            } catch (\Exception $e) {
                DB::rollBack();

                Log::error('Paytm: Failed to store transaction', [
                    'request_id' => $requestId,
                    'transaction_id' => $transactionId,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);

                return response()->json([
                    'status' => false,
                    'message' => 'Payment verified but failed to process. Please contact support.',
                    'error' => $e->getMessage(),
                    'error_type' => 'processing_error'
                ], 500);
            }

        } catch (\Exception $e) {
            Log::critical('Paytm: Unexpected exception in payment verification', [
                'request_id' => $requestId ?? 'unknown',
                'transaction_id' => $request->transaction_id ?? 'N/A',
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An unexpected error occurred while processing payment',
                'error_type' => 'system_error',
                'data' => [
                    'transaction_id' => $request->transaction_id ?? null,
                    'payment_status' => 'ERROR',
                    'captured' => false
                ]
            ], 500);
        }
    }

    /**
     * Check payment status without storing in database
     *
     * POST /api/paytm/check-status
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function checkStatus(Request $request)
    {
        $requestId = uniqid('paytm_check_', true);

        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'transaction_id' => [
                    'required',
                    'string',
                    'min:3',
                    'max:255',
                    'regex:/^[a-zA-Z0-9_-]+$/'
                ]
            ], [
                'transaction_id.required' => 'Transaction ID is required',
                'transaction_id.regex' => 'Transaction ID contains invalid characters'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $transactionId = trim($request->transaction_id);

            Log::info('Paytm: Status check requested', [
                'request_id' => $requestId,
                'transaction_id' => $transactionId,
                'user_id' => auth()->id()
            ]);

            // Check payment status
            $statusResult = PaytmPaymentCaptureService::checkPaymentStatus($transactionId);

            if (!$statusResult['success']) {
                $errorType = $statusResult['error_type'] ?? 'unknown';

                Log::error('Paytm: Status check failed', [
                    'request_id' => $requestId,
                    'transaction_id' => $transactionId,
                    'error' => $statusResult['error'],
                    'error_type' => $errorType
                ]);

                $httpStatusCode = match ($errorType) {
                    'validation_error' => 422,
                    'connection_error', 'request_error' => 503,
                    default => 400
                };

                return response()->json([
                    'status' => false,
                    'message' => $statusResult['error'] ?? 'Failed to check payment status',
                    'error_type' => $errorType,
                    'data' => [
                        'transaction_id' => $transactionId,
                        'payment_status' => 'UNKNOWN'
                    ]
                ], $httpStatusCode);
            }

            $paymentData = $statusResult['data'];

            return response()->json([
                'status' => true,
                'message' => 'Payment status retrieved successfully',
                'data' => [
                    'transaction_id' => $transactionId,
                    'paytm_transaction_id' => $paymentData['transaction_id'],
                    'bank_transaction_id' => $paymentData['bank_transaction_id'],
                    'amount' => floatval($paymentData['amount']),
                    'payment_status' => $paymentData['status'],
                    'response_message' => $paymentData['response_msg'],
                    'payment_mode' => $paymentData['payment_mode'],
                    'bank_name' => $paymentData['bank_name'],
                    'transaction_date' => $paymentData['transaction_date']
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::critical('Paytm: Status check exception', [
                'request_id' => $requestId,
                'transaction_id' => $request->transaction_id ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while checking payment status',
                'error_type' => 'system_error',
                'data' => [
                    'transaction_id' => $request->transaction_id ?? null,
                    'payment_status' => 'ERROR'
                ]
            ], 500);
        }
    }

    /**
     * Get Paytm configuration for Flutter app
     *
     * GET /customer/paytm/config
     *
     * Returns ONLY public, non-sensitive Paytm configuration
     * NEVER returns merchant_key (kept secret on server)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getConfig(Request $request)
    {
        $requestId = uniqid('paytm_config_', true);

        try {
            // Verify user is authenticated
            $user = auth()->user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'User not authenticated'
                ], 401);
            }

            Log::info('Paytm: Config requested', [
                'request_id' => $requestId,
                'user_id' => $user->id
            ]);

            // Get environment setting
            $environment = DB::table('settings')
                ->where('variable', 'paytm_environment')
                ->value('value') ?? 'test';

            // Validate environment
            if (!in_array($environment, ['test', 'live'])) {
                Log::error('Paytm: Invalid environment configuration', [
                    'environment' => $environment
                ]);
                return response()->json([
                    'status' => false,
                    'message' => 'Invalid Paytm configuration'
                ], 500);
            }

            // Determine which credentials to use
            $prefix = $environment === 'live' ? 'paytm_live' : 'paytm_test';

            // Get ONLY public configuration (NO SECRET KEY!)
            $settings = DB::table('settings')
                ->whereIn('variable', [
                    $prefix . '_merchant_id',
                    $prefix . '_website',
                    $prefix . '_industry_type',
                    $prefix . '_channel_id'
                ])
                ->pluck('value', 'variable');

            // Validate required configuration
            if (empty($settings[$prefix . '_merchant_id'])) {
                Log::error('Paytm: Merchant ID not configured', [
                    'environment' => $environment
                ]);
                return response()->json([
                    'status' => false,
                    'message' => 'Paytm is not configured properly'
                ], 500);
            }

            // Build response with ONLY safe, public data
            $config = [
                'merchant_id' => $settings[$prefix . '_merchant_id'] ?? null,
                'website' => $settings[$prefix . '_website'] ?? 'DEFAULT',
                'industry_type' => $settings[$prefix . '_industry_type'] ?? 'Retail',
                'channel_id' => $settings[$prefix . '_channel_id'] ?? 'WAP',
                'environment' => $environment,
                'callback_url' => url('/api/paytm/callback'), // For Paytm callback
                'urls' => [
                    'test' => 'https://securestage.paytmpayments.com',
                    'live' => 'https://secure.paytmpayments.com',
                    'current' => $environment === 'live'
                        ? 'https://secure.paytmpayments.com'
                        : 'https://securestage.paytmpayments.com'
                ]
            ];

            Log::info('Paytm: Config provided successfully', [
                'request_id' => $requestId,
                'user_id' => $user->id,
                'environment' => $environment
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Paytm configuration retrieved successfully',
                'data' => $config,
                'note' => 'For security, merchant_key is NOT included. All checksum generation happens server-side.'
            ], 200);

        } catch (\Exception $e) {
            Log::critical('Paytm: Config retrieval exception', [
                'request_id' => $requestId,
                'user_id' => auth()->id() ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while retrieving Paytm configuration',
                'error_type' => 'system_error'
            ], 500);
        }
    }

    /**
     * Get Paytm configuration for Delivery Boy app
     *
     * GET /api/delivery-boy/paytm/config
     *
     * Returns ONLY public, non-sensitive Paytm configuration
     * NEVER returns merchant_key (kept secret on server)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getConfigForDeliveryBoy(Request $request)
    {
        $requestId = uniqid('paytm_config_db_', true);

        try {
            // Verify delivery boy is authenticated
            $deliveryBoy = auth()->guard('api')->user();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => false,
                    'message' => 'Delivery boy not authenticated'
                ], 401);
            }

            Log::info('Paytm: Config requested by delivery boy', [
                'request_id' => $requestId,
                'delivery_boy_id' => $deliveryBoy->id
            ]);

            // Get environment setting
            $environment = DB::table('settings')
                ->where('variable', 'paytm_environment')
                ->value('value') ?? 'test';

            // Validate environment
            if (!in_array($environment, ['test', 'live'])) {
                Log::error('Paytm: Invalid environment configuration', [
                    'environment' => $environment
                ]);
                return response()->json([
                    'status' => false,
                    'message' => 'Invalid Paytm configuration'
                ], 500);
            }

            // Determine which credentials to use
            $prefix = $environment === 'live' ? 'paytm_live' : 'paytm_test';

            // Get ONLY public configuration (NO SECRET KEY!)
            $settings = DB::table('settings')
                ->whereIn('variable', [
                    $prefix . '_merchant_id',
                    $prefix . '_website',
                    $prefix . '_industry_type',
                    $prefix . '_channel_id'
                ])
                ->pluck('value', 'variable');

            // Validate required configuration
            if (empty($settings[$prefix . '_merchant_id'])) {
                Log::error('Paytm: Merchant ID not configured', [
                    'environment' => $environment
                ]);
                return response()->json([
                    'status' => false,
                    'message' => 'Paytm is not configured properly'
                ], 500);
            }

            // Build response with ONLY safe, public data
            $config = [
                'merchant_id' => $settings[$prefix . '_merchant_id'] ?? null,
                'website' => $settings[$prefix . '_website'] ?? 'DEFAULT',
                'industry_type' => $settings[$prefix . '_industry_type'] ?? 'Retail',
                'channel_id' => $settings[$prefix . '_channel_id'] ?? 'WAP',
                'environment' => $environment,
                'callback_url' => url('/api/paytm/callback'), // For Paytm callback
                'urls' => [
                    'test' => 'https://securestage.paytmpayments.com',
                    'live' => 'https://secure.paytmpayments.com',
                    'current' => $environment === 'live'
                        ? 'https://secure.paytmpayments.com'
                        : 'https://securestage.paytmpayments.com'
                ]
            ];

            Log::info('Paytm: Config provided successfully to delivery boy', [
                'request_id' => $requestId,
                'delivery_boy_id' => $deliveryBoy->id,
                'environment' => $environment
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Paytm configuration retrieved successfully',
                'data' => $config,
                'note' => 'For security, merchant_key is NOT included. All checksum generation happens server-side.'
            ], 200);

        } catch (\Exception $e) {
            Log::critical('Paytm: Config retrieval exception (delivery boy)', [
                'request_id' => $requestId,
                'delivery_boy_id' => auth()->guard('api')->id() ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while retrieving Paytm configuration',
                'error_type' => 'system_error'
            ], 500);
        }
    }

    /**
     * Handle Paytm payment callback
     *
     * POST /api/paytm/callback
     *
     * This endpoint is called by Paytm server after payment completion
     * NO authentication required (called by Paytm server)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function callback(Request $request)
    {
        $requestId = uniqid('paytm_callback_', true);

        try {
            Log::info('Paytm: Callback received', [
                'request_id' => $requestId,
                'all_data' => $request->all(),
                'headers' => $request->headers->all(),
                'ip' => $request->ip()
            ]);

            // Paytm sends callback data as POST parameters
            $callbackData = $request->all();

            // Validate required callback parameters
            if (empty($callbackData['ORDERID']) || empty($callbackData['TXNID'])) {
                Log::error('Paytm: Callback missing required parameters', [
                    'request_id' => $requestId,
                    'received_data' => $callbackData
                ]);

                return response()->json([
                    'status' => false,
                    'message' => 'Invalid callback data'
                ], 400);
            }

            $orderId = $callbackData['ORDERID'];
            $txnId = $callbackData['TXNID'];
            $status = $callbackData['STATUS'] ?? 'UNKNOWN';
            $checksumReceived = $callbackData['CHECKSUMHASH'] ?? null;

            Log::info('Paytm: Callback data extracted', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'txn_id' => $txnId,
                'status' => $status,
                'checksum_received' => substr($checksumReceived ?? '', 0, 20) . '...'
            ]);

            // Detect if this is a QR code payment webhook or regular callback
            // QR code order IDs look like "416_1773306540" (orderId_timestamp)
            // Regular callbacks have ORDERID as transaction reference (alphanumeric)
            $numericOrderId = (int) $orderId; // "416_1773306540" → 416
            $order = $numericOrderId > 0 ? Order::find($numericOrderId) : null;

            if ($order) {
                // This is a QR code webhook - route to webhook service
                Log::info('Paytm: Detected QR code webhook for order', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'order_found' => true
                ]);

                return $this->handleQRCodeWebhook($callbackData, $requestId);
            }

            // This is a regular callback (non-order payment) - continue with existing logic
            Log::info('Paytm: Processing as regular callback (non-order payment)', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'order_found' => false
            ]);

            // Verify checksum for security
            if ($checksumReceived) {
                $isValidChecksum = $this->verifyChecksum($callbackData, $checksumReceived);

                if (!$isValidChecksum) {
                    Log::error('Paytm: Callback checksum verification failed', [
                        'request_id' => $requestId,
                        'order_id' => $orderId,
                        'txn_id' => $txnId
                    ]);

                    return response()->json([
                        'status' => false,
                        'message' => 'Invalid checksum'
                    ], 400);
                }

                Log::info('Paytm: Callback checksum verified successfully', [
                    'request_id' => $requestId,
                    'order_id' => $orderId
                ]);
            } else {
                Log::warning('Paytm: Callback received without checksum', [
                    'request_id' => $requestId,
                    'order_id' => $orderId
                ]);
            }

            // Update transaction in database
            DB::beginTransaction();
            try {
                $transaction = PaytmTransaction::where('txn_id', $orderId)
                    ->orWhere('paytm_txn_id', $txnId)
                    ->lockForUpdate()
                    ->first();

                if ($transaction) {
                    // Map Paytm status to our status
                    $mappedStatus = match (strtoupper($status)) {
                        'TXN_SUCCESS' => PaytmTransaction::$statusSuccess,
                        'TXN_FAILURE' => PaytmTransaction::$statusFailed,
                        'PENDING' => PaytmTransaction::$statusPending,
                        default => PaytmTransaction::$statusFailed
                    };

                    // Update transaction with callback data
                    $transaction->update([
                        'status' => $mappedStatus,
                        'paytm_txn_id' => $txnId,
                        'bank_txn_id' => $callbackData['BANKTXNID'] ?? null,
                        'payment_mode' => $callbackData['PAYMENTMODE'] ?? null,
                        'bank_name' => $callbackData['BANKNAME'] ?? null,
                        'gateway_name' => $callbackData['GATEWAYNAME'] ?? null,
                        'response_code' => $callbackData['RESPCODE'] ?? null,
                        'response_msg' => $callbackData['RESPMSG'] ?? null,
                        'transaction_date' => isset($callbackData['TXNDATE'])
                            ? \Carbon\Carbon::parse($callbackData['TXNDATE'])
                            : now(),
                        'metadata' => json_encode([
                            'callback_data' => $callbackData,
                            'request_id' => $requestId,
                            'callback_ip' => $request->ip(),
                            'callback_time' => now()->toDateTimeString()
                        ])
                    ]);

                    Log::info('Paytm: Transaction updated from callback', [
                        'request_id' => $requestId,
                        'transaction_id' => $transaction->id,
                        'order_id' => $orderId,
                        'txn_id' => $txnId,
                        'status' => $mappedStatus
                    ]);
                } else {
                    Log::warning('Paytm: Transaction not found for callback', [
                        'request_id' => $requestId,
                        'order_id' => $orderId,
                        'txn_id' => $txnId
                    ]);

                    // Transaction doesn't exist yet - this is okay, callback might arrive before verify-payment
                    // We'll just log it
                }

                DB::commit();

                // Return success response to Paytm
                return response()->json([
                    'status' => true,
                    'message' => 'Callback processed successfully'
                ], 200);

            } catch (\Exception $e) {
                DB::rollBack();

                Log::error('Paytm: Failed to process callback', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'txn_id' => $txnId,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);

                return response()->json([
                    'status' => false,
                    'message' => 'Failed to process callback'
                ], 500);
            }

        } catch (\Exception $e) {
            Log::critical('Paytm: Callback exception', [
                'request_id' => $requestId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while processing callback'
            ], 500);
        }
    }

    /**
     * Verify Paytm checksum
     *
     * @param array $params
     * @param string $receivedChecksum
     * @return bool
     */
    private function verifyChecksum(array $params, string $receivedChecksum): bool
    {
        try {
            // Get environment setting
            $environment = DB::table('settings')
                ->where('variable', 'paytm_environment')
                ->value('value') ?? 'test';

            // Get merchant key
            $prefix = $environment === 'live' ? 'paytm_live' : 'paytm_test';
            $merchantKey = DB::table('settings')
                ->where('variable', $prefix . '_merchant_key')
                ->value('value');

            if (empty($merchantKey)) {
                Log::error('Paytm: Merchant key not found for checksum verification');
                return false;
            }

            // Remove CHECKSUMHASH from params before verification
            $paramsForChecksum = $params;
            unset($paramsForChecksum['CHECKSUMHASH']);

            // Generate checksum using Paytm's algorithm
            $calculatedChecksum = $this->generateChecksumHash($paramsForChecksum, $merchantKey);

            return hash_equals($calculatedChecksum, $receivedChecksum);

        } catch (\Exception $e) {
            Log::error('Paytm: Checksum verification exception', [
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Generate checksum hash (Paytm's algorithm)
     *
     * @param array $params
     * @param string $key
     * @return string
     */
    private function generateChecksumHash(array $params, string $key): string
    {
        ksort($params);
        $paramStr = '';
        foreach ($params as $k => $v) {
            if (strlen($v) > 0) {
                $paramStr .= $k . '=' . $v . '&';
            }
        }
        $paramStr = rtrim($paramStr, '&');

        return hash_hmac('sha256', $paramStr, $key);
    }

    /**
     * Handle QR code payment webhook
     *
     * Routes webhook notification to PaytmWebhookService for processing
     * This is called when customer pays via UPI QR code
     *
     * @param array $webhookData Raw webhook data from Paytm
     * @param string $requestId Unique request identifier for logging
     * @return \Illuminate\Http\JsonResponse
     */
    private function handleQRCodeWebhook(array $webhookData, string $requestId): \Illuminate\Http\JsonResponse
    {
        try {
            Log::info('Paytm: Processing QR code payment webhook', [
                'request_id' => $requestId,
                'order_id' => $webhookData['ORDERID'] ?? 'N/A',
                'txn_id' => $webhookData['TXNID'] ?? 'N/A',
                'status' => $webhookData['STATUS'] ?? 'N/A'
            ]);

            // Use PaytmWebhookService to process the webhook
            $result = PaytmWebhookService::processPaymentWebhook($webhookData);

            if ($result['success']) {
                Log::info('Paytm: QR code webhook processed successfully', [
                    'request_id' => $requestId,
                    'order_id' => $result['data']['order_id'] ?? 'N/A',
                    'transaction_id' => $result['data']['transaction_id'] ?? 'N/A',
                    'amount' => $result['data']['amount'] ?? 'N/A'
                ]);

                // Return success response to Paytm
                return response()->json([
                    'status' => 'OK',
                    'message' => $result['message']
                ], 200);
            } else {
                Log::error('Paytm: QR code webhook processing failed', [
                    'request_id' => $requestId,
                    'error' => $result['error'],
                    'error_type' => $result['error_type'] ?? 'unknown'
                ]);

                // Return 200 to prevent Paytm from retrying for invalid data
                return response()->json([
                    'status' => 'ERROR',
                    'message' => $result['error']
                ], 200);
            }

        } catch (\Exception $e) {
            Log::critical('Paytm: QR code webhook exception', [
                'request_id' => $requestId,
                'order_id' => $webhookData['ORDERID'] ?? 'N/A',
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
}
