<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Category;
use App\Models\CategoryGroup;
use App\Models\CategorySubGroup;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Seller;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * DYNAMIC catalogue seeder for a "Dmart" super-mart seller.
 *
 * Instead of a hardcoded product list, this generates products programmatically
 * from a compact catalogue spec:  category → { brands × types × sizes }.
 * Each (brand × type) becomes a Product; each size becomes a ProductVariant.
 * Prices/discounts/stock are derived, not typed out.
 *
 * It also fills the data the customer "browse" screen needs to look like the
 * Dmart mockup:
 *   - sub-group categories  → the category filter chips (Ghee, Sunflower, …)
 *   - category_types         → the "Filters by Type" chips (Cow Ghee, Premium…)
 *   - brands.category_ids    → the "Shop By Brands" strip (Amul, Patanjali, …)
 *   - product_variants.measurement/unit → the size dropdown (500 g, 1 L, …)
 *
 * Portability: seller / store / city / brands / units are resolved BY NAME, so
 * it runs on any environment. Brands that don't exist are created.
 *
 * Cleanup: removes the seller's OLD category groups that aren't part of this
 * catalogue (e.g. leftover test groups) so the store search lands on the real
 * catalogue, and clears previously seeded products (marked by MARKER).
 *
 * Images are intentionally left blank for now.
 *
 * Run: php artisan db:seed --class=SuperMartDmartSeeder
 */
class SuperMartDmartSeeder extends Seeder
{
    /* ───────── CONFIG (edit for the live server) ───────── */
    private const SELLER_NAME      = 'Super Mart Dmart';
    private const SELLER_NAME_LIKE = 'Dmart';
    private const CITY_NAME        = 'Hyderabad';
    /* ───────────────────────────────────────────────────── */

    /** Marks seeder-created products so re-runs can clean only their own rows. */
    private const MARKER = 'ZENFO_SEED';

    /** Size presets: [label, measurement, unitName, priceFactor]. */
    private array $sizes = [
        'GRAIN' => [['500 g', 500, 'Grams', 0.6], ['1 Kg', 1, 'Kilogram', 1.0], ['5 Kg', 5, 'Kilogram', 4.6]],
        'OIL'   => [['500 ml', 500, 'Millilitre', 0.55], ['1 L', 1, 'Litre', 1.0]],
        'GHEE'  => [['500 g', 500, 'Grams', 0.55], ['1 L', 1, 'Litre', 1.05]],
        'SPICE' => [['100 g', 100, 'Grams', 1.0], ['200 g', 200, 'Grams', 1.9]],
        'BEV'   => [['250 g', 250, 'Grams', 1.0], ['500 g', 500, 'Grams', 1.9]],
        'MILK'  => [['500 ml', 500, 'Millilitre', 0.55], ['1 L', 1000, 'Millilitre', 1.0]],
        'SNACK' => [['100 g', 100, 'Grams', 1.0], ['200 g', 200, 'Grams', 1.9]],
        'DRINK' => [['750 ml', 750, 'Millilitre', 1.0], ['1 L', 1, 'Litre', 1.25]],
        'EGG'   => [['6 pcs', 1, 'Half Dozen', 1.0], ['12 pcs', 1, 'Dozen', 1.9]],
        'LOAF'  => [['400 g', 1, 'Packet', 1.0]],
    ];

    /** Per-category Unsplash photo IDs (real grocery photos, fast images.unsplash.com CDN). */
    private array $catImageId = [
        'Atta'          => '1586201375761-83865001e31c',
        'Rice'          => '1586201375761-83865001e31c',
        'Dal'           => '1552585960-0e1069ce7405',
        'Ghee'          => '1573812461383-e5f8b759d12e',
        'Sunflower Oil' => '1642140027864-07cb8cb59cd9',
        'Mustard Oil'   => '1642140027864-07cb8cb59cd9',
        'Groundnut Oil' => '1642140027864-07cb8cb59cd9',
        'Masala'        => '1716816211590-c15a328a5ff0',
        'Turmeric'      => '1716816211590-c15a328a5ff0',
        'Tea'           => '1610478506025-8110cc8f1986',
        'Coffee'        => '1447933601403-0c6688de566e',
        'Milk & Dairy'  => '1634141510639-d691d86f47be',
        'Bread'         => '1598373182133-52452f7691ef',
        'Eggs'          => '1498654077810-12c21d4d6dc3',
        'Biscuits'      => '1558961363-fa8fdf82db35',
        'Chips'         => '1590165482129-1b8b27698780',
        'Namkeen'       => '1590165482129-1b8b27698780',
        'Cold Drinks'   => '1554866585-cd94860890b7',
        'Juices'        => '1603569283847-aa295f0d016a',
    ];

    /** Builds a lightweight (w=500) image URL for a category.
     *  Uses fm=jpg (NOT auto=format): with auto=format Unsplash serves AVIF to
     *  clients that accept it, which Flutter can't decode (tiles show blank). */
    private function imageForCat(string $cat): string
    {
        $id = $this->catImageId[$cat] ?? '1586201375761-83865001e31c'; // grocery fallback
        return "https://images.unsplash.com/photo-{$id}?w=500&q=70&fm=jpg&fit=crop";
    }

    /**
     * Catalogue spec.
     *   group => [ subGroup => [ category => [brands, types, size-preset, base-price] ] ]
     */
    private function catalogue(): array
    {
        return [
            'Groceries & Kitchen' => [
                'Atta, Rice & Dal' => [
                    'Atta'  => [['Aashirvaad', 'Fortune', 'Pillsbury'], ['Whole Wheat', 'Multigrain', 'Chakki Fresh'], 'GRAIN', 60],
                    'Rice'  => [['India Gate', 'Daawat', 'Fortune'], ['Basmati', 'Sona Masoori', 'Brown'], 'GRAIN', 90],
                    'Dal'   => [['Tata Sampann', 'Fortune'], ['Toor', 'Chana', 'Moong'], 'GRAIN', 110],
                ],
                'Oil & Ghee' => [
                    'Ghee'          => [['Amul', 'Patanjali', 'GRB'], ['Cow Ghee', 'Buffalo Ghee', 'Premium Ghee'], 'GHEE', 300],
                    'Sunflower Oil' => [['Fortune', 'Gold Drop'], ['Refined'], 'OIL', 150],
                    'Mustard Oil'   => [['Fortune', 'Patanjali'], ['Kachi Ghani'], 'OIL', 160],
                    'Groundnut Oil' => [['Fortune', 'Gold Drop'], ['Filtered'], 'OIL', 180],
                ],
                'Masala & Spices' => [
                    'Masala'   => [['Tata Sampann', 'Everest', 'MDH'], ['Garam Masala', 'Chaat Masala'], 'SPICE', 70],
                    'Turmeric' => [['Everest', 'MDH'], ['Powder'], 'SPICE', 55],
                ],
                'Tea, Coffee & Milk' => [
                    'Tea'          => [['Tata Tea', 'Red Label', 'Taj Mahal'], ['Premium', 'Green Tea'], 'BEV', 130],
                    'Coffee'       => [['Bru', 'Nescafe'], ['Instant', 'Filter'], 'BEV', 180],
                    'Milk & Dairy' => [['Amul', 'Heritage'], ['Full Cream', 'Toned'], 'MILK', 30],
                ],
                'Bakery, Bread & Eggs' => [
                    'Bread'    => [['Britannia', 'Modern'], ['Brown', 'White'], 'LOAF', 45],
                    'Eggs'     => [['Farm Fresh'], ['White', 'Brown'], 'EGG', 60],
                    'Biscuits' => [['Parle', 'Britannia'], ['Glucose', 'Marie'], 'SNACK', 30],
                ],
            ],
            'Snacks & Drinks' => [
                'Chips & Namkeen' => [
                    'Chips'   => [['Lays', 'Bingo'], ['Salted', 'Masala'], 'SNACK', 20],
                    'Namkeen' => [['Haldiram', 'Bikaji'], ['Aloo Bhujia', 'Mixture'], 'SNACK', 50],
                ],
                'Cold Drinks & Juices' => [
                    'Cold Drinks' => [['Coca-Cola', 'Pepsi', 'Sprite'], ['Regular'], 'DRINK', 40],
                    'Juices'      => [['Real', 'Tropicana'], ['Mixed Fruit', 'Orange'], 'DRINK', 110],
                ],
            ],
        ];
    }

    public function run(): void
    {
        $seller = Seller::where('store_name', self::SELLER_NAME)->first()
            ?? Seller::where('name', self::SELLER_NAME)->first()
            ?? Seller::where('store_name', 'LIKE', '%' . self::SELLER_NAME_LIKE . '%')->orderBy('id')->first();

        if (!$seller) {
            $this->command->error("No seller matching '" . self::SELLER_NAME . "'. Aborting.");
            return;
        }

        $sellerId = $seller->id;
        $storeId  = $seller->store_id;
        $this->command->info("Target seller: #{$sellerId} '" . ($seller->store_name ?: $seller->name) . "' (store_id {$storeId}).");

        $cityId = DB::table('cities')->whereRaw('LOWER(name) = ?', [strtolower(self::CITY_NAME)])->value('id');

        // Unit name => id (case-insensitive)
        $unitByName = collect(DB::table('units')->get(['id', 'name']))
            ->mapWithKeys(fn ($u) => [strtolower(trim($u->name)) => $u->id]);
        $resolveUnit = fn (string $n) => $unitByName[strtolower($n)] ?? $unitByName['pieces'] ?? $unitByName->first();

        $catalogue = $this->catalogue();
        $groupNames = array_keys($catalogue);

        DB::beginTransaction();
        try {
            // Ensure the seller is reachable by the location-based browse filter.
            if (empty($seller->city_id) && $cityId) {
                $seller->city_id = $cityId;
                $seller->save();
                $this->command->info("Assigned seller #{$sellerId} to city '" . self::CITY_NAME . "' (#{$cityId}).");
            }

            // ── Cleanup: drop seller's old groups not in this catalogue + prior seeded products ──
            $oldGroups = CategoryGroup::where('seller_id', $sellerId)->whereNotIn('name', $groupNames)->get();
            foreach ($oldGroups as $g) {
                CategorySubGroup::where('category_group_id', $g->id)->delete();
            }
            $removedGroups = $oldGroups->count();
            CategoryGroup::where('seller_id', $sellerId)->whereNotIn('name', $groupNames)->delete();

            // 'Brand' = legacy marker from the earlier hardcoded version of this seeder.
            $priorIds = Product::where('seller_id', $sellerId)
                ->whereIn('manufacturer', [self::MARKER, 'Brand'])->pluck('id');
            if ($priorIds->isNotEmpty()) {
                ProductVariant::whereIn('product_id', $priorIds)->forceDelete();
                Product::whereIn('id', $priorIds)->forceDelete();
            }
            $this->command->info("Cleanup: removed {$removedGroups} old group(s) and " . $priorIds->count() . ' previously seeded product(s).');

            // ── Brand cache (created by name on demand) ──
            $brandId = [];
            $brandCats = []; // brandId => [categoryId, ...]  (for Shop By Brands)
            $brandIdFor = function (string $name) use (&$brandId) {
                $key = strtolower($name);
                if (!isset($brandId[$key])) {
                    $b = Brand::firstOrNew(['name' => $name]);
                    $b->status = 1;
                    $b->image = $b->image ?: '';
                    $b->save();
                    $brandId[$key] = $b->id;
                }
                return $brandId[$key];
            };

            $catRow = (int) (Category::where('seller_id', $sellerId)->max('row_order') ?? 0);
            $pRow   = (int) (Product::max('row_order') ?? 0);
            $productCount = 0;
            $variantCount = 0;

            $groupOrder = 0;
            foreach ($catalogue as $groupName => $subGroups) {
                $group = CategoryGroup::firstOrNew(['seller_id' => $sellerId, 'name' => $groupName]);
                $group->status        = 1;
                $group->is_super_mart = 1;
                $group->row_order     = $groupOrder++;
                $group->save();

                $subOrder = 0;
                foreach ($subGroups as $subName => $cats) {
                    // Create categories first to know their ids (for the CSV + chips)
                    $catIdsInOrder = [];
                    foreach ($cats as $catName => $_spec) {
                        $cat = Category::firstOrNew(['seller_id' => $sellerId, 'name' => $catName]);
                        $cat->status              = 1;
                        $cat->is_added_by_seller  = 1;
                        $cat->is_super_mart       = 1;
                        $cat->is_sweet_house_store = 0;
                        $cat->parent_id           = 0;
                        $cat->subtitle            = $catName;
                        $cat->slug                = $cat->slug ?: $this->slugify($catName);
                        $cat->image               = $cat->image ?: ''; // images untouched for now
                        if (!$cat->exists) {
                            $cat->row_order = ++$catRow;
                        }
                        $cat->save();
                        $catIdsInOrder[$catName] = $cat->id;
                    }

                    $sub = CategorySubGroup::firstOrNew(['seller_id' => $sellerId, 'name' => $subName]);
                    $sub->category_group_id   = $group->id;
                    $sub->subcategory_ids     = implode(',', array_values($catIdsInOrder));
                    $sub->is_group            = 1;
                    $sub->is_children_allowed = 1;
                    $sub->is_special_item     = 0;
                    $sub->is_super_mart       = 1;
                    $sub->row_order           = $subOrder++;
                    $sub->image               = $sub->image ?: '';
                    $sub->save();

                    // Products per category
                    foreach ($cats as $catName => $spec) {
                        [$brands, $types, $sizeKey, $base] = $spec;
                        $catId = $catIdsInOrder[$catName];
                        $sizeList = $this->sizes[$sizeKey];

                        // category_types -> "Filters by Type"
                        DB::table('category_types')->where('category_id', $catId)->delete();
                        $typeId = [];
                        foreach ($types as $t) {
                            $typeId[$t] = DB::table('category_types')->insertGetId([
                                'name' => $t, 'category_id' => $catId,
                                'created_at' => now(), 'updated_at' => now(),
                            ]);
                        }

                        foreach ($brands as $bi => $brandName) {
                            $bId = $brandIdFor($brandName);
                            $brandCats[$bId][$catId] = $catId;

                            foreach ($types as $ti => $typeName) {
                                // Append the category only when the name doesn't already imply it
                                // (avoids "Amul Cow Ghee Ghee" / "Tata Tea Premium Tea").
                                $name = trim("$brandName $typeName");
                                if (stripos($name, $catName) === false) {
                                    $name = trim("$name $catName");
                                }
                                $slug = $this->slugify($name);
                                $slugCount = Product::where('slug', 'LIKE', "{$slug}%")->count();

                                $product = new Product();
                                $product->name                  = $name;
                                $product->slug                  = $slugCount ? "{$slug}-{$slugCount}" : $slug;
                                $product->row_order             = ++$pRow;
                                $product->description           = "<p>{$name} — fresh stock, quality assured.</p>";
                                $product->category_id           = $catId;
                                $product->category_group_id     = $group->id;
                                $product->sub_category_group_id = $sub->id;
                                $product->item_type_id          = $typeId[$typeName];
                                $product->store_id              = $storeId;
                                $product->seller_id             = $sellerId;
                                $product->brand_id              = $bId;
                                $product->tags                  = "$brandName,$typeName,$catName";
                                $product->tax_id                = 0;
                                $product->tax                   = '0.00';
                                $product->type                  = 'packet';
                                $product->indicator             = 1;
                                $product->manufacturer          = self::MARKER;
                                $product->is_unlimited_stock    = 0;
                                $product->fssai_lic_no          = ' ';
                                $product->total_allowed_quantity = 100;
                                $product->cancelable_status     = 1;
                                $product->till_status           = 3;
                                $product->return_status         = 1;
                                $product->return_days           = 7;
                                $product->is_approved           = 1;
                                $product->status                = 1;
                                $product->cod_allowed           = 1;
                                $product->image                 = ''; // images untouched for now
                                $product->save();
                                $productCount++;

                                foreach ($sizeList as $si => [$label, $measure, $unitName, $factor]) {
                                    $price = (int) round($base * $factor * (1 + 0.04 * $bi + 0.06 * $ti) / 5) * 5;
                                    $price = max($price, 10);
                                    $disc  = (int) round($price * 0.80); // ~20% off, matches mockup
                                    $stock = 40 + (($productCount * 7 + $si * 13) % 160);

                                    $variant = new ProductVariant();
                                    $variant->product_id       = $product->id;
                                    $variant->type             = 'packet';
                                    $variant->measurement      = $measure;
                                    $variant->price            = $price;
                                    $variant->discounted_price = $disc;
                                    $variant->stock            = $stock;
                                    $variant->stock_unit_id    = $resolveUnit($unitName);
                                    $variant->status           = 1;
                                    $variant->save();
                                    $variantCount++;
                                }
                            }
                        }
                    }
                }
            }

            // ── Link brands to their categories so "Shop By Brands" shows them ──
            // The browse query uses FIND_IN_SET(category_id, brands.category_ids), which needs a
            // PLAIN CSV. The Brand model casts category_ids to 'array' (JSON), so we write the raw
            // column via the query builder to bypass the cast.
            foreach ($brandCats as $bId => $catSet) {
                $rawExisting = DB::table('brands')->where('id', $bId)->value('category_ids');
                $existing = array_filter(array_map('intval', preg_split('/[^0-9]+/', (string) $rawExisting)));
                $merged = array_values(array_unique(array_merge($existing, array_keys($catSet))));
                sort($merged);
                DB::table('brands')->where('id', $bId)->update(['category_ids' => implode(',', $merged)]);
            }

            DB::commit();
            $this->command->info("Seeded {$productCount} products / {$variantCount} variants across " . count($catalogue) . ' groups for seller #' . $sellerId . '.');
        } catch (\Exception $e) {
            DB::rollBack();
            $this->command->error('SuperMartDmartSeeder failed: ' . $e->getMessage());
            Log::error('SuperMartDmartSeeder failed', ['error' => $e->getMessage()]);
        }
    }

    private function slugify(string $name): string
    {
        $clean = preg_replace('/[^\p{L}\p{N} ]/u', '', $name);
        return preg_replace('/\s+/', '-', trim($clean));
    }
}
