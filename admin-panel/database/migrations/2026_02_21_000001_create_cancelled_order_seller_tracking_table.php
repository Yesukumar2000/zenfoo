<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('cancelled_order_seller_tracking', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('original_tracking_id')->comment('ID of the row from order_seller_status_tracking before deletion');
            $table->unsignedBigInteger('order_id');
            $table->unsignedBigInteger('seller_id');
            $table->unsignedBigInteger('store_id')->nullable();
            $table->unsignedBigInteger('store_location_id')->nullable();
            $table->tinyInteger('is_zenfoo_store')->default(0);
            $table->tinyInteger('is_driver_picked')->default(0);
            $table->json('driver_captured_images_when_marked_as_pickup')->nullable();
            $table->enum('status', ['assigned_to_seller', 'packed_by_seller', 'given_to_delivery_partner'])->default('assigned_to_seller');
            $table->string('otp', 4)->nullable();
            $table->tinyInteger('is_seller_started_preparing')->default(0);
            $table->integer('delayed_time_in_min')->nullable();
            $table->timestamp('driver_arrived_at_seller')->nullable();
            $table->json('prep_time')->nullable();
            $table->enum('cancelled_by', ['admin', 'customer'])->comment('Who triggered the cancellation');
            $table->timestamp('cancelled_at')->useCurrent();
            $table->timestamps();

            $table->index('order_id');
            $table->index('seller_id');
            $table->index('store_id');
            $table->index('cancelled_by');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cancelled_order_seller_tracking');
    }
};
