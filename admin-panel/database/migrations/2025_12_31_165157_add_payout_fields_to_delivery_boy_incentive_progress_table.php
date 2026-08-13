<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPayoutFieldsToDeliveryBoyIncentiveProgressTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boy_incentive_progress', function (Blueprint $table) {
            $table->boolean('is_completed')->default(false)->after('is_eligible');
            $table->unsignedBigInteger('achieved_tier_id')->nullable()->after('is_completed');
            $table->decimal('payout_amount', 10, 2)->default(0)->after('achieved_tier_id');
            $table->enum('payout_status', ['pending', 'processed', 'failed'])->default('pending')->after('payout_amount');
            $table->datetime('payout_processed_at')->nullable()->after('payout_status');
            $table->datetime('completed_at')->nullable()->after('payout_processed_at');

            $table->foreign('achieved_tier_id')->references('id')->on('incentive_offer_tiers')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boy_incentive_progress', function (Blueprint $table) {
            $table->dropForeign(['achieved_tier_id']);
            $table->dropColumn([
                'is_completed',
                'achieved_tier_id',
                'payout_amount',
                'payout_status',
                'payout_processed_at',
                'completed_at'
            ]);
        });
    }
}
