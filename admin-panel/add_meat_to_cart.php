<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

$userId  = 8;
$storeIds = [14, 18, 19];
$now     = Carbon::now();

echo "=== Adding Meat/Fish Products to Cart for User ID: {$userId} ===\n\n";

try {
    DB::beginTransaction();

    // Step 1: Clear existing cart items for this user
    echo "Step 1: Clearing existing cart items for user {$userId}...\n";
    $deleted = DB::table('carts')->where('user_id', $userId)->delete();
    echo "Deleted {$deleted} existing cart row(s).\n\n";

    // Step 2: Fetch all products from stores 14, 18, 19
    echo "Step 2: Fetching products from stores " . implode(', ', $storeIds) . "...\n";

    $products = DB::table('products')
        ->whereIn('store_id', $storeIds)
        ->whereNull('deleted_at')
        ->where('status', 1)
        ->select('id', 'name', 'store_id')
        ->get();

    if ($products->isEmpty()) {
        echo "No products found for those stores. Exiting.\n";
        DB::rollBack();
        exit(1);
    }

    echo "Found {$products->count()} product(s):\n";
    foreach ($products as $p) {
        echo "  - Product ID {$p->id}: {$p->name} (store_id={$p->store_id})\n";
    }
    echo "\n";

    // Step 3: For each product, pick the first active variant and add to cart
    echo "Step 3: Adding products to cart...\n";

    $added   = 0;
    $skipped = 0;

    foreach ($products as $product) {
        // Pick the first available variant (status=1 preferred, fallback to any)
        $variant = DB::table('product_variants')
            ->where('product_id', $product->id)
            ->where('status', 1)
            ->orderBy('id')
            ->first();

        if (!$variant) {
            // Fallback: any variant for this product
            $variant = DB::table('product_variants')
                ->where('product_id', $product->id)
                ->orderBy('id')
                ->first();
        }

        if (!$variant) {
            echo "  - SKIPPED {$product->name} (no variant found)\n";
            $skipped++;
            continue;
        }

        $cartId = DB::table('carts')->insertGetId([
            'user_id'            => $userId,
            'product_id'         => $product->id,
            'product_variant_id' => $variant->id,
            'qty'                => 1,
            'created_at'         => $now,
            'updated_at'         => $now,
        ]);

        echo "  - Added \"{$product->name}\" | Product ID: {$product->id} | Variant ID: {$variant->id} | Store: {$product->store_id} | Cart ID: {$cartId}\n";
        $added++;
    }

    echo "\n";

    DB::commit();

    // Step 4: Summary
    echo "=== SUMMARY ===\n";
    echo "Products added   : {$added}\n";
    echo "Products skipped : {$skipped}\n\n";

    echo "Current cart for user {$userId}:\n";
    $cartRows = DB::table('carts')
        ->join('products', 'carts.product_id', '=', 'products.id')
        ->join('product_variants', 'carts.product_variant_id', '=', 'product_variants.id')
        ->where('carts.user_id', $userId)
        ->select(
            'products.name',
            'products.store_id',
            'product_variants.id as variant_id',
            'product_variants.measurement',
            'carts.qty',
            'carts.id as cart_id'
        )
        ->get();

    foreach ($cartRows as $row) {
        echo "  [Cart #{$row->cart_id}] {$row->name} | Variant: {$row->variant_id} | Measurement: {$row->measurement} | Qty: {$row->qty} | Store: {$row->store_id}\n";
    }

    echo "\n=== Done. Cart populated for User ID: {$userId} ===\n";

    // Step 5: Generate Postman payload
    $deliveryCharge = 30;
    $addressId      = 2;

    $payloadRows = DB::table('carts')
        ->join('product_variants', 'carts.product_variant_id', '=', 'product_variants.id')
        ->join('products', 'carts.product_id', '=', 'products.id')
        ->where('carts.user_id', $userId)
        ->select(
            'carts.product_variant_id',
            'carts.qty',
            DB::raw('COALESCE(NULLIF(product_variants.discounted_price, 0), product_variants.price) as effective_price')
        )
        ->get();

    $variantIds = [];
    $quantities = [];
    $total      = 0;

    foreach ($payloadRows as $row) {
        $variantIds[] = $row->product_variant_id;
        $quantities[] = $row->qty;
        $total       += (float) $row->effective_price * $row->qty;
    }

    $finalTotal = $total + $deliveryCharge;

    $payload = [
        "order_type"         => "doorstep",
        "payment_method"     => "COD",
        "product_variant_id" => implode(',', $variantIds),
        "quantity"           => implode(',', $quantities),
        "total"              => $total,
        "delivery_charge"    => $deliveryCharge,
        "final_total"        => $finalTotal,
        "delivery_time"      => "10:00 AM - 12:00 PM",
        "address_id"         => $addressId,
        "order_note"         => "Test meat order - " . count($variantIds) . " items",
        "wallet_used"        => "false",
        "wallet_balance"     => 0,
    ];

    echo "\n=== Postman Payload ===\n\n";
    echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";

} catch (Exception $e) {
    DB::rollBack();
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}
