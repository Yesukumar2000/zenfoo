<?php

namespace App\Services;

use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;

class PhonePePayoutService
{
    // PhonePe Payout API credentials
    private static $merchantId;
    private static $clientId;
    private static $clientSecret;
    private static $isProduction;
    private static $mockMode;

    // PhonePe Payout API URLs (OAuth2 based)
    private static $uatAuthUrl = 'https://api-preprod.phonepe.com/apis/pg-sandbox/v1/oauth/token';
    private static $uatPayoutUrl = 'https://api-preprod.phonepe.com/apis/pg-sandbox/disbursement/v2/pay';
    private static $uatStatusUrl = 'https://api-preprod.phonepe.com/apis/pg-sandbox/disbursement/v2/transaction';

    private static $prodAuthUrl = 'https://api.phonepe.com/apis/identity-manager/v1/oauth/token';
    private static $prodPayoutUrl = 'https://api.phonepe.com/apis/disbursement/v2/pay';
    private static $prodStatusUrl = 'https://api.phonepe.com/apis/disbursement/v2/transaction';

    // Payout status constants
    const PAYOUT_STATUS_PENDING = 'pending';
    const PAYOUT_STATUS_SUCCESS = 'success';
    const PAYOUT_STATUS_FAILED = 'failed';
    const PAYOUT_STATUS_PROCESSING = 'processing';

    /**
     * Initialize PhonePe configuration
     *
     * @return void
     */
    private static function initConfig()
    {
        self::$merchantId = config('services.phonepe.merchant_id', 'M23TSU3JHDUZ0');
        self::$clientId = config('services.phonepe.client_id', 'M23TSU3JHDUZ0_2601211145');
        self::$clientSecret = config('services.phonepe.client_secret', 'MTIyNTBkNTMtNTY3MC00ZWJmLWFjMTYtY2E5ZmNjNTliOWYw');
        self::$isProduction = config('services.phonepe.is_production', false);
        // Enable mock mode for local development (when not in production and mock is enabled)
        self::$mockMode = config('services.phonepe.mock_mode', !self::$isProduction);
    }

    /**
     * Get OAuth2 access token from PhonePe
     */
    private static function getAccessToken()
    {
        self::initConfig();

        // Check cache first
        $cacheKey = 'phonepe_payout_token_' . self::$clientId;
        $cachedToken = Cache::get($cacheKey);

        if ($cachedToken) {
            return $cachedToken;
        }

        $authUrl = self::$isProduction ? self::$prodAuthUrl : self::$uatAuthUrl;

        Log::info('PhonePe Payout: Requesting OAuth token', [
            'client_id' => self::$clientId,
            'auth_url' => $authUrl
        ]);

        $ch = curl_init();
        $curlOptions = [
            CURLOPT_URL => $authUrl,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => http_build_query([
                'grant_type' => 'client_credentials',
                'client_id' => self::$clientId,
                'client_secret' => self::$clientSecret,
                'client_version' => '1'
            ]),
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/x-www-form-urlencoded'
            ],
            CURLOPT_TIMEOUT => 30
        ];

        // Disable SSL verification for non-production (local development)
        if (!self::$isProduction) {
            $curlOptions[CURLOPT_SSL_VERIFYPEER] = false;
            $curlOptions[CURLOPT_SSL_VERIFYHOST] = 0;
        }

        curl_setopt_array($ch, $curlOptions);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if (curl_errno($ch)) {
            $error = curl_error($ch);
            curl_close($ch);
            Log::error('PhonePe Payout: OAuth token error', ['error' => $error]);
            return null;
        }

        curl_close($ch);
        $responseData = json_decode($response, true);

        Log::info('PhonePe Payout: OAuth response', [
            'http_code' => $httpCode,
            'response' => $responseData
        ]);

        if ($httpCode === 200 && isset($responseData['access_token'])) {
            $token = $responseData['access_token'];
            $expiresIn = $responseData['expires_in'] ?? 3600;

            // Cache token (expire 5 minutes before actual expiry)
            Cache::put($cacheKey, $token, now()->addSeconds($expiresIn - 300));

            return $token;
        }

        Log::error('PhonePe Payout: Failed to get OAuth token', [
            'http_code' => $httpCode,
            'response' => $responseData
        ]);

        return null;
    }

    /**
     * Process payout to delivery boy's bank account
     *
     * @param int $deliveryBoyId
     * @param array $transactionIds Array of transaction IDs to settle
     * @param float $totalAmount Total amount to pay
     * @return array
     */
    public static function processPayoutToDeliveryBoy($deliveryBoyId, $transactionIds, $totalAmount)
    {
        try {
            Log::info('PhonePe Payout: Starting payout process', [
                'delivery_boy_id' => $deliveryBoyId,
                'transaction_ids' => $transactionIds,
                'total_amount' => $totalAmount
            ]);

            // Validate input
            if (empty($transactionIds)) {
                Log::warning('PhonePe Payout: No transaction IDs provided', [
                    'delivery_boy_id' => $deliveryBoyId
                ]);
                return [
                    'success' => false,
                    'error' => 'No transactions selected for payout'
                ];
            }

            if ($totalAmount <= 0) {
                Log::warning('PhonePe Payout: Invalid amount', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'amount' => $totalAmount
                ]);
                return [
                    'success' => false,
                    'error' => 'Invalid payout amount'
                ];
            }

            // Get delivery boy details
            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            if (!$deliveryBoy) {
                Log::error('PhonePe Payout: Delivery boy not found', [
                    'delivery_boy_id' => $deliveryBoyId
                ]);
                return [
                    'success' => false,
                    'error' => 'Delivery boy not found'
                ];
            }

            // Get bank details from delivery_boy_documents table
            $bankDetails = self::getDeliveryBoyBankDetails($deliveryBoyId);
            if (!$bankDetails['success']) {
                return $bankDetails;
            }

            // Generate unique payout transaction ID
            $payoutTransactionId = self::generatePayoutTransactionId($deliveryBoyId);

            Log::info('PhonePe Payout: Bank details retrieved', [
                'delivery_boy_id' => $deliveryBoyId,
                'payout_transaction_id' => $payoutTransactionId,
                'bank_name' => $bankDetails['data']['bank_name'],
                'account_holder_name' => $bankDetails['data']['account_holder_name'],
                // Masking sensitive data for logs
                'account_number_masked' => self::maskAccountNumber($bankDetails['data']['account_number']),
                'ifsc_code' => $bankDetails['data']['ifsc_code']
            ]);

            // Initiate the payout
            $payoutResult = self::initiateBankTransfer(
                $payoutTransactionId,
                $totalAmount,
                $bankDetails['data'],
                $deliveryBoy
            );

            if (!$payoutResult['success']) {
                Log::error('PhonePe Payout: Bank transfer initiation failed', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'payout_transaction_id' => $payoutTransactionId,
                    'error' => $payoutResult['error']
                ]);
                return $payoutResult;
            }

            // Create payout record
            $payoutRecord = self::createPayoutRecord(
                $deliveryBoyId,
                $payoutTransactionId,
                $transactionIds,
                $totalAmount,
                $payoutResult,
                $bankDetails['data']['account_number']
            );

            Log::info('PhonePe Payout: Payout initiated successfully', [
                'delivery_boy_id' => $deliveryBoyId,
                'payout_transaction_id' => $payoutTransactionId,
                'payout_record_id' => $payoutRecord ? $payoutRecord->id : null,
                'amount' => $totalAmount,
                'phonepe_response' => $payoutResult['data'] ?? []
            ]);

            return [
                'success' => true,
                'message' => 'Payout initiated successfully',
                'data' => [
                    'payout_transaction_id' => $payoutTransactionId,
                    'amount' => $totalAmount,
                    'status' => self::PAYOUT_STATUS_PROCESSING,
                    'phonepe_response' => $payoutResult['data'] ?? []
                ]
            ];

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Exception during payout process', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Payout processing failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get bank details for delivery boy from delivery_boy_documents table
     *
     * @param int $deliveryBoyId
     * @return array
     */
    public static function getDeliveryBoyBankDetails($deliveryBoyId)
    {
        try {
            Log::info('PhonePe Payout: Fetching bank details', [
                'delivery_boy_id' => $deliveryBoyId
            ]);

            $bankDetails = DB::table('delivery_boy_documents')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->select([
                    'bank_name',
                    'account_holder_name',
                    'account_number',
                    'ifsc_code',
                    'bank_details_status'
                ])
                ->first();

            if (!$bankDetails) {
                Log::warning('PhonePe Payout: No bank details found', [
                    'delivery_boy_id' => $deliveryBoyId
                ]);
                return [
                    'success' => false,
                    'error' => 'Bank details not found for this delivery boy'
                ];
            }

            // Validate bank details status
            if ($bankDetails->bank_details_status !== 'verified') {
                Log::warning('PhonePe Payout: Bank details not verified', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'status' => $bankDetails->bank_details_status
                ]);
                return [
                    'success' => false,
                    'error' => 'Bank details are not verified. Current status: ' . $bankDetails->bank_details_status
                ];
            }

            // Validate required fields
            $requiredFields = ['bank_name', 'account_holder_name', 'account_number', 'ifsc_code'];
            foreach ($requiredFields as $field) {
                if (empty($bankDetails->$field)) {
                    Log::warning('PhonePe Payout: Missing required bank field', [
                        'delivery_boy_id' => $deliveryBoyId,
                        'missing_field' => $field
                    ]);
                    return [
                        'success' => false,
                        'error' => 'Missing required bank detail: ' . str_replace('_', ' ', $field)
                    ];
                }
            }

            // Validate IFSC code format (11 characters)
            if (strlen($bankDetails->ifsc_code) !== 11) {
                Log::warning('PhonePe Payout: Invalid IFSC code format', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'ifsc_code' => $bankDetails->ifsc_code
                ]);
                return [
                    'success' => false,
                    'error' => 'Invalid IFSC code format'
                ];
            }

            Log::info('PhonePe Payout: Bank details validated successfully', [
                'delivery_boy_id' => $deliveryBoyId
            ]);

            return [
                'success' => true,
                'data' => [
                    'bank_name' => $bankDetails->bank_name,
                    'account_holder_name' => $bankDetails->account_holder_name,
                    'account_number' => $bankDetails->account_number,
                    'ifsc_code' => $bankDetails->ifsc_code
                ]
            ];

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Exception fetching bank details', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to fetch bank details: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Initiate bank transfer via PhonePe Payout API (OAuth2)
     *
     * @param string $payoutTransactionId
     * @param float $amount
     * @param array $bankDetails
     * @param DeliveryBoy $deliveryBoy
     * @return array
     */
    private static function initiateBankTransfer($payoutTransactionId, $amount, $bankDetails, $deliveryBoy)
    {
        try {
            self::initConfig();

            // Use mock mode for local development
            if (self::$mockMode) {
                return self::mockBankTransfer($payoutTransactionId, $amount, $bankDetails, $deliveryBoy);
            }

            // Get OAuth access token
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'error' => 'Failed to authenticate with PhonePe. Please check credentials.'
                ];
            }

            // Convert amount to paise (integer)
            $amountInPaise = (int) ($amount * 100);

            // Build payout payload for PhonePe Disbursement API v2
            $payload = [
                'merchantId' => self::$merchantId,
                'transactionId' => $payoutTransactionId,
                'amount' => $amountInPaise,
                'paymentMode' => 'IMPS',
                'purpose' => 'REIMBURSEMENT',
                'beneficiary' => [
                    'name' => $bankDetails['account_holder_name'],
                    'vpa' => null,
                    'bankAccount' => [
                        'accountNumber' => $bankDetails['account_number'],
                        'ifsc' => $bankDetails['ifsc_code']
                    ],
                    'mobile' => $deliveryBoy->phone ?? null,
                    'email' => $deliveryBoy->email ?? null
                ]
            ];

            $payoutUrl = self::$isProduction ? self::$prodPayoutUrl : self::$uatPayoutUrl;

            Log::info('PhonePe Payout: Initiating disbursement', [
                'payout_transaction_id' => $payoutTransactionId,
                'amount_paise' => $amountInPaise,
                'payment_mode' => 'IMPS',
                'payout_url' => $payoutUrl
            ]);

            // Make API call with OAuth Bearer token
            $ch = curl_init();
            $curlOptions = [
                CURLOPT_URL => $payoutUrl,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => json_encode($payload),
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'Authorization: Bearer ' . $accessToken,
                    'X-MERCHANT-ID: ' . self::$merchantId
                ],
                CURLOPT_TIMEOUT => 60,
                CURLOPT_CONNECTTIMEOUT => 30
            ];

            // Disable SSL verification in non-production (for local development)
            if (!self::$isProduction) {
                $curlOptions[CURLOPT_SSL_VERIFYPEER] = false;
                $curlOptions[CURLOPT_SSL_VERIFYHOST] = 0;
            }

            curl_setopt_array($ch, $curlOptions);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

            if (curl_errno($ch)) {
                $error = curl_error($ch);
                curl_close($ch);

                Log::error('PhonePe Payout: cURL error', [
                    'payout_transaction_id' => $payoutTransactionId,
                    'error' => $error
                ]);

                return [
                    'success' => false,
                    'error' => 'Network error: ' . $error
                ];
            }

            curl_close($ch);

            $responseData = json_decode($response, true);

            Log::info('PhonePe Payout: API response received', [
                'payout_transaction_id' => $payoutTransactionId,
                'http_code' => $httpCode,
                'response' => $responseData
            ]);

            // Check response
            if ($httpCode === 200 && isset($responseData['success']) && $responseData['success']) {
                return [
                    'success' => true,
                    'data' => $responseData['data'] ?? [],
                    'code' => $responseData['code'] ?? '',
                    'message' => $responseData['message'] ?? 'Payout initiated'
                ];
            } else {
                return [
                    'success' => false,
                    'error' => $responseData['message'] ?? 'Payout initiation failed',
                    'code' => $responseData['code'] ?? 'UNKNOWN',
                    'data' => $responseData['data'] ?? null
                ];
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Exception during bank transfer', [
                'payout_transaction_id' => $payoutTransactionId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Bank transfer failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Mock bank transfer for local development/testing
     * Simulates a successful payout without calling the actual PhonePe API
     *
     * @param string $payoutTransactionId
     * @param float $amount
     * @param array $bankDetails
     * @param DeliveryBoy $deliveryBoy
     * @return array
     */
    private static function mockBankTransfer($payoutTransactionId, $amount, $bankDetails, $deliveryBoy)
    {
        Log::info('PhonePe Payout: MOCK MODE - Simulating bank transfer', [
            'payout_transaction_id' => $payoutTransactionId,
            'amount' => $amount,
            'account_holder_name' => $bankDetails['account_holder_name'],
            'account_number_masked' => self::maskAccountNumber($bankDetails['account_number']),
            'ifsc_code' => $bankDetails['ifsc_code'],
            'delivery_boy_id' => $deliveryBoy->id
        ]);

        // Simulate a small delay like a real API call
        usleep(500000); // 0.5 seconds

        // Generate mock UTR (Unique Transaction Reference)
        $mockUtr = 'MOCK' . strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 12));

        $mockResponse = [
            'success' => true,
            'code' => 'SUCCESS',
            'message' => 'MOCK: Payout initiated successfully',
            'data' => [
                'merchantId' => self::$merchantId,
                'merchantTransactionId' => $payoutTransactionId,
                'transactionId' => 'MOCK_TXN_' . time(),
                'amount' => (int) ($amount * 100),
                'state' => 'COMPLETED',
                'paymentMode' => 'IMPS',
                'utr' => $mockUtr,
                'bankAccountDetails' => [
                    'accountHolderName' => $bankDetails['account_holder_name'],
                    'accountNumber' => self::maskAccountNumber($bankDetails['account_number']),
                    'ifsc' => $bankDetails['ifsc_code']
                ],
                'completedAt' => Carbon::now()->toIso8601String(),
                '_mock' => true,
                '_mock_message' => 'This is a simulated response for development. No actual money was transferred.'
            ]
        ];

        Log::info('PhonePe Payout: MOCK MODE - Simulated successful response', [
            'payout_transaction_id' => $payoutTransactionId,
            'mock_utr' => $mockUtr,
            'mock_response' => $mockResponse
        ]);

        return $mockResponse;
    }

    /**
     * Check payout status from PhonePe (OAuth2)
     *
     * @param string $payoutTransactionId
     * @return array
     */
    public static function checkPayoutStatus($payoutTransactionId)
    {
        try {
            self::initConfig();

            Log::info('PhonePe Payout: Checking payout status', [
                'payout_transaction_id' => $payoutTransactionId
            ]);

            // Use mock mode for local development
            if (self::$mockMode) {
                return self::mockCheckPayoutStatus($payoutTransactionId);
            }

            // Get OAuth access token
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'error' => 'Failed to authenticate with PhonePe.'
                ];
            }

            // Build status check URL
            $statusUrl = self::$isProduction ? self::$prodStatusUrl : self::$uatStatusUrl;
            $url = $statusUrl . '/' . self::$merchantId . '/' . $payoutTransactionId;

            // Make API call with OAuth Bearer token
            $ch = curl_init();
            $curlOptions = [
                CURLOPT_URL => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'Authorization: Bearer ' . $accessToken,
                    'X-MERCHANT-ID: ' . self::$merchantId
                ],
                CURLOPT_TIMEOUT => 30
            ];

            // Disable SSL verification in non-production (for local development)
            if (!self::$isProduction) {
                $curlOptions[CURLOPT_SSL_VERIFYPEER] = false;
                $curlOptions[CURLOPT_SSL_VERIFYHOST] = 0;
            }

            curl_setopt_array($ch, $curlOptions);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

            if (curl_errno($ch)) {
                $error = curl_error($ch);
                curl_close($ch);

                Log::error('PhonePe Payout: Status check cURL error', [
                    'payout_transaction_id' => $payoutTransactionId,
                    'error' => $error
                ]);

                return [
                    'success' => false,
                    'error' => 'Network error: ' . $error
                ];
            }

            curl_close($ch);

            $responseData = json_decode($response, true);

            Log::info('PhonePe Payout: Status check response', [
                'payout_transaction_id' => $payoutTransactionId,
                'http_code' => $httpCode,
                'response' => $responseData
            ]);

            if ($httpCode === 200 && isset($responseData['success']) && $responseData['success']) {
                return [
                    'success' => true,
                    'data' => $responseData['data'] ?? [],
                    'code' => $responseData['code'] ?? '',
                    'message' => $responseData['message'] ?? ''
                ];
            } else {
                return [
                    'success' => false,
                    'error' => $responseData['message'] ?? 'Status check failed',
                    'code' => $responseData['code'] ?? 'UNKNOWN'
                ];
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Exception during status check', [
                'payout_transaction_id' => $payoutTransactionId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Status check failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Mock payout status check for local development/testing
     *
     * @param string $payoutTransactionId
     * @return array
     */
    private static function mockCheckPayoutStatus($payoutTransactionId)
    {
        Log::info('PhonePe Payout: MOCK MODE - Checking payout status', [
            'payout_transaction_id' => $payoutTransactionId
        ]);

        // Simulate a small delay
        usleep(200000); // 0.2 seconds

        $mockResponse = [
            'success' => true,
            'code' => 'SUCCESS',
            'message' => 'MOCK: Payout status retrieved successfully',
            'data' => [
                'merchantId' => self::$merchantId,
                'merchantTransactionId' => $payoutTransactionId,
                'transactionId' => 'MOCK_TXN_' . substr(md5($payoutTransactionId), 0, 10),
                'state' => 'COMPLETED',
                'amount' => 0, // Amount would need to be fetched from DB in real scenario
                'paymentMode' => 'IMPS',
                'utr' => 'MOCK' . strtoupper(substr(md5($payoutTransactionId), 0, 12)),
                'completedAt' => Carbon::now()->toIso8601String(),
                '_mock' => true,
                '_mock_message' => 'This is a simulated status response for development.'
            ]
        ];

        Log::info('PhonePe Payout: MOCK MODE - Status check response', [
            'payout_transaction_id' => $payoutTransactionId,
            'mock_response' => $mockResponse
        ]);

        return $mockResponse;
    }

    /**
     * Create payout record and update transactions as settled
     *
     * @param int $deliveryBoyId
     * @param string $payoutTransactionId
     * @param array $transactionIds
     * @param float $amount
     * @param array $payoutResult
     * @return object|null
     */
    private static function createPayoutRecord($deliveryBoyId, $payoutTransactionId, $transactionIds, $amount, $payoutResult, $bankAccountNumber = null)
    {
        try {
            DB::beginTransaction();

            Log::info('PhonePe Payout: Creating payout record', [
                'delivery_boy_id' => $deliveryBoyId,
                'payout_transaction_id' => $payoutTransactionId,
                'transaction_count' => count($transactionIds),
                'amount' => $amount
            ]);

            // Create payout record in delivery_boy_payouts table (if exists)
            // For now, we'll update the transactions directly

            // Mark all selected transactions as settled
            $updatedCount = DB::table('delivery_boy_transactions')
                ->whereIn('id', $transactionIds)
                ->where('delivery_boy_id', $deliveryBoyId)
                ->update([
                    'settled_with_admin' => 1,
                    'settled_at' => Carbon::now(),
                    'payout_reference' => $payoutTransactionId,
                    'bank_acc_number' => $bankAccountNumber,
                    'updated_at' => Carbon::now()
                ]);

            Log::info('PhonePe Payout: Transactions marked as settled', [
                'delivery_boy_id' => $deliveryBoyId,
                'payout_transaction_id' => $payoutTransactionId,
                'updated_count' => $updatedCount,
                'expected_count' => count($transactionIds)
            ]);

            // Create a payout transaction record for tracking
            $payoutRecord = DB::table('delivery_boy_payout_history')->insertGetId([
                'delivery_boy_id' => $deliveryBoyId,
                'payout_transaction_id' => $payoutTransactionId,
                'amount' => $amount,
                'transaction_ids' => json_encode($transactionIds),
                'status' => self::PAYOUT_STATUS_PROCESSING,
                'phonepe_response' => json_encode($payoutResult['data'] ?? []),
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            DB::commit();

            Log::info('PhonePe Payout: Payout record created successfully', [
                'delivery_boy_id' => $deliveryBoyId,
                'payout_record_id' => $payoutRecord,
                'payout_transaction_id' => $payoutTransactionId
            ]);

            return (object) ['id' => $payoutRecord];

        } catch (\Exception $e) {
            DB::rollBack();

            Log::error('PhonePe Payout: Exception creating payout record', [
                'delivery_boy_id' => $deliveryBoyId,
                'payout_transaction_id' => $payoutTransactionId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            // If table doesn't exist, just update transactions without payout_history
            try {
                DB::beginTransaction();

                DB::table('delivery_boy_transactions')
                    ->whereIn('id', $transactionIds)
                    ->where('delivery_boy_id', $deliveryBoyId)
                    ->update([
                        'settled_with_admin' => 1,
                        'settled_at' => Carbon::now(),
                        'bank_acc_number' => $bankAccountNumber,
                        'updated_at' => Carbon::now()
                    ]);

                DB::commit();

                Log::info('PhonePe Payout: Transactions settled (without payout_history)', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'payout_transaction_id' => $payoutTransactionId
                ]);

                return null;

            } catch (\Exception $innerE) {
                DB::rollBack();
                Log::error('PhonePe Payout: Failed to update transactions', [
                    'error' => $innerE->getMessage()
                ]);
                return null;
            }
        }
    }

    /**
     * Handle PhonePe payout callback/webhook
     *
     * @param array $callbackData
     * @return array
     */
    public static function handlePayoutCallback($callbackData)
    {
        try {
            Log::info('PhonePe Payout: Callback received', [
                'callback_data' => $callbackData
            ]);

            // Validate callback checksum
            if (isset($callbackData['response']) && isset($callbackData['checksum'])) {
                $isValid = self::validatePayoutCallback($callbackData['response'], $callbackData['checksum']);

                if (!$isValid) {
                    Log::warning('PhonePe Payout: Invalid callback checksum', [
                        'callback_data' => $callbackData
                    ]);
                    return [
                        'success' => false,
                        'error' => 'Invalid callback checksum'
                    ];
                }
            }

            // Decode response
            $decodedResponse = [];
            if (isset($callbackData['response'])) {
                $decodedResponse = json_decode(base64_decode($callbackData['response']), true);
            }

            $merchantTransactionId = $decodedResponse['merchantTransactionId'] ?? null;
            $payoutStatus = $decodedResponse['state'] ?? $decodedResponse['status'] ?? null;

            Log::info('PhonePe Payout: Callback decoded', [
                'merchant_transaction_id' => $merchantTransactionId,
                'payout_status' => $payoutStatus,
                'decoded_response' => $decodedResponse
            ]);

            if (!$merchantTransactionId) {
                return [
                    'success' => false,
                    'error' => 'Missing merchant transaction ID in callback'
                ];
            }

            // Update payout status
            $updateResult = self::updatePayoutStatus($merchantTransactionId, $payoutStatus, $decodedResponse);

            return $updateResult;

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Exception handling callback', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'callback_data' => $callbackData
            ]);

            return [
                'success' => false,
                'error' => 'Callback processing failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Update payout status based on callback or status check
     *
     * @param string $payoutTransactionId
     * @param string $status
     * @param array $responseData
     * @return array
     */
    public static function updatePayoutStatus($payoutTransactionId, $status, $responseData = [])
    {
        try {
            Log::info('PhonePe Payout: Updating payout status', [
                'payout_transaction_id' => $payoutTransactionId,
                'status' => $status
            ]);

            // Map PhonePe status to our status
            $mappedStatus = self::mapPhonePeStatus($status);

            // Try to update payout_history if exists
            try {
                DB::table('delivery_boy_payout_history')
                    ->where('payout_transaction_id', $payoutTransactionId)
                    ->update([
                        'status' => $mappedStatus,
                        'phonepe_response' => json_encode($responseData),
                        'updated_at' => Carbon::now()
                    ]);
            } catch (\Exception $e) {
                // Table might not exist, ignore
                Log::debug('PhonePe Payout: Could not update payout_history', [
                    'error' => $e->getMessage()
                ]);
            }

            // If payout failed, revert the settled status
            if ($mappedStatus === self::PAYOUT_STATUS_FAILED) {
                try {
                    DB::table('delivery_boy_transactions')
                        ->where('payout_reference', $payoutTransactionId)
                        ->update([
                            'settled_with_admin' => 0,
                            'settled_at' => null,
                            'payout_reference' => null,
                            'updated_at' => Carbon::now()
                        ]);

                    Log::info('PhonePe Payout: Reverted settlement due to failed payout', [
                        'payout_transaction_id' => $payoutTransactionId
                    ]);
                } catch (\Exception $e) {
                    Log::error('PhonePe Payout: Failed to revert settlement', [
                        'payout_transaction_id' => $payoutTransactionId,
                        'error' => $e->getMessage()
                    ]);
                }
            }

            Log::info('PhonePe Payout: Status updated successfully', [
                'payout_transaction_id' => $payoutTransactionId,
                'mapped_status' => $mappedStatus
            ]);

            return [
                'success' => true,
                'status' => $mappedStatus,
                'message' => 'Payout status updated'
            ];

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Exception updating status', [
                'payout_transaction_id' => $payoutTransactionId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to update payout status: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Validate payout callback checksum
     *
     * @param string $base64Response
     * @param string $receivedChecksum
     * @return bool
     */
    private static function validatePayoutCallback($base64Response, $receivedChecksum)
    {
        try {
            self::initConfig();

            $checksumParts = explode('###', $receivedChecksum);
            $receivedHash = $checksumParts[0] ?? '';

            // Use Client Secret for checksum validation
            $checksumString = $base64Response . self::$clientSecret;
            $expectedHash = hash('sha256', $checksumString);

            $isValid = ($receivedHash === $expectedHash);

            Log::info('PhonePe Payout: Callback validation', [
                'is_valid' => $isValid
            ]);

            return $isValid;

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Callback validation failed', [
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Map PhonePe status to internal status
     *
     * @param string $phonePeStatus
     * @return string
     */
    private static function mapPhonePeStatus($phonePeStatus)
    {
        $statusMap = [
            'SUCCESS' => self::PAYOUT_STATUS_SUCCESS,
            'COMPLETED' => self::PAYOUT_STATUS_SUCCESS,
            'FAILED' => self::PAYOUT_STATUS_FAILED,
            'FAILURE' => self::PAYOUT_STATUS_FAILED,
            'REJECTED' => self::PAYOUT_STATUS_FAILED,
            'PENDING' => self::PAYOUT_STATUS_PENDING,
            'PROCESSING' => self::PAYOUT_STATUS_PROCESSING,
            'INITIATED' => self::PAYOUT_STATUS_PROCESSING
        ];

        $upperStatus = strtoupper($phonePeStatus ?? '');
        return $statusMap[$upperStatus] ?? self::PAYOUT_STATUS_PENDING;
    }

    /**
     * Generate unique payout transaction ID
     *
     * @param int $deliveryBoyId
     * @return string
     */
    private static function generatePayoutTransactionId($deliveryBoyId)
    {
        $timestamp = Carbon::now()->format('YmdHis');
        $random = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 6));
        return "PO_{$deliveryBoyId}_{$timestamp}_{$random}";
    }

    /**
     * Mask account number for logging (show last 4 digits)
     *
     * @param string $accountNumber
     * @return string
     */
    private static function maskAccountNumber($accountNumber)
    {
        if (strlen($accountNumber) <= 4) {
            return '****';
        }
        return str_repeat('*', strlen($accountNumber) - 4) . substr($accountNumber, -4);
    }

    /**
     * Validate bank account via IFSC
     *
     * @param string $ifscCode
     * @param string $accountNumber
     * @return array
     */
    public static function validateBankAccount($ifscCode, $accountNumber)
    {
        try {
            Log::info('PhonePe Payout: Validating bank account', [
                'ifsc_code' => $ifscCode,
                'account_number_masked' => self::maskAccountNumber($accountNumber)
            ]);

            // Basic IFSC validation
            if (!preg_match('/^[A-Z]{4}0[A-Z0-9]{6}$/', strtoupper($ifscCode))) {
                return [
                    'success' => false,
                    'error' => 'Invalid IFSC code format'
                ];
            }

            // Account number validation (basic)
            if (!preg_match('/^[0-9]{9,18}$/', $accountNumber)) {
                return [
                    'success' => false,
                    'error' => 'Invalid account number format'
                ];
            }

            return [
                'success' => true,
                'message' => 'Bank account validation passed (basic)'
            ];

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Bank validation exception', [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Validation failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get payout summary for delivery boy
     *
     * @param int $deliveryBoyId
     * @return array
     */
    public static function getPayoutSummary($deliveryBoyId)
    {
        try {
            Log::info('PhonePe Payout: Fetching payout summary', [
                'delivery_boy_id' => $deliveryBoyId
            ]);

            // Get settled amount
            $settledAmount = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->where('is_hand_cash', 0)
                ->where('settled_with_admin', 1)
                ->where('type', '!=', 'incentive')
                ->sum('driver_earnings');

            // Get unsettled amount
            $unsettledAmount = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->where('is_hand_cash', 0)
                ->where(function ($query) {
                    $query->where('settled_with_admin', 0)
                          ->orWhereNull('settled_with_admin');
                })
                ->where('type', '!=', 'incentive')
                ->sum('driver_earnings');

            // Get incentive amount (auto-settled)
            $incentiveAmount = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->where('type', 'incentive')
                ->sum('amount');

            return [
                'success' => true,
                'data' => [
                    'settled_amount' => (float) ($settledAmount ?? 0),
                    'unsettled_amount' => (float) ($unsettledAmount ?? 0),
                    'incentive_amount' => (float) ($incentiveAmount ?? 0),
                    'total_earnings' => (float) (($settledAmount ?? 0) + ($unsettledAmount ?? 0) + ($incentiveAmount ?? 0))
                ]
            ];

        } catch (\Exception $e) {
            Log::error('PhonePe Payout: Exception fetching summary', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to fetch payout summary'
            ];
        }
    }
}
