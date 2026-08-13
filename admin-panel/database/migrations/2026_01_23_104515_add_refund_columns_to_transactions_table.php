<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddRefundColumnsToTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->tinyInteger('is_refunded')->default(0)->after('status');
            $table->string('refund_transaction_id')->nullable()->after('is_refunded');
            $table->decimal('refund_amount', 10, 2)->nullable()->after('refund_transaction_id');
            $table->timestamp('refunded_at')->nullable()->after('refund_amount');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropColumn(['is_refunded', 'refund_transaction_id', 'refund_amount', 'refunded_at']);
        });
    }
}
