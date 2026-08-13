<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;

/**
 * Service for syncing Order ETA data to Firestore
 *
 * Collection: order_eta
 * Document: {order_id}
 * Fields: eta, stored_at, delayed_time
 */
class FirestoreOrderETAService
{
    /**
     * Firestore collection name for order ETA
     */
    private const COLLECTION_NAME = 'order_eta';

    /**
     * Firestore REST API base URL
     */
    private const FIRESTORE_BASE_URL = 'https://firestore.googleapis.com/v1';

    /**
     * Get Firebase service account credentials
     *
     * @return array|null
     */
    private static function getServiceAccountCredentials(): ?array
    {
        try {
            $filePath = base_path('config/firebase.json');

            if (!file_exists($filePath)) {
                Log::error('FirestoreOrderETAService: Firebase service account file not found');
                return null;
            }

            $credentials = json_decode(file_get_contents($filePath), true);

            if (!$credentials || !isset($credentials['project_id'])) {
                Log::error('FirestoreOrderETAService: Invalid Firebase service account file');
                return null;
            }

            return $credentials;
        } catch (\Exception $e) {
            Log::error('FirestoreOrderETAService: Failed to read Firebase credentials', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Generate JWT token for Firebase authentication
     *
     * @param array $credentials Service account credentials
     * @return string|null
     */
    private static function generateJwtToken(array $credentials): ?string
    {
        try {
            $now = time();
            $expiry = $now + 3600; // 1 hour

            // JWT Header
            $header = [
                'alg' => 'RS256',
                'typ' => 'JWT'
            ];

            // JWT Payload
            $payload = [
                'iss' => $credentials['client_email'],
                'sub' => $credentials['client_email'],
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $expiry,
                'scope' => 'https://www.googleapis.com/auth/datastore'
            ];

            // Base64 URL encode
            $base64Header = self::base64UrlEncode(json_encode($header));
            $base64Payload = self::base64UrlEncode(json_encode($payload));

            // Create signature
            $signatureInput = $base64Header . '.' . $base64Payload;
            $privateKey = $credentials['private_key'];

            openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
            $base64Signature = self::base64UrlEncode($signature);

            return $base64Header . '.' . $base64Payload . '.' . $base64Signature;
        } catch (\Exception $e) {
            Log::error('FirestoreOrderETAService: Failed to generate JWT token', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Base64 URL encode
     *
     * @param string $data
     * @return string
     */
    private static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Get OAuth2 access token using JWT
     *
     * @return string|null
     */
    private static function getAccessToken(): ?string
    {
        try {
            // Check cache first
            $cachedToken = Cache::get('firestore_access_token');
            if ($cachedToken) {
                return $cachedToken;
            }

            $credentials = self::getServiceAccountCredentials();
            if (!$credentials) {
                return null;
            }

            $jwt = self::generateJwtToken($credentials);
            if (!$jwt) {
                return null;
            }

            // Exchange JWT for access token
            $response = Http::asForm()
                ->withOptions(['verify' => false])
                ->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt
                ]);

            if (!$response->successful()) {
                Log::error('FirestoreOrderETAService: Failed to get access token', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return null;
            }

            $data = $response->json();
            $accessToken = $data['access_token'] ?? null;

            if ($accessToken) {
                // Cache for 50 minutes (token expires in 60 minutes)
                Cache::put('firestore_access_token', $accessToken, now()->addMinutes(50));
            }

            return $accessToken;
        } catch (\Exception $e) {
            Log::error('FirestoreOrderETAService: Failed to get access token', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Get Firestore document path
     *
     * @param string $collection
     * @param string $documentId
     * @return string
     */
    private static function getDocumentPath(string $collection, string $documentId): string
    {
        $credentials = self::getServiceAccountCredentials();
        $projectId = $credentials['project_id'] ?? '';

        return self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/{$collection}/{$documentId}";
    }

    /**
     * Convert PHP value to Firestore value format
     *
     * @param mixed $value
     * @return array
     */
    private static function toFirestoreValue($value): array
    {
        if (is_null($value)) {
            return ['nullValue' => null];
        }
        if (is_bool($value)) {
            return ['booleanValue' => $value];
        }
        if (is_int($value)) {
            return ['integerValue' => (string) $value];
        }
        if (is_float($value)) {
            return ['doubleValue' => $value];
        }
        if (is_string($value)) {
            return ['stringValue' => $value];
        }
        if (is_array($value)) {
            // Check if it's an associative array (map) or indexed array
            if (empty($value) || array_keys($value) !== range(0, count($value) - 1)) {
                // Associative array - convert to map
                $mapValue = [];
                foreach ($value as $k => $v) {
                    $mapValue[$k] = self::toFirestoreValue($v);
                }
                return ['mapValue' => ['fields' => $mapValue]];
            } else {
                // Indexed array - convert to array
                $arrayValues = [];
                foreach ($value as $v) {
                    $arrayValues[] = self::toFirestoreValue($v);
                }
                return ['arrayValue' => ['values' => $arrayValues]];
            }
        }
        return ['stringValue' => (string) $value];
    }

    /**
     * Sync Order ETA to Firestore
     *
     * @param int $orderId
     * @param int $etaMinutes Estimated time of arrival in minutes
     * @param int $sellerCount Number of unique sellers/stores in the order
     * @return array
     */
    public static function syncOrderETA(int $orderId, int $etaMinutes, int $sellerCount = 0): array
    {
        try {
            Log::info("FirestoreOrderETAService: Syncing ETA for order_id: {$orderId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Get current time in IST (Asia/Kolkata)
            $storedAt = Carbon::now()->setTimezone('Asia/Kolkata')->format('h:i A');

            // Prepare Firestore document data
            $orderDate = Carbon::now()->setTimezone('Asia/Kolkata')->format('Y-m-d');
            $firestoreData = [
                'fields' => [
                    'eta' => self::toFirestoreValue($etaMinutes),
                    'stored_at' => self::toFirestoreValue($storedAt),
                    'delayed_time' => self::toFirestoreValue(null),
                    'order_id' => self::toFirestoreValue($orderId),
                    'seller_count' => self::toFirestoreValue($sellerCount),
                    'order_status' => self::toFirestoreValue('Your order was placed'),
                    'order_status_desc' => self::toFirestoreValue('Your order has been successfully placed'),
                    'order_date' => self::toFirestoreValue($orderDate),
                    'updated_at' => self::toFirestoreValue(Carbon::now()->setTimezone('Asia/Kolkata')->toIso8601String())
                ]
            ];

            // Create/Update document in Firestore
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $orderId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $firestoreData);

            if (!$response->successful()) {
                Log::error("FirestoreOrderETAService: Failed to sync ETA for order_id: {$orderId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to sync ETA to Firestore',
                    'error' => $response->body()
                ];
            }

            Log::info("FirestoreOrderETAService: Successfully synced ETA for order_id: {$orderId}", [
                'eta_minutes' => $etaMinutes,
                'stored_at' => $storedAt,
                'seller_count' => $sellerCount
            ]);

            return [
                'success' => true,
                'message' => 'ETA synced to Firestore successfully',
                'data' => [
                    'order_id' => $orderId,
                    'eta' => $etaMinutes,
                    'stored_at' => $storedAt,
                    'delayed_time' => null,
                    'seller_count' => $sellerCount,
                    'order_status' => 'Your order was placed',
                    'order_status_desc' => 'Your order has been successfully placed',
                    'order_date' => $orderDate
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderETAService: Exception syncing ETA for order_id: {$orderId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while syncing ETA to Firestore',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Update delayed time for an order in Firestore
     *
     * @param int $orderId
     * @param int|null $delayedMinutes Delayed time in minutes (null to clear)
     * @return array
     */
    public static function updateDelayedTime(int $orderId, ?int $delayedMinutes): array
    {
        try {
            Log::info("FirestoreOrderETAService: Updating delayed time for order_id: {$orderId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Prepare update data
            $firestoreData = [
                'fields' => [
                    'delayed_time' => self::toFirestoreValue($delayedMinutes),
                    'updated_at' => self::toFirestoreValue(Carbon::now()->setTimezone('Asia/Kolkata')->toIso8601String())
                ]
            ];

            // Update document in Firestore with field mask
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $orderId);
            $url .= '?updateMask.fieldPaths=delayed_time&updateMask.fieldPaths=updated_at';

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $firestoreData);

            if (!$response->successful()) {
                Log::error("FirestoreOrderETAService: Failed to update delayed time for order_id: {$orderId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to update delayed time in Firestore',
                    'error' => $response->body()
                ];
            }

            Log::info("FirestoreOrderETAService: Successfully updated delayed time for order_id: {$orderId}", [
                'delayed_minutes' => $delayedMinutes
            ]);

            return [
                'success' => true,
                'message' => 'Delayed time updated in Firestore successfully',
                'data' => [
                    'order_id' => $orderId,
                    'delayed_time' => $delayedMinutes
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderETAService: Exception updating delayed time for order_id: {$orderId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while updating delayed time',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Update order status in Firestore
     *
     * @param int $orderId
     * @param string $orderStatus The new order status (e.g., 'Preparing your order', 'Ready', 'Delivered')
     * @param string $orderStatusDesc The order status description
     * @return array
     */
    public static function updateOrderStatus(int $orderId, string $orderStatus, string $orderStatusDesc): array
    {
        try {
            Log::info("FirestoreOrderETAService: Updating order status for order_id: {$orderId}", [
                'new_status' => $orderStatus,
                'new_status_desc' => $orderStatusDesc
            ]);

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Prepare update data
            $firestoreData = [
                'fields' => [
                    'order_status' => self::toFirestoreValue($orderStatus),
                    'order_status_desc' => self::toFirestoreValue($orderStatusDesc),
                    'updated_at' => self::toFirestoreValue(Carbon::now()->setTimezone('Asia/Kolkata')->toIso8601String())
                ]
            ];

            // Update document in Firestore with field mask
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $orderId);
            $url .= '?updateMask.fieldPaths=order_status&updateMask.fieldPaths=order_status_desc&updateMask.fieldPaths=updated_at';

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $firestoreData);

            if (!$response->successful()) {
                Log::error("FirestoreOrderETAService: Failed to update order status for order_id: {$orderId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to update order status in Firestore',
                    'error' => $response->body()
                ];
            }

            Log::info("FirestoreOrderETAService: Successfully updated order status for order_id: {$orderId}", [
                'order_status' => $orderStatus,
                'order_status_desc' => $orderStatusDesc
            ]);

            return [
                'success' => true,
                'message' => 'Order status updated in Firestore successfully',
                'data' => [
                    'order_id' => $orderId,
                    'order_status' => $orderStatus,
                    'order_status_desc' => $orderStatusDesc
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderETAService: Exception updating order status for order_id: {$orderId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while updating order status',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Delete order ETA document from Firestore
     *
     * @param int $orderId
     * @return array
     */
    public static function deleteOrderETA(int $orderId): array
    {
        try {
            Log::info("FirestoreOrderETAService: Deleting ETA for order_id: {$orderId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $orderId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->delete($url);

            if (!$response->successful() && $response->status() !== 404) {
                Log::error("FirestoreOrderETAService: Failed to delete ETA for order_id: {$orderId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to delete ETA from Firestore'
                ];
            }

            Log::info("FirestoreOrderETAService: Successfully deleted ETA for order_id: {$orderId}");

            return [
                'success' => true,
                'message' => 'ETA deleted from Firestore successfully'
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderETAService: Exception deleting ETA for order_id: {$orderId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while deleting ETA',
                'error' => $e->getMessage()
            ];
        }
    }
}
