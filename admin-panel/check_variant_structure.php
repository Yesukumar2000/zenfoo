<?php

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;

echo "Structure of product_variants table:\n";
$columns = DB::select('DESCRIBE product_variants');
foreach ($columns as $col) {
    echo "  - {$col->Field} ({$col->Type})\n";
}

?>
