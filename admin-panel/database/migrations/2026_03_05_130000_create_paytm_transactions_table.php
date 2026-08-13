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
        Schema::create('paytm_transactions', function (Blueprint $table) {
            $table->id();
            $table->integer('user_id')->index()->comment('User/Customer ID');
            $table->string('order_id')->index()->nullable()->comment('Order ID (null for wallet topup)');

            // Paytm Transaction Details
            $table->string('txn_id')->unique()->comment('Our transaction ID / Paytm ORDER_ID');
            $table->string('paytm_txn_id')->nullable()->comment('Paytm transaction ID (TXNID)');
            $table->string('bank_txn_id')->nullable()->comment('Bank transaction ID (BANKTXNID)');

            // Payment Information
            $table->decimal('amount', 10, 2)->comment('Transaction amount');
            $table->string('payment_mode')->nullable()->comment('Payment mode: UPI, CC, DC, NB, etc.');
            $table->string('bank_name')->nullable()->comment('Bank name used for payment');
            $table->string('gateway_name')->nullable()->comment('Payment gateway name');

            // Status Information
            $table->string('status')->index()->comment('Transaction status: success, failed, pending');
            $table->string('response_code')->nullable()->comment('Paytm response code');
            $table->text('response_msg')->nullable()->comment('Paytm response message');
            $table->tinyInteger('is_captured')->default(0)->comment('Whether payment is captured (1=yes, 0=no)');

            // Transaction Type
            $table->enum('type_of_payment', ['order_placing', 'wallet_topup'])->default('order_placing')->comment('Type of payment transaction');

            // Additional Information
            $table->dateTime('transaction_date')->comment('Transaction date and time');
            $table->text('metadata')->nullable()->comment('Additional metadata (JSON format)');

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('paytm_transactions');
    }
};
