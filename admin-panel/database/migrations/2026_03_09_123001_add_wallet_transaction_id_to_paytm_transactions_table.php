<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddWalletTransactionIdToPaytmTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('paytm_transactions', function (Blueprint $table) {
            $table->unsignedBigInteger('wallet_transaction_id')->nullable()->after('order_id')->comment('Wallet transaction ID if used for wallet topup');
            $table->index('wallet_transaction_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('paytm_transactions', function (Blueprint $table) {
            $table->dropIndex(['wallet_transaction_id']);
            $table->dropColumn('wallet_transaction_id');
        });
    }
}
