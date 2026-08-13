<?php

namespace App\Services;

use Illuminate\Support\Collection;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SellerFilterService
{
    /**
     * Available sort options
     */
    const SORT_DISTANCE = 'distance';
    const SORT_RATING = 'rating';
    const SORT_PRICE_LOW_TO_HIGH = 'price_low_to_high';
    const SORT_PRICE_HIGH_TO_LOW = 'price_high_to_low';
    const SORT_NAME = 'name';

    /**
     * Food type filter options
     * Based on products.indicator column: 1 = veg, 2 = non-veg
     */
    const FOOD_TYPE_ALL = 'all';
    const FOOD_TYPE_VEG = 'veg';
    const FOOD_TYPE_NON_VEG = 'non_veg';

    /**
     * Product indicator values
     */
    const INDICATOR_VEG = 1;
    const INDICATOR_NON_VEG = 2;

    /**
     * Apply sorting to sellers collection
     *
     * @param Collection $sellers
     * @param string $sortBy
     * @return Collection
     */
    public static function applySorting(Collection $sellers, string $sortBy): Collection
    {
        Log::info('SellerFilterService::applySorting - Started', [
            'sort_by' => $sortBy,
            'sellers_count' => $sellers->count(),
            'seller_ids' => $sellers->pluck('id')->toArray(),
        ]);

        $result = collect([]);

        switch ($sortBy) {
            case self::SORT_PRICE_LOW_TO_HIGH:
                Log::info('SellerFilterService::applySorting - Applying price_low_to_high sort');
                $result = self::sortByPriceLowToHigh($sellers);
                break;

            case self::SORT_PRICE_HIGH_TO_LOW:
                Log::info('SellerFilterService::applySorting - Applying price_high_to_low sort');
                $result = self::sortByPriceHighToLow($sellers);
                break;

            case self::SORT_RATING:
                Log::info('SellerFilterService::applySorting - Applying rating sort');
                $result = $sellers->sortByDesc('rating')->values();
                break;

            case self::SORT_NAME:
                Log::info('SellerFilterService::applySorting - Applying name sort');
                $result = $sellers->sortBy('store_name')->values();
                break;

            case self::SORT_DISTANCE:
            default:
                Log::info('SellerFilterService::applySorting - Applying distance sort (default)');
                $result = self::sortByDistance($sellers);
                break;
        }

        Log::info('SellerFilterService::applySorting - Completed', [
            'sort_by' => $sortBy,
            'sorted_seller_ids' => $result->pluck('id')->toArray(),
        ]);

        return $result;
    }

    /**
     * Sort sellers by minimum product price (low to high)
     *
     * @param Collection $sellers
     * @return Collection
     */
    public static function sortByPriceLowToHigh(Collection $sellers): Collection
    {
        $sellerIds = $sellers->pluck('id')->toArray();

        Log::info('SellerFilterService::sortByPriceLowToHigh - Fetching min prices', [
            'seller_ids' => $sellerIds,
        ]);

        // Get minimum price for each seller
        $sellerMinPrices = self::getSellerMinPrices($sellerIds);

        Log::info('SellerFilterService::sortByPriceLowToHigh - Min prices fetched', [
            'seller_min_prices' => $sellerMinPrices,
        ]);

        // Attach min_price to each seller
        $sellers = $sellers->map(function ($seller) use ($sellerMinPrices) {
            $seller->min_price = $sellerMinPrices[$seller->id] ?? PHP_INT_MAX;
            return $seller;
        });

        // Sort by min_price ascending (sellers without products go to end)
        $sorted = $sellers->sortBy('min_price')->values();

        Log::info('SellerFilterService::sortByPriceLowToHigh - Sorting completed', [
            'sorted_order' => $sorted->map(function ($s) {
                return [
                    'id' => $s->id,
                    'store_name' => $s->store_name,
                    'min_price' => $s->min_price ?? 'N/A',
                ];
            })->toArray(),
        ]);

        return $sorted;
    }

    /**
     * Sort sellers by minimum product price (high to low)
     *
     * @param Collection $sellers
     * @return Collection
     */
    public static function sortByPriceHighToLow(Collection $sellers): Collection
    {
        $sellerIds = $sellers->pluck('id')->toArray();

        Log::info('SellerFilterService::sortByPriceHighToLow - Fetching min prices', [
            'seller_ids' => $sellerIds,
        ]);

        // Get minimum price for each seller
        $sellerMinPrices = self::getSellerMinPrices($sellerIds);

        Log::info('SellerFilterService::sortByPriceHighToLow - Min prices fetched', [
            'seller_min_prices' => $sellerMinPrices,
        ]);

        // Attach min_price to each seller
        $sellers = $sellers->map(function ($seller) use ($sellerMinPrices) {
            $seller->min_price = $sellerMinPrices[$seller->id] ?? 0;
            return $seller;
        });

        // Sort by min_price descending
        $sorted = $sellers->sortByDesc('min_price')->values();

        Log::info('SellerFilterService::sortByPriceHighToLow - Sorting completed', [
            'sorted_order' => $sorted->map(function ($s) {
                return [
                    'id' => $s->id,
                    'store_name' => $s->store_name,
                    'min_price' => $s->min_price ?? 'N/A',
                ];
            })->toArray(),
        ]);

        return $sorted;
    }

    /**
     * Sort sellers by distance
     *
     * @param Collection $sellers
     * @return Collection
     */
    public static function sortByDistance(Collection $sellers): Collection
    {
        Log::info('SellerFilterService::sortByDistance - Starting distance sort', [
            'sellers_with_distance' => $sellers->map(function ($s) {
                return [
                    'id' => $s->id,
                    'store_name' => $s->store_name,
                    'distance_km' => $s->distance_km ?? 'N/A',
                ];
            })->toArray(),
        ]);

        $sorted = $sellers->sortBy(function ($seller) {
            // Extract numeric value from distance_km string (e.g., "33.37 km" -> 33.37)
            if ($seller->distance_km === null) {
                return PHP_INT_MAX;
            }
            return (float) preg_replace('/[^0-9.]/', '', $seller->distance_km);
        })->values();

        Log::info('SellerFilterService::sortByDistance - Sorting completed', [
            'sorted_order' => $sorted->map(function ($s) {
                return [
                    'id' => $s->id,
                    'store_name' => $s->store_name,
                    'distance_km' => $s->distance_km ?? 'N/A',
                ];
            })->toArray(),
        ]);

        return $sorted;
    }

    /**
     * Get minimum product prices for given seller IDs
     *
     * @param array $sellerIds
     * @return array [seller_id => min_price]
     */
    private static function getSellerMinPrices(array $sellerIds): array
    {
        if (empty($sellerIds)) {
            Log::warning('SellerFilterService::getSellerMinPrices - Empty seller IDs provided');
            return [];
        }

        Log::info('SellerFilterService::getSellerMinPrices - Querying database', [
            'seller_ids' => $sellerIds,
        ]);

        // Get minimum discounted_price (or price if no discount) for each seller
        $query = ProductVariant::select('products.seller_id')
            ->selectRaw('MIN(CASE WHEN product_variants.discounted_price > 0 THEN product_variants.discounted_price ELSE product_variants.price END) as min_price')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->whereIn('products.seller_id', $sellerIds)
            ->where('products.status', 1)
            ->where('products.is_approved', 1)
            ->groupBy('products.seller_id');

        // Log the SQL query
        Log::info('SellerFilterService::getSellerMinPrices - SQL Query', [
            'sql' => $query->toSql(),
            'bindings' => $query->getBindings(),
        ]);

        $results = $query->get();

        $prices = [];
        foreach ($results as $result) {
            $prices[$result->seller_id] = (float) $result->min_price;
        }

        Log::info('SellerFilterService::getSellerMinPrices - Query completed', [
            'results_count' => count($prices),
            'prices' => $prices,
        ]);

        return $prices;
    }

    /**
     * Get average product prices for given seller IDs
     *
     * @param array $sellerIds
     * @return array [seller_id => avg_price]
     */
    public static function getSellerAvgPrices(array $sellerIds): array
    {
        if (empty($sellerIds)) {
            Log::warning('SellerFilterService::getSellerAvgPrices - Empty seller IDs provided');
            return [];
        }

        Log::info('SellerFilterService::getSellerAvgPrices - Querying database', [
            'seller_ids' => $sellerIds,
        ]);

        $query = ProductVariant::select('products.seller_id')
            ->selectRaw('AVG(CASE WHEN product_variants.discounted_price > 0 THEN product_variants.discounted_price ELSE product_variants.price END) as avg_price')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->whereIn('products.seller_id', $sellerIds)
            ->where('products.status', 1)
            ->where('products.is_approved', 1)
            ->groupBy('products.seller_id');

        // Log the SQL query
        Log::info('SellerFilterService::getSellerAvgPrices - SQL Query', [
            'sql' => $query->toSql(),
            'bindings' => $query->getBindings(),
        ]);

        $results = $query->get();

        $prices = [];
        foreach ($results as $result) {
            $prices[$result->seller_id] = round((float) $result->avg_price, 2);
        }

        Log::info('SellerFilterService::getSellerAvgPrices - Query completed', [
            'results_count' => count($prices),
            'prices' => $prices,
        ]);

        return $prices;
    }

    /**
     * Apply food type filter to sellers collection
     * - Veg seller: ALL products have indicator = 1
     * - Non-veg seller: At least one product has indicator = 2
     *
     * @param Collection $sellers
     * @param string $foodType
     * @return Collection
     */
    public static function applyFoodTypeFilter(Collection $sellers, string $foodType): Collection
    {
        Log::info('SellerFilterService::applyFoodTypeFilter - Started', [
            'food_type' => $foodType,
            'sellers_count' => $sellers->count(),
            'seller_ids' => $sellers->pluck('id')->toArray(),
        ]);

        // If 'all' or empty, return all sellers
        if (empty($foodType) || $foodType === self::FOOD_TYPE_ALL) {
            Log::info('SellerFilterService::applyFoodTypeFilter - No filter applied (all)');
            return $sellers;
        }

        $sellerIds = $sellers->pluck('id')->toArray();

        if (empty($sellerIds)) {
            Log::info('SellerFilterService::applyFoodTypeFilter - No sellers to filter');
            return $sellers;
        }

        // Get food type for each seller
        $sellerFoodTypes = self::getSellerFoodTypes($sellerIds);

        Log::info('SellerFilterService::applyFoodTypeFilter - Seller food types', [
            'seller_food_types' => $sellerFoodTypes,
        ]);

        // Attach food_type to each seller and filter
        $filtered = $sellers->filter(function ($seller) use ($sellerFoodTypes, $foodType) {
            $sellerFoodType = $sellerFoodTypes[$seller->id] ?? null;

            // If seller has no products, exclude from filtered results
            if ($sellerFoodType === null) {
                return false;
            }

            return $sellerFoodType === $foodType;
        })->values();

        Log::info('SellerFilterService::applyFoodTypeFilter - Completed', [
            'food_type' => $foodType,
            'filtered_count' => $filtered->count(),
            'filtered_seller_ids' => $filtered->pluck('id')->toArray(),
        ]);

        return $filtered;
    }

    /**
     * Get food type for each seller based on their products
     * - Veg: ALL products have indicator = 1
     * - Non-veg: At least one product has indicator = 2
     *
     * @param array $sellerIds
     * @return array [seller_id => 'veg'|'non_veg']
     */
    public static function getSellerFoodTypes(array $sellerIds): array
    {
        if (empty($sellerIds)) {
            Log::warning('SellerFilterService::getSellerFoodTypes - Empty seller IDs provided');
            return [];
        }

        Log::info('SellerFilterService::getSellerFoodTypes - Querying database', [
            'seller_ids' => $sellerIds,
        ]);

        // Query to check if seller has any non-veg products (indicator = 2)
        $query = Product::select('seller_id')
            ->selectRaw('MAX(CASE WHEN indicator = ' . self::INDICATOR_NON_VEG . ' THEN 1 ELSE 0 END) as has_non_veg')
            ->selectRaw('COUNT(*) as product_count')
            ->whereIn('seller_id', $sellerIds)
            ->where('status', 1)
            ->where('is_approved', 1)
            ->groupBy('seller_id');

        // Log the SQL query
        Log::info('SellerFilterService::getSellerFoodTypes - SQL Query', [
            'sql' => $query->toSql(),
            'bindings' => $query->getBindings(),
        ]);

        $results = $query->get();

        $foodTypes = [];
        foreach ($results as $result) {
            // If has_non_veg = 1, seller is non-veg; otherwise veg
            $foodTypes[$result->seller_id] = $result->has_non_veg ? self::FOOD_TYPE_NON_VEG : self::FOOD_TYPE_VEG;
        }

        Log::info('SellerFilterService::getSellerFoodTypes - Query completed', [
            'results_count' => count($foodTypes),
            'food_types' => $foodTypes,
        ]);

        return $foodTypes;
    }

    /**
     * Attach food type to each seller in the collection
     *
     * @param Collection $sellers
     * @return Collection
     */
    public static function attachFoodTypeToSellers(Collection $sellers): Collection
    {
        $sellerIds = $sellers->pluck('id')->toArray();

        if (empty($sellerIds)) {
            return $sellers;
        }

        $sellerFoodTypes = self::getSellerFoodTypes($sellerIds);

        return $sellers->map(function ($seller) use ($sellerFoodTypes) {
            $seller->food_type = $sellerFoodTypes[$seller->id] ?? null;
            return $seller;
        });
    }

    /**
     * Get list of available sort options
     *
     * @return array
     */
    public static function getSortOptions(): array
    {
        return [
            self::SORT_DISTANCE => 'Distance (Nearest)',
            self::SORT_RATING => 'Rating (Highest)',
            self::SORT_PRICE_LOW_TO_HIGH => 'Price (Low to High)',
            self::SORT_PRICE_HIGH_TO_LOW => 'Price (High to Low)',
            self::SORT_NAME => 'Name (A-Z)',
        ];
    }

    /**
     * Get list of available food type filter options
     *
     * @return array
     */
    public static function getFoodTypeOptions(): array
    {
        return [
            self::FOOD_TYPE_ALL => 'All',
            self::FOOD_TYPE_VEG => 'Veg Only',
            self::FOOD_TYPE_NON_VEG => 'Non-Veg',
        ];
    }
}
