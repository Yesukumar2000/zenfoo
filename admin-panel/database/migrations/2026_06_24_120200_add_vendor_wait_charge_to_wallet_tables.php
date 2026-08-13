<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddVendorWaitChargeToWalletTables extends Migration
{
    public function up()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->decimal('vendor_wait_charge', 8, 2)->default(0)->after('payment_gateway_fees');
        });

        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->decimal('vendor_wait_charge', 8, 2)->default(0)->after('bonus_amount');
        });
    }

    public function down()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->dropColumn('vendor_wait_charge');
        });

        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->dropColumn('vendor_wait_charge');
        });
    }
}
