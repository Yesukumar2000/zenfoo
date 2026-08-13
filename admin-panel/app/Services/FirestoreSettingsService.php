<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class FirestoreSettingsService
{
    /**
     * Firestore collection name for settings
     */
    private const COLLECTION_NAME = 'settings_zenfoo';

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
            return $firestoreValue['doubleValue'];
        }
        if (isset($firestoreValue['stringValue'])) {
            return $firestoreValue['stringValue'];
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
     * Get store hours from Firestore
     *
     * @return array
     */
    public static function getStoreHours(): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'store_opening_time' => null,
                    'store_closing_time' => null
                ];
            }

            $url = self::getDocumentPath(self::COLLECTION_NAME, 'store_hours');

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($url);

            if (!$response->successful()) {
                // Document doesn't exist yet
                return [
                    'store_opening_time' => null,
                    'store_closing_time' => null
                ];
            }

            $data = $response->json();
            $fields = $data['fields'] ?? [];

            return [
                'store_opening_time' => isset($fields['store_opening_time'])
                    ? self::fromFirestoreValue($fields['store_opening_time'])
                    : null,
                'store_closing_time' => isset($fields['store_closing_time'])
                    ? self::fromFirestoreValue($fields['store_closing_time'])
                    : null
            ];
        } catch (\Exception $e) {
            Log::error('Failed to get store hours from Firestore', [
                'error' => $e->getMessage()
            ]);
            return [
                'store_opening_time' => null,
                'store_closing_time' => null
            ];
        }
    }

    /**
     * Update store hours in Firestore
     *
     * @param string|null $openingTime
     * @param string|null $closingTime
     * @return array
     */
    public static function updateStoreHours(?string $openingTime, ?string $closingTime): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }
            $documentData = [
                'fields' => [
                    'store_opening_time' => self::toFirestoreValue($openingTime),
                    'store_closing_time' => self::toFirestoreValue($closingTime),
                    'updated_at' => self::toFirestoreValue(now()->toIso8601String())
                ]
            ];

            $url = self::getDocumentPath(self::COLLECTION_NAME, 'store_hours');

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $documentData);

            if (!$response->successful()) {
                Log::error('Firestore store hours update failed', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to update store hours in Firestore'
                ];
            }

            Log::info('Store hours updated in Firestore', [
                'opening_time' => $openingTime,
                'closing_time' => $closingTime
            ]);

            return [
                'success' => true,
                'message' => 'Store hours updated successfully in Firestore'
            ];
        } catch (\Exception $e) {
            Log::error('Failed to update store hours in Firestore', [
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to update: ' . $e->getMessage()
            ];
        }
    }
}
