<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Store18ProductSeeder extends Seeder
{
    /**
     * Seed 20 products for store_id = 18 (admin-managed, no seller).
     *
     * Store 18 ("Fresh Mutton") has:
     *   CategoryGroup 37 ("Fresh Mutton")
     *     SubCatGroup 35 ("Mutton")       → cat 90 (Mutton parent)
     *     SubCatGroup 45 ("Raw Mutton")   → cats 120(Brain),121(Head),123(Liver 1kg),124(Liver 500g),127(Curry Cut Bone+Boneless),128(Curry Cut Boneless)
     *     SubCatGroup 86 ("Mutton")       → same cats as 45
     *
     * Run: php artisan db:seed --class=Store18ProductSeeder
     */
    public function run(): void
    {
        // category_id → [category_group_id, sub_category_group_id]
        $catMapping = [
            90  => [37, 35],  // Mutton (parent)
            120 => [37, 45],  // Mutton Brain
            121 => [37, 45],  // Mutton Head
            123 => [37, 45],  // Mutton Liver 1kg
            124 => [37, 45],  // Mutton Liver 500g
            127 => [37, 45],  // Mutton Curry Cut (Bone+Boneless)
            128 => [37, 45],  // Mutton Curry Cut (Boneless)
        ];

        $products = [
            // ── Mutton Curry Cut Bone+Boneless (cat 127) ──
            [
                'category_id' => 127, 'item_type_id' => null,
                'name' => 'Mutton Curry Cut Mixed 1kg', 'description' => 'Fresh mutton curry cut with bone and boneless pieces. Ideal for rich curries.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 750, 'disc_price' => 700, 'stock' => 30, 'unit_id' => 1,
            ],
            [
                'category_id' => 127, 'item_type_id' => null,
                'name' => 'Mutton Curry Cut Mixed 500g', 'description' => 'Fresh mutton curry cut with bone and boneless, half kg pack.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 390, 'disc_price' => 365, 'stock' => 40, 'unit_id' => 2,
            ],
            [
                'category_id' => 127, 'item_type_id' => null,
                'name' => 'Mutton Curry Cut Mixed 250g', 'description' => 'Fresh mutton curry cut with bone and boneless, quarter kg trial pack.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 250, 'price' => 210, 'disc_price' => 195, 'stock' => 50, 'unit_id' => 2,
            ],

            // ── Mutton Curry Cut Boneless (cat 128) ──
            [
                'category_id' => 128, 'item_type_id' => null,
                'name' => 'Mutton Boneless 1kg', 'description' => 'Premium boneless mutton, tender and lean. Great for kebabs and korma.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 900, 'disc_price' => 850, 'stock' => 25, 'unit_id' => 1,
            ],
            [
                'category_id' => 128, 'item_type_id' => null,
                'name' => 'Mutton Boneless 500g', 'description' => 'Premium boneless mutton, half kg. Perfect for quick keema and stir-fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 470, 'disc_price' => 440, 'stock' => 35, 'unit_id' => 2,
            ],

            // ── Mutton Brain (cat 120) ──
            [
                'category_id' => 120, 'item_type_id' => null,
                'name' => 'Mutton Brain Fresh', 'description' => 'Fresh mutton brain, cleaned and ready to cook. Delicacy for bheja fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 250, 'price' => 180, 'disc_price' => 160, 'stock' => 20, 'unit_id' => 2,
            ],
            [
                'category_id' => 120, 'item_type_id' => null,
                'name' => 'Mutton Brain Pack of 2', 'description' => 'Two fresh mutton brains, cleaned. Rich and creamy texture for masala fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 2, 'price' => 320, 'disc_price' => 290, 'stock' => 15, 'unit_id' => 3,
            ],

            // ── Mutton Head (cat 121) ──
            [
                'category_id' => 121, 'item_type_id' => null,
                'name' => 'Mutton Head Full', 'description' => 'Full mutton head, cleaned and fired. Traditional delicacy for nihari.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 350, 'disc_price' => 320, 'stock' => 15, 'unit_id' => 3,
            ],
            [
                'category_id' => 121, 'item_type_id' => null,
                'name' => 'Mutton Head Half', 'description' => 'Half mutton head, cleaned. Perfect for soup and paya preparation.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 200, 'disc_price' => 180, 'stock' => 20, 'unit_id' => 3,
            ],

            // ── Mutton Liver 1kg (cat 123) ──
            [
                'category_id' => 123, 'item_type_id' => null,
                'name' => 'Mutton Liver Fresh 1kg', 'description' => 'Fresh mutton liver, rich in iron and vitamins. Ideal for liver fry and masala.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 400, 'disc_price' => 370, 'stock' => 25, 'unit_id' => 1,
            ],

            // ── Mutton Liver 500g (cat 124) ──
            [
                'category_id' => 124, 'item_type_id' => null,
                'name' => 'Mutton Liver Fresh 500g', 'description' => 'Fresh mutton liver half kg, cleaned and ready. Quick cook for weeknight meal.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 220, 'disc_price' => 200, 'stock' => 30, 'unit_id' => 2,
            ],

            // ── Mutton parent (cat 90) ──
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Keema 1kg', 'description' => 'Fresh mutton mince (keema), fine ground. Perfect for seekh kebab and kofta curry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 850, 'disc_price' => 800, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Keema 500g', 'description' => 'Fresh mutton mince half kg. Great for keema pav and stuffed paratha.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 440, 'disc_price' => 415, 'stock' => 30, 'unit_id' => 2,
            ],
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Ribs 1kg', 'description' => 'Fresh mutton ribs with bone. Excellent for slow-cooked ribs and barbecue.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 780, 'disc_price' => 730, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Shoulder 1kg', 'description' => 'Mutton shoulder cut with bone, tender and juicy. Best for slow-cooked rogan josh.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 720, 'disc_price' => 680, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Paya 4 Pieces', 'description' => 'Fresh mutton trotters (paya), set of 4. Traditional recipe for paya soup.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 4, 'price' => 200, 'disc_price' => 180, 'stock' => 25, 'unit_id' => 3,
            ],
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Chops 500g', 'description' => 'Fresh mutton chops, individually cut. Perfect for tandoori chops and grilling.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 480, 'disc_price' => 450, 'stock' => 25, 'unit_id' => 2,
            ],
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Leg Whole', 'description' => 'Full mutton leg with bone. Ideal for roasting and festive raan preparation.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 800, 'disc_price' => 750, 'stock' => 15, 'unit_id' => 1,
            ],
            [
                'category_id' => 90, 'item_type_id' => null,
                'name' => 'Mutton Boti Cut 1kg', 'description' => 'Mutton boti pieces, small cubed cuts with bone. Great for spicy boti masala.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 760, 'disc_price' => 710, 'stock' => 25, 'unit_id' => 1,
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
                $product->store_id               = 18;
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
            $this->command->info("Seeded {$count} products with variants for Store 18 (admin-managed).");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Seeder failed: " . $e->getMessage());
            Log::error('Store18ProductSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
