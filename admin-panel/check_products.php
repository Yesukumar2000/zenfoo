<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

$sellerId = 62;

echo "Checking products for seller_id: $sellerId\n";
echo str_repeat('=', 80) . "\n";

// Get all products for this seller
$products = DB::table('products')
    ->where('seller_id', $sellerId)
    ->select('id', 'name', 'is_approved', 'status', 'store_id', 'category_id')
    ->get();

echo "Total products found: " . $products->count() . "\n\n";

foreach ($products as $product) {
    echo "ID: {$product->id}\n";
    echo "  Name: {$product->name}\n";
    echo "  Approved: {$product->is_approved}\n";
    echo "  Status: {$product->status}\n";
    echo "  Store ID: {$product->store_id}\n";
    echo "  Category ID: {$product->category_id}\n";
    echo str_repeat('-', 80) . "\n";
}

// Check what would match the filter
$filtered = DB::table('products')
    ->where('seller_id', $sellerId)
    ->where('store_id', 15)
    ->where('is_approved', 1)
    ->where('status', 1)
    ->count();

echo "\nProducts matching API filters (store_id=15, is_approved=1, status=1): $filtered\n";

// Check if store is managed by admin
$store = DB::table('stores')->where('id', 15)->first();
echo "\nStore 15 managed_by_admin: " . ($store->managed_by_admin ?? 'N/A') . "\n";