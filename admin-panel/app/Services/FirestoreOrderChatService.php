<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use Carbon\Carbon;

/**
 * Service for Order Chat functionality using Firestore
 *
 * Collection: order_chats
 * Document: {order_id}
 * Sub-collections: customer, driver, seller
 * Message fields: message, order_id, read, recipient_type, sender_id, sender_name, sender_type, timestamp
 */
class FirestoreOrderChatService
{
    /**
     * Firestore collection name for order chats
     */
    private const COLLECTION_NAME = 'order_chats';

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
                Log::error('FirestoreOrderChatService: Firebase service account file not found');
                return null;
            }

            $credentials = json_decode(file_get_contents($filePath), true);

            if (!$credentials || !isset($credentials['project_id'])) {
                Log::error('FirestoreOrderChatService: Invalid Firebase service account file');
                return null;
            }

            return $credentials;
        } catch (\Exception $e) {
            Log::error('FirestoreOrderChatService: Failed to read Firebase credentials', [
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
            Log::error('FirestoreOrderChatService: Failed to generate JWT token', [
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
                Log::error('FirestoreOrderChatService: Failed to get access token', [
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
            Log::error('FirestoreOrderChatService: Failed to get access token', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Get project ID from credentials
     *
     * @return string|null
     */
    private static function getProjectId(): ?string
    {
        $credentials = self::getServiceAccountCredentials();
        return $credentials['project_id'] ?? null;
    }

    /**
     * Get Firestore base path for a document
     *
     * @param string $collection
     * @param string $documentId
     * @return string
     */
    private static function getDocumentPath(string $collection, string $documentId): string
    {
        $projectId = self::getProjectId();
        return self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/{$collection}/{$documentId}";
    }

    /**
     * Get Firestore path for sub-collection
     *
     * @param string $orderId
     * @param string $chatType customer|driver|seller
     * @return string
     */
    private static function getSubCollectionPath(string $orderId, string $chatType): string
    {
        $projectId = self::getProjectId();
        return self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/" . self::COLLECTION_NAME . "/{$orderId}/{$chatType}";
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
     * Get messages for a specific order and chat type
     *
     * @param int $orderId
     * @param string $chatType customer|driver|seller
     * @return array
     */
    public static function getMessages(int $orderId, string $chatType): array
    {
        try {
            Log::info("FirestoreOrderChatService: Fetching messages for order_id: {$orderId}, type: {$chatType}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token',
                    'data' => []
                ];
            }

            // Get messages from sub-collection, ordered by timestamp
            $url = self::getSubCollectionPath((string) $orderId, $chatType);
            $url .= '?orderBy=timestamp';

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($url);

            if (!$response->successful()) {
                // If 404, no messages exist yet - return empty array
                if ($response->status() === 404) {
                    return [
                        'success' => true,
                        'message' => 'No messages found',
                        'data' => []
                    ];
                }

                Log::error("FirestoreOrderChatService: Failed to fetch messages for order_id: {$orderId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to fetch messages from Firestore',
                    'data' => []
                ];
            }

            $responseData = $response->json();
            $messages = [];

            if (isset($responseData['documents'])) {
                foreach ($responseData['documents'] as $doc) {
                    $docPath = $doc['name'] ?? '';
                    $docId = basename($docPath);

                    $messageData = [
                        'id' => $docId
                    ];

                    if (isset($doc['fields'])) {
                        foreach ($doc['fields'] as $field => $value) {
                            $messageData[$field] = self::fromFirestoreValue($value);
                        }
                    }

                    $messages[] = $messageData;
                }
            }

            Log::info("FirestoreOrderChatService: Fetched " . count($messages) . " messages for order_id: {$orderId}");

            return [
                'success' => true,
                'message' => 'Messages fetched successfully',
                'data' => $messages
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderChatService: Exception fetching messages for order_id: {$orderId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while fetching messages',
                'error' => $e->getMessage(),
                'data' => []
            ];
        }
    }

    /**
     * Send a message to a specific order chat
     *
     * @param int $orderId
     * @param string $chatType customer|driver|seller
     * @param string $message
     * @param string $senderId
     * @param string $senderName
     * @param string $senderType admin|customer|driver|seller
     * @param string $recipientType admin|customer|driver|seller
     * @return array
     */
    public static function sendMessage(
        int $orderId,
        string $chatType,
        string $message,
        string $senderId,
        string $senderName,
        string $senderType,
        string $recipientType
    ): array {
        try {
            Log::info("FirestoreOrderChatService: Sending message for order_id: {$orderId}, type: {$chatType}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // First, ensure the parent document exists
            $parentUrl = self::getDocumentPath(self::COLLECTION_NAME, (string) $orderId);
            $parentData = [
                'fields' => [
                    'order_id' => self::toFirestoreValue((string) $orderId),
                    'created_at' => self::toFirestoreValue(Carbon::now()->setTimezone('Asia/Kolkata')->toIso8601String())
                ]
            ];

            Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($parentUrl, $parentData);

            // Prepare message data
            $timestamp = Carbon::now()->setTimezone('Asia/Kolkata')->toIso8601String();

            $firestoreData = [
                'fields' => [
                    'message' => self::toFirestoreValue($message),
                    'order_id' => self::toFirestoreValue((string) $orderId),
                    'read' => self::toFirestoreValue(false),
                    'recipient_type' => self::toFirestoreValue($recipientType),
                    'sender_id' => self::toFirestoreValue($senderId),
                    'sender_name' => self::toFirestoreValue($senderName),
                    'sender_type' => self::toFirestoreValue($senderType),
                    'timestamp' => ['timestampValue' => $timestamp]
                ]
            ];

            // Create message in sub-collection
            $url = self::getSubCollectionPath((string) $orderId, $chatType);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->post($url, $firestoreData);

            if (!$response->successful()) {
                Log::error("FirestoreOrderChatService: Failed to send message for order_id: {$orderId}", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to send message to Firestore',
                    'error' => $response->body()
                ];
            }

            $responseData = $response->json();
            $docPath = $responseData['name'] ?? '';
            $docId = basename($docPath);

            Log::info("FirestoreOrderChatService: Successfully sent message for order_id: {$orderId}", [
                'message_id' => $docId
            ]);

            return [
                'success' => true,
                'message' => 'Message sent successfully',
                'data' => [
                    'id' => $docId,
                    'message' => $message,
                    'order_id' => (string) $orderId,
                    'read' => false,
                    'recipient_type' => $recipientType,
                    'sender_id' => $senderId,
                    'sender_name' => $senderName,
                    'sender_type' => $senderType,
                    'timestamp' => $timestamp
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderChatService: Exception sending message for order_id: {$orderId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while sending message',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Mark messages as read
     *
     * @param int $orderId
     * @param string $chatType customer|driver|seller
     * @param array $messageIds Array of message IDs to mark as read
     * @return array
     */
    public static function markMessagesAsRead(int $orderId, string $chatType, array $messageIds): array
    {
        try {
            Log::info("FirestoreOrderChatService: Marking messages as read for order_id: {$orderId}");

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $projectId = self::getProjectId();
            $updatedCount = 0;

            foreach ($messageIds as $messageId) {
                $url = self::FIRESTORE_BASE_URL . "/projects/{$projectId}/databases/(default)/documents/"
                     . self::COLLECTION_NAME . "/{$orderId}/{$chatType}/{$messageId}";
                $url .= '?updateMask.fieldPaths=read';

                $firestoreData = [
                    'fields' => [
                        'read' => self::toFirestoreValue(true)
                    ]
                ];

                $response = Http::withToken($accessToken)
                    ->withOptions(['verify' => false])
                    ->patch($url, $firestoreData);

                if ($response->successful()) {
                    $updatedCount++;
                }
            }

            Log::info("FirestoreOrderChatService: Marked {$updatedCount} messages as read for order_id: {$orderId}");

            return [
                'success' => true,
                'message' => "Marked {$updatedCount} messages as read",
                'data' => [
                    'updated_count' => $updatedCount
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderChatService: Exception marking messages as read for order_id: {$orderId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while marking messages as read',
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Get unread message count for a specific order and chat type
     *
     * @param int $orderId
     * @param string $chatType customer|driver|seller
     * @param string $recipientType The type of recipient to count unread messages for
     * @return array
     */
    public static function getUnreadCount(int $orderId, string $chatType, string $recipientType = 'admin'): array
    {
        try {
            $result = self::getMessages($orderId, $chatType);

            if (!$result['success']) {
                return $result;
            }

            $unreadCount = 0;
            foreach ($result['data'] as $message) {
                if (isset($message['read']) && $message['read'] === false
                    && isset($message['recipient_type']) && $message['recipient_type'] === $recipientType) {
                    $unreadCount++;
                }
            }

            return [
                'success' => true,
                'message' => 'Unread count fetched successfully',
                'data' => [
                    'unread_count' => $unreadCount
                ]
            ];

        } catch (\Exception $e) {
            Log::error("FirestoreOrderChatService: Exception getting unread count for order_id: {$orderId}", [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Exception occurred while getting unread count',
                'error' => $e->getMessage(),
                'data' => ['unread_count' => 0]
            ];
        }
    }
}
