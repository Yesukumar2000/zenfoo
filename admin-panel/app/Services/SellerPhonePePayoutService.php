<?php

namespace App\Services;

use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;

class SellerPhonePePayoutService
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
     */
    private static function initConfig()
    {
        self::$merchantId = config('services.phonepe.merchant_id', 'M23TSU3JHDUZ0');
        self::$clientId = config('services.phonepe.client_id', 'M23TSU3JHDUZ0_2601211145');
        self::$clientSecret = config('services.phonepe.client_secret', 'MTIyNTBkNTMtNTY3MC00ZWJmLWFjMTYtY2E5ZmNjNTliOWYw');
        self::$isProduction = config('services.phonepe.is_production', false);
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
     * Process payout to seller's bank account
     */
    public static function processPayoutToSeller($sellerId, $transactionIds, $totalAmount)
    {
        try {
            self::initConfig();

            Log::info('Seller PhonePe Payout: Starting payout process', [
                'seller_id' => $sellerId,
                'transaction_ids' => $transactionIds,
                'total_amount' => $totalAmount
            ]);

            // Validate input
            if (empty($transactionIds)) {
                return [
                    'success' => false,
                    'error' => 'No transactions selected for payout'
                ];
            }

            if ($totalAmount <= 0) {
                return [
                    'success' => false,
                    'error' => 'Invalid payout amount'
                ];
            }

            // Get seller details
            $seller = Seller::find($sellerId);
            if (!$seller) {
                return [
                    'success' => false,
                    'error' => 'Seller not found'
                ];
            }

            // Get bank details
            $bankDetails = self::getSellerBankDetails($sellerId);
            if (!$bankDetails['success']) {
                return $bankDetails;
            }

            // Generate unique payout transaction ID
            $payoutTransactionId = self::generatePayoutTransactionId($sellerId);

            Log::info('Seller PhonePe Payout: Bank details retrieved', [
                'seller_id' => $sellerId,
                'payout_transaction_id' => $payoutTransactionId,
                'bank_name' => $bankDetails['data']['bank_name'],
                'account_holder_name' => $bankDetails['data']['account_holder_name'],
                'account_number_masked' => self::maskAccountNumber($bankDetails['data']['account_number']),
                'ifsc_code' => $bankDetails['data']['ifsc_code']
            ]);

            // Initiate the payout
            $payoutResult = self::initiateBankTransfer(
                $payoutTransactionId,
                $totalAmount,
                $bankDetails['data'],
                $seller
            );

            if (!$payoutResult['success']) {
                Log::error('Seller PhonePe Payout: Bank transfer initiation failed', [
                    'seller_id' => $sellerId,
                    'payout_transaction_id' => $payoutTransactionId,
                    'error' => $payoutResult['error']
                ]);
                return $payoutResult;
            }

            // Create payout record and mark transactions as paid
            $payoutRecord = self::createPayoutRecord(
                $sellerId,
                $payoutTransactionId,
                $transactionIds,
                $totalAmount,
                $payoutResult
            );

            Log::info('Seller PhonePe Payout: Payout initiated successfully', [
                'seller_id' => $sellerId,
                'payout_transaction_id' => $payoutTransactionId,
                'amount' => $totalAmount
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
            Log::error('Seller PhonePe Payout: Exception during payout process', [
                'seller_id' => $sellerId,
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
     * Get bank details for seller from seller_bank_accounts table
     */
    public static function getSellerBankDetails($sellerId)
    {
        try {
            Log::info('Seller PhonePe Payout: Fetching bank details', [
                'seller_id' => $sellerId
            ]);

            $bankDetails = DB::table('seller_bank_accounts')
                ->where('seller_id', $sellerId)
                ->where('is_default', 1)
                ->select([
                    'bank_name',
                    'account_holder_name',
                    'account_number',
                    'ifsc_code',
                    'is_verified'
                ])
                ->first();

            if (!$bankDetails) {
                // Try to get any bank account if no default is set
                $bankDetails = DB::table('seller_bank_accounts')
                    ->where('seller_id', $sellerId)
                    ->select([
                        'bank_name',
                        'account_holder_name',
                        'account_number',
                        'ifsc_code',
                        'is_verified'
                    ])
                    ->first();
            }

            if (!$bankDetails) {
                Log::warning('Seller PhonePe Payout: No bank details found', [
                    'seller_id' => $sellerId
                ]);
                return [
                    'success' => false,
                    'error' => 'Bank details not found for this seller. Please add bank account first.'
                ];
            }

            // Validate required fields
            $requiredFields = ['bank_name', 'account_holder_name', 'account_number', 'ifsc_code'];
            foreach ($requiredFields as $field) {
                if (empty($bankDetails->$field)) {
                    return [
                        'success' => false,
                        'error' => 'Missing required bank detail: ' . str_replace('_', ' ', $field)
                    ];
                }
            }

            // Validate IFSC code format (11 characters)
            if (strlen($bankDetails->ifsc_code) !== 11) {
                return [
                    'success' => false,
                    'error' => 'Invalid IFSC code format'
                ];
            }

            return [
                'success' => true,
                'data' => [
                    'bank_name' => $bankDetails->bank_name,
                    'account_holder_name' => $bankDetails->account_holder_name,
                    'account_number' => $bankDetails->account_number,
                    'ifsc_code' => $bankDetails->ifsc_code,
                    'is_verified' => $bankDetails->is_verified ?? false
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Seller PhonePe Payout: Exception fetching bank details', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to fetch bank details: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Initiate bank transfer via PhonePe Payout API (OAuth2)
     */
    private static function initiateBankTransfer($payoutTransactionId, $amount, $bankDetails, $seller)
    {
        try {
            self::initConfig();

            // Use mock mode for local development
            if (self::$mockMode) {
                return self::mockBankTransfer($payoutTransactionId, $amount, $bankDetails, $seller);
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
                    'mobile' => $seller->phone ?? null,
                    'email' => $seller->email ?? null
                ]
            ];

            $payoutUrl = self::$isProduction ? self::$prodPayoutUrl : self::$uatPayoutUrl;

            Log::info('PhonePe Payout: Initiating disbursement', [
                'payout_transaction_id' => $payoutTransactionId,
                'amount_paise' => $amountInPaise,
                'payout_url' => $payoutUrl
            ]);

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
                return [
                    'success' => false,
                    'error' => 'Network error: ' . $error
                ];
            }

            curl_close($ch);
            $responseData = json_decode($response, true);

            Log::info('PhonePe Payout: Disbursement response', [
                'payout_transaction_id' => $payoutTransactionId,
                'http_code' => $httpCode,
                'response' => $responseData
            ]);

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
                    'code' => $responseData['code'] ?? 'UNKNOWN'
                ];
            }

        } catch (\Exception $e) {
            return [
                'success' => false,
                'error' => 'Bank transfer failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Mock bank transfer for local development/testing
     */
    private static function mockBankTransfer($payoutTransactionId, $amount, $bankDetails, $seller)
    {
        Log::info('Seller PhonePe Payout: MOCK MODE - Simulating bank transfer', [
            'payout_transaction_id' => $payoutTransactionId,
            'amount' => $amount,
            'seller_id' => $seller->id
        ]);

        // Simulate a small delay
        usleep(500000); // 0.5 seconds

        // Generate mock UTR
        $mockUtr = 'MOCK' . strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 12));

        $mockResponse = [
            'success' => true,
            'code' => 'SUCCESS',
            'message' => 'MOCK: Payout initiated successfully',
            'data' => [
                'merchantId' => self::$merchantId,
                'transactionId' => $payoutTransactionId,
                'providerTransactionId' => 'MOCK_TXN_' . time(),
                'amount' => (int) ($amount * 100),
                'state' => 'COMPLETED',
                'paymentMode' => 'IMPS',
                'utr' => $mockUtr,
                'beneficiary' => [
                    'name' => $bankDetails['account_holder_name'],
                    'accountNumber' => self::maskAccountNumber($bankDetails['account_number']),
                    'ifsc' => $bankDetails['ifsc_code']
                ],
                'completedAt' => Carbon::now()->toIso8601String(),
                '_mock' => true,
                '_mock_message' => 'This is a simulated response for development.'
            ]
        ];

        return $mockResponse;
    }

    /**
     * Create payout record and update transactions as paid
     */
    private static function createPayoutRecord($sellerId, $payoutTransactionId, $transactionIds, $amount, $payoutResult)
    {
        try {
            DB::beginTransaction();

            // Mark all selected transactions as paid
            SellerWalletTransaction::whereIn('id', $transactionIds)
                ->where('seller_id', $sellerId)
                ->update([
                    'is_paid_to_seller' => true,
                    'payment_transaction_id' => $payoutTransactionId,
                    'paid_at' => Carbon::now(),
                    'paid_by' => auth()->id()
                ]);

            // Try to create payout history record if table exists
            try {
                DB::table('seller_payout_history')->insert([
                    'seller_id' => $sellerId,
                    'payout_transaction_id' => $payoutTransactionId,
                    'amount' => $amount,
                    'transaction_ids' => json_encode($transactionIds),
                    'status' => self::PAYOUT_STATUS_PROCESSING,
                    'phonepe_response' => json_encode($payoutResult['data'] ?? []),
                    'created_at' => Carbon::now(),
                    'updated_at' => Carbon::now()
                ]);
            } catch (\Exception $e) {
                // Table might not exist, continue without it
                Log::debug('Seller payout_history table not found, skipping', [
                    'error' => $e->getMessage()
                ]);
            }

            DB::commit();

            Log::info('Seller PhonePe Payout: Transactions marked as paid', [
                'seller_id' => $sellerId,
                'payout_transaction_id' => $payoutTransactionId,
                'transaction_count' => count($transactionIds)
            ]);

            return true;

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Seller PhonePe Payout: Failed to create payout record', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Generate unique payout transaction ID
     */
    private static function generatePayoutTransactionId($sellerId)
    {
        $timestamp = Carbon::now()->format('YmdHis');
        $random = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 6));
        return "SPO_{$sellerId}_{$timestamp}_{$random}";
    }

    /**
     * Mask account number for logging (show last 4 digits)
     */
    private static function maskAccountNumber($accountNumber)
    {
        if (strlen($accountNumber) <= 4) {
            return '****';
        }
        return str_repeat('*', strlen($accountNumber) - 4) . substr($accountNumber, -4);
    }
}
