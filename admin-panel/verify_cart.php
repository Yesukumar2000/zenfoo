<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "=== Cart Verification for User ID: 8 ===\n\n";

$userId = 8;

echo "Regular Cart (carts table):\n";
$carts = DB::table('carts')
    ->where('user_id', $userId)
    ->get();

echo "Total items: " . $carts->count() . "\n";
foreach ($carts as $cart) {
    echo "  - ID: {$cart->id}, Product ID: {$cart->product_id}, Variant ID: {$cart->product_variant_id}, Qty: {$cart->qty}\n";
}

echo "\nCombo Cart (combo_custom_cart table):\n";
$comboCarts = DB::table('combo_custom_cart')
    ->where('user_id', $userId)
    ->get();

echo "Total combos: " . $comboCarts->count() . "\n";
foreach ($comboCarts as $combo) {
    echo "  - ID: {$combo->id}, Combo ID: {$combo->combo_id}, Is Ordered: {$combo->is_ordered}\n";
    
    $comboProducts = DB::table('combo_custom_products')
        ->where('combo_custom_id', $combo->id)
        ->get();
    
    echo "    Products in this combo: {$comboProducts->count()}\n";
    foreach ($comboProducts as $prod) {
        echo "      * Product ID: {$prod->product_id}, Variant ID: {$prod->variant_id}, Qty: {$prod->quantity}\n";
    }
}

?>
