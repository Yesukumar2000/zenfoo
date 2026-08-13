<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Store20ProductSeeder extends Seeder
{
    /**
     * Seed 20 products for store_id = 20 (admin-managed, no seller).
     *
     * Store 20 ("Camel Meat") has:
     *   CategoryGroup 39 ("Camel Meat")
     *     SubCatGroup 85 ("Camel Meat") → cat 206 (Camel Meat)
     *
     * Run: php artisan db:seed --class=Store20ProductSeeder
     */
    public function run(): void
    {
        // category_id → [category_group_id, sub_category_group_id]
        $catMapping = [
            206 => [39, 85],  // Camel Meat
        ];

        $products = [
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Curry Cut 1kg', 'description' => 'Fresh camel meat curry cut with bone. Traditional cut for rich curries and stews.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 600, 'disc_price' => 560, 'stock' => 25, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Curry Cut 500g', 'description' => 'Fresh camel meat curry cut, half kg pack. Perfect for small family servings.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 320, 'disc_price' => 295, 'stock' => 30, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Boneless 1kg', 'description' => 'Premium boneless camel meat, lean and tender. Great for kebabs and grilling.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 750, 'disc_price' => 700, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Boneless 500g', 'description' => 'Premium boneless camel meat, half kg. Ideal for quick stir-fry and wraps.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 400, 'disc_price' => 370, 'stock' => 25, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Keema 1kg', 'description' => 'Fresh camel meat mince, fine ground. Perfect for seekh kebab and kofta.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 700, 'disc_price' => 650, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Keema 500g', 'description' => 'Fresh camel meat mince, half kg. Great for keema pav and stuffed preparations.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 370, 'disc_price' => 340, 'stock' => 25, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Ribs 1kg', 'description' => 'Camel ribs with bone, rich and flavorful. Slow cook for tender fall-off-bone ribs.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 650, 'disc_price' => 600, 'stock' => 15, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Shoulder 1kg', 'description' => 'Camel shoulder cut with bone. Excellent for slow-cooked stews and braises.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 620, 'disc_price' => 580, 'stock' => 15, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Leg Cut 1kg', 'description' => 'Fresh camel leg cut with bone. Premium cut for roasting and festive cooking.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 680, 'disc_price' => 630, 'stock' => 15, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Steak Cut 500g', 'description' => 'Thick camel steaks, boneless. Lean and healthy alternative for grilling.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 420, 'disc_price' => 390, 'stock' => 20, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Liver Fresh 500g', 'description' => 'Fresh camel liver, cleaned and sliced. Rich in iron, great for masala fry.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 250, 'disc_price' => 220, 'stock' => 20, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Liver Fresh 1kg', 'description' => 'Fresh camel liver, whole cleaned. Nutrient-dense organ meat for traditional recipes.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 450, 'disc_price' => 400, 'stock' => 15, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Biryani Cut 1kg', 'description' => 'Special biryani cut camel meat with bone. Perfect size pieces for camel biryani.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 640, 'disc_price' => 590, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Biryani Cut 500g', 'description' => 'Special biryani cut camel meat, half kg. Ideal for small batch biryani.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 340, 'disc_price' => 310, 'stock' => 25, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Hump Fat 500g', 'description' => 'Premium camel hump fat, rendered. Traditional cooking fat with unique flavor.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 300, 'disc_price' => 270, 'stock' => 15, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Chops 500g', 'description' => 'Fresh camel chops, bone-in. Marinate and grill for smoky barbecue flavor.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 500, 'price' => 380, 'disc_price' => 350, 'stock' => 20, 'unit_id' => 2,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Boti 1kg', 'description' => 'Small cubed camel boti pieces with bone. Great for spicy boti masala.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 610, 'disc_price' => 570, 'stock' => 20, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Tongue Fresh', 'description' => 'Fresh camel tongue, cleaned. Delicacy for slow-cooked traditional preparations.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 350, 'disc_price' => 320, 'stock' => 10, 'unit_id' => 3,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Shank 1kg', 'description' => 'Camel shank with bone and marrow. Ideal for slow-braised nihari and soups.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 550, 'disc_price' => 510, 'stock' => 15, 'unit_id' => 1,
            ],
            [
                'category_id' => 206, 'item_type_id' => null,
                'name' => 'Camel Meat Mixed Pack 1kg', 'description' => 'Mixed camel meat pack with assorted cuts. Value pack for family meals.',
                'type' => 'loose', 'indicator' => 2, 'measurement' => 1, 'price' => 580, 'disc_price' => 540, 'stock' => 20, 'unit_id' => 1,
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
                $product->store_id               = 20;
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
            $this->command->info("Seeded {$count} products with variants for Store 20 (admin-managed).");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Seeder failed: " . $e->getMessage());
            Log::error('Store20ProductSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
