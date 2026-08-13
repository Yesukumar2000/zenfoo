<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddCascadeIdsToSlidersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('sliders', function (Blueprint $table) {
            // Stores the category group selected in the cascade (step 2 after store)
            $table->unsignedBigInteger('category_group_id')->nullable()->after('store_id');

            // Stores the sub category group selected in the cascade (step 3)
            $table->unsignedBigInteger('sub_category_group_id')->nullable()->after('category_group_id');

            // Stores the category selected in the cascade (step 4).
            // For type=category this mirrors type_id; for type=product it holds
            // the parent category of the selected product.
            $table->unsignedBigInteger('slider_category_id')->nullable()->after('sub_category_group_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('sliders', function (Blueprint $table) {
            $table->dropColumn(['category_group_id', 'sub_category_group_id', 'slider_category_id']);
        });
    }
}
