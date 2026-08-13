<?php

namespace App\Services;

use App\Models\DeliveryBoy;
use App\Models\DeliveryBoySession;
use App\Models\DeliveryBoyLocationHistory;
use App\Models\PendingDeliveryAssignment;
use App\Models\OrderDeliveryBoyNotification;
use App\Models\Setting;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;
use App\Services\OrderStoreSegregationService;

class FirestoreDeliveryBoyService
{
    /**
     * Firestore collection name for delivery boys
     */
    private const COLLECTION_NAME = 'delivery_boys';

    /**
     * Earth radius in kilometers for Haversine formula
     */
    private const EARTH_RADIUS_KM = 6371;

    /**
     * Firestore REST API base URL
     */
    private const FIRESTORE_BASE_URL = 'https://firestore.googleapis.com/v1';

    /**
     * Tiered dispatch defaults (used when the admin settings are missing/blank)
     */
    private const DEFAULT_TIER_STEP_KM      = 1.0;   // ring increment (1 km, 2 km, 3 km, ...)
    private const DEFAULT_MAX_RADIUS_KM     = 5.0;   // outer limit — never offer beyond this
    private const DEFAULT_OFFER_TIMEOUT_SEC = 25;    // wait per ring before expanding outward

    /**
     * Admin-configurable ring increment in km (the "1 km / 2 km / 3 km" step).
     * Clamped to a sane minimum so a bad value can't create thousands of rings.
     */
    public static function dispatchTierStepKm(): float
    {
        $value = (float) Setting::get_value('dispatch_tier_step_km');
        return $value > 0 ? $value : self::DEFAULT_TIER_STEP_KM;
    }

    /**
     * Admin-configurable outer search limit in km. Offers never expand past this.
     */
    public static function dispatchMaxRadiusKm(): float
    {
        $value = (float) Setting::get_value('dispatch_max_radius_km');
        return $value > 0 ? $value : self::DEFAULT_MAX_RADIUS_KM;
    }

    /**
     * Admin-configurable wait (seconds) for a ring to accept before expanding outward.
     */
    public static function dispatchOfferTimeoutSeconds(): int
    {
        $value = (int) Setting::get_value('dispatch_offer_timeout_sec');
        return $value > 0 ? $value : self::DEFAULT_OFFER_TIMEOUT_SEC;
    }

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
            // An empty PHP array is ambiguous: json_encode() renders it as `[]`, so
            // wrapping it in a mapValue produces {"fields": []} and Firestore rejects
            // the whole document with "Cannot bind a list to map for field 'fields'".
            // Every empty array we write is a list (step_statuses, sellers_visit_order,
            // items_from_completed_sellers, ...), so emit an empty arrayValue.
            if (empty($value)) {
                return ['arrayValue' => ['values' => []]];
            }
            // Check if it's an associative array (map) or indexed array
            if (array_keys($value) !== range(0, count($value) - 1)) {
                // Associative array - convert to map
                return self::toFirestoreMap($value);
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
     * Convert a PHP array to a Firestore mapValue, regardless of its keys.
     * Use this when the value must be a map even if it is empty or its keys
     * happen to look like a list (e.g. the orders map keyed by order id).
     *
     * @param array $value
     * @return array
     */
    private static function toFirestoreMap(array $value): array
    {
        $fields = [];
        foreach ($value as $k => $v) {
            $fields[(string) $k] = self::toFirestoreValue($v);
        }

        // Cast to object so an empty map still encodes as {} and not [].
        return ['mapValue' => ['fields' => (object) $fields]];
    }

    /**
     * Get available delivery boy IDs
     *
     * @return array Array of delivery boy IDs who are available
     */
    public static function getAvailableDeliveryBoyIds(): array
    {
        return DB::table('delivery_boys')
            ->where('is_available', 1)
            ->where('is_problematic', 0)
            ->pluck('id')
            ->toArray();
    }

    /**
     * Get available delivery boys with basic details
     *
     * @return array Array of delivery boys with id, name, mobile
     */
    public static function getAvailableDeliveryBoys(): array
    {
        return DB::table('delivery_boys')
            ->where('is_available', 1)
            ->where('is_problematic', 0)
            ->select('id', 'name', 'mobile', 'latitude', 'longitude')
            ->get()
            ->toArray();
    }

    /**
     * Get seller locations for a given order
     *
     * @param int $orderId The order ID
     * @return array Array of seller locations with seller_id, latitude, longitude
     */
    public static function getSellerLocationsByOrderId(int $orderId): array
    {
        // Get all seller IDs from order_seller_status_tracking table
        $allSellerIds = DB::table('order_seller_status_tracking')
            ->where('order_id', $orderId)
            ->pluck('seller_id')
            ->toArray();

        // Separate real seller IDs from null (Zenfoo store items)
        $sellerIds = array_filter($allSellerIds, fn($id) => $id !== null);
        $hasZenfooItems = in_array(null, $allSellerIds, true);

        Log::info('Seller locations lookup', [
            'order_id' => $orderId,
            'total_tracking_rows' => count($allSellerIds),
            'seller_ids' => array_values($sellerIds),
            'has_zenfoo_items' => $hasZenfooItems,
        ]);

        $sellerLocations = [];

        // Get seller lat_long from sellers table
        if (!empty($sellerIds)) {
            $sellers = DB::table('sellers')
                ->whereIn('id', $sellerIds)
                ->select('id', 'lat_long', 'store_name')
                ->get();

            foreach ($sellers as $seller) {
                $latitude = null;
                $longitude = null;

                // Parse lat_long string (format: "17.438925073025825,78.39837715029716")
                if (!empty($seller->lat_long)) {
                    $coords = explode(',', $seller->lat_long);
                    if (count($coords) === 2) {
                        $latitude = trim($coords[0]);
                        $longitude = trim($coords[1]);
                    }
                }

                $sellerLocations[] = [
                    'seller_id' => $seller->id,
                    'store_name' => $seller->store_name,
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                ];
            }

            Log::info('Seller locations resolved', [
                'order_id' => $orderId,
                'sellers_found' => count($sellerLocations),
                'sellers' => array_map(fn($s) => [
                    'id' => $s['seller_id'],
                    'name' => $s['store_name'],
                    'has_location' => !empty($s['latitude']),
                ], $sellerLocations),
            ]);
        }

        // If order has Zenfoo items, add nearest Zenfoo store location
        if ($hasZenfooItems) {
            $nearestStore = self::getNearestStoreLocationForOrder($orderId);
            if ($nearestStore) {
                $sellerLocations[] = $nearestStore;
            } else {
                Log::warning('Zenfoo store items found but could not resolve nearest store location', [
                    'order_id' => $orderId,
                ]);
            }
        }

        Log::info('Final pickup locations for driver search', [
            'order_id' => $orderId,
            'total_locations' => count($sellerLocations),
            'locations' => array_map(fn($s) => [
                'name' => $s['store_name'],
                'type' => $s['seller_id'] ? 'seller' : 'zenfoo_store',
                'lat' => $s['latitude'],
                'lng' => $s['longitude'],
            ], $sellerLocations),
        ]);

        return $sellerLocations;
    }

    /**
     * Find the nearest active store_locations entry to the customer's delivery address.
     * Used as fallback for Zenfoo-only orders that have no seller locations.
     */
    private static function getNearestStoreLocationForOrder(int $orderId): ?array
    {
        // Get customer address from order
        $order = DB::table('orders')->where('id', $orderId)->select('address_id')->first();
        if (!$order || !$order->address_id) {
            Log::warning('Nearest store lookup: No address_id on order', [
                'order_id' => $orderId,
            ]);
            return null;
        }

        $address = DB::table('user_addresses')
            ->where('id', $order->address_id)
            ->select('latitude', 'longitude')
            ->first();

        if (!$address || !$address->latitude || !$address->longitude) {
            Log::warning('Nearest store lookup: Customer address has no lat/lon', [
                'order_id' => $orderId,
                'address_id' => $order->address_id,
            ]);
            return null;
        }

        $customerLat = (float) $address->latitude;
        $customerLon = (float) $address->longitude;

        // Get all active store locations
        $stores = DB::table('store_locations')
            ->where('status', 1)
            ->select('id', 'name', 'latitude', 'longitude')
            ->get();

        if ($stores->isEmpty()) {
            Log::warning('Nearest store lookup: No active store locations found', [
                'order_id' => $orderId,
            ]);
            return null;
        }

        // Calculate distance from customer to each store
        $nearestStore = null;
        $minDistance = PHP_FLOAT_MAX;
        $storeDistances = [];

        foreach ($stores as $store) {
            if (!$store->latitude || !$store->longitude) {
                continue;
            }

            $distance = self::calculateDistance(
                $customerLat, $customerLon,
                (float) $store->latitude, (float) $store->longitude
            );

            if ($distance !== null) {
                $storeDistances[] = [
                    'store_id' => $store->id,
                    'store_name' => $store->name,
                    'distance_km' => round($distance, 2),
                ];

                if ($distance < $minDistance) {
                    $minDistance = $distance;
                    $nearestStore = $store;
                }
            }
        }

        if (!$nearestStore) {
            Log::warning('Nearest store lookup: Could not calculate distance to any store', [
                'order_id' => $orderId,
            ]);
            return null;
        }

        Log::info('Nearest Zenfoo store resolved for driver search', [
            'order_id' => $orderId,
            'customer_lat' => $customerLat,
            'customer_lon' => $customerLon,
            'nearest_store_id' => $nearestStore->id,
            'nearest_store_name' => $nearestStore->name,
            'distance_km' => round($minDistance, 2),
            'all_store_distances' => $storeDistances,
        ]);

        return [
            'seller_id' => null,
            'store_name' => $nearestStore->name,
            'latitude' => $nearestStore->latitude,
            'longitude' => $nearestStore->longitude,
        ];
    }

    /**
     * Get available delivery boys within a specified radius of sellers for an order
     * Filters drivers into on_ride and not_on_ride categories
     * Also filters based on driver's order_priority setting:
     *   - 0 = Both (can handle all orders)
     *   - 1 = Admin-managed orders only (stores with managed_by_admin = 1)
     *
     * @param int $orderId The order ID
     * @param float $radiusKm The radius in kilometers (default 10km)
     * @return array Array with on_ride and not_on_ride delivery boys
     */
    public static function getAvailableDeliveryBoysNearOrderSellers(int $orderId, float $radiusKm = 5): array
    {
        // Log::info('=== Driver Search Started ===', [
        //     'order_id' => $orderId,
        //     'radius_km' => $radiusKm
        // ]);

        // Get seller locations for this order
        $sellerLocations = self::getSellerLocationsByOrderId($orderId);

        if (empty($sellerLocations)) {
            // Log::warning('Driver search aborted: No seller locations found for order', [
            //     'order_id' => $orderId
            // ]);
            return [
                'on_ride' => [],
                'not_on_ride' => []
            ];
        }

        // Log::info('Seller locations for order', [
        //     'order_id' => $orderId,
        //     'seller_count' => count($sellerLocations),
        //     'sellers' => array_map(fn($s) => [
        //         'seller_id' => $s['seller_id'],
        //         'store_name' => $s['store_name'] ?? null,
        //         'lat' => $s['latitude'],
        //         'lng' => $s['longitude'],
        //     ], $sellerLocations)
        // ]);

        $hasNonAdminManagedItems = OrderStoreSegregationService::orderHasNonAdminManagedItems($orderId);

        $allDeliveryBoys = DB::table('delivery_boys')
            ->select('id', 'name', 'is_available', 'orders_priority', 'is_problematic')
            ->get();

        // Drivers held back by admin (problematic list) never receive new orders.
        $problematicCount = $allDeliveryBoys->where('is_problematic', 1)->count();
        $allDeliveryBoys  = $allDeliveryBoys->where('is_problematic', 0);

        if ($problematicCount > 0) {
            Log::info('Driver search: problematic drivers excluded', [
                'order_id' => $orderId,
                'excluded' => $problematicCount,
            ]);
        }

        $availableDeliveryBoys = $allDeliveryBoys->where('is_available', 1);
        $unavailableCount = $allDeliveryBoys->where('is_available', 0)->count();

        // Log::info('Driver availability check', [
        //     'order_id' => $orderId,
        //     'total_drivers' => $allDeliveryBoys->count(),
        //     'available (is_available=1)' => $availableDeliveryBoys->count(),
        //     'unavailable (is_available=0)' => $unavailableCount
        // ]);

        if ($availableDeliveryBoys->isEmpty()) {
            // Log::warning('Driver search aborted: No drivers have is_available=1', [
            //     'order_id' => $orderId
            // ]);
            return [
                'on_ride' => [],
                'not_on_ride' => []
            ];
        }

        $nearbyDrivers = [];

        // ── Stage 1: Online filter (batch — one query for all drivers) ────────
        $onlineDriverIds = DB::table('delivery_boy_sessions')
            ->whereNull('logout_at')
            ->pluck('delivery_boy_id')
            ->unique()
            ->values()
            ->toArray();

        $onlineDeliveryBoys  = $availableDeliveryBoys->whereIn('id', $onlineDriverIds)->values();
        $totalAvailable      = $availableDeliveryBoys->count();
        $onlineCount         = $onlineDeliveryBoys->count();
        $offlineCount        = $totalAvailable - $onlineCount;

        // ── Stage 1b: Drop drivers who already refused THIS order ────────────
        // A rejection (explicit tap or the app's 60s auto-reject) is recorded in
        // delivery_boy_order_cancellations. Without this filter every expanding
        // retry ring re-offers the same order to the same driver, so a driver who
        // said no keeps getting the same popup back every few seconds.
        $rejectedDriverIds = DB::table('delivery_boy_order_cancellations')
            ->where('order_id', $orderId)
            ->pluck('delivery_boy_id')
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->toArray();

        $rejectedDrivers = [];

        if (!empty($rejectedDriverIds)) {
            $rejectedDrivers = $onlineDeliveryBoys
                ->whereIn('id', $rejectedDriverIds)
                ->map(fn($d) => ['id' => $d->id, 'name' => $d->name])
                ->values()
                ->toArray();

            $onlineDeliveryBoys = $onlineDeliveryBoys
                ->reject(fn($d) => in_array((int) $d->id, $rejectedDriverIds, true))
                ->values();
        }

        $rejectedCount = count($rejectedDrivers);

        // Log::info('Driver Search | Stage 1 — Online filter', [
        //     'order_id'       => $orderId,
        //     'total_available' => $totalAvailable,
        //     'online'         => $onlineCount,
        //     'offline'        => $offlineCount,
        // ]);

        // ── Stage 2: Batch-fetch latest location per online driver ────────────
        $onlineIds = $onlineDeliveryBoys->pluck('id')->toArray();

        $latestLocations = DB::table('delivery_boy_location_history')
            ->whereIn('delivery_boy_id', $onlineIds)
            ->select('delivery_boy_id', 'latitude', 'longitude', 'tracked_at')
            ->orderBy('tracked_at', 'desc')
            ->get()
            ->unique('delivery_boy_id')
            ->keyBy('delivery_boy_id');

        // ── Stage 3: Seller radius filter — driver within Xkm of any seller ──
        $withinRadiusDrivers = [];
        $noLocationCount     = 0;
        $outOfRadiusCount    = 0;

        foreach ($onlineDeliveryBoys as $deliveryBoy) {
            $loc = $latestLocations->get($deliveryBoy->id);

            if (!$loc || !$loc->latitude || !$loc->longitude) {
                $noLocationCount++;
                continue;
            }

            $driverLat = (float) $loc->latitude;
            $driverLng = (float) $loc->longitude;

            // Check if driver is within radius of at least one seller
            $nearAnySeller = false;
            foreach ($sellerLocations as $seller) {
                $sellerLat = (float) ($seller['latitude'] ?? 0);
                $sellerLng = (float) ($seller['longitude'] ?? 0);

                if (!$sellerLat || !$sellerLng) {
                    continue;
                }

                $distanceToSeller = self::calculateDistance($driverLat, $driverLng, $sellerLat, $sellerLng);
                if ($distanceToSeller !== null && $distanceToSeller <= $radiusKm) {
                    $nearAnySeller = true;
                    break;
                }
            }

            if (!$nearAnySeller) {
                $outOfRadiusCount++;
                continue;
            }

            $withinRadiusDrivers[] = [
                'id'   => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'lat'  => $driverLat,
                'lng'  => $driverLng,
            ];
        }

        $withinRadiusCount = count($withinRadiusDrivers);

        // ── Stage 4: Order priority (only within-radius drivers)
        // Individual skip reasons only logged for this smaller set.
        $skippedReasons = [
            'funnel_summary' => [
                'total_available'  => $totalAvailable,
                'online'           => $onlineCount,
                'offline'          => $offlineCount,
                'already_rejected' => $rejectedCount,
                'no_location'      => $noLocationCount,
                'out_of_radius'    => $outOfRadiusCount,
                'within_radius'    => $withinRadiusCount,
            ],
            'already_rejected'      => $rejectedDrivers,
            'order_priority'        => [],
            // 'no_active_gig_booking' => [], // COMMENTED OUT: No longer checking gig bookings
        ];

        // COMMENTED OUT: Gig window time variables - No longer needed without gig requirement
        /*
        // Pre-compute gig window times once
        $currentDateTime     = now();
        $currentDate         = $currentDateTime->toDateString();
        $currentTime         = $currentDateTime->toTimeString();
        $fifteenMinutesLater = $currentDateTime->copy()->addMinutes(15)->toTimeString();
        */

        foreach ($withinRadiusDrivers as $driver) {
            // Order priority check
            $deliveryBoyRecord = $availableDeliveryBoys->firstWhere('id', $driver['id']);
            if ($deliveryBoyRecord && $deliveryBoyRecord->orders_priority == 1 && $hasNonAdminManagedItems) {
                $skippedReasons['order_priority'][] = [
                    'id'   => $driver['id'],
                    'name' => $driver['name'],
                ];
                continue;
            }

            // COMMENTED OUT: Gig booking check - Driver can receive orders without gigs
            /*
            // Gig booking check
            $activeGigBooking = DB::table('delivery_boy_gig_bookings as bookings')
                ->join('gig_slots as slots', 'bookings.gig_slot_id', '=', 'slots.id')
                ->where('bookings.delivery_boy_id', $driver['id'])
                ->whereIn('bookings.booking_status', ['booked', 'active'])
                ->where('slots.slot_date', $currentDate)
                ->where(function ($query) use ($currentTime, $fifteenMinutesLater) {
                    $query->where(function ($q) use ($currentTime) {
                        $q->where('slots.start_time', '<=', $currentTime)
                          ->where('slots.end_time', '>=', $currentTime);
                    })
                    ->orWhere(function ($q) use ($currentTime, $fifteenMinutesLater) {
                        $q->where('slots.start_time', '>', $currentTime)
                          ->where('slots.start_time', '<=', $fifteenMinutesLater);
                    });
                })
                ->first();

            if (!$activeGigBooking) {
                $skippedReasons['no_active_gig_booking'][] = [
                    'id'   => $driver['id'],
                    'name' => $driver['name'],
                ];
                continue;
            }
            */

            // Passed all checks
            $nearbyDrivers[$driver['id']] = [
                'id'   => $driver['id'],
                'name' => $driver['name'],
            ];
        }

        // if (!empty($skippedReasons['order_priority'])) {
        //     Log::info('Driver Search | Stage 4 — Order priority skipped', [
        //         'order_id' => $orderId,
        //         'count'    => count($skippedReasons['order_priority']),
        //         'drivers'  => $skippedReasons['order_priority'],
        //     ]);
        // }

        // COMMENTED OUT: Gig booking logging - No longer checking gig bookings
        // if (!empty($skippedReasons['no_active_gig_booking'])) {
        //     Log::info('Driver Search | Stage 4 — No active gig booking', [
        //         'order_id' => $orderId,
        //         'count'    => count($skippedReasons['no_active_gig_booking']),
        //         'drivers'  => $skippedReasons['no_active_gig_booking'],
        //     ]);
        // }

        // Log::info('Drivers within radius (before filters)', [
        //     'order_id' => $orderId,
        //     'count' => count($nearbyDrivers),
        //     'drivers' => array_values($nearbyDrivers)
        // ]);

        // Filter out drivers who have exceeded hand cash limit
        $nearbyDriversFiltered = HandCashLimitService::filterByHandCashLimit(array_values($nearbyDrivers));

        // Capture hand-cash-excluded drivers (with names) for skip reasons
        $filteredPassIds = array_column($nearbyDriversFiltered, 'id');
        $handCashExcludedDrivers = array_values(array_filter(
            array_values($nearbyDrivers),
            fn($d) => !in_array($d['id'], $filteredPassIds)
        ));
        $handCashExcluded = count($handCashExcludedDrivers);

        // if ($handCashExcluded > 0) {
        //     Log::info('Drivers removed by hand cash limit filter', [
        //         'order_id'      => $orderId,
        //         'excluded_count' => $handCashExcluded,
        //         'drivers'       => array_map(fn($d) => ['id' => $d['id'], 'name' => $d['name']], $handCashExcludedDrivers),
        //     ]);
        // }

        // Filter drivers into on_ride and not_on_ride categories
        $result = self::filterDriversByRideStatus($nearbyDriversFiltered);

        // ── Final skip reasons: hand cash + on-ride ─────────────────────────
        $skippedReasons['hand_cash_exceeded'] = array_map(
            fn($d) => ['id' => $d['id'], 'name' => $d['name']],
            $handCashExcludedDrivers
        );
        $skippedReasons['on_ride'] = array_map(
            fn($d) => ['id' => $d['id'], 'name' => $d['name']],
            $result['on_ride']
        );

        // Update funnel summary with final output count
        $skippedReasons['funnel_summary']['hand_cash_excluded'] = $handCashExcluded;
        $skippedReasons['funnel_summary']['on_ride']            = count($result['on_ride']);
        $skippedReasons['funnel_summary']['final_notified']     = count($result['not_on_ride']);

        $funnel = $skippedReasons['funnel_summary'];
        // Log::info('=== Driver Search Completed ===', [
        //     'order_id'                        => $orderId,
        //     'stage0_total_available'          => $funnel['total_available'],
        //     'stage1_online'                   => $funnel['online'],
        //     'stage1_offline'                  => $funnel['offline'],
        //     'stage2_no_location'              => $funnel['no_location'],
        //     'stage2_out_of_radius'            => $funnel['out_of_radius'],
        //     'stage2_within_radius'            => $funnel['within_radius'],
        //     'stage3_skipped_order_priority'   => count($skippedReasons['order_priority']),
        //     // 'stage4_skipped_no_gig_booking'   => count($skippedReasons['no_active_gig_booking']), // REMOVED: No longer checking gigs
        //     'stage4_skipped_hand_cash'        => $handCashExcluded,
        //     'stage5_skipped_on_ride'          => count($result['on_ride']),
        //     'final_notified'                  => $funnel['final_notified'],
        //     'not_on_ride_drivers'             => array_map(fn($d) => ['id' => $d['id'], 'name' => $d['name']], $result['not_on_ride']),
        //     'on_ride_drivers'                 => array_map(fn($d) => ['id' => $d['id'], 'name' => $d['name']], $result['on_ride']),
        // ]);

        return array_merge($result, ['skipped_reasons' => $skippedReasons]);
    }

    /**
     * Sync available delivery boys to Firestore for an order
     * Uses Firestore REST API (no gRPC required)
     * Only syncs if not_on_ride array is not empty
     *
     * New Structure:
     * delivery_boys (collection)
     *   └── {delivery_boy_id} (document)
     *         └── orders: { order_id: order_id, ... }
     *
     * @param int $orderId The order ID
     * @param array $notOnRideDrivers Array of drivers who are not on ride
     * @return array Result with success status and message
     */
    public static function syncToFirestore(int $orderId, array $notOnRideDrivers): array
    {
        try {
            // Only sync if not_on_ride is not empty
            if (empty($notOnRideDrivers)) {
                return [
                    'success' => false,
                    'message' => 'No available drivers (not_on_ride is empty), skipping Firestore sync'
                ];
            }

            // Get access token
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $successCount = 0;
            $failedCount = 0;
            $deliveryBoyIds = [];

            // For each delivery boy, add the order to their document
            foreach ($notOnRideDrivers as $driver) {
                $deliveryBoyId = $driver['id'];
                $deliveryBoyIds[] = $deliveryBoyId;

                // First, get existing document to preserve existing orders
                $existingOrders = self::getDeliveryBoyOrders($accessToken, $deliveryBoyId);

                // Add new order to the orders map
                $existingOrders[(string) $orderId] = $orderId;

                // Build Firestore document with orders map
                $documentData = [
                    'fields' => [
                        // Always a map, even when the order ids happen to look like list keys
                        'orders' => self::toFirestoreMap($existingOrders),
                        'updated_at' => self::toFirestoreValue(now()->toIso8601String()),
                    ]
                ];

                // Make REST API call to create/update document
                $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $deliveryBoyId);

                $response = Http::withToken($accessToken)
                    ->withOptions(['verify' => false])
                    ->patch($url, $documentData);

                if ($response->successful()) {
                    $successCount++;
                } else {
                    $failedCount++;
                    Log::error('Firestore sync failed for delivery boy', [
                        'delivery_boy_id' => $deliveryBoyId,
                        'order_id' => $orderId,
                        'status' => $response->status(),
                        'body' => $response->body()
                    ]);
                }
            }

            if ($failedCount > 0 && $successCount === 0) {
                return [
                    'success' => false,
                    'message' => "Firestore sync failed for all {$failedCount} delivery boys"
                ];
            }

            Log::info('Firestore sync completed', [
                'order_id' => $orderId,
                'delivery_boy_ids' => $deliveryBoyIds,
                'success_count' => $successCount,
                'failed_count' => $failedCount,
                'collection' => self::COLLECTION_NAME
            ]);

            return [
                'success' => true,
                'message' => "Successfully synced to {$successCount} delivery boys" . ($failedCount > 0 ? ", {$failedCount} failed" : ''),
                'delivery_boy_ids' => $deliveryBoyIds,
                'success_count' => $successCount,
                'failed_count' => $failedCount
            ];

        } catch (\Exception $e) {
            Log::error('Firestore sync failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Firestore sync failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get existing orders for a delivery boy from Firestore
     *
     * @param string $accessToken The access token
     * @param int $deliveryBoyId The delivery boy ID
     * @return array Existing orders map
     */
    private static function getDeliveryBoyOrders(string $accessToken, int $deliveryBoyId): array
    {
        try {
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $deliveryBoyId);

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
                    // Extract the integer value from the Firestore format
                    $orderId = $value['integerValue'] ?? $value['stringValue'] ?? $key;
                    $orders[$key] = (int) $orderId;
                }
                return $orders;
            }

            return [];
        } catch (\Exception $e) {
            Log::warning('Failed to get existing orders for delivery boy', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);
            return [];
        }
    }

    /**
     * Every delivery boy who was ever offered this order across all attempts.
     * This is exactly the set whose Firestore `orders` map can still hold the
     * order id (trackNotification records the same ids syncToFirestore wrote).
     *
     * @param int $orderId The order ID
     * @return array Unique delivery boy IDs
     */
    public static function getNotifiedDeliveryBoyIds(int $orderId): array
    {
        $ids = OrderDeliveryBoyNotification::where('order_id', $orderId)
            ->pluck('delivery_boy_ids')
            ->flatten()
            ->filter()
            ->map(fn($id) => (int) $id)
            ->unique()
            ->values()
            ->toArray();

        return $ids;
    }

    /**
     * Remove one offered order from the `orders` map on the given delivery boys'
     * Firestore documents.
     *
     * The driver app listens to `delivery_boys/{id}` and drives the incoming-order
     * popup off that map, so deleting the key is what makes the popup close on the
     * phones that lost the race. Uses an updateMask on the single nested field so
     * the rest of the document (e.g. current_order) is left untouched.
     *
     * @param int      $orderId             The order that is no longer on offer
     * @param array    $deliveryBoyIds      Drivers to clear it from
     * @param int|null $exceptDeliveryBoyId Driver to skip (usually the accepter)
     * @return array Result with success status and per-driver counts
     */
    public static function removeOrderFromDeliveryBoys(int $orderId, array $deliveryBoyIds, ?int $exceptDeliveryBoyId = null): array
    {
        try {
            $targets = collect($deliveryBoyIds)
                ->map(fn($id) => (int) $id)
                ->filter()
                ->unique()
                ->reject(fn($id) => $exceptDeliveryBoyId !== null && $id === (int) $exceptDeliveryBoyId)
                ->values();

            if ($targets->isEmpty()) {
                return [
                    'success' => true,
                    'message' => 'No other delivery boys to clear',
                    'cleared_count' => 0,
                    'failed_count' => 0,
                ];
            }

            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token',
                    'cleared_count' => 0,
                    'failed_count' => $targets->count(),
                ];
            }

            // Numeric map keys are not valid field-path identifiers, so they must
            // be backtick-quoted: orders.`123`
            $fieldPath = 'orders.`' . $orderId . '`';

            $clearedCount = 0;
            $failedCount = 0;
            $failedIds = [];

            foreach ($targets as $deliveryBoyId) {
                $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $deliveryBoyId)
                    . '?updateMask.fieldPaths=' . urlencode($fieldPath);

                // Field named in the mask but absent from the body => deleted.
                $response = Http::withToken($accessToken)
                    ->withOptions(['verify' => false])
                    ->patch($url, ['fields' => (object) []]);

                if ($response->successful()) {
                    $clearedCount++;
                } else {
                    $failedCount++;
                    $failedIds[] = $deliveryBoyId;
                    Log::error('Firestore offer cleanup failed for delivery boy', [
                        'delivery_boy_id' => $deliveryBoyId,
                        'order_id' => $orderId,
                        'status' => $response->status(),
                        'body' => $response->body(),
                    ]);
                }
            }

            Log::info('Firestore offer cleanup completed', [
                'order_id' => $orderId,
                'except_delivery_boy_id' => $exceptDeliveryBoyId,
                'cleared_count' => $clearedCount,
                'failed_count' => $failedCount,
                'failed_ids' => $failedIds,
            ]);

            return [
                'success' => $failedCount === 0,
                'message' => "Cleared offer from {$clearedCount} delivery boys" . ($failedCount > 0 ? ", {$failedCount} failed" : ''),
                'cleared_count' => $clearedCount,
                'failed_count' => $failedCount,
                'failed_ids' => $failedIds,
            ];

        } catch (\Exception $e) {
            Log::error('Firestore offer cleanup failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => 'Firestore offer cleanup failed: ' . $e->getMessage(),
                'cleared_count' => 0,
                'failed_count' => count($deliveryBoyIds),
            ];
        }
    }

    /**
     * Clear an order that is no longer on offer from every delivery boy who was
     * notified about it. Convenience wrapper around removeOrderFromDeliveryBoys.
     *
     * @param int      $orderId             The order ID
     * @param int|null $exceptDeliveryBoyId Driver to skip (usually the accepter)
     * @return array
     */
    public static function clearOrderOfferFromOtherDeliveryBoys(int $orderId, ?int $exceptDeliveryBoyId = null): array
    {
        return self::removeOrderFromDeliveryBoys(
            $orderId,
            self::getNotifiedDeliveryBoyIds($orderId),
            $exceptDeliveryBoyId
        );
    }

    /**
     * Get available delivery boys and sync to Firestore
     * Combines getAvailableDeliveryBoysNearOrderSellers and syncToFirestore
     * If no delivery boys available, stores in pending_delivery_assignments table
     * Also tracks notifications in order_delivery_boy_notifications table
     *
     * @param int $orderId The order ID
     * @param float|null $radiusKm The search radius in km. When null, starts at the
     *                             first tier ring (admin "tier step") so the initial
     *                             offer goes only to the nearest drivers; the retry
     *                             chain then expands the radius ring by ring.
     * @return array Result with drivers and Firestore sync status
     */
    public static function getAndSyncAvailableDeliveryBoys(int $orderId, ?float $radiusKm = null): array
    {
        // Default the very first offer to ring 1 (nearest drivers only).
        if ($radiusKm === null) {
            $radiusKm = self::dispatchTierStepKm();
        }

        // Get seller locations for storing in pending table if needed
        $sellerLocations = self::getSellerLocationsByOrderId($orderId);

        // Get available delivery boys
        $result = self::getAvailableDeliveryBoysNearOrderSellers($orderId, $radiusKm);

        // Extract skipped reasons (added to result array)
        $skippedReasons = $result['skipped_reasons'] ?? null;

        // Get next attempt number
        $attemptNumber = OrderDeliveryBoyNotification::getNextAttemptNumber($orderId);

        // Extract IDs for tracking
        $notOnRideIds = array_map(fn($d) => $d['id'], $result['not_on_ride']);
        $onRideIds = array_map(fn($d) => $d['id'], $result['on_ride']);

        // If no delivery boys available (not_on_ride is empty), store in pending table
        if (empty($result['not_on_ride'])) {
            $pendingResult = self::storePendingDeliveryAssignment($orderId, $sellerLocations);

            // Track the failed notification attempt
            self::trackNotification($orderId, $attemptNumber, [], $onRideIds, 'failed', 'No available drivers', $skippedReasons);

            return [
                'on_ride' => $result['on_ride'],
                'not_on_ride' => $result['not_on_ride'],
                'firestore_sync' => [
                    'success' => false,
                    'message' => 'No available drivers, stored in pending assignments'
                ],
                'pending_assignment' => $pendingResult,
                'notification' => [
                    'attempt_number' => $attemptNumber,
                    'drivers_notified' => 0,
                    'on_ride_count' => count($onRideIds)
                ]
            ];
        }

        // Sync to Firestore if not_on_ride is not empty
        $firestoreResult = self::syncToFirestore($orderId, $result['not_on_ride']);

        // Track the notification
        $notificationStatus = $firestoreResult['success'] ? 'sent' : 'failed';
        $errorMessage = $firestoreResult['success'] ? null : $firestoreResult['message'];
        $notificationRecord = self::trackNotification($orderId, $attemptNumber, $notOnRideIds, $onRideIds, $notificationStatus, $errorMessage, $skippedReasons);

        // If Firestore sync successful, remove from pending table if exists
        if ($firestoreResult['success']) {
            self::removePendingDeliveryAssignment($orderId);
        }

        return [
            'on_ride' => $result['on_ride'],
            'not_on_ride' => $result['not_on_ride'],
            'firestore_sync' => $firestoreResult,
            'notification' => [
                'id' => $notificationRecord->id ?? null,
                'attempt_number' => $attemptNumber,
                'drivers_notified' => count($notOnRideIds),
                'on_ride_count' => count($onRideIds)
            ]
        ];
    }

    /**
     * Track notification sent to delivery boys
     *
     * @param int $orderId The order ID
     * @param int $attemptNumber The attempt number
     * @param array $deliveryBoyIds IDs of delivery boys notified
     * @param array $onRideIds IDs of delivery boys who were on ride
     * @param string $status Status of notification (sent/failed)
     * @param string|null $errorMessage Error message if failed
     * @return OrderDeliveryBoyNotification
     */
    public static function trackNotification(
        int $orderId,
        int $attemptNumber,
        array $deliveryBoyIds,
        array $onRideIds,
        string $status = 'sent',
        ?string $errorMessage = null,
        ?array $skipReasons = null
    ): OrderDeliveryBoyNotification {
        return OrderDeliveryBoyNotification::create([
            'order_id' => $orderId,
            'attempt_number' => $attemptNumber,
            'delivery_boy_ids' => $deliveryBoyIds,
            'drivers_notified_count' => count($deliveryBoyIds),
            'on_ride_driver_ids' => $onRideIds,
            'on_ride_count' => count($onRideIds),
            'status' => $status,
            'notified_at' => now(),
            'error_message' => $errorMessage,
            'skip_reasons' => $skipReasons,
        ]);
    }

    /**
     * Get notification history for an order
     *
     * @param int $orderId The order ID
     * @return array
     */
    public static function getNotificationHistory(int $orderId): array
    {
        $notifications = OrderDeliveryBoyNotification::where('order_id', $orderId)
            ->orderBy('attempt_number', 'asc')
            ->get();

        $totalNotified = $notifications->sum('drivers_notified_count');
        $totalAttempts = $notifications->count();

        return [
            'order_id' => $orderId,
            'total_attempts' => $totalAttempts,
            'total_drivers_notified' => $totalNotified,
            'attempts' => $notifications->map(function ($n) {
                return [
                    'attempt_number' => $n->attempt_number,
                    'drivers_notified_count' => $n->drivers_notified_count,
                    'delivery_boy_ids' => $n->delivery_boy_ids,
                    'on_ride_count' => $n->on_ride_count,
                    'on_ride_driver_ids' => $n->on_ride_driver_ids,
                    'status' => $n->status,
                    'accepted_by' => $n->accepted_by,
                    'accepted_at' => $n->accepted_at,
                    'notified_at' => $n->notified_at,
                    'error_message' => $n->error_message
                ];
            })->toArray()
        ];
    }

    /**
     * Mark notification as accepted by a delivery boy
     *
     * @param int $orderId The order ID
     * @param int $deliveryBoyId The delivery boy who accepted
     * @return bool
     */
    public static function markNotificationAccepted(int $orderId, int $deliveryBoyId): bool
    {
        $notification = OrderDeliveryBoyNotification::where('order_id', $orderId)
            ->where('status', 'sent')
            ->orderBy('attempt_number', 'desc')
            ->first();

        if ($notification) {
            $notification->markAsAccepted($deliveryBoyId);
            return true;
        }

        return false;
    }

    /**
     * Store order in pending_delivery_assignments table
     *
     * @param int $orderId The order ID
     * @param array $sellerLocations The seller locations for this order
     * @return array Result with success status
     */
    public static function storePendingDeliveryAssignment(int $orderId, array $sellerLocations): array
    {
        try {
            $pending = PendingDeliveryAssignment::updateOrCreate(
                ['order_id' => $orderId],
                [
                    'seller_locations' => $sellerLocations,
                    'attempts' => DB::raw('attempts + 1'),
                    'last_attempted_at' => now(),
                    'status' => PendingDeliveryAssignment::STATUS_PENDING
                ]
            );

            $pending->refresh();

            Log::info('Order stored in pending delivery assignments', [
                'order_id' => $orderId,
                'attempts' => $pending->attempts,
                'seller_locations_count' => count($sellerLocations)
            ]);

            return [
                'success' => true,
                'message' => 'Order stored in pending assignments',
                'pending_id' => $pending->id,
                'attempts' => $pending->attempts
            ];
        } catch (\Exception $e) {
            Log::error('Failed to store pending delivery assignment', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to store in pending: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Remove order from pending_delivery_assignments table (mark as assigned)
     *
     * @param int $orderId The order ID
     * @return bool
     */
    public static function removePendingDeliveryAssignment(int $orderId): bool
    {
        try {
            $pending = PendingDeliveryAssignment::where('order_id', $orderId)->first();

            if ($pending) {
                $pending->markAsAssigned();
                Log::info('Pending delivery assignment marked as assigned', [
                    'order_id' => $orderId
                ]);
            }

            return true;
        } catch (\Exception $e) {
            Log::error('Failed to update pending delivery assignment', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Retry pending delivery assignments
     * Called by scheduler or manually to retry orders without delivery boys
     *
     * @param int $maxAttempts Maximum attempts before marking as failed
     * @return array Results of retry attempts
     */
    public static function retryPendingDeliveryAssignments(int $maxAttempts = 10): array
    {
        $results = [];

        $pendingAssignments = PendingDeliveryAssignment::pending()
            ->where('attempts', '<', $maxAttempts)
            ->orderBy('created_at', 'asc')
            ->get();

        foreach ($pendingAssignments as $pending) {
            $sellerLocations = $pending->seller_locations ?? [];

            // Get available delivery boys
            $result = self::getAvailableDeliveryBoysNearOrderSellers($pending->order_id);

            if (!empty($result['not_on_ride'])) {
                // Found delivery boys, sync to Firestore
                $firestoreResult = self::syncToFirestore($pending->order_id, $result['not_on_ride']);

                if ($firestoreResult['success']) {
                    $pending->markAsAssigned();
                    $results[] = [
                        'order_id' => $pending->order_id,
                        'status' => 'assigned',
                        'delivery_boys' => count($result['not_on_ride'])
                    ];
                } else {
                    $pending->incrementAttempt();
                    $pending->last_error = $firestoreResult['message'];
                    $pending->save();
                    $results[] = [
                        'order_id' => $pending->order_id,
                        'status' => 'firestore_failed',
                        'error' => $firestoreResult['message']
                    ];
                }
            } else {
                // Still no delivery boys
                $pending->incrementAttempt();

                // Mark as failed if max attempts reached
                if ($pending->attempts >= $maxAttempts) {
                    $pending->markAsFailed('Max retry attempts reached');
                    $results[] = [
                        'order_id' => $pending->order_id,
                        'status' => 'failed',
                        'reason' => 'Max attempts reached'
                    ];
                } else {
                    $results[] = [
                        'order_id' => $pending->order_id,
                        'status' => 'pending',
                        'attempts' => $pending->attempts
                    ];
                }
            }
        }

        Log::info('Pending delivery assignments retry completed', [
            'processed' => count($results),
            'results' => $results
        ]);

        return $results;
    }

    /**
     * Delete order document from Firestore
     * Uses Firestore REST API (no gRPC required)
     *
     * @param int $orderId The order ID
     * @return array Result with success status
     */
    public static function deleteFromFirestore(int $orderId): array
    {
        try {
            // Get access token
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Make REST API call to delete document
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string) $orderId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->delete($url);

            // 404 is also considered success (document didn't exist)
            if (!$response->successful() && $response->status() !== 404) {
                Log::error('Firestore delete failed', [
                    'order_id' => $orderId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Firestore delete failed: ' . $response->body()
                ];
            }

            Log::info('Firestore document deleted', [
                'order_id' => $orderId,
                'collection' => self::COLLECTION_NAME
            ]);

            return [
                'success' => true,
                'message' => 'Document deleted from Firestore'
            ];

        } catch (\Exception $e) {
            Log::error('Firestore delete failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Firestore delete failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Filter drivers into on_ride and not_on_ride categories
     * A driver is NOT on ride if all their orders have active_status 6, 7, or 8 (delivered/cancelled/returned)
     * A driver IS on ride if they have any order with active_status NOT in 6, 7, 8
     *
     * @param array $drivers Array of drivers with id and name
     * @return array Array with on_ride and not_on_ride categories
     */
    private static function filterDriversByRideStatus(array $drivers): array
    {
        $onRide = [];
        $notOnRide = [];

        // Completed order statuses (delivered = 6, cancelled = 7, returned = 8)
        $completedStatuses = [6, 7, 8];

        foreach ($drivers as $driver) {
            // Check if driver has any active (non-completed) orders
            $hasActiveOrder = DB::table('orders')
                ->where('delivery_boy_id', $driver['id'])
                ->whereNotIn('active_status', $completedStatuses)
                ->exists();

            if ($hasActiveOrder) {
                $onRide[] = $driver;
            } else {
                $notOnRide[] = $driver;
            }
        }

        return [
            'on_ride' => $onRide,
            'not_on_ride' => $notOnRide
        ];
    }

    /**
     * Calculate distance between two coordinates
     * Uses Google Maps API as primary, falls back to Haversine if API fails
     *
     * @param float $lat1 Latitude of point 1
     * @param float $lng1 Longitude of point 1
     * @param float $lat2 Latitude of point 2
     * @param float $lng2 Longitude of point 2
     * @return float|null Distance in kilometers, null if both methods fail
     */
    public static function calculateDistance(float $lat1, float $lng1, float $lat2, float $lng2): ?float
    {
        // Try Google Maps API first
        $distance = self::calculateDistanceWithGoogleMaps($lat1, $lng1, $lat2, $lng2);

        if ($distance !== null) {
            return $distance;
        }

        // Fallback to Haversine formula if Google Maps API fails
        Log::info('Google Maps API failed, using Haversine formula as fallback');
        return self::calculateHaversineDistance($lat1, $lng1, $lat2, $lng2);
    }

    /**
     * Calculate distance using Google Maps Distance Matrix API
     *
     * @param float $lat1 Latitude of origin
     * @param float $lng1 Longitude of origin
     * @param float $lat2 Latitude of destination
     * @param float $lng2 Longitude of destination
     * @return float|null Distance in kilometers, null if API fails
     */
    private static function calculateDistanceWithGoogleMaps(float $lat1, float $lng1, float $lat2, float $lng2): ?float
    {
        try {
            // Get API key from settings table (id 47)
            $apiKey = DB::table('settings')->where('id', 47)->value('value');

            if (empty($apiKey)) {
                Log::warning('Google Maps API key not found in settings table (id 47)');
                return null;
            }

            $origin = "{$lat1},{$lng1}";
            $destination = "{$lat2},{$lng2}";

            $url = "https://maps.googleapis.com/maps/api/distancematrix/json";

            $response = Http::withOptions(['verify' => false])->get($url, [
                'origins' => $origin,
                'destinations' => $destination,
                'key' => $apiKey,
                'units' => 'metric'
            ]);

            if (!$response->successful()) {
                Log::error('Google Maps API request failed', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return null;
            }

            $data = $response->json();

            if ($data['status'] !== 'OK') {
                Log::error('Google Maps API returned error status', [
                    'status' => $data['status'],
                    'error_message' => $data['error_message'] ?? null
                ]);
                return null;
            }

            $element = $data['rows'][0]['elements'][0] ?? null;

            if (!$element || $element['status'] !== 'OK') {
                Log::warning('Google Maps API element status not OK', [
                    'element_status' => $element['status'] ?? 'unknown'
                ]);
                return null;
            }

            // Distance is returned in meters, convert to kilometers
            $distanceInMeters = $element['distance']['value'];
            return $distanceInMeters / 1000;

        } catch (\Exception $e) {
            Log::error('Google Maps API exception', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return null;
        }
    }

    /**
     * Calculate distance between two coordinates using Haversine formula
     * Used as fallback when Google Maps API fails
     *
     * @param float $lat1 Latitude of point 1
     * @param float $lng1 Longitude of point 1
     * @param float $lat2 Latitude of point 2
     * @param float $lng2 Longitude of point 2
     * @return float Distance in kilometers
     */
    private static function calculateHaversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $latFrom = deg2rad($lat1);
        $lngFrom = deg2rad($lng1);
        $latTo = deg2rad($lat2);
        $lngTo = deg2rad($lng2);

        $latDelta = $latTo - $latFrom;
        $lngDelta = $lngTo - $lngFrom;

        $a = sin($latDelta / 2) * sin($latDelta / 2) +
             cos($latFrom) * cos($latTo) *
             sin($lngDelta / 2) * sin($lngDelta / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return self::EARTH_RADIUS_KM * $c;
    }

    /**
     * Update delivery boy's current order data in Firestore
     * Called when admin assigns a delivery boy to an order
     *
     * Structure in Firestore:
     * delivery_boys/{delivery_boy_id}/current_order
     *
     * @param int $orderId The order ID
     * @param int $deliveryBoyId The delivery boy ID
     * @return array Result with success status and message
     */
    public static function updateDeliveryBoyCurrentOrder(
        int $orderId,
        int $deliveryBoyId,
        ?float $handoffLat = null,
        ?float $handoffLon = null,
        ?string $handoffDriverName = null,
        ?array $completedSellerNames = [],
        ?array $completedSellerIds = [],
        // Appended (not inserted) so existing positional callers keep working.
        ?string $handoffDriverPhone = null,
        ?int $handoffDriverId = null
    ): array
    {
        try {
            // Get access token
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Get delivery boy details
            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            if (!$deliveryBoy) {
                return [
                    'success' => false,
                    'message' => 'Delivery boy not found'
                ];
            }

            // Get driver's latest location
            $driverLocation = self::getDriverLatestLocation($deliveryBoyId);
            $driverLat = $driverLocation['latitude'] ?? 0;
            $driverLng = $driverLocation['longitude'] ?? 0;

            // Get order details
            $order = DB::table('orders')
                ->join('users', 'users.id', '=', 'orders.user_id')
                ->leftJoin('user_addresses', 'user_addresses.id', '=', 'orders.address_id')
                ->where('orders.id', $orderId)
                ->select(
                    'orders.id',
                    'orders.address',
                    'orders.latitude',
                    'orders.longitude',
                    'orders.order_type',
                    'orders.cart_metadata',
                    // Receiver name from the delivery address, falling back to the account name.
                    DB::raw("COALESCE(NULLIF(TRIM(user_addresses.name), ''), NULLIF(TRIM(users.name), ''), 'Customer') as customer_name"),
                    'users.mobile as customer_mobile'
                )
                ->first();

            if (!$order) {
                return [
                    'success' => false,
                    'message' => 'Order not found'
                ];
            }

            // Parse cart metadata
            $cartMeta = json_decode($order->cart_metadata, true);
            $deliveryTip = $cartMeta['cart_info']['delivery_tip'] ?? 0;
            $totalOrderValue = $cartMeta['billing_summary']['to_be_paid'] ?? 0;
            $deliveryCharge = $cartMeta['billing_summary']['delivery_charge'] ?? 0;

            // Check if this is emergency driver change
            $isEmergencyChange = ($handoffLat !== null && $handoffLon !== null);

            // Get seller locations
            // For emergency change: only get sellers that haven't been picked up yet
            $sellers = self::getSellerLocationsForFirestore($orderId, $isEmergencyChange);

            // If handoff location provided (emergency driver change), add as first stop
            $orderedSellers = [];
            $totalDistance = 0;

            // The old driver only carries something if they actually marked a
            // pickup done. If they never picked anything up there is nothing to
            // hand over, so no handoff stop - the new driver goes straight to
            // the restaurant(s). Counted on the tracking table directly (not on
            // $completedSellerNames) so a picked Zenfoo store stop, which has a
            // null seller_id and drops out of the sellers join, still counts.
            $pickedStopsCount = $isEmergencyChange
                ? DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->where('is_driver_picked', 1)
                    ->count()
                : 0;

            $hasHandoffStop = $isEmergencyChange && $pickedStopsCount > 0;

            if ($isEmergencyChange && !$hasHandoffStop) {
                Log::info('Emergency driver change: no handoff stop added, old driver had picked nothing', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoyId,
                    'handoff_driver' => $handoffDriverName
                ]);
            }

            if ($hasHandoffStop) {
                // Calculate distance from new driver to old driver (handoff point)
                $handoffDistance = self::calculateDistance(
                    $driverLat,
                    $driverLng,
                    $handoffLat,
                    $handoffLon
                );

                // Build handoff point description with completed seller info
                $handoffDescription = 'Handoff Point - ' . $handoffDriverName;
                if (!empty($completedSellerNames)) {
                    $handoffDescription .= ' (Has items from: ' . implode(', ', $completedSellerNames) . ')';
                }

                // Add old driver handoff location as FIRST stop.
                // Keys and types must match a normal stop (see
                // getSellerLocationsForFirestore) - the driver app parses every
                // stop with the same model, so a stray String coordinate or a
                // missing store_name breaks the whole order.
                $orderedSellers[] = [
                    'seller_id' => 0, // Special ID for handoff point
                    'store_id' => null,
                    'is_zenfoo_store' => false,
                    'store_name' => $handoffDescription,
                    'seller_name' => $handoffDescription, // kept for older app builds
                    'seller_address' => 'Collect the picked-up items from ' . $handoffDriverName,
                    // Previous driver's number - the driver app's Call button on
                    // this stop dials it (there is no seller record behind it).
                    'seller_phone_number' => $handoffDriverPhone,
                    'handoff_driver_id' => $handoffDriverId,
                    'latitude' => (float)$handoffLat,
                    'longitude' => (float)$handoffLon,
                    'distance_from_previous_km' => round($handoffDistance ?? 0, 2),
                    'is_handoff_point' => true,
                    'items_from_completed_sellers' => $completedSellerIds ?? []
                ];

                $totalDistance += $handoffDistance ?? 0;

                Log::info('Emergency driver change: Handoff point added as first stop', [
                    'order_id' => $orderId,
                    'handoff_driver' => $handoffDriverName,
                    'distance_to_handoff_km' => round($handoffDistance ?? 0, 2),
                    'completed_sellers' => $completedSellerNames ?? [],
                    'remaining_sellers_count' => count($sellers)
                ]);

                // Start route calculation from handoff point
                $currentLat = $handoffLat;
                $currentLng = $handoffLon;
            } else {
                // Normal assignment: Start from driver's current location
                $currentLat = $driverLat;
                $currentLng = $driverLng;
            }

            // Calculate route with nearest-neighbor algorithm
            $unvisited = $sellers;

            while (!empty($unvisited)) {
                // Zenfoo store(s) are always visited first. While any Zenfoo pickup
                // (with valid coordinates) is still unvisited, only Zenfoo stores are
                // eligible for the next stop; within that group the nearest one is
                // chosen. Once all Zenfoo stops are done, the rest fall back to
                // nearest-neighbor ordering. (A handoff point, if any, was already
                // added as the first stop before this loop.)
                $zenfooPending = false;
                foreach ($unvisited as $seller) {
                    if (!empty($seller['is_zenfoo_store']) && $seller['latitude'] && $seller['longitude']) {
                        $zenfooPending = true;
                        break;
                    }
                }

                $nearestIndex = null;
                $nearestDistance = null;

                foreach ($unvisited as $index => $seller) {
                    if (!$seller['latitude'] || !$seller['longitude']) {
                        continue;
                    }

                    // Skip non-Zenfoo sellers while a Zenfoo store is pending.
                    if ($zenfooPending && empty($seller['is_zenfoo_store'])) {
                        continue;
                    }

                    $distance = self::calculateDistance(
                        $currentLat,
                        $currentLng,
                        (float)$seller['latitude'],
                        (float)$seller['longitude']
                    );

                    if ($nearestDistance === null || $distance < $nearestDistance) {
                        $nearestDistance = $distance;
                        $nearestIndex = $index;
                    }
                }

                if ($nearestIndex === null) {
                    break;
                }

                $nearestSeller = $unvisited[$nearestIndex];
                $nearestSeller['distance_from_previous_km'] = round($nearestDistance ?? 0, 2);

                $totalDistance += $nearestDistance ?? 0;
                $currentLat = (float)$nearestSeller['latitude'];
                $currentLng = (float)$nearestSeller['longitude'];

                $orderedSellers[] = $nearestSeller;
                unset($unvisited[$nearestIndex]);
            }

            // Calculate last leg distance (to customer)
            $lastLegDistance = self::calculateDistance(
                $currentLat,
                $currentLng,
                (float)$order->latitude,
                (float)$order->longitude
            );
            $totalDistance += $lastLegDistance ?? 0;

            // Get multi_order_bonus from settings
            $multiOrderBonusValue = floatval(DB::table('settings')->where('variable', 'multi_order_bonus')->value('value') ?? 0);
            // Don't count handoff point as a seller for multi-order bonus
            $actualSellerCount = $hasHandoffStop ? count($orderedSellers) - 1 : count($orderedSellers);
            $multiOrderBonus = $actualSellerCount > 1 ? $multiOrderBonusValue : 0;

            // Build step statuses array
            // Steps: [handoff (if exists)] + [sellers] + [customer delivery]
            // All steps start as "inProgress" when admin assigns
            $stepStatuses = [];
            $stepCount = count($orderedSellers) + 1; // all stops (including handoff if exists) + customer delivery
            for ($i = 0; $i < $stepCount; $i++) {
                $stepStatuses[] = 'inProgress';
            }

            // Build Firestore document data
            $currentTime = now();
            $firestoreData = [
                'fields' => [
                    'current_order' => self::toFirestoreValue([
                        'accepted_at' => $currentTime->toIso8601String(),
                        'delivery_progress' => [
                            'current_step' => 0,
                            'step_statuses' => $stepStatuses,
                            'updated_at' => $currentTime->toIso8601String()
                        ],
                        'driver_location' => [
                            'latitude' => $driverLat,
                            'longitude' => $driverLng,
                            'updated_at' => $currentTime->toIso8601String()
                        ],
                        'order_details' => [
                            'customer' => [
                                'address' => $order->address,
                                'latitude' => (string)$order->latitude,
                                'longitude' => (string)$order->longitude,
                                'mobile' => $order->customer_mobile,
                                'name' => $order->customer_name
                            ],
                            'delivery_charge' => (float)$deliveryCharge,
                            'delivery_tip' => (float)$deliveryTip,
                            'driver' => [
                                'latitude' => $driverLat,
                                'longitude' => $driverLng
                            ],
                            'multi_order_bonus' => $multiOrderBonus,
                            'order_id' => (int)$orderId,
                            'order_type' => $order->order_type,
                            'sellers_visit_order' => $orderedSellers,
                            'total_order_value' => (float)$totalOrderValue,
                            'total_route_distance_km' => round($totalDistance, 2)
                        ],
                        'order_id' => (int)$orderId,
                        'last_updated' => $currentTime->toIso8601String()
                    ]),
                    'updated_at' => self::toFirestoreValue($currentTime->toIso8601String())
                ]
            ];

            // Update Firestore document
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string)$deliveryBoyId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $firestoreData);

            if (!$response->successful()) {
                Log::error('Firestore update current order failed', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'order_id' => $orderId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Firestore update failed: ' . $response->body()
                ];
            }

            Log::info('Firestore current_order updated for delivery boy', [
                'delivery_boy_id' => $deliveryBoyId,
                'order_id' => $orderId,
                'has_handoff_stop' => $hasHandoffStop,
                'handoff_driver' => $hasHandoffStop ? $handoffDriverName : null,
                'total_stops' => count($orderedSellers),
                'actual_sellers_count' => $actualSellerCount,
                'total_distance_km' => round($totalDistance, 2)
            ]);

            return [
                'success' => true,
                'message' => 'Delivery boy current order updated in Firestore',
                'data' => [
                    'delivery_boy_id' => $deliveryBoyId,
                    'order_id' => $orderId,
                    'sellers_count' => count($orderedSellers),
                    'total_distance_km' => round($totalDistance, 2)
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Firestore update current order failed', [
                'delivery_boy_id' => $deliveryBoyId,
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Firestore update failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get driver's latest location from location history
     *
     * @param int $deliveryBoyId The delivery boy ID
     * @return array Array with latitude and longitude
     */
    private static function getDriverLatestLocation(int $deliveryBoyId): array
    {
        // Get active session for this delivery boy
        $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoyId)
            ->whereNull('logout_at')
            ->first();

        if (!$activeSession) {
            // Fallback to delivery_boys table location
            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            return [
                'latitude' => $deliveryBoy->latitude ?? 0,
                'longitude' => $deliveryBoy->longitude ?? 0
            ];
        }

        // Get latest location from location history
        $latestLocation = DB::table('delivery_boy_location_history')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->where('session_id', $activeSession->id)
            ->orderBy('tracked_at', 'desc')
            ->first();

        if ($latestLocation) {
            return [
                'latitude' => (float)$latestLocation->latitude,
                'longitude' => (float)$latestLocation->longitude
            ];
        }

        // Fallback to delivery_boys table location
        $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
        return [
            'latitude' => $deliveryBoy->latitude ?? 0,
            'longitude' => $deliveryBoy->longitude ?? 0
        ];
    }

    /**
     * Get seller locations for Firestore update (includes Zenfoo store if applicable)
     *
     * @param int $orderId The order ID
     * @return array Array of seller locations
     */
    private static function getSellerLocationsForFirestore(int $orderId, bool $onlyUnpicked = false): array
    {
        // Get seller IDs from order_seller_status_tracking table
        $query = DB::table('order_seller_status_tracking')
            ->where('order_id', $orderId);

        // For emergency driver change, only get sellers that haven't been picked up yet
        if ($onlyUnpicked) {
            $query->where('is_driver_picked', 0);
            Log::info('getSellerLocationsForFirestore: Filtering only unpicked sellers', [
                'order_id' => $orderId
            ]);
        }

        $sellerIds = $query->pluck('seller_id')->toArray();

        // Filter out null values (Zenfoo store entries have null seller_id)
        $sellerIds = array_filter($sellerIds, function ($id) {
            return !is_null($id);
        });

        $sellerLocations = [];

        if (!empty($sellerIds)) {
            // Get seller lat_long from sellers table
            $sellers = DB::table('sellers')
                ->whereIn('id', $sellerIds)
                ->select('id', 'store_id', 'lat_long', 'store_name', 'store_location', 'mobile')
                ->get();

            foreach ($sellers as $seller) {
                $latitude = null;
                $longitude = null;

                // Parse lat_long string (format: "17.438925073025825,78.39837715029716")
                if (!empty($seller->lat_long)) {
                    $coords = explode(',', $seller->lat_long);
                    if (count($coords) === 2) {
                        $latitude = (float) trim($coords[0]);
                        $longitude = (float) trim($coords[1]);
                    }
                }

                $sellerLocations[] = [
                    'seller_id' => $seller->id,
                    'store_id' => $seller->store_id ? (int) $seller->store_id : null,
                    'is_zenfoo_store' => false,
                    'store_name' => $seller->store_name,
                    'seller_address' => $seller->store_location,
                    'seller_phone_number' => $seller->mobile,
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                ];
            }
        }

        // Check if order has products with store_id = 12 (Zenfoo store)
        $hasZenfooProducts = self::orderHasZenfooStoreProducts($orderId);

        if ($hasZenfooProducts) {
            // On an emergency driver change the Zenfoo stop needs the same
            // already-picked filter as the sellers above. It cannot use that
            // filter directly: Zenfoo tracking rows carry a null seller_id and
            // are keyed by store_id 12/13 instead - the same identification the
            // pickup API uses when it marks them picked.
            $zenfooAlreadyPicked = false;

            if ($onlyUnpicked) {
                $zenfooRows = DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->whereIn('store_id', [12, 13]);

                $zenfooTotal = (clone $zenfooRows)->count();
                $zenfooPending = (clone $zenfooRows)->where('is_driver_picked', 0)->count();

                // Only suppress when rows exist and none is still pending. An
                // order with no Zenfoo tracking row keeps the old behaviour, so
                // a missing row can never silently drop a real pickup.
                $zenfooAlreadyPicked = $zenfooTotal > 0 && $zenfooPending === 0;
            }

            if ($zenfooAlreadyPicked) {
                Log::info('getSellerLocationsForFirestore: Skipping Zenfoo store, already picked by previous driver', [
                    'order_id' => $orderId
                ]);
            } else {
                // Get Zenfoo store location based on order's city
                $zenfooStoreLocation = self::getZenfooStoreLocationForOrder($orderId);

                if ($zenfooStoreLocation) {
                    $sellerLocations[] = $zenfooStoreLocation;
                }
            }
        }

        return $sellerLocations;
    }

    /**
     * Check if order has products from Zenfoo store (store_id = 12)
     *
     * @param int $orderId
     * @return bool
     */
    private static function orderHasZenfooStoreProducts(int $orderId): bool
    {
        $zenfooStoreId = 12;

        // Check in order_items
        $hasInOrderItems = DB::table('order_items')
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->where('order_items.order_id', $orderId)
            ->where('products.store_id', $zenfooStoreId)
            ->exists();

        if ($hasInOrderItems) {
            return true;
        }

        // Check in order_combo_items
        $comboItems = DB::table('order_combo_items')
            ->where('order_id', $orderId)
            ->get();

        foreach ($comboItems as $combo) {
            if (!empty($combo->products)) {
                $products = json_decode($combo->products, true);
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }

                if (is_array($products)) {
                    $comboProductIds = array_column($products, 'product_id');

                    $hasZenfooComboProducts = DB::table('products')
                        ->whereIn('id', $comboProductIds)
                        ->where('store_id', $zenfooStoreId)
                        ->exists();

                    if ($hasZenfooComboProducts) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * Get Zenfoo store location based on order's city
     *
     * @param int $orderId
     * @return array|null
     */
    private static function getZenfooStoreLocationForOrder(int $orderId): ?array
    {
        // Get order with city_id
        $order = DB::table('orders')
            ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->where('orders.id', $orderId)
            ->select('orders.*', 'user_addresses.city_id')
            ->first();

        if (!$order) {
            return null;
        }

        // Get Zenfoo store details from store_locations table based on order's city
        $storeLocation = DB::table('store_locations')
            ->where('city_id', $order->city_id)
            ->where('status', 1)
            ->first();

        if (!$storeLocation) {
            return null;
        }

        $storeLatitude = $storeLocation->latitude ? (float) $storeLocation->latitude : null;
        $storeLongitude = $storeLocation->longitude ? (float) $storeLocation->longitude : null;

        return [
            'seller_id' => null,
            'store_id' => 12,
            'is_zenfoo_store' => true,
            'store_name' => $storeLocation->name,
            'seller_address' => $storeLocation->address,
            'seller_phone_number' => $storeLocation->phone ?? null,
            'latitude' => $storeLatitude,
            'longitude' => $storeLongitude,
        ];
    }

    /**
     * Remove current order from delivery boy in Firestore
     * Used for emergency driver change - clears the current_order field
     *
     * @param int $deliveryBoyId The delivery boy ID
     * @param int $orderId The order ID (for logging purposes)
     * @return array Result with success status and message
     */
    /**
     * Write the reason an order left a driver onto their Firestore document.
     *
     * The driver app listens to `delivery_boys/{id}.last_order_event` and shows
     * a dialog before leaving the delivery screen, so the order does not simply
     * disappear from under the driver. Uses an updateMask on the single field so
     * current_order and everything else on the document is left untouched; the
     * app deletes the field once it has shown the message.
     *
     * Never fatal: a failure here only costs the in-app dialog, the FCM push is
     * sent separately.
     *
     * @param int   $deliveryBoyId Driver to notify
     * @param array $event         type / order_id / title / message / created_at
     * @return array Result with success status and message
     */
    public static function setLastOrderEvent(int $deliveryBoyId, array $event): array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                Log::error('Firestore last_order_event skipped: no access token', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'event' => $event
                ]);

                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string)$deliveryBoyId)
                . '?updateMask.fieldPaths=last_order_event';

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, [
                    'fields' => [
                        'last_order_event' => self::toFirestoreValue($event)
                    ]
                ]);

            if (!$response->successful()) {
                Log::error('Firestore last_order_event write failed', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'event' => $event,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Firestore last_order_event write failed: ' . $response->body()
                ];
            }

            Log::info('Firestore last_order_event written', [
                'delivery_boy_id' => $deliveryBoyId,
                'type' => $event['type'] ?? null,
                'order_id' => $event['order_id'] ?? null
            ]);

            return [
                'success' => true,
                'message' => 'Last order event written'
            ];

        } catch (\Exception $e) {
            Log::error('Firestore last_order_event write failed', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Firestore last_order_event write failed: ' . $e->getMessage()
            ];
        }
    }

    public static function removeCurrentOrderFromDeliveryBoy(int $deliveryBoyId, int $orderId): array
    {
        try {
            // Get access token
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                return [
                    'success' => false,
                    'message' => 'Failed to get Firestore access token'
                ];
            }

            // Build Firestore document data with null current_order
            $currentTime = now();
            $firestoreData = [
                'fields' => [
                    'current_order' => ['nullValue' => null],
                    'updated_at' => self::toFirestoreValue($currentTime->toIso8601String())
                ]
            ];

            // Update Firestore document
            $url = self::getDocumentPath(self::COLLECTION_NAME, (string)$deliveryBoyId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->patch($url, $firestoreData);

            if (!$response->successful()) {
                Log::error('Firestore remove current order failed', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'order_id' => $orderId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);

                return [
                    'success' => false,
                    'message' => 'Firestore remove order failed: ' . $response->body()
                ];
            }

            Log::info('Firestore current_order removed from delivery boy', [
                'delivery_boy_id' => $deliveryBoyId,
                'order_id' => $orderId
            ]);

            return [
                'success' => true,
                'message' => 'Current order removed from delivery boy in Firestore'
            ];

        } catch (\Exception $e) {
            Log::error('Firestore remove current order failed', [
                'delivery_boy_id' => $deliveryBoyId,
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Firestore remove order failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Emergency driver change - reassign order from old driver to new driver
     * Handles both MySQL and Firestore updates atomically
     *
     * @param int $orderId The order ID
     * @param int $oldDeliveryBoyId The current delivery boy ID
     * @param int $newDeliveryBoyId The new delivery boy ID
     * @return array Result with success status and message
     */
    public static function emergencyChangeDriver(int $orderId, int $oldDeliveryBoyId, int $newDeliveryBoyId): array
    {
        try {
            DB::beginTransaction();

            // 1. Update MySQL: append old driver to previous_drivers_allocated and update delivery_boy_id
            $order = DB::table('orders')->where('id', $orderId)->first();

            if (!$order) {
                DB::rollBack();
                return [
                    'success' => false,
                    'message' => 'Order not found'
                ];
            }

            // Get existing previous drivers array
            $previousDrivers = $order->previous_drivers_allocated
                ? json_decode($order->previous_drivers_allocated, true)
                : [];

            // Append old driver ID
            $previousDrivers[] = $oldDeliveryBoyId;

            // Get old driver's location BEFORE removing order (for handoff point)
            $oldDriverLocation = self::getDriverLatestLocation($oldDeliveryBoyId);
            $oldDriverLat = $oldDriverLocation['latitude'] ?? null;
            $oldDriverLon = $oldDriverLocation['longitude'] ?? null;

            // Get old driver details for handoff info
            $oldDriver = DeliveryBoy::find($oldDeliveryBoyId);

            // Get information about already picked sellers (for handoff point description)
            $completedSellers = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('is_driver_picked', 1)
                ->join('sellers', 'order_seller_status_tracking.seller_id', '=', 'sellers.id')
                ->select('sellers.id', 'sellers.store_name')
                ->get();

            $completedSellerNames = $completedSellers->pluck('store_name')->toArray();
            $completedSellerIds = $completedSellers->pluck('id')->toArray();

            $remainingSellers = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('is_driver_picked', 0)
                ->count();

            // Get old driver's Firestore document to calculate billable distance
            $oldDriverFirestore = self::getDeliveryBoyDocument($oldDeliveryBoyId);
            $oldDriverBillableDistance = 0;

            if ($oldDriverFirestore && isset($oldDriverFirestore['current_order'])) {
                $sellersVisited = $oldDriverFirestore['current_order']['order_details']['sellers_visit_order'] ?? [];

                Log::info('Emergency driver change: Old driver route retrieved', [
                    'old_driver_id' => $oldDeliveryBoyId,
                    'total_stops' => count($sellersVisited)
                ]);

                // Their visit order still holds the full plan, so count only the
                // legs into stops they actually picked up - the rest is about to
                // become the new driver's work. No final leg: they are not the
                // one delivering to the customer.
                $oldDriverBillableDistance = self::calculateBillableDistance($sellersVisited, [
                    'only_picked_for_order' => $orderId
                ]);

                Log::info('Emergency driver change: Old driver billable distance calculated', [
                    'old_driver_id' => $oldDeliveryBoyId,
                    'billable_distance_km' => $oldDriverBillableDistance,
                    'total_stops' => count($sellersVisited)
                ]);
            } else {
                Log::warning('Emergency driver change: Could not retrieve old driver Firestore data', [
                    'old_driver_id' => $oldDeliveryBoyId,
                    'order_id' => $orderId
                ]);
            }

            // Prepare driver distance split data
            $driverDistanceSplit = [
                'total_billable_distance_km' => null, // Will be calculated at completion
                'drivers' => [
                    $oldDeliveryBoyId => [
                        'name' => $oldDriver->name ?? 'Unknown',
                        'billable_distance_km' => $oldDriverBillableDistance,
                        'percentage' => null, // Will be calculated at completion
                        'earnings' => null, // Will be calculated at completion
                        'completed_sellers' => $completedSellerNames,
                        'handoff_location' => [
                            'latitude' => $oldDriverLat,
                            'longitude' => $oldDriverLon
                        ]
                    ]
                ]
            ];

            Log::info('Emergency driver change: Driver distance split prepared', [
                'order_id' => $orderId,
                'old_driver_id' => $oldDeliveryBoyId,
                'old_driver_name' => $oldDriver->name ?? 'Unknown',
                'old_driver_billable_km' => $oldDriverBillableDistance,
                'latitude' => $oldDriverLat,
                'longitude' => $oldDriverLon,
                'completed_sellers' => count($completedSellerIds),
                'completed_seller_names' => implode(', ', $completedSellerNames),
                'remaining_sellers' => $remainingSellers
            ]);

            // Update order in MySQL
            DB::table('orders')
                ->where('id', $orderId)
                ->update([
                    'delivery_boy_id' => $newDeliveryBoyId,
                    'previous_drivers_allocated' => json_encode($previousDrivers),
                    'driver_distance_split' => json_encode($driverDistanceSplit),
                    'updated_at' => now()
                ]);

            // 2. Tell the old driver's app WHY the order is about to vanish.
            // Written before current_order is cleared so the reason is already on
            // the document when the app reacts to the order disappearing -
            // otherwise the app cannot tell a reassignment from a completion or
            // a cancellation and has to stay silent.
            self::setLastOrderEvent($oldDeliveryBoyId, [
                'type' => 'reassigned',
                'order_id' => $orderId,
                'title' => 'Order Reassigned',
                'message' => "Order #{$orderId} has been reassigned to another delivery partner by support. "
                    . "You have been paid for the distance you covered. "
                    . "Please take a rest - contact support if you have any questions.",
                'created_at' => now()->toIso8601String(),
            ]);

            // 3. Remove order from old driver's Firestore
            $removeResult = self::removeCurrentOrderFromDeliveryBoy($oldDeliveryBoyId, $orderId);
            if (!$removeResult['success']) {
                DB::rollBack();
                return $removeResult;
            }

            // 4. Assign order to new driver's Firestore with old driver handoff location
            $assignResult = self::updateDeliveryBoyCurrentOrder(
                $orderId,
                $newDeliveryBoyId,
                $oldDriverLat,
                $oldDriverLon,
                $oldDriver->name ?? 'Previous Driver',
                $completedSellerNames,
                $completedSellerIds,
                $oldDriver->mobile ?? null,
                $oldDeliveryBoyId
            );
            if (!$assignResult['success']) {
                DB::rollBack();
                return $assignResult;
            }

            DB::commit();

            Log::info('Emergency driver change completed successfully', [
                'order_id' => $orderId,
                'old_delivery_boy_id' => $oldDeliveryBoyId,
                'new_delivery_boy_id' => $newDeliveryBoyId,
                'previous_drivers' => $previousDrivers
            ]);

            return [
                'success' => true,
                'message' => 'Driver changed successfully',
                'data' => [
                    'order_id' => $orderId,
                    'old_driver_id' => $oldDeliveryBoyId,
                    'new_driver_id' => $newDeliveryBoyId,
                    'previous_drivers' => $previousDrivers
                ]
            ];

        } catch (\Exception $e) {
            DB::rollBack();

            Log::error('Emergency driver change failed', [
                'order_id' => $orderId,
                'old_delivery_boy_id' => $oldDeliveryBoyId,
                'new_delivery_boy_id' => $newDeliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Driver change failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Calculate billable distance from a driver's sellers visit order.
     *
     * Always excludes the two commute legs a driver is not paid for: getting to
     * their first pickup, and (on a reassignment) getting to the handoff point.
     *
     * Two options shape the rest, and between them they decide how the delivery
     * charge is split when an order passes through more than one driver:
     *
     *  - 'delivered_to' => ['latitude' => .., 'longitude' => ..]
     *    Adds the final leg from the last stop to the customer. Pass this for
     *    the driver who COMPLETES the order. That leg is not a member of
     *    sellers_visit_order - it is added straight to total_route_distance_km
     *    when the route is built - so without this the completing driver of a
     *    reassigned order can bill 0 km for the whole run to the door.
     *
     *  - 'only_picked_for_order' => int (order id)
     *    Counts a leg only if the stop it arrives at was actually picked up.
     *    Pass this for a driver being reassigned AWAY, whose visit order still
     *    holds the full plan: without it they are paid for legs the next driver
     *    rides.
     *
     * @param array $sellersVisitOrder
     * @param array $options See above. Empty = legacy behaviour.
     * @return float Billable distance in km
     */
    public static function calculateBillableDistance(array $sellersVisitOrder, array $options = []): float
    {
        $billableDistance = 0;
        $firstSellerFound = false;

        $deliveredTo = $options['delivered_to'] ?? null;
        $onlyPickedForOrder = $options['only_picked_for_order'] ?? null;

        // Stops this driver actually completed. Zenfoo rows have a null
        // seller_id and are keyed by store_id, so both are collected and a stop
        // matches on whichever it carries.
        $pickedSellerIds = [];
        $pickedStoreIds = [];

        if ($onlyPickedForOrder !== null) {
            $pickedRows = DB::table('order_seller_status_tracking')
                ->where('order_id', $onlyPickedForOrder)
                ->where('is_driver_picked', 1)
                ->get(['seller_id', 'store_id']);

            foreach ($pickedRows as $row) {
                if ($row->seller_id !== null) {
                    $pickedSellerIds[] = (int) $row->seller_id;
                }
                if ($row->store_id !== null) {
                    $pickedStoreIds[] = (int) $row->store_id;
                }
            }
        }

        Log::info('calculateBillableDistance: Starting calculation', [
            'total_stops' => count($sellersVisitOrder),
            'counts_final_leg' => $deliveredTo !== null,
            'only_picked_for_order' => $onlyPickedForOrder,
            'picked_seller_ids' => $pickedSellerIds,
            'picked_store_ids' => $pickedStoreIds
        ]);

        $lastStop = null;

        foreach ($sellersVisitOrder as $index => $stop) {
            $isHandoffPoint = $stop['is_handoff_point'] ?? false;
            $distance = floatval($stop['distance_from_previous_km'] ?? 0);
            $stopName = $stop['seller_name'] ?? 'Unknown';

            // Track every stop, skipped or not: the final leg starts wherever
            // the driver physically ended up, which on a reassignment where
            // everything was already picked is the handoff point itself.
            $lastStop = $stop;

            // Skip handoff point distance (new driver getting TO the handoff)
            if ($isHandoffPoint) {
                Log::info('calculateBillableDistance: Skipping handoff point', [
                    'stop_index' => $index,
                    'stop_name' => $stopName,
                    'distance_km' => $distance,
                    'reason' => 'Handoff point - new driver commute'
                ]);
                continue;
            }

            // Skip first actual seller's distance (driver getting TO the job)
            if (!$firstSellerFound) {
                $firstSellerFound = true;
                Log::info('calculateBillableDistance: Skipping first seller', [
                    'stop_index' => $index,
                    'stop_name' => $stopName,
                    'distance_km' => $distance,
                    'reason' => 'Driver commute to first pickup'
                ]);
                continue;
            }

            // Legs into a stop this driver never reached belong to whoever does
            // reach it, not to them.
            if ($onlyPickedForOrder !== null && !self::stopWasPicked($stop, $pickedSellerIds, $pickedStoreIds)) {
                Log::info('calculateBillableDistance: Skipping unpicked stop', [
                    'stop_index' => $index,
                    'stop_name' => $stopName,
                    'distance_km' => $distance,
                    'reason' => 'Driver was reassigned before reaching this stop'
                ]);
                continue;
            }

            // Count this distance
            $billableDistance += $distance;
            Log::info('calculateBillableDistance: Counting distance', [
                'stop_index' => $index,
                'stop_name' => $stopName,
                'distance_km' => $distance,
                'cumulative_billable_km' => $billableDistance
            ]);
        }

        // Final leg: last stop → customer. Only for the completing driver.
        if ($deliveredTo !== null && $lastStop !== null) {
            $finalLeg = self::calculateDistance(
                (float) ($lastStop['latitude'] ?? 0),
                (float) ($lastStop['longitude'] ?? 0),
                (float) ($deliveredTo['latitude'] ?? 0),
                (float) ($deliveredTo['longitude'] ?? 0)
            ) ?? 0;

            $billableDistance += $finalLeg;

            Log::info('calculateBillableDistance: Counting final leg to customer', [
                'from_stop' => $lastStop['seller_name'] ?? 'Unknown',
                'distance_km' => round($finalLeg, 2),
                'cumulative_billable_km' => $billableDistance
            ]);
        } elseif ($deliveredTo !== null) {
            Log::warning('calculateBillableDistance: Final leg not counted, driver had no stops', [
                'reason' => 'sellers_visit_order was empty'
            ]);
        }

        Log::info('calculateBillableDistance: Calculation complete', [
            'total_billable_distance_km' => $billableDistance,
            'total_stops_processed' => count($sellersVisitOrder)
        ]);

        return $billableDistance;
    }

    /**
     * Did this driver complete the given stop?
     *
     * Matched on seller_id, falling back to store_id for Zenfoo stops, which
     * carry no seller_id.
     *
     * @param array $stop            One entry of sellers_visit_order
     * @param array $pickedSellerIds Seller ids marked picked on the order
     * @param array $pickedStoreIds  Store ids marked picked on the order
     * @return bool
     */
    private static function stopWasPicked(array $stop, array $pickedSellerIds, array $pickedStoreIds): bool
    {
        $sellerId = $stop['seller_id'] ?? null;

        if (!empty($sellerId) && in_array((int) $sellerId, $pickedSellerIds, true)) {
            return true;
        }

        $storeId = $stop['store_id'] ?? null;

        if ($storeId !== null && in_array((int) $storeId, $pickedStoreIds, true)) {
            return true;
        }

        return false;
    }

    /**
     * Get delivery boy's Firestore document
     *
     * @param int $deliveryBoyId
     * @return array|null
     */
    public static function getDeliveryBoyDocument(int $deliveryBoyId): ?array
    {
        try {
            $accessToken = self::getAccessToken();
            if (!$accessToken) {
                Log::error('getDeliveryBoyDocument: Failed to get access token', [
                    'delivery_boy_id' => $deliveryBoyId
                ]);
                return null;
            }

            $url = self::getDocumentPath(self::COLLECTION_NAME, (string)$deliveryBoyId);

            $response = Http::withToken($accessToken)
                ->withOptions(['verify' => false])
                ->get($url);

            if (!$response->successful()) {
                Log::error('getDeliveryBoyDocument: Firestore read failed', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return null;
            }

            $firestoreDoc = $response->json();

            // Convert Firestore format to plain array
            $data = self::convertFirestoreToArray($firestoreDoc['fields'] ?? []);

            Log::info('getDeliveryBoyDocument: Document retrieved', [
                'delivery_boy_id' => $deliveryBoyId,
                'has_current_order' => isset($data['current_order'])
            ]);

            return $data;

        } catch (\Exception $e) {
            Log::error('getDeliveryBoyDocument: Exception occurred', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return null;
        }
    }

    /**
     * Convert Firestore document fields to plain array
     *
     * @param array $fields
     * @return array
     */
    private static function convertFirestoreToArray(array $fields): array
    {
        $result = [];

        foreach ($fields as $key => $value) {
            if (isset($value['stringValue'])) {
                $result[$key] = $value['stringValue'];
            } elseif (isset($value['integerValue'])) {
                $result[$key] = (int)$value['integerValue'];
            } elseif (isset($value['doubleValue'])) {
                $result[$key] = (float)$value['doubleValue'];
            } elseif (isset($value['booleanValue'])) {
                $result[$key] = (bool)$value['booleanValue'];
            } elseif (isset($value['mapValue']['fields'])) {
                $result[$key] = self::convertFirestoreToArray($value['mapValue']['fields']);
            } elseif (isset($value['arrayValue']['values'])) {
                $result[$key] = array_map(function($item) {
                    if (isset($item['mapValue']['fields'])) {
                        return self::convertFirestoreToArray($item['mapValue']['fields']);
                    }
                    return $item;
                }, $value['arrayValue']['values']);
            } elseif (isset($value['nullValue'])) {
                $result[$key] = null;
            }
        }

        return $result;
    }
}