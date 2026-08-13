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
        // Insert skip_payment_verification setting if not exists
        $exists = DB::table('settings')
            ->where('variable', 'skip_payment_verification')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'skip_payment_verification',
                'value' => 'true' // Set to 'true' for testing, 'false' for production
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')
            ->where('variable', 'skip_payment_verification')
            ->delete();
    }
};