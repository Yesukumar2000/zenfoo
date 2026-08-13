<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddSellerPreparingColumnsToOrderSellerStatusTrackingTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->tinyInteger('is_seller_started_preparing')->default(0)->after('status');
            $table->integer('delayed_time_in_min')->nullable()->after('is_seller_started_preparing');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->dropColumn(['is_seller_started_preparing', 'delayed_time_in_min']);
        });
    }
}
