<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddGstPercentageToSellerWalletTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->decimal('gst_percentage', 5, 2)->default(0.00)->after('admin_commission')->comment('GST percentage applied to this transaction');
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
            $table->dropColumn('gst_percentage');
        });
    }
}
