<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Illuminate\Support\Facades\DB;

echo "=== Active Delivery Boys in Database ===\n\n";

$drivers = DB::table('delivery_boys')
    ->select('id', 'name', 'mobile')
    ->where('status', 1)
    ->orderBy('id', 'desc')
    ->limit(10)
    ->get();

if ($drivers->count() > 0) {
    echo "Found " . $drivers->count() . " active drivers:\n\n";
    foreach ($drivers as $driver) {
        echo "ID: {$driver->id} | Name: {$driver->name} | Phone: {$driver->mobile}\n";
    }
} else {
    echo "No active delivery boys found!\n";
}

echo "\n=== Checking specific IDs ===\n\n";

$specificIds = [33, 58, 98];
foreach ($specificIds as $id) {
    $exists = DB::table('delivery_boys')->where('id', $id)->exists();
    echo "ID {$id}: " . ($exists ? "✓ EXISTS" : "✗ DOES NOT EXIST") . "\n";
}