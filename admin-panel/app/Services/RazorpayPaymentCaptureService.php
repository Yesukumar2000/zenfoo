<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class RazorpayPaymentCaptureService
{
    private static $keyId;
    private static $keySecret;
    private static $baseUrl = 'https://api.razorpay.com/v1';

    /**
     * Initialize Razorpay configuration from database
     */
    private static function initConfig()
    {
        // Get credentials from settings table
        $settings = DB::table('settings')
            ->whereIn('variable', ['razorpay_key', 'razorpay_secret_key'])
            ->pluck('value', 'variable');

        self::$keyId = $settings['razorpay_key'] ?? null;
        self::$keySecret = $settings['razorpay_secret_key'] ?? null;
    }

    /**
     * Make API request to Razorpay
     */
    private static function makeRequest($method, $endpoint, $data = [])
    {
        self::initConfig();

        if (empty(self::$keyId) || empty(self::$keySecret)) {
            return [
                'success' => false,
                'error' => 'Razorpay credentials not configured'
            ];
        }

        $url = self::$baseUrl . $endpoint;

        Log::info('Razorpay API Request', [
            'method' => $method,
            'url' => $url,
            'data' => $data
        ]);

        try {
            $response = Http::withBasicAuth(self::$keyId, self::$keySecret)
                ->withHeaders(['Content-Type' => 'application/json'])
                ->withoutVerifying() // Bypass SSL verification for local development
                ->timeout(60);

            if ($method === 'POST') {
                $response = $response->post($url, $data);
            } elseif ($method === 'GET') {
                $response = $response->get($url, $data);
            }

            $responseData = $response->json();

            Log::info('Razorpay API Response', [
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
            Log::error('Razorpay API Exception', ['error' => $e->getMessage()]);
            return [
                'success' => false,
                'error' => 'Network error: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Fetch payment details by payment ID
     *
     * @param string $paymentId Razorpay payment ID (pay_xxx)
     * @return array
     */
    public static function fetchPayment($paymentId)
    {
        Log::info('Razorpay: Fetching payment', ['payment_id' => $paymentId]);

        $result = self::makeRequest('GET', '/payments/' . $paymentId);

        if ($result['success']) {
            return [
                'success' => true,
                'data' => [
                    'payment_id' => $result['data']['id'],
                    'amount' => $result['data']['amount'] / 100, // Convert paise to rupees
                    'currency' => $result['data']['currency'],
                    'status' => $result['data']['status'],
                    'captured' => $result['data']['captured'] ?? false,
                    'method' => $result['data']['method'],
                    'email' => $result['data']['email'] ?? null,
                    'contact' => $result['data']['contact'] ?? null,
                    'created_at' => $result['data']['created_at']
                ]
            ];
        }

        return $result;
    }

    /**
     * Capture a payment
     *
     * @param string $paymentId Razorpay payment ID (pay_xxx)
     * @param float $amount Amount to capture in rupees
     * @return array
     */
    public static function capturePayment($paymentId, $amount)
    {
        Log::info('Razorpay: Capturing payment', [
            'payment_id' => $paymentId,
            'amount' => $amount
        ]);

        // Convert to paise
        $amountInPaise = (int) ($amount * 100);

        $result = self::makeRequest('POST', '/payments/' . $paymentId . '/capture', [
            'amount' => $amountInPaise,
            'currency' => 'INR'
        ]);

        if ($result['success']) {
            return [
                'success' => true,
                'message' => 'Payment captured successfully',
                'data' => [
                    'payment_id' => $result['data']['id'],
                    'amount' => $result['data']['amount'] / 100,
                    'status' => $result['data']['status'],
                    'captured' => true
                ]
            ];
        }

        return $result;
    }

    /**
     * Verify and capture payment if not already captured
     *
     * @param string $paymentId Razorpay payment ID
     * @param float|null $expectedAmount Optional expected amount to verify
     * @return array
     */
    public static function verifyAndCapture($paymentId, $expectedAmount = null)
    {
        Log::info('Razorpay: Verify and capture', [
            'payment_id' => $paymentId,
            'expected_amount' => $expectedAmount
        ]);

        // First fetch the payment details
        $fetchResult = self::fetchPayment($paymentId);

        if (!$fetchResult['success']) {
            return $fetchResult;
        }

        $payment = $fetchResult['data'];

        // Check if payment is already captured
        if ($payment['captured']) {
            Log::info('Razorpay: Payment already captured', ['payment_id' => $paymentId]);
            return [
                'success' => true,
                'message' => 'Payment already captured',
                'data' => $payment,
                'already_captured' => true
            ];
        }

        // Check if payment status is authorized (ready to capture)
        if ($payment['status'] !== 'authorized') {
            return [
                'success' => false,
                'error' => 'Payment is not in authorized state. Current status: ' . $payment['status'],
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

        // Capture the payment
        $captureResult = self::capturePayment($paymentId, $payment['amount']);

        if ($captureResult['success']) {
            $captureResult['already_captured'] = false;
        }

        return $captureResult;
    }

    /**
     * Check if payment is valid and captured/successful
     *
     * @param string $paymentId Razorpay payment ID
     * @return array
     */
    public static function isPaymentValid($paymentId)
    {
        $fetchResult = self::fetchPayment($paymentId);

        if (!$fetchResult['success']) {
            return [
                'valid' => false,
                'error' => $fetchResult['error']
            ];
        }

        $payment = $fetchResult['data'];

        // Payment is valid if status is 'captured'
        $isValid = $payment['status'] === 'captured' && $payment['captured'] === true;

        return [
            'valid' => $isValid,
            'status' => $payment['status'],
            'amount' => $payment['amount'],
            'data' => $payment
        ];
    }
}