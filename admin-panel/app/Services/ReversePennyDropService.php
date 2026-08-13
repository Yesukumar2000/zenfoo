<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class ReversePennyDropService
{
    // PhonePe API credentials
    private static $merchantId;
    private static $saltKey;
    private static $saltIndex;
    private static $isProduction;

    // API URLs
    private static $uatBaseUrl = 'https://api-preprod.phonepe.com/apis/pg-sandbox';
    private static $prodBaseUrl = 'https://api.phonepe.com/apis/hermes';

    // Verification amount (₹1 = 100 paise)
    const VERIFICATION_AMOUNT_PAISE = 100;

    // Verification status constants
    const STATUS_PENDING = 'pending';
    const STATUS_SUCCESS = 'success';
    const STATUS_FAILED = 'failed';

    /**
     * Initialize PhonePe configuration
     */
    private static function initConfig()
    {
        self::$merchantId = config('services.phonepe.merchant_id', 'PGTESTPAYUAT');
        self::$saltKey = config('services.phonepe.salt_key', '96434309-7796-489d-8924-ab56988a6076');
        self::$saltIndex = config('services.phonepe.salt_index', '1');
        self::$isProduction = config('services.phonepe.is_production', false);
    }

    /**
     * Get the base URL based on environment
     */
    private static function getBaseUrl()
    {
        self::initConfig();
        return self::$isProduction ? self::$prodBaseUrl : self::$uatBaseUrl;
    }

    /**
     * Initiate Reverse Penny Drop - Create payment request for ₹1
     * Driver will pay this amount to verify their bank account
     *
     * @param int $deliveryBoyId
     * @param string $redirectUrl URL to redirect after payment
     * @param string $callbackUrl Webhook URL for payment status
     * @return array
     */
    public static function initiateVerification($deliveryBoyId, $redirectUrl, $callbackUrl)
    {
        try {
            self::initConfig();

            Log::info('Reverse Penny Drop: Initiating verification', [
                'delivery_boy_id' => $deliveryBoyId
            ]);

            // Get delivery boy details
            $deliveryBoy = DB::table('delivery_boys')->where('id', $deliveryBoyId)->first();

            if (!$deliveryBoy) {
                Log::error('Reverse Penny Drop: Delivery boy not found', [
                    'delivery_boy_id' => $deliveryBoyId
                ]);
                return [
                    'success' => false,
                    'error' => 'Delivery boy not found'
                ];
            }

            // Generate unique transaction ID
            $merchantTransactionId = self::generateTransactionId($deliveryBoyId);

            // Create verification record
            $verificationId = self::createVerificationRecord($deliveryBoyId, $merchantTransactionId);

            if (!$verificationId) {
                return [
                    'success' => false,
                    'error' => 'Failed to create verification record'
                ];
            }

            // Build payment payload
            $payload = [
                'merchantId' => self::$merchantId,
                'merchantTransactionId' => $merchantTransactionId,
                'merchantUserId' => 'DB_' . $deliveryBoyId,
                'amount' => self::VERIFICATION_AMOUNT_PAISE,
                'redirectUrl' => $redirectUrl . '?txnId=' . $merchantTransactionId,
                'redirectMode' => 'POST',
                'callbackUrl' => $callbackUrl,
                'mobileNumber' => $deliveryBoy->mobile ?? '',
                'paymentInstrument' => [
                    'type' => 'PAY_PAGE'
                ]
            ];

            // Encode payload
            $jsonPayload = json_encode($payload);
            $base64Payload = base64_encode($jsonPayload);

            // Generate checksum
            $checksumString = $base64Payload . '/pg/v1/pay' . self::$saltKey;
            $sha256Hash = hash('sha256', $checksumString);
            $checksum = $sha256Hash . '###' . self::$saltIndex;

            // Build API URL
            $url = self::getBaseUrl() . '/pg/v1/pay';

            Log::info('Reverse Penny Drop: Making API call', [
                'delivery_boy_id' => $deliveryBoyId,
                'transaction_id' => $merchantTransactionId,
                'url' => $url
            ]);

            // Make API call
            $ch = curl_init();
            $curlOptions = [
                CURLOPT_URL => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => json_encode(['request' => $base64Payload]),
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'X-VERIFY: ' . $checksum
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

                Log::error('Reverse Penny Drop: cURL error', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'error' => $error
                ]);

                return [
                    'success' => false,
                    'error' => 'Network error: ' . $error
                ];
            }

            curl_close($ch);

            $responseData = json_decode($response, true);

            Log::info('Reverse Penny Drop: API response', [
                'delivery_boy_id' => $deliveryBoyId,
                'http_code' => $httpCode,
                'response' => $responseData
            ]);

            // Check response
            if ($httpCode === 200 && isset($responseData['success']) && $responseData['success']) {
                // Get payment URL
                $paymentUrl = $responseData['data']['instrumentResponse']['redirectInfo']['url'] ?? null;

                if ($paymentUrl) {
                    Log::info('Reverse Penny Drop: Payment URL generated', [
                        'delivery_boy_id' => $deliveryBoyId,
                        'transaction_id' => $merchantTransactionId
                    ]);

                    return [
                        'success' => true,
                        'data' => [
                            'transaction_id' => $merchantTransactionId,
                            'verification_id' => $verificationId,
                            'payment_url' => $paymentUrl,
                            'amount' => 1.00 // ₹1
                        ]
                    ];
                }
            }

            // Update verification as failed
            self::updateVerificationStatus($merchantTransactionId, self::STATUS_FAILED, [
                'error' => $responseData['message'] ?? 'Payment initiation failed'
            ]);

            return [
                'success' => false,
                'error' => $responseData['message'] ?? 'Failed to initiate payment'
            ];

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Exception during initiation', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Verification initiation failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Check payment status and extract bank details
     *
     * @param string $merchantTransactionId
     * @return array
     */
    public static function checkPaymentStatus($merchantTransactionId)
    {
        try {
            self::initConfig();

            Log::info('Reverse Penny Drop: Checking payment status', [
                'transaction_id' => $merchantTransactionId
            ]);

            // Build status check URL
            $statusEndpoint = '/pg/v1/status/' . self::$merchantId . '/' . $merchantTransactionId;
            $url = self::getBaseUrl() . $statusEndpoint;

            // Generate checksum
            $checksumString = $statusEndpoint . self::$saltKey;
            $sha256Hash = hash('sha256', $checksumString);
            $checksum = $sha256Hash . '###' . self::$saltIndex;

            // Make API call
            $ch = curl_init();
            $curlOptions = [
                CURLOPT_URL => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'X-VERIFY: ' . $checksum,
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

                Log::error('Reverse Penny Drop: Status check cURL error', [
                    'transaction_id' => $merchantTransactionId,
                    'error' => $error
                ]);

                return [
                    'success' => false,
                    'error' => 'Network error: ' . $error
                ];
            }

            curl_close($ch);

            $responseData = json_decode($response, true);

            Log::info('Reverse Penny Drop: Status check response', [
                'transaction_id' => $merchantTransactionId,
                'http_code' => $httpCode,
                'response' => $responseData
            ]);

            // Check if payment was successful
            if ($httpCode === 200 && isset($responseData['success']) && $responseData['success']) {
                $paymentState = $responseData['data']['state'] ?? '';
                $code = $responseData['code'] ?? '';

                if ($code === 'PAYMENT_SUCCESS' || $paymentState === 'COMPLETED') {
                    // Extract bank details from payment response
                    $bankDetails = self::extractBankDetailsFromResponse($responseData);

                    // Get verification record
                    $verification = DB::table('bank_verification_requests')
                        ->where('transaction_id', $merchantTransactionId)
                        ->first();

                    if ($verification) {
                        // Update delivery boy documents with bank details
                        $updateResult = self::updateDeliveryBoyBankDetails(
                            $verification->delivery_boy_id,
                            $bankDetails
                        );

                        // Update verification status
                        self::updateVerificationStatus($merchantTransactionId, self::STATUS_SUCCESS, [
                            'bank_details' => $bankDetails,
                            'phonepe_response' => $responseData
                        ]);

                        Log::info('Reverse Penny Drop: Verification successful', [
                            'transaction_id' => $merchantTransactionId,
                            'delivery_boy_id' => $verification->delivery_boy_id,
                            'bank_details' => $bankDetails
                        ]);

                        return [
                            'success' => true,
                            'message' => 'Bank account verified successfully',
                            'data' => [
                                'bank_details' => $bankDetails,
                                'verified' => true
                            ]
                        ];
                    }
                }

                // Payment pending or failed
                return [
                    'success' => false,
                    'status' => $paymentState,
                    'error' => 'Payment not completed. Status: ' . $paymentState
                ];
            }

            return [
                'success' => false,
                'error' => $responseData['message'] ?? 'Status check failed'
            ];

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Exception during status check', [
                'transaction_id' => $merchantTransactionId,
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
     * Handle PhonePe callback/webhook
     *
     * @param array $callbackData
     * @return array
     */
    public static function handleCallback($callbackData)
    {
        try {
            Log::info('Reverse Penny Drop: Callback received', [
                'callback_data' => $callbackData
            ]);

            // Validate callback
            if (!isset($callbackData['response'])) {
                return [
                    'success' => false,
                    'error' => 'Invalid callback data'
                ];
            }

            // Validate checksum if provided
            if (isset($callbackData['checksum'])) {
                $isValid = self::validateCallbackChecksum(
                    $callbackData['response'],
                    $callbackData['checksum']
                );

                if (!$isValid) {
                    Log::warning('Reverse Penny Drop: Invalid callback checksum');
                    return [
                        'success' => false,
                        'error' => 'Invalid checksum'
                    ];
                }
            }

            // Decode response
            $decodedResponse = json_decode(base64_decode($callbackData['response']), true);

            $merchantTransactionId = $decodedResponse['merchantTransactionId'] ?? null;
            $code = $decodedResponse['code'] ?? '';
            $state = $decodedResponse['data']['state'] ?? '';

            if (!$merchantTransactionId) {
                return [
                    'success' => false,
                    'error' => 'Missing transaction ID in callback'
                ];
            }

            Log::info('Reverse Penny Drop: Callback decoded', [
                'transaction_id' => $merchantTransactionId,
                'code' => $code,
                'state' => $state
            ]);

            // Check if payment was successful
            if ($code === 'PAYMENT_SUCCESS') {
                // Extract and store bank details
                $bankDetails = self::extractBankDetailsFromResponse(['data' => $decodedResponse['data'] ?? []]);

                // Get verification record
                $verification = DB::table('bank_verification_requests')
                    ->where('transaction_id', $merchantTransactionId)
                    ->first();

                if ($verification) {
                    // Update delivery boy documents
                    self::updateDeliveryBoyBankDetails(
                        $verification->delivery_boy_id,
                        $bankDetails
                    );

                    // Update verification status
                    self::updateVerificationStatus($merchantTransactionId, self::STATUS_SUCCESS, [
                        'bank_details' => $bankDetails,
                        'callback_response' => $decodedResponse
                    ]);

                    return [
                        'success' => true,
                        'message' => 'Bank account verified successfully'
                    ];
                }
            } else {
                // Payment failed
                self::updateVerificationStatus($merchantTransactionId, self::STATUS_FAILED, [
                    'error' => $code,
                    'callback_response' => $decodedResponse
                ]);
            }

            return [
                'success' => false,
                'error' => 'Payment not successful'
            ];

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Exception handling callback', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Callback processing failed'
            ];
        }
    }

    /**
     * Extract bank details from PhonePe response
     * When user pays via UPI, PhonePe returns the payer's VPA and bank details
     *
     * @param array $responseData
     * @return array
     */
    private static function extractBankDetailsFromResponse($responseData)
    {
        $data = $responseData['data'] ?? [];
        $paymentInstrument = $data['paymentInstrument'] ?? [];

        // UPI payment details
        $upiDetails = $paymentInstrument['upi'] ?? [];
        $vpa = $upiDetails['vpa'] ?? ($paymentInstrument['vpa'] ?? '');

        // Bank account details (if available in response)
        $bankAccount = $paymentInstrument['bankAccount'] ?? [];

        // Extract account holder name from VPA or response
        $accountHolderName = $bankAccount['accountHolderName']
            ?? $data['accountHolderName']
            ?? self::extractNameFromVPA($vpa);

        // Extract bank name from IFSC or VPA
        $ifscCode = $bankAccount['ifsc'] ?? ($data['ifsc'] ?? '');
        $bankName = $bankAccount['bankName'] ?? self::getBankNameFromIFSC($ifscCode);

        // Account number (may not always be available)
        $accountNumber = $bankAccount['accountNumber'] ?? ($data['accountNumber'] ?? '');

        return [
            'account_holder_name' => $accountHolderName,
            'account_number' => $accountNumber,
            'ifsc_code' => $ifscCode,
            'bank_name' => $bankName,
            'upi_vpa' => $vpa,
            'verified_at' => Carbon::now()->toDateTimeString(),
            'verification_method' => 'reverse_penny_drop'
        ];
    }

    /**
     * Update delivery boy documents with verified bank details
     *
     * @param int $deliveryBoyId
     * @param array $bankDetails
     * @return bool
     */
    private static function updateDeliveryBoyBankDetails($deliveryBoyId, $bankDetails)
    {
        try {
            Log::info('Reverse Penny Drop: Updating bank details', [
                'delivery_boy_id' => $deliveryBoyId,
                'bank_details' => $bankDetails
            ]);

            // Check if record exists
            $exists = DB::table('delivery_boy_documents')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->exists();

            $updateData = [
                'bank_name' => $bankDetails['bank_name'] ?? null,
                'account_holder_name' => $bankDetails['account_holder_name'] ?? null,
                'account_number' => $bankDetails['account_number'] ?? null,
                'ifsc_code' => $bankDetails['ifsc_code'] ?? null,
                'bank_details_status' => 'verified',
                'updated_at' => Carbon::now()
            ];

            if ($exists) {
                DB::table('delivery_boy_documents')
                    ->where('delivery_boy_id', $deliveryBoyId)
                    ->update($updateData);
            } else {
                $updateData['delivery_boy_id'] = $deliveryBoyId;
                $updateData['created_at'] = Carbon::now();
                DB::table('delivery_boy_documents')->insert($updateData);
            }

            Log::info('Reverse Penny Drop: Bank details updated successfully', [
                'delivery_boy_id' => $deliveryBoyId
            ]);

            return true;

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Failed to update bank details', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Create verification record in database
     *
     * @param int $deliveryBoyId
     * @param string $transactionId
     * @return int|null
     */
    private static function createVerificationRecord($deliveryBoyId, $transactionId)
    {
        try {
            $id = DB::table('bank_verification_requests')->insertGetId([
                'delivery_boy_id' => $deliveryBoyId,
                'transaction_id' => $transactionId,
                'amount' => 1.00,
                'status' => self::STATUS_PENDING,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            Log::info('Reverse Penny Drop: Verification record created', [
                'id' => $id,
                'delivery_boy_id' => $deliveryBoyId,
                'transaction_id' => $transactionId
            ]);

            return $id;

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Failed to create verification record', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Update verification status
     *
     * @param string $transactionId
     * @param string $status
     * @param array $additionalData
     * @return bool
     */
    private static function updateVerificationStatus($transactionId, $status, $additionalData = [])
    {
        try {
            $updateData = [
                'status' => $status,
                'response_data' => json_encode($additionalData),
                'updated_at' => Carbon::now()
            ];

            if ($status === self::STATUS_SUCCESS) {
                $updateData['verified_at'] = Carbon::now();
            }

            DB::table('bank_verification_requests')
                ->where('transaction_id', $transactionId)
                ->update($updateData);

            return true;

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Failed to update verification status', [
                'transaction_id' => $transactionId,
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Validate callback checksum
     *
     * @param string $base64Response
     * @param string $receivedChecksum
     * @return bool
     */
    private static function validateCallbackChecksum($base64Response, $receivedChecksum)
    {
        try {
            self::initConfig();

            $checksumParts = explode('###', $receivedChecksum);
            $receivedHash = $checksumParts[0] ?? '';

            $checksumString = $base64Response . self::$saltKey;
            $expectedHash = hash('sha256', $checksumString);

            return ($receivedHash === $expectedHash);

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Checksum validation error', [
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Generate unique transaction ID
     *
     * @param int $deliveryBoyId
     * @return string
     */
    private static function generateTransactionId($deliveryBoyId)
    {
        $timestamp = Carbon::now()->format('YmdHis');
        $random = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 6));
        return "RPD_{$deliveryBoyId}_{$timestamp}_{$random}";
    }

    /**
     * Extract name from UPI VPA (basic extraction)
     *
     * @param string $vpa
     * @return string
     */
    private static function extractNameFromVPA($vpa)
    {
        if (empty($vpa)) {
            return '';
        }

        // VPA format: username@bankhandle
        $parts = explode('@', $vpa);
        $username = $parts[0] ?? '';

        // Try to make it more readable
        $name = str_replace(['.', '_', '-'], ' ', $username);
        return ucwords(strtolower($name));
    }

    /**
     * Get bank name from IFSC code using Razorpay free API
     *
     * @param string $ifscCode
     * @return string
     */
    private static function getBankNameFromIFSC($ifscCode)
    {
        if (empty($ifscCode) || strlen($ifscCode) !== 11) {
            return '';
        }

        try {
            self::initConfig();

            $url = 'https://ifsc.razorpay.com/' . strtoupper($ifscCode);

            $ch = curl_init();
            $curlOptions = [
                CURLOPT_URL => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 10
            ];

            // Disable SSL verification in non-production (for local development)
            if (!self::$isProduction) {
                $curlOptions[CURLOPT_SSL_VERIFYPEER] = false;
                $curlOptions[CURLOPT_SSL_VERIFYHOST] = 0;
            }

            curl_setopt_array($ch, $curlOptions);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode === 200) {
                $data = json_decode($response, true);
                return $data['BANK'] ?? '';
            }

            return '';

        } catch (\Exception $e) {
            Log::debug('Reverse Penny Drop: IFSC lookup failed', [
                'ifsc' => $ifscCode,
                'error' => $e->getMessage()
            ]);
            return '';
        }
    }

    /**
     * Get verification status for a delivery boy
     *
     * @param int $deliveryBoyId
     * @return array
     */
    public static function getVerificationStatus($deliveryBoyId)
    {
        try {
            // Check if bank details are verified
            $documents = DB::table('delivery_boy_documents')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->first();

            if ($documents && $documents->bank_details_status === 'verified') {
                return [
                    'success' => true,
                    'verified' => true,
                    'data' => [
                        'bank_name' => $documents->bank_name,
                        'account_holder_name' => $documents->account_holder_name,
                        'account_number_masked' => self::maskAccountNumber($documents->account_number),
                        'ifsc_code' => $documents->ifsc_code
                    ]
                ];
            }

            // Check for pending verification
            $pendingVerification = DB::table('bank_verification_requests')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->where('status', self::STATUS_PENDING)
                ->orderBy('created_at', 'desc')
                ->first();

            if ($pendingVerification) {
                return [
                    'success' => true,
                    'verified' => false,
                    'pending' => true,
                    'transaction_id' => $pendingVerification->transaction_id
                ];
            }

            return [
                'success' => true,
                'verified' => false,
                'pending' => false
            ];

        } catch (\Exception $e) {
            Log::error('Reverse Penny Drop: Error getting verification status', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to get verification status'
            ];
        }
    }

    /**
     * Mask account number for display
     *
     * @param string $accountNumber
     * @return string
     */
    private static function maskAccountNumber($accountNumber)
    {
        if (empty($accountNumber) || strlen($accountNumber) <= 4) {
            return '****';
        }
        return str_repeat('*', strlen($accountNumber) - 4) . substr($accountNumber, -4);
    }
}
