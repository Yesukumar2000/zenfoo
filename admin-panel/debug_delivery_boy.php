<?php
require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\Admin;
use App\Models\DeliveryBoy;

// Get the user ID or mobile number to check
$identifier = $argv[1] ?? null;

if (!$identifier) {
    echo "Usage: php debug_delivery_boy.php <user_id or mobile>\n";
    exit(1);
}

echo "=== Debugging Delivery Boy Account ===\n\n";

// Check if identifier is numeric (user_id) or string (mobile)
if (is_numeric($identifier)) {
    $admin = Admin::find($identifier);
    echo "Searching by Admin ID: {$identifier}\n";
} else {
    $admin = Admin::where('mobile', $identifier)->first();
    echo "Searching by Mobile: {$identifier}\n";
}

if (!$admin) {
    echo "❌ Admin user not found!\n";
    exit(1);
}

echo "\n✅ Admin User Found:\n";
echo "   ID: {$admin->id}\n";
echo "   Name: {$admin->name}\n";
echo "   Mobile: {$admin->mobile}\n";
echo "   Email: {$admin->email}\n";
echo "   Role ID: {$admin->role_id}\n";

// Now check for delivery boy
$deliveryBoy = DeliveryBoy::where('admin_id', $admin->id)->first();

if (!$deliveryBoy) {
    echo "\n❌ Delivery Boy Record NOT FOUND for admin_id: {$admin->id}\n";

    // Check if there's a delivery boy with same mobile but different admin_id
    $deliveryByMobile = DeliveryBoy::where('mobile', $admin->mobile)->first();

    if ($deliveryByMobile) {
        echo "\n⚠️  WARNING: Found delivery boy with same mobile but different admin_id:\n";
        echo "   Delivery Boy ID: {$deliveryByMobile->id}\n";
        echo "   Admin ID in delivery_boys: {$deliveryByMobile->admin_id}\n";
        echo "   Current authenticated admin_id: {$admin->id}\n";
        echo "\n🔧 FIX: Update the delivery boy record:\n";
        echo "   UPDATE delivery_boys SET admin_id = {$admin->id} WHERE id = {$deliveryByMobile->id};\n";
    } else {
        echo "\n⚠️  No delivery boy record exists at all for this mobile number\n";
        echo "\n🔧 FIX: Create a delivery boy record:\n";
        echo "   INSERT INTO delivery_boys (name, mobile, admin_id, address, status) \n";
        echo "   VALUES ('{$admin->name}', '{$admin->mobile}', {$admin->id}, '', 1);\n";
    }
} else {
    echo "\n✅ Delivery Boy Record Found:\n";
    echo "   ID: {$deliveryBoy->id}\n";
    echo "   Name: {$deliveryBoy->name}\n";
    echo "   Mobile: {$deliveryBoy->mobile}\n";
    echo "   Admin ID: {$deliveryBoy->admin_id}\n";
    echo "   Status: {$deliveryBoy->status}\n";
    echo "   City ID: {$deliveryBoy->city_id}\n";
    echo "\n✅ Everything looks good! The link is correct.\n";
}

echo "\n";
