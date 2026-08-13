<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Jobs\ProcessReferralBonusAfterReturnPeriod;
use App\Jobs\RetryDeliveryBoyAssignmentJob;
use App\Jobs\SendEmailJob;
use App\Models\Admin;
use App\Models\DeliveryBoy;
use App\Models\FundTransfer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatus;
use App\Models\OrderStatusList;
use App\Models\PaytmTransaction;
use App\Models\Role;
use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use App\Models\Setting;
use App\Models\Store;
use App\Models\Transaction;
use App\Models\User;
use App\Models\DeliveryBoyTransaction;
use App\Models\ProductVariant;
use App\Models\OrderDeliveryBoyNotification;
use App\Models\PendingDeliveryAssignment;
use App\Services\CityZoneService;
use App\Services\StoreDistanceService;
use App\Services\FirestoreDeliveryBoyService;
use App\Services\HandCashLimitService;
use App\Services\DeliveryBoyOrderService;
use App\Services\FirestoreOrderSellerTrackingService;
use App\Services\DriverNotificationService;
use App\Services\PhonePeRefundService;
use App\Services\FirestoreOrderETAService;
use App\Services\ProductOrderPolicyService;
use App\Services\OrderStoreSegregationService;
use App\Services\SellerNotificationService;
use App\Services\SellerOrderSettlementService;
use App\Notifications\OrderNotification;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class OrdersApiController extends Controller
{
    public function getOrderStatusCounts()
    {
        $statusCounts = Order::select('active_status', DB::raw('COUNT(*) as count'))
            ->where('order_type', 'doorstep')
            ->whereNotIn('active_status', [1, 12]) // Exclude Payment Pending (1) and Preorder Pending (12)
            ->groupBy('active_status')
            ->get()
            ->pluck('count', 'active_status')
            ->toArray();

        $totalCount = Order::where('order_type', 'doorstep')
            ->whereNotIn('active_status', [1, 12]) // Exclude Payment Pending (1) and Preorder Pending (12)
            ->count();

        $data = [
            'all' => $totalCount,
            'received' => $statusCounts[2] ?? 0,
            'processed' => $statusCounts[3] ?? 0,
            'shipped' => $statusCounts[4] ?? 0,
            'out_for_delivery' => $statusCounts[5] ?? 0,
            'delivered' => $statusCounts[6] ?? 0,
            'cancelled' => $statusCounts[7] ?? 0,
            'returned' => $statusCounts[8] ?? 0,
        ];

        return CommonHelper::responseWithData($data);
    }

    public function getOrders(Request $request){
        $limit = $request->input('per_page', 10);
        $offset = (($request->input('page', 0))-1)*$limit;
        $search = $request->input('search', '');

        // Debug logging
        Log::info('getOrders - Request params:', [
            'status' => $request->input('status'),
            'page' => $request->input('page'),
            'per_page' => $request->input('per_page'),
        ]);

        $sellers = Seller::where('status',1)->orderBy('id','DESC')->get()->toArray();

        $startDate = Carbon::parse($request->input('startDate'))->startOfDay();
        $endDate = Carbon::parse($request->input('endDate'))->endOfDay();

        $startDeliveryDate = Carbon::parse($request->input('startDeliveryDate'))->startOfDay();
        $endDeliveryDate = Carbon::parse($request->input('endDeliveryDate'))->endOfDay();

        $orders = Order::select(
            'orders.id',
            'orders.orders_id',
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
            'orders.created_at',
            'orders.total_vendor_wait_charge',
            DB::raw('TIMESTAMPDIFF(MINUTE, orders.created_at, NOW()) as minutes_from_now'),
            'sellers.name as seller_name',
            'users.name as user_name',
            'delivery_boys.name as delivery_boy_name'
        )
        ->leftJoin('users', 'orders.user_id', '=', 'users.id')
        ->leftJoin('order_items', 'orders.id', '=', 'order_items.order_id')
        ->leftJoin('sellers', 'order_items.seller_id', '=', 'sellers.id')
        ->leftJoin('delivery_boys', 'orders.delivery_boy_id', '=', 'delivery_boys.id')
        ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
        ->where('orders.order_type', 'doorstep')
        ->whereNotIn('orders.active_status', [1, 12]); // Exclude Payment Pending (1) and Preorder Pending (12)

        if(isset($request->startDate) && $request->startDate != "" && isset($request->endDate) && $request->endDate != ""){
            $orders = $orders->whereBetween('order_items.created_at', [$startDate, $endDate]);
        }

        if(isset($request->startDeliveryDate) && $request->startDeliveryDate != "" && isset($request->endDeliveryDate) && $request->endDeliveryDate != ""){
            // Convert start and end dates from request to Y-m-d format
            $startDeliveryDate = date('Y-m-d', strtotime($request->startDeliveryDate));
            $endDeliveryDate = date('Y-m-d', strtotime($request->endDeliveryDate));

            // Define a callback function to extract and format the delivery_time date
            $orders = $orders->where(function($query) use ($startDeliveryDate, $endDeliveryDate) {
                $query->whereRaw("STR_TO_DATE(SUBSTRING_INDEX(orders.delivery_time, ' ', 1), '%d-%m-%Y') BETWEEN ? AND ?", [$startDeliveryDate, $endDeliveryDate]);
            });
        }

        // Filter by Seller ID using order_seller_status_tracking table
        if(isset($request->seller) && $request->seller != ""){
            $orders = $orders->whereIn('orders.id', function($query) use ($request) {
                $query->select('order_id')
                    ->from('order_seller_status_tracking')
                    ->where('seller_id', $request->seller);
            });
        }
        if(isset($request->status) && $request->status != ""){
            Log::info('getOrders - Applying status filter:', ['status' => $request->status]);
            $orders = $orders->where('orders.active_status', $request->status);
        }

        // Filter by User ID
        if(isset($request->user_id) && $request->user_id != ""){
            $orders = $orders->where('orders.user_id', $request->user_id);
        }

        if ($search) {
            $columns = [
                'orders.payment_method', 'orders.id','orders.orders_id','orders.delivery_charge','orders.wallet_balance', 'orders.remaining_final','orders.total','orders.delivery_time','sellers.name',
                'users.name', 'order_items.active_status'
            ];

            // "ZF-0451" should find order 451 even on rows the backfill has not
            // reached yet, so match the id the prefix resolves to as well.
            $searchedOrderId = CommonHelper::parseOrderNumber($search);

            $orders = $orders->where(function($query) use ($search, $columns, $searchedOrderId) {
                foreach ($columns as $column) {
                    $query->orWhere($column, 'like', "%{$search}%");
                }
                if ($searchedOrderId !== null) {
                    $query->orWhere('orders.id', $searchedOrderId);
                }
            });
        }

        // Filter by Store ID using order_seller_status_tracking table
        if ($request->has('store_id') && $request->store_id != "") {
            $storeId = $request->store_id;

            $orders = $orders->whereIn('orders.id', function($query) use ($storeId) {
                $query->select('order_id')
                    ->from('order_seller_status_tracking')
                    ->where('store_id', $storeId);
            });
        }

        // Filter by City ID via user_addresses
        if ($request->has('city_id') && $request->city_id != "") {
            $orders = $orders->where('user_addresses.city_id', $request->city_id);
        }

        $orders = $orders->orderBy('orders.id', 'DESC')->groupBy('orders.id');

        // Log the SQL query for debugging
        Log::info('getOrders - SQL Query:', ['sql' => $orders->toSql(), 'bindings' => $orders->getBindings()]);

        $orders_total = $orders->get()->count();
        $orders = $orders->skip($offset)->take($limit)->get();

        // Log the returned orders with their active_status
        Log::info('getOrders - Results:', [
            'total' => $orders_total,
            'returned_count' => $orders->count(),
            'order_statuses' => $orders->pluck('active_status', 'id')->toArray()
        ]);

        foreach ($orders as $order) {
            if (!empty($order->additional_charges)) {
                if (is_string($order->additional_charges)) {
                    $decoded = json_decode($order->additional_charges, true);
                    $order->additional_charges = (is_array($decoded)) ? $decoded : [];
                }else {
                    $order->additional_charges = [];
                }
            } else {
                $order->additional_charges = [];
            }

            // Get prep_time from order_seller_status_tracking
            $prepTimes = DB::table('order_seller_status_tracking')
                ->where('order_id', $order->id)
                ->whereNotNull('prep_time')
                ->pluck('prep_time');

            // Calculate total preparation time (max of all sellers + buffer)
            $maxPrepMinutes = 0;
            $latestPrepTime = null;

            foreach ($prepTimes as $prepTimeJson) {
                $prepTimeData = json_decode($prepTimeJson, true);
                if ($prepTimeData && isset($prepTimeData[0])) {
                    $minutes = (int) $prepTimeData[0];
                    if ($minutes > $maxPrepMinutes) {
                        $maxPrepMinutes = $minutes;
                        $latestPrepTime = $prepTimeData[1] ?? null;
                    }
                }
            }

            // Add buffer of 5-10 minutes (using 7 as average)
            if ($maxPrepMinutes > 0) {
                $totalMinutes = $maxPrepMinutes + 7;
                $order->prep_time = [
                    $totalMinutes,
                    $latestPrepTime
                ];
            } else {
                $order->prep_time = null;
            }

            // Per-seller waiting charge — when listing a specific seller's
            // orders (Seller View → Orders tab) we show what THIS seller
            // had deducted, not the order's grand total.
            if (!empty($request->seller)) {
                $order->vendor_wait_charge = (float) (DB::table('order_seller_status_tracking')
                    ->where('order_id', $order->id)
                    ->where('seller_id', $request->seller)
                    ->value('vendor_wait_charge') ?? 0);
            } else {
                $order->vendor_wait_charge = (float) ($order->total_vendor_wait_charge ?? 0);
            }
        }

        $item_limit = $request->input('item_per_page', 10);
        $item_offset = (($request->input('item_page', 0))-1)*$item_limit;
        $data = array(
            "sellers" => $sellers,
            "orders" => $orders,
            "orders_total" => $orders_total
        );
        return CommonHelper::responseWithData($data);
    }

    public function getSelfPickupOrders(Request $request){
        $limit = $request->input('per_page', 10);
        $offset = (($request->input('page', 0))-1)*$limit;
        $search = $request->input('search', '');

        $sellers = Seller::where('status',1)->orderBy('id','DESC')->get()->toArray();

        $startDate = Carbon::parse($request->input('startDate'))->startOfDay();
        $endDate = Carbon::parse($request->input('endDate'))->endOfDay();

        $startDeliveryDate = Carbon::parse($request->input('startDeliveryDate'))->startOfDay();
        $endDeliveryDate = Carbon::parse($request->input('endDeliveryDate'))->endOfDay();

        $orders = Order::select(
            'orders.id',
            'orders.orders_id',
            'orders.mobile',
            'orders.total',
            'orders.delivery_charge',
            'orders.wallet_balance',
            'orders.final_total',
            'orders.remaining_final',
            'orders.payment_method',
            'orders.delivery_time',
            'orders.additional_charges',
            'orders.active_status',
            'sellers.name as seller_name',
            'users.name as user_name'
        )
        ->leftJoin('users', 'orders.user_id', '=', 'users.id')
        ->leftJoin('order_items', 'orders.id', '=', 'order_items.order_id')
        ->leftJoin('sellers', 'order_items.seller_id', '=', 'sellers.id')
        ->where('orders.order_type', 'selfpickup');

        if(isset($request->startDate) && $request->startDate != "" && isset($request->endDate) && $request->endDate != ""){
            $orders = $orders->whereBetween('order_items.created_at', [$startDate, $endDate]);
        }

        if(isset($request->startDeliveryDate) && $request->startDeliveryDate != "" && isset($request->endDeliveryDate) && $request->endDeliveryDate != ""){
            // Convert start and end dates from request to Y-m-d format
            $startDeliveryDate = date('Y-m-d', strtotime($request->startDeliveryDate));
            $endDeliveryDate = date('Y-m-d', strtotime($request->endDeliveryDate));

            // Define a callback function to extract and format the delivery_time date
            $orders = $orders->where(function($query) use ($startDeliveryDate, $endDeliveryDate) {
                $query->whereRaw("STR_TO_DATE(SUBSTRING_INDEX(orders.delivery_time, ' ', 1), '%d-%m-%Y') BETWEEN ? AND ?", [$startDeliveryDate, $endDeliveryDate]);
            });
        }

        if(isset($request->seller) && $request->seller != ""){
            $orders = $orders->where('order_items.seller_id', $request->seller);
        }
        if(isset($request->status) && $request->status != ""){
            $orders = $orders->where('orders.active_status', $request->status);
        }

        if ($search) {
            $columns = [
                'orders.payment_method', 'orders.id','orders.orders_id','orders.delivery_charge','orders.wallet_balance', 'orders.remaining_final','orders.total','orders.delivery_time','sellers.name',
                'users.name', 'order_items.active_status'
            ];

            // "ZF-0451" should find order 451 even on rows the backfill has not
            // reached yet, so match the id the prefix resolves to as well.
            $searchedOrderId = CommonHelper::parseOrderNumber($search);

            $orders = $orders->where(function($query) use ($search, $columns, $searchedOrderId) {
                foreach ($columns as $column) {
                    $query->orWhere($column, 'like', "%{$search}%");
                }
                if ($searchedOrderId !== null) {
                    $query->orWhere('orders.id', $searchedOrderId);
                }
            });
        }
        $orders = $orders->orderBy('orders.id', 'DESC')->groupBy('orders.id');

        $orders_total = $orders->get()->count();
        $orders = $orders->skip($offset)->take($limit)->get();

        foreach ($orders as $order) {
            if (!empty($order->additional_charges)) {
                if (is_string($order->additional_charges)) {
                    $decoded = json_decode($order->additional_charges, true);
                    $order->additional_charges = (is_array($decoded)) ? $decoded : [];
                }else {
                    $order->additional_charges = [];
                }
            } else {
                $order->additional_charges = [];
            }

            // Get prep_time from order_seller_status_tracking
            $prepTimes = DB::table('order_seller_status_tracking')
                ->where('order_id', $order->id)
                ->whereNotNull('prep_time')
                ->pluck('prep_time');

            // Calculate total preparation time (max of all sellers + buffer)
            $maxPrepMinutes = 0;
            $latestPrepTime = null;

            foreach ($prepTimes as $prepTimeJson) {
                $prepTimeData = json_decode($prepTimeJson, true);
                if ($prepTimeData && isset($prepTimeData[0])) {
                    $minutes = (int) $prepTimeData[0];
                    if ($minutes > $maxPrepMinutes) {
                        $maxPrepMinutes = $minutes;
                        $latestPrepTime = $prepTimeData[1] ?? null;
                    }
                }
            }

            // Add buffer of 5-10 minutes (using 7 as average)
            if ($maxPrepMinutes > 0) {
                $totalMinutes = $maxPrepMinutes + 7;
                $order->prep_time = [
                    $totalMinutes,
                    $latestPrepTime
                ];
            } else {
                $order->prep_time = null;
            }
        }

        $item_limit = $request->input('item_per_page', 10); // Default items per page
        $item_offset = (($request->input('item_page', 0))-1)*$item_limit; // Default page
        $data = array(
            "sellers" => $sellers,
            "orders" => $orders,
            "orders_total" => $orders_total
        );
        return CommonHelper::responseWithData($data);
    }

    // public function view($id){
    //     $data = CommonHelper::getOrderDetails($id);
    //     if(!$data["order"]){
    //         return CommonHelper::responseError("Order Not found!");
    //     }

    //     if($data["order"]->order_type == 'selfpickup') {
    //         $pickupStatus = OrderStatus::where('order_id', $id)
    //             ->where('status', OrderStatusList::$selfPickupPicked)
    //             ->orderBy('created_at', 'desc')
    //             ->first();
            
    //         $data["pickup_date"] = $pickupStatus ? $pickupStatus->created_at : null;
    //     }

    //     $deliveryBoys = DeliveryBoy::select('id','name')->where('city_id',$data["order"]->city_id)->where('status',1)->get();

    //     $data["deliveryBoys"] = $deliveryBoys;


    //     /*-----------------------------------------
    //     | 🆕 STORE SEGREGATION LOGIC (13 & 14)
    //     ------------------------------------------*/

    //     $variantIds = collect($data["order_items"])
    //         ->pluck('product_variant_id')
    //         ->toArray();

    //     // dd($variantIds);


    //     $data["is_sellers_stores"] = 0;
    //     $data["eligible_sellers"] = [];

    //     if (!empty($variantIds)) {

    //         $productIds = DB::table('product_variants')
    //             ->whereIn('id', $variantIds)
    //             ->pluck('product_id')
    //             ->toArray();

    //             // dd($productIds);


    //         if (!empty($productIds)) {

    //             // 3. Store IDs
    //             $storeIds = DB::table('products')
    //                 ->whereIn('id', $productIds)
    //                 ->pluck('store_id')
    //                 ->unique()
    //                 ->toArray();

    //             // dd($storeIds);

    //             // 4. Filter target stores
    //             $filteredStoreIds = array_intersect($storeIds, [13, 14]);

    //             if (!empty($filteredStoreIds)) {

    //                 $data["is_sellers_stores"] = 1;

    //                 // 5. Fetch eligible sellers
    //                 $sellers = DB::table('sellers')
    //                     ->whereIn('store_id', $filteredStoreIds)
    //                     ->select('id', 'store_name')
    //                     ->get();

    //                 $formatted = [];
    //                 foreach ($sellers as $seller) {
    //                     $formatted[] = [
    //                         'seller_id'  => $seller->id,
    //                         'store_name' => $seller->store_name
    //                     ];
    //                 }

    //                 $data["eligible_sellers"] = $formatted;
    //             }
    //         }
    //     }

    //     return CommonHelper::responseWithData($data);
    // }

    public function view($id)
    {
        $data = CommonHelper::getOrderDetails($id);

        if (!$data["order"]) {
            return CommonHelper::responseError("Order Not found!");
        }

        // Fetch customer data using user_id from the order
        $customer = User::select('id', 'name', 'email', 'mobile', 'profile', 'balance', 'referral_code', 'friends_code', 'status', 'created_at')
            ->where('id', $data["order"]->user_id)
            ->first();

        $data["customer"] = $customer;

        if ($data["order"]->order_type == 'selfpickup') {
            $pickupStatus = OrderStatus::where('order_id', $id)
                ->where('status', OrderStatusList::$selfPickupPicked)
                ->orderBy('created_at', 'desc')
                ->first();

            $data["pickup_date"] = $pickupStatus ? $pickupStatus->created_at : null;
        }

        // ========================================
        // DELIVERY BOY DROPDOWN - FILTERING PIPELINE
        // ========================================
        $cityId = $data["order"]->city_id;

        // Log::info('DeliveryBoy Dropdown | START', [
        //     'order_id' => $id,
        //     'city_id' => $cityId,
        //     'city_id_type' => gettype($cityId),
        // ]);

        // STEP 1: Get store IDs linked to this order
        $orderStoreIds = DB::table('order_seller_status_tracking')
            ->where('order_id', $id)
            ->pluck('store_id')
            ->unique()
            ->toArray();

        // STEP 2: Check if any store is managed by admin
        $hasAdminManagedStore = false;
        $adminManagedStoreIds = [];

        if (!empty($orderStoreIds)) {
            $adminManagedStoreIds = DB::table('stores')
                ->whereIn('id', $orderStoreIds)
                ->where('managed_by_admin', 1)
                ->pluck('id')
                ->toArray();

            $hasAdminManagedStore = !empty($adminManagedStoreIds);
        }

        // Log::info('DeliveryBoy Dropdown | Step 1-2: Store check', [
        //     'order_id' => $id,
        //     'order_store_ids' => $orderStoreIds,
        //     'admin_managed_store_ids' => $adminManagedStoreIds,
        //     'has_admin_managed_store' => $hasAdminManagedStore,
        // ]);

        // STEP 3: Get ALL delivery boys in this city (baseline count)
        $allCityDrivers = DB::table('delivery_boys')
            ->where('city_id', $cityId)
            ->select('id', 'name', 'status', 'is_available', 'orders_priority')
            ->get();

        // Log::info('DeliveryBoy Dropdown | Step 3: All drivers in city', [
        //     'order_id' => $id,
        //     'total_in_city' => $allCityDrivers->count(),
        //     'drivers' => $allCityDrivers->map(fn($b) => [
        //         'id' => $b->id,
        //         'name' => $b->name,
        //         'status' => $b->status,
        //         'is_available' => $b->is_available,
        //         'orders_priority' => $b->orders_priority,
        //     ])->toArray(),
        // ]);

        // STEP 4: Filter by active session
        $driverIdsWithActiveSession = DB::table('delivery_boy_sessions')
            ->whereNull('logout_at')
            ->pluck('delivery_boy_id')
            ->unique()
            ->toArray();

        $afterSessionFilter = $allCityDrivers->filter(function ($boy) use ($driverIdsWithActiveSession) {
            return in_array($boy->id, $driverIdsWithActiveSession);
        })->values();

        $removedAtSession = $allCityDrivers->filter(function ($boy) use ($driverIdsWithActiveSession) {
            return !in_array($boy->id, $driverIdsWithActiveSession);
        })->pluck('name', 'id')->toArray();

        // Log::info('DeliveryBoy Dropdown | Step 4: Active session filter', [
        //     'order_id' => $id,
        //     'passed' => $afterSessionFilter->count(),
        //     'removed' => $removedAtSession,
        // ]);

        // STEP 5: Filter by status=1 and is_available=1
        $afterAvailabilityFilter = $afterSessionFilter->filter(function ($boy) {
            return $boy->status == 1 && $boy->is_available == 1;
        })->values();

        $removedAtAvailability = $afterSessionFilter->filter(function ($boy) {
            return !($boy->status == 1 && $boy->is_available == 1);
        })->map(fn($b) => [
            'id' => $b->id,
            'name' => $b->name,
            'status' => $b->status,
            'is_available' => $b->is_available,
        ])->toArray();

        // Log::info('DeliveryBoy Dropdown | Step 5: Status & availability filter', [
        //     'order_id' => $id,
        //     'passed' => $afterAvailabilityFilter->count(),
        //     'removed' => $removedAtAvailability,
        // ]);

        // STEP 6: Filter by orders_priority
        // 0 = Both (default), 1 = Grocery / admin-managed only, 2 = Multi-orders (both).
        // Only priority 1 is restricted, and only when the order contains items from a
        // store that is NOT managed by admin. Mirrors FirestoreDeliveryBoyService so the
        // manual dropdown and the auto-dispatch funnel agree.
        $hasNonAdminManagedItems = OrderStoreSegregationService::orderHasNonAdminManagedItems($id);

        $afterPriorityFilter = $afterAvailabilityFilter->filter(function ($boy) use ($hasNonAdminManagedItems) {
            return !($boy->orders_priority == 1 && $hasNonAdminManagedItems);
        })->values();

        $removedAtPriority = $afterAvailabilityFilter->filter(function ($boy) use ($hasNonAdminManagedItems) {
            return $boy->orders_priority == 1 && $hasNonAdminManagedItems;
        })->map(fn($b) => [
            'id' => $b->id,
            'name' => $b->name,
            'orders_priority' => $b->orders_priority,
        ])->toArray();

        // Log::info('DeliveryBoy Dropdown | Step 6: Priority filter', [
        //     'order_id' => $id,
        //     'has_admin_managed_store' => $hasAdminManagedStore,
        //     'passed' => $afterPriorityFilter->count(),
        //     'removed' => $removedAtPriority,
        // ]);

        // STEP 7: Gig booking filter — DISABLED.
        // A driver can receive orders without a gig booking (same decision already applied
        // in FirestoreDeliveryBoyService). Keeping it here made the admin dropdown empty
        // whenever nobody had booked a slot for the current 15-minute window.
        $afterGigFilter = $afterPriorityFilter;
        $removedAtGig   = [];

        /*
        $gigCurrentDate         = now()->toDateString();
        $gigCurrentTime         = now()->toTimeString();
        $gigFifteenMinutesLater = now()->addMinutes(15)->toTimeString();

        $driverIdsWithActiveGig = DB::table('delivery_boy_gig_bookings as bookings')
            ->join('gig_slots as slots', 'bookings.gig_slot_id', '=', 'slots.id')
            ->whereIn('bookings.booking_status', ['booked', 'active'])
            ->where('slots.slot_date', $gigCurrentDate)
            ->where(function ($query) use ($gigCurrentTime, $gigFifteenMinutesLater) {
                // Currently inside gig window
                $query->where(function ($q) use ($gigCurrentTime) {
                    $q->where('slots.start_time', '<=', $gigCurrentTime)
                      ->where('slots.end_time', '>=', $gigCurrentTime);
                })
                // OR gig starts within the next 15 minutes
                ->orWhere(function ($q) use ($gigCurrentTime, $gigFifteenMinutesLater) {
                    $q->where('slots.start_time', '>', $gigCurrentTime)
                      ->where('slots.start_time', '<=', $gigFifteenMinutesLater);
                });
            })
            ->pluck('bookings.delivery_boy_id')
            ->unique()
            ->toArray();

        $afterGigFilter = $afterPriorityFilter->filter(function ($boy) use ($driverIdsWithActiveGig) {
            return in_array($boy->id, $driverIdsWithActiveGig);
        })->values();

        $removedAtGig = $afterPriorityFilter->filter(function ($boy) use ($driverIdsWithActiveGig) {
            return !in_array($boy->id, $driverIdsWithActiveGig);
        })->pluck('name', 'id')->toArray();
        */

        // Log::info('DeliveryBoy Dropdown | Step 7: Gig booking filter', [
        //     'order_id'        => $id,
        //     'gig_date'        => $gigCurrentDate,
        //     'gig_time'        => $gigCurrentTime,
        //     'drivers_with_gig' => $driverIdsWithActiveGig,
        //     'passed'          => $afterGigFilter->count(),
        //     'removed'         => $removedAtGig,
        // ]);

        // STEP 8: Filter out drivers with ongoing orders
        $completedStatuses = [6, 7, 8];

        $afterOngoingFilter = $afterGigFilter->filter(function ($boy) use ($completedStatuses) {
            return !DB::table('orders')
                ->where('delivery_boy_id', $boy->id)
                ->whereNotIn('active_status', $completedStatuses)
                ->exists();
        })->values();

        $removedAtOngoing = $afterGigFilter->filter(function ($boy) use ($completedStatuses) {
            return DB::table('orders')
                ->where('delivery_boy_id', $boy->id)
                ->whereNotIn('active_status', $completedStatuses)
                ->exists();
        })->map(function ($boy) use ($completedStatuses) {
            $activeCount = DB::table('orders')
                ->where('delivery_boy_id', $boy->id)
                ->whereNotIn('active_status', $completedStatuses)
                ->count();
            return ['id' => $boy->id, 'name' => $boy->name, 'active_orders' => $activeCount];
        })->toArray();

        // Log::info('DeliveryBoy Dropdown | Step 8: Ongoing orders filter', [
        //     'order_id' => $id,
        //     'passed' => $afterOngoingFilter->count(),
        //     'removed' => $removedAtOngoing,
        // ]);

        // STEP 9: Filter by 10km radius using delivery_boy_location_history
        $orderLat = !empty($data["order"]->latitude)  ? (float) $data["order"]->latitude  : null;
        $orderLon = !empty($data["order"]->longitude) ? (float) $data["order"]->longitude : null;

        // Log::info('DeliveryBoy Dropdown | Step 9: 10km radius filter | START', [
        //     'order_id'  => $id,
        //     'order_lat' => $orderLat,
        //     'order_lon' => $orderLon,
        //     'drivers_before_radius_filter' => $afterOngoingFilter->count(),
        //     'driver_ids_before' => $afterOngoingFilter->pluck('id')->toArray(),
        // ]);

        if ($orderLat && $orderLon) {
            // Get the latest location for each remaining delivery boy
            $driverIds = $afterOngoingFilter->pluck('id')->toArray();

            $latestLocations = DB::table('delivery_boy_location_history')
                ->whereIn('delivery_boy_id', $driverIds)
                ->select('delivery_boy_id', 'latitude', 'longitude', 'tracked_at')
                ->orderBy('tracked_at', 'desc')
                ->get()
                ->unique('delivery_boy_id')  // Keep only the latest record per driver
                ->keyBy('delivery_boy_id');

            // Log::info('DeliveryBoy Dropdown | Step 9: Location history fetched', [
            //     'order_id'              => $id,
            //     'drivers_with_location' => $latestLocations->count(),
            //     'drivers_without_location' => count($driverIds) - $latestLocations->count(),
            //     'locations' => $latestLocations->map(fn($loc) => [
            //         'delivery_boy_id' => $loc->delivery_boy_id,
            //         'lat'             => $loc->latitude,
            //         'lon'             => $loc->longitude,
            //         'tracked_at'      => $loc->tracked_at,
            //     ])->values()->toArray(),
            // ]);

            $removedAtRadius  = [];
            $passedAtRadius   = [];
            $noLocationBoys   = [];

            $afterRadiusFilter = $afterOngoingFilter->filter(function ($boy) use (
                $latestLocations, $orderLat, $orderLon, &$removedAtRadius, &$passedAtRadius, &$noLocationBoys
            ) {
                if (!isset($latestLocations[$boy->id])) {
                    // No location history — include with a note (can't verify distance)
                    $noLocationBoys[] = ['id' => $boy->id, 'name' => $boy->name];
                    return true;
                }

                $loc      = $latestLocations[$boy->id];
                $driverLat = (float) $loc->latitude;
                $driverLon = (float) $loc->longitude;

                $distanceKm = StoreDistanceService::haversine($orderLat, $orderLon, $driverLat, $driverLon);

                if ($distanceKm <= 10) {
                    $passedAtRadius[] = [
                        'id'          => $boy->id,
                        'name'        => $boy->name,
                        'distance_km' => round($distanceKm, 2),
                        'tracked_at'  => $loc->tracked_at,
                    ];
                    return true;
                } else {
                    $removedAtRadius[] = [
                        'id'          => $boy->id,
                        'name'        => $boy->name,
                        'distance_km' => round($distanceKm, 2),
                        'tracked_at'  => $loc->tracked_at,
                    ];
                    return false;
                }
            })->values();

            // Log::info('DeliveryBoy Dropdown | Step 9: 10km radius filter | RESULT', [
            //     'order_id'              => $id,
            //     'passed_count'          => $afterRadiusFilter->count(),
            //     'passed'                => $passedAtRadius,
            //     'removed_count'         => count($removedAtRadius),
            //     'removed'               => $removedAtRadius,
            //     'no_location_included'  => $noLocationBoys,
            // ]);
        } else {
            // No order lat/lon — skip radius filter
            $afterRadiusFilter = $afterOngoingFilter;

            // Log::warning('DeliveryBoy Dropdown | Step 9: 10km radius filter | SKIPPED', [
            //     'order_id' => $id,
            //     'reason'   => 'Order has no latitude/longitude',
            // ]);
        }

        // FINAL: Prepare result
        $deliveryBoys = $afterRadiusFilter->map(fn($boy) => (object)[
            'id' => $boy->id,
            'name' => $boy->name,
        ]);

        // Log::info('DeliveryBoy Dropdown | FINAL', [
        //     'order_id' => $id,
        //     'total_eligible' => $deliveryBoys->count(),
        //     'driver_ids' => $deliveryBoys->pluck('id')->toArray(),
        // ]);

        $data["deliveryBoys"] = $deliveryBoys;

        // Get existing seller assignments from order_seller_status_tracking table (keyed by store_id)
        $existingSellerAssignments = DB::table('order_seller_status_tracking')
            ->where('order_id', $id)
            ->get()
            ->keyBy('store_id');

        // Get seller details for existing assignments
        $assignedSellerIds = $existingSellerAssignments->pluck('seller_id')->unique()->toArray();
        $assignedSellersInfo = [];
        if (!empty($assignedSellerIds)) {
            $assignedSellersInfo = DB::table('sellers')
                ->whereIn('id', $assignedSellerIds)
                ->select('id', 'store_id', 'store_name', 'name', 'mobile', 'email')
                ->get()
                ->keyBy('id')
                ->toArray();
        }

        // Build a map of store_id => assigned_seller from tracking table
        $storeAssignedSellerMap = [];
        foreach ($existingSellerAssignments as $storeId => $tracking) {
            $sellerInfo = $assignedSellersInfo[$tracking->seller_id] ?? null;
            if ($sellerInfo) {
                $storeAssignedSellerMap[$storeId] = [
                    'seller_id' => $tracking->seller_id,
                    'seller_name' => $sellerInfo->name,
                    'store_name' => $sellerInfo->store_name,
                    'mobile' => $sellerInfo->mobile,
                    'email' => $sellerInfo->email,
                    'status' => $tracking->status ?? 'assigned_to_seller'
                ];
            }
        }

        // For cancelled orders, the tracking rows are deleted and moved to cancelled_order_seller_tracking.
        // Fall back to that archive table so we still show the correct originally-assigned seller.
        if ($data["order"]->active_status == 7 && empty($storeAssignedSellerMap)) {
            $cancelledAssignments = DB::table('cancelled_order_seller_tracking')
                ->where('order_id', $id)
                ->whereNotNull('seller_id')
                ->get()
                ->keyBy('store_id');

            $cancelledSellerIds = $cancelledAssignments->pluck('seller_id')->unique()->filter()->toArray();
            if (!empty($cancelledSellerIds)) {
                $cancelledSellersInfo = DB::table('sellers')
                    ->whereIn('id', $cancelledSellerIds)
                    ->select('id', 'store_id', 'store_name', 'name', 'mobile', 'email')
                    ->get()
                    ->keyBy('id')
                    ->toArray();

                foreach ($cancelledAssignments as $storeId => $tracking) {
                    $sellerInfo = $cancelledSellersInfo[$tracking->seller_id] ?? null;
                    if ($sellerInfo) {
                        $storeAssignedSellerMap[$storeId] = [
                            'seller_id' => $tracking->seller_id,
                            'seller_name' => $sellerInfo->name,
                            'store_name' => $sellerInfo->store_name,
                            'mobile' => $sellerInfo->mobile,
                            'email' => $sellerInfo->email,
                            'status' => $tracking->status ?? 'assigned_to_seller'
                        ];
                    }
                }
            }
        }

        $orderItems = collect($data["order_items"]);

        $variantIds = $orderItems->pluck('product_variant_id')->toArray();

        $variantProductMap = DB::table('product_variants')
            ->whereIn('id', $variantIds)
            ->pluck('product_id', 'id');

        $productStoreMap = DB::table('products')
            ->whereIn('id', $variantProductMap->values())
            ->pluck('store_id', 'id');

        // Get all unique store IDs from order items
        $allStoreIds = $productStoreMap->values()->unique()->toArray();

        // Fetch combo items from order_combo_items table
        $comboItems = DB::table('order_combo_items')
            ->where('order_id', $id)
            ->get();

        // Collect all unique product_ids from combo items
        $allComboProductIds = [];
        foreach ($comboItems as $combo) {
            if (!empty($combo->products)) {
                $products = json_decode($combo->products, true);
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

        // Get store_ids for combo products
        $comboProductStoreMap = [];
        if (!empty($allComboProductIds)) {
            $comboProductStoreMap = DB::table('products')
                ->whereIn('id', $allComboProductIds)
                ->pluck('store_id', 'id')
                ->toArray();
        }

        // Add combo store IDs to all store IDs
        $comboStoreIds = array_unique(array_values($comboProductStoreMap));
        $allStoreIds = array_unique(array_merge($allStoreIds, $comboStoreIds));

        // Fetch all store names
        $storeNames = DB::table('stores')
            ->whereIn('id', $allStoreIds)
            ->pluck('name', 'id')
            ->toArray();

        // Get all store IDs that support dropdown seller assignment (meat stores only)
        $allMeatStoreIds = DB::table('stores')->where('is_meat', 1)->pluck('id')->toArray();
        $dropdownStoreIds = array_unique($allMeatStoreIds);
        $orderMeatStoreIds = array_values(array_intersect($allStoreIds, $dropdownStoreIds));

        // Fetch eligible sellers for each store in this order that supports dropdown assignment.
        // A seller is eligible for a store if:
        //   - their primary store_id matches, OR
        //   - the store ID appears in their other_store_ids JSON array
        $eligibleSellers = [];
        if (!empty($orderMeatStoreIds)) {

            // -------------------------------------------------------
            // STEP 1: Resolve delivery address & detect customer zone
            // -------------------------------------------------------
            $zoneFilterEnabled = CityZoneService::isZoneFilterEnabled();
            $deliveryCity      = null;
            $deliveryLat       = null;
            $deliveryLon       = null;

            // Log::info('EligibleSellers | Zone filter | START', [
            //     'order_id'            => $id,
            //     'zone_filter_enabled' => $zoneFilterEnabled,
            //     'address_id'          => $data["order"]->address_id ?? null,
            // ]);

            if ($zoneFilterEnabled && !empty($data["order"]->address_id)) {

                $deliveryAddress = DB::table('user_addresses')
                    ->where('id', $data["order"]->address_id)
                    ->select('latitude', 'longitude', 'city_id', 'city')
                    ->first();

                // Log::info('EligibleSellers | Zone filter | Delivery address fetched', [
                //     'order_id'   => $id,
                //     'address_id' => $data["order"]->address_id,
                //     'lat'        => $deliveryAddress->latitude  ?? null,
                //     'lon'        => $deliveryAddress->longitude ?? null,
                //     'city_id'    => $deliveryAddress->city_id   ?? null,
                //     'city_name'  => $deliveryAddress->city      ?? null,
                // ]);

                if ($deliveryAddress && !empty($deliveryAddress->latitude) && !empty($deliveryAddress->longitude)) {
                    $deliveryLat = (float) $deliveryAddress->latitude;
                    $deliveryLon = (float) $deliveryAddress->longitude;

                    // Detect which city polygon this lat/lon falls inside
                    $deliveryCity = CityZoneService::detectCity($deliveryLat, $deliveryLon);

                    // Log::info('EligibleSellers | Zone filter | City detection result', [
                    //     'order_id'  => $id,
                    //     'lat'       => $deliveryLat,
                    //     'lon'       => $deliveryLon,
                    //     'city_id'   => $deliveryCity->id   ?? null,
                    //     'city_name' => $deliveryCity->name ?? 'none (outside all zones)',
                    // ]);
                } else {
                    // Log::warning('EligibleSellers | Zone filter | Address has no lat/lon — zone filter skipped', [
                    //     'order_id'   => $id,
                    //     'address_id' => $data["order"]->address_id,
                    // ]);
                }
            } else {
                // Log::info('EligibleSellers | Zone filter | Skipping zone resolution', [
                //     'order_id'            => $id,
                //     'reason'              => !$zoneFilterEnabled ? 'zone_filter_disabled_in_settings' : 'no_address_id_on_order',
                // ]);
            }

            // -------------------------------------------------------
            // STEP 2: Fetch sellers filtered by status / shop
            // -------------------------------------------------------
            // Only filter by opening time: if current time is before opening_time, exclude the seller.
            // If the seller is still online (shop_status=1) after closing time, we still show them.
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

            // Log::info('EligibleSellers | Status + Shop + Timing filter result', [
            //     'order_id'      => $id,
            //     'current_time'  => $now,
            //     'sellers_count' => $allSellers->count(),
            //     'seller_ids'    => $allSellers->pluck('id')->toArray(),
            // ]);

            // -------------------------------------------------------
            // STEP 3: Apply zone filter — keep only sellers in the
            //         same city zone as the delivery address
            // -------------------------------------------------------
            if ($zoneFilterEnabled && $deliveryCity && $deliveryLat && $deliveryLon) {

                $allSellerIds = $allSellers->pluck('id')->toArray();

                // Log::info('EligibleSellers | Zone filter | Applying zone filter', [
                //     'order_id'          => $id,
                //     'city_id'           => $deliveryCity->id,
                //     'city_name'         => $deliveryCity->name,
                //     'sellers_before'    => count($allSellerIds),
                //     'seller_ids_before' => $allSellerIds,
                // ]);

                $zoneFilteredIds = CityZoneService::filterSellersByZone(
                    $allSellerIds,
                    $deliveryCity,
                    $deliveryLat,
                    $deliveryLon
                );

                $allSellers = $allSellers->filter(fn($s) => in_array($s->id, $zoneFilteredIds))->values();

                // Log::info('EligibleSellers | Zone filter | Zone filter applied', [
                //     'order_id'         => $id,
                //     'sellers_after'    => $allSellers->count(),
                //     'seller_ids_after' => $allSellers->pluck('id')->toArray(),
                // ]);

            } else {
                // Log::info('EligibleSellers | Zone filter | Zone filter not applied', [
                //     'order_id' => $id,
                //     'reason'   => !$zoneFilterEnabled
                //         ? 'zone_filter_disabled_in_settings'
                //         : (!$deliveryCity ? 'no_city_zone_detected_for_address' : 'missing_lat_lon'),
                // ]);
            }

            foreach ($allSellers as $seller) {
                $primaryStore   = (int) $seller->store_id;
                $otherStoreIds  = [];
                if (!empty($seller->other_store_ids)) {
                    $decoded = json_decode($seller->other_store_ids, true);
                    if (is_array($decoded)) {
                        $otherStoreIds = array_map('intval', $decoded);
                    }
                }
                $sellerStores = array_unique(array_merge([$primaryStore], $otherStoreIds));

                foreach ($orderMeatStoreIds as $meatStoreId) {
                    if (in_array($meatStoreId, $sellerStores)) {
                        $eligibleSellers[$meatStoreId][] = [
                            'seller_id'   => $seller->id,
                            'seller_name' => $seller->name,
                            'store_name'  => $seller->store_name,
                        ];
                    }
                }
            }
        }

        // Fetch seller names for store_id 15 and 17 (display only, no dropdown)
        $fixedSellerStoreIds = array_intersect($allStoreIds, [15, 17]);
        $fixedSellers = [];
        if (!empty($fixedSellerStoreIds)) {
            $sellers = DB::table('sellers')
                ->whereIn('store_id', $fixedSellerStoreIds)
                ->select('id', 'store_id', 'store_name', 'name', 'mobile', 'email')
                ->get();

            foreach ($sellers as $seller) {
                $fixedSellers[$seller->store_id] = [
                    'seller_id'  => $seller->id,
                    'seller_name' => $seller->name,
                    'store_name' => $seller->store_name,
                    'mobile' => $seller->mobile,
                    'email' => $seller->email,
                ];
            }
        }

        // Build store_wise_items
        $storeWiseItems = [];
        foreach ($orderItems as $item) {
            $productId = $variantProductMap[$item->product_variant_id] ?? null;
            $storeId   = $productStoreMap[$productId] ?? 0;

            if (!isset($storeWiseItems[$storeId])) {
                $storeWiseItems[$storeId] = [
                    'store_id'    => $storeId,
                    'store_name'  => $storeNames[$storeId] ?? '',
                    'items'       => []
                ];
            }

            $storeWiseItems[$storeId]['items'][] = $item;
        }

        $data["store_wise_items"] = array_values($storeWiseItems);
        unset($data["order_items"]);

        // Build combo_items with store-wise product grouping
        $formattedComboItems = [];
        foreach ($comboItems as $combo) {
            $comboData = [
                'id' => $combo->id,
                'order_id' => $combo->order_id,
                'combo_id' => $combo->combo_id ?? null,
                'combo_name' => $combo->combo_name ?? '',
                'combo_description' => $combo->combo_description ?? '',
                'combo_price' => $combo->combo_price ?? 0,
                'combo_quantity' => $combo->combo_quantity ?? 1,
                'combo_sub_total' => $combo->combo_sub_total ?? 0,
                'products_count' => $combo->products_count ?? 0,
                'seller_id' => $combo->seller_id ?? null,
                'combo_custom_cart_id' => $combo->combo_custom_cart_id ?? null,
                'sub_total' => $combo->sub_total ?? 0,
                'discount_percentage' => $combo->discount_percentage ?? 0,
                'total_actual_price' => $combo->total_actual_price ?? 0,
                'total_products_price' => $combo->total_products_price ?? 0,
                'products' => [],
                'store_wise_products' => [], // Group products by store
            ];

            if (!empty($combo->products)) {
                $products = json_decode($combo->products, true);
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }
                if (is_array($products)) {
                    $comboData['products'] = $products;

                    // Group products by store
                    $storeWiseComboProducts = [];
                    foreach ($products as $product) {
                        $productId = $product['product_id'] ?? null;
                        $storeId = $comboProductStoreMap[$productId] ?? 0;

                        if (!isset($storeWiseComboProducts[$storeId])) {
                            $storeWiseComboProducts[$storeId] = [
                                'store_id' => $storeId,
                                'store_name' => $storeNames[$storeId] ?? '',
                                'products' => []
                            ];
                        }
                        $storeWiseComboProducts[$storeId]['products'][] = $product;
                    }
                    $comboData['store_wise_products'] = array_values($storeWiseComboProducts);
                }
            }

            $formattedComboItems[] = $comboData;
        }

        $data["combo_items"] = $formattedComboItems;

        // Parse cart_metadata for notes
        $cartMetadata = $data['order']->cart_metadata ?? [];
        $cartInfo = $cartMetadata['cart_info'] ?? null;
        $sellerNotes = $cartInfo['seller_notes'] ?? [];
        $comboNotes = $cartInfo['combo_notes'] ?? [];

        // Fetch store information (managed_by_admin status)
        $storesInfo = DB::table('stores')
            ->whereIn('id', $allStoreIds)
            ->select('id', 'name', 'managed_by_admin')
            ->get()
            ->keyBy('id');

        // Build seller_assignments section for bottom of screen
        // Structure: store_id => { store_name, seller_type, assigned_seller, eligible_sellers }
        $sellerAssignments = [];

        foreach ($allStoreIds as $storeId) {
            if ($storeId == 0) continue; // Skip unknown store

            $assignment = [
                'store_id' => $storeId,
                'store_name' => $storeNames[$storeId] ?? '',
                'seller_type' => 'none', // none, fixed, dropdown
                'assigned_seller' => null,
                'eligible_sellers' => [],
                'show_dropdown' => false,
            ];

            // Store ID 12 & 13: No seller UI
            if (in_array($storeId, [12, 13])) {
                $assignment['seller_type'] = 'none';
            }
            // Store ID 15 & 17: Show seller name only (no dropdown)
            elseif (in_array($storeId, [15, 17])) {
                $assignment['seller_type'] = 'fixed';
                if (isset($fixedSellers[$storeId])) {
                    $assignment['assigned_seller'] = $fixedSellers[$storeId];
                }
                // Check if already assigned in tracking table
                if (isset($storeAssignedSellerMap[$storeId])) {
                    $assignment['assigned_seller'] = $storeAssignedSellerMap[$storeId];
                }
            }
            // Meat stores (is_meat=1): Show dropdown based on primary + other_store_ids
            elseif (in_array($storeId, $allMeatStoreIds)) {
                $assignment['seller_type'] = 'dropdown';
                $assignment['show_dropdown'] = true;
                $assignment['eligible_sellers'] = $eligibleSellers[$storeId] ?? [];

                // Prefill if seller is already assigned in tracking table
                if (isset($storeAssignedSellerMap[$storeId])) {
                    $assignment['assigned_seller'] = $storeAssignedSellerMap[$storeId];
                }
            }

            // --- NOTES LOGIC ---
            $assignment['store_seller_notes'] = [];
            $assignment['store_combo_notes'] = [];

            // 1. Seller Note for assigned seller
            if ($assignment['assigned_seller']) {
                $assignedSellerId = (string)($assignment['assigned_seller']['seller_id'] ?? "");
                if ($assignedSellerId && isset($sellerNotes[$assignedSellerId])) {
                    $assignment['store_seller_notes'][] = $sellerNotes[$assignedSellerId];
                }
            }

            // 2. Note for admin managed stores (key "0")
            if (isset($storesInfo[$storeId]) && $storesInfo[$storeId]->managed_by_admin == 1) {
                if (isset($sellerNotes["0"])) {
                    $assignment['store_seller_notes'][] = $sellerNotes["0"];
                }
            }

            // 3. Combo notes belonging to this store
            foreach ($formattedComboItems as $combo) {
                if (isset($combo['store_wise_products'])) {
                    foreach ($combo['store_wise_products'] as $swp) {
                        if ($swp['store_id'] == $storeId) {
                            $comboItemId = (string)($combo['combo_custom_cart_id'] ?? $combo['id']);
                            if (isset($comboNotes[$comboItemId])) {
                                $assignment['store_combo_notes'][] = [
                                    'combo_name' => $combo['combo_name'],
                                    'note' => $comboNotes[$comboItemId]
                                ];
                            }
                        }
                    }
                }
            }

            $sellerAssignments[] = $assignment;
        }

        $data["seller_assignments"] = $sellerAssignments;

        // Get previous drivers' details if exists
        $previousDriversDetails = [];
        if ($data["order"]->previous_drivers_allocated) {
            try {
                $previousDriverIds = json_decode($data["order"]->previous_drivers_allocated, true);

                if (is_array($previousDriverIds) && !empty($previousDriverIds)) {
                    $previousDrivers = DeliveryBoy::whereIn('id', $previousDriverIds)
                        ->select('id', 'name', 'mobile')
                        ->get()
                        ->keyBy('id');

                    // Maintain order of previous drivers
                    foreach ($previousDriverIds as $driverId) {
                        $driver = $previousDrivers->get($driverId);
                        $previousDriversDetails[] = [
                            'id' => $driverId,
                            'name' => $driver ? $driver->name : 'Driver ID: ' . $driverId,
                            'mobile' => $driver ? $driver->mobile : null
                        ];
                    }
                }
            } catch (\Exception $e) {
                Log::warning('Failed to parse previous_drivers_allocated', [
                    'order_id' => $id,
                    'error' => $e->getMessage()
                ]);
            }
        }

        $data["previous_drivers_details"] = $previousDriversDetails;

        // Fetch Paytm transaction details if transaction_id is set
        if ($data["order"]->transaction_id) {
            $paytmTxn = PaytmTransaction::find($data["order"]->transaction_id);
            if ($paytmTxn) {
                $data["paytm_transaction"] = [
                    'paytm_txn_id' => $paytmTxn->paytm_txn_id,
                    'bank_txn_id' => $paytmTxn->bank_txn_id,
                    'amount' => $paytmTxn->amount,
                    'payment_mode' => $paytmTxn->payment_mode,
                    'status' => $paytmTxn->status,
                    'transaction_date' => $paytmTxn->transaction_date,
                ];
            }
        }

        return CommonHelper::responseWithData($data);
    }

    /**
     * Get detailed invoice information for an order
     * Similar to Zepto/Instamart invoice format
     */
    public function getInvoiceDetails($id)
    {
        $data = CommonHelper::getDetailedInvoiceData($id);
        
        if (!$data) {
            return CommonHelper::responseError("Order not found!");
        }

        // Add admin settlement which is specific to this API call
        $order = $data['order'];
        $data['admin_settlement'] = [
            'order_total' => $order->final_total,
            'delivery_boy_bonus' => $order->delivery_boy_bonus_amount ?? 0,
            'platform_earning' => ($order->final_total ?? 0) - ($order->delivery_boy_bonus_amount ?? 0),
            'payment_method' => $order->payment_method,
            'cash_collected' => $order->payment_method === 'COD' ? $order->remaining_final : 0
        ];

        return CommonHelper::responseWithData($data);
    }

    public function generateOrderInvoice(Request $request){
        $data = CommonHelper::getOrderDetails($request->order_id, true);
        if(!$data["order"]){
            return CommonHelper::responseError("Order Not found!");
        }
        CommonHelper::AdditionalChargesArray($data['order']);
        $invoice = CommonHelper::generateOrderInvoice($data);
        return CommonHelper::responseWithData($invoice);
    }
    public function downloadOrderInvoice(Request $request){
        $data = CommonHelper::getOrderDetails($request->order_id, true);
        if(!$data["order"]){
            return CommonHelper::responseError("Order Not found!");
        }
        CommonHelper::AdditionalChargesArray($data['order']);
        return CommonHelper::downloadOrderInvoice($request->order_id);
    }

    public function delete(Request $request){
        if(isset($request->id)){
            $order = Order::find($request->id);
            if($order){
                $order->delete();
                return CommonHelper::responseSuccess("Order Deleted Successfully!");
            }else{
                return CommonHelper::responseSuccess("Order Already Deleted!");
            }
        }
    }

    public function deleteItem(Request $request){
        if(isset($request->id)){
            $orderItem = OrderItem::find($request->id);
            if($orderItem){
                $orderItem->delete();
                return CommonHelper::responseSuccess("Order Item Deleted Successfully!");
            }else{
                return CommonHelper::responseSuccess("Order Item Already Deleted!");
            }
        }
    }

    public function getWeeklySales(Request $request){
        $period = $request->input('period', 'weekly');
        $curdate = date('Y-m-d');

        // Build query based on period
        $query = Order::select('id', 'cart_metadata', 'active_status', DB::raw('DATE(created_at) AS order_date'))
            ->where(DB::raw('DATE(created_at)'), '<=', $curdate)
            ->whereIn('active_status', [6, 7])
            ->whereNotNull('cart_metadata');

        // Apply date range based on period
        $dateRange = $this->getDateRangeForPeriod($period);
        if ($dateRange) {
            $query->whereBetween(DB::raw('DATE(created_at)'), [$dateRange['start'], $dateRange['end']]);
        }

        $orders = $query->get();

        $salesByDate = [];
        foreach ($orders as $order) {
            $cartMetadata = $order->cart_metadata;

            if (is_string($cartMetadata)) {
                $cartMetadata = json_decode($cartMetadata, true);
            }

            if ($cartMetadata === null || !is_array($cartMetadata)) {
                continue;
            }

            $toBePaid = $cartMetadata['billing_summary']['to_be_paid'] ?? 0;
            $orderDate = $order->order_date;

            if (!isset($salesByDate[$orderDate])) {
                $salesByDate[$orderDate] = 0;
            }
            $salesByDate[$orderDate] += $toBePaid;
        }

        krsort($salesByDate);

        // Limit based on period
        $limit = $this->getLimitForPeriod($period);
        $salesByDate = array_slice($salesByDate, 0, $limit, true);

        $result = [];
        foreach ($salesByDate as $date => $totalSale) {
            $result[] = [
                'order_date' => $date,
                'total_sale' => round($totalSale, 2)
            ];
        }

        return CommonHelper::responseWithData($result);
    }

    public function getWeeklyReturns(Request $request){
        $period = $request->input('period', 'weekly');
        $curdate = date('Y-m-d');

        // Build query based on period
        $query = Order::select('id', 'cart_metadata', 'active_status', DB::raw('DATE(created_at) AS order_date'))
            ->where(DB::raw('DATE(created_at)'), '<=', $curdate)
            ->where('active_status', 8)
            ->whereNotNull('cart_metadata');

        // Apply date range based on period
        $dateRange = $this->getDateRangeForPeriod($period);
        if ($dateRange) {
            $query->whereBetween(DB::raw('DATE(created_at)'), [$dateRange['start'], $dateRange['end']]);
        }

        $orders = $query->get();

        $returnsByDate = [];
        foreach ($orders as $order) {
            $cartMetadata = $order->cart_metadata;

            if (is_string($cartMetadata)) {
                $cartMetadata = json_decode($cartMetadata, true);
            }

            if ($cartMetadata === null || !is_array($cartMetadata)) {
                continue;
            }

            $toBePaid = $cartMetadata['billing_summary']['to_be_paid'] ?? 0;
            $orderDate = $order->order_date;

            if (!isset($returnsByDate[$orderDate])) {
                $returnsByDate[$orderDate] = 0;
            }
            $returnsByDate[$orderDate] += $toBePaid;
        }

        krsort($returnsByDate);

        // Limit based on period
        $limit = $this->getLimitForPeriod($period);
        $returnsByDate = array_slice($returnsByDate, 0, $limit, true);

        $result = [];
        foreach ($returnsByDate as $date => $totalReturn) {
            $result[] = [
                'order_date' => $date,
                'total_return' => round($totalReturn, 2)
            ];
        }

        return CommonHelper::responseWithData($result);
    }

    /**
     * Get date range based on period type
     * @param string $period - Period type (daily, weekly, monthly, yearly, all)
     * @return array|null - Array with start and end dates, or null for all data
     */
    private function getDateRangeForPeriod($period)
    {
        $now = now();

        switch ($period) {
            case 'daily':
                return [
                    'start' => $now->toDateString(),
                    'end' => $now->toDateString()
                ];
            case 'weekly':
                return [
                    'start' => $now->copy()->startOfWeek()->toDateString(),
                    'end' => $now->copy()->endOfWeek()->toDateString()
                ];
            case 'monthly':
                return [
                    'start' => $now->copy()->startOfMonth()->toDateString(),
                    'end' => $now->copy()->endOfMonth()->toDateString()
                ];
            case 'yearly':
                return [
                    'start' => $now->copy()->startOfYear()->toDateString(),
                    'end' => $now->copy()->endOfYear()->toDateString()
                ];
            case 'all':
                return null; // No date range filter
            default:
                // Default to weekly
                return [
                    'start' => $now->copy()->startOfWeek()->toDateString(),
                    'end' => $now->copy()->endOfWeek()->toDateString()
                ];
        }
    }

    /**
     * Get the number of data points to show based on period
     * @param string $period - Period type (daily, weekly, monthly, yearly, all)
     * @return int - Number of data points to limit
     */
    private function getLimitForPeriod($period)
    {
        switch ($period) {
            case 'daily':
                return 1;
            case 'weekly':
                return 7;
            case 'monthly':
                return 31;
            case 'yearly':
                return 12;
            case 'all':
                return 365; // Limit all time to 365 data points
            default:
                return 7;
        }
    }

    public function updateStatus(Request $request){
        $validator = Validator::make($request->all(),[
            'order_id' => 'required',
            'status_id' => 'required',
        ], [
            'order_id.required' => 'The Order id field is required.',
            'status_id.required' => 'The status field is required.',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $order = Order::find($request->order_id);
        if(empty($order)){
            return CommonHelper::responseError("Order Not found!");
        }
        $selectedStatus = OrderStatusList::where('id',$request->status_id)->value('status');

        if($order->active_status == $request->status_id){
            return CommonHelper::responseError("This Order is already ".$selectedStatus."!");
        }

        if($order->active_status == 6 && $request->status_id < 6){
            return CommonHelper::responseError("This Order is Delivered");
        }

        if($order->active_status == OrderStatusList::$paymentPending){
            return CommonHelper::responseError("Payment is pending. Without payment order can not receive");
        }

        if($order->active_status == OrderStatusList::$returned || $order->active_status == OrderStatusList::$cancelled){
            return CommonHelper::responseError("Order is Cancelled OR Returned.");
        }

        if(auth()->user()->role_id != Role::$roleSuperAdmin ){
            if($order->active_status > $request->status_id){
                return CommonHelper::responseError("You can not update this order status to ".$selectedStatus."!");
            }
        }

        DB::beginTransaction();
        try {

            if($order->active_status != $request->status_id){

                if(isset($request->delivery_boy_id) && $request->delivery_boy_id != "" && $request->delivery_boy_id != 0){

                    // Delivery Boy cash collection add and cash_received update with update balance of delivery boy start
                    if($request->status_id == OrderStatusList::$delivered) {

                        $deliveryBoy = DeliveryBoy::find($request->delivery_boy_id);

                        $deliveryBoy->balance = floatval($deliveryBoy->balance) + floatval($order->delivery_boy_bonus_amount);

                        CommonHelper::addFundTransfers($deliveryBoy->id, $order->delivery_boy_bonus_amount, FundTransfer::$typeCredit);

                        if ($order->payment_method == DeliveryBoyTransaction::$paymentTypeCod) {

                           $transactionData = [
                                'user_id'           => $order->user_id,
                                'order_id'          => $order->id,
                                'delivery_boy_id'   => $deliveryBoy->id,
                                'type'              => $order->payment_method,
                                'amount'            => $order->remaining_final,
                                'status'            => Transaction::$statusSuccess,
                                'message'           => "Delivery boy " . OrderStatusList::$orderDelivered . " this order. Order payment method was " . Transaction::$paymentTypeCod,
                                'transaction_date'  => now(), // Cleaner than date('Y-m-d H:i:s')
                            ];

                            $transaction = DeliveryBoyTransaction::create($transactionData);

                            if (!$transaction) {
                                \Log::error("Failed to save delivery boy transaction", $transactionData);
                            }

                            $order->transaction_id = $transaction->id ?? 0;

                            $deliveryBoy->cash_received = floatval($deliveryBoy->cash_received) + floatval($order->remaining_final);
                        }

                        $deliveryBoy->save();
                    }

                    $order->delivery_boy_id = $request->delivery_boy_id;
                }
                //refer earn bonus amount update start





                $order->active_status = $request->status_id;
                $order->save();

                if ($request->status_id == OrderStatusList::$delivered) {
                    $order = Order::with('user', 'items.productVariant.product')->find($request->order_id);
                    $user = $order->user;

                    

                    $referralMinOrderAmount = Setting::get_value('referral_min_order_amount');

                    if ($user && $user->friends_code && $order->final_total >= $referralMinOrderAmount) {

                        // Check if this is the user's FIRST delivered order
                        $deliveredOrdersCount = Order::where('user_id', $user->id)
                            ->where('active_status', OrderStatusList::$delivered)
                            ->where('id', '!=', $order->id)  // Exclude current order
                            ->count();

                        if ($deliveredOrdersCount === 0) {  // This means it's the first order

                            $now = Carbon::now();

                            $canCreditReferral = true;

                            foreach ($order->items as $item) {
                                $product = $item->productVariant->product ?? null;
                                if ($product && $product->return_status == 1 && $product->return_days > 0) {
                                   $canCreditReferral = false;
                                }
                            }

                            if ($canCreditReferral) {
                                // Credit referral bonus immediately. The helper
                                // enforces idempotency and the lifetime cap.
                                $referrer = User::where('referral_code', $user->friends_code)->first();
                                CommonHelper::creditReferralFirstOrderBonus($order, $referrer);

                            } else {
                                // Queue a job to check again after max return days
                                $maxReturnDays = $order->items->filter(function ($item) {
                                    $product = $item->productVariant->product ?? null;
                                    return $product && $product->return_status == 1 && $product->return_days > 0;
                                })->max(function ($item) {
                                    return $item->productVariant->product->return_days;
                                }) ?? 0;

                                $deliveredStatus = OrderStatus::where('order_id', $order->id)
                                    ->where('status', OrderStatusList::$delivered)
                                    ->orderBy('created_at', 'desc')
                                    ->first();

                                $deliveredAt = $deliveredStatus ? Carbon::parse($deliveredStatus->created_at) : Carbon::parse($order->updated_at);
                                $now = Carbon::now();

                                if ($maxReturnDays > 0) {

                                    $returnPeriodEnd = $deliveredAt->copy()->addDays($maxReturnDays);
                                    $delay = $now->diffInSeconds($returnPeriodEnd, false); // false: signed diff


                                    if ($delay > 0) {
                                        ProcessReferralBonusAfterReturnPeriod::dispatch($order->id)->delay(Carbon::now()->addSeconds($delay));
                                    }
                                }
                            }
                        }
                    }

                    // Credit seller wallet for each delivered order item
                    $orderItems = OrderItem::where('order_id', $request->order_id)
                        ->whereNotIn('active_status', [OrderStatusList::$cancelled, OrderStatusList::$returned])
                        ->get();

                    foreach ($orderItems as $orderItem) {
                        \App\Http\Controllers\SellerWalletController::creditOrderAmount($orderItem);
                    }
                }

                $excludedStatuses = [OrderStatusList::$cancelled, OrderStatusList::$returned];

                // Update the order items
                $query = OrderItem::where("order_id", $request->order_id)
                    ->whereNotIn("active_status", $excludedStatuses)
                    ->update(['active_status' => $request->status_id]);

                $orderStatus = array();
                $orderStatus["order_id"] = $request->order_id;
                $orderStatus['order_item_id'] = 0;
                $orderStatus["status"] = $request->status_id;
                $orderStatus["created_by"] = auth()->user()->id;
                $orderStatus["user_type"] = auth()->user()->role_id;
                CommonHelper::setOrderStatus($orderStatus);
            }else{
                $status = OrderStatusList::find($request->status_id);
                return CommonHelper::responseError("Status is already ".$status->status);
            }
            DB::commit();
        } catch (\Exception $e) {
            Log::info("Error : ".$e->getMessage());
            DB::rollBack();
            throw $e;
            return CommonHelper::responseError("Something Went Wrong!");
        }

        $order = Order::with('items')->where("id",$request->order_id)->first();

        if(!empty($order)){
            log::info("order",[$order]);

           //
          try {
               // dispatch(function () use ($order, $request) {
                    CommonHelper::sendNotificationOrderStatus($order);
                    $admins = Admin::get();

                    foreach ($admins as $admin) {
                        $admin->notify(new OrderNotification($order->id,(string)$request->status_id));
                    }
               // })->afterResponse();
             }
             catch (\Exception $e) {

             }

            try {
                dispatch(new SendEmailJob($order))->afterResponse();
            }catch ( \Exception $e){
                Log::error("Update order status by delivery boy Send mail error :",[$e->getMessage()] );
            }

            try {
                CommonHelper::sendSmsOrderStatus($order, $order->active_status);
            }catch ( \Exception $e){
                Log::error("Update order status by delivery boy Send SMS error :",[$e->getMessage()] );
            }
        }


        return CommonHelper::responseSuccess("Order Updated Successfully!");
    }

    public function assignDeliveryBoy(Request $request){
        $validator = Validator::make($request->all(),[
            'order_id' => 'required',
            'delivery_boy_id' => 'required',
        ], [
            'order_id.required' => 'The Order id field is required.',
            'delivery_boy_id.required' => 'The delivery boy field is required.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $deliveryBoy = DeliveryBoy::find($request->delivery_boy_id);
        if(empty($deliveryBoy)) {
            return CommonHelper::responseSuccess("Delivery Boy Not Found!");
        }
        $order = Order::find($request->order_id);

        if($order) {
            if($order->delivery_boy_id == $request->delivery_boy_id){
                return CommonHelper::responseError("This delivery boy already assign!");
            }
            if($order->active_status == OrderStatusList::$paymentPending){
                return CommonHelper::responseError("Payment is pending. Without payment order can not receive");
            }

            $final_total = floatval($order->total);

            $bonus_type = $deliveryBoy->bonus_type;
            $bonus_details['final_total'] = $final_total;
            $bonus_details['bonus_type'] = $bonus_type;
            $bonus_amount = 0;
            if($bonus_type == DeliveryBoy::$bonusCommission){

                $bonus_percentage = floatval($deliveryBoy->bonus_percentage);
                $bonus_min_amount = floatval($deliveryBoy->bonus_min_amount);
                $bonus_max_amount = floatval($deliveryBoy->bonus_max_amount);

                $bonus_amount = floatval( ($final_total *  $bonus_percentage)/100);

                if($bonus_amount < $bonus_min_amount && $bonus_min_amount != 0){
                    $bonus_amount = $bonus_min_amount;
                }

                if($bonus_amount > $bonus_max_amount && $bonus_max_amount != 0){
                    $bonus_amount = $bonus_max_amount;
                }

                $bonus_details['bonus_type_name'] = DeliveryBoy::$commission;
                $bonus_details['bonus_percentage'] = $bonus_percentage;
                $bonus_details['bonus_min_amount'] = $bonus_min_amount;
                $bonus_details['bonus_max_amount'] = $bonus_max_amount;
                $bonus_details['bonus_amount'] = $bonus_amount;
            }else{
                $bonus_details['bonus_type_name'] = DeliveryBoy::$fixed;
            }
            $bonus_details['bonus_amount'] = $bonus_amount;

            $order->delivery_boy_bonus_details = $bonus_details;
            $order->delivery_boy_bonus_amount = $bonus_amount;

            $previousDeliveryBoyId = $order->delivery_boy_id ? (int) $order->delivery_boy_id : null;

            $order->delivery_boy_id = $request->delivery_boy_id;
            $order->save();

            // The driver app reads its ride from Firestore, not from this table, so
            // an assignment written only to MySQL never reaches the phone. Push the
            // same Firestore updates the admin assign endpoint performs: hand the
            // order over properly when it already had a driver, otherwise write the
            // route to the newly assigned one.
            try {
                if ($previousDeliveryBoyId !== null && $previousDeliveryBoyId !== (int) $request->delivery_boy_id) {
                    FirestoreDeliveryBoyService::emergencyChangeDriver(
                        (int) $order->id,
                        $previousDeliveryBoyId,
                        (int) $request->delivery_boy_id
                    );
                } else {
                    FirestoreDeliveryBoyService::updateDeliveryBoyCurrentOrder(
                        (int) $order->id,
                        (int) $request->delivery_boy_id
                    );
                }

                // Withdraw the order from any driver still holding the offer popup.
                FirestoreDeliveryBoyService::clearOrderOfferFromOtherDeliveryBoys((int) $order->id);
                RetryDeliveryBoyAssignmentJob::cancelExistingForOrder((int) $order->id);
            } catch (\Exception $e) {
                Log::error("Delivery boy assigned on order Firestore sync error :", [$e->getMessage()]);
            }

            try {
                CommonHelper::sendMailOrderStatus($order, true);
                CommonHelper::sendNotificationOrderAssignDeliveryBoy($order);
            }catch ( \Exception $e){
                Log::error("Delivery boy assigned on order Send mail error :",[$e->getMessage()] );
            }

            return CommonHelper::responseSuccess("Delivery boy assigned Successfully for this order!");
        }else{
            return CommonHelper::responseError("Order Not found!");
        }

    }

    /**
     * Admin assigns a delivery boy to an order (similar to driver accepting the order)
     * This method bypasses the notification check and directly assigns the driver
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function adminAssignDeliveryBoy(Request $request)
    {
        try {
            $orderId = $request->input('order_id');
            $deliveryBoyId = $request->input('delivery_boy_id');

            if (empty($orderId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            if (empty($deliveryBoyId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'delivery_boy_id parameter is required'
                ], 400);
            }

            // Use the service to assign the order
            $result = DeliveryBoyOrderService::adminAssignOrder((int) $orderId, (int) $deliveryBoyId);

            if ($result['success']) {
                $wasReassigned = $result['reassigned'] ?? false;

                // On a reassignment the service already wrote both drivers'
                // Firestore documents, including the handoff stop and the
                // already-picked stops filter. Writing the route again here would
                // replace it with a full-stops route and send the new driver back
                // to restaurants the previous driver had already collected from.
                if (!($result['firestore_synced'] ?? false)) {
                    try {
                        $firestoreResult = FirestoreDeliveryBoyService::updateDeliveryBoyCurrentOrder((int) $orderId, (int) $deliveryBoyId);
                        if (!$firestoreResult['success']) {
                            Log::warning("Admin assign delivery boy - Firestore update failed:", [$firestoreResult['message']]);
                        }
                    } catch (\Exception $e) {
                        Log::error("Admin assign delivery boy - Firestore error:", [$e->getMessage()]);
                    }
                }

                // Send notifications (with try-catch to prevent notification failures from breaking the response)
                try {
                    $order = Order::find($orderId);
                    if ($order) {
                        // Send email notification
                        CommonHelper::sendMailOrderStatus($order, true);
                        // Send push notification to delivery boy
                        CommonHelper::sendNotificationOrderAssignDeliveryBoy($order);

                        // Send notification to driver using DriverNotificationService
                        DriverNotificationService::send(
                            (int) $deliveryBoyId,
                            $wasReassigned ? 'Order Transferred To You' : 'New Order Assigned',
                            $wasReassigned
                                ? "Order #{$order->id} has been transferred to you by support. Collect the items from the previous partner shown as your first stop."
                                : "Order #{$order->id} has been assigned to you by admin. Please check your orders.",
                            '',
                            'order',
                            null,
                            ['order_id' => $order->id, 'reassigned' => $wasReassigned]
                        );
                    }
                } catch (\Exception $e) {
                    Log::error("Admin assign delivery boy - notification error:", [$e->getMessage()]);
                }

                return response()->json([
                    'status' => 1,
                    'message' => $result['message'],
                    'data' => $result['data']
                ]);
            }

            return response()->json([
                'status' => 0,
                'message' => $result['message']
            ], 400);

        } catch (\Exception $e) {
            Log::error('Admin assign delivery boy failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    public function updateItemsStatus(Request $request){
        $validator = Validator::make($request->all(),[
            'ids' => 'required',
            'status_id' => 'required',
        ], [
            'ids.required' => 'The Item id field is required.',
            'status_id.required' => 'The status field is required.',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $ids = explode(",",$request->ids);
        foreach ($ids as $key => $id){
            $orderItem = OrderItem::find($id);
            $orderItem->active_status = $request->status_id;
            $orderItem->save();

            // Credit seller wallet when order item is marked as delivered
            if ($request->status_id == OrderStatusList::$delivered) {
                \App\Http\Controllers\SellerWalletController::creditOrderAmount($orderItem);
            }

            $orderStatus = array();
            $orderStatus["order_id"] = $orderItem->order_id;
            $orderStatus["order_item_id"] = $id;
            $orderStatus["status"] = $request->status_id;
            $orderStatus["created_by"] = auth()->user()->id;
            $orderStatus["user_type"] = auth()->user()->role_id;
            CommonHelper::setOrderStatus($orderStatus);
        }
        return CommonHelper::responseSuccess("Order Updated Successfully!");
    }

    public function updateSelfPickupOrderStatus(Request $request){
        $validator = Validator::make($request->all(),[
            'order_id' => 'required',
            'status_id' => 'required',
            'order_item_id' => 'nullable|integer',
        ], [
            'order_id.required' => 'The Order id field is required.',
            'status_id.required' => 'The status field is required.',
        ]);
        
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        
        $order = Order::find($request->order_id);
        if(empty($order)){
            return CommonHelper::responseError("Order Not found!");
        }
        
        if($order->order_type !== 'selfpickup'){
            return CommonHelper::responseError("This is not a self pickup order!");
        }
        
        if(isset($request->order_item_id) && $request->order_item_id != ""){
            return $this->handleItemReturn($request, $order);
        }
        
        $selectedStatus = OrderStatusList::where('id',$request->status_id)->value('status');

        if($order->active_status == $request->status_id){
            return CommonHelper::responseError("This Order is already ".$selectedStatus."!");
        }

        $selfPickupStatuses = [
            OrderStatusList::$selfPickupPending,
            OrderStatusList::$selfPickupReady,
            OrderStatusList::$selfPickupPicked,
        ];
        
        if(!in_array($request->status_id, $selfPickupStatuses)){
            return CommonHelper::responseError("Invalid status for self pickup order!");
        }

        if($order->active_status == OrderStatusList::$selfPickupPicked){
            return CommonHelper::responseError("Order is already picked up!");
        }
        if($order->active_status == OrderStatusList::$returned){
            return CommonHelper::responseError("Order is already returned!");
        }
        if($order->active_status == OrderStatusList::$cancelled){
            return CommonHelper::responseError("Order is already cancelled!");
        }

        if($order->active_status > $request->status_id){
            return CommonHelper::responseError("You cannot update this order status to ".$selectedStatus."!");
        }

        if($order->active_status == OrderStatusList::$paymentPending){
            return CommonHelper::responseError("Payment is pending. Without payment order can not be processed");
        }

        DB::beginTransaction();
        try {
            if($order->active_status != $request->status_id){
                $order->active_status = $request->status_id;
                $order->save();

                $excludedStatuses = [OrderStatusList::$cancelled];
                $query = OrderItem::where("order_id", $request->order_id)
                    ->whereNotIn("active_status", $excludedStatuses)
                    ->update(['active_status' => $request->status_id]);

                // Credit seller wallet when self-pickup order is picked up
                if ($request->status_id == OrderStatusList::$selfPickupPicked) {
                    $orderItems = OrderItem::where('order_id', $request->order_id)
                        ->whereNotIn('active_status', [OrderStatusList::$cancelled])
                        ->get();

                    foreach ($orderItems as $orderItem) {
                        \App\Http\Controllers\SellerWalletController::creditOrderAmount($orderItem);
                    }
                }

                $orderStatus = array();
                $orderStatus["order_id"] = $request->order_id;
                $orderStatus['order_item_id'] = 0;
                $orderStatus["status"] = $request->status_id;
                $orderStatus["created_by"] = auth()->user()->id;
                $orderStatus["user_type"] = auth()->user()->role_id;
                CommonHelper::setOrderStatus($orderStatus);
            }else{
                $status = OrderStatusList::find($request->status_id);
                return CommonHelper::responseError("Status is already ".$status->status);
            }
            DB::commit();
        } catch (\Exception $e) {
            Log::info("Error : ".$e->getMessage());
            DB::rollBack();
            throw $e;
            return CommonHelper::responseError("Something Went Wrong!");
        }

        $order = Order::with('items')->where("id",$request->order_id)->first();

        if(!empty($order)){
          try {
               CommonHelper::sendNotificationOrderStatus($order);
               $admins = Admin::get();

               foreach ($admins as $admin) {
                   $admin->notify(new OrderNotification($order->id,(string)$request->status_id));
               }
             }
             catch (\Exception $e) {
                 Log::error("Self pickup order status notification error: " . $e->getMessage());
             }

            try {
                dispatch(new SendEmailJob($order))->afterResponse();
            }catch ( \Exception $e){
                Log::error("Self pickup order status email error: " . $e->getMessage());
            }

            try {
                CommonHelper::sendSmsOrderStatus($order, $order->active_status);
            }catch ( \Exception $e){
                Log::error("Self pickup order status SMS error: " . $e->getMessage());
            }
        }

        return CommonHelper::responseSuccess("Self Pickup Order Updated Successfully!");
    }

    private function handleItemReturn($request, $order){
        $orderItem = OrderItem::find($request->order_item_id);
        if(empty($orderItem)){
            return CommonHelper::responseError("Order item not found!");
        }
        
        if($request->status_id != OrderStatusList::$returned){
            return CommonHelper::responseError("Invalid status for product return!");
        }
        
        if($orderItem->active_status == OrderStatusList::$returned || $orderItem->active_status == OrderStatusList::$cancelled){
            return CommonHelper::responseError("This product is already returned or cancelled!");
        }
        
        if($order->active_status != OrderStatusList::$selfPickupPicked){
            return CommonHelper::responseError("Order must be picked up before returning products!");
        }
        
        DB::beginTransaction();
        try {
            $orderItem->active_status = $request->status_id;
            $orderItem->cancellation_reason = $request->reason ?? 'Product returned by customer';
            $orderItem->save();
            
            $remainingActiveItems = OrderItem::where("order_id", $order->id)
                ->where('id', '!=', $orderItem->id)
                ->where('active_status', '!=', OrderStatusList::$cancelled)
                ->where('active_status', '!=', OrderStatusList::$returned)
                ->count();
            
            if ($remainingActiveItems == 0) {
                $additional_charges = json_decode($order->additional_charges, true) ?? [];
                $additional_charges_total = array_sum(array_column($additional_charges, 'amount'));

                $order->active_status = OrderStatusList::$returned;
                $order->remaining_total = 0;
                $order->final_total = $additional_charges_total;
                $order->remaining_final = $additional_charges_total;
                $order->save();
            }
            else{
                $additional_charges = json_decode($order->additional_charges, true) ?? [];
                $additional_charges_total = array_sum(array_column($additional_charges, 'amount'));

                $order->remaining_total = floatval($order->remaining_total) - floatval($orderItem->sub_total);
                $order->remaining_final = floatval($order->remaining_total) + $additional_charges_total;

                $order->final_total = $order->remaining_final;

                $order->save();
            }
            
            $product_variant_id = $orderItem->product_variant_id;
            $product_variant = ProductVariant::where('id', $product_variant_id)->first();
            
            if ($product_variant) {
                $new_stock_value = $product_variant->stock + $orderItem->quantity;
                $product_variant->stock = $new_stock_value;
                $product_variant->save();
            }
            
            try {
                CommonHelper::sendSmsOrderStatus($orderItem, 9);
                CommonHelper::sendOrderItemStatusMailNotification($orderItem, 'order_item_status_update');
            } catch (\Exception $e) {
                Log::error("Error sending notifications for item return: " . $e->getMessage());
            }
            
            DB::commit();
        } catch (\Exception $e) {
            Log::info("Error returning product: ".$e->getMessage());
            DB::rollBack();
            return CommonHelper::responseError("Something went wrong while returning the product!");
        }
        
        return CommonHelper::responseSuccess("Product returned successfully");
    }

    public function getSellerOrders(Request $request)
    {
        try {
            // Get authenticated seller
            $seller = auth()->user()->seller;
            if (!$seller) {
                return CommonHelper::responseError('Seller not found');
            }

            $limit = $request->input('limit', 10);
            $offset = $request->input('offset', 0);
            $order_status = $request->input('order_status'); // Optional filter by status

            // Fetch orders that have items belonging to this seller
            $ordersQuery = Order::select(
                'orders.*',
                'users.name as customer_name',
                'users.email as customer_email',
                'users.mobile as customer_mobile'
            )
            ->join('order_items', 'orders.id', '=', 'order_items.order_id')
            ->leftJoin('users', 'orders.user_id', '=', 'users.id')
            ->where('order_items.seller_id', $seller->id)
            ->groupBy('orders.id')
            ->orderBy('orders.id', 'DESC');

            // Filter by order status if provided
            if ($order_status) {
                $ordersQuery->where('orders.active_status', $order_status);
            }

            $total = $ordersQuery->count();
            $orders = $ordersQuery->skip($offset)->take($limit)->get();

            $response = [];
            foreach ($orders as $order) {
                // Fetch order items for this seller only
                $orderItems = OrderItem::with('images')
                    ->select(
                        'order_items.*',
                        'products.name as product_name',
                        'products.image as product_image',
                        'product_variants.measurement',
                        DB::raw('(select short_code from units where id = product_variants.stock_unit_id) as unit')
                    )
                    ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                    ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                    ->where('order_items.order_id', $order->id)
                    ->where('order_items.seller_id', $seller->id)
                    ->get();

                // Format items with images
                $formattedItems = [];
                foreach ($orderItems as $item) {
                    $itemData = $item->toArray();

                    // Add product image
                    if ($item->product_image) {
                        $itemData['product_image_url'] = str_starts_with($item->product_image, 'http') ? $item->product_image : asset('storage/' . $item->product_image);
                    }

                    // Add item images
                    $itemData['images'] = [];
                    if ($item->images) {
                        foreach ($item->images as $img) {
                            $itemData['images'][] = [
                                'id' => $img->id,
                                'image' => $img->image ? (str_starts_with($img->image, 'http') ? $img->image : asset('storage/' . $img->image)) : null
                            ];
                        }
                    }

                    $formattedItems[] = $itemData;
                }

                // Fetch combo items for this seller
                $comboItems = DB::table('order_combo_items')
                    ->where('order_id', $order->id)
                    ->where('seller_id', $seller->id)
                    ->get();

                $formattedCombos = [];
                foreach ($comboItems as $combo) {
                    $comboData = (array) $combo;

                    // Decode products JSON
                    if (isset($comboData['products']) && is_string($comboData['products'])) {
                        $comboData['products'] = json_decode($comboData['products'], true);
                    }

                    $formattedCombos[] = $comboData;
                }

                // Get cart metadata
                $cartMetadata = null;
                $sellerNotes = null;
                $comboNotes = null;

                if (!empty($order->cart_metadata) && is_array($order->cart_metadata)) {
                    $cartMetadata = $order->cart_metadata;

                    // Get seller-specific notes
                    if (isset($cartMetadata['cart_info']['seller_notes'])) {
                        $sellerNotes = $cartMetadata['cart_info']['seller_notes'][$seller->id] ?? null;
                    }

                    // Get combo notes for this seller
                    if (isset($cartMetadata['cart_info']['combo_notes'])) {
                        foreach ($comboItems as $combo) {
                            if (isset($cartMetadata['cart_info']['combo_notes'][$combo->combo_custom_cart_id])) {
                                $comboNotes = $cartMetadata['cart_info']['combo_notes'][$combo->combo_custom_cart_id];
                                break; // Get first combo note
                            }
                        }
                    }
                }

                // Get preparation time from settings or seller profile
                $preparationTime = Setting::get_value('default_preparation_time') ?? 30; // Default 30 minutes

                // Get order status details
                $orderStatuses = OrderStatus::where('order_id', $order->id)
                    ->orderBy('id', 'DESC')
                    ->get();

                $currentStatus = OrderStatusList::find($order->active_status);

                // Build response
                $response[] = [
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'customer_name' => $order->customer_name,
                    'customer_email' => $order->customer_email,
                    'customer_mobile' => $order->customer_mobile ?? $order->mobile,
                    'order_type' => $order->order_type,
                    'payment_method' => $order->payment_method,
                    'total' => (float) $order->total,
                    'delivery_charge' => (float) $order->delivery_charge,
                    'final_total' => (float) $order->final_total,
                    'delivery_time' => $order->delivery_time,
                    'delivery_address' => $order->address,
                    'active_status' => $order->active_status,
                    'status_name' => $currentStatus->status ?? '',
                    'created_at' => $order->created_at,
                    'preparation_time' => $preparationTime,
                    'items' => $formattedItems,
                    'combo_items' => $formattedCombos,
                    'seller_notes' => $sellerNotes,
                    'combo_notes' => $comboNotes,
                    'order_statuses' => $orderStatuses,
                    'cart_metadata' => [
                        'delivery_instructions' => $cartMetadata['cart_info']['delivery_instructions'] ?? null,
                        'contact_name' => $cartMetadata['cart_info']['contact_name'] ?? null,
                        'contact_phone' => $cartMetadata['cart_info']['contact_phone'] ?? null,
                        'contact_email' => $cartMetadata['cart_info']['contact_email'] ?? null,
                    ]
                ];
            }

            return CommonHelper::responseWithData([
                'orders' => $response,
                'total' => $total
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getSellerOrders: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch orders');
        }
    }

    public function assignSeller(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required',
            'store_id' => 'required',
            'seller_id' => 'required',
        ], [
            'order_id.required' => 'The Order id field is required.',
            'store_id.required' => 'The Store id field is required.',
            'seller_id.required' => 'The Seller id field is required.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $order = Order::find($request->order_id);
        if (empty($order)) {
            return CommonHelper::responseError("Order Not found!");
        }

        $seller = Seller::find($request->seller_id);
        if (empty($seller)) {
            return CommonHelper::responseError("Seller Not found!");
        }

        try {
            $now = now()->setTimezone('Asia/Kolkata');

            // Check if record exists for this order_id and store_id
            $existingRecord = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->where('store_id', $request->store_id)
                ->first();

            if ($existingRecord) {
                // Update existing record
                DB::table('order_seller_status_tracking')
                    ->where('order_id', $request->order_id)
                    ->where('store_id', $request->store_id)
                    ->update([
                        'seller_id' => $request->seller_id,
                        'updated_at' => $now,
                    ]);
                Log::info("Order Seller Assignment - Updated seller for order_id: {$request->order_id}, store_id: {$request->store_id}, seller_id: {$request->seller_id}");
            } else {
                // Insert new record with unique OTP
                $otp = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);
                DB::table('order_seller_status_tracking')->insert([
                    'order_id' => $request->order_id,
                    'seller_id' => $request->seller_id,
                    'store_id' => $request->store_id,
                    'status' => 'assigned_to_seller',
                    'otp' => $otp,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
                Log::info("Order Seller Assignment - Inserted new tracking record for order_id: {$request->order_id}, store_id: {$request->store_id}, seller_id: {$request->seller_id}");
            }

            Log::info("Order Seller Assignment - About to start Firestore sync", [
                'order_id' => $request->order_id,
                'checkpoint' => 'before_try_block'
            ]);

            // Sync order seller tracking data to Firestore
            try {
                Log::info("Order Seller Assignment - Attempting to sync to Firestore", [
                    'order_id' => $request->order_id,
                    'seller_id' => $request->seller_id,
                    'store_id' => $request->store_id
                ]);

                $firestoreResult = FirestoreOrderSellerTrackingService::syncOrderSellerTracking($request->order_id);

                if ($firestoreResult['success']) {
                    Log::info("Order Seller Assignment - Synced to Firestore successfully", [
                        'order_id' => $request->order_id,
                        'seller_id' => $request->seller_id,
                        'sellers_count' => $firestoreResult['sellers_count'] ?? 0,
                        'success_count' => $firestoreResult['success_count'] ?? 0
                    ]);
                } else {
                    Log::warning("Order Seller Assignment - Failed to sync to Firestore", [
                        'order_id' => $request->order_id,
                        'seller_id' => $request->seller_id,
                        'error' => $firestoreResult['message'] ?? 'Unknown error'
                    ]);
                }
            } catch (\Exception $firestoreException) {
                // Log Firestore error but don't fail the seller assignment
                Log::error("Order Seller Assignment - Firestore sync exception", [
                    'order_id' => $request->order_id,
                    'seller_id' => $request->seller_id,
                    'error' => $firestoreException->getMessage(),
                    'trace' => $firestoreException->getTraceAsString()
                ]);
            }

            return CommonHelper::responseSuccess("Seller assigned successfully!");

        } catch (\Exception $e) {
            Log::error('Error in assignSeller: ' . $e->getMessage());
            return CommonHelper::responseError("Something went wrong while assigning seller!");
        }
    }

    /**
     * Get driver notifications history for an order
     *
     * @param int $id Order ID
     * @return \Illuminate\Http\JsonResponse
     */
    public function getDriverNotifications($id)
    {
        try {
            $order = Order::find($id);

            if (!$order) {
                return CommonHelper::responseError("Order not found");
            }

            // Get notification history
            $notifications = OrderDeliveryBoyNotification::where('order_id', $id)
                ->orderBy('attempt_number', 'asc')
                ->get();

            // Collect all delivery boy IDs for name lookup (including those in skip_reasons)
            $allDeliveryBoyIds = [];
            foreach ($notifications as $notification) {
                $allDeliveryBoyIds = array_merge($allDeliveryBoyIds, $notification->delivery_boy_ids ?? []);
                $allDeliveryBoyIds = array_merge($allDeliveryBoyIds, $notification->on_ride_driver_ids ?? []);
                if ($notification->accepted_by) {
                    $allDeliveryBoyIds[] = $notification->accepted_by;
                }
                // Also collect IDs from skip_reasons (skip funnel_summary — has no driver IDs)
                if (!empty($notification->skip_reasons)) {
                    foreach ($notification->skip_reasons as $reason => $data) {
                        if ($reason === 'funnel_summary') continue;
                        if (is_array($data)) {
                            foreach ($data as $driver) {
                                if (!empty($driver['id'])) {
                                    $allDeliveryBoyIds[] = $driver['id'];
                                }
                            }
                        }
                    }
                }
            }
            $allDeliveryBoyIds = array_unique($allDeliveryBoyIds);

            $deliveryBoyNames = [];
            if (!empty($allDeliveryBoyIds)) {
                $deliveryBoyNames = DeliveryBoy::whereIn('id', $allDeliveryBoyIds)
                    ->pluck('name', 'id')
                    ->toArray();
            }

            // Get pending assignment status
            $pendingAssignment = PendingDeliveryAssignment::where('order_id', $id)->first();

            // Skip reason labels for display (in pipeline order)
            $skipReasonLabels = [
                'order_priority'         => '[1] Order Priority Mismatch',
                'no_location'            => '[2] No Location History',
                'out_of_customer_radius' => '[3] Outside Customer Radius (>10km)',
                'no_active_session'      => '[4] Not Online (No Active Session)',
                'no_active_gig_booking'  => '[5] No Active Gig Booking',
                'hand_cash_exceeded'     => '[6] Hand Cash Limit Exceeded',
                'on_ride'                => '[7] Currently On Active Ride',
            ];

            // Format response
            $formattedNotifications = $notifications->map(function ($n) use ($deliveryBoyNames, $skipReasonLabels) {
                // Get driver names for notified drivers
                $notifiedDrivers = [];
                foreach ($n->delivery_boy_ids ?? [] as $driverId) {
                    $notifiedDrivers[] = [
                        'id' => $driverId,
                        'name' => $deliveryBoyNames[$driverId] ?? 'Unknown'
                    ];
                }

                // Get driver names for on-ride drivers
                $onRideDrivers = [];
                foreach ($n->on_ride_driver_ids ?? [] as $driverId) {
                    $onRideDrivers[] = [
                        'id' => $driverId,
                        'name' => $deliveryBoyNames[$driverId] ?? 'Unknown'
                    ];
                }

                // Format skip reasons — funnel_summary as counts, individual groups with driver names
                $formattedSkipReasons = null;
                if (!empty($n->skip_reasons)) {
                    $rawSkipReasons  = $n->skip_reasons;
                    $funnelSummary   = $rawSkipReasons['funnel_summary'] ?? null;
                    $individualGroups = [];

                    foreach ($rawSkipReasons as $reason => $drivers) {
                        if ($reason === 'funnel_summary') continue;
                        if (empty($drivers) || !is_array($drivers)) continue;

                        $enrichedDrivers = array_map(function ($driver) use ($deliveryBoyNames) {
                            return array_merge($driver, [
                                'name' => $deliveryBoyNames[$driver['id'] ?? 0] ?? ($driver['name'] ?? 'Unknown'),
                            ]);
                        }, $drivers);

                        $individualGroups[] = [
                            'reason'  => $reason,
                            'label'   => $skipReasonLabels[$reason] ?? $reason,
                            'count'   => count($drivers),
                            'drivers' => $enrichedDrivers,
                        ];
                    }

                    $formattedSkipReasons = [
                        'funnel_summary'    => $funnelSummary,
                        'individual_groups' => $individualGroups,
                    ];
                }

                return [
                    'id' => $n->id,
                    'attempt_number' => $n->attempt_number,
                    'drivers_notified_count' => $n->drivers_notified_count,
                    'notified_drivers' => $notifiedDrivers,
                    'on_ride_count' => $n->on_ride_count,
                    'on_ride_drivers' => $onRideDrivers,
                    'status' => $n->status,
                    'status_label' => $this->getNotificationStatusLabel($n->status),
                    'accepted_by' => $n->accepted_by,
                    'accepted_by_name' => $n->accepted_by ? ($deliveryBoyNames[$n->accepted_by] ?? 'Unknown') : null,
                    'accepted_at' => $n->accepted_at ? $n->accepted_at->format('d-m-Y H:i:s') : null,
                    'notified_at' => $n->notified_at ? $n->notified_at->format('d-m-Y H:i:s') : null,
                    'error_message' => $n->error_message,
                    'skip_reasons' => $formattedSkipReasons,
                    'created_at' => $n->created_at->format('d-m-Y H:i:s')
                ];
            });

            $totalNotified = $notifications->sum('drivers_notified_count');
            $totalAttempts = $notifications->count();
            $latestStatus = $notifications->last() ? $notifications->last()->status : null;

            // Check if auto-retry job is active in the queue
            $isRetryActive = RetryDeliveryBoyAssignmentJob::isActiveForOrder((int) $id);
            $autoRetryStatus = ['active' => $isRetryActive];

            if ($isRetryActive) {
                $nextJob = DB::table('jobs')
                    ->where('payload', 'like', '%RetryDeliveryBoyAssignmentJob%')
                    ->where('payload', 'like', '%"orderId";i:' . $id . ';%')
                    ->orderBy('available_at', 'asc')
                    ->first();

                if ($nextJob) {
                    $autoRetryStatus['next_run_at'] = date('d-m-Y H:i:s', $nextJob->available_at);
                }
            }

            return response()->json([
                'status' => 1,
                'message' => 'Driver notifications retrieved successfully',
                'data' => [
                    'order_id' => (int) $id,
                    'order_status' => $order->active_status,
                    'delivery_boy_assigned' => $order->delivery_boy_id ? true : false,
                    'delivery_boy_name' => $order->delivery_boy_id
                        ? (DeliveryBoy::find($order->delivery_boy_id)->name ?? null)
                        : null,
                    'total_attempts' => $totalAttempts,
                    'total_drivers_notified' => $totalNotified,
                    'latest_notification_status' => $latestStatus,
                    'auto_retry' => $autoRetryStatus,
                    'pending_assignment' => $pendingAssignment ? [
                        'status' => $pendingAssignment->status,
                        'attempts' => $pendingAssignment->attempts,
                        'last_attempted_at' => $pendingAssignment->last_attempted_at
                            ? $pendingAssignment->last_attempted_at->format('d-m-Y H:i:s')
                            : null,
                        'last_error' => $pendingAssignment->last_error
                    ] : null,
                    'notifications' => $formattedNotifications
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error getting driver notifications: ' . $e->getMessage());
            return CommonHelper::responseError("Something went wrong!");
        }
    }

    /**
     * Retry sending driver notification for an order
     *
     * @param int $id Order ID
     * @return \Illuminate\Http\JsonResponse
     */
    public function retryDriverNotification($id)
    {
        try {
            $order = Order::find($id);

            if (!$order) {
                return CommonHelper::responseError("Order not found");
            }

            // Check if order is in a valid state for notification (active_status >= 2)
            if ($order->active_status < 2) {
                return CommonHelper::responseError("Order must be confirmed (status 2 or higher) to send driver notifications");
            }

            // Check if delivery boy is already assigned
            if ($order->delivery_boy_id) {
                return CommonHelper::responseError("A delivery boy is already assigned to this order");
            }

            // Call the service to retry notification
            $result = FirestoreDeliveryBoyService::getAndSyncAvailableDeliveryBoys($id);

            $success = $result['firestore_sync']['success'] ?? false;
            $driversNotified = count($result['not_on_ride'] ?? []);
            $driversOnRide = count($result['on_ride'] ?? []);

            // Dispatch retry job to keep searching if no driver accepts
            try {
                RetryDeliveryBoyAssignmentJob::dispatchForOrder((int) $id);
            } catch (\Exception $retryJobException) {
                Log::error('Failed to dispatch retry delivery boy assignment job for order: ' . $id, [
                    'error' => $retryJobException->getMessage(),
                    'trace' => $retryJobException->getTraceAsString()
                ]);
            }

            if ($success) {
                return response()->json([
                    'status' => 1,
                    'message' => "Notification sent successfully to {$driversNotified} driver(s)",
                    'data' => [
                        'drivers_notified' => $driversNotified,
                        'drivers_on_ride' => $driversOnRide,
                        'attempt_number' => $result['notification']['attempt_number'] ?? null,
                        'firestore_synced' => true,
                        'auto_retry' => true
                    ]
                ]);
            } else {
                $message = $result['firestore_sync']['message'] ?? 'Failed to send notification';

                return response()->json([
                    'status' => 0,
                    'message' => $message,
                    'data' => [
                        'drivers_notified' => $driversNotified,
                        'drivers_on_ride' => $driversOnRide,
                        'attempt_number' => $result['notification']['attempt_number'] ?? null,
                        'firestore_synced' => false,
                        'pending_assignment' => $result['pending_assignment'] ?? null,
                        'auto_retry' => true
                    ]
                ]);
            }

        } catch (\Exception $e) {
            Log::error('Error retrying driver notification: ' . $e->getMessage());
            return CommonHelper::responseError("Something went wrong: " . $e->getMessage());
        }
    }

    public function testRetryDriverJob($id)
    {
        try {
            $order = Order::find($id);

            if (!$order) {
                return CommonHelper::responseError("Order not found");
            }

            if ($order->delivery_boy_id) {
                return CommonHelper::responseError("A delivery boy is already assigned to this order");
            }

            RetryDeliveryBoyAssignmentJob::dispatchForOrder((int) $id, 5);

            Log::info('Test: Retry delivery boy assignment job dispatched for order: ' . $id);

            return response()->json([
                'status' => 1,
                'message' => "Retry driver assignment job dispatched for order {$id}. Check logs for progress.",
                'data' => [
                    'order_id' => (int) $id,
                    'max_attempts' => RetryDeliveryBoyAssignmentJob::maxAttempts(),
                    'retry_delay_seconds' => RetryDeliveryBoyAssignmentJob::offerTimeoutSeconds(),
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Error dispatching test retry driver job: ' . $e->getMessage());
            return CommonHelper::responseError("Something went wrong: " . $e->getMessage());
        }
    }

    /**
     * Get human-readable label for notification status
     *
     * @param string $status
     * @return string
     */
    private function getNotificationStatusLabel($status)
    {
        $labels = [
            'sent' => 'Sent',
            'accepted' => 'Accepted',
            'expired' => 'Expired',
            'failed' => 'Failed'
        ];

        return $labels[$status] ?? ucfirst($status);
    }

    /**
     * Live orders whose driver has stopped sending GPS.
     * A dead or switched-off phone keeps the order "in progress" forever, so admin
     * needs to see it before the customer calls.
     */
    public function stuckOrders(Request $request)
    {
        try {
            $minutes = (int) $request->input('minutes', 10);
            if ($minutes < 1) {
                $minutes = 10;
            }

            $cutoff = now()->subMinutes($minutes);

            // Latest GPS ping per driver
            $lastPing = DB::table('delivery_boy_location_history')
                ->select('delivery_boy_id', DB::raw('MAX(tracked_at) as last_tracked_at'))
                ->groupBy('delivery_boy_id');

            $orders = DB::table('orders')
                ->leftJoin('delivery_boys', 'delivery_boys.id', '=', 'orders.delivery_boy_id')
                ->leftJoinSub($lastPing, 'ping', function ($join) {
                    $join->on('ping.delivery_boy_id', '=', 'orders.delivery_boy_id');
                })
                ->leftJoin('users', 'users.id', '=', 'orders.user_id')
                ->whereNotNull('orders.delivery_boy_id')
                ->where('orders.delivery_boy_id', '>', 0)
                ->whereNotIn('orders.active_status', [
                    OrderStatusList::$delivered,
                    OrderStatusList::$cancelled,
                    OrderStatusList::$returned,
                ])
                ->whereNull('orders.deleted_at')
                ->where(function ($q) use ($cutoff) {
                    $q->whereNull('ping.last_tracked_at')
                      ->orWhere('ping.last_tracked_at', '<', $cutoff);
                })
                ->select(
                    'orders.id as order_id',
                    'orders.active_status',
                    'orders.created_at as order_created_at',
                    'orders.payment_method',
                    'orders.total',
                    'users.name as customer_name',
                    'users.mobile as customer_mobile',
                    'delivery_boys.id as driver_id',
                    'delivery_boys.name as driver_name',
                    'delivery_boys.mobile as driver_mobile',
                    'delivery_boys.is_available',
                    'delivery_boys.is_problematic',
                    'ping.last_tracked_at'
                )
                ->orderBy('orders.id', 'DESC')
                ->get();

            $now = now();

            $data = $orders->map(function ($row) use ($now) {
                $minutesSincePing = $row->last_tracked_at
                    ? $now->diffInMinutes(\Carbon\Carbon::parse($row->last_tracked_at))
                    : null;

                return [
                    'order_id'           => $row->order_id,
                    'order_number'       => CommonHelper::formatOrderNumber($row->order_id),
                    'active_status'      => $row->active_status,
                    'order_created_at'   => $row->order_created_at,
                    'payment_method'     => $row->payment_method,
                    'total'              => $row->total,
                    'customer_name'      => $row->customer_name,
                    'customer_mobile'    => $row->customer_mobile,
                    'driver_id'          => $row->driver_id,
                    'driver_name'        => $row->driver_name,
                    'driver_mobile'      => $row->driver_mobile,
                    'driver_is_available'=> $row->is_available,
                    'driver_is_problematic' => $row->is_problematic,
                    'last_tracked_at'    => $row->last_tracked_at,
                    'minutes_since_ping' => $minutesSincePing,
                ];
            });

            return CommonHelper::responseWithData($data, $data->count());
        } catch (\Exception $e) {
            Log::error('Stuck Orders Error: ', [
                'message' => $e->getMessage(),
                'trace'   => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch stuck orders.');
        }
    }

    /**
     * Stores involved in a cancelled order, with what has already been paid to them.
     * Used by the "pay store for cancelled order" screen — the store cooked the food,
     * so Zenfoo still owes them even though the order was cancelled.
     */
    public function cancelledOrderStores(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $orderId = $request->order_id;
        $order = Order::find($orderId);

        if (!$order) {
            return CommonHelper::responseError('Order not found.');
        }

        if ($order->active_status != 7) {
            return CommonHelper::responseError('This order is not cancelled.');
        }

        $rows = DB::table('cancelled_order_seller_tracking')
            ->leftJoin('sellers', 'sellers.id', '=', 'cancelled_order_seller_tracking.seller_id')
            ->where('cancelled_order_seller_tracking.order_id', $orderId)
            ->select(
                'cancelled_order_seller_tracking.seller_id',
                'cancelled_order_seller_tracking.store_id',
                'cancelled_order_seller_tracking.status as tracking_status',
                'cancelled_order_seller_tracking.is_driver_picked',
                'sellers.store_name'
            )
            ->get()
            ->unique('seller_id')
            ->values();

        $paid = SellerWalletTransaction::where('order_id', $orderId)
            ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION, SellerWalletTransaction::TYPE_ADJUSTMENT])
            ->get()
            ->keyBy('seller_id');

        $data = $rows->map(function ($row) use ($paid) {
            $txn = $paid->get($row->seller_id);
            return [
                'seller_id'       => $row->seller_id,
                'store_id'        => $row->store_id,
                'store_name'      => $row->store_name,
                'tracking_status' => $row->tracking_status,
                'is_driver_picked'=> $row->is_driver_picked,
                'already_paid'    => $txn ? true : false,
                'paid_amount'     => $txn ? $txn->amount : null,
                'paid_type'       => $txn ? $txn->type : null,
            ];
        });

        return CommonHelper::responseWithData($data, $data->count());
    }

    /**
     * Pay a store for an order that was cancelled after the food was already made.
     * Creates a normal seller wallet credit, so it flows through the usual payout cycle.
     */
    public function payStoreForCancelledOrder(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'order_id'  => 'required|integer',
                'seller_id' => 'required|integer|exists:sellers,id',
                'amount'    => 'required|numeric|min:0.01',
                'note'      => 'nullable|string|max:500',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $orderId  = $request->order_id;
            $sellerId = $request->seller_id;
            $amount   = round(floatval($request->amount), 2);

            $order = Order::find($orderId);

            if (!$order) {
                return CommonHelper::responseError('Order not found.');
            }

            if ($order->active_status != 7) {
                return CommonHelper::responseError('This order is not cancelled. Use the normal settlement instead.');
            }

            $alreadyPaid = SellerWalletTransaction::where('order_id', $orderId)
                ->where('seller_id', $sellerId)
                ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION, SellerWalletTransaction::TYPE_ADJUSTMENT])
                ->first();

            if ($alreadyPaid) {
                return CommonHelper::responseError('This store has already been paid for this order (transaction #' . $alreadyPaid->id . ').');
            }

            $seller = Seller::find($sellerId);

            if (!$seller) {
                return CommonHelper::responseError('Store not found.');
            }

            DB::beginTransaction();

            $balanceBefore = floatval($seller->balance ?? 0);
            $balanceAfter  = $balanceBefore + $amount;

            $transaction = SellerWalletTransaction::create([
                'seller_id'      => $seller->id,
                'order_id'       => $orderId,
                'type'           => SellerWalletTransaction::TYPE_ADJUSTMENT,
                'amount'         => $amount,
                'balance_before' => $balanceBefore,
                'balance_after'  => $balanceAfter,
                'reference_type' => SellerWalletTransaction::REF_ADJUSTMENT,
                'reference_id'   => $orderId,
                'message'        => 'Cancelled order #' . $orderId . ' - paid by Zenfoo (food was already prepared)',
                'admin_note'     => $request->note,
                'status'         => 1,
                'processed_by'   => auth()->user()->id ?? null,
                'is_paid_to_seller' => false,
            ]);

            $seller->balance = $balanceAfter;
            $seller->save();

            DB::commit();

            Log::info('Store paid for cancelled order', [
                'order_id'       => $orderId,
                'seller_id'      => $sellerId,
                'amount'         => $amount,
                'transaction_id' => $transaction->id,
                'processed_by'   => auth()->user()->id ?? null,
            ]);

            return CommonHelper::responseSuccess('Store paid ' . number_format($amount, 2) . ' for cancelled order #' . $orderId . '.');
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Pay Store For Cancelled Order Error: ', [
                'order_id' => $request->order_id ?? null,
                'message'  => $e->getMessage(),
                'trace'    => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to pay the store. Please try again.');
        }
    }

    /**
     * Reason list for the admin cancel popup.
     */
    public function cancelReasons()
    {
        $reasons = [];
        foreach (Order::$cancelReasons as $value => $label) {
            $reasons[] = [
                'value' => $value,
                'label' => $label,
                'allowed_after_handover' => in_array($value, Order::$cancelReasonsAllowedAfterHandover, true),
                'refund_to_wallet'       => in_array($value, Order::$cancelReasonsRefundedToWallet, true),
            ];
        }

        return CommonHelper::responseWithData($reasons, count($reasons));
    }

    public function adminCancelOrder(Request $request)
    {
        try {
            Log::info('adminCancelOrder: [STEP 1] Request received', [
                'request_data' => $request->all()
            ]);

            $validator = Validator::make($request->all(), [
                'order_id' => 'required|integer',
                'reason'   => 'required|string|in:' . implode(',', array_keys(Order::$cancelReasons)),
                'reason_note' => 'nullable|string|max:1000',
            ]);

            if ($validator->fails()) {
                Log::warning('adminCancelOrder: [STEP 1] Validation failed', [
                    'errors' => $validator->errors()->toArray()
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            $orderId     = $request->order_id;
            $reason      = $request->reason;
            $reasonNote  = $request->reason_note;
            $refundToWallet = in_array($reason, Order::$cancelReasonsRefundedToWallet, true);
            $cancelledByAdminId = auth()->user()->id ?? null;

            $order = Order::find($orderId);

            if (!$order) {
                Log::warning('adminCancelOrder: [STEP 2] Order not found', [
                    'order_id' => $orderId
                ]);
                return CommonHelper::responseError('Order not found.');
            }

            Log::info('adminCancelOrder: [STEP 2] Order found', [
                'order_id' => $orderId,
                'payment_method' => $order->payment_method,
                'active_status' => $order->active_status
            ]);

            if ($order->active_status == 7) {
                Log::warning('adminCancelOrder: [STEP 2] Order is already cancelled', [
                    'order_id' => $orderId
                ]);
                return CommonHelper::responseError('Order is already cancelled.');
            }

            // Block cancellation only if any seller has already handed to delivery partner
            $givenToDriver = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('status', 'given_to_delivery_partner')
                ->first();

            if ($givenToDriver && !in_array($reason, Order::$cancelReasonsAllowedAfterHandover, true)) {
                Log::warning('adminCancelOrder: [STEP 2] Cancellation blocked — already handed to delivery partner', [
                    'order_id'  => $orderId,
                    'seller_id' => $givenToDriver->seller_id,
                    'status'    => $givenToDriver->status,
                    'reason'    => $reason,
                ]);
                return CommonHelper::responseError('Order cannot be cancelled as it has already been handed to the delivery partner.');
            }

            if ($givenToDriver) {
                Log::info('adminCancelOrder: [STEP 2] Order already handed to delivery partner, but cancellation allowed for this reason', [
                    'order_id'  => $orderId,
                    'seller_id' => $givenToDriver->seller_id,
                    'reason'    => $reason,
                ]);
            }

            Log::info('adminCancelOrder: [STEP 2] Pre-checks passed — order not cancelled, seller not preparing', [
                'order_id'      => $orderId,
                'active_status' => $order->active_status,
                'payment_method'=> $order->payment_method,
            ]);

            // [STEP 2.5] Check product-level cancel policy using product_ids sent from the frontend
            // The frontend (ViewOrder.vue) already has all items loaded, so we reuse that data
            // Skipped for reasons that are allowed after handover (e.g. driver issue) — the failure
            // is on Zenfoo's side, so the per-product cancellable window must not block the admin.
            $skipProductPolicy = in_array($reason, Order::$cancelReasonsAllowedAfterHandover, true);

            if ($skipProductPolicy) {
                Log::info('adminCancelOrder: [STEP 2.5] Product cancel policy skipped for this reason', [
                    'order_id' => $orderId,
                    'reason'   => $reason,
                ]);
            }

            $frontendProductIds = $skipProductPolicy ? [] : array_values(array_unique(array_filter(
                array_map('intval', $request->input('product_ids', []))
            )));

            if (!empty($frontendProductIds)) {
                $productIds = $frontendProductIds;
                Log::info('adminCancelOrder: [STEP 2.5] Product IDs received from frontend', [
                    'order_id'    => $orderId,
                    'source'      => 'frontend',
                    'product_ids' => $productIds,
                    'count'       => count($productIds),
                ]);
            } else {
                // Fallback: derive product_ids from order_items table
                $productIds = DB::table('order_items')
                    ->join('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                    ->where('order_items.order_id', $orderId)
                    ->pluck('product_variants.product_id')
                    ->unique()->filter()->values()->toArray();
                Log::info('adminCancelOrder: [STEP 2.5] Product IDs derived from DB (frontend did not send them)', [
                    'order_id'    => $orderId,
                    'source'      => 'db_fallback',
                    'product_ids' => $productIds,
                    'count'       => count($productIds),
                ]);
            }

            $policyService = new ProductOrderPolicyService();
            foreach (($skipProductPolicy ? [] : $productIds) as $productId) {
                $policyResult = $policyService->checkCancelPolicy(
                    (int) $productId,
                    (int) $order->active_status
                );
                if ($policyResult['can_cancel_now']) {
                    Log::info('adminCancelOrder: [STEP 2.5] Product cancel policy — PASSED', [
                        'order_id'   => $orderId,
                        'product_id' => $productId,
                        'product'    => $policyResult['product_name'] ?? $productId,
                        'reason'     => $policyResult['reason'],
                    ]);
                } else {
                    Log::warning('adminCancelOrder: [STEP 2.5] Product cancel policy — BLOCKED', [
                        'order_id'      => $orderId,
                        'product_id'    => $productId,
                        'product'       => $policyResult['product_name'] ?? $productId,
                        'cancellable'   => $policyResult['cancellable'],
                        'till_status'   => $policyResult['till_status'],
                        'order_status'  => $policyResult['current_order_status'],
                        'reason'        => $policyResult['reason'],
                    ]);
                    return CommonHelper::responseError(
                        'This order cannot be cancelled. Due to product "' . ($policyResult['product_name'] ?? "ID:{$productId}") . '": ' . $policyResult['reason']
                    );
                }
            }

            Log::info('adminCancelOrder: [STEP 2.5] All product cancel policies passed — proceeding to DB transaction', [
                'order_id'      => $orderId,
                'products_checked' => count($productIds),
            ]);

            DB::beginTransaction();
            Log::info('adminCancelOrder: [STEP 3] Transaction started', ['order_id' => $orderId]);

            $refundResult = null;
            $paymentMethod = strtolower($order->payment_method ?? '');
            // Amount the customer paid online that must go back to their wallet instead of the gateway.
            $onlinePaidToWallet = 0.0;

            Log::info('adminCancelOrder: [STEP 4] Checking payment method', [
                'order_id' => $orderId,
                'payment_method' => $paymentMethod,
                'reason' => $reason,
                'refund_to_wallet' => $refundToWallet,
            ]);

            if ($paymentMethod !== 'cod') {
                Log::info('adminCancelOrder: [STEP 5] Non-COD payment, looking for transaction', [
                    'order_id' => $orderId
                ]);

                $transaction = Transaction::where('order_id', $orderId)
                    ->where('status', Transaction::$statusSuccess)
                    ->first();

                if ($transaction && $transaction->txn_id) {
                    Log::info('adminCancelOrder: [STEP 6] Transaction found', [
                        'order_id' => $orderId,
                        'transaction_id' => $transaction->id,
                        'txn_id' => $transaction->txn_id,
                        'type' => $transaction->type,
                        'amount' => $transaction->amount
                    ]);

                    $refundAmount = $transaction->amount ?? 0;

                    if ($refundAmount > 0) {
                        if ($refundToWallet) {
                            // Policy: this reason is settled in the customer wallet, not through the
                            // payment gateway. Nothing is sent to PhonePe; the credit happens at STEP 11.6.
                            $onlinePaidToWallet = (float) $refundAmount;

                            Log::info('adminCancelOrder: [STEP 7] Gateway refund skipped — amount will be credited to customer wallet', [
                                'order_id' => $orderId,
                                'reason' => $reason,
                                'amount' => $onlinePaidToWallet,
                                'payment_type' => $transaction->type,
                            ]);
                        } elseif (strtolower($transaction->type) === 'phonepe') {
                            Log::info('adminCancelOrder: [STEP 7] Initiating PhonePe refund', [
                                'order_id' => $orderId,
                                'txn_id' => $transaction->txn_id,
                                'refund_amount' => $refundAmount
                            ]);

                            $phonePeRefundService = new PhonePeRefundService();
                            $refundResult = $phonePeRefundService->initiateRefund(
                                $transaction->txn_id,
                                $refundAmount,
                                $orderId
                            );

                            Log::info('adminCancelOrder: [STEP 8] PhonePe refund response', [
                                'order_id' => $orderId,
                                'refund_result' => $refundResult
                            ]);

                            if (!$refundResult['success']) {
                                DB::rollBack();
                                Log::error('adminCancelOrder: [STEP 8] PhonePe refund failed - Rolling back', [
                                    'order_id' => $orderId,
                                    'error' => $refundResult['error'] ?? 'Unknown error',
                                    'refund_result' => $refundResult
                                ]);
                                return CommonHelper::responseError('Order cancellation failed: Unable to process refund. Please try again or contact support.');
                            }

                            Log::info('adminCancelOrder: [STEP 9] PhonePe refund successful', [
                                'order_id' => $orderId,
                                'refund_transaction_id' => $refundResult['refund_transaction_id'] ?? null
                            ]);

                            $transaction->is_refunded = 1;
                            $transaction->refund_transaction_id = $refundResult['refund_transaction_id'] ?? null;
                            $transaction->refund_amount = $refundAmount;
                            $transaction->refunded_at = now();
                            $transaction->save();

                            Log::info('adminCancelOrder: [STEP 9.1] Transaction updated with refund details', [
                                'order_id' => $orderId,
                                'transaction_id' => $transaction->id,
                                'refund_transaction_id' => $transaction->refund_transaction_id,
                                'refund_amount' => $transaction->refund_amount
                            ]);
                        } else {
                            Log::info('adminCancelOrder: [STEP 7] Non-PhonePe payment type, skipping refund API', [
                                'order_id' => $orderId,
                                'payment_type' => $transaction->type
                            ]);
                        }
                    } else {
                        Log::warning('adminCancelOrder: [STEP 6] Refund amount is zero or negative', [
                            'order_id' => $orderId,
                            'refund_amount' => $refundAmount
                        ]);
                    }
                } else {
                    Log::warning('adminCancelOrder: [STEP 5] No successful transaction found for order', [
                        'order_id' => $orderId,
                        'transaction_exists' => $transaction ? true : false,
                        'txn_id_exists' => $transaction ? ($transaction->txn_id ? true : false) : false
                    ]);
                }
            } else {
                Log::info('adminCancelOrder: [STEP 5] COD payment, no refund needed', [
                    'order_id' => $orderId
                ]);
            }

            // [STEP 9.5] Pay the stores that had already cooked the food. Must run before the
            // tracking rows below are archived and deleted — the settlement reads them.
            $cancelSettlement = SellerOrderSettlementService::settleCookedSellersForCancelledOrder($orderId);

            Log::info('adminCancelOrder: [STEP 9.5] Store settlement for cancelled order', [
                'order_id'    => $orderId,
                'success'     => $cancelSettlement['success'],
                'message'     => $cancelSettlement['message'],
                'settlements' => count($cancelSettlement['settlements'] ?? []),
            ]);

            $trackingRows = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get();

            // Kept for the notifications below — these rows are deleted a few lines further down.
            $affectedSellerIds = $trackingRows->pluck('seller_id')->filter()->unique()->values()->toArray();

            // Remove the ticket from the vendor app while the tracking rows still exist:
            // deleteOrderSellerTracking reads this same table to find which sellers hold
            // the order, so calling it after the delete below would find nothing.
            try {
                FirestoreOrderSellerTrackingService::deleteOrderSellerTracking((int) $orderId);
            } catch (\Exception $sellerTrackingException) {
                Log::error('adminCancelOrder: [STEP 10] Failed to remove the order from the vendor app', [
                    'order_id' => $orderId,
                    'error'    => $sellerTrackingException->getMessage(),
                ]);
            }

            if ($trackingRows->isNotEmpty()) {
                $now = now();
                $archive = $trackingRows->map(function ($row) use ($now) {
                    return [
                        'original_tracking_id' => $row->id,
                        'order_id'             => $row->order_id,
                        'seller_id'            => $row->seller_id,
                        'store_id'             => $row->store_id,
                        'store_location_id'    => $row->store_location_id,
                        'is_zenfoo_store'      => $row->is_zenfoo_store,
                        'is_driver_picked'     => $row->is_driver_picked,
                        'driver_captured_images_when_marked_as_pickup' => $row->driver_captured_images_when_marked_as_pickup,
                        'status'                      => $row->status,
                        'otp'                         => $row->otp,
                        'is_seller_started_preparing' => $row->is_seller_started_preparing,
                        'delayed_time_in_min'         => $row->delayed_time_in_min,
                        'driver_arrived_at_seller'    => $row->driver_arrived_at_seller,
                        'prep_time'                   => $row->prep_time,
                        'cancelled_by'                => 'admin',
                        'cancelled_at'                => $now,
                        'created_at'                  => $now,
                        'updated_at'                  => $now,
                    ];
                })->toArray();

                DB::table('cancelled_order_seller_tracking')->insert($archive);

                Log::info('adminCancelOrder: [STEP 10] Archived tracking records to cancelled_order_seller_tracking', [
                    'order_id'       => $orderId,
                    'archived_rows'  => count($archive),
                    'original_ids'   => array_column($archive, 'original_tracking_id'),
                    'seller_ids'     => array_column($archive, 'seller_id'),
                ]);
            } else {
                Log::info('adminCancelOrder: [STEP 10] No tracking rows found in order_seller_status_tracking — nothing to archive', [
                    'order_id' => $orderId,
                ]);
            }

            $deletedRows = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->delete();

            Log::info('adminCancelOrder: [STEP 10.1] Deleted order_seller_status_tracking records', [
                'order_id'     => $orderId,
                'deleted_rows' => $deletedRows,
            ]);

            Log::info('adminCancelOrder: [STEP 11] Updating order status to cancelled (7)', [
                'order_id'   => $orderId,
                'old_status' => $order->active_status,
                'new_status' => 7,
            ]);

            $order->active_status = 7;
            $order->cancellation_reason   = $reason;
            $order->cancellation_note     = $reasonNote;
            $order->cancelled_by_admin_id = $cancelledByAdminId;
            $order->cancelled_at          = now();
            $order->save();

            Log::info('adminCancelOrder: [STEP 11] Order status saved successfully', [
                'order_id'   => $orderId,
                'active_status' => $order->active_status,
                'reason' => $reason,
                'cancelled_by_admin_id' => $cancelledByAdminId,
            ]);

            $totalCreditedToWallet = 0.0;

            // [STEP 11.5] Refund wallet amount if wallet was used for this order
            if ($order->wallet_balance > 0) {
                $user = User::find($order->user_id);
                if ($user) {
                    $currentBalance = $user->balance;
                    $walletRefund = floatval($order->wallet_balance);
                    $newBalance = $currentBalance + $walletRefund;

                    CommonHelper::updateUserWalletBalance($newBalance, $user->id);
                    $walletTxn = CommonHelper::addWalletTransaction($orderId, 0, $user->id, 'credit', $walletRefund, 'Refund - Order Cancelled by Admin', 1, $order->payment_method);
                    if ($walletTxn && $cancelledByAdminId) {
                        $walletTxn->created_by_admin_id = $cancelledByAdminId;
                        $walletTxn->save();
                    }

                    // Reset wallet_balance on order so it's not refunded again
                    $order->wallet_balance = 0;
                    $order->save();

                    $totalCreditedToWallet += $walletRefund;

                    Log::info('adminCancelOrder: [STEP 11.5] Wallet amount refunded', [
                        'order_id'        => $orderId,
                        'user_id'         => $user->id,
                        'wallet_refund'   => $walletRefund,
                        'old_balance'     => $currentBalance,
                        'new_balance'     => $newBalance,
                    ]);
                }
            }

            // [STEP 11.6] Credit the online-paid amount to the wallet for reasons settled in wallet
            // (e.g. driver issue). No gateway refund was sent for this order.
            if ($onlinePaidToWallet > 0) {
                // Re-read the customer: STEP 11.5 may have already changed the balance in the DB.
                $user = User::find($order->user_id);
                if ($user) {
                    $currentBalance = floatval($user->balance);
                    $newBalance = $currentBalance + $onlinePaidToWallet;

                    CommonHelper::updateUserWalletBalance($newBalance, $user->id);
                    $onlineTxn = CommonHelper::addWalletTransaction(
                        $orderId,
                        0,
                        $user->id,
                        'credit',
                        $onlinePaidToWallet,
                        'Refund to wallet - Order cancelled by admin (' . (Order::$cancelReasons[$reason] ?? $reason) . ')',
                        1,
                        $order->payment_method
                    );
                    if ($onlineTxn && $cancelledByAdminId) {
                        $onlineTxn->created_by_admin_id = $cancelledByAdminId;
                        $onlineTxn->save();
                    }

                    $totalCreditedToWallet += $onlinePaidToWallet;

                    Log::info('adminCancelOrder: [STEP 11.6] Online paid amount credited to wallet', [
                        'order_id'    => $orderId,
                        'user_id'     => $user->id,
                        'amount'      => $onlinePaidToWallet,
                        'old_balance' => $currentBalance,
                        'new_balance' => $newBalance,
                        'reason'      => $reason,
                    ]);
                } else {
                    DB::rollBack();
                    Log::error('adminCancelOrder: [STEP 11.6] Customer not found — cannot credit wallet, rolling back', [
                        'order_id' => $orderId,
                        'user_id'  => $order->user_id,
                    ]);
                    return CommonHelper::responseError('Order cancellation failed: customer account not found for wallet refund.');
                }
            }

            $order->refund_mode = $totalCreditedToWallet > 0
                ? 'wallet'
                : (($refundResult && $refundResult['success']) ? 'gateway' : 'none');
            $order->refund_to_wallet_amount = $totalCreditedToWallet > 0 ? $totalCreditedToWallet : null;
            $order->save();

            DB::commit();
            Log::info('adminCancelOrder: [STEP 12] Transaction committed successfully', [
                'order_id' => $orderId
            ]);

            // [STEP 12.5] Take the order off every phone. The apps read from Firestore, not
            // MySQL, so without this the driver keeps the ride on screen, other drivers keep
            // the offer popup, the store keeps the ticket, and the retry chain keeps offering it.
            try {
                RetryDeliveryBoyAssignmentJob::cancelExistingForOrder((int) $orderId);
                FirestoreDeliveryBoyService::removePendingDeliveryAssignment((int) $orderId);
                FirestoreDeliveryBoyService::clearOrderOfferFromOtherDeliveryBoys((int) $orderId);

                if (!empty($order->delivery_boy_id)) {
                    // The app watches last_order_event and shows a dialog before it leaves the
                    // delivery screen, so the order is explained instead of vanishing. Written
                    // before current_order is cleared, same order as the reassign flow.
                    FirestoreDeliveryBoyService::setLastOrderEvent((int) $order->delivery_boy_id, [
                        'type'     => 'cancelled',
                        'order_id' => $orderId,
                        'title'    => 'Order Cancelled',
                        'message'  => "Order #{$orderId} has been cancelled by admin. "
                            . "Please stop the delivery. "
                            . "Contact support if you have any questions.",
                        'created_at' => now()->toIso8601String(),
                    ]);

                    FirestoreDeliveryBoyService::removeCurrentOrderFromDeliveryBoy(
                        (int) $order->delivery_boy_id,
                        (int) $orderId
                    );
                }

                // Tell the driver on his phone. Clearing the screen without a word looks
                // like the app lost the order.
                if (!empty($order->delivery_boy_id)) {
                    DriverNotificationService::send(
                        (int) $order->delivery_boy_id,
                        'Order Cancelled',
                        'Order #' . $orderId . ' has been cancelled by admin. Please stop the delivery.',
                        '',
                        'order',
                        null,
                        [
                            'order_id' => (string) $orderId,
                            'action'   => 'order_cancelled',
                            'reason'   => (string) $reason,
                        ]
                    );
                }

                // Tell the stores too — their ticket disappears at the same moment.
                if (!empty($affectedSellerIds)) {
                    SellerNotificationService::sendToMultiple(
                        $affectedSellerIds,
                        'Order Cancelled',
                        'Order #' . $orderId . ' has been cancelled by admin. Please stop preparing it.',
                        '',
                        'order',
                        $orderId,
                        [
                            'order_id' => (string) $orderId,
                            'action'   => 'order_cancelled',
                            'reason'   => (string) $reason,
                        ]
                    );
                }

                Log::info('adminCancelOrder: [STEP 12.5] Order withdrawn from driver and store apps', [
                    'order_id'        => $orderId,
                    'delivery_boy_id' => $order->delivery_boy_id,
                ]);
            } catch (\Exception $cleanupException) {
                Log::error('adminCancelOrder: [STEP 12.5] Failed to withdraw the order from the apps', [
                    'order_id' => $orderId,
                    'error'    => $cleanupException->getMessage(),
                ]);
            }

            try {
                $orderStatusResult = FirestoreOrderETAService::updateOrderStatus(
                    $orderId,
                    'Order Cancelled',
                    'Your order has been cancelled'
                );
                Log::info('adminCancelOrder: [STEP 13] Firestore order status updated to Cancelled', [
                    'order_id' => $orderId,
                    'result' => $orderStatusResult
                ]);
            } catch (\Exception $firestoreException) {
                Log::error('adminCancelOrder: [STEP 13] Failed to update Firestore order status', [
                    'order_id' => $orderId,
                    'error' => $firestoreException->getMessage()
                ]);
            }

            $successMessage = 'Order cancelled successfully.';
            if ($totalCreditedToWallet > 0) {
                $successMessage = 'Order cancelled successfully. ' . number_format($totalCreditedToWallet, 2) . ' has been credited to the customer wallet.';
            } elseif ($refundResult && $refundResult['success']) {
                $successMessage = 'Order cancelled successfully. Refund has been initiated and will be credited to the customer\'s account.';
            }

            Log::info('adminCancelOrder: [STEP 14] Order cancellation completed', [
                'order_id' => $orderId,
                'refund_initiated' => $refundResult && $refundResult['success'] ? true : false,
                'message' => $successMessage
            ]);

            return CommonHelper::responseSuccess($successMessage);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('adminCancelOrder: Exception occurred', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
                'order_id' => $request->order_id ?? null
            ]);
            return CommonHelper::responseError('Failed to cancel order.');
        }
    }

    /**
     * Search delivery boy by phone number for emergency driver change
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function searchDriverByPhone(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string',
        ], [
            'phone.required' => 'Phone number is required.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Search for delivery boy by phone number (active drivers only)
            $deliveryBoy = DeliveryBoy::where('mobile', $request->phone)
                ->where('status', 1) // Only active drivers
                ->select('id', 'name', 'mobile', 'status', 'is_available')
                ->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('No active driver found with this phone number');
            }

            // Get current orders count for this driver
            $currentOrdersCount = Order::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNotIn('active_status', [6, 7, 8]) // Not delivered, cancelled, or returned
                ->count();

            $driverData = [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'phone' => $deliveryBoy->mobile,
                'status' => $deliveryBoy->status,
                'is_available' => $deliveryBoy->is_available,
                'current_orders_count' => $currentOrdersCount
            ];

            return CommonHelper::responseSuccessWithData('Driver found', $driverData);

        } catch (\Exception $e) {
            Log::error('searchDriverByPhone: Exception occurred', [
                'error' => $e->getMessage(),
                'phone' => $request->phone ?? null
            ]);
            return CommonHelper::responseError('Failed to search driver');
        }
    }

    /**
     * Find nearby drivers to current driver for emergency driver change
     * Filters by: online status, no active orders, hand cash limit, and distance radius
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function findNearbyDrivers(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer|exists:orders,id',
            'current_driver_id' => 'required|integer|exists:delivery_boys,id',
            'radius_km' => 'required|numeric|min:0.1|max:50',
        ], [
            'order_id.required' => 'Order ID is required.',
            'order_id.exists' => 'Order not found.',
            'current_driver_id.required' => 'Current driver ID is required.',
            'current_driver_id.exists' => 'Current driver not found.',
            'radius_km.required' => 'Search radius is required.',
            'radius_km.min' => 'Search radius must be at least 0.1 km (100 meters).',
            'radius_km.max' => 'Search radius cannot exceed 50 km.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $orderId = $request->order_id;
            $currentDriverId = $request->current_driver_id;
            $radiusKm = $request->radius_km;
            $radiusMeters = $radiusKm * 1000; // Convert km to meters

            Log::info('findNearbyDrivers: Starting search', [
                'order_id' => $orderId,
                'current_driver_id' => $currentDriverId,
                'radius_km' => $radiusKm,
                'radius_meters' => $radiusMeters
            ]);

            // Get current driver details
            $currentDriver = DeliveryBoy::find($currentDriverId);
            if (!$currentDriver) {
                return CommonHelper::responseError('Current driver not found');
            }

            // Get current driver's latest location from delivery_boy_location_history
            $currentDriverLocation = DB::table('delivery_boy_location_history')
                ->where('delivery_boy_id', $currentDriverId)
                ->orderBy('tracked_at', 'desc')
                ->first();

            if (!$currentDriverLocation || !$currentDriverLocation->latitude || !$currentDriverLocation->longitude) {
                return CommonHelper::responseError('Current driver location not available. Driver may not have location tracking enabled.');
            }

            $currentLat = (float) $currentDriverLocation->latitude;
            $currentLon = (float) $currentDriverLocation->longitude;

            Log::info('findNearbyDrivers: Current driver location', [
                'driver_id' => $currentDriverId,
                'latitude' => $currentLat,
                'longitude' => $currentLon,
                'tracked_at' => $currentDriverLocation->tracked_at
            ]);

            // STEP 1: Get base eligible drivers
            // - Active status
            // - Not in gig mode 3+
            // - Online/Available
            // - Not the current driver
            $eligibleDrivers = DeliveryBoy::where('status', 1)
                ->where('is_available', 1) // Online only
                ->where('id', '!=', $currentDriverId) // Exclude current driver
                ->get();

            Log::info('findNearbyDrivers: Step 1 - Base filter', [
                'total_drivers' => $eligibleDrivers->count()
            ]);

            // STEP 2: Filter out drivers with active orders
            $completedStatuses = [6, 7, 8];
            $eligibleDrivers = $eligibleDrivers->filter(function ($driver) use ($completedStatuses) {
                return !DB::table('orders')
                    ->where('delivery_boy_id', $driver->id)
                    ->whereNotIn('active_status', $completedStatuses)
                    ->exists();
            })->values();

            Log::info('findNearbyDrivers: Step 2 - No active orders filter', [
                'remaining_drivers' => $eligibleDrivers->count()
            ]);

            // STEP 3: Filter by hand cash limit
            $driversArray = $eligibleDrivers->map(fn($d) => ['id' => $d->id, 'name' => $d->name])->toArray();
            $driversWithinCashLimit = HandCashLimitService::filterByHandCashLimit($driversArray);
            $eligibleDriverIds = array_column($driversWithinCashLimit, 'id');

            $eligibleDrivers = $eligibleDrivers->filter(function ($driver) use ($eligibleDriverIds) {
                return in_array($driver->id, $eligibleDriverIds);
            })->values();

            Log::info('findNearbyDrivers: Step 3 - Hand cash limit filter', [
                'remaining_drivers' => $eligibleDrivers->count()
            ]);

            // STEP 4: Get location for each driver and calculate distance
            $driverIds = $eligibleDrivers->pluck('id')->toArray();

            $latestLocations = DB::table('delivery_boy_location_history')
                ->whereIn('delivery_boy_id', $driverIds)
                ->select('delivery_boy_id', 'latitude', 'longitude', 'tracked_at')
                ->orderBy('tracked_at', 'desc')
                ->get()
                ->unique('delivery_boy_id')
                ->keyBy('delivery_boy_id');

            $nearbyDrivers = [];

            foreach ($eligibleDrivers as $driver) {
                // Skip if no location data
                if (!isset($latestLocations[$driver->id])) {
                    Log::info('findNearbyDrivers: Driver skipped - no location', [
                        'driver_id' => $driver->id,
                        'driver_name' => $driver->name
                    ]);
                    continue;
                }

                $loc = $latestLocations[$driver->id];
                $driverLat = (float) $loc->latitude;
                $driverLon = (float) $loc->longitude;

                // Calculate distance using haversine formula
                $distanceKm = StoreDistanceService::haversine($currentLat, $currentLon, $driverLat, $driverLon);
                $distanceMeters = $distanceKm * 1000;

                // Filter by radius
                if ($distanceMeters <= $radiusMeters) {
                    // Format distance display
                    $distanceDisplay = $distanceMeters < 1000
                        ? round($distanceMeters) . 'm away'
                        : round($distanceKm, 1) . 'km away';

                    $nearbyDrivers[] = [
                        'id' => $driver->id,
                        'name' => $driver->name,
                        'phone' => $driver->mobile,
                        'latitude' => $driverLat,
                        'longitude' => $driverLon,
                        'distance_meters' => round($distanceMeters),
                        'distance_km' => round($distanceKm, 2),
                        'distance_display' => $distanceDisplay,
                        'status' => $driver->status,
                        'is_available' => $driver->is_available,
                        'current_orders_count' => 0,
                        'tracked_at' => $loc->tracked_at
                    ];
                }
            }

            // Sort by distance (nearest first)
            usort($nearbyDrivers, function($a, $b) {
                return $a['distance_meters'] <=> $b['distance_meters'];
            });

            Log::info('findNearbyDrivers: Final results', [
                'order_id' => $orderId,
                'radius_km' => $radiusKm,
                'total_found' => count($nearbyDrivers),
                'driver_ids' => array_column($nearbyDrivers, 'id')
            ]);

            // Get current driver location name using reverse geocoding
            $locationName = CityZoneService::reverseGeocode($currentLat, $currentLon);
            if (empty($locationName)) {
                // Fallback to coordinates if geocoding fails
                $locationName = 'Lat: ' . round($currentLat, 4) . ', Lon: ' . round($currentLon, 4);
            }

            $responseData = [
                'current_driver' => [
                    'id' => $currentDriver->id,
                    'name' => $currentDriver->name,
                    'latitude' => $currentLat,
                    'longitude' => $currentLon,
                    'location_name' => $locationName
                ],
                'nearby_drivers' => $nearbyDrivers,
                'search_radius_km' => $radiusKm,
                'search_radius_meters' => $radiusMeters,
                'total_found' => count($nearbyDrivers)
            ];

            $message = count($nearbyDrivers) > 0
                ? 'Found ' . count($nearbyDrivers) . ' nearby driver(s)'
                : 'No drivers found within ' . $radiusKm . 'km radius';

            return CommonHelper::responseSuccessWithData($message, $responseData);

        } catch (\Exception $e) {
            Log::error('findNearbyDrivers: Exception occurred', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
                'order_id' => $request->order_id ?? null,
                'current_driver_id' => $request->current_driver_id ?? null
            ]);
            return CommonHelper::responseError('Failed to find nearby drivers');
        }
    }

    /**
     * Emergency change driver - reassign order from current driver to new driver
     * Updates both MySQL (orders table) and Firestore (delivery_boys collection)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function emergencyChangeDriver(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer|exists:orders,id',
            'new_delivery_boy_id' => 'required|integer|exists:delivery_boys,id',
        ], [
            'order_id.required' => 'Order ID is required.',
            'order_id.exists' => 'Order not found.',
            'new_delivery_boy_id.required' => 'New delivery boy ID is required.',
            'new_delivery_boy_id.exists' => 'Delivery boy not found.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $orderId = $request->order_id;
            $newDeliveryBoyId = $request->new_delivery_boy_id;

            // Get order details
            $order = Order::find($orderId);

            if (!$order) {
                return CommonHelper::responseError('Order not found');
            }

            // Check if order already has a delivery boy assigned
            if (!$order->delivery_boy_id || $order->delivery_boy_id == 0) {
                return CommonHelper::responseError('No delivery boy currently assigned to this order');
            }

            $oldDeliveryBoyId = $order->delivery_boy_id;

            // Check if trying to assign the same driver
            if ($oldDeliveryBoyId == $newDeliveryBoyId) {
                return CommonHelper::responseError('New driver is same as current driver');
            }

            // Check if order is already delivered or cancelled
            if (in_array($order->active_status, [6, 7, 8])) {
                $statusName = $order->active_status == 6 ? 'delivered' : ($order->active_status == 7 ? 'cancelled' : 'returned');
                return CommonHelper::responseError("Cannot change driver for {$statusName} order");
            }

            // Perform emergency driver change using Firestore service
            $result = FirestoreDeliveryBoyService::emergencyChangeDriver(
                $orderId,
                $oldDeliveryBoyId,
                $newDeliveryBoyId
            );

            if (!$result['success']) {
                return CommonHelper::responseError($result['message']);
            }

            // Get driver names for response
            $oldDriver = DeliveryBoy::find($oldDeliveryBoyId);
            $newDriver = DeliveryBoy::find($newDeliveryBoyId);

            $responseData = [
                'order_id' => $orderId,
                'old_driver' => [
                    'id' => $oldDeliveryBoyId,
                    'name' => $oldDriver->name ?? 'Unknown'
                ],
                'new_driver' => [
                    'id' => $newDeliveryBoyId,
                    'name' => $newDriver->name ?? 'Unknown'
                ],
                'previous_drivers' => $result['data']['previous_drivers'] ?? []
            ];

            return CommonHelper::responseSuccessWithData(
                'Driver changed successfully',
                $responseData
            );

        } catch (\Exception $e) {
            Log::error('emergencyChangeDriver: Exception occurred', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
                'order_id' => $request->order_id ?? null,
                'new_delivery_boy_id' => $request->new_delivery_boy_id ?? null
            ]);
            return CommonHelper::responseError('Failed to change driver');
        }
    }
}