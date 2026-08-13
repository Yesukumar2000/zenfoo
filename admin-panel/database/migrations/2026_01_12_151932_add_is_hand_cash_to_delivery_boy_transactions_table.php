<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddIsHandCashToDeliveryBoyTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->tinyInteger('is_hand_cash')->default(0)->after('id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->dropColumn('is_hand_cash');
        });
    }
}
