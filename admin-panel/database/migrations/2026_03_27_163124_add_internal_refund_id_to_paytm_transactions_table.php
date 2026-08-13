<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddInternalRefundIdToPaytmTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('paytm_transactions', function (Blueprint $table) {
            $table->string('internal_refund_id')->nullable()->after('is_refunded')
                ->comment('Our internal refund reference ID sent to Paytm (e.g., REFUND_449_1774608523_4853)');
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
            $table->dropColumn('internal_refund_id');
        });
    }
}
