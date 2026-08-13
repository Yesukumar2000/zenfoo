<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $exists = DB::table('settings')
            ->where('variable', 'is_test_rain_mode_activated')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'is_test_rain_mode_activated',
                'value' => '0',
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')
            ->where('variable', 'is_test_rain_mode_activated')
            ->delete();
    }
};
