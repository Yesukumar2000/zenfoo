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
        Schema::create('brand_campaigns', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Campaign name (e.g., "Sunflower Oil Promotion")
            $table->text('description')->nullable(); // Campaign description
            $table->string('tagline')->nullable(); // Marketing tagline

            // Primary branding images
            $table->string('primary_image_url')->nullable(); // Main campaign image
            $table->string('secondary_image_url')->nullable(); // Secondary campaign image

            // Banner content (up to 3 banners)
            $table->json('banners')->nullable(); // Array of banner objects with type (image/video), url, title, description

            // Brand and product selection
            $table->unsignedBigInteger('brand_id')->nullable(); // Specific brand or null for multi-brand
            $table->json('product_ids')->nullable(); // JSON array of selected product IDs
            $table->json('category_ids')->nullable(); // Optional: filter by categories

            // Campaign dates
            $table->dateTime('start_date');
            $table->dateTime('end_date');
            $table->dateTime('expired_at')->nullable(); // Explicit expiry timestamp

            // Campaign status and visibility
            $table->tinyInteger('status')->default(1); // 1 = active, 0 = inactive
            $table->tinyInteger('is_featured')->default(0); // Show as featured campaign
            $table->integer('display_order')->default(0); // For sorting campaigns

            // Meta information
            $table->string('campaign_type')->default('brand_promotion'); // Type: brand_promotion, seasonal, flash_sale, etc.
            $table->string('theme_color')->default('#000000'); // Campaign theme color
            $table->json('metadata')->nullable(); // Additional flexible data

            $table->timestamps();
            $table->softDeletes();

            // Indexes
            $table->index('brand_id');
            $table->index('status');
            $table->index('is_featured');
            $table->index('start_date');
            $table->index('end_date');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('brand_campaigns');
    }
};
