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
        Schema::create('order_product_ratings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('product_id');
            $table->unsignedBigInteger('seller_id')->nullable();
            $table->unsignedBigInteger('store_id')->nullable();
            $table->tinyInteger('rating')->comment('1 to 5');
            $table->timestamps();

            $table->unique(['order_id', 'user_id', 'product_id'], 'order_product_rating_unique');

            $table->index('order_id');
            $table->index('user_id');
            $table->index('product_id');
            $table->index('seller_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_product_ratings');
    }
};