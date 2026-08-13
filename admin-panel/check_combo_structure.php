<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

// Get structure of combo_products table
echo "Structure of combo_products table:\n";
$columns = DB::select('DESCRIBE combo_products');
foreach ($columns as $col) {
    echo "  - {$col->Field} ({$col->Type})\n";
}

echo "\nSample data from combo_products for combo_id = 11:\n";
$comboProducts = DB::table('combo_products')
    ->where('combo_id', 11)
    ->get();

if ($comboProducts->isEmpty()) {
    echo "  No products found for combo_id = 11\n";
} else {
    foreach ($comboProducts as $cp) {
        echo "  - ";
        print_r($cp);
    }
}

?>
