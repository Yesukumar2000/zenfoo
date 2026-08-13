<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteStore20ProductsSeeder extends Seeder
{
    /**
     * Delete all products seeded by Store20ProductSeeder.
     *
     * Run: php artisan db:seed --class=DeleteStore20ProductsSeeder
     */
    public function run(): void
    {
        $names = [
            'Camel Meat Curry Cut 1kg',
            'Camel Meat Curry Cut 500g',
            'Camel Meat Boneless 1kg',
            'Camel Meat Boneless 500g',
            'Camel Keema 1kg',
            'Camel Keema 500g',
            'Camel Meat Ribs 1kg',
            'Camel Meat Shoulder 1kg',
            'Camel Meat Leg Cut 1kg',
            'Camel Meat Steak Cut 500g',
            'Camel Liver Fresh 500g',
            'Camel Liver Fresh 1kg',
            'Camel Meat Biryani Cut 1kg',
            'Camel Meat Biryani Cut 500g',
            'Camel Hump Fat 500g',
            'Camel Meat Chops 500g',
            'Camel Meat Boti 1kg',
            'Camel Tongue Fresh',
            'Camel Shank 1kg',
            'Camel Meat Mixed Pack 1kg',
        ];

        DB::beginTransaction();
        try {
            $products = Product::where('store_id', 20)
                ->whereIn('name', $names)
                ->get();

            $count = 0;
            foreach ($products as $product) {
                ProductVariant::where('product_id', $product->id)->delete();
                $product->delete();
                $count++;
            }

            DB::commit();
            $this->command->info("Deleted {$count} seeded products and their variants from Store 20.");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Delete failed: " . $e->getMessage());
            Log::error('DeleteStore20ProductsSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
