<?php
// Quick verification script
require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\Order;
use App\Models\OrderStatusList;

echo "=== LATEST ORDER FOR CUSTOMER 8 ===" . PHP_EOL;

$order = Order::where('user_id', 8)->orderBy('id', 'desc')->first();

if ($order) {
    echo "Order ID: " . $order->id . PHP_EOL;
    echo "Is Preorder: " . ($order->is_preorder ? 'YES ✅' : 'NO ❌') . PHP_EOL;
    echo "Status: " . OrderStatusList::find($order->active_status)->status . " (ID: {$order->active_status})" . PHP_EOL;
    echo "Preorder Placed At: " . ($order->preorder_placed_at ?? 'N/A') . PHP_EOL;
    echo "Preorder Process Date: " . ($order->preorder_process_date ?? 'N/A') . PHP_EOL;
    echo "Final Total: ₹" . $order->final_total . PHP_EOL;
    echo "Payment Method: " . $order->payment_method . PHP_EOL;

    echo PHP_EOL . "Expected Values:" . PHP_EOL;
    echo "✓ is_preorder should be: 1" . PHP_EOL;
    echo "✓ active_status should be: 12 (Preorder Pending)" . PHP_EOL;
    echo "✓ preorder_process_date should be: Next Friday 6:30 AM" . PHP_EOL;
} else {
    echo "No orders found for customer 8" . PHP_EOL;
}