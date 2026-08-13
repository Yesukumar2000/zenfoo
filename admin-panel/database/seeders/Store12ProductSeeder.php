<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class Store12ProductSeeder extends Seeder
{
    /**
     * Seed 35 products for store_id = 12 only (admin-managed, no seller).
     *
     * Hierarchy: Store → CategoryGroup → SubCategoryGroup → Category
     *
     * Store 12 ("Grocery & Kitchen") has:
     *   CategoryGroup 1 ("Groceries & Kitchen")
     *     SubCatGroup 2  ("Atta rice & Dal")        → cats 38,149,40,39,150,151
     *     SubCatGroup 3  ("Oils,Ghee & Massala")    → cats 41,42,43
     *     SubCatGroup 4  ("Tea, Coffee & Milk")     → cats 44,45,46
     *     SubCatGroup 5  ("Instant Food")           → cat 47
     *     SubCatGroup 6  ("Dry Fruits & Cereals")   → cats 48,49
     *     SubCatGroup 12 ("Dairy, Bread & Eggs")    → cats 60,61,62
     *     SubCatGroup 13 ("Bakery & Biscuits")      → cats 64,63
     *     SubCatGroup 16 ("Bottles & cups")         → cats 69,68
     *   CategoryGroup 2 ("Snacks & Drinks")
     *     SubCatGroup 7  ("Chips & Namkeen")        → cats 50,51
     *     SubCatGroup 8  ("Chocolates & Biscuits")  → cats 52,53
     *     SubCatGroup 9  ("Drinks & Juices")        → cats 54,55
     *
     * Run: php artisan db:seed --class=Store12ProductSeeder
     */
    public function run(): void
    {
        // category_id → [category_group_id, sub_category_group_id, store_id]
        $catMapping = [
            38  => [1, 2],   // Atta           → Groceries & Kitchen → Atta rice & Dal
            149 => [1, 2],   // Besan,Sooji    → Groceries & Kitchen → Atta rice & Dal
            39  => [1, 2],   // Rice           → Groceries & Kitchen → Atta rice & Dal
            126 => [1, 2],   // Basmati (child of Rice)
            40  => [1, 2],   // Dal            → Groceries & Kitchen → Atta rice & Dal
            150 => [1, 2],   // Rajma,Chhole   → Groceries & Kitchen → Atta rice & Dal
            151 => [1, 2],   // Millet & Flours→ Groceries & Kitchen → Atta rice & Dal
            41  => [1, 3],   // Oils           → Groceries & Kitchen → Oils,Ghee & Massala
            42  => [1, 3],   // Ghee           → Groceries & Kitchen → Oils,Ghee & Massala
            43  => [1, 3],   // Massala        → Groceries & Kitchen → Oils,Ghee & Massala
            44  => [1, 4],   // Tea            → Groceries & Kitchen → Tea, Coffee & Milk
            45  => [1, 4],   // Coffee         → Groceries & Kitchen → Tea, Coffee & Milk
            46  => [1, 4],   // Milk Drinks    → Groceries & Kitchen → Tea, Coffee & Milk
            47  => [1, 5],   // Instant Food   → Groceries & Kitchen → Instant Food
            48  => [1, 6],   // Dry Fruits     → Groceries & Kitchen → Dry Fruits & Cereals
            49  => [1, 6],   // Cereals        → Groceries & Kitchen → Dry Fruits & Cereals
            60  => [1, 12],  // Dairy          → Groceries & Kitchen → Dairy, Bread & Eggs
            61  => [1, 12],  // Bread          → Groceries & Kitchen → Dairy, Bread & Eggs
            62  => [1, 12],  // Eggs           → Groceries & Kitchen → Dairy, Bread & Eggs
            63  => [1, 13],  // Bakery         → Groceries & Kitchen → Bakery & Biscuits
            64  => [1, 13],  // Biscuits       → Groceries & Kitchen → Bakery & Biscuits
            68  => [1, 16],  // Bottles        → Groceries & Kitchen → Bottles & cups
            69  => [1, 16],  // Cups           → Groceries & Kitchen → Bottles & cups
            50  => [2, 7],   // Chips          → Snacks & Drinks → Chips & Namkeen
            51  => [2, 7],   // Namkeen        → Snacks & Drinks → Chips & Namkeen
            52  => [2, 8],   // Chocolates     → Snacks & Drinks → Chocolates & Biscuits
            53  => [2, 8],   // Biscuits       → Snacks & Drinks → Chocolates & Biscuits
            54  => [2, 9],   // Drinks         → Snacks & Drinks → Drinks & Juices
            55  => [2, 9],   // Juices         → Snacks & Drinks → Drinks & Juices
        ];

        $products = [
            // ── Atta rice & Dal (SubCatGroup 2) ──
            [
                'category_id' => 38, 'item_type_id' => 51,
                'name' => 'Rajdhani Besan', 'description' => 'Premium gram flour made from selected chana dal. Ideal for pakoras, kadhi and sweets.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 500, 'price' => 75, 'disc_price' => 65, 'stock' => 120, 'unit_id' => 2,
            ],
            [
                'category_id' => 38, 'item_type_id' => 52,
                'name' => 'Sooji Fine Grain', 'description' => 'Fine grain semolina (rava), perfect for upma, halwa and idli.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 55, 'disc_price' => 48, 'stock' => 200, 'unit_id' => 1,
            ],
            [
                'category_id' => 39, 'item_type_id' => null,
                'name' => 'Kolam Rice', 'description' => 'Short grain kolam rice, soft and sticky after cooking. Great for everyday meals.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 5, 'price' => 380, 'disc_price' => 350, 'stock' => 60, 'unit_id' => 1,
            ],
            [
                'category_id' => 39, 'item_type_id' => null,
                'name' => 'Brown Rice Organic', 'description' => 'Unpolished organic brown rice, high in fiber and nutrients.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 140, 'disc_price' => 125, 'stock' => 80, 'unit_id' => 1,
            ],
            [
                'category_id' => 40, 'item_type_id' => null,
                'name' => 'Chana Dal Premium', 'description' => 'Split bengal gram, rich in protein. Essential for dal fry and chana dal curry.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 130, 'disc_price' => 115, 'stock' => 150, 'unit_id' => 1,
            ],
            [
                'category_id' => 40, 'item_type_id' => null,
                'name' => 'Masoor Dal Red', 'description' => 'Red lentils, quick cooking and high in iron. Perfect for everyday dal.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 500, 'price' => 70, 'disc_price' => 62, 'stock' => 180, 'unit_id' => 2,
            ],

            // ── Besan, Sooji & Maida (cat 149) ──
            [
                'category_id' => 149, 'item_type_id' => null,
                'name' => 'Pillsbury Maida', 'description' => 'Refined wheat flour (maida), fine and smooth. Essential for naan, bread and pastries.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 52, 'disc_price' => 45, 'stock' => 150, 'unit_id' => 1,
            ],

            // ── Basmati Rice (cat 126, child of Rice 39) ──
            [
                'category_id' => 126, 'item_type_id' => null,
                'name' => 'India Gate Basmati Rice', 'description' => 'Premium aged basmati rice, extra long grain. Perfect for biryani and pulao.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 5, 'price' => 550, 'disc_price' => 499, 'stock' => 40, 'unit_id' => 1,
            ],

            // ── Rajma, Chhole & Others (cat 150) ──
            [
                'category_id' => 150, 'item_type_id' => null,
                'name' => 'Kabuli Chana White', 'description' => 'Premium white chickpeas for chhole, hummus and salads. High in protein.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 160, 'disc_price' => 140, 'stock' => 100, 'unit_id' => 1,
            ],

            // ── Millet & Other Flours (cat 151) ──
            [
                'category_id' => 151, 'item_type_id' => null,
                'name' => 'Ragi Flour (Finger Millet)', 'description' => 'Organic ragi flour, rich in calcium and iron. Great for ragi roti and porridge.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 500, 'price' => 85, 'disc_price' => 75, 'stock' => 80, 'unit_id' => 2,
            ],

            // ── Oils, Ghee & Massala (SubCatGroup 3) ──
            [
                'category_id' => 41, 'item_type_id' => null,
                'name' => 'Fortune Sunflower Oil', 'description' => 'Refined sunflower oil, light and heart-friendly. Suitable for all types of cooking.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 180, 'disc_price' => 165, 'stock' => 100, 'unit_id' => 7,
            ],
            [
                'category_id' => 41, 'item_type_id' => null,
                'name' => 'Cold Pressed Groundnut Oil', 'description' => 'Traditional cold pressed peanut oil, full of natural flavor and aroma.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 280, 'disc_price' => 255, 'stock' => 50, 'unit_id' => 7,
            ],
            [
                'category_id' => 42, 'item_type_id' => null,
                'name' => 'Amul Pure Ghee', 'description' => 'Made from fresh cream, rich aroma and golden color. Pure cow ghee.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 500, 'price' => 310, 'disc_price' => 290, 'stock' => 40, 'unit_id' => 8,
            ],
            [
                'category_id' => 43, 'item_type_id' => null,
                'name' => 'MDH Garam Masala', 'description' => 'Blend of aromatic spices. Adds perfect flavor to curries and biryanis.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 100, 'price' => 65, 'disc_price' => 58, 'stock' => 200, 'unit_id' => 2,
            ],
            [
                'category_id' => 43, 'item_type_id' => null,
                'name' => 'Everest Turmeric Powder', 'description' => 'Pure turmeric powder, bright yellow color and earthy flavor.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 200, 'price' => 48, 'disc_price' => 42, 'stock' => 250, 'unit_id' => 2,
            ],

            // ── Dry Fruits & Cereals (SubCatGroup 6) ──
            [
                'category_id' => 48, 'item_type_id' => null,
                'name' => 'California Almonds', 'description' => 'Premium quality whole california almonds. Rich in vitamin E and healthy fats.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 250, 'price' => 320, 'disc_price' => 289, 'stock' => 60, 'unit_id' => 2,
            ],
            [
                'category_id' => 48, 'item_type_id' => null,
                'name' => 'Cashew Whole W320', 'description' => 'Whole cashew nuts, W320 grade. Great for snacking, sweets and gravies.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 250, 'price' => 280, 'disc_price' => 250, 'stock' => 70, 'unit_id' => 2,
            ],

            // ── Cereals (cat 49) ──
            [
                'category_id' => 49, 'item_type_id' => null,
                'name' => 'Kelloggs Corn Flakes', 'description' => 'Crispy golden corn flakes, a healthy breakfast option with milk.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 475, 'price' => 220, 'disc_price' => 195, 'stock' => 80, 'unit_id' => 2,
            ],

            // ── Dairy, Bread & Eggs (SubCatGroup 12) ──
            [
                'category_id' => 60, 'item_type_id' => null,
                'name' => 'Amul Toned Milk', 'description' => 'Pasteurized toned milk, 500ml pouch. Fresh and nutritious.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 500, 'price' => 28, 'disc_price' => 0, 'stock' => 300, 'unit_id' => 8,
            ],
            [
                'category_id' => 61, 'item_type_id' => null,
                'name' => 'Harvest Gold Bread', 'description' => 'Fresh white sandwich bread, soft and fluffy. Perfect for toast and sandwiches.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 400, 'price' => 40, 'disc_price' => 35, 'stock' => 200, 'unit_id' => 2,
            ],
            [
                'category_id' => 62, 'item_type_id' => null,
                'name' => 'Country Eggs Pack of 6', 'description' => 'Farm fresh country eggs (desi), free range. Rich yolk and natural taste.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 6, 'price' => 60, 'disc_price' => 52, 'stock' => 150, 'unit_id' => 3,
            ],

            // ── Bakery & Biscuits (SubCatGroup 13) ──
            [
                'category_id' => 63, 'item_type_id' => null,
                'name' => 'Fruit Cake Slice', 'description' => 'Rich fruit cake with dry fruits and tutti-frutti. Fresh baked daily.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 250, 'price' => 80, 'disc_price' => 70, 'stock' => 60, 'unit_id' => 2,
            ],
            [
                'category_id' => 64, 'item_type_id' => null,
                'name' => 'Britannia Marie Gold', 'description' => 'Light and crispy marie biscuits. Perfect with tea and coffee.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 250, 'price' => 40, 'disc_price' => 35, 'stock' => 200, 'unit_id' => 2,
            ],

            // ── Bottles & Cups (SubCatGroup 16) ──
            [
                'category_id' => 68, 'item_type_id' => null,
                'name' => 'Milton Water Bottle 1L', 'description' => 'BPA-free plastic water bottle, leak-proof lid. Ideal for daily use.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 150, 'disc_price' => 130, 'stock' => 50, 'unit_id' => 3,
            ],
            [
                'category_id' => 69, 'item_type_id' => null,
                'name' => 'Paper Cups Pack of 50', 'description' => 'Disposable paper cups, 200ml. Great for parties and daily chai.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 50, 'price' => 60, 'disc_price' => 50, 'stock' => 100, 'unit_id' => 3,
            ],

            // ── Snacks: Chips & Namkeen (SubCatGroup 7) ──
            [
                'category_id' => 50, 'item_type_id' => null,
                'name' => 'Lays Classic Salted', 'description' => 'Classic salted potato chips, crispy and delicious. Party pack.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 130, 'price' => 50, 'disc_price' => 45, 'stock' => 250, 'unit_id' => 2,
            ],
            [
                'category_id' => 51, 'item_type_id' => null,
                'name' => 'Haldirams Aloo Bhujia', 'description' => 'Crispy potato noodle namkeen. Classic Indian tea-time snack.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 200, 'price' => 55, 'disc_price' => 48, 'stock' => 150, 'unit_id' => 2,
            ],

            // ── Snacks: Chocolates & Biscuits (SubCatGroup 8) ──
            [
                'category_id' => 52, 'item_type_id' => null,
                'name' => 'Cadbury Dairy Milk Silk', 'description' => 'Smooth and creamy milk chocolate bar. Irresistibly rich cocoa flavor.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 150, 'price' => 160, 'disc_price' => 145, 'stock' => 100, 'unit_id' => 2,
            ],
            [
                'category_id' => 53, 'item_type_id' => null,
                'name' => 'Parle-G Gold Biscuits', 'description' => 'Glucose biscuits enriched with vitamins. India\'s favourite biscuit.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 200, 'price' => 30, 'disc_price' => 25, 'stock' => 400, 'unit_id' => 2,
            ],

            // ── Tea, Coffee & Milk Drinks (SubCatGroup 4) ──
            [
                'category_id' => 44, 'item_type_id' => null,
                'name' => 'Tata Tea Gold', 'description' => '15% long leaf blend for rich aromatic cup of chai.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 500, 'price' => 280, 'disc_price' => 255, 'stock' => 100, 'unit_id' => 2,
            ],
            [
                'category_id' => 45, 'item_type_id' => null,
                'name' => 'Nescafe Classic Coffee', 'description' => 'Instant coffee powder, 100% pure coffee. Rich taste and aroma.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 200, 'price' => 350, 'disc_price' => 320, 'stock' => 80, 'unit_id' => 2,
            ],

            [
                'category_id' => 46, 'item_type_id' => null,
                'name' => 'Bournvita Health Drink', 'description' => 'Chocolate health drink powder with vitamins and minerals. Mix with hot or cold milk.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 500, 'price' => 240, 'disc_price' => 215, 'stock' => 80, 'unit_id' => 2,
            ],

            // ── Instant Food (SubCatGroup 5) ──
            [
                'category_id' => 47, 'item_type_id' => null,
                'name' => 'Maggi 2-Minute Noodles', 'description' => 'Instant masala noodles. Quick and tasty snack loved by all.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 420, 'price' => 56, 'disc_price' => 48, 'stock' => 300, 'unit_id' => 2,
            ],

            // ── Drinks & Juices (SubCatGroup 9) ──
            [
                'category_id' => 54, 'item_type_id' => null,
                'name' => 'Real Mango Juice', 'description' => 'Made from Alphonso mangoes. No added preservatives, rich mango flavor.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 99, 'disc_price' => 89, 'stock' => 120, 'unit_id' => 7,
            ],
            [
                'category_id' => 55, 'item_type_id' => null,
                'name' => 'Tropicana Orange Juice', 'description' => '100% orange juice, no added sugar. Fresh and tangy morning drink.',
                'type' => 'packet', 'indicator' => 1, 'measurement' => 1, 'price' => 110, 'disc_price' => 95, 'stock' => 100, 'unit_id' => 7,
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
                $product->store_id               = 12;
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
            $this->command->info("Seeded {$count} products with variants (admin-managed).");
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error("Seeder failed: " . $e->getMessage());
            Log::error('Store12ProductSeeder failed', ['error' => $e->getMessage()]);
        }
    }
}
