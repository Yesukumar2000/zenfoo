<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

class PhonePePaymentCaptureService
{
    private static $merchantId;
    private static $clientId;
    private static $clientSecret;
    private static $clientVersion;
    private static $mode; // 'sandbox' or 'production'

    private static $sandboxUrl = 'https://api-preprod.phonepe.com/apis/pg-sandbox';
    private static $productionUrl = 'https://api.phonepe.com/apis/hermes';

    /**
     * Initialize PhonePe configuration from database
     */
    private static function initConfig()
    {
        // Get credentials from settings table
        $settings = DB::table('settings')
            ->whereIn('variable', [
                'phonepay_merchant_id',
                'phonepay_client_id',
                'phonepay_client_secret',
                'phonepay_client_version',
                'phonepay_mode'
            ])
            ->pluck('value', 'variable');

        self::$merchantId = $settings['phonepay_merchant_id'] ?? null;
        self::$clientId = $settings['phonepay_client_id'] ?? null;
        self::$clientSecret = $settings['phonepay_client_secret'] ?? null;
        self::$clientVersion = $settings['phonepay_client_version'] ?? '1';
        self::$mode = $settings['phonepay_mode'] ?? 'sandbox';
    }

    /**
     * Get base URL based on mode
     */
    private static function getBaseUrl()
    {
        return self::$mode === 'production' ? self::$productionUrl : self::$sandboxUrl;
    }

    /**
     * Get access token (with caching)
     */
    private static function getAccessToken()
    {
        self::initConfig();

        // Check cache first
        $cachedToken = Cache::get('phonepe_access_token');
        if ($cachedToken) {
            return $cachedToken;
        }

        // Check database cache
        $dbCache = DB::table('settings')
            ->where('variable', 'phonepay_access_token_cache')
            ->first();

        if ($dbCache && $dbCache->value) {
            $tokenData = json_decode($dbCache->value, true);
            if (isset($tokenData['access_token']) && isset($tokenData['expires_at'])) {
                if (time() < $tokenData['expires_at']) {
                    Cache::put('phonepe_access_token', $tokenData['access_token'], $tokenData['expires_at'] - time());
                    return $tokenData['access_token'];
                }
            }
        }

        // Get new access token
        $newToken = self::fetchNewAccessToken();
        return $newToken;
    }

    /**
     * Fetch new access token from PhonePe
     */
    private static function fetchNewAccessToken()
    {
        self::initConfig();

        if (empty(self::$clientId) || empty(self::$clientSecret)) {
            Log::error('PhonePe: Client credentials not configured');
            return null;
        }

        $url = self::getBaseUrl() . '/v1/oauth/token';

        try {
            $response = Http::withoutVerifying()->asForm()->post($url, [
                'client_id' => self::$clientId,
                'client_version' => self::$clientVersion,
                'client_secret' => self::$clientSecret,
                'grant_type' => 'client_credentials'
            ]);

            $data = $response->json();

            Log::info('PhonePe: Access token response', ['response' => $data]);

            if ($response->successful() && isset($data['access_token'])) {
                $expiresIn = $data['expires_in'] ?? 3600;
                $expiresAt = time() + $expiresIn - 60; // 60 seconds buffer

                // Cache in memory
                Cache::put('phonepe_access_token', $data['access_token'], $expiresIn - 60);

                // Cache in database
                $cacheData = json_encode([
                    'access_token' => $data['access_token'],
                    'expires_at' => $expiresAt
                ]);

                DB::table('settings')
                    ->updateOrInsert(
                        ['variable' => 'phonepay_access_token_cache'],
                        ['value' => $cacheData]
                    );

                return $data['access_token'];
            }

            Log::error('PhonePe: Failed to get access token', ['response' => $data]);
            return null;

        } catch (\Exception $e) {
            Log::error('PhonePe: Access token exception', ['error' => $e->getMessage()]);
            return null;
        }
    }

    /**
     * Make authenticated API request to PhonePe
     */
    private static function makeRequest($method, $endpoint, $data = [])
    {
        self::initConfig();

        $accessToken = self::getAccessToken();
        if (!$accessToken) {
            return [
                'success' => false,
                'error' => 'Failed to get PhonePe access token'
            ];
        }

        $url = self::getBaseUrl() . $endpoint;

        Log::info('PhonePe API Request', [
            'method' => $method,
            'url' => $url,
            'data' => $data
        ]);

        try {
            $response = Http::withToken($accessToken)
                ->withHeaders([
                    'Content-Type' => 'application/json',
                    'X-MERCHANT-ID' => self::$merchantId
                ])
                ->withoutVerifying() // Bypass SSL verification for local development
                ->timeout(60);

            if ($method === 'POST') {
                $response = $response->post($url, $data);
            } elseif ($method === 'GET') {
                $response = $response->get($url, $data);
            }

            $responseData = $response->json();

            Log::info('PhonePe API Response', [
                'status' => $response->status(),
                'response' => $responseData
            ]);

            if ($response->successful()) {
                return [
                    'success' => true,
                    'data' => $responseData
                ];
            } else {
                return [
                    'success' => false,
                    'error' => $responseData['message'] ?? 'API request failed',
                    'code' => $responseData['code'] ?? 'UNKNOWN',
                    'data' => $responseData
                ];
            }
        } catch (\Exception $e) {
            Log::error('PhonePe API Exception', ['error' => $e->getMessage()]);
            return [
                'success' => false,
                'error' => 'Network error: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Check payment status by transaction ID
     *
     * @param string $transactionId PhonePe transaction/order ID
     * @return array
     */
    public static function checkPaymentStatus($transactionId)
    {
        self::initConfig();

        Log::info('PhonePe: Checking payment status', ['transaction_id' => $transactionId]);

        $endpoint = '/pg/v1/status/' . self::$merchantId . '/' . $transactionId;

        $result = self::makeRequest('GET', $endpoint);

        if ($result['success'] && isset($result['data']['data'])) {
            $paymentData = $result['data']['data'];
            return [
                'success' => true,
                'data' => [
                    'transaction_id' => $paymentData['merchantTransactionId'] ?? $transactionId,
                    'phonepe_transaction_id' => $paymentData['transactionId'] ?? null,
                    'amount' => isset($paymentData['amount']) ? $paymentData['amount'] / 100 : 0, // Convert paise to rupees
                    'status' => $paymentData['state'] ?? $paymentData['code'] ?? 'UNKNOWN',
                    'payment_instrument' => $paymentData['paymentInstrument'] ?? null,
                    'response_code' => $result['data']['code'] ?? null
                ]
            ];
        }

        return $result;
    }

    /**
     * Verify payment is successful
     *
     * @param string $transactionId PhonePe transaction/order ID
     * @param float|null $expectedAmount Optional expected amount to verify
     * @return array
     */
    public static function verifyPayment($transactionId, $expectedAmount = null)
    {
        Log::info('PhonePe: Verifying payment', [
            'transaction_id' => $transactionId,
            'expected_amount' => $expectedAmount
        ]);

        $statusResult = self::checkPaymentStatus($transactionId);

        if (!$statusResult['success']) {
            return $statusResult;
        }

        $payment = $statusResult['data'];
        $status = strtoupper($payment['status']);

        // Check if payment is successful
        $successStatuses = ['COMPLETED', 'SUCCESS', 'PAYMENT_SUCCESS'];
        $isSuccess = in_array($status, $successStatuses);

        if (!$isSuccess) {
            return [
                'success' => false,
                'error' => 'Payment not successful. Current status: ' . $status,
                'data' => $payment
            ];
        }

        // Verify amount if provided
        if ($expectedAmount !== null && abs($payment['amount'] - $expectedAmount) > 0.01) {
            return [
                'success' => false,
                'error' => 'Amount mismatch. Expected: ' . $expectedAmount . ', Actual: ' . $payment['amount'],
                'data' => $payment
            ];
        }

        return [
            'success' => true,
            'message' => 'Payment verified successfully',
            'data' => $payment,
            'captured' => true // PhonePe auto-captures
        ];
    }

    /**
     * Check if payment is valid and successful
     *
     * @param string $transactionId PhonePe transaction ID
     * @return array
     */
    public static function isPaymentValid($transactionId)
    {
        $statusResult = self::checkPaymentStatus($transactionId);

        if (!$statusResult['success']) {
            return [
                'valid' => false,
                'error' => $statusResult['error']
            ];
        }

        $payment = $statusResult['data'];
        $status = strtoupper($payment['status']);

        $successStatuses = ['COMPLETED', 'SUCCESS', 'PAYMENT_SUCCESS'];
        $isValid = in_array($status, $successStatuses);

        return [
            'valid' => $isValid,
            'status' => $status,
            'amount' => $payment['amount'],
            'data' => $payment
        ];
    }
}