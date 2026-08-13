<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDeliveryBoyPayoutHistoryTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('delivery_boy_payout_history', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->string('payout_transaction_id', 100)->unique();
            $table->decimal('amount', 10, 2);
            $table->json('transaction_ids')->nullable(); // Array of transaction IDs settled in this payout
            $table->enum('status', ['pending', 'processing', 'success', 'failed'])->default('pending');
            $table->json('phonepe_response')->nullable(); // Store PhonePe API response
            $table->string('failure_reason')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->index(['delivery_boy_id', 'status']);
            $table->index('payout_transaction_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('delivery_boy_payout_history');
    }
}
