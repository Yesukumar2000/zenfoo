<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\Store;
use App\Models\StoreLocation;
use App\Models\Seller;
use App\Models\Product;
use App\Models\Cart;
use App\Services\DeliveryChargeCalculationService;

class CartDeliveryChargeService
{
    /**
     * Calculate delivery charges for cart items
     * Handles both admin-managed store products and seller-managed products
     *
     * @param int $userId User ID
     * @param float $subTotal Order subtotal for free delivery check
     * @return array
     */
    public static function calculateCartDeliveryCharge(
        int $userId,
        float $subTotal = 0
    ): array {
        try {
            // Get customer's default address for city_id and coordinates
            $customerAddress = DB::table('user_addresses')
                ->where('user_id', $userId)
                ->where('is_default', 1)
                ->first();

            if (!$customerAddress) {
                return [
                    'status' => 0,
                    'message' => 'No default address found for user'
                ];
            }

            $customerCityId = $customerAddress->city_id ?? null;
            $customerLat = floatval($customerAddress->latitude ?? 0);
            $customerLon = floatval($customerAddress->longitude ?? 0);

            // Debug: Log city_id for testing
            Log::info('CartDeliveryChargeService: Debug city_id', [
                'user_id' => $userId,
                'city_id' => $customerCityId,
                'customer_lat' => $customerLat,
                'customer_lon' => $customerLon,
                'address_id' => $customerAddress->id ?? null,
                'address' => $customerAddress->address ?? null
            ]);

            // Return debug response for Postman testing
            return [
                'status' => 1,
                'debug' => true,
                'data' => [
                    'user_id' => $userId,
                    'city_id' => $customerCityId,
                    'customer_lat' => $customerLat,
                    'customer_lon' => $customerLon,
                    'address_id' => $customerAddress->id ?? null,
                    'total_delivery_charge' => 0,
                    'delivery_charge' => 0
                ]
            ];

            // Get cart items with product and store information
            $cartItems = Cart::select(
                'carts.*',
                'products.id as product_id',
                'products.seller_id',
                'products.store_id',
                'stores.managed_by_admin',
                'sellers.latitude as seller_lat',
                'sellers.longitude as seller_lon',
                'sellers.name as seller_name',
                'sellers.city_id as seller_city_id'
            )
                ->join('products', 'carts.product_id', '=', 'products.id')
                ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->where('carts.user_id', $userId)
                ->where('carts.save_for_later', 0)
                ->get();

            if ($cartItems->isEmpty()) {
                return [
                    'status' => 1,
                    'data' => [
                        'total_delivery_charge' => 0,
                        'delivery_charge' => 0,
                        'delivery_charge_details' => []
                    ]
                ];
            }

            // Separate items into admin-managed and seller-managed
            $adminManagedItems = $cartItems->filter(function ($item) {
                return $item->managed_by_admin == 1;
            });

            $sellerManagedItems = $cartItems->filter(function ($item) {
                return $item->managed_by_admin != 1;
            });

            $deliveryChargeDetails = [];
            $totalDeliveryCharge = 0;

            // Process admin-managed store items
            if ($adminManagedItems->isNotEmpty()) {
                $adminChargeResult = self::calculateAdminManagedDeliveryCharge(
                    $customerLat,
                    $customerLon,
                    $customerCityId,
                    $subTotal
                );

                if ($adminChargeResult['status'] == 1) {
                    $deliveryChargeDetails[] = [
                        'type' => 'admin_managed',
                        'source_name' => $adminChargeResult['store_name'] ?? 'Zenfoo Store',
                        'source_lat' => $adminChargeResult['store_lat'] ?? 0,
                        'source_lon' => $adminChargeResult['store_lon'] ?? 0,
                        'delivery_charge' => $adminChargeResult['charge'],
                        'distance' => $adminChargeResult['distance'] ?? 0,
                        'distance_text' => $adminChargeResult['distance_text'] ?? '',
                        'duration' => $adminChargeResult['duration'] ?? 0,
                        'duration_text' => $adminChargeResult['duration_text'] ?? '',
                        'free_delivery' => $adminChargeResult['free_delivery'] ?? false
                    ];
                    $totalDeliveryCharge += $adminChargeResult['charge'];
                } elseif ($adminChargeResult['status'] == 0) {
                    return [
                        'status' => 0,
                        'message' => $adminChargeResult['message'] ?? 'Unable to calculate delivery charge for admin-managed store'
                    ];
                }
            }

            // Process seller-managed items (group by seller to avoid duplicate charges)
            if ($sellerManagedItems->isNotEmpty()) {
                $sellerIds = $sellerManagedItems->pluck('seller_id')->unique()->filter()->values()->toArray();

                foreach ($sellerIds as $sellerId) {
                    $sellerChargeResult = self::calculateSellerDeliveryCharge(
                        $sellerId,
                        $customerLat,
                        $customerLon,
                        $subTotal
                    );

                    if ($sellerChargeResult['status'] == 1) {
                        $deliveryChargeDetails[] = [
                            'type' => 'seller_managed',
                            'seller_id' => $sellerId,
                            'source_name' => $sellerChargeResult['seller_name'] ?? 'Seller',
                            'source_lat' => $sellerChargeResult['seller_lat'] ?? 0,
                            'source_lon' => $sellerChargeResult['seller_lon'] ?? 0,
                            'delivery_charge' => $sellerChargeResult['charge'],
                            'distance' => $sellerChargeResult['distance'] ?? 0,
                            'distance_text' => $sellerChargeResult['distance_text'] ?? '',
                            'duration' => $sellerChargeResult['duration'] ?? 0,
                            'duration_text' => $sellerChargeResult['duration_text'] ?? '',
                            'free_delivery' => $sellerChargeResult['free_delivery'] ?? false
                        ];
                        $totalDeliveryCharge += $sellerChargeResult['charge'];
                    } elseif ($sellerChargeResult['status'] == 0) {
                        return [
                            'status' => 0,
                            'message' => $sellerChargeResult['message'] ?? 'Unable to calculate delivery charge for seller'
                        ];
                    }
                }
            }

            return [
                'status' => 1,
                'data' => [
                    'total_delivery_charge' => round($totalDeliveryCharge, 2),
                    'delivery_charge' => round($totalDeliveryCharge, 2),
                    'delivery_charge_details' => $deliveryChargeDetails
                ]
            ];

        } catch (\Exception $e) {
            Log::error('CartDeliveryChargeService: Error calculating cart delivery charge', [
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'status' => 0,
                'message' => 'Error calculating delivery charge: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Calculate delivery charge for admin-managed store products
     * Uses nearest Zenfoo store location based on customer's city
     *
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @param int|null $customerCityId Customer's city ID from default address
     * @param float $subTotal Order subtotal
     * @return array
     */
    private static function calculateAdminManagedDeliveryCharge(
        float $customerLat,
        float $customerLon,
        ?int $customerCityId,
        float $subTotal
    ): array {
        try {
            // Find nearest store location in the customer's city
            $nearestStore = self::findNearestStoreLocation($customerLat, $customerLon, $customerCityId);

            if (!$nearestStore) {
                Log::warning('CartDeliveryChargeService: No store location found', [
                    'customer_city_id' => $customerCityId,
                    'customer_lat' => $customerLat,
                    'customer_lon' => $customerLon
                ]);

                return [
                    'status' => 0,
                    'message' => 'No store location available for delivery'
                ];
            }

            // Calculate delivery charge using the existing service
            $chargeResult = DeliveryChargeCalculationService::calculateDeliveryCharge(
                [
                    [
                        'lat' => floatval($nearestStore->latitude),
                        'lon' => floatval($nearestStore->longitude)
                    ]
                ],
                $customerLat,
                $customerLon,
                $customerCityId,
                $subTotal
            );

            return [
                'status' => $chargeResult['error'] ? 0 : 1,
                'message' => $chargeResult['message'] ?? '',
                'charge' => $chargeResult['charge'] ?? 0,
                'distance' => $chargeResult['distance'] ?? 0,
                'distance_text' => $chargeResult['distance_text'] ?? '',
                'duration' => $chargeResult['duration'] ?? 0,
                'duration_text' => $chargeResult['duration_text'] ?? '',
                'store_name' => $nearestStore->name ?? 'Zenfoo Store',
                'store_lat' => floatval($nearestStore->latitude),
                'store_lon' => floatval($nearestStore->longitude),
                'store_location_id' => $nearestStore->id,
                'free_delivery' => $chargeResult['free_delivery'] ?? false
            ];

        } catch (\Exception $e) {
            Log::error('CartDeliveryChargeService: Error calculating admin-managed delivery charge', [
                'error' => $e->getMessage()
            ]);

            return [
                'status' => 0,
                'message' => 'Error calculating delivery charge: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Calculate delivery charge for seller-managed products
     *
     * @param int $sellerId Seller ID
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @param float $subTotal Order subtotal
     * @return array
     */
    private static function calculateSellerDeliveryCharge(
        int $sellerId,
        float $customerLat,
        float $customerLon,
        float $subTotal
    ): array {
        try {
            $seller = Seller::find($sellerId);

            if (!$seller) {
                Log::warning('CartDeliveryChargeService: Seller not found', [
                    'seller_id' => $sellerId
                ]);

                return [
                    'status' => 0,
                    'message' => 'Seller not found'
                ];
            }

            if (empty($seller->latitude) || empty($seller->longitude)) {
                Log::warning('CartDeliveryChargeService: Seller location not available', [
                    'seller_id' => $sellerId
                ]);

                return [
                    'status' => 0,
                    'message' => 'Seller location not available'
                ];
            }

            // Calculate delivery charge using the existing service
            $chargeResult = DeliveryChargeCalculationService::calculateDeliveryCharge(
                [
                    [
                        'lat' => floatval($seller->latitude),
                        'lon' => floatval($seller->longitude)
                    ]
                ],
                $customerLat,
                $customerLon,
                $seller->city_id,
                $subTotal
            );

            return [
                'status' => $chargeResult['error'] ? 0 : 1,
                'message' => $chargeResult['message'] ?? '',
                'charge' => $chargeResult['charge'] ?? 0,
                'distance' => $chargeResult['distance'] ?? 0,
                'distance_text' => $chargeResult['distance_text'] ?? '',
                'duration' => $chargeResult['duration'] ?? 0,
                'duration_text' => $chargeResult['duration_text'] ?? '',
                'seller_name' => $seller->name ?? 'Seller',
                'seller_lat' => floatval($seller->latitude),
                'seller_lon' => floatval($seller->longitude),
                'free_delivery' => $chargeResult['free_delivery'] ?? false
            ];

        } catch (\Exception $e) {
            Log::error('CartDeliveryChargeService: Error calculating seller delivery charge', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);

            return [
                'status' => 0,
                'message' => 'Error calculating delivery charge: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Find the nearest store location to the customer
     * First tries to find stores in the customer's city, then falls back to nearest overall
     *
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @param int|null $cityId Customer's city ID
     * @return StoreLocation|null
     */
    private static function findNearestStoreLocation(
        float $customerLat,
        float $customerLon,
        ?int $cityId
    ): ?StoreLocation {
        // First, try to find active store locations in the same city
        if ($cityId) {
            $storeLocationsInCity = StoreLocation::active()
                ->byCity($cityId)
                ->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->get();

            if ($storeLocationsInCity->isNotEmpty()) {
                return self::getNearestFromCollection($storeLocationsInCity, $customerLat, $customerLon);
            }
        }

        // Fallback: Find nearest store location from all active stores
        $allStoreLocations = StoreLocation::active()
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->get();

        if ($allStoreLocations->isNotEmpty()) {
            return self::getNearestFromCollection($allStoreLocations, $customerLat, $customerLon);
        }

        return null;
    }

    /**
     * Get the nearest store location from a collection using Haversine distance
     *
     * @param \Illuminate\Database\Eloquent\Collection $storeLocations
     * @param float $customerLat
     * @param float $customerLon
     * @return StoreLocation|null
     */
    private static function getNearestFromCollection($storeLocations, float $customerLat, float $customerLon): ?StoreLocation
    {
        $nearestStore = null;
        $minDistance = PHP_FLOAT_MAX;

        foreach ($storeLocations as $store) {
            $distance = DeliveryChargeCalculationService::calculateHaversineDistance(
                $customerLat,
                $customerLon,
                floatval($store->latitude),
                floatval($store->longitude)
            );

            if ($distance < $minDistance) {
                $minDistance = $distance;
                $nearestStore = $store;
            }
        }

        return $nearestStore;
    }

    /**
     * Get delivery charge for a specific set of product variant IDs
     * Useful for checkout when specific items are selected
     *
     * @param int $userId User ID
     * @param array $productVariantIds Array of product variant IDs
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @param float $subTotal Order subtotal
     * @return array
     */
    public static function calculateDeliveryChargeForVariants(
        int $userId,
        array $productVariantIds,
        float $customerLat,
        float $customerLon,
        float $subTotal = 0
    ): array {
        try {
            // Get products for the given variant IDs
            $products = DB::table('product_variants')
                ->join('products', 'product_variants.product_id', '=', 'products.id')
                ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->whereIn('product_variants.id', $productVariantIds)
                ->select(
                    'products.id as product_id',
                    'products.seller_id',
                    'products.store_id',
                    'stores.managed_by_admin',
                    'sellers.latitude as seller_lat',
                    'sellers.longitude as seller_lon',
                    'sellers.name as seller_name',
                    'sellers.city_id as seller_city_id'
                )
                ->get();

            if ($products->isEmpty()) {
                return [
                    'status' => 1,
                    'data' => [
                        'total_delivery_charge' => 0,
                        'delivery_charge' => 0,
                        'delivery_charge_details' => []
                    ]
                ];
            }

            // Separate items into admin-managed and seller-managed
            $adminManagedProducts = $products->filter(function ($item) {
                return $item->managed_by_admin == 1;
            });

            $sellerManagedProducts = $products->filter(function ($item) {
                return $item->managed_by_admin != 1;
            });

            $deliveryChargeDetails = [];
            $totalDeliveryCharge = 0;

            // Get customer's default address for city_id
            $customerAddress = DB::table('user_addresses')
                ->where('user_id', $userId)
                ->where('is_default', 1)
                ->first();

            $customerCityId = $customerAddress->city_id ?? null;

            // Process admin-managed store items
            if ($adminManagedProducts->isNotEmpty()) {
                $adminChargeResult = self::calculateAdminManagedDeliveryCharge(
                    $customerLat,
                    $customerLon,
                    $customerCityId,
                    $subTotal
                );

                if ($adminChargeResult['status'] == 1) {
                    $deliveryChargeDetails[] = [
                        'type' => 'admin_managed',
                        'source_name' => $adminChargeResult['store_name'] ?? 'Zenfoo Store',
                        'source_lat' => $adminChargeResult['store_lat'] ?? 0,
                        'source_lon' => $adminChargeResult['store_lon'] ?? 0,
                        'delivery_charge' => $adminChargeResult['charge'],
                        'distance' => $adminChargeResult['distance'] ?? 0,
                        'distance_text' => $adminChargeResult['distance_text'] ?? '',
                        'duration' => $adminChargeResult['duration'] ?? 0,
                        'duration_text' => $adminChargeResult['duration_text'] ?? '',
                        'free_delivery' => $adminChargeResult['free_delivery'] ?? false
                    ];
                    $totalDeliveryCharge += $adminChargeResult['charge'];
                } elseif ($adminChargeResult['status'] == 0) {
                    return [
                        'status' => 0,
                        'message' => $adminChargeResult['message'] ?? 'Unable to calculate delivery charge for admin-managed store'
                    ];
                }
            }

            // Process seller-managed items
            if ($sellerManagedProducts->isNotEmpty()) {
                $sellerIds = $sellerManagedProducts->pluck('seller_id')->unique()->filter()->values()->toArray();

                foreach ($sellerIds as $sellerId) {
                    $sellerChargeResult = self::calculateSellerDeliveryCharge(
                        $sellerId,
                        $customerLat,
                        $customerLon,
                        $subTotal
                    );

                    if ($sellerChargeResult['status'] == 1) {
                        $deliveryChargeDetails[] = [
                            'type' => 'seller_managed',
                            'seller_id' => $sellerId,
                            'source_name' => $sellerChargeResult['seller_name'] ?? 'Seller',
                            'source_lat' => $sellerChargeResult['seller_lat'] ?? 0,
                            'source_lon' => $sellerChargeResult['seller_lon'] ?? 0,
                            'delivery_charge' => $sellerChargeResult['charge'],
                            'distance' => $sellerChargeResult['distance'] ?? 0,
                            'distance_text' => $sellerChargeResult['distance_text'] ?? '',
                            'duration' => $sellerChargeResult['duration'] ?? 0,
                            'duration_text' => $sellerChargeResult['duration_text'] ?? '',
                            'free_delivery' => $sellerChargeResult['free_delivery'] ?? false
                        ];
                        $totalDeliveryCharge += $sellerChargeResult['charge'];
                    } elseif ($sellerChargeResult['status'] == 0) {
                        return [
                            'status' => 0,
                            'message' => $sellerChargeResult['message'] ?? 'Unable to calculate delivery charge for seller'
                        ];
                    }
                }
            }

            return [
                'status' => 1,
                'data' => [
                    'total_delivery_charge' => round($totalDeliveryCharge, 2),
                    'delivery_charge' => round($totalDeliveryCharge, 2),
                    'delivery_charge_details' => $deliveryChargeDetails
                ]
            ];

        } catch (\Exception $e) {
            Log::error('CartDeliveryChargeService: Error calculating delivery charge for variants', [
                'user_id' => $userId,
                'product_variant_ids' => $productVariantIds,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'status' => 0,
                'message' => 'Error calculating delivery charge: ' . $e->getMessage()
            ];
        }
    }
}
