<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteStore12ProductsSeeder extends Seeder
{
    /**
     * Delete all products seeded by Store12ProductSeeder.
     *
     * Run: php artisan db:seed --class=DeleteStore12ProductsSeeder
     */
    public function run(): void
    {
        $names = [
            'Rajdhani Besan',
            'Sooji Fine Grain',
            'Pillsbury Maida',
            'India Gate Basmati Rice',
            'Kolam Rice',
            'Brown Rice Organic',
            'Chana Dal Premium',
            'Masoor Dal Red',
            'Kabuli Chana White',
            'Ragi Flour (Finger Millet)',
            'Fortune Sunflower Oil',
            'Cold Pressed Groundnut Oil',
            'Amul Pure Ghee',
            'MDH Garam Masala',
            'Everest Turmeric Powder',
            'California Almonds',
            'Cashew Whole W320',
            'Kelloggs Corn Flakes',
            'Amul Toned Milk',
            'Harvest Gold Bread',
            'Country Eggs Pack of 6',
            'Fruit Cake Slice',
            'Britannia Marie Gold',
            'Milton Water Bottle 1L',
            'Paper Cups Pack of 50',
            'Lays Classic Salted',
            'Haldirams Aloo Bhujia',
            'Cadbury Dairy Milk Silk',
            'Parle-G Gold Biscuits',
            'Tata Tea Gold',
            'Nescafe Classic Coffee',
            'Bournvita Health Drink',
            'Maggi 2-Minute Noodles',
            'Real Mango Juice',
            'Tropicana Orange Juice',
        ];

        DB::beginTransaction();
        try {
            $products = Product::where('store_id', 12)
                ->whereIn('name', $names)
                ->get();

            $count = 0;
            foreach ($products as $product) {
                ProductVariant::where('product_id', $product->id)->delete();
                $product->delete();
                $count++;
            }

            DB::commit();
            $this->command->info("Deleted {$count} seeded products and their variants from Store 12.");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Delete failed: " . $e->getMessage());
            Log::error('DeleteStore12ProductsSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
