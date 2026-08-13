<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddBuildingToUserAddressesTable extends Migration
{
    public function up()
    {
        Schema::table('user_addresses', function (Blueprint $table) {
            $table->string('building')->nullable()->after('address');
        });
    }

    public function down()
    {
        Schema::table('user_addresses', function (Blueprint $table) {
            $table->dropColumn('building');
        });
    }
}
