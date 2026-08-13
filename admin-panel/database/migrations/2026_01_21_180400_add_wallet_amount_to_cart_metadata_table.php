<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddWalletAmountToCartMetadataTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('cart_metadata', function (Blueprint $table) {
            if (!Schema::hasColumn('cart_metadata', 'wallet_amount')) {
                $table->tinyInteger('wallet_amount')->default(0)->nullable();
            }
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
            $table->dropColumn('wallet_amount');
        });
    }
}
