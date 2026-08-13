<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Service for calculating estimated time of arrival for orders.
 *
 * Designed for high scalability:
 * - Uses database indexing on order_id
 * - Stateless static methods for horizontal scaling
 * - Minimal database queries
 * - Google Maps API with Haversine fallback
 */
class OrderArrivalTimeService
{
    /**
     * Minutes per kilometer for ETA calculation
     */
    private const MINUTES_PER_KM = 5;

    /**
     * Get order seller status tracking records by order ID
     *
     * @param int $orderId
     * @return array
     */
    public static function getTrackingByOrderId(int $orderId): array
    {
        try {
            Log::info("OrderArrivalTimeService: Fetching tracking data for order_id: {$orderId}");

            $trackingRecords = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->select([
                    'id',
                    'order_id',
                    'seller_id',
                    'store_id',
                    'status',
                    'prep_time',
                    'is_seller_started_preparing',
                    'delayed_time_in_min',
                    'is_driver_picked',
                    'driver_arrived_at_seller',
                    'created_at',
                    'updated_at'
                ])
                ->get()
                ->toArray();

            if (empty($trackingRecords)) {
                Log::info("OrderArrivalTimeService: No tracking records found for order_id: {$orderId}");
                return [
                    'success' => false,
                    'message' => 'No tracking records found for this order',
                    'data' => null
                ];
            }

            Log::info("OrderArrivalTimeService: Found " . count($trackingRecords) . " tracking records for order_id: {$orderId}");

            return [
                'success' => true,
                'message' => 'Tracking records retrieved successfully',
                'data' => [
                    'order_id' => $orderId,
                    'tracking_records' => $trackingRecords,
                    'total_records' => count($trackingRecords)
                ]
            ];

        } catch (\Exception $e) {
            Log::error("OrderArrivalTimeService: Error fetching tracking data for order_id: {$orderId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to retrieve tracking records: ' . $e->getMessage(),
                'data' => null
            ];
        }
    }

    /**
     * Calculate estimated arrival time for an order
     *
     * @param int $orderId
     * @return array
     */
    public static function calculateArrivalTime(int $orderId): array
    {
        try {
            Log::info("OrderArrivalTimeService: Calculating arrival time for order_id: {$orderId}");

            // Step 1: Get tracking records
            $trackingResult = self::getTrackingByOrderId($orderId);

            if (!$trackingResult['success']) {
                return $trackingResult;
            }

            $trackingRecords = $trackingResult['data']['tracking_records'];

            // Step 2: Get order details (user_id, address_id, latitude, longitude)
            $order = DB::table('orders')
                ->where('id', $orderId)
                ->select(['id', 'user_id', 'address_id', 'latitude', 'longitude'])
                ->first();

            if (!$order) {
                Log::error("OrderArrivalTimeService: Order not found for order_id: {$orderId}");
                return [
                    'success' => false,
                    'message' => 'Order not found',
                    'data' => null
                ];
            }

            // Step 3: Get customer location from order or user_addresses
            $customerLocation = self::getCustomerLocation($order);

            if (!$customerLocation) {
                Log::error("OrderArrivalTimeService: Customer location not found for order_id: {$orderId}");
                return [
                    'success' => false,
                    'message' => 'Customer location not found',
                    'data' => null
                ];
            }

            // Step 4: Process each tracking record and get pickup locations
            $pickupLocations = [];
            $hasAdminManaged = false;
            $hasNonAdminManaged = false;

            foreach ($trackingRecords as $record) {
                $locationData = self::getPickupLocationForRecord($record, $customerLocation);

                if ($locationData) {
                    $pickupLocations[] = $locationData;

                    if ($locationData['managed_by_admin']) {
                        $hasAdminManaged = true;
                    } else {
                        $hasNonAdminManaged = true;
                    }
                }
            }

            // Step 5: Calculate total route distance and ETA
            $routeCalculation = self::calculateRouteDistanceAndETA(
                $customerLocation,
                $pickupLocations,
                $hasAdminManaged,
                $hasNonAdminManaged
            );

            Log::info("OrderArrivalTimeService: Calculated arrival time for order_id: {$orderId}", [
                'total_locations' => count($pickupLocations),
                'total_distance_km' => $routeCalculation['total_distance_km'],
                'estimated_time_min' => $routeCalculation['estimated_time_min']
            ]);

            return [
                'success' => true,
                'message' => 'Arrival time data calculated successfully',
                'data' => [
                    'order_id' => $orderId,
                    'customer_location' => $customerLocation,
                    'pickup_locations' => $pickupLocations,
                    'total_pickup_points' => count($pickupLocations),
                    'has_admin_managed' => $hasAdminManaged,
                    'has_non_admin_managed' => $hasNonAdminManaged,
                    'is_mixed_order' => $hasAdminManaged && $hasNonAdminManaged,
                    'route_calculation' => $routeCalculation
                ]
            ];

        } catch (\Exception $e) {
            Log::error("OrderArrivalTimeService: Error calculating arrival time for order_id: {$orderId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to calculate arrival time: ' . $e->getMessage(),
                'data' => null
            ];
        }
    }

    /**
     * Calculate route distance and ETA for all pickup locations
     *
     * For mixed orders: Customer -> Seller(s) -> Zenfoo Store -> Customer
     * For single type: Customer -> Pickup Location(s) -> Customer
     *
     * @param array $customerLocation
     * @param array $pickupLocations
     * @param bool $hasAdminManaged
     * @param bool $hasNonAdminManaged
     * @return array
     */
    private static function calculateRouteDistanceAndETA(
        array $customerLocation,
        array $pickupLocations,
        bool $hasAdminManaged,
        bool $hasNonAdminManaged
    ): array {
        if (empty($pickupLocations)) {
            return [
                'total_distance_km' => 0,
                'estimated_time_min' => 0,
                'route_segments' => [],
                'distance_source' => 'none'
            ];
        }

        $routeSegments = [];
        $totalDistanceKm = 0;
        $distanceSource = 'haversine'; // Will be updated if Google Maps works

        // Separate locations by type
        $sellerLocations = [];
        $zenfooLocations = [];
        $visitedStoreLocationIds = [];

        foreach ($pickupLocations as $location) {
            if ($location['managed_by_admin']) {
                // Deduplicate Zenfoo store locations by store_location_id
                $storeLocationId = $location['store_location_id'] ?? null;
                if ($storeLocationId !== null && in_array($storeLocationId, $visitedStoreLocationIds)) {
                    continue; // Skip duplicate store location
                }
                if ($storeLocationId !== null) {
                    $visitedStoreLocationIds[] = $storeLocationId;
                }
                $zenfooLocations[] = $location;
            } else {
                $sellerLocations[] = $location;
            }
        }

        // Build route: Driver starts from pickup location(s) and ends at Customer
        // Route: Zenfoo Store(s) -> Seller(s) -> Customer (one-way trip)

        // Determine the starting point (first pickup location)
        $allLocations = array_merge($zenfooLocations, $sellerLocations);

        if (empty($allLocations)) {
            return [
                'total_distance_km' => 0,
                'estimated_time_min' => 0,
                'route_segments' => [],
                'distance_source' => 'none'
            ];
        }

        // Start from first Zenfoo location (if exists), otherwise first seller
        $firstLocation = $allLocations[0];
        $currentLat = $firstLocation['latitude'];
        $currentLon = $firstLocation['longitude'];
        $currentName = $firstLocation['store_location_name'] ?? $firstLocation['seller_name'] ?? $firstLocation['store_name'];

        // Visit remaining Zenfoo store locations (if any, starting from index 1)
        for ($i = 1; $i < count($zenfooLocations); $i++) {
            $location = $zenfooLocations[$i];
            $segment = self::calculateSegmentDistance(
                $currentLat,
                $currentLon,
                $location['latitude'],
                $location['longitude'],
                $currentName,
                $location['store_location_name'] ?? $location['store_name']
            );

            $routeSegments[] = $segment;
            $totalDistanceKm += $segment['distance_km'];

            if ($segment['source'] === 'google_maps') {
                $distanceSource = 'google_maps';
            }

            $currentLat = $location['latitude'];
            $currentLon = $location['longitude'];
            $currentName = $location['store_location_name'] ?? $location['store_name'];
        }

        // Then visit seller locations (if any)
        foreach ($sellerLocations as $location) {
            $segment = self::calculateSegmentDistance(
                $currentLat,
                $currentLon,
                $location['latitude'],
                $location['longitude'],
                $currentName,
                $location['seller_name'] ?? $location['store_name']
            );

            $routeSegments[] = $segment;
            $totalDistanceKm += $segment['distance_km'];

            if ($segment['source'] === 'google_maps') {
                $distanceSource = 'google_maps';
            }

            $currentLat = $location['latitude'];
            $currentLon = $location['longitude'];
            $currentName = $location['seller_name'] ?? $location['store_name'];
        }

        // Finally, go to customer (one-way destination)
        $finalSegment = self::calculateSegmentDistance(
            $currentLat,
            $currentLon,
            $customerLocation['latitude'],
            $customerLocation['longitude'],
            $currentName,
            'Customer'
        );

        $routeSegments[] = $finalSegment;
        $totalDistanceKm += $finalSegment['distance_km'];

        if ($finalSegment['source'] === 'google_maps') {
            $distanceSource = 'google_maps';
        }

        // Calculate ETA: 5 minutes per km
        $estimatedTimeMin = round($totalDistanceKm * self::MINUTES_PER_KM, 2);

        return [
            'total_distance_km' => round($totalDistanceKm, 2),
            'estimated_time_min' => $estimatedTimeMin,
            'estimated_time_formatted' => self::formatTime($estimatedTimeMin),
            'route_segments' => $routeSegments,
            'distance_source' => $distanceSource,
            'calculation_rate' => self::MINUTES_PER_KM . ' min/km'
        ];
    }

    /**
     * Calculate distance for a single segment using Google Maps API with Haversine fallback
     *
     * @param float $lat1
     * @param float $lon1
     * @param float $lat2
     * @param float $lon2
     * @param string $fromName
     * @param string $toName
     * @return array
     */
    private static function calculateSegmentDistance(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2,
        string $fromName,
        string $toName
    ): array {
        // Try Google Maps API first
        $googleResult = self::getGoogleMapsDistance($lat1, $lon1, $lat2, $lon2);

        if ($googleResult !== null) {
            return [
                'from' => $fromName,
                'to' => $toName,
                'from_coords' => ['lat' => $lat1, 'lon' => $lon1],
                'to_coords' => ['lat' => $lat2, 'lon' => $lon2],
                'distance_km' => $googleResult['distance_km'],
                'google_time_min' => $googleResult['time_min'],
                'source' => 'google_maps'
            ];
        }

        // Fallback to Haversine
        $haversineDistance = self::calculateHaversineDistance($lat1, $lon1, $lat2, $lon2);

        return [
            'from' => $fromName,
            'to' => $toName,
            'from_coords' => ['lat' => $lat1, 'lon' => $lon1],
            'to_coords' => ['lat' => $lat2, 'lon' => $lon2],
            'distance_km' => $haversineDistance,
            'google_time_min' => null,
            'source' => 'haversine'
        ];
    }

    /**
     * Get distance using Google Maps Distance Matrix API
     *
     * @param float $lat1
     * @param float $lon1
     * @param float $lat2
     * @param float $lon2
     * @return array|null
     */
    private static function getGoogleMapsDistance(float $lat1, float $lon1, float $lat2, float $lon2): ?array
    {
        try {
            // Get API key from settings table
            $apiKey = DB::table('settings')
                ->where('variable', 'googleMapApiKey')
                ->value('value');

            if (empty($apiKey)) {
                Log::info("OrderArrivalTimeService: Google Maps API key not found, using Haversine");
                return null;
            }

            $url = "https://maps.googleapis.com/maps/api/distancematrix/json?"
                . "origins={$lat1},{$lon1}"
                . "&destinations={$lat2},{$lon2}"
                . "&key={$apiKey}";

            $ch = curl_init();

            curl_setopt_array($ch, [
                CURLOPT_URL => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_TIMEOUT => 10
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if (!$response || $httpCode !== 200) {
                Log::warning("OrderArrivalTimeService: Google Maps API request failed", [
                    'http_code' => $httpCode
                ]);
                return null;
            }

            $json = json_decode($response, true);

            if (
                !isset($json['rows'][0]['elements'][0]['status']) ||
                $json['rows'][0]['elements'][0]['status'] !== 'OK'
            ) {
                Log::warning("OrderArrivalTimeService: Google Maps API returned non-OK status", [
                    'response' => $json
                ]);
                return null;
            }

            return [
                'distance_km' => round($json['rows'][0]['elements'][0]['distance']['value'] / 1000, 2),
                'time_min' => round($json['rows'][0]['elements'][0]['duration']['value'] / 60, 2)
            ];

        } catch (\Exception $e) {
            Log::error("OrderArrivalTimeService: Google Maps API exception", [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Get customer location from order or user_addresses table
     *
     * @param object $order
     * @return array|null
     */
    private static function getCustomerLocation(object $order): ?array
    {
        // First try to get from order directly
        if (!empty($order->latitude) && !empty($order->longitude)) {
            return [
                'latitude' => (float) $order->latitude,
                'longitude' => (float) $order->longitude,
                'source' => 'order'
            ];
        }

        // Fallback to user_addresses table
        if ($order->address_id > 0) {
            $address = DB::table('user_addresses')
                ->where('id', $order->address_id)
                ->select(['latitude', 'longitude', 'city_id'])
                ->first();

            if ($address && !empty($address->latitude) && !empty($address->longitude)) {
                return [
                    'latitude' => (float) $address->latitude,
                    'longitude' => (float) $address->longitude,
                    'city_id' => $address->city_id,
                    'source' => 'user_addresses'
                ];
            }
        }

        return null;
    }

    /**
     * Get pickup location for a tracking record
     *
     * @param object $record
     * @param array $customerLocation
     * @return array|null
     */
    private static function getPickupLocationForRecord(object $record, array $customerLocation): ?array
    {
        $sellerId = $record->seller_id;
        $storeId = $record->store_id;

        // Case 1: seller_id is NOT null - check if managed_by_admin
        if ($sellerId !== null) {
            // Get seller details with store info
            $seller = DB::table('sellers')
                ->where('id', $sellerId)
                ->select(['id', 'name', 'lat_long', 'store_id'])
                ->first();

            if (!$seller) {
                Log::warning("OrderArrivalTimeService: Seller not found for seller_id: {$sellerId}");
                return null;
            }

            // Check if store is managed_by_admin
            $store = DB::table('stores')
                ->where('id', $seller->store_id)
                ->select(['id', 'name', 'managed_by_admin'])
                ->first();

            if (!$store) {
                Log::warning("OrderArrivalTimeService: Store not found for store_id: {$seller->store_id}");
                return null;
            }

            // If managed_by_admin = 0, use seller's lat_long
            if ($store->managed_by_admin == 0) {
                $latLong = self::parseLatLong($seller->lat_long);

                if ($latLong) {
                    $distance = self::calculateHaversineDistance(
                        $latLong['latitude'],
                        $latLong['longitude'],
                        $customerLocation['latitude'],
                        $customerLocation['longitude']
                    );

                    return [
                        'tracking_id' => $record->id,
                        'seller_id' => $sellerId,
                        'store_id' => $storeId,
                        'seller_name' => $seller->name,
                        'store_name' => $store->name,
                        'managed_by_admin' => false,
                        'latitude' => $latLong['latitude'],
                        'longitude' => $latLong['longitude'],
                        'distance_km' => $distance,
                        'source' => 'seller_lat_long'
                    ];
                }
            }

            // If managed_by_admin = 1, use nearest store_location
            return self::getNearestStoreLocation($record, $customerLocation, $store->name);
        }

        // Case 2: seller_id is NULL - Zenfoo store product, use nearest store_location
        $store = DB::table('stores')
            ->where('id', $storeId)
            ->select(['id', 'name'])
            ->first();

        $storeName = $store ? $store->name : 'Unknown Store';

        return self::getNearestStoreLocation($record, $customerLocation, $storeName);
    }

    /**
     * Get nearest store_location to customer
     *
     * @param object $record
     * @param array $customerLocation
     * @param string $storeName
     * @return array|null
     */
    private static function getNearestStoreLocation(object $record, array $customerLocation, string $storeName): ?array
    {
        // Get all active store_locations
        $storeLocations = DB::table('store_locations')
            ->where('status', 1)
            ->select(['id', 'name', 'latitude', 'longitude', 'address'])
            ->get();

        if ($storeLocations->isEmpty()) {
            Log::warning("OrderArrivalTimeService: No active store_locations found");
            return null;
        }

        $nearestLocation = null;
        $minDistance = PHP_FLOAT_MAX;

        foreach ($storeLocations as $location) {
            $distance = self::calculateHaversineDistance(
                (float) $location->latitude,
                (float) $location->longitude,
                $customerLocation['latitude'],
                $customerLocation['longitude']
            );

            if ($distance < $minDistance) {
                $minDistance = $distance;
                $nearestLocation = $location;
            }
        }

        if (!$nearestLocation) {
            return null;
        }

        return [
            'tracking_id' => $record->id,
            'seller_id' => $record->seller_id,
            'store_id' => $record->store_id,
            'seller_name' => null,
            'store_name' => $storeName,
            'managed_by_admin' => true,
            'store_location_id' => $nearestLocation->id,
            'store_location_name' => $nearestLocation->name,
            'latitude' => (float) $nearestLocation->latitude,
            'longitude' => (float) $nearestLocation->longitude,
            'distance_km' => $minDistance,
            'source' => 'store_locations'
        ];
    }

    /**
     * Parse lat_long string (format: "lat,long") to array
     *
     * @param string|null $latLong
     * @return array|null
     */
    private static function parseLatLong(?string $latLong): ?array
    {
        if (empty($latLong)) {
            return null;
        }

        $parts = explode(',', $latLong);

        if (count($parts) !== 2) {
            return null;
        }

        $latitude = trim($parts[0]);
        $longitude = trim($parts[1]);

        if (!is_numeric($latitude) || !is_numeric($longitude)) {
            return null;
        }

        return [
            'latitude' => (float) $latitude,
            'longitude' => (float) $longitude
        ];
    }

    /**
     * Calculate distance between two coordinates using Haversine formula
     *
     * @param float $lat1
     * @param float $lon1
     * @param float $lat2
     * @param float $lon2
     * @return float Distance in kilometers
     */
    private static function calculateHaversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371; // Earth's radius in kilometers

        $latDiff = deg2rad($lat2 - $lat1);
        $lonDiff = deg2rad($lon2 - $lon1);

        $a = sin($latDiff / 2) * sin($latDiff / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($lonDiff / 2) * sin($lonDiff / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        $distance = $earthRadius * $c;

        return round($distance, 2);
    }

    /**
     * Get complete order items snapshot with product details
     *
     * Returns all order items (regular + combo) with:
     * - product_id, name, image, store_id
     * - quantity, price, discounted_price
     * - variant info (measurement, unit)
     * - seller info
     *
     * @param int $orderId
     * @return array
     */
    public static function getOrderItemsSnapshot(int $orderId): array
    {
        try {
            Log::info("OrderArrivalTimeService: Getting order items snapshot for order_id: {$orderId}");

            $snapshot = [
                'order_items' => [],
                'combo_items' => [],
                'total_items' => 0,
                'total_quantity' => 0
            ];

            // Step 1: Get regular order items with full product details
            $orderItems = DB::table('order_items as oi')
                ->leftJoin('product_variants as v', 'oi.product_variant_id', '=', 'v.id')
                ->leftJoin('products as p', 'v.product_id', '=', 'p.id')
                ->leftJoin('sellers as s', 'oi.seller_id', '=', 's.id')
                ->leftJoin('stores as st', 'p.store_id', '=', 'st.id')
                ->leftJoin('units as u', 'v.stock_unit_id', '=', 'u.id')
                ->where('oi.order_id', $orderId)
                ->select([
                    'oi.id as order_item_id',
                    'oi.quantity',
                    'oi.price',
                    'oi.discounted_price',
                    'oi.sub_total',
                    'oi.product_variant_id',
                    'p.id as product_id',
                    'p.name as product_name',
                    'p.image as product_image',
                    'p.store_id',
                    'v.measurement',
                    'v.price as variant_price',
                    'v.discounted_price as variant_discounted_price',
                    'u.short_code as unit',
                    's.id as seller_id',
                    's.store_name as seller_name',
                    'st.name as store_name'
                ])
                ->get()
                ->toArray();

            foreach ($orderItems as $item) {
                $snapshot['order_items'][] = [
                    'order_item_id' => $item->order_item_id,
                    'product_id' => $item->product_id,
                    'product_name' => $item->product_name,
                    'product_image' => $item->product_image,
                    'store_id' => $item->store_id,
                    'store_name' => $item->store_name,
                    'seller_id' => $item->seller_id,
                    'seller_name' => $item->seller_name,
                    'variant_id' => $item->product_variant_id,
                    'measurement' => $item->measurement,
                    'unit' => $item->unit,
                    'quantity' => $item->quantity,
                    'price' => $item->price,
                    'discounted_price' => $item->discounted_price,
                    'sub_total' => $item->sub_total
                ];
                $snapshot['total_quantity'] += $item->quantity;
            }

            // Step 2: Get combo items with full details
            $comboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->select(['id', 'combo_id', 'total_products_price', 'sub_total', 'products', 'product_count'])
                ->get();

            foreach ($comboItems as $comboItem) {
                $comboProducts = json_decode($comboItem->products, true);
                // Handle double-encoded JSON
                if (is_string($comboProducts)) {
                    $comboProducts = json_decode($comboProducts, true);
                }

                $productDetails = [];
                if (is_array($comboProducts)) {
                    // Get all product IDs from combo
                    $productIds = array_column($comboProducts, 'product_id');

                    if (!empty($productIds)) {
                        // Fetch product details
                        $products = DB::table('products as p')
                            ->leftJoin('stores as st', 'p.store_id', '=', 'st.id')
                            ->whereIn('p.id', $productIds)
                            ->select([
                                'p.id as product_id',
                                'p.name as product_name',
                                'p.image as product_image',
                                'p.store_id',
                                'st.name as store_name'
                            ])
                            ->get()
                            ->keyBy('product_id')
                            ->toArray();

                        foreach ($comboProducts as $cp) {
                            $pid = $cp['product_id'] ?? null;
                            if ($pid && isset($products[$pid])) {
                                $prod = $products[$pid];
                                $productDetails[] = [
                                    'product_id' => $prod->product_id,
                                    'product_name' => $prod->product_name,
                                    'product_image' => $prod->product_image,
                                    'store_id' => $prod->store_id,
                                    'store_name' => $prod->store_name,
                                    'quantity' => $cp['quantity'] ?? 1
                                ];
                            }
                        }
                    }
                }

                $snapshot['combo_items'][] = [
                    'order_combo_item_id' => $comboItem->id,
                    'combo_id' => $comboItem->combo_id,
                    'product_count' => $comboItem->product_count,
                    'total_products_price' => $comboItem->total_products_price,
                    'sub_total' => $comboItem->sub_total,
                    'products' => $productDetails
                ];
                $snapshot['total_quantity'] += $comboItem->product_count;
            }

            $snapshot['total_items'] = count($snapshot['order_items']) + count($snapshot['combo_items']);

            Log::info("OrderArrivalTimeService: Order items snapshot created for order_id: {$orderId}", [
                'order_items_count' => count($snapshot['order_items']),
                'combo_items_count' => count($snapshot['combo_items'])
            ]);

            return $snapshot;

        } catch (\Exception $e) {
            Log::error("OrderArrivalTimeService: Error getting order items snapshot for order_id: {$orderId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'order_items' => [],
                'combo_items' => [],
                'total_items' => 0,
                'total_quantity' => 0,
                'error' => $e->getMessage()
            ];
        }
    }

    /**
     * Get seller count for an order by counting unique stores from order items
     *
     * Logic:
     * - order_items -> product_variant_id -> product_variants -> product_id -> products -> store_id
     * - order_combo_items -> products (JSON with product_id) -> products -> store_id
     * - Count unique store_ids
     *
     * @param int $orderId
     * @return int
     */
    public static function getSellerCount(int $orderId): int
    {
        try {
            Log::info("OrderArrivalTimeService: Calculating seller count for order_id: {$orderId}");

            $allProductIds = [];

            // Step 1: Get product IDs from order_items via product_variants
            $orderItemVariantIds = DB::table('order_items')
                ->where('order_id', $orderId)
                ->pluck('product_variant_id')
                ->toArray();

            if (!empty($orderItemVariantIds)) {
                $regularProductIds = DB::table('product_variants')
                    ->whereIn('id', $orderItemVariantIds)
                    ->pluck('product_id')
                    ->toArray();
                $allProductIds = array_merge($allProductIds, $regularProductIds);
            }

            // Step 2: Get product IDs from order_combo_items
            $comboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->pluck('products')
                ->toArray();

            foreach ($comboItems as $productsJson) {
                $products = json_decode($productsJson, true);
                // Handle double-encoded JSON
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }
                if (is_array($products)) {
                    foreach ($products as $product) {
                        if (isset($product['product_id'])) {
                            $allProductIds[] = $product['product_id'];
                        }
                    }
                }
            }

            $allProductIds = array_unique($allProductIds);

            if (empty($allProductIds)) {
                Log::info("OrderArrivalTimeService: No products found for order_id: {$orderId}");
                return 0;
            }

            // Step 3: Get unique store_ids from products table
            $uniqueStoreCount = DB::table('products')
                ->whereIn('id', $allProductIds)
                ->distinct()
                ->count('store_id');

            Log::info("OrderArrivalTimeService: Seller count for order_id: {$orderId} is {$uniqueStoreCount}");

            return $uniqueStoreCount;

        } catch (\Exception $e) {
            Log::error("OrderArrivalTimeService: Error calculating seller count for order_id: {$orderId}", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return 0;
        }
    }

    /**
     * Format time in minutes to human readable string
     *
     * @param float $minutes
     * @return string
     */
    private static function formatTime(float $minutes): string
    {
        if ($minutes < 1) {
            return round($minutes * 60) . ' sec';
        }

        if ($minutes < 60) {
            return round($minutes) . ' min';
        }

        $hours = floor($minutes / 60);
        $mins = round($minutes % 60);

        if ($mins === 0) {
            return $hours . ' hr';
        }

        return $hours . ' hr ' . $mins . ' min';
    }
}
