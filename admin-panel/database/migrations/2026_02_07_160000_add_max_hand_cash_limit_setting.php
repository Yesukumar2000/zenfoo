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
            ->where('variable', 'max_hand_cash_limit')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'max_hand_cash_limit',
                'value' => '1000',
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')
            ->where('variable', 'max_hand_cash_limit')
            ->delete();
    }
};