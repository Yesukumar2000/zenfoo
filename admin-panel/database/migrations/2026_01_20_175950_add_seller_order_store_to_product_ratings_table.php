<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddSellerOrderStoreToProductRatingsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('product_ratings', function (Blueprint $table) {
            $table->unsignedBigInteger('seller_id')->nullable()->after('product_id');
            $table->unsignedBigInteger('order_id')->nullable()->after('seller_id');
            $table->unsignedBigInteger('store_id')->nullable()->after('order_id');
            $table->tinyInteger('is_zenfoo_store')->default(0)->after('store_id'); // 1 = admin-managed store, 0 = seller store
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('product_ratings', function (Blueprint $table) {
            $table->dropColumn(['seller_id', 'order_id', 'store_id', 'is_zenfoo_store']);
        });
    }
}
