<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use App\Models\Cart;
use App\Services\DeliveryChargeCalculationService;

class CartStoreIdsService
{
    /**
     * Get all unique store IDs from the user's cart with managed_by_admin flag
     * For non-admin managed stores, also includes seller information
     * This includes:
     * - Store IDs from regular cart items
     * - Store IDs from admin-managed store items
     * - Store IDs from custom combo products
     *
     * @param int $userId User ID
     * @return array
     */
    public static function getCartStoreIds(int $userId): array
    {
        $storeIds = [];
        $storeSellerMap = []; // Map store_id to seller_id for non-admin managed stores

        // 1. Get store IDs and seller IDs from regular cart items (not save_for_later)
        $cartItems = Cart::select('products.store_id', 'products.seller_id', 'stores.managed_by_admin')
            ->join('products', 'carts.product_id', '=', 'products.id')
            ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
            ->where('carts.user_id', $userId)
            ->where('carts.save_for_later', 0)
            ->whereNotNull('products.store_id')
            ->distinct()
            ->get();

        foreach ($cartItems as $item) {
            $storeIds[] = $item->store_id;
            if (!$item->managed_by_admin && $item->seller_id) {
                $storeSellerMap[$item->store_id] = $item->seller_id;
            }
        }

        // 2. Get store IDs from custom combo products in cart
        $customComboCarts = DB::table('combo_custom_cart')
            ->where('user_id', $userId)
            ->where('is_ordered', 0)
            ->pluck('id')
            ->toArray();

        if (!empty($customComboCarts)) {
            $comboProductIds = DB::table('combo_custom_products')
                ->whereIn('combo_custom_id', $customComboCarts)
                ->pluck('product_id')
                ->toArray();

            if (!empty($comboProductIds)) {
                $comboItems = DB::table('products')
                    ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
                    ->whereIn('products.id', $comboProductIds)
                    ->whereNotNull('products.store_id')
                    ->select('products.store_id', 'products.seller_id', 'stores.managed_by_admin')
                    ->distinct()
                    ->get();

                foreach ($comboItems as $item) {
                    $storeIds[] = $item->store_id;
                    if (!$item->managed_by_admin && $item->seller_id) {
                        $storeSellerMap[$item->store_id] = $item->seller_id;
                    }
                }
            }
        }

        // Remove duplicates and re-index array
        $storeIds = array_values(array_unique($storeIds));

        // Get unique seller IDs for fetching seller details
        $sellerIds = array_values(array_unique(array_values($storeSellerMap)));

        // Get seller details
        $sellers = [];
        if (!empty($sellerIds)) {
            $sellers = DB::table('sellers')
                ->whereIn('id', $sellerIds)
                ->select('id', 'name', 'lat_long', 'mobile')
                ->get()
                ->keyBy('id')
                ->toArray();
        }

        // Get store details with managed_by_admin flag
        $stores = DB::table('stores')
            ->whereIn('id', $storeIds)
            ->select('id as store_id', 'name as store_name', 'managed_by_admin')
            ->get()
            ->map(function ($store) use ($storeSellerMap, $sellers) {
                $result = [
                    'store_id' => $store->store_id,
                    'store_name' => $store->store_name,
                    'managed_by_admin' => (bool) $store->managed_by_admin
                ];

                // Add seller info for non-admin managed stores
                if (!$store->managed_by_admin && isset($storeSellerMap[$store->store_id])) {
                    $sellerId = $storeSellerMap[$store->store_id];
                    $result['seller_id'] = $sellerId;

                    if (isset($sellers[$sellerId])) {
                        $seller = $sellers[$sellerId];
                        $result['seller_name'] = $seller->name;
                        $result['seller_lat_long'] = $seller->lat_long;
                        $result['seller_mobile'] = $seller->mobile;
                    }
                }

                return $result;
            })
            ->toArray();

        // Get user's default address
        $defaultAddress = DB::table('user_addresses')
            ->where('user_id', $userId)
            ->where('is_default', 1)
            ->first();

        // Check if any store is managed_by_admin and get store location if so
        $hasAdminManagedStore = collect($stores)->contains('managed_by_admin', true);
        $storeLocation = null;

        if ($hasAdminManagedStore && $defaultAddress && $defaultAddress->city_id) {
            $storeLocation = DB::table('store_locations')
                ->where('city_id', $defaultAddress->city_id)
                ->select('id', 'city_id', 'latitude', 'longitude')
                ->first();
        }

        // Add store_location lat/lon to admin-managed stores
        $stores = collect($stores)->map(function ($store) use ($storeLocation) {
            if ($store['managed_by_admin'] && $storeLocation) {
                $store['latitude'] = $storeLocation->latitude;
                $store['longitude'] = $storeLocation->longitude;
            }
            return $store;
        })->toArray();


        
        $city = DB::table('cities')->where('id', $defaultAddress->city_id)->first();
        $fixed_price_per_km = $city->fixed_charge ?? 0;
        $per_km_charge = $city->per_km_charge ?? 0;

        
        // Build locations array with lat, lon, is_managed_by_admin
        $locations = [];

        foreach ($stores as $store) {
            if ($store['managed_by_admin']) {
                if (isset($store['latitude']) && isset($store['longitude'])) {
                    $locations[] = [
                        'latitude' => $store['latitude'],
                        'longitude' => $store['longitude'],
                        'is_managed_by_admin' => true
                    ];
                }
            } else {
                if (isset($store['seller_lat_long']) && $store['seller_lat_long']) {
                    $latLong = explode(',', $store['seller_lat_long']);
                    $locations[] = [
                        'latitude' => $latLong[0] ?? null,
                        'longitude' => $latLong[1] ?? null,
                        'is_managed_by_admin' => false
                    ];
                }
            }
        }

        // Get customer lat/lon from default address
        $customerLat = floatval($defaultAddress->latitude ?? 0);
        $customerLon = floatval($defaultAddress->longitude ?? 0);
        $cityId = $defaultAddress->city_id ? intval($defaultAddress->city_id) : null;

        // Prepare seller locations with their details
        $sellerLocations = [];
        foreach ($locations as $index => $location) {
            if ($location['latitude'] && $location['longitude']) {
                $sellerLocations[] = [
                    'index' => $index,
                    'lat' => floatval($location['latitude']),
                    'lon' => floatval($location['longitude']),
                    'is_managed_by_admin' => $location['is_managed_by_admin']
                ];
            }
        }

        // Calculate chain delivery: Customer -> Nearest Seller -> Next Nearest Seller -> ...
        $deliveryChain = [];
        $totalDistance = 0;
        $totalDuration = 0;
        $totalCharge = 0;

        // Start from customer location
        $currentLat = $customerLat;
        $currentLon = $customerLon;
        $remainingSellers = $sellerLocations;
        $visitOrder = [];

        while (!empty($remainingSellers)) {
            // Find nearest seller from current location
            $nearestIndex = null;
            $nearestDistance = PHP_FLOAT_MAX;
            $nearestResult = null;

            foreach ($remainingSellers as $key => $seller) {
                $distance = DeliveryChargeCalculationService::calculateHaversineDistance(
                    $currentLat,
                    $currentLon,
                    $seller['lat'],
                    $seller['lon']
                );

                if ($distance < $nearestDistance) {
                    $nearestDistance = $distance;
                    $nearestIndex = $key;
                }
            }

            if ($nearestIndex !== null) {
                $nearestSeller = $remainingSellers[$nearestIndex];

                // Get actual distance using Google Maps or Haversine
                $distanceResult = DeliveryChargeCalculationService::getDistanceOnly(
                    $currentLat,
                    $currentLon,
                    $nearestSeller['lat'],
                    $nearestSeller['lon']
                );

                // Calculate charge for this leg
                $legCharge = DeliveryChargeCalculationService::calculateDeliveryCharge(
                    [['lat' => $nearestSeller['lat'], 'lon' => $nearestSeller['lon']]],
                    $currentLat,
                    $currentLon,
                    $cityId,
                    0
                );

                $deliveryChain[] = [
                    'from' => [
                        'type' => empty($visitOrder) ? 'customer' : 'seller',
                        'lat' => $currentLat,
                        'lon' => $currentLon
                    ],
                    'to' => [
                        'type' => 'seller',
                        'lat' => $nearestSeller['lat'],
                        'lon' => $nearestSeller['lon'],
                        'is_managed_by_admin' => $nearestSeller['is_managed_by_admin']
                    ],
                    'distance_km' => $distanceResult['distance_km'],
                    'distance_text' => $distanceResult['distance_text'],
                    'duration_min' => $distanceResult['duration_min'],
                    'duration_text' => $distanceResult['duration_text'],
                    'charge' => $legCharge['charge'] ?? 0
                ];

                $totalDistance += $distanceResult['distance_km'];
                $totalDuration += $distanceResult['duration_min'];
                $totalCharge += $legCharge['charge'] ?? 0;

                // Move to the nearest seller location
                $currentLat = $nearestSeller['lat'];
                $currentLon = $nearestSeller['lon'];
                $visitOrder[] = $nearestSeller;

                // Remove from remaining
                unset($remainingSellers[$nearestIndex]);
                $remainingSellers = array_values($remainingSellers);
            }
        }

        // Tiered delivery charge logic (matching CommonHelper)
        $chargeBelow1km = \App\Models\Setting::get_value('delivery_charge_below_1km') ?? 20;
        $charge1to2km = \App\Models\Setting::get_value('delivery_charge_1_to_2km') ?? 25;

        if ($totalDistance < 1) {
            $total_delivery_charges = (float) $chargeBelow1km;
        } elseif ($totalDistance >= 1 && $totalDistance <= 2) {
            $total_delivery_charges = (float) $charge1to2km;
        } else {
            // > 2 km: use per_km_charge from city settings. If the city has no
            // per_km_charge configured this yields 0, which silently makes the
            // delivery boy's earning 0 on every long trip — floor it at the
            // 1-2 km tier so a longer ride is never cheaper than a short one.
            $total_delivery_charges = max(
                (float) $per_km_charge * ceil($totalDistance),
                (float) $charge1to2km
            );

            if ((float) $per_km_charge <= 0) {
                \Log::warning('CartStoreIdsService: city per_km_charge not configured, falling back to 1-2km tier', [
                    'city_id' => $defaultAddress->city_id ?? null,
                    'total_distance_km' => round($totalDistance, 2),
                    'fallback_charge' => (float) $charge1to2km,
                ]);
            }
        }

        \Log::info('CartStoreIdsService: Delivery charge calculation', [
            'total_distance_km' => round($totalDistance, 2),
            'charge_below_1km' => $chargeBelow1km,
            'charge_1_to_2km' => $charge1to2km,
            'per_km_charge' => $per_km_charge,
            'total_delivery_charges' => round($total_delivery_charges, 2),
            'city_id' => $defaultAddress->city_id ?? null,
        ]);

        // dd for testing in Postman
        // dd([
        //     'user_id' => $userId,
        //     'stores' => $stores,
        //     'store_ids' => $storeIds,
        //     'total_unique_stores' => count($storeIds),
        //     'default_address' => $defaultAddress,
        //     'locations' => $locations,
        //     'delivery_chain' => $deliveryChain,
        //     'visit_order' => $visitOrder,
        //     'totals' => [
        //         'total_distance_km' => round($totalDistance, 2),
        //         'total_duration_min' => round($totalDuration, 2),
        //         'total_charge' => round($total_delivery_charges, 2)
        //     ]
        // ]);

        return [
            'delivery_charge' => $total_delivery_charges,
            'total_distance' => round($totalDistance, 2)
        ];
    }
}
