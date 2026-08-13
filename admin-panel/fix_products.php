<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

$sellerId = 62;

echo "Activating products for seller_id: $sellerId\n";
echo str_repeat('=', 80) . "\n";

$updated = DB::table('products')
    ->where('seller_id', $sellerId)
    ->where('status', 0)
    ->update(['status' => 1]);

echo "Updated $updated products to active status\n";

// Verify
$products = DB::table('products')
    ->where('seller_id', $sellerId)
    ->select('id', 'name', 'status')
    ->get();

echo "\nCurrent product statuses:\n";
foreach ($products as $product) {
    echo "  ID: {$product->id} | {$product->name} | Status: {$product->status}\n";
}