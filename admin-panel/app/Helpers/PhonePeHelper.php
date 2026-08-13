<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Log;

class PhonePeHelper
{
    // PhonePe API credentials
    private static $merchantId = 'PGTESTPAYUAT';
    private static $saltKey = '96434309-7796-489d-8924-ab56988a6076';
    private static $saltIndex = '1';

    // API URLs
    private static $uatBaseUrl = 'https://api-preprod.phonepe.com/apis/pg-sandbox';
    private static $prodBaseUrl = 'https://api.phonepe.com/apis/hermes';

    /**
     * Create PhonePe transaction body and checksum
     *
     * @param array $data Transaction data containing amount, merchantTransactionId, merchantUserId, etc.
     * @return array ['body' => base64_encoded_payload, 'checksum' => sha256_checksum]
     */
    public static function createTransaction($data)
    {
        try {
            // Ensure amount is in paise (integer)
            $amount = (int) $data['amount'];

            // Build payload
            $payload = [
                'merchantId' => self::$merchantId,
                'merchantTransactionId' => $data['merchantTransactionId'],
                'merchantUserId' => $data['merchantUserId'],
                'amount' => $amount,
                'redirectUrl' => $data['redirectUrl'] ?? '',
                'redirectMode' => 'POST',
                'callbackUrl' => $data['callbackUrl'] ?? '',
                'mobileNumber' => $data['mobileNumber'] ?? '',
                'paymentInstrument' => [
                    'type' => 'PAY_PAGE'
                ]
            ];

            // Encode payload to JSON then base64
            $jsonPayload = json_encode($payload);
            $base64Payload = base64_encode($jsonPayload);

            // Generate checksum: SHA256(base64_payload + "/pg/v1/pay" + salt_key) + ### + salt_index
            $checksumString = $base64Payload . '/pg/v1/pay' . self::$saltKey;
            $sha256Hash = hash('sha256', $checksumString);
            $checksum = $sha256Hash . '###' . self::$saltIndex;

            Log::info('PhonePe Transaction Created', [
                'merchantTransactionId' => $data['merchantTransactionId'],
                'amount' => $amount,
                'payload' => $jsonPayload
            ]);

            return [
                'success' => true,
                'body' => $base64Payload,
                'checksum' => $checksum,
                'payload' => $payload
            ];

        } catch (\Exception $e) {
            Log::error('PhonePe Transaction Creation Failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Verify PhonePe transaction status
     *
     * @param string $merchantTransactionId
     * @param bool $isProduction
     * @return array Transaction status response
     */
    public static function verifyTransaction($merchantTransactionId, $isProduction = false)
    {
        try {
            // Build status check URL
            $baseUrl = $isProduction ? self::$prodBaseUrl : self::$uatBaseUrl;
            $url = $baseUrl . '/pg/v1/status/' . self::$merchantId . '/' . $merchantTransactionId;

            // Generate checksum for status check: SHA256("/pg/v1/status/{merchantId}/{merchantTransactionId}" + salt_key) + ### + salt_index
            $checksumString = '/pg/v1/status/' . self::$merchantId . '/' . $merchantTransactionId . self::$saltKey;
            $sha256Hash = hash('sha256', $checksumString);
            $checksum = $sha256Hash . '###' . self::$saltIndex;

            // Make API call
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'X-VERIFY: ' . $checksum,
                'X-MERCHANT-ID: ' . self::$merchantId
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

            if (curl_errno($ch)) {
                $error = curl_error($ch);
                curl_close($ch);

                Log::error('PhonePe Status Check Failed - cURL Error', [
                    'merchantTransactionId' => $merchantTransactionId,
                    'error' => $error
                ]);

                return [
                    'success' => false,
                    'error' => 'Network error: ' . $error
                ];
            }

            curl_close($ch);

            $responseData = json_decode($response, true);

            Log::info('PhonePe Status Check Response', [
                'merchantTransactionId' => $merchantTransactionId,
                'httpCode' => $httpCode,
                'response' => $responseData
            ]);

            if ($httpCode === 200 && isset($responseData['success']) && $responseData['success']) {
                return [
                    'success' => true,
                    'data' => $responseData['data'],
                    'code' => $responseData['code'] ?? '',
                    'message' => $responseData['message'] ?? ''
                ];
            } else {
                return [
                    'success' => false,
                    'error' => $responseData['message'] ?? 'Transaction verification failed',
                    'code' => $responseData['code'] ?? 'UNKNOWN',
                    'data' => $responseData['data'] ?? null
                ];
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Status Check Exception', [
                'merchantTransactionId' => $merchantTransactionId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Get merchant ID
     *
     * @return string
     */
    public static function getMerchantId()
    {
        return self::$merchantId;
    }

    /**
     * Validate callback checksum
     *
     * @param string $base64Response
     * @param string $receivedChecksum
     * @return bool
     */
    public static function validateCallback($base64Response, $receivedChecksum)
    {
        try {
            // Extract checksum hash (remove ### and salt index)
            $checksumParts = explode('###', $receivedChecksum);
            $receivedHash = $checksumParts[0] ?? '';

            // Generate expected checksum
            $checksumString = $base64Response . self::$saltKey;
            $expectedHash = hash('sha256', $checksumString);

            $isValid = ($receivedHash === $expectedHash);

            Log::info('PhonePe Callback Validation', [
                'isValid' => $isValid,
                'receivedChecksum' => $receivedChecksum,
                'expectedHash' => $expectedHash
            ]);

            return $isValid;

        } catch (\Exception $e) {
            Log::error('PhonePe Callback Validation Failed', [
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }
}
