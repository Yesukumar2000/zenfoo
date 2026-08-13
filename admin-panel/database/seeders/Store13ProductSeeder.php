<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Store13ProductSeeder extends Seeder
{
    /**
     * Seed 20 products for store_id = 13 (admin-managed, no seller).
     *
     * Hierarchy: Store → CategoryGroup → SubCategoryGroup → Category
     *
     * Store 13 ("Vegetables & Fruits") has:
     *   CategoryGroup 3 ("Vegetables")
     *     SubCatGroup 17 ("Pudina")      → cat 72
     *     SubCatGroup 18 ("Tomato")      → cat 70
     *     SubCatGroup 19 ("Potato")      → cat 71
     *     SubCatGroup 20 ("Cabbage")     → cat 73
     *     SubCatGroup 21 ("Spinach")     → cat 74
     *     SubCatGroup 22 ("Carrot")      → cat 75
     *     SubCatGroup 23 ("Onion")       → cat 76
     *     SubCatGroup 24 ("Thotakura")   → cat 77
     *   CategoryGroup 8 ("Fruits")
     *     SubCatGroup 25 ("Apple")       → cat 78
     *     SubCatGroup 26 ("Banana")      → cat 79
     *     SubCatGroup 27 ("Papaya")      → cat 80
     *     SubCatGroup 28 ("Orange")      → cat 81
     *     SubCatGroup 29 ("Grapes")      → cat 82
     *     SubCatGroup 30 ("Pineapple")   → cat 83
     *     SubCatGroup 31 ("Watermelon")  → cat 84
     *     SubCatGroup 32 ("Guava")       → cat 85
     *
     * Run: php artisan db:seed --class=Store13ProductSeeder
     */
    public function run(): void
    {
        // category_id → [category_group_id, sub_category_group_id]
        $catMapping = [
            70 => [3, 18],  // Tomato
            71 => [3, 19],  // Potato
            72 => [3, 17],  // Pudina
            73 => [3, 20],  // Cabbage
            74 => [3, 21],  // Spinach
            75 => [3, 22],  // Carrot
            76 => [3, 23],  // Onion
            77 => [3, 24],  // Thotakura
            78 => [8, 25],  // Apple
            79 => [8, 26],  // Banana
            80 => [8, 27],  // Papaya
            81 => [8, 28],  // Orange
            82 => [8, 29],  // Grapes
            83 => [8, 30],  // Pineapple
            84 => [8, 31],  // Watermelon
            85 => [8, 32],  // Guava
        ];

        $products = [
            // ── Vegetables ──

            // Tomato (cat 70)
            [
                'category_id' => 70, 'item_type_id' => null,
                'name' => 'Fresh Tomato Local', 'description' => 'Locally grown ripe tomatoes, juicy and tangy. Essential for every kitchen.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 40, 'disc_price' => 35, 'stock' => 500, 'unit_id' => 1,
            ],
            [
                'category_id' => 70, 'item_type_id' => null,
                'name' => 'Hybrid Tomato', 'description' => 'Firm hybrid tomatoes, perfect for salads and sandwiches.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 500, 'price' => 25, 'disc_price' => 22, 'stock' => 300, 'unit_id' => 2,
            ],

            // Potato (cat 71)
            [
                'category_id' => 71, 'item_type_id' => null,
                'name' => 'Fresh Potato Medium', 'description' => 'Farm fresh medium-sized potatoes. Versatile for curries, fries and sabzi.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 32, 'disc_price' => 28, 'stock' => 400, 'unit_id' => 1,
            ],

            // Onion (cat 76)
            [
                'category_id' => 76, 'item_type_id' => null,
                'name' => 'Onion Red Medium', 'description' => 'Fresh red onions, medium size. Staple ingredient for Indian cooking.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 38, 'disc_price' => 32, 'stock' => 600, 'unit_id' => 1,
            ],
            [
                'category_id' => 76, 'item_type_id' => null,
                'name' => 'White Onion', 'description' => 'Mild and sweet white onions. Great for raitas and salads.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 500, 'price' => 30, 'disc_price' => 25, 'stock' => 200, 'unit_id' => 2,
            ],

            // Cabbage (cat 73)
            [
                'category_id' => 73, 'item_type_id' => null,
                'name' => 'Green Cabbage', 'description' => 'Fresh green cabbage, crisp and crunchy. Perfect for salads, stir-fry and coleslaw.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 30, 'disc_price' => 25, 'stock' => 150, 'unit_id' => 3,
            ],

            // Spinach (cat 74)
            [
                'category_id' => 74, 'item_type_id' => null,
                'name' => 'Palak (Spinach) Bunch', 'description' => 'Fresh spinach leaves, rich in iron and vitamins. Great for palak paneer.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 20, 'disc_price' => 15, 'stock' => 200, 'unit_id' => 3,
            ],

            // Carrot (cat 75)
            [
                'category_id' => 75, 'item_type_id' => null,
                'name' => 'Carrot Orange', 'description' => 'Fresh orange carrots, sweet and crunchy. Rich in beta-carotene.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 500, 'price' => 35, 'disc_price' => 30, 'stock' => 250, 'unit_id' => 2,
            ],

            // Pudina (cat 72)
            [
                'category_id' => 72, 'item_type_id' => null,
                'name' => 'Pudina (Mint) Bunch', 'description' => 'Fresh mint leaves, aromatic and refreshing. Essential for chutneys and raita.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 10, 'disc_price' => 8, 'stock' => 300, 'unit_id' => 3,
            ],

            // Thotakura (cat 77)
            [
                'category_id' => 77, 'item_type_id' => null,
                'name' => 'Thotakura (Amaranth) Bunch', 'description' => 'Fresh amaranth greens, nutritious leafy vegetable popular in Andhra cuisine.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 15, 'disc_price' => 12, 'stock' => 150, 'unit_id' => 3,
            ],

            // Potato (cat 71) - second variant
            [
                'category_id' => 71, 'item_type_id' => null,
                'name' => 'Baby Potato', 'description' => 'Small baby potatoes, ideal for dum aloo and roasted preparations.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 500, 'price' => 40, 'disc_price' => 35, 'stock' => 200, 'unit_id' => 2,
            ],

            // ── Fruits ──

            // Banana (cat 79)
            [
                'category_id' => 79, 'item_type_id' => null,
                'name' => 'Banana Robusta', 'description' => 'Robusta bananas, ripe and ready to eat. Rich in potassium.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 6, 'price' => 40, 'disc_price' => 35, 'stock' => 200, 'unit_id' => 3,
            ],
            [
                'category_id' => 79, 'item_type_id' => null,
                'name' => 'Banana Yelakki', 'description' => 'Small sweet elaichi bananas. Fragrant and naturally sweet.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 12, 'price' => 50, 'disc_price' => 45, 'stock' => 150, 'unit_id' => 3,
            ],

            // Apple (cat 78)
            [
                'category_id' => 78, 'item_type_id' => null,
                'name' => 'Apple Shimla', 'description' => 'Fresh Shimla apples, red and juicy. Rich in fiber and antioxidants.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 180, 'disc_price' => 160, 'stock' => 100, 'unit_id' => 1,
            ],

            // Papaya (cat 80)
            [
                'category_id' => 80, 'item_type_id' => null,
                'name' => 'Papaya Ripe', 'description' => 'Ripe papaya, sweet orange flesh. Good source of vitamin C and digestive enzymes.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 45, 'disc_price' => 38, 'stock' => 80, 'unit_id' => 3,
            ],

            // Orange (cat 81)
            [
                'category_id' => 81, 'item_type_id' => null,
                'name' => 'Orange Nagpur', 'description' => 'Famous Nagpur oranges, sweet and juicy. Packed with vitamin C.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 80, 'disc_price' => 70, 'stock' => 120, 'unit_id' => 1,
            ],

            // Grapes (cat 82)
            [
                'category_id' => 82, 'item_type_id' => null,
                'name' => 'Green Grapes Seedless', 'description' => 'Sweet seedless green grapes. Refreshing and perfect for snacking.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 500, 'price' => 65, 'disc_price' => 55, 'stock' => 100, 'unit_id' => 2,
            ],

            // Pineapple (cat 83)
            [
                'category_id' => 83, 'item_type_id' => null,
                'name' => 'Pineapple Fresh', 'description' => 'Ripe tropical pineapple, sweet and tangy. Rich in bromelain enzymes.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 50, 'disc_price' => 42, 'stock' => 60, 'unit_id' => 3,
            ],

            // Watermelon (cat 84)
            [
                'category_id' => 84, 'item_type_id' => null,
                'name' => 'Watermelon Kiran', 'description' => 'Sweet and juicy watermelon. Perfect summer fruit, high water content.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 1, 'price' => 40, 'disc_price' => 35, 'stock' => 50, 'unit_id' => 3,
            ],

            // Guava (cat 85)
            [
                'category_id' => 85, 'item_type_id' => null,
                'name' => 'Guava Thailand Pink', 'description' => 'Thai pink guava, crisp and aromatic. High in vitamin C and fiber.',
                'type' => 'loose', 'indicator' => 1, 'measurement' => 500, 'price' => 60, 'disc_price' => 50, 'stock' => 100, 'unit_id' => 2,
            ],
        ];

        DB::beginTransaction();
        try {
            $count = 0;
            foreach ($products as $pd) {
                $catId  = $pd['category_id'];
                $map    = $catMapping[$catId] ?? [null, null];
                $cgId   = $map[0]; // category_group_id
                $scgId  = $map[1]; // sub_category_group_id

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
                $product->store_id               = 13;
                $product->seller_id              = null; // admin-managed
                $product->type                   = $pd['type'];
                $product->indicator              = $pd['indicator'];
                $product->is_unlimited_stock     = 0;
                $product->fssai_lic_no           = ' ';
                $product->total_allowed_quantity = 100;
                $product->cancelable_status      = 1;
                $product->till_status            = 3; // Processed
                $product->return_status          = 1;
                $product->return_days            = 7;
                $product->is_approved            = 1;
                $product->status                 = 1;
                $product->cod_allowed            = 1;
                $product->image                  = '';
                $product->save();

                // One variant per product
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
            $this->command->info("Seeded {$count} products with variants for Store 13 (admin-managed).");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Seeder failed: " . $e->getMessage());
            Log::error('Store13ProductSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
