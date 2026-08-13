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
        Schema::create('order_seller_reviews', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('seller_id')->nullable();
            $table->unsignedBigInteger('store_id')->nullable();
            $table->text('review');
            $table->timestamps();

            $table->unique(['order_id', 'user_id', 'store_id'], 'order_seller_review_unique');

            $table->index('order_id');
            $table->index('user_id');
            $table->index('seller_id');
            $table->index('store_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_seller_reviews');
    }
};