<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteStore14ProductsSeeder extends Seeder
{
    /**
     * Delete all products seeded by Store14ProductSeeder.
     *
     * Run: php artisan db:seed --class=DeleteStore14ProductsSeeder
     */
    public function run(): void
    {
        $names = [
            'Chicken Biryani Cut 1kg',
            'Chicken Biryani Cut 500g',
            'Chicken Curry Cut 1kg',
            'Chicken Curry Cut 500g',
            'Chicken Breast Boneless 1kg',
            'Chicken Breast Boneless 500g',
            'Chicken Leg Piece 1kg',
            'Chicken Drumstick 500g',
            'Chicken Starter Cut 1kg',
            'Chicken Starter Cut 500g',
            'Full Chicken Skinless',
            'Full Chicken With Skin',
            'Chicken Keema 1kg',
            'Chicken Keema 500g',
            'Chicken Wings 1kg',
            'Chicken Liver 500g',
            'Farm Eggs Pack of 6',
            'Farm Eggs Pack of 12',
            'Farm Eggs Pack of 30',
        ];

        DB::beginTransaction();
        try {
            $products = Product::where('store_id', 14)
                ->whereIn('name', $names)
                ->get();

            $count = 0;
            foreach ($products as $product) {
                ProductVariant::where('product_id', $product->id)->delete();
                $product->delete();
                $count++;
            }

            DB::commit();
            $this->command->info("Deleted {$count} seeded products and their variants from Store 14.");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Delete failed: " . $e->getMessage());
            Log::error('DeleteStore14ProductsSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
