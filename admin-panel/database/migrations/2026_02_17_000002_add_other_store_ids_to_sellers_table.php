<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddOtherStoreIdsToSellersTable extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->json('other_store_ids')->nullable()->after('store_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->dropColumn('other_store_ids');
        });
    }
}
