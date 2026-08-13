<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddIsZenfooStoreToOrderSellerStatusTrackingTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->tinyInteger('is_zenfoo_store')->default(0)->after('store_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->dropColumn('is_zenfoo_store');
        });
    }
}
