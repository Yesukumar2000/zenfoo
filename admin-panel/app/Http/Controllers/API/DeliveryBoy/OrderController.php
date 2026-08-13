<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

use Illuminate\Support\Facades\Auth;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoySession;
use App\Models\DeliveryBoyTransaction;
use App\Models\DeliveryBoyReferralTracking;
use App\Models\Order;
use App\Models\Setting;
use App\Services\FirestoreDeliveryBoyService;
use App\Services\DeliveryBoyOrderService;
use App\Services\MediaUploadService;
use App\Models\DeliveryBoyDailyTracking;
use App\Services\DeliveryBoyIncentiveService;
use App\Services\SellerOrderSettlementService;
use App\Services\CustomerNotificationService;
use App\Services\AdminNotificationService;
use App\Services\SellerNotificationService;
use App\Services\DriverCustomerDistanceService;
use App\Services\ReferralBonusService;
use App\Services\PaytmQRCodeService;

class OrderController extends Controller
{
    /**
     * Get seller locations for given order IDs
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getSellerLocations(Request $request)
    {
        try {
            $orderIds = $request->input('order_ids');

            if (empty($orderIds)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_ids parameter is required'
                ], 400);
            }

            if (is_string($orderIds)) {
                $orderIds = array_map('trim', explode(',', $orderIds));
            }

            /** ------------------------------
             *  DELIVERY BOY (AUTH BASED)
             *  ------------------------------ */
            // $adminId = 42; 

            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $adminId = $driver_data_admin->id;

            // dd($adminId);

            $deliveryBoy = DeliveryBoy::where('admin_id', $adminId)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if (!$activeSession) {
                return response()->json([
                    'status' => 0,
                    'message' => 'No active delivery session'
                ], 400);
            }


            $latestLocation = DB::table('delivery_boy_location_history')
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->where('session_id', $activeSession->id)
                ->orderBy('tracked_at', 'desc')
                ->first();

            if (!$latestLocation) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Driver location not available'
                ], 400);
            }

            $driverLat = (float) $latestLocation->latitude;
            $driverLng = (float) $latestLocation->longitude;

            $result = [];

            foreach ($orderIds as $orderId) {

                /** ------------------------------
                 *  ORDER + CUSTOMER
                 *  ------------------------------ */
                $order = DB::table('orders')
                    ->join('users', 'users.id', '=', 'orders.user_id')
                    ->leftJoin('user_addresses', 'user_addresses.id', '=', 'orders.address_id')
                    ->where('orders.id', $orderId)
                    ->select(
                        'orders.id',
                        'orders.address',
                        'orders.latitude',
                        'orders.longitude',
                        'orders.order_type',
                        'orders.cart_metadata',
                        'orders.is_rain_surcharge',
                        'orders.rain_surcharge_amount',
                        'users.id as customer_id',
                        'users.email as customer_email',
                        // Receiver name saved on the delivery address wins - the account
                        // name is often blank (signup is mobile-only).
                        DB::raw("COALESCE(NULLIF(TRIM(user_addresses.name), ''), NULLIF(TRIM(users.name), ''), 'Customer') as customer_name"),
                        'users.mobile as customer_mobile'
                    )
                    ->first();

                if (!$order) {
                    continue;
                }

                $cartMeta = json_decode($order->cart_metadata, true);
                $deliveryTip = $cartMeta['cart_info']['delivery_tip'] ?? 0;
                $totalOrderValue = $cartMeta['billing_summary']['to_be_paid'] ?? 0;
                $deliveryCharge = $cartMeta['billing_summary']['delivery_charge'] ?? 0;

                /** ------------------------------
                 *  SELLERS
                 *  ------------------------------ */
                $sellers = $this->getSellerLocationsByOrderId((int) $orderId);
                if (empty($sellers)) {
                    continue;
                }

                /** ------------------------------
                 *  NEAREST-NEIGHBOR ROUTING
                 *  ------------------------------ */
                $unvisited = $sellers;
                $orderedSellers = [];
                $totalDistance = 0;

                $currentLat = $driverLat;
                $currentLng = $driverLng;

                while (!empty($unvisited)) {
                    // Zenfoo store(s) are always visited first. While any Zenfoo
                    // pickup is still unvisited, only Zenfoo stores are eligible for
                    // the next stop; within that group the nearest one is chosen.
                    // Once all Zenfoo stops are done, the rest fall back to
                    // nearest-neighbor ordering.
                    $zenfooPending = false;
                    foreach ($unvisited as $seller) {
                        if (!empty($seller['is_zenfoo_store'])) {
                            $zenfooPending = true;
                            break;
                        }
                    }

                    $nearestIndex = null;
                    $nearestDistance = null;

                    foreach ($unvisited as $index => $seller) {
                        // Skip non-Zenfoo sellers while a Zenfoo store is pending.
                        if ($zenfooPending && empty($seller['is_zenfoo_store'])) {
                            continue;
                        }

                        $distance = FirestoreDeliveryBoyService::calculateDistance(
                            $currentLat,
                            $currentLng,
                            (float) $seller['latitude'],
                            (float) $seller['longitude']
                        );

                        if ($nearestDistance === null || $distance < $nearestDistance) {
                            $nearestDistance = $distance;
                            $nearestIndex = $index;
                        }
                    }

                    $nearestSeller = $unvisited[$nearestIndex];
                    $nearestSeller['distance_from_previous_km'] = round($nearestDistance, 2);

                    $totalDistance += $nearestDistance;
                    $currentLat = (float) $nearestSeller['latitude'];
                    $currentLng = (float) $nearestSeller['longitude'];

                    $orderedSellers[] = $nearestSeller;
                    unset($unvisited[$nearestIndex]);
                }

                /** ------------------------------
                 *  LAST SELLER ➜ CUSTOMER
                 *  ------------------------------ */
                $lastLegDistance = FirestoreDeliveryBoyService::calculateDistance(
                    $currentLat,
                    $currentLng,
                    (float) $order->latitude,
                    (float) $order->longitude
                );

                $totalDistance += $lastLegDistance;

                // Check if order qualifies for multi-order bonus
                // Bonus is given only if order has store_id 15 along with other store_ids
                $orderStoreIds = array_column($orderedSellers, 'store_id');
                $hasStore15 = in_array(15, $orderStoreIds);
                $hasOtherStores = count(array_filter($orderStoreIds, fn($id) => $id != 15)) > 0;

                $multiOrderBonus = 0;
                if ($hasStore15 && $hasOtherStores) {
                    $multiOrderBonus = floatval(Setting::get_value('multi_order_bonus') ?: 0);
                }



                /** ------------------------------
                 *  FINAL RESPONSE
                 *  ------------------------------ */
                $result[] = [
                    'order_id' => (int) $orderId,

                    'driver' => [
                        'latitude' => $driverLat,
                        'longitude' => $driverLng
                    ],

                    'customer' => [
                        'id' => (int) $order->customer_id,
                        'name' => $order->customer_name,
                        'email' => $order->customer_email,
                        'mobile' => $order->customer_mobile,
                        'address' => $order->address,
                        'latitude' => $order->latitude,
                        'longitude' => $order->longitude
                    ],

                    'order_type' => $order->order_type,
                    'delivery_tip' => (float) $deliveryTip,
                    'total_order_value' => (float) $totalOrderValue,

                    'total_route_distance_km' => round($totalDistance, 2),
                    'multi_order_bonus' => $multiOrderBonus,

                    'sellers_visit_order' => $orderedSellers,
                    'delivery_charge' => (float) $deliveryCharge,
                    'is_rain_surcharge' => (bool) ($order->is_rain_surcharge ?? false),
                    'rain_surcharge_amount' => (float) ($order->rain_surcharge_amount ?? 0),
                ];
            }

            return response()->json([
                'status' => 1,
                'message' => 'Optimized seller route calculated successfully',
                'data' => $result
            ]);

        } catch (\Exception $e) {
            Log::error('Route calculation failed', ['error' => $e->getMessage()]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }





    /**
     * Get seller locations for a given order
     *
     * @param int $orderId The order ID
     * @return array Array of seller locations with seller_id, latitude, longitude
     */
    private function getSellerLocationsByOrderId(int $orderId): array
    {
        // Get seller IDs from order_seller_status_tracking table
        $sellerIds = DB::table('order_seller_status_tracking')
            ->where('order_id', $orderId)
            ->pluck('seller_id')
            ->toArray();

        // Filter out null values (Zenfoo store entries have null seller_id)
        $sellerIds = array_filter($sellerIds, function ($id) {
            return !is_null($id);
        });

        $sellerLocations = [];

        if (!empty($sellerIds)) {
            // Get seller lat_long from sellers table
            $sellers = DB::table('sellers')
                ->whereIn('id', $sellerIds)
                ->select('id', 'store_id', 'lat_long', 'store_name', 'store_location', 'mobile')
                ->get();

            foreach ($sellers as $seller) {
                $latitude = null;
                $longitude = null;

                // Parse lat_long string (format: "17.438925073025825,78.39837715029716")
                if (!empty($seller->lat_long)) {
                    $coords = explode(',', $seller->lat_long);
                    if (count($coords) === 2) {
                        $latitude = (float) trim($coords[0]);
                        $longitude = (float) trim($coords[1]);
                    }
                }

                $sellerLocations[] = [
                    'seller_id' => $seller->id,
                    'store_id' => $seller->store_id ? (int) $seller->store_id : null,
                    'is_zenfoo_store' => false,
                    'store_name' => $seller->store_name,
                    'seller_address' => $seller->store_location,
                    'seller_phone_number' => $seller->mobile,
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                ];
            }
        }

        // Check if order has products from any Zenfoo store (store_id 12 or 13)
        $hasZenfooProducts = $this->orderHasZenfooStoreProducts($orderId);

        if ($hasZenfooProducts) {
            // Get Zenfoo store location based on order's city
            $zenfooStoreLocation = $this->getZenfooStoreLocationForOrder($orderId);

            if ($zenfooStoreLocation) {
                $sellerLocations[] = $zenfooStoreLocation;
            }
        }

        return $sellerLocations;
    }

    /**
     * Check if order has products from Zenfoo store (store_id 12 or 13)
     *
     * @param int $orderId
     * @return bool
     */
    private function orderHasZenfooStoreProducts(int $orderId): bool
    {
        $zenfooStoreIds = [12, 13];

        // Check in order_items
        $hasInOrderItems = DB::table('order_items')
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->where('order_items.order_id', $orderId)
            ->whereIn('products.store_id', $zenfooStoreIds)
            ->exists();

        if ($hasInOrderItems) {
            return true;
        }

        // Check in order_combo_items
        $comboItems = DB::table('order_combo_items')
            ->where('order_id', $orderId)
            ->get();

        foreach ($comboItems as $combo) {
            if (!empty($combo->products)) {
                $products = json_decode($combo->products, true);
                if (is_string($products)) {
                    $products = json_decode($products, true);
                }

                if (is_array($products)) {
                    $comboProductIds = array_column($products, 'product_id');

                    $hasZenfooComboProducts = DB::table('products')
                        ->whereIn('id', $comboProductIds)
                        ->whereIn('store_id', $zenfooStoreIds)
                        ->exists();

                    if ($hasZenfooComboProducts) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * Get Zenfoo store location based on order's city
     *
     * @param int $orderId
     * @return array|null
     */
    private function getZenfooStoreLocationForOrder(int $orderId): ?array
    {
        // Get order with city_id
        $order = DB::table('orders')
            ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->where('orders.id', $orderId)
            ->select('orders.*', 'user_addresses.city_id')
            ->first();

        if (!$order) {
            return null;
        }

        // Get Zenfoo store details from store_locations table based on order's city
        $storeLocation = DB::table('store_locations')
            ->where('city_id', $order->city_id)
            ->where('status', 1)
            ->first();

        if (!$storeLocation) {
            return null;
        }

        $storeLatitude = $storeLocation->latitude ? (float) $storeLocation->latitude : null;
        $storeLongitude = $storeLocation->longitude ? (float) $storeLocation->longitude : null;

        return [
            'seller_id' => null,
            'store_id' => 12,
            'is_zenfoo_store' => true,
            'store_name' => $storeLocation->name,
            'seller_address' => $storeLocation->address,
            'seller_phone_number' => $storeLocation->phone,
            'latitude' => $storeLatitude,
            'longitude' => $storeLongitude,
        ];
    }

    /**
     * Accept an order by delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function acceptOrder(Request $request)
    {
        try {
            $orderId = $request->input('order_id');

            if (empty($orderId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            // Get authenticated delivery boy
            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Check for active session
            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if (!$activeSession) {
                return response()->json([
                    'status' => 0,
                    'message' => 'No active delivery session'
                ], 400);
            }

            // Accept the order using the service
            $result = DeliveryBoyOrderService::acceptOrder((int) $orderId, $deliveryBoy->id);

            if ($result['success']) {
                // Update driver accepted time and location
                $updateData = ['driver_accepted_at_time' => now()];

                if ($request->input('lat') !== null) {
                    $updateData['driver_accepted_lat'] = (double) $request->input('lat');
                }
                if ($request->input('lon') !== null) {
                    $updateData['driver_accepted_lon'] = (double) $request->input('lon');
                }

                DB::table('orders')
                    ->where('id', $orderId)
                    ->update($updateData);

                // Send notification to customer that delivery partner has been assigned
                try {
                    $order = Order::find($orderId);
                    if ($order && $order->user_id) {
                        CustomerNotificationService::send(
                            customerId: $order->user_id,
                            title: 'Delivery Partner Assigned!',
                            message: "A delivery partner has been assigned to your order #{$orderId} and will pick it up soon.",
                            image: '',
                            pageNavigation: 'order',
                            navigationId: $orderId
                        );
                        Log::info('Customer notification sent for driver assignment', [
                            'order_id' => $orderId,
                            'customer_id' => $order->user_id,
                            'delivery_boy_id' => $deliveryBoy->id
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error('Failed to send customer notification for driver assignment', [
                        'order_id' => $orderId,
                        'error' => $e->getMessage()
                    ]);
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
            Log::error('Order acceptance failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Get seller order details for delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getSellerOrderDetails(Request $request)
    {
        try {
            $orderId = $request->input('order_id');
            $sellerId = $request->input('seller_id');

            if (empty($orderId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            // Validate driver coordinates
            $driverLatitude = $request->input('latitude');
            $driverLongitude = $request->input('longitude');

            if (empty($driverLatitude) || empty($driverLongitude)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Driver latitude and longitude are required'
                ], 400);
            }

            $driverLatitude = (float) $driverLatitude;
            $driverLongitude = (float) $driverLongitude;

            if (!DriverCustomerDistanceService::areCoordinatesValid($driverLatitude, $driverLongitude)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Invalid driver coordinates'
                ], 400);
            }

            // Get authenticated delivery boy
            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Check for active session
            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if (!$activeSession) {
                return response()->json([
                    'status' => 0,
                    'message' => 'No active delivery session'
                ], 400);
            }

            // Verify order exists
            $order = DB::table('orders')
                ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('orders.id', $orderId)
                ->select('orders.*', 'user_addresses.city_id')
                ->first();

            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            // Check if seller_id is provided or if we need to get Zenfoo store products
            $isZenfooStore = empty($sellerId);

            if ($isZenfooStore) {
                // Get Zenfoo store details from store_locations table based on order's city
                $storeLocation = DB::table('store_locations')
                    ->where('city_id', $order->city_id)
                    ->where('status', 1)
                    ->first();

                if (!$storeLocation) {
                    return response()->json([
                        'status' => 0,
                        'message' => 'Zenfoo store location not found for this city'
                    ], 404);
                }

                $storeName = $storeLocation->name;
                $storePhone = $storeLocation->phone;
                $storeAddress = $storeLocation->address;
                $storeLatitude = $storeLocation->latitude ? (float) $storeLocation->latitude : null;
                $storeLongitude = $storeLocation->longitude ? (float) $storeLocation->longitude : null;

                // Zenfoo store IDs are 12 and 13 (treated as one logical store)
                $zenfooStoreIds = [12, 13];

                // Get order items filtered by any Zenfoo store ID
                $orderItems = DB::table('order_items')
                    ->select(
                        'order_items.id',
                        'order_items.quantity',
                        'order_items.product_variant_id',
                        'products.id as product_id',
                        'products.name as product_name',
                        'products.store_id',
                        'product_variants.measurement',
                        'units.short_code as unit_short_code'
                    )
                    ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                    ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                    ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                    ->where('order_items.order_id', $orderId)
                    ->whereIn('products.store_id', $zenfooStoreIds)
                    ->get();

                $targetStoreIds = $zenfooStoreIds;

            } else {
                // Get seller details
                $seller = DB::table('sellers')
                    ->where('id', $sellerId)
                    ->select('id', 'store_name', 'mobile', 'lat_long', 'store_location', 'store_id')
                    ->first();

                if (!$seller) {
                    return response()->json([
                        'status' => 0,
                        'message' => 'Seller not found'
                    ], 404);
                }

                // Parse seller lat_long
                $storeLatitude = null;
                $storeLongitude = null;
                if (!empty($seller->lat_long)) {
                    $coords = explode(',', $seller->lat_long);
                    if (count($coords) === 2) {
                        $storeLatitude = (float) trim($coords[0]);
                        $storeLongitude = (float) trim($coords[1]);
                    }
                }

                $storeName = $seller->store_name;
                $storePhone = $seller->mobile;
                $storeAddress = $seller->store_location;
                $sellerStoreId = $seller->store_id;

                // Get order items filtered by seller's store_id
                $orderItems = DB::table('order_items')
                    ->select(
                        'order_items.id',
                        'order_items.quantity',
                        'order_items.product_variant_id',
                        'products.id as product_id',
                        'products.name as product_name',
                        'products.store_id',
                        'product_variants.measurement',
                        'units.short_code as unit_short_code'
                    )
                    ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                    ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                    ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                    ->where('order_items.order_id', $orderId)
                    ->where('products.store_id', $sellerStoreId)
                    ->get();

                $targetStoreIds = [$sellerStoreId];
            }

            // Check driver proximity to seller/store location (must be within 100 meters)
            if (!DriverCustomerDistanceService::areCoordinatesValid($storeLatitude, $storeLongitude)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Store location coordinates are not available'
                ], 400);
            }

            $proximityRadius = intval(Setting::get_value('driver_proximity_radius') ?: 100);

            $proximityCheck = DriverCustomerDistanceService::isDriverWithinRange(
                $driverLatitude,
                $driverLongitude,
                $storeLatitude,
                $storeLongitude,
                $proximityRadius
            );

            if (!$proximityCheck['allowed']) {
                $distanceMeters = $proximityCheck['distance_meters'];
                return response()->json([
                    'status' => 0,
                    'message' => "You are {$distanceMeters} meters away from the store. Please move closer (within {$proximityRadius} meters) to view seller details.",
                    'data' => [
                        'distance_meters' => $distanceMeters,
                        'max_allowed_meters' => $proximityRadius,
                        'store_latitude' => $storeLatitude,
                        'store_longitude' => $storeLongitude
                    ]
                ], 400);
            }

            // Build items list with aggregation by product + variant
            $allProducts = [];

            foreach ($orderItems as $item) {
                $key = $item->product_id . '_' . $item->product_variant_id;
                $measurementDisplay = $item->measurement . ' ' . ($item->unit_short_code ?? '');

                if (isset($allProducts[$key])) {
                    $allProducts[$key]['quantity'] += $item->quantity;
                } else {
                    $allProducts[$key] = [
                        'quantity' => (int) $item->quantity,
                        'item_name' => $item->product_name,
                        'measurement' => trim($measurementDisplay),
                        'source' => 'order_item'
                    ];
                }
            }

            // Get combo items for this order
            $comboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->get();

            // Process combo items - extract products that belong to target store(s)
            foreach ($comboItems as $combo) {
                if (!empty($combo->products)) {
                    $products = json_decode($combo->products, true);
                    if (is_string($products)) {
                        $products = json_decode($products, true);
                    }

                    if (is_array($products)) {
                        // Get product IDs from combo
                        $comboProductIds = array_column($products, 'product_id');

                        // Get products that belong to target store(s) with their details
                        $matchingProductDetails = DB::table('products')
                            ->select(
                                'products.id as product_id',
                                'products.name as product_name',
                                'products.store_id'
                            )
                            ->whereIn('products.id', $comboProductIds)
                            ->whereIn('products.store_id', $targetStoreIds)
                            ->get()
                            ->keyBy('product_id');

                        foreach ($products as $product) {
                            $productId = $product['product_id'] ?? null;
                            $variantId = $product['variant_id'] ?? null;

                            if ($productId && isset($matchingProductDetails[$productId])) {
                                $productDetail = $matchingProductDetails[$productId];

                                // Get variant details for measurement
                                $variantDetail = null;
                                if ($variantId) {
                                    $variantDetail = DB::table('product_variants')
                                        ->select(
                                            'product_variants.measurement',
                                            'units.short_code as unit_short_code'
                                        )
                                        ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                                        ->where('product_variants.id', $variantId)
                                        ->first();
                                }

                                $key = $productId . '_' . $variantId;
                                $qty = $product['quantity'] ?? 1;
                                $measurement = $variantDetail->measurement ?? ($product['variant_measurement'] ?? '');
                                $unit = $variantDetail->unit_short_code ?? '';
                                $measurementDisplay = $measurement . ' ' . $unit;

                                if (isset($allProducts[$key])) {
                                    // Same product and variant - add quantity
                                    $allProducts[$key]['quantity'] += $qty;
                                } else {
                                    $allProducts[$key] = [
                                        'quantity' => (int) $qty,
                                        'item_name' => $product['product_name'] ?? $productDetail->product_name,
                                        'measurement' => trim($measurementDisplay),
                                        'source' => 'combo_item'
                                    ];
                                }
                            }
                        }
                    }
                }
            }

            // Convert to array
            $allItems = array_values($allProducts);

            // Get OTP, status and prep_time from order_seller_status_tracking table
            $otp = null;
            $trackingStatus = null;
            $prepTime = 0;

            if ($isZenfooStore) {
                // For Zenfoo store, get tracking info by any Zenfoo store_id (12 or 13).
                // Both rows are kept in sync (shared OTP, status, prep_time) by the admin
                // ZenfooStoreItemsController, so either row is canonical here.
                $trackingRecord = DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->whereIn('store_id', [12, 13])
                    ->first();
            } else {
                // For seller, get tracking info by seller_id
                $trackingRecord = DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->where('seller_id', $sellerId)
                    ->first();
            }

            // Initialize time calculation variables
            $timeRemaining = null;
            $completedBy = null;
            $prepTimeMinutes = 0;
            $prepTimeFormatted = null;
            $delayedTimeInMin = null;

            if ($trackingRecord) {
                $otp = $trackingRecord->otp ?? null;
                $trackingStatus = $trackingRecord->status ?? null;
                $delayedTimeInMin = $trackingRecord->delayed_time_in_min ?? 0;

                // Only return prep_time if status is 'assigned_to_seller'
                if ($trackingStatus === 'assigned_to_seller' && !empty($trackingRecord->prep_time)) {
                    $prepTimeData = $trackingRecord->prep_time;
                    $prepTime = $prepTimeData ?? 0;

                    // Parse prep_time - format is "[minutes, \"time_string\"]" e.g. "[6,\"3:40 PM\"]"
                    // minutes = how many more minutes needed when seller gave this update
                    // time_string = the time when seller gave this update
                    // So completed_by = time_string + minutes
                    $prepTimeDecoded = json_decode($prepTimeData, true);
                    if (is_array($prepTimeDecoded) && count($prepTimeDecoded) >= 2) {
                        $prepTimeMinutes = (int) $prepTimeDecoded[0]; // minutes needed
                        $prepTimeFormatted = $prepTimeDecoded[1]; // time when seller said it, e.g. "3:40 PM"

                        // Calculate using IST timezone
                        $istTimezone = new \DateTimeZone('Asia/Kolkata');
                        $now = new \DateTime('now', $istTimezone);

                        // Parse the time when seller gave the update
                        $todayDate = $now->format('Y-m-d');
                        $sellerUpdateTime = \DateTime::createFromFormat('Y-m-d g:i A', $todayDate . ' ' . $prepTimeFormatted, $istTimezone);

                        if ($sellerUpdateTime) {
                            // completed_by = seller_update_time + prep_time_minutes
                            $completedByDateTime = clone $sellerUpdateTime;
                            $completedByDateTime->modify("+{$prepTimeMinutes} minutes");
                            $completedBy = $completedByDateTime->format('g:i A'); // e.g. "3:46 PM"

                            // Calculate time remaining until order is ready (from now to completed_by)
                            $diffSeconds = $completedByDateTime->getTimestamp() - $now->getTimestamp();
                            $timeRemainingMinutes = (int) ceil($diffSeconds / 60);
                            $timeRemaining = $timeRemainingMinutes > 0 ? $timeRemainingMinutes : 0;
                        }
                    }
                }

                // Update driver_arrived_at_seller timestamp if not already set
                if (empty($trackingRecord->driver_arrived_at_seller)) {
                    $updateData = ['driver_arrived_at_seller' => now()];

                    if ($isZenfooStore) {
                        // Propagate "driver arrived" timestamp to both Zenfoo rows so
                        // the per-store views stay in sync.
                        DB::table('order_seller_status_tracking')
                            ->where('order_id', $orderId)
                            ->whereIn('store_id', [12, 13])
                            ->update($updateData);
                    } else {
                        DB::table('order_seller_status_tracking')
                            ->where('order_id', $orderId)
                            ->where('seller_id', $sellerId)
                            ->update($updateData);
                    }

                    Log::info('Driver arrived at seller location recorded', [
                        'order_id' => $orderId,
                        'seller_id' => $sellerId,
                        'delivery_boy_id' => $deliveryBoy->id,
                        'arrived_at' => now()->toDateTimeString()
                    ]);

                    // Send notification to seller/admin about driver arrival
                    try {
                        $driverName = $deliveryBoy->name ?? 'Driver';

                        if ($isZenfooStore) {
                            // For Zenfoo store (store_id 12), send web notification to admin panel
                            AdminNotificationService::send(
                                adminIds: null, // Send to all admins
                                title: 'Driver Arrived at Store',
                                message: "Driver {$driverName} has arrived at Zenfoo store for Order #{$orderId}. Please prepare the order for pickup.",
                                type: 'driver_arrived',
                                data: [
                                    'order_id' => $orderId,
                                    'store_id' => 12,
                                    'delivery_boy_id' => $deliveryBoy->id,
                                    'driver_name' => $driverName
                                ]
                            );

                            Log::info('Admin notification sent for driver arrival at Zenfoo store', [
                                'order_id' => $orderId,
                                'delivery_boy_id' => $deliveryBoy->id
                            ]);
                        } else {
                            // For seller, send notification via SellerNotificationService
                            SellerNotificationService::send(
                                sellerId: (int) $sellerId,
                                title: 'Driver Arrived',
                                message: "Driver {$driverName} has arrived at your store for Order #{$orderId}. Please prepare the order for pickup.",
                                image: '',
                                pageNavigation: 'order',
                                navigationId: $orderId,
                                extraData: [
                                    'delivery_boy_id' => $deliveryBoy->id,
                                    'driver_name' => $driverName
                                ]
                            );

                            Log::info('Seller notification sent for driver arrival', [
                                'order_id' => $orderId,
                                'seller_id' => $sellerId,
                                'delivery_boy_id' => $deliveryBoy->id
                            ]);
                        }
                    } catch (\Exception $notificationException) {
                        Log::error('Failed to send driver arrival notification', [
                            'order_id' => $orderId,
                            'seller_id' => $sellerId,
                            'is_zenfoo_store' => $isZenfooStore,
                            'error' => $notificationException->getMessage()
                        ]);
                        // Continue execution even if notification fails
                    }
                }
            }

            // Get store_id from tracking record
            $trackingStoreId = $trackingRecord->store_id ?? ($isZenfooStore ? 12 : null);

            // Fields needed by the driver app for the live wait-charge timer.
            // (Zenfoo orders skip waiting charges entirely — fields kept for
            // shape consistency; app ignores them when is_zenfoo_store=true.)
            $freshTracking = DB::table('order_seller_status_tracking')
                ->where('id', $trackingRecord->id)
                ->first();

            $waitChargeSettings = [
                'grace_minutes'        => (int) (Setting::get_value('vendor_wait_grace_minutes')     ?: 5),
                'charge_per_minute'    => (float) (Setting::get_value('vendor_wait_charge_per_minute') ?: 2),
                'cap'                  => (float) (Setting::get_value('vendor_wait_charge_cap')        ?: 50),
            ];

            $response = [
                'order_id' => (int) $orderId,
                'seller_id' => $isZenfooStore ? null : (int) $sellerId,
                'store_id' => $trackingStoreId ? (int) $trackingStoreId : null,
                'is_zenfoo_store' => $isZenfooStore,
                'items_count' => count($allItems),
                'items' => $allItems,
                'otp' => $otp,
                'status' => $trackingStatus,
                'prep_time' => $prepTime,
                // 'prep_time_minutes' => $prepTimeMinutes,
                // 'ready_by_time' => $prepTimeFormatted,
                'time_remaining_minutes' => $timeRemaining,
                'delayed_time_in_min' => $delayedTimeInMin,
                'completed_by' => $completedBy,
                'driver_arrived_at_seller' => $freshTracking->driver_arrived_at_seller ?? null,
                'first_prep_time_set_at'   => $freshTracking->first_prep_time_set_at ?? null,
                'first_prep_time_minutes'  => $freshTracking->first_prep_time_minutes ?? null,
                'wait_charge_settings'     => $waitChargeSettings,
                'seller' => [
                    'store_name' => $storeName,
                    'phone_number' => $storePhone,
                    'address' => $storeAddress,
                    'latitude' => $storeLatitude,
                    'longitude' => $storeLongitude
                ]
            ];

            return response()->json([
                'status' => 1,
                'message' => 'Seller order details retrieved successfully',
                'data' => $response
            ]);

        } catch (\Exception $e) {
            Log::error('Get seller order details failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Mark order as picked by driver
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAsDriverPicked(Request $request)
    {
        try {
            $orderId = $request->input('order_id');
            $sellerId = $request->input('seller_id');
            $storeId = $request->input('store_id');

            if (empty($orderId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            if (empty($sellerId) && empty($storeId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Either seller_id or store_id parameter is required'
                ], 400);
            }

            // Validate images are provided
            if (!$request->hasFile('images')) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Images are required to mark as picked'
                ], 400);
            }

            $images = $request->file('images');
            if (!is_array($images) || count($images) === 0) {
                return response()->json([
                    'status' => 0,
                    'message' => 'At least one image is required'
                ], 400);
            }

            // Get authenticated delivery boy
            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Check for active session
            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if (!$activeSession) {
                return response()->json([
                    'status' => 0,
                    'message' => 'No active delivery session'
                ], 400);
            }

            // Build query based on seller_id or store_id.
            // For Zenfoo stores (12 or 13), match either row — they are kept in sync
            // and represent one logical Zenfoo store.
            $query = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId);

            $isZenfooStorePickup = false;
            if (!empty($sellerId)) {
                $query->where('seller_id', $sellerId);
            } elseif (in_array((int) $storeId, [12, 13], true)) {
                $isZenfooStorePickup = true;
                $query->whereIn('store_id', [12, 13]);
            } else {
                $query->where('store_id', $storeId);
            }

            $trackingRecord = $query->first();

            if (!$trackingRecord) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order tracking record not found'
                ], 404);
            }

            // dd($trackingRecord !== 'given_to_delivery_partner');


            // Check if order status is 'given_to_delivery_partner'
            if ($trackingRecord->status !== 'given_to_delivery_partner') {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order cannot be marked as picked. OTP not verified'
                ], 400);
            }

            // Upload images and collect URLs
            $imageUrls = [];
            foreach ($images as $image) {
                $url = MediaUploadService::uploadWithFullUrl(
                    $image,
                    'delivery_boy/pickup_images',
                    'public'
                );
                $imageUrls[] = $url;
            }

            // Update is_driver_picked to 1 and store image URLs.
            // For Zenfoo stores (12 or 13), propagate to both rows.
            $query = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId);

            if (!empty($sellerId)) {
                $query->where('seller_id', $sellerId);
            } elseif ($isZenfooStorePickup) {
                $query->whereIn('store_id', [12, 13]);
            } else {
                $query->where('store_id', $storeId);
            }

            $pickedAt = now();

            $query->update([
                'is_driver_picked' => 1,
                'driver_picked_at' => $pickedAt,
                'driver_captured_images_when_marked_as_pickup' => json_encode($imageUrls, JSON_UNESCAPED_SLASHES)
            ]);

            // ─────────────────────────────────────────────────────────────────
            // Vendor waiting charge — regular sellers only (Zenfoo excluded).
            // Clock starts at max(driver_arrived_at_seller, vendor_promised_ready_at).
            // ─────────────────────────────────────────────────────────────────
            if (!$isZenfooStorePickup) {
                try {
                    $fresh = DB::table('order_seller_status_tracking')
                        ->where('id', $trackingRecord->id)
                        ->first();

                    $arrivedAt  = $fresh->driver_arrived_at_seller ?? null;
                    $firstSetAt = $fresh->first_prep_time_set_at ?? null;
                    $firstMin   = $fresh->first_prep_time_minutes ?? null;

                    if ($arrivedAt && $firstSetAt && $firstMin !== null) {
                        $grace = (int) (Setting::get_value('vendor_wait_grace_minutes')     ?: 5);
                        $rate  = (float) (Setting::get_value('vendor_wait_charge_per_minute') ?: 2);
                        $cap   = (float) (Setting::get_value('vendor_wait_charge_cap')        ?: 50);

                        $arrivedTs = \Carbon\Carbon::parse($arrivedAt);
                        $readyTs   = \Carbon\Carbon::parse($firstSetAt)->addMinutes((int) $firstMin);
                        $pickedTs  = \Carbon\Carbon::parse($pickedAt);

                        $effectiveStart = $arrivedTs->greaterThan($readyTs) ? $arrivedTs : $readyTs;
                        $waitMin = max(0, (int) floor(($pickedTs->getTimestamp() - $effectiveStart->getTimestamp()) / 60));

                        $billable = max(0, $waitMin - $grace);
                        $charge   = $cap > 0 ? min($billable * $rate, $cap) : ($billable * $rate);

                        DB::table('order_seller_status_tracking')
                            ->where('id', $trackingRecord->id)
                            ->update([
                                'vendor_wait_minutes' => $waitMin,
                                'vendor_wait_charge'  => $charge,
                            ]);

                        $orderTotal = DB::table('order_seller_status_tracking')
                            ->where('order_id', $orderId)
                            ->sum('vendor_wait_charge');

                        DB::table('orders')
                            ->where('id', $orderId)
                            ->update(['total_vendor_wait_charge' => $orderTotal]);

                        Log::info('Vendor wait charge computed', [
                            'order_id'      => $orderId,
                            'seller_id'     => $fresh->seller_id,
                            'tracking_id'   => $fresh->id,
                            'arrived_at'    => $arrivedTs->toDateTimeString(),
                            'ready_at'      => $readyTs->toDateTimeString(),
                            'picked_at'     => $pickedTs->toDateTimeString(),
                            'wait_minutes'  => $waitMin,
                            'billable_min'  => $billable,
                            'grace'         => $grace,
                            'rate'          => $rate,
                            'cap'           => $cap,
                            'charge'        => $charge,
                            'order_total'   => $orderTotal,
                        ]);
                    } else {
                        Log::warning('Vendor wait charge skipped — missing inputs', [
                            'order_id'      => $orderId,
                            'tracking_id'   => $trackingRecord->id,
                            'has_arrived'   => (bool) $arrivedAt,
                            'has_first_set' => (bool) $firstSetAt,
                            'has_first_min' => $firstMin !== null,
                        ]);
                    }
                } catch (\Exception $waitChargeException) {
                    Log::error('Vendor wait charge calculation failed', [
                        'order_id'    => $orderId,
                        'tracking_id' => $trackingRecord->id,
                        'error'       => $waitChargeException->getMessage(),
                    ]);
                    // Do NOT fail the pickup — wait charge is a derived value.
                }
            }

            // Check if all rows for this order_id have is_driver_picked = 1
            $pendingPickups = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('is_driver_picked', 0)
                ->count();

            // If all items are picked, update order active_status to 5
            if ($pendingPickups === 0) {
                DB::table('orders')
                    ->where('id', $orderId)
                    ->update(['active_status' => 5]);
            }

            return response()->json([
                'status' => 1,
                'message' => 'Order marked as picked by driver successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Mark as driver picked failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Get complete order summary with all items from all sellers
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getOrderSummary(Request $request)
    {
        try {
            $orderId = $request->input('order_id');

            if (empty($orderId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            // Get authenticated delivery boy
            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Check for active session
            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if (!$activeSession) {
                return response()->json([
                    'status' => 0,
                    'message' => 'No active delivery session'
                ], 400);
            }

            // Get order with customer details
            $order = DB::table('orders')
                ->join('users', 'users.id', '=', 'orders.user_id')
                ->leftJoin('user_addresses', 'user_addresses.id', '=', 'orders.address_id')
                ->where('orders.id', $orderId)
                ->select(
                    'orders.id',
                    'orders.address',
                    'orders.latitude',
                    'orders.longitude',
                    'orders.cart_metadata',
                    'orders.payment_method',
                    'users.id as customer_id',
                    // Receiver name from the delivery address, falling back to the account name.
                    DB::raw("COALESCE(NULLIF(TRIM(user_addresses.name), ''), NULLIF(TRIM(users.name), ''), 'Customer') as customer_name"),
                    'users.mobile as customer_phone'
                )
                ->first();

            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            // Get seller count from order_seller_status_tracking
            $sellerCount = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->count();

            // Determine order type (single or multi)
            $orderType = $sellerCount > 1 ? 'multi_order' : 'single_order';

            // Parse cart_metadata for billing info
            $cartMeta = json_decode($order->cart_metadata, true);
            $totalPrice = $cartMeta['billing_summary']['to_be_paid'] ?? 0;

            // Get all order items
            $orderItems = DB::table('order_items')
                ->select(
                    'order_items.id',
                    'order_items.quantity',
                    'order_items.product_variant_id',
                    'products.id as product_id',
                    'products.name as product_name',
                    'products.store_id',
                    'product_variants.measurement',
                    'units.short_code as unit_short_code'
                )
                ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                ->where('order_items.order_id', $orderId)
                ->get();

            // Build items list with aggregation by product + variant
            $allProducts = [];

            foreach ($orderItems as $item) {
                $key = $item->product_id . '_' . $item->product_variant_id;
                $measurementDisplay = $item->measurement . ' ' . ($item->unit_short_code ?? '');

                if (isset($allProducts[$key])) {
                    $allProducts[$key]['quantity'] += $item->quantity;
                } else {
                    $allProducts[$key] = [
                        'item_name' => $item->product_name,
                        'quantity' => (int) $item->quantity,
                        'measurement' => trim($measurementDisplay),
                    ];
                }
            }

            // Get combo items for this order
            $comboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->get();

            // Process combo items - extract all products
            foreach ($comboItems as $combo) {
                if (!empty($combo->products)) {
                    $products = json_decode($combo->products, true);
                    if (is_string($products)) {
                        $products = json_decode($products, true);
                    }

                    if (is_array($products)) {
                        foreach ($products as $product) {
                            $productId = $product['product_id'] ?? null;
                            $variantId = $product['variant_id'] ?? null;

                            if ($productId) {
                                // Get variant details for measurement
                                $variantDetail = null;
                                if ($variantId) {
                                    $variantDetail = DB::table('product_variants')
                                        ->select(
                                            'product_variants.measurement',
                                            'units.short_code as unit_short_code'
                                        )
                                        ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                                        ->where('product_variants.id', $variantId)
                                        ->first();
                                }

                                $key = $productId . '_' . $variantId;
                                $qty = $product['quantity'] ?? 1;
                                $measurement = $variantDetail->measurement ?? ($product['variant_measurement'] ?? '');
                                $unit = $variantDetail->unit_short_code ?? '';
                                $measurementDisplay = $measurement . ' ' . $unit;

                                if (isset($allProducts[$key])) {
                                    $allProducts[$key]['quantity'] += $qty;
                                } else {
                                    $allProducts[$key] = [
                                        'item_name' => $product['product_name'] ?? '',
                                        'quantity' => (int) $qty,
                                        'measurement' => trim($measurementDisplay),
                                    ];
                                }
                            }
                        }
                    }
                }
            }

            // Convert to array
            $allItems = array_values($allProducts);
            $itemCount = count($allItems);

            $response = [
                'order_id' => (int) $orderId,
                'order_type' => $orderType,
                'payment_mode' => $order->payment_method,
                'total_price' => (float) $totalPrice,
                'item_count' => $itemCount,
                'items' => $allItems,
                'customer' => [
                    'id' => (int) $order->customer_id,
                    'name' => $order->customer_name,
                    'phone' => $order->customer_phone,
                    'address' => $order->address,
                    'latitude' => $order->latitude ? (float) $order->latitude : null,
                    'longitude' => $order->longitude ? (float) $order->longitude : null,
                ],
            ];

            return response()->json([
                'status' => 1,
                'message' => 'Order summary retrieved successfully',
                'data' => $response
            ]);

        } catch (\Exception $e) {
            Log::error('Get order summary failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Collect cash from customer for an order
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function collectCash(Request $request)
    {
        try {
            $orderId = $request->input('order_id');
            $amount = $request->input('amount');

            Log::info('Collect cash API called', [
                'order_id' => $orderId,
                'amount' => $amount,
                'timestamp' => now()->toDateTimeString()
            ]);

            // Validate required fields
            if (empty($orderId)) {
                Log::warning('Collect cash validation failed - order_id missing', [
                    'order_id' => $orderId
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            if (!isset($amount) || $amount === '') {
                Log::warning('Collect cash validation failed - amount missing', [
                    'order_id' => $orderId,
                    'amount' => $amount
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'amount parameter is required'
                ], 400);
            }

            // Validate images are provided
            $images = $request->file('images');

            // Handle both single file and array of files
            if (empty($images)) {
                Log::warning('Collect cash validation failed - no images provided', [
                    'order_id' => $orderId,
                    'amount' => $amount
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'Images are required for cash collection'
                ], 400);
            }

            // Convert single file to array for consistent processing
            if (!is_array($images)) {
                $images = [$images];
            }

            if (count($images) === 0) {
                Log::warning('Collect cash validation failed - empty images array', [
                    'order_id' => $orderId,
                    'amount' => $amount
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'At least one image is required'
                ], 400);
            }

            Log::info('Images received for cash collection', [
                'order_id' => $orderId,
                'image_count' => count($images)
            ]);

            $amount = floatval($amount);

            // Check if order qualifies for multi-order bonus
            // Bonus is given only if order has store_id 15 along with other store_ids
            $storeIds = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->pluck('store_id')
                ->toArray();

            Log::info('Store IDs retrieved for bonus calculation', [
                'order_id' => $orderId,
                'store_ids' => $storeIds
            ]);

            $bonusAmount = 0;
            $hasStore15 = in_array(15, $storeIds);
            $hasOtherStores = \count(array_filter($storeIds, fn($id) => $id != 15)) > 0;

            if ($hasStore15 && $hasOtherStores) {
                $bonusAmount = floatval(Setting::get_value('multi_order_bonus') ?: 0);
                Log::info('Multi-order bonus calculated', [
                    'order_id' => $orderId,
                    'bonus_amount' => $bonusAmount,
                    'has_store_15' => $hasStore15,
                    'has_other_stores' => $hasOtherStores
                ]);
            }

            // Get authenticated delivery boy
            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                Log::warning('Collect cash - unauthorized driver attempt', [
                    'order_id' => $orderId
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            Log::info('Driver authenticated for cash collection', [
                'order_id' => $orderId,
                'driver_id' => $driver_data_admin->id
            ]);

            $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();
            if (!$deliveryBoy) {
                Log::warning('Collect cash - delivery boy not found', [
                    'order_id' => $orderId,
                    'admin_id' => $driver_data_admin->id
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Get order
            $order = Order::find($orderId);

            if (!$order) {
                Log::warning('Collect cash - order not found', [
                    'order_id' => $orderId
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            Log::info('Order retrieved for cash collection', [
                'order_id' => $orderId,
                'customer_id' => $order->user_id,
                'delivery_boy_id' => $order->delivery_boy_id,
                'payment_method' => $order->payment_method,
                'cash_collected' => $order->cash_collected
            ]);

            // Check if order is assigned to this delivery boy
            if ($order->delivery_boy_id != $deliveryBoy->id) {
                Log::warning('Collect cash - order not assigned to delivery boy', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id,
                    'order_delivery_boy_id' => $order->delivery_boy_id
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'This order is not assigned to you'
                ], 403);
            }

            // Check if payment method is COD
            if ($order->payment_method !== 'COD') {
                Log::warning('Collect cash - invalid payment method', [
                    'order_id' => $orderId,
                    'payment_method' => $order->payment_method
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'This order is not a Cash on Delivery order'
                ], 400);
            }

            // Check if cash is already collected
            if ($order->cash_collected) {
                Log::warning('Collect cash - cash already collected', [
                    'order_id' => $orderId,
                    'cash_collected_at' => $order->cash_collected_at
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'Cash has already been collected for this order'
                ], 400);
            }

            // Extract cart_metadata for amount validation and other fields
            $cartMetadata = $order->cart_metadata;
            if (is_string($cartMetadata)) {
                $cartMetadata = json_decode($cartMetadata, true);
            }

            // Get the amount to be collected from cart_metadata (to_be_paid from billing_summary)
            $expectedAmount = floatval($cartMetadata['billing_summary']['to_be_paid'] ?? ($order->remaining_final ?? $order->final_total));

            Log::info('Amount validation for cash collection', [
                'order_id' => $orderId,
                'provided_amount' => $amount,
                'expected_amount' => $expectedAmount,
                'amount_match' => abs($amount - $expectedAmount) <= 0.01
            ]);

            // Check if amount matches
            if (abs($amount - $expectedAmount) > 0.01) {
                Log::warning('Cash collection - amount mismatch', [
                    'order_id' => $orderId,
                    'provided_amount' => $amount,
                    'expected_amount' => $expectedAmount,
                    'difference' => abs($amount - $expectedAmount)
                ]);
                return response()->json([
                    'status' => 0,
                    'message' => 'Amount mismatch. The total order amount is ₹' . number_format($expectedAmount, 2) . '. Please collect the exact amount from the customer.',
                    'data' => [
                        'expected_amount' => $expectedAmount,
                        'provided_amount' => $amount
                    ]
                ], 400);
            }

            // Get delivery_tip, delivery_charge, and rain_surcharge from cart_metadata
            $deliveryTip = floatval($cartMetadata['cart_info']['delivery_tip'] ?? 0);
            $deliveryCharge = floatval($cartMetadata['cart_info']['delivery_charge'] ?? ($cartMetadata['billing_summary']['delivery_charge'] ?? 0));
            $rainSurcharge = floatval($order->rain_surcharge_amount ?? 0);

            // Vendor wait charge for this order — already deducted from vendor payout
            // in SellerOrderSettlementService. The completing driver receives 100%.
            $vendorWaitCharge = floatval($order->total_vendor_wait_charge ?? 0);

            // Check if this is a multi-driver order (emergency driver change happened)
            $driverDistanceSplit = $order->driver_distance_split ? json_decode($order->driver_distance_split, true) : null;
            $isMultiDriverOrder = !empty($driverDistanceSplit) && count($driverDistanceSplit['drivers'] ?? []) > 0;

            Log::info('Checking multi-driver order status', [
                'order_id' => $orderId,
                'is_multi_driver' => $isMultiDriverOrder,
                'previous_drivers' => $isMultiDriverOrder ? array_keys($driverDistanceSplit['drivers']) : []
            ]);

            // Default single-driver calculation
            $driverEarnings = $deliveryTip + $deliveryCharge + $rainSurcharge + $bonusAmount + $vendorWaitCharge;
            $adminCash = $amount - $driverEarnings;

            // A negative admin_cash is valid and means Zenfoo owes the driver the
            // difference — same convention as the prepaid path below. This is the
            // free-delivery case: the customer was charged 0 for delivery, so the
            // collected cash does not cover the driver's delivery charge and the
            // owner bears it. Never trim $driverEarnings down to the cash
            // collected, that would silently pay the driver less than they earned.
            if ($adminCash < 0) {
                Log::info('Cash collection - admin owes driver the shortfall', [
                    'order_id' => $orderId,
                    'collected_from_customer' => $amount,
                    'driver_earnings' => $driverEarnings,
                    'admin_owes' => abs($adminCash),
                    'is_free_delivery' => $cartMetadata['billing_summary']['is_free_delivery'] ?? null,
                ]);
            }

            // Start transaction
            DB::beginTransaction();

            Log::info('Starting database transaction for cash collection', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoy->id,
                'amount' => $amount,
                'driver_earnings' => $driverEarnings,
                'admin_cash' => $adminCash
            ]);

            try {
                // Upload images and collect URLs
                $imageUrls = [];
                foreach ($images as $image) {
                    try {
                        $url = MediaUploadService::uploadWithFullUrl(
                            $image,
                            'delivery_boy/cash_collection_images',
                            'public'
                        );
                        $imageUrls[] = $url;
                        Log::info('Image uploaded for cash collection', [
                            'order_id' => $orderId,
                            'image_url' => $url
                        ]);
                    } catch (\Exception $uploadEx) {
                        Log::error('Image upload failed during cash collection', [
                            'order_id' => $orderId,
                            'error' => $uploadEx->getMessage()
                        ]);
                        throw $uploadEx;
                    }
                }

                Log::info('All images uploaded successfully', [
                    'order_id' => $orderId,
                    'total_images' => \count($imageUrls)
                ]);

                // Handle multi-driver order or single-driver order
                if ($isMultiDriverOrder) {
                    Log::info('Processing multi-driver order completion', [
                        'order_id' => $orderId,
                        'completing_driver_id' => $deliveryBoy->id
                    ]);

                    // Calculate current driver's billable distance
                    $currentDriverFirestore = \App\Services\FirestoreDeliveryBoyService::getDeliveryBoyDocument($deliveryBoy->id);
                    $currentDriverBillableDistance = 0;

                    if ($currentDriverFirestore && isset($currentDriverFirestore['current_order'])) {
                        $sellersVisited = $currentDriverFirestore['current_order']['order_details']['sellers_visit_order'] ?? [];

                        // This driver reached the customer, so their run includes
                        // the last stop → customer leg. It lives outside
                        // sellers_visit_order, and on a reassigned order it can be
                        // most of what they rode.
                        $currentDriverBillableDistance = \App\Services\FirestoreDeliveryBoyService::calculateBillableDistance($sellersVisited, [
                            'delivered_to' => [
                                'latitude' => (float) $order->latitude,
                                'longitude' => (float) $order->longitude
                            ]
                        ]);

                        Log::info('Current driver billable distance calculated', [
                            'order_id' => $orderId,
                            'driver_id' => $deliveryBoy->id,
                            'billable_distance_km' => $currentDriverBillableDistance,
                            'total_stops' => count($sellersVisited)
                        ]);
                    }

                    // Add current driver to split data
                    $driverDistanceSplit['drivers'][$deliveryBoy->id] = [
                        'name' => $deliveryBoy->name,
                        'billable_distance_km' => $currentDriverBillableDistance,
                        'percentage' => null,
                        'earnings' => null
                    ];

                    // Calculate total billable distance
                    $totalBillableDistance = array_sum(array_column($driverDistanceSplit['drivers'], 'billable_distance_km'));
                    $driverDistanceSplit['total_billable_distance_km'] = $totalBillableDistance;

                    Log::info('Total billable distance calculated', [
                        'order_id' => $orderId,
                        'total_billable_km' => $totalBillableDistance,
                        'drivers_count' => count($driverDistanceSplit['drivers'])
                    ]);

                    // Calculate split for each driver and create transactions
                    foreach ($driverDistanceSplit['drivers'] as $driverId => &$driverData) {
                        $isCompletingDriver = ($driverId == $deliveryBoy->id);

                        // Calculate percentage
                        $driverData['percentage'] = $totalBillableDistance > 0
                            ? ($driverData['billable_distance_km'] / $totalBillableDistance) * 100
                            : 0;

                        // Calculate earnings
                        $driverDeliveryCharge = $totalBillableDistance > 0
                            ? ($deliveryCharge * $driverData['percentage']) / 100
                            : 0;

                        // Only completing driver gets tip, bonus and waiting-charge bonus
                        $driverTip = $isCompletingDriver ? $deliveryTip : 0;
                        $driverBonus = $isCompletingDriver ? $bonusAmount : 0;
                        $driverWaitCharge = $isCompletingDriver ? $vendorWaitCharge : 0;

                        // Rain surcharge split proportionally
                        $driverRainSurcharge = $totalBillableDistance > 0
                            ? ($rainSurcharge * $driverData['percentage']) / 100
                            : 0;

                        $driverTotalEarnings = $driverDeliveryCharge + $driverTip + $driverRainSurcharge + $driverBonus + $driverWaitCharge;
                        $driverData['earnings'] = $driverTotalEarnings;

                        // Only completing driver collects cash
                        $driverAdminCash = $isCompletingDriver ? ($amount - $driverEarnings) : 0;

                        // Create transaction for this driver
                        $transaction = new DeliveryBoyTransaction();
                        $transaction->user_id = $order->user_id;
                        $transaction->order_id = $order->id;
                        $transaction->delivery_boy_id = $driverId;
                        $transaction->type = DeliveryBoyTransaction::$paymentTypeCod;
                        $transaction->amount = $isCompletingDriver ? $amount : 0;
                        $transaction->delivery_charge = $driverDeliveryCharge;
                        $transaction->delivery_tip = $driverTip;
                        $transaction->rain_surcharge = $driverRainSurcharge;
                        $transaction->bonus_amount = $driverBonus;
                        $transaction->vendor_wait_charge = $driverWaitCharge;
                        $transaction->driver_earnings = $driverTotalEarnings;
                        $transaction->admin_cash = $driverAdminCash;
                        $transaction->is_hand_cash = $isCompletingDriver ? 1 : 0;
                        $transaction->status = DeliveryBoyTransaction::$statusSuccess;
                        $transaction->message = $isCompletingDriver
                            ? sprintf('Order completed - traveled %.2fkm (%.1f%%)', $driverData['billable_distance_km'], $driverData['percentage'])
                            : sprintf('Partial delivery - traveled %.2fkm (%.1f%%)', $driverData['billable_distance_km'], $driverData['percentage']);
                        $transaction->transaction_date = now()->toDateTimeString();
                        $transaction->settled_with_admin = false;
                        $transaction->save();

                        Log::info('Multi-driver transaction created', [
                            'order_id' => $orderId,
                            'transaction_id' => $transaction->id,
                            'driver_id' => $driverId,
                            'driver_name' => $driverData['name'],
                            'is_completing_driver' => $isCompletingDriver,
                            'billable_distance_km' => $driverData['billable_distance_km'],
                            'percentage' => $driverData['percentage'],
                            'delivery_charge' => $driverDeliveryCharge,
                            'tip' => $driverTip,
                            'rain_surcharge' => $driverRainSurcharge,
                            'bonus' => $driverBonus,
                            'total_earnings' => $driverTotalEarnings,
                            'admin_cash' => $driverAdminCash
                        ]);
                    }

                    // Update order with final split data
                    $order->driver_distance_split = json_encode($driverDistanceSplit);

                    Log::info('Multi-driver split completed', [
                        'order_id' => $orderId,
                        'total_billable_km' => $totalBillableDistance,
                        'total_delivery_charge' => $deliveryCharge,
                        'drivers' => array_map(function($d) {
                            return [
                                'name' => $d['name'],
                                'distance_km' => $d['billable_distance_km'],
                                'percentage' => $d['percentage'],
                                'earnings' => $d['earnings']
                            ];
                        }, $driverDistanceSplit['drivers'])
                    ]);

                } else {
                    // Single driver - existing logic
                    Log::info('Processing single-driver order completion', [
                        'order_id' => $orderId,
                        'driver_id' => $deliveryBoy->id
                    ]);

                    $transaction = new DeliveryBoyTransaction();
                    $transaction->user_id = $order->user_id;
                    $transaction->order_id = $order->id;
                    $transaction->delivery_boy_id = $deliveryBoy->id;
                    $transaction->type = DeliveryBoyTransaction::$paymentTypeCod;
                    $transaction->amount = $amount;
                    $transaction->delivery_charge = $deliveryCharge;
                    $transaction->delivery_tip = $deliveryTip;
                    $transaction->rain_surcharge = $rainSurcharge;
                    $transaction->bonus_amount = $bonusAmount;
                    $transaction->vendor_wait_charge = $vendorWaitCharge;
                    $transaction->driver_earnings = $driverEarnings;
                    $transaction->admin_cash = $adminCash;
                    $transaction->is_hand_cash = 1;
                    $transaction->status = DeliveryBoyTransaction::$statusSuccess;
                    $transaction->message = 'Cash collected from customer for order #' . $order->id;
                    $transaction->transaction_date = now()->toDateTimeString();
                    $transaction->settled_with_admin = false;
                    $transaction->save();

                    Log::info('Single-driver transaction created', [
                        'order_id' => $orderId,
                        'transaction_id' => $transaction->id,
                        'amount' => $amount,
                        'driver_earnings' => $driverEarnings,
                        'admin_cash' => $adminCash,
                        'bonus_amount' => $bonusAmount
                    ]);
                }

                $deliveryBoy->save();

                Log::info('Delivery boy updated for cash collection', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id
                ]);

                // Get current time string for consistency
                $currentDateTime = now()->toDateTimeString();

                // Update order cash_collected status, images and bonus details
                $order->cash_collected = true;
                $order->cash_collected_at = $currentDateTime;
                $order->delivery_time_before_images = $imageUrls;
                $order->delivered_at_time = now();
                $order->active_status = 6;

                // Store bonus details if bonus amount is provided
                if ($bonusAmount > 0) {
                    $order->delivery_boy_bonus_amount = $bonusAmount;
                    $order->delivery_boy_bonus_details = [
                        'type' => 'multi order bonus',
                        'amount' => $bonusAmount,
                        'collected_at' => $currentDateTime
                    ];
                }

                $order->save();

                // Cash collection also completes the delivery, so the referral
                // gate has to run here too. Idempotent if markDelivered also ran.
                CommonHelper::processReferralForDeliveredOrder($order->id);

                Log::info('Order updated with cash collection details', [
                    'order_id' => $orderId,
                    'cash_collected_at' => $currentDateTime,
                    'active_status' => 6,
                    'has_bonus' => $bonusAmount > 0,
                    'bonus_amount' => $bonusAmount
                ]);

                // Update delivery_boy_daily_tracking table
                $todayDate = now()->format('Y-m-d');
                $dailyTracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->where('tracking_date', $todayDate)
                    ->first();

                Log::info('Fetching daily tracking record', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id,
                    'tracking_date' => $todayDate
                ]);

                if (!$dailyTracking) {
                    Log::error('Daily tracking record not found during cash collection', [
                        'order_id' => $orderId,
                        'delivery_boy_id' => $deliveryBoy->id,
                        'tracking_date' => $todayDate
                    ]);
                    DB::rollBack();
                    return response()->json([
                        'status' => 0,
                        'message' => 'Daily tracking record not found for today. Please ensure you are logged in.'
                    ], 404);
                }

                // Add driver earnings (total amount minus admin_cash) and increment orders_delivered
                $previousEarnings = floatval($dailyTracking->total_earnings);
                $previousOrdersDelivered = intval($dailyTracking->orders_delivered);

                $dailyTracking->total_earnings = $previousEarnings + $driverEarnings;
                $dailyTracking->orders_delivered = $previousOrdersDelivered + 1;
                $dailyTracking->last_activity_at = now();
                $dailyTracking->save();

                // Increment face verification counter and check if verification needed
                $faceVerificationRequired = false;
                $deliveryBoy->orders_since_last_face_verify = intval($deliveryBoy->orders_since_last_face_verify) + 1;
                if ($deliveryBoy->orders_since_last_face_verify >= 10) {
                    $deliveryBoy->is_available = 0;
                    $faceVerificationRequired = true;
                    Log::info('Face verification required - driver made offline', [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'orders_since_last_face_verify' => $deliveryBoy->orders_since_last_face_verify
                    ]);
                }
                $deliveryBoy->save();

                Log::info('Daily tracking record updated for cash collection', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id,
                    'previous_earnings' => $previousEarnings,
                    'new_earnings' => $dailyTracking->total_earnings,
                    'driver_earnings_added' => $driverEarnings,
                    'previous_orders_delivered' => $previousOrdersDelivered,
                    'new_orders_delivered' => $dailyTracking->orders_delivered
                ]);

                // Settle order amounts for sellers (credit their wallets)
                // This must be inside transaction to ensure atomicity
                $sellerSettlement = SellerOrderSettlementService::settleOrderForSellers($order->id);
                Log::info('Seller settlement completed for COD cash collection', [
                    'order_id' => $orderId,
                    'result' => $sellerSettlement
                ]);

                // Update incentive progress
                // This must be inside transaction to ensure atomicity
                DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion($deliveryBoy, $order);
                Log::info('Incentive progress updated for cash collection', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id
                ]);

                // Process referral tracking and bonus payment
                // This must be inside transaction to ensure atomicity
                $referralResult = ReferralBonusService::processOrderCompletion($deliveryBoy, $order->id);
                if ($referralResult['success'] && isset($referralResult['bonus_amount'])) {
                    Log::info('Referral bonus processed for COD order', [
                        'order_id' => $order->id,
                        'delivery_boy_id' => $deliveryBoy->id,
                        'result' => $referralResult
                    ]);
                }

                // Commit transaction after all critical operations complete successfully
                DB::commit();

                Log::info('Database transaction committed for cash collection', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id
                ]);

                // Send referral bonus notifications if applicable (after transaction commit)
                if (isset($referralResult['should_send_notifications']) && $referralResult['should_send_notifications'] && isset($referralResult['tracking_id'])) {
                    try {
                        $tracking = DeliveryBoyReferralTracking::find($referralResult['tracking_id']);
                        if ($tracking) {
                            ReferralBonusService::sendBonusPaidNotifications($tracking);
                        }
                    } catch (\Exception $e) {
                        Log::error('Failed to send referral bonus notifications', [
                            'order_id' => $order->id,
                            'error' => $e->getMessage(),
                            'trace' => $e->getTraceAsString()
                        ]);
                        // Continue execution - notification failure should not break the flow
                    }
                }

                // Send notification to customer that order has been delivered
                try {
                    if ($order->user_id) {
                        CustomerNotificationService::send(
                            customerId: $order->user_id,
                            title: 'Order Delivered!',
                            message: "Your order #{$order->id} has been delivered successfully. Thank you for ordering with Zenfoo!",
                            image: '',
                            pageNavigation: 'order',
                            navigationId: $order->id
                        );
                        Log::info('Customer notification sent for COD order delivery', [
                            'order_id' => $order->id,
                            'customer_id' => $order->user_id
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error('Failed to send customer notification for COD order delivery', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString()
                    ]);
                    // Continue execution - notification failure should not break the flow
                }

                // Send notification to admin about order delivered
                try {
                    AdminNotificationService::notifyOrderStatusChange($order->id, 'Delivered', "#{$order->id}");
                    Log::info('Admin notification sent for order delivered (COD)', [
                        'order_id' => $order->id
                    ]);
                } catch (\Exception $e) {
                    Log::error('Failed to send admin notification for order delivered (COD)', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString()
                    ]);
                    // Continue execution - notification failure should not break the flow
                }

                // Calculate travel time
                $travelTimeMinutes = null;
                if ($order->driver_accepted_at_time) {
                    $acceptedAt = \Carbon\Carbon::parse($order->driver_accepted_at_time);
                    $deliveredAt = \Carbon\Carbon::parse($order->delivered_at_time);
                    $travelTimeMinutes = $acceptedAt->diffInMinutes($deliveredAt);
                    Log::info('Travel time calculated for cash collection', [
                        'order_id' => $orderId,
                        'travel_time_minutes' => $travelTimeMinutes
                    ]);
                }

                Log::info('Cash collection completed successfully', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id,
                    'transaction_id' => $transaction->id,
                    'total_collected' => $amount,
                    'delivery_charge' => $deliveryCharge,
                    'delivery_tip' => $deliveryTip,
                    'bonus_amount' => $bonusAmount,
                    'driver_earnings' => $driverEarnings,
                    'admin_cash' => $adminCash,
                    'images_count' => \count($imageUrls),
                    'travel_time_minutes' => $travelTimeMinutes
                ]);

                return response()->json([
                    'status' => 1,
                    'message' => 'Cash collected successfully',
                    'data' => [
                        'order_id' => $order->id,
                        'total_collected' => $amount,
                        'delivery_charge' => $deliveryCharge,
                        'delivery_tip' => $deliveryTip,
                        'bonus_amount' => $bonusAmount,
                        'vendor_wait_charge' => $vendorWaitCharge,
                        'driver_earnings' => $driverEarnings,
                        'admin_cash' => $adminCash,
                        'transaction_id' => $transaction->id,
                        'is_rain_surcharge' => (bool) $order->is_rain_surcharge,
                        'rain_surcharge_amount' => $rainSurcharge,
                        'delivery_time_before_images' => $imageUrls,
                        // 'cash_to_settle_with_admin' => $deliveryBoy->cash_received,
                        'travel_time_minutes' => $travelTimeMinutes,
                        'face_verification_required' => $faceVerificationRequired
                    ]
                ]);

            } catch (\Exception $e) {
                Log::error('Cash collection transaction failed', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id ?? null,
                    'error' => $e->getMessage(),
                    'error_code' => $e->getCode(),
                    'trace' => $e->getTraceAsString()
                ]);

                DB::rollBack();
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('Cash collection API failed', [
                'order_id' => $orderId ?? null,
                'amount' => $amount ?? null,
                'error' => $e->getMessage(),
                'error_code' => $e->getCode(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Settle cash with admin (driver pays collected cash to admin)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function settleCash(Request $request)
    {
        try {
            $transactionIds = $request->input('transaction_ids');

            // Validate required fields
            if (empty($transactionIds)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'transaction_ids parameter is required'
                ], 400);
            }

            // Convert to array if string
            if (is_string($transactionIds)) {
                $transactionIds = array_map('trim', explode(',', $transactionIds));
            }

            // Get authenticated delivery boy
            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Get the transactions to settle (only unsettled COD transactions belonging to this driver)
            $transactionsToSettle = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('id', $transactionIds)
                ->where('type', DeliveryBoyTransaction::$paymentTypeCod)
                ->where('settled_with_admin', false)
                ->get();

            if ($transactionsToSettle->isEmpty()) {
                return response()->json([
                    'status' => 0,
                    'message' => 'No valid unsettled transactions found for the provided IDs'
                ], 400);
            }

            // Calculate total amount to settle. For a COD transaction admin_cash is
            // already "collected from customer minus what the driver earned", so it
            // is exactly what the driver hands over — and it is negative on free
            // delivery orders, where Zenfoo owes the driver instead. Summing
            // admin_cash directly nets those against each other; falling back to
            // $txn->amount here would demand the full collected cash from the
            // driver and swallow their earnings on precisely those orders.
            $totalAmountToSettle = $transactionsToSettle->sum(function ($txn) {
                return floatval($txn->admin_cash);
            });

            // Start transaction
            DB::beginTransaction();

            try {
                // Get current time string for consistency
                $currentDateTime = now()->toDateTimeString();

                // Create delivery boy transaction record for settlement
                $settlementTransaction = new DeliveryBoyTransaction();
                $settlementTransaction->user_id = 0;
                $settlementTransaction->order_id = 0;
                $settlementTransaction->delivery_boy_id = $deliveryBoy->id;
                $settlementTransaction->type = 'delivery_boy_cash_collection';
                $settlementTransaction->amount = $totalAmountToSettle;
                $settlementTransaction->admin_cash = $totalAmountToSettle;
                $settlementTransaction->status = DeliveryBoyTransaction::$statusSuccess;
                $settlementTransaction->message = 'Cash settled with admin for ' . count($transactionsToSettle) . ' transactions';
                $settlementTransaction->transaction_date = $currentDateTime;
                $settlementTransaction->settled_with_admin = true;
                $settlementTransaction->settled_at = $currentDateTime;
                $settlementTransaction->save();

                // Mark selected transactions as settled
                $settledOrders = [];
                $settledTransactionIds = [];
                foreach ($transactionsToSettle as $txn) {
                    $txn->settled_with_admin = true;
                    $txn->settled_at = $currentDateTime;
                    $txn->save();
                    $settledOrders[] = $txn->order_id;
                    $settledTransactionIds[] = $txn->id;
                }

                // Calculate remaining cash in hand from unsettled transactions
                $remainingCashInHand = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                    ->where('type', DeliveryBoyTransaction::$paymentTypeCod)
                    ->where('settled_with_admin', false)
                    ->sum('admin_cash');

                DB::commit();

                return response()->json([
                    'status' => 1,
                    'message' => 'Cash settled successfully',
                    'data' => [
                        'amount_settled' => $totalAmountToSettle,
                        'settlement_transaction_id' => $settlementTransaction->id,
                        'settled_transaction_ids' => $settledTransactionIds,
                        'settled_orders' => $settledOrders,
                        'remaining_cash_in_hand' => floatval($remainingCashInHand)
                    ]
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('Cash settlement failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Mark prepaid order as delivered (for non-COD orders)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markDelivered(Request $request)
    {
        try {
            $orderId = $request->input('order_id');

            // Validate required fields
            if (empty($orderId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            // Debug logging for file upload
            Log::info('Mark Delivered - Request Debug:', [
                'has_file_images' => $request->hasFile('images'),
                'all_files' => $request->allFiles(),
                'file_keys' => array_keys($request->allFiles()),
                'content_type' => $request->header('Content-Type'),
            ]);

            // Validate images are provided - check multiple possible keys
            $images = $request->file('images');

            // If images[] was used, Laravel might put it under 'images' as array
            if (empty($images)) {
                // Try to get from allFiles
                $allFiles = $request->allFiles();
                if (isset($allFiles['images'])) {
                    $images = $allFiles['images'];
                }
            }

            Log::info('Mark Delivered - Images found:', [
                'images' => $images,
                'images_type' => gettype($images),
                'is_array' => is_array($images),
            ]);

            // Handle both single file and array of files
            if (empty($images)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Images are required for delivery confirmation',
                    'debug' => [
                        'all_files' => array_keys($request->allFiles()),
                        'has_file' => $request->hasFile('images'),
                    ]
                ], 400);
            }

            // Convert single file to array for consistent processing
            if (!is_array($images)) {
                $images = [$images];
            }

            if (count($images) === 0) {
                return response()->json([
                    'status' => 0,
                    'message' => 'At least one image is required'
                ], 400);
            }

            // Get authenticated delivery boy
            $driver_data_admin = auth()->guard('api')->user();

            if (!$driver_data_admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Get order
            $order = Order::find($orderId);

            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            // Check if order is assigned to this delivery boy
            if ($order->delivery_boy_id != $deliveryBoy->id) {
                return response()->json([
                    'status' => 0,
                    'message' => 'This order is not assigned to you'
                ], 403);
            }

            // Check if payment method is NOT COD (must be prepaid)
            if ($order->payment_method === 'COD') {
                return response()->json([
                    'status' => 0,
                    // 'message' => 'This is a COD order.'
                    'message' => 'Customer did not paid the money yet contact admin'
                ], 400);
            }

            // Check if order is already delivered
            if ($order->active_status == 6) {
                return response()->json([
                    'status' => 0,
                    'message' => 'This order has already been delivered'
                ], 400);
            }

            // Check if order qualifies for multi-order bonus
            // Bonus is given only if order has store_id 15 along with other store_ids
            $storeIds = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->pluck('store_id')
                ->toArray();

            $bonusAmount = 0;
            $hasStore15 = in_array(15, $storeIds);
            $hasOtherStores = count(array_filter($storeIds, fn($id) => $id != 15)) > 0;

            if ($hasStore15 && $hasOtherStores) {
                $bonusAmount = floatval(Setting::get_value('multi_order_bonus') ?: 0);
            }

            // Extract cart_metadata for driver earnings calculation
            $cartMetadata = $order->cart_metadata;
            if (is_string($cartMetadata)) {
                $cartMetadata = json_decode($cartMetadata, true);
            }

            // Get delivery_tip, delivery_charge, and rain_surcharge from cart_metadata
            $deliveryTip = floatval($cartMetadata['cart_info']['delivery_tip'] ?? 0);
            $deliveryCharge = floatval($cartMetadata['cart_info']['delivery_charge'] ?? ($cartMetadata['billing_summary']['delivery_charge'] ?? 0));
            $rainSurcharge = floatval($order->rain_surcharge_amount ?? 0);

            // Vendor wait charge for this order — already deducted from vendor payout
            // in SellerOrderSettlementService. The completing driver receives 100%.
            $vendorWaitCharge = floatval($order->total_vendor_wait_charge ?? 0);

            // Check if this is a multi-driver order
            $driverDistanceSplit = $order->driver_distance_split ? json_decode($order->driver_distance_split, true) : null;
            $isMultiDriverOrder = !empty($driverDistanceSplit) && count($driverDistanceSplit['drivers'] ?? []) > 0;

            Log::info('Prepaid order - Checking multi-driver status', [
                'order_id' => $orderId,
                'is_multi_driver' => $isMultiDriverOrder,
                'previous_drivers' => $isMultiDriverOrder ? array_keys($driverDistanceSplit['drivers']) : []
            ]);

            // Calculate driver earnings (admin owes this to driver, rain surcharge goes to driver)
            $driverEarnings = $deliveryTip + $deliveryCharge + $rainSurcharge + $bonusAmount + $vendorWaitCharge;

            // Start transaction
            DB::beginTransaction();

            try {
                // Upload images and collect URLs
                $imageUrls = [];
                foreach ($images as $image) {
                    $url = MediaUploadService::uploadWithFullUrl(
                        $image,
                        'delivery_boy/delivery_images',
                        'public'
                    );
                    $imageUrls[] = $url;
                }

                // Handle multi-driver or single-driver order
                if ($isMultiDriverOrder) {
                    Log::info('Processing multi-driver prepaid order', [
                        'order_id' => $orderId,
                        'completing_driver_id' => $deliveryBoy->id
                    ]);

                    // Calculate current driver's billable distance (same as COD)
                    $currentDriverFirestore = \App\Services\FirestoreDeliveryBoyService::getDeliveryBoyDocument($deliveryBoy->id);
                    $currentDriverBillableDistance = 0;

                    if ($currentDriverFirestore && isset($currentDriverFirestore['current_order'])) {
                        $sellersVisited = $currentDriverFirestore['current_order']['order_details']['sellers_visit_order'] ?? [];

                        // Same as COD: the completing driver's run includes the
                        // last stop → customer leg.
                        $currentDriverBillableDistance = \App\Services\FirestoreDeliveryBoyService::calculateBillableDistance($sellersVisited, [
                            'delivered_to' => [
                                'latitude' => (float) $order->latitude,
                                'longitude' => (float) $order->longitude
                            ]
                        ]);

                        Log::info('Prepaid - Current driver billable distance calculated', [
                            'order_id' => $orderId,
                            'driver_id' => $deliveryBoy->id,
                            'billable_distance_km' => $currentDriverBillableDistance
                        ]);
                    }

                    // Add current driver to split data
                    $driverDistanceSplit['drivers'][$deliveryBoy->id] = [
                        'name' => $deliveryBoy->name,
                        'billable_distance_km' => $currentDriverBillableDistance,
                        'percentage' => null,
                        'earnings' => null
                    ];

                    // Calculate total billable distance
                    $totalBillableDistance = array_sum(array_column($driverDistanceSplit['drivers'], 'billable_distance_km'));
                    $driverDistanceSplit['total_billable_distance_km'] = $totalBillableDistance;

                    // Create transactions for all drivers
                    foreach ($driverDistanceSplit['drivers'] as $driverId => &$driverData) {
                        $isCompletingDriver = ($driverId == $deliveryBoy->id);

                        // Calculate percentage
                        $driverData['percentage'] = $totalBillableDistance > 0
                            ? ($driverData['billable_distance_km'] / $totalBillableDistance) * 100
                            : 0;

                        // Calculate earnings
                        $driverDeliveryCharge = $totalBillableDistance > 0
                            ? ($deliveryCharge * $driverData['percentage']) / 100
                            : 0;

                        $driverTip = $isCompletingDriver ? $deliveryTip : 0;
                        $driverBonus = $isCompletingDriver ? $bonusAmount : 0;
                        $driverWaitCharge = $isCompletingDriver ? $vendorWaitCharge : 0;
                        $driverRainSurcharge = $totalBillableDistance > 0
                            ? ($rainSurcharge * $driverData['percentage']) / 100
                            : 0;

                        $driverTotalEarnings = $driverDeliveryCharge + $driverTip + $driverRainSurcharge + $driverBonus + $driverWaitCharge;
                        $driverData['earnings'] = $driverTotalEarnings;

                        // Create transaction (admin owes driver)
                        $transaction = new DeliveryBoyTransaction();
                        $transaction->user_id = $order->user_id;
                        $transaction->order_id = $order->id;
                        $transaction->delivery_boy_id = $driverId;
                        $transaction->type = $order->payment_method;
                        $transaction->amount = 0;
                        $transaction->delivery_charge = $driverDeliveryCharge;
                        $transaction->delivery_tip = $driverTip;
                        $transaction->rain_surcharge = $driverRainSurcharge;
                        $transaction->bonus_amount = $driverBonus;
                        $transaction->vendor_wait_charge = $driverWaitCharge;
                        $transaction->driver_earnings = $driverTotalEarnings;
                        $transaction->admin_cash = -$driverTotalEarnings; // Negative = admin owes
                        $transaction->status = DeliveryBoyTransaction::$statusSuccess;
                        $transaction->message = $isCompletingDriver
                            ? sprintf('Prepaid order completed - traveled %.2fkm (%.1f%%). Admin owes ₹%.2f',
                                $driverData['billable_distance_km'], $driverData['percentage'], $driverTotalEarnings)
                            : sprintf('Prepaid partial delivery - traveled %.2fkm (%.1f%%). Admin owes ₹%.2f',
                                $driverData['billable_distance_km'], $driverData['percentage'], $driverTotalEarnings);
                        $transaction->transaction_date = now()->toDateTimeString();
                        $transaction->settled_with_admin = false;
                        $transaction->save();

                        Log::info('Prepaid multi-driver transaction created', [
                            'order_id' => $orderId,
                            'transaction_id' => $transaction->id,
                            'driver_id' => $driverId,
                            'driver_name' => $driverData['name'],
                            'is_completing_driver' => $isCompletingDriver,
                            'distance_km' => $driverData['billable_distance_km'],
                            'percentage' => $driverData['percentage'],
                            'earnings' => $driverTotalEarnings
                        ]);
                    }

                    // Update order with final split
                    $order->driver_distance_split = json_encode($driverDistanceSplit);

                } else {
                    // Single driver - existing logic
                    Log::info('Processing single-driver prepaid order', [
                        'order_id' => $orderId,
                        'driver_id' => $deliveryBoy->id
                    ]);

                    $transaction = new DeliveryBoyTransaction();
                    $transaction->user_id = $order->user_id;
                    $transaction->order_id = $order->id;
                    $transaction->delivery_boy_id = $deliveryBoy->id;
                    $transaction->type = $order->payment_method;
                    $transaction->amount = 0;
                    $transaction->delivery_charge = $deliveryCharge;
                    $transaction->delivery_tip = $deliveryTip;
                    $transaction->rain_surcharge = $rainSurcharge;
                    $transaction->bonus_amount = $bonusAmount;
                    $transaction->vendor_wait_charge = $vendorWaitCharge;
                    $transaction->driver_earnings = $driverEarnings;
                    $transaction->admin_cash = -$driverEarnings;
                    $transaction->status = DeliveryBoyTransaction::$statusSuccess;
                    $transaction->message = 'Prepaid order delivered. Admin owes driver ₹' . number_format($driverEarnings, 2);
                    $transaction->transaction_date = now()->toDateTimeString();
                    $transaction->settled_with_admin = false;
                    $transaction->save();

                    Log::info('Single-driver prepaid transaction created', [
                        'order_id' => $orderId,
                        'transaction_id' => $transaction->id,
                        'earnings' => $driverEarnings
                    ]);
                }

                // Get current time string for consistency
                $currentDateTime = now()->toDateTimeString();

                // Update order status and images
                $order->delivery_time_before_images = $imageUrls;
                $order->delivered_at_time = now();
                $order->active_status = 6;

                // Store bonus details if bonus amount is provided
                if ($bonusAmount > 0) {
                    $order->delivery_boy_bonus_amount = $bonusAmount;
                    $order->delivery_boy_bonus_details = [
                        'type' => 'multi order bonus',
                        'amount' => $bonusAmount,
                        'delivered_at' => $currentDateTime
                    ];
                }

                $order->save();

                // Referral payout. This path sets active_status directly instead
                // of going through OrdersApiController@updateStatus, so without
                // this call a driver-delivered order never credits the referrer.
                CommonHelper::processReferralForDeliveredOrder($order->id);

                // Update delivery_boy_daily_tracking table
                $todayDate = now()->format('Y-m-d');
                $dailyTracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->where('tracking_date', $todayDate)
                    ->first();

                if (!$dailyTracking) {
                    DB::rollBack();
                    return response()->json([
                        'status' => 0,
                        'message' => 'Daily tracking record not found for today. Please ensure you are logged in.'
                    ], 404);
                }

                // Add driver earnings and increment orders_delivered
                $dailyTracking->total_earnings = floatval($dailyTracking->total_earnings) + $driverEarnings;
                $dailyTracking->orders_delivered = intval($dailyTracking->orders_delivered) + 1;
                $dailyTracking->last_activity_at = now();
                $dailyTracking->save();

                // Increment face verification counter and check if verification needed
                $faceVerificationRequired = false;
                $deliveryBoy->orders_since_last_face_verify = intval($deliveryBoy->orders_since_last_face_verify) + 1;
                if ($deliveryBoy->orders_since_last_face_verify >= 10) {
                    $deliveryBoy->is_available = 0;
                    $faceVerificationRequired = true;
                    Log::info('Face verification required - driver made offline', [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'orders_since_last_face_verify' => $deliveryBoy->orders_since_last_face_verify
                    ]);
                }
                $deliveryBoy->save();

                DB::commit();

                // Settle order amounts for sellers (credit their wallets)
                $sellerSettlement = SellerOrderSettlementService::settleOrderForSellers($order->id);
                Log::info('Seller settlement result for prepaid order', [
                    'order_id' => $order->id,
                    'result' => $sellerSettlement
                ]);

                // Update incentive progress
                DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion($deliveryBoy, $order);

                // Process referral tracking and bonus payment
                try {
                    $referralResult = ReferralBonusService::processOrderCompletion($deliveryBoy, $order->id);
                    if ($referralResult['success'] && isset($referralResult['bonus_amount'])) {
                        Log::info('Referral bonus processed for delivered order', [
                            'order_id' => $order->id,
                            'delivery_boy_id' => $deliveryBoy->id,
                            'result' => $referralResult
                        ]);
                    }
                } catch (\Exception $referralEx) {
                    Log::error('Referral tracking failed for delivered order', [
                        'order_id' => $order->id,
                        'error' => $referralEx->getMessage()
                    ]);
                }

                // Send notification to customer that order has been delivered
                try {
                    if ($order->user_id) {
                        CustomerNotificationService::send(
                            customerId: $order->user_id,
                            title: 'Order Delivered!',
                            message: "Your order #{$order->id} has been delivered successfully. Thank you for ordering with Zenfoo!",
                            image: '',
                            pageNavigation: 'order',
                            navigationId: $order->id
                        );
                        Log::info('Customer notification sent for prepaid order delivery', [
                            'order_id' => $order->id,
                            'customer_id' => $order->user_id
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error('Failed to send customer notification for prepaid order delivery', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage()
                    ]);
                }

                // Send notification to admin about order delivered
                try {
                    AdminNotificationService::notifyOrderStatusChange($order->id, 'Delivered', "#{$order->id}");
                    Log::info('Admin notification sent for order delivered (Prepaid)', [
                        'order_id' => $order->id
                    ]);
                } catch (\Exception $e) {
                    Log::error('Failed to send admin notification for order delivered (Prepaid)', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage()
                    ]);
                }

                // Calculate travel time
                $travelTimeMinutes = null;
                if ($order->driver_accepted_at_time) {
                    $acceptedAt = \Carbon\Carbon::parse($order->driver_accepted_at_time);
                    $deliveredAt = \Carbon\Carbon::parse($order->delivered_at_time);
                    $travelTimeMinutes = $acceptedAt->diffInMinutes($deliveredAt);
                }

                return response()->json([
                    'status' => 1,
                    'message' => 'Order delivered successfully',
                    'data' => [
                        'order_id' => $order->id,
                        'payment_method' => $order->payment_method,
                        'delivery_charge' => $deliveryCharge,
                        'delivery_tip' => $deliveryTip,
                        'bonus_amount' => $bonusAmount,
                        'vendor_wait_charge' => $vendorWaitCharge,
                        'driver_earnings' => $driverEarnings,
                        'admin_owes_driver' => $driverEarnings,
                        'is_rain_surcharge' => (bool) $order->is_rain_surcharge,
                        'rain_surcharge_amount' => $rainSurcharge,
                        'transaction_id' => $transaction->id,
                        'delivery_time_before_images' => $imageUrls,
                        'travel_time_minutes' => $travelTimeMinutes,
                        'face_verification_required' => $faceVerificationRequired
                    ]
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('Mark delivered failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Verify delivery PIN for an order
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyDeliveryPin(Request $request)
    {
        try {
            $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
                'order_id' => 'required|exists:orders,id',
                'delivery_pin' => 'required|string|size:4'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 0,
                    'message' => $validator->errors()->first()
                ], 422);
            }

            // Get authenticated delivery boy
            $authUser = auth()->guard('api')->user();
            if (!$authUser) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Get the order
            $order = Order::find($request->order_id);
            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            // Check if delivery boy is assigned to this order
            if ($order->delivery_boy_id != $deliveryBoy->id) {
                return response()->json([
                    'status' => 0,
                    'message' => 'You are not assigned to this order'
                ], 403);
            }

            // Verify the PIN
            if ($order->delivery_pin !== $request->delivery_pin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Invalid PIN',
                    'attempts_remaining' => 3 // You can track this in a separate field if needed
                ], 400);
            }

            return response()->json([
                'status' => 1,
                'message' => 'PIN verified successfully',
                'data' => [
                    'order_id' => $order->id,
                    'customer_name' => optional($order->user)->name,
                    'customer_phone' => $order->mobile,
                    'delivery_address' => $order->address
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Verify delivery PIN failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Get trip history for delivery boy with earnings
     * Supports Daily, Weekly, Monthly views with pagination
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getTripHistory(Request $request)
    {
        try {
            $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
                'period' => 'required|in:daily,weekly,monthly',
                'offset' => 'nullable|integer',
                'limit' => 'nullable|integer|min:1|max:100',
                'page' => 'nullable|integer|min:1',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 0,
                    'message' => $validator->errors()->first()
                ], 422);
            }

            // Get authenticated delivery boy
            $authUser = auth()->guard('api')->user();
            if (!$authUser) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Parameters
            $limit = (int) ($request->input('limit', 10));
            $page = (int) ($request->input('page', 1));
            $offset = (int) ($request->input('offset', 0));
            $period = $request->input('period', 'daily');
            $paginationSkip = ($page - 1) * $limit;

            // Calculate date range based on period + offset (offset navigates periods: -1 = previous period)
            $now = \Carbon\Carbon::now();

            if ($period === 'daily') {
                $startDate = $now->copy()->addDays($offset)->startOfDay();
                $endDate = $startDate->copy()->endOfDay();
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->copy()->startOfWeek();
                $startDate = $currentWeekStart->copy()->addWeeks($offset);
                $endDate = $startDate->copy()->endOfWeek();
            } else {
                $currentMonthStart = $now->copy()->startOfMonth();
                $startDate = $currentMonthStart->copy()->addMonths($offset);
                $endDate = $startDate->copy()->endOfMonth();
            }

            // Get orders for the period (status 6/7/8)
            $ordersQuery = Order::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->whereIn('active_status', ['6', '7', '8'])
                ->with(['user'])
                ->orderBy('created_at', 'DESC');

            $totalCount = $ordersQuery->count();

            $orders = $ordersQuery
                ->skip($paginationSkip)
                ->take($limit)
                ->get();

            // Pre-load all transactions for these orders (avoid N+1)
            $orderIds = $orders->pluck('id')->toArray();
            $allTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('order_id', $orderIds)
                ->get()
                ->groupBy('order_id');

            // Get summary from transactions table (source of truth)
            $allOrderIds = Order::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->whereIn('active_status', ['6', '7', '8'])
                ->pluck('id')
                ->toArray();

            $summaryTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('order_id', $allOrderIds)
                ->where('status', 'success')
                ->get();

            $totalDeliveryCharge = (float) $summaryTransactions->sum('delivery_charge');
            $totalDriverEarnings = (float) $summaryTransactions->sum('driver_earnings');

            // Get total distance from daily tracking
            $totalDistance = (float) DB::table('delivery_boy_daily_tracking')
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('tracking_date', '>=', $startDate->toDateString())
                ->whereDate('tracking_date', '<=', $endDate->toDateString())
                ->sum('total_distance_km');

            // Pre-load order items with seller info for all orders
            $allOrderItems = DB::table('order_items as oi')
                ->select(
                    'oi.order_id',
                    'oi.id',
                    'oi.product_name',
                    'oi.quantity',
                    'oi.seller_id',
                    's.store_name as seller_name',
                    's.store_location as seller_address',
                    's.lat_long as seller_lat_long',
                    's.mobile as seller_mobile'
                )
                ->leftJoin('sellers as s', 'oi.seller_id', '=', 's.id')
                ->whereIn('oi.order_id', $orderIds)
                ->get()
                ->groupBy('order_id');

            // Build response
            $tripData = [];
            foreach ($orders as $order) {
                $transactions = $allTransactions->get($order->id, collect());
                $orderItems = $allOrderItems->get($order->id, collect());

                $isMultiOrder = !empty($order->delivery_boy_bonus_amount) && $order->delivery_boy_bonus_amount > 0;

                // Build unique seller + customer locations
                $uniqueLocations = [];
                $seenSellerIds = [];
                foreach ($orderItems as $item) {
                    if ($item->seller_id && !in_array($item->seller_id, $seenSellerIds)) {
                        $uniqueLocations[] = [
                            'type' => 'seller',
                            'name' => $item->seller_name ?? 'Seller',
                            'address' => $item->seller_address,
                            'lat_long' => $item->seller_lat_long,
                            'mobile' => $item->seller_mobile,
                            'seller_id' => $item->seller_id
                        ];
                        $seenSellerIds[] = $item->seller_id;
                    }
                }
                $uniqueLocations[] = [
                    'type' => 'customer',
                    'name' => optional($order->user)->name ?? 'Customer',
                    'address' => $order->address,
                    'lat_long' => $order->latitude . ',' . $order->longitude,
                    'mobile' => $order->mobile
                ];

                // Calculate earnings from pre-loaded transactions
                $deliveryCharge = 0;
                $deliveryTip = 0;
                $multiOrderBonus = 0;
                $rainSurcharge = 0;
                $driverEarnings = 0;
                $cashCollected = 0;
                $adminCash = 0;
                $isSettled = false;

                foreach ($transactions as $transaction) {
                    $deliveryCharge += (float) ($transaction->delivery_charge ?? 0);
                    $deliveryTip += (float) ($transaction->delivery_tip ?? 0);
                    $rainSurcharge += (float) ($transaction->rain_surcharge ?? 0);
                    $multiOrderBonus += (float) ($transaction->bonus_amount ?? 0);
                    $driverEarnings += (float) ($transaction->driver_earnings ?? 0);

                    // Cash handling from is_hand_cash transaction
                    if ($transaction->is_hand_cash) {
                        $cashCollected = (float) ($transaction->amount ?? 0);
                        $adminCash = (float) ($transaction->admin_cash ?? 0);
                        $isSettled = (bool) $transaction->settled_with_admin;
                    }
                }

                $totalTripEarning = $driverEarnings;

                $tripData[] = [
                    'order_id' => $order->id,
                    'orders_id' => $order->orders_id,
                    'is_multi_order' => $isMultiOrder,
                    'delivery_time' => $order->delivered_at_time ? \Carbon\Carbon::parse($order->delivered_at_time)->format('H:i A') : 'In Progress',
                    'status' => $order->active_status,
                    'payment_method' => $order->payment_method,
                    'is_rain_surcharge' => (bool) ($order->is_rain_surcharge ?? false),
                    'rain_surcharge_amount' => (float) ($order->rain_surcharge_amount ?? 0),
                    'customer' => [
                        'name' => optional($order->user)->name,
                        'phone' => $order->mobile
                    ],
                    'addresses' => $uniqueLocations,
                    'items_count' => $orderItems->count(),
                    'earnings_details' => [
                        'base_earning' => (float) $deliveryCharge,
                        'rain_surcharge' => (float) $rainSurcharge,
                        'multi_order_bonus' => (float) $multiOrderBonus,
                        'customer_tip' => (float) $deliveryTip,
                        'total_trip_earning' => (float) $totalTripEarning
                    ],
                    'cash_handling' => [
                        'cash_collected' => (float) $cashCollected,
                        'cash_paid_to_company' => $isSettled ? (float) $adminCash : 0,
                        'cash_balance' => (float) ($cashCollected - ($isSettled ? $adminCash : 0))
                    ]
                ];
            }

            // Build period name
            if ($period === 'daily') {
                $periodName = $startDate->format('D, M d, Y');
            } elseif ($period === 'weekly') {
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $periodName = $startDate->format('F Y');
            }

            return response()->json([
                'status' => 1,
                'message' => 'Trip history retrieved successfully',
                'data' => [
                    'period' => $period,
                    'offset' => $offset,
                    'period_name' => $periodName,
                    'date_range' => [
                        'start' => $startDate->format('Y-m-d'),
                        'end' => $endDate->format('Y-m-d')
                    ],
                    'summary' => [
                        'total_trips' => $totalCount,
                        'total_delivery_charge' => (float) $totalDeliveryCharge,
                        'total_earnings' => (float) $totalDriverEarnings,
                        'total_distance_km' => (float) $totalDistance
                    ],
                    'pagination' => [
                        'total' => $totalCount,
                        'limit' => $limit,
                        'page' => $page,
                        'total_pages' => (int) ceil($totalCount / $limit),
                    ],
                    'trips' => $tripData
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Get trip history failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Notify customer that driver has arrived at their location
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function notifyArrival(Request $request)
    {
        try {
            $orderId = $request->input('order_id');
            $driverLat = $request->input('latitude');
            $driverLon = $request->input('longitude');

            if (empty($orderId)) {
                return response()->json([
                    'status' => 0,
                    'message' => 'order_id parameter is required'
                ], 400);
            }

            // Driver coordinates are optional. The arrival notification is sent
            // whenever the driver taps "Reached customer", regardless of distance.
            $driverLat = ($driverLat !== null && $driverLat !== '') ? (float) $driverLat : null;
            $driverLon = ($driverLon !== null && $driverLon !== '') ? (float) $driverLon : null;

            // Get authenticated delivery boy
            $admin = Auth::guard('api')->user();
            if (!$admin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Get delivery boy record
            $deliveryBoy = DeliveryBoy::where('admin_id', $admin->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Get the order
            $order = Order::find($orderId);
            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            // Verify the order is assigned to this delivery boy
            if ($order->delivery_boy_id != $deliveryBoy->id) {
                return response()->json([
                    'status' => 0,
                    'message' => 'This order is not assigned to you'
                ], 403);
            }

            // Customer-side proximity radius is not applied at all. The customer may
            // collect the order from a point other than the saved delivery location,
            // so the driver's distance to the customer is neither enforced nor logged.
            // (The store-side proximity check in getSellerDetails() is untouched.)
            //
            // $customerLat = (float) $order->latitude;
            // $customerLon = (float) $order->longitude;
            //
            // if (
            //     $driverLat !== null && $driverLon !== null &&
            //     DriverCustomerDistanceService::areCoordinatesValid($driverLat, $driverLon) &&
            //     DriverCustomerDistanceService::areCoordinatesValid($customerLat, $customerLon)
            // ) {
            //     $proximityRadius = intval(Setting::get_value('driver_proximity_radius') ?: 100);
            //     $distanceCheck = DriverCustomerDistanceService::isDriverWithinRange(
            //         $driverLat,
            //         $driverLon,
            //         $customerLat,
            //         $customerLon,
            //         $proximityRadius
            //     );
            //     Log::info('Driver arrival distance', [
            //         'order_id' => $orderId,
            //         'within_range' => $distanceCheck['allowed'],
            //         'distance_meters' => $distanceCheck['distance_meters'],
            //     ]);
            // }

            // Get customer ID from the order
            $customerId = $order->user_id;
            if (!$customerId) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Customer not found for this order'
                ], 404);
            }

            // Build the arrival message, including the delivery OTP so the customer
            // can hand it to the partner to complete the delivery.
            $deliveryPin = $order->delivery_pin;
            if (!empty($deliveryPin)) {
                $arrivalMessage = "Your delivery partner has arrived at your location for Order #{$order->id}. Share your delivery OTP {$deliveryPin} with the partner to receive your order.";
            } else {
                $arrivalMessage = "Your delivery partner has arrived at your location for Order #{$order->id}. Please be ready to collect your order.";
            }

            // Send notification to customer
            $notificationResult = ['success' => false, 'message' => 'Not sent'];
            try {
                $notificationResult = CustomerNotificationService::send(
                    (int) $customerId,
                    'Driver Arrived',
                    $arrivalMessage,
                    '',
                    'order',
                    $order->id,
                    [
                        'order_id' => $order->id,
                        'driver_name' => $deliveryBoy->name ?? 'Driver',
                        'delivery_pin' => $deliveryPin,
                    ]
                );

                Log::info("Driver arrival notification sent", [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id,
                    'customer_id' => $customerId,
                    'notification_result' => $notificationResult
                ]);
            } catch (\Exception $e) {
                Log::error("Failed to send driver arrival notification", [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id,
                    'customer_id' => $customerId,
                    'error' => $e->getMessage()
                ]);
            }

            // Update driver_arrived_at_cus_locn timestamp
            $order->driver_arrived_at_cus_locn = now();
            $order->save();

            return response()->json([
                'status' => 1,
                'message' => 'Customer has been notified of your arrival',
                'data' => [
                    'order_id' => $orderId,
                    'customer_notified' => $notificationResult['success']
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Notify arrival failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Something went wrong'
            ], 500);
        }
    }

    /**
     * Get delivery boy order history grouped by date
     * Shows last 10 days from today with pagination
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getOrderHistory(Request $request)
    {
        try {
            // Get authenticated delivery boy
            $authUser = auth()->guard('api')->user();
            if (!$authUser) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Pagination parameters
            $page = (int) $request->input('page', 1);
            $perPage = (int) $request->input('per_page', 10); // 10 days per page

            // Calculate date range for the requested page
            $startOffset = ($page - 1) * $perPage;
            $endDate = \Carbon\Carbon::today()->subDays($startOffset);
            $startDate = $endDate->copy()->subDays($perPage - 1);

            // Get all delivered orders for the delivery boy in the date range
            $orders = Order::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->orderBy('created_at', 'DESC')
                ->get();

            // Group orders by date
            $ordersByDate = [];
            foreach ($orders as $order) {
                $orderDate = \Carbon\Carbon::parse($order->created_at)->format('Y-m-d');

                if (!isset($ordersByDate[$orderDate])) {
                    $ordersByDate[$orderDate] = [];
                }

                // Get order items with measurements
                $orderItems = DB::table('order_items')
                    ->select(
                        'order_items.id',
                        'order_items.quantity',
                        'order_items.product_variant_id',
                        'products.id as product_id',
                        'products.name as product_name',
                        'product_variants.measurement',
                        'units.short_code as unit_short_code'
                    )
                    ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                    ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                    ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                    ->where('order_items.order_id', $order->id)
                    ->get();

                // Build items list
                $allItems = [];
                foreach ($orderItems as $item) {
                    $measurementDisplay = $item->measurement . ' ' . ($item->unit_short_code ?? '');
                    $allItems[] = [
                        'item_name' => $item->product_name,
                        'quantity' => (int) $item->quantity,
                        'measurement' => trim($measurementDisplay),
                    ];
                }

                // Get combo items
                $comboItems = DB::table('order_combo_items')
                    ->where('order_id', $order->id)
                    ->get();

                // Process combo items - extract all products
                foreach ($comboItems as $combo) {
                    if (!empty($combo->products)) {
                        $products = json_decode($combo->products, true);
                        if (is_string($products)) {
                            $products = json_decode($products, true);
                        }

                        if (is_array($products)) {
                            foreach ($products as $product) {
                                $productId = $product['product_id'] ?? null;
                                $variantId = $product['variant_id'] ?? null;

                                if ($productId && $variantId) {
                                    // Get variant details for measurement
                                    $variantDetail = DB::table('product_variants')
                                        ->select(
                                            'product_variants.measurement',
                                            'units.short_code as unit_short_code'
                                        )
                                        ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                                        ->where('product_variants.id', $variantId)
                                        ->first();

                                    $qty = $product['quantity'] ?? 1;
                                    $measurement = $variantDetail->measurement ?? ($product['variant_measurement'] ?? '');
                                    $unit = $variantDetail->unit_short_code ?? '';
                                    $measurementDisplay = $measurement . ' ' . $unit;

                                    $allItems[] = [
                                        'item_name' => $product['product_name'] ?? 'Combo Item',
                                        'quantity' => (int) $qty,
                                        'measurement' => trim($measurementDisplay),
                                    ];
                                }
                            }
                        }
                    }
                }

                // Get transaction details for this order
                $transactions = DeliveryBoyTransaction::where('order_id', $order->id)
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->get();

                $deliveryCharge = 0;
                $deliveryTip = 0;
                $rainSurcharge = 0;
                $multiOrderBonus = 0;

                foreach ($transactions as $transaction) {
                    $deliveryCharge += (float) ($transaction->delivery_charge ?? 0);
                    $deliveryTip += (float) ($transaction->delivery_tip ?? 0);
                    $rainSurcharge += (float) ($transaction->rain_surcharge ?? 0);
                    $multiOrderBonus += (float) ($transaction->bonus_amount ?? 0);
                }

                // Parse cart_metadata for total price
                $cartMeta = is_string($order->cart_metadata)
                    ? json_decode($order->cart_metadata, true)
                    : $order->cart_metadata;
                $totalPrice = $cartMeta['billing_summary']['to_be_paid'] ?? $order->final_total ?? 0;

                // Get delivery time
                $deliveryTime = $order->delivered_at_time
                    ? \Carbon\Carbon::parse($order->delivered_at_time)->format('h:i A')
                    : ($order->delivery_time ?? 'N/A');

                $ordersByDate[$orderDate][] = [
                    'order_id' => $order->id,
                    'item_count' => count($allItems),
                    'items' => $allItems,
                    'delivery_time' => $deliveryTime,
                    'total_amount_paid' => (float) $totalPrice,
                    'delivery_charges' => (float) $deliveryCharge,
                    'is_rain_surcharge' => (bool) ($order->is_rain_surcharge ?? false),
                    'rain_surcharge_amount' => (float) ($order->rain_surcharge_amount ?? 0),
                    'rain_surcharge' => (float) $rainSurcharge,
                    'tip' => (float) $deliveryTip,
                    'multi_order_bonus' => (float) $multiOrderBonus,
                ];
            }

            // Format response with date headers - include all days in range
            $formattedData = [];
            $currentDate = $endDate->copy();
            while ($currentDate->gte($startDate)) {
                $dateStr = $currentDate->format('Y-m-d');
                $dateHeader = $currentDate->format('d M') . ' | ' . $currentDate->format('l');

                $dayOrders = $ordersByDate[$dateStr] ?? [];

                $formattedData[] = [
                    'date' => $dateStr,
                    'date_header' => $dateHeader,
                    'orders' => $dayOrders,
                    'order_count' => count($dayOrders),
                ];

                $currentDate->subDay();
            }

            // Calculate pagination info
            $totalDays = $endDate->copy()->diffInDays(\Carbon\Carbon::today()->subDays(365)); // Last 1 year
            $totalPages = (int) ceil($totalDays / $perPage);
            $hasMore = $page < $totalPages;

            return response()->json([
                'status' => 1,
                'message' => 'Order history retrieved successfully',
                'data' => [
                    'orders_by_date' => $formattedData,
                    'pagination' => [
                        'current_page' => $page,
                        'per_page' => $perPage,
                        'has_more' => $hasMore,
                        'total_pages' => $totalPages,
                    ],
                ],
            ], 200);

        } catch (\Exception $e) {
            Log::error('Get order history failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to retrieve order history: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Generate QR code for order payment
     *
     * This endpoint generates a UPI QR code that the delivery boy can show to customers
     * for direct payment via Paytm or any UPI app
     *
     * POST /api/delivery-boy/order/generate-qr
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function generateOrderQRCode(Request $request)
    {
        try {
            // Validate request
            $request->validate([
                'order_id' => 'required|integer|exists:orders,id',
                'generate_image' => 'nullable|boolean', // Whether to generate QR image (requires library)
            ]);

            $orderId = $request->order_id;
            $generateImage = $request->generate_image ?? false;

            // Get authenticated delivery boy
            $driverData = auth()->guard('api')->user();
            if (!$driverData) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driverData->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Get order
            $order = Order::find($orderId);
            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            // Verify this delivery boy is assigned to this order
            if ($order->delivery_boy_id != $deliveryBoy->id) {
                return response()->json([
                    'status' => 0,
                    'message' => 'You are not assigned to this order'
                ], 403);
            }

            // Validate order can have QR code generated
            $validation = PaytmQRCodeService::validateOrderForQR($order);
            if (!$validation['valid']) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Cannot generate QR code for this order',
                    'errors' => $validation['errors']
                ], 400);
            }

            // Generate QR code
            $qrResult = PaytmQRCodeService::generateOrderQRCode($order, [
                'generate_image' => $generateImage,
                'size' => 300,
                'save_to_storage' => false // Don't save to storage, just return base64
            ]);

            if (!$qrResult['success']) {
                Log::error('Failed to generate QR code for order', [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoy->id,
                    'error' => $qrResult['error'] ?? 'Unknown error',
                    'error_type' => $qrResult['error_type'] ?? 'unknown'
                ]);

                return response()->json([
                    'status' => 0,
                    'message' => $qrResult['error'] ?? 'Failed to generate QR code',
                    'error_type' => $qrResult['error_type'] ?? 'unknown'
                ], 500);
            }

            Log::info('QR code generated for order - FULL RESPONSE', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoy->id,
                'amount' => $qrResult['data']['amount'] ?? null,
                'currency' => $qrResult['data']['currency'] ?? null,
                'qr_code_id' => $qrResult['data']['qr_code_id'] ?? null,
                'qr_code_string' => $qrResult['data']['qr_code_string'] ?? null,
                'qr_type' => $qrResult['data']['qr_type'] ?? null,
                'payment_gateway' => $qrResult['data']['payment_gateway'] ?? null,
                'has_qr_image' => !empty($qrResult['data']['qr_image_base64']),
                'qr_image_length' => strlen($qrResult['data']['qr_image_base64'] ?? ''),
                'all_data_keys' => array_keys($qrResult['data'] ?? []),
                'paytm_raw_response' => $qrResult['data']['paytm_response'] ?? null,
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'QR code generated successfully',
                'data' => $qrResult['data']
            ], 200);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'status' => 0,
                'message' => 'Validation failed',
                'errors' => $e->errors()
            ], 422);

        } catch (\Exception $e) {
            Log::error('Generate QR code failed', [
                'order_id' => $request->order_id ?? 'N/A',
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to generate QR code: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get merchant static QR code
     *
     * This endpoint returns a static QR code for the merchant account
     * that can be used for any payment (customer enters amount manually)
     *
     * GET /api/delivery-boy/merchant-qr
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMerchantStaticQR(Request $request)
    {
        try {
            // Get authenticated delivery boy
            $driverData = auth()->guard('api')->user();
            if (!$driverData) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Unauthorized driver'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $driverData->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            // Generate static QR code
            $qrResult = PaytmQRCodeService::getMerchantStaticQR();

            if (!$qrResult['success']) {
                Log::error('Failed to generate static QR code', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'error' => $qrResult['error'] ?? 'Unknown error'
                ]);

                return response()->json([
                    'status' => 0,
                    'message' => $qrResult['error'] ?? 'Failed to generate static QR code'
                ], 500);
            }

            Log::info('Static QR code retrieved', [
                'delivery_boy_id' => $deliveryBoy->id,
                'merchant_vpa' => $qrResult['data']['merchant_vpa']
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'Static QR code generated successfully',
                'data' => $qrResult['data']
            ], 200);

        } catch (\Exception $e) {
            Log::error('Get static QR code failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to get static QR code: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * TEST ONLY - Generate QR code without authentication
     *
     * POST /api/test/generate-qr
     *
     * IMPORTANT: This endpoint should be DISABLED in production!
     * Only for development/testing purposes.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function testGenerateQRCode(Request $request)
    {
        // Only allow in non-production environments
        if (app()->environment('production')) {
            return response()->json([
                'status' => 0,
                'message' => 'Test endpoint disabled in production'
            ], 403);
        }

        try {
            Log::info('TEST: QR code generation requested (no auth)', [
                'request_data' => $request->all()
            ]);

            // Validate request
            $validator = Validator::make($request->all(), [
                'order_id' => 'required|integer|exists:orders,id',
                'generate_image' => 'boolean'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 400);
            }

            $orderId = $request->order_id;
            $generateImage = $request->input('generate_image', true);

            // Get order
            $order = Order::find($orderId);

            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            Log::info('TEST: Order found for QR generation', [
                'order_id' => $orderId,
                'amount' => $order->final_total,
                'payment_status' => $order->payment_status
            ]);

            // Validate order is eligible for QR code
            $validation = PaytmQRCodeService::validateOrderForQR($order);

            if (!$validation['valid']) {
                Log::warning('TEST: Order validation failed for QR', [
                    'order_id' => $orderId,
                    'errors' => $validation['errors']
                ]);

                return response()->json([
                    'status' => 0,
                    'message' => 'Cannot generate QR code for this order',
                    'errors' => $validation['errors']
                ], 400);
            }

            // Generate QR code
            $qrResult = PaytmQRCodeService::generateOrderQRCode($order, [
                'generate_image' => $generateImage,
                'size' => 300,
                'save_to_storage' => false
            ]);

            if (!$qrResult['success']) {
                Log::error('TEST: QR code generation failed', [
                    'order_id' => $orderId,
                    'error' => $qrResult['error']
                ]);

                return response()->json([
                    'status' => 0,
                    'message' => $qrResult['error']
                ], 500);
            }

            Log::info('TEST: QR code generated successfully', [
                'order_id' => $orderId,
                'has_image' => isset($qrResult['data']['image_base64'])
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'QR code generated successfully (TEST MODE)',
                'data' => $qrResult['data'],
                'warning' => 'This is a test endpoint. Disable in production!'
            ], 200);

        } catch (\Exception $e) {
            Log::error('TEST: QR code generation exception', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to generate QR code: ' . $e->getMessage()
            ], 500);
        }
    }
}