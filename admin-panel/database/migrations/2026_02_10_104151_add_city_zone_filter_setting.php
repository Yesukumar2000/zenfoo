<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Insert city_zone_filter_enabled setting (default: disabled)
        DB::table('settings')->insertOrIgnore([
            'variable' => 'city_zone_filter_enabled',
            'value' => '0',
        ]);
    }

    public function down(): void
    {
        DB::table('settings')->where('variable', 'city_zone_filter_enabled')->delete();
    }
};