<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddWalletAmountValueToCartMetadataTable extends Migration
{
    /**
     * How much wallet balance the customer chose to apply. NULL means "apply as
     * much as the balance allows", which is the behaviour of the existing
     * wallet_amount on/off flag.
     */
    public function up()
    {
        Schema::table('cart_metadata', function (Blueprint $table) {
            $table->decimal('wallet_amount_value', 10, 2)->nullable()->after('wallet_amount');
        });
    }

    public function down()
    {
        Schema::table('cart_metadata', function (Blueprint $table) {
            $table->dropColumn('wallet_amount_value');
        });
    }
}
