<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Support\Facades\Log;

echo "=== Testing Product 38 Access ===\n\n";

// Test 1: Direct database query
echo "Test 1: Direct database query\n";
$productRaw = \DB::table('products')->where('id', 38)->first();
echo "Product ID: {$productRaw->id}\n";
echo "Product Name: {$productRaw->name}\n";
echo "is_unlimited_stock (raw): {$productRaw->is_unlimited_stock}\n";
echo "type: {$productRaw->type}\n";
echo "status: {$productRaw->status}\n\n";

// Test 2: Using Product Model
echo "Test 2: Using Product Model (Eloquent)\n";
$product = Product::where('id', 38)->where('status', 1)->first();
if ($product) {
    echo "Product ID: {$product->id}\n";
    echo "Product Name: {$product->name}\n";
    echo "is_unlimited_stock (model): {$product->is_unlimited_stock}\n";
    echo "type: {$product->type}\n";
    echo "Model attributes: " . implode(', ', array_keys($product->getAttributes())) . "\n\n";
} else {
    echo "Product not found or inactive!\n\n";
}

// Test 3: Variant check
echo "Test 3: Variant for Product 38\n";
$variant = ProductVariant::where('product_id', 38)->where('status', 1)->first();
if ($variant) {
    echo "Variant ID: {$variant->id}\n";
    echo "Stock: {$variant->stock}\n";
    echo "Status: {$variant->status}\n\n";
} else {
    echo "No active variant found!\n\n";
}

// Test 4: Simulate stock check helper
echo "Test 4: Simulate ProductHelper::isItemAvailableWithStock\n";
if ($variant && $product) {
    echo "Product is_unlimited_stock: {$product->is_unlimited_stock}\n";
    echo "Type check: " . gettype($product->is_unlimited_stock) . "\n";
    echo "Equality check (== 1): " . ($product->is_unlimited_stock == 1 ? 'TRUE' : 'FALSE') . "\n";
    echo "Strict equality check (=== 1): " . ($product->is_unlimited_stock === 1 ? 'TRUE' : 'FALSE') . "\n";
    echo "Equality check (== '1'): " . ($product->is_unlimited_stock == '1' ? 'TRUE' : 'FALSE') . "\n";

    if ($product->is_unlimited_stock == 1) {
        echo "\n✅ UNLIMITED STOCK CHECK PASSED - Should allow add to cart!\n";
    } else {
        echo "\n❌ UNLIMITED STOCK CHECK FAILED - Would check stock ({$variant->stock} available)\n";
    }
}

echo "\n=== Test Complete ===\n";
