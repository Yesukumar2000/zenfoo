<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\CustomerItemMissingReport;
use App\Models\Order;
use App\Models\ProductVariant;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\CustomerIssueReportRefundService;
use App\Services\CustomerIssueReportReturnService;
use App\Services\CustomerNotificationService;
use App\Services\SellerNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class CustomerIssueReportsApiController extends Controller
{
    public function getReports(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'report_type' => 'nullable|string|in:missing,wrong,return',
            'status' => 'nullable|integer|in:0,1,2,3',
            'customer_id' => 'nullable|integer',
            'order_id' => 'nullable|integer',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $query = CustomerItemMissingReport::select(
                'customer_item_missing_reports.*',
                'users.name as customer_name',
                'users.mobile as customer_mobile'
            )
            ->leftJoin('users', 'customer_item_missing_reports.customer_id', '=', 'users.id');

            if ($request->filled('report_type')) {
                $query->where('customer_item_missing_reports.report_type', $request->report_type);
            }

            if ($request->filled('status') || $request->input('status') === '0' || $request->input('status') === 0) {
                $query->where('customer_item_missing_reports.status', $request->status);
            }

            if ($request->filled('customer_id')) {
                $query->where('customer_item_missing_reports.customer_id', $request->customer_id);
            }

            if ($request->filled('order_id')) {
                $query->where('customer_item_missing_reports.order_id', $request->order_id);
            }

            if ($request->filled('from_date')) {
                $query->whereDate('customer_item_missing_reports.created_at', '>=', $request->from_date);
            }

            if ($request->filled('to_date')) {
                $query->whereDate('customer_item_missing_reports.created_at', '<=', $request->to_date);
            }

            $reports = $query->orderBy('customer_item_missing_reports.created_at', 'desc')->get();

            // Transform reports for display with seller info
            $transformedReports = $reports->map(function ($report) {
                $reportType = $report->report_type ?? 'missing';
                $selectedItems = $report->selected_items ?? [];
                $selectedComboItems = $report->selected_combo_items ?? [];

                // For wrong item reports, enrich with seller info from order_seller_status_tracking
                if ($reportType === 'wrong') {
                    $orderId = $report->order_id;

                    // Get seller assignments from order_seller_status_tracking
                    $sellerAssignments = DB::table('order_seller_status_tracking')
                        ->where('order_id', $orderId)
                        ->get()
                        ->keyBy('store_id');

                    // Get seller details
                    $assignedSellerIds = $sellerAssignments->pluck('seller_id')->unique()->toArray();
                    $sellersInfo = [];
                    if (!empty($assignedSellerIds)) {
                        $sellersInfo = DB::table('sellers')
                            ->whereIn('id', $assignedSellerIds)
                            ->select('id', 'store_id', 'store_name', 'name')
                            ->get()
                            ->keyBy('id')
                            ->toArray();
                    }

                    // Build store_id => seller info map
                    $storeSellerMap = [];
                    foreach ($sellerAssignments as $storeId => $tracking) {
                        $sellerInfo = $sellersInfo[$tracking->seller_id] ?? null;
                        if ($sellerInfo) {
                            $storeSellerMap[$storeId] = [
                                'seller_id' => $tracking->seller_id,
                                'seller_name' => $sellerInfo->name,
                                'seller_store_name' => $sellerInfo->store_name,
                            ];
                        }
                    }

                    // Enrich selected_items with seller info
                    $enrichedItems = [];
                    foreach ($selectedItems as $storeItem) {
                        $storeId = (int) ($storeItem['store_id'] ?? 0);
                        $sellerData = $storeSellerMap[$storeId] ?? null;

                        // Apply store-specific packer logic
                        $packerName = null;
                        $packerStoreName = null;
                        $packerId = null;

                        if ($storeId == 12) {
                            $packerName = 'Zenfoo';
                            $packerStoreName = 'Zenfoo Store';
                        } elseif ($storeId == 17) {
                            // Store 17 (DMart) - store owner packs all orders, use store_name as seller
                            $packerName = $storeItem['store_name'] ?? 'DMart';
                            $packerStoreName = $storeItem['store_name'] ?? 'DMart';
                        } elseif (in_array($storeId, [13, 14, 15])) {
                            if ($sellerData) {
                                $packerId = $sellerData['seller_id'];
                                $packerName = $sellerData['seller_name'];
                                $packerStoreName = $sellerData['seller_store_name'];
                            }
                        } else {
                            if ($sellerData) {
                                $packerId = $sellerData['seller_id'];
                                $packerName = $sellerData['seller_name'];
                                $packerStoreName = $sellerData['seller_store_name'];
                            }
                        }

                        $enrichedItems[] = [
                            'store_id' => $storeItem['store_id'] ?? 0,
                            'store_name' => $storeItem['store_name'] ?? 'Unknown',
                            'image_urls' => $storeItem['image_urls'] ?? [],
                            'description' => $storeItem['description'] ?? '',
                            'seller_id' => $packerId,
                            'seller_name' => $packerName,
                            'seller_store_name' => $packerStoreName,
                        ];
                    }
                    $selectedItems = $enrichedItems;

                    // For combo items in wrong reports, get seller info per combo's products
                    $enrichedComboItems = [];
                    foreach ($selectedComboItems as $comboItem) {
                        $comboId = $comboItem['combo_id'] ?? $comboItem['id'] ?? 0;

                        // Get combo products to find their stores and sellers
                        $orderCombo = DB::table('order_combo_items')
                            ->where('order_id', $orderId)
                            ->where('id', $comboId)
                            ->first();

                        $comboSellers = [];
                        if ($orderCombo && !empty($orderCombo->products)) {
                            $products = json_decode($orderCombo->products, true);
                            if (is_string($products)) {
                                $products = json_decode($products, true);
                            }

                            if (is_array($products)) {
                                $comboProductIds = array_column($products, 'product_id');
                                $comboProductStoreMap = DB::table('products')
                                    ->whereIn('id', $comboProductIds)
                                    ->pluck('store_id', 'id')
                                    ->toArray();

                                // Get store names for store 17
                                $store17Name = DB::table('stores')->where('id', 17)->value('name') ?? 'DMart';

                                // Collect unique sellers for this combo
                                $seenSellers = [];
                                foreach ($comboProductIds as $productId) {
                                    $productStoreId = $comboProductStoreMap[$productId] ?? null;
                                    if ($productStoreId) {
                                        if ($productStoreId == 12) {
                                            if (!isset($seenSellers['zenfoo'])) {
                                                $comboSellers[] = [
                                                    'seller_id' => null,
                                                    'seller_name' => 'Zenfoo',
                                                    'seller_store_name' => 'Zenfoo Store',
                                                ];
                                                $seenSellers['zenfoo'] = true;
                                            }
                                        } elseif ($productStoreId == 17) {
                                            // Store 17 - store owner packs all orders
                                            if (!isset($seenSellers['store17'])) {
                                                $comboSellers[] = [
                                                    'seller_id' => null,
                                                    'seller_name' => $store17Name,
                                                    'seller_store_name' => $store17Name,
                                                ];
                                                $seenSellers['store17'] = true;
                                            }
                                        } else {
                                            $sellerData = $storeSellerMap[$productStoreId] ?? null;
                                            if ($sellerData && !isset($seenSellers[$sellerData['seller_id']])) {
                                                $comboSellers[] = [
                                                    'seller_id' => $sellerData['seller_id'],
                                                    'seller_name' => $sellerData['seller_name'],
                                                    'seller_store_name' => $sellerData['seller_store_name'],
                                                ];
                                                $seenSellers[$sellerData['seller_id']] = true;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        $enrichedComboItems[] = [
                            'combo_id' => $comboItem['combo_id'] ?? $comboItem['id'] ?? 0,
                            'combo_name' => $comboItem['combo_name'] ?? '',
                            'image_urls' => $comboItem['image_urls'] ?? [],
                            'description' => $comboItem['description'] ?? '',
                            'sellers' => $comboSellers,
                        ];
                    }
                    $selectedComboItems = $enrichedComboItems;
                }

                return [
                    'id' => $report->id,
                    'customer_id' => $report->customer_id,
                    'customer_name' => $report->customer_name,
                    'customer_mobile' => $report->customer_mobile,
                    'order_id' => $report->order_id,
                    'report_type' => $reportType,
                    'description' => $report->description,
                    'is_refund_requested' => $report->is_refund_requested,
                    'status' => $report->status,
                    'status_name' => $this->getStatusName($report->status),
                    'admin_remarks' => $report->admin_remarks,
                    'selected_items' => $selectedItems,
                    'selected_combo_items' => $selectedComboItems,
                    'created_at' => $report->created_at,
                    'updated_at' => $report->updated_at,
                ];
            });

            return CommonHelper::responseWithData($transformedReports);

        } catch (\Exception $e) {
            Log::error('Admin Get Issue Reports Error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch reports. Please try again later.');
        }
    }

    public function show(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $report = CustomerItemMissingReport::select(
                'customer_item_missing_reports.*',
                'users.name as customer_name',
                'users.mobile as customer_mobile',
                'users.email as customer_email'
            )
            ->leftJoin('users', 'customer_item_missing_reports.customer_id', '=', 'users.id')
            ->where('customer_item_missing_reports.id', $request->id)
            ->first();

            if (!$report) {
                return CommonHelper::responseError('Report not found.');
            }

            $orderId = $report->order_id;
            $selectedItems = $report->selected_items ?? [];
            $selectedComboItems = $report->selected_combo_items ?? [];
            $reportType = $report->report_type ?? 'missing';

            // Fetch order details
            $order = DB::table('orders')->where('id', $orderId)->first();

            // Get seller assignments from order_seller_status_tracking table (keyed by store_id)
            $sellerAssignments = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get()
                ->keyBy('store_id');

            // Get seller details for assignments (including address)
            $assignedSellerIds = $sellerAssignments->pluck('seller_id')->unique()->toArray();
            $sellersInfo = [];
            if (!empty($assignedSellerIds)) {
                $sellersInfo = DB::table('sellers')
                    ->whereIn('id', $assignedSellerIds)
                    ->select('id', 'store_id', 'store_name', 'name', 'mobile', 'store_location', 'lat_long')
                    ->get()
                    ->keyBy('id')
                    ->toArray();
            }

            // Build a map of store_id => seller info
            $storeSellerMap = [];
            foreach ($sellerAssignments as $storeId => $tracking) {
                $sellerInfo = $sellersInfo[$tracking->seller_id] ?? null;
                if ($sellerInfo) {
                    $storeSellerMap[$storeId] = [
                        'seller_id' => $tracking->seller_id,
                        'seller_name' => $sellerInfo->name,
                        'seller_store_name' => $sellerInfo->store_name,
                        'seller_mobile' => $sellerInfo->mobile ?? null,
                        'seller_address' => $sellerInfo->store_location ?? null,
                        'seller_lat_long' => $sellerInfo->lat_long ?? null,
                        'status' => $tracking->status ?? 'assigned_to_seller'
                    ];
                }
            }

            // Get order items with product info
            $orderItemsData = DB::table('order_items')
                ->where('order_id', $orderId)
                ->select('id', 'product_variant_id', 'product_name', 'variant_name', 'quantity', 'price', 'discounted_price', 'sub_total')
                ->get()
                ->keyBy('id');

            // Get product variant to product mapping
            $variantIds = $orderItemsData->pluck('product_variant_id')->toArray();
            $variantProductMap = DB::table('product_variants')
                ->whereIn('id', $variantIds)
                ->pluck('product_id', 'id');

            // Get product to store mapping
            $productIds = $variantProductMap->values()->unique()->toArray();
            $productStoreMap = DB::table('products')
                ->whereIn('id', $productIds)
                ->pluck('store_id', 'id');

            // Build item to store map (order_item_id => store_id)
            $itemStoreMap = [];
            foreach ($orderItemsData as $itemId => $item) {
                $productId = $variantProductMap[$item->product_variant_id] ?? null;
                $storeId = $productId ? ($productStoreMap[$productId] ?? null) : null;
                $itemStoreMap[$itemId] = $storeId;
            }

            // Enrich selected_items with seller info
            $enrichedSelectedItems = [];
            foreach ($selectedItems as $storeItem) {
                $storeId = $storeItem['store_id'] ?? 0;
                $sellerData = $storeSellerMap[$storeId] ?? null;

                // Apply store-specific packer logic:
                // Store ID 12: Zenfoo (admin managed)
                // Store ID 13, 14, 15, 17: Seller from order_seller_status_tracking
                $packerName = null;
                $packerStoreName = null;
                $packerId = null;
                $packerMobile = null;
                $packerAddress = null;
                $packerLatLong = null;
                $packingStatus = null;

                if ($storeId == 12) {
                    // Zenfoo store - show "Zenfoo" as packer
                    // Get Zenfoo store address from store_locations based on order's city
                    $packerName = 'Zenfoo';
                    $packerStoreName = 'Zenfoo Store';

                    // Get customer address to find city_id
                    if ($order && $order->address_id) {
                        $userAddressForCity = DB::table('user_addresses')
                            ->where('id', $order->address_id)
                            ->select('city_id')
                            ->first();

                        if ($userAddressForCity && $userAddressForCity->city_id) {
                            $zenfooStoreLocation = DB::table('store_locations')
                                ->where('city_id', $userAddressForCity->city_id)
                                ->where('status', 1)
                                ->first();

                            if ($zenfooStoreLocation) {
                                $packerAddress = $zenfooStoreLocation->address ?? null;
                                $packerLatLong = ($zenfooStoreLocation->latitude && $zenfooStoreLocation->longitude)
                                    ? $zenfooStoreLocation->latitude . ',' . $zenfooStoreLocation->longitude
                                    : null;
                            }
                        }
                    }
                } elseif ($storeId == 17) {
                    // Store 17 (DMart) - store owner packs all orders, use store_name as seller
                    $packerName = $storeItem['store_name'] ?? 'DMart';
                    $packerStoreName = $storeItem['store_name'] ?? 'DMart';
                } elseif (in_array($storeId, [13, 14, 15])) {
                    // Vendor stores - get seller from order_seller_status_tracking
                    if ($sellerData) {
                        $packerId = $sellerData['seller_id'];
                        $packerName = $sellerData['seller_name'];
                        $packerStoreName = $sellerData['seller_store_name'];
                        $packerMobile = $sellerData['seller_mobile'] ?? null;
                        $packerAddress = $sellerData['seller_address'] ?? null;
                        $packerLatLong = $sellerData['seller_lat_long'] ?? null;
                        $packingStatus = $sellerData['status'];
                    }
                } else {
                    // Other stores - use seller data if available
                    if ($sellerData) {
                        $packerId = $sellerData['seller_id'];
                        $packerName = $sellerData['seller_name'];
                        $packerStoreName = $sellerData['seller_store_name'];
                        $packerMobile = $sellerData['seller_mobile'] ?? null;
                        $packerAddress = $sellerData['seller_address'] ?? null;
                        $packerLatLong = $sellerData['seller_lat_long'] ?? null;
                        $packingStatus = $sellerData['status'];
                    }
                }

                $enrichedStore = [
                    'store_id' => $storeId,
                    'store_name' => $storeItem['store_name'] ?? 'Unknown',
                    'description' => $storeItem['description'] ?? '',
                    'seller_id' => $packerId,
                    'seller_name' => $packerName,
                    'seller_store_name' => $packerStoreName,
                    'seller_mobile' => $packerMobile,
                    'seller_address' => $packerAddress,
                    'seller_lat_long' => $packerLatLong,
                    'packing_status' => $packingStatus,
                ];

                $enrichedStore['image_urls'] = $storeItem['image_urls'] ?? [];

                if ($reportType === 'wrong') {
                    // image_urls already set above
                } else {
                    $enrichedItems = [];
                    foreach ($storeItem['items'] ?? [] as $item) {
                        $productId = $item['product_id'] ?? 0;
                        $orderItem = $orderItemsData[$productId] ?? null;

                        $enrichedItems[] = [
                            'product_id' => $productId,
                            'product_name' => $orderItem ? $orderItem->product_name : ($item['product_name'] ?? 'Unknown'),
                            'variant_measurement' => $orderItem ? $orderItem->variant_name : ($item['variant_measurement'] ?? ''),
                            'price' => $orderItem ? $orderItem->discounted_price : ($item['price'] ?? 0),
                            'actual_price' => $orderItem ? $orderItem->price : ($item['actual_price'] ?? 0),
                            'quantity' => $orderItem ? $orderItem->quantity : ($item['quantity'] ?? 1),
                            'sub_total' => $orderItem ? $orderItem->sub_total : ($item['sub_total'] ?? 0),
                        ];
                    }
                    $enrichedStore['items'] = $enrichedItems;
                }

                $enrichedSelectedItems[] = $enrichedStore;
            }

            // Get combo items with seller info from order_combo_items
            $orderComboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->select('id', 'combo_id', 'combo_name', 'sub_total', 'discount_percentage', 'total_actual_price', 'total_products_price', 'products', 'seller_id')
                ->get()
                ->keyBy('id');

            // Collect all product IDs from combo products to get their store mappings
            $comboProductIds = [];
            foreach ($orderComboItems as $combo) {
                if (!empty($combo->products)) {
                    $products = json_decode($combo->products, true);
                    if (is_string($products)) {
                        $products = json_decode($products, true);
                    }
                    if (is_array($products)) {
                        foreach ($products as $product) {
                            if (!empty($product['product_id'])) {
                                $comboProductIds[] = $product['product_id'];
                            }
                        }
                    }
                }
            }

            // Get product to store mapping for combo products
            $comboProductStoreMap = [];
            if (!empty($comboProductIds)) {
                $comboProductStoreMap = DB::table('products')
                    ->whereIn('id', array_unique($comboProductIds))
                    ->pluck('store_id', 'id')
                    ->toArray();
            }

            // Enrich selected_combo_items with per-product seller info
            $enrichedSelectedComboItems = [];
            foreach ($selectedComboItems as $comboItem) {
                $comboId = $comboItem['id'] ?? $comboItem['combo_id'] ?? 0;
                $orderCombo = $orderComboItems[$comboId] ?? null;

                $enrichedCombo = [
                    'id' => $comboId,
                    'combo_id' => $orderCombo ? $orderCombo->combo_id : ($comboItem['combo_id'] ?? 0),
                    'combo_name' => $orderCombo ? $orderCombo->combo_name : ($comboItem['combo_name'] ?? ''),
                    'description' => $comboItem['description'] ?? '',
                    'image_urls' => $comboItem['image_urls'] ?? [],
                ];

                if ($reportType === 'wrong') {

                    // For wrong reports, get unique sellers from combo's products
                    $comboSellers = [];
                    if ($orderCombo && !empty($orderCombo->products)) {
                        $products = json_decode($orderCombo->products, true);
                        if (is_string($products)) {
                            $products = json_decode($products, true);
                        }

                        if (is_array($products)) {
                            // Get store 17 name
                            $store17Name = DB::table('stores')->where('id', 17)->value('name') ?? 'DMart';

                            $seenSellers = [];
                            foreach ($products as $product) {
                                $productId = $product['product_id'] ?? 0;
                                $productStoreId = $comboProductStoreMap[$productId] ?? null;

                                if ($productStoreId) {
                                    if ($productStoreId == 12) {
                                        if (!isset($seenSellers['zenfoo'])) {
                                            $comboSellers[] = [
                                                'seller_id' => null,
                                                'seller_name' => 'Zenfoo',
                                                'seller_store_name' => 'Zenfoo Store',
                                                'seller_mobile' => null,
                                            ];
                                            $seenSellers['zenfoo'] = true;
                                        }
                                    } elseif ($productStoreId == 17) {
                                        // Store 17 - store owner packs all orders
                                        if (!isset($seenSellers['store17'])) {
                                            $comboSellers[] = [
                                                'seller_id' => null,
                                                'seller_name' => $store17Name,
                                                'seller_store_name' => $store17Name,
                                                'seller_mobile' => null,
                                            ];
                                            $seenSellers['store17'] = true;
                                        }
                                    } else {
                                        $sellerData = $storeSellerMap[$productStoreId] ?? null;
                                        if ($sellerData && !isset($seenSellers[$sellerData['seller_id']])) {
                                            $comboSellers[] = [
                                                'seller_id' => $sellerData['seller_id'],
                                                'seller_name' => $sellerData['seller_name'],
                                                'seller_store_name' => $sellerData['seller_store_name'],
                                                'seller_mobile' => $sellerData['seller_mobile'] ?? null,
                                            ];
                                            $seenSellers[$sellerData['seller_id']] = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    $enrichedCombo['sellers'] = $comboSellers;
                } else {
                    $enrichedCombo['sub_total'] = $orderCombo ? $orderCombo->sub_total : 0;
                    $enrichedCombo['discount_percentage'] = $orderCombo ? $orderCombo->discount_percentage : 0;
                    $enrichedCombo['total_actual_price'] = $orderCombo ? $orderCombo->total_actual_price : 0;
                    $enrichedCombo['total_products_price'] = $orderCombo ? $orderCombo->total_products_price : 0;

                    // Parse products from combo with per-product packer info
                    $enrichedProducts = [];
                    $selectedProductIds = array_column($comboItem['products'] ?? [], 'product_id');

                    if ($orderCombo && !empty($orderCombo->products)) {
                        $products = json_decode($orderCombo->products, true);
                        if (is_string($products)) {
                            $products = json_decode($products, true);
                        }
                        if (is_array($products)) {
                            foreach ($products as $product) {
                                $productId = $product['product_id'] ?? 0;
                                if (in_array($productId, $selectedProductIds)) {
                                    // Get the store_id for this product
                                    $productStoreId = $comboProductStoreMap[$productId] ?? 0;

                                    // Apply store-specific packer logic for each product
                                    $productPackerName = null;
                                    $productPackerStoreName = null;

                                    if ($productStoreId == 12) {
                                        // Zenfoo store
                                        $productPackerName = 'Zenfoo';
                                        $productPackerStoreName = 'Zenfoo Store';
                                    } elseif ($productStoreId == 17) {
                                        // Store 17 - store owner packs all orders, use store name
                                        $store17Name = DB::table('stores')->where('id', 17)->value('name') ?? 'DMart';
                                        $productPackerName = $store17Name;
                                        $productPackerStoreName = $store17Name;
                                    } elseif (in_array($productStoreId, [13, 14, 15])) {
                                        // Vendor stores - get seller from order_seller_status_tracking
                                        $sellerData = $storeSellerMap[$productStoreId] ?? null;
                                        if ($sellerData) {
                                            $productPackerName = $sellerData['seller_name'];
                                            $productPackerStoreName = $sellerData['seller_store_name'];
                                        }
                                    } else {
                                        // Other stores - use seller data if available
                                        $sellerData = $storeSellerMap[$productStoreId] ?? null;
                                        if ($sellerData) {
                                            $productPackerName = $sellerData['seller_name'];
                                            $productPackerStoreName = $sellerData['seller_store_name'];
                                        }
                                    }

                                    $enrichedProducts[] = [
                                        'product_id' => $productId,
                                        'product_name' => $product['product_name'] ?? '',
                                        'variant_measurement' => $product['variant_measurement'] ?? '',
                                        'price' => $product['price'] ?? 0,
                                        'actual_price' => $product['actual_price'] ?? 0,
                                        'quantity' => $product['quantity'] ?? 1,
                                        'sub_total' => $product['sub_total'] ?? 0,
                                        'store_id' => $productStoreId,
                                        'packer_name' => $productPackerName,
                                        'packer_store_name' => $productPackerStoreName,
                                    ];
                                }
                            }
                        }
                    }
                    $enrichedCombo['products'] = $enrichedProducts;
                }

                $enrichedSelectedComboItems[] = $enrichedCombo;
            }

            // Get delivery partner details if exists
            $deliveryPartner = null;
            if ($order && $order->delivery_boy_id) {
                $deliveryPartner = DB::table('delivery_boys')
                    ->where('id', $order->delivery_boy_id)
                    ->select('id', 'name')
                    ->first();
            }

            // Get driver captured images when marked as pickup from order_seller_status_tracking
            // Only fetch images for stores that are reported in the issue (selected_items)
            $driverPickupImages = [];
            $reportedStoreIds = array_column($selectedItems, 'store_id');

            if (!empty($reportedStoreIds)) {
                $sellerTrackingImages = DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->whereIn('store_id', $reportedStoreIds)
                    ->whereNotNull('driver_captured_images_when_marked_as_pickup')
                    ->select('driver_captured_images_when_marked_as_pickup', 'store_id')
                    ->get();

                foreach ($sellerTrackingImages as $tracking) {
                    $images = json_decode($tracking->driver_captured_images_when_marked_as_pickup, true);
                    if (is_array($images) && !empty($images)) {
                        foreach ($images as $image) {
                            $driverPickupImages[] = $image;
                        }
                    }
                }
            }

            // Get delivery_time_before_images from orders table
            $deliveryBeforeImages = [];
            if ($order && !empty($order->delivery_time_before_images)) {
                $images = json_decode($order->delivery_time_before_images, true);
                if (is_array($images)) {
                    $deliveryBeforeImages = $images;
                }
            }

            // Extract delivery date from status array
            $deliveryDate = null;
            if ($order && $order->status) {
                $statusArray = json_decode($order->status, true);
                if (is_array($statusArray)) {
                    foreach ($statusArray as $statusItem) {
                        if (is_array($statusItem) && count($statusItem) >= 2) {
                            if ($statusItem[0] == 6) { // Delivered status
                                $deliveryDate = $statusItem[1];
                                break;
                            }
                        }
                    }
                    if (!$deliveryDate && !empty($statusArray)) {
                        $lastStatus = end($statusArray);
                        if (is_array($lastStatus) && count($lastStatus) >= 2) {
                            $deliveryDate = $lastStatus[1];
                        }
                    }
                }
            }

            // Get stores and vendors from order items
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
                    $variantProductMapForStores = DB::table('product_variants')
                        ->whereIn('id', $variantIdsForStores)
                        ->pluck('product_id', 'id');

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

            // Get customer delivery address from order
            $customerAddress = null;
            if ($order) {
                // First try to get detailed address from user_addresses table
                if ($order->address_id) {
                    $userAddress = DB::table('user_addresses')
                        ->where('id', $order->address_id)
                        ->select('address', 'landmark', 'city', 'pincode', 'latitude', 'longitude')
                        ->first();

                    if ($userAddress) {
                        $customerAddress = [
                            'address' => $userAddress->address,
                            'landmark' => $userAddress->landmark,
                            'city' => $userAddress->city,
                            'pincode' => $userAddress->pincode,
                            'lat_long' => ($userAddress->latitude && $userAddress->longitude)
                                ? $userAddress->latitude . ',' . $userAddress->longitude
                                : null,
                            'full_address' => $order->address, // Full address string from orders table
                        ];
                    }
                }

                // If user_addresses didn't have data, use order's address field
                if (!$customerAddress && $order->address) {
                    $customerAddress = [
                        'address' => $order->address,
                        'landmark' => null,
                        'city' => null,
                        'pincode' => null,
                        'lat_long' => ($order->latitude && $order->longitude)
                            ? $order->latitude . ',' . $order->longitude
                            : null,
                        'full_address' => $order->address,
                    ];
                }
            }

            // Get return records for this report
            $returnRecords = DB::table('customer_issue_report_returns')
                ->where('report_id', $report->id)
                ->select('id', 'seller_id', 'customer_id', 'date', 'product_ids', 'products_json', 'refundable_amount', 'delivery_partner_id', 'delivered_date', 'is_return_accepted', 'is_zenfoo_store', 'created_at', 'updated_at')
                ->get()
                ->map(function ($record) {
                    $record->products_json = json_decode($record->products_json, true);
                    $record->product_ids = json_decode($record->product_ids, true);
                    return $record;
                });

            return CommonHelper::responseWithData([
                'id' => $report->id,
                'customer_id' => $report->customer_id,
                'customer_name' => $report->customer_name,
                'customer_mobile' => $report->customer_mobile,
                'customer_email' => $report->customer_email,
                'customer_address' => $customerAddress,
                'order_id' => $report->order_id,
                'report_type' => $reportType,
                'description' => $report->description,
                'is_refund_requested' => $report->is_refund_requested,
                'status' => $report->status,
                'status_name' => $this->getStatusName($report->status),
                'admin_remarks' => $report->admin_remarks,
                'status_change_history' => $report->status_change_json ?? [],
                'selected_items' => $enrichedSelectedItems,
                'selected_combo_items' => $enrichedSelectedComboItems,
                'created_at' => $report->created_at,
                'updated_at' => $report->updated_at,
                'order_details' => [
                    'delivery_partner' => $deliveryPartner ? [
                        'id' => $deliveryPartner->id,
                        'name' => $deliveryPartner->name,
                    ] : null,
                    'delivery_date' => $deliveryDate,
                    'has_zenfoo' => $hasZenfoo,
                    'vendors' => $vendorsList,
                    'combos' => $combosList,
                    'stores_and_vendors' => $storesAndVendors,
                    'driver_pickup_images' => $driverPickupImages,
                    'delivery_before_images' => $deliveryBeforeImages,
                ],
                'return_records' => $returnRecords,
            ]);

        } catch (\Exception $e) {
            Log::error('Admin Get Issue Report Detail Error', [
                'error' => $e->getMessage(),
                'id' => $request->id,
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch report details.');
        }
    }

    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer',
            'status' => 'required|integer|in:0,1,2,3,4,5,6',
            'admin_remarks' => 'required|string|max:500',
        ], [
            'admin_remarks.required' => 'Admin remarks is required when updating the report.',
        ]);

        if ($validator->fails()) {
            Log::warning('Admin Update Issue Report - Validation failed', [
                'id' => $request->id,
                'errors' => $validator->errors()->toArray(),
            ]);
            return CommonHelper::responseError($validator->errors()->first());
        }

        Log::info('Admin updating issue report', [
            'report_id' => $request->id,
            'new_status' => $request->status,
            'status_name' => $this->getStatusName($request->status),
            'admin_remarks' => $request->admin_remarks,
        ]);

        try {
            $report = CustomerItemMissingReport::find($request->id);

            if (!$report) {
                Log::warning('Admin Update Issue Report - Report not found', [
                    'report_id' => $request->id,
                ]);
                return CommonHelper::responseError('Report not found.');
            }

            $oldStatus = $report->status;
            $newStatus = $request->status;

            Log::info('Admin Update Issue Report - Status change details', [
                'report_id' => $report->id,
                'order_id' => $report->order_id,
                'customer_id' => $report->customer_id,
                'from_status' => $oldStatus,
                'from_status_name' => $this->getStatusName($oldStatus),
                'to_status' => $newStatus,
                'to_status_name' => $this->getStatusName($newStatus),
            ]);

            // Idempotency guard: if the report is already in the requested status,
            // do not re-apply it. Re-clicking "Update Report" on the same status
            // would otherwise append a duplicate history entry, re-send
            // notifications, and (for Driver Assigned) insert a second set of
            // seller return records.
            if ($newStatus == $oldStatus) {
                Log::info('Admin Update Issue Report - Status unchanged, skipping re-apply', [
                    'report_id' => $report->id,
                    'status' => $newStatus,
                    'status_name' => $this->getStatusName($newStatus),
                ]);
                return CommonHelper::responseError(
                    'This report is already marked as "' . $this->getStatusName($newStatus) . '".'
                );
            }

            // Block direct resolve if the report has already been sent to sellers for return.
            // In that case the resolution must come from all sellers accepting via the return flow.
            if ($newStatus == 2) {
                $returnRecordsExist = DB::table('customer_issue_report_returns')
                    ->where('report_id', $report->id)
                    ->exists();

                if ($returnRecordsExist) {
                    Log::info('Admin Update Issue Report - Blocked direct resolve, return records exist', [
                        'report_id' => $report->id,
                        'order_id' => $report->order_id,
                    ]);
                    return CommonHelper::responseError(
                        'This report has been sent to sellers for return. It will be auto-resolved once all sellers accept the return.'
                    );
                }
            }

            // Calculate refund amount for resolved status
            $refundAmount = 0;
            if ($newStatus == 2) { // Resolved
                $refundAmount = $this->calculateRefundAmount($report);
                Log::info('Admin Update Issue Report - Refund amount calculated', [
                    'report_id' => $report->id,
                    'refund_amount' => $refundAmount,
                ]);
            }

            // Get status change message for customer
            $statusChangeMessage = $this->getStatusChangeMessage($newStatus, $refundAmount);

            // Get existing status change history or initialize empty array
            $statusChangeHistory = $report->status_change_json ?? [];
            if (is_string($statusChangeHistory)) {
                $statusChangeHistory = json_decode($statusChangeHistory, true) ?? [];
            }

            // Add new status change entry
            $statusChangeHistory[] = [
                'from_status' => $oldStatus,
                'to_status' => $newStatus,
                'status_name' => $this->getStatusName($newStatus),
                'message' => $statusChangeMessage,
                'refund_amount' => $refundAmount,
                'changed_at' => now()->toDateTimeString(),
            ];

            $report->status = $newStatus;
            $report->admin_remarks = $request->admin_remarks;
            $report->status_change_json = $statusChangeHistory;
            $report->save();

            Log::info('Admin Update Issue Report - Report saved successfully', [
                'report_id' => $report->id,
                'order_id' => $report->order_id,
                'from_status' => $oldStatus,
                'to_status' => $newStatus,
                'refund_amount' => $refundAmount,
            ]);

            // If status is Resolved (2), update product stock, add wallet transaction,
            // and update each seller's wallet transaction + balance
            if ($newStatus == 2 && $refundAmount > 0) {
                Log::info('Admin Update Issue Report - Processing refund for resolved status', [
                    'report_id' => $report->id,
                    'refund_amount' => $refundAmount,
                ]);

                // Update product stock in product_variants table
                $this->updateProductStock($report);

                // Add refund to customer wallet
                $this->addWalletTransaction($report, $refundAmount);

                // Deduct refundable amounts from each seller's wallet transaction and balance
                $this->updateSellerWalletForAdminResolve($report);
            } elseif ($newStatus == 2 && $refundAmount == 0) {
                Log::info('Admin Update Issue Report - Resolved with no refund amount', [
                    'report_id' => $report->id,
                ]);
            }

            // If status is Driver Assigned (4), create return records for sellers.
            // Guard against duplicates: only create if none exist yet for this
            // report (the service does a plain insert with no dedupe of its own).
            if ($newStatus == 4) {
                $returnRecordsExist = DB::table('customer_issue_report_returns')
                    ->where('report_id', $report->id)
                    ->exists();

                if ($returnRecordsExist) {
                    Log::info('Admin Update Issue Report - Seller return records already exist, skipping creation', [
                        'report_id' => $report->id,
                        'order_id' => $report->order_id,
                    ]);
                } else {
                    Log::info('Admin Update Issue Report - Creating seller return records (Driver Assigned)', [
                        'report_id' => $report->id,
                        'order_id' => $report->order_id,
                    ]);
                    CustomerIssueReportReturnService::createReturnRecordsForSellers($report);
                    Log::info('Admin Update Issue Report - Seller return records created', [
                        'report_id' => $report->id,
                    ]);
                }
            }

            // Send notifications to customer and sellers
            $this->sendStatusChangeNotifications($report, $newStatus, $statusChangeMessage, $refundAmount);

            Log::info('Admin Update Issue Report - Completed successfully', [
                'report_id' => $report->id,
                'final_status' => $newStatus,
                'status_name' => $this->getStatusName($newStatus),
            ]);

            return CommonHelper::responseSuccess(null, 'Report updated successfully.');

        } catch (\Exception $e) {
            Log::error('Admin Update Issue Report Error', [
                'error' => $e->getMessage(),
                'id' => $request->id,
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to update report.');
        }
    }

    private function calculateRefundAmount($report)
    {
        $totalAmount = 0;

        // Calculate from selected_items
        $selectedItems = $report->selected_items ?? [];
        if (is_string($selectedItems)) {
            $selectedItems = json_decode($selectedItems, true) ?? [];
        }

        foreach ($selectedItems as $storeItem) {
            $items = $storeItem['items'] ?? [];
            foreach ($items as $item) {
                $totalAmount += floatval($item['sub_total'] ?? 0);
            }
        }

        // Calculate from selected_combo_items
        $selectedComboItems = $report->selected_combo_items ?? [];
        if (is_string($selectedComboItems)) {
            $selectedComboItems = json_decode($selectedComboItems, true) ?? [];
        }

        foreach ($selectedComboItems as $comboItem) {
            $totalAmount += floatval($comboItem['sub_total'] ?? 0);
        }

        // Deduct promocode discount and milestone reward used in the order
        // (mirrors the seller-flow deduction logic)
        $order = DB::table('orders')
            ->where('id', $report->order_id)
            ->select('cart_metadata')
            ->first();

        if ($order && $order->cart_metadata) {
            $billingSummary = json_decode($order->cart_metadata, true)['billing_summary'] ?? [];
            $promoDiscount      = (float) ($billingSummary['promocode_discount']        ?? 0);
            $milestoneAmount    = (float) ($billingSummary['claimable_milestone_amount'] ?? 0);
            $totalAmount -= ($promoDiscount + $milestoneAmount);
            if ($totalAmount < 0) {
                $totalAmount = 0;
            }
        }

        return round($totalAmount, 2);
    }

    private function getStatusChangeMessage($status, $refundAmount = 0)
    {
        $messages = [
            0 => 'Your report has been received and is pending review.',
            1 => 'Your report is being reviewed by our team.',
            2 => $refundAmount > 0
                ? "Your issue has been resolved. An amount of ₹{$refundAmount} has been refunded to your wallet."
                : 'Your issue has been resolved successfully.',
            3 => 'Your report has been reviewed and could not be processed. Please contact support for more details.',
            4 => 'A delivery partner has been assigned to collect the item from you. Please keep the item ready.',
            5 => 'The delivery partner has collected the item from you.',
            6 => 'The item has been returned successfully. Your refund will be processed shortly.',
        ];

        return $messages[$status] ?? 'Status updated.';
    }

    public function delete(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $report = CustomerItemMissingReport::find($request->id);

            if (!$report) {
                return CommonHelper::responseError('Report not found.');
            }

            $report->delete();

            return CommonHelper::responseSuccess(null, 'Report deleted successfully.');

        } catch (\Exception $e) {
            Log::error('Admin Delete Issue Report Error', [
                'error' => $e->getMessage(),
                'id' => $request->id,
            ]);
            return CommonHelper::responseError('Failed to delete report.');
        }
    }

    private function getStatusName($status)
    {
        $statuses = [
            0 => 'Pending',
            1 => 'In Progress',
            2 => 'Resolved',
            3 => 'Rejected',
            4 => 'Driver Assigned',
            5 => 'Driver Took Item',
            6 => 'Driver Returned Item',
        ];

        return $statuses[$status] ?? 'Unknown';
    }

    /**
     * Update product stock in product_variants table when issue is resolved
     * The stock is increased back since the item was missing/wrong
     */
    private function updateProductStock($report)
    {
        try {
            // Get selected_items from report
            $selectedItems = $report->selected_items ?? [];
            if (is_string($selectedItems)) {
                $selectedItems = json_decode($selectedItems, true) ?? [];
            }

            // Get order_id to fetch order_items for product_variant_id mapping
            $orderId = $report->order_id;

            // Get order items to map product_id to product_variant_id
            $orderItems = DB::table('order_items')
                ->where('order_id', $orderId)
                ->select('id', 'product_variant_id', 'quantity')
                ->get()
                ->keyBy('id');

            // Update stock for each selected item
            foreach ($selectedItems as $storeItem) {
                $items = $storeItem['items'] ?? [];
                foreach ($items as $item) {
                    $productId = $item['product_id'] ?? 0; // This is actually order_item_id
                    $orderItem = $orderItems[$productId] ?? null;

                    if ($orderItem && $orderItem->product_variant_id) {
                        // Increase stock by the quantity that was reported missing/wrong
                        $quantity = $orderItem->quantity ?? 1;

                        ProductVariant::where('id', $orderItem->product_variant_id)
                            ->increment('stock', $quantity);

                        Log::info('Product stock updated for resolved issue', [
                            'report_id' => $report->id,
                            'product_variant_id' => $orderItem->product_variant_id,
                            'quantity_added' => $quantity,
                        ]);
                    }
                }
            }

            // Update stock for combo items
            $selectedComboItems = $report->selected_combo_items ?? [];
            if (is_string($selectedComboItems)) {
                $selectedComboItems = json_decode($selectedComboItems, true) ?? [];
            }

            foreach ($selectedComboItems as $comboItem) {
                $products = $comboItem['products'] ?? [];
                // Get combo quantity (how many times the combo was ordered)
                $comboQuantity = $comboItem['combo_quantity'] ?? 1;

                foreach ($products as $product) {
                    $productId = $product['product_id'] ?? 0;
                    $variantMeasurement = $product['variant_measurement'] ?? null;

                    if ($productId) {
                        // Get product_variant_id by matching product_id and measurement
                        $query = DB::table('product_variants')
                            ->where('product_id', $productId);

                        // Match by measurement if available to get the correct variant
                        if ($variantMeasurement !== null) {
                            $query->where('measurement', $variantMeasurement);
                        }

                        $productVariant = $query->first();

                        if ($productVariant) {
                            // Quantity = product quantity in combo * combo quantity ordered
                            $productQuantityInCombo = $product['quantity'] ?? 1;
                            $totalQuantity = $productQuantityInCombo * $comboQuantity;

                            ProductVariant::where('id', $productVariant->id)
                                ->increment('stock', $totalQuantity);

                            Log::info('Combo product stock updated for resolved issue', [
                                'report_id' => $report->id,
                                'combo_id' => $comboItem['id'] ?? $comboItem['combo_id'] ?? 0,
                                'product_id' => $productId,
                                'product_variant_id' => $productVariant->id,
                                'quantity_added' => $totalQuantity,
                            ]);
                        }
                    }
                }
            }

        } catch (\Exception $e) {
            Log::error('Failed to update product stock for resolved issue', [
                'report_id' => $report->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Add wallet transaction for customer refund when issue is resolved
     */
    private function addWalletTransaction($report, $refundAmount)
    {
        try {
            // 1. Credit the refund to the customer's wallet balance
            $customer = User::find($report->customer_id);
            if ($customer) {
                $customer->balance = $customer->balance + $refundAmount;
                $customer->save();
            }

            // 2. Record the wallet transaction
            WalletTransaction::create([
                'user_id'          => $report->customer_id,
                'order_id'         => $report->order_id,
                'type'             => 'credit',
                'amount'           => $refundAmount,
                'message'          => 'Refund for missing/wrong item issue #' . $report->id,
                'status'           => WalletTransaction::$statusSuccess,
                'txn_id'           => 'REFUND_' . $report->id . '_' . time(),
                'payment_type'     => 'Wallet Refund',
                'transaction_date' => now(),
            ]);

            Log::info('Wallet transaction created for resolved issue', [
                'report_id'   => $report->id,
                'customer_id' => $report->customer_id,
                'amount'      => $refundAmount,
                'new_balance' => $customer->balance ?? null,
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create wallet transaction for resolved issue', [
                'report_id' => $report->id,
                'error'     => $e->getMessage(),
            ]);
        }
    }

    /**
     * Update each seller's wallet transaction and balance when admin directly resolves a report.
     * Mirrors the deductions done in the seller return-acceptance flow.
     */
    private function updateSellerWalletForAdminResolve($report)
    {
        try {
            $selectedItems = $report->selected_items ?? [];
            if (is_string($selectedItems)) {
                $selectedItems = json_decode($selectedItems, true) ?? [];
            }

            if (empty($selectedItems)) {
                return;
            }

            $orderId = $report->order_id;

            // Build store_id → seller_id map from order_seller_status_tracking
            $sellerAssignments = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get()
                ->keyBy('store_id');

            foreach ($selectedItems as $storeItem) {
                $storeId = (int) ($storeItem['store_id'] ?? 0);
                if (!$storeId) {
                    continue;
                }

                // Sum this store's refundable amount from its items
                $storeRefundable = 0;
                foreach ($storeItem['items'] ?? [] as $item) {
                    $storeRefundable += floatval($item['sub_total'] ?? 0);
                }

                if ($storeRefundable <= 0) {
                    continue;
                }

                $sellerAssignment = $sellerAssignments[$storeId] ?? null;
                if (!$sellerAssignment) {
                    continue;
                }

                $sellerId = $sellerAssignment->seller_id;

                // Find this seller's wallet transaction for the order
                $sellerTransaction = DB::table('seller_wallet_transactions')
                    ->where('seller_id', $sellerId)
                    ->where('order_id', $orderId)
                    ->first();

                if (!$sellerTransaction) {
                    continue;
                }

                $newBalanceAfter    = (float) $sellerTransaction->balance_after - $storeRefundable;
                $transactionAmount  = (float) $sellerTransaction->amount;
                $refundMessage      = " | Refund to customer: ₹" . number_format($storeRefundable, 2)
                    . " (Admin resolved Issue Report #{$report->id})";
                $updatedMessage     = ($sellerTransaction->message ?? '') . $refundMessage;

                $updateData = [
                    'balance_after'           => $newBalanceAfter,
                    'is_refunded_to_customer' => 1,
                    'refundable_amount'       => $storeRefundable,
                    'message'                 => $updatedMessage,
                    'updated_at'              => now(),
                ];

                // If full amount is being refunded, mark the transaction as settled
                if ($transactionAmount <= $storeRefundable) {
                    $updateData['is_paid_to_seller']        = 1;
                    $updateData['paid_by']                  = 1; // System/Admin
                    $updateData['paid_at']                  = now();
                    $updateData['payment_transaction_id']   = 'refund_settled_for_order_' . $orderId;
                    $updateData['message']                  = $updatedMessage . ' | Transaction settled: Full amount refunded to customer';
                }

                DB::table('seller_wallet_transactions')
                    ->where('id', $sellerTransaction->id)
                    ->update($updateData);

                // Deduct from sellers.balance
                $sellerRecord = DB::table('sellers')->where('id', $sellerId)->first();
                if ($sellerRecord) {
                    $newSellerBalance = (float) ($sellerRecord->balance ?? 0) - $storeRefundable;
                    DB::table('sellers')
                        ->where('id', $sellerId)
                        ->update(['balance' => $newSellerBalance, 'updated_at' => now()]);
                }

                Log::info('Seller wallet updated for admin-resolved report', [
                    'report_id'        => $report->id,
                    'seller_id'        => $sellerId,
                    'store_id'         => $storeId,
                    'refundable_amount' => $storeRefundable,
                    'new_balance_after' => $newBalanceAfter,
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Failed to update seller wallet for admin-resolved report', [
                'report_id' => $report->id,
                'error'     => $e->getMessage(),
            ]);
        }
    }

    /**
     * Send notifications to customer and sellers when report status changes
     */
    private function sendStatusChangeNotifications($report, $newStatus, $statusChangeMessage, $refundAmount = 0)
    {
        try {
            $orderId = $report->order_id;
            $customerId = $report->customer_id;
            $reportType = $report->report_type === 'wrong' ? 'Wrong Item' : 'Missing Item';
            $statusName = $this->getStatusName($newStatus);

            // Send notification to customer
            $customerTitle = "Issue Report Update - Order #{$orderId}";
            $customerMessage = $statusChangeMessage;

            CustomerNotificationService::send(
                $customerId,
                $customerTitle,
                $customerMessage,
                '',
                'order',
                $orderId,
                [
                    'report_id' => $report->id,
                    'report_type' => $report->report_type,
                    'status' => $newStatus,
                    'status_name' => $statusName,
                    'refund_amount' => $refundAmount,
                ]
            );

            Log::info('Customer notification sent for issue report status change', [
                'report_id' => $report->id,
                'customer_id' => $customerId,
                'new_status' => $newStatus,
            ]);

            // Send notification to sellers (only for specific statuses)
            // Status 2: Resolved     - notify sellers that report is resolved and amount deducted
            // Status 4: Driver Assigned - notify sellers that driver will collect item
            // Status 5: Driver Took Item - notify sellers that item has been collected
            // Status 6: Driver Returned Item - notify sellers that item has been returned
            if (in_array($newStatus, [2, 4, 5, 6])) {
                $this->sendSellerNotifications($report, $newStatus, $statusName, $reportType);
            }

        } catch (\Exception $e) {
            Log::error('Failed to send status change notifications', [
                'report_id' => $report->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Send notifications to sellers involved in the report
     */
    private function sendSellerNotifications($report, $newStatus, $statusName, $reportType)
    {
        try {
            $orderId = $report->order_id;

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

            // Collect unique seller IDs
            $sellerIds = [];

            // From normal items
            foreach ($selectedItems as $storeItem) {
                $storeId = (int) ($storeItem['store_id'] ?? 0);

                // Skip store ID 12 (Zenfoo/admin managed store)
                if ($storeId == 12) {
                    continue;
                }

                $sellerAssignment = $sellerAssignments[$storeId] ?? null;
                if ($sellerAssignment && !in_array($sellerAssignment->seller_id, $sellerIds)) {
                    $sellerIds[] = $sellerAssignment->seller_id;
                }
            }

            // From combo items
            foreach ($selectedComboItems as $comboItem) {
                $products = $comboItem['products'] ?? [];
                $productIds = array_column($products, 'product_id');

                if (!empty($productIds)) {
                    $productStoreMap = DB::table('products')
                        ->whereIn('id', $productIds)
                        ->pluck('store_id', 'id')
                        ->toArray();

                    foreach ($productIds as $productId) {
                        $storeId = $productStoreMap[$productId] ?? null;

                        // Skip store ID 12
                        if (!$storeId || $storeId == 12) {
                            continue;
                        }

                        $sellerAssignment = $sellerAssignments[$storeId] ?? null;
                        if ($sellerAssignment && !in_array($sellerAssignment->seller_id, $sellerIds)) {
                            $sellerIds[] = $sellerAssignment->seller_id;
                        }
                    }
                }
            }

            // Send notifications to each seller
            if (!empty($sellerIds)) {
                $sellerTitle = "{$reportType} Report - Order #{$orderId}";
                $sellerMessage = $this->getSellerNotificationMessage($newStatus, $orderId);

                foreach ($sellerIds as $sellerId) {
                    SellerNotificationService::send(
                        $sellerId,
                        $sellerTitle,
                        $sellerMessage,
                        '',
                        'order',
                        $orderId,
                        [
                            'report_id' => $report->id,
                            'report_type' => $report->report_type,
                            'status' => $newStatus,
                            'status_name' => $statusName,
                        ]
                    );
                }

                Log::info('Seller notifications sent for issue report status change', [
                    'report_id' => $report->id,
                    'seller_ids' => $sellerIds,
                    'new_status' => $newStatus,
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Failed to send seller notifications', [
                'report_id' => $report->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Get notification message for sellers based on status
     */
    private function getSellerNotificationMessage($status, $orderId)
    {
        $messages = [
            2 => "The issue report for Order #{$orderId} has been resolved by admin. The refundable amount has been deducted from your wallet.",
            4 => "A delivery partner has been assigned to collect the reported item from the customer for Order #{$orderId}.",
            5 => "The delivery partner has collected the reported item from the customer for Order #{$orderId}.",
            6 => "The reported item has been returned successfully for Order #{$orderId}.",
        ];

        return $messages[$status] ?? "Issue report status updated for Order #{$orderId}.";
    }

    /**
     * Get customer issue reports for a specific order
     * Used by ViewOrder > CustomerReports tab
     */
    public function getReportsByOrderId(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $orderId = $request->order_id;

            // Get all reports for this order
            $reports = CustomerItemMissingReport::select(
                'customer_item_missing_reports.*',
                'users.name as customer_name',
                'users.mobile as customer_mobile',
                'users.email as customer_email'
            )
            ->leftJoin('users', 'customer_item_missing_reports.customer_id', '=', 'users.id')
            ->where('customer_item_missing_reports.order_id', $orderId)
            ->orderBy('customer_item_missing_reports.created_at', 'desc')
            ->get();

            // Separate by report type
            $missingReports = [];
            $wrongReports = [];
            $returnReports = [];

            foreach ($reports as $report) {
                $reportType = $report->report_type ?? 'missing';
                $selectedItems = $report->selected_items ?? [];
                $selectedComboItems = $report->selected_combo_items ?? [];

                // Get status name
                $statusName = $this->getStatusName($report->status);

                $reportData = [
                    'id' => $report->id,
                    'order_id' => $report->order_id,
                    'customer_id' => $report->customer_id,
                    'customer_name' => $report->customer_name,
                    'customer_mobile' => $report->customer_mobile,
                    'customer_email' => $report->customer_email,
                    'report_type' => $reportType,
                    'description' => $report->description,
                    'is_refund_requested' => $report->is_refund_requested,
                    'status' => $report->status,
                    'status_name' => $statusName,
                    'admin_remarks' => $report->admin_remarks,
                    'created_at' => $report->created_at ? $report->created_at->format('Y-m-d H:i:s') : null,
                    'updated_at' => $report->updated_at ? $report->updated_at->format('Y-m-d H:i:s') : null,
                ];

                if ($reportType === 'wrong') {
                    // For wrong item reports, include images
                    $sellerAssignments = DB::table('order_seller_status_tracking')
                        ->where('order_id', $orderId)
                        ->get()
                        ->keyBy('store_id');

                    $assignedSellerIds = $sellerAssignments->pluck('seller_id')->unique()->toArray();
                    $sellersInfo = [];
                    if (!empty($assignedSellerIds)) {
                        $sellersInfo = DB::table('sellers')
                            ->whereIn('id', $assignedSellerIds)
                            ->select('id', 'store_id', 'store_name', 'name')
                            ->get()
                            ->keyBy('id')
                            ->toArray();
                    }

                    $storeSellerMap = [];
                    foreach ($sellerAssignments as $storeId => $tracking) {
                        $sellerInfo = $sellersInfo[$tracking->seller_id] ?? null;
                        if ($sellerInfo) {
                            $storeSellerMap[$storeId] = [
                                'seller_id' => $tracking->seller_id,
                                'seller_name' => $sellerInfo->name,
                                'seller_store_name' => $sellerInfo->store_name,
                            ];
                        }
                    }

                    $enrichedItems = [];
                    foreach ($selectedItems as $storeItem) {
                        $storeId = (int) ($storeItem['store_id'] ?? 0);
                        $sellerData = $storeSellerMap[$storeId] ?? null;

                        $packerName = null;
                        $packerStoreName = null;
                        $packerId = null;

                        if ($storeId == 12) {
                            $packerName = 'Zenfoo';
                            $packerStoreName = 'Zenfoo Store';
                        } elseif ($storeId == 17) {
                            $packerName = $storeItem['store_name'] ?? 'DMart';
                            $packerStoreName = $storeItem['store_name'] ?? 'DMart';
                        } elseif ($sellerData) {
                            $packerId = $sellerData['seller_id'];
                            $packerName = $sellerData['seller_name'];
                            $packerStoreName = $sellerData['seller_store_name'];
                        }

                        $enrichedItems[] = [
                            'store_id' => $storeItem['store_id'] ?? 0,
                            'store_name' => $storeItem['store_name'] ?? 'Unknown',
                            'image_urls' => $storeItem['image_urls'] ?? [],
                            'description' => $storeItem['description'] ?? '',
                            'seller_id' => $packerId,
                            'seller_name' => $packerName,
                            'seller_store_name' => $packerStoreName,
                        ];
                    }

                    $enrichedComboItems = [];
                    foreach ($selectedComboItems as $comboItem) {
                        $enrichedComboItems[] = [
                            'combo_id' => $comboItem['combo_id'] ?? $comboItem['id'] ?? 0,
                            'combo_name' => $comboItem['combo_name'] ?? '',
                            'image_urls' => $comboItem['image_urls'] ?? [],
                            'description' => $comboItem['description'] ?? '',
                        ];
                    }

                    $reportData['store_wise_items'] = $enrichedItems;
                    $reportData['combo_items'] = $enrichedComboItems;
                    $wrongReports[] = $reportData;

                } else {
                    // For missing item reports, include product details
                    $storeWiseItems = [];
                    foreach ($selectedItems as $storeItem) {
                        $storeWiseItems[] = [
                            'store_id' => $storeItem['store_id'] ?? 0,
                            'store_name' => $storeItem['store_name'] ?? 'Unknown',
                            'description' => $storeItem['description'] ?? '',
                            'items' => $storeItem['items'] ?? [],
                        ];
                    }

                    $comboItems = [];
                    foreach ($selectedComboItems as $comboItem) {
                        $comboItems[] = [
                            'id' => $comboItem['id'] ?? 0,
                            'combo_name' => $comboItem['combo_name'] ?? '',
                            'combo_quantity' => $comboItem['combo_quantity'] ?? 1,
                            'sub_total' => $comboItem['sub_total'] ?? 0,
                            'description' => $comboItem['description'] ?? '',
                            'products' => $comboItem['products'] ?? [],
                        ];
                    }

                    $reportData['store_wise_items'] = $storeWiseItems;
                    $reportData['combo_items'] = $comboItems;

                    if ($reportType === 'return') {
                        $returnReports[] = $reportData;
                    } else {
                        $missingReports[] = $reportData;
                    }
                }
            }

            return CommonHelper::responseSuccess([
                'order_id' => $orderId,
                'missing_reports' => $missingReports,
                'wrong_reports' => $wrongReports,
                'return_reports' => $returnReports,
                'missing_count' => count($missingReports),
                'wrong_count' => count($wrongReports),
                'return_count' => count($returnReports),
                'total_count' => count($reports),
            ], 'Reports fetched successfully.');

        } catch (\Exception $e) {
            Log::error('Get Reports By Order ID Error', [
                'error' => $e->getMessage(),
                'order_id' => $request->order_id ?? null,
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch reports. Please try again later.');
        }
    }

    /**
     * Get seller-wise refund breakdown for a report
     * Used to show products with prices for refund calculation
     */
    public function getRefundBreakdown(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'report_id' => 'required|integer',
            'seller_id' => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // If seller_id is provided, get breakdown for specific seller
            if ($request->filled('seller_id')) {
                $result = CustomerIssueReportRefundService::getSellerRefundBreakdown(
                    $request->report_id,
                    $request->seller_id
                );
            } else {
                // Get full seller-wise breakdown
                $result = CustomerIssueReportRefundService::getSellerWiseRefundBreakdown($request->report_id);
            }

            if (!$result['success']) {
                return CommonHelper::responseError($result['message']);
            }

            return CommonHelper::responseWithData($result['data'], $result['message']);

        } catch (\Exception $e) {
            Log::error('Get Refund Breakdown Error', [
                'error' => $e->getMessage(),
                'report_id' => $request->report_id ?? null,
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch refund breakdown. Please try again later.');
        }
    }

    /**
     * Update Zenfoo store return status (Admin only)
     * This is called when admin confirms return items have been received at Zenfoo store
     */
    public function updateZenfooReturnStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'return_id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get return request - must be a Zenfoo store return (is_zenfoo_store = 1)
            $return = DB::table('customer_issue_report_returns')
                ->where('id', $request->return_id)
                ->where('is_zenfoo_store', 1)
                ->first();

            if (!$return) {
                return CommonHelper::responseError('Zenfoo store return request not found.');
            }

            // Check if this return is already accepted
            if ($return->is_return_accepted == 1) {
                return CommonHelper::responseSuccess('Return already accepted for Zenfoo store.');
            }

            // Update return status
            DB::table('customer_issue_report_returns')
                ->where('id', $request->return_id)
                ->update([
                    'is_return_accepted' => 1,
                    'updated_at' => now(),
                ]);

            Log::info('Admin updated Zenfoo store return status', [
                'return_id' => $request->return_id,
                'is_return_accepted' => 1,
            ]);

            
            // Note: Zenfoo store items don't have seller_id, so no seller wallet transaction updates needed
            // The refund comes from Zenfoo's own inventory, not from third-party sellers

            // Check if all returns (sellers + Zenfoo) have accepted the return for this report
            // If yes, update the report status to resolved (status = 2)
            $reportId = $return->report_id;

            // Get total count of return records for this report
            $totalReturnRecords = DB::table('customer_issue_report_returns')
                ->where('report_id', $reportId)
                ->count();

            // Get count of accepted return records for this report
            $acceptedReturnRecords = DB::table('customer_issue_report_returns')
                ->where('report_id', $reportId)
                ->where('is_return_accepted', 1)
                ->count();

            // If all parties have accepted, update report status to resolved
            if ($totalReturnRecords > 0 && $totalReturnRecords === $acceptedReturnRecords) {
                // Get the report first to get current status for status_change_json
                $report = CustomerItemMissingReport::find($reportId);
                $previousStatus = $report ? $report->status : 0;

                // Calculate total refundable amount from all return records
                $totalRefundableAmount = DB::table('customer_issue_report_returns')
                    ->where('report_id', $reportId)
                    ->sum('refundable_amount');

                // Get order details to check for deductions
                $order = DB::table('orders')
                    ->where('id', $report->order_id)
                    ->select('cart_metadata')
                    ->first();

                $promocodeDiscount = 0;
                $claimableMilestoneAmount = 0;

                if ($order && $order->cart_metadata) {
                    $cartMetadata = json_decode($order->cart_metadata, true);
                    $billingSummary = $cartMetadata['billing_summary'] ?? [];
                    $promocodeDiscount = (float) ($billingSummary['promocode_discount'] ?? 0);
                    $claimableMilestoneAmount = (float) ($billingSummary['claimable_milestone_amount'] ?? 0);
                }

                $totalDeductions = $promocodeDiscount + $claimableMilestoneAmount;
                $finalRefundAmount = $totalRefundableAmount - $totalDeductions;
                if ($finalRefundAmount < 0) {
                    $finalRefundAmount = 0;
                }

                // Build status change message
                $statusMessage = "Your issue has been resolved.";
                if ($finalRefundAmount > 0) {
                    $statusMessage = "Your issue has been resolved. An amount of ₹" . number_format($finalRefundAmount, 2) . " has been refunded to your wallet.";
                }

                // Get existing status_change_json and append new entry
                $existingStatusJson = $report->status_change_json ?? [];
                if (is_string($existingStatusJson)) {
                    $existingStatusJson = json_decode($existingStatusJson, true) ?? [];
                }

                $newStatusEntry = [
                    'from_status' => $previousStatus,
                    'to_status' => CustomerItemMissingReport::$statusResolved,
                    'status_name' => 'Resolved',
                    'message' => $statusMessage,
                    'admin_remarks' => 'All returns accepted (including Zenfoo store)',
                    'refund_amount' => $finalRefundAmount,
                    'changed_at' => now()->format('Y-m-d H:i:s'),
                ];

                $existingStatusJson[] = $newStatusEntry;

                // Update report status and status_change_json
                CustomerItemMissingReport::where('id', $reportId)
                    ->update([
                        'status' => CustomerItemMissingReport::$statusResolved,
                        'status_change_json' => json_encode($existingStatusJson),
                        'updated_at' => now(),
                    ]);

                Log::info('All returns accepted (Zenfoo + sellers) - Report marked as resolved', [
                    'report_id' => $reportId,
                    'total_returns' => $totalReturnRecords,
                    'status_change_json' => $newStatusEntry,
                ]);

                // Credit refund to customer wallet if final refund amount exists
                if ($finalRefundAmount > 0 && $report) {
                    try {
                        $customer = User::find($report->customer_id);

                        if ($customer) {
                            $customer->balance = $customer->balance + $finalRefundAmount;
                            $customer->save();

                            // Build wallet transaction message
                            $walletMessage = "Refund for Issue Report #{$reportId} - Order #{$report->order_id}";
                            if ($totalDeductions > 0) {
                                $walletMessage .= ". Original amount: ₹" . number_format($totalRefundableAmount, 2);
                                if ($promocodeDiscount > 0) {
                                    $walletMessage .= ", Promocode Discount deducted: ₹" . number_format($promocodeDiscount, 2);
                                }
                                if ($claimableMilestoneAmount > 0) {
                                    $walletMessage .= ", Milestone Reward deducted: ₹" . number_format($claimableMilestoneAmount, 2);
                                }
                                $walletMessage .= ". Final refund: ₹" . number_format($finalRefundAmount, 2);
                            }

                            // Create wallet transaction record
                            $walletTransaction = new WalletTransaction();
                            $walletTransaction->user_id = $report->customer_id;
                            $walletTransaction->order_id = $report->order_id;
                            $walletTransaction->type = 'credit';
                            $walletTransaction->amount = $finalRefundAmount;
                            $walletTransaction->txn_id = 'refund_report_' . $reportId;
                            $walletTransaction->payment_type = 'refund';
                            $walletTransaction->message = $walletMessage;
                            $walletTransaction->status = 1;
                            $walletTransaction->save();

                            Log::info('Refund credited to customer wallet (Zenfoo return)', [
                                'report_id' => $reportId,
                                'customer_id' => $report->customer_id,
                                'final_refund_amount' => $finalRefundAmount,
                                'new_balance' => $customer->balance,
                            ]);
                        }
                    } catch (\Exception $e) {
                        Log::error('Failed to credit refund to customer wallet (Zenfoo return)', [
                            'report_id' => $reportId,
                            'error' => $e->getMessage(),
                        ]);
                    }
                }

                // Send notification to customer
                if ($report) {
                    try {
                        $deductionMessage = '';
                        if ($totalDeductions > 0) {
                            $deductionParts = [];
                            if ($promocodeDiscount > 0) {
                                $deductionParts[] = "Promocode Discount: ₹" . number_format($promocodeDiscount, 2);
                            }
                            if ($claimableMilestoneAmount > 0) {
                                $deductionParts[] = "Milestone Reward: ₹" . number_format($claimableMilestoneAmount, 2);
                            }
                            $deductionMessage = " (Deductions: " . implode(', ', $deductionParts) . ")";
                        }

                        $notificationMessage = "Your issue report for Order #{$report->order_id} has been resolved.";
                        if ($finalRefundAmount > 0) {
                            $notificationMessage .= " ₹" . number_format($finalRefundAmount, 2) . " has been credited to your wallet.";
                            if ($totalDeductions > 0) {
                                $notificationMessage .= $deductionMessage;
                            }
                        }

                        CustomerNotificationService::send(
                            $report->customer_id,
                            'Issue Report Resolved',
                            $notificationMessage,
                            '',
                            'order',
                            $report->order_id,
                            ['report_id' => $reportId, 'refund_amount' => $finalRefundAmount]
                        );

                        Log::info('Customer notification sent for resolved report (Zenfoo return)', [
                            'report_id' => $reportId,
                            'customer_id' => $report->customer_id,
                        ]);
                    } catch (\Exception $e) {
                        Log::error('Failed to send customer notification (Zenfoo return)', [
                            'report_id' => $reportId,
                            'error' => $e->getMessage(),
                        ]);
                    }
                }

                return CommonHelper::responseSuccess('Zenfoo store return accepted. All returns confirmed - report has been resolved and refund processed.');
            }

            return CommonHelper::responseSuccess('Zenfoo store return status updated successfully.');

        } catch (\Exception $e) {
            Log::error('Update Zenfoo Return Status Error', [
                'error' => $e->getMessage(),
                'return_id' => $request->return_id,
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to update return status. Please try again later.');
        }
    }
}
