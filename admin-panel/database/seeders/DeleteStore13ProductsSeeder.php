<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteStore13ProductsSeeder extends Seeder
{
    /**
     * Delete all products seeded by Store13ProductSeeder.
     *
     * Run: php artisan db:seed --class=DeleteStore13ProductsSeeder
     */
    public function run(): void
    {
        $names = [
            'Fresh Tomato Local',
            'Hybrid Tomato',
            'Fresh Potato Medium',
            'Onion Red Medium',
            'White Onion',
            'Green Cabbage',
            'Palak (Spinach) Bunch',
            'Carrot Orange',
            'Pudina (Mint) Bunch',
            'Thotakura (Amaranth) Bunch',
            'Banana Robusta',
            'Banana Yelakki',
            'Apple Shimla',
            'Papaya Ripe',
            'Orange Nagpur',
            'Green Grapes Seedless',
            'Pineapple Fresh',
            'Watermelon Kiran',
            'Baby Potato',
            'Guava Thailand Pink',
        ];

        DB::beginTransaction();
        try {
            $products = Product::where('store_id', 13)
                ->whereIn('name', $names)
                ->get();

            $count = 0;
            foreach ($products as $product) {
                ProductVariant::where('product_id', $product->id)->delete();
                $product->delete();
                $count++;
            }

            DB::commit();
            $this->command->info("Deleted {$count} seeded products and their variants from Store 13.");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Delete failed: " . $e->getMessage());
            Log::error('DeleteStore13ProductsSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
