<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddIsZenfooStoreToProductRatingsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (!Schema::hasColumn('product_ratings', 'is_zenfoo_store')) {
            Schema::table('product_ratings', function (Blueprint $table) {
                $table->tinyInteger('is_zenfoo_store')->default(0)->after('store_id'); // 1 = admin-managed store, 0 = seller store
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        if (Schema::hasColumn('product_ratings', 'is_zenfoo_store')) {
            Schema::table('product_ratings', function (Blueprint $table) {
                $table->dropColumn('is_zenfoo_store');
            });
        }
    }
}
