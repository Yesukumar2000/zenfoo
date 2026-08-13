<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PhonePeRefundService
{
    private $merchantId;
    private $clientId;
    private $clientSecret;
    private $apiBaseUrl;
    private $isProduction;
    private $mockMode;

    public function __construct()
    {
        $this->merchantId = config('services.phonepe.merchant_id', 'M23TSU3JHDUZ0');
        $this->clientId = config('services.phonepe.client_id', 'M23TSU3JHDUZ0_2601211145');
        $this->clientSecret = config('services.phonepe.client_secret', 'MTIyNTBkNTMtNTY3MC00ZWJmLWFjMTYtY2E5ZmNjNTliOWYw');
        $this->isProduction = config('services.phonepe.is_production', false);
        $this->mockMode = config('services.phonepe.mock_mode', false);

        $this->apiBaseUrl = $this->isProduction
            ? 'https://api.phonepe.com/apis/hermes'
            : 'https://api-preprod.phonepe.com/apis/pg-sandbox';
    }

    /**
     * Initiate refund for a PhonePe transaction
     *
     * @param string $originalTransactionId The original merchant transaction ID
     * @param float $amount Amount to refund (in rupees)
     * @param int $orderId Order ID for reference
     * @return array
     */
    public function initiateRefund(string $originalTransactionId, float $amount, int $orderId): array
    {
        try {
            // Generate unique refund transaction ID
            $refundTransactionId = 'REFUND_' . $orderId . '_' . time() . '_' . rand(1000, 9999);

            // Convert amount to paise
            $amountInPaise = (int) ($amount * 100);

            // Create refund payload
            $payload = [
                'merchantId' => $this->merchantId,
                'merchantTransactionId' => $refundTransactionId,
                'originalTransactionId' => $originalTransactionId,
                'amount' => $amountInPaise,
                'callbackUrl' => url('/api/phonepe/refund-callback'),
            ];

            Log::info('PhonePe Refund Initiation:', [
                'refund_transaction_id' => $refundTransactionId,
                'original_transaction_id' => $originalTransactionId,
                'amount' => $amount,
                'order_id' => $orderId,
                'mock_mode' => $this->mockMode,
            ]);

            // Mock mode for local development - simulate successful refund
            if ($this->mockMode) {
                Log::info('PhonePe Refund: Mock mode enabled, simulating successful refund', [
                    'order_id' => $orderId,
                    'refund_transaction_id' => $refundTransactionId,
                ]);

                return [
                    'success' => true,
                    'refund_transaction_id' => $refundTransactionId,
                    'message' => 'Refund initiated successfully (Mock Mode)',
                    'data' => [
                        'merchantId' => $this->merchantId,
                        'merchantTransactionId' => $refundTransactionId,
                        'originalTransactionId' => $originalTransactionId,
                        'amount' => $amountInPaise,
                        'state' => 'COMPLETED',
                        'responseCode' => 'SUCCESS',
                    ],
                ];
            }

            // Encode payload to base64
            $base64Payload = base64_encode(json_encode($payload));

            // Generate checksum for refund endpoint
            $checksum = $this->generateRefundChecksum($base64Payload);

            // Call PhonePe Refund API
            // Disable SSL verification for non-production (local development)
            $httpClient = Http::withHeaders([
                'Content-Type' => 'application/json',
                'X-VERIFY' => $checksum,
            ]);

            if (!$this->isProduction) {
                $httpClient = $httpClient->withoutVerifying();
            }

            $response = $httpClient->post($this->apiBaseUrl . '/pg/v1/refund', [
                'request' => $base64Payload,
            ]);

            $responseData = $response->json();

            Log::info('PhonePe Refund API Response:', [
                'order_id' => $orderId,
                'response' => $responseData,
            ]);

            if ($response->successful() && isset($responseData['success']) && $responseData['success']) {
                return [
                    'success' => true,
                    'refund_transaction_id' => $refundTransactionId,
                    'message' => $responseData['message'] ?? 'Refund initiated successfully',
                    'data' => $responseData['data'] ?? null,
                ];
            } else {
                $errorMessage = $responseData['message'] ?? 'Refund initiation failed';
                $errorCode = $responseData['code'] ?? 'UNKNOWN_ERROR';

                Log::error('PhonePe Refund API Error:', [
                    'order_id' => $orderId,
                    'code' => $errorCode,
                    'message' => $errorMessage,
                ]);

                return [
                    'success' => false,
                    'error' => $errorMessage,
                    'code' => $errorCode,
                ];
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Refund Exception:', [
                'order_id' => $orderId,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return [
                'success' => false,
                'error' => 'Failed to initiate refund: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Check refund status
     *
     * @param string $refundTransactionId
     * @return array
     */
    public function checkRefundStatus(string $refundTransactionId): array
    {
        try {
            $url = $this->apiBaseUrl . '/pg/v1/status/' . $this->merchantId . '/' . $refundTransactionId;

            // Generate checksum for status check
            $checksumString = '/pg/v1/status/' . $this->merchantId . '/' . $refundTransactionId . $this->clientSecret;
            $checksum = hash('sha256', $checksumString) . '###1';

            // Disable SSL verification for non-production (local development)
            $httpClient = Http::withHeaders([
                'Content-Type' => 'application/json',
                'X-VERIFY' => $checksum,
                'X-MERCHANT-ID' => $this->merchantId,
            ]);

            if (!$this->isProduction) {
                $httpClient = $httpClient->withoutVerifying();
            }

            $response = $httpClient->get($url);

            $responseData = $response->json();

            Log::info('PhonePe Refund Status Check Response:', [
                'refund_transaction_id' => $refundTransactionId,
                'response' => $responseData,
            ]);

            if ($response->successful() && isset($responseData['success']) && $responseData['success']) {
                return [
                    'success' => true,
                    'data' => $responseData['data'] ?? null,
                    'code' => $responseData['code'] ?? '',
                    'message' => $responseData['message'] ?? '',
                ];
            } else {
                return [
                    'success' => false,
                    'error' => $responseData['message'] ?? 'Status check failed',
                    'code' => $responseData['code'] ?? 'UNKNOWN',
                ];
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Refund Status Check Exception:', [
                'refund_transaction_id' => $refundTransactionId,
                'message' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * Generate SHA256 checksum for refund endpoint
     *
     * @param string $base64Payload
     * @return string
     */
    private function generateRefundChecksum(string $base64Payload): string
    {
        $string = $base64Payload . '/pg/v1/refund' . $this->clientSecret;
        return hash('sha256', $string) . '###1';
    }
}
