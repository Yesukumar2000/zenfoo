<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\CustomerNotificationService;
use App\Services\DriverNotificationService;
use App\Services\FirestoreDeliveryBoyService;
use App\Services\FirestoreOrderETAService;
use App\Jobs\RetryDeliveryBoyAssignmentJob;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ZenfooStoreItemsController extends Controller
{
    /**
     * Get Zenfoo store tracking data for an order
     * Only returns data where store_id is one of the Zenfoo store IDs (12, 13).
     *
     * @param int $orderId
     * @return \Illuminate\Http\JsonResponse
     */
    public function getZenfooStoreTracking($orderId)
    {
        try {
            Log::info('Fetching Zenfoo store tracking data', ['order_id' => $orderId]);

            $zenfooStoreIds = [12, 13];

            // Get tracking data for Zenfoo store_ids (12, 13)
            $trackingData = DB::table('order_seller_status_tracking as ost')
                ->leftJoin('stores', 'ost.store_id', '=', 'stores.id')
                ->leftJoin('sellers', 'ost.seller_id', '=', 'sellers.id')
                ->leftJoin('store_locations', 'ost.store_location_id', '=', 'store_locations.id')
                ->where('ost.order_id', $orderId)
                ->whereIn('ost.store_id', $zenfooStoreIds)
                ->select(
                    'ost.id',
                    'ost.order_id',
                    'ost.seller_id',
                    'ost.store_id',
                    'ost.store_location_id',
                    'ost.is_zenfoo_store',
                    'ost.is_driver_picked',
                    'ost.driver_captured_images_when_marked_as_pickup',
                    'ost.status',
                    'ost.is_seller_started_preparing',
                    'ost.delayed_time_in_min',
                    'ost.otp',
                    'ost.prep_time',
                    'ost.created_at',
                    'ost.updated_at',
                    'stores.name as store_name',
                    'sellers.name as seller_name',
                    'sellers.mobile as seller_mobile',
                    'store_locations.name as location_name',
                    'store_locations.address as location_address'
                )
                ->get();

            // Format the data, then collapse all Zenfoo store rows (12, 13) into one
            // logical entry — UI treats them as a single Zenfoo block (shared prep_time, OTP, status).
            // The underlying rows still exist in the DB for per-store reporting.
            $formattedData = $trackingData->map(function ($item) {
                return [
                    'id' => $item->id,
                    'order_id' => $item->order_id,
                    'store_id' => $item->store_id,
                    'store_name' => $item->store_name ?? 'Zenfoo Store',
                    'store_location_id' => $item->store_location_id,
                    'location_name' => $item->location_name,
                    'location_address' => $item->location_address,
                    'seller_id' => $item->seller_id,
                    'seller_name' => $item->seller_name,
                    'seller_mobile' => $item->seller_mobile,
                    'is_zenfoo_store' => $item->is_zenfoo_store,
                    'is_driver_picked' => $item->is_driver_picked,
                    'driver_captured_images' => $item->driver_captured_images_when_marked_as_pickup
                        ? json_decode($item->driver_captured_images_when_marked_as_pickup, true)
                        : [],
                    'status' => $item->status,
                    'status_label' => $this->getStatusLabel($item->status),
                    'is_seller_started_preparing' => $item->is_seller_started_preparing,
                    'delayed_time_in_min' => $item->delayed_time_in_min,
                    'otp' => $item->otp,
                    'prep_time' => $item->prep_time ? json_decode($item->prep_time, true) : null,
                    'created_at' => $item->created_at,
                    'updated_at' => $item->updated_at,
                ];
            });

            // Capture every store_id present in the tracking rows BEFORE we collapse
            // them — the items query below needs all of [12, 13] when both are present.
            $trackingStoreIds = $formattedData->pluck('store_id')->filter()->unique()->values()->all();

            // Merge into one entry. Prefer the row with the most-advanced fields
            // (any non-null prep_time / non-default status) so the UI shows the latest state.
            if ($formattedData->count() > 1) {
                $primary = $formattedData->first();
                $primary['merged_store_ids'] = $trackingStoreIds;
                $primary['store_name'] = 'Zenfoo Store';
                // The "id" stays the first row's id — but updates need to touch every row.
                $primary['tracking_row_ids'] = $formattedData->pluck('id')->all();
                $formattedData = collect([$primary]);
            } elseif ($formattedData->count() === 1) {
                $only = $formattedData->first();
                $only['merged_store_ids'] = [$only['store_id']];
                $only['tracking_row_ids'] = [$only['id']];
                $formattedData = collect([$only]);
            }

            // Get order items for store_id = 12
            // Join: order_items -> product_variants -> products

            // Check if order has items snapshot
            $orderData = DB::table('orders')
                ->where('id', $orderId)
                ->select('order_items_snapshot')
                ->first();

            if ($orderData && !empty($orderData->order_items_snapshot)) {
                Log::info('Order has items snapshot', [
                    'order_id' => $orderId,
                    'snapshot_data' => json_decode($orderData->order_items_snapshot, true)
                ]);
            }

            // First, check all order items without filtering by store_id
            $allOrderItems = DB::table('order_items as oi')
                ->leftJoin('product_variants as pv', 'oi.product_variant_id', '=', 'pv.id')
                ->leftJoin('products', 'pv.product_id', '=', 'products.id')
                ->where('oi.order_id', $orderId)
                ->select(
                    'oi.id',
                    'oi.order_id',
                    'oi.product_variant_id',
                    'oi.quantity',
                    'pv.product_id',
                    'products.name as product_name',
                    'products.store_id'
                )
                ->get();

            Log::info('All order items (before store_id filter)', [
                'order_id' => $orderId,
                'total_items' => $allOrderItems->count(),
                'items_detail' => $allOrderItems->map(function($item) {
                    return [
                        'order_item_id' => $item->id,
                        'product_variant_id' => $item->product_variant_id,
                        'product_id' => $item->product_id,
                        'product_name' => $item->product_name,
                        'store_id' => $item->store_id,
                        'quantity' => $item->quantity
                    ];
                })
            ]);

            // Fallback if there were no tracking rows at all for this order.
            if (empty($trackingStoreIds)) {
                $trackingStoreIds = $zenfooStoreIds;
            }

            $orderItems = DB::table('order_items as oi')
                ->leftJoin('product_variants as pv', 'oi.product_variant_id', '=', 'pv.id')
                ->leftJoin('products', 'pv.product_id', '=', 'products.id')
                ->where('oi.order_id', $orderId)
                ->whereIn('products.store_id', $trackingStoreIds)
                ->select(
                    'oi.id',
                    'oi.order_id',
                    'oi.product_variant_id',
                    'oi.quantity',
                    'oi.price',
                    'oi.discounted_price',
                    'oi.tax_amount',
                    'oi.tax_percentage',
                    'oi.sub_total',
                    'oi.active_status',
                    'pv.product_id',
                    'pv.measurement as variant_measurement',
                    'pv.stock_unit_id as variant_unit_id',
                    'products.name as product_name',
                    'products.image as product_image',
                    'products.store_id'
                )
                ->get();

                
            Log::info('Order items after store_id filter', [
                'order_id' => $orderId,
                'filtered_items_count' => $orderItems->count(),
                'tracking_store_ids' => $trackingStoreIds
            ]);

            // Check for combo items (they might not be included in order_items table)
            $comboItems = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->get();

            Log::info('Checking combo items for order', [
                'order_id' => $orderId,
                'combo_items_count' => $comboItems->count(),
                'combo_items_detail' => $comboItems->map(function($combo) {
                    return [
                        'id' => $combo->id,
                        'order_id' => $combo->order_id,
                        'has_products' => !empty($combo->products)
                    ];
                })
            ]);

            // Process combo items and extract products that belong to the tracking store
            $comboItemsForStore = [];
            foreach ($comboItems as $combo) {
                if (!empty($combo->products)) {
                    $products = json_decode($combo->products, true);
                    if (is_string($products)) {
                        $products = json_decode($products, true);
                    }

                    if (is_array($products)) {
                        foreach ($products as $product) {
                            // Check if product belongs to the tracking store
                            $productId = $product['product_id'] ?? null;
                            if ($productId) {
                                $productInfo = DB::table('products')
                                    ->where('id', $productId)
                                    ->select('id', 'name', 'store_id', 'image')
                                    ->first();

                                if ($productInfo && in_array($productInfo->store_id, $trackingStoreIds)) {
                                    $variantId = $product['variant_id'] ?? null;
                                    $variantDetail = null;

                                    if ($variantId) {
                                        $variantDetail = DB::table('product_variants')
                                            ->select(
                                                'product_variants.measurement',
                                                'product_variants.stock_unit_id',
                                                'units.short_code as unit_short_code'
                                            )
                                            ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                                            ->where('product_variants.id', $variantId)
                                            ->first();
                                    }

                                    $comboItemsForStore[] = (object)[
                                        'id' => null,
                                        'order_id' => $orderId,
                                        'product_variant_id' => $variantId,
                                        'quantity' => $product['quantity'] ?? 1,
                                        'price' => $product['price'] ?? 0,
                                        'discounted_price' => $product['discounted_price'] ?? 0,
                                        'tax_amount' => 0,
                                        'tax_percentage' => 0,
                                        'sub_total' => $product['sub_total'] ?? 0,
                                        'active_status' => 1,
                                        'product_id' => $productId,
                                        'variant_measurement' => $variantDetail->measurement ?? '',
                                        'variant_unit_id' => $variantDetail->stock_unit_id ?? null,
                                        'product_name' => $product['product_name'] ?? $productInfo->name,
                                        'product_image' => $productInfo->image,
                                        'store_id' => $productInfo->store_id
                                    ];
                                }
                            }
                        }
                    }
                }
            }

            Log::info('Combo items extracted for tracking store', [
                'order_id' => $orderId,
                'tracking_store_ids' => $trackingStoreIds,
                'extracted_combo_items_count' => count($comboItemsForStore)
            ]);

            // Merge regular items with combo items
            $allItems = $orderItems->merge($comboItemsForStore);

            Log::info('Zenfoo store tracking data fetched successfully', [
                'order_id' => $orderId,
                'tracking_count' => $formattedData->count(),
                'regular_items_count' => $orderItems->count(),
                'combo_items_count' => count($comboItemsForStore),
                'total_items_count' => $allItems->count()
            ]);

            $deliveryInstructions = null;
            if ($orderData && !empty($orderData->cart_metadata ?? null)) {
                $meta = is_string($orderData->cart_metadata)
                    ? json_decode($orderData->cart_metadata, true)
                    : $orderData->cart_metadata;
                $deliveryInstructions = $meta['cart_info']['delivery_instructions'] ?? null;
            }
            if ($deliveryInstructions === null) {
                $metaRow = DB::table('orders')->where('id', $orderId)->value('cart_metadata');
                if (!empty($metaRow)) {
                    $meta = is_string($metaRow) ? json_decode($metaRow, true) : $metaRow;
                    $deliveryInstructions = $meta['cart_info']['delivery_instructions'] ?? null;
                }
            }

            return response()->json([
                'status' => 1,
                'message' => 'Zenfoo store tracking data fetched successfully',
                'data' => [
                    'tracking' => $formattedData,
                    'items' => $allItems,
                    'delivery_instructions' => $deliveryInstructions,
                    'summary' => [
                        'total_items' => $allItems->sum('quantity'),
                        'total_amount' => $allItems->sum('sub_total'),
                        'has_tracking' => $formattedData->count() > 0
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching Zenfoo store tracking data', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to fetch Zenfoo store tracking data',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update prep time for Zenfoo store order (Admin panel)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updatePrepTime(Request $request)
    {
        try {
            $request->validate([
                'order_id' => 'required|integer',
                'tracking_id' => 'required|integer',
                'prep_time' => 'required',
            ]);

            Log::info('Admin updating prep time', [
                'order_id' => $request->order_id,
                'tracking_id' => $request->tracking_id,
                'prep_time' => $request->prep_time
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

            // Get the tracking record
            $trackingRecord = DB::table('order_seller_status_tracking')
                ->where('id', $request->tracking_id)
                ->where('order_id', $request->order_id)
                ->whereIn('store_id', [12, 13])
                ->first();

            if (!$trackingRecord) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order tracking record not found'
                ], 404);
            }

            $updateData = [
                'prep_time' => json_encode($prepTime),
                'updated_at' => now()
            ];

            // Check if prep_time already exists (updating prep time again)
            if (!empty($trackingRecord->prep_time)) {
                // prep_time format: [minutes, "time"] e.g. [15, "4:47 PM"]
                // Calculate delay
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
                        $delayedMinutes = $elapsedMinutes - $oldRemainingMinutes + $newRemainingMinutes;
                        if ($delayedMinutes < 0) {
                            $delayedMinutes = 0;
                        }
                    } catch (\Exception $e) {
                        $delayedMinutes = $newRemainingMinutes;
                    }
                } else {
                    $delayedMinutes = $newRemainingMinutes;
                }

                $updateData['delayed_time_in_min'] = $delayedMinutes;

                // Send notification to driver about delay (if driver is assigned)
                if ($delayedMinutes > 0) {
                    try {
                        $order = Order::find($request->order_id);
                        if ($order && $order->delivery_boy_id) {
                            DriverNotificationService::send(
                                driverId: $order->delivery_boy_id,
                                title: 'Order Delayed',
                                message: "Order #{$request->order_id} is delayed by {$delayedMinutes} minutes. The seller needs more time to prepare the order.",
                                type: 'order',
                                orderItemId: $request->order_id
                            );
                            Log::info('Driver notification sent for order delay', [
                                'order_id' => $request->order_id,
                                'driver_id' => $order->delivery_boy_id,
                                'delayed_minutes' => $delayedMinutes
                            ]);
                        }
                    } catch (\Exception $e) {
                        Log::error('Failed to send driver notification for order delay', [
                            'order_id' => $request->order_id,
                            'error' => $e->getMessage()
                        ]);
                    }
                }
            } else {
                // First time setting prep time - mark as started preparing
                $updateData['is_seller_started_preparing'] = 1;
            }

            // Propagate the prep_time update to ALL Zenfoo store rows (12, 13) of this
            // order so the merged view stays consistent.
            DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->whereIn('store_id', [12, 13])
                ->update($updateData);

            // Check if all sellers have started preparing and sync to Firestore
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
                    Log::info('Firestore sync completed for order: ' . $request->order_id, ['result' => $firestoreResult]);
                } catch (\Exception $firestoreException) {
                    Log::error('Firestore sync failed for order: ' . $request->order_id, [
                        'error' => $firestoreException->getMessage(),
                        'trace' => $firestoreException->getTraceAsString()
                    ]);
                    // Continue execution even if Firestore sync fails
                }

                // Dispatch retry job to keep searching for drivers if none accepted
                try {
                    RetryDeliveryBoyAssignmentJob::dispatchForOrder($request->order_id);
                } catch (\Exception $retryJobException) {
                    Log::error('Failed to dispatch retry delivery boy assignment job for order: ' . $request->order_id, [
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
                    Log::info('Order status updated to Preparing for order: ' . $request->order_id, ['result' => $orderStatusResult]);
                } catch (\Exception $statusException) {
                    Log::error('Failed to update order status for order: ' . $request->order_id, [
                        'error' => $statusException->getMessage(),
                        'trace' => $statusException->getTraceAsString()
                    ]);
                    // Continue execution even if status update fails
                }
            }

            Log::info('Prep time updated successfully', [
                'order_id' => $request->order_id,
                'tracking_id' => $request->tracking_id,
                'prep_time' => $prepTime,
                'is_new' => empty($trackingRecord->prep_time)
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'Prep time updated successfully',
                'data' => [
                    'prep_time' => $prepTime,
                    'is_seller_started_preparing' => $updateData['is_seller_started_preparing'] ?? $trackingRecord->is_seller_started_preparing,
                    'delayed_time_in_min' => $updateData['delayed_time_in_min'] ?? $trackingRecord->delayed_time_in_min
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error updating prep time', [
                'order_id' => $request->order_id ?? null,
                'tracking_id' => $request->tracking_id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to update prep time',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Mark order as packed by seller (Admin panel)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAsPacked(Request $request)
    {
        try {
            $request->validate([
                'order_id' => 'required|integer',
                'tracking_id' => 'required|integer',
            ]);

            Log::info('Admin marking order as packed', [
                'order_id' => $request->order_id,
                'tracking_id' => $request->tracking_id
            ]);

            // Get the tracking record for store_id = 12
            $trackingRecord = DB::table('order_seller_status_tracking')
                ->where('id', $request->tracking_id)
                ->where('order_id', $request->order_id)
                ->whereIn('store_id', [12, 13])
                ->first();

            if (!$trackingRecord) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order tracking record not found'
                ], 404);
            }

            // Update the tracking record status to packed_by_seller
            $updateData = [
                'status' => 'packed_by_seller',
                'updated_at' => now()
            ];

            // Propagate "packed" to ALL Zenfoo store rows of this order so they advance together.
            DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->whereIn('store_id', [12, 13])
                ->update($updateData);

            // Check if all sellers have packed
            $allTrackingRecords = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->get();

            $allPacked = $allTrackingRecords->every(function ($record) {
                return $record->status === 'packed_by_seller';
            });

            if ($allPacked) {
                // Update main order status to 3 (Ready for Pickup)
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
                            message: "Great news! Your order #{$request->order_id} has been packed and is ready for pickup by the delivery partner.",
                            image: '',
                            pageNavigation: 'order',
                            navigationId: $request->order_id
                        );
                        Log::info('Customer notification sent for packed order (Zenfoo Store)', [
                            'order_id' => $request->order_id,
                            'customer_id' => $order->user_id
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error('Failed to send customer notification for packed order (Zenfoo Store)', [
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
                    Log::info('Order status updated to Ready for Pickup for order: ' . $request->order_id, ['result' => $orderStatusResult]);
                } catch (\Exception $statusException) {
                    Log::error('Failed to update order status for order: ' . $request->order_id, [
                        'error' => $statusException->getMessage(),
                        'trace' => $statusException->getTraceAsString()
                    ]);
                    // Continue execution even if status update fails
                }

                Log::info('All sellers packed - Order status updated to 3', [
                    'order_id' => $request->order_id
                ]);
            }

            Log::info('Order marked as packed successfully', [
                'order_id' => $request->order_id,
                'tracking_id' => $request->tracking_id,
                'all_packed' => $allPacked
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'Order marked as packed successfully',
                'data' => [
                    'order_id' => $request->order_id,
                    'tracking_id' => $request->tracking_id,
                    'status' => 'packed_by_seller',
                    'all_packed' => $allPacked
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error marking order as packed', [
                'order_id' => $request->order_id ?? null,
                'tracking_id' => $request->tracking_id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to mark order as packed',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Verify OTP and update tracking status to given_to_delivery_partner (Admin panel)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyOtp(Request $request)
    {
        try {
            $request->validate([
                'order_id' => 'required|integer',
                'tracking_id' => 'required|integer',
                'otp' => 'required|string|size:4',
            ]);

            Log::info('Admin verifying OTP for Zenfoo store', [
                'order_id' => $request->order_id,
                'tracking_id' => $request->tracking_id
            ]);

            // Get the tracking record for store_id = 12
            $trackingRecord = DB::table('order_seller_status_tracking')
                ->where('id', $request->tracking_id)
                ->where('order_id', $request->order_id)
                ->whereIn('store_id', [12, 13])
                ->first();

            if (!$trackingRecord) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order tracking record not found'
                ], 404);
            }

            // Verify OTP
            if ($trackingRecord->otp != $request->otp) {
                Log::warning('OTP verification failed - Invalid OTP', [
                    'order_id' => $request->order_id,
                    'tracking_id' => $request->tracking_id,
                    'expected' => $trackingRecord->otp,
                    'received' => $request->otp
                ]);

                return response()->json([
                    'status' => 0,
                    'message' => 'Invalid OTP'
                ], 400);
            }

            // Propagate "given_to_delivery_partner" + driver-picked flag to ALL Zenfoo store
            // rows of this order so they advance together (single shared OTP unlocks both).
            DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->whereIn('store_id', [12, 13])
                ->update([
                    'status' => 'given_to_delivery_partner',
                    'is_driver_picked' => 1,
                    'updated_at' => now()
                ]);

            // Check if all sellers have given to delivery partner
            $allTrackingRecords = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->get();

            $allGivenToDriver = $allTrackingRecords->every(function ($record) {
                return $record->status === 'given_to_delivery_partner';
            });

            if ($allGivenToDriver) {
                // Update main order status to 5 (Out for Delivery)
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
                        Log::info('Customer notification sent for order out for delivery (Zenfoo Store)', [
                            'order_id' => $request->order_id,
                            'customer_id' => $order->user_id
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error('Failed to send customer notification for order out for delivery (Zenfoo Store)', [
                        'order_id' => $request->order_id,
                        'error' => $e->getMessage()
                    ]);
                }

                Log::info('All sellers given to delivery partner - Order status updated to 5', [
                    'order_id' => $request->order_id
                ]);
            }

            Log::info('OTP verified successfully', [
                'order_id' => $request->order_id,
                'tracking_id' => $request->tracking_id,
                'all_given_to_driver' => $allGivenToDriver
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'OTP verified successfully',
                'data' => [
                    'order_id' => $request->order_id,
                    'tracking_id' => $request->tracking_id,
                    'status' => 'given_to_delivery_partner',
                    'all_given_to_driver' => $allGivenToDriver
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error verifying OTP', [
                'order_id' => $request->order_id ?? null,
                'tracking_id' => $request->tracking_id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to verify OTP',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get human-readable status label
     *
     * @param string $status
     * @return string
     */
    private function getStatusLabel($status)
    {
        $labels = [
            'assigned_to_seller' => 'Start Preparing',
            'packed_by_seller' => 'Packed by Seller',
            'given_to_delivery_partner' => 'Given to Delivery Partner'
        ];

        return $labels[$status] ?? ucfirst(str_replace('_', ' ', $status));
    }
}
