<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddMultiOrderFieldsToCartMetadataTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('cart_metadata', function (Blueprint $table) {
            $table->decimal('multi_order_charges', 10, 2)->default(0)->after('billing_summary');
            $table->boolean('has_multi_order')->default(false)->after('multi_order_charges');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('cart_metadata', function (Blueprint $table) {
            $table->dropColumn(['multi_order_charges', 'has_multi_order']);
        });
    }
}
