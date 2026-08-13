<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class ChangeTransactionIdToStringInOrdersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * Fix: Paytm transaction IDs are 38 digits long, exceeding BIGINT limit (20 digits)
     * Change transaction_id column to VARCHAR to accommodate long transaction IDs
     *
     * @return void
     */
    public function up()
    {
        Schema::table('orders', function (Blueprint $table) {
            // Change transaction_id from BIGINT to VARCHAR(100)
            // Paytm transaction IDs can be up to 38 digits long
            $table->string('transaction_id', 100)->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('orders', function (Blueprint $table) {
            // Revert back to BIGINT unsigned
            $table->unsignedBigInteger('transaction_id')->nullable()->change();
        });
    }
}