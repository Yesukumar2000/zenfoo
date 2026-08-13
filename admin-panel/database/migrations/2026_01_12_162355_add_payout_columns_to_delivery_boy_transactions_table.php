<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPayoutColumnsToDeliveryBoyTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            // Add payout reference column if not exists
            if (!Schema::hasColumn('delivery_boy_transactions', 'payout_reference')) {
                $table->string('payout_reference', 100)->nullable()->after('settled_at');
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
            if (Schema::hasColumn('delivery_boy_transactions', 'payout_reference')) {
                $table->dropColumn('payout_reference');
            }
        });
    }
}
