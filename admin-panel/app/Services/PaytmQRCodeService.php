<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Setting;
use App\Helpers\Paytm;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Exception;

/**
 * Service for generating Paytm/UPI QR codes for order payments
 *
 * This service generates dynamic QR codes that delivery boys can show to customers
 * for direct payment via Paytm or any UPI app
 */
class PaytmQRCodeService
{
    /**
     * Generate QR code data for an order using Paytm Dynamic QR API
     *
     * This method calls Paytm's Dynamic QR Code API to generate order-specific QR codes
     * where money flows through Paytm Payment Gateway account (like Razorpay)
     *
     * @param Order $order
     * @param array $options Optional parameters (generate_image, size, etc.)
     * @return array
     */
    public static function generateOrderQRCode(Order $order, array $options = []): array
    {
        try {
            // Calculate total amount to be paid
            $amount = self::calculateOrderAmount($order);

            if ($amount <= 0) {
                return [
                    'success' => false,
                    'error' => 'Invalid order amount',
                    'error_type' => 'validation_error'
                ];
            }

            // Generate dynamic QR code using Paytm API
            $result = self::generateDynamicQRCode($order, $amount);

            if (!$result['success']) {
                return $result;
            }

            Log::info('Paytm Dynamic QR Code generated successfully', [
                'order_id' => $order->id,
                'amount' => $amount,
                'qr_code_id' => $result['data']['qr_code_id'] ?? 'N/A'
            ]);

            return $result;

        } catch (Exception $e) {
            Log::error('Failed to generate QR code for order', [
                'order_id' => $order->id ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to generate QR code: ' . $e->getMessage(),
                'error_type' => 'system_error'
            ];
        }
    }

    /**
     * Generate Paytm Dynamic QR Code using Paytm API
     *
     * This creates an order-specific QR code where:
     * - Money goes to Paytm PG account (not direct UPI)
     * - Webhook is sent when payment is received
     * - Money is settled to bank (T+1/T+2)
     *
     * @param Order $order
     * @param float $amount
     * @return array
     */
    private static function generateDynamicQRCode(Order $order, float $amount): array
    {
        try {
            // Get Paytm credentials
            $credentials = Paytm::get_credentials();

            if (empty($credentials['paytm_merchant_id']) || empty($credentials['paytm_merchant_key'])) {
                return [
                    'success' => false,
                    'error' => 'Paytm merchant credentials not configured',
                    'error_type' => 'configuration_error'
                ];
            }

            $merchantId = $credentials['paytm_merchant_id'];
            $merchantKey = $credentials['paytm_merchant_key'];
            $environment = $credentials['paytm_payment_mode'] ?? 'test';

            // Determine API endpoint based on environment
            $apiUrl = $environment === 'live'
                ? 'https://secure.paytmpayments.com/paymentservices/qr/create'
                : 'https://securestage.paytmpayments.com/paymentservices/qr/create';

            // Prepare unique order ID for Paytm to avoid conflicts with other payment attempts
            // We append a timestamp to make it unique, but keep the numeric ID at start
            // so our webhook can easily extract the original order ID using (int)
            $paytmOrderId = $order->id . '_' . time();

            // Prepare request body
            $requestBody = [
                'mid' => $merchantId,
                'orderId' => $paytmOrderId,
                'amount' => number_format($amount, 2, '.', ''),
                'businessType' => 'UPI_QR_CODE',
                'posId' => 'ZENFOO_' . $order->id // Point of Sale ID
            ];

            // Use a consistent JSON string for both checksum and body
            // This is CRITICAL for Paytm as they are very sensitive to JSON formatting/whitespace
            $jsonRequestBody = json_encode($requestBody, JSON_UNESCAPED_SLASHES);

            // Generate checksum on the EXACT JSON string that will be sent in the 'body' field
            $checksum = Paytm::generateSignature($jsonRequestBody, $merchantKey);

            $payload = [
                'head' => [
                    'clientId' => $merchantId,
                    'version' => 'v1',
                    'tokenType' => 'CHECKSUM',
                    'signature' => $checksum
                ],
                'body' => $requestBody
            ];

            Log::info('Calling Paytm Dynamic QR API', [
                'order_id' => $order->id,
                'paytm_order_id' => $paytmOrderId,
                'amount' => $amount,
                'merchant_id' => $merchantId,
                'api_url' => $apiUrl,
                'request_body' => $requestBody,
                'checksum_first_20' => substr($checksum, 0, 20) . '...'
            ]);

            // Make API request to Paytm with manual JSON encoding to ensure consistency
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])
            ->withOptions([
                'verify' => false, // Disable SSL verification for local development
            ])
            ->withBody(json_encode($payload, JSON_UNESCAPED_SLASHES), 'application/json')
            ->post($apiUrl);

            // Check if request was successful
            if (!$response->successful()) {
                Log::error('Paytm API request failed', [
                    'status' => $response->status(),
                    'response' => $response->body()
                ]);

                return [
                    'success' => false,
                    'error' => 'Paytm API request failed',
                    'error_type' => 'api_error',
                    'api_response' => $response->body()
                ];
            }

            $responseData = $response->json();

            // Check API response status ('S' or 'SUCCESS' both mean success)
            $resultStatus = $responseData['body']['resultInfo']['resultStatus'] ?? '';
            if ($resultStatus !== 'S' && $resultStatus !== 'SUCCESS') {

                $errorMsg = $responseData['body']['resultInfo']['resultMsg'] ?? 'Unknown error';

                Log::error('Paytm QR generation failed', [
                    'order_id' => $order->id,
                    'error' => $errorMsg,
                    'response' => $responseData
                ]);

                return [
                    'success' => false,
                    'error' => 'Paytm QR generation failed: ' . $errorMsg,
                    'error_type' => 'paytm_error',
                    'paytm_response' => $responseData
                ];
            }

            // Extract QR code data from response
            $qrCodeData = $responseData['body'] ?? [];
            $qrCodeId = $qrCodeData['qrCodeId'] ?? null;
            $qrCodeImage = $qrCodeData['image'] ?? null; // Base64 encoded image
            $qrCodeString = $qrCodeData['qrData'] ?? null; // UPI string

            Log::info('Paytm Dynamic QR created successfully', [
                'order_id' => $order->id,
                'qr_code_id' => $qrCodeId,
                'has_image' => !empty($qrCodeImage)
            ]);

            return [
                'success' => true,
                'data' => [
                    'order_id' => $order->id,
                    'amount' => $amount,
                    'currency' => 'INR',
                    'qr_code_id' => $qrCodeId,
                    'qr_code_string' => $qrCodeString,
                    'qr_image_base64' => $qrCodeImage ? 'data:image/png;base64,' . $qrCodeImage : null,
                    'qr_type' => 'paytm_dynamic',
                    'payment_gateway' => 'paytm',
                    'instructions' => [
                        'Ask customer to scan QR code using any UPI app',
                        'Payment will go to Paytm Payment Gateway account',
                        'You will receive notification when payment is confirmed',
                        'Order will be automatically marked as paid'
                    ],
                    'paytm_response' => $responseData
                ]
            ];

        } catch (Exception $e) {
            Log::error('Exception in Paytm Dynamic QR generation', [
                'order_id' => $order->id ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Exception: ' . $e->getMessage(),
                'error_type' => 'exception'
            ];
        }
    }

    /**
     * Get merchant VPA and details for UPI QR code
     *
     * @return array
     */
    private static function getMerchantDetails(): array
    {
        try {
            // Get Paytm environment
            $environment = Setting::get_value('paytm_environment') ?? 'test';
            $prefix = $environment === 'live' ? 'paytm_live' : 'paytm_test';

            // Get merchant ID (which might be used to construct VPA)
            $merchantId = Setting::get_value($prefix . '_merchant_id');

            if (empty($merchantId)) {
                return [
                    'success' => false,
                    'error' => 'Paytm merchant ID not configured'
                ];
            }

            // Get or construct merchant UPI VPA
            // Option 1: If admin has configured a specific VPA/UPI ID
            $merchantVPA = Setting::get_value('paytm_merchant_vpa')
                ?? Setting::get_value('merchant_upi_id')
                ?? Setting::get_value('business_upi_id');

            // Option 2: If no VPA configured, construct from merchant ID
            // Note: Paytm merchants get VPA like: merchantid@paytm
            if (empty($merchantVPA)) {
                // Clean merchant ID (remove special characters)
                $cleanMerchantId = preg_replace('/[^a-zA-Z0-9]/', '', $merchantId);
                $merchantVPA = strtolower($cleanMerchantId) . '@paytm';
            }

            // Get merchant/business name
            $merchantName = Setting::get_value('business_name')
                ?? Setting::get_value('store_name')
                ?? 'Zenfoo';

            return [
                'success' => true,
                'vpa' => $merchantVPA,
                'name' => $merchantName,
                'merchant_id' => $merchantId,
                'environment' => $environment
            ];

        } catch (Exception $e) {
            Log::error('Failed to get merchant details', [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to retrieve merchant configuration'
            ];
        }
    }

    /**
     * Calculate total amount to be paid for order
     *
     * @param Order $order
     * @return float
     */
    private static function calculateOrderAmount(Order $order): float
    {
        // Use final_total which includes all charges
        return floatval($order->final_total ?? 0);
    }

    /**
     * Generate UPI payment string
     *
     * UPI String Format: upi://pay?pa=VPA&pn=NAME&am=AMOUNT&tr=REF&tn=NOTE&cu=INR
     *
     * @param string $vpa Virtual Payment Address (UPI ID)
     * @param string $payeeName Merchant/Business name
     * @param float $amount Amount to be paid
     * @param string $transactionRef Transaction reference (order ID)
     * @param string $transactionNote Transaction description
     * @return string
     */
    private static function generateUPIString(
        string $vpa,
        string $payeeName,
        float $amount,
        string $transactionRef,
        string $transactionNote
    ): string {
        // Build UPI payment URL according to NPCI standards
        $params = [
            'pa' => $vpa,                           // Payee Address (UPI ID)
            'pn' => urlencode($payeeName),          // Payee Name
            'am' => number_format($amount, 2, '.', ''), // Amount
            'tr' => $transactionRef,                // Transaction Reference
            'tn' => urlencode($transactionNote),    // Transaction Note
            'cu' => 'INR'                           // Currency
        ];

        $queryString = http_build_query($params);

        return "upi://pay?" . $queryString;
    }

    /**
     * Generate QR code image from UPI string
     *
     * Uses SimpleSoftwareIO QR Code library to generate QR images
     *
     * @param string $upiString
     * @param array $options
     * @return array
     */
    private static function generateQRImage(string $upiString, array $options = []): array
    {
        try {
            // Check if SimpleSoftwareIO QR Code package is available
            if (!class_exists('\SimpleSoftwareIO\QrCode\Generator')) {
                return [
                    'success' => false,
                    'error' => 'QR code library not installed. Run: composer require simplesoftwareio/simple-qrcode',
                    'error_type' => 'library_missing'
                ];
            }

            // Generate QR code image
            $size = $options['size'] ?? 300; // Default 300x300 pixels
            $format = $options['format'] ?? 'svg'; // Use SVG by default (no PHP extensions needed)

            // Create QR code instance
            $qrCodeGenerator = new \SimpleSoftwareIO\QrCode\Generator();

            // Generate QR code as SVG (works without imagick or gd extensions)
            $qrCode = $qrCodeGenerator
                ->format('svg')
                ->size($size)
                ->errorCorrection('H') // High error correction for better scanning
                ->margin(2)
                ->generate($upiString);

            // Convert to base64 for easy transmission to mobile app
            // SVG is text-based and can be embedded directly in HTML or mobile apps
            $base64 = base64_encode($qrCode);

            // Determine data URI format
            $mimeType = 'image/svg+xml';
            $dataUriFormat = 'svg+xml';

            // Optionally save to storage and return URL
            $imagePath = null;
            $imageUrl = null;

            if ($options['save_to_storage'] ?? false) {
                $filename = 'qr_order_' . time() . '_' . uniqid() . '.png';
                $path = storage_path('app/public/qr_codes/' . $filename);

                // Create directory if it doesn't exist
                if (!file_exists(dirname($path))) {
                    mkdir(dirname($path), 0755, true);
                }

                file_put_contents($path, $qrCode);
                $imagePath = $path;
                $imageUrl = url('storage/qr_codes/' . $filename);
            }

            return [
                'success' => true,
                'image_base64' => 'data:' . $mimeType . ';base64,' . $base64,
                'image_svg' => $qrCode, // Raw SVG for direct use
                'image_path' => $imagePath,
                'image_url' => $imageUrl,
                'size' => $size,
                'format' => 'svg'
            ];

        } catch (Exception $e) {
            Log::error('Failed to generate QR image', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to generate QR image: ' . $e->getMessage(),
                'error_type' => 'generation_error'
            ];
        }
    }

    /**
     * Validate QR code can be generated for order
     *
     * @param Order $order
     * @return array
     */
    public static function validateOrderForQR(Order $order): array
    {
        $errors = [];

        // Check order status
        if (in_array($order->order_status, ['cancelled', 'refunded', 'failed'])) {
            $errors[] = 'Cannot generate QR for cancelled/refunded orders';
        }

        // Check if order is already paid
        if ($order->payment_status === 'paid' || $order->payment_status === 'success') {
            $errors[] = 'Order is already paid';
        }

        // Check if order has valid amount
        if ($order->final_total <= 0) {
            $errors[] = 'Order amount is invalid';
        }

        // Check merchant configuration
        $merchantDetails = self::getMerchantDetails();
        if (!$merchantDetails['success']) {
            $errors[] = $merchantDetails['error'];
        }

        return [
            'valid' => empty($errors),
            'errors' => $errors
        ];
    }

    /**
     * Get merchant static QR code (if available)
     * Returns the static merchant QR code that can be used for any payment
     *
     * @return array
     */
    public static function getMerchantStaticQR(): array
    {
        try {
            $merchantDetails = self::getMerchantDetails();

            if (!$merchantDetails['success']) {
                return [
                    'success' => false,
                    'error' => $merchantDetails['error']
                ];
            }

            // Generate UPI string without amount (customer enters amount manually)
            $params = [
                'pa' => $merchantDetails['vpa'],
                'pn' => urlencode($merchantDetails['name']),
                'cu' => 'INR'
            ];

            $upiString = "upi://pay?" . http_build_query($params);

            return [
                'success' => true,
                'data' => [
                    'upi_string' => $upiString,
                    'merchant_vpa' => $merchantDetails['vpa'],
                    'merchant_name' => $merchantDetails['name'],
                    'qr_type' => 'static',
                    'instructions' => [
                        'This is a static QR code for your merchant account',
                        'Customers can scan and enter any amount',
                        'Not linked to specific orders - manual reconciliation needed'
                    ]
                ]
            ];

        } catch (Exception $e) {
            Log::error('Failed to generate static QR', [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to generate static QR: ' . $e->getMessage()
            ];
        }
    }
}
