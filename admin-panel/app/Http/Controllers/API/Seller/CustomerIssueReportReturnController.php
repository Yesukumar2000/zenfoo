<?php

namespace App\Http\Controllers\API\Seller;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\CustomerItemMissingReport;
use App\Models\Seller;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Services\AdminNotificationService;
use App\Services\CustomerNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class CustomerIssueReportReturnController extends Controller
{
    /**
     * Get customer issue report returns for authenticated seller
     */
    public function getReturns(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'nullable|integer|in:0,1',
            'report_status' => 'nullable|integer',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
            'page' => 'nullable|integer|min:1',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get authenticated admin user
            $admin = auth()->guard('api')->user();

            if (!$admin) {
                return CommonHelper::responseError("Invalid token or unauthorized access.");
            }

            $seller = DB::table('sellers')->where('admin_id', $admin->id)->first();

            if (!$seller) {
                return CommonHelper::responseError('Seller account not found.');
            }

            // Query customer_issue_report_returns table
            $query = DB::table('customer_issue_report_returns')
                ->where('seller_id', $seller->id);

            // Apply filters
            if ($request->filled('status') || $request->input('status') === '0' || $request->input('status') === 0) {
                $query->where('is_return_accepted', $request->status);
            }

            if ($request->filled('from_date')) {
                $query->whereDate('date', '>=', $request->from_date);
            }

            if ($request->filled('to_date')) {
                $query->whereDate('date', '<=', $request->to_date);
            }

            // Filter by report status (e.g. 2 = resolved, 4 = driver assigned)
            if ($request->filled('report_status')) {
                $matchingReportIds = DB::table('customer_item_missing_reports')
                    ->where('status', $request->report_status)
                    ->pluck('id')
                    ->toArray();

                if (empty($matchingReportIds)) {
                    return CommonHelper::responseSuccessWithData('No return requests found.', [
                        'returns' => [],
                        'pagination' => [
                            'current_page' => (int) $request->input('page', 1),
                            'per_page'     => (int) $request->input('per_page', 20),
                            'total'        => 0,
                            'total_pages'  => 0,
                        ],
                    ]);
                }

                $query->whereIn('report_id', $matchingReportIds);
            }

            $perPage = $request->input('per_page', 20);
            $page = $request->input('page', 1);

            $totalCount = $query->count();

            $returns = $query->orderBy('created_at', 'desc')
                ->skip(($page - 1) * $perPage)
                ->take($perPage)
                ->get();

            if ($returns->isEmpty()) {
                return CommonHelper::responseSuccessWithData('No return requests found.', [
                    'returns' => [],
                    'pagination' => [
                        'current_page' => (int) $page,
                        'per_page' => (int) $perPage,
                        'total' => 0,
                        'total_pages' => 0,
                    ],
                ]);
            }

            // Get all report IDs
            $reportIds = $returns->pluck('report_id')->unique()->toArray();

            // Fetch reports with related data
            $reports = CustomerItemMissingReport::whereIn('id', $reportIds)
                ->select('id', 'customer_id', 'order_id', 'report_type', 'selected_items', 'selected_combo_items', 'description', 'is_refund_requested', 'status', 'admin_remarks', 'created_at', 'updated_at')
                ->get()
                ->keyBy('id');

            // Get customer IDs
            $customerIds = $reports->pluck('customer_id')->unique()->toArray();
            $customers = DB::table('users')
                ->whereIn('id', $customerIds)
                ->select('id', 'name', 'mobile', 'email')
                ->get()
                ->keyBy('id');

            // Get order IDs
            $orderIds = $reports->pluck('order_id')->unique()->toArray();
            $orders = DB::table('orders')
                ->whereIn('id', $orderIds)
                ->select('id', 'status', 'delivery_boy_id', 'delivery_time_before_images', 'address_id', 'address', 'latitude', 'longitude')
                ->get()
                ->keyBy('id');

            // Get customer delivery addresses from user_addresses table
            $addressIds = $orders->pluck('address_id')->filter()->unique()->toArray();
            $userAddresses = [];
            if (!empty($addressIds)) {
                $userAddresses = DB::table('user_addresses')
                    ->whereIn('id', $addressIds)
                    ->select('id', 'address', 'landmark', 'city', 'pincode', 'latitude', 'longitude')
                    ->get()
                    ->keyBy('id');
            }

            // Get seller's store_ids per order and driver pickup images (only for this seller's stores)
            $orderDriverPickupImages = [];
            $sellerOrderStoreIds = [];
            if (!empty($orderIds)) {
                $sellerTrackingRows = DB::table('order_seller_status_tracking')
                    ->whereIn('order_id', $orderIds)
                    ->where('seller_id', $seller->id)
                    ->select('order_id', 'store_id', 'driver_captured_images_when_marked_as_pickup')
                    ->get();

                foreach ($sellerTrackingRows as $tracking) {
                    // Build seller's store_ids per order
                    if (!isset($sellerOrderStoreIds[$tracking->order_id])) {
                        $sellerOrderStoreIds[$tracking->order_id] = [];
                    }
                    $sellerOrderStoreIds[$tracking->order_id][] = (int) $tracking->store_id;

                    // Collect driver pickup images for this seller's stores only
                    if (!empty($tracking->driver_captured_images_when_marked_as_pickup)) {
                        $images = json_decode($tracking->driver_captured_images_when_marked_as_pickup, true);
                        if (is_array($images) && !empty($images)) {
                            if (!isset($orderDriverPickupImages[$tracking->order_id])) {
                                $orderDriverPickupImages[$tracking->order_id] = [];
                            }
                            foreach ($images as $image) {
                                $orderDriverPickupImages[$tracking->order_id][] = $image;
                            }
                        }
                    }
                }
            }

            // Get delivery boys
            $deliveryBoyIds = $orders->pluck('delivery_boy_id')->filter()->unique()->toArray();
            $deliveryBoys = [];
            if (!empty($deliveryBoyIds)) {
                $deliveryBoys = DB::table('delivery_boys')
                    ->whereIn('id', $deliveryBoyIds)
                    ->select('id', 'name', 'mobile')
                    ->get()
                    ->keyBy('id');
            }

            // Get all product IDs from returns and fetch product images
            $allProductIds = [];
            foreach ($returns as $return) {
                $productIds = json_decode($return->product_ids, true) ?? [];
                $allProductIds = array_merge($allProductIds, $productIds);
            }
            $allProductIds = array_unique($allProductIds);

            $productImages = [];
            if (!empty($allProductIds)) {
                $products = DB::table('products')
                    ->whereIn('id', $allProductIds)
                    ->select('id', 'name', 'image')
                    ->get();

                foreach ($products as $product) {
                    $productImages[$product->id] = [
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'image' => $product->image,
                    ];
                }
            }

            // Build measurement & quantity lookup per report from selected_items
            // Keys: report_id → product_name → {measurement, quantity}
            $reportProductMeasurements = [];
            foreach ($reports as $reportId => $rpt) {
                $selectedItems = is_array($rpt->selected_items)
                    ? $rpt->selected_items
                    : (json_decode($rpt->selected_items, true) ?? []);

                foreach ($selectedItems as $storeGroup) {
                    foreach ($storeGroup['items'] ?? [] as $item) {
                        $pName = $item['product_name'] ?? '';
                        if ($pName) {
                            $reportProductMeasurements[$reportId][$pName] = [
                                'measurement' => $item['variant_measurement'] ?? null,
                                'quantity'    => $item['quantity'] ?? null,
                            ];
                        }
                    }
                }
            }

            // Build response
            $response = [];
            foreach ($returns as $return) {
                $report = $reports[$return->report_id] ?? null;
                if (!$report) {
                    continue;
                }

                $customer = $customers[$report->customer_id] ?? null;
                $order = $orders[$report->order_id] ?? null;
                $deliveryBoy = null;
                if ($order && $order->delivery_boy_id) {
                    $deliveryBoy = $deliveryBoys[$order->delivery_boy_id] ?? null;
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
                    }
                }

                // Get delivery images for this order
                $driverPickupImages = $orderDriverPickupImages[$report->order_id] ?? [];
                $deliveryBeforeImages = [];
                if ($order && !empty($order->delivery_time_before_images)) {
                    $images = json_decode($order->delivery_time_before_images, true);
                    if (is_array($images)) {
                        $deliveryBeforeImages = $images;
                    }
                }

                // Get customer-given images only for this seller's stores
                $customerGivenImages = [];
                $sellerStoreIds = $sellerOrderStoreIds[$report->order_id] ?? [];
                $reportSelectedItems = is_array($report->selected_items)
                    ? $report->selected_items
                    : (json_decode($report->selected_items, true) ?? []);
                foreach ($reportSelectedItems as $storeGroup) {
                    if (in_array((int) ($storeGroup['store_id'] ?? 0), $sellerStoreIds)) {
                        $customerGivenImages = array_merge($customerGivenImages, $storeGroup['image_urls'] ?? []);
                    }
                }

                // Get product images for this return's product_ids
                $returnProductIds = json_decode($return->product_ids, true) ?? [];
                $returnProductImages = [];
                foreach ($returnProductIds as $productId) {
                    if (isset($productImages[$productId])) {
                        $pd = $productImages[$productId];
                        $detail = ($reportProductMeasurements[$return->report_id] ?? [])[$pd['product_name']] ?? [];
                        $returnProductImages[] = [
                            'product_id'   => $pd['product_id'],
                            'product_name' => $pd['product_name'],
                            'image'        => $pd['image'],
                            'measurement'  => $detail['measurement'] ?? null,
                            'quantity'     => $detail['quantity'] ?? null,
                        ];
                    }
                }

                // Get customer delivery address
                $customerAddress = null;
                if ($order) {
                    // First try to get detailed address from user_addresses table
                    if ($order->address_id && isset($userAddresses[$order->address_id])) {
                        $userAddress = $userAddresses[$order->address_id];
                        $customerAddress = [
                            'address' => $userAddress->address,
                            'landmark' => $userAddress->landmark,
                            'city' => $userAddress->city,
                            'pincode' => $userAddress->pincode,
                            'lat_long' => ($userAddress->latitude && $userAddress->longitude)
                                ? $userAddress->latitude . ',' . $userAddress->longitude
                                : null,
                            'full_address' => $order->address,
                        ];
                    } elseif ($order->address) {
                        // Fallback to order's address field
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

                $response[] = [
                    'return_id' => $return->id,
                    'report_id' => $return->report_id,
                    'seller_id' => $return->seller_id,
                    'customer_id' => $return->customer_id,
                    'date' => $return->date,
                    'product_ids' => $returnProductIds,
                    'products' => $returnProductImages,
                    'delivery_partner_id' => $return->delivery_partner_id,
                    'delivered_date' => $return->delivered_date,
                    'is_return_accepted' => $return->is_return_accepted,
                    'return_status' => $return->is_return_accepted == 1 ? 'Accepted' : 'Pending',
                    'report' => [
                        'order_id' => $report->order_id,
                        'report_type' => $report->report_type,
                        'description' => $report->description,
                        'is_refund_requested' => $report->is_refund_requested,
                        'status' => $report->status,
                        'status_name' => $report->status_name,
                        'admin_remarks' => $report->admin_remarks,
                        'selected_items' => $report->selected_items ?? [],
                        'selected_combo_items' => $report->selected_combo_items ?? [],
                        'created_at' => $report->created_at->format('Y-m-d H:i:s'),
                        'updated_at' => $report->updated_at->format('Y-m-d H:i:s'),
                    ],
                    'customer' => $customer ? [
                        'id' => $customer->id,
                        'name' => $customer->name,
                        'mobile' => $customer->mobile,
                        'email' => $customer->email,
                    ] : null,
                    'customer_address' => $customerAddress,
                    'delivery_partner' => $deliveryBoy ? [
                        'id' => $deliveryBoy->id,
                        'name' => $deliveryBoy->name,
                        'mobile' => $deliveryBoy->mobile,
                    ] : null,
                    'delivery_date' => $deliveryDate,
                    'delivery_images' => [
                        'customer_given_images' => $customerGivenImages,
                        'driver_pickup_images' => $driverPickupImages,
                        'delivery_before_images' => $deliveryBeforeImages,
                    ],
                ];
            }

            return CommonHelper::responseSuccessWithData('Return requests fetched successfully.', [
                'returns' => $response,
                'pagination' => [
                    'current_page' => (int) $page,
                    'per_page' => (int) $perPage,
                    'total' => $totalCount,
                    'total_pages' => ceil($totalCount / $perPage),
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Get Seller Return Requests Error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id ?? null,
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch return requests. Please try again later.');
        }
    }

    /**
     * Get single return request by ID
     */
    public function getReturnById(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'return_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get authenticated admin user
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get seller by admin_id
            $seller = Seller::where('admin_id', $user->id)->first();

            
            if (!$seller) {
                return CommonHelper::responseError('Seller account not found.');
            }

            // Get return request
            $return = DB::table('customer_issue_report_returns')
                ->where('id', $request->return_id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$return) {
                return CommonHelper::responseError('Return request not found.');
            }

            // Get report details
            $report = CustomerItemMissingReport::find($return->report_id);

            if (!$report) {
                return CommonHelper::responseError('Associated report not found.');
            }

            // Get customer details
            $customer = DB::table('users')
                ->where('id', $return->customer_id)
                ->select('id', 'name', 'mobile', 'email')
                ->first();

            // Get order details
            $order = DB::table('orders')
                ->where('id', $report->order_id)
                ->select('id', 'status', 'delivery_boy_id', 'delivery_time_before_images', 'address_id', 'address', 'latitude', 'longitude')
                ->first();

            // Get delivery boy details
            $deliveryBoy = null;
            if ($order && $order->delivery_boy_id) {
                $deliveryBoy = DB::table('delivery_boys')
                    ->where('id', $order->delivery_boy_id)
                    ->select('id', 'name', 'mobile')
                    ->first();
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
                }
            }

            // Get driver pickup images from order_seller_status_tracking
            $driverPickupImages = [];
            $sellerTrackingImages = DB::table('order_seller_status_tracking')
                ->where('order_id', $report->order_id)
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

            // Get delivery before images from orders table
            $deliveryBeforeImages = [];
            if ($order && !empty($order->delivery_time_before_images)) {
                $images = json_decode($order->delivery_time_before_images, true);
                if (is_array($images)) {
                    $deliveryBeforeImages = $images;
                }
            }

            // Get product images for this return's product_ids
            $returnProductIds = json_decode($return->product_ids, true) ?? [];
            $returnProductImages = [];
            if (!empty($returnProductIds)) {
                $products = DB::table('products')
                    ->whereIn('id', $returnProductIds)
                    ->select('id', 'name', 'image')
                    ->get();

                foreach ($products as $product) {
                    $returnProductImages[] = [
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'image' => $product->image,
                    ];
                }
            }

            // Get customer delivery address
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
                            'full_address' => $order->address,
                        ];
                    }
                }

                // Fallback to order's address field
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

            $response = [
                'return_id' => $return->id,
                'report_id' => $return->report_id,
                'seller_id' => $return->seller_id,
                'customer_id' => $return->customer_id,
                'date' => $return->date,
                'product_ids' => $returnProductIds,
                'products' => $returnProductImages,
                'delivery_partner_id' => $return->delivery_partner_id,
                'delivered_date' => $return->delivered_date,
                'is_return_accepted' => $return->is_return_accepted,
                'return_status' => $return->is_return_accepted == 1 ? 'Accepted' : 'Pending',
                'report' => [
                    'order_id' => $report->order_id,
                    'report_type' => $report->report_type,
                    'description' => $report->description,
                    'is_refund_requested' => $report->is_refund_requested,
                    'status' => $report->status,
                    'status_name' => $report->status_name,
                    'admin_remarks' => $report->admin_remarks,
                    'selected_items' => $report->selected_items ?? [],
                    'selected_combo_items' => $report->selected_combo_items ?? [],
                    'created_at' => $report->created_at->format('Y-m-d H:i:s'),
                    'updated_at' => $report->updated_at->format('Y-m-d H:i:s'),
                ],
                'customer' => $customer ? [
                    'id' => $customer->id,
                    'name' => $customer->name,
                    'mobile' => $customer->mobile,
                    'email' => $customer->email,
                ] : null,
                'customer_address' => $customerAddress,
                'delivery_partner' => $deliveryBoy ? [
                    'id' => $deliveryBoy->id,
                    'name' => $deliveryBoy->name,
                    'mobile' => $deliveryBoy->mobile,
                ] : null,
                'delivery_date' => $deliveryDate,
                'delivery_images' => [
                    'driver_pickup_images' => $driverPickupImages,
                    'delivery_before_images' => $deliveryBeforeImages,
                ],
            ];

            return CommonHelper::responseSuccessWithData('Return request fetched successfully.', $response);

        } catch (\Exception $e) {
            Log::error('Get Seller Return Request By ID Error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id ?? null,
                'return_id' => $request->return_id,
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch return request. Please try again later.');
        }
    }

    /**
     * Update return acceptance status
     */
    public function updateReturnStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'return_id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get authenticated admin user
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get seller by admin_id
            $seller = Seller::where('admin_id', $user->id)->first();

            if (!$seller) {
                return CommonHelper::responseError('Seller account not found.');
            }

            // Get return request
            $return = DB::table('customer_issue_report_returns')
                ->where('id', $request->return_id)
                ->where('seller_id', $seller->id)
                ->first();

            if (!$return) {
                return CommonHelper::responseError('Return request not found.');
            }

            // Check if this return is already accepted
            if ($return->is_return_accepted == 1) {
                return CommonHelper::responseSuccess('Return already accepted. Refund has been processed. Please update your stock quantity for the returned products if needed.');
            }

            // Update return status
            DB::table('customer_issue_report_returns')
                ->where('id', $request->return_id)
                ->update([
                    'is_return_accepted' => 1,
                    'updated_at' => now(),
                ]);

            Log::info('Seller updated return status', [
                'seller_id' => $seller->id,
                'return_id' => $request->return_id,
                'is_return_accepted' => 1,
            ]);

            // Update seller_wallet_transactions for this seller and order
            // Get order_id from the report
            $reportForTransaction = CustomerItemMissingReport::find($return->report_id);

            // Only move money (seller balance deduction + customer wallet credit)
            // when the customer actually requested a refund on the report. If no
            // refund was requested, the return is still accepted and the report
            // is resolved, but no money moves.
            $refundRequested = $reportForTransaction
                ? (bool) $reportForTransaction->is_refund_requested
                : false;

            if ($reportForTransaction) {
                $orderId = $reportForTransaction->order_id;
                $refundableAmount = (float) ($return->refundable_amount ?? 0);

                // Find the seller's transaction for this order
                $sellerTransaction = DB::table('seller_wallet_transactions')
                    ->where('seller_id', $return->seller_id)
                    ->where('order_id', $orderId)
                    ->first();

                if ($refundRequested && $sellerTransaction && $refundableAmount > 0) {
                    // Calculate new balance_after by subtracting refundable amount
                    $newBalanceAfter = (float) $sellerTransaction->balance_after - $refundableAmount;
                    $transactionAmount = (float) $sellerTransaction->amount;

                    // Build updated message
                    $currentMessage = $sellerTransaction->message ?? '';
                    $refundMessage = " | Refund to customer: Rs. " . number_format($refundableAmount, 2) . " (Return accepted for Issue Report #{$return->report_id})";
                    $updatedMessage = $currentMessage . $refundMessage;
                     $newBalanceAfter = max(0, $newBalanceAfter); // Ensure balance_after doesn't go negative
                    // Prepare update data
                    $updateData = [
                        'balance_after' => $newBalanceAfter,
                        'is_refunded_to_customer' => 1,
                        'refundable_amount' => $refundableAmount,
                        'message' => $updatedMessage,
                        'updated_at' => now(),
                    ];

                    // If amount <= refundable_amount, mark as paid so admin won't pay again
                    if ($transactionAmount <= $refundableAmount) {
                        $updateData['is_paid_to_seller'] = 1;
                        $updateData['paid_by'] = 1; // System/Admin
                        $updateData['paid_at'] = now();
                        $updateData['payment_transaction_id'] = 'refund_settled_for_order_' . $orderId;

                        // Update message to indicate full refund settlement
                        $updateData['message'] = $updatedMessage . " | Transaction settled: Full amount refunded to customer";

                        Log::info('Seller transaction marked as paid due to full refund', [
                            'seller_id' => $return->seller_id,
                            'order_id' => $orderId,
                            'transaction_id' => $sellerTransaction->id,
                            'transaction_amount' => $transactionAmount,
                            'refundable_amount' => $refundableAmount,
                        ]);
                    }

                    // Update the transaction
                    DB::table('seller_wallet_transactions')
                        ->where('id', $sellerTransaction->id)
                        ->update($updateData);

                    // Update seller's balance in sellers table
                    $sellerRecord = DB::table('sellers')
                        ->where('id', $return->seller_id)
                        ->first();

                    if ($sellerRecord) {
                        $currentSellerBalance = (float) ($sellerRecord->balance ?? 0);
                        $newSellerBalance = $currentSellerBalance - $refundableAmount;

                        DB::table('sellers')
                            ->where('id', $return->seller_id)
                            ->update([
                                'balance' => $newSellerBalance,
                                'updated_at' => now(),
                            ]);

                        Log::info('Seller balance updated for refund', [
                            'seller_id' => $return->seller_id,
                            'original_balance' => $currentSellerBalance,
                            'refundable_amount' => $refundableAmount,
                            'new_balance' => $newSellerBalance,
                        ]);
                    }

                    Log::info('Seller wallet transaction updated for refund', [
                        'seller_id' => $return->seller_id,
                        'order_id' => $orderId,
                        'transaction_id' => $sellerTransaction->id,
                        'original_balance_after' => $sellerTransaction->balance_after,
                        'refundable_amount' => $refundableAmount,
                        'new_balance_after' => $newBalanceAfter,
                    ]);
                }
            }

            // Check if all sellers have accepted the return for this report
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

            // If all sellers have accepted, update report status to resolved
            if ($totalReturnRecords > 0 && $totalReturnRecords === $acceptedReturnRecords) {
                // Get the report first to get current status for status_change_json
                $report = CustomerItemMissingReport::find($reportId);
                $previousStatus = $report ? $report->status : 0;

                // Guard: if admin already directly resolved this report, skip auto-resolve
                // and customer wallet credit to prevent double-refund
                if ($report && $report->status == CustomerItemMissingReport::$statusResolved) {
                    Log::info('All sellers accepted return but report already resolved by admin - skipping customer credit', [
                        'report_id' => $reportId,
                    ]);
                    return CommonHelper::responseSuccess('Return status updated successfully. The item has been returned. Please update your stock quantity for the returned products if needed.');
                }

                // Calculate total refundable amount from all return records (needed for status message)
                $totalRefundableAmountForStatus = DB::table('customer_issue_report_returns')
                    ->where('report_id', $reportId)
                    ->sum('refundable_amount');

                // Get order details to check for deductions
                $orderForDeductions = DB::table('orders')
                    ->where('id', $report->order_id)
                    ->select('cart_metadata')
                    ->first();

                $promoDiscountForStatus = 0;
                $milestoneAmountForStatus = 0;

                if ($orderForDeductions && $orderForDeductions->cart_metadata) {
                    $cartMetadataForStatus = json_decode($orderForDeductions->cart_metadata, true);
                    $billingSummaryForStatus = $cartMetadataForStatus['billing_summary'] ?? [];
                    $promoDiscountForStatus = (float) ($billingSummaryForStatus['promocode_discount'] ?? 0);
                    $milestoneAmountForStatus = (float) ($billingSummaryForStatus['claimable_milestone_amount'] ?? 0);
                }

                $finalRefundForStatus = $totalRefundableAmountForStatus - ($promoDiscountForStatus + $milestoneAmountForStatus);
                if ($finalRefundForStatus < 0) {
                    $finalRefundForStatus = 0;
                }

                // No refund unless the customer requested one.
                if (!$refundRequested) {
                    $finalRefundForStatus = 0;
                }

                // Build status change message
                $statusMessage = "Your issue has been resolved.";
                if ($finalRefundForStatus > 0) {
                    $statusMessage = "Your issue has been resolved. An amount of ₹" . number_format($finalRefundForStatus, 2) . " has been refunded to your wallet.";
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
                    'admin_remarks' => 'All sellers accepted the return',
                    'refund_amount' => $finalRefundForStatus,
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

                Log::info('All sellers accepted return - Report marked as resolved', [
                    'report_id' => $reportId,
                    'total_sellers' => $totalReturnRecords,
                    'status_change_json' => $newStatusEntry,
                ]);

                // Refresh report to get updated data
                $report = CustomerItemMissingReport::find($reportId);

                if ($report) {
                    // Calculate total refundable amount from all return records
                    $totalRefundableAmount = DB::table('customer_issue_report_returns')
                        ->where('report_id', $reportId)
                        ->sum('refundable_amount');

                    // Get order details to check for deductions (promocode_discount, claimable_milestone_amount)
                    $order = DB::table('orders')
                        ->where('id', $report->order_id)
                        ->select('cart_metadata')
                        ->first();

                    $promocodeDiscount = 0;
                    $claimableMilestoneAmount = 0;
                    $deductionMessage = '';

                    if ($order && $order->cart_metadata) {
                        $cartMetadata = json_decode($order->cart_metadata, true);
                        $billingSummary = $cartMetadata['billing_summary'] ?? [];

                        $promocodeDiscount = (float) ($billingSummary['promocode_discount'] ?? 0);
                        $claimableMilestoneAmount = (float) ($billingSummary['claimable_milestone_amount'] ?? 0);
                    }

                    // Calculate total deductions
                    $totalDeductions = $promocodeDiscount + $claimableMilestoneAmount;

                    // Calculate final refund amount after deductions
                    $finalRefundAmount = $totalRefundableAmount - $totalDeductions;
                    if ($finalRefundAmount < 0) {
                        $finalRefundAmount = 0;
                    }

                    // No refund unless the customer requested one.
                    if (!$refundRequested) {
                        $finalRefundAmount = 0;
                    }

                    // Build deduction message if any deductions exist
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

                    // Credit refund to customer wallet if final refund amount exists
                    if ($finalRefundAmount > 0) {
                        try {
                            // Get the customer
                            $customer = User::find($report->customer_id);

                            if ($customer) {
                                // Update customer balance
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

                                Log::info('Refund credited to customer wallet', [
                                    'report_id' => $reportId,
                                    'customer_id' => $report->customer_id,
                                    'original_refund_amount' => $totalRefundableAmount,
                                    'promocode_discount' => $promocodeDiscount,
                                    'claimable_milestone_amount' => $claimableMilestoneAmount,
                                    'total_deductions' => $totalDeductions,
                                    'final_refund_amount' => $finalRefundAmount,
                                    'new_balance' => $customer->balance,
                                    'wallet_transaction_id' => $walletTransaction->id,
                                ]);
                            }
                        } catch (\Exception $e) {
                            Log::error('Failed to credit refund to customer wallet', [
                                'report_id' => $reportId,
                                'customer_id' => $report->customer_id,
                                'refund_amount' => $finalRefundAmount,
                                'error' => $e->getMessage(),
                            ]);
                        }
                    }

                    // Send notification to customer
                    try {
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

                        Log::info('Customer notification sent for resolved report', [
                            'report_id' => $reportId,
                            'customer_id' => $report->customer_id,
                        ]);
                    } catch (\Exception $e) {
                        Log::error('Failed to send customer notification for resolved report', [
                            'report_id' => $reportId,
                            'error' => $e->getMessage(),
                        ]);
                    }

                    // Send notification to admin
                    try {
                        $adminMessage = "Issue Report #{$reportId} for Order #{$report->order_id} has been resolved. All sellers have accepted the return.";
                        if ($finalRefundAmount > 0) {
                            $adminMessage .= " Refund of ₹" . number_format($finalRefundAmount, 2) . " credited to customer wallet.";
                        }

                        AdminNotificationService::send(
                            null, // All admins
                            'Issue Report Resolved',
                            $adminMessage,
                            'customer_issue_report',
                            ['report_id' => $reportId, 'order_id' => $report->order_id, 'refund_amount' => $finalRefundAmount]
                        );

                        Log::info('Admin notification sent for resolved report', [
                            'report_id' => $reportId,
                        ]);
                    } catch (\Exception $e) {
                        Log::error('Failed to send admin notification for resolved report', [
                            'report_id' => $reportId,
                            'error' => $e->getMessage(),
                        ]);
                    }
                }
            }

            return CommonHelper::responseSuccess('Return status updated successfully. The item has been returned. Please update your stock quantity for the returned products if needed.');

        } catch (\Exception $e) {
            Log::error('Update Seller Return Status Error', [
                'error' => $e->getMessage(),
                'return_id' => $request->return_id,
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to update return status. Please try again later.');
        }
    }

    /**
     * Get customer issue report by report ID for authenticated seller
     */
    public function getReportById(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'report_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get authenticated admin user
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get seller by admin_id
            $seller = Seller::where('admin_id', $user->id)->first();

            if (!$seller) {
                return CommonHelper::responseError('Seller account not found.');
            }

            // Get the report from customer_item_missing_reports table
            // We need to verify this report belongs to this seller by checking the order's store_id
            $report = CustomerItemMissingReport::where('id', $request->report_id)->first();

            if (!$report) {
                return CommonHelper::responseError('Report not found.');
            }

            // Verify the report belongs to this seller by checking order's items
            // Get order details to find store association
            $order = DB::table('orders')
                ->where('id', $report->order_id)
                ->first();

            if (!$order) {
                return CommonHelper::responseError('Associated order not found.');
            }

            // Check if this seller has items in this order via order_items
            $hasSellerItems = DB::table('order_items')
                ->where('order_id', $report->order_id)
                ->where('store_id', $seller->id)
                ->exists();

            if (!$hasSellerItems) {
                return CommonHelper::responseError('You do not have access to this report.');
            }

            // Get customer details
            $customer = DB::table('users')
                ->where('id', $report->customer_id)
                ->select('id', 'name', 'mobile', 'email')
                ->first();

            // Build response
            $response = [
                'report_id' => $report->id,
                'customer_id' => $report->customer_id,
                'order_id' => $report->order_id,
                'report_type' => $report->report_type,
                'selected_items' => $report->selected_items ?? [],
                'selected_combo_items' => $report->selected_combo_items ?? [],
                'description' => $report->description,
                'is_refund_requested' => $report->is_refund_requested,
                'status' => $report->status,
                'status_name' => $report->status_name,
                'admin_remarks' => $report->admin_remarks,
                'created_at' => $report->created_at->format('Y-m-d H:i:s'),
                'updated_at' => $report->updated_at->format('Y-m-d H:i:s'),
                'customer' => $customer ? [
                    'id' => $customer->id,
                    'name' => $customer->name,
                    'mobile' => $customer->mobile,
                    'email' => $customer->email,
                ] : null,
            ];

            return CommonHelper::responseSuccessWithData('Report fetched successfully.', $response);

        } catch (\Exception $e) {
            Log::error('Get Report By ID Error', [
                'error' => $e->getMessage(),
                'user_id' => $user->id ?? null,
                'report_id' => $request->report_id,
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);
            return CommonHelper::responseError('Failed to fetch report. Please try again later.');
        }
    }
}
