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
        Schema::create('delivery_boy_referral_tracking', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('referring_delivery_boy_id')->comment('Who made the referral');
            $table->unsignedBigInteger('referred_delivery_boy_id')->comment('Who was referred');
            $table->integer('completed_orders_count')->default(0)->comment('Number of orders completed by referred driver');
            $table->integer('required_orders_count')->default(5)->comment('Number of orders required to earn bonus');
            $table->decimal('bonus_amount', 10, 2)->default(200.00)->comment('Bonus amount for referring driver');
            $table->boolean('is_bonus_paid')->default(false)->comment('Whether bonus has been paid');
            $table->unsignedBigInteger('bonus_transaction_id')->nullable()->comment('Link to delivery_boy_transactions');
            $table->timestamp('bonus_paid_at')->nullable()->comment('When the bonus was paid');
            $table->timestamps();

            // Foreign keys
            $table->foreign('referring_delivery_boy_id')
                  ->references('id')
                  ->on('delivery_boys')
                  ->onDelete('cascade');

            $table->foreign('referred_delivery_boy_id')
                  ->references('id')
                  ->on('delivery_boys')
                  ->onDelete('cascade');

            $table->foreign('bonus_transaction_id')
                  ->references('id')
                  ->on('delivery_boy_transactions')
                  ->onDelete('set null');

            // Indexes
            $table->index('referring_delivery_boy_id');
            $table->index('referred_delivery_boy_id');
            $table->index('is_bonus_paid');

            // Unique constraint: One tracking record per referral relationship
            $table->unique(['referring_delivery_boy_id', 'referred_delivery_boy_id'], 'referral_tracking_unique');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('delivery_boy_referral_tracking');
    }
};
