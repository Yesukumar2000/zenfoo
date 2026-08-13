<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations for version 2.1.2
     * This migration consolidates all changes for version 2.1.2
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table('return_requests', function (Blueprint $table) {
            if (!Schema::hasColumn('return_requests', 'cancellation_reason')) {
                $table->text('cancellation_reason')->nullable()->after('delivery_boy_id');
            }
        });

        Schema::table('sellers', function (Blueprint $table) {
            if (!Schema::hasColumn('sellers', 'self_pickup_mode')) {
                $table->tinyInteger('self_pickup_mode')->default(0)->after('fssai_lic_no');
            }
            if (!Schema::hasColumn('sellers', 'pickup_store_address')) {
                $table->text('pickup_store_address')->nullable()->after('self_pickup_mode');
            }
            if (!Schema::hasColumn('sellers', 'pickup_latitude')) {
                $table->string('pickup_latitude')->nullable()->after('pickup_store_address');
            }
            if (!Schema::hasColumn('sellers', 'pickup_longitude')) {
                $table->string('pickup_longitude')->nullable()->after('pickup_latitude');
            }
            if (!Schema::hasColumn('sellers', 'pickup_store_timings')) {
                $table->text('pickup_store_timings')->nullable()->after('pickup_longitude');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'order_type')) {
                $table->enum('order_type', ['doorstep', 'selfpickup'])->default('doorstep')->after('active_status');
            }
            if (!Schema::hasColumn('orders', 'pickup_address')) {
                $table->text('pickup_address')->nullable()->after('order_type');
            }
        });

        Schema::table('order_items', function (Blueprint $table) {
            if (!Schema::hasColumn('order_items', 'refund_amount')) {
                $table->float('refund_amount')->nullable()->after('sub_total');
            }
        });
    }

    /**
     * Reverse the migrations for version 2.1.2
     *
     * @return void
     */
    public function down(): void
    {
        Schema::table('order_items', function (Blueprint $table) {
            if (Schema::hasColumn('order_items', 'refund_amount')) {
                $table->dropColumn('refund_amount');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'order_type') || Schema::hasColumn('orders', 'pickup_address')) {
                $table->dropColumn(['order_type', 'pickup_address']);
            }
        });

        Schema::table('sellers', function (Blueprint $table) {
            if (Schema::hasColumn('sellers', 'self_pickup_mode') || 
                Schema::hasColumn('sellers', 'pickup_store_address') ||
                Schema::hasColumn('sellers', 'pickup_latitude') ||
                Schema::hasColumn('sellers', 'pickup_longitude') ||
                Schema::hasColumn('sellers', 'pickup_store_timings')) {
                $table->dropColumn([
                    'self_pickup_mode',
                    'pickup_store_address',
                    'pickup_latitude',
                    'pickup_longitude',
                    'pickup_store_timings'
                ]);
            }
        });

        Schema::table('return_requests', function (Blueprint $table) {
            if (Schema::hasColumn('return_requests', 'cancellation_reason')) {
                $table->dropColumn('cancellation_reason');
            }
        });
    }
};
