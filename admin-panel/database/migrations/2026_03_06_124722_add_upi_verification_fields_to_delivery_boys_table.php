<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddUpiVerificationFieldsToDeliveryBoysTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->string('upi_id', 100)->nullable()->after('mobile')->comment('UPI ID for payments');
            $table->string('upi_verification_transaction_id', 255)->nullable()->comment('Paytm transaction ID used for UPI verification');
            $table->boolean('is_upi_verified')->default(0)->comment('Whether UPI ID is verified');
            $table->timestamp('upi_verified_at')->nullable()->comment('Timestamp when UPI was verified');
            $table->string('payment_mode', 50)->default('UPI')->comment('Payment method preference');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropColumn([
                'upi_id',
                'upi_verification_transaction_id',
                'is_upi_verified',
                'upi_verified_at',
                'payment_mode'
            ]);
        });
    }
}
