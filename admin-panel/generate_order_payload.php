<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$userId          = 8;
$deliveryCharge  = 30;
$addressId       = 2;   // change if needed

echo "=== Generating Order Payload for User ID: {$userId} ===\n\n";

// Read current cart for this user
$cartItems = DB::table('carts')
    ->join('product_variants', 'carts.product_variant_id', '=', 'product_variants.id')
    ->join('products', 'carts.product_id', '=', 'products.id')
    ->where('carts.user_id', $userId)
    ->select(
        'carts.product_variant_id',
        'carts.qty',
        'products.name',
        'products.store_id',
        DB::raw('COALESCE(NULLIF(product_variants.discounted_price, 0), product_variants.price) as effective_price'),
        'product_variants.price',
        'product_variants.discounted_price',
        'product_variants.measurement',
        'product_variants.type'
    )
    ->get();

if ($cartItems->isEmpty()) {
    echo "No cart items found for user {$userId}.\n";
    echo "Please run: php add_meat_to_cart.php   first.\n";
    exit(1);
}

echo "Cart Items:\n";
$variantIds = [];
$quantities = [];
$total      = 0;

foreach ($cartItems as $item) {
    $price = (float) $item->effective_price;
    $line  = $price * $item->qty;
    $total += $line;

    $variantIds[] = $item->product_variant_id;
    $quantities[] = $item->qty;

    echo "  - {$item->name} (Store {$item->store_id})"
       . " | Variant: {$item->product_variant_id}"
       . " | {$item->measurement} {$item->type}"
       . " | Price: ₹{$price}"
       . " | Qty: {$item->qty}"
       . " | Line total: ₹{$line}\n";
}

$finalTotal = $total + $deliveryCharge;

echo "\nSubtotal        : ₹{$total}\n";
echo "Delivery charge : ₹{$deliveryCharge}\n";
echo "Final total     : ₹{$finalTotal}\n\n";

// Build the payload
$payload = [
    "order_type"          => "doorstep",
    "payment_method"      => "COD",
    "product_variant_id"  => implode(',', $variantIds),
    "quantity"            => implode(',', $quantities),
    "total"               => $total,
    "delivery_charge"     => $deliveryCharge,
    "final_total"         => $finalTotal,
    "delivery_time"       => "10:00 AM - 12:00 PM",
    "address_id"          => $addressId,
    "order_note"          => "Test meat order - " . count($variantIds) . " items",
    "wallet_used"         => "false",
    "wallet_balance"      => 0,
];

echo "=== Postman Payload (copy this) ===\n\n";
echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
