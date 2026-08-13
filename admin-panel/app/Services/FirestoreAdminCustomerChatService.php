<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;

/**
 * Service for Admin-Customer Chat via Firestore
 *
 * Collection: admin_customer_chatting
 * Document: {customer_id}
 * Fields: messages (subcollection), last_message, last_message_time, admin_id, customer_name
 */
class FirestoreAdminCustomerChatService
{
    /**
     * Firestore collection name for admin-customer chat
     */
    private const COLLECTION_NAME = 'admin_customer_chatting';

    /**
     * Firestore REST API base URL
     */
    private const FIRESTORE_BASE_URL = 'https://firestore.googleapis.com/v1';

    /**
     * Get Firebase service account credentials
     */
    private static function getServiceAccountCredentials(): ?array
    {
        try {
            $filePath = base_path('config/firebase.json');

            if (!file_exists($filePath)) {
                Log::error('FirestoreAdminCustomerChatService: Firebase service account file not found');
                return null;
            }

            $credentials = json_decode(file_get_contents($filePath), true);

            if (!$credentials || !isset($credentials['project_id'])) {
                Log::error('FirestoreAdminCustomerChatService: Invalid Firebase service account file');
                return null;
            }

            return $credentials;
        } catch (\Exception $e) {
            Log::error('FirestoreAdminCustomerChatService: Failed to read Firebase credentials', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Generate JWT token for Firebase authentication
     */
    private static function generateJwtToken(array $credentials): ?string
    {
        try {
            $now = time();
            $expiry = $now + 3600;

            $header = [
                'alg' => 'RS256',
                'typ' => 'JWT'
            ];

            $payload = [
                'iss' => $credentials['client_email'],
                'sub' => $credentials['client_email'],
                'aud' => 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $expiry,
                'scope' => 'https://www.googleapis.com/auth/datastore'
            ];

            $base64Header = self::base64UrlEncode(json_encode($header));
            $base64Payload = self::base64UrlEncode(json_encode($payload));

            $signatureInput = $base64Header . '.' . $base64Payload;
            $privateKey = $credentials['private_key'];

            openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
            $base64Signature = self::base64UrlEncode($signature);

            return $base64Header . '.' . $base64Payload . '.' . $base64Signature;
        } catch (\Exception $e) {
            Log::error('FirestoreAdminCustomerChatService: Failed to generate JWT token', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Base64 URL encode
     */
    private static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Get OAuth2 access token using JWT
     */
    private static function getAccessToken(): ?string
    {
        try {
            $cachedToken = Cache::get('firestore_chat_access_token');
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

            $response = Http::asForm()
                ->withOptions(['verify' => false])
                ->post('https://oauth2.googleapis.com/token', [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $jwt
                ]);

            if (!$response->successful()) {
                Log::error('FirestoreAdminCustomerChatService: Failed to get access token', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return null;
            }

            $data = $response->json();
            $accessToken = $data['access_token'] ?? null;

            if ($accessToken) {
                Cache::put('firestore_chat_access_token', $accessToken, now()->addMinutes(50));
            }

            return $accessToken;
        } catch (\Exception $e) {
            Log::error('FirestoreAdminCustomerChatService: Failed to get access token', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Get Firestore document path
     */
    private static function getDocumentPath(string $collection, string $documentId): string
    {
        $credentials = self::getServiceAccountCredentials();
        $projectId = $credentials['project_id'] ?? '';

        return self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/{$collection}/{$documentId}";
    }

    /**
     * Get Firestore collection path
     */
    private static function getCollectionPath(string $collection): string
    {
        $credentials = self::getServiceAccountCredentials();
        $projectId = $credentials['project_id'] ?? '';

        return self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/{$collection}";
    }

    /**
     * Convert PHP value to Firestore value format
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
            if (empty($value) || array_keys($value) !== range(0, count($value) - 1)) {
                $mapValue = [];
                foreach ($value as $k => $v) {
                    $mapValue[$k] = self::toFirestoreValue($v);
                }
                return ['mapValue' => ['fields' => $mapValue]];
            } else {
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
            return $firestoreValue['doubleValue'];
        }
        if (isset($firestoreValue['stringValue'])) {
            return $firestoreValue['stringValue'];
        }
        if (isset($firestoreValue['arrayValue'])) {
            $result = [];
            foreach ($firestoreValue['arrayValue']['values'] ?? [] as $val) {
                $result[] = self::fromFirestoreValue($val);
            }
            return $result;
        }
        if (isset($firestoreValue['mapValue'])) {
            $result = [];
            foreach ($firestoreValue['mapValue']['fields'] ?? [] as $key => $val) {
                $result[$key] = self::fromFirestoreValue($val);
            }
            return $result;
        }
        return null;
    }

    /**
     * Initialize or get chat document for a customer
     *
     * @param int $customerId
     * @param string $customerName
     * @return array
     */
    public static function initializeChat(int $customerId, string $customerName = ''): array
    {
        try {
            Log::info("FirestoreAdminCustomerChatService: Initializing chat for customer_id: {$customerId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $now = Carbon::now()->setTimezone('Asia/Kolkata');

            $firestoreData = [
                'fields' => [
                    'customer_id' => self::toFirestoreValue($customerId),
                    'customer_name' => self::toFirestoreValue($customerName),
                    'last_message' => self::toFirestoreValue(''),
                    'last_message_time' => self::toFirestoreValue($now->toIso8601String()),
                    'last_sender' => self::toFirestoreValue(''),
                    'unread_count' => self::toFirestoreValue(0),
                    'created_at' => self::toFirestoreValue($now->toIso8601String()),
                    'updated_at' => self::toFirestoreValue($now->toIso8601String())
                ]
            ];

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $customerId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $firestoreData);

            if (!$response->successful()) {
                Log::error("FirestoreAdminCustomerChatService: Failed to initialize chat for customer_id: {$customerId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to initialize chat in Firestore',
                    'error' => $response->body()
                ];
            }

            Log::info("FirestoreAdminCustomerChatService: Successfully initialized chat for customer_id: {$customerId}");

            return [
                'success' => true,
                'message' => 'Chat initialized successfully',
                'data' => [
                    'customer_id' => $customerId,
                    'customer_name' => $customerName
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminCustomerChatService: Exception initializing chat for customer_id: {$customerId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while initializing chat',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Send a message from admin to customer
     *
     * @param int $customerId
     * @param int $adminId
     * @param string $message
     * @param string $senderType 'admin' or 'customer'
     * @return array
     */
    public static function sendMessage(int $customerId, int $adminId, string $message, string $senderType = 'admin'): array
    {
        try {
            Log::info("FirestoreAdminCustomerChatService: Sending message for customer_id: {$customerId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $now = Carbon::now()->setTimezone('Asia/Kolkata');
            $messageId = uniqid('msg_', true);

            // Create message in subcollection
            $messageData = [
                'fields' => [
                    'message_id' => self::toFirestoreValue($messageId),
                    'sender' => self::toFirestoreValue($senderType),
                    'sender_id' => self::toFirestoreValue($senderType === 'admin' ? $adminId : $customerId),
                    'receiver' => self::toFirestoreValue($senderType === 'admin' ? 'customer' : 'admin'),
                    'receiver_id' => self::toFirestoreValue($senderType === 'admin' ? $customerId : $adminId),
                    'message' => self::toFirestoreValue($message),
                    'time' => self::toFirestoreValue($now->toIso8601String()),
                    'time_display' => self::toFirestoreValue($now->format('h:i A')),
                    'date' => self::toFirestoreValue($now->format('Y-m-d')),
                    'read' => self::toFirestoreValue(false)
                ]
            ];

            // Add message to messages subcollection
            $credentials = self::getServiceAccountCredentials();
            $projectId = $credentials['project_id'] ?? '';
            $messagesUrl = self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/" . self::COLLECTION_NAME . "/{$customerId}/messages";

            $messageResponse = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->post($messagesUrl, $messageData);

            if (!$messageResponse->successful()) {
                Log::error("FirestoreAdminCustomerChatService: Failed to send message for customer_id: {$customerId}", [
                    'status' => $messageResponse->status(),
                    'body' => $messageResponse->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to send message to Firestore',
                    'error' => $messageResponse->body()
                ];
            }

            // Update parent document with last message info
            $updateData = [
                'fields' => [
                    'last_message' => self::toFirestoreValue($message),
                    'last_message_time' => self::toFirestoreValue($now->toIso8601String()),
                    'last_sender' => self::toFirestoreValue($senderType),
                    'updated_at' => self::toFirestoreValue($now->toIso8601String())
                ]
            ];

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $customerId);
            $url .= '?updateMask.fieldPaths=last_message&updateMask.fieldPaths=last_message_time&updateMask.fieldPaths=last_sender&updateMask.fieldPaths=updated_at';

            Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $updateData);

            Log::info("FirestoreAdminCustomerChatService: Successfully sent message for customer_id: {$customerId}");

            return [
                'success' => true,
                'message' => 'Message sent successfully',
                'data' => [
                    'message_id' => $messageId,
                    'customer_id' => $customerId,
                    'sender' => $senderType,
                    'message' => $message,
                    'time' => $now->toIso8601String(),
                    'time_display' => $now->format('h:i A')
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminCustomerChatService: Exception sending message for customer_id: {$customerId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while sending message',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Get all messages for a customer chat
     *
     * @param int $customerId
     * @param int $limit
     * @return array
     */
    public static function getMessages(int $customerId, int $limit = 50): array
    {
        try {
            Log::info("FirestoreAdminCustomerChatService: Getting messages for customer_id: {$customerId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $credentials = self::getServiceAccountCredentials();
            $projectId = $credentials['project_id'] ?? '';
            $messagesUrl = self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/" . self::COLLECTION_NAME . "/{$customerId}/messages?pageSize={$limit}&orderBy=time";

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($messagesUrl);

            if (!$response->successful()) {
                Log::error("FirestoreAdminCustomerChatService: Failed to get messages for customer_id: {$customerId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to get messages from Firestore',
                    'error' => $response->body()
                ];
            }

            $data = $response->json();
            $messages = [];

            if (isset($data['documents'])) {
                foreach ($data['documents'] as $doc) {
                    $fields = $doc['fields'] ?? [];
                    $messages[] = [
                        'message_id' => self::fromFirestoreValue($fields['message_id'] ?? []),
                        'sender' => self::fromFirestoreValue($fields['sender'] ?? []),
                        'sender_id' => self::fromFirestoreValue($fields['sender_id'] ?? []),
                        'receiver' => self::fromFirestoreValue($fields['receiver'] ?? []),
                        'receiver_id' => self::fromFirestoreValue($fields['receiver_id'] ?? []),
                        'message' => self::fromFirestoreValue($fields['message'] ?? []),
                        'time' => self::fromFirestoreValue($fields['time'] ?? []),
                        'time_display' => self::fromFirestoreValue($fields['time_display'] ?? []),
                        'date' => self::fromFirestoreValue($fields['date'] ?? []),
                        'read' => self::fromFirestoreValue($fields['read'] ?? [])
                    ];
                }
            }

            Log::info("FirestoreAdminCustomerChatService: Successfully retrieved messages for customer_id: {$customerId}", [
                'count' => count($messages)
            ]);

            return [
                'success' => true,
                'message' => 'Messages retrieved successfully',
                'data' => [
                    'customer_id' => $customerId,
                    'messages' => $messages,
                    'count' => count($messages)
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminCustomerChatService: Exception getting messages for customer_id: {$customerId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while getting messages',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Get all customer chats (for admin panel listing)
     *
     * @param int $limit
     * @return array
     */
    public static function getAllChats(int $limit = 50): array
    {
        try {
            Log::info("FirestoreAdminCustomerChatService: Getting all customer chats");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $url = self::getCollectionPath(self::COLLECTION_NAME) . "?pageSize={$limit}&orderBy=updated_at desc";

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($url);

            if (!$response->successful()) {
                Log::error("FirestoreAdminCustomerChatService: Failed to get all chats", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to get chats from Firestore',
                    'error' => $response->body()
                ];
            }

            $data = $response->json();
            $chats = [];

            if (isset($data['documents'])) {
                foreach ($data['documents'] as $doc) {
                    $fields = $doc['fields'] ?? [];
                    $chats[] = [
                        'customer_id' => self::fromFirestoreValue($fields['customer_id'] ?? []),
                        'customer_name' => self::fromFirestoreValue($fields['customer_name'] ?? []),
                        'last_message' => self::fromFirestoreValue($fields['last_message'] ?? []),
                        'last_message_time' => self::fromFirestoreValue($fields['last_message_time'] ?? []),
                        'last_sender' => self::fromFirestoreValue($fields['last_sender'] ?? []),
                        'unread_count' => self::fromFirestoreValue($fields['unread_count'] ?? []),
                        'updated_at' => self::fromFirestoreValue($fields['updated_at'] ?? [])
                    ];
                }
            }

            Log::info("FirestoreAdminCustomerChatService: Successfully retrieved all chats", [
                'count' => count($chats)
            ]);

            return [
                'success' => true,
                'message' => 'Chats retrieved successfully',
                'data' => [
                    'chats' => $chats,
                    'count' => count($chats)
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminCustomerChatService: Exception getting all chats", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while getting chats',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Mark messages as read
     *
     * @param int $customerId
     * @return array
     */
    public static function markAsRead(int $customerId): array
    {
        try {
            Log::info("FirestoreAdminCustomerChatService: Marking messages as read for customer_id: {$customerId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Update unread count to 0
            $updateData = [
                'fields' => [
                    'unread_count' => self::toFirestoreValue(0),
                    'updated_at' => self::toFirestoreValue(Carbon::now()->setTimezone('Asia/Kolkata')->toIso8601String())
                ]
            ];

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $customerId);
            $url .= '?updateMask.fieldPaths=unread_count&updateMask.fieldPaths=updated_at';

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $updateData);

            if (!$response->successful()) {
                Log::error("FirestoreAdminCustomerChatService: Failed to mark as read for customer_id: {$customerId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to mark messages as read'
                ];
            }

            return [
                'success' => true,
                'message' => 'Messages marked as read'
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminCustomerChatService: Exception marking as read for customer_id: {$customerId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while marking as read',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Delete chat for a customer
     *
     * @param int $customerId
     * @return array
     */
    public static function deleteChat(int $customerId): array
    {
        try {
            Log::info("FirestoreAdminCustomerChatService: Deleting chat for customer_id: {$customerId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $customerId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->delete($url);

            if (!$response->successful() && $response->status() !== 404) {
                Log::error("FirestoreAdminCustomerChatService: Failed to delete chat for customer_id: {$customerId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to delete chat from Firestore'
                ];
            }

            Log::info("FirestoreAdminCustomerChatService: Successfully deleted chat for customer_id: {$customerId}");

            return [
                'success' => true,
                'message' => 'Chat deleted successfully'
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminCustomerChatService: Exception deleting chat for customer_id: {$customerId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while deleting chat',
                'error' => $e->getMessage()
            ];
        }
    }
}
