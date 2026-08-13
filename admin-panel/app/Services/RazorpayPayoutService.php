<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class RazorpayPayoutService
{
    // RazorpayX API credentials
    private static $keyId;
    private static $keySecret;
    private static $accountNumber;
    private static $isProduction;
    private static $mockMode;

    // RazorpayX API URLs
    private static $baseUrl = 'https://api.razorpay.com/v1';

    // Payout status constants
    const PAYOUT_STATUS_PENDING = 'pending';
    const PAYOUT_STATUS_PROCESSING = 'processing';
    const PAYOUT_STATUS_PROCESSED = 'processed';
    const PAYOUT_STATUS_REVERSED = 'reversed';
    const PAYOUT_STATUS_FAILED = 'failed';

    /**
     * Initialize RazorpayX configuration
     */
    private static function initConfig()
    {
        self::$keyId = config('services.razorpayx.key_id');
        self::$keySecret = config('services.razorpayx.key_secret');
        self::$accountNumber = config('services.razorpayx.account_number');
        self::$isProduction = config('services.razorpayx.is_production', false);
        self::$mockMode = config('services.razorpayx.mock_mode', true);
    }

    /**
     * Make API request to RazorpayX
     */
    private static function makeRequest($method, $endpoint, $data = [])
    {
        self::initConfig();

        $url = self::$baseUrl . $endpoint;

        Log::info('RazorpayX API Request', [
            'method' => $method,
            'url' => $url,
            'data' => $data
        ]);

        try {
            $response = Http::withBasicAuth(self::$keyId, self::$keySecret)
                ->withHeaders([
                    'Content-Type' => 'application/json',
                ])
                ->timeout(60);

            if ($method === 'POST') {
                $response = $response->post($url, $data);
            } elseif ($method === 'GET') {
                $response = $response->get($url, $data);
            }

            $responseData = $response->json();

            Log::info('RazorpayX API Response', [
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
                    'error' => $responseData['error']['description'] ?? 'API request failed',
                    'code' => $responseData['error']['code'] ?? 'UNKNOWN',
                    'data' => $responseData
                ];
            }
        } catch (\Exception $e) {
            Log::error('RazorpayX API Exception', [
                'error' => $e->getMessage()
            ]);
            return [
                'success' => false,
                'error' => 'Network error: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Create a payout using Composite API (creates contact + fund account + payout in one call)
     *
     * @param array $beneficiary Beneficiary details (name, email, phone, account_number, ifsc)
     * @param float $amount Amount in rupees
     * @param string $purpose Purpose of payout
     * @param string $referenceId Unique reference ID
     * @return array
     */
    public static function createPayout($beneficiary, $amount, $purpose = 'payout', $referenceId = null)
    {
        self::initConfig();

        // Use mock mode for testing
        if (self::$mockMode) {
            return self::mockCreatePayout($beneficiary, $amount, $purpose, $referenceId);
        }

        // Validate credentials
        if (empty(self::$keyId) || empty(self::$keySecret) || empty(self::$accountNumber)) {
            return [
                'success' => false,
                'error' => 'RazorpayX credentials not configured. Please add RAZORPAYX_KEY_ID, RAZORPAYX_KEY_SECRET, and RAZORPAYX_ACCOUNT_NUMBER in .env file.'
            ];
        }

        // Convert amount to paise
        $amountInPaise = (int) ($amount * 100);

        // Generate unique reference ID if not provided
        if (!$referenceId) {
            $referenceId = 'PAYOUT_' . time() . '_' . mt_rand(1000, 9999);
        }

        // Build composite payout request
        $payload = [
            'account_number' => self::$accountNumber,
            'amount' => $amountInPaise,
            'currency' => 'INR',
            'mode' => 'IMPS',
            'purpose' => $purpose,
            'reference_id' => $referenceId,
            'narration' => substr($beneficiary['narration'] ?? 'Payout', 0, 30),
            'fund_account' => [
                'account_type' => 'bank_account',
                'bank_account' => [
                    'name' => $beneficiary['name'],
                    'ifsc' => $beneficiary['ifsc'],
                    'account_number' => $beneficiary['account_number']
                ],
                'contact' => [
                    'name' => $beneficiary['name'],
                    'email' => $beneficiary['email'] ?? null,
                    'contact' => $beneficiary['phone'] ?? null,
                    'type' => $beneficiary['type'] ?? 'vendor'
                ]
            ]
        ];

        // Remove null values from contact
        $payload['fund_account']['contact'] = array_filter($payload['fund_account']['contact']);

        Log::info('RazorpayX Payout: Creating composite payout', [
            'reference_id' => $referenceId,
            'amount' => $amount,
            'beneficiary_name' => $beneficiary['name']
        ]);

        $result = self::makeRequest('POST', '/payouts', $payload);

        if ($result['success']) {
            return [
                'success' => true,
                'message' => 'Payout initiated successfully',
                'data' => [
                    'payout_id' => $result['data']['id'],
                    'reference_id' => $referenceId,
                    'amount' => $amount,
                    'status' => $result['data']['status'],
                    'utr' => $result['data']['utr'] ?? null,
                    'fund_account_id' => $result['data']['fund_account_id'] ?? null
                ]
            ];
        }

        return $result;
    }

    /**
     * Get payout status by payout ID
     */
    public static function getPayoutStatus($payoutId)
    {
        self::initConfig();

        if (self::$mockMode) {
            return self::mockGetPayoutStatus($payoutId);
        }

        return self::makeRequest('GET', '/payouts/' . $payoutId);
    }

    /**
     * Mock payout creation for testing
     */
    private static function mockCreatePayout($beneficiary, $amount, $purpose, $referenceId)
    {
        Log::info('RazorpayX Payout: MOCK MODE - Simulating payout', [
            'beneficiary' => $beneficiary['name'],
            'amount' => $amount,
            'reference_id' => $referenceId
        ]);

        usleep(500000); // 0.5 second delay

        $mockPayoutId = 'pout_mock_' . strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 14));
        $mockUtr = 'MOCK' . strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 12));

        $mockResponse = [
            'success' => true,
            'message' => 'MOCK: Payout initiated successfully',
            'data' => [
                'payout_id' => $mockPayoutId,
                'reference_id' => $referenceId ?? 'PAYOUT_' . time(),
                'amount' => $amount,
                'status' => 'processed',
                'utr' => $mockUtr,
                'fund_account_id' => 'fa_mock_' . substr(md5(uniqid()), 0, 14),
                '_mock' => true,
                '_mock_message' => 'This is a simulated payout for testing. No actual money was transferred.'
            ]
        ];

        Log::info('RazorpayX Payout: MOCK MODE - Simulated response', $mockResponse);

        return $mockResponse;
    }

    /**
     * Mock get payout status
     */
    private static function mockGetPayoutStatus($payoutId)
    {
        Log::info('RazorpayX Payout: MOCK MODE - Checking status', [
            'payout_id' => $payoutId
        ]);

        return [
            'success' => true,
            'data' => [
                'id' => $payoutId,
                'status' => 'processed',
                'utr' => 'MOCK' . strtoupper(substr(md5($payoutId), 0, 12)),
                '_mock' => true
            ]
        ];
    }

    /**
     * Map Razorpay status to internal status
     */
    public static function mapStatus($razorpayStatus)
    {
        $statusMap = [
            'pending' => self::PAYOUT_STATUS_PENDING,
            'queued' => self::PAYOUT_STATUS_PENDING,
            'processing' => self::PAYOUT_STATUS_PROCESSING,
            'processed' => self::PAYOUT_STATUS_PROCESSED,
            'reversed' => self::PAYOUT_STATUS_REVERSED,
            'failed' => self::PAYOUT_STATUS_FAILED,
            'cancelled' => self::PAYOUT_STATUS_FAILED,
            'rejected' => self::PAYOUT_STATUS_FAILED
        ];

        return $statusMap[strtolower($razorpayStatus)] ?? self::PAYOUT_STATUS_PENDING;
    }
}
