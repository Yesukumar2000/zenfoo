<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class AddFreeDeliveryOrderAmountSetting extends Migration
{
    public function up()
    {
        $exists = DB::table('settings')
            ->where('variable', 'free_delivery_order_amount')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'free_delivery_order_amount',
                'value' => '0'
            ]);
        }
    }

    public function down()
    {
        DB::table('settings')
            ->where('variable', 'free_delivery_order_amount')
            ->delete();
    }
}
