<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Store19ProductSeeder extends Seeder
{
    /**
     * Seed 20 products for store_id = 19 (admin-managed, no seller).
     *
     * Store 19 ("Fresh Fish") has:
     *   CategoryGroup 38 ("Fresh Fish")
     *     SubCatGroup 34 ("Fish & Seafood") → cats 88(Fish), 89(Seafood)
     *     SubCatGroup 36 ("Prawns")         → cat 91(Prawns)
     *     SubCatGroup 87 ("Fish Meat")      → cats 91,88,89 (same as above)
     *
     * Run: php artisan db:seed --class=Store19ProductSeeder
     */
    public function run(): void
    {
        // category_id → [category_group_id, sub_category_group_id]
        $catMapping = [
            88 => [38, 34],  // Fish
            89 => [38, 34],  // Seafood
            91 => [38, 36],  // Prawns
        ];

        $products = [
            // ── Fish (cat 88) ──
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Rohu Fish Whole 1kg', 'description' => 'Fresh whole rohu fish, cleaned and gutted. Popular for fish curry and fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 280, 'disc_price' => 260, 'stock' => 30, 'unit_id' => 1,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Rohu Fish Steaks 500g', 'description' => 'Fresh rohu fish cut into steaks. Ready for frying and curry preparation.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 155, 'disc_price' => 140, 'stock' => 40, 'unit_id' => 2,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Katla Fish Whole 1kg', 'description' => 'Fresh whole katla fish, cleaned. Rich taste, great for Bengali fish curry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 300, 'disc_price' => 280, 'stock' => 25, 'unit_id' => 1,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Pomfret White Medium', 'description' => 'Fresh white pomfret, medium size. Premium fish for tawa fry and rava fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 450, 'disc_price' => 420, 'stock' => 20, 'unit_id' => 2,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Surmai (Seer Fish) Steaks', 'description' => 'Fresh surmai fish steaks, firm and flavorful. Best for tandoori and grilling.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 500, 'disc_price' => 470, 'stock' => 20, 'unit_id' => 2,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Tilapia Fish Fillets 500g', 'description' => 'Boneless tilapia fillets, mild taste. Easy to cook for kids and quick meals.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 220, 'disc_price' => 200, 'stock' => 35, 'unit_id' => 2,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Bangda (Mackerel) 500g', 'description' => 'Fresh bangda fish, cleaned. Affordable and tasty for everyday fish fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 160, 'disc_price' => 145, 'stock' => 40, 'unit_id' => 2,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Sardine Fish 500g', 'description' => 'Fresh sardine fish, small and flavorful. Rich in omega-3, great for frying.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 130, 'disc_price' => 115, 'stock' => 40, 'unit_id' => 2,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Basa Fish Fillets 1kg', 'description' => 'Boneless basa fish fillets. Mild flavor, perfect for pan fry and fish tacos.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 350, 'disc_price' => 320, 'stock' => 30, 'unit_id' => 1,
            ],
            [
                'category_id' => 88, 'item_type_id' => null,
                'name' => 'Salmon Fish Steaks 250g', 'description' => 'Premium salmon steaks, rich in omega-3. Ideal for grilling and baking.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 250, 'price' => 550, 'disc_price' => 520, 'stock' => 15, 'unit_id' => 2,
            ],

            // ── Seafood (cat 89) ──
            [
                'category_id' => 89, 'item_type_id' => null,
                'name' => 'Squid (Calamari) Rings 500g', 'description' => 'Fresh squid cleaned and cut into rings. Perfect for crispy fried calamari.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 350, 'disc_price' => 320, 'stock' => 25, 'unit_id' => 2,
            ],
            [
                'category_id' => 89, 'item_type_id' => null,
                'name' => 'Crab Whole Medium', 'description' => 'Fresh whole crab, medium size. Rich flavor for crab masala and pepper crab.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 400, 'disc_price' => 370, 'stock' => 15, 'unit_id' => 2,
            ],
            [
                'category_id' => 89, 'item_type_id' => null,
                'name' => 'Clams (Tisrya) 500g', 'description' => 'Fresh clams, cleaned. Popular Konkani delicacy for tisrya masala.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 200, 'disc_price' => 180, 'stock' => 20, 'unit_id' => 2,
            ],
            [
                'category_id' => 89, 'item_type_id' => null,
                'name' => 'Mussels Fresh 500g', 'description' => 'Fresh mussels, cleaned and debearded. Great for garlic butter mussels.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 250, 'disc_price' => 225, 'stock' => 15, 'unit_id' => 2,
            ],

            // ── Prawns (cat 91) ──
            [
                'category_id' => 91, 'item_type_id' => null,
                'name' => 'Prawns Medium 500g', 'description' => 'Fresh medium prawns, cleaned and deveined. Ideal for prawn curry and fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 380, 'disc_price' => 350, 'stock' => 30, 'unit_id' => 2,
            ],
            [
                'category_id' => 91, 'item_type_id' => null,
                'name' => 'Prawns Medium 1kg', 'description' => 'Fresh medium prawns, cleaned and deveined. Family pack for prawn lovers.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 700, 'disc_price' => 650, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 91, 'item_type_id' => null,
                'name' => 'Jumbo Prawns 500g', 'description' => 'Large jumbo prawns, cleaned. Premium quality for tandoori and butter garlic.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 550, 'disc_price' => 510, 'stock' => 15, 'unit_id' => 2,
            ],
            [
                'category_id' => 91, 'item_type_id' => null,
                'name' => 'Tiger Prawns 500g', 'description' => 'Fresh tiger prawns, large and succulent. Best for grilling and Thai curry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 600, 'disc_price' => 560, 'stock' => 15, 'unit_id' => 2,
            ],
            [
                'category_id' => 91, 'item_type_id' => null,
                'name' => 'Small Prawns (Jawla) 500g', 'description' => 'Small dried-style prawns, great for rice dishes and kolambi bhaat.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 250, 'disc_price' => 220, 'stock' => 30, 'unit_id' => 2,
            ],
            [
                'category_id' => 91, 'item_type_id' => null,
                'name' => 'Prawns Peeled Deveined 250g', 'description' => 'Ready to cook peeled and deveined prawns. Just add to your pan and cook.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 250, 'price' => 280, 'disc_price' => 260, 'stock' => 25, 'unit_id' => 2,
            ],
        ];

        DB::beginTransaction();
        try {
            $count = 0;
            foreach ($products as $pd) {
                $catId = $pd['category_id'];
                $map   = $catMapping[$catId] ?? [null, null];
                $cgId  = $map[0];
                $scgId = $map[1];

                $slug      = preg_replace('/\s+/', '-', trim(preg_replace('/[^\p{L}\p{N} ]/u', '', $pd['name'])));
                $slugCount = Product::where('slug', 'LIKE', "{$slug}%")->count();
                $rowOrder  = (Product::max('row_order') ?? 0) + 1;

                $product = new Product();
                $product->name                   = $pd['name'];
                $product->slug                   = $slugCount ? "{$slug}-{$slugCount}" : $slug;
                $product->row_order              = $rowOrder;
                $product->description            = $pd['description'];
                $product->category_id            = $catId;
                $product->category_group_id      = $cgId;
                $product->sub_category_group_id  = $scgId;
                $product->item_type_id           = $pd['item_type_id'];
                $product->store_id               = 19;
                $product->seller_id              = null;
                $product->type                   = $pd['type'];
                $product->indicator              = $pd['indicator'];
                $product->is_unlimited_stock     = 0;
                $product->fssai_lic_no           = ' ';
                $product->total_allowed_quantity = 100;
                $product->cancelable_status      = 1;
                $product->till_status            = 3;
                $product->return_status          = 1;
                $product->return_days            = 7;
                $product->is_approved            = 1;
                $product->status                 = 1;
                $product->cod_allowed            = 1;
                $product->image                  = '';
                $product->save();

                $variant                   = new ProductVariant();
                $variant->product_id       = $product->id;
                $variant->type             = $pd['type'];
                $variant->measurement      = $pd['measurement'];
                $variant->price            = $pd['price'];
                $variant->discounted_price = $pd['disc_price'];
                $variant->stock            = $pd['stock'];
                $variant->stock_unit_id    = $pd['unit_id'];
                $variant->status           = 1;
                $variant->save();

                $count++;
            }

            DB::commit();
            $this->command->info("Seeded {$count} products with variants for Store 19 (admin-managed).");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Seeder failed: " . $e->getMessage());
            Log::error('Store19ProductSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
