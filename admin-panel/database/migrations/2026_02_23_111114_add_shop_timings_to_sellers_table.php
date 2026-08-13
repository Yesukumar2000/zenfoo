<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AddShopTimingsToSellersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->time('shop_opening_time')->default('06:00:00')->after('shop_status');
            $table->time('shop_closing_time')->default('23:00:00')->after('shop_opening_time');
        });

        // Set default timings for all existing sellers
        DB::table('sellers')->update([
            'shop_opening_time' => '06:00:00',
            'shop_closing_time' => '23:00:00',
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->dropColumn(['shop_opening_time', 'shop_closing_time']);
        });
    }
}
