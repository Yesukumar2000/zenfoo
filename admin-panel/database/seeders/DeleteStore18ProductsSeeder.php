<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteStore18ProductsSeeder extends Seeder
{
    /**
     * Delete all products seeded by Store18ProductSeeder.
     *
     * Run: php artisan db:seed --class=DeleteStore18ProductsSeeder
     */
    public function run(): void
    {
        $names = [
            'Mutton Curry Cut Mixed 1kg',
            'Mutton Curry Cut Mixed 500g',
            'Mutton Curry Cut Mixed 250g',
            'Mutton Boneless 1kg',
            'Mutton Boneless 500g',
            'Mutton Brain Fresh',
            'Mutton Brain Pack of 2',
            'Mutton Head Full',
            'Mutton Head Half',
            'Mutton Liver Fresh 1kg',
            'Mutton Liver Fresh 500g',
            'Mutton Keema 1kg',
            'Mutton Keema 500g',
            'Mutton Ribs 1kg',
            'Mutton Shoulder 1kg',
            'Mutton Paya 4 Pieces',
            'Mutton Chops 500g',
            'Mutton Leg Whole',
            'Mutton Boti Cut 1kg',
        ];

        DB::beginTransaction();
        try {
            $products = Product::where('store_id', 18)
                ->whereIn('name', $names)
                ->get();

            $count = 0;
            foreach ($products as $product) {
                ProductVariant::where('product_id', $product->id)->delete();
                $product->delete();
                $count++;
            }

            DB::commit();
            $this->command->info("Deleted {$count} seeded products and their variants from Store 18.");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Delete failed: " . $e->getMessage());
            Log::error('DeleteStore18ProductsSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
