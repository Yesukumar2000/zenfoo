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
        Schema::create('seller_order_zenfoo_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('seller_order_zenfoo_id');
            $table->unsignedBigInteger('product_id');
            $table->unsignedBigInteger('variant_id')->nullable();
            $table->timestamps();

            $table->index('seller_order_zenfoo_id');
            $table->index('product_id');
            $table->index('variant_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('seller_order_zenfoo_items');
    }
};