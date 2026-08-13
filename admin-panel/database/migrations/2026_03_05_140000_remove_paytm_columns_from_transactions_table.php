<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('transactions', function (Blueprint $table) {
            // Only drop columns if they exist
            $columnsToDrop = [];

            if (Schema::hasColumn('transactions', 'bank_txn_id')) {
                $columnsToDrop[] = 'bank_txn_id';
            }
            if (Schema::hasColumn('transactions', 'payment_mode')) {
                $columnsToDrop[] = 'payment_mode';
            }
            if (Schema::hasColumn('transactions', 'bank_name')) {
                $columnsToDrop[] = 'bank_name';
            }
            if (Schema::hasColumn('transactions', 'gateway_name')) {
                $columnsToDrop[] = 'gateway_name';
            }
            if (Schema::hasColumn('transactions', 'response_code')) {
                $columnsToDrop[] = 'response_code';
            }
            if (Schema::hasColumn('transactions', 'is_captured')) {
                $columnsToDrop[] = 'is_captured';
            }
            if (Schema::hasColumn('transactions', 'type_of_payment')) {
                $columnsToDrop[] = 'type_of_payment';
            }

            if (!empty($columnsToDrop)) {
                $table->dropColumn($columnsToDrop);
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
        Schema::table('transactions', function (Blueprint $table) {
            // Add them back in case we need to rollback
            $table->string('bank_txn_id')->nullable();
            $table->string('payment_mode')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('gateway_name')->nullable();
            $table->string('response_code')->nullable();
            $table->tinyInteger('is_captured')->default(0);
            $table->enum('type_of_payment', ['order_placing', 'wallet_topup'])->default('order_placing');
        });
    }
};
