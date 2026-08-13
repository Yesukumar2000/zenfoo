<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPartialPaymentToDeliveryBoyTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->decimal('partial_payment', 10, 2)->nullable()->after('settled_with_admin')
                ->comment('Amount partially paid towards this transaction (if not fully settled)');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->dropColumn('partial_payment');
        });
    }
}
