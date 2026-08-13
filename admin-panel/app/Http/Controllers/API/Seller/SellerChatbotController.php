<?php

namespace App\Http\Controllers\API\Seller;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderStatusList;
use App\Models\DeliveryBoy;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class SellerChatbotController extends Controller
{
    /**
     * Available chatbot questions a seller can ask about an order.
     */
    public function getQuestions(Request $request)
    {
        $questions = [
            // ['key' => 'order_status',      'question' => 'What is the current status of this order?'],
            ['key' => 'order_items',        'question' => 'What items from my store are in this order?'],
            ['key' => 'order_total',        'question' => 'What is my items total for this order?'],
            ['key' => 'customer_details',   'question' => 'Who is the customer for this order?'],
            // ['key' => 'delivery_address',   'question' => 'What is the delivery address?'],
            ['key' => 'driver_details',     'question' => 'Who is the delivery driver?'],
            ['key' => 'other',     'question' => 'Need to talk with Support Team?'],
        ];

        return response()->json([
            'status'  => true,
            'message' => 'Chatbot questions fetched successfully.',
            'data'    => $questions,
        ]);
    }

    /**
     * Answer a specific question about an order for the authenticated seller.
     *
     * Request params:
     *   - order_id  (required) : the order's primary key
     *   - question  (required) : one of the question keys listed above
     */
    public function getAnswer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer|exists:orders,id',
            'question' => 'required|string|in:order_status,order_items,order_total,customer_details,delivery_address,driver_details',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $adminUser = auth()->guard('api')->user();

        if (!$adminUser) {
            return response()->json(['status' => false, 'message' => 'Unauthorized.'], 401);
        }

        $sellerDetails = DB::table('sellers')->where('admin_id', $adminUser->id)->first();

        if (!$sellerDetails) {
            return response()->json(['status' => false, 'message' => 'Seller profile not found.'], 404);
        }

        $sellerId      = $sellerDetails->id;
        $sellerStoreId = $sellerDetails->store_id;

        // Verify seller has items in this order via tracking table
        $tracking = DB::table('order_seller_status_tracking')
            ->where('order_id', $request->order_id)
            ->where('seller_id', $sellerId)
            ->first();

        if (!$tracking) {
            return response()->json([
                'status'  => false,
                'message' => 'This order does not belong to your store.',
            ], 403);
        }

        $order = Order::select(
                'orders.*',
                'users.name as customer_name',
                'users.mobile as customer_mobile',
                'users.email as customer_email',
                'address.address as delivery_address_text',
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
            ->where('orders.id', $request->order_id)
            ->first();

        if (!$order) {
            return response()->json(['status' => false, 'message' => 'Order not found.'], 404);
        }

        $answer = $this->resolveAnswer($request->question, $order, $sellerStoreId, $tracking);

        return response()->json([
            'status'   => true,
            'order_id' => $order->id,
            'question' => $request->question,
            'answer'   => $answer,
        ]);
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private function resolveAnswer(string $key, $order, int $sellerStoreId, $tracking): array
    {
        switch ($key) {
            case 'order_status':
                return $this->answerOrderStatus($order, $tracking);
            case 'order_items':
                return $this->answerOrderItems($order, $sellerStoreId);
            case 'order_total':
                return $this->answerOrderTotal($order, $sellerStoreId);
            case 'customer_details':
                return $this->answerCustomerDetails($order);
            case 'delivery_address':
                return $this->answerDeliveryAddress($order);
            case 'driver_details':
                return $this->answerDriverDetails($order);
            default:
                return ['text' => 'Sorry, I could not understand that question.'];
        }
    }

    private function answerOrderStatus($order, $tracking): array
    {
        $orderStatus   = $order->order_status_name ?? 'Unknown';
        $sellerStatus  = ucwords(str_replace('_', ' ', $tracking->status ?? 'pending'));

        return [
            'text' => "Order #{$order->id} is currently: {$orderStatus}. Your store status: {$sellerStatus}.",
            'details' => [
                ['label' => 'Order ID',      'value' => (string) $order->id],
                ['label' => 'Order Status',  'value' => $orderStatus],
                ['label' => 'Store Status',  'value' => $sellerStatus],
            ],
        ];
    }

    private function answerOrderItems($order, int $sellerStoreId): array
    {
        $items = $this->getSellerItems($order->id, $sellerStoreId);

        if (empty($items)) {
            return ['text' => 'No items from your store were found in this order.', 'details' => []];
        }

        $details = [];
        foreach ($items as $item) {
            $details[] = [
                'label' => $item['product_name'] . ($item['variant_name'] ? ' (' . $item['variant_name'] . ')' : '') . ' × ' . $item['quantity'],
                'value' => '₹' . number_format($item['sub_total'], 2),
            ];
        }

        return [
            'text'    => "Your store has " . count($items) . " item(s) in order #{$order->id}.",
            'details' => $details,
        ];
    }

    private function answerOrderTotal($order, int $sellerStoreId): array
    {
        $items = $this->getSellerItems($order->id, $sellerStoreId);

        if (empty($items)) {
            return ['text' => 'No items from your store were found in this order.', 'details' => []];
        }

        $itemsTotal = array_sum(array_column($items, 'sub_total'));
        $taxTotal   = 0;
        foreach ($items as $item) {
            $taxTotal += ($item['tax_amount'] ?? 0) * $item['quantity'];
        }

        $details = [];
        foreach ($items as $item) {
            $details[] = [
                'label' => $item['product_name'] . ' × ' . $item['quantity'],
                'value' => '₹' . number_format($item['sub_total'], 2),
            ];
        }
        if ($taxTotal > 0) {
            $details[] = ['label' => 'Tax',   'value' => '₹' . number_format($taxTotal, 2)];
        }
        $details[] = [
            'label'    => 'Your Items Total',
            'value'    => '₹' . number_format($itemsTotal, 2),
            'is_total' => true,
        ];

        return [
            'text'    => "Your store's items total for order #{$order->id} is ₹" . number_format($itemsTotal, 2) . ".",
            'details' => $details,
        ];
    }

    private function answerCustomerDetails($order): array
    {
        $name   = $order->customer_name   ?? 'N/A';
        $mobile = $order->customer_mobile ?? 'N/A';
        $email  = $order->customer_email  ?? 'N/A';

        return [
            'text'    => "The order is placed by {$name} ({$mobile}).",
            'details' => [
                ['label' => 'Name',   'value' => $name],
                ['label' => 'Mobile', 'value' => $mobile],
                ['label' => 'Email',  'value' => $email],
            ],
        ];
    }

    private function answerDeliveryAddress($order): array
    {
        $parts = array_filter([
            $order->delivery_address_text,
            $order->delivery_landmark,
            $order->delivery_area,
            $order->delivery_city,
            $order->delivery_state
                ? $order->delivery_state . ' - ' . ($order->delivery_pincode ?? '')
                : $order->delivery_pincode,
        ], fn($v) => !empty($v) && $v !== 'null');

        $address = $parts ? implode(', ', $parts) : 'N/A';

        return [
            'text'    => "Delivery address: {$address}",
            'details' => [
                ['label' => 'Delivery Address', 'value' => $address],
            ],
        ];
    }

    private function answerDriverDetails($order): array
    {
        if (empty($order->delivery_boy_id)) {
            return ['text' => 'No driver has been assigned to this order yet.', 'details' => []];
        }

        $driver = DeliveryBoy::select('name', 'mobile')->find($order->delivery_boy_id);

        if (!$driver) {
            return ['text' => 'Driver information could not be found.', 'details' => []];
        }

        return [
            'text'    => "Delivery driver: {$driver->name}, mobile: {$driver->mobile}.",
            'details' => [
                ['label' => 'Driver Name',   'value' => $driver->name],
                ['label' => 'Driver Mobile', 'value' => $driver->mobile],
            ],
        ];
    }

    /**
     * Fetch regular + combo items from this order that belong to the seller's store.
     */
    private function getSellerItems(int $orderId, int $sellerStoreId): array
    {
        // Regular order items
        $orderItems = DB::table('order_items')
            ->select(
                'products.name as product_name',
                'order_items.quantity',
                'order_items.price',
                'order_items.discounted_price',
                'order_items.tax_amount',
                'order_items.tax_percentage',
                'order_items.sub_total',
                'product_variants.measurement',
                'units.short_code as unit_short_code'
            )
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
            ->where('order_items.order_id', $orderId)
            ->where('products.store_id', $sellerStoreId)
            ->get();

        $items = [];

        foreach ($orderItems as $item) {
            $variantName = ($item->measurement && $item->unit_short_code)
                ? $item->measurement . ' ' . $item->unit_short_code
                : '';

            $items[] = [
                'product_name'     => $item->product_name,
                'variant_name'     => $variantName,
                'quantity'         => $item->quantity,
                'price'            => (float) $item->price,
                'discounted_price' => (float) $item->discounted_price,
                'tax_amount'       => (float) $item->tax_amount,
                'tax_percentage'   => (float) $item->tax_percentage,
                'sub_total'        => (float) $item->sub_total,
                'item_type'        => 'regular',
            ];
        }

        // Combo items filtered by seller's store
        $comboItemsRaw = DB::table('order_combo_items')->where('order_id', $orderId)->get();

        foreach ($comboItemsRaw as $combo) {
            if (empty($combo->products)) continue;

            $products = json_decode($combo->products, true);
            if (is_string($products)) {
                $products = json_decode($products, true);
            }
            if (!is_array($products)) continue;

            $comboProductIds = array_column($products, 'product_id');

            $matchingProducts = DB::table('products')
                ->whereIn('id', $comboProductIds)
                ->where('store_id', $sellerStoreId)
                ->pluck('name', 'id');

            foreach ($products as $product) {
                $productId = $product['product_id'] ?? null;
                if (!$productId || !isset($matchingProducts[$productId])) continue;

                $qty             = $product['quantity'] ?? 1;
                $discountedPrice = (float) ($product['discounted_price'] ?? $product['price'] ?? 0);
                $price           = (float) ($product['price'] ?? 0);
                $subTotal        = ($discountedPrice > 0 ? $discountedPrice : $price) * $qty;

                $items[] = [
                    'product_name'     => $product['product_name'] ?? $matchingProducts[$productId],
                    'variant_name'     => $product['variant_name'] ?? 'Combo Item',
                    'quantity'         => $qty,
                    'price'            => $price,
                    'discounted_price' => $discountedPrice,
                    'tax_amount'       => (float) ($product['tax_amount'] ?? 0),
                    'tax_percentage'   => (float) ($product['tax_percentage'] ?? 0),
                    'sub_total'        => $subTotal,
                    'item_type'        => 'combo',
                ];
            }
        }

        return $items;
    }
}
