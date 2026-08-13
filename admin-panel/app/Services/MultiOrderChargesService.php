<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\Cart;
use App\Models\Setting;

class MultiOrderChargesService
{
    /**
     * Check if the cart has multi-order scenario (store_id 15 + other stores)
     * If yes, return 0 for multi_order_charges
     * If no (single store or no store_id 15), return multi_order_bonus from settings
     *
     * @param int $userId User ID
     * @return float Multi order charges amount
     */
    public static function getMultiOrderCharges(int $userId): float
    {
        $multiOrderBonus = Setting::get_value('multi_order_bonus');
        $hasMultiOrder = self::hasMultiOrderScenario($userId);

        Log::info('MultiOrderChargesService::getMultiOrderCharges', [
            'user_id' => $userId,
            'multi_order_bonus_from_settings' => $multiOrderBonus,
            'has_multi_order' => $hasMultiOrder,
        ]);

        // If multi-order scenario (store_id 15 + other stores), return the charge
        // If single store order, return 0 (no additional charge)
        if ($hasMultiOrder) {
            $charge = $multiOrderBonus ? floatval($multiOrderBonus) : 0;
            Log::info('MultiOrderChargesService: Multi-order detected, applying charge', ['charge' => $charge]);
            return $charge;
        }

        Log::info('MultiOrderChargesService: Single store order, no charge applied');
        return 0;
    }

    /**
     * Check if the cart has multi-order scenario (for informational purposes)
     *
     * @param int $userId User ID
     * @return bool True if multi-order scenario exists
     */
    public static function hasMultiOrderScenario(int $userId): bool
    {
        // Get all unique store IDs from the user's cart (not save_for_later)
        $storeIds = Cart::select('products.store_id')
            ->join('products', 'carts.product_id', '=', 'products.id')
            ->where('carts.user_id', $userId)
            ->where('carts.save_for_later', 0)
            ->whereNotNull('products.store_id')
            ->distinct()
            ->pluck('products.store_id')
            ->toArray();

        // Also check custom combo products in cart
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
                $comboStoreIds = DB::table('products')
                    ->whereIn('id', $comboProductIds)
                    ->whereNotNull('store_id')
                    ->pluck('store_id')
                    ->toArray();

                $storeIds = array_merge($storeIds, $comboStoreIds);
            }
        }

        // Remove duplicates
        $storeIds = array_values(array_unique($storeIds));

        // Check if cart has store_id 15
        $hasStore15 = in_array(15, $storeIds);

        // Multi-order scenario: store_id 15 exists AND other stores exist
        $isMultiOrder = $hasStore15 && count($storeIds) > 1;

        

        return $isMultiOrder;
    }
}
