<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddRefundColumnsToPaytmTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('paytm_transactions', function (Blueprint $table) {
            $table->boolean('is_refunded')->default(0)->after('is_captured')->comment('Whether this transaction has been refunded');
            $table->string('refund_id')->nullable()->after('is_refunded')->comment('Paytm refund transaction ID');
            $table->decimal('refund_amount', 10, 2)->nullable()->after('refund_id')->comment('Amount refunded');
            $table->timestamp('refunded_at')->nullable()->after('refund_amount')->comment('When the refund was processed');
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
            $table->dropColumn(['is_refunded', 'refund_id', 'refund_amount', 'refunded_at']);
        });
    }
}
