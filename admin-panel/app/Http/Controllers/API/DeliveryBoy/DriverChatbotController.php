<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class DriverChatbotController extends Controller
{
    /**
     * Available chatbot questions a driver can ask about an order.
     */
    public function getQuestions(Request $request)
    {
        $questions = [
            ['key' => 'my_earning',        'question' => 'How much will I earn from this order?'],
            ['key' => 'customer_details',  'question' => 'Who is the customer and how do I contact them?'],
            ['key' => 'delivery_address',  'question' => 'What is the delivery address?'],
            ['key' => 'order_items',       'question' => 'What items are in this order?'],
            ['key' => 'order_total',       'question' => 'What is the total amount to collect?'],
            ['key' => 'payment_method',    'question' => 'How is the customer paying?'],
            ['key' => 'seller_details',    'question' => 'Where do I pick up this order from?'],
            ['key' => 'other',             'question' => 'Need to talk with Support Team?'],
        ];

        return response()->json([
            'status'  => true,
            'message' => 'Chatbot questions fetched successfully.',
            'data'    => $questions,
        ]);
    }

    /**
     * Answer a specific question about an order for the authenticated driver.
     *
     * Request params:
     *   - order_id  (required) : the order's primary key
     *   - question  (required) : one of the question keys listed above
     */
    public function getAnswer(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer|exists:orders,id',
            'question' => 'required|string|in:customer_details,delivery_address,order_items,order_total,payment_method,seller_details,my_earning',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        $authUser = auth()->guard('api')->user();

        if (!$authUser) {
            return response()->json(['status' => false, 'message' => 'Unauthorized.'], 401);
        }

        $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();

        if (!$deliveryBoy) {
            return response()->json(['status' => false, 'message' => 'Driver profile not found.'], 404);
        }

        // Verify this order is assigned to this driver
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
            ->where('orders.delivery_boy_id', $deliveryBoy->id)
            ->first();

        if (!$order) {
            return response()->json([
                'status'  => false,
                'message' => 'This order is not assigned to you.',
            ], 403);
        }

        $answer = $this->resolveAnswer($request->question, $order);

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

    private function resolveAnswer(string $key, $order): array
    {
        switch ($key) {
            case 'customer_details':
                return $this->answerCustomerDetails($order);
            case 'delivery_address':
                return $this->answerDeliveryAddress($order);
            case 'order_items':
                return $this->answerOrderItems($order);
            case 'order_total':
                return $this->answerOrderTotal($order);
            case 'payment_method':
                return $this->answerPaymentMethod($order);
            case 'seller_details':
                return $this->answerSellerDetails($order);
            case 'my_earning':
                return $this->answerMyEarning($order);
            default:
                return ['text' => 'Sorry, I could not understand that question.'];
        }
    }

    private function answerCustomerDetails($order): array
    {
        $name   = $order->customer_name   ?? 'N/A';
        $mobile = $order->customer_mobile ?? 'N/A';

        return [
            'text'    => "Customer: {$name}, Mobile: {$mobile}.",
            'details' => [
                ['label' => 'Name',   'value' => $name],
                ['label' => 'Mobile', 'value' => $mobile],
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
            'text'    => "Deliver to: {$address}",
            'details' => [
                ['label' => 'Delivery Address', 'value' => $address],
            ],
        ];
    }

    private function answerOrderItems($order): array
    {
        $details = [];

        // Regular order items
        $orderItems = DB::table('order_items')
            ->select(
                'products.name as product_name',
                'order_items.quantity',
                'order_items.sub_total',
                'product_variants.measurement',
                'units.short_code as unit_short_code',
                'stores.name as store_name'
            )
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
            ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
            ->where('order_items.order_id', $order->id)
            ->get();

        foreach ($orderItems as $item) {
            $variant = ($item->measurement && $item->unit_short_code)
                ? ' (' . $item->measurement . ' ' . $item->unit_short_code . ')'
                : '';
            $store = $item->store_name ? ' [' . $item->store_name . ']' : '';

            $details[] = [
                'label' => ($item->product_name ?? 'Unknown') . $variant . $store . ' × ' . $item->quantity,
                'value' => '₹' . number_format($item->sub_total, 2),
            ];
        }

        // Combo order items
        $comboItems = DB::table('order_combo_items')
            ->where('order_id', $order->id)
            ->get();

        foreach ($comboItems as $combo) {
            if (empty($combo->products)) continue;

            $products = json_decode($combo->products, true);
            if (is_string($products)) {
                $products = json_decode($products, true);
            }
            if (!is_array($products)) continue;

            foreach ($products as $product) {
                $productId = $product['product_id'] ?? null;
                if (!$productId) continue;

                $variantId   = $product['product_variant_id'] ?? ($product['variant_id'] ?? null);
                $productName = $product['product_name'] ?? 'Unknown';
                $qty         = $product['quantity'] ?? 1;
                $discounted  = (float) ($product['discounted_price'] ?? 0);
                $price       = (float) ($product['price'] ?? 0);
                $subTotal    = ($discounted > 0 ? $discounted : $price) * $qty;

                $variantDetail = null;
                if ($variantId) {
                    $variantDetail = DB::table('product_variants')
                        ->select('product_variants.measurement', 'units.short_code as unit_short_code')
                        ->leftJoin('units', 'product_variants.stock_unit_id', '=', 'units.id')
                        ->where('product_variants.id', $variantId)
                        ->first();
                }

                $measurement = $variantDetail->measurement ?? ($product['variant_measurement'] ?? null);
                $unitCode    = $variantDetail->unit_short_code ?? null;
                $variant     = ($measurement && $unitCode) ? ' (' . $measurement . ' ' . $unitCode . ')' : '';

                $details[] = [
                    'label' => $productName . $variant . ' × ' . $qty,
                    'value' => '₹' . number_format($subTotal, 2),
                ];
            }
        }

        if (empty($details)) {
            return ['text' => 'No item details found for this order.', 'details' => []];
        }

        return [
            'text'    => "Order #{$order->id} has " . count($details) . " item(s).",
            'details' => $details,
        ];
    }

    private function answerOrderTotal($order): array
    {
        $meta    = is_string($order->cart_metadata)
            ? json_decode($order->cart_metadata, true)
            : (array) $order->cart_metadata;

        $summary  = $meta['billing_summary'] ?? [];
        $currency = $summary['currency'] ?? '₹';

        $itemsSubtotal    = (float) ($summary['items_subtotal']      ?? $summary['items_total'] ?? 0);
        $discount         = (float) ($summary['discount']            ?? 0);
        $combosTotal      = (float) ($summary['combos_total']        ?? $summary['combo_total'] ?? 0);
        $deliveryCharge   = (float) ($summary['delivery_charge']     ?? 0);
        $multiOrderCharge = (float) ($summary['multi_order_charges'] ?? 0);
        $rainSurcharge    = (float) ($summary['rain_surcharge']      ?? 0);
        $tip              = (float) ($summary['delivery_tip']        ?? 0);
        $toBePaid         = (float) ($summary['to_be_paid']          ?? $order->final_total ?? 0);

        $paymentMethod = strtoupper($order->payment_method ?? 'N/A');

        $details = [];

        if ($itemsSubtotal > 0) {
            $details[] = ['label' => 'Items Subtotal',     'value' => $currency . number_format($itemsSubtotal, 2)];
        }
        if ($combosTotal > 0) {
            $details[] = ['label' => 'Combos',             'value' => $currency . number_format($combosTotal, 2)];
        }
        if ($discount > 0) {
            $details[] = ['label' => 'Discount',           'value' => '- ' . $currency . number_format($discount, 2)];
        }
        if ($deliveryCharge > 0) {
            $details[] = ['label' => 'Delivery Charge',    'value' => $currency . number_format($deliveryCharge, 2)];
        }
        if ($multiOrderCharge > 0) {
            $details[] = ['label' => 'Multi Order Charge', 'value' => $currency . number_format($multiOrderCharge, 2)];
        }
        if ($rainSurcharge > 0) {
            $details[] = ['label' => 'Rain Surcharge',     'value' => $currency . number_format($rainSurcharge, 2)];
        }
        if ($tip > 0) {
            $details[] = ['label' => 'Delivery Tip',       'value' => $currency . number_format($tip, 2)];
        }

        $details[] = [
            'label'    => 'Total to Collect',
            'value'    => $currency . number_format($toBePaid, 2),
            'is_total' => true,
        ];
        $details[] = ['label' => 'Payment Method', 'value' => $paymentMethod];

        $collectText = ($paymentMethod === 'COD')
            ? "Collect {$currency}" . number_format($toBePaid, 2) . " cash from the customer."
            : "Payment already done online. No cash to collect.";

        return [
            'text'    => "Order #{$order->id} total is {$currency}" . number_format($toBePaid, 2) . ". {$collectText}",
            'details' => $details,
        ];
    }

    private function answerPaymentMethod($order): array
    {
        $method     = strtoupper($order->payment_method ?? 'N/A');
        $finalTotal = (float) ($order->final_total ?? 0);
        $isCod      = $method === 'COD';

        $text = $isCod
            ? "Payment method is COD. Please collect ₹" . number_format($finalTotal, 2) . " from the customer."
            : "Payment method is {$method}. The customer has already paid online.";

        return [
            'text'    => $text,
            'details' => [
                ['label' => 'Payment Method', 'value' => $method],
                ['label' => 'Amount',         'value' => '₹' . number_format($finalTotal, 2)],
                ['label' => 'Collect Cash',   'value' => $isCod ? 'Yes' : 'No'],
            ],
        ];
    }

    private function answerMyEarning($order): array
    {
        $meta = is_string($order->cart_metadata)
            ? json_decode($order->cart_metadata, true)
            : (array) $order->cart_metadata;

        $summary = $meta['billing_summary'] ?? [];

        $deliveryCharge   = (float) ($summary['delivery_charge']    ?? 0);
        $tip              = (float) ($summary['delivery_tip']        ?? 0);
        $multiOrderCharge = (float) ($summary['multi_order_charges'] ?? 0);
        $rainSurcharge    = (float) ($summary['rain_surcharge']      ?? 0);
        $totalEarning     = $deliveryCharge + $tip + $multiOrderCharge + $rainSurcharge;
        $currency         = $summary['currency'] ?? '₹';

        $details = [
            ['label' => 'Delivery Charge', 'value' => $currency . number_format($deliveryCharge, 2)],
        ];

        if ($tip > 0) {
            $details[] = ['label' => 'Tip from Customer', 'value' => $currency . number_format($tip, 2)];
        }

        if ($multiOrderCharge > 0) {
            $details[] = ['label' => 'Multi Order Charges', 'value' => $currency . number_format($multiOrderCharge, 2)];
        }

        if ($rainSurcharge > 0) {
            $details[] = ['label' => 'Rain Surcharge', 'value' => $currency . number_format($rainSurcharge, 2)];
        }

        $details[] = [
            'label'    => 'Your Total Earning',
            'value'    => $currency . number_format($totalEarning, 2),
            'is_total' => true,
        ];

        $extras = [];
        if ($tip > 0)              $extras[] = "{$currency}" . number_format($tip, 2) . " tip";
        if ($multiOrderCharge > 0) $extras[] = "{$currency}" . number_format($multiOrderCharge, 2) . " multi-order charge";
        if ($rainSurcharge > 0)    $extras[] = "{$currency}" . number_format($rainSurcharge, 2) . " rain surcharge";

        $extrasText = $extras ? " plus " . implode(', ', $extras) : '';
        $text       = "You will earn {$currency}" . number_format($deliveryCharge, 2)
                    . " delivery charge{$extrasText} for order #{$order->id}."
                    . " Total: {$currency}" . number_format($totalEarning, 2) . ".";

        return [
            'text'    => $text,
            'details' => $details,
        ];
    }

    private function answerSellerDetails($order): array
    {
        $pickupLocations = [];

        // ── 1. Regular sellers from order_seller_status_tracking ──────────────
        $trackingRows = DB::table('order_seller_status_tracking')
            ->select(
                'order_seller_status_tracking.seller_id',
                'order_seller_status_tracking.status as tracking_status',
                'sellers.store_name',
                'sellers.mobile as seller_mobile',
                'sellers.store_location',
                'sellers.lat_long'
            )
            ->leftJoin('sellers', 'order_seller_status_tracking.seller_id', '=', 'sellers.id')
            ->where('order_seller_status_tracking.order_id', $order->id)
            ->whereNotNull('order_seller_status_tracking.seller_id')
            ->get();

        foreach ($trackingRows as $row) {
            $pickupLocations[] = [
                'store_name'      => $row->store_name ?? 'N/A',
                'mobile'          => $row->seller_mobile ?? 'N/A',
                'address'         => !empty($row->store_location) && $row->store_location !== 'null'
                                        ? $row->store_location : 'N/A',
                'tracking_status' => ucwords(str_replace('_', ' ', $row->tracking_status ?? 'pending')),
                'is_zenfoo_store' => false,
            ];
        }

        // ── 2. Zenfoo store (store_id=12) — same logic as getSellerLocationsByOrderId ─
        $zenfooStoreId = 12;
        $hasZenfoo     = DB::table('order_items')
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->where('order_items.order_id', $order->id)
            ->where('products.store_id', $zenfooStoreId)
            ->exists();

        if (!$hasZenfoo) {
            $comboRows = DB::table('order_combo_items')->where('order_id', $order->id)->get();
            foreach ($comboRows as $combo) {
                if (empty($combo->products)) continue;
                $products = json_decode($combo->products, true);
                if (is_string($products)) $products = json_decode($products, true);
                if (!is_array($products)) continue;
                $comboProductIds = array_column($products, 'product_id');
                if (DB::table('products')->whereIn('id', $comboProductIds)->where('store_id', $zenfooStoreId)->exists()) {
                    $hasZenfoo = true;
                    break;
                }
            }
        }

        if ($hasZenfoo) {
            $orderWithCity = DB::table('orders')
                ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('orders.id', $order->id)
                ->select('user_addresses.city_id')
                ->first();

            if ($orderWithCity && $orderWithCity->city_id) {
                $zenfooLocation = DB::table('store_locations')
                    ->where('city_id', $orderWithCity->city_id)
                    ->where('status', 1)
                    ->first();

                if ($zenfooLocation) {
                    $pickupLocations[] = [
                        'store_name'      => $zenfooLocation->name,
                        'mobile'          => 'N/A',
                        'address'         => $zenfooLocation->address ?? 'N/A',
                        'tracking_status' => 'Zenfoo Store',
                        'is_zenfoo_store' => true,
                    ];
                }
            }
        }

        if (empty($pickupLocations)) {
            return ['text' => 'No seller information found for this order.', 'details' => []];
        }

        $details    = [];
        $storeNames = [];

        foreach ($pickupLocations as $loc) {
            $storeNames[] = $loc['store_name'];

            $details[] = ['label' => 'Store',        'value' => $loc['store_name']];
            $details[] = ['label' => 'Contact',      'value' => $loc['mobile']];
            $details[] = ['label' => 'Address',      'value' => $loc['address']];
            $details[] = ['label' => 'Store Status', 'value' => $loc['tracking_status']];
        }

        return [
            'text'    => "Pick up from: " . implode(', ', $storeNames) . ".",
            'details' => $details,
        ];
    }
}
