<?php

namespace App\Services;

use App\Models\CustomerItemMissingReport;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CustomerIssueReportService
{
    /**
     * Get customer issue reports with filtering and pagination
     *
     * @param int $customerId - The customer user ID
     * @param array $filters - Filter options (report_id, order_id, report_type, status, is_refund_requested, from_date, to_date)
     * @param int $page - Page number
     * @param int $perPage - Results per page
     * @return array - Result with reports data and pagination
     */
    public static function getReports(
        int $customerId,
        array $filters = [],
        int $page = 1,
        int $perPage = 20
    ): array {
        // Log::info('CustomerIssueReportService::getReports - START', [
        //     'customer_id' => $customerId,
        //     'filters' => $filters,
        //     'page' => $page,
        //     'per_page' => $perPage,
        // ]);

        try {
            // Build query with filters
            $query = self::buildReportsQuery($customerId, $filters);

            // Get total count for pagination
            $totalCount = $query->count();

            // Log::info('CustomerIssueReportService::getReports - Query count', [
            //     'customer_id' => $customerId,
            //     'total_count' => $totalCount,
            // ]);

            // Get paginated reports
            $reports = $query->orderBy('created_at', 'desc')
                ->skip(($page - 1) * $perPage)
                ->take($perPage)
                ->get();

            if ($reports->isEmpty()) {
                // Log::info('CustomerIssueReportService::getReports - No reports found', [
                //     'customer_id' => $customerId,
                // ]);

                return [
                    'success' => true,
                    'message' => 'No reports found.',
                    'reports' => [],
                    'pagination' => [
                        'current_page' => $page,
                        'per_page' => $perPage,
                        'total' => 0,
                        'total_pages' => 0,
                    ],
                ];
            }

            // Log::info('CustomerIssueReportService::getReports - Reports fetched', [
            //     'customer_id' => $customerId,
            //     'reports_count' => $reports->count(),
            // ]);

            // Transform reports to response format
            $response = [];
            foreach ($reports as $report) {
                $response[] = self::transformReport($report);
            }

            // Log::info('CustomerIssueReportService::getReports - END', [
            //     'customer_id' => $customerId,
            //     'response_count' => count($response),
            // ]);

            return [
                'success' => true,
                'message' => 'Reports fetched successfully.',
                'reports' => $response,
                'pagination' => [
                    'current_page' => $page,
                    'per_page' => $perPage,
                    'total' => $totalCount,
                    'total_pages' => ceil($totalCount / $perPage),
                ],
                'is_single_report' => isset($filters['report_id']) && count($response) === 1,
            ];

        } catch (\Exception $e) {
            Log::error('CustomerIssueReportService::getReports - Exception', [
                'customer_id' => $customerId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return [
                'success' => false,
                'message' => 'Failed to fetch reports: ' . $e->getMessage(),
                'reports' => [],
                'pagination' => null,
            ];
        }
    }

    /**
     * Build the query with filters applied
     */
    private static function buildReportsQuery(int $customerId, array $filters)
    {
        // Log::info('CustomerIssueReportService::buildReportsQuery - Building query', [
        //     'customer_id' => $customerId,
        //     'filters' => $filters,
        // ]);

        $query = CustomerItemMissingReport::where('customer_id', $customerId);

        if (!empty($filters['report_id'])) {
            $query->where('id', $filters['report_id']);
            // Log::info('CustomerIssueReportService::buildReportsQuery - Filter: report_id', [
            //     'report_id' => $filters['report_id'],
            // ]);
        }

        if (!empty($filters['order_id'])) {
            $query->where('order_id', $filters['order_id']);
            // Log::info('CustomerIssueReportService::buildReportsQuery - Filter: order_id', [
            //     'order_id' => $filters['order_id'],
            // ]);
        }

        if (!empty($filters['report_type'])) {
            $query->where('report_type', $filters['report_type']);
            // Log::info('CustomerIssueReportService::buildReportsQuery - Filter: report_type', [
            //     'report_type' => $filters['report_type'],
            // ]);
        }

        if (isset($filters['status']) && ($filters['status'] !== '' && $filters['status'] !== null)) {
            $query->where('status', $filters['status']);
            // Log::info('CustomerIssueReportService::buildReportsQuery - Filter: status', [
            //     'status' => $filters['status'],
            // ]);
        }

        if (isset($filters['is_refund_requested']) && $filters['is_refund_requested'] !== null) {
            $query->where('is_refund_requested', $filters['is_refund_requested']);
            // Log::info('CustomerIssueReportService::buildReportsQuery - Filter: is_refund_requested', [
            //     'is_refund_requested' => $filters['is_refund_requested'],
            // ]);
        }

        if (!empty($filters['from_date'])) {
            $query->whereDate('created_at', '>=', $filters['from_date']);
            // Log::info('CustomerIssueReportService::buildReportsQuery - Filter: from_date', [
            //     'from_date' => $filters['from_date'],
            // ]);
        }

        if (!empty($filters['to_date'])) {
            $query->whereDate('created_at', '<=', $filters['to_date']);
            // Log::info('CustomerIssueReportService::buildReportsQuery - Filter: to_date', [
            //     'to_date' => $filters['to_date'],
            // ]);
        }

        return $query;
    }

    /**
     * Transform a single report to response format
     */
    private static function transformReport(CustomerItemMissingReport $report): array
    {
        $orderId = $report->order_id;
        $selectedItems = $report->selected_items ?? [];
        $selectedComboItems = $report->selected_combo_items ?? [];
        $reportType = $report->report_type ?? 'missing';

        // Log::info('CustomerIssueReportService::transformReport - Processing report', [
        //     'report_id' => $report->id,
        //     'order_id' => $orderId,
        //     'report_type' => $reportType,
        //     'selected_items_count' => count($selectedItems),
        //     'selected_combo_items_count' => count($selectedComboItems),
        // ]);

        if ($reportType === 'wrong') {
            return self::transformWrongItemReport($report, $selectedItems, $selectedComboItems);
        } else {
            return self::transformMissingItemReport($report, $orderId, $selectedItems, $selectedComboItems);
        }
    }

    /**
     * Transform wrong item report (with images)
     */
    private static function transformWrongItemReport(
        CustomerItemMissingReport $report,
        array $selectedItems,
        array $selectedComboItems
    ): array {
        // Log::info('CustomerIssueReportService::transformWrongItemReport - START', [
        //     'report_id' => $report->id,
        // ]);

        $storeWiseItems = [];
        foreach ($selectedItems as $storeItem) {
            $storeWiseItems[] = [
                'store_id' => $storeItem['store_id'] ?? 0,
                'store_name' => $storeItem['store_name'] ?? 'Unknown',
                'image_urls' => $storeItem['image_urls'] ?? [],
                'description' => $storeItem['description'] ?? '',
            ];
        }

        // Log::info('CustomerIssueReportService::transformWrongItemReport - Store items processed', [
        //     'report_id' => $report->id,
        //     'store_items_count' => count($storeWiseItems),
        // ]);

        $comboItems = [];
        foreach ($selectedComboItems as $comboItem) {
            $comboItems[] = [
                'combo_id' => $comboItem['combo_id'] ?? $comboItem['id'] ?? 0,
                'combo_name' => $comboItem['combo_name'] ?? '',
                'image_urls' => $comboItem['image_urls'] ?? [],
                'description' => $comboItem['description'] ?? '',
            ];
        }

        // Log::info('CustomerIssueReportService::transformWrongItemReport - Combo items processed', [
        //     'report_id' => $report->id,
        //     'combo_items_count' => count($comboItems),
        // ]);

        // Get driver details
        $driverDetails = self::getDriverDetails($report->order_id);

        return [
            'report_id' => $report->id,
            'customer_id' => $report->customer_id,
            'order_id' => $report->order_id,
            'report_type' => $report->report_type ?? 'wrong',
            'description' => $report->description,
            'is_refund_requested' => $report->is_refund_requested,
            'status' => $report->status,
            'status_name' => $report->status_name,
            'admin_remarks' => $report->admin_remarks,
            'status_change_json' => $report->status_change_json,
            'created_at' => $report->created_at->format('Y-m-d H:i:s'),
            'updated_at' => $report->updated_at->format('Y-m-d H:i:s'),
            'driver_id' => $driverDetails['driver_id'] ?? null,
            'driver_name' => $driverDetails['driver_name'] ?? null,
            // 'driver_phone' => $driverDetails['driver_phone'] ?? null,
            'delivered_at_time' => $driverDetails['delivered_at_time'] ?? null,
            'delivery_images' => $driverDetails['delivery_images'] ?? [],
            'customer' => $driverDetails['customer'] ?? null,
            'store_wise_items' => $storeWiseItems,
            'combo_items' => $comboItems,
        ];
    }

    /**
     * Transform missing item report (with product details)
     */
    private static function transformMissingItemReport(
        CustomerItemMissingReport $report,
        int $orderId,
        array $selectedItems,
        array $selectedComboItems
    ): array {
        // Log::info('CustomerIssueReportService::transformMissingItemReport - START', [
        //     'report_id' => $report->id,
        //     'order_id' => $orderId,
        // ]);

        // Collect all product IDs from selected items
        $allProductIds = [];
        foreach ($selectedItems as $storeItem) {
            foreach ($storeItem['items'] ?? [] as $item) {
                $allProductIds[] = $item['product_id'];
            }
        }

        // Collect all combo IDs
        $allComboIds = [];
        foreach ($selectedComboItems as $comboItem) {
            $allComboIds[] = $comboItem['id'];
        }

        // Log::info('CustomerIssueReportService::transformMissingItemReport - IDs collected', [
        //     'report_id' => $report->id,
        //     'product_ids_count' => count($allProductIds),
        //     'combo_ids_count' => count($allComboIds),
        // ]);

        // Process store-wise items
        $storeWiseItems = self::processStoreWiseItems($orderId, $selectedItems, $allProductIds);

        // Log::info('CustomerIssueReportService::transformMissingItemReport - Store items processed', [
        //     'report_id' => $report->id,
        //     'store_wise_items_count' => count($storeWiseItems),
        // ]);

        // Process combo items
        $comboItems = self::processComboItems($orderId, $selectedComboItems, $allComboIds);

        // Log::info('CustomerIssueReportService::transformMissingItemReport - Combo items processed', [
        //     'report_id' => $report->id,
        //     'combo_items_count' => count($comboItems),
        // ]);

        // Get driver details
        $driverDetails = self::getDriverDetails($orderId);

        return [
            'report_id' => $report->id,
            'customer_id' => $report->customer_id,
            'order_id' => $report->order_id,
            'report_type' => $report->report_type ?? 'missing',
            'description' => $report->description,
            'is_refund_requested' => $report->is_refund_requested,
            'status' => $report->status,
            'status_name' => $report->status_name,
            'admin_remarks' => $report->admin_remarks,
            'status_change_json' => $report->status_change_json,
            'created_at' => $report->created_at->format('Y-m-d H:i:s'),
            'updated_at' => $report->updated_at->format('Y-m-d H:i:s'),
            'driver_id' => $driverDetails['driver_id'] ?? null,
            'driver_name' => $driverDetails['driver_name'] ?? null,
            // 'driver_phone' => $driverDetails['driver_phone'] ?? null,
            'delivered_at_time' => $driverDetails['delivered_at_time'] ?? null,
            'delivery_images' => $driverDetails['delivery_images'] ?? [],
            'customer' => $driverDetails['customer'] ?? null,
            'store_wise_items' => $storeWiseItems,
            'combo_items' => $comboItems,
        ];
    }

    /**
     * Process store-wise items for missing item report
     */
    private static function processStoreWiseItems(int $orderId, array $selectedItems, array $allProductIds): array
    {
        if (empty($allProductIds)) {
            // Log::info('CustomerIssueReportService::processStoreWiseItems - No product IDs to process');
            return [];
        }

        // Log::info('CustomerIssueReportService::processStoreWiseItems - START', [
        //     'order_id' => $orderId,
        //     'product_ids' => $allProductIds,
        // ]);

        // Get order items
        $orderItems = OrderItem::where('order_id', $orderId)
            ->whereIn('id', $allProductIds)
            ->select('id', 'product_variant_id', 'product_name', 'variant_name', 'quantity', 'price', 'discounted_price', 'sub_total')
            ->get()
            ->keyBy('id');

        // Log::info('CustomerIssueReportService::processStoreWiseItems - Order items fetched', [
        //     'order_id' => $orderId,
        //     'order_items_count' => $orderItems->count(),
        // ]);

        // Get variant details
        $variantIds = $orderItems->pluck('product_variant_id')->toArray();
        $variantDetails = DB::table('product_variants')
            ->whereIn('id', $variantIds)
            ->select('id', 'product_id')
            ->get()
            ->keyBy('id');

        // Log::info('CustomerIssueReportService::processStoreWiseItems - Variant details fetched', [
        //     'variant_ids_count' => count($variantIds),
        // ]);

        // Get product details
        $productIds = $variantDetails->pluck('product_id')->unique()->toArray();
        $productDetails = DB::table('products')
            ->whereIn('id', $productIds)
            ->select('id', 'store_id')
            ->get()
            ->keyBy('id');

        // Log::info('CustomerIssueReportService::processStoreWiseItems - Product details fetched', [
        //     'product_ids_count' => count($productIds),
        // ]);

        // Get store details
        $storeIds = $productDetails->pluck('store_id')->unique()->toArray();
        $stores = DB::table('stores')
            ->whereIn('id', $storeIds)
            ->select('id', 'name', 'managed_by_admin')
            ->get()
            ->keyBy('id');

        // Log::info('CustomerIssueReportService::processStoreWiseItems - Store details fetched', [
        //     'store_ids_count' => count($storeIds),
        // ]);

        // Get seller details for vendor stores
        $vendorStoreIds = $stores->filter(function ($store) {
            return $store->managed_by_admin != 1;
        })->pluck('id')->toArray();

        $sellers = collect([]);
        if (!empty($vendorStoreIds)) {
            $sellers = DB::table('sellers')
                ->whereIn('store_id', $vendorStoreIds)
                ->select('id', 'store_id', 'store_name')
                ->get()
                ->keyBy('store_id');

            // Log::info('CustomerIssueReportService::processStoreWiseItems - Sellers fetched', [
            //     'vendor_store_ids' => $vendorStoreIds,
            //     'sellers_count' => $sellers->count(),
            // ]);
        }

        // Build store-wise items
        $storeWiseItems = [];
        foreach ($selectedItems as $storedStoreItem) {
            $inputStoreId = $storedStoreItem['store_id'] ?? 0;
            $storeDescription = $storedStoreItem['description'] ?? '';

            $store = $stores[$inputStoreId] ?? null;
            $isZenfooStore = $store && $store->managed_by_admin == 1;
            $seller = !$isZenfooStore ? ($sellers[$inputStoreId] ?? null) : null;

            if ($isZenfooStore) {
                $storeName = $store ? $store->name : 'Unknown';
            } else {
                $storeName = $seller ? $seller->store_name : ($store ? $store->name : 'Unknown');
            }

            $items = [];
            foreach ($storedStoreItem['items'] ?? [] as $storedItem) {
                $productId = $storedItem['product_id'];
                $item = $orderItems[$productId] ?? null;
                if ($item) {
                    $items[] = [
                        'product_id' => $item->id,
                        'product_name' => $item->product_name,
                        'variant_measurement' => $item->variant_name,
                        'price' => $item->discounted_price,
                        'actual_price' => $item->price,
                        'quantity' => $item->quantity,
                        'sub_total' => $item->sub_total,
                    ];
                }
            }

            if (!empty($items)) {
                $storeWiseItems[] = [
                    'store_id' => $inputStoreId,
                    'store_name' => $storeName,
                    'description' => $storeDescription,
                    'image_urls' => $storedStoreItem['image_urls'] ?? [],
                    'items' => $items,
                ];

                // Log::info('CustomerIssueReportService::processStoreWiseItems - Store item added', [
                //     'store_id' => $inputStoreId,
                //     'store_name' => $storeName,
                //     'items_count' => count($items),
                // ]);
            }
        }

        return $storeWiseItems;
    }

    /**
     * Process combo items for missing item report
     */
    private static function processComboItems(int $orderId, array $selectedComboItems, array $allComboIds): array
    {
        if (empty($allComboIds)) {
            // Log::info('CustomerIssueReportService::processComboItems - No combo IDs to process');
            return [];
        }

        // Log::info('CustomerIssueReportService::processComboItems - START', [
        //     'order_id' => $orderId,
        //     'combo_ids' => $allComboIds,
        // ]);

        // Get order combo items
        $orderComboItems = DB::table('order_combo_items')
            ->where('order_id', $orderId)
            ->whereIn('id', $allComboIds)
            ->get()
            ->keyBy('id');

        // Log::info('CustomerIssueReportService::processComboItems - Order combo items fetched', [
        //     'order_combo_items_count' => $orderComboItems->count(),
        // ]);

        // Collect all stock unit IDs for units lookup
        $comboStockUnitIds = [];
        foreach ($orderComboItems as $combo) {
            if (!empty($combo->products)) {
                $products = json_decode($combo->products, true);
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }
                if (is_array($products)) {
                    foreach ($products as $product) {
                        if (!empty($product['variant_stock_unit_id'])) {
                            $comboStockUnitIds[] = $product['variant_stock_unit_id'];
                        }
                    }
                }
            }
        }

        // Get units
        $comboUnits = [];
        if (!empty($comboStockUnitIds)) {
            $comboUnits = DB::table('units')
                ->whereIn('id', array_unique($comboStockUnitIds))
                ->pluck('short_code', 'id')
                ->toArray();

            // Log::info('CustomerIssueReportService::processComboItems - Units fetched', [
            //     'units_count' => count($comboUnits),
            // ]);
        }

        // Build combo items
        $comboItems = [];
        foreach ($selectedComboItems as $storedComboItem) {
            $comboId = $storedComboItem['id'] ?? 0;
            $comboDescription = $storedComboItem['description'] ?? '';
            $selectedProductIds = array_column($storedComboItem['products'] ?? [], 'product_id');

            $combo = $orderComboItems[$comboId] ?? null;
            if (!$combo) {
                // Log::warning('CustomerIssueReportService::processComboItems - Combo not found', [
                //     'combo_id' => $comboId,
                // ]);
                continue;
            }

            $comboData = [
                'id' => $combo->id,
                'combo_name' => $combo->combo_name ?? '',
                'combo_quantity' => $combo->combo_quantity ?? 1,
                'sub_total' => $combo->sub_total ?? 0,
                'discount_percentage' => $combo->discount_percentage ?? 0,
                'total_actual_price' => $combo->total_actual_price ?? 0,
                'total_products_price' => $combo->total_products_price ?? 0,
                'description' => $comboDescription,
                'image_urls' => $storedComboItem['image_urls'] ?? [],
                'products' => [],
            ];

            if (!empty($combo->products)) {
                $products = json_decode($combo->products, true);
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }
                if (is_array($products)) {
                    foreach ($products as $product) {
                        $productId = $product['product_id'] ?? 0;
                        if (in_array($productId, $selectedProductIds)) {
                            $measurement = $product['variant_measurement'] ?? '';
                            $stockUnitId = $product['variant_stock_unit_id'] ?? null;
                            $unitShortCode = $stockUnitId ? ($comboUnits[$stockUnitId] ?? '') : '';

                            $variantMeasurement = $measurement . ($unitShortCode ? ' ' . $unitShortCode : '');

                            $comboData['products'][] = [
                                'product_id' => $productId,
                                'product_name' => $product['product_name'] ?? '',
                                'variant_measurement' => trim($variantMeasurement),
                                'price' => $product['price'] ?? 0,
                                'actual_price' => $product['actual_price'] ?? 0,
                                'quantity' => $product['quantity'] ?? 1,
                                'sub_total' => $product['sub_total'] ?? 0,
                            ];
                        }
                    }
                }
            }

            if (!empty($comboData['products'])) {
                $comboItems[] = $comboData;

                // Log::info('CustomerIssueReportService::processComboItems - Combo item added', [
                //     'combo_id' => $comboId,
                //     'combo_name' => $comboData['combo_name'],
                //     'products_count' => count($comboData['products']),
                // ]);
            }
        }

        return $comboItems;
    }

    /**
     * Get driver details and order info from order's delivery_boy_id
     */
    private static function getDriverDetails(int $orderId): ?array
    {
        $order = Order::with(['deliveryBoy', 'user'])->find($orderId);

        if (!$order) {
            return null;
        }

        $driver = $order->deliveryBoy;

        // Get customer details from cart_metadata
        $cartMetadata = $order->cart_metadata;
        if (is_string($cartMetadata)) {
            $cartMetadata = json_decode($cartMetadata, true);
        }
        $cartInfo = $cartMetadata['cart_info'] ?? [];

        // Prefer the customer's account details, fall back to the order's
        // delivery contact info stored in cart_metadata.
        $customerUser = $order->user;

        // Delivery-proof images captured by the driver at delivery time.
        // Column is cast to array on the Order model.
        $deliveryImages = $order->delivery_time_before_images ?? [];
        if (!is_array($deliveryImages)) {
            $deliveryImages = [];
        }

        return [
            'driver_id' => $driver->id ?? null,
            'driver_name' => $driver->name ?? null,
            'driver_phone' => $driver->phone ?? null,
            'delivered_at_time' => $order->delivered_at_time ?? null,
            'delivery_images' => array_values($deliveryImages),
            'customer' => [
                'name' => $customerUser->name ?? $cartInfo['contact_name'] ?? null,
                'phone' => $customerUser->mobile ?? $cartInfo['contact_phone'] ?? null,
                'email' => $customerUser->email ?? $cartInfo['contact_email'] ?? null,
            ],
        ];
    }
}
