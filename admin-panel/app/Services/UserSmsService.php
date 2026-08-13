<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class UserSmsService
{
    /**
     * Send OTP to customer via Fast2SMS
     *
     * @param string $phone - 10 digit mobile number
     * @param string $otp - OTP to send
     * @return array - ['success' => bool, 'message' => string]
     */
    public static function sendOtp(string $phone, string $otp): array
    {
        try {
            $authKey = config('services.fast2sms.api_key');
            $senderId = config('services.fast2sms.sender_id');
            $messageId = config('services.fast2sms.customer_message_id');

            if (empty($authKey)) {
                Log::error('UserSmsService::sendOtp - Fast2SMS API key is not configured', [
                    'phone' => $phone
                ]);
                return [
                    'success' => false,
                    'message' => 'SMS service is not configured properly'
                ];
            }

            $url = 'https://www.fast2sms.com/dev/bulkV2';

            $params = [
                'authorization' => $authKey,
                'route' => 'dlt',
                'sender_id' => $senderId,
                'message' => $messageId,
                'variables_values' => $otp . '|',
                'flash' => 0,
                'numbers' => $phone,
            ];

            Log::info('UserSmsService::sendOtp - Sending OTP request', [
                'phone' => $phone,
                'sender_id' => $senderId,
                'message_id' => $messageId
            ]);

            // Disable SSL verification in dev environment (Windows dev issue)
            $http = Http::timeout(30);
            if (config('app.env') === 'local' || config('app.debug') === true) {
                $http = $http->withoutVerifying();
            }

            $response = $http->get($url, $params);

            $responseBody = $response->json();

            if ($response->successful() && isset($responseBody['return']) && $responseBody['return'] === true) {
                Log::info('UserSmsService::sendOtp - OTP sent successfully', [
                    'phone' => $phone,
                    'request_id' => $responseBody['request_id'] ?? null,
                    'message' => $responseBody['message'] ?? 'Success'
                ]);

                return [
                    'success' => true,
                    'message' => 'OTP sent successfully',
                    'request_id' => $responseBody['request_id'] ?? null
                ];
            }

            // API returned error
            $errorMessage = $responseBody['message'] ?? 'Unknown error from SMS gateway';

            Log::error('UserSmsService::sendOtp - Fast2SMS API returned error', [
                'phone' => $phone,
                'status_code' => $response->status(),
                'response' => $responseBody,
                'error_message' => $errorMessage
            ]);

            return [
                'success' => false,
                'message' => 'Failed to send OTP. Please try again later.'
            ];

        } catch (Exception $e) {
            Log::error('UserSmsService::sendOtp - Exception occurred', [
                'phone' => $phone,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'There was an issue in sending OTP. Please try again later.'
            ];
        }
    }

    /**
     * Send custom SMS to customer via Fast2SMS (Quick SMS route)
     *
     * @param string $phone - 10 digit mobile number
     * @param string $message - Message to send
     * @return array - ['success' => bool, 'message' => string]
     */
    public static function sendSms(string $phone, string $message): array
    {
        try {
            $authKey = config('services.fast2sms.api_key');

            if (empty($authKey)) {
                Log::error('UserSmsService::sendSms - Fast2SMS API key is not configured', [
                    'phone' => $phone
                ]);
                return [
                    'success' => false,
                    'message' => 'SMS service is not configured properly'
                ];
            }

            $url = 'https://www.fast2sms.com/dev/bulkV2';

            $params = [
                'authorization' => $authKey,
                'route' => 'q', // Quick SMS route
                'message' => $message,
                'flash' => 0,
                'numbers' => $phone,
            ];

            Log::info('UserSmsService::sendSms - Sending SMS request', [
                'phone' => $phone,
                'message_length' => strlen($message)
            ]);

            // Disable SSL verification in dev environment (Windows dev issue)
            $http = Http::timeout(30);
            if (config('app.env') === 'local' || config('app.debug') === true) {
                $http = $http->withoutVerifying();
            }

            $response = $http->get($url, $params);

            $responseBody = $response->json();

            if ($response->successful() && isset($responseBody['return']) && $responseBody['return'] === true) {
                Log::info('UserSmsService::sendSms - SMS sent successfully', [
                    'phone' => $phone,
                    'request_id' => $responseBody['request_id'] ?? null
                ]);

                return [
                    'success' => true,
                    'message' => 'SMS sent successfully',
                    'request_id' => $responseBody['request_id'] ?? null
                ];
            }

            $errorMessage = $responseBody['message'] ?? 'Unknown error from SMS gateway';

            Log::error('UserSmsService::sendSms - Fast2SMS API returned error', [
                'phone' => $phone,
                'status_code' => $response->status(),
                'response' => $responseBody,
                'error_message' => $errorMessage
            ]);

            return [
                'success' => false,
                'message' => 'Failed to send SMS. Please try again later.'
            ];

        } catch (Exception $e) {
            Log::error('UserSmsService::sendSms - Exception occurred', [
                'phone' => $phone,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'There was an issue in sending SMS. Please try again later.'
            ];
        }
    }
}
