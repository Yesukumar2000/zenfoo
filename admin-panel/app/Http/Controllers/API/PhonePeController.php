<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Helpers\PhonePeHelper;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redirect;
use Illuminate\Support\Facades\Http;


class PhonePeController extends Controller
{
    private $merchantId;
    private $clientId;
    private $clientSecret;
    private $apiBaseUrl;
    private $isProduction;

    public function __construct()
    {
        // PhonePe Credentials from config (using Client ID and Client Secret)
        $this->merchantId = config('services.phonepe.merchant_id', 'M23TSU3JHDUZ0');
        $this->clientId = config('services.phonepe.client_id', 'M23TSU3JHDUZ0_2601211145');
        $this->clientSecret = config('services.phonepe.client_secret', 'MTIyNTBkNTMtNTY3MC00ZWJmLWFjMTYtY2E5ZmNjNTliOWYw');
        $this->isProduction = config('services.phonepe.is_production', false);

        // Use sandbox for testing, production for live
        $this->apiBaseUrl = $this->isProduction
            ? 'https://api.phonepe.com/apis/hermes'
            : 'https://api-preprod.phonepe.com/apis/pg-sandbox';
    }

    /**
     * Initiate PhonePe Payment
     */
    public function initiatePayment(Request $request)
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'amount' => 'required|numeric|min:1',
                'user_id' => 'required|string',
                'mobile_number' => 'required|string|min:10|max:10',
                'payment_mode' => 'nullable|string|in:UPI,CARD,WALLET',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Validation failed',
                    'total' => 0,
                    'errors' => $validator->errors(),
                ], 422);
            }

            $validated = $validator->validated();

            // Generate unique transaction ID
            $transactionId = 'TXN_' . $validated['user_id'] . '_' . time() . '_' . rand(1000, 9999);

            // Convert amount to paise
            $amountInPaise = (int) ($validated['amount'] * 100);

            // Create payload for PhonePe API
            $payload = [
                'merchantId' => $this->merchantId,
                'merchantTransactionId' => $transactionId,
                'merchantUserId' => 'USER_' . $validated['user_id'],
                'amount' => $amountInPaise,
                'redirectUrl' => url('/phonepe/redirect'),
                'redirectMode' => 'POST',
                'callbackUrl' => url('/api/phonepe/callback'),
                'mobileNumber' => $validated['mobile_number'],
                'paymentInstrument' => [
                    'type' => 'PAY_PAGE',
                ],
            ];

            Log::info('PhonePe Payment Initiation:', [
                'transaction_id' => $transactionId,
                'amount' => $validated['amount'],
                'user_id' => $validated['user_id'],
            ]);

            // Encode payload to base64
            $base64Payload = base64_encode(json_encode($payload));

            // Generate checksum
            $checksum = $this->generateChecksum($base64Payload);

            // Call PhonePe API
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
                'X-VERIFY' => $checksum,
            ])->post($this->apiBaseUrl . '/pg/v1/pay', [
                        'request' => $base64Payload,
                    ]);

            $responseData = $response->json();

            Log::info('PhonePe API Response:', $responseData);

            // Check if API call was successful
            if ($response->successful() && isset($responseData['success']) && $responseData['success']) {
                // Extract redirect URL with token
                $redirectUrl = $responseData['data']['instrumentResponse']['redirectInfo']['url'] ?? null;

                if (!$redirectUrl) {
                    Log::error('PhonePe: No redirect URL in response', $responseData);
                    return response()->json([
                        'status' => 0,
                        'message' => 'Failed to get payment URL from PhonePe',
                        'total' => 0,
                    ], 500);
                }

                // Parse token from URL (format: phonepe://pay?token=xxx&orderId=yyy)
                $urlParts = parse_url($redirectUrl);
                parse_str($urlParts['query'] ?? '', $queryParams);

                $token = $queryParams['token'] ?? null;

                if (!$token) {
                    Log::error('PhonePe: No token in redirect URL', ['url' => $redirectUrl]);
                    return response()->json([
                        'status' => 0,
                        'message' => 'Failed to extract payment token',
                        'total' => 0,
                    ], 500);
                }

                // Return token for Flutter SDK
                return response()->json([
                    'status' => 1,
                    'message' => 'success',
                    'total' => 1,
                    'data' => [
                        'orderId' => $transactionId,
                        'token' => $token,
                        'paymentMode' => $validated['payment_mode'] ?? 'UPI',
                        'merchantId' => $this->merchantId,
                        'amount' => $validated['amount'],
                    ],
                ]);

            } else {
                $errorMessage = $responseData['message'] ?? 'Payment initiation failed';
                $errorCode = $responseData['code'] ?? 'UNKNOWN_ERROR';

                Log::error('PhonePe API Error:', [
                    'code' => $errorCode,
                    'message' => $errorMessage,
                ]);

                return response()->json([
                    'status' => 0,
                    'message' => $errorMessage,
                    'total' => 0,
                ], 400);
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Payment Exception:', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to initiate payment: ' . $e->getMessage(),
                'total' => 0,
            ], 500);
        }
    }

    /**
     * PhonePe Callback Handler
     */
    public function callback(Request $request)
    {
        try {
            Log::info('PhonePe Callback Received:', $request->all());

            $base64Response = $request->input('response');
            $receivedChecksum = $request->header('X-VERIFY');

            if (!$base64Response || !$receivedChecksum) {
                return response()->json(['status' => 0, 'message' => 'Invalid callback'], 400);
            }

            // Verify checksum using Client Secret
            $calculatedChecksum = hash('sha256', $base64Response . '/pg/v1/status' . $this->clientSecret) . '###1';

            if ($calculatedChecksum !== $receivedChecksum) {
                Log::error('PhonePe Callback: Checksum mismatch');
                return response()->json(['status' => 0, 'message' => 'Invalid checksum'], 400);
            }

            // Decode response
            $response = json_decode(base64_decode($base64Response), true);

            $transactionId = $response['data']['merchantTransactionId'] ?? null;
            $paymentStatus = $response['code'] ?? null;

            if ($paymentStatus === 'PAYMENT_SUCCESS') {
                $amount = ($response['data']['amount'] ?? 0) / 100;

                // TODO: Update wallet balance in your database
                Log::info('PhonePe Payment Success:', [
                    'transaction_id' => $transactionId,
                    'amount' => $amount,
                ]);

                return response()->json([
                    'status' => 1,
                    'message' => 'Payment successful',
                ]);
            } else {
                Log::info('PhonePe Payment Failed/Pending:', [
                    'transaction_id' => $transactionId,
                    'status' => $paymentStatus,
                ]);

                return response()->json([
                    'status' => 0,
                    'message' => 'Payment failed or pending',
                ]);
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Callback Exception:', ['error' => $e->getMessage()]);
            return response()->json(['status' => 0, 'message' => 'Callback error'], 500);
        }
    }

    /**
     * PhonePe Redirect Handler
     */
    public function redirect(Request $request)
    {
        Log::info('PhonePe Redirect:', $request->all());
        return response()->json(['status' => 1, 'message' => 'Payment processed']);
    }

    /**
     * Generate SHA256 checksum using Client Secret
     */
    private function generateChecksum($base64Payload)
    {
        $string = $base64Payload . '/pg/v1/pay' . $this->clientSecret;
        return hash('sha256', $string) . '###1';
    }
}
