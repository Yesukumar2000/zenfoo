<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderInvoiceController extends Controller
{
    /**
     * Get order invoice for thermal printer (USB printing)
     * Requires bearer token authentication - seller_id obtained from token
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getOrderInvoice(Request $request)
    {
        // Seller logged in through token (like other seller endpoints)
        $adminUser = auth()->guard('api')->user();

        if (!$adminUser) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized seller'
            ], 401);
        }

        // Validate order_id
        if (!$request->has('order_id') || empty($request->order_id)) {
            return response()->json([
                'status' => 0,
                'message' => 'Order ID is required'
            ], 400);
        }

        $orderId = $request->order_id;

        try {
            // Get seller details using admin_id (like status-tracking API)
            $sellerDetails = DB::table('sellers')->where('admin_id', $adminUser->id)->first();

            if (!$sellerDetails) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            $sellerId = $sellerDetails->id;
            $sellerStoreId = $sellerDetails->store_id;
            // Get order details with related data
            $order = Order::select(
                'orders.*',
                'users.name as customer_name',
                'users.mobile as customer_mobile',
                'users.email as customer_email',
                'address.address as delivery_address',
                'address.landmark as delivery_landmark',
                'address.area as delivery_area',
                'address.city as delivery_city',
                'address.state as delivery_state',
                'address.pincode as delivery_pincode',
                'os.status as order_status_name'
            )
            ->leftJoin('users', 'orders.user_id', '=', 'users.id')
            ->leftJoin('user_addresses as address', 'orders.address_id', '=', 'address.id')
            ->leftJoin('order_status_lists as os', 'orders.active_status', '=', 'os.id')
            ->where('orders.id', $orderId)
            ->first();

            if (!$order) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Order not found'
                ], 404);
            }

            // Verify this seller has items in this order (check tracking)
            $tracking = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('seller_id', $sellerId)
                ->first();

            if (!$tracking) {
                return response()->json([
                    'status' => 0,
                    'message' => 'This seller has no items in this order'
                ], 403);
            }

            // Get full seller details
            $seller = DB::table('sellers')
                ->select(
                    'sellers.id',
                    'sellers.store_id',
                    'sellers.store_name',
                    'sellers.name as seller_name',
                    'sellers.mobile as seller_mobile',
                    'sellers.email as seller_email',
                    'sellers.street',
                    'sellers.formatted_address',
                    'sellers.place_name',
                    'sellers.store_location',
                    'sellers.pan_number'
                )
                ->where('sellers.id', $sellerId)
                ->first();

            // Build full address from available fields (filter out nulls)
            $storeAddressParts = array_filter([
                $seller->street,
                $seller->place_name,
                $seller->formatted_address,
                $seller->store_location
            ], function($value) {
                return !empty($value) && $value !== 'null' && trim($value) !== '';
            });

            $storeAddress = !empty($storeAddressParts) ? implode(', ', $storeAddressParts) : 'N/A';

            // Get app name from settings (key-value table)
            $appName = Setting::get_value('app_name');
            if (empty($appName) || trim($appName) === '') {
                $appName = 'N/A';
            }

            $storeDetails = [
                'store_name' => $seller->store_name ?? 'N/A',
                'seller_name' => $seller->seller_name ?? 'N/A',
                'seller_mobile' => $seller->seller_mobile ?? 'N/A',
                'seller_email' => $seller->seller_email ?? 'N/A',
                'address' => $storeAddress,
                'pan_number' => $seller->pan_number ?? 'N/A',
                'app_name' => $appName,
            ];

            // Get order items filtered by seller's store_id (like status-tracking API)
            $orderItems = DB::table('order_items')
                ->select(
                    'order_items.id',
                    'order_items.product_variant_id',
                    'order_items.quantity',
                    'order_items.price',
                    'order_items.discounted_price',
                    'order_items.sub_total',
                    'products.id as product_id',
                    'products.name as product_name',
                    'products.image as product_image',
                    'products.store_id',
                    'product_variants.measurement',
                    'units.name as unit_name',
                    'units.short_code as unit_short_code'
                )
                ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
                ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                ->where('order_items.order_id', $orderId)
                ->where('products.store_id', $sellerStoreId)  // Filter by seller's store
                ->get();

            // Get combo items and filter by seller's store_id (like status-tracking API)
            $comboItemsRaw = DB::table('order_combo_items')
                ->where('order_id', $orderId)
                ->get();

            // Process combo items - filter products by seller's store_id
            $comboProductsList = [];
            foreach ($comboItemsRaw as $combo) {
                if (!empty($combo->products)) {
                    $products = json_decode($combo->products, true);
                    if (is_string($products)) {
                        $products = json_decode($products, true);
                    }
                    if (is_array($products)) {
                        // Get product IDs from combo
                        $comboProductIds = array_column($products, 'product_id');

                        // Get products that belong to seller's store
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

                                $qty = $product['quantity'] ?? 1;
                                $price = $product['price'] ?? ($variantDetail->price ?? 0);
                                $discountedPrice = $product['discounted_price'] ?? ($variantDetail->discounted_price ?? 0);
                                $subTotal = ($discountedPrice > 0 ? $discountedPrice : $price) * $qty;

                                $comboProductsList[] = [
                                    'product_id' => $productId,
                                    'product_variant_id' => $variantId,
                                    'product_name' => $product['product_name'] ?? $productDetail->product_name,
                                    'variant_name' => $product['variant_name'] ?? null,
                                    'quantity' => $qty,
                                    'price' => $price,
                                    'discounted_price' => $discountedPrice,
                                    'sub_total' => $subTotal,
                                    'measurement' => $variantDetail->measurement ?? null,
                                    'unit_name' => $variantDetail->unit_name ?? null,
                                    'unit_short_code' => $variantDetail->unit_short_code ?? null,
                                    'tax_amount' => $product['tax_amount'] ?? 0,
                                    'tax_percentage' => $product['tax_percentage'] ?? 0,
                                ];
                            }
                        }
                    }
                }
            }

            // Combine all items for invoice
            $items = [];

            // Add regular order items
            foreach ($orderItems as $item) {
                $variantName = '';
                if ($item->measurement && $item->unit_short_code) {
                    $variantName = $item->measurement . ' ' . $item->unit_short_code;
                }

                $items[] = [
                    'product_name' => $item->product_name,
                    'variant_name' => $variantName,
                    'quantity' => $item->quantity,
                    'price' => (float) $item->price,
                    'discounted_price' => (float) $item->discounted_price,
                    'sub_total' => (float) $item->sub_total,
                    'item_type' => 'regular'
                ];
            }

            // Add combo items that belong to this seller
            foreach ($comboProductsList as $item) {
                $variantName = '';
                if (!empty($item['variant_name'])) {
                    $variantName = $item['variant_name'];
                } elseif ($item['measurement'] && $item['unit_short_code']) {
                    $variantName = $item['measurement'] . ' ' . $item['unit_short_code'];
                }

                $items[] = [
                    'product_name' => $item['product_name'],
                    'variant_name' => $variantName ?: 'Combo Item',
                    'quantity' => $item['quantity'],
                    'price' => (float) $item['price'],
                    'discounted_price' => (float) $item['discounted_price'],
                    'sub_total' => (float) $item['sub_total'],
                    'item_type' => 'combo'
                ];
            }

            // Calculate seller-specific totals (only for this seller's items)
            $sellerItemsTotal = 0;
            foreach ($items as $item) {
                $sellerItemsTotal += $item['sub_total'];
            }

            // Build customer address (filter out nulls and empty values)
            $addressParts = array_filter([
                $order->delivery_address,
                $order->delivery_landmark,
                $order->delivery_area,
                $order->delivery_city,
                $order->delivery_state ? $order->delivery_state . ' - ' . ($order->delivery_pincode ?? '') : $order->delivery_pincode
            ], function($value) {
                return !empty($value) && $value !== 'null' && trim($value) !== '';
            });

            // If no address from user_addresses table, fallback to orders.address field
            if (empty($addressParts)) {
                $customerAddress = !empty($order->address) && trim($order->address) !== '' ? $order->address : 'N/A';
            } else {
                $customerAddress = implode(', ', $addressParts);
            }

            // Build invoice response
            $invoiceData = [
                'status' => 1,
                'message' => 'Invoice retrieved successfully',
                'invoice' => [
                    // Store Details
                    'store' => $storeDetails,

                    // Order Details
                    'order_info' => [
                        'order_id' => $order->id,
                        'order_number' => $order->orders_id ?? 'N/A',
                        'order_date' => $order->created_at ?? 'N/A',
                        'order_type' => strtoupper($order->order_type ?? 'DOORSTEP'),
                        'order_status' => $order->order_status_name ?? 'N/A',
                        'payment_method' => strtoupper($order->payment_method ?? 'N/A'),
                    ],

                    // Customer Details
                    'customer' => [
                        'name' => $order->customer_name ?? 'N/A',
                        'mobile' => $order->customer_mobile ?? $order->mobile ?? 'N/A',
                        'email' => $order->customer_email ?? 'N/A',
                        'address' => $customerAddress,
                    ],

                    // Items
                    'items' => $items,

                    // Pricing (seller-specific only)
                    'pricing' => [
                        'items_total' => $sellerItemsTotal,
                    ],

                    // Additional Info
                    'notes' => [
                        'seller_note' => $this->getSellerNote($order, $sellerId, $sellerStoreId),
                    ],

                    // Footer message
                    'footer' => [
                        'message' => 'Thank you for your order!',
                        'tagline' => 'Visit again!'
                    ]
                ]
            ];

            return response()->json($invoiceData);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 0,
                'message' => 'Error retrieving invoice: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get seller note from cart_metadata.
     * Only returns note for non-admin-managed sellers.
     * Admin managed store sellers get N/A.
     */
    private function getSellerNote($order, $sellerId, $sellerStoreId)
    {
        Log::info('SellerInvoice Notes | START', [
            'order_id' => $order->id,
            'seller_id' => $sellerId,
            'seller_store_id' => $sellerStoreId,
        ]);

        // If seller's store is admin managed, skip notes entirely
        $isAdminManaged = DB::table('stores')
            ->where('id', $sellerStoreId)
            ->where('managed_by_admin', 1)
            ->exists();

        if ($isAdminManaged) {
            Log::info('SellerInvoice Notes | Skipped - store is admin managed', [
                'order_id' => $order->id,
                'seller_id' => $sellerId,
                'store_id' => $sellerStoreId,
            ]);
            return 'N/A';
        }

        $cartMetadata = $order->cart_metadata;
        if (is_string($cartMetadata)) {
            $cartMetadata = json_decode($cartMetadata, true);
        }

        $cartInfo = $cartMetadata['cart_info'] ?? null;
        if (!$cartInfo) {
            Log::info('SellerInvoice Notes | No cart_info found in cart_metadata', [
                'order_id' => $order->id,
            ]);
            return 'N/A';
        }

        $sellerNotesData = $cartInfo['seller_notes'] ?? [];

        Log::info('SellerInvoice Notes | cart_info parsed', [
            'order_id' => $order->id,
            'seller_notes_keys' => array_keys($sellerNotesData),
            'seller_notes_data' => $sellerNotesData,
        ]);

        $sellerIdStr = (string) $sellerId;
        if (isset($sellerNotesData[$sellerIdStr])) {
            Log::info('SellerInvoice Notes | Seller note found', [
                'order_id' => $order->id,
                'seller_id' => $sellerIdStr,
                'note' => $sellerNotesData[$sellerIdStr],
            ]);
            return $sellerNotesData[$sellerIdStr];
        }

        Log::info('SellerInvoice Notes | No seller note for this seller_id', [
            'order_id' => $order->id,
            'seller_id' => $sellerIdStr,
            'available_keys' => array_keys($sellerNotesData),
        ]);

        return 'N/A';
    }
}
