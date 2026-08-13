<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Store14ProductSeeder extends Seeder
{
    /**
     * Seed 20 products for store_id = 14 (admin-managed, no seller).
     *
     * Store 14 ("Chicken & Eggs") has:
     *   CategoryGroup 9 ("Fresh Meat")
     *     SubCatGroup 33 ("Chicken & Eggs")
     *       cat 86 (Chicken) → children: 108(Biryani Cut),109(Curry Cut),111(Chest),113(Leg),115(Starter Cut),116(Full Bird Skinless),117(Full Bird Skin)
     *       cat 87 (Eggs)
     *
     * Run: php artisan db:seed --class=Store14ProductSeeder
     */
    public function run(): void
    {
        // category_id → [category_group_id, sub_category_group_id]
        $catMapping = [
            86  => [9, 33],  // Chicken
            87  => [9, 33],  // Eggs
            108 => [9, 33],  // Chicken Biryani Cut
            109 => [9, 33],  // Chicken Curry Cut
            111 => [9, 33],  // Chicken Chest Pieces
            113 => [9, 33],  // Chicken Leg Pieces
            115 => [9, 33],  // Chicken Starter Cut
            116 => [9, 33],  // Chicken Full Bird (Skinless)
            117 => [9, 33],  // Chicken Full Bird (Skin)
        ];

        $products = [
            // ── Chicken Biryani Cut (cat 108) ──
            [
                'category_id' => 108, 'item_type_id' => null,
                'name' => 'Chicken Biryani Cut 1kg', 'description' => 'Skinless biryani cut pieces, perfect size for biryani and pulao.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 280, 'disc_price' => 260, 'stock' => 50, 'unit_id' => 1,
            ],
            [
                'category_id' => 108, 'item_type_id' => null,
                'name' => 'Chicken Biryani Cut 500g', 'description' => 'Skinless biryani cut pieces, half kg pack for small servings.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 150, 'disc_price' => 140, 'stock' => 80, 'unit_id' => 2,
            ],

            // ── Chicken Curry Cut (cat 109) ──
            [
                'category_id' => 109, 'item_type_id' => null,
                'name' => 'Chicken Curry Cut 1kg', 'description' => 'Skinless curry cut pieces with bone. Ideal for chicken curry and gravy.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 270, 'disc_price' => 250, 'stock' => 60, 'unit_id' => 1,
            ],
            [
                'category_id' => 109, 'item_type_id' => null,
                'name' => 'Chicken Curry Cut 500g', 'description' => 'Skinless curry cut pieces, half kg pack for everyday cooking.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 145, 'disc_price' => 135, 'stock' => 80, 'unit_id' => 2,
            ],

            // ── Chicken Chest Pieces (cat 111) ──
            [
                'category_id' => 111, 'item_type_id' => null,
                'name' => 'Chicken Breast Boneless 1kg', 'description' => 'Skinless boneless chicken breast. High protein, great for grilling and salads.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 350, 'disc_price' => 320, 'stock' => 40, 'unit_id' => 1,
            ],
            [
                'category_id' => 111, 'item_type_id' => null,
                'name' => 'Chicken Breast Boneless 500g', 'description' => 'Skinless boneless chicken breast, half kg. Perfect for stir-fry and wraps.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 185, 'disc_price' => 170, 'stock' => 60, 'unit_id' => 2,
            ],

            // ── Chicken Leg Pieces (cat 113) ──
            [
                'category_id' => 113, 'item_type_id' => null,
                'name' => 'Chicken Leg Piece 1kg', 'description' => 'Chicken leg pieces with skin and bone. Juicy and flavorful for tandoori.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 290, 'disc_price' => 270, 'stock' => 50, 'unit_id' => 1,
            ],
            [
                'category_id' => 113, 'item_type_id' => null,
                'name' => 'Chicken Drumstick 500g', 'description' => 'Fresh chicken drumsticks. Great for frying, roasting and lollipop preparation.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 155, 'disc_price' => 145, 'stock' => 70, 'unit_id' => 2,
            ],

            // ── Chicken Starter Cut (cat 115) ──
            [
                'category_id' => 115, 'item_type_id' => null,
                'name' => 'Chicken Starter Cut 1kg', 'description' => 'Skinless starter cut pieces. Perfect for 65, manchurian and crispy fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 310, 'disc_price' => 290, 'stock' => 40, 'unit_id' => 1,
            ],
            [
                'category_id' => 115, 'item_type_id' => null,
                'name' => 'Chicken Starter Cut 500g', 'description' => 'Skinless starter cut pieces, half kg. Ideal for quick snacks and appetizers.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 165, 'disc_price' => 155, 'stock' => 60, 'unit_id' => 2,
            ],

            // ── Chicken Full Bird Skinless (cat 116) ──
            [
                'category_id' => 116, 'item_type_id' => null,
                'name' => 'Full Chicken Skinless', 'description' => 'Whole chicken cleaned and skinless. Ready for roasting or full bird curry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 260, 'disc_price' => 240, 'stock' => 30, 'unit_id' => 1,
            ],

            // ── Chicken Full Bird Skin (cat 117) ──
            [
                'category_id' => 117, 'item_type_id' => null,
                'name' => 'Full Chicken With Skin', 'description' => 'Whole chicken with skin, cleaned and dressed. Great for roasting and grilling.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 250, 'disc_price' => 230, 'stock' => 30, 'unit_id' => 1,
            ],

            // ── Chicken parent category (cat 86) ──
            [
                'category_id' => 86, 'item_type_id' => null,
                'name' => 'Chicken Keema 1kg', 'description' => 'Fresh chicken mince (keema), skinless and boneless. Perfect for kebabs and kofta.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 330, 'disc_price' => 300, 'stock' => 40, 'unit_id' => 1,
            ],
            [
                'category_id' => 86, 'item_type_id' => null,
                'name' => 'Chicken Keema 500g', 'description' => 'Fresh chicken mince, half kg. Great for quick kebab and paratha stuffing.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 175, 'disc_price' => 160, 'stock' => 50, 'unit_id' => 2,
            ],
            [
                'category_id' => 86, 'item_type_id' => null,
                'name' => 'Chicken Wings 1kg', 'description' => 'Fresh chicken wings, ideal for buffalo wings, grilling and deep frying.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 240, 'disc_price' => 220, 'stock' => 50, 'unit_id' => 1,
            ],
            [
                'category_id' => 86, 'item_type_id' => null,
                'name' => 'Chicken Liver 500g', 'description' => 'Fresh chicken liver, cleaned. Rich in iron, great for fry and masala.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 120, 'disc_price' => 100, 'stock' => 40, 'unit_id' => 2,
            ],

            // ── Eggs (cat 87) ──
            [
                'category_id' => 87, 'item_type_id' => null,
                'name' => 'Farm Eggs Pack of 6', 'description' => 'Farm fresh brown eggs, pack of 6. Rich in protein and omega-3.',
                'type' => 'packet', 'indicator' => 2, 'measurement' => 6, 'price' => 54, 'disc_price' => 48, 'stock' => 200, 'unit_id' => 3,
            ],
            [
                'category_id' => 87, 'item_type_id' => null,
                'name' => 'Farm Eggs Pack of 12', 'description' => 'Farm fresh brown eggs, dozen pack. Everyday protein at best value.',
                'type' => 'packet', 'indicator' => 2, 'measurement' => 12, 'price' => 96, 'disc_price' => 84, 'stock' => 150, 'unit_id' => 3,
            ],
            [
                'category_id' => 87, 'item_type_id' => null,
                'name' => 'Farm Eggs Pack of 30', 'description' => 'Farm fresh brown eggs, tray of 30. Best value bulk pack for families.',
                'type' => 'packet', 'indicator' => 2, 'measurement' => 30, 'price' => 220, 'disc_price' => 195, 'stock' => 80, 'unit_id' => 3,
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
                $product->store_id               = 14;
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
            $this->command->info("Seeded {$count} products with variants for Store 14 (admin-managed).");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Seeder failed: " . $e->getMessage());
            Log::error('Store14ProductSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
