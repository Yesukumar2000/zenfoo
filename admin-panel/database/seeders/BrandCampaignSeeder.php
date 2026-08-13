<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\BrandCampaign;
use App\Models\Brand;
use App\Models\Product;
use Carbon\Carbon;

class BrandCampaignSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get some brands and products
        $brands = Brand::limit(5)->pluck('id')->toArray();
        $products = Product::limit(20)->pluck('id')->toArray();

        if (empty($brands) || empty($products)) {
            $this->command->warn('Please create some brands and products first!');
            return;
        }

        // Current Active Campaign: Sunflower Oil Promotion
        BrandCampaign::create([
            'name' => 'Pure Goodness Sunflower Oil',
            'description' => 'Experience the purity and freshness of our premium sunflower oil collection. Cold-pressed, pure and natural, perfect for your healthy kitchen.',
            'tagline' => 'Pure Goodness in Every Drop - Sunflower Oil for a Healthier You!',
            'primary_image_url' => 'https://via.placeholder.com/800x600?text=Sunflower+Oil+Main',
            'secondary_image_url' => 'https://via.placeholder.com/400x400?text=Sunflower+Oil+Secondary',
            'banners' => [
                [
                    'type' => 'image',
                    'url' => 'https://via.placeholder.com/1200x400?text=Banner1+Sunflower',
                    'title' => 'Premium Quality Oil',
                    'description' => 'Cold-pressed, pure and natural',
                ],
                [
                    'type' => 'image',
                    'url' => 'https://via.placeholder.com/1200x400?text=Banner2+Nature+Touch',
                    'title' => "Nature's Touch in Every Moment",
                    'description' => 'Experience freshness like never before',
                ],
                [
                    'type' => 'image',
                    'url' => 'https://via.placeholder.com/1200x400?text=Banner3+Bright+Choices',
                    'title' => 'Bright Choices, Better Living',
                    'description' => 'Empowering you with quality choices',
                ],
            ],
            'brand_id' => $brands[0] ?? null,
            'product_ids' => array_slice($products, 0, 5),
            'category_ids' => [1, 2, 3],
            'start_date' => Carbon::now(),
            'end_date' => Carbon::now()->addDays(30),
            'expired_at' => Carbon::now()->addDays(45),
            'status' => 1,
            'is_featured' => 1,
            'display_order' => 1,
            'campaign_type' => 'brand_promotion',
            'metadata' => [
                'discount_percentage' => 10,
                'free_shipping' => true,
                'target_audience' => 'health_conscious',
            ],
        ]);

        // Upcoming Campaign: Seasonal Cooking Oils (scheduled for future)
        BrandCampaign::create([
            'name' => 'Seasonal Cooking Oil Collection',
            'description' => 'Complete range of cooking oils for every culinary need. Perfect for winter cooking with special family packs available.',
            'tagline' => 'Choose Quality, Choose Health',
            'primary_image_url' => 'https://via.placeholder.com/800x600?text=Cooking+Oils',
            'secondary_image_url' => 'https://via.placeholder.com/400x400?text=Oils+Secondary',
            'banners' => [
                [
                    'type' => 'image',
                    'url' => 'https://via.placeholder.com/1200x400?text=Season+Banner1',
                    'title' => 'Winter Special',
                    'description' => 'Perfect for winter cooking',
                ],
                [
                    'type' => 'image',
                    'url' => 'https://via.placeholder.com/1200x400?text=Season+Banner2',
                    'title' => 'Family Packs Available',
                    'description' => 'Bulk discounts on family packs',
                ],
            ],
            'brand_id' => $brands[1] ?? null,
            'product_ids' => array_slice($products, 5, 8),
            'category_ids' => [2, 3],
            'start_date' => Carbon::now()->addDays(31),
            'end_date' => Carbon::now()->addDays(61),
            'expired_at' => Carbon::now()->addDays(90),
            'status' => 1,
            'is_featured' => 1,
            'display_order' => 2,
            'campaign_type' => 'seasonal',
            'metadata' => [
                'discount_percentage' => 15,
                'free_shipping' => true,
                'min_order_value' => 500,
            ],
        ]);

        // Flash Sale Campaign (scheduled for future)
        BrandCampaign::create([
            'name' => 'Flash Sale - Premium Oils',
            'description' => 'Limited time offer on our premium oil collection. Don\'t miss this amazing deal!',
            'tagline' => 'Hurry! Limited Stock Available',
            'primary_image_url' => 'https://via.placeholder.com/800x600?text=Flash+Sale',
            'secondary_image_url' => 'https://via.placeholder.com/400x400?text=Flash+Secondary',
            'banners' => [
                [
                    'type' => 'image',
                    'url' => 'https://via.placeholder.com/1200x400?text=Flash+Banner',
                    'title' => '50% Off Today Only',
                    'description' => 'Don\'t miss this amazing deal',
                ],
            ],
            'brand_id' => $brands[2] ?? null,
            'product_ids' => array_slice($products, 13, 5),
            'category_ids' => [1],
            'start_date' => Carbon::now()->addDays(62),
            'end_date' => Carbon::now()->addDays(63),
            'expired_at' => Carbon::now()->addDays(63),
            'status' => 1,
            'is_featured' => 1,
            'display_order' => 3,
            'campaign_type' => 'flash_sale',
            'metadata' => [
                'discount_percentage' => 50,
                'urgency_level' => 'high',
                'stock_limited' => true,
            ],
        ]);

        // Past Campaign (inactive - for testing)
        BrandCampaign::create([
            'name' => 'Previous Season Campaign',
            'description' => 'This campaign has ended',
            'tagline' => 'Past Campaign',
            'primary_image_url' => 'https://via.placeholder.com/800x600?text=Past+Campaign',
            'secondary_image_url' => 'https://via.placeholder.com/400x400?text=Past+Secondary',
            'banners' => [
                [
                    'type' => 'image',
                    'url' => 'https://via.placeholder.com/1200x400?text=Past+Banner',
                    'title' => 'This offer has ended',
                    'description' => 'Thank you for your support',
                ],
            ],
            'brand_id' => $brands[3] ?? null,
            'product_ids' => array_slice($products, 15, 3),
            'category_ids' => [1],
            'start_date' => Carbon::now()->subDays(90),
            'end_date' => Carbon::now()->subDays(30),
            'expired_at' => Carbon::now()->subDays(30),
            'status' => 0,
            'is_featured' => 0,
            'display_order' => 5,
            'campaign_type' => 'brand_promotion',
            'metadata' => [],
        ]);

        $this->command->info('Brand campaigns seeded successfully!');
        $this->command->info('Current active campaign: Pure Goodness Sunflower Oil');
        $this->command->info('Next campaign starts in 31 days');
    }
}
