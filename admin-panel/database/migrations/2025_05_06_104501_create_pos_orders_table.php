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
        Schema::create('pos_orders', function (Blueprint $table) {
            $table->id();
            $table->integer('pos_user_id')->nullable(); 
            $table->integer('user_id')->nullable();
            $table->integer('store_id')->nullable();
            $table->decimal('total_amount', 10, 2);
            $table->decimal('discount_amount', 10, 2)->default(0);
            $table->decimal('discount_percentage', 5, 2)->default(0);
            $table->string('payment_method')->enum('cash', 'card', 'upi');
            $table->timestamps();
        });

        Schema::create('pos_additional_charges', function (Blueprint $table) {
            $table->id();
            $table->integer('pos_order_id');
            $table->string('charge_name');
            $table->decimal('amount', 10, 2);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pos_order_additional_charges');
        Schema::dropIfExists('pos_orders');
    }
};
