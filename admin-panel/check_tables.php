<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

$tables = DB::select('SHOW TABLES');

echo "Available tables:\n";
foreach ($tables as $table) {
    $tableName = $table->Tables_in_zenfoo;
    echo "  - {$tableName}\n";
}

// Check for cart-related tables
echo "\nCart-related tables:\n";
foreach ($tables as $table) {
    $tableName = $table->Tables_in_zenfoo;
    if (stripos($tableName, 'cart') !== false || stripos($tableName, 'combo') !== false) {
        echo "  - {$tableName}\n";
    }
}

?>
