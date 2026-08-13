<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;

/**
 * Service for Admin-Seller Chat via Firestore
 *
 * Collection: admin_seller_chatting
 * Document: {seller_id}
 * Fields: messages (subcollection), last_message, last_message_time, admin_id, seller_name
 */
class FirestoreAdminSellerChatService
{
    /**
     * Firestore collection name for admin-seller chat
     */
    private const COLLECTION_NAME = 'admin_seller_chatting';

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
                Log::error('FirestoreAdminSellerChatService: Firebase service account file not found');
                return null;
            }

            $credentials = json_decode(file_get_contents($filePath), true);

            if (!$credentials || !isset($credentials['project_id'])) {
                Log::error('FirestoreAdminSellerChatService: Invalid Firebase service account file');
                return null;
            }

            return $credentials;
        } catch (\Exception $e) {
            Log::error('FirestoreAdminSellerChatService: Failed to read Firebase credentials', [
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
            Log::error('FirestoreAdminSellerChatService: Failed to generate JWT token', [
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
            $cachedToken = Cache::get('firestore_seller_chat_access_token');
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
                Log::error('FirestoreAdminSellerChatService: Failed to get access token', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return null;
            }

            $data = $response->json();
            $accessToken = $data['access_token'] ?? null;

            if ($accessToken) {
                Cache::put('firestore_seller_chat_access_token', $accessToken, now()->addMinutes(50));
            }

            return $accessToken;
        } catch (\Exception $e) {
            Log::error('FirestoreAdminSellerChatService: Failed to get access token', [
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
     * Initialize or get chat document for a seller
     *
     * @param int $sellerId
     * @param string $sellerName
     * @return array
     */
    public static function initializeChat(int $sellerId, string $sellerName = ''): array
    {
        try {
            Log::info("FirestoreAdminSellerChatService: Initializing chat for seller_id: {$sellerId}");

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
                    'seller_id' => self::toFirestoreValue($sellerId),
                    'seller_name' => self::toFirestoreValue($sellerName),
                    'last_message' => self::toFirestoreValue(''),
                    'last_message_time' => self::toFirestoreValue($now->toIso8601String()),
                    'last_sender' => self::toFirestoreValue(''),
                    'unread_count' => self::toFirestoreValue(0),
                    'created_at' => self::toFirestoreValue($now->toIso8601String()),
                    'updated_at' => self::toFirestoreValue($now->toIso8601String())
                ]
            ];

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $sellerId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $firestoreData);

            if (!$response->successful()) {
                Log::error("FirestoreAdminSellerChatService: Failed to initialize chat for seller_id: {$sellerId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to initialize chat in Firestore',
                    'error' => $response->body()
                ];
            }

            Log::info("FirestoreAdminSellerChatService: Successfully initialized chat for seller_id: {$sellerId}");

            return [
                'success' => true,
                'message' => 'Chat initialized successfully',
                'data' => [
                    'seller_id' => $sellerId,
                    'seller_name' => $sellerName
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminSellerChatService: Exception initializing chat for seller_id: {$sellerId}", [
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
     * Send a message from admin to seller
     *
     * @param int $sellerId
     * @param int $adminId
     * @param string $message
     * @param string $senderType 'admin' or 'seller'
     * @return array
     */
    public static function sendMessage(int $sellerId, int $adminId, string $message, string $senderType = 'admin'): array
    {
        try {
            Log::info("FirestoreAdminSellerChatService: Sending message for seller_id: {$sellerId}");

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
                    'sender_id' => self::toFirestoreValue($senderType === 'admin' ? $adminId : $sellerId),
                    'receiver' => self::toFirestoreValue($senderType === 'admin' ? 'seller' : 'admin'),
                    'receiver_id' => self::toFirestoreValue($senderType === 'admin' ? $sellerId : $adminId),
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
            $messagesUrl = self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/" . self::COLLECTION_NAME . "/{$sellerId}/messages";

            $messageResponse = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->post($messagesUrl, $messageData);

            if (!$messageResponse->successful()) {
                Log::error("FirestoreAdminSellerChatService: Failed to send message for seller_id: {$sellerId}", [
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

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $sellerId);
            $url .= '?updateMask.fieldPaths=last_message&updateMask.fieldPaths=last_message_time&updateMask.fieldPaths=last_sender&updateMask.fieldPaths=updated_at';

            Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $updateData);

            Log::info("FirestoreAdminSellerChatService: Successfully sent message for seller_id: {$sellerId}");

            return [
                'success' => true,
                'message' => 'Message sent successfully',
                'data' => [
                    'message_id' => $messageId,
                    'seller_id' => $sellerId,
                    'sender' => $senderType,
                    'message' => $message,
                    'time' => $now->toIso8601String(),
                    'time_display' => $now->format('h:i A')
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminSellerChatService: Exception sending message for seller_id: {$sellerId}", [
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
     * Get all messages for a seller chat
     *
     * @param int $sellerId
     * @param int $limit
     * @return array
     */
    public static function getMessages(int $sellerId, int $limit = 50): array
    {
        try {
            Log::info("FirestoreAdminSellerChatService: Getting messages for seller_id: {$sellerId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $credentials = self::getServiceAccountCredentials();
            $projectId = $credentials['project_id'] ?? '';
            $messagesUrl = self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/" . self::COLLECTION_NAME . "/{$sellerId}/messages?pageSize={$limit}&orderBy=time";

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($messagesUrl);

            if (!$response->successful()) {
                Log::error("FirestoreAdminSellerChatService: Failed to get messages for seller_id: {$sellerId}", [
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

            Log::info("FirestoreAdminSellerChatService: Successfully retrieved messages for seller_id: {$sellerId}", [
                'count' => count($messages)
            ]);

            return [
                'success' => true,
                'message' => 'Messages retrieved successfully',
                'data' => [
                    'seller_id' => $sellerId,
                    'messages' => $messages,
                    'count' => count($messages)
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminSellerChatService: Exception getting messages for seller_id: {$sellerId}", [
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
     * Get all seller chats (for admin panel listing)
     *
     * @param int $limit
     * @return array
     */
    public static function getAllChats(int $limit = 50): array
    {
        try {
            Log::info("FirestoreAdminSellerChatService: Getting all seller chats");

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
                Log::error("FirestoreAdminSellerChatService: Failed to get all chats", [
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
                        'seller_id' => self::fromFirestoreValue($fields['seller_id'] ?? []),
                        'seller_name' => self::fromFirestoreValue($fields['seller_name'] ?? []),
                        'last_message' => self::fromFirestoreValue($fields['last_message'] ?? []),
                        'last_message_time' => self::fromFirestoreValue($fields['last_message_time'] ?? []),
                        'last_sender' => self::fromFirestoreValue($fields['last_sender'] ?? []),
                        'unread_count' => self::fromFirestoreValue($fields['unread_count'] ?? []),
                        'updated_at' => self::fromFirestoreValue($fields['updated_at'] ?? [])
                    ];
                }
            }

            Log::info("FirestoreAdminSellerChatService: Successfully retrieved all chats", [
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
            Log::error("FirestoreAdminSellerChatService: Exception getting all chats", [
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
     * @param int $sellerId
     * @return array
     */
    public static function markAsRead(int $sellerId): array
    {
        try {
            Log::info("FirestoreAdminSellerChatService: Marking messages as read for seller_id: {$sellerId}");

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

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $sellerId);
            $url .= '?updateMask.fieldPaths=unread_count&updateMask.fieldPaths=updated_at';

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $updateData);

            if (!$response->successful()) {
                Log::error("FirestoreAdminSellerChatService: Failed to mark as read for seller_id: {$sellerId}", [
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
            Log::error("FirestoreAdminSellerChatService: Exception marking as read for seller_id: {$sellerId}", [
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
     * Delete chat for a seller
     *
     * @param int $sellerId
     * @return array
     */
    public static function deleteChat(int $sellerId): array
    {
        try {
            Log::info("FirestoreAdminSellerChatService: Deleting chat for seller_id: {$sellerId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $sellerId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->delete($url);

            if (!$response->successful() && $response->status() !== 404) {
                Log::error("FirestoreAdminSellerChatService: Failed to delete chat for seller_id: {$sellerId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to delete chat from Firestore'
                ];
            }

            Log::info("FirestoreAdminSellerChatService: Successfully deleted chat for seller_id: {$sellerId}");

            return [
                'success' => true,
                'message' => 'Chat deleted successfully'
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreAdminSellerChatService: Exception deleting chat for seller_id: {$sellerId}", [
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