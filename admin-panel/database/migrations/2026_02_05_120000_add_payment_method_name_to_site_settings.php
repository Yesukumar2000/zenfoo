<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Insert payment_method_name setting if not exists
        $exists = DB::table('settings')
            ->where('variable', 'payment_method_name')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'payment_method_name',
                'value' => 'razorpay' // Default to razorpay, can be 'razorpay' or 'phonepe'
            ]);
        }

        // Insert skip_payment_verification setting if not exists
        $existsSkip = DB::table('settings')
            ->where('variable', 'skip_payment_verification')
            ->exists();

        if (!$existsSkip) {
            DB::table('settings')->insert([
                'variable' => 'skip_payment_verification',
                'value' => 'false' // Set to 'true' to skip payment verification for testing
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')
            ->where('variable', 'payment_method_name')
            ->delete();
    }
};