<?php

namespace App\Http\Controllers;

use App\Models\SellerRegistrationHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Helpers\CommonHelper;
use Illuminate\Support\Facades\DB;
use App\Models\Category;
use App\Models\CategoryType;
use App\Models\Order;
use App\Models\OrderStatusList;

use App\Services\MediaUploadService;
use App\Services\FirestoreDeliveryBoyService;
use App\Services\FirestoreOrderSellerTrackingService;
use App\Services\FirestoreOrderETAService;
use App\Services\CustomerNotificationService;
use App\Services\SellerNotificationService;
use App\Services\DriverNotificationService;
use App\Jobs\RetryDeliveryBoyAssignmentJob;

class SellerRegistrationHelperController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function indexWithMeat()
    {
        $helpers = SellerRegistrationHelper::orderBy('id', 'DESC')->get();

        // Collect all store IDs referenced by helpers
        $storeIds = $helpers->pluck('stores')
            ->filter()
            ->map(fn($s) => (int) $s)
            ->unique()
            ->values()
            ->toArray();

        // Check which of the helper store IDs have is_meat = 1
        $meatStoreIds = DB::table('stores')
            ->whereIn('id', $storeIds)
            ->where('is_meat', 1)
            ->pluck('id')
            ->toArray();

        // Fetch all is_meat stores to attach to meat-related helpers
        $allMeatStores = DB::table('stores')
            ->where('is_meat', 1)
            ->get();

        $helpers = $helpers->map(function ($helper) use ($meatStoreIds, $allMeatStores) {
            $storeId = (int) $helper->stores;
            $helper->store_wise_details = in_array($storeId, $meatStoreIds) ? $allMeatStores : null;
            return $helper;
        });

        return CommonHelper::responseWithData($helpers);
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        $helpers = SellerRegistrationHelper::orderBy('id', 'ASC')->get();
        return CommonHelper::responseWithData($helpers);
    }


    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'stores' => 'required|string',
            'categories' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $image = '';
            if($request->hasFile('image')){
                $image = MediaUploadService::uploadWithFullUrl($request->file('image'), 'seller_registration_helper');
            }

            $categories = $request->categories ? json_decode($request->categories, true) : null;

            $helper = SellerRegistrationHelper::create([
                'name' => $request->name,
                'description' => $request->description,
                'img' => $image,
                'stores' => $request->stores,
                'categories' => $categories
            ]);

            return CommonHelper::responseSuccess("Seller Registration Helper created successfully!");
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        $helper = SellerRegistrationHelper::find($id);

        if (!$helper) {
            return CommonHelper::responseError("Seller Registration Helper not found!");
        }

        return CommonHelper::responseWithData($helper);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'stores' => 'required|string',
            'categories' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $helper = SellerRegistrationHelper::find($id);

            if (!$helper) {
                return CommonHelper::responseError("Seller Registration Helper not found!");
            }

            if($request->hasFile('image')){
                // Delete old image if exists
                if ($helper->img) {
                    MediaUploadService::deleteByUrl($helper->img);
                }
                $helper->img = MediaUploadService::uploadWithFullUrl($request->file('image'), 'seller_registration_helper');
            }

            $categories = $request->categories ? json_decode($request->categories, true) : null;

            $helper->update([
                'name' => $request->name,
                'description' => $request->description,
                'stores' => $request->stores,
                'categories' => $categories
            ]);

            return CommonHelper::responseSuccess("Seller Registration Helper updated successfully!");
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        try {
            $helper = SellerRegistrationHelper::find($id);

            if (!$helper) {
                return CommonHelper::responseError("Seller Registration Helper not found!");
            }

            $helper->delete();
            return CommonHelper::responseSuccess("Seller Registration Helper deleted successfully!");
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function getSellersByOrder($id)
    {
        $orderId = $id;

        if (!$orderId) {
            return response()->json([
                'status' => 0,
                'message' => 'order_id is required'
            ], 400);
        }

        $orderItems = DB::table('order_items')
            ->where('order_id', $orderId)
            ->pluck('product_variant_id')
            ->toArray();        

        if (empty($orderItems)) {
            return response()->json([
                'status' => 1,
                'message' => 'No order items found',
                'data' => []
            ]);
        }

        $productIds = DB::table('product_variants')
            ->whereIn('id', $orderItems)
            ->pluck('product_id')
            ->toArray();

        // dd($productIds,$orderItems);
        
        if (empty($productIds)) {
            return response()->json([
                'status' => 1,
                'message' => 'No products found',
                'data' => []
            ]);
        }

        $storeIds = DB::table('products')
            ->whereIn('id', $productIds)
            ->pluck('store_id')
            ->unique()
            ->toArray();

        // dd($storeIds);

        $filteredStoreIds = array_intersect($storeIds, [13, 14]);
        // $filteredStoreIds = [13, 14];

        // dd($filteredStoreIds);

        
        if (empty($filteredStoreIds)) {
            return response()->json([
                'status' => 1,
                'message' => 'Order does not belong to store 13 or 14',
                'data' => []
            ]);
        }

        $sellers = DB::table('sellers')
            ->whereIn('store_id', $filteredStoreIds)
            ->select('id', 'store_name')
            ->get();


        $formatted = [];
        foreach ($sellers as $seller) {
            $formatted[] = [
                'seller_id' => $seller->id,
                'store_name' => $seller->store_name
            ];
        }

        return response()->json([
            'status' => 1,
            'message' => 'Success',
            'data' => $formatted
        ]);
    }


    public function storeSellerSweetHouseCategory(Request $request)
    {

        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = DB::table('sellers')->where('admin_id', $admin->id)->first();
        
        DB::beginTransaction();

        try {
            $imagePath = MediaUploadService::upload(
                $request->file('image'),
                'group/categories/image'
            );

            $categoryId = DB::table('categories')->insertGetId([
                'name'                  => $request->name,
                'subtitle'              => $request->subtitle,
                'image'                 => $imagePath,
                'is_added_by_seller'    => 1,
                'is_sweet_house_store'  => 1,
                'seller_id'             => $seller->id,
                'created_at'            => now(),
                'updated_at'            => now(),
            ]);

            $category = Category::find($categoryId);

            // Insert into sub_category_groups with is_group = 0 and seller_id
            if($seller->store_id == 15){
                DB::table('sub_category_groups')->insert([
                    'name'        => $request->name,
                    'is_group'    => 0,
                    'is_super_mart' => 0,
                    'seller_id'   => $seller->id,
                    'subcategory_ids' => $categoryId,
                    'image'       => $imagePath,
                    'created_at'  => now(),
                    'updated_at'  => now(),
                ]);
            }

            if (!empty($request->types) && is_array($request->types)) {
                foreach ($request->types as $typeName) {
                    CategoryType::create([
                        'name'        => $typeName,
                        'category_id' => $category->id,
                    ]);
                }
            }


            DB::commit();

            return response()->json([
                'status'  => 1,
                'message' => 'Category created successfully',
            ], 200);

        } catch (\Exception $e) {

            DB::rollBack();

            return response()->json([
                'status'  => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function storeCategoryType(Request $request)
    {

        $categoryType = CategoryType::create([
            'name'        => $request->name,
            'category_id' => $request->category_id,
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Category type created successfully',
            'data' => $categoryType
        ]);
    }

    

    public function GetSellerSweetHouseCategory(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = DB::table('sellers')->where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller not found.");
        }

        // Check if store is managed by admin
        $store = DB::table('stores')->where('id', $seller->store_id)->first();
        $isManagedByAdmin = $store && $store->managed_by_admin == 1;

        try {
            // If managed by admin, show categories with seller_id null, otherwise show seller's own categories
            $query = $isManagedByAdmin
                ? Category::whereNull('seller_id')
                : Category::where('seller_id', $seller->id);

            // Search functionality
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', '%' . $search . '%')
                      ->orWhere('slug', 'like', '%' . $search . '%');
                });
            }

            // Filter by status if provided
            if ($request->has('status')) {
                $query->where('status', $request->status);
            }

            // Pagination parameters
            $perPage = $request->input('per_page', 10);
            $page = $request->input('page', 1);

            // Get total count
            $total = $query->count();

            // Get paginated results
            $categories = $query->orderBy('created_at', 'desc')
                ->paginate($perPage, ['*'], 'page', $page);

            // Attach types and image_url
            $data = $categories->items();
            foreach ($data as $c) {
                $types = CategoryType::where('category_id', $c->id)->select('name','id')->get();
                $c->types = $types;
                $c->image_url = $c->image ? url('storage/' . $c->image) : null;
            }

            return response()->json([
                'status' => 1,
                'data'   => [
                    'total' => $total,
                    'per_page' => $perPage,
                    'current_page' => $page,
                    'last_page' => $categories->lastPage(),
                    'data' => $data
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'status'  => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }


    public function updateSellerSweetHouseCategory(Request $request, $id)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = DB::table('sellers')->where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller not found.");
        }

        $category = Category::where('id', $id)
            ->where('seller_id', $seller->id)
            ->first();

        if (!$category) {
            return CommonHelper::responseError("Category not found or does not belong to this seller.");
        }

        DB::beginTransaction();

        try {

            // Upload new image if provided
            if ($request->hasFile('image')) {
                $imagePath = MediaUploadService::upload(
                    $request->file('image'),
                    'group/categories/image'
                );
                $category->image = $imagePath;
            }

            $category->name = $request->name ?? $category->name;
            $category->subtitle = $request->subtitle ?? $category->subtitle;

            // Update corresponding sub_category_groups entry
            if($seller->store_id == 15) {

                DB::table('sub_category_groups')
                    ->where('subcategory_ids', $category->id)
                    ->where('seller_id', $seller->id)
                    ->where('is_group', 0)
                    ->update([
                        'name' => $category->name,
                        'image'=> $category->image,
                        'updated_at' => now(),
                    ]);
            }

            if ($request->has('types')) {
                foreach ($request->types as $typeName) {
                    CategoryType::create([
                        'name'        => $typeName,
                        'category_id' => $category->id,
                    ]);
                }
            }

            $category->save();

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => 'Category updated successfully',
            ], 200);

        } catch (\Exception $e) {

            DB::rollBack();
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }


    public function deleteSellerSweetHouseCategory(Request $request, $id)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = DB::table('sellers')->where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller not found.");
        }

        $category = Category::where('id', $id)
            ->where('seller_id', $seller->id)
            ->first();

        if (!$category) {
            return CommonHelper::responseError("Category not found or does not belong to this seller.");
        }

        DB::beginTransaction();

        try {
            // Delete corresponding sub_category_groups entry
            if($seller->store_id == 15){
                DB::table('sub_category_groups')
                    ->where('subcategory_ids', $category->id)
                    ->where('seller_id', $seller->id)
                    ->where('is_group', 0)
                    ->delete();
            }

            $category->delete();

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => 'Category deleted successfully',
            ], 200);

        } catch (\Exception $e) {

            DB::rollBack();

            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }


    
    public function assignSellerToStore(Request $request)
    {
        $request->validate([
            'order_id'  => 'required|integer',
            'store_id'  => 'required|integer',
            'seller_id' => 'required|integer',
        ]);

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
                \Log::info("Order Seller Assignment - Updated seller for order_id: {$request->order_id}, store_id: {$request->store_id}, seller_id: {$request->seller_id}");
            } else {
                // Insert new record

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
                \Log::info("Order Seller Assignment - Inserted new tracking record for order_id: {$request->order_id}, store_id: {$request->store_id}, seller_id: {$request->seller_id}");
            }

            // Sync order seller tracking data to Firestore
            try {
                \Log::info("Order Seller Assignment - Attempting to sync to Firestore", [
                    'order_id' => $request->order_id,
                    'seller_id' => $request->seller_id,
                    'store_id' => $request->store_id
                ]);

                $firestoreResult = FirestoreOrderSellerTrackingService::syncOrderSellerTracking($request->order_id);

                if ($firestoreResult['success']) {
                    \Log::info("Order Seller Assignment - Synced to Firestore successfully", [
                        'order_id' => $request->order_id,
                        'seller_id' => $request->seller_id,
                        'sellers_count' => $firestoreResult['sellers_count'] ?? 0,
                        'success_count' => $firestoreResult['success_count'] ?? 0
                    ]);
                } else {
                    \Log::warning("Order Seller Assignment - Failed to sync to Firestore", [
                        'order_id' => $request->order_id,
                        'seller_id' => $request->seller_id,
                        'error' => $firestoreResult['message'] ?? 'Unknown error'
                    ]);
                }
            } catch (\Exception $firestoreException) {
                // Log Firestore error but don't fail the seller assignment
                \Log::error("Order Seller Assignment - Firestore sync exception", [
                    'order_id' => $request->order_id,
                    'seller_id' => $request->seller_id,
                    'error' => $firestoreException->getMessage(),
                    'trace' => $firestoreException->getTraceAsString()
                ]);
            }

            // Send push notification to seller about new order assignment
            try {
                SellerNotificationService::send(
                    sellerId: $request->seller_id,
                    title: 'New Order Arrived!',
                    message: "You have been assigned a new order #{$request->order_id}. Please check and prepare the items.",
                    image: '',
                    pageNavigation: 'new_order',
                    navigationId: $request->order_id
                );
                \Log::info("Order Seller Assignment - Notification sent to seller", [
                    'order_id' => $request->order_id,
                    'seller_id' => $request->seller_id
                ]);
            } catch (\Exception $e) {
                \Log::error("Order Seller Assignment - Failed to send notification to seller", [
                    'order_id' => $request->order_id,
                    'seller_id' => $request->seller_id,
                    'error' => $e->getMessage()
                ]);
            }

            return response()->json([
                'status' => 1,
                'message' => 'Seller assigned successfully!'
            ]);

        } catch (\Exception $e) {
            \Log::error('Error in assignSellerToStore: ' . $e->getMessage());
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function getSellerAssignedOrders(Request $request)
    {
        // Seller logged in through token
        $seller = auth()->guard('api')->user();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        try {
            // Get filter parameters from request
            $statusFilter = $request->input('status'); // e.g., 'received', 'processed', 'delivered', etc.
            $search = $request->input('search');
            $startDate = $request->input('startDate') ? \Carbon\Carbon::parse($request->startDate)->startOfDay() : null;
            $endDate = $request->input('endDate') ? \Carbon\Carbon::parse($request->endDate)->endOfDay() : null;
            $startDeliveryDate = $request->input('startDeliveryDate');
            $endDeliveryDate = $request->input('endDeliveryDate');

            // Get all orders that have items or combo items belonging to this seller
            // Using Order model with relationships
            $ordersQuery = Order::where(function($query) use ($seller) {
                    $query->whereHas('items', function($q) use ($seller) {
                        $q->where('seller_id', $seller->id);
                    })->orWhereHas('comboItems', function($q) use ($seller) {
                        $q->where('seller_id', $seller->id);
                    });
                });

            // Apply date range filter
            if ($startDate && $endDate) {
                $ordersQuery->whereBetween('orders.created_at', [$startDate, $endDate]);
            }

            // Apply delivery date range filter
            if ($startDeliveryDate && $endDeliveryDate) {
                $startDeliveryDateFormatted = date('Y-m-d', strtotime($startDeliveryDate));
                $endDeliveryDateFormatted = date('Y-m-d', strtotime($endDeliveryDate));

                $ordersQuery->where(function($query) use ($startDeliveryDateFormatted, $endDeliveryDateFormatted) {
                    $query->whereRaw("STR_TO_DATE(SUBSTRING_INDEX(orders.delivery_time, ' ', 1), '%d-%m-%Y') BETWEEN ? AND ?",
                        [$startDeliveryDateFormatted, $endDeliveryDateFormatted]);
                });
            }

            // Apply status filter if provided
            if ($statusFilter && $statusFilter != 0) {
                $ordersQuery->where('active_status', $statusFilter);
            }

            // Apply search filter
            if ($search) {
                $ordersQuery->where(function($query) use ($search) {
                    $query->where('orders.id', 'like', "%{$search}%")
                        ->orWhere('orders.orders_id', 'like', "%{$search}%")
                        ->orWhere('orders.payment_method', 'like', "%{$search}%")
                        ->orWhere('orders.mobile', 'like', "%{$search}%")
                        ->orWhere('orders.total', 'like', "%{$search}%")
                        ->orWhere('orders.final_total', 'like', "%{$search}%")
                        ->orWhereHas('user', function($q) use ($search) {
                            $q->where('name', 'like', "%{$search}%");
                        })
                        ->orWhereHas('deliveryBoy', function($q) use ($search) {
                            $q->where('name', 'like', "%{$search}%");
                        });
                });
            }

            // Get total count for status order count
            $totalOrdersCount = (clone $ordersQuery)->groupBy('orders.id')->get()->count();

            // Pagination
            $perPage = $request->input('per_page', 15);
            $orders = $ordersQuery
                ->with([
                    'items' => function($query) use ($seller) {
                        $query->where('seller_id', $seller->id)
                              ->with(['productVariant', 'seller']);
                    },
                    'comboItems' => function($query) use ($seller) {
                        $query->where('seller_id', $seller->id);
                    },
                    'user',
                    'orderStatus',
                    'deliveryBoy'
                ])
                ->orderBy('created_at', 'desc')
                ->groupBy('orders.id')
                ->paginate($perPage);

            // Add OTP value dynamically based on setting
            $generate_otp = \App\Models\Setting::get_value("generate_otp");

            // Get status order count
            $statusOrderCount = CommonHelper::getStatusOrderCount($seller->id, 'doorstep')->toArray() ?? [];
            array_unshift($statusOrderCount, array("id" => 0, "status" => "All Orders", "order_count" => $totalOrdersCount));

            $finalData = [];

            foreach ($orders as $order) {
                // Get cart metadata which includes preparation_time and notes
                $cartMetadata = $order->cart_metadata ?? [];
                $preparationTime = $cartMetadata['preparation_time'] ?? null;
                $billingBreakdown = $cartMetadata['billing_breakdown'] ?? null;

                // Extract seller-specific note from cart metadata notes
                $sellerNote = null;
                if (isset($cartMetadata['notes'])) {
                    $notesData = $cartMetadata['notes'];
                    // Notes are stored as {"0":"general note","30":"seller 30 note"}
                    // Extract note for current seller
                    $sellerNote = $notesData[$seller->id] ?? $notesData['0'] ?? null;
                }
                $notes = $sellerNote;

                // Get status data from database based on active_status
                $statusData = $this->getStatusData($order->active_status);

                // Set OTP based on setting
                $otp = ($generate_otp == 1) ? $order->otp : 0;

                // Map regular order items
                $mappedItems = [];
                foreach ($order->items as $item) {
                    $mappedItems[] = [
                        'type'              => 'regular',
                        'item_id'           => $item->id,
                        'product_name'      => $item->product_name,
                        'variant_name'      => $item->variant_name,
                        'quantity'          => $item->quantity,
                        'price'             => $item->price,
                        'discounted_price'  => $item->discounted_price,
                        'tax_amount'        => $item->tax_amount,
                        'tax_percentage'    => $item->tax_percentage,
                        'discount'          => $item->discount,
                        'sub_total'         => $item->sub_total,
                        'status'            => $item->status,
                        'active_status'     => $item->active_status,
                        'image_url'         => $item->image_url,
                        'product_variant'   => $item->productVariant,
                    ];
                }

                // Map combo items
                $mappedComboItems = [];
                foreach ($order->comboItems as $comboItem) {
                    $mappedComboItems[] = [
                        'type'                  => 'combo',
                        'combo_item_id'         => $comboItem->id,
                        'combo_id'              => $comboItem->combo_id,
                        'combo_name'            => $comboItem->combo_name,
                        'combo_description'     => $comboItem->combo_description,
                        'product_count'         => $comboItem->product_count,
                        'total_products_price'  => $comboItem->total_products_price,
                        'total_actual_price'    => $comboItem->total_actual_price,
                        'discount_percentage'   => $comboItem->discount_percentage,
                        'sub_total'             => $comboItem->sub_total,
                        'products'              => $comboItem->products,
                        'status'                => $comboItem->status,
                        'active_status'         => $comboItem->active_status,
                    ];
                }

                // Prepare delivery boy details
                $deliveryBoyDetails = null;
                if ($order->deliveryBoy) {
                    $deliveryBoyDetails = [
                        'id'                    => $order->deliveryBoy->id,
                        'name'                  => $order->deliveryBoy->name,
                        'mobile'                => $order->deliveryBoy->mobile,
                        'email'                 => $order->deliveryBoy->email,
                        'profile'               => $order->deliveryBoy->profile ?? null,
                        'balance'               => $order->deliveryBoy->balance ?? 0,
                        'driving_license_url'   => $order->deliveryBoy->driving_license_url ?? null,
                    ];
                }

                $finalData[] = [
                    'order_id'              => $order->id,
                    'orders_id'             => $order->orders_id,
                    'otp'                   => $otp,
                    'user_id'               => $order->user_id,
                    'user'                  => $order->user,
                    'mobile'                => $order->mobile,
                    'address'               => $order->address,
                    'latitude'              => $order->latitude,
                    'longitude'             => $order->longitude,
                    'order_note'            => $order->order_note,
                    'total'                 => $order->total,
                    'delivery_charge'       => $order->delivery_charge,
                    'tax_amount'            => $order->tax_amount,
                    'tax_percentage'        => $order->tax_percentage,
                    'discount'              => $order->discount,
                    'promo_code'            => $order->promo_code,
                    'promo_discount'        => $order->promo_discount,
                    'wallet_balance'        => $order->wallet_balance,
                    'final_total'           => $order->final_total,
                    'payment_method'        => $order->payment_method,
                    'delivery_time'         => $order->delivery_time,
                    'delivery_boy_id'       => $order->delivery_boy_id,
                    'delivery_boy'          => $deliveryBoyDetails,
                    'status'                => json_decode($order->status),
                    'active_status'         => $order->active_status,
                    'status_data'           => $statusData,
                    'order_status_history'  => $order->orderStatus,
                    'preparation_time'      => $preparationTime,
                    'notes'                 => $notes,
                    'billing_breakdown'     => $billingBreakdown,
                    'cart_metadata'         => $cartMetadata,
                    'created_at'            => $order->created_at,
                    'updated_at'            => $order->updated_at,
                    'items'                 => $mappedItems,
                    'combo_items'           => $mappedComboItems,
                ];
            }

            return response()->json([
                'status' => 1,
                'status_order_count' => $statusOrderCount,
                'data'   => $finalData,
                'pagination' => [
                    'total' => $orders->total(),
                    'per_page' => $orders->perPage(),
                    'current_page' => $orders->currentPage(),
                    'last_page' => $orders->lastPage(),
                    'from' => $orders->firstItem(),
                    'to' => $orders->lastItem(),
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get status name from status ID by fetching from database
     */
    private function getStatusName($activeStatus)
    {
        // Map status codes to status IDs
        $statusCodeToId = [
            'payment_pending' => OrderStatusList::$paymentPending,
            'received' => OrderStatusList::$received,
            'processed' => OrderStatusList::$processed,
            'shipped' => OrderStatusList::$shipped,
            'out_for_delivery' => OrderStatusList::$outForDelivery,
            'delivered' => OrderStatusList::$delivered,
            'cancelled' => OrderStatusList::$cancelled,
            'returned' => OrderStatusList::$returned,
            'pending' => OrderStatusList::$selfPickupPending,
            'ready_for_pickup' => OrderStatusList::$selfPickupReady,
            'picked_up' => OrderStatusList::$selfPickupPicked,
        ];

        $statusId = $statusCodeToId[$activeStatus] ?? null;

        if ($statusId) {
            $statusRecord = OrderStatusList::find($statusId);
            if ($statusRecord) {
                return $statusRecord->status;
            }
        }

        return ucwords(str_replace('_', ' ', $activeStatus));
    }

    /**
     * Get status data from database by status ID
     */
    private function getStatusData($activeStatus)
    {

        $statusId = $activeStatus ?? null;

        if ($statusId) {
            $statusRecord = OrderStatusList::find($statusId);
            if ($statusRecord) {
                return [
                    'id' => $statusRecord->id,
                    'code' => $activeStatus,
                    'name' => $statusRecord->status,
                ];
            }
        }

        return [
            'id' => null,
            'code' => $activeStatus,
            'name' => ucwords(str_replace('_', ' ', $activeStatus)),
        ];
    }

    /**
     * Get all available order statuses from database
     */
    public function getOrderStatuses(Request $request)
    {
        // Fetch all statuses from database
        $dbStatuses = OrderStatusList::all();

        // Map status codes to IDs
        $statusMapping = [
            ['id' => OrderStatusList::$paymentPending, 'code' => 'payment_pending'],
            ['id' => OrderStatusList::$received, 'code' => 'received'],
            ['id' => OrderStatusList::$processed, 'code' => 'processed'],
            ['id' => OrderStatusList::$shipped, 'code' => 'shipped'],
            ['id' => OrderStatusList::$outForDelivery, 'code' => 'out_for_delivery'],
            ['id' => OrderStatusList::$delivered, 'code' => 'delivered'],
            ['id' => OrderStatusList::$cancelled, 'code' => 'cancelled'],
            ['id' => OrderStatusList::$returned, 'code' => 'returned'],
            ['id' => OrderStatusList::$selfPickupPending, 'code' => 'pending'],
            ['id' => OrderStatusList::$selfPickupReady, 'code' => 'ready_for_pickup'],
            ['id' => OrderStatusList::$selfPickupPicked, 'code' => 'picked_up'],
        ];

        $statuses = [];
        foreach ($statusMapping as $mapping) {
            $statusRecord = $dbStatuses->firstWhere('id', $mapping['id']);
            if ($statusRecord) {
                $statuses[] = [
                    'id' => $statusRecord->id,
                    'code' => $mapping['code'],
                    'name' => $statusRecord->status,
                ];
            }
        }

        return response()->json([
            'status' => 1,
            'data' => $statuses
        ]);
    }

    /**
     * Update preparation time for an order
     */
    public function updatePreparationTime(Request $request)
    {
        $seller = auth()->guard('api')->user();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'preparation_time' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $order = Order::find($request->order_id);

            if (!$order) {
                return CommonHelper::responseError("Order not found");
            }

            // Verify seller has items in this order
            $hasItems = $order->items()->where('seller_id', $seller->id)->exists() ||
                       $order->comboItems()->where('seller_id', $seller->id)->exists();

            if (!$hasItems) {
                return CommonHelper::responseError("You don't have permission to update this order");
            }

            // Update cart metadata with preparation time
            $cartMetadata = $order->cart_metadata ?? [];
            $cartMetadata['preparation_time'] = $request->preparation_time;
            $order->cart_metadata = $cartMetadata;
            $order->save();

            return response()->json([
                'status' => 1,
                'message' => 'Preparation time updated successfully',
                'data' => [
                    'order_id' => $order->id,
                    'preparation_time' => $request->preparation_time
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update order status
     */
    public function updateOrderStatus(Request $request)
    {
        $seller = auth()->guard('api')->user();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'status' => 'required|string',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $order = Order::find($request->order_id);

            if (!$order) {
                return CommonHelper::responseError("Order not found");
            }

            // Verify seller has items in this order
            $hasItems = $order->items()->where('seller_id', $seller->id)->exists() ||
                       $order->comboItems()->where('seller_id', $seller->id)->exists();

            if (!$hasItems) {
                return CommonHelper::responseError("You don't have permission to update this order");
            }

            // Update order status
            $order->active_status = $request->status;
            $order->save();

            // Get status data
            $statusData = $this->getStatusData($request->status);

            return response()->json([
                'status' => 1,
                'message' => 'Order status updated successfully',
                'data' => [
                    'order_id' => $order->id,
                    'active_status' => $order->active_status,
                    'status_data' => $statusData,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Verify OTP from delivery partner
     */
    public function verifyDeliveryOTP(Request $request)
    {
        $seller = auth()->guard('api')->user();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'otp' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            $order = Order::find($request->order_id);

            if (!$order) {
                return CommonHelper::responseError("Order not found");
            }

            // Verify seller has items in this order
            $hasItems = $order->items()->where('seller_id', $seller->id)->exists() ||
                       $order->comboItems()->where('seller_id', $seller->id)->exists();

            if (!$hasItems) {
                return CommonHelper::responseError("You don't have permission to verify this order");
            }

            // Verify OTP
            if ($order->otp != $request->otp) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Invalid OTP. Please try again.'
                ]);
            }

            // OTP verified successfully
            // You can update order status here if needed
            // For example: mark as ready for pickup or delivered

            return response()->json([
                'status' => 1,
                'message' => 'OTP verified successfully',
                'data' => [
                    'order_id' => $order->id,
                    'orders_id' => $order->orders_id,
                    'verified' => true,
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }


    public function getSellerOrderStatusTracking(Request $request)
    {
        // Seller logged in through token
        $seller = auth()->guard('api')->user();

        // dd($seller->id);

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        try {
            // Get seller details to get store_id
            $sellerDetails = DB::table('sellers')->where('admin_id', $seller->id)->first();

            if (!$sellerDetails) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            $sellerStoreId = $sellerDetails->store_id;

            // Get all tracking records for this seller
            $allTrackingRecords = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerDetails->id)
                ->get();

            $sellerOrderIds = $allTrackingRecords->pluck('order_id')->toArray();

            // Apply date filter to get filtered order IDs (used for both counts and data)
            $dateFilteredOrderIds = null;
            if (($request->has('from_date') && !empty($request->from_date)) || ($request->has('to_date') && !empty($request->to_date)) || ($request->has('date') && !empty($request->date))) {
                $dateQuery = DB::table('orders')->whereIn('id', $sellerOrderIds);
                if ($request->has('date') && !empty($request->date)) {
                    $dateQuery->whereDate('created_at', $request->date);
                }
                if ($request->has('from_date') && !empty($request->from_date)) {
                    $dateQuery->whereDate('created_at', '>=', $request->from_date);
                }
                if ($request->has('to_date') && !empty($request->to_date)) {
                    $dateQuery->whereDate('created_at', '<=', $request->to_date);
                }
                $dateFilteredOrderIds = $dateQuery->pluck('id')->toArray();
            }

            // Use date-filtered IDs for counting if date filter is active
            $countingOrderIds = $dateFilteredOrderIds ?? $sellerOrderIds;
            $countingTrackingRecords = $dateFilteredOrderIds !== null
                ? $allTrackingRecords->whereIn('order_id', $dateFilteredOrderIds)
                : $allTrackingRecords;

            $sellerStatusCounts = [];

            // New Orders vs Ongoing are both in the pre-pack ("assigned_to_seller")
            // phase. They are split purely by is_seller_started_preparing:
            //   0 -> New Orders (seller hasn't set a prep time yet)
            //   1 -> Ongoing (seller has started preparing)
            $newOrdersCount = 0;
            $ongoingCount = 0;

            // Fetch all actual order statuses in one query to avoid N+1
            $orderStatusMap = DB::table('orders')
                ->whereIn('id', $countingOrderIds)
                ->pluck('active_status', 'id')
                ->toArray();

            foreach ($countingTrackingRecords as $tracking) {
                $actualStatus = isset($orderStatusMap[$tracking->order_id])
                    ? (int) $orderStatusMap[$tracking->order_id]
                    : null;

                if ($tracking->status === 'packed_by_seller') {
                    // Only show as Processed (3) if the order hasn't progressed beyond it
                    $mappedStatus = ($actualStatus !== null && $actualStatus <= 3) ? 3 : $actualStatus;
                } elseif ($tracking->status === 'given_to_delivery_partner') {
                    // Only show as Shipped (4) if the order hasn't progressed beyond it
                    $mappedStatus = ($actualStatus !== null && $actualStatus <= 4) ? 4 : $actualStatus;
                } else {
                    // Pre-pack phase: bucket into New / Ongoing by the prep flag
                    if ((int) $tracking->is_seller_started_preparing === 1) {
                        $ongoingCount++;
                    } else {
                        $newOrdersCount++;
                    }
                    continue;
                }

                if ($mappedStatus !== null) {
                    $sellerStatusCounts[$mappedStatus] = ($sellerStatusCounts[$mappedStatus] ?? 0) + 1;
                }
            }

            // Add cancelled orders count from the archive table (they are deleted from the main table)
            $cancelledQuery = DB::table('cancelled_order_seller_tracking')
                ->where('seller_id', $sellerDetails->id);
            if ($dateFilteredOrderIds !== null) {
                $cancelledQuery->whereIn('order_id', $dateFilteredOrderIds);
            }
            $cancelledCount = $cancelledQuery->count();
            $sellerStatusCounts[7] = ($sellerStatusCounts[7] ?? 0) + $cancelledCount;

            $orderStatusList = DB::table('order_status_lists')
                ->orderBy('id')
                ->get();

            // "New Orders" tab (id=0): orders not yet started preparing.
            $statusOrderCount = [
                [
                    'id' => 0,
                    'status' => 'New Orders',
                    'order_count' => $newOrdersCount
                ]
            ];

            foreach ($orderStatusList as $statusItem) {
                if (in_array($statusItem->id, [1, 9, 4 ,10, 11, 12])) {
                    continue;
                }

                // "Received" (id=2) is repurposed as the "Ongoing" tab: orders the
                // seller has started preparing (is_seller_started_preparing = 1).
                if ($statusItem->id == OrderStatusList::$received) {
                    $statusOrderCount[] = [
                        'id' => $statusItem->id,
                        'status' => 'Ongoing',
                        'order_count' => $ongoingCount
                    ];
                    continue;
                }

                $statusOrderCount[] = [
                    'id' => $statusItem->id,
                    'status' => $statusItem->status,
                    'order_count' => $sellerStatusCounts[$statusItem->id] ?? 0
                ];
            }

            $trackingQuery = DB::table('order_seller_status_tracking')
                ->where('seller_id', $sellerDetails->id);

            if ($request->has('status') && !empty($request->status)) {
                $trackingQuery->where('status', $request->status);
            }

            if ($request->has('order_id') && !empty($request->order_id)) {
                $trackingQuery->where('order_id', $request->order_id);
            }

            // Search by order id
            if ($request->has('search') && !empty($request->search)) {
                $search = $request->search;
                $matchingOrderIds = DB::table('orders')
                    ->whereIn('id', $sellerOrderIds)
                    ->where('orders.id', 'like', "%{$search}%")
                    ->pluck('id')
                    ->toArray();
                $trackingQuery->whereIn('order_id', $matchingOrderIds);
            }

            // Filter by date using orders.created_at (not tracking table)
            if ($dateFilteredOrderIds !== null) {
                $trackingQuery->whereIn('order_id', $dateFilteredOrderIds);
            }

            // Filter by order active_status if provided (using mapped status logic)
            if ($request->has('order_status') && $request->order_status !== null && $request->order_status !== '') {
                $requestedStatus = (int) $request->order_status;

                if ($requestedStatus === 3) {
                    // Processed = packed_by_seller
                    $trackingQuery->where('status', 'packed_by_seller');
                } elseif ($requestedStatus === 4) {
                    // Shipped = given_to_delivery_partner
                    $trackingQuery->where('status', 'given_to_delivery_partner');
                } elseif ($requestedStatus === 1 || $requestedStatus === 2) {
                    // New Orders (1) and Ongoing (2) are both pre-pack
                    // ("assigned_to_seller") orders, split by the prep flag:
                    //   New     -> is_seller_started_preparing = 0
                    //   Ongoing -> is_seller_started_preparing = 1
                    $prepFlag = $requestedStatus === 2 ? 1 : 0;
                    $trackingQuery
                        ->whereNotIn('status', ['packed_by_seller', 'given_to_delivery_partner'])
                        ->where('is_seller_started_preparing', $prepFlag);
                } else {
                    // For other statuses (delivered, out for delivery, etc.), filter only by order's active_status
                    // regardless of what status the tracking row holds
                    $orderIdsWithStatus = DB::table('orders')
                        ->whereIn('id', $sellerOrderIds)
                        ->where('active_status', $request->order_status)
                        ->pluck('id')
                        ->toArray();
                    $trackingQuery->whereIn('order_id', $orderIdsWithStatus);
                }
            }

            // When order_status=7 (Cancelled), records come from the archive table
            // because they are deleted from order_seller_status_tracking on cancellation
            if ($request->has('order_status') && (int) $request->order_status === 7) {
                $cancelledQuery = DB::table('cancelled_order_seller_tracking')
                    ->where('seller_id', $sellerDetails->id);

                if ($request->has('order_id') && !empty($request->order_id)) {
                    $cancelledQuery->where('order_id', $request->order_id);
                }
                if ($request->has('search') && !empty($request->search)) {
                    $search = $request->search;
                    $cancelledOrderIds = $cancelledQuery->pluck('order_id')->toArray();
                    $matchingCancelledOrderIds = DB::table('orders')
                        ->whereIn('id', $cancelledOrderIds)
                        ->where('orders.id', 'like', "%{$search}%")
                        ->pluck('id')
                        ->toArray();
                    $cancelledQuery->whereIn('order_id', $matchingCancelledOrderIds);
                }
                // Apply date filter using orders.created_at
                if ($dateFilteredOrderIds !== null) {
                    $cancelledQuery->whereIn('order_id', $dateFilteredOrderIds);
                }

                $trackingRecords = $cancelledQuery->orderBy('cancelled_at', 'desc')->get();
            } else {
                $trackingRecords = $trackingQuery->orderBy('created_at', 'desc')->get();
            }

            // Build order data with filtered products
            $orderDataList = [];

            foreach ($trackingRecords as $tracking) {
                // Get order details
                $order = Order::select(
                    'orders.*',
                    'users.name as user_name',
                    'users.email as user_email',
                    'users.mobile as user_mobile',
                    'address.address as customer_address',
                    'address.landmark as customer_landmark',
                    'address.area as customer_area',
                    'address.pincode as customer_pincode',
                    'address.city as customer_city',
                    'address.state as customer_state',
                    'address.country as customer_country',
                    'address.latitude as customer_latitude',
                    'address.longitude as customer_longitude',
                    'os.id as status_id',
                    'os.status as status_name'
                )
                ->leftJoin('users', 'orders.user_id', '=', 'users.id')
                ->leftJoin('user_addresses as address', 'orders.address_id', '=', 'address.id')
                ->leftJoin('order_status_lists as os', 'orders.active_status', '=', 'os.id')
                ->where('orders.id', $tracking->order_id)
                ->first();

                if (!$order) {
                    continue;
                }

                // Get order items filtered by seller's store_id
                $orderItems = DB::table('order_items')
                    ->select(
                        'order_items.*',
                        'products.id as product_id',
                        'products.name as product_name',
                        'products.image as product_image',
                        'products.store_id',
                        'product_variants.measurement',
                        'product_variants.stock_unit_id',
                        'product_variants.price as variant_price',
                        'product_variants.discounted_price as variant_discounted_price',
                        'units.name as unit_name',
                        'units.short_code as unit_short_code',
                        'os.status as item_status_name'
                    )
                    ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                    ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                    ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                    ->leftJoin('order_status_lists as os', 'order_items.active_status', '=', 'os.id')
                    ->where('order_items.order_id', $tracking->order_id)
                    ->where('products.store_id', $sellerStoreId)
                    ->get();

                $allProducts = [];

                foreach ($orderItems as $item) {
                    $item->product_image_url = $item->product_image ? (str_starts_with($item->product_image, 'http') ? $item->product_image : asset('storage/' . $item->product_image)) : null;
                    $item->source = 'order_item';

                    $key = $item->product_id . '_' . $item->product_variant_id;

                    if (isset($allProducts[$key])) {
                        $allProducts[$key]['quantity'] += $item->quantity;
                        $allProducts[$key]['sub_total'] += $item->sub_total;
                    } else {
                        $allProducts[$key] = [
                            'product_id' => $item->product_id,
                            'product_variant_id' => $item->product_variant_id,
                            'product_name' => $item->product_name,
                            'variant_name' => $item->variant_name,
                            'product_image' => $item->product_image,
                            'product_image_url' => $item->product_image_url,
                            'store_id' => $item->store_id,
                            'quantity' => $item->quantity,
                            'price' => $item->price,
                            'discounted_price' => $item->discounted_price,
                            'sub_total' => $item->sub_total,
                            'measurement' => $item->measurement,
                            'unit_name' => $item->unit_name,
                            'unit_short_code' => $item->unit_short_code,
                            'variant_price' => $item->variant_price,
                            'variant_discounted_price' => $item->variant_discounted_price,
                            'tax_amount' => $item->tax_amount,
                            'tax_percentage' => $item->tax_percentage,
                            'item_status_name' => $item->item_status_name,
                            'source' => 'order_item',
                        ];
                    }
                }

                $comboItems = DB::table('order_combo_items')
                    ->where('order_id', $tracking->order_id)
                    ->get();

                foreach ($comboItems as $combo) {
                    if (!empty($combo->products)) {
                        $products = json_decode($combo->products, true);
                        if (is_string($products)) {
                            $products = json_decode($products, true);
                        }
                        if (is_array($products)) {
                            // Get product IDs from combo
                            $comboProductIds = array_column($products, 'product_id');

                            // Get products that belong to seller's store with their details
                            $matchingProductDetails = DB::table('products')
                                ->select(
                                    'products.id as product_id',
                                    'products.name as product_name',
                                    'products.image as product_image',
                                    'products.store_id'
                                )
                                ->whereIn('products.id', $comboProductIds)
                                ->where('products.store_id', $sellerStoreId)
                                ->get()
                                ->keyBy('product_id');

                            foreach ($products as $product) {
                                $productId = $product['product_id'] ?? null;
                                $variantId = $product['product_variant_id'] ?? null;

                                if ($productId && isset($matchingProductDetails[$productId])) {
                                    $productDetail = $matchingProductDetails[$productId];

                                    // Get variant details
                                    $variantDetail = null;
                                    if ($variantId) {
                                        $variantDetail = DB::table('product_variants')
                                            ->select(
                                                'product_variants.*',
                                                'units.name as unit_name',
                                                'units.short_code as unit_short_code'
                                            )
                                            ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                                            ->where('product_variants.id', $variantId)
                                            ->first();
                                    }

                                    $key = $productId . '_' . $variantId;
                                    $qty = $product['quantity'] ?? 1;
                                    $price = $product['price'] ?? ($variantDetail->price ?? 0);
                                    $discountedPrice = $product['discounted_price'] ?? ($variantDetail->discounted_price ?? 0);
                                    $subTotal = ($discountedPrice > 0 ? $discountedPrice : $price) * $qty;

                                    if (isset($allProducts[$key])) {
                                        // Same product and variant - add quantity and sub_total
                                        $allProducts[$key]['quantity'] += $qty;
                                        $allProducts[$key]['sub_total'] += $subTotal;
                                    } else {
                                        $allProducts[$key] = [
                                            'product_id' => $productId,
                                            'product_variant_id' => $variantId,
                                            'product_name' => $product['product_name'] ?? $productDetail->product_name,
                                            'variant_name' => $product['variant_name'] ?? null,
                                            'product_image' => $productDetail->product_image,
                                            'product_image_url' => $productDetail->product_image ? (str_starts_with($productDetail->product_image, 'http') ? $productDetail->product_image : asset('storage/' . $productDetail->product_image)) : null,
                                            'store_id' => $productDetail->store_id,
                                            'quantity' => $qty,
                                            'price' => $price,
                                            'discounted_price' => $discountedPrice,
                                            'sub_total' => $subTotal,
                                            'measurement' => $variantDetail->measurement ?? null,
                                            'unit_name' => $variantDetail->unit_name ?? null,
                                            'unit_short_code' => $variantDetail->unit_short_code ?? null,
                                            'variant_price' => $variantDetail->price ?? null,
                                            'variant_discounted_price' => $variantDetail->discounted_price ?? null,
                                            'tax_amount' => $product['tax_amount'] ?? 0,
                                            'tax_percentage' => $product['tax_percentage'] ?? 0,
                                            'item_status_name' => null,
                                            'source' => 'combo_item',
                                        ];
                                    }
                                }
                            }
                        }
                    }
                }

                // Convert to array and calculate total
                $productsArray = array_values($allProducts);
                $sellerTotal = array_sum(array_column($productsArray, 'sub_total'));

                // Calculate commission and GST deduction using the
                // dynamic vendor-category snapshots first, falling back
                // to legacy per-row values for any seller that pre-dates
                // the snapshot migration. The legacy sellers.gst column
                // has been dropped, so gst now reads exclusively from
                // vendor_gst_percent.
                $commissionPercentage = (float) (
                    $sellerDetails->vendor_commission_percent
                    ?? $sellerDetails->commission
                    ?? 0
                );
                $commissionDeduction = ($sellerTotal * $commissionPercentage) / 100;
                $gstPercentage = (float) ($sellerDetails->vendor_gst_percent ?? 0);
                $gstDeduction = ($sellerTotal * $gstPercentage) / 100;
                $paymentGatewayFeesPercent = (float) (DB::table('settings')->where('variable', 'payment_gateway_fees')->value('value') ?? 0);
                $paymentGatewayFeesDeduction = ($sellerTotal * $paymentGatewayFeesPercent) / 100;
                $netTotal = $sellerTotal - $commissionDeduction - $gstDeduction - $paymentGatewayFeesDeduction;

                // Extract seller notes from cart_metadata
                $sellerNotes = null;

                // Check if seller's store is admin managed - if yes, skip notes entirely
                $isAdminManaged = DB::table('stores')
                    ->where('id', $sellerStoreId)
                    ->where('managed_by_admin', 1)
                    ->exists();

                if ($isAdminManaged) {
                    $sellerNotes = 'N/A';
                } elseif ($order->cart_metadata) {
                    try {
                        $cartMetadata = \is_string($order->cart_metadata) ? \json_decode($order->cart_metadata, true) : $order->cart_metadata;
                        if (isset($cartMetadata['cart_info']['seller_notes'])) {
                            $allSellerNotes = $cartMetadata['cart_info']['seller_notes'];
                            // Check if there's a note for this seller (seller_id as key)
                            $sellerId = (string) $sellerDetails->id;
                            if (isset($allSellerNotes[$sellerId])) {
                                $sellerNotes = $allSellerNotes[$sellerId];
                            }
                        }
                    } catch (\Exception $e) {
                        \Log::error('Error parsing cart metadata for seller notes', [
                            'order_id' => $order->id,
                            'seller_id' => $sellerDetails->id,
                            'error' => $e->getMessage()
                        ]);
                    }
                }

                // Map tracking status to order status for seller view
                $mappedStatusId = $order->status_id;
                $mappedStatusName = $order->status_name;
                $mappedActiveStatus = $order->active_status;

                if ($tracking->status === 'packed_by_seller' && (int) $order->active_status <= 3) {
                    $mappedStatusId = 3;
                    $mappedStatusName = 'Processed';
                    $mappedActiveStatus = '3';
                } elseif ($tracking->status === 'given_to_delivery_partner' && (int) $order->active_status <= 4) {
                    $mappedStatusId = 4;
                    $mappedStatusName = 'Shipped';
                    $mappedActiveStatus = '4';
                }

                $orderDataList[] = [
                    'tracking_info' => [
                        'id' => $tracking->id,
                        'order_id' => $tracking->order_id,
                        'seller_id' => $tracking->seller_id,
                        'store_id' => $tracking->store_id,
                        'status' => $tracking->status,
                        'prep_time' => $tracking->prep_time ? json_decode($tracking->prep_time, true) : null,
                        'created_at' => $tracking->created_at,
                        'updated_at' => $tracking->updated_at,
                    ],
                    'order_data' => [
                        'id' => $order->id,
                        'orders_id' => $order->orders_id,
                        'user_id' => $order->user_id,
                        'user_name' => $order->user_name,
                        'user_email' => $order->user_email,
                        'user_mobile' => $order->user_mobile,
                        'mobile' => $order->mobile,
                        'total' => $order->total,
                        'delivery_charge' => $order->delivery_charge,
                        'discount' => $order->discount,
                        'promo_code' => $order->promo_code,
                        'promo_discount' => $order->promo_discount,
                        'wallet_balance' => $order->wallet_balance,
                        'final_total' => $order->final_total,
                        'payment_method' => $order->payment_method,
                        'address' => $order->address,
                        'customer_address' => $order->customer_address,
                        'customer_landmark' => $order->customer_landmark,
                        'customer_area' => $order->customer_area,
                        'customer_pincode' => $order->customer_pincode,
                        'customer_city' => $order->customer_city,
                        'customer_state' => $order->customer_state,
                        'customer_country' => $order->customer_country,
                        'customer_latitude' => $order->customer_latitude,
                        'customer_longitude' => $order->customer_longitude,
                        'delivery_time' => $order->delivery_time,
                        'order_type' => $order->order_type,
                        'active_status' => $mappedActiveStatus,
                        'status_id' => $mappedStatusId,
                        'status_name' => $mappedStatusName,
                        'order_note' => $order->order_note,
                        'created_at' => $order->created_at,
                        'updated_at' => $order->updated_at,
                    ],
                    'seller_total' => round($sellerTotal, 2),
                    'commission_percentage' => round($commissionPercentage, 2),
                    'commission_deduction' => round($commissionDeduction, 2),
                    'gst_percentage' => round($gstPercentage, 2),
                    'gst_deduction' => round($gstDeduction, 2),
                    'net_total' => round($netTotal, 2),
                    'notes' => $sellerNotes,
                    'delivery_boy' => null,
                    'products' => $productsArray,
                ];

                // Get settlement transaction details from seller_wallet_transactions
                $settlementTransaction = DB::table('seller_wallet_transactions')
                    ->where('order_id', $tracking->order_id)
                    ->where('seller_id', $sellerDetails->id)
                    ->where('type', 'order_commission')
                    ->first();

                if ($settlementTransaction) {
                    $productsJson = json_decode($settlementTransaction->products_json ?? '[]', true);
                    $totalProductAmount = 0;
                    $totalGstAmount = 0;
                    foreach ($productsJson as $p) {
                        $totalProductAmount += floatval($p['total_amount'] ?? 0);
                        $totalGstAmount += floatval($p['gst'] ?? 0);
                    }

                    // Derive the label commission percentage from the
                    // actually-recorded admin_commission so the label
                    // always matches the deducted amount on this
                    // specific order, even if the live rate has since
                    // changed in Vendor Commission Configurations.
                    $settledCommissionAmount = floatval($settlementTransaction->admin_commission);
                    $settledCommissionPercent = $totalProductAmount > 0
                        ? round(($settledCommissionAmount / $totalProductAmount) * 100, 2)
                        : 0;

                    $settledWaitCharge = floatval($settlementTransaction->vendor_wait_charge ?? 0);
                    $settlementBreakdown = [
                        ['label' => 'Total Product Amount', 'value' => round($totalProductAmount, 2)],
                        ['label' => 'Admin Commission (' . $settledCommissionPercent . '%)', 'value' => round($settledCommissionAmount, 2)],
                        ['label' => 'GST (' . round(floatval($settlementTransaction->gst_percentage), 2) . '%)', 'value' => round($totalGstAmount, 2)],
                        ['label' => 'Payment Gateway Fees (' . round($paymentGatewayFeesPercent, 2) . '%)', 'value' => round(floatval($settlementTransaction->payment_gateway_fees ?? 0), 2)],
                    ];
                    if ($settledWaitCharge > 0) {
                        $settlementBreakdown[] = ['label' => 'Waiting Charge (paid to driver)', 'value' => round($settledWaitCharge, 2)];
                    }
                    $settlementBreakdown[] = ['label' => 'Net Seller Amount', 'value' => round(floatval($settlementTransaction->amount), 2)];
                    $settlementBreakdown[] = ['label' => 'Payment Status', 'value' => $settlementTransaction->is_paid_to_seller ? 'Paid' : 'Pending'];
                    $settlementBreakdown[] = ['label' => 'Settled At', 'value' => $settlementTransaction->created_at];

                    $orderDataList[count($orderDataList) - 1]['settlement_info'] = $settlementBreakdown;
                } else {
                    // Order not yet delivered - use calculated estimates
                    $orderDataList[count($orderDataList) - 1]['settlement_info'] = [
                        ['label' => 'Total Product Amount', 'value' => round($sellerTotal, 2)],
                        ['label' => 'Admin Commission (' . round($commissionPercentage, 2) . '%)', 'value' => round($commissionDeduction, 2)],
                        ['label' => 'GST (' . round($gstPercentage, 2) . '%)', 'value' => round($gstDeduction, 2)],
                        ['label' => 'Payment Gateway Fees (' . round($paymentGatewayFeesPercent, 2) . '%)', 'value' => round($paymentGatewayFeesDeduction, 2)],
                        ['label' => 'Net Seller Amount', 'value' => round($netTotal, 2)],
                        ['label' => 'Payment Status', 'value' => 'Not Settled'],
                    ];
                }

                // Get delivery boy info if assigned
                if ($order->delivery_boy_id) {
                    $deliveryBoy = DB::table('delivery_boys')
                        ->where('id', $order->delivery_boy_id)
                        ->first();

                    if ($deliveryBoy) {
                        $orderDataList[count($orderDataList) - 1]['delivery_boy'] = [
                            'id' => $deliveryBoy->id,
                            'name' => $deliveryBoy->name,
                            'mobile' => $deliveryBoy->mobile,
                            // Use the driver's profile photo, not their driving-license scan
                            'image_url' => $deliveryBoy->profile_image ? (str_starts_with($deliveryBoy->profile_image, 'http') ? $deliveryBoy->profile_image : asset('storage/' . $deliveryBoy->profile_image)) : null,
                        ];
                    }
                }
            }

            return response()->json([
                'status' => 1,
                'message' => 'Order status tracking records retrieved successfully',
                'status_order_count' => $statusOrderCount,
                'data' => $orderDataList
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function updateSellerOrderPrepTime(Request $request)
    {
        $seller = auth()->guard('api')->user();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        try {
            $request->validate([
                'order_id' => 'required|integer',
                'prep_time' => 'required',
            ]);

            // Handle prep_time as string (JSON) or array
            $prepTime = $request->prep_time;
            if (is_string($prepTime)) {
                $prepTime = json_decode($prepTime, true);
                if (json_last_error() !== JSON_ERROR_NONE) {
                    return response()->json([
                        'status' => 0,
                        'message' => 'Invalid prep_time format'
                    ], 400);
                }
            }

            $sellerDetails = DB::table('sellers')->where('admin_id', $seller->id)->first();

            if (!$sellerDetails) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            $trackingRecord = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->where('seller_id', $sellerDetails->id)
                ->first();

            if (!$trackingRecord) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order tracking record not found for this seller'
                ], 404);
            }

            $updateData = [
                'prep_time' => json_encode($prepTime),
                'updated_at' => now()
            ];

            // Check if prep_time already exists (seller is updating prep time again)
            if (!empty($trackingRecord->prep_time)) {
                // prep_time format: [minutes, "time"] e.g. [15, "4:47 PM"]
                // Calculate delay: elapsed_time - old_remaining + new_remaining
                $oldPrepTime = json_decode($trackingRecord->prep_time, true);
                $oldRemainingMinutes = isset($oldPrepTime[0]) ? (int)$oldPrepTime[0] : 0;
                $oldTimeString = isset($oldPrepTime[1]) ? $oldPrepTime[1] : null;

                $newRemainingMinutes = isset($prepTime[0]) ? (int)$prepTime[0] : 0;
                $newTimeString = isset($prepTime[1]) ? $prepTime[1] : null;

                $delayedMinutes = 0;
                if ($oldTimeString && $newTimeString) {
                    try {
                        $oldTime = \Carbon\Carbon::parse($oldTimeString);
                        $newTime = \Carbon\Carbon::parse($newTimeString);
                        $elapsedMinutes = $oldTime->diffInMinutes($newTime, false);

                        // Delay = elapsed_time - old_remaining + new_remaining
                        // If elapsed >= old_remaining, order should have been done, so delay = new_remaining + (elapsed - old_remaining)
                        $delayedMinutes = $elapsedMinutes - $oldRemainingMinutes + $newRemainingMinutes;
                        if ($delayedMinutes < 0) {
                            $delayedMinutes = 0;
                        }
                    } catch (\Exception $e) {
                        // Fallback to simple approach if time parsing fails
                        $delayedMinutes = $newRemainingMinutes;
                    }
                } else {
                    $delayedMinutes = $newRemainingMinutes;
                }

                $updateData['delayed_time_in_min'] = $delayedMinutes;

                // Send notification to customer and driver about order delay
                if ($delayedMinutes > 0) {
                    $order = Order::find($request->order_id);

                    // Notify customer about delay
                    // try {
                    //     if ($order && $order->user_id) {
                    //         CustomerNotificationService::send(
                    //             customerId: $order->user_id,
                    //             title: 'Order Delayed',
                    //             message: "Your order #{$request->order_id} is slightly delayed. The seller needs an additional {$delayedMinutes} minutes to prepare your order. We apologize for the inconvenience.",
                    //             image: '',
                    //             pageNavigation: 'order',
                    //             navigationId: $request->order_id
                    //         );
                    //         \Log::info('Customer notification sent for order delay', [
                    //             'order_id' => $request->order_id,
                    //             'customer_id' => $order->user_id,
                    //             'delayed_minutes' => $delayedMinutes
                    //         ]);
                    //     }
                    // } catch (\Exception $e) {
                    //     \Log::error('Failed to send customer notification for order delay', [
                    //         'order_id' => $request->order_id,
                    //         'error' => $e->getMessage()
                    //     ]);
                    // }

                    // Notify driver about delay (if driver is assigned)
                    try {
                        if ($order && $order->delivery_boy_id) {
                            DriverNotificationService::send(
                                driverId: $order->delivery_boy_id,
                                title: 'Order Delayed',
                                message: "Order #{$request->order_id} is delayed by {$delayedMinutes} minutes. The seller needs more time to prepare the order.",
                                image: '',
                                type: 'order',
                                orderItemId: $request->order_id
                            );
                            \Log::info('Driver notification sent for order delay', [
                                'order_id' => $request->order_id,
                                'driver_id' => $order->delivery_boy_id,
                                'delayed_minutes' => $delayedMinutes
                            ]);
                        }
                    } catch (\Exception $e) {
                        \Log::error('Failed to send driver notification for order delay', [
                            'order_id' => $request->order_id,
                            'error' => $e->getMessage()
                        ]);
                    }
                }
            } else {
                // First time seller is giving prep time - mark as started preparing
                $updateData['is_seller_started_preparing'] = 1;

                // Lock the first promised prep_time for vendor waiting-charge billing.
                // Subsequent prep_time updates do NOT move this anchor (prevents gaming).
                $firstMinutes = isset($prepTime[0]) ? (int) $prepTime[0] : null;
                if ($firstMinutes !== null) {
                    $updateData['first_prep_time_set_at']  = now();
                    $updateData['first_prep_time_minutes'] = $firstMinutes;
                }
            }

            DB::table('order_seller_status_tracking')
                ->where('id', $trackingRecord->id)
                ->update($updateData);

            // Check if all sellers for this order have started preparing
            $allSellersForOrder = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->get();

            $allStartedPreparing = $allSellersForOrder->every(function ($record) {
                return $record->is_seller_started_preparing == 1;
            });

            if ($allStartedPreparing && $allSellersForOrder->count() > 0) {
                // Sync available delivery boys to Firestore when all sellers have started preparing
                try {
                    $firestoreResult = FirestoreDeliveryBoyService::getAndSyncAvailableDeliveryBoys($request->order_id);
                    \Log::info('Firestore sync completed for order: ' . $request->order_id, ['result' => $firestoreResult]);
                } catch (\Exception $firestoreException) {
                    \Log::error('Firestore sync failed for order: ' . $request->order_id, [
                        'error' => $firestoreException->getMessage(),
                        'trace' => $firestoreException->getTraceAsString()
                    ]);
                    // Continue execution even if Firestore sync fails
                }

                // Dispatch retry job to keep searching for drivers if none accepted
                try {
                    RetryDeliveryBoyAssignmentJob::dispatchForOrder($request->order_id);
                } catch (\Exception $retryJobException) {
                    \Log::error('Failed to dispatch retry delivery boy assignment job for order: ' . $request->order_id, [
                        'error' => $retryJobException->getMessage(),
                        'trace' => $retryJobException->getTraceAsString()
                    ]);
                }

                // Update order status to "Preparing your order" in Firestore
                try {
                    $orderStatusResult = FirestoreOrderETAService::updateOrderStatus(
                        $request->order_id,
                        'Preparing your order',
                        'We are getting your order ready'
                    );
                    \Log::info('Order status updated to Preparing for order: ' . $request->order_id, ['result' => $orderStatusResult]);
                } catch (\Exception $statusException) {
                    \Log::error('Failed to update order status for order: ' . $request->order_id, [
                        'error' => $statusException->getMessage(),
                        'trace' => $statusException->getTraceAsString()
                    ]);
                    // Continue execution even if status update fails
                }
            }

            return response()->json([
                'status' => 1,
                'message' => 'Prep time updated successfully',
                'data' => [
                    'order_id' => $request->order_id,
                    'prep_time' => $prepTime
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function updateSellerOrderTrackingStatus(Request $request)
    {
        $seller = auth()->guard('api')->user();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        try {

            $sellerDetails = DB::table('sellers')->where('admin_id', $seller->id)->first();

            if (!$sellerDetails) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            $trackingRecord = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->where('seller_id', $sellerDetails->id)
                // ->where('seller_id', 37)
                ->first();

            if (!$trackingRecord) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order tracking record not found for this seller'
                ], 404);
            }

            $updateData = [
                'status' => $request->status,
                'updated_at' => now()
            ];

            // $otp = null;
            // if ($request->status === 'packed_by_seller') {
            //     $otp = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);
            //     $updateData['otp'] = $otp;
            // }

            DB::table('order_seller_status_tracking')
                ->where('id', $trackingRecord->id)
                ->update($updateData);

            $allTrackingRecords = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->get();

            if ($request->status === 'packed_by_seller') {
                $allPacked = $allTrackingRecords->every(function ($record) {
                    return $record->status === 'packed_by_seller';
                });

                if ($allPacked) {
                    DB::table('orders')
                        ->where('id', $request->order_id)
                        ->update([
                            'active_status' => 3,
                            'updated_at' => now()
                        ]);

                    DB::table('order_statuses')->updateOrInsert(
                        ['order_id' => $request->order_id, 'status' => 3],
                        [
                            'created_at' => now(),
                            'created_by' => 0,
                            'user_type' => 1,
                        ]
                    );

                    // Send notification to customer that order is packed
                    try {
                        $order = Order::find($request->order_id);
                        if ($order && $order->user_id) {
                            CustomerNotificationService::send(
                                customerId: $order->user_id,
                                title: 'Order Packed!',
                                message: "Great news! Your order #{$request->order_id} has been packed by the seller",
                                image: '',
                                pageNavigation: 'order',
                                navigationId: $request->order_id
                            );
                            \Log::info('Customer notification sent for packed order', [
                                'order_id' => $request->order_id,
                                'customer_id' => $order->user_id
                            ]);
                        }
                    } catch (\Exception $e) {
                        \Log::error('Failed to send customer notification for packed order', [
                            'order_id' => $request->order_id,
                            'error' => $e->getMessage()
                        ]);
                    }

                    // Update order status to "Ready for Pickup" in Firestore
                    try {
                        $orderStatusResult = FirestoreOrderETAService::updateOrderStatus(
                            $request->order_id,
                            'Ready for Pickup',
                            'Delivery partner can pick it up as soon as possible'
                        );
                        \Log::info('Order status updated to Ready for Pickup for order: ' . $request->order_id, ['result' => $orderStatusResult]);
                    } catch (\Exception $statusException) {
                        \Log::error('Failed to update order status for order: ' . $request->order_id, [
                            'error' => $statusException->getMessage(),
                            'trace' => $statusException->getTraceAsString()
                        ]);
                        // Continue execution even if status update fails
                    }

                    // Sync available delivery boys to Firestore when all sellers have packed
                    // try {
                    //     $firestoreResult = FirestoreDeliveryBoyService::getAndSyncAvailableDeliveryBoys($request->order_id);
                    //     \Log::info('Firestore sync completed for order: ' . $request->order_id, ['result' => $firestoreResult]);
                    // } catch (\Exception $firestoreException) {
                    //     \Log::error('Firestore sync failed for order: ' . $request->order_id, [
                    //         'error' => $firestoreException->getMessage(),
                    //         'trace' => $firestoreException->getTraceAsString()
                    //     ]);
                    //     // Continue execution even if Firestore sync fails
                    // }
                }
            }

            if ($request->status === 'given_to_delivery_partner') {
                $allGivenToDelivery = $allTrackingRecords->every(function ($record) {
                    return $record->status === 'given_to_delivery_partner';
                });

                if ($allGivenToDelivery) {
                    DB::table('orders')
                        ->where('id', $request->order_id)
                        ->update([
                            'active_status' => 5,
                            'updated_at' => now()
                        ]);

                    DB::table('order_statuses')->updateOrInsert(
                        ['order_id' => $request->order_id, 'status' => 5],
                        [
                            'created_at' => now(),
                            'created_by' => 0,
                            'user_type' => 1,
                        ]
                    );

                    // Send notification to customer that order is out for delivery
                    try {
                        $order = Order::find($request->order_id);
                        if ($order && $order->user_id) {
                            CustomerNotificationService::send(
                                customerId: $order->user_id,
                                title: 'Order Out for Delivery!',
                                message: "Your order #{$request->order_id} has been picked up by our delivery partner and is on its way to you.",
                                image: '',
                                pageNavigation: 'order',
                                navigationId: $request->order_id
                            );
                            \Log::info('Customer notification sent for order out for delivery', [
                                'order_id' => $request->order_id,
                                'customer_id' => $order->user_id
                            ]);
                        }
                    } catch (\Exception $e) {
                        \Log::error('Failed to send customer notification for order out for delivery', [
                            'order_id' => $request->order_id,
                            'error' => $e->getMessage()
                        ]);
                    }
                }
            }

            $responseData = [
                'order_id' => $request->order_id,
                'status' => $request->status
            ];

            // if ($otp !== null) {
            //     $responseData['otp'] = $otp;
            // }

            return response()->json([
                'status' => 1,
                'message' => 'Order tracking status updated successfully',
                'data' => $responseData
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    public function verifyOtpAndUpdateTrackingStatus(Request $request)
    {
        // Seller logged in through token
        $seller = auth()->guard('api')->user();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        try {
            // Validate request
            $request->validate([
                'order_id' => 'required|integer',
                'otp' => 'required|string|size:4',
            ]);

            // Get seller details
            $sellerDetails = DB::table('sellers')->where('admin_id', $seller->id)->first();

            if (!$sellerDetails) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Find the tracking record for this order and seller
            $trackingRecord = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->where('seller_id', $sellerDetails->id)
                ->first();

            if (!$trackingRecord) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order tracking record not found for this seller'
                ], 404);
            }

            // Verify OTP
            if ($trackingRecord->otp !== $request->otp) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Invalid OTP'
                ], 400);
            }

            // Update status to given_to_delivery_partner and clear OTP
            DB::table('order_seller_status_tracking')
                ->where('id', $trackingRecord->id)
                ->update([
                    'status' => 'given_to_delivery_partner',
                    // 'otp' => null,
                    'updated_at' => now()
                ]);

            // Check if all sellers have given items to delivery partner
            $allTrackingRecords = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->get();

            // Check if all sellers have status 'given_to_delivery_partner'
            $allGivenToDelivery = $allTrackingRecords->every(function ($record) {
                return $record->status === 'given_to_delivery_partner';
            });

            // If all sellers have given to delivery partner, update the order status to Out for Delivery (5)
            if ($allGivenToDelivery) {
                DB::table('orders')
                    ->where('id', $request->order_id)
                    ->update([
                        'active_status' => 5, // Out for Delivery status
                        'updated_at' => now()
                    ]);

                // Also create order status record for tracking
                DB::table('order_statuses')->updateOrInsert(
                    ['order_id' => $request->order_id, 'status' => 5],
                    [
                        'created_at' => now(),
                        'created_by' => 0,
                        'user_type' => 1,
                    ]
                );

                // Send notification to customer that order is out for delivery
                try {
                    $order = Order::find($request->order_id);
                    if ($order && $order->user_id) {
                        CustomerNotificationService::send(
                            customerId: $order->user_id,
                            title: 'Order Out for Delivery!',
                            message: "Your order #{$request->order_id} has been picked up by our delivery partner and is on its way to you.",
                            image: '',
                            pageNavigation: 'order',
                            navigationId: $request->order_id
                        );
                        \Log::info('Customer notification sent for order out for delivery (OTP verified)', [
                            'order_id' => $request->order_id,
                            'customer_id' => $order->user_id
                        ]);
                    }
                } catch (\Exception $e) {
                    \Log::error('Failed to send customer notification for order out for delivery (OTP verified)', [
                        'order_id' => $request->order_id,
                        'error' => $e->getMessage()
                    ]);
                }
            }

            return response()->json([
                'status' => 1,
                'message' => 'OTP verified and status updated successfully',
                'data' => [
                    'order_id' => $request->order_id,
                    'status' => 'given_to_delivery_partner'
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get issue report returns for the authenticated seller.
     *
     * Retrieves all customer issue report returns associated with the seller's store,
     * including related customer, delivery partner, order, and product information.
     *
     * @param Request $request The HTTP request containing optional filter parameters:
     *                         - is_return_accepted: Filter by return acceptance status (0 or 1)
     *                         - date: Filter by specific date (Y-m-d format)
     *                         - start_date: Filter from date (Y-m-d format)
     *                         - end_date: Filter to date (Y-m-d format)
     *
     * @return \Illuminate\Http\JsonResponse JSON response containing:
     *         - status: 1 for success, 0 for failure
     *         - message: Success or error message
     *         - total: Total count of records (on success)
     *         - data: Array of issue report return records (on success)
     */
    public function getIssueReportReturns(Request $request): \Illuminate\Http\JsonResponse
    {
        $authenticatedUser = auth()->guard('api')->user();

        if ($authenticatedUser === null) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        try {
            $sellerDetails = DB::table('sellers')
                ->where('admin_id', $authenticatedUser->id)
                ->first();

            if ($sellerDetails === null) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            $returnRecords = $this->fetchReturnRecords($request, $sellerDetails->id);

            if ($returnRecords->isEmpty()) {
                return response()->json([
                    'status' => 1,
                    'message' => 'Issue report returns fetched successfully',
                    'total' => 0,
                    'data' => []
                ]);
            }

            $relatedData = $this->fetchRelatedData($returnRecords);
            $orderSellerProducts = $this->fetchOrderSellerProducts(
                $returnRecords,
                $relatedData['reports'],
                $sellerDetails->store_id
            );

            $transformedData = $this->transformReturnRecords(
                $returnRecords,
                $relatedData,
                $orderSellerProducts
            );

            return response()->json([
                'status' => 1,
                'message' => 'Issue report returns fetched successfully',
                'total' => $transformedData->count(),
                'data' => $transformedData->values()
            ]);

        } catch (\Exception $e) {
            \Log::error('Error fetching issue report returns: ' . $e->getMessage(), [
                'seller_id' => $authenticatedUser->id ?? null,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'An error occurred while fetching issue report returns'
            ], 500);
        }
    }

    /**
     * Fetch return records based on filter criteria.
     *
     * @param Request $request The HTTP request with filter parameters
     * @param int $sellerId The seller's ID
     * @return \Illuminate\Support\Collection Collection of return records
     */
    private function fetchReturnRecords(Request $request, int $sellerId): \Illuminate\Support\Collection
    {
        $query = DB::table('customer_issue_report_returns')
            ->where('seller_id', $sellerId);

        if ($request->filled('is_return_accepted')) {
            $query->where('is_return_accepted', (int) $request->input('is_return_accepted'));
        }

        if ($request->filled('date')) {
            $query->whereDate('date', $request->input('date'));
        }

        if ($request->filled('start_date')) {
            $query->whereDate('date', '>=', $request->input('start_date'));
        }

        if ($request->filled('end_date')) {
            $query->whereDate('date', '<=', $request->input('end_date'));
        }

        return $query->orderBy('created_at', 'desc')->get();
    }

    /**
     * Fetch all related data for return records in batch queries.
     *
     * @param \Illuminate\Support\Collection $returnRecords Collection of return records
     * @return array Associative array containing reports, customers, deliveryPartners, and orders
     */
    private function fetchRelatedData(\Illuminate\Support\Collection $returnRecords): array
    {
        $reportIds = $returnRecords->pluck('report_id')->unique()->filter()->values()->toArray();
        $customerIds = $returnRecords->pluck('customer_id')->unique()->filter()->values()->toArray();
        $deliveryPartnerIds = $returnRecords->pluck('delivery_partner_id')->unique()->filter()->values()->toArray();

        $reports = collect();
        if (!empty($reportIds)) {
            $reports = DB::table('customer_item_missing_reports')
                ->whereIn('id', $reportIds)
                ->select('id', 'order_id', 'report_type', 'description', 'status', 'selected_items', 'selected_combo_items', 'created_at')
                ->get()
                ->keyBy('id');
        }

        $customers = collect();
        if (!empty($customerIds)) {
            $customers = DB::table('users')
                ->whereIn('id', $customerIds)
                ->select('id', 'name', 'mobile', 'email')
                ->get()
                ->keyBy('id');
        }

        $deliveryPartners = collect();
        if (!empty($deliveryPartnerIds)) {
            $deliveryPartners = DB::table('delivery_boys')
                ->whereIn('id', $deliveryPartnerIds)
                ->select('id', 'name', 'mobile')
                ->get()
                ->keyBy('id');
        }

        $orders = collect();
        $orderIds = $reports->pluck('order_id')->unique()->filter()->values()->toArray();
        if (!empty($orderIds)) {
            $orders = DB::table('orders')
                ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->whereIn('orders.id', $orderIds)
                ->select(
                    'orders.id',
                    'orders.mobile',
                    'orders.total',
                    'orders.active_status',
                    'user_addresses.address',
                    'user_addresses.city',
                    'user_addresses.pincode',
                    'user_addresses.landmark'
                )
                ->get()
                ->keyBy('id');
        }

        return [
            'reports' => $reports,
            'customers' => $customers,
            'deliveryPartners' => $deliveryPartners,
            'orders' => $orders
        ];
    }

    /**
     * Fetch order products that belong to the seller's store.
     *
     * @param \Illuminate\Support\Collection $returnRecords Collection of return records
     * @param \Illuminate\Support\Collection $reports Collection of reports
     * @param int|null $sellerStoreId The seller's store ID
     * @return array Associative array mapping order IDs to their products
     */
    private function fetchOrderSellerProducts(
        \Illuminate\Support\Collection $returnRecords,
        \Illuminate\Support\Collection $reports,
        ?int $sellerStoreId
    ): array {
        if ($sellerStoreId === null) {
            return [];
        }

        $orderSellerProducts = [];

        $reportSelectedItems = [];
        $reportSelectedComboItems = [];
        $reportToOrderMap = [];

        foreach ($reports as $report) {
            $reportSelectedItems[$report->id] = $this->safeJsonDecode($report->selected_items);
            $reportSelectedComboItems[$report->id] = $this->safeJsonDecode($report->selected_combo_items);
            $reportToOrderMap[$report->id] = $report->order_id;
        }

        $ordersWithSelectedItems = $this->getOrdersWithSelectedItems(
            $returnRecords,
            $reportSelectedItems,
            $reportToOrderMap
        );

        if (!empty($ordersWithSelectedItems)) {
            $orderSellerProducts = $this->fetchRegularOrderItems(
                $ordersWithSelectedItems,
                $sellerStoreId,
                $orderSellerProducts
            );
        }

        $comboData = $this->getOrdersWithComboItems(
            $returnRecords,
            $reportSelectedComboItems,
            $reportToOrderMap
        );

        if (!empty($comboData['comboIds'])) {
            $orderSellerProducts = $this->fetchComboOrderItems(
                $comboData['orderIds'],
                $comboData['comboIds'],
                $sellerStoreId,
                $orderSellerProducts
            );
        }

        return $orderSellerProducts;
    }

    /**
     * Safely decode JSON string to array.
     *
     * @param string|null $json JSON string to decode
     * @return array Decoded array or empty array on failure
     */
    private function safeJsonDecode(?string $json): array
    {
        if ($json === null || $json === '') {
            return [];
        }

        $decoded = json_decode($json, true);

        return is_array($decoded) ? $decoded : [];
    }

    /**
     * Get order IDs that have selected items in their reports.
     *
     * @param \Illuminate\Support\Collection $returnRecords Collection of return records
     * @param array $reportSelectedItems Map of report IDs to selected items
     * @param array $reportToOrderMap Map of report IDs to order IDs
     * @return array Array of unique order IDs
     */
    private function getOrdersWithSelectedItems(
        \Illuminate\Support\Collection $returnRecords,
        array $reportSelectedItems,
        array $reportToOrderMap
    ): array {
        $ordersWithSelectedItems = [];

        foreach ($returnRecords as $record) {
            $selectedItems = $reportSelectedItems[$record->report_id] ?? [];
            if (!empty($selectedItems)) {
                $orderId = $reportToOrderMap[$record->report_id] ?? null;
                if ($orderId !== null) {
                    $ordersWithSelectedItems[] = $orderId;
                }
            }
        }

        return array_unique($ordersWithSelectedItems);
    }

    /**
     * Fetch regular order items belonging to seller's store.
     *
     * @param array $orderIds Array of order IDs to fetch
     * @param int $sellerStoreId Seller's store ID
     * @param array $orderSellerProducts Existing products array to append to
     * @return array Updated products array
     */
    private function fetchRegularOrderItems(
        array $orderIds,
        int $sellerStoreId,
        array $orderSellerProducts
    ): array {
        $orderItems = DB::table('order_items')
            ->whereIn('order_id', $orderIds)
            ->select('id', 'order_id', 'product_variant_id', 'product_name', 'variant_name', 'quantity', 'price', 'discounted_price', 'sub_total')
            ->get();

        if ($orderItems->isEmpty()) {
            return $orderSellerProducts;
        }

        $variantIds = $orderItems->pluck('product_variant_id')->unique()->filter()->values()->toArray();

        $variantProductMap = [];
        if (!empty($variantIds)) {
            $variantProductMap = DB::table('product_variants')
                ->whereIn('id', $variantIds)
                ->pluck('product_id', 'id')
                ->toArray();
        }

        $productIds = array_unique(array_values($variantProductMap));
        $productsInfo = [];
        if (!empty($productIds)) {
            $productsInfo = DB::table('products')
                ->whereIn('id', $productIds)
                ->select('id', 'store_id', 'image', 'name')
                ->get()
                ->keyBy('id')
                ->toArray();
        }

        foreach ($orderItems as $item) {
            $productId = $variantProductMap[$item->product_variant_id] ?? null;
            $productInfo = ($productId !== null) ? ($productsInfo[$productId] ?? null) : null;

            if ($productInfo !== null && (int) $productInfo->store_id === $sellerStoreId) {
                if (!isset($orderSellerProducts[$item->order_id])) {
                    $orderSellerProducts[$item->order_id] = [];
                }

                $orderSellerProducts[$item->order_id][] = [
                    'order_item_id' => $item->id,
                    'product_id' => $productId,
                    'product_variant_id' => $item->product_variant_id,
                    'product_name' => $item->product_name,
                    'variant_name' => $item->variant_name,
                    'quantity' => $item->quantity,
                    'price' => $item->price,
                    'discounted_price' => $item->discounted_price,
                    'sub_total' => $item->sub_total,
                    'product_image' => $productInfo->image ? (str_starts_with($productInfo->image, 'http') ? $productInfo->image : asset('storage/' . $productInfo->image)) : null,
                    'source' => 'order_item',
                ];
            }
        }

        return $orderSellerProducts;
    }

    /**
     * Get order IDs and combo IDs that have selected combo items.
     *
     * @param \Illuminate\Support\Collection $returnRecords Collection of return records
     * @param array $reportSelectedComboItems Map of report IDs to selected combo items
     * @param array $reportToOrderMap Map of report IDs to order IDs
     * @return array Array with 'orderIds' and 'comboIds' keys
     */
    private function getOrdersWithComboItems(
        \Illuminate\Support\Collection $returnRecords,
        array $reportSelectedComboItems,
        array $reportToOrderMap
    ): array {
        $ordersWithSelectedComboItems = [];
        $comboIdsToFetch = [];

        foreach ($returnRecords as $record) {
            $selectedComboItems = $reportSelectedComboItems[$record->report_id] ?? [];

            if (!empty($selectedComboItems)) {
                $orderId = $reportToOrderMap[$record->report_id] ?? null;

                if ($orderId !== null) {
                    $ordersWithSelectedComboItems[] = $orderId;
                    foreach ($selectedComboItems as $comboItem) {
                        if (isset($comboItem['combo_id'])) {
                            $comboIdsToFetch[] = $comboItem['combo_id'];
                        }
                    }
                }
            }
        }

        return [
            'orderIds' => array_unique($ordersWithSelectedComboItems),
            'comboIds' => array_unique($comboIdsToFetch)
        ];
    }

    /**
     * Fetch combo order items belonging to seller's store.
     *
     * @param array $orderIds Array of order IDs
     * @param array $comboIds Array of combo IDs
     * @param int $sellerStoreId Seller's store ID
     * @param array $orderSellerProducts Existing products array to append to
     * @return array Updated products array
     */
    private function fetchComboOrderItems(
        array $orderIds,
        array $comboIds,
        int $sellerStoreId,
        array $orderSellerProducts
    ): array {
        $orderComboItems = DB::table('order_combo_items')
            ->whereIn('order_id', $orderIds)
            ->whereIn('id', $comboIds)
            ->select('id', 'order_id', 'combo_id', 'combo_name', 'sub_total', 'products')
            ->get();

        if ($orderComboItems->isEmpty()) {
            return $orderSellerProducts;
        }

        $comboProductIds = $this->extractComboProductIds($orderComboItems);

        $comboProductsInfo = [];
        if (!empty($comboProductIds)) {
            $comboProductsInfo = DB::table('products')
                ->whereIn('id', $comboProductIds)
                ->select('id', 'store_id', 'image', 'name')
                ->get()
                ->keyBy('id')
                ->toArray();
        }

        $stockUnits = DB::table('units')
            ->pluck('name', 'id')
            ->toArray();

        foreach ($orderComboItems as $comboItem) {
            $products = $this->parseComboProducts($comboItem->products);

            foreach ($products as $product) {
                $productId = $product['product_id'] ?? null;
                $productInfo = ($productId !== null) ? ($comboProductsInfo[$productId] ?? null) : null;

                if ($productInfo !== null && (int) $productInfo->store_id === $sellerStoreId) {
                    if (!isset($orderSellerProducts[$comboItem->order_id])) {
                        $orderSellerProducts[$comboItem->order_id] = [];
                    }

                    $variantName = $this->buildVariantName($product, $stockUnits);

                    $orderSellerProducts[$comboItem->order_id][] = [
                        'order_combo_item_id' => $comboItem->id,
                        'combo_id' => $comboItem->combo_id,
                        'combo_name' => $comboItem->combo_name,
                        'product_id' => $productId,
                        'product_name' => $product['product_name'] ?? $productInfo->name ?? null,
                        'variant_name' => $variantName,
                        'quantity' => $product['quantity'] ?? 1,
                        'price' => $product['price'] ?? null,
                        'discounted_price' => $product['discounted_price'] ?? null,
                        'sub_total' => $product['sub_total'] ?? null,
                        'product_image' => $productInfo->image ? (str_starts_with($productInfo->image, 'http') ? $productInfo->image : asset('storage/' . $productInfo->image)) : null,
                        'source' => 'combo_item',
                    ];
                }
            }
        }

        return $orderSellerProducts;
    }

    /**
     * Extract product IDs from combo items.
     *
     * @param \Illuminate\Support\Collection $orderComboItems Collection of combo items
     * @return array Array of unique product IDs
     */
    private function extractComboProductIds(\Illuminate\Support\Collection $orderComboItems): array
    {
        $comboProductIds = [];

        foreach ($orderComboItems as $comboItem) {
            $products = $this->parseComboProducts($comboItem->products);

            foreach ($products as $product) {
                if (isset($product['product_id'])) {
                    $comboProductIds[] = $product['product_id'];
                }
            }
        }

        return array_unique($comboProductIds);
    }

    /**
     * Parse combo products JSON, handling double-encoded JSON.
     *
     * @param string|null $productsJson JSON string of products
     * @return array Array of product data
     */
    private function parseComboProducts(?string $productsJson): array
    {
        if ($productsJson === null || $productsJson === '') {
            return [];
        }

        $products = json_decode($productsJson, true);

        if (is_string($products)) {
            $products = json_decode($products, true);
        }

        return is_array($products) ? $products : [];
    }

    /**
     * Build variant name from product data.
     *
     * @param array $product Product data array
     * @param array $stockUnits Map of unit IDs to names
     * @return string|null Variant name or null
     */
    private function buildVariantName(array $product, array $stockUnits): ?string
    {
        $variantName = $product['variant_name'] ?? null;

        if ($variantName === null && isset($product['variant_measurement'])) {
            $measurement = $product['variant_measurement'];
            $stockUnitId = $product['variant_stock_unit_id'] ?? null;
            $unitName = ($stockUnitId !== null) ? ($stockUnits[$stockUnitId] ?? '') : '';
            $variantName = trim($measurement . ' ' . $unitName);
        }

        return $variantName;
    }

    /**
     * Transform return records into the response format.
     *
     * @param \Illuminate\Support\Collection $returnRecords Collection of return records
     * @param array $relatedData Related data (reports, customers, etc.)
     * @param array $orderSellerProducts Map of order IDs to products
     * @return \Illuminate\Support\Collection Transformed collection
     */
    private function transformReturnRecords(
        \Illuminate\Support\Collection $returnRecords,
        array $relatedData,
        array $orderSellerProducts
    ): \Illuminate\Support\Collection {
        $reports = $relatedData['reports'];
        $customers = $relatedData['customers'];
        $deliveryPartners = $relatedData['deliveryPartners'];
        $orders = $relatedData['orders'];

        return $returnRecords->map(function ($record) use ($reports, $customers, $deliveryPartners, $orders, $orderSellerProducts) {
            $report = $reports->get($record->report_id);
            $customer = $customers->get($record->customer_id);
            $deliveryPartner = $deliveryPartners->get($record->delivery_partner_id);
            $order = ($report !== null) ? $orders->get($report->order_id) : null;
            $sellerProducts = ($report !== null) ? ($orderSellerProducts[$report->order_id] ?? []) : [];

            return [
                'id' => $record->id,
                'report_id' => $record->report_id,
                'seller_id' => $record->seller_id,
                'customer_id' => $record->customer_id,
                'date' => $record->date,
                'product_ids' => $this->safeJsonDecode($record->product_ids),
                'delivery_partner_id' => $record->delivery_partner_id,
                'delivered_date' => $record->delivered_date,
                'is_return_accepted' => $record->is_return_accepted,
                'created_at' => $record->created_at,
                'updated_at' => $record->updated_at,
                'customer' => $this->formatCustomerData($customer),
                'delivery_partner' => $this->formatDeliveryPartnerData($deliveryPartner),
                'report' => $this->formatReportData($report),
                'order' => $this->formatOrderData($order),
                'products' => $sellerProducts,
            ];
        });
    }

    /**
     * Format customer data for response.
     *
     * @param object|null $customer Customer data object
     * @return array|null Formatted customer data or null
     */
    private function formatCustomerData(?object $customer): ?array
    {
        if ($customer === null) {
            return null;
        }

        return [
            'id' => $customer->id,
            'name' => $customer->name,
            'mobile' => $customer->mobile,
            'email' => $customer->email,
        ];
    }

    /**
     * Format delivery partner data for response.
     *
     * @param object|null $deliveryPartner Delivery partner data object
     * @return array|null Formatted delivery partner data or null
     */
    private function formatDeliveryPartnerData(?object $deliveryPartner): ?array
    {
        if ($deliveryPartner === null) {
            return null;
        }

        return [
            'id' => $deliveryPartner->id,
            'name' => $deliveryPartner->name,
            'mobile' => $deliveryPartner->mobile,
        ];
    }

    /**
     * Format report data for response.
     *
     * @param object|null $report Report data object
     * @return array|null Formatted report data or null
     */
    private function formatReportData(?object $report): ?array
    {
        if ($report === null) {
            return null;
        }

        return [
            'id' => $report->id,
            'order_id' => $report->order_id,
            'report_type' => $report->report_type,
            'description' => $report->description,
            'status' => $report->status,
            'selected_items' => $this->safeJsonDecode($report->selected_items),
            'selected_combo_items' => $this->safeJsonDecode($report->selected_combo_items),
            'created_at' => $report->created_at,
        ];
    }

    /**
     * Format order data for response.
     *
     * @param object|null $order Order data object
     * @return array|null Formatted order data or null
     */
    private function formatOrderData(?object $order): ?array
    {
        if ($order === null) {
            return null;
        }

        return [
            'id' => $order->id,
            'mobile' => $order->mobile,
            'address' => $order->address,
            'city' => $order->city,
            'pincode' => $order->pincode,
            'landmark' => $order->landmark,
            'total' => $order->total ?? 0,
            'active_status' => $order->active_status,
        ];
    }

}
