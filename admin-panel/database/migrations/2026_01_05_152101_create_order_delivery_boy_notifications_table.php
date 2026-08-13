<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateOrderDeliveryBoyNotificationsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('order_delivery_boy_notifications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->integer('attempt_number')->default(1);
            $table->json('delivery_boy_ids'); // Array of delivery boy IDs notified
            $table->integer('drivers_notified_count')->default(0);
            $table->json('on_ride_driver_ids')->nullable(); // Drivers who were on ride (not notified)
            $table->integer('on_ride_count')->default(0);
            $table->enum('status', ['sent', 'accepted', 'expired', 'failed'])->default('sent');
            $table->unsignedBigInteger('accepted_by')->nullable(); // delivery_boy_id who accepted
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('notified_at')->nullable();
            $table->text('error_message')->nullable();
            $table->timestamps();

            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->foreign('accepted_by')->references('id')->on('delivery_boys')->onDelete('set null');
            $table->index(['order_id', 'attempt_number']);
            $table->index(['order_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('order_delivery_boy_notifications');
    }
}
