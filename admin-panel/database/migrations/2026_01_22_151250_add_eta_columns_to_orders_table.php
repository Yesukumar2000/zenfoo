<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddEtaColumnsToOrdersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->json('locations_json')->nullable()->after('cart_metadata')->comment('Pickup locations and route calculation data');
            $table->integer('estimated_time_of_delivery')->nullable()->after('locations_json')->comment('Estimated delivery time in minutes');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('locations_json');
            $table->dropColumn('estimated_time_of_delivery');
        });
    }
}
