<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddOrdersPriorityToDeliveryBoysTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->tinyInteger('orders_priority')->default(0)->comment('0: both, 1: food+grocery, 2: multi orders')->after('status');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropColumn('orders_priority');
        });
    }
}
