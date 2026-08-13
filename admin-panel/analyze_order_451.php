<?php

use App\Services\CityZoneService;

// Get order details
$order = DB::table('orders')->where('id', 451)->first();
echo "\n========================================\n";
echo "ORDER 451 ANALYSIS\n";
echo "========================================\n";
echo "Address ID: {$order->address_id}\n";

// Get all order items and their stores (using the same logic as API)
$orderItems = DB::table('order_items')
    ->where('order_id', 451)
    ->select('id', 'product_variant_id', 'product_name')
    ->get();

$variantIds = $orderItems->pluck('product_variant_id')->toArray();

$variantProductMap = DB::table('product_variants')
    ->whereIn('id', $variantIds)
    ->pluck('product_id', 'id');

$productStoreMap = DB::table('products')
    ->whereIn('id', $variantProductMap->values())
    ->pluck('store_id', 'id');

// Get all unique store IDs from order items
$allStoreIds = $productStoreMap->values()->unique()->toArray();

// Also handle combo items
$comboItems = DB::table('order_combo_items')->where('order_id', 451)->get();
$allComboProductIds = [];
foreach ($comboItems as $combo) {
    if (!empty($combo->products)) {
        $products = json_decode($combo->products, true);
        if (is_string($products)) {
            $products = json_decode($products, true);
        }
        if (is_array($products)) {
            foreach ($products as $product) {
                if (isset($product['product_id'])) {
                    $allComboProductIds[] = $product['product_id'];
                }
            }
        }
    }
}
$allComboProductIds = array_unique($allComboProductIds);

// Get store_ids for combo products
$comboProductStoreMap = [];
if (!empty($allComboProductIds)) {
    $comboProductStoreMap = DB::table('products')
        ->whereIn('id', $allComboProductIds)
        ->pluck('store_id', 'id')
        ->toArray();
}

// Add combo store IDs to all store IDs
$comboStoreIds = array_unique(array_values($comboProductStoreMap));
$allStoreIds = array_unique(array_merge($allStoreIds, $comboStoreIds));

// Get store names
$storeNames = DB::table('stores')
    ->whereIn('id', $allStoreIds)
    ->pluck('name', 'id')
    ->toArray();

echo "\nSTORES IN ORDER:\n";
// Group items by store
$itemsByStore = [];
foreach ($orderItems as $item) {
    $variantId = $item->product_variant_id;
    $productId = $variantProductMap[$variantId] ?? null;
    $storeId = $productId ? ($productStoreMap[$productId] ?? null) : null;
    if ($storeId) {
        if (!isset($itemsByStore[$storeId])) {
            $itemsByStore[$storeId] = [];
        }
        $itemsByStore[$storeId][] = $item->product_name;
    }
}

foreach ($allStoreIds as $storeId) {
    $storeName = $storeNames[$storeId] ?? "Store {$storeId}";
    echo "  - Store {$storeId}: {$storeName}\n";
    if (isset($itemsByStore[$storeId])) {
        $items = implode(", ", array_slice($itemsByStore[$storeId], 0, 3));
        $remaining = count($itemsByStore[$storeId]) - 3;
        echo "    Items: {$items}";
        if ($remaining > 0) {
            echo " ... (+{$remaining} more)";
        }
        echo "\n";
    }
}

// Get stores that support dropdown assignment (meat stores + Store 13)
$allMeatStoreIds = DB::table('stores')->where('is_meat', 1)->pluck('id')->toArray();
$dropdownStoreIds = array_unique(array_merge($allMeatStoreIds, [13]));
$orderMeatStoreIds = array_values(array_intersect($allStoreIds, $dropdownStoreIds));

echo "\nSTORES WITH DROPDOWN ASSIGNMENT:\n";
foreach ($orderMeatStoreIds as $storeId) {
    echo "  - Store {$storeId}: {$storeNames[$storeId]}\n";
}

// STEP 1: Get delivery address
$zoneFilterEnabled = CityZoneService::isZoneFilterEnabled();
echo "\n========================================\n";
echo "ZONE FILTERING: " . ($zoneFilterEnabled ? 'ENABLED' : 'DISABLED') . "\n";
echo "========================================\n";

$deliveryCity = null;
$deliveryLat = null;
$deliveryLon = null;

if ($zoneFilterEnabled && !empty($order->address_id)) {
    $deliveryAddress = DB::table('user_addresses')
        ->where('id', $order->address_id)
        ->select('latitude', 'longitude', 'city_id', 'city', 'address')
        ->first();

    if ($deliveryAddress && !empty($deliveryAddress->latitude) && !empty($deliveryAddress->longitude)) {
        $deliveryLat = (float) $deliveryAddress->latitude;
        $deliveryLon = (float) $deliveryAddress->longitude;

        echo "Delivery Address: {$deliveryAddress->address}\n";
        echo "City: {$deliveryAddress->city}\n";
        echo "Coordinates: {$deliveryLat}, {$deliveryLon}\n";

        // Detect which city polygon this lat/lon falls inside
        $deliveryCity = CityZoneService::detectCity($deliveryLat, $deliveryLon);

        if ($deliveryCity) {
            echo "Detected Zone: {$deliveryCity->name} (ID: {$deliveryCity->id})\n";
        } else {
            echo "Detected Zone: NONE (outside all zones)\n";
        }
    }
}

// STEP 2: Fetch all active sellers
$now = now()->setTimezone('Asia/Kolkata')->format('H:i:s');
echo "\n========================================\n";
echo "FETCHING SELLERS\n";
echo "========================================\n";
echo "Current Time (IST): {$now}\n";
echo "Filters: status=1, shop_status=1, open or no opening time\n\n";

$allSellers = DB::table('sellers')
    ->select('id', 'store_id', 'other_store_ids', 'store_name', 'name')
    ->where('status', 1)
    ->where('shop_status', 1)
    ->where(function ($q) use ($now) {
        $q->whereNull('shop_opening_time')
          ->orWhereRaw('? >= shop_opening_time', [$now]);
    })
    ->get();

echo "Total Active Sellers (before zone filter): {$allSellers->count()}\n";

// STEP 3: Apply zone filter
if ($zoneFilterEnabled && $deliveryCity && $deliveryLat && $deliveryLon) {
    $allSellerIds = $allSellers->pluck('id')->toArray();

    $zoneFilteredIds = CityZoneService::filterSellersByZone(
        $allSellerIds,
        $deliveryCity,
        $deliveryLat,
        $deliveryLon
    );

    $allSellers = $allSellers->filter(fn($s) => in_array($s->id, $zoneFilteredIds))->values();

    echo "Sellers AFTER Zone Filter: {$allSellers->count()}\n";
    echo "Zone-filtered Seller IDs: " . implode(', ', $allSellers->pluck('id')->toArray()) . "\n";
}

// STEP 4: Map sellers to stores
$eligibleSellers = [];
foreach ($allSellers as $seller) {
    $primaryStore = (int) $seller->store_id;
    $otherStoreIds = [];
    if (!empty($seller->other_store_ids)) {
        $decoded = json_decode($seller->other_store_ids, true);
        if (is_array($decoded)) {
            $otherStoreIds = array_map('intval', $decoded);
        }
    }
    $sellerStores = array_unique(array_merge([$primaryStore], $otherStoreIds));

    foreach ($orderMeatStoreIds as $meatStoreId) {
        if (in_array($meatStoreId, $sellerStores)) {
            $eligibleSellers[$meatStoreId][] = [
                'seller_id' => $seller->id,
                'seller_name' => $seller->name,
                'store_name' => $seller->store_name,
                'primary_store_id' => $primaryStore,
                'other_stores' => $otherStoreIds,
            ];
        }
    }
}

// Display results
echo "\n========================================\n";
echo "ELIGIBLE SELLERS BY STORE\n";
echo "========================================\n";

foreach ($orderMeatStoreIds as $storeId) {
    $storeName = $storeNames[$storeId] ?? "Store {$storeId}";
    echo "\n📦 Store {$storeId}: {$storeName}\n";
    echo str_repeat('-', 60) . "\n";

    if (empty($eligibleSellers[$storeId])) {
        echo "  ❌ NO ELIGIBLE SELLERS IN ZONE\n";
    } else {
        foreach ($eligibleSellers[$storeId] as $seller) {
            $isPrimary = $seller['primary_store_id'] == $storeId ? '⭐ PRIMARY' : '📌 OTHER STORE';
            echo "  ✓ Seller #{$seller['seller_id']}: {$seller['seller_name']} ({$seller['store_name']}) - {$isPrimary}\n";
            if (!empty($seller['other_stores'])) {
                echo "    Other Stores: " . implode(', ', $seller['other_stores']) . "\n";
            }
        }
    }
}

echo "\n========================================\n";
echo "SUMMARY\n";
echo "========================================\n";
echo "Total Stores in Order: " . count($allStoreIds) . "\n";
echo "Stores with Dropdown Assignment: " . count($orderMeatStoreIds) . "\n";
echo "Zone Filter Status: " . ($zoneFilterEnabled ? 'ENABLED' : 'DISABLED') . "\n";
if ($deliveryCity) {
    echo "Customer Zone: {$deliveryCity->name}\n";
}
echo "Total Sellers in Zone: " . $allSellers->count() . "\n";
echo "========================================\n\n";
