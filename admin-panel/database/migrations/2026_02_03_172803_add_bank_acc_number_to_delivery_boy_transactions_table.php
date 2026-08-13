<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddBankAccNumberToDeliveryBoyTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            if (!Schema::hasColumn('delivery_boy_transactions', 'bank_acc_number')) {
                $table->string('bank_acc_number', 50)->nullable()->after('payout_reference');
            }
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
            if (Schema::hasColumn('delivery_boy_transactions', 'bank_acc_number')) {
                $table->dropColumn('bank_acc_number');
            }
        });
    }
}
