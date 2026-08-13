<?php

namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\CustomerItemMissingReport;
use App\Models\CustomerWrongItemReport;
use App\Models\OrderItem;
use App\Models\OrderStatusList;
use App\Services\AdminNotificationService;
use App\Services\CustomerIssueReportService;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class CustomerIssueReportController extends Controller
{
    public function getOrderItems(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        $orderId = $request->order_id;

        $orderItems = OrderItem::where('order_id', $orderId)
            ->select('id', 'order_id', 'product_variant_id', 'quantity', 'price')
            ->get();

        $comboItems = DB::table('order_combo_items')
            ->where('order_id', $orderId)
            ->get();

        if ($orderItems->isEmpty() && $comboItems->isEmpty()) {
            return CommonHelper::responseError('No order items found for this order.');
        }

        $variantIds = $orderItems->pluck('product_variant_id')->toArray();

        $variantProductMap = DB::table('product_variants')
            ->whereIn('id', $variantIds)
            ->pluck('product_id', 'id');

        $productStoreMap = DB::table('products')
            ->whereIn('id', $variantProductMap->values())
            ->pluck('store_id', 'id');

        // Only use store IDs from regular order items (not combo items) for vendors
        $orderItemStoreIds = $productStoreMap->values()->unique()->toArray();

        $stores = DB::table('stores')
            ->whereIn('id', $orderItemStoreIds)
            ->select('id', 'name', 'managed_by_admin')
            ->get()
            ->keyBy('id');

        $vendorStoreIds = $stores->filter(function ($store) {
            return $store->managed_by_admin != 1;
        })->pluck('id')->toArray();

        // Use order_seller_status_tracking to get the exact seller per store for this order
        $sellerTracking = collect([]);
        if (!empty($vendorStoreIds)) {
            $sellerTracking = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->whereIn('store_id', $vendorStoreIds)
                ->select('store_id', 'seller_id')
                ->get()
                ->keyBy('store_id');
        }

        $sellers = collect([]);
        $trackingSellerIds = $sellerTracking->pluck('seller_id')->filter()->unique()->toArray();
        if (!empty($trackingSellerIds)) {
            $sellers = DB::table('sellers')
                ->whereIn('id', $trackingSellerIds)
                ->select('id', 'store_id', 'name', 'store_name')
                ->get()
                ->keyBy('id');
        }

        $hasZenfoo = false;
        $vendorsList = [];

        // Only check regular order item stores for Zenfoo/vendors (exclude combo items)
        foreach ($orderItemStoreIds as $storeId) {
            $store = $stores[$storeId] ?? null;
            if ($store && $store->managed_by_admin == 1) {
                $hasZenfoo = true;
            } else {
                $tracking = $sellerTracking[$storeId] ?? null;
                $seller = ($tracking && $tracking->seller_id) ? ($sellers[$tracking->seller_id] ?? null) : null;
                if ($seller) {
                    $vendorsList[] = [
                        'id' => $seller->id,
                        'name' => $seller->store_name,
                    ];
                }
            }
        }

        $hasCombos = $comboItems->isNotEmpty();

        $response = [
            'order_id' => $orderId,
            'has_combos' => $hasCombos,
            'has_zenfoo' => $hasZenfoo,
            'vendors' => $vendorsList,
        ];

        return CommonHelper::responseSuccess($response, 'Order items fetched successfully.');
    }

    public function getOrderItemDetails(Request $request)
    {
        // Handle vendor_ids as comma-separated string, array, or single vendor_id
        $vendorIdsInput = $request->input('vendor_ids') ?? $request->input('vendor_id');
        if (is_string($vendorIdsInput) && !empty($vendorIdsInput)) {
            $request->merge(['vendor_ids' => array_map('intval', explode(',', $vendorIdsInput))]);
        } elseif (is_numeric($vendorIdsInput)) {
            $request->merge(['vendor_ids' => [(int) $vendorIdsInput]]);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'combo' => 'nullable|in:true,false,1,0,yes,no',
            'zenfoo' => 'nullable|in:true,false,1,0,yes,no',
            'vendor_ids' => 'nullable|array',
            'vendor_ids.*' => 'integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        $orderId = $request->input('order_id');
        $includeCombo = filter_var($request->input('combo', false), FILTER_VALIDATE_BOOLEAN);
        $includeZenfoo = filter_var($request->input('zenfoo', false), FILTER_VALIDATE_BOOLEAN);
        $vendorIds = $request->input('vendor_ids', []);

        // Get order items
        $orderItems = OrderItem::where('order_id', $orderId)
            ->select('id', 'order_id', 'product_variant_id', 'product_name', 'variant_name', 'quantity', 'price', 'discounted_price', 'sub_total')
            ->get();

        // Get combo items
        $comboItems = DB::table('order_combo_items')
            ->where('order_id', $orderId)
            ->get();

        if ($orderItems->isEmpty() && $comboItems->isEmpty()) {
            return CommonHelper::responseError('No order items found for this order.');
        }

        // Get variant and product mappings
        $variantIds = $orderItems->pluck('product_variant_id')->toArray();

        $variantDetails = DB::table('product_variants')
            ->whereIn('id', $variantIds)
            ->select('id', 'product_id', 'measurement', 'stock_unit_id', 'type')
            ->get()
            ->keyBy('id');

        $productIds = $variantDetails->pluck('product_id')->unique()->toArray();

        $productDetails = DB::table('products')
            ->whereIn('id', $productIds)
            ->select('id', 'name', 'store_id', 'return_status', 'return_days')
            ->get()
            ->keyBy('id');

        // Get all store IDs
        $allStoreIds = $productDetails->pluck('store_id')->unique()->toArray();

        // Get stores info
        $stores = DB::table('stores')
            ->whereIn('id', $allStoreIds)
            ->select('id', 'name', 'managed_by_admin')
            ->get()
            ->keyBy('id');

        // Get Zenfoo store IDs (managed_by_admin = 1)
        $zenfooStoreIds = $stores->filter(function ($store) {
            return $store->managed_by_admin == 1;
        })->pluck('id')->toArray();

        // Get vendor store IDs
        $vendorStoreIds = $stores->filter(function ($store) {
            return $store->managed_by_admin != 1;
        })->pluck('id')->toArray();

        // Get sellers for vendor stores via order_seller_status_tracking
        // (multiple sellers can share the same store_id, so use the tracking
        //  table to get the exact seller assigned to this order's store)
        $sellerTracking = collect([]);
        if (!empty($vendorStoreIds)) {
            $sellerTracking = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->whereIn('store_id', $vendorStoreIds)
                ->select('store_id', 'seller_id')
                ->get()
                ->keyBy('store_id');
        }

        $sellers = collect([]);
        $trackingSellerIds = $sellerTracking->pluck('seller_id')->filter()->unique()->toArray();
        if (!empty($trackingSellerIds)) {
            $sellers = DB::table('sellers')
                ->whereIn('id', $trackingSellerIds)
                ->select('id', 'store_id', 'name', 'store_name')
                ->get()
                ->keyBy('id');
        }

        // Build seller ID to store ID map
        $sellerToStoreMap = $sellers->pluck('store_id', 'id')->toArray();

        // Get units for measurement
        $unitIds = $variantDetails->pluck('stock_unit_id')->unique()->toArray();
        $units = DB::table('units')
            ->whereIn('id', $unitIds)
            ->pluck('short_code', 'id')
            ->toArray();

        // Get order delivered time for return eligibility check
        $order = DB::table('orders')->where('id', $orderId)->select('id', 'delivered_at_time')->first();
        $deliveredAt = $order && $order->delivered_at_time ? \Carbon\Carbon::parse($order->delivered_at_time) : null;

        $response = [
            'order_id' => $orderId,
            'store_wise_items' => [],
            'combo_items' => [],
        ];

        // Group items by store
        $storeWiseItems = [];

        // Filter and build regular items
        foreach ($orderItems as $item) {
            $variant = $variantDetails[$item->product_variant_id] ?? null;
            $product = $variant ? ($productDetails[$variant->product_id] ?? null) : null;
            $storeId = $product ? $product->store_id : 0;
            $store = $stores[$storeId] ?? null;

            $isZenfooStore = $store && $store->managed_by_admin == 1;

            // Resolve seller via tracking table (store_id → seller_id → seller)
            $tracking = !$isZenfooStore ? ($sellerTracking[$storeId] ?? null) : null;
            $seller = ($tracking && $tracking->seller_id) ? ($sellers[$tracking->seller_id] ?? null) : null;
            $sellerId = $seller ? $seller->id : null;

            // Apply filters
            $shouldInclude = false;

            if ($includeZenfoo && $isZenfooStore) {
                $shouldInclude = true;
            }

            if (!empty($vendorIds) && $sellerId && in_array($sellerId, $vendorIds)) {
                $shouldInclude = true;
            }

            // If no filters specified, include all
            if (!$includeZenfoo && !$includeCombo && empty($vendorIds)) {
                $shouldInclude = true;
            }

            if ($shouldInclude) {
                // For managed_by_admin stores, use store name from stores table
                // For vendor stores, use seller name from sellers table
                if ($isZenfooStore) {
                    $storeName = $store ? $store->name : 'Unknown';
                } else {
                    $storeName = $seller ? $seller->store_name : ($store ? $store->name : 'Unknown');
                }

                // Initialize store group if not exists
                if (!isset($storeWiseItems[$storeId])) {
                    $storeWiseItems[$storeId] = [
                        'store_id' => $storeId,
                        'store_name' => $storeName,
                        'items' => [],
                    ];
                }

                // Check return eligibility
                $isReturnable = false;
                $returnDays = 0;
                $remainingReturnDays = 0;
                if ($product && $product->return_status == 1 && $product->return_days > 0) {
                    $returnDays = $product->return_days;
                    if ($deliveredAt) {
                        $daysSinceDelivery = (int) $deliveredAt->diffInDays(now());
                        $remainingReturnDays = max(0, $product->return_days - $daysSinceDelivery);
                        $isReturnable = $remainingReturnDays > 0;
                    } else {
                        // Not yet delivered, return window hasn't started
                        $isReturnable = true;
                        $remainingReturnDays = $product->return_days;
                    }
                }

                $storeWiseItems[$storeId]['items'][] = [
                    'product_id' => $item->id,
                    'product_name' => $item->product_name ?? ($product ? $product->name : ''),
                    'variant_measurement' => $item->variant_name ?? '',
                    'price' => $item->discounted_price,
                    'actual_price' => $item->price,
                    'quantity' => $item->quantity,
                    'sub_total' => $item->sub_total,
                    'is_returnable' => $isReturnable,
                    'return_days' => $returnDays,
                    'remaining_return_days' => $remainingReturnDays,
                    'is_still_return_available' => $isReturnable && $remainingReturnDays > 0,
                ];
            }
        }

        $response['store_wise_items'] = array_values($storeWiseItems);

        // Filter and build combo items
        if ($includeCombo || (!$includeZenfoo && !$includeCombo && empty($vendorIds))) {
            // Collect all stock unit IDs and product IDs from combo products
            $comboStockUnitIds = [];
            $comboProductIds = [];
            foreach ($comboItems as $combo) {
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
                            if (!empty($product['product_id'])) {
                                $comboProductIds[] = $product['product_id'];
                            }
                        }
                    }
                }
            }

            // Fetch return info for combo products
            $comboProductDetails = [];
            if (!empty($comboProductIds)) {
                $comboProductDetails = DB::table('products')
                    ->whereIn('id', array_unique($comboProductIds))
                    ->select('id', 'return_status', 'return_days')
                    ->get()
                    ->keyBy('id');
            }

            // Fetch units for combo products
            $comboUnits = [];
            if (!empty($comboStockUnitIds)) {
                $comboUnits = DB::table('units')
                    ->whereIn('id', array_unique($comboStockUnitIds))
                    ->pluck('short_code', 'id')
                    ->toArray();
            }

            foreach ($comboItems as $combo) {
                $comboData = [
                    'id' => $combo->id,
                    'combo_name' => $combo->combo_name ?? '',
                    'combo_quantity' => $combo->combo_quantity ?? 1,
                    'sub_total' => $combo->sub_total ?? 0,
                    'discount_percentage' => $combo->discount_percentage ?? 0,
                    'total_actual_price' => $combo->total_actual_price ?? 0,
                    'total_products_price' => $combo->total_products_price ?? 0,
                    'products' => [],
                ];

                if (!empty($combo->products)) {
                    $products = json_decode($combo->products, true);
                    if (is_string($products)) {
                        $products = json_decode($products, true);
                    }
                    if (is_array($products)) {
                        foreach ($products as $product) {
                            $measurement = $product['variant_measurement'] ?? '';
                            $stockUnitId = $product['variant_stock_unit_id'] ?? null;
                            $unitShortCode = $stockUnitId ? ($comboUnits[$stockUnitId] ?? '') : '';

                            // Format variant_measurement with unit
                            $variantMeasurement = $measurement . ($unitShortCode ? ' ' . $unitShortCode : '');

                            // Check return eligibility for combo product
                            $comboProductId = $product['product_id'] ?? 0;
                            $comboProduct = $comboProductDetails[$comboProductId] ?? null;
                            $isReturnable = false;
                            $returnDays = 0;
                            $remainingReturnDays = 0;
                            if ($comboProduct && $comboProduct->return_status == 1 && $comboProduct->return_days > 0) {
                                $returnDays = $comboProduct->return_days;
                                if ($deliveredAt) {
                                    $daysSinceDelivery = (int) $deliveredAt->diffInDays(now());
                                    $remainingReturnDays = max(0, $comboProduct->return_days - $daysSinceDelivery);
                                    $isReturnable = $remainingReturnDays > 0;
                                } else {
                                    // Not yet delivered, return window hasn't started
                                    $isReturnable = true;
                                    $remainingReturnDays = $comboProduct->return_days;
                                }
                            }

                            $comboData['products'][] = [
                                'product_id' => $comboProductId,
                                'product_name' => $product['product_name'] ?? '',
                                'variant_measurement' => trim($variantMeasurement),
                                'price' => $product['price'] ?? 0,
                                'actual_price' => $product['actual_price'] ?? 0,
                                'quantity' => $product['quantity'] ?? 1,
                                'sub_total' => $product['sub_total'] ?? 0,
                                'is_returnable' => $isReturnable,
                                'return_days' => $returnDays,
                                'remaining_return_days' => $remainingReturnDays,
                                'is_still_return_available' => $isReturnable && $remainingReturnDays > 0,
                            ];
                        }
                    }
                }

                $response['combo_items'][] = $comboData;
            }
        }

        return CommonHelper::responseSuccess($response, 'Order item details fetched successfully.');
    }

    public function storeItemMissingReport(Request $request)
    {
        // Handle JSON string inputs for arrays (from URL params or JSON body)
        $normalItems = $request->input('normal_items');
        $comboItems = $request->input('combo_items');
        $isRefundRequested = $request->input('is_refund_requested');

        // Log the raw input for debugging
        Log::info('Issue Report Raw Input', [
            'normal_items_raw' => $normalItems,
            'normal_items_type' => gettype($normalItems),
            'combo_items_raw' => $comboItems,
            'combo_items_type' => gettype($comboItems),
            'is_refund_requested_raw' => $isRefundRequested,
            'is_refund_requested_type' => gettype($isRefundRequested),
        ]);

        // Decode if string
        if (is_string($normalItems) && !empty($normalItems)) {
            $decoded = json_decode($normalItems, true);
            if (json_last_error() === JSON_ERROR_NONE) {
                $normalItems = $decoded;
                $request->merge(['normal_items' => $normalItems]);
            } else {
                Log::warning('Failed to decode normal_items JSON', [
                    'error' => json_last_error_msg(),
                    'input' => $normalItems
                ]);
            }
        }

        if (is_string($comboItems) && !empty($comboItems)) {
            $decoded = json_decode($comboItems, true);
            if (json_last_error() === JSON_ERROR_NONE) {
                $comboItems = $decoded;
                $request->merge(['combo_items' => $comboItems]);
            } else {
                Log::warning('Failed to decode combo_items JSON', [
                    'error' => json_last_error_msg(),
                    'input' => $comboItems
                ]);
            }
        }

        // Convert string boolean to actual boolean
        if (is_string($isRefundRequested)) {
            $isRefundRequested = filter_var($isRefundRequested, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
            if ($isRefundRequested !== null) {
                $request->merge(['is_refund_requested' => $isRefundRequested]);
            }
        }

        // If still not array, set to empty array
        if (!is_array($normalItems)) {
            $normalItems = [];
            $request->merge(['normal_items' => []]);
        }

        if (!is_array($comboItems)) {
            $comboItems = [];
            $request->merge(['combo_items' => []]);
        }

        Log::info('Issue Report Processed Input', [
            'normal_items' => $normalItems,
            'combo_items' => $comboItems,
            'is_refund_requested' => $isRefundRequested,
        ]);

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'type' => 'required|in:missing,wrong,return',
            'normal_items' => 'array',
            'normal_items.*.store_id' => 'sometimes|integer',
            'normal_items.*.product_ids' => 'sometimes|array',
            'normal_items.*.product_ids.*' => 'integer',
            'normal_items.*.description' => 'nullable|string',
            'combo_items' => 'array',
            'combo_items.*.combo_id' => 'sometimes|integer',
            'combo_items.*.product_ids' => 'sometimes|array',
            'combo_items.*.product_ids.*' => 'integer',
            'combo_items.*.description' => 'nullable|string',
            'description' => 'nullable|string',
            'is_refund_requested' => 'required|boolean',
            // Store-wise images: normal_items_images[store_id][] = image files
            'normal_items_images' => 'nullable|array',
            'normal_items_images.*' => 'nullable|array',
            'normal_items_images.*.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            // Combo-wise images: combo_items_images[combo_id][] = image files
            'combo_items_images' => 'nullable|array',
            'combo_items_images.*' => 'nullable|array',
            'combo_items_images.*.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        if ($validator->fails()) {
            Log::error('Issue Report Validation Failed', [
                'errors' => $validator->errors()->toArray(),
                'input' => $request->all(),
            ]);
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        // Extract data from request (works for both JSON body and query params)
        $orderId = $request->input('order_id');
        $reportType = $request->input('type');
        $normalItemsInput = $request->input('normal_items', []);
        $comboItemsInput = $request->input('combo_items', []);
        $description = $request->input('description', '');
        $isRefundRequested = $request->input('is_refund_requested', false);

        // Handle JSON string input
        if (is_string($normalItemsInput)) {
            $normalItemsInput = json_decode($normalItemsInput, true) ?? [];
        }
        if (is_string($comboItemsInput)) {
            $comboItemsInput = json_decode($comboItemsInput, true) ?? [];
        }

        // Collect all product IDs from all stores
        $allProductIds = [];
        foreach ($normalItemsInput as $storeItem) {
            $productIds = $storeItem['product_ids'] ?? [];
            if (is_string($productIds)) {
                $productIds = json_decode($productIds, true) ?? [];
            }
            $allProductIds = array_merge($allProductIds, $productIds);
        }

        // Collect all combo IDs
        $allComboIds = [];
        foreach ($comboItemsInput as $comboItem) {
            if (!empty($comboItem['combo_id'])) {
                $allComboIds[] = $comboItem['combo_id'];
            }
            // Also handle product_ids in combo items
            if (isset($comboItem['product_ids']) && is_string($comboItem['product_ids'])) {
                $comboItem['product_ids'] = json_decode($comboItem['product_ids'], true) ?? [];
            }
        }

        // Validate that at least one item or combo is selected
        if (empty($allProductIds) && empty($allComboIds)) {
            return CommonHelper::responseError('Please select at least one item or combo to report.');
        }

        // Fetch normal items details from order_items table
        $selectedItems = [];
        if (!empty($allProductIds)) {
            $orderItems = OrderItem::where('order_id', $orderId)
                ->whereIn('id', $allProductIds)
                ->select('id', 'product_variant_id', 'product_name', 'variant_name', 'quantity', 'price', 'discounted_price', 'sub_total')
                ->get()
                ->keyBy('id');

            // Get product and store details
            $variantIds = $orderItems->pluck('product_variant_id')->toArray();
            $variantDetails = DB::table('product_variants')
                ->whereIn('id', $variantIds)
                ->select('id', 'product_id')
                ->get()
                ->keyBy('id');

            $productIds = $variantDetails->pluck('product_id')->unique()->toArray();
            $productDetails = DB::table('products')
                ->whereIn('id', $productIds)
                ->select('id', 'store_id')
                ->get()
                ->keyBy('id');

            $storeIds = $productDetails->pluck('store_id')->unique()->toArray();
            $stores = DB::table('stores')
                ->whereIn('id', $storeIds)
                ->select('id', 'name', 'managed_by_admin')
                ->get()
                ->keyBy('id');

            // Get sellers for vendor stores via order_seller_status_tracking
            // (multiple sellers can share the same store_id, so we use the tracking
            //  table to get the exact seller assigned to this order's store)
            $vendorStoreIds = $stores->filter(function ($store) {
                return $store->managed_by_admin != 1;
            })->pluck('id')->toArray();

            // Map store_id → seller_id for this specific order
            $sellerTracking = collect([]);
            if (!empty($vendorStoreIds)) {
                $sellerTracking = DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->whereIn('store_id', $vendorStoreIds)
                    ->select('store_id', 'seller_id')
                    ->get()
                    ->keyBy('store_id');
            }

            $sellers = collect([]);
            $trackingSellerIds = $sellerTracking->pluck('seller_id')->filter()->unique()->toArray();
            if (!empty($trackingSellerIds)) {
                $sellers = DB::table('sellers')
                    ->whereIn('id', $trackingSellerIds)
                    ->select('id', 'store_id', 'store_name')
                    ->get()
                    ->keyBy('id');
            }

            // Build store-wise items with their own descriptions and images
            $storeWiseItems = [];
            $normalItemsImages = $request->file('normal_items_images') ?? [];

            foreach ($normalItemsInput as $storeItem) {
                $storeProductIds = $storeItem['product_ids'] ?? [];
                $storeDescription = $storeItem['description'] ?? '';
                $inputStoreId = $storeItem['store_id'] ?? 0;

                if (empty($storeProductIds)) {
                    continue;
                }

                $store = $stores[$inputStoreId] ?? null;
                $isZenfooStore = $store && $store->managed_by_admin == 1;

                // Resolve seller via tracking table (store_id → seller_id → seller)
                $tracking = !$isZenfooStore ? ($sellerTracking[$inputStoreId] ?? null) : null;
                $seller = ($tracking && $tracking->seller_id) ? ($sellers[$tracking->seller_id] ?? null) : null;

                if ($isZenfooStore) {
                    $storeName = $store ? $store->name : 'Unknown';
                } else {
                    $storeName = $seller ? $seller->store_name : ($store ? $store->name : 'Unknown');
                }

                $items = [];
                foreach ($storeProductIds as $productId) {
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

                // Upload store-wise images if provided
                $storeImageUrls = [];
                if (isset($normalItemsImages[$inputStoreId]) && is_array($normalItemsImages[$inputStoreId])) {
                    foreach ($normalItemsImages[$inputStoreId] as $image) {
                        try {
                            $imageUrl = MediaUploadService::uploadWithFullUrl(
                                $image,
                                'issue_reports/missing/stores',
                                'public'
                            );
                            $storeImageUrls[] = $imageUrl;
                        } catch (\Exception $e) {
                            Log::error('Failed to upload store issue report image', [
                                'store_id' => $inputStoreId,
                                'error' => $e->getMessage(),
                            ]);
                        }
                    }
                }

                if (!empty($items)) {
                    $storeWiseItems[] = [
                        'store_id' => $inputStoreId,
                        'store_name' => $storeName,
                        'description' => $storeDescription,
                        'image_urls' => !empty($storeImageUrls) ? $storeImageUrls : null,
                        'items' => $items,
                    ];
                }
            }

            $selectedItems = $storeWiseItems;
        }

        // Fetch combo items details from order_combo_items table
        $selectedComboItems = [];
        if (!empty($allComboIds)) {
            $orderComboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->whereIn('id', $allComboIds)
                ->get()
                ->keyBy('id');

            $combos = [];
            $comboItemsImages = $request->file('combo_items_images') ?? [];

            foreach ($comboItemsInput as $comboInput) {
                $comboId = $comboInput['combo_id'] ?? 0;
                $selectedProductIds = $comboInput['product_ids'] ?? [];
                $comboDescription = $comboInput['description'] ?? '';

                $combo = $orderComboItems[$comboId] ?? null;
                if (!$combo) {
                    continue;
                }

                // Upload combo-wise images if provided
                $comboImageUrls = [];
                if (isset($comboItemsImages[$comboId]) && is_array($comboItemsImages[$comboId])) {
                    foreach ($comboItemsImages[$comboId] as $image) {
                        try {
                            $imageUrl = MediaUploadService::uploadWithFullUrl(
                                $image,
                                'issue_reports/missing/combos',
                                'public'
                            );
                            $comboImageUrls[] = $imageUrl;
                        } catch (\Exception $e) {
                            Log::error('Failed to upload combo issue report image', [
                                'combo_id' => $comboId,
                                'error' => $e->getMessage(),
                            ]);
                        }
                    }
                }

                $comboData = [
                    'id' => $combo->id,
                    'combo_name' => $combo->combo_name ?? '',
                    'combo_quantity' => $combo->combo_quantity ?? 1,
                    'sub_total' => $combo->sub_total ?? 0,
                    'description' => $comboDescription,
                    'image_urls' => !empty($comboImageUrls) ? $comboImageUrls : null,
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
                            // Only include selected products
                            if (in_array($productId, $selectedProductIds)) {
                                $comboData['products'][] = [
                                    'product_id' => $productId,
                                    'product_name' => $product['product_name'] ?? '',
                                    'variant_measurement' => $product['variant_measurement'] ?? '',
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
                    $combos[] = $comboData;
                }
            }

            $selectedComboItems = $combos;
        }

        // Create the report (images are stored within selected_items and selected_combo_items)
        $report = CustomerItemMissingReport::create([
            'customer_id' => $user->id,
            'order_id' => $orderId,
            'report_type' => $reportType,
            'selected_items' => !empty($selectedItems) ? $selectedItems : null,
            'selected_combo_items' => !empty($selectedComboItems) ? $selectedComboItems : null,
            'description' => $description,
            'is_refund_requested' => $isRefundRequested,
            'status' => CustomerItemMissingReport::$statusPending,
        ]);

        // Update order active_status to returned
        try {
            DB::table('orders')
                ->where('id', $orderId)
                ->update(['active_status' => OrderStatusList::$returned]);
        } catch (\Exception $e) {
            Log::error('Failed to update order active_status for missing item report', [
                'report_id' => $report->id,
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }

        // Send notification to admin panel
        try {
            AdminNotificationService::notifyCustomerIssueReport(
                $report->id,
                $orderId,
                $reportType,
                $user->name ?? 'Customer'
            );
        } catch (\Exception $e) {
            Log::error('Failed to send admin notification for missing item report', [
                'report_id' => $report->id,
                'error' => $e->getMessage(),
            ]);
        }

        return CommonHelper::responseSuccess([
            'report_id' => $report->id,
            'order_id' => $report->order_id,
            'status' => $report->status_name,
        ], 'Issue report submitted successfully.');
    }

    public function getReports(Request $request)
    {
        Log::info('CustomerIssueReportController::getReports - Request received', [
            'params' => $request->all(),
        ]);

        // Convert is_refund_requested string to boolean
        if ($request->has('is_refund_requested') && is_string($request->is_refund_requested)) {
            $request->merge([
                'is_refund_requested' => filter_var($request->is_refund_requested, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)
            ]);
        }

        $validator = Validator::make($request->all(), [
            'report_id' => 'nullable|integer',
            'order_id' => 'nullable|integer',
            'report_type' => 'nullable|string|in:missing,wrong,return',
            'status' => 'nullable|integer|in:0,1,2,3',
            'is_refund_requested' => 'nullable|boolean',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        if ($validator->fails()) {
            Log::warning('CustomerIssueReportController::getReports - Validation failed', [
                'errors' => $validator->errors()->toArray(),
            ]);
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            Log::warning('CustomerIssueReportController::getReports - Unauthorized access attempt');
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        Log::info('CustomerIssueReportController::getReports - User authenticated', [
            'user_id' => $user->id,
        ]);

        // Build filters array
        $filters = [];

        if ($request->filled('report_id')) {
            $filters['report_id'] = $request->report_id;
        }

        if ($request->filled('order_id')) {
            $filters['order_id'] = $request->order_id;
        }

        if ($request->filled('report_type')) {
            $filters['report_type'] = $request->report_type;
        }

        if ($request->filled('status') || $request->input('status') === '0' || $request->input('status') === 0) {
            $filters['status'] = $request->status;
        }

        if ($request->filled('is_refund_requested')) {
            $filters['is_refund_requested'] = filter_var($request->is_refund_requested, FILTER_VALIDATE_BOOLEAN);
        }

        if ($request->filled('from_date')) {
            $filters['from_date'] = $request->from_date;
        }

        if ($request->filled('to_date')) {
            $filters['to_date'] = $request->to_date;
        }

        $perPage = (int) $request->input('per_page', 20);
        $page = (int) $request->input('page', 1);

        Log::info('CustomerIssueReportController::getReports - Calling service', [
            'user_id' => $user->id,
            'filters' => $filters,
            'page' => $page,
            'per_page' => $perPage,
        ]);

        // Call the service
        $result = CustomerIssueReportService::getReports(
            $user->id,
            $filters,
            $page,
            $perPage
        );

        if (!$result['success']) {
            Log::error('CustomerIssueReportController::getReports - Service returned error', [
                'user_id' => $user->id,
                'message' => $result['message'],
            ]);
            return CommonHelper::responseError($result['message']);
        }

        Log::info('CustomerIssueReportController::getReports - Service returned success', [
            'user_id' => $user->id,
            'reports_count' => count($result['reports']),
        ]);

        // Check if single report requested
        if (!empty($result['is_single_report']) && count($result['reports']) === 1) {
            return CommonHelper::responseSuccessWithData('Report fetched successfully.', $result['reports'][0]);
        }

        return CommonHelper::responseSuccessWithData($result['message'], [
            'reports' => $result['reports'],
            'pagination' => $result['pagination'],
        ]);
    }

    public function getReportById(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'report_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        try {
            $report = CustomerItemMissingReport::where('id', $request->report_id)
                ->where('customer_id', $user->id)
                ->first();

            if (!$report) {
                return CommonHelper::responseError('Report not found.');
            }

            $orderId = $report->order_id;
            $selectedItems = $report->selected_items ?? [];
            $selectedComboItems = $report->selected_combo_items ?? [];
            $reportType = $report->report_type ?? 'missing';

            // For 'wrong' report type, we use image_urls instead of product_ids
            if ($reportType === 'wrong') {
                // Build response for wrong item report (with images)
                $storeWiseItems = [];
                foreach ($selectedItems as $storeItem) {
                    $storeWiseItems[] = [
                        'store_id' => $storeItem['store_id'] ?? 0,
                        'store_name' => $storeItem['store_name'] ?? 'Unknown',
                        'image_urls' => $storeItem['image_urls'] ?? [],
                        'description' => $storeItem['description'] ?? '',
                    ];
                }

                $comboItems = [];
                foreach ($selectedComboItems as $comboItem) {
                    $comboItems[] = [
                        'combo_id' => $comboItem['combo_id'] ?? $comboItem['id'] ?? 0,
                        'combo_name' => $comboItem['combo_name'] ?? '',
                        'image_urls' => $comboItem['image_urls'] ?? [],
                        'description' => $comboItem['description'] ?? '',
                    ];
                }
            } else {
                // Build response for missing item report (with product details)
                $allProductIds = [];
                foreach ($selectedItems as $storeItem) {
                    foreach ($storeItem['items'] ?? [] as $item) {
                        $allProductIds[] = $item['product_id'];
                    }
                }

                $allComboIds = [];
                foreach ($selectedComboItems as $comboItem) {
                    $allComboIds[] = $comboItem['id'];
                }

                $storeWiseItems = [];
                if (!empty($allProductIds)) {
                    $orderItems = OrderItem::where('order_id', $orderId)
                        ->whereIn('id', $allProductIds)
                        ->select('id', 'product_variant_id', 'product_name', 'variant_name', 'quantity', 'price', 'discounted_price', 'sub_total')
                        ->get()
                        ->keyBy('id');

                    $variantIds = $orderItems->pluck('product_variant_id')->toArray();
                    $variantDetails = DB::table('product_variants')
                        ->whereIn('id', $variantIds)
                        ->select('id', 'product_id')
                        ->get()
                        ->keyBy('id');

                    $productIds = $variantDetails->pluck('product_id')->unique()->toArray();
                    $productDetails = DB::table('products')
                        ->whereIn('id', $productIds)
                        ->select('id', 'store_id')
                        ->get()
                        ->keyBy('id');

                    $storeIds = $productDetails->pluck('store_id')->unique()->toArray();
                    $stores = DB::table('stores')
                        ->whereIn('id', $storeIds)
                        ->select('id', 'name', 'managed_by_admin')
                        ->get()
                        ->keyBy('id');

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
                    }

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
                                'items' => $items,
                            ];
                        }
                    }
                }

                $comboItems = [];
                if (!empty($allComboIds)) {
                    $orderComboItems = DB::table('order_combo_items')
                        ->where('order_id', $orderId)
                        ->whereIn('id', $allComboIds)
                        ->get()
                        ->keyBy('id');

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

                    $comboUnits = [];
                    if (!empty($comboStockUnitIds)) {
                        $comboUnits = DB::table('units')
                            ->whereIn('id', array_unique($comboStockUnitIds))
                            ->pluck('short_code', 'id')
                            ->toArray();
                    }

                    foreach ($selectedComboItems as $storedComboItem) {
                        $comboId = $storedComboItem['id'] ?? 0;
                        $comboDescription = $storedComboItem['description'] ?? '';
                        $selectedProductIds = array_column($storedComboItem['products'] ?? [], 'product_id');

                        $combo = $orderComboItems[$comboId] ?? null;
                        if (!$combo) {
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
                        }
                    }
                }
            }

            // Fetch order details for additional info
            $order = DB::table('orders')->where('id', $orderId)->first();

            // Get customer details
            $customer = DB::table('users')
                ->where('id', $report->customer_id)
                ->select('id', 'name', 'mobile', 'email')
                ->first();

            // Get delivery partner details if exists
            $deliveryPartner = null;
            if ($order && $order->delivery_boy_id) {
                $deliveryPartner = DB::table('delivery_boys')
                    ->where('id', $order->delivery_boy_id)
                    ->select('id', 'name')
                    ->first();
            }

            // Extract delivery date from status array
            $deliveryDate = null;
            if ($order && $order->status) {
                $statusArray = json_decode($order->status, true);
                if (is_array($statusArray)) {
                    // Look for status 6 (delivered) or get the last status date
                    foreach ($statusArray as $statusItem) {
                        if (is_array($statusItem) && count($statusItem) >= 2) {
                            if ($statusItem[0] == 6) { // Delivered status
                                $deliveryDate = $statusItem[1];
                                break;
                            }
                        }
                    }
                    // If no delivered status found, get the last status date
                    if (!$deliveryDate && !empty($statusArray)) {
                        $lastStatus = end($statusArray);
                        if (is_array($lastStatus) && count($lastStatus) >= 2) {
                            $deliveryDate = $lastStatus[1];
                        }
                    }
                }
            }

            // Get stores and vendors from order items using product_variant -> product -> store chain
            $storesAndVendors = [];
            $hasZenfoo = false;
            $vendorsList = [];
            $combosList = [];

            if ($order) {
                // Get order items with product_variant_id
                $orderItemsForStores = DB::table('order_items')
                    ->where('order_id', $orderId)
                    ->select('product_variant_id')
                    ->get();

                $variantIdsForStores = $orderItemsForStores->pluck('product_variant_id')->toArray();

                if (!empty($variantIdsForStores)) {
                    // Get product IDs from variants
                    $variantProductMapForStores = DB::table('product_variants')
                        ->whereIn('id', $variantIdsForStores)
                        ->pluck('product_id', 'id');

                    // Get store IDs from products
                    $productStoreMap = DB::table('products')
                        ->whereIn('id', $variantProductMapForStores->values())
                        ->pluck('store_id', 'id');

                    $orderItemStoreIds = $productStoreMap->values()->unique()->toArray();

                    if (!empty($orderItemStoreIds)) {
                        $storesForOrder = DB::table('stores')
                            ->whereIn('id', $orderItemStoreIds)
                            ->select('id', 'name', 'managed_by_admin')
                            ->get()
                            ->keyBy('id');

                        $vendorStoreIdsForOrder = $storesForOrder->filter(function ($store) {
                            return $store->managed_by_admin != 1;
                        })->pluck('id')->toArray();

                        $sellersForOrder = collect([]);
                        if (!empty($vendorStoreIdsForOrder)) {
                            $sellersForOrder = DB::table('sellers')
                                ->whereIn('store_id', $vendorStoreIdsForOrder)
                                ->select('id', 'store_id', 'name', 'store_name')
                                ->get()
                                ->keyBy('store_id');
                        }

                        foreach ($orderItemStoreIds as $storeId) {
                            $store = $storesForOrder[$storeId] ?? null;
                            if ($store && $store->managed_by_admin == 1) {
                                $hasZenfoo = true;
                                $storesAndVendors[] = [
                                    'store_id' => $store->id,
                                    'store_name' => 'Zenfoo Store',
                                    'type' => 'zenfoo',
                                ];
                            } else if ($store) {
                                $seller = $sellersForOrder[$storeId] ?? null;
                                $vendorsList[] = [
                                    'id' => $seller ? $seller->id : null,
                                    'name' => $seller ? $seller->store_name : $store->name,
                                ];
                                $storesAndVendors[] = [
                                    'store_id' => $store->id,
                                    'store_name' => $seller ? $seller->store_name : $store->name,
                                    'vendor_id' => $seller ? $seller->id : null,
                                    'type' => 'vendor',
                                ];
                            }
                        }
                    }
                }

                // Get combo items from the order
                $orderCombos = DB::table('order_combo_items')
                    ->where('order_id', $orderId)
                    ->select('id', 'combo_id', 'combo_name')
                    ->get();

                foreach ($orderCombos as $combo) {
                    $combosList[] = [
                        'combo_id' => $combo->combo_id,
                        'combo_name' => $combo->combo_name,
                    ];
                    $storesAndVendors[] = [
                        'combo_id' => $combo->combo_id,
                        'combo_name' => $combo->combo_name,
                        'type' => 'combo',
                    ];
                }
            }

            $response = [
                'report_id' => $report->id,
                'order_id' => $report->order_id,
                'report_type' => $reportType,
                'description' => $report->description,
                'is_refund_requested' => $report->is_refund_requested,
                'status' => $report->status,
                'status_name' => $report->status_name,
                'admin_remarks' => $report->admin_remarks,
                'created_at' => $report->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $report->updated_at->format('Y-m-d H:i:s'),
                'store_wise_items' => $storeWiseItems,
                'combo_items' => $comboItems,
                'order_details' => [
                    'customer' => $customer ? [
                        'id' => $customer->id,
                        'name' => $customer->name,
                        'mobile' => $customer->mobile,
                        'email' => $customer->email,
                    ] : null,
                    'delivery_partner' => $deliveryPartner ? [
                        'id' => $deliveryPartner->id,
                        'name' => $deliveryPartner->name,
                    ] : null,
                    'delivery_date' => $deliveryDate,
                    'has_zenfoo' => $hasZenfoo,
                    'vendors' => $vendorsList,
                    'combos' => $combosList,
                    'stores_and_vendors' => $storesAndVendors,
                ],
            ];

            return CommonHelper::responseSuccessWithData('Report fetched successfully.', $response);

        } catch (\Exception $e) {
            Log::error('Get Report By ID Error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id ?? null,
                'report_id' => $request->report_id,
            ]);
            return CommonHelper::responseError('Failed to fetch report. Please try again later.');
        }
    }

    public function storeWrongItemReport(Request $request)
    {
        // Convert string boolean to actual boolean for is_refund_requested
        if ($request->has('is_refund_requested') && is_string($request->is_refund_requested)) {
            $request->merge([
                'is_refund_requested' => filter_var($request->is_refund_requested, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)
            ]);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'description' => 'required|string|max:200',
            'is_refund_requested' => 'required|boolean',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        try {
            // Upload image using MediaUploadService
            $uploadResult = MediaUploadService::uploadWithFullUrl(
                $request->file('image'),
                'wrong_item_reports'
            );

            // Create the report
            $report = CustomerWrongItemReport::create([
                'customer_id' => $user->id,
                'order_id' => $request->order_id,
                'img_url' => $uploadResult['url'],
                'description' => $request->description,
                'is_refund_requested' => $request->is_refund_requested,
                'status' => CustomerWrongItemReport::$statusPending,
            ]);

            return CommonHelper::responseSuccessWithData('Wrong item report submitted successfully.', [
                'report_id' => $report->id,
                'order_id' => $report->order_id,
                'img_url' => $report->img_url,
                'description' => $report->description,
                'is_refund_requested' => $report->is_refund_requested,
                'status' => $report->status_name,
            ]);

        } catch (\Exception $e) {
            Log::error('Wrong Item Report Error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id,
            ]);
            return CommonHelper::responseError('Failed to submit report: ' . $e->getMessage());
        }
    }

    public function getWrongItemStoreList(Request $request)
    {
        // Convert string booleans to actual booleans
        if ($request->has('combo') && is_string($request->combo)) {
            $request->merge([
                'combo' => filter_var($request->combo, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)
            ]);
        }
        if ($request->has('zenfoo') && is_string($request->zenfoo)) {
            $request->merge([
                'zenfoo' => filter_var($request->zenfoo, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)
            ]);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'combo' => 'nullable|boolean',
            'zenfoo' => 'nullable|boolean',
            'vendor_id' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        $orderId = $request->input('order_id');

        try {
            // Parse filters - if not provided, treat as false (not needed)
            $showCombo = $request->has('combo') ? $request->boolean('combo') : false;
            $showZenfoo = $request->has('zenfoo') ? $request->boolean('zenfoo') : false;
            $vendorIds = [];
            if ($request->filled('vendor_id')) {
                $vendorIds = array_map('intval', explode(',', $request->vendor_id));
            }

            // Get order items
            $orderItems = OrderItem::where('order_id', $orderId)
                ->select('id', 'product_variant_id')
                ->get();

            // Get combo items
            $comboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->select('id', 'combo_name')
                ->get();

            if ($orderItems->isEmpty() && $comboItems->isEmpty()) {
                return CommonHelper::responseError('No order items found for this order.');
            }

            // Get variant and product mappings
            $variantIds = $orderItems->pluck('product_variant_id')->toArray();

            $variantDetails = DB::table('product_variants')
                ->whereIn('id', $variantIds)
                ->select('id', 'product_id')
                ->get()
                ->keyBy('id');

            $productIds = $variantDetails->pluck('product_id')->unique()->toArray();

            $productDetails = DB::table('products')
                ->whereIn('id', $productIds)
                ->select('id', 'store_id')
                ->get()
                ->keyBy('id');

            // Get all store IDs
            $allStoreIds = $productDetails->pluck('store_id')->unique()->toArray();

            // Get stores info
            $stores = DB::table('stores')
                ->whereIn('id', $allStoreIds)
                ->select('id', 'name', 'managed_by_admin')
                ->get()
                ->keyBy('id');

            // Get vendor store IDs
            $vendorStoreIds = $stores->filter(function ($store) {
                return $store->managed_by_admin != 1;
            })->pluck('id')->toArray();

            // Get sellers for vendor stores
            $sellers = collect([]);
            if (!empty($vendorStoreIds)) {
                $sellers = DB::table('sellers')
                    ->whereIn('store_id', $vendorStoreIds)
                    ->select('id', 'store_id', 'store_name')
                    ->get()
                    ->keyBy('store_id');
            }

            // Build store list with filters
            $storeList = [];
            foreach ($allStoreIds as $storeId) {
                $store = $stores[$storeId] ?? null;
                if (!$store) continue;

                $isZenfooStore = $store->managed_by_admin == 1;

                // Apply zenfoo filter
                if ($isZenfooStore && !$showZenfoo) {
                    continue;
                }

                // For vendor stores (non-zenfoo): only include if vendor_id is provided
                if (!$isZenfooStore) {
                    // Skip vendor stores if no vendor_id filter is provided
                    if (empty($vendorIds)) {
                        continue;
                    }
                    // If vendor_id filter is provided, only show specified vendors
                    $seller = $sellers[$storeId] ?? null;
                    $sellerId = $seller ? $seller->id : null;
                    if (!in_array($sellerId, $vendorIds)) {
                        continue;
                    }
                }

                if ($isZenfooStore) {
                    $storeName = 'Zenfoo Store';
                } else {
                    $seller = $sellers[$storeId] ?? null;
                    $storeName = $seller ? $seller->store_name : $store->name;
                }

                $storeList[] = [
                    'store_id' => $storeId,
                    'store_name' => $storeName,
                ];
            }

            // Add combos if exists and combo filter is true
            $comboList = [];
            if ($showCombo && $comboItems->isNotEmpty()) {
                foreach ($comboItems as $combo) {
                    $comboList[] = [
                        'combo_id' => $combo->id,
                        'combo_name' => $combo->combo_name,
                    ];
                }
            }

            return CommonHelper::responseSuccessWithData('Store list fetched successfully.', [
                'order_id' => $orderId,
                'store_list' => $storeList,
                'combo_list' => $comboList,
            ]);

        } catch (\Exception $e) {
            Log::error('Get Wrong Item Store List Error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id ?? null,
                'order_id' => $orderId ?? null,
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch store list. Please try again later.');
        }
    }

    public function storeWrongItemReportWithImages(Request $request)
    {
        // Convert string boolean to actual boolean for is_refund_requested
        if ($request->has('is_refund_requested') && is_string($request->is_refund_requested)) {
            $request->merge([
                'is_refund_requested' => filter_var($request->is_refund_requested, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)
            ]);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'normal_items' => 'nullable|array',
            'normal_items.*.store_id' => 'required|integer',
            'normal_items.*.images' => 'required|array|min:1',
            'normal_items.*.images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'normal_items.*.description' => 'nullable|string|max:200',
            'combo_items' => 'nullable|array',
            'combo_items.*.combo_id' => 'required|integer',
            'combo_items.*.images' => 'required|array|min:1',
            'combo_items.*.images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:5120',
            'combo_items.*.description' => 'nullable|string|max:200',
            'description' => 'nullable|string',
            'is_refund_requested' => 'required|boolean',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = Auth::guard('api-customers')->user();

        if (!$user) {
            return CommonHelper::responseError('Unauthorized. Please login to continue.');
        }

        $normalItemsInput = $request->input('normal_items', []);
        $comboItemsInput = $request->input('combo_items', []);

        Log::info('Wrong Item Report Initial Input', [
            'normal_items_input' => $normalItemsInput,
            'normal_items_input_type' => gettype($normalItemsInput),
            'combo_items_input' => $comboItemsInput,
            'combo_items_input_type' => gettype($comboItemsInput),
            'all_files' => $request->allFiles(),
        ]);

        // Validate at least one item or combo is provided
        if (empty($normalItemsInput) && empty($comboItemsInput)) {
            return CommonHelper::responseError('Please provide at least one store item or combo item with images.');
        }

        try {
            $orderId = $request->order_id;

            // Process normal items with images
            $selectedItems = [];
            if (!empty($normalItemsInput)) {
                foreach ($normalItemsInput as $index => $storeItem) {
                    Log::info("Processing normal item index: {$index}", [
                        'store_item' => $storeItem,
                        'index' => $index,
                    ]);

                    $storeId = $storeItem['store_id'];
                    $storeDescription = $storeItem['description'] ?? '';
                    $imageUrls = [];

                    // Upload each image for this store
                    $normalItemsFiles = $request->file('normal_items');

                    Log::info("Normal items files retrieved", [
                        'index' => $index,
                        'normalItemsFiles_type' => gettype($normalItemsFiles),
                        'normalItemsFiles_is_array' => is_array($normalItemsFiles),
                        'normalItemsFiles_value' => $normalItemsFiles,
                    ]);

                    $images = [];
                    if (is_array($normalItemsFiles) && isset($normalItemsFiles[$index]['images']) && is_array($normalItemsFiles[$index]['images'])) {
                        $images = $normalItemsFiles[$index]['images'];
                        Log::info("Images extracted for index {$index}", [
                            'images_count' => count($images),
                        ]);
                    } else {
                        Log::warning("Failed to extract images for index {$index}", [
                            'is_array' => is_array($normalItemsFiles),
                            'isset_check' => is_array($normalItemsFiles) ? isset($normalItemsFiles[$index]['images']) : false,
                            'is_array_check' => is_array($normalItemsFiles) && isset($normalItemsFiles[$index]['images']) ? is_array($normalItemsFiles[$index]['images']) : false,
                        ]);
                    }

                    foreach ($images as $imageIndex => $image) {
                        Log::info("Uploading image {$imageIndex} for store {$storeId}", [
                            'image_type' => gettype($image),
                            'image_class' => is_object($image) ? get_class($image) : 'not_object',
                        ]);

                        $uploadedUrl = MediaUploadService::uploadWithFullUrl($image, 'wrong_item_reports');
                        $imageUrls[] = $uploadedUrl;
                    }

                    // Get store name
                    $store = DB::table('stores')->where('id', $storeId)->first();
                    $storeName = 'Unknown';
                    if ($store) {
                        if ($store->managed_by_admin == 1) {
                            $storeName = $store->name;
                        } else {
                            $seller = DB::table('sellers')->where('store_id', $storeId)->first();
                            $storeName = $seller ? $seller->store_name : $store->name;
                        }
                    }

                    $selectedItems[] = [
                        'store_id' => $storeId,
                        'store_name' => $storeName,
                        'image_urls' => $imageUrls,
                        'description' => $storeDescription,
                    ];
                }
            }

            // Process combo items with images
            $selectedComboItems = [];
            if (!empty($comboItemsInput)) {
                foreach ($comboItemsInput as $index => $comboItem) {
                    Log::info("Processing combo item index: {$index}", [
                        'combo_item' => $comboItem,
                        'index' => $index,
                    ]);

                    $comboId = $comboItem['combo_id'];
                    $comboDescription = $comboItem['description'] ?? '';
                    $imageUrls = [];

                    // Upload each image for this combo
                    $comboItemsFiles = $request->file('combo_items');

                    Log::info("Combo items files retrieved", [
                        'index' => $index,
                        'comboItemsFiles_type' => gettype($comboItemsFiles),
                        'comboItemsFiles_is_array' => is_array($comboItemsFiles),
                        'comboItemsFiles_value' => $comboItemsFiles,
                    ]);

                    $images = [];
                    if (is_array($comboItemsFiles) && isset($comboItemsFiles[$index]['images']) && is_array($comboItemsFiles[$index]['images'])) {
                        $images = $comboItemsFiles[$index]['images'];
                        Log::info("Images extracted for combo index {$index}", [
                            'images_count' => count($images),
                        ]);
                    } else {
                        Log::warning("Failed to extract images for combo index {$index}", [
                            'is_array' => is_array($comboItemsFiles),
                            'isset_check' => is_array($comboItemsFiles) ? isset($comboItemsFiles[$index]['images']) : false,
                            'is_array_check' => is_array($comboItemsFiles) && isset($comboItemsFiles[$index]['images']) ? is_array($comboItemsFiles[$index]['images']) : false,
                        ]);
                    }

                    foreach ($images as $imageIndex => $image) {
                        Log::info("Uploading image {$imageIndex} for combo {$comboId}", [
                            'image_type' => gettype($image),
                            'image_class' => is_object($image) ? get_class($image) : 'not_object',
                        ]);

                        $uploadedUrl = MediaUploadService::uploadWithFullUrl($image, 'wrong_item_reports');
                        $imageUrls[] = $uploadedUrl;
                    }

                    // Get combo name from order_combo_items
                    $orderCombo = DB::table('order_combo_items')
                        ->where('order_id', $orderId)
                        ->where('id', $comboId)
                        ->first();

                    $selectedComboItems[] = [
                        'combo_id' => $comboId,
                        'combo_name' => $orderCombo->combo_name ?? '',
                        'image_urls' => $imageUrls,
                        'description' => $comboDescription,
                    ];
                }
            }

            // Create the report
            $report = CustomerItemMissingReport::create([
                'customer_id' => $user->id,
                'order_id' => $orderId,
                'report_type' => 'wrong',
                'selected_items' => !empty($selectedItems) ? $selectedItems : null,
                'selected_combo_items' => !empty($selectedComboItems) ? $selectedComboItems : null,
                'description' => $request->description,
                'is_refund_requested' => $request->is_refund_requested,
                'status' => CustomerItemMissingReport::$statusPending,
            ]);

            // Update order active_status to returned
            try {
                DB::table('orders')
                    ->where('id', $orderId)
                    ->update(['active_status' => OrderStatusList::$returned]);
            } catch (\Exception $e) {
                Log::error('Failed to update order active_status for wrong item report', [
                    'report_id' => $report->id,
                    'order_id' => $orderId,
                    'error' => $e->getMessage(),
                ]);
            }

            // Commented out: storing data in customer_issue_report_returns table
            // $sellerAssignments = DB::table('order_seller_status_tracking')
            //     ->where('order_id', $orderId)
            //     ->get()
            //     ->keyBy('store_id');

            // // dd($sellerAssignments);

            // $currentDate = now()->toDateString();
            // $returnRecords = [];
            // $processedSellers = [];

            // foreach ($selectedItems as $storeItem) {
            //     $storeId = (int) ($storeItem['store_id'] ?? 0);

            //     if ($storeId == 12) {
            //         continue;
            //     }

            //     $sellerAssignment = $sellerAssignments[$storeId] ?? null;
            //     if (!$sellerAssignment) {
            //         continue;
            //     }

            //     $sellerId = $sellerAssignment->seller_id;

            //     if (isset($processedSellers[$sellerId])) {
            //         continue;
            //     }
            //     $processedSellers[$sellerId] = true;

            //     $returnRecords[] = [
            //         'report_id' => $report->id,
            //         'seller_id' => $sellerId,
            //         'customer_id' => $user->id,
            //         'date' => $currentDate,
            //         'product_ids' => json_encode([]),
            //         'delivery_partner_id' => null,
            //         'delivered_date' => null,
            //         'is_return_accepted' => 0,
            //         'created_at' => now(),
            //         'updated_at' => now(),
            //     ];
            // }

            // foreach ($selectedComboItems as $comboItem) {
            //     $comboId = $comboItem['combo_id'] ?? 0;

            //     $orderCombo = DB::table('order_combo_items')
            //         ->where('order_id', $orderId)
            //         ->where('id', $comboId)
            //         ->first();

            //     if ($orderCombo && !empty($orderCombo->products)) {
            //         $products = json_decode($orderCombo->products, true);
            //         if (is_string($products)) {
            //             $products = json_decode($products, true);
            //         }

            //         if (is_array($products)) {
            //             $comboProductIds = array_column($products, 'product_id');
            //             $comboProductStoreMap = DB::table('products')
            //                 ->whereIn('id', $comboProductIds)
            //                 ->pluck('store_id', 'id')
            //                 ->toArray();

            //             foreach ($comboProductIds as $productId) {
            //                 $storeId = $comboProductStoreMap[$productId] ?? null;

            //                 if (!$storeId || $storeId == 12) {
            //                     continue;
            //                 }

            //                 $sellerAssignment = $sellerAssignments[$storeId] ?? null;
            //                 if (!$sellerAssignment) {
            //                     continue;
            //                 }

            //                 $sellerId = $sellerAssignment->seller_id;

            //                 if (isset($processedSellers[$sellerId])) {
            //                     continue;
            //                 }
            //                 $processedSellers[$sellerId] = true;

            //                 $returnRecords[] = [
            //                     'report_id' => $report->id,
            //                     'seller_id' => $sellerId,
            //                     'customer_id' => $user->id,
            //                     'date' => $currentDate,
            //                     'product_ids' => json_encode([]),
            //                     'delivery_partner_id' => null,
            //                     'delivered_date' => null,
            //                     'is_return_accepted' => 0,
            //                     'created_at' => now(),
            //                     'updated_at' => now(),
            //                 ];
            //             }
            //         }
            //     }
            // }

            // if (!empty($returnRecords)) {
            //     DB::table('customer_issue_report_returns')->insert($returnRecords);
            // }

            Log::info('Wrong item report created successfully', [
                'report_id' => $report->id,
                'order_id' => $report->order_id,
                'selected_items_count' => count($selectedItems),
                'selected_combo_items_count' => count($selectedComboItems),
            ]);

            // Send notification to admin panel
            try {
                AdminNotificationService::notifyCustomerIssueReport(
                    $report->id,
                    $orderId,
                    'wrong', // report type
                    $user->name ?? 'Customer'
                );
            } catch (\Exception $e) {
                Log::error('Failed to send admin notification for wrong item report', [
                    'report_id' => $report->id,
                    'error' => $e->getMessage(),
                ]);
            }

            return CommonHelper::responseSuccessWithData('Wrong item report submitted successfully.', [
                'report_id' => $report->id,
                'order_id' => $report->order_id,
                'report_type' => $report->report_type,
                'status' => $report->status_name,
            ]);

        } catch (\Exception $e) {
            Log::error('Wrong Item Report With Images Error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id,
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to submit report: ' . $e->getMessage());
        }
    }
}
