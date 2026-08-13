<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPaymentGatewayFeesToSellerWalletTransactionsTable extends Migration
{
    public function up()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->decimal('payment_gateway_fees', 8, 2)->default(0.00)->after('gst_percentage')->comment('Payment gateway fees applied to this transaction');
        });
    }

    public function down()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->dropColumn('payment_gateway_fees');
        });
    }
}
