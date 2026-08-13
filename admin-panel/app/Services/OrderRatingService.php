<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderRatingService
{
    /**
     * Get seller-wise items for a given order
     *
     * @param int $orderId
     * @param int $userId
     * @return array
     */
    public static function getSellerWiseItems(int $orderId, int $userId): array
    {
        try {
            // Verify order belongs to this customer
            $order = DB::table('orders')
                ->leftJoin('delivery_boys', 'orders.delivery_boy_id', '=', 'delivery_boys.id')
                ->where('orders.id', $orderId)
                ->where('orders.user_id', $userId)
                ->select('orders.*', 'delivery_boys.id as db_id', 'delivery_boys.name as db_name', 'delivery_boys.profile_image as db_profile_image')
                ->first();

            if (!$order) {
                return ['success' => false, 'message' => 'Order not found', 'code' => 404];
            }

            // Get sellers from order_seller_status_tracking
            $sellerLocations = self::getSellersForOrder($orderId, $order);

            if (empty($sellerLocations)) {
                return ['success' => false, 'message' => 'No sellers found for this order', 'code' => 404];
            }

            // Get items grouped by store_id
            $storeItems = self::getItemsGroupedByStore($orderId);

            // Build seller-wise response
            $sellers = [];
            foreach ($sellerLocations as $seller) {
                $storeId = $seller['store_id'];
                $items = isset($storeItems[$storeId]) ? array_values($storeItems[$storeId]) : [];

                $sellers[] = [
                    'seller_id' => $seller['seller_id'],
                    'store_id' => $storeId,
                    'store_name' => $seller['store_name'],
                    'seller_name' => $seller['seller_name'],
                    'seller_logo' => $seller['seller_logo'],
                    'is_zenfoo_store' => $seller['is_zenfoo_store'],
                    'items' => $items,
                    'item_count' => count($items),
                ];
            }

            return [
                'success' => true,
                'data' => [
                    'order_id' => $orderId,
                    'delivery_boy' => [
                        'id' => $order->db_id ? (int) $order->db_id : null,
                        'name' => $order->db_name,
                        'profile_image' => $order->db_profile_image ?: null,
                    ],
                    'seller_count' => count($sellers),
                    'sellers' => $sellers,
                ]
            ];

        } catch (\Exception $e) {
            Log::error('OrderRatingService::getSellerWiseItems failed', [
                'order_id' => $orderId,
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return ['success' => false, 'message' => 'Something went wrong', 'code' => 500];
        }
    }

    /**
     * Get sellers involved in an order
     */
    private static function getSellersForOrder(int $orderId, object $order): array
    {
        $sellerLocations = [];

        // Get sellers from order_seller_status_tracking
        $sellerIds = DB::table('order_seller_status_tracking')
            ->where('order_id', $orderId)
            ->pluck('seller_id')
            ->filter()
            ->toArray();

        if (!empty($sellerIds)) {
            $sellers = DB::table('sellers')
                ->leftJoin('stores', 'sellers.store_id', '=', 'stores.id')
                ->whereIn('sellers.id', $sellerIds)
                ->select('sellers.id', 'sellers.store_id', 'sellers.store_name', 'sellers.store_location', 'sellers.logo', 'sellers.name as seller_name', 'stores.name as store_table_name')
                ->get();

            foreach ($sellers as $seller) {
                $sellerLocations[] = [
                    'seller_id' => $seller->id,
                    'store_id' => $seller->store_id ? (int) $seller->store_id : null,
                    'is_zenfoo_store' => false,
                    'store_name' => $seller->store_table_name ?? $seller->store_name,
                    'seller_name' => $seller->seller_name,
                    'seller_logo' => $seller->logo ?: null,
                ];
            }
        }

        // Check for Zenfoo store products (store_id = 12)
        $zenfooStoreId = 12;
        $hasZenfooProducts = DB::table('order_items')
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->where('order_items.order_id', $orderId)
            ->where('products.store_id', $zenfooStoreId)
            ->exists();

        if ($hasZenfooProducts) {
            $storeLocation = DB::table('store_locations')
                ->join('user_addresses', function ($join) use ($order) {
                    $join->on('store_locations.city_id', '=', 'user_addresses.city_id');
                })
                ->where('user_addresses.id', $order->address_id)
                ->where('store_locations.status', 1)
                ->select('store_locations.name')
                ->first();

            $sellerLocations[] = [
                'seller_id' => null,
                'store_id' => $zenfooStoreId,
                'is_zenfoo_store' => true,
                'store_name' => $storeLocation->name ?? 'Zenfoo Store',
                'seller_name' => 'Zenfoo',
                'seller_logo' => asset('images/logo.png'),
            ];
        }

        return $sellerLocations;
    }

    /**
     * Get seller-wise items with customer's existing ratings/reviews
     */
    public static function getOrderRatings(int $orderId, int $userId): array
    {
        try {
            $order = DB::table('orders')
                ->leftJoin('delivery_boys', 'orders.delivery_boy_id', '=', 'delivery_boys.id')
                ->where('orders.id', $orderId)
                ->where('orders.user_id', $userId)
                ->select('orders.*', 'delivery_boys.id as db_id', 'delivery_boys.name as db_name', 'delivery_boys.profile_image as db_profile_image')
                ->first();

            if (!$order) {
                return ['success' => false, 'message' => 'Order not found', 'code' => 404];
            }

            $sellerLocations = self::getSellersForOrder($orderId, $order);

            if (empty($sellerLocations)) {
                return ['success' => false, 'message' => 'No sellers found for this order', 'code' => 404];
            }

            $storeItems = self::getItemsGroupedByStore($orderId);

            // Fetch existing product ratings for this order + user
            $productRatings = DB::table('order_product_ratings')
                ->where('order_id', $orderId)
                ->where('user_id', $userId)
                ->get()
                ->keyBy('product_id');

            // Fetch existing seller reviews for this order + user
            $sellerReviews = DB::table('order_seller_reviews')
                ->where('order_id', $orderId)
                ->where('user_id', $userId)
                ->get()
                ->keyBy('store_id');

            // Fetch existing driver rating for this order + user
            $driverRating = DB::table('order_driver_ratings')
                ->where('order_id', $orderId)
                ->where('user_id', $userId)
                ->first();

            // Build seller-wise response with ratings
            $sellers = [];
            foreach ($sellerLocations as $seller) {
                $storeId = $seller['store_id'];
                $rawItems = isset($storeItems[$storeId]) ? $storeItems[$storeId] : [];

                $items = [];
                foreach ($rawItems as $item) {
                    $existingRating = $productRatings->get($item['product_id'] ?? null);
                    $items[] = [
                        'product_id' => $item['product_id'] ?? null,
                        'item_name' => $item['item_name'],
                        'quantity' => $item['quantity'],
                        'measurement' => $item['measurement'],
                        'rating' => $existingRating ? (int) $existingRating->rating : null,
                    ];
                }

                $existingReview = $sellerReviews->get($storeId);

                $sellers[] = [
                    'seller_id' => $seller['seller_id'],
                    'store_id' => $storeId,
                    'store_name' => $seller['store_name'],
                    'seller_name' => $seller['seller_name'],
                    'seller_logo' => $seller['seller_logo'],
                    'is_zenfoo_store' => $seller['is_zenfoo_store'],
                    'review' => $existingReview->review ?? null,
                    'items' => $items,
                    'item_count' => count($items),
                ];
            }

            return [
                'success' => true,
                'data' => [
                    'order_id' => $orderId,
                    'delivery_boy' => [
                        'id' => $order->db_id ? (int) $order->db_id : null,
                        'name' => $order->db_name,
                        'profile_image' => $order->db_profile_image ?: null,
                        'rating' => $driverRating ? (int) $driverRating->rating : null,
                        'review' => $driverRating->review ?? null,
                    ],
                    'seller_count' => count($sellers),
                    'sellers' => $sellers,
                ]
            ];

        } catch (\Exception $e) {
            Log::error('OrderRatingService::getOrderRatings failed', [
                'order_id' => $orderId,
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return ['success' => false, 'message' => 'Something went wrong', 'code' => 500];
        }
    }

    /**
     * Submit rating/review for a product, seller, or driver
     *
     * @param int $orderId
     * @param int $userId
     * @param string $type  'product', 'seller', or 'driver'
     * @param array $data
     * @return array
     */
    public static function submitRating(int $orderId, int $userId, string $type, array $data): array
    {
        try {
            $order = DB::table('orders')->where('id', $orderId)->where('user_id', $userId)->first();
            if (!$order) {
                return ['success' => false, 'message' => 'Order not found', 'code' => 404];
            }

            if ($type === 'product') {
                return self::submitProductRating($orderId, $userId, $data);
            } elseif ($type === 'seller') {
                return self::submitSellerReview($orderId, $userId, $data);
            } elseif ($type === 'driver') {
                return self::submitDriverRating($orderId, $userId, $order, $data);
            }

            return ['success' => false, 'message' => 'Invalid type. Use product, seller or driver', 'code' => 400];

        } catch (\Exception $e) {
            Log::error('OrderRatingService::submitRating failed', [
                'order_id' => $orderId,
                'user_id' => $userId,
                'type' => $type,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return ['success' => false, 'message' => 'Something went wrong', 'code' => 500];
        }
    }

    /**
     * Submit product rating (rating only, no review)
     */
    private static function submitProductRating(int $orderId, int $userId, array $data): array
    {
        $productId = $data['product_id'];

        $product = DB::table('products')->where('id', $productId)->first();
        if (!$product) {
            return ['success' => false, 'message' => 'Product not found', 'code' => 404];
        }

        $seller = DB::table('sellers')->where('store_id', $product->store_id)->first();

        DB::table('order_product_ratings')
            ->updateOrInsert(
                [
                    'order_id' => $orderId,
                    'user_id' => $userId,
                    'product_id' => $productId,
                ],
                [
                    'seller_id' => $seller->id ?? null,
                    'store_id' => $product->store_id,
                    'rating' => $data['rating'],
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );

        return [
            'success' => true,
            'message' => 'Product rating submitted successfully',
        ];
    }

    /**
     * Submit seller review (review only, no rating)
     */
    private static function submitSellerReview(int $orderId, int $userId, array $data): array
    {
        $storeId = $data['store_id'];

        $seller = DB::table('sellers')->where('store_id', $storeId)->first();

        DB::table('order_seller_reviews')
            ->updateOrInsert(
                [
                    'order_id' => $orderId,
                    'user_id' => $userId,
                    'store_id' => $storeId,
                ],
                [
                    'seller_id' => $seller->id ?? null,
                    'review' => $data['review'],
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );

        return [
            'success' => true,
            'message' => 'Seller review submitted successfully',
        ];
    }

    /**
     * Submit driver rating (rating + optional review)
     */
    private static function submitDriverRating(int $orderId, int $userId, object $order, array $data): array
    {
        if (empty($order->delivery_boy_id)) {
            return ['success' => false, 'message' => 'No delivery boy assigned to this order', 'code' => 400];
        }

        DB::table('order_driver_ratings')
            ->updateOrInsert(
                [
                    'order_id' => $orderId,
                    'user_id' => $userId,
                ],
                [
                    'delivery_boy_id' => $order->delivery_boy_id,
                    'rating' => $data['rating'],
                    'review' => $data['review'] ?? null,
                    'updated_at' => now(),
                    'created_at' => now(),
                ]
            );

        return [
            'success' => true,
            'message' => 'Driver rating submitted successfully',
        ];
    }

    /**
     * Get order items (regular + combo) grouped by store_id
     */
    private static function getItemsGroupedByStore(int $orderId): array
    {
        $storeItems = [];

        // Regular order items
        $orderItems = DB::table('order_items')
            ->select(
                'order_items.quantity',
                'order_items.product_variant_id',
                'products.id as product_id',
                'products.name as product_name',
                'products.store_id',
                'product_variants.measurement',
                'units.short_code as unit_short_code'
            )
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
            ->where('order_items.order_id', $orderId)
            ->get();

        foreach ($orderItems as $item) {
            $storeId = $item->store_id;
            $key = $storeId . '_' . $item->product_id . '_' . $item->product_variant_id;
            $measurementDisplay = $item->measurement . ' ' . ($item->unit_short_code ?? '');

            if (!isset($storeItems[$storeId])) {
                $storeItems[$storeId] = [];
            }

            if (isset($storeItems[$storeId][$key])) {
                $storeItems[$storeId][$key]['quantity'] += $item->quantity;
            } else {
                $storeItems[$storeId][$key] = [
                    'product_id' => (int) $item->product_id,
                    'item_name' => $item->product_name,
                    'quantity' => (int) $item->quantity,
                    'measurement' => trim($measurementDisplay),
                ];
            }
        }

        // Combo items
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
                    foreach ($products as $product) {
                        $productId = $product['product_id'] ?? null;
                        $variantId = $product['variant_id'] ?? null;

                        if ($productId) {
                            $productDetail = DB::table('products')->where('id', $productId)->first();
                            $storeId = $productDetail->store_id ?? null;

                            $variantDetail = null;
                            if ($variantId) {
                                $variantDetail = DB::table('product_variants')
                                    ->select('product_variants.measurement', 'units.short_code as unit_short_code')
                                    ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                                    ->where('product_variants.id', $variantId)
                                    ->first();
                            }

                            $key = $storeId . '_' . $productId . '_' . $variantId;
                            $qty = $product['quantity'] ?? 1;
                            $measurement = $variantDetail->measurement ?? ($product['variant_measurement'] ?? '');
                            $unit = $variantDetail->unit_short_code ?? '';
                            $measurementDisplay = $measurement . ' ' . $unit;

                            if (!isset($storeItems[$storeId])) {
                                $storeItems[$storeId] = [];
                            }

                            if (isset($storeItems[$storeId][$key])) {
                                $storeItems[$storeId][$key]['quantity'] += $qty;
                            } else {
                                $storeItems[$storeId][$key] = [
                                    'product_id' => (int) $productId,
                                    'item_name' => $product['product_name'] ?? $productDetail->name ?? '',
                                    'quantity' => (int) $qty,
                                    'measurement' => trim($measurementDisplay),
                                ];
                            }
                        }
                    }
                }
            }
        }

        return $storeItems;
    }

    /**
     * Get ratings and reviews received by a seller
     *
     * @param int $sellerId
     * @param int|null $storeId
     * @return array
     */
    public static function getSellerRatings(int $sellerId, ?int $storeId, int $page = 1, int $perPage = 15): array
    {
        try {
            // Scope strictly to this seller. (Previously OR'd on store_id, which
            // leaked other sellers' reviews to anyone sharing the same store.)
            $productRatingsQuery = DB::table('order_product_ratings')
                ->where('seller_id', $sellerId);

            $totalRatings = $productRatingsQuery->count();
            $avgRating = $totalRatings > 0 ? round($productRatingsQuery->avg('rating'), 1) : 0;

            // Star distribution
            $starCounts = [];
            for ($i = 5; $i >= 1; $i--) {
                $starCounts[$i . '_star'] = DB::table('order_product_ratings')
                    ->where('seller_id', $sellerId)
                    ->where('rating', $i)
                    ->count();
            }

            // Get seller reviews with customer details + avg product rating per order (paginated)
            $reviewsPaginated = DB::table('order_seller_reviews')
                ->leftJoin('users', 'order_seller_reviews.user_id', '=', 'users.id')
                ->where('order_seller_reviews.seller_id', $sellerId)
                ->select(
                    'order_seller_reviews.id',
                    'order_seller_reviews.order_id',
                    'order_seller_reviews.review',
                    'order_seller_reviews.user_id as customer_id',
                    'users.name as customer_name',
                    'users.profile as customer_profile',
                    'order_seller_reviews.created_at'
                )
                ->orderBy('order_seller_reviews.created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            // Attach avg product rating from each order to the review
            $reviews = collect($reviewsPaginated->items());
            foreach ($reviews as $review) {
                $orderAvg = DB::table('order_product_ratings')
                    ->where('order_id', $review->order_id)
                    ->where('seller_id', $sellerId)
                    ->avg('rating');

                $review->avg_order_rating = $orderAvg ? round((float) $orderAvg, 1) : null;
            }

            return [
                'success' => true,
                'data' => [
                    'avg_rating' => $avgRating,
                    'total_ratings' => $totalRatings,
                    'star_counts' => $starCounts,
                    'reviews' => $reviews->values(),
                    'pagination' => [
                        'current_page' => $reviewsPaginated->currentPage(),
                        'per_page' => $reviewsPaginated->perPage(),
                        'total' => $reviewsPaginated->total(),
                        'last_page' => $reviewsPaginated->lastPage(),
                    ]
                ]
            ];

        } catch (\Exception $e) {
            Log::error('OrderRatingService::getSellerRatings failed', [
                'seller_id' => $sellerId,
                'store_id' => $storeId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return ['success' => false, 'message' => 'Something went wrong', 'code' => 500];
        }
    }

    /**
     * Get order-wise product ratings for a seller (with pagination)
     *
     * @param int $sellerId
     * @param int|null $storeId
     * @param int $page
     * @param int $perPage
     * @return array
     */
    public static function getSellerProductRatings(int $sellerId, ?int $storeId, int $page = 1, int $perPage = 15): array
    {
        try {
            // Get product ratings grouped by order with pagination
            $ratings = DB::table('order_product_ratings')
                ->leftJoin('users', 'order_product_ratings.user_id', '=', 'users.id')
                ->leftJoin('products', 'order_product_ratings.product_id', '=', 'products.id')
                ->where('order_product_ratings.seller_id', $sellerId)
                ->select(
                    'order_product_ratings.id',
                    'order_product_ratings.order_id',
                    'order_product_ratings.product_id',
                    'products.name as product_name',
                    'order_product_ratings.rating',
                    'order_product_ratings.user_id as customer_id',
                    'users.name as customer_name',
                    'users.profile as customer_profile',
                    'order_product_ratings.created_at'
                )
                ->orderBy('order_product_ratings.created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            return [
                'success' => true,
                'data' => [
                    'product_ratings' => $ratings->items(),
                    'pagination' => [
                        'current_page' => $ratings->currentPage(),
                        'per_page' => $ratings->perPage(),
                        'total' => $ratings->total(),
                        'last_page' => $ratings->lastPage(),
                    ]
                ]
            ];

        } catch (\Exception $e) {
            Log::error('OrderRatingService::getSellerProductRatings failed', [
                'seller_id' => $sellerId,
                'store_id' => $storeId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return ['success' => false, 'message' => 'Something went wrong', 'code' => 500];
        }
    }

    /**
     * Get ratings and reviews received by a delivery boy
     *
     * @param int $deliveryBoyId
     * @return array
     */
    public static function getDriverRatings(int $deliveryBoyId, int $page = 1, int $perPage = 15): array
    {
        try {
            $ratingsQuery = DB::table('order_driver_ratings')
                ->where('delivery_boy_id', $deliveryBoyId);

            $totalRatings = $ratingsQuery->count();
            $avgRating = $totalRatings > 0 ? round($ratingsQuery->avg('rating'), 1) : 0;

            // Star distribution
            $starCounts = [];
            for ($i = 5; $i >= 1; $i--) {
                $starCounts[$i . '_star'] = DB::table('order_driver_ratings')
                    ->where('delivery_boy_id', $deliveryBoyId)
                    ->where('rating', $i)
                    ->count();
            }

            // Get ratings with customer details (paginated)
            $ratingsPaginated = DB::table('order_driver_ratings')
                ->leftJoin('users', 'order_driver_ratings.user_id', '=', 'users.id')
                ->where('order_driver_ratings.delivery_boy_id', $deliveryBoyId)
                ->select(
                    'order_driver_ratings.id',
                    'order_driver_ratings.order_id',
                    'order_driver_ratings.rating',
                    'order_driver_ratings.review',
                    'order_driver_ratings.user_id as customer_id',
                    'users.name as customer_name',
                    'users.profile as customer_profile',
                    'order_driver_ratings.created_at'
                )
                ->orderBy('order_driver_ratings.created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            return [
                'success' => true,
                'data' => [
                    'avg_rating' => $avgRating,
                    'total_ratings' => $totalRatings,
                    'star_counts' => $starCounts,
                    'ratings' => $ratingsPaginated->items(),
                    'pagination' => [
                        'current_page' => $ratingsPaginated->currentPage(),
                        'per_page' => $ratingsPaginated->perPage(),
                        'total' => $ratingsPaginated->total(),
                        'last_page' => $ratingsPaginated->lastPage(),
                    ]
                ]
            ];

        } catch (\Exception $e) {
            Log::error('OrderRatingService::getDriverRatings failed', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return ['success' => false, 'message' => 'Something went wrong', 'code' => 500];
        }
    }
}