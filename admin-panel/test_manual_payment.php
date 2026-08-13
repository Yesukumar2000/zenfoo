<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Models\DeliveryBoyManualPayment;
use App\Models\Setting;
use Illuminate\Support\Facades\DB;

echo "=== Manual Payment System Debug ===\n\n";

// Test 1: Check if table exists
echo "1. Checking if table exists...\n";
try {
    $count = DB::table('delivery_boy_manual_payments')->count();
    echo "   ✓ Table exists! Current rows: $count\n\n";
} catch (\Exception $e) {
    echo "   ✗ Table error: " . $e->getMessage() . "\n\n";
    exit(1);
}

// Test 2: Check if model works
echo "2. Checking if model is accessible...\n";
try {
    $model = new DeliveryBoyManualPayment();
    echo "   ✓ Model loaded successfully\n";
    echo "   Table name: " . $model->getTable() . "\n\n";
} catch (\Exception $e) {
    echo "   ✗ Model error: " . $e->getMessage() . "\n\n";
}

// Test 3: Check settings
echo "3. Checking admin payment settings...\n";
try {
    $upi = Setting::get_value('admin_upi_id');
    $bank = Setting::get_value('admin_bank_name');
    echo "   UPI ID: " . ($upi ?: '(empty)') . "\n";
    echo "   Bank: " . ($bank ?: '(empty)') . "\n\n";
} catch (\Exception $e) {
    echo "   ✗ Settings error: " . $e->getMessage() . "\n\n";
}

// Test 4: Check storage directory
echo "4. Checking storage directory...\n";
$paymentProofsPath = storage_path('app/public/payment_proofs');
if (is_dir($paymentProofsPath)) {
    echo "   ✓ Directory exists: $paymentProofsPath\n";
    if (is_writable($paymentProofsPath)) {
        echo "   ✓ Directory is writable\n\n";
    } else {
        echo "   ✗ Directory is NOT writable\n\n";
    }
} else {
    echo "   ✗ Directory does NOT exist: $paymentProofsPath\n\n";
}

// Test 5: Try creating a test record
echo "5. Testing record creation...\n";
try {
    $testPayment = DeliveryBoyManualPayment::create([
        'delivery_boy_id' => 1, // Use a valid delivery boy ID
        'transaction_id' => 'TEST_' . time(),
        'amount' => 100.00,
        'proof_image' => null,
        'status' => 'pending',
    ]);
    echo "   ✓ Test record created with ID: " . $testPayment->id . "\n";
    echo "   Deleting test record...\n";
    $testPayment->delete();
    echo "   ✓ Test record deleted\n\n";
} catch (\Exception $e) {
    echo "   ✗ Creation error: " . $e->getMessage() . "\n\n";
}

echo "=== Debug Complete ===\n";