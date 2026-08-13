<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class RatingService
{
    /**
     * Get seller rating and rating count
     * If no ratings exist, return dummy rating between 4.0-5.0
     *
     * @param int $sellerId
     * @param int|null $storeId
     * @return array ['rating' => float, 'rating_count' => int]
     */
    public static function getSellerRating(int $sellerId, ?int $storeId = null): array
    {
        try {
            // Get product ratings for this seller only
            $query = DB::table('order_product_ratings')
                ->where('seller_id', $sellerId);

            $totalRatings = $query->count();

            if ($totalRatings > 0) {
                $avgRating = round($query->avg('rating'), 1);

                return [
                    'rating' => (float) $avgRating,
                    'rating_count' => $totalRatings
                ];
            }

            // No ratings exist - return dummy rating
            return self::getDummyRating();

        } catch (\Exception $e) {
            Log::error('RatingService::getSellerRating failed', [
                'seller_id' => $sellerId,
                'store_id' => $storeId,
                'error' => $e->getMessage()
            ]);

            // Return dummy rating on error
            return self::getDummyRating();
        }
    }

    /**
     * Get product rating and rating count
     * If no ratings exist, return dummy rating between 4.0-5.0
     *
     * @param int $productId
     * @return array ['rating' => float, 'rating_count' => int]
     */
    public static function getProductRating(int $productId): array
    {
        try {
            $query = DB::table('order_product_ratings')
                ->where('product_id', $productId);

            $totalRatings = $query->count();
            
            if ($totalRatings > 0) {
                $avgRating = round($query->avg('rating'), 1);
                
                return [
                    'rating' => (float) $avgRating,
                    'rating_count' => $totalRatings
                ];
            }

            // No ratings exist - return dummy rating
            return self::getDummyRating();

        } catch (\Exception $e) {
            Log::error('RatingService::getProductRating failed', [
                'product_id' => $productId,
                'error' => $e->getMessage()
            ]);

            // Return dummy rating on error
            return self::getDummyRating();
        }
    }

    /**
     * Get driver/delivery boy rating and rating count
     * If no ratings exist, return dummy rating between 4.0-5.0
     *
     * @param int $deliveryBoyId
     * @return array ['rating' => float, 'rating_count' => int]
     */
    public static function getDriverRating(int $deliveryBoyId): array
    {
        try {
            $query = DB::table('order_driver_ratings')
                ->where('delivery_boy_id', $deliveryBoyId);

            $totalRatings = $query->count();
            
            if ($totalRatings > 0) {
                $avgRating = round($query->avg('rating'), 1);
                
                return [
                    'rating' => (float) $avgRating,
                    'rating_count' => $totalRatings
                ];
            }

            // No ratings exist - return dummy rating
            return self::getDummyRating();

        } catch (\Exception $e) {
            Log::error('RatingService::getDriverRating failed', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            // Return dummy rating on error
            return self::getDummyRating();
        }
    }

    /**
     * Get ratings for multiple sellers at once (bulk operation)
     * More efficient than calling getSellerRating multiple times
     *
     * @param array $sellerIds
     * @return array [seller_id => ['rating' => float, 'rating_count' => int]]
     */
    public static function getBulkSellerRatings(array $sellerIds): array
    {
        if (empty($sellerIds)) {
            return [];
        }

        try {
            // Get all ratings for these sellers
            $ratings = DB::table('order_product_ratings')
                ->select('seller_id', DB::raw('AVG(rating) as avg_rating'), DB::raw('COUNT(*) as rating_count'))
                ->whereIn('seller_id', $sellerIds)
                ->groupBy('seller_id')
                ->get()
                ->keyBy('seller_id');

            $result = [];
            foreach ($sellerIds as $sellerId) {
                if (isset($ratings[$sellerId])) {
                    $result[$sellerId] = [
                        'rating' => round((float) $ratings[$sellerId]->avg_rating, 1),
                        'rating_count' => (int) $ratings[$sellerId]->rating_count
                    ];
                } else {
                    // No ratings - use dummy
                    $result[$sellerId] = self::getDummyRating();
                }
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('RatingService::getBulkSellerRatings failed', [
                'seller_ids' => $sellerIds,
                'error' => $e->getMessage()
            ]);

            // Return dummy ratings for all sellers on error
            $result = [];
            foreach ($sellerIds as $sellerId) {
                $result[$sellerId] = self::getDummyRating();
            }
            return $result;
        }
    }

    /**
     * Get ratings for multiple products at once (bulk operation)
     *
     * @param array $productIds
     * @return array [product_id => ['rating' => float, 'rating_count' => int]]
     */
    public static function getBulkProductRatings(array $productIds): array
    {
        if (empty($productIds)) {
            return [];
        }

        try {
            // Get all ratings for these products
            $ratings = DB::table('order_product_ratings')
                ->select('product_id', DB::raw('AVG(rating) as avg_rating'), DB::raw('COUNT(*) as rating_count'))
                ->whereIn('product_id', $productIds)
                ->groupBy('product_id')
                ->get()
                ->keyBy('product_id');

            $result = [];
            foreach ($productIds as $productId) {
                if (isset($ratings[$productId])) {
                    $result[$productId] = [
                        'rating' => round((float) $ratings[$productId]->avg_rating, 1),
                        'rating_count' => (int) $ratings[$productId]->rating_count
                    ];
                } else {
                    // No ratings - use dummy
                    $result[$productId] = self::getDummyRating();
                }
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('RatingService::getBulkProductRatings failed', [
                'product_ids' => $productIds,
                'error' => $e->getMessage()
            ]);

            // Return dummy ratings for all products on error
            $result = [];
            foreach ($productIds as $productId) {
                $result[$productId] = self::getDummyRating();
            }
            return $result;
        }
    }

    /**
     * Get ratings for multiple categories at once (based on products in those categories)
     *
     * @param array $categoryIds
     * @return array [category_id => ['rating' => float, 'rating_count' => int]]
     */
    public static function getBulkCategoryRatings(array $categoryIds): array
    {
        if (empty($categoryIds)) {
            return [];
        }

        try {
            $ratings = DB::table('order_product_ratings')
                ->join('products', 'products.id', '=', 'order_product_ratings.product_id')
                ->whereIn('products.category_id', $categoryIds)
                ->select('products.category_id', DB::raw('AVG(order_product_ratings.rating) as avg_rating'), DB::raw('COUNT(*) as rating_count'))
                ->groupBy('products.category_id')
                ->get()
                ->keyBy('category_id');

            $result = [];
            foreach ($categoryIds as $categoryId) {
                if (isset($ratings[$categoryId])) {
                    $result[$categoryId] = [
                        'rating' => round((float) $ratings[$categoryId]->avg_rating, 1),
                        'rating_count' => (int) $ratings[$categoryId]->rating_count
                    ];
                } else {
                    $result[$categoryId] = self::getDummyRating();
                }
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('RatingService::getBulkCategoryRatings failed', [
                'category_ids' => $categoryIds,
                'error' => $e->getMessage()
            ]);

            $result = [];
            foreach ($categoryIds as $categoryId) {
                $result[$categoryId] = self::getDummyRating();
            }
            return $result;
        }
    }

    /**
     * Get ratings for multiple drivers at once (bulk operation)
     *
     * @param array $deliveryBoyIds
     * @return array [delivery_boy_id => ['rating' => float, 'rating_count' => int]]
     */
    public static function getBulkDriverRatings(array $deliveryBoyIds): array
    {
        if (empty($deliveryBoyIds)) {
            return [];
        }

        try {
            // Get all ratings for these drivers
            $ratings = DB::table('order_driver_ratings')
                ->select('delivery_boy_id', DB::raw('AVG(rating) as avg_rating'), DB::raw('COUNT(*) as rating_count'))
                ->whereIn('delivery_boy_id', $deliveryBoyIds)
                ->groupBy('delivery_boy_id')
                ->get()
                ->keyBy('delivery_boy_id');

            $result = [];
            foreach ($deliveryBoyIds as $deliveryBoyId) {
                if (isset($ratings[$deliveryBoyId])) {
                    $result[$deliveryBoyId] = [
                        'rating' => round((float) $ratings[$deliveryBoyId]->avg_rating, 1),
                        'rating_count' => (int) $ratings[$deliveryBoyId]->rating_count
                    ];
                } else {
                    // No ratings - use dummy
                    $result[$deliveryBoyId] = self::getDummyRating();
                }
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('RatingService::getBulkDriverRatings failed', [
                'delivery_boy_ids' => $deliveryBoyIds,
                'error' => $e->getMessage()
            ]);

            // Return dummy ratings for all drivers on error
            $result = [];
            foreach ($deliveryBoyIds as $deliveryBoyId) {
                $result[$deliveryBoyId] = self::getDummyRating();
            }
            return $result;
        }
    }

    /**
     * Generate a dummy rating between 4.0 and 5.0 with a middle average
     * Returns a consistent dummy rating for better UX
     *
     * @return array ['rating' => float, 'rating_count' => int]
     */
    private static function getDummyRating(): array
    {
        // Generate rating between 4.0 and 5.0 with preference for middle values (4.3-4.7)
        // Using a weighted random approach
        $rand = mt_rand(0, 100);
        
        if ($rand < 20) {
            // 20% chance: 4.0 - 4.2
            $rating = round(mt_rand(40, 42) / 10, 1);
        } elseif ($rand < 80) {
            // 60% chance: 4.3 - 4.7 (middle average)
            $rating = round(mt_rand(43, 47) / 10, 1);
        } else {
            // 20% chance: 4.8 - 5.0
            $rating = round(mt_rand(48, 50) / 10, 1);
        }

        // Generate rating count between 50 and 500
        $ratingCount = mt_rand(50, 500);

        return [
            'rating' => $rating,
            'rating_count' => $ratingCount
        ];
    }

    /**
     * Check if seller has any real ratings
     *
     * @param int $sellerId
     * @param int|null $storeId
     * @return bool
     */
    public static function sellerHasRatings(int $sellerId, ?int $storeId = null): bool
    {
        try {
            $count = DB::table('order_product_ratings')
                ->where('seller_id', $sellerId)
                ->count();

            return $count > 0;

        } catch (\Exception $e) {
            Log::error('RatingService::sellerHasRatings failed', [
                'seller_id' => $sellerId,
                'store_id' => $storeId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Check if product has any real ratings
     *
     * @param int $productId
     * @return bool
     */
    public static function productHasRatings(int $productId): bool
    {
        try {
            $count = DB::table('order_product_ratings')
                ->where('product_id', $productId)
                ->count();

            return $count > 0;

        } catch (\Exception $e) {
            Log::error('RatingService::productHasRatings failed', [
                'product_id' => $productId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Check if driver has any real ratings
     *
     * @param int $deliveryBoyId
     * @return bool
     */
    public static function driverHasRatings(int $deliveryBoyId): bool
    {
        try {
            $count = DB::table('order_driver_ratings')
                ->where('delivery_boy_id', $deliveryBoyId)
                ->count();

            return $count > 0;

        } catch (\Exception $e) {
            Log::error('RatingService::driverHasRatings failed', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }
}
