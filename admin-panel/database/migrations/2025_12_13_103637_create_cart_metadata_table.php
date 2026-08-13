<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCartMetadataTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('cart_metadata', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');

            // Coupon/Promocode
            $table->integer('promocode_id')->nullable();

            // Delivery tip
            $table->decimal('delivery_tip', 10, 2)->default(0);

            // Global delivery instructions
            $table->text('delivery_instructions')->nullable();

            // Contact information
            $table->string('contact_name')->nullable();
            $table->string('contact_phone')->nullable();
            $table->string('contact_email')->nullable();

            // Notes per seller (JSON: {"seller_id": "note"})
            $table->json('seller_notes')->nullable();

            // Notes per combo (JSON: {"combo_custom_cart_id": "note"})
            $table->json('combo_notes')->nullable();

            $table->timestamps();

            // Index for faster lookups
            $table->index('user_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('cart_metadata');
    }
}
