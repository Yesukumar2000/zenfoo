<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class FirestoreChatService
{
    /**
     * Firestore collection name for chatting
     */
    private const COLLECTION_NAME = 'chatting';

    /**
     * Sub-collection name for customer to driver messages
     */
    private const SUBCOLLECTION_NAME = 'customer_to_driver';

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
     * Get Firestore base path for the project
     *
     * @return string
     */
    private static function getBasePath(): string
    {
        $credentials = self::getServiceAccountCredentials();
        $projectId = $credentials['project_id'] ?? '';

        return self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents";
    }

    /**
     * Get Firestore document path for chat
     * Structure: chatting/{order_id}/customer_to_driver/{chat_document_id}
     *
     * @param int $orderId
     * @param string|null $documentId
     * @return string
     */
    private static function getChatDocumentPath(int $orderId, ?string $documentId = null): string
    {
        $basePath = self::getBasePath();
        $path = "{$basePath}/" . self::COLLECTION_NAME . "/{$orderId}/" . self::SUBCOLLECTION_NAME;

        if ($documentId) {
            $path .= "/{$documentId}";
        }

        return $path;
    }

    /**
     * Get Firestore document path for the order document
     *
     * @param int $orderId
     * @return string
     */
    private static function getOrderDocumentPath(int $orderId): string
    {
        $basePath = self::getBasePath();
        return "{$basePath}/" . self::COLLECTION_NAME . "/{$orderId}";
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
     * Convert Firestore value to PHP value
     *
     * @param array $firestoreValue
     * @return mixed
     */
    private static function fromFirestoreValue(array $firestoreValue)
    {
        if (isset($firestoreValue['nullValue'])) {
            return null;
        }
        if (isset($firestoreValue['booleanValue'])) {
            return $firestoreValue['booleanValue'];
        }
        if (isset($firestoreValue['integerValue'])) {
            return (int) $firestoreValue['integerValue'];
        }
        if (isset($firestoreValue['doubleValue'])) {
            return (float) $firestoreValue['doubleValue'];
        }
        if (isset($firestoreValue['stringValue'])) {
            return $firestoreValue['stringValue'];
        }
        if (isset($firestoreValue['timestampValue'])) {
            return $firestoreValue['timestampValue'];
        }
        if (isset($firestoreValue['mapValue']['fields'])) {
            $result = [];
            foreach ($firestoreValue['mapValue']['fields'] as $key => $value) {
                $result[$key] = self::fromFirestoreValue($value);
            }
            return $result;
        }
        if (isset($firestoreValue['arrayValue']['values'])) {
            $result = [];
            foreach ($firestoreValue['arrayValue']['values'] as $value) {
                $result[] = self::fromFirestoreValue($value);
            }
            return $result;
        }
        return null;
    }

    /**
     * Initialize chat for an order
     * Creates the order document with customer and driver info
     *
     * @param int $orderId
     * @param int $customerId
     * @param int $driverId
     * @return array
     */
    public static function initializeChat(int $orderId, int $customerId, int $driverId): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Check if chat already initialized
            $existingChat = self::getChatInfo($orderId);
            if ($existingChat['success'] && !empty($existingChat['data']['order_id'])) {
                Log::info('Chat already initialized', ['order_id' => $orderId]);
                return [
                    'success' => true,
                    'message' => 'Chat already initialized',
                    'data' => $existingChat['data']
                ];
            }

            // Get customer details
            $customer = DB::table('users')
                ->where('id', $customerId)
                ->select('id', 'name', 'mobile', 'profile')
                ->first();

            // Get driver details
            $driver = DB::table('delivery_boys')
                ->where('id', $driverId)
                ->select('id', 'name', 'mobile', 'profile')
                ->first();

            if (!$customer || !$driver) {
                Log::warning('Customer or driver not found for chat initialization', [
                    'order_id' => $orderId,
                    'customer_id' => $customerId,
                    'driver_id' => $driverId,
                    'customer_found' => $customer ? true : false,
                    'driver_found' => $driver ? true : false
                ]);
                return [
                    'success' => false,
                    'message' => 'Customer or driver not found'
                ];
            }

            $currentTime = now();

            // Build order document data
            $orderDocumentData = [
                'fields' => [
                    'order_id' => self::toFirestoreValue($orderId),
                    'customer_id' => self::toFirestoreValue($customerId),
                    'driver_id' => self::toFirestoreValue($driverId),
                    'customer_info' => self::toFirestoreValue([
                        'id' => $customer->id,
                        'name' => $customer->name,
                        'mobile' => $customer->mobile,
                        'profile' => $customer->profile
                    ]),
                    'driver_info' => self::toFirestoreValue([
                        'id' => $driver->id,
                        'name' => $driver->name,
                        'mobile' => $driver->mobile,
                        'profile' => $driver->profile
                    ]),
                    'created_at' => self::toFirestoreValue($currentTime->toIso8601String()),
                    'updated_at' => self::toFirestoreValue($currentTime->toIso8601String()),
                    'is_active' => self::toFirestoreValue(true)
                ]
            ];

            // Create order document using PATCH with updateMask to ensure fields are created
            $url = self::getOrderDocumentPath($orderId);
            $updateMask = 'updateMask.fieldPaths=order_id&updateMask.fieldPaths=customer_id&updateMask.fieldPaths=driver_id&updateMask.fieldPaths=customer_info&updateMask.fieldPaths=driver_info&updateMask.fieldPaths=created_at&updateMask.fieldPaths=updated_at&updateMask.fieldPaths=is_active';

            Log::info('Initializing chat in Firestore', [
                'order_id' => $orderId,
                'url' => $url,
                'customer_id' => $customerId,
                'driver_id' => $driverId
            ]);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url . '?' . $updateMask, $orderDocumentData);

            if (!$response->successful()) {
                Log::error('Firestore chat initialization failed', [
                    'order_id' => $orderId,
                    'status' => $response->status(),
                    'body' => $response->body(),
                    'url' => $url
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to initialize chat: ' . $response->body()
                ];
            }

            Log::info('Firestore chat initialized successfully', [
                'order_id' => $orderId,
                'customer_id' => $customerId,
                'driver_id' => $driverId,
                'response_status' => $response->status()
            ]);

            return [
                'success' => true,
                'message' => 'Chat initialized successfully',
                'data' => [
                    'order_id' => $orderId,
                    'customer_id' => $customerId,
                    'driver_id' => $driverId,
                    'chat_path' => self::COLLECTION_NAME . "/{$orderId}/" . self::SUBCOLLECTION_NAME
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Firestore chat initialization failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Chat initialization failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Send a message from customer to driver or vice versa
     *
     * @param int $orderId
     * @param int $senderId
     * @param string $senderType - 'customer' or 'driver'
     * @param string $message
     * @param string|null $messageType - 'text', 'image', 'location'
     * @param array|null $metadata - additional data like image_url, location coordinates
     * @return array
     */
    public static function sendMessage(
        int $orderId,
        int $senderId,
        string $senderType,
        string $message,
        ?string $messageType = 'text',
        ?array $metadata = null
    ): array {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Validate sender type
            if (!in_array($senderType, ['customer', 'driver'])) {
                return [
                    'success' => false,
                    'message' => 'Invalid sender type. Must be "customer" or "driver"'
                ];
            }

            // Generate unique message ID
            $messageId = uniqid('msg_', true);
            $currentTime = now();

            // Build message data
            $messageData = [
                'message_id' => $messageId,
                'sender_id' => $senderId,
                'sender_type' => $senderType,
                'message' => $message,
                'message_type' => $messageType ?? 'text',
                'is_read' => false,
                'created_at' => $currentTime->toIso8601String(),
                'timestamp' => $currentTime->timestamp
            ];

            // Add metadata if provided
            if ($metadata) {
                $messageData['metadata'] = $metadata;
            }

            // Build Firestore document
            $documentData = [
                'fields' => []
            ];
            foreach ($messageData as $key => $value) {
                $documentData['fields'][$key] = self::toFirestoreValue($value);
            }

            // Create message in subcollection
            $url = self::getChatDocumentPath($orderId, $messageId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $documentData);

            if (!$response->successful()) {
                Log::error('Firestore send message failed', [
                    'order_id' => $orderId,
                    'sender_id' => $senderId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to send message: ' . $response->body()
                ];
            }

            // Update the order document's updated_at timestamp
            self::updateChatTimestamp($orderId);

            Log::info('Firestore message sent', [
                'order_id' => $orderId,
                'message_id' => $messageId,
                'sender_id' => $senderId,
                'sender_type' => $senderType
            ]);

            return [
                'success' => true,
                'message' => 'Message sent successfully',
                'data' => [
                    'message_id' => $messageId,
                    'order_id' => $orderId,
                    'sender_id' => $senderId,
                    'sender_type' => $senderType,
                    'created_at' => $currentTime->toIso8601String()
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Firestore send message failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Send message failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Update the chat timestamp on the order document
     *
     * @param int $orderId
     * @return bool
     */
    private static function updateChatTimestamp(int $orderId): bool
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return false;
            }

            $url = self::getOrderDocumentPath($orderId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, [
                    'fields' => [
                        'updated_at' => self::toFirestoreValue(now()->toIso8601String())
                    ]
                ]);

            return $response->successful();
        } catch (\Exception $e) {
            Log::warning('Failed to update chat timestamp', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Get all messages for an order chat
     *
     * @param int $orderId
     * @param int|null $limit
     * @param string|null $orderBy - 'asc' or 'desc'
     * @return array
     */
    public static function getMessages(int $orderId, ?int $limit = 50, ?string $orderBy = 'asc'): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token',
                    'messages' => []
                ];
            }

            $credentials = self::getServiceAccountCredentials();
            $projectId = $credentials['project_id'] ?? '';

            // Use runQuery to get messages with ordering
            $queryUrl = self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents:runQuery";

            $query = [
                'structuredQuery' => [
                    'from' => [
                        [
                            'collectionId' => self::SUBCOLLECTION_NAME,
                            'allDescendants' => false
                        ]
                    ],
                    'orderBy' => [
                        [
                            'field' => ['fieldPath' => 'timestamp'],
                            'direction' => $orderBy === 'desc' ? 'DESCENDING' : 'ASCENDING'
                        ]
                    ]
                ]
            ];

            if ($limit) {
                $query['structuredQuery']['limit'] = $limit;
            }

            // Set the parent path
            $parentPath = "projects/{$projectId}/databases/(default)/documents/" . self::COLLECTION_NAME . "/{$orderId}";

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->post($queryUrl, array_merge($query, ['parent' => $parentPath]));

            if (!$response->successful()) {
                Log::error('Firestore get messages failed', [
                    'order_id' => $orderId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to get messages',
                    'messages' => []
                ];
            }

            $data = $response->json();
            $messages = [];

            foreach ($data as $item) {
                if (isset($item['document']['fields'])) {
                    $messageData = [];
                    foreach ($item['document']['fields'] as $key => $value) {
                        $messageData[$key] = self::fromFirestoreValue($value);
                    }
                    $messages[] = $messageData;
                }
            }

            return [
                'success' => true,
                'message' => 'Messages retrieved successfully',
                'messages' => $messages,
                'count' => count($messages)
            ];

        } catch (\Exception $e) {
            Log::error('Firestore get messages failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Get messages failed: ' . $e->getMessage(),
                'messages' => []
            ];
        }
    }

    /**
     * Mark messages as read
     *
     * @param int $orderId
     * @param array $messageIds
     * @param int $readerId
     * @return array
     */
    public static function markMessagesAsRead(int $orderId, array $messageIds, int $readerId): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $successCount = 0;
            $failedCount = 0;

            foreach ($messageIds as $messageId) {
                $url = self::getChatDocumentPath($orderId, $messageId);

                $response = Http::withToken($accessToken)
                    ->withOptions(['verify' => false])
                    ->patch($url, [
                        'fields' => [
                            'is_read' => self::toFirestoreValue(true),
                            'read_at' => self::toFirestoreValue(now()->toIso8601String()),
                            'read_by' => self::toFirestoreValue($readerId)
                        ]
                    ]);

                if ($response->successful()) {
                    $successCount++;
                } else {
                    $failedCount++;
                }
            }

            Log::info('Messages marked as read', [
                'order_id' => $orderId,
                'reader_id' => $readerId,
                'success_count' => $successCount,
                'failed_count' => $failedCount
            ]);

            return [
                'success' => $failedCount === 0,
                'message' => "Marked {$successCount} messages as read" . ($failedCount > 0 ? ", {$failedCount} failed" : ''),
                'success_count' => $successCount,
                'failed_count' => $failedCount
            ];

        } catch (\Exception $e) {
            Log::error('Mark messages as read failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to mark messages as read: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get chat info for an order
     *
     * @param int $orderId
     * @return array
     */
    public static function getChatInfo(int $orderId): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token',
                    'data' => null
                ];
            }

            $url = self::getOrderDocumentPath($orderId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($url);

            if (!$response->successful()) {
                if ($response->status() === 404) {
                    return [
                        'success' => false,
                        'message' => 'Chat not found for this order',
                        'data' => null
                    ];
                }

                return [
                    'success' => false,
                    'message' => 'Failed to get chat info',
                    'data' => null
                ];
            }

            $data = $response->json();
            $chatInfo = [];

            if (isset($data['fields'])) {
                foreach ($data['fields'] as $key => $value) {
                    $chatInfo[$key] = self::fromFirestoreValue($value);
                }
            }

            return [
                'success' => true,
                'message' => 'Chat info retrieved successfully',
                'data' => $chatInfo
            ];

        } catch (\Exception $e) {
            Log::error('Get chat info failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Get chat info failed: ' . $e->getMessage(),
                'data' => null
            ];
        }
    }

    /**
     * Deactivate chat for an order (when order is completed/cancelled)
     *
     * @param int $orderId
     * @return array
     */
    public static function deactivateChat(int $orderId): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $url = self::getOrderDocumentPath($orderId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, [
                    'fields' => [
                        'is_active' => self::toFirestoreValue(false),
                        'deactivated_at' => self::toFirestoreValue(now()->toIso8601String())
                    ]
                ]);

            if (!$response->successful() && $response->status() !== 404) {
                Log::error('Firestore deactivate chat failed', [
                    'order_id' => $orderId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to deactivate chat'
                ];
            }

            Log::info('Firestore chat deactivated', [
                'order_id' => $orderId
            ]);

            return [
                'success' => true,
                'message' => 'Chat deactivated successfully'
            ];

        } catch (\Exception $e) {
            Log::error('Deactivate chat failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Deactivate chat failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Delete chat for an order (complete deletion)
     *
     * @param int $orderId
     * @return array
     */
    public static function deleteChat(int $orderId): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // First, delete all messages in the subcollection
            $messagesResult = self::getMessages($orderId, 500);

            if ($messagesResult['success'] && !empty($messagesResult['messages'])) {
                foreach ($messagesResult['messages'] as $message) {
                    if (isset($message['message_id'])) {
                        $messageUrl = self::getChatDocumentPath($orderId, $message['message_id']);
                        Http::withToken($accessToken)
                            ->withOptions(['verify' => false])
                            ->delete($messageUrl);
                    }
                }
            }

            // Delete the order document
            $url = self::getOrderDocumentPath($orderId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->delete($url);

            if (!$response->successful() && $response->status() !== 404) {
                Log::error('Firestore delete chat failed', [
                    'order_id' => $orderId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to delete chat'
                ];
            }

            Log::info('Firestore chat deleted', [
                'order_id' => $orderId
            ]);

            return [
                'success' => true,
                'message' => 'Chat deleted successfully'
            ];

        } catch (\Exception $e) {
            Log::error('Delete chat failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Delete chat failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get unread message count for a user in an order chat
     *
     * @param int $orderId
     * @param int $userId
     * @param string $userType - 'customer' or 'driver'
     * @return array
     */
    public static function getUnreadCount(int $orderId, int $userId, string $userType): array
    {
        try {
            // Get all messages and filter for unread ones not sent by this user
            $messagesResult = self::getMessages($orderId, 500);

            if (!$messagesResult['success']) {
                return [
                    'success' => false,
                    'message' => $messagesResult['message'],
                    'unread_count' => 0
                ];
            }

            $unreadCount = 0;
            $oppositeType = $userType === 'customer' ? 'driver' : 'customer';

            foreach ($messagesResult['messages'] as $message) {
                // Count messages from the other party that are unread
                if (
                    isset($message['sender_type']) &&
                    $message['sender_type'] === $oppositeType &&
                    isset($message['is_read']) &&
                    $message['is_read'] === false
                ) {
                    $unreadCount++;
                }
            }

            return [
                'success' => true,
                'message' => 'Unread count retrieved',
                'unread_count' => $unreadCount
            ];

        } catch (\Exception $e) {
            Log::error('Get unread count failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Get unread count failed: ' . $e->getMessage(),
                'unread_count' => 0
            ];
        }
    }
}
