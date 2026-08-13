<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class FirestoreOrderSellerTrackingService
{
    /**
     * Firestore collection name for seller orders
     */
    private const COLLECTION_NAME = 'seller_orders';

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
                Log::error('Firebase service account file not found');
                return null;
            }

            $credentials = json_decode(file_get_contents($filePath), true);

            if (!$credentials || !isset($credentials['project_id'])) {
                Log::error('Invalid Firebase service account file');
                return null;
            }

            return $credentials;
        } catch (\Exception $e) {
            Log::error('Failed to read Firebase credentials', [
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
            Log::error('Failed to generate JWT token', [
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
                Log::error('Failed to get access token', [
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
            Log::error('Failed to get access token', [
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
            if (array_keys($value) !== range(0, count($value) - 1)) {
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
     * Get existing orders for a seller from Firestore
     *
     * @param string $accessToken The access token
     * @param int $sellerId The seller ID
     * @return array Existing orders map
     */
    private static function getSellerOrders(string $accessToken, int $sellerId): array
    {
        try {
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $sellerId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($url);

            if (!$response->successful()) {
                // Document doesn't exist yet, return empty array
                return [];
            }

            $data = $response->json();
            $ordersField = $data['fields']['orders'] ?? null;

            if (!$ordersField) {
                return [];
            }

            // Parse mapValue fields back to simple array
            if (isset($ordersField['mapValue']['fields'])) {
                $orders = [];
                foreach ($ordersField['mapValue']['fields'] as $key => $value) {
                    // Extract the map value from the Firestore format
                    if (isset($value['mapValue']['fields'])) {
                        $orderData = [];
                        foreach ($value['mapValue']['fields'] as $fieldKey => $fieldValue) {
                            if (isset($fieldValue['integerValue'])) {
                                $orderData[$fieldKey] = (int) $fieldValue['integerValue'];
                            } elseif (isset($fieldValue['stringValue'])) {
                                $orderData[$fieldKey] = $fieldValue['stringValue'];
                            } elseif (isset($fieldValue['doubleValue'])) {
                                $orderData[$fieldKey] = $fieldValue['doubleValue'];
                            }
                        }
                        $orders[$key] = $orderData;
                    }
                }
                return $orders;
            }

            return [];
        } catch (\Exception $e) {
            Log::warning('Failed to get existing orders for seller', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);
            return [];
        }
    }

    /**
     * Sync order seller tracking data to Firestore
     * Creates/updates documents with seller_id as the document ID
     * Each seller document contains a map of their orders
     *
     * Structure in Firestore:
     * seller_orders (collection)
     *   └── {seller_id} (document)
     *         └── orders: {
     *               "order_123": {
     *                 order_id: 123,
     *                 store_id: 15,
     *                 status: "assigned_to_seller",
     *                 otp: "1234",
     *                 is_zenfoo_store: 0,
     *                 store_location_id: 0,
     *                 created_at: "2024-01-13T10:30:00",
     *                 updated_at: "2024-01-13T10:30:00"
     *               },
     *               "order_124": {...},
     *               ...
     *             }
     *             updated_at: "2024-01-13T10:30:00"
     *
     * @param int $orderId The order ID
     * @return array Result with success status and message
     */
    public static function syncOrderSellerTracking(int $orderId): array
    {
        Log::info('FirestoreOrderSellerTracking - Starting sync process', [
            'order_id' => $orderId,
            'method' => 'syncOrderSellerTracking'
        ]);

        try {
            // Get access token
            Log::info('FirestoreOrderSellerTracking - Requesting access token', [
                'order_id' => $orderId
            ]);

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                Log::error('FirestoreOrderSellerTracking - Failed to get access token', [
                    'order_id' => $orderId
                ]);
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            Log::info('FirestoreOrderSellerTracking - Access token obtained successfully', [
                'order_id' => $orderId
            ]);

            // Get order seller tracking data from database
            Log::info('FirestoreOrderSellerTracking - Querying order_seller_status_tracking table', [
                'order_id' => $orderId
            ]);

            $trackingData = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get();

            Log::info('FirestoreOrderSellerTracking - Query completed', [
                'order_id' => $orderId,
                'records_found' => $trackingData->count()
            ]);

            if ($trackingData->isEmpty()) {
                Log::warning('FirestoreOrderSellerTracking - No tracking data found', [
                    'order_id' => $orderId
                ]);
                return [
                    'success' => false,
                    'message' => 'No tracking data found for this order'
                ];
            }

            $successCount = 0;
            $failedCount = 0;
            $sellerIds = [];

            // Process each seller
            Log::info('FirestoreOrderSellerTracking - Processing sellers', [
                'order_id' => $orderId,
                'total_records' => $trackingData->count()
            ]);

            foreach ($trackingData as $index => $record) {
                $sellerId = $record->seller_id;

                Log::info('FirestoreOrderSellerTracking - Processing record', [
                    'order_id' => $orderId,
                    'record_index' => $index + 1,
                    'seller_id' => $sellerId,
                    'store_id' => $record->store_id,
                    'status' => $record->status,
                    'is_zenfoo_store' => $record->is_zenfoo_store
                ]);

                // Skip if seller_id is null (Zenfoo store entries)
                if (is_null($sellerId)) {
                    Log::info('FirestoreOrderSellerTracking - Skipping record with null seller_id (Zenfoo store)', [
                        'order_id' => $orderId,
                        'record_index' => $index + 1,
                        'store_id' => $record->store_id
                    ]);
                    continue;
                }

                $sellerIds[] = $sellerId;

                // Get existing orders for this seller
                Log::info('FirestoreOrderSellerTracking - Fetching existing orders for seller', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId
                ]);

                $existingOrders = self::getSellerOrders($accessToken, $sellerId);

                Log::info('FirestoreOrderSellerTracking - Existing orders fetched', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'existing_orders_count' => count($existingOrders),
                    'existing_order_keys' => array_keys($existingOrders)
                ]);

                // Add/update this order in the seller's orders map
                $orderKey = "order_{$orderId}";
                $existingOrders[$orderKey] = [
                    'order_id' => (int) $orderId,
                    'store_id' => (int) $record->store_id,
                    'status' => $record->status,
                    'otp' => $record->otp,
                    'is_zenfoo_store' => (int) $record->is_zenfoo_store,
                    'store_location_id' => (int) $record->store_location_id,
                    'created_at' => $record->created_at,
                    'updated_at' => $record->updated_at,
                ];

                Log::info('FirestoreOrderSellerTracking - Order data prepared for seller', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'order_key' => $orderKey,
                    'total_orders_in_map' => count($existingOrders)
                ]);

                // Build Firestore document data
                $documentData = [
                    'fields' => [
                        'seller_id' => self::toFirestoreValue($sellerId),
                        'orders' => self::toFirestoreValue($existingOrders),
                        'updated_at' => self::toFirestoreValue(now()->toIso8601String()),
                    ]
                ];

                // Make REST API call to create/update seller document
                $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $sellerId);

                Log::info('FirestoreOrderSellerTracking - Sending PATCH request to Firestore', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'url' => $url,
                    'collection' => self::COLLECTION_NAME
                ]);

                $response = Http::withToken($accessToken)
                    ->withOptions(['verify' => false])
                    ->patch($url, $documentData);

                if ($response->successful()) {
                    $successCount++;
                    Log::info('FirestoreOrderSellerTracking - Order successfully added to seller document', [
                        'order_id' => $orderId,
                        'seller_id' => $sellerId,
                        'response_status' => $response->status(),
                        'collection' => self::COLLECTION_NAME,
                        'success_count' => $successCount
                    ]);
                } else {
                    $failedCount++;
                    Log::error('FirestoreOrderSellerTracking - Failed to add order to seller document', [
                        'order_id' => $orderId,
                        'seller_id' => $sellerId,
                        'response_status' => $response->status(),
                        'response_body' => $response->body(),
                        'failed_count' => $failedCount
                    ]);
                }
            }

            if ($failedCount > 0 && $successCount === 0) {
                Log::error('FirestoreOrderSellerTracking - All seller syncs failed', [
                    'order_id' => $orderId,
                    'failed_count' => $failedCount,
                    'seller_ids' => $sellerIds
                ]);
                return [
                    'success' => false,
                    'message' => "Firestore sync failed for all {$failedCount} sellers"
                ];
            }

            Log::info('FirestoreOrderSellerTracking - Sync process completed', [
                'order_id' => $orderId,
                'seller_ids' => $sellerIds,
                'success_count' => $successCount,
                'failed_count' => $failedCount,
                'collection' => self::COLLECTION_NAME,
                'result' => 'success'
            ]);

            return [
                'success' => true,
                'message' => "Successfully synced to {$successCount} seller(s)" . ($failedCount > 0 ? ", {$failedCount} failed" : ''),
                'order_id' => $orderId,
                'sellers_count' => count($sellerIds),
                'success_count' => $successCount,
                'failed_count' => $failedCount
            ];

        } catch (\Exception $e) {
            Log::error('FirestoreOrderSellerTracking - Exception occurred during sync', [
                'order_id' => $orderId,
                'error_message' => $e->getMessage(),
                'error_file' => $e->getFile(),
                'error_line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Firestore sync failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Update seller status in Firestore
     * Updates a specific seller's status in the order tracking document
     *
     * @param int $orderId The order ID
     * @param int $sellerId The seller ID
     * @param string $status The new status
     * @return array Result with success status and message
     */
    public static function updateSellerStatus(int $orderId, int $sellerId, string $status): array
    {
        Log::info('FirestoreOrderSellerTracking - Starting status update', [
            'order_id' => $orderId,
            'seller_id' => $sellerId,
            'new_status' => $status,
            'method' => 'updateSellerStatus'
        ]);

        try {
            // Get access token
            Log::info('FirestoreOrderSellerTracking - Requesting access token for status update', [
                'order_id' => $orderId,
                'seller_id' => $sellerId
            ]);

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                Log::error('FirestoreOrderSellerTracking - Failed to get access token for status update', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId
                ]);
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            Log::info('FirestoreOrderSellerTracking - Access token obtained, updating database', [
                'order_id' => $orderId,
                'seller_id' => $sellerId
            ]);

            // Update status in database first
            $affectedRows = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('seller_id', $sellerId)
                ->update([
                    'status' => $status,
                    'updated_at' => now()
                ]);

            Log::info('FirestoreOrderSellerTracking - Database updated', [
                'order_id' => $orderId,
                'seller_id' => $sellerId,
                'affected_rows' => $affectedRows,
                'new_status' => $status
            ]);

            // Sync updated data to Firestore
            Log::info('FirestoreOrderSellerTracking - Syncing updated status to Firestore', [
                'order_id' => $orderId,
                'seller_id' => $sellerId
            ]);

            $result = self::syncOrderSellerTracking($orderId);

            Log::info('FirestoreOrderSellerTracking - Status update completed', [
                'order_id' => $orderId,
                'seller_id' => $sellerId,
                'sync_result' => $result['success'] ? 'success' : 'failed'
            ]);

            return $result;

        } catch (\Exception $e) {
            Log::error('FirestoreOrderSellerTracking - Exception during status update', [
                'order_id' => $orderId,
                'seller_id' => $sellerId,
                'status' => $status,
                'error_message' => $e->getMessage(),
                'error_file' => $e->getFile(),
                'error_line' => $e->getLine()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to update seller status: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Delete order from seller documents in Firestore
     * Removes the specific order from each seller's orders map
     *
     * @param int $orderId The order ID
     * @return array Result with success status
     */
    public static function deleteOrderSellerTracking(int $orderId): array
    {
        Log::info('FirestoreOrderSellerTracking - Starting order deletion', [
            'order_id' => $orderId,
            'method' => 'deleteOrderSellerTracking'
        ]);

        try {
            // Get access token
            Log::info('FirestoreOrderSellerTracking - Requesting access token for deletion', [
                'order_id' => $orderId
            ]);

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                Log::error('FirestoreOrderSellerTracking - Failed to get access token for deletion', [
                    'order_id' => $orderId
                ]);
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            Log::info('FirestoreOrderSellerTracking - Access token obtained, querying tracking data', [
                'order_id' => $orderId
            ]);

            // Get order seller tracking data from database to find which sellers have this order
            $trackingData = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get();

            Log::info('FirestoreOrderSellerTracking - Tracking data query completed', [
                'order_id' => $orderId,
                'records_found' => $trackingData->count()
            ]);

            if ($trackingData->isEmpty()) {
                Log::warning('FirestoreOrderSellerTracking - No tracking data to delete', [
                    'order_id' => $orderId
                ]);
                return [
                    'success' => true,
                    'message' => 'No tracking data found for this order'
                ];
            }

            $successCount = 0;
            $failedCount = 0;
            $sellerIds = [];

            // Remove order from each seller's document
            Log::info('FirestoreOrderSellerTracking - Processing sellers for deletion', [
                'order_id' => $orderId,
                'total_records' => $trackingData->count()
            ]);

            foreach ($trackingData as $index => $record) {
                $sellerId = $record->seller_id;

                Log::info('FirestoreOrderSellerTracking - Processing deletion record', [
                    'order_id' => $orderId,
                    'record_index' => $index + 1,
                    'seller_id' => $sellerId
                ]);

                // Skip if seller_id is null (Zenfoo store entries)
                if (is_null($sellerId)) {
                    Log::info('FirestoreOrderSellerTracking - Skipping null seller_id for deletion', [
                        'order_id' => $orderId,
                        'record_index' => $index + 1
                    ]);
                    continue;
                }

                $sellerIds[] = $sellerId;

                // Get existing orders for this seller
                Log::info('FirestoreOrderSellerTracking - Fetching existing orders for deletion', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId
                ]);

                $existingOrders = self::getSellerOrders($accessToken, $sellerId);

                Log::info('FirestoreOrderSellerTracking - Existing orders fetched for deletion', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'orders_count_before' => count($existingOrders)
                ]);

                // Remove this order from the seller's orders map
                $orderKey = "order_{$orderId}";
                $wasPresent = isset($existingOrders[$orderKey]);

                if ($wasPresent) {
                    unset($existingOrders[$orderKey]);
                    Log::info('FirestoreOrderSellerTracking - Order removed from map', [
                        'order_id' => $orderId,
                        'seller_id' => $sellerId,
                        'order_key' => $orderKey,
                        'orders_count_after' => count($existingOrders)
                    ]);
                } else {
                    Log::warning('FirestoreOrderSellerTracking - Order not found in seller map', [
                        'order_id' => $orderId,
                        'seller_id' => $sellerId,
                        'order_key' => $orderKey
                    ]);
                }

                // Update seller document with the order removed
                $documentData = [
                    'fields' => [
                        'seller_id' => self::toFirestoreValue($sellerId),
                        'orders' => self::toFirestoreValue($existingOrders),
                        'updated_at' => self::toFirestoreValue(now()->toIso8601String()),
                    ]
                ];

                $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $sellerId);

                Log::info('FirestoreOrderSellerTracking - Sending PATCH request for deletion', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'url' => $url
                ]);

                $response = Http::withToken($accessToken)
                    ->withOptions(['verify' => false])
                    ->patch($url, $documentData);

                if ($response->successful()) {
                    $successCount++;
                    Log::info('FirestoreOrderSellerTracking - Order successfully removed from seller document', [
                        'seller_id' => $sellerId,
                        'order_id' => $orderId,
                        'response_status' => $response->status(),
                        'collection' => self::COLLECTION_NAME,
                        'success_count' => $successCount
                    ]);
                } else {
                    $failedCount++;
                    Log::error('FirestoreOrderSellerTracking - Failed to remove order from seller document', [
                        'seller_id' => $sellerId,
                        'order_id' => $orderId,
                        'response_status' => $response->status(),
                        'response_body' => $response->body(),
                        'failed_count' => $failedCount
                    ]);
                }
            }

            Log::info('FirestoreOrderSellerTracking - Deletion process completed', [
                'order_id' => $orderId,
                'seller_ids' => $sellerIds,
                'success_count' => $successCount,
                'failed_count' => $failedCount,
                'collection' => self::COLLECTION_NAME,
                'result' => 'success'
            ]);

            return [
                'success' => true,
                'message' => "Successfully removed from {$successCount} seller(s)" . ($failedCount > 0 ? ", {$failedCount} failed" : ''),
                'order_id' => $orderId,
                'success_count' => $successCount,
                'failed_count' => $failedCount
            ];

        } catch (\Exception $e) {
            Log::error('FirestoreOrderSellerTracking - Exception during deletion', [
                'order_id' => $orderId,
                'error_message' => $e->getMessage(),
                'error_file' => $e->getFile(),
                'error_line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Firestore delete failed: ' . $e->getMessage()
            ];
        }
    }
}