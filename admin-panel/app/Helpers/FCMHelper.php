<?php

namespace App\Helpers;

use App\Models\Setting;
use App\Models\UserToken;
use App\Models\AdminToken;
use Illuminate\Support\Facades\Log;
use Exception;

/**
 * FCM Helper - Works on localhost without SSL certificate issues
 * Uses JWT for authentication instead of Google Client library
 */
class FCMHelper
{
    private static $accessToken = null;
    private static $tokenExpiry = null;

    /**
     * Send notification to a device
     */
    public static function send($platform, $deviceToken, $fcmMsg, $notification)
    {
        // Log incoming data for debugging
        Log::info("FCMHelper: Preparing notification", [
            'platform' => $platform,
            'has_image' => !empty($fcmMsg['image']),
            'image_url' => $fcmMsg['image'] ?? 'none',
            'title' => $fcmMsg['title'] ?? 'none'
        ]);

        if ($platform == "android") {
            // Android: Include notification block with image for rich notifications
            $message = [
                "token" => $deviceToken,
                "data" => self::convertToStrings($fcmMsg),
                "android" => [
                    "priority" => "high"
                ]
            ];

            // Skip android.notification block if data_only flag is set (e.g., for chat notifications)
            // This prevents duplicate notifications when Flutter app handles the data payload
            if (empty($fcmMsg['data_only'])) {
                $message["android"]["notification"] = [
                    "title" => $fcmMsg["title"] ?? '',
                    "body" => $fcmMsg["body"] ?? '',
                    "sound" => "default",
                    "click_action" => "FLUTTER_NOTIFICATION_CLICK"
                ];

                // Add image to Android notification if provided
                if (!empty($fcmMsg['image'])) {
                    $message["android"]["notification"]["image"] = $fcmMsg['image'];
                    Log::info("FCMHelper: Added image to Android notification", ['image' => $fcmMsg['image']]);
                }
            } else {
                Log::info("FCMHelper: Skipping android.notification (data_only mode)");
            }

            $fields = ["message" => $message];

        } elseif ($platform == "web") {
            // Web: Send data-only message - service worker handles notification display
            // This ensures single notification and proper click handling in all browsers
            $message = [
                "token" => $deviceToken,
                "data" => self::convertToStrings($fcmMsg),
                "webpush" => [
                    "headers" => [
                        "Urgency" => "high",
                        "TTL" => "86400"
                    ]
                ]
            ];

            Log::info("FCMHelper: Web data-only notification");

            $fields = ["message" => $message];

        } elseif ($platform == "ios") {
            // iOS: Include APNS with mutable-content for image
            $apnsPayload = [
                "aps" => [
                    "alert" => [
                        "title" => $fcmMsg["title"] ?? '',
                        "body" => $fcmMsg["body"] ?? ''
                    ],
                    "sound" => isset($fcmMsg["type"]) && ($fcmMsg["type"] == "new_order" || $fcmMsg["type"] == "assign_order")
                        ? "order_sound.aiff"
                        : "default",
                    "mutable-content" => 1
                ]
            ];

            $message = [
                "token" => $deviceToken,
                "data" => self::convertToStrings($fcmMsg),
                "notification" => [
                    "title" => $fcmMsg["title"] ?? '',
                    "body" => $fcmMsg["body"] ?? '',
                ],
                "apns" => [
                    "payload" => $apnsPayload,
                    "fcm_options" => []
                ]
            ];

            // Add image to iOS notification if provided
            if (!empty($fcmMsg['image'])) {
                $message["apns"]["fcm_options"]["image"] = $fcmMsg['image'];
                Log::info("FCMHelper: Added image to iOS notification", ['image' => $fcmMsg['image']]);
            }

            $fields = ["message" => $message];

        } else {
            Log::error("FCMHelper: Invalid platform specified: {$platform}");
            return false;
        }

        // Log the final payload being sent
        Log::info("FCMHelper: Final FCM payload", [
            'platform' => $platform,
            'payload' => json_encode($fields)
        ]);

        return self::sendPushNotification($fields);
    }

    /**
     * Send push notification to FCM
     */
    public static function sendPushNotification($fields)
    {
        $accessToken = self::getAccessToken();

        if (!$accessToken) {
            Log::error("FCMHelper: Failed to get access token");
            return false;
        }

        $projectID = optional(Setting::where('variable', 'projectId')->first())->value;

        if (!$projectID) {
            Log::error("FCMHelper: Firebase project ID not found in settings.");
            return false;
        }

        $url = 'https://fcm.googleapis.com/v1/projects/' . $projectID . '/messages:send';

        $headers = [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));

        // Disable SSL verification for localhost
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($ch);

        if ($result === false) {
            Log::error('FCMHelper: cURL request failed: ' . curl_error($ch));
            curl_close($ch);
            return false;
        }

        curl_close($ch);

        $response = json_decode($result, true);

        // Handle invalid/expired tokens
        if (isset($response['error'])) {
            $errorCode = $response['error']['code'] ?? null;
            $errorStatus = $response['error']['status'] ?? '';
            $errorMessage = $response['error']['message'] ?? '';
            $fcmErrorCode = '';

            // Extract FCM-specific error code from details
            if (isset($response['error']['details'])) {
                foreach ($response['error']['details'] as $detail) {
                    if (isset($detail['errorCode'])) {
                        $fcmErrorCode = $detail['errorCode'];
                        break;
                    }
                }
            }

            Log::error("FCMHelper: Push notification failed", [
                'error_code' => $errorCode,
                'error_status' => $errorStatus,
                'error_message' => $errorMessage,
                'fcm_error_code' => $fcmErrorCode,
                'token' => substr($fields['message']['token'] ?? '', 0, 30) . '...'
            ]);

            // Delete token if it's invalid/unregistered/expired
            $shouldDeleteToken = (
                $errorCode == 404 ||
                $errorCode == 400 ||
                $errorCode == 401 ||
                $errorStatus == 'NOT_FOUND' ||
                $errorStatus == 'UNAUTHENTICATED' ||
                $fcmErrorCode == 'THIRD_PARTY_AUTH_ERROR' ||
                $fcmErrorCode == 'UNREGISTERED' ||
                strpos($errorMessage, 'NotRegistered') !== false ||
                strpos($errorMessage, 'not a valid FCM') !== false
            );

            if ($shouldDeleteToken) {
                $token = $fields['message']['token'];
                $deletedUser = UserToken::where('fcm_token', $token)->delete();
                $deletedAdmin = AdminToken::where('fcm_token', $token)->delete();
                Log::warning("FCMHelper: Deleted invalid/expired FCM token", [
                    'token' => substr($token, 0, 30) . '...',
                    'reason' => $fcmErrorCode ?: $errorStatus ?: $errorMessage,
                    'deleted_user_tokens' => $deletedUser,
                    'deleted_admin_tokens' => $deletedAdmin
                ]);
            }
        } else {
            Log::info('FCMHelper: Push notification sent successfully', [
                'message_name' => $response['name'] ?? 'unknown'
            ]);
        }

        Log::info('FCMHelper: Push notification response', ['response' => $response]);

        return $response;
    }

    /**
     * Get OAuth2 access token using JWT
     */
    private static function getAccessToken()
    {
        // Return cached token if still valid
        if (self::$accessToken && self::$tokenExpiry && time() < self::$tokenExpiry) {
            return self::$accessToken;
        }

        $filePath = base_path('config/firebase.json');

        if (!file_exists($filePath)) {
            throw new Exception('FCMHelper: Service account file not found');
        }

        $serviceAccount = json_decode(file_get_contents($filePath), true);

        // Create JWT
        $jwt = self::createJWT($serviceAccount);

        // Exchange JWT for access token
        $accessToken = self::exchangeJWTForToken($jwt);

        if ($accessToken) {
            self::$accessToken = $accessToken;
            self::$tokenExpiry = time() + 3500; // Token valid for ~1 hour, refresh at 58 mins
        }

        return $accessToken;
    }

    /**
     * Create JWT for Google OAuth2
     */
    private static function createJWT($serviceAccount)
    {
        $header = [
            'alg' => 'RS256',
            'typ' => 'JWT'
        ];

        $now = time();
        $claim = [
            'iss' => $serviceAccount['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600
        ];

        $headerEncoded = self::base64UrlEncode(json_encode($header));
        $claimEncoded = self::base64UrlEncode(json_encode($claim));

        $signatureInput = $headerEncoded . '.' . $claimEncoded;

        // Sign with private key
        $privateKey = $serviceAccount['private_key'];
        openssl_sign($signatureInput, $signature, $privateKey, 'SHA256');

        $signatureEncoded = self::base64UrlEncode($signature);

        return $headerEncoded . '.' . $claimEncoded . '.' . $signatureEncoded;
    }

    /**
     * Exchange JWT for OAuth2 access token
     */
    private static function exchangeJWTForToken($jwt)
    {
        $url = 'https://oauth2.googleapis.com/token';

        $postData = http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt
        ]);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/x-www-form-urlencoded'
        ]);

        // Disable SSL verification for localhost
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

        $result = curl_exec($ch);

        if ($result === false) {
            Log::error('FCMHelper: Token exchange failed: ' . curl_error($ch));
            curl_close($ch);
            return null;
        }

        curl_close($ch);

        $response = json_decode($result, true);

        if (isset($response['access_token'])) {
            Log::info('FCMHelper: Access token obtained successfully');
            return $response['access_token'];
        }

        Log::error('FCMHelper: Failed to get access token', ['response' => $response]);
        return null;
    }

    /**
     * Base64 URL encode (JWT compatible)
     */
    private static function base64UrlEncode($data)
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Convert all values to strings (FCM data payload requirement)
     */
    private static function convertToStrings($data)
    {
        $result = [];
        foreach ($data as $key => $value) {
            $result[$key] = is_array($value) ? json_encode($value) : (string) $value;
        }
        return $result;
    }
}