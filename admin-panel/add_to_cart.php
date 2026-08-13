<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

echo "=== Adding Items to Cart for User ID: 8 ===\n\n";

$userId = 8;
$now = Carbon::now();

try {
    DB::beginTransaction();
    
    echo "Step 1: Clearing existing cart items...\n";
    $deletedCart = DB::table('carts')->where('user_id', $userId)->delete();
    echo "Deleted {$deletedCart} items from carts\n";
    
    $comboCustomIds = DB::table('combo_custom_cart')
        ->where('user_id', $userId)
        ->pluck('id');
    
    $deletedComboProducts = 0;
    if ($comboCustomIds->count() > 0) {
        $deletedComboProducts = DB::table('combo_custom_products')
            ->whereIn('combo_custom_id', $comboCustomIds)
            ->delete();
    }
    echo "Deleted {$deletedComboProducts} items from combo_custom_products\n";
    
    $deletedComboCart = DB::table('combo_custom_cart')->where('user_id', $userId)->delete();
    echo "Deleted {$deletedComboCart} items from combo_custom_cart\n\n";
    
    echo "Step 2: Getting product IDs for variants...\n";
    
    $variantData = [
        ['variant_id' => 5, 'qty' => 1, 'store' => 12, 'name' => 'Potatos'],
        ['variant_id' => 18, 'qty' => 1, 'store' => 13, 'name' => 'Product Details'],
        ['variant_id' => 102, 'qty' => 1, 'store' => 14, 'name' => 'Whole Chicken']
    ];
    
    $cartItems = [];
    
    foreach ($variantData as $item) {
        $variant = DB::table('product_variants')
            ->where('id', $item['variant_id'])
            ->first();
        
        if ($variant) {
            $cartItems[] = [
                'product_id' => $variant->product_id,
                'variant_id' => $item['variant_id'],
                'qty' => $item['qty'],
                'store' => $item['store'],
                'name' => $item['name']
            ];
            echo "  - Variant ID {$item['variant_id']}: Product ID = {$variant->product_id}\n";
        } else {
            echo "  - WARNING: Variant ID {$item['variant_id']} not found!\n";
        }
    }
    echo "\n";
    
    echo "Step 3: Adding regular items to cart...\n";
    
    foreach ($cartItems as $item) {
        $cartId = DB::table('carts')->insertGetId([
            'user_id' => $userId,
            'product_variant_id' => $item['variant_id'],
            'product_id' => $item['product_id'],
            'qty' => $item['qty'],
            'created_at' => $now,
            'updated_at' => $now
        ]);
        
        echo "  - Added {$item['name']} (Variant: {$item['variant_id']}, Product: {$item['product_id']}, Qty: {$item['qty']}) - Cart ID: {$cartId}\n";
    }
    echo "\n";
    
    echo "Step 4: Getting combo products for Combo ID 11 (Biryani Combo)...\n";
    
    $comboId = 11;
    $comboProducts = DB::table('combo_products')
        ->where('combo_id', $comboId)
        ->get();
    
    if ($comboProducts->isEmpty()) {
        echo "  - WARNING: No products found for Combo ID {$comboId}\n\n";
    } else {
        echo "  - Found {$comboProducts->count()} products in combo:\n";
        foreach ($comboProducts as $cp) {
            echo "    * Product ID: {$cp->product_id}, Variant ID: {$cp->variant_id}, Quantity: {$cp->quantity}\n";
        }
        echo "\n";
        
        echo "Step 5: Adding combo to combo_custom_cart...\n";
        
        $comboCustomId = DB::table('combo_custom_cart')->insertGetId([
            'combo_id' => $comboId,
            'user_id' => $userId,
            'is_ordered' => 0,
            'created_at' => $now,
            'updated_at' => $now
        ]);
        
        echo "  - Added Biryani Combo to cart - Combo Custom ID: {$comboCustomId}\n\n";
        
        echo "Step 6: Adding combo products to combo_custom_products...\n";
        
        foreach ($comboProducts as $cp) {
            $comboProductId = DB::table('combo_custom_products')->insertGetId([
                'combo_custom_id' => $comboCustomId,
                'product_id' => $cp->product_id,
                'variant_id' => $cp->variant_id,
                'quantity' => $cp->quantity,
                'created_at' => $now,
                'updated_at' => $now
            ]);
            
            echo "  - Added product (Product ID: {$cp->product_id}, Variant ID: {$cp->variant_id}, Qty: {$cp->quantity}) - ID: {$comboProductId}\n";
        }
        echo "\n";
    }
    
    DB::commit();
    
    echo "=== SUMMARY ===\n\n";
    
    echo "Regular Cart Items:\n";
    $cartSummary = DB::table('carts')
        ->join('product_variants', 'carts.product_variant_id', '=', 'product_variants.id')
        ->join('products', 'carts.product_id', '=', 'products.id')
        ->where('carts.user_id', $userId)
        ->select('products.name', 'product_variants.type', 'product_variants.measurement', 'carts.qty')
        ->get();
    
    foreach ($cartSummary as $item) {
        $variantInfo = $item->measurement . ' ' . $item->type;
        echo "  - {$item->name} ({$variantInfo}) - Quantity: {$item->qty}\n";
    }
    
    echo "\nCombo Cart Items:\n";
    $comboSummary = DB::table('combo_custom_cart')
        ->join('combos', 'combo_custom_cart.combo_id', '=', 'combos.id')
        ->where('combo_custom_cart.user_id', $userId)
        ->select('combos.name', 'combo_custom_cart.id as combo_custom_id', 'combos.id as combo_id')
        ->get();
    
    foreach ($comboSummary as $combo) {
        echo "  - {$combo->name} (Combo ID: {$combo->combo_id})\n";
        
        $comboProds = DB::table('combo_custom_products')
            ->join('products', 'combo_custom_products.product_id', '=', 'products.id')
            ->join('product_variants', 'combo_custom_products.variant_id', '=', 'product_variants.id')
            ->where('combo_custom_products.combo_custom_id', $combo->combo_custom_id)
            ->select('products.name', 'product_variants.type', 'product_variants.measurement', 'combo_custom_products.quantity')
            ->get();
        
        foreach ($comboProds as $prod) {
            $variantInfo = $prod->measurement . ' ' . $prod->type;
            echo "    * {$prod->name} ({$variantInfo}) - Quantity: {$prod->quantity}\n";
        }
    }
    
    echo "\n=== Cart successfully populated for User ID: {$userId} ===\n";
    
} catch (Exception $e) {
    DB::rollBack();
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}

?>