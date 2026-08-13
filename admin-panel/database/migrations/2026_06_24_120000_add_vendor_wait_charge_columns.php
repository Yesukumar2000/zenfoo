<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddVendorWaitChargeColumns extends Migration
{
    public function up()
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->timestamp('first_prep_time_set_at')->nullable()->after('prep_time');
            $table->integer('first_prep_time_minutes')->nullable()->after('first_prep_time_set_at');
            $table->timestamp('driver_picked_at')->nullable()->after('first_prep_time_minutes');
            $table->integer('vendor_wait_minutes')->default(0)->after('driver_picked_at');
            $table->decimal('vendor_wait_charge', 8, 2)->default(0)->after('vendor_wait_minutes');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('total_vendor_wait_charge', 8, 2)->default(0)->after('store_location_id');
        });
    }

    public function down()
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->dropColumn([
                'first_prep_time_set_at',
                'first_prep_time_minutes',
                'driver_picked_at',
                'vendor_wait_minutes',
                'vendor_wait_charge',
            ]);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('total_vendor_wait_charge');
        });
    }
}
