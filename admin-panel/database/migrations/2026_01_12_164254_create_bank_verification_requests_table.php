<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBankVerificationRequestsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('bank_verification_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->string('transaction_id', 100)->unique();
            $table->decimal('amount', 10, 2)->default(1.00);
            $table->enum('status', ['pending', 'success', 'failed'])->default('pending');
            $table->json('response_data')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->index(['delivery_boy_id', 'status']);
            $table->index('transaction_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('bank_verification_requests');
    }
}
