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
        Schema::create('seller_orders_zenfoo', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->unsignedBigInteger('seller_id');
            $table->unsignedBigInteger('cus_id');
            $table->unsignedBigInteger('store_id');
            $table->string('status', 50)->default('assigned');
            $table->timestamps();

            $table->index('order_id');
            $table->index('seller_id');
            $table->index('cus_id');
            $table->index('store_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('seller_orders_zenfoo');
    }
};
