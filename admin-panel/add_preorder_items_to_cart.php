<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

echo "=== Adding ALL Preorder Items to Cart for User ID: 8 ===\n\n";

$userId = 8;
$now = Carbon::now();

try {
    DB::beginTransaction();

    // Step 1: Find all products where is_pre_order_item = 1
    echo "Step 1: Finding all preorder products...\n";

    $preorderProducts = DB::table('products')
        ->where('is_pre_order_item', 1)
        ->select('id', 'name')
        ->get();

    if ($preorderProducts->isEmpty()) {
        echo "  - No preorder products found!\n";
        echo "  - Please mark products as preorder items first (set is_pre_order_item = 1)\n\n";
        DB::rollBack();
        exit(0);
    }

    echo "  - Found {$preorderProducts->count()} preorder products:\n";
    foreach ($preorderProducts as $p) {
        echo "    * Product ID: {$p->id} - {$p->name}\n";
    }
    echo "\n";

    // Step 2: Clear existing cart
    echo "Step 2: Clearing existing cart items for User {$userId}...\n";
    $deletedCart = DB::table('carts')->where('user_id', $userId)->delete();
    echo "  - Deleted {$deletedCart} items from cart\n";

    $comboCustomIds = DB::table('combo_custom_cart')
        ->where('user_id', $userId)
        ->pluck('id');

    $deletedComboProducts = 0;
    if ($comboCustomIds->count() > 0) {
        $deletedComboProducts = DB::table('combo_custom_products')
            ->whereIn('combo_custom_id', $comboCustomIds)
            ->delete();
    }
    echo "  - Deleted {$deletedComboProducts} combo products\n";

    $deletedComboCart = DB::table('combo_custom_cart')->where('user_id', $userId)->delete();
    echo "  - Deleted {$deletedComboCart} combo cart items\n\n";

    // Step 3: Get all active variants for preorder products
    echo "Step 3: Getting active variants for all preorder products...\n";

    $preorderProductIds = $preorderProducts->pluck('id')->toArray();

    $variants = DB::table('product_variants as pv')
        ->join('products as p', 'pv.product_id', '=', 'p.id')
        ->whereIn('p.id', $preorderProductIds)
        ->where('pv.status', 1)
        ->where('p.is_pre_order_item', 1)
        ->select('pv.id as variant_id', 'pv.product_id', 'p.name as product_name', 'pv.measurement', 'pv.type', 'pv.price')
        ->get();

    if ($variants->isEmpty()) {
        echo "  - WARNING: No active variants found for preorder products!\n";
        echo "  - Products without active variants will be skipped\n\n";
    } else {
        echo "  - Found {$variants->count()} active variants:\n";
        foreach ($variants as $v) {
            echo "    * Product: {$v->product_name} (ID: {$v->product_id}), Variant ID: {$v->variant_id}, {$v->measurement} {$v->type}, Price: ₹{$v->price}\n";
        }
        echo "\n";
    }

    // Step 4: Check and fix stock, then add variants to cart
    echo "Step 4: Checking stock and adding preorder items to cart...\n";

    if ($variants->isEmpty()) {
        echo "  - No variants to add (all preorder products are missing active variants)\n\n";
        DB::rollBack();
        exit(0);
    }

    foreach ($variants as $variant) {
        // Check current stock
        $currentStock = DB::table('product_variants')
            ->where('id', $variant->variant_id)
            ->value('stock');

        // If stock is insufficient (0 or negative), increment by 10
        if ($currentStock <= 0) {
            $newStock = $currentStock + 10;
            DB::table('product_variants')
                ->where('id', $variant->variant_id)
                ->update([
                    'stock' => $newStock,
                    'status' => 1  // Ensure variant is active
                ]);
            echo "  - Fixed stock for {$variant->product_name} (Variant: {$variant->variant_id}): {$currentStock} → {$newStock}\n";
        }

        // Add to cart
        $cartId = DB::table('carts')->insertGetId([
            'user_id' => $userId,
            'product_id' => $variant->product_id,
            'product_variant_id' => $variant->variant_id,
            'qty' => 1,
            'save_for_later' => 0,
            'created_at' => $now,
            'updated_at' => $now
        ]);

        echo "  - Added {$variant->product_name} (Variant: {$variant->variant_id}, Qty: 1) - Cart ID: {$cartId}\n";
    }
    echo "\n";

    DB::commit();

    // Step 5: Display summary
    echo "\n=== SUMMARY ===\n\n";

    echo "Cart Contents for User {$userId}:\n";
    $cartSummary = DB::table('carts as c')
        ->join('product_variants as pv', 'c.product_variant_id', '=', 'pv.id')
        ->join('products as p', 'c.product_id', '=', 'p.id')
        ->where('c.user_id', $userId)
        ->select('p.name', 'p.is_pre_order_item', 'pv.measurement', 'pv.type', 'pv.price', 'c.qty')
        ->get();

    foreach ($cartSummary as $item) {
        $preorderLabel = $item->is_pre_order_item == 1 ? '[PREORDER]' : '[REGULAR]';
        $variantInfo = $item->measurement . ' ' . $item->type;
        echo "  {$preorderLabel} {$item->name} ({$variantInfo}) - Qty: {$item->qty}, Price: ₹{$item->price}\n";
    }

    $totalItems = $cartSummary->count();
    $preorderCount = $cartSummary->where('is_pre_order_item', 1)->count();

    echo "\n";
    echo "Total items: {$totalItems}\n";
    echo "Preorder items: {$preorderCount}\n";
    echo "Regular items: " . ($totalItems - $preorderCount) . "\n";

    echo "\n=== Preorder cart successfully populated for User ID: {$userId} ===\n";

    // Generate Postman payload
    echo "\n=================================================\n";
    echo "POSTMAN PAYLOAD FOR PLACE ORDER API\n";
    echo "=================================================\n\n";

    $variantIds = [];
    $quantities = [];
    $itemTotal = 0;

    foreach ($cartSummary as $item) {
        // Get variant_id from cart
        $cart = DB::table('carts')
            ->join('products', 'carts.product_id', '=', 'products.id')
            ->where('carts.user_id', $userId)
            ->where('products.name', $item->name)
            ->select('carts.product_variant_id', 'carts.qty')
            ->first();

        if ($cart) {
            $variantIds[] = $cart->product_variant_id;
            $quantities[] = $cart->qty;
            $itemTotal += $item->price * $cart->qty;
        }
    }

    $deliveryCharge = 30;
    $finalTotal = $itemTotal + $deliveryCharge;

    $payload = [
        "order_type" => "doorstep",
        "payment_method" => "COD",
        "product_variant_id" => implode(',', $variantIds),
        "quantity" => implode(',', $quantities),
        "total" => $itemTotal,
        "delivery_charge" => $deliveryCharge,
        "final_total" => $finalTotal,
        "delivery_time" => "10:00 AM - 12:00 PM",
        "address_id" => 2,
        "order_note" => "Test preorder - " . $preorderCount . " preorder items",
        "wallet_used" => "false",
        "wallet_balance" => 0
    ];

    echo json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";

    echo "\n=================================================\n";
    echo "NOTE: is_preorder field is NOT needed - backend auto-detects!\n";
    echo "=================================================\n\n";

    echo "API Endpoint: POST {{dev_url}}/api/customer/place-order\n";
    echo "Headers:\n";
    echo "  - Authorization: Bearer <customer_token>\n";
    echo "  - Content-Type: application/json\n\n";

} catch (Exception $e) {
    DB::rollBack();
    echo "\nERROR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}

?>
