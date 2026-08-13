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
        Schema::create('order_driver_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('delivery_boy_id');
            $table->tinyInteger('rating')->comment('1 to 5');
            $table->text('review')->nullable();
            $table->timestamps();

            $table->unique(['order_id', 'user_id'], 'order_driver_rating_unique');

            $table->index('order_id');
            $table->index('user_id');
            $table->index('delivery_boy_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_driver_ratings');
    }
};