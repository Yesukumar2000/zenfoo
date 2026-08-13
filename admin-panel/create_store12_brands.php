<?php

/**
 * Standalone script to create 5 brands for store 12 and link them to products
 * Run: php create_store12_brands.php
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

echo "========================================\n";
echo "Creating 5 Brands for Store 12\n";
echo "========================================\n\n";

$now = Carbon::now();

// Define 5 brands for store 12
$brands = [
    [
        'name' => 'Nature Fresh',
        'store_id' => 12,
        'category_group_id' => 1,
        'sub_category_group_id' => 2,
        'category_ids' => '38,40',
        'image' => 'https://wheat-rook-708688.hostingersite.com/storage/brand/1765358238_2401.png',
        'status' => 1,
        'seller_id' => null,
        'created_at' => $now,
        'updated_at' => $now,
    ],
    [
        'name' => 'Best Choice',
        'store_id' => 12,
        'category_group_id' => 1,
        'sub_category_group_id' => 2,
        'category_ids' => '38,40,41',
        'image' => 'https://wheat-rook-708688.hostingersite.com/storage/brand/1765359254_70576.jpeg',
        'status' => 1,
        'seller_id' => null,
        'created_at' => $now,
        'updated_at' => $now,
    ],
    [
        'name' => 'Golden Harvest',
        'store_id' => 12,
        'category_group_id' => 1,
        'sub_category_group_id' => 2,
        'category_ids' => '38',
        'image' => 'https://wheat-rook-708688.hostingersite.com/storage/brand/1766396036_41071.webp',
        'status' => 1,
        'seller_id' => null,
        'created_at' => $now,
        'updated_at' => $now,
    ],
    [
        'name' => 'Pure Organic',
        'store_id' => 12,
        'category_group_id' => 1,
        'sub_category_group_id' => 2,
        'category_ids' => '40,41',
        'image' => 'https://wheat-rook-708688.hostingersite.com/storage/brand/1766396936_28566.jpeg',
        'status' => 1,
        'seller_id' => null,
        'created_at' => $now,
        'updated_at' => $now,
    ],
    [
        'name' => 'Premium Quality',
        'store_id' => 12,
        'category_group_id' => 1,
        'sub_category_group_id' => 2,
        'category_ids' => '38,40',
        'image' => 'https://wheat-rook-708688.hostingersite.com/storage/brand/1766397626_97666.jpeg',
        'status' => 1,
        'seller_id' => null,
        'created_at' => $now,
        'updated_at' => $now,
    ],
];

echo "Step 1: Creating 5 brands...\n";
echo "----------------------------\n";

$brandIds = [];
foreach ($brands as $brand) {
    try {
        $brandId = DB::table('brands')->insertGetId($brand);
        $brandIds[] = $brandId;
        echo "✓ Created: {$brand['name']} (ID: {$brandId})\n";
    } catch (\Exception $e) {
        echo "✗ Error creating {$brand['name']}: " . $e->getMessage() . "\n";
    }
}

echo "\nStep 2: Linking brands to products...\n";
echo "--------------------------------------\n";

// Get all active products from store 12
$products = DB::table('products')
    ->where('store_id', 12)
    ->where('status', 1)
    ->select('id', 'name')
    ->get();

if ($products->isEmpty()) {
    echo "⚠ Warning: No active products found in store 12\n";
    echo "   Please add products to store 12 first.\n";
} else {
    $productCount = $products->count();
    $productsPerBrand = max(1, floor($productCount / 5));

    echo "Found {$productCount} products in store 12\n";
    echo "Distributing ~{$productsPerBrand} products per brand\n\n";

    $productIndex = 0;
    foreach ($brandIds as $index => $brandId) {
        $productsToUpdate = [];

        // Get a chunk of products for this brand
        for ($i = 0; $i < $productsPerBrand && $productIndex < $productCount; $i++) {
            $productsToUpdate[] = $products[$productIndex]->id;
            $productIndex++;
        }

        // If this is the last brand, assign remaining products
        if ($index === count($brandIds) - 1) {
            while ($productIndex < $productCount) {
                $productsToUpdate[] = $products[$productIndex]->id;
                $productIndex++;
            }
        }

        if (!empty($productsToUpdate)) {
            try {
                DB::table('products')
                    ->whereIn('id', $productsToUpdate)
                    ->update(['brand_id' => $brandId]);

                $brandName = $brands[$index]['name'];
                echo "✓ Linked " . count($productsToUpdate) . " products to '{$brandName}' (ID: {$brandId})\n";
            } catch (\Exception $e) {
                echo "✗ Error linking products to brand {$brandId}: " . $e->getMessage() . "\n";
            }
        }
    }
}

echo "\n========================================\n";
echo "✅ Process Complete!\n";
echo "========================================\n";
echo "Brands created: " . count($brandIds) . "\n";
if (!$products->isEmpty()) {
    echo "Products updated: {$productCount}\n";
}
echo "\nYou can now test the brand filtering with store_id=12\n";