<?php

namespace App\Services;

use App\Models\CustomerItemMissingReport;
use Illuminate\Support\Facades\Log;

class CustomerIssueReportRefundService
{
    /**
     * Get seller-wise product breakdown with prices for a report
     * Uses price and quantity directly from selected_items and selected_combo_items
     *
     * @param int $reportId
     * @return array
     */
    public static function getSellerWiseRefundBreakdown($reportId)
    {
        try {
            $report = CustomerItemMissingReport::find($reportId);

            if (!$report) {
                return [
                    'success' => false,
                    'message' => 'Report not found.',
                    'data' => null,
                ];
            }

            $orderId = $report->order_id;
            $customerId = $report->customer_id;

            // Get selected_items from report
            $selectedItems = $report->selected_items ?? [];
            if (is_string($selectedItems)) {
                $selectedItems = json_decode($selectedItems, true) ?? [];
            }

            // Get selected_combo_items from report
            $selectedComboItems = $report->selected_combo_items ?? [];
            if (is_string($selectedComboItems)) {
                $selectedComboItems = json_decode($selectedComboItems, true) ?? [];
            }

            // Build seller-wise breakdown
            $sellerBreakdown = [];
            $grandTotal = 0;

            // Process regular items (grouped by store/seller)
            foreach ($selectedItems as $storeItem) {
                $storeId = $storeItem['store_id'] ?? 0;
                $storeName = $storeItem['store_name'] ?? 'Unknown Store';
                $sellerId = $storeItem['seller_id'] ?? null;
                $sellerName = $storeItem['seller_name'] ?? null;
                $sellerStoreName = $storeItem['seller_store_name'] ?? null;
                $sellerMobile = $storeItem['seller_mobile'] ?? null;
                $sellerAddress = $storeItem['seller_address'] ?? null;

                // Use seller_id as key, or store_id if no seller assigned
                $key = $sellerId ? "seller_{$sellerId}" : "store_{$storeId}";

                if (!isset($sellerBreakdown[$key])) {
                    $sellerBreakdown[$key] = [
                        'store_id' => $storeId,
                        'store_name' => $storeName,
                        'seller_id' => $sellerId,
                        'seller_name' => $sellerName,
                        'seller_store_name' => $sellerStoreName,
                        'seller_mobile' => $sellerMobile,
                        'seller_address' => $sellerAddress,
                        'products' => [],
                        'total_amount' => 0,
                    ];
                }

                $items = $storeItem['items'] ?? [];
                foreach ($items as $item) {
                    $productId = $item['product_id'] ?? 0;
                    $productName = $item['product_name'] ?? 'Unknown Product';
                    $variantMeasurement = $item['variant_measurement'] ?? null;
                    $quantity = intval($item['quantity'] ?? 1);
                    $price = floatval($item['price'] ?? 0);

                    // Calculate sub_total using price * quantity
                    $subTotal = $price * $quantity;

                    $sellerBreakdown[$key]['products'][] = [
                        'product_id' => $productId,
                        'product_name' => $productName,
                        'variant_measurement' => $variantMeasurement,
                        'price' => $price,
                        'quantity' => $quantity,
                        'sub_total' => round($subTotal, 2),
                    ];

                    $sellerBreakdown[$key]['total_amount'] += $subTotal;
                    $grandTotal += $subTotal;
                }
            }

            // Process combo items - add products to the same products array
            foreach ($selectedComboItems as $comboItem) {
                $comboId = $comboItem['combo_id'] ?? $comboItem['id'] ?? 0;
                $comboName = $comboItem['combo_name'] ?? 'Unknown Combo';
                $comboQuantity = intval($comboItem['combo_quantity'] ?? $comboItem['quantity'] ?? 1);

                // Get products in the combo
                $comboProducts = $comboItem['products'] ?? [];

                // For combos, default to Zenfoo store (store_id 12)
                $storeId = 12;
                $key = "store_{$storeId}";

                if (!isset($sellerBreakdown[$key])) {
                    $sellerBreakdown[$key] = [
                        'store_id' => $storeId,
                        'store_name' => 'Zenfoo',
                        'seller_id' => null,
                        'seller_name' => 'Zenfoo',
                        'seller_store_name' => 'Zenfoo Store',
                        'seller_mobile' => null,
                        'seller_address' => null,
                        'products' => [],
                        'total_amount' => 0,
                    ];
                }

                foreach ($comboProducts as $product) {
                    $productId = $product['product_id'] ?? 0;
                    $productName = $product['product_name'] ?? 'Unknown';
                    $variantMeasurement = $product['variant_measurement'] ?? null;
                    $productQuantity = intval($product['quantity'] ?? 1);
                    $price = floatval($product['price'] ?? 0);

                    // Calculate sub_total: price * product_quantity * combo_quantity
                    $subTotal = $price * $productQuantity * $comboQuantity;

                    $sellerBreakdown[$key]['products'][] = [
                        'product_id' => $productId,
                        'product_name' => $productName,
                        'variant_measurement' => $variantMeasurement,
                        'price' => $price,
                        'quantity' => $productQuantity * $comboQuantity,
                        'sub_total' => round($subTotal, 2),
                        'combo_id' => $comboId,
                        'combo_name' => $comboName,
                    ];

                    $sellerBreakdown[$key]['total_amount'] += $subTotal;
                    $grandTotal += $subTotal;
                }
            }

            // Convert to indexed array and round totals
            $sellersData = [];
            foreach ($sellerBreakdown as $seller) {
                $seller['total_amount'] = round($seller['total_amount'], 2);
                $sellersData[] = $seller;
            }

            return [
                'success' => true,
                'message' => 'Refund breakdown fetched successfully.',
                'data' => [
                    'report_id' => $report->id,
                    'order_id' => $orderId,
                    'customer_id' => $customerId,
                    'report_type' => $report->report_type,
                    'report_status' => $report->status,
                    'is_refund_requested' => $report->is_refund_requested,
                    'sellers' => $sellersData,
                    'total_amount' => round($grandTotal, 2),
                    'total_sellers' => count($sellersData),
                    'total_products' => array_sum(array_map(fn($s) => count($s['products']), $sellersData)),
                ],
            ];

        } catch (\Exception $e) {
            Log::error('CustomerIssueReportRefundService::getSellerWiseRefundBreakdown Error', [
                'report_id' => $reportId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return [
                'success' => false,
                'message' => 'Failed to fetch refund breakdown: ' . $e->getMessage(),
                'data' => null,
            ];
        }
    }

    /**
     * Get refund breakdown for a specific seller from a report
     *
     * @param int $reportId
     * @param int $sellerId
     * @return array
     */
    public static function getSellerRefundBreakdown($reportId, $sellerId)
    {
        $breakdown = self::getSellerWiseRefundBreakdown($reportId);

        if (!$breakdown['success']) {
            return $breakdown;
        }

        $sellers = $breakdown['data']['sellers'] ?? [];
        $sellerData = null;

        foreach ($sellers as $seller) {
            if ($seller['seller_id'] == $sellerId) {
                $sellerData = $seller;
                break;
            }
        }

        if (!$sellerData) {
            return [
                'success' => false,
                'message' => 'Seller not found in this report.',
                'data' => null,
            ];
        }

        return [
            'success' => true,
            'message' => 'Seller refund breakdown fetched successfully.',
            'data' => [
                'report_id' => $breakdown['data']['report_id'],
                'order_id' => $breakdown['data']['order_id'],
                'customer_id' => $breakdown['data']['customer_id'],
                'report_type' => $breakdown['data']['report_type'],
                'seller' => $sellerData,
            ],
        ];
    }

    /**
     * Calculate total refund amount for a report
     *
     * @param int $reportId
     * @return float
     */
    public static function calculateTotalRefundAmount($reportId)
    {
        $breakdown = self::getSellerWiseRefundBreakdown($reportId);

        if (!$breakdown['success']) {
            return 0;
        }

        return $breakdown['data']['total_amount'] ?? 0;
    }

    /**
     * Calculate refund amount for a specific seller from a report
     *
     * @param int $reportId
     * @param int $sellerId
     * @return float
     */
    public static function calculateSellerRefundAmount($reportId, $sellerId)
    {
        $breakdown = self::getSellerRefundBreakdown($reportId, $sellerId);

        if (!$breakdown['success']) {
            return 0;
        }

        return $breakdown['data']['seller']['total_amount'] ?? 0;
    }
}
