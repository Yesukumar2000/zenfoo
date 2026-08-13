<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateOrderComboItemsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('order_combo_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->string('orders_id'); // Order reference ID
            $table->unsignedBigInteger('user_id');
            $table->unsignedBigInteger('combo_id');
            $table->unsignedBigInteger('combo_custom_cart_id');
            $table->string('combo_name');
            $table->text('combo_description')->nullable();
            $table->integer('product_count')->default(0);
            $table->decimal('total_products_price', 10, 2)->default(0); // Selling price
            $table->decimal('total_actual_price', 10, 2)->default(0); // MRP price
            $table->decimal('discount_percentage', 5, 2)->default(0);
            $table->decimal('sub_total', 10, 2)->default(0);
            $table->json('products')->nullable(); // Store combo products details
            $table->json('status')->nullable(); // Order status history
            $table->string('active_status')->nullable();
            $table->unsignedBigInteger('seller_id')->nullable();
            $table->timestamps();

            $table->index('order_id');
            $table->index('orders_id');
            $table->index('user_id');
            $table->index('combo_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('order_combo_items');
    }
}
