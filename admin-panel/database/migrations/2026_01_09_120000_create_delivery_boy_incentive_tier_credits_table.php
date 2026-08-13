<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDeliveryBoyIncentiveTierCreditsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('delivery_boy_incentive_tier_credits', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_incentive_progress_id');
            $table->unsignedBigInteger('tier_id');
            $table->decimal('incentive_amount', 10, 2);
            $table->unsignedBigInteger('transaction_id')->nullable();
            $table->dateTime('credited_at');
            $table->timestamps();

            // Foreign keys with shorter names to avoid MySQL 64-char limit
            $table->foreign('delivery_boy_incentive_progress_id', 'fk_dbitc_progress')
                ->references('id')
                ->on('delivery_boy_incentive_progress')
                ->onDelete('cascade');

            $table->foreign('tier_id', 'fk_dbitc_tier')
                ->references('id')
                ->on('incentive_offer_tiers')
                ->onDelete('cascade');

            $table->foreign('transaction_id', 'fk_dbitc_transaction')
                ->references('id')
                ->on('delivery_boy_transactions')
                ->onDelete('set null')
                ->nullable();

            // Indexes with shorter names to avoid MySQL 64-char identifier limit
            $table->index('delivery_boy_incentive_progress_id', 'idx_dbitc_progress');
            $table->index('tier_id', 'idx_dbitc_tier');
            $table->index('transaction_id', 'idx_dbitc_transaction');
            $table->unique(['delivery_boy_incentive_progress_id', 'tier_id'], 'uniq_progress_tier');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('delivery_boy_incentive_tier_credits');
    }
}
