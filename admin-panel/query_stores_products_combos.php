<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();
use Illuminate\Support\Facades\DB;

echo "========================================\n";
echo "QUERYING STORES, PRODUCTS & COMBOS\n";
echo "========================================\n\n";

echo "--- STORE INFORMATION ---\n";
$stores = DB::table('stores')->whereIn('id', [12, 13, 14])->get();
foreach ($stores as $store) {
    echo "Store ID: {$store->id}, Name: {$store->name}, Active: {$store->is_active}, Managed by Admin: {$store->managed_by_admin}\n";
}

echo "\n--- PRODUCTS FROM STORES 12, 13, 14 ---\n";
foreach ([12, 13, 14] as $storeId) {
    echo "\n=== Store {$storeId} ===\n";
    $products = DB::table('products')
        ->join('product_variants', 'products.id', '=', 'product_variants.product_id')
        ->where('products.store_id', $storeId)
        ->whereNull('products.deleted_at')
        ->whereNull('product_variants.deleted_at')
        ->select('products.id as product_id', 'products.name as product_name', 
                 'product_variants.id as variant_id', 'product_variants.type as variant_type',
                 'product_variants.measurement', 'product_variants.price', 'product_variants.stock')
        ->limit(3)->get();
    
    foreach ($products as $p) {
        echo "Product: {$p->product_name} | Variant ID: {$p->variant_id} | Type: {$p->variant_type} | ";
        echo "Measurement: {$p->measurement} | Price: {$p->price} | Stock: {$p->stock}\n";
    }
}

echo "\n--- COMBOS WITH MULTIPLE STORES ---\n";
$combos = DB::table('combos')->where('store_id', 'like', '%,%')->where('status', 1)->get();
echo "Found {$combos->count()} combos with comma-separated store_ids\n\n";

foreach ($combos as $combo) {
    echo "\nCombo #{$combo->id}: {$combo->name}\n";
    echo "Store IDs: {$combo->store_id} | Price: {$combo->price}\n";
    
    $comboProducts = DB::table('combo_products')
        ->join('products', 'combo_products.product_id', '=', 'products.id')
        ->join('product_variants', 'combo_products.variant_id', '=', 'product_variants.id')
        ->where('combo_products.combo_id', $combo->id)
        ->select('combo_products.product_id', 'combo_products.variant_id', 'combo_products.quantity',
                 'products.name as product_name', 'products.store_id', 'product_variants.type as variant_type',
                 'product_variants.measurement', 'product_variants.price')
        ->get();
    
    $storeIds = [];
    foreach ($comboProducts as $cp) {
        echo "  - {$cp->product_name} ({$cp->variant_type}-{$cp->measurement}) | Store: {$cp->store_id} | Qty: {$cp->quantity}\n";
        $storeIds[] = $cp->store_id;
    }
    echo "  Unique stores: " . implode(', ', array_unique($storeIds)) . "\n";
}

echo "\n--- COMBOS INVOLVING STORES 12, 13, 14 ---\n";
$specificCombos = DB::table('combos')
    ->where(function($query) {
        $query->where('store_id', 'like', '%12%')
              ->orWhere('store_id', 'like', '%13%')
              ->orWhere('store_id', 'like', '%14%');
    })
    ->where('status', 1)->get();

echo "Found {$specificCombos->count()} combos involving stores 12, 13, or 14\n\n";

foreach ($specificCombos as $combo) {
    echo "\nCombo #{$combo->id}: {$combo->name} | Store IDs: {$combo->store_id}\n";
    $comboProducts = DB::table('combo_products')
        ->join('products', 'combo_products.product_id', '=', 'products.id')
        ->where('combo_products.combo_id', $combo->id)
        ->select('products.name', 'products.store_id', 'combo_products.quantity')
        ->get();
    
    $storeIds = [];
    foreach ($comboProducts as $cp) {
        echo "  - {$cp->name} from Store {$cp->store_id} (Qty: {$cp->quantity})\n";
        $storeIds[] = $cp->store_id;
    }
    echo "  Stores: " . implode(', ', array_unique($storeIds)) . "\n";
}

echo "\n========================================\n";
echo "Query completed!\n";
