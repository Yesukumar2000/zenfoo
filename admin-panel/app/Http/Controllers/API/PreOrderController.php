<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderStatusList;
use App\Models\Seller;
use App\Models\Store;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use App\Services\CityZoneService;

class PreOrderController extends Controller
{
    /**
     * Get all preorders with filters
     */
    public function getPreOrders(Request $request)
    {
        $limit = $request->input('per_page', 10);
        $offset = (($request->input('page', 1))-1)*$limit;
        $search = $request->input('search', '');

        Log::info('getPreOrders - Request params:', $request->all());

        $startDate = $request->input('startDate') ? Carbon::parse($request->input('startDate'))->startOfDay() : null;
        $endDate = $request->input('endDate') ? Carbon::parse($request->input('endDate'))->endOfDay() : null;

        $orders = Order::select(
            'orders.id',
            'orders.mobile',
            'orders.total',
            'orders.status',
            'orders.active_status',
            'orders.delivery_charge',
            'orders.wallet_balance',
            'orders.final_total',
            'orders.remaining_final',
            'orders.payment_method',
            'orders.delivery_time',
            'orders.additional_charges',
            'orders.is_preorder',
            'orders.preorder_placed_at',
            'orders.preorder_process_date',
            'orders.created_at',
            DB::raw('TIMESTAMPDIFF(MINUTE, orders.created_at, NOW()) as minutes_from_now'),
            'users.name as user_name',
            'delivery_boys.name as delivery_boy_name'
        )
        ->leftJoin('users', 'orders.user_id', '=', 'users.id')
        ->leftJoin('delivery_boys', 'orders.delivery_boy_id', '=', 'delivery_boys.id')
        ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
        ->where('orders.is_preorder', 1);

        // Date range filter
        if($startDate && $endDate){
            $orders = $orders->whereBetween('orders.preorder_placed_at', [$startDate, $endDate]);
        }

        // Status filter
        if($request->has('status') && $request->status != ""){
            $orders = $orders->where('orders.active_status', $request->status);
        }

        // Store filter
        if($request->has('store_id') && $request->store_id != ""){
            $storeId = $request->store_id;
            $orders = $orders->whereIn('orders.id', function($query) use ($storeId) {
                $query->select('order_id')
                    ->from('order_seller_status_tracking')
                    ->where('store_id', $storeId);
            });
        }

        // Seller filter
        if($request->has('seller') && $request->seller != ""){
            $orders = $orders->whereIn('orders.id', function($query) use ($request) {
                $query->select('order_id')
                    ->from('order_seller_status_tracking')
                    ->where('seller_id', $request->seller);
            });
        }

        // City filter via user_addresses
        if($request->has('city_id') && $request->city_id != ""){
            $orders = $orders->where('user_addresses.city_id', $request->city_id);
        }

        // Search filter
        if ($search) {
            $orders = $orders->where(function($query) use ($search) {
                $query->where('orders.id', 'like', "%{$search}%")
                    ->orWhere('orders.mobile', 'like', "%{$search}%")
                    ->orWhere('users.name', 'like', "%{$search}%")
                    ->orWhere('orders.payment_method', 'like', "%{$search}%");
            });
        }

        $orders = $orders->orderBy('orders.id', 'DESC');

        $orders_total = $orders->count();
        $orders_data = $orders->skip($offset)->take($limit)->get();

        // Format preorder dates
        foreach ($orders_data as $order) {
            if (!empty($order->additional_charges)) {
                if (is_string($order->additional_charges)) {
                    $order->additional_charges = json_decode($order->additional_charges, true);
                }
            }

            $order->preorder_placed_at_formatted = $order->preorder_placed_at ?
                Carbon::parse($order->preorder_placed_at)->format('d M Y, h:i A') : null;
            $order->preorder_process_date_formatted = $order->preorder_process_date ?
                Carbon::parse($order->preorder_process_date)->format('d M Y, h:i A') : null;
        }

        $sellers = Seller::where('status',1)->orderBy('id','DESC')->get();
        $stores = Store::where('managed_by_admin', 1)->orderBy('name','ASC')->get();

        return response()->json([
            'status' => 1,
            'data' => [
                'orders' => $orders_data,
                'orders_total' => $orders_total,
                'sellers' => $sellers,
                'stores' => $stores
            ]
        ]);
    }

    /**
     * Get preorder statistics
     */
    public function getPreOrderStats()
    {
        $pending = Order::where('is_preorder', 1)
            ->where('active_status', OrderStatusList::$preorderPending)
            ->count();

        $processed = Order::where('is_preorder', 1)
            ->where('active_status', '!=', OrderStatusList::$preorderPending)
            ->count();

        $total = Order::where('is_preorder', 1)->count();

        $nextProcessDate = Order::where('is_preorder', 1)
            ->where('active_status', OrderStatusList::$preorderPending)
            ->min('preorder_process_date');

        return response()->json([
            'status' => 1,
            'data' => [
                'pending' => $pending,
                'processed' => $processed,
                'total' => $total,
                'next_process_date' => $nextProcessDate ? Carbon::parse($nextProcessDate)->format('d M Y, h:i A') : null
            ]
        ]);
    }

    /**
     * Get preorder details by ID
     */
    public function getPreOrderDetails($id)
    {
        $order = Order::with(['items', 'user'])
            ->where('id', $id)
            ->where('is_preorder', 1)
            ->first();

        if (!$order) {
            return response()->json([
                'status' => 0,
                'message' => 'Preorder not found'
            ], 404);
        }

        return response()->json([
            'status' => 1,
            'data' => $order
        ]);
    }

    /**
     * Get store-wise preorder analytics
     */
    public function getStoreWiseAnalytics(Request $request)
    {
        $startDate = $request->input('startDate') ? Carbon::parse($request->input('startDate'))->startOfDay() : null;
        $endDate = $request->input('endDate') ? Carbon::parse($request->input('endDate'))->endOfDay() : null;
        $status = $request->input('status');
        $cityId = $request->input('city_id');

        // Build base query for preorders
        $preordersQuery = Order::where('orders.is_preorder', 1);

        if ($startDate && $endDate) {
            $preordersQuery->whereBetween('orders.preorder_placed_at', [$startDate, $endDate]);
        }

        if ($status) {
            $preordersQuery->where('orders.active_status', $status);
        }

        // City filter via user_addresses
        if ($cityId) {
            $preordersQuery->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $preorderIds = $preordersQuery->pluck('orders.id');

        // Get store-wise data from order_items
        $storeWiseItems = DB::table('order_items')
            ->join('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->join('stores', 'products.store_id', '=', 'stores.id')
            ->whereIn('order_items.order_id', $preorderIds)
            ->select(
                'stores.id as store_id',
                'stores.name as store_name',
                DB::raw('COUNT(DISTINCT order_items.order_id) as order_count'),
                DB::raw('COUNT(order_items.id) as item_count'),
                DB::raw('SUM(order_items.sub_total) as total_amount')
            )
            ->groupBy('stores.id', 'stores.name')
            ->orderBy('order_count', 'DESC')
            ->get();

        // Get store-wise data from combo products (count individual products in combos, not just combo rows)
        $storeWiseComboItems = DB::table('order_combo_items')
            ->join('combo_products', 'order_combo_items.combo_id', '=', 'combo_products.combo_id')
            ->join('products', 'combo_products.product_id', '=', 'products.id')
            ->join('stores', 'products.store_id', '=', 'stores.id')
            ->whereIn('order_combo_items.order_id', $preorderIds)
            ->select(
                'stores.id as store_id',
                'stores.name as store_name',
                DB::raw('COUNT(combo_products.product_id) as item_count')
            )
            ->groupBy('stores.id', 'stores.name')
            ->get();

        // Get total amount from combo items per store (by parsing products JSON and summing individual products)
        // First, get all combo items with their products
        $allComboItems = DB::table('order_combo_items')
            ->whereIn('order_id', $preorderIds)
            ->select('id', 'products')
            ->get();

        // Get product IDs from all combo items
        $allComboProductIds = [];
        foreach ($allComboItems as $comboItem) {
            if (!empty($comboItem->products)) {
                $products = json_decode($comboItem->products, true);
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }
                if (is_array($products)) {
                    foreach ($products as $product) {
                        if (isset($product['product_id'])) {
                            $allComboProductIds[] = $product['product_id'];
                        }
                    }
                }
            }
        }
        $allComboProductIds = array_unique($allComboProductIds);

        // Get product_id => store_id mapping
        $productStoreMap = [];
        if (!empty($allComboProductIds)) {
            $productStoreMap = DB::table('products')
                ->whereIn('id', $allComboProductIds)
                ->pluck('store_id', 'id')
                ->toArray();
        }

        // Calculate amounts per store by parsing JSON
        $storeWiseComboAmounts = [];
        foreach ($allComboItems as $comboItem) {
            if (!empty($comboItem->products)) {
                $products = json_decode($comboItem->products, true);
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }
                if (is_array($products)) {
                    foreach ($products as $product) {
                        $productId = $product['product_id'] ?? null;
                        $storeId = $productStoreMap[$productId] ?? 0;
                        $subTotal = floatval($product['sub_total'] ?? 0);

                        if (!isset($storeWiseComboAmounts[$storeId])) {
                            $storeWiseComboAmounts[$storeId] = 0;
                        }
                        $storeWiseComboAmounts[$storeId] += $subTotal;
                    }
                }
            }
        }

        // Merge both results - track unique order IDs to avoid double counting
        $storeWiseData = [];
        $storeOrderIds = []; // Track unique order IDs per store

        // Get order IDs from regular items
        $regularItemOrders = DB::table('order_items')
            ->join('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->whereIn('order_items.order_id', $preorderIds)
            ->select('products.store_id', 'order_items.order_id')
            ->get();

        foreach ($regularItemOrders as $row) {
            if (!isset($storeOrderIds[$row->store_id])) {
                $storeOrderIds[$row->store_id] = [];
            }
            $storeOrderIds[$row->store_id][] = $row->order_id;
        }

        // Get order IDs from combo items (need to check which stores are involved via combo_products)
        $comboItemOrders = DB::table('order_combo_items')
            ->join('combo_products', 'order_combo_items.combo_id', '=', 'combo_products.combo_id')
            ->join('products', 'combo_products.product_id', '=', 'products.id')
            ->whereIn('order_combo_items.order_id', $preorderIds)
            ->select('products.store_id', 'order_combo_items.order_id')
            ->get();

        foreach ($comboItemOrders as $row) {
            if (!isset($storeOrderIds[$row->store_id])) {
                $storeOrderIds[$row->store_id] = [];
            }
            $storeOrderIds[$row->store_id][] = $row->order_id;
        }

        // Initialize store data with regular items
        foreach ($storeWiseItems as $item) {
            $storeWiseData[$item->store_id] = [
                'store_id' => $item->store_id,
                'store_name' => $item->store_name,
                'order_count' => 0, // Will be calculated from unique order IDs
                'item_count' => $item->item_count,
                'total_amount' => $item->total_amount
            ];
        }

        // Merge combo items data (count individual products in combos)
        foreach ($storeWiseComboItems as $combo) {
            if (isset($storeWiseData[$combo->store_id])) {
                // Add individual product count from combos
                $storeWiseData[$combo->store_id]['item_count'] += $combo->item_count;
            } else {
                $storeWiseData[$combo->store_id] = [
                    'store_id' => $combo->store_id,
                    'store_name' => $combo->store_name,
                    'order_count' => 0, // Will be calculated from unique order IDs
                    'item_count' => $combo->item_count,
                    'total_amount' => 0 // Will be added below
                ];
            }
        }

        // Add combo amounts to store data
        foreach ($storeWiseComboAmounts as $storeId => $amount) {
            if (isset($storeWiseData[$storeId])) {
                $storeWiseData[$storeId]['total_amount'] += $amount;
            }
        }

        // Calculate actual order count from unique order IDs
        foreach ($storeWiseData as $storeId => &$data) {
            if (isset($storeOrderIds[$storeId])) {
                $data['order_count'] = count(array_unique($storeOrderIds[$storeId]));
            }
        }
        unset($data); // Break the reference

        // Sort by order count
        usort($storeWiseData, function($a, $b) {
            return $b['order_count'] - $a['order_count'];
        });

        return response()->json([
            'status' => 1,
            'data' => array_values($storeWiseData)
        ]);
    }

    /**
     * Get preorders data for PDF generation (frontend will handle PDF via print)
     */
    public function exportPDF(Request $request)
    {
        $startDate = $request->input('startDate') ? Carbon::parse($request->input('startDate'))->startOfDay() : null;
        $endDate = $request->input('endDate') ? Carbon::parse($request->input('endDate'))->endOfDay() : null;
        $search = $request->input('search', '');

        $orders = Order::select(
            'orders.id',
            'orders.mobile',
            'orders.total',
            'orders.status',
            'orders.active_status',
            'orders.delivery_charge',
            'orders.wallet_balance',
            'orders.final_total',
            'orders.payment_method',
            'orders.preorder_placed_at',
            'orders.preorder_process_date',
            'users.name as user_name'
        )
        ->leftJoin('users', 'orders.user_id', '=', 'users.id')
        ->where('orders.is_preorder', 1);

        // Apply filters
        if ($startDate && $endDate) {
            $orders = $orders->whereBetween('orders.preorder_placed_at', [$startDate, $endDate]);
        }

        if ($request->has('status') && $request->status != "") {
            $orders = $orders->where('orders.active_status', $request->status);
        }

        if ($request->has('store_id') && $request->store_id != "") {
            $storeId = $request->store_id;
            $orders = $orders->whereIn('orders.id', function($query) use ($storeId) {
                $query->select('order_id')
                    ->from('order_seller_status_tracking')
                    ->where('store_id', $storeId);
            });
        }

        if ($search) {
            $orders = $orders->where(function($query) use ($search) {
                $query->where('orders.id', 'like', "%{$search}%")
                    ->orWhere('orders.mobile', 'like', "%{$search}%")
                    ->orWhere('users.name', 'like', "%{$search}%");
            });
        }

        $orders = $orders->orderBy('orders.id', 'DESC')->get();

        // Format dates
        foreach ($orders as $order) {
            $order->preorder_placed_at_formatted = $order->preorder_placed_at ?
                Carbon::parse($order->preorder_placed_at)->format('d M Y, h:i A') : null;
            $order->preorder_process_date_formatted = $order->preorder_process_date ?
                Carbon::parse($order->preorder_process_date)->format('d M Y, h:i A') : null;
        }

        // Return data as JSON for frontend PDF generation
        return response()->json([
            'status' => 1,
            'data' => [
                'orders' => $orders,
                'date' => Carbon::now()->format('d M Y'),
                'totalAmount' => $orders->sum('final_total'),
                'totalOrders' => $orders->count()
            ]
        ]);
    }

    /**
     * Export preorders to CSV (Excel-compatible)
     */
    public function exportExcel(Request $request)
    {
        $startDate = $request->input('startDate') ? Carbon::parse($request->input('startDate'))->startOfDay() : null;
        $endDate = $request->input('endDate') ? Carbon::parse($request->input('endDate'))->endOfDay() : null;
        $search = $request->input('search', '');

        $orders = Order::select(
            'orders.id',
            'orders.mobile',
            'orders.total',
            'orders.delivery_charge',
            'orders.wallet_balance',
            'orders.final_total',
            'orders.payment_method',
            'orders.active_status',
            'orders.preorder_placed_at',
            'orders.preorder_process_date',
            'users.name as user_name'
        )
        ->leftJoin('users', 'orders.user_id', '=', 'users.id')
        ->where('orders.is_preorder', 1);

        // Apply filters
        if ($startDate && $endDate) {
            $orders = $orders->whereBetween('orders.preorder_placed_at', [$startDate, $endDate]);
        }

        if ($request->has('status') && $request->status != "") {
            $orders = $orders->where('orders.active_status', $request->status);
        }

        if ($request->has('store_id') && $request->store_id != "") {
            $storeId = $request->store_id;
            $orders = $orders->whereIn('orders.id', function($query) use ($storeId) {
                $query->select('order_id')
                    ->from('order_seller_status_tracking')
                    ->where('store_id', $storeId);
            });
        }

        if ($search) {
            $orders = $orders->where(function($query) use ($search) {
                $query->where('orders.id', 'like', "%{$search}%")
                    ->orWhere('orders.mobile', 'like', "%{$search}%")
                    ->orWhere('users.name', 'like', "%{$search}%");
            });
        }

        $orders = $orders->orderBy('orders.id', 'DESC')->get();

        // Status map
        $statusMap = [
            12 => 'Preorder Pending',
            2 => 'Processed',
            3 => 'In Progress',
            5 => 'Out For Delivery',
            6 => 'Delivered'
        ];

        // Generate CSV
        $filename = 'preorders-' . Carbon::now()->format('Y-m-d') . '.csv';
        $headers = [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ];

        $callback = function() use ($orders, $statusMap) {
            $file = fopen('php://output', 'w');

            // Add BOM for Excel UTF-8 compatibility
            fprintf($file, chr(0xEF).chr(0xBB).chr(0xBF));

            // Add headers
            fputcsv($file, [
                'Order ID',
                'Customer Name',
                'Mobile',
                'Subtotal',
                'Delivery Charge',
                'Wallet Used',
                'Final Total',
                'Payment Method',
                'Status',
                'Placed At',
                'Process Date'
            ]);

            // Add data rows
            foreach ($orders as $order) {
                fputcsv($file, [
                    $order->id,
                    $order->user_name ?: 'Guest',
                    $order->mobile,
                    number_format($order->total, 2),
                    number_format($order->delivery_charge, 2),
                    number_format($order->wallet_balance, 2),
                    number_format($order->final_total, 2),
                    $order->payment_method,
                    $statusMap[$order->active_status] ?? 'Status ' . $order->active_status,
                    $order->preorder_placed_at ? Carbon::parse($order->preorder_placed_at)->format('d M Y, h:i A') : 'N/A',
                    $order->preorder_process_date ? Carbon::parse($order->preorder_process_date)->format('d M Y, h:i A') : 'N/A'
                ]);
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    /**
     * Get single preorder data (frontend handles PDF via thermal print feature)
     */
    public function downloadOrderPDF($id)
    {
        $order = Order::with(['items', 'user'])
            ->where('id', $id)
            ->where('is_preorder', 1)
            ->first();

        if (!$order) {
            return response()->json([
                'status' => 0,
                'message' => 'Preorder not found'
            ], 404);
        }

        $order->preorder_placed_at_formatted = $order->preorder_placed_at ?
            Carbon::parse($order->preorder_placed_at)->format('d M Y, h:i A') : null;
        $order->preorder_process_date_formatted = $order->preorder_process_date ?
            Carbon::parse($order->preorder_process_date)->format('d M Y, h:i A') : null;

        // Return order data - frontend will use thermal print which has print-to-PDF capability
        return response()->json([
            'status' => 1,
            'data' => $order,
            'message' => 'Use the Thermal Print option and select "Save as PDF" in the print dialog'
        ]);
    }

    /**
     * Get store preorders with items (for detailed view)
     */
    public function getStoreOrders(Request $request)
    {
        $storeId = $request->input('store_id');
        $startDate = $request->input('startDate') ? Carbon::parse($request->input('startDate'))->startOfDay() : null;
        $endDate = $request->input('endDate') ? Carbon::parse($request->input('endDate'))->endOfDay() : null;
        $status = $request->input('status');

        if (!$storeId) {
            return response()->json([
                'status' => 0,
                'message' => 'Store ID is required'
            ], 400);
        }

        // Load orders with items and combo items filtered by store
        $orders = Order::with([
                'items' => function($query) use ($storeId) {
                    $query->with('productVariant')->whereHas('productVariant.product', function($q) use ($storeId) {
                        $q->where('store_id', $storeId);
                    });
                },
                'comboItems' => function($query) use ($storeId) {
                    // Filter combos that have products from this store
                    $query->whereHas('combo.products', function($q) use ($storeId) {
                        $q->where('products.store_id', $storeId);
                    });
                },
                'user'
            ])
            ->select(
                'orders.id',
                'orders.user_id',
                'orders.address_id',
                'orders.mobile',
                'orders.total',
                'orders.status',
                'orders.active_status',
                'orders.delivery_charge',
                'orders.wallet_balance',
                'orders.final_total',
                'orders.payment_method',
                'orders.preorder_placed_at',
                'orders.preorder_process_date',
                'users.name as user_name'
            )
            ->leftJoin('users', 'orders.user_id', '=', 'users.id')
            ->where('orders.is_preorder', 1)
            ->where(function($query) use ($storeId) {
                // Find orders that have items from this store OR combo items with products from this store
                $query->whereHas('items', function($q) use ($storeId) {
                    $q->whereHas('productVariant.product', function($pq) use ($storeId) {
                        $pq->where('store_id', $storeId);
                    });
                })->orWhereHas('comboItems', function($q) use ($storeId) {
                    // Check if combo has products from this store
                    $q->whereHas('combo.products', function($cq) use ($storeId) {
                        $cq->where('products.store_id', $storeId);
                    });
                });
            });

        // Apply filters
        if ($startDate && $endDate) {
            $orders = $orders->whereBetween('orders.preorder_placed_at', [$startDate, $endDate]);
        }

        if ($status) {
            $orders = $orders->where('orders.active_status', $status);
        }

        $orders = $orders->orderBy('orders.id', 'DESC')->get();

        // Debug: Log the number of orders found
        \Log::info('Store Orders Query', [
            'store_id' => $storeId,
            'orders_count' => $orders->count(),
            'orders_ids' => $orders->pluck('id')->toArray()
        ]);

        // Build store_wise_products for combo items
        // Step 1: Collect all product IDs from combo items
        $allComboProductIds = [];
        foreach ($orders as $order) {
            if ($order->comboItems && count($order->comboItems) > 0) {
                foreach ($order->comboItems as $comboItem) {
                    if (!empty($comboItem->products)) {
                        $products = json_decode($comboItem->products, true);
                        if (is_string($products)) {
                            $products = json_decode($products, true);
                        }
                        if (is_array($products)) {
                            foreach ($products as $product) {
                                if (isset($product['product_id'])) {
                                    $allComboProductIds[] = $product['product_id'];
                                }
                            }
                        }
                    }
                }
            }
        }
        $allComboProductIds = array_unique($allComboProductIds);

        // Step 2: Get store_ids for combo products
        $comboProductStoreMap = [];
        if (!empty($allComboProductIds)) {
            $comboProductStoreMap = DB::table('products')
                ->whereIn('id', $allComboProductIds)
                ->pluck('store_id', 'id')
                ->toArray();
        }

        // Step 3: Get combo store IDs and fetch store names
        $comboStoreIds = array_unique(array_values($comboProductStoreMap));
        $storeNames = [];
        if (!empty($comboStoreIds)) {
            $storeNames = DB::table('stores')
                ->whereIn('id', $comboStoreIds)
                ->pluck('name', 'id')
                ->toArray();
        }

        // Format dates and calculate store-specific totals
        foreach ($orders as $order) {
            $order->preorder_placed_at_formatted = $order->preorder_placed_at ?
                Carbon::parse($order->preorder_placed_at)->format('d M Y, h:i A') : null;
            $order->preorder_process_date_formatted = $order->preorder_process_date ?
                Carbon::parse($order->preorder_process_date)->format('d M Y, h:i A') : null;

            // Calculate totals from only this store's items (both regular and combo items)
            $regularItemsTotal = ($order->items && count($order->items) > 0) ? $order->items->sum('sub_total') : 0;

            // Calculate combo items total for this store only (sum products from this store, not full combo price)
            $comboItemsTotal = 0;
            if ($order->comboItems && count($order->comboItems) > 0) {
                foreach ($order->comboItems as $comboItem) {
                    if (!empty($comboItem->products)) {
                        $products = json_decode($comboItem->products, true);
                        if (is_string($products)) {
                            $products = json_decode($products, true);
                        }
                        if (is_array($products)) {
                            foreach ($products as $product) {
                                $productId = $product['product_id'] ?? null;
                                $productStoreId = $comboProductStoreMap[$productId] ?? 0;

                                // Only add products from this store
                                if ($productStoreId == $storeId) {
                                    $comboItemsTotal += floatval($product['sub_total'] ?? 0);
                                }
                            }
                        }
                    }
                }
            }

            $storeItemsTotal = $regularItemsTotal + $comboItemsTotal;

            if ($storeItemsTotal > 0) {
                // Update the subtotal to reflect only this store's items
                $order->total = $storeItemsTotal;

                // No delivery charge for store-specific view
                $order->delivery_charge = 0;

                // Set final total to just the store items total (no delivery, no wallet)
                $order->final_total = $storeItemsTotal;
            }

            // Add store_wise_products structure to combo items
            if ($order->comboItems && count($order->comboItems) > 0) {
                foreach ($order->comboItems as $comboItem) {
                    $comboItem->store_wise_products = [];

                    if (!empty($comboItem->products)) {
                        $products = json_decode($comboItem->products, true);
                        if (is_string($products)) {
                            $products = json_decode($products, true);
                        }
                        if (is_array($products)) {
                            // Group products by store
                            $storeWiseComboProducts = [];
                            foreach ($products as $product) {
                                $productId = $product['product_id'] ?? null;
                                $productStoreId = $comboProductStoreMap[$productId] ?? 0;

                                if (!isset($storeWiseComboProducts[$productStoreId])) {
                                    $storeWiseComboProducts[$productStoreId] = [
                                        'store_id' => $productStoreId,
                                        'store_name' => $storeNames[$productStoreId] ?? '',
                                        'products' => []
                                    ];
                                }
                                $storeWiseComboProducts[$productStoreId]['products'][] = $product;
                            }
                            $comboItem->store_wise_products = array_values($storeWiseComboProducts);
                        }
                    }
                }
            }

            // Check if this is a Zenfoo store or if seller is assigned
            $trackingInfo = DB::table('order_seller_status_tracking as osst')
                ->leftJoin('sellers', 'osst.seller_id', '=', 'sellers.id')
                ->where('osst.order_id', $order->id)
                ->where('osst.store_id', $storeId)
                ->select('osst.seller_id', 'osst.is_zenfoo_store', 'sellers.name as seller_name')
                ->first();

            if ($trackingInfo) {
                // Check if it's a Zenfoo store
                if ($trackingInfo->is_zenfoo_store == 1) {
                    $order->is_zenfoo_store = true;
                    $order->is_seller_assigned = false;
                    $order->assigned_seller_id = null;
                    $order->assigned_seller_name = null;
                }
                // Check if seller is assigned
                elseif ($trackingInfo->seller_id && $trackingInfo->seller_id != 0) {
                    $order->is_zenfoo_store = false;
                    $order->is_seller_assigned = true;
                    $order->assigned_seller_id = $trackingInfo->seller_id;
                    $order->assigned_seller_name = $trackingInfo->seller_name ?: 'Seller #' . $trackingInfo->seller_id;
                }
                else {
                    $order->is_zenfoo_store = false;
                    $order->is_seller_assigned = false;
                    $order->assigned_seller_id = null;
                    $order->assigned_seller_name = null;
                }
            } else {
                $order->is_zenfoo_store = false;
                $order->is_seller_assigned = false;
                $order->assigned_seller_id = null;
                $order->assigned_seller_name = null;
            }
        }

        // -------------------------------------------------------
        // Zone-based grouping: group orders by customer delivery zone
        // and fetch eligible sellers per zone
        // -------------------------------------------------------
        $zoneFilterEnabled = CityZoneService::isZoneFilterEnabled();
        $zoneGroups = [];

        // Collect all address_ids from orders
        $addressIds = $orders->pluck('address_id')->filter()->unique()->values()->toArray();

        // Fetch delivery addresses
        $addresses = [];
        if (!empty($addressIds)) {
            $addresses = DB::table('user_addresses')
                ->whereIn('id', $addressIds)
                ->select('id', 'latitude', 'longitude')
                ->get()
                ->keyBy('id');
        }

        // Detect zone for each order
        $orderZoneMap = []; // order_id => zone_id (or 'no_zone')
        $detectedZones = []; // zone_id => city object

        foreach ($orders as $order) {
            $zoneKey = 'no_zone';

            if ($zoneFilterEnabled && !empty($order->address_id) && isset($addresses[$order->address_id])) {
                $addr = $addresses[$order->address_id];
                if (!empty($addr->latitude) && !empty($addr->longitude)) {
                    $lat = (float) $addr->latitude;
                    $lon = (float) $addr->longitude;
                    $city = CityZoneService::detectCity($lat, $lon);
                    if ($city) {
                        $zoneKey = $city->id;
                        if (!isset($detectedZones[$zoneKey])) {
                            $detectedZones[$zoneKey] = [
                                'city' => $city,
                                'lat' => $lat,
                                'lon' => $lon,
                            ];
                        }
                    }
                }
            }

            $orderZoneMap[$order->id] = $zoneKey;
        }

        // Fetch all active sellers for this store (base query before zone filtering)
        $now = now()->setTimezone('Asia/Kolkata')->format('H:i:s');
        $allSellers = DB::table('sellers')
            ->select('id', 'store_id', 'other_store_ids', 'store_name', 'name')
            ->where('status', 1)
            ->where('shop_status', 1)
            ->where(function ($q) use ($now) {
                $q->whereNull('shop_opening_time')
                  ->orWhereRaw('? >= shop_opening_time', [$now]);
            })
            ->get();

        // Filter sellers that serve this store
        $storeSellers = $allSellers->filter(function ($seller) use ($storeId) {
            if ((int) $seller->store_id === (int) $storeId) {
                return true;
            }
            if (!empty($seller->other_store_ids)) {
                $otherIds = json_decode($seller->other_store_ids, true);
                if (is_array($otherIds) && in_array((int) $storeId, array_map('intval', $otherIds))) {
                    return true;
                }
            }
            return false;
        })->values();

        $storeSellerIds = $storeSellers->pluck('id')->toArray();

        // Group orders by zone and get eligible sellers per zone
        $groupedOrders = [];
        foreach ($orders as $order) {
            $zoneKey = $orderZoneMap[$order->id] ?? 'no_zone';
            if (!isset($groupedOrders[$zoneKey])) {
                $groupedOrders[$zoneKey] = [];
            }
            $groupedOrders[$zoneKey][] = $order;
        }

        foreach ($groupedOrders as $zoneKey => $zoneOrders) {
            $zoneName = 'Unknown Zone';
            $eligibleSellerIds = $storeSellerIds;

            if ($zoneKey !== 'no_zone' && isset($detectedZones[$zoneKey])) {
                $zoneInfo = $detectedZones[$zoneKey];
                $zoneName = $zoneInfo['city']->name;

                // Apply zone filtering to sellers
                if ($zoneFilterEnabled && !empty($storeSellerIds)) {
                    $eligibleSellerIds = CityZoneService::filterSellersByZone(
                        $storeSellerIds,
                        $zoneInfo['city'],
                        $zoneInfo['lat'],
                        $zoneInfo['lon']
                    );
                }
            }

            // Get seller details for eligible sellers
            $eligibleSellersList = $storeSellers->filter(function ($s) use ($eligibleSellerIds) {
                return in_array($s->id, $eligibleSellerIds);
            })->map(function ($s) {
                return [
                    'id' => $s->id,
                    'name' => $s->name,
                    'store_name' => $s->store_name,
                ];
            })->values()->toArray();

            $zoneGroups[] = [
                'zone_id' => $zoneKey !== 'no_zone' ? (int) $zoneKey : null,
                'zone_name' => $zoneName,
                'orders' => array_values($zoneOrders),
                'eligible_sellers' => $eligibleSellersList,
            ];
        }

        return response()->json([
            'status' => 1,
            'data' => [
                'orders' => $orders,
                'zone_groups' => $zoneGroups,
            ]
        ]);
    }

    /**
     * Assign sellers to multiple pre-orders for a specific store
     */
    public function assignSellers(Request $request)
    {
        $request->validate([
            'order_ids' => 'required|array',
            'order_ids.*' => 'required|integer',
            'seller_id' => 'required|integer',
            'store_id' => 'required|integer'
        ]);

        $orderIds = $request->order_ids;
        $sellerId = $request->seller_id;
        $storeId = $request->store_id;

        try {
            $assignedCount = 0;

            foreach ($orderIds as $orderId) {
                // Generate 4-digit OTP
                $otp = str_pad(rand(0, 9999), 4, '0', STR_PAD_LEFT);

                // Check if tracking record already exists
                $existingTracking = DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->where('store_id', $storeId)
                    ->first();

                if ($existingTracking) {
                    // Update existing tracking record
                    DB::table('order_seller_status_tracking')
                        ->where('order_id', $orderId)
                        ->where('store_id', $storeId)
                        ->update([
                            'seller_id' => $sellerId,
                            'status' => 'assigned_to_seller',
                            'otp' => $otp,
                            'updated_at' => now()
                        ]);
                } else {
                    // Create new tracking record
                    DB::table('order_seller_status_tracking')->insert([
                        'order_id' => $orderId,
                        'store_id' => $storeId,
                        'seller_id' => $sellerId,
                        'status' => 'assigned_to_seller',
                        'otp' => $otp,
                        'created_at' => now(),
                        'updated_at' => now()
                    ]);
                }

                $assignedCount++;
            }

            \Log::info('Sellers assigned to pre-orders', [
                'order_ids' => $orderIds,
                'seller_id' => $sellerId,
                'store_id' => $storeId,
                'count' => $assignedCount
            ]);

            return response()->json([
                'status' => 1,
                'message' => "Successfully assigned seller to {$assignedCount} order(s)"
            ]);

        } catch (\Exception $e) {
            \Log::error('Error assigning sellers to pre-orders', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to assign sellers: ' . $e->getMessage()
            ], 500);
        }
    }
}