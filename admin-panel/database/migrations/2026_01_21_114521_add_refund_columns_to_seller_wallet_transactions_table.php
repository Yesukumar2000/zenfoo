<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddRefundColumnsToSellerWalletTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->tinyInteger('is_refunded_to_customer')->nullable()->default(null)->after('is_paid_to_seller');
            $table->decimal('refundable_amount', 10, 2)->nullable()->default(null)->after('is_refunded_to_customer');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->dropColumn('is_refunded_to_customer');
            $table->dropColumn('refundable_amount');
        });
    }
}
