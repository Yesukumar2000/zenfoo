<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make('Illuminate\Contracts\Console\Kernel');
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n=== Get Driver Token for Postman Testing ===\n\n";

$admin = DB::table('admins')
    ->where('type', 'delivery_boy')
    ->first();

if ($admin) {
    echo "Driver ID: " . $admin->id . "\n";
    echo "Driver Name: " . ($admin->name ?? 'N/A') . "\n";
    echo "Driver Phone: " . ($admin->phone ?? 'N/A') . "\n";
    echo "Driver Email: " . ($admin->email ?? 'N/A') . "\n";
    echo "\nAccess Token (Copy this for Postman):\n";
    echo "----------------------------------------\n";
    echo $admin->remember_token . "\n";
    echo "----------------------------------------\n";
} else {
    echo "No delivery boy found in database.\n";
    echo "Please create a delivery boy first or use the login API to get a token.\n";
}

echo "\n";
