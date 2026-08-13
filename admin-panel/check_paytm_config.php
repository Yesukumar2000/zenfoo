<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make('Illuminate\Contracts\Console\Kernel');
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n=== Paytm Configuration Check ===\n\n";

$settings = DB::table('settings')
    ->whereIn('variable', [
        'paytm_test_merchant_id',
        'paytm_test_merchant_key',
        'paytm_live_merchant_id',
        'paytm_live_merchant_key',
        'paytm_environment',
        'store_mode'
    ])
    ->get(['variable', 'value']);

foreach ($settings as $setting) {
    $displayValue = $setting->value ?: 'NOT SET';

    // Mask sensitive keys
    if (str_contains($setting->variable, 'key')) {
        $displayValue = $setting->value ? substr($setting->value, 0, 10) . '...' : 'NOT SET';
    }

    echo str_pad($setting->variable, 30) . ': ' . $displayValue . "\n";
}

echo "\n=== Test Paytm Helper ===\n\n";

try {
    $credentials = App\Helpers\Paytm::get_credentials();

    echo "Merchant ID: " . ($credentials['paytm_merchant_id'] ?? 'NOT SET') . "\n";
    echo "Merchant Key: " . (isset($credentials['paytm_merchant_key']) ? substr($credentials['paytm_merchant_key'], 0, 10) . '...' : 'NOT SET') . "\n";
    echo "Environment: " . ($credentials['environment'] ?? 'NOT SET') . "\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

echo "\n";