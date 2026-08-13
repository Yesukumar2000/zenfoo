<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBrandCampaignProductsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('brand_campaign_products', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('brand_campaign_id');
            $table->unsignedBigInteger('product_id');
            $table->integer('display_order')->default(0);
            $table->timestamps();

            // Foreign keys
            $table->foreign('brand_campaign_id')
                ->references('id')
                ->on('brand_campaigns')
                ->onDelete('cascade');

            $table->foreign('product_id')
                ->references('id')
                ->on('products')
                ->onDelete('cascade');

            // Unique constraint - one product can appear only once per campaign
            $table->unique(['brand_campaign_id', 'product_id'], 'campaign_product_unique');

            // Index for faster queries
            $table->index('brand_campaign_id');
            $table->index('product_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('brand_campaign_products');
    }
}
