<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Add referral driver order count setting
        DB::table('settings')->insert([
            'variable' => 'referral_driver_order_count',
            'value' => '5'
        ]);

        // Add referral driver amount setting
        DB::table('settings')->insert([
            'variable' => 'referral_driver_amount',
            'value' => '200'
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::table('settings')->whereIn('variable', [
            'referral_driver_order_count',
            'referral_driver_amount'
        ])->delete();
    }
};
