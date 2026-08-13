<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddGroupAndStoreColumnsToProductsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->integer('sub_category_group_id')->nullable()->after('category_id');
            $table->integer('category_group_id')->nullable()->after('sub_category_group_id');
            $table->integer('store_id')->nullable()->after('category_group_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn(['sub_category_group_id', 'category_group_id', 'store_id']);
        });
    }
}
