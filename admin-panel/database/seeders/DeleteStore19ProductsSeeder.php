<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeleteStore19ProductsSeeder extends Seeder
{
    /**
     * Delete all products seeded by Store19ProductSeeder.
     *
     * Run: php artisan db:seed --class=DeleteStore19ProductsSeeder
     */
    public function run(): void
    {
        $names = [
            'Rohu Fish Whole 1kg',
            'Rohu Fish Steaks 500g',
            'Katla Fish Whole 1kg',
            'Pomfret White Medium',
            'Surmai (Seer Fish) Steaks',
            'Tilapia Fish Fillets 500g',
            'Bangda (Mackerel) 500g',
            'Sardine Fish 500g',
            'Basa Fish Fillets 1kg',
            'Salmon Fish Steaks 250g',
            'Squid (Calamari) Rings 500g',
            'Crab Whole Medium',
            'Clams (Tisrya) 500g',
            'Mussels Fresh 500g',
            'Prawns Medium 500g',
            'Prawns Medium 1kg',
            'Jumbo Prawns 500g',
            'Tiger Prawns 500g',
            'Small Prawns (Jawla) 500g',
            'Prawns Peeled Deveined 250g',
        ];

        DB::beginTransaction();
        try {
            $products = Product::where('store_id', 19)
                ->whereIn('name', $names)
                ->get();

            $count = 0;
            foreach ($products as $product) {
                ProductVariant::where('product_id', $product->id)->delete();
                $product->delete();
                $count++;
            }

            DB::commit();
            $this->command->info("Deleted {$count} seeded products and their variants from Store 19.");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Delete failed: " . $e->getMessage());
            Log::error('DeleteStore19ProductsSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
