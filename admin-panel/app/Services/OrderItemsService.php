<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderItemsService
{
    /**
     * Get all items (normal + combo) for a given order.
     *
     * Returns:
     *   order_id        int
     *   normal_items    array  — one row per order_items record, is_combo_item = false
     *   combo_items     array  — one row per order_combo_items record, each has a
     *                           `products` array where every entry has is_combo_item = true
     *   all_product_ids array  — flat unique product IDs (normal + combo) for policy checks
     */
    public function getOrderItems(int $orderId): array
    {
        Log::info('OrderItemsService::getOrderItems', ['order_id' => $orderId]);

        // ── 1. Normal items ───────────────────────────────────────────────────
        $rawItems = DB::table('order_items')
            ->join('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
            ->leftJoin('sellers', 'order_items.seller_id', '=', 'sellers.id')
            ->leftJoin('order_status_lists as osl', 'order_items.active_status', '=', 'osl.id')
            ->where('order_items.order_id', $orderId)
            ->select(
                'order_items.id',
                'products.id as product_id',
                'products.name as product_name',
                'products.image as product_image',
                'product_variants.id as product_variant_id',
                'product_variants.measurement',
                'units.short_code as unit',
                'order_items.quantity',
                'order_items.price',
                'order_items.discounted_price',
                'order_items.sub_total',
                'order_items.active_status',
                'osl.status as status_name',
                'order_items.seller_id',
                'sellers.name as seller_name',
                'sellers.store_name'
            )
            ->get();

        $normalItems = $rawItems->map(fn($item) => [
            'id'                 => $item->id,
            'product_id'         => $item->product_id,
            'product_name'       => $item->product_name,
            'product_image'      => $item->product_image ? asset('storage/' . $item->product_image) : null,
            'product_variant_id' => $item->product_variant_id,
            'variant_name'       => trim($item->measurement . ' ' . ($item->unit ?? '')),
            'quantity'           => (int) $item->quantity,
            'price'              => (float) $item->price,
            'discounted_price'   => (float) $item->discounted_price,
            'sub_total'          => (float) $item->sub_total,
            'active_status'      => $item->active_status,
            'status_name'        => $item->status_name,
            'seller_id'          => $item->seller_id,
            'seller_name'        => $item->seller_name,
            'store_name'         => $item->store_name,
            'is_combo_item'      => false,
        ])->toArray();

        // ── 2. Combo items ────────────────────────────────────────────────────
        $orderCombos = DB::table('order_combo_items')
            ->where('order_id', $orderId)
            ->select('id', 'combo_id', 'combo_name', 'combo_description', 'sub_total', 'discount_percentage', 'products')
            ->get();

        // Decode JSON and collect all variant/product IDs for batch fetch
        $decodedCombos    = [];
        $allComboVariantIds  = [];
        $allComboProductIds  = [];

        foreach ($orderCombos as $combo) {
            $products = json_decode($combo->products ?? '[]', true);
            if (is_string($products)) {
                $products = json_decode($products, true);
            }
            $products = is_array($products) ? $products : [];

            $decodedCombos[$combo->id] = ['combo' => $combo, 'products' => $products];

            foreach ($products as $p) {
                if (!empty($p['product_id'])) $allComboProductIds[] = (int) $p['product_id'];
                // stored JSON uses 'variant_id'; fall back to 'product_variant_id' for newer entries
                $vid = $p['variant_id'] ?? $p['product_variant_id'] ?? null;
                if (!empty($vid)) $allComboVariantIds[] = (int) $vid;
            }
        }

        $allComboProductIds = array_values(array_unique($allComboProductIds));
        $allComboVariantIds = array_values(array_unique($allComboVariantIds));

        // Batch fetch product details for all combo products in one query
        $comboProductDetails = !empty($allComboProductIds)
            ? DB::table('products')
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->whereIn('products.id', $allComboProductIds)
                ->select(
                    'products.id',
                    'products.name',
                    'products.image',
                    'products.seller_id',
                    'sellers.name as seller_name',
                    'sellers.store_name'
                )
                ->get()->keyBy('id')
            : collect();

        // Batch fetch variant details for all combo variants in one query
        $comboVariantDetails = !empty($allComboVariantIds)
            ? DB::table('product_variants')
                ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                ->whereIn('product_variants.id', $allComboVariantIds)
                ->select('product_variants.id', 'product_variants.measurement', 'units.short_code as unit')
                ->get()->keyBy('id')
            : collect();

        // Build combo_items with formatted products
        $comboItems = [];
        foreach ($decodedCombos as $entry) {
            $combo = $entry['combo'];
            $formattedProducts = [];

            foreach ($entry['products'] as $p) {
                $pid = $p['product_id'] ?? null;
                if (!$pid) continue;

                $vid     = $p['variant_id'] ?? $p['product_variant_id'] ?? null;
                $detail  = $comboProductDetails[$pid] ?? null;
                $variant = $vid ? ($comboVariantDetails[$vid] ?? null) : null;

                $formattedProducts[] = [
                    'product_id'         => $pid,
                    'product_name'       => $detail->name ?? ($p['product_name'] ?? null),
                    'product_image'      => ($detail && $detail->image) ? asset('storage/' . $detail->image) : null,
                    'product_variant_id' => $vid,
                    'variant_name'       => $variant ? trim($variant->measurement . ' ' . ($variant->unit ?? '')) : null,
                    'quantity'           => (int) ($p['quantity'] ?? 1),
                    'price'              => (float) ($p['price'] ?? 0),
                    'discounted_price'   => (float) ($p['discounted_price'] ?? 0),
                    'sub_total'          => (float) (($p['discounted_price'] ?? $p['price'] ?? 0) * ($p['quantity'] ?? 1)),
                    'seller_id'          => $detail->seller_id ?? null,
                    'seller_name'        => $detail->seller_name ?? null,
                    'store_name'         => $detail->store_name ?? null,
                    'is_combo_item'      => true,
                ];
            }

            $comboItems[] = [
                'order_combo_item_id' => $combo->id,
                'combo_id'            => $combo->combo_id,
                'combo_name'          => $combo->combo_name,
                'combo_description'   => $combo->combo_description,
                'combo_sub_total'     => (float) $combo->sub_total,
                'discount_percentage' => (float) $combo->discount_percentage,
                'products'            => $formattedProducts,
            ];
        }

        // ── 3. Flat unique product ID list (normal + combo) ───────────────────
        $normalProductIds = array_column($normalItems, 'product_id');
        $allProductIds    = array_values(array_unique(array_merge($normalProductIds, $allComboProductIds)));

        $result = [
            'order_id'          => $orderId,
            'normal_items'      => $normalItems,
            'combo_items'       => $comboItems,
            'all_product_ids'   => $allProductIds,
        ];

        Log::info('OrderItemsService::getOrderItems result', [
            'order_id'           => $orderId,
            'normal_items_count' => count($normalItems),
            'combo_items_count'  => count($comboItems),
            'all_product_ids'    => $allProductIds,
        ]);

        return $result;
    }
}
