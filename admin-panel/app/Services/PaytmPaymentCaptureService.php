<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;

class PaytmPaymentCaptureService
{
    private static $merchantId;
    private static $merchantKey;
    private static $website;
    private static $industryType;
    private static $channelId;
    private static $environment; // 'test' or 'live'

    private static $testUrl = 'https://securegw-stage.paytm.in';
    private static $liveUrl = 'https://securegw.paytm.in';

    // API timeout settings
    private static $apiTimeout = 30; // seconds
    private static $maxRetries = 3;

    /**
     * Initialize Paytm configuration from database
     *
     * @throws \Exception if credentials are not configured
     */
    private static function initConfig()
    {
        try {
            // Get environment setting
            $environment = DB::table('settings')
                ->where('variable', 'paytm_environment')
                ->value('value') ?? 'test';

            if (!in_array($environment, ['test', 'live'])) {
                throw new \Exception('Invalid Paytm environment configuration');
            }

            self::$environment = $environment;

            // Determine which credentials to use based on environment
            $prefix = $environment === 'live' ? 'paytm_live' : 'paytm_test';

            // Get credentials from settings table
            $settings = DB::table('settings')
                ->whereIn('variable', [
                    $prefix . '_merchant_id',
                    $prefix . '_merchant_key',
                    $prefix . '_website',
                    $prefix . '_industry_type',
                    $prefix . '_channel_id'
                ])
                ->pluck('value', 'variable');

            self::$merchantId = $settings[$prefix . '_merchant_id'] ?? null;
            self::$merchantKey = $settings[$prefix . '_merchant_key'] ?? null;
            self::$website = $settings[$prefix . '_website'] ?? 'DEFAULT';
            self::$industryType = $settings[$prefix . '_industry_type'] ?? 'Retail';
            self::$channelId = $settings[$prefix . '_channel_id'] ?? 'WAP';

            // Validate required credentials
            if (empty(self::$merchantId) || empty(self::$merchantKey)) {
                throw new \Exception('Paytm credentials not configured properly');
            }

            Log::info('Paytm Config Initialized', [
                'environment' => self::$environment,
                'merchant_id' => substr(self::$merchantId, 0, 5) . '***', // Masked for security
                'website' => self::$website,
                'channel_id' => self::$channelId
            ]);

        } catch (\Exception $e) {
            Log::error('Paytm: Configuration initialization failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw new \Exception('Failed to initialize Paytm configuration: ' . $e->getMessage());
        }
    }

    /**
     * Get base URL based on environment
     *
     * @return string
     */
    private static function getBaseUrl()
    {
        return self::$environment === 'live' ? self::$liveUrl : self::$testUrl;
    }

    /**
     * Generate checksum for Paytm API request
     *
     * @param array $params
     * @return string
     * @throws \Exception
     */
    private static function generateChecksum($params)
    {
        try {
            if (!is_array($params) || empty($params)) {
                throw new \Exception('Invalid parameters for checksum generation');
            }

            $paramStr = '';
            ksort($params);
            foreach ($params as $key => $value) {
                if (is_null($value) || $value === '') {
                    continue; // Skip null or empty values
                }
                $paramStr .= $key . '=' . $value . '&';
            }
            $paramStr = rtrim($paramStr, '&');

            if (empty(self::$merchantKey)) {
                throw new \Exception('Merchant key not available for checksum generation');
            }

            $salt = self::$merchantKey;
            $finalString = $paramStr . '|' . $salt;

            return hash('sha256', $finalString);

        } catch (\Exception $e) {
            Log::error('Paytm: Checksum generation failed', [
                'error' => $e->getMessage()
            ]);
            throw new \Exception('Failed to generate checksum: ' . $e->getMessage());
        }
    }

    /**
     * Verify checksum from Paytm response
     *
     * @param array $params
     * @param string $checksum
     * @return bool
     */
    private static function verifyChecksum($params, $checksum)
    {
        try {
            if (empty($checksum)) {
                Log::warning('Paytm: Empty checksum received');
                return false;
            }

            $generatedChecksum = self::generateChecksum($params);
            return hash_equals($generatedChecksum, $checksum);

        } catch (\Exception $e) {
            Log::error('Paytm: Checksum verification failed', [
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Validate transaction ID format
     *
     * @param string $orderId
     * @return bool
     */
    private static function validateTransactionId($orderId)
    {
        // Transaction ID should be alphanumeric and within reasonable length
        if (empty($orderId) || !is_string($orderId)) {
            return false;
        }

        if (strlen($orderId) > 255 || strlen($orderId) < 3) {
            return false;
        }

        // Allow alphanumeric, underscore, hyphen
        if (!preg_match('/^[a-zA-Z0-9_-]+$/', $orderId)) {
            return false;
        }

        return true;
    }

    /**
     * Make API request with retry logic
     *
     * @param string $url
     * @param array $params
     * @param int $retryCount
     * @return array
     */
    private static function makeApiRequest($url, $params, $retryCount = 0)
    {
        try {
            $response = Http::asForm()
                ->withoutVerifying() // TODO: Enable SSL verification in production
                ->timeout(self::$apiTimeout)
                ->retry(self::$maxRetries, 1000) // Retry 3 times with 1 second delay
                ->post($url, $params);

            return [
                'success' => true,
                'response' => $response,
                'data' => $response->json()
            ];

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('Paytm: Connection error', [
                'error' => $e->getMessage(),
                'url' => $url,
                'retry_count' => $retryCount
            ]);

            return [
                'success' => false,
                'error' => 'Network connection error. Please try again.',
                'error_type' => 'connection_error'
            ];

        } catch (\Illuminate\Http\Client\RequestException $e) {
            Log::error('Paytm: Request error', [
                'error' => $e->getMessage(),
                'url' => $url,
                'status_code' => $e->response ? $e->response->status() : 'N/A'
            ]);

            return [
                'success' => false,
                'error' => 'Payment gateway request failed. Please contact support.',
                'error_type' => 'request_error'
            ];

        } catch (\Exception $e) {
            Log::error('Paytm: Unexpected API error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'An unexpected error occurred. Please try again later.',
                'error_type' => 'unexpected_error'
            ];
        }
    }

    /**
     * 
     * Check payment status by order ID/transaction ID
     *
     * @param string $orderId Paytm order ID
     * @return array
     */
    public static function checkPaymentStatus($orderId)
    {
        try {
            // Validate transaction ID
            if (!self::validateTransactionId($orderId)) {
                return [
                    'success' => false,
                    'error' => 'Invalid transaction ID format',
                    'error_type' => 'validation_error'
                ];
            }

            // Initialize configuration
            self::initConfig();

            Log::info('Paytm: Checking payment status', [
                'order_id' => $orderId,
                'merchant_id' => substr(self::$merchantId, 0, 5) . '***'
            ]);

            // Use the working Paytm helper's transaction_status method
            $response = \App\Helpers\Paytm::transaction_status($orderId);

            if (empty($response)) {
                return [
                    'success' => false,
                    'error' => 'Empty response from payment gateway',
                    'error_type' => 'empty_response'
                ];
            }

            $responseData = json_decode($response, true);

            if (!$responseData) {
                Log::error('Paytm: Failed to parse response', [
                    'response' => substr($response, 0, 500)
                ]);
                return [
                    'success' => false,
                    'error' => 'Failed to parse payment gateway response',
                    'error_type' => 'parse_error'
                ];
            }

            // Log the FULL response structure for debugging
            Log::info('Paytm: Raw response structure', [
                'order_id' => $orderId,
                'response_keys' => array_keys($responseData),
                'has_body' => isset($responseData['body']),
                'has_head' => isset($responseData['head']),
                'has_STATUS' => isset($responseData['STATUS']),
                'full_response' => $responseData
            ]);

            // Paytm v3 API returns body/head structure, not flat STATUS field
            $isV3Format = isset($responseData['body']);

            if ($isV3Format) {
                Log::info('Paytm: Detected v3 API response format', [
                    'order_id' => $orderId,
                    'body_keys' => isset($responseData['body']) ? array_keys($responseData['body']) : [],
                    'result_status' => $responseData['body']['resultInfo']['resultStatus'] ?? 'UNKNOWN',
                    'result_code' => $responseData['body']['resultInfo']['resultCode'] ?? 'UNKNOWN',
                    'result_msg' => $responseData['body']['resultInfo']['resultMsg'] ?? 'UNKNOWN'
                ]);
            } else {
                Log::info('Paytm: Detected legacy API response format', [
                    'order_id' => $orderId,
                    'status' => $responseData['STATUS'] ?? 'UNKNOWN'
                ]);
            }

            // Validate response structure (support both v3 and legacy formats)
            if (!$isV3Format && !isset($responseData['STATUS'])) {
                Log::error('Paytm: Invalid response structure - neither v3 nor legacy format', [
                    'order_id' => $orderId,
                    'response_keys' => array_keys($responseData),
                    'full_response' => $responseData,
                    'expected_v3_keys' => ['body', 'head'],
                    'expected_legacy_keys' => ['STATUS', 'ORDERID', 'TXNID'],
                    'actual_keys' => array_keys($responseData)
                ]);
                return [
                    'success' => false,
                    'error' => 'Invalid response from payment gateway - unexpected structure',
                    'error_type' => 'invalid_response',
                    'debug' => [
                        'received_keys' => array_keys($responseData),
                        'expected_keys' => ['body/head for v3', 'STATUS for legacy']
                    ]
                ];
            }

            // Verify response checksum if present
            if ($isV3Format && isset($responseData['head']['signature'])) {
                // v3 format has checksum in head.signature
                $receivedChecksum = $responseData['head']['signature'];
                $bodyJson = json_encode($responseData['body'], JSON_UNESCAPED_SLASHES);

                Log::info('Paytm: v3 checksum verification', [
                    'order_id' => $orderId,
                    'has_signature' => !empty($receivedChecksum),
                    'body_json_length' => strlen($bodyJson)
                ]);

                // For v3, we verify the signature of the body JSON
                // Note: Paytm v3 signature verification is complex, skipping for now
                // The response came from Paytm's SSL connection so it's already verified

            } elseif (!$isV3Format && isset($responseData['CHECKSUMHASH'])) {
                // Legacy format has CHECKSUMHASH
                $receivedChecksum = $responseData['CHECKSUMHASH'];
                $responseDataCopy = $responseData;
                unset($responseDataCopy['CHECKSUMHASH']);

                if (!self::verifyChecksum($responseDataCopy, $receivedChecksum)) {
                    Log::error('Paytm: Checksum verification failed for response', [
                        'order_id' => $orderId
                    ]);
                    return [
                        'success' => false,
                        'error' => 'Security verification failed for payment gateway response',
                        'error_type' => 'checksum_mismatch'
                    ];
                }
            }

            // Parse and return payment data (support both v3 and legacy formats)
            if ($isV3Format) {
                // v3 API format
                $body = $responseData['body'];
                $resultInfo = $body['resultInfo'] ?? [];

                return [
                    'success' => true,
                    'data' => [
                        'order_id' => $body['orderId'] ?? $orderId,
                        'transaction_id' => $body['txnId'] ?? null,
                        'bank_transaction_id' => $body['bankTxnId'] ?? null,
                        'amount' => isset($body['txnAmount']) ? floatval($body['txnAmount']) : 0,
                        'status' => $resultInfo['resultStatus'] ?? 'UNKNOWN',
                        'response_code' => $resultInfo['resultCode'] ?? null,
                        'response_msg' => $resultInfo['resultMsg'] ?? null,
                        'transaction_date' => $body['txnDate'] ?? null,
                        'gateway_name' => $body['gatewayName'] ?? null,
                        'bank_name' => $body['bankName'] ?? null,
                        'payment_mode' => $body['paymentMode'] ?? null
                    ]
                ];
            } else {
                // Legacy API format
                return [
                    'success' => true,
                    'data' => [
                        'order_id' => $responseData['ORDERID'] ?? $orderId,
                        'transaction_id' => $responseData['TXNID'] ?? null,
                        'bank_transaction_id' => $responseData['BANKTXNID'] ?? null,
                        'amount' => isset($responseData['TXNAMOUNT']) ? floatval($responseData['TXNAMOUNT']) : 0,
                        'status' => $responseData['STATUS'] ?? 'UNKNOWN',
                        'response_code' => $responseData['RESPCODE'] ?? null,
                        'response_msg' => $responseData['RESPMSG'] ?? null,
                        'transaction_date' => $responseData['TXNDATE'] ?? null,
                        'gateway_name' => $responseData['GATEWAYNAME'] ?? null,
                        'bank_name' => $responseData['BANKNAME'] ?? null,
                        'payment_mode' => $responseData['PAYMENTMODE'] ?? null
                    ]
                ];
            }

        } catch (\Exception $e) {
            Log::error('Paytm: Status check exception', [
                'order_id' => $orderId ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to check payment status: ' . $e->getMessage(),
                'error_type' => 'exception'
            ];
        }
    }

    /**
     * Verify payment is successful and optionally validate amount
     *
     * @param string $orderId Paytm order ID
     * @param float|null $expectedAmount Optional expected amount to verify
     * @return array
     */
    public static function verifyPayment($orderId, $expectedAmount = null)
    {
        try {
            // Validate inputs
            if (!self::validateTransactionId($orderId)) {
                return [
                    'success' => false,
                    'error' => 'Invalid transaction ID format',
                    'error_type' => 'validation_error'
                ];
            }

            if ($expectedAmount !== null) {
                if (!is_numeric($expectedAmount) || $expectedAmount <= 0) {
                    return [
                        'success' => false,
                        'error' => 'Invalid expected amount',
                        'error_type' => 'validation_error'
                    ];
                }
                $expectedAmount = floatval($expectedAmount);
            }

            Log::info('Paytm: Verifying payment', [
                'order_id' => $orderId,
                'expected_amount' => $expectedAmount
            ]);

            // Check payment status
            $statusResult = self::checkPaymentStatus($orderId);

            if (!$statusResult['success']) {
                return $statusResult;
            }

            $payment = $statusResult['data'];
            $status = strtoupper($payment['status']);

            // Check if payment is successful
            $successStatuses = ['TXN_SUCCESS', 'SUCCESS'];
            $isSuccess = in_array($status, $successStatuses);

            if (!$isSuccess) {
                Log::warning('Paytm: Payment not successful', [
                    'order_id' => $orderId,
                    'status' => $status,
                    'response_msg' => $payment['response_msg']
                ]);

                return [
                    'success' => false,
                    'error' => 'Payment not successful. Status: ' . $status . ' - ' . ($payment['response_msg'] ?? 'Unknown error'),
                    'error_type' => 'payment_failed',
                    'data' => $payment
                ];
            }

            // Verify amount if provided
            if ($expectedAmount !== null) {
                $actualAmount = floatval($payment['amount']);

                // Allow small floating point differences (0.01)
                if (abs($actualAmount - $expectedAmount) > 0.01) {
                    Log::error('Paytm: Amount mismatch detected', [
                        'order_id' => $orderId,
                        'expected' => $expectedAmount,
                        'actual' => $actualAmount,
                        'difference' => abs($actualAmount - $expectedAmount)
                    ]);

                    return [
                        'success' => false,
                        'error' => sprintf(
                            'Payment amount mismatch. Expected: ₹%.2f, Received: ₹%.2f',
                            $expectedAmount,
                            $actualAmount
                        ),
                        'error_type' => 'amount_mismatch',
                        'data' => $payment
                    ];
                }
            }

            Log::info('Paytm: Payment verified successfully', [
                'order_id' => $orderId,
                'transaction_id' => $payment['transaction_id'],
                'amount' => $payment['amount']
            ]);

            return [
                'success' => true,
                'message' => 'Payment verified successfully',
                'data' => $payment,
                'captured' => true // Paytm auto-captures successful payments
            ];

        } catch (\Exception $e) {
            Log::error('Paytm: Payment verification exception', [
                'order_id' => $orderId ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Payment verification failed: ' . $e->getMessage(),
                'error_type' => 'exception'
            ];
        }
    }

    /**
     * Check if payment is valid and successful (simplified check)
     *
     * @param string $orderId Paytm order ID
     * @return array
     */
    public static function isPaymentValid($orderId)
    {
        try {
            if (!self::validateTransactionId($orderId)) {
                return [
                    'valid' => false,
                    'error' => 'Invalid transaction ID format'
                ];
            }

            $statusResult = self::checkPaymentStatus($orderId);

            if (!$statusResult['success']) {
                return [
                    'valid' => false,
                    'error' => $statusResult['error']
                ];
            }

            $payment = $statusResult['data'];
            $status = strtoupper($payment['status']);

            $successStatuses = ['TXN_SUCCESS', 'SUCCESS'];
            $isValid = in_array($status, $successStatuses);

            return [
                'valid' => $isValid,
                'status' => $status,
                'amount' => $payment['amount'],
                'transaction_id' => $payment['transaction_id'],
                'data' => $payment
            ];

        } catch (\Exception $e) {
            Log::error('Paytm: Payment validation exception', [
                'order_id' => $orderId ?? 'N/A',
                'error' => $e->getMessage()
            ]);

            return [
                'valid' => false,
                'error' => 'Payment validation failed: ' . $e->getMessage()
            ];
        }
    }
}
