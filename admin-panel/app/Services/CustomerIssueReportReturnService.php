<?php

namespace App\Services;

use App\Models\CustomerItemMissingReport;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CustomerIssueReportReturnService
{
    /**
     * Create return records for sellers when admin assigns a driver to collect items
     * This inserts records into customer_issue_report_returns table
     *
     * For normal items: product_id in selected_items.items = order_items.id
     *   - Need to convert: order_items.id -> order_items.product_variant_id -> product_variants.product_id
     *
     * For combo items: product_id in selected_combo_items.products = products.id directly
     *
     * @param CustomerItemMissingReport $report - The customer issue report
     * @return bool - Returns true on success, false on failure
     */
    public static function createReturnRecordsForSellers(CustomerItemMissingReport $report): bool
    {
        try {
            $orderId = $report->order_id;
            $customerId = $report->customer_id;

            // Get selected items and combo items from report
            $selectedItems = $report->selected_items ?? [];
            if (is_string($selectedItems)) {
                $selectedItems = json_decode($selectedItems, true) ?? [];
            }

            $selectedComboItems = $report->selected_combo_items ?? [];
            if (is_string($selectedComboItems)) {
                $selectedComboItems = json_decode($selectedComboItems, true) ?? [];
            }

            // Get seller assignments from order_seller_status_tracking
            $sellerAssignments = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get()
                ->keyBy('store_id');

            // Collect all order_item_ids from selected_items to batch query
            $allOrderItemIds = [];
            foreach ($selectedItems as $storeItem) {
                $items = $storeItem['items'] ?? [];
                foreach ($items as $item) {
                    $orderItemId = $item['product_id'] ?? 0; // This is actually order_items.id
                    if ($orderItemId) {
                        $allOrderItemIds[] = $orderItemId;
                    }
                }
            }

            // Get order_items data to map order_item_id -> product_variant_id
            $orderItemsMap = [];
            if (!empty($allOrderItemIds)) {
                $orderItemsMap = DB::table('order_items')
                    ->whereIn('id', $allOrderItemIds)
                    ->pluck('product_variant_id', 'id')
                    ->toArray();
            }

            // Get product_variants data to map product_variant_id -> product_id (products.id)
            $variantIds = array_values($orderItemsMap);
            $variantToProductMap = [];
            if (!empty($variantIds)) {
                $variantToProductMap = DB::table('product_variants')
                    ->whereIn('id', $variantIds)
                    ->pluck('product_id', 'id')
                    ->toArray();
            }

            // Build order_item_id -> products.id map
            $orderItemToProductIdMap = [];
            foreach ($orderItemsMap as $orderItemId => $variantId) {
                $productId = $variantToProductMap[$variantId] ?? null;
                if ($productId) {
                    $orderItemToProductIdMap[$orderItemId] = $productId;
                }
            }

            // Collect all product IDs (from both normal and combo items) for store lookup
            $allProductIds = array_values($orderItemToProductIdMap);

            // Add combo product IDs
            foreach ($selectedComboItems as $comboItem) {
                $products = $comboItem['products'] ?? [];
                foreach ($products as $product) {
                    $productId = $product['product_id'] ?? 0;
                    if ($productId) {
                        $allProductIds[] = $productId;
                    }
                }
            }

            // Get product -> store mapping
            $productStoreMap = [];
            if (!empty($allProductIds)) {
                $productStoreMap = DB::table('products')
                    ->whereIn('id', array_unique($allProductIds))
                    ->pluck('store_id', 'id')
                    ->toArray();
            }

            // Now collect product_ids and product details per seller
            // Structure: $sellerProductIds[seller_id] = [product_id1, product_id2, ...]
            // Structure: $sellerProductsJson[seller_id] = [product_details_array]
            $sellerProductIds = [];
            $sellerProductsJson = [];
            $sellerRefundableAmount = [];

            // Zenfoo store (store_id = 12) tracking
            $zenfooProductIds = [];
            $zenfooProductsJson = [];
            $zenfooRefundableAmount = 0;

            // Process normal items
            foreach ($selectedItems as $storeItem) {
                $storeId = (int) ($storeItem['store_id'] ?? 0);

                // Handle store ID 12 (Zenfoo/admin managed store) separately
                if ($storeId == 12) {
                    $items = $storeItem['items'] ?? [];
                    foreach ($items as $item) {
                        $orderItemId = $item['product_id'] ?? 0;
                        $actualProductId = $orderItemToProductIdMap[$orderItemId] ?? null;

                        if ($actualProductId) {
                            $zenfooProductIds[] = $actualProductId;

                            $zenfooProductsJson[] = [
                                'product_id' => $actualProductId,
                                'product_name' => $item['product_name'] ?? '',
                                'variant_measurement' => $item['variant_measurement'] ?? '',
                                'price' => $item['price'] ?? 0,
                                'actual_price' => $item['actual_price'] ?? 0,
                                'quantity' => $item['quantity'] ?? 1,
                                'sub_total' => $item['sub_total'] ?? 0,
                            ];

                            $zenfooRefundableAmount += (float) ($item['price'] ?? 0);
                        }
                    }
                    continue;
                }

                $sellerAssignment = $sellerAssignments[$storeId] ?? null;
                if (!$sellerAssignment) {
                    continue;
                }

                $sellerId = $sellerAssignment->seller_id;

                // Initialize arrays for this seller if not exists
                if (!isset($sellerProductIds[$sellerId])) {
                    $sellerProductIds[$sellerId] = [];
                    $sellerProductsJson[$sellerId] = [];
                    $sellerRefundableAmount[$sellerId] = 0;
                }

                // Process items and get actual product IDs
                $items = $storeItem['items'] ?? [];
                foreach ($items as $item) {
                    $orderItemId = $item['product_id'] ?? 0; // This is order_items.id
                    $actualProductId = $orderItemToProductIdMap[$orderItemId] ?? null;

                    if ($actualProductId) {
                        // Verify this product belongs to a store assigned to this seller
                        $productStoreId = $productStoreMap[$actualProductId] ?? null;
                        if ($productStoreId && $productStoreId != 12) {
                            $sellerProductIds[$sellerId][] = $actualProductId;

                            // Add product details to products_json
                            $sellerProductsJson[$sellerId][] = [
                                'product_id' => $actualProductId,
                                'product_name' => $item['product_name'] ?? '',
                                'variant_measurement' => $item['variant_measurement'] ?? '',
                                'price' => $item['price'] ?? 0,
                                'actual_price' => $item['actual_price'] ?? 0,
                                'quantity' => $item['quantity'] ?? 1,
                                'sub_total' => $item['sub_total'] ?? 0,
                            ];

                            // Add to refundable amount
                            $sellerRefundableAmount[$sellerId] += (float) ($item['price'] ?? 0);
                        }
                    }
                }
            }

            // Process combo items
            foreach ($selectedComboItems as $comboItem) {
                $products = $comboItem['products'] ?? [];

                foreach ($products as $product) {
                    $productId = $product['product_id'] ?? 0; // This is directly products.id

                    if (!$productId) {
                        continue;
                    }

                    $storeId = $productStoreMap[$productId] ?? null;

                    if (!$storeId) {
                        continue;
                    }

                    // Handle store ID 12 (Zenfoo/admin managed store) separately
                    if ($storeId == 12) {
                        $zenfooProductIds[] = $productId;

                        $zenfooProductsJson[] = [
                            'product_id' => $productId,
                            'product_name' => $product['product_name'] ?? '',
                            'variant_measurement' => $product['variant_measurement'] ?? '',
                            'price' => $product['price'] ?? 0,
                            'actual_price' => $product['actual_price'] ?? 0,
                            'quantity' => $product['quantity'] ?? 1,
                            'sub_total' => $product['sub_total'] ?? 0,
                            'combo_id' => $comboItem['id'] ?? null,
                            'combo_name' => $comboItem['combo_name'] ?? '',
                        ];

                        $zenfooRefundableAmount += (float) ($product['price'] ?? 0);
                        continue;
                    }

                    $sellerAssignment = $sellerAssignments[$storeId] ?? null;
                    if (!$sellerAssignment) {
                        continue;
                    }

                    $sellerId = $sellerAssignment->seller_id;

                    // Initialize arrays for this seller if not exists
                    if (!isset($sellerProductIds[$sellerId])) {
                        $sellerProductIds[$sellerId] = [];
                        $sellerProductsJson[$sellerId] = [];
                        $sellerRefundableAmount[$sellerId] = 0;
                    }

                    $sellerProductIds[$sellerId][] = $productId;

                    // Add product details to products_json
                    $sellerProductsJson[$sellerId][] = [
                        'product_id' => $productId,
                        'product_name' => $product['product_name'] ?? '',
                        'variant_measurement' => $product['variant_measurement'] ?? '',
                        'price' => $product['price'] ?? 0,
                        'actual_price' => $product['actual_price'] ?? 0,
                        'quantity' => $product['quantity'] ?? 1,
                        'sub_total' => $product['sub_total'] ?? 0,
                        'combo_id' => $comboItem['id'] ?? null,
                        'combo_name' => $comboItem['combo_name'] ?? '',
                    ];

                    // Add to refundable amount
                    $sellerRefundableAmount[$sellerId] += (float) ($product['price'] ?? 0);
                }
            }

            // Build return records with merged product_ids per seller
            $currentDate = now()->toDateString();
            $returnRecords = [];

            // Add Zenfoo store record if any products exist (seller_id = null, is_zenfoo_store = 1)
            if (!empty($zenfooProductIds)) {
                $uniqueZenfooProductIds = array_values(array_unique($zenfooProductIds));

                $returnRecords[] = [
                    'report_id' => $report->id,
                    'seller_id' => null,
                    'customer_id' => $customerId,
                    'date' => $currentDate,
                    'product_ids' => json_encode($uniqueZenfooProductIds),
                    'products_json' => json_encode($zenfooProductsJson),
                    'refundable_amount' => $zenfooRefundableAmount,
                    'delivery_partner_id' => null,
                    'delivered_date' => null,
                    'is_return_accepted' => 0,
                    'is_zenfoo_store' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // Add seller records
            foreach ($sellerProductIds as $sellerId => $productIds) {
                // Remove duplicates and get unique product IDs
                $uniqueProductIds = array_values(array_unique($productIds));

                $returnRecords[] = [
                    'report_id' => $report->id,
                    'seller_id' => $sellerId,
                    'customer_id' => $customerId,
                    'date' => $currentDate,
                    'product_ids' => json_encode($uniqueProductIds),
                    'products_json' => json_encode($sellerProductsJson[$sellerId] ?? []),
                    'refundable_amount' => $sellerRefundableAmount[$sellerId] ?? 0,
                    'delivery_partner_id' => null,
                    'delivered_date' => null,
                    'is_return_accepted' => 0,
                    'is_zenfoo_store' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            // Insert records if any
            if (!empty($returnRecords)) {
                DB::table('customer_issue_report_returns')->insert($returnRecords);

                Log::info('Customer issue report return records created', [
                    'report_id' => $report->id,
                    'order_id' => $orderId,
                    'records_count' => count($returnRecords),
                    'seller_product_ids' => $sellerProductIds,
                    'zenfoo_product_ids' => $zenfooProductIds,
                    'zenfoo_refundable_amount' => $zenfooRefundableAmount,
                ]);
            }

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to create customer issue report return records', [
                'report_id' => $report->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return false;
        }
    }
}
