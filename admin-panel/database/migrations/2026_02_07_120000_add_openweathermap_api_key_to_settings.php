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
            ->where('variable', 'openweathermap_api_key')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'openweathermap_api_key',
                'value' => 'a5a73e528bea851362c2b37391a9b1e1' // Get free API key from https://openweathermap.org/api
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')
            ->where('variable', 'openweathermap_api_key')
            ->delete();
    }
};
