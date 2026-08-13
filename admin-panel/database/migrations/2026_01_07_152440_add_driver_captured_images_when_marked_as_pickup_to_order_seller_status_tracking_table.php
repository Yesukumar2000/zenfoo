<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddDriverCapturedImagesWhenMarkedAsPickupToOrderSellerStatusTrackingTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->json('driver_captured_images_when_marked_as_pickup')->nullable()->after('is_driver_picked');
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
            $table->dropColumn('driver_captured_images_when_marked_as_pickup');
        });
    }
}
