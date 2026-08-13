<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddStoreAndCategoryGroupFieldsToBrandsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('brands', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('seller_id');
            $table->unsignedBigInteger('category_group_id')->nullable()->after('store_id');
            $table->unsignedBigInteger('sub_category_group_id')->nullable()->after('category_group_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('brands', function (Blueprint $table) {
            $table->dropColumn(['store_id', 'category_group_id', 'sub_category_group_id']);
        });
    }
}
