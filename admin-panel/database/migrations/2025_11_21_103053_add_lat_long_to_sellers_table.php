<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddLatLongToSellersTable extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->string('lat_long')->nullable()->after('store_city');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->dropColumn('lat_long');
        });
    }
}
