<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

/**
 * Adds real products to the thin stores so the app looks stocked.
 *
 * Super Mart (994) and Grocery (459) are already full; Chicken & Meat (33),
 * Mutton (32), Fish (39), Camel (20) and Vegetables & Fruits (84) are not, and
 * a near-empty category is the first thing a client notices.
 *
 * Each item below is a real thing sold in an Indian quick-commerce store, with
 * its own English Wikipedia article — so every product gets a DISTINCT, correct
 * photo rather than the same stock image repeated down the grid.
 *
 * Placement piggybacks on what already works: each new product copies the
 * category / group / sub-group triple of an existing product in the same store,
 * so it lands somewhere the browse hierarchy already renders.
 *
 * Additive and reversible. Every row is tagged in products.manufacturer.
 *
 *   php artisan zenfoo:stock-up --dry-run
 *   php artisan zenfoo:stock-up
 *   php artisan zenfoo:stock-up --undo
 */
class StockUpStores extends Command
{
    protected $signature = 'zenfoo:stock-up
        {--dry-run : Report what would be added, add nothing}
        {--only= : Comma-separated store ids (default: all thin stores)}
        {--undo : Remove products this command added, then stop}';

    protected $description = 'Add real, distinctly-photographed products to the thin stores';

    public const MARKER = 'ZFDEMO_STOCKUP';

    private const UA = 'ZenfooCatalogSeeder/1.0 (kmadhu@techlanditsolutions.com)';

    /** Lead images that are plates or the living plant, not the product. */
    private const BOTANICAL_REJECT = [
        'illustration', 'medizinal', 'kohler', 'koehler', 'k%c3%b6hler', 'blanco',
        'drawing', 'engraving', 'lithograph', 'herbarium', 'botanical',
        'blossom', 'bloei', 'bloem', 'plantation', 'seedling',
    ];

    /**
     * store id => [ [display name, wikipedia title, ₹ per kg], ... ]
     *
     * Prices are indicative Indian retail per kg (per piece where the unit
     * makes more sense) — close enough to look right on a tile.
     */
    private function catalogue(): array
    {
        return [
            // ── Vegetables & Fruits ─────────────────────────────────────
            13 => [
                ['Ash Gourd', 'Winter melon', 35],
                ['Snake Gourd', 'Trichosanthes cucumerina', 45],
                ['Ivy Gourd', 'Coccinia grandis', 55],
                ['Pointed Gourd', 'Trichosanthes dioica', 65],
                ['Cluster Beans', 'Guar', 70],
                ['Broad Beans', 'Vicia faba', 80],
                ['Cowpea', 'Cowpea', 60],
                ['Turnip', 'Turnip', 45],
                ['Yam', 'Yam (vegetable)', 70],
                ['Colocasia', 'Taro', 55],
                ['Sweet Potato', 'Sweet potato', 50],
                ['Raw Banana', 'Cooking banana', 40],
                ['Green Chilli', 'Chili pepper', 90],
                ['Ginger', 'Ginger', 140],
                ['Garlic', 'Garlic', 190],
                ['Lemon', 'Lemon', 110],
                ['Pumpkin', 'Pumpkin', 30],
                ['Chow Chow', 'Chayote', 45],
                ['Red Cabbage', 'Red cabbage', 80],
                ['Brussels Sprout', 'Brussels sprout', 220],
                ['Kohlrabi', 'Kohlrabi', 60],
                ['Leek', 'Leek', 120],
                ['Bok Choy', 'Bok choy', 150],
                ['Asparagus', 'Asparagus', 380],
                ['Parsley', 'Parsley', 200],
                ['Basil', 'Basil', 220],
                ['Custard Apple', 'Sugar apple', 160],
                ['Sapota', 'Manilkara zapota', 90],
                ['Jackfruit', 'Jackfruit', 70],
                ['Litchi', 'Lychee', 220],
                ['Plum', 'Plum', 180],
                ['Peach', 'Peach', 200],
                ['Apricot', 'Apricot', 320],
                ['Fig', 'Fig', 280],
                ['Cherry', 'Cherry', 600],
                ['Blackberry', 'Blackberry', 450],
                ['Raspberry', 'Raspberry', 700],
                ['Coconut', 'Coconut', 55],
                ['Star Fruit', 'Carambola', 120],
                ['Passion Fruit', 'Passiflora edulis', 260],
                ['Mulberry', 'Morus (plant)', 300],
                ['Indian Gooseberry', 'Phyllanthus emblica', 110],
                ['Dates', 'Date palm', 240],
                ['Pomelo', 'Pomelo', 90],
                ['Guava Pink', 'Guava', 80],
            ],

            // ── Fish & Seafood ──────────────────────────────────────────
            19 => [
                ['Rohu', 'Rohu', 260],
                ['Catla', 'Catla', 250],
                ['Tilapia', 'Tilapia', 220],
                ['Pomfret', 'Pomfret', 700],
                ['Sardine', 'Sardine', 180],
                ['Anchovy', 'Anchovy', 200],
                ['Tuna', 'Tuna', 480],
                ['Salmon', 'Salmon', 1400],
                ['Basa', 'Pangasius', 320],
                ['Crab', 'Crab', 520],
                ['Squid', 'Squid', 420],
                ['Mussels', 'Mussel', 260],
                ['Clams', 'Clam', 240],
                ['Oyster', 'Oyster', 480],
                ['Lobster', 'Lobster', 1600],
                ['Red Snapper', 'Lutjanidae', 560],
                ['Barramundi', 'Barramundi', 620],
                ['Milkfish', 'Milkfish', 300],
                ['Mullet', 'Mullet (fish)', 280],
                ['Eel', 'Eel', 400],
            ],

            // ── Chicken & Meat ──────────────────────────────────────────
            14 => [
                ['Chicken Breast Boneless', 'Chicken breast', 320],
                ['Chicken Liver', 'Liver (food)', 180],
                ['Duck Meat', 'Duck as food', 480],
                ['Turkey Meat', 'Turkey as food', 620],
                ['Quail', 'Quail', 400],
                ['Farm Eggs', 'Egg as food', 90],
                ['Rabbit Meat', 'Rabbit meat', 520],
            ],

            // ── Mutton ──────────────────────────────────────────────────
            18 => [
                ['Goat Meat Curry Cut', 'Goat meat', 820],
                ['Lamb Chops', 'Lamb and mutton', 900],
                ['Mutton Liver', 'Liver (food)', 400],
                ['Mutton Trotters', 'Trotters (food)', 300],
                ['Mutton Ribs', 'Ribs (food)', 760],
            ],

            // ── Camel ───────────────────────────────────────────────────
            20 => [
                ['Camel Meat Boneless', 'Camel meat', 700],
                ['Camel Milk', 'Camel milk', 300],
            ],
        ];
    }

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('undo')) {
            return $this->undo();
        }

        $dry = (bool) $this->option('dry-run');
        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $catalogue = $this->catalogue();

        if ($this->option('only')) {
            $wanted = array_map('intval', array_map('trim', explode(',', $this->option('only'))));
            $catalogue = array_intersect_key($catalogue, array_flip($wanted));
        }

        $totalProducts = 0;
        $totalVariants = 0;
        $noImage = [];

        foreach ($catalogue as $storeId => $items) {
            $storeName = DB::table('stores')->where('id', $storeId)->value('name') ?? "store {$storeId}";

            // Never place a product inside a "special items" sub-group — those
            // are hand-curated for the home screen and must stay exactly as the
            // merchandising team left them.
            $specialGroupIds = $this->specialGroupIds();

            // Template rows give valid category placement and the store's unit.
            $templates = DB::table('products')
                ->where('store_id', $storeId)
                ->where('status', 1)
                ->whereNull('deleted_at')
                ->where('manufacturer', 'NOT LIKE', self::MARKER . '%')
                ->when($specialGroupIds, fn ($q) => $q->whereNotIn('sub_category_group_id', $specialGroupIds))
                ->select('id', 'category_id', 'category_group_id', 'sub_category_group_id',
                    'tax_id', 'tax', 'indicator', 'cod_allowed', 'tax_included_in_price', 'return_status',
                    'cancelable_status', 'return_days', 'type', 'fssai_lic_no')
                ->get();

            if ($templates->isEmpty()) {
                $this->warn("  {$storeName}: every product sits in a special-items group — skipped, nothing safe to copy placement from");
                continue;
            }

            $unitId = (int) (DB::table('product_variants as v')
                ->join('products as p', 'p.id', '=', 'v.product_id')
                ->where('p.store_id', $storeId)->value('v.stock_unit_id') ?: 1);
            $variantType = (string) (DB::table('product_variants as v')
                ->join('products as p', 'p.id', '=', 'v.product_id')
                ->where('p.store_id', $storeId)->value('v.type') ?: 'packet');

            $this->newLine();
            $this->line("<info>▸ {$storeName}</info> (store {$storeId})");

            $made = 0;
            $variants = 0;

            foreach ($items as $i => [$name, $wikiTitle, $pricePerKg]) {
                if (DB::table('products')->where('store_id', $storeId)->where('name', $name)->exists()) {
                    continue;
                }

                $image = $this->wikipediaImage($wikiTitle);
                if (!$image) {
                    // A tile with no photo is worse than a missing product.
                    $noImage[] = "{$name} ({$wikiTitle})";
                    continue;
                }

                // Placement by MEANING, not round-robin. Round-robin filed Ash
                // Gourd under "Oils" and Litchi under "Leafy & Herbs" — correct
                // rows, nonsense storefront.
                $tpl = $this->templateFor($name, $templates, $i);

                if ($dry) {
                    $made++;
                    $variants += 3;
                    $this->line(sprintf('    %-24s %s', substr($name, 0, 24), basename(parse_url($image, PHP_URL_PATH))));
                    continue;
                }

                DB::transaction(function () use ($name, $wikiTitle, $pricePerKg, $image, $tpl, $storeId, $unitId, $variantType, $i, &$made, &$variants) {
                    $productId = DB::table('products')->insertGetId([
                        'seller_id'              => null,
                        'row_order'              => 500 + $i,
                        'name'                   => $name,
                        'tags'                   => $name,
                        'tax_id'                 => $tpl->tax_id,
                        'brand_id'               => 0,
                        'slug'                   => Str::slug($name) . '-' . $storeId,
                        'category_id'            => $tpl->category_id,
                        'category_group_id'      => $tpl->category_group_id,
                        'sub_category_group_id'  => $tpl->sub_category_group_id,
                        'store_id'               => $storeId,
                        'tax'                    => $tpl->tax,
                        'indicator'              => $tpl->indicator,
                        'manufacturer'           => self::MARKER,
                        'made_in'                => 'India',
                        'return_status'          => $tpl->return_status,
                        'cancelable_status'      => $tpl->cancelable_status,
                        'image'                  => $image,
                        'description'            => "<p>Fresh {$name}, sourced daily and quality checked before packing. Delivered chilled to keep it fresh.</p>",
                        'status'                 => 1,
                        'is_approved'            => 1,
                        'return_days'            => $tpl->return_days,
                        'type'                   => $tpl->type,
                        'is_unlimited_stock'     => 0,
                        'cod_allowed'            => $tpl->cod_allowed ?? 1,
                        'total_allowed_quantity' => 10,
                        'tax_included_in_price'  => $tpl->tax_included_in_price,
                        'fssai_lic_no'           => $tpl->fssai_lic_no ?: '',
                        'created_at'             => now(),
                        'updated_at'             => now(),
                    ]);
                    $made++;

                    // Three pack sizes, priced off the per-kg rate with a mild
                    // economy of scale so the 1 kg pack is the better deal.
                    foreach ([[250, 0.27], [500, 0.52], [1000, 1.00]] as [$grams, $factor]) {
                        $price = max(5, round($pricePerKg * $factor / 5) * 5);
                        DB::table('product_variants')->insert([
                            'product_id'       => $productId,
                            'type'             => $variantType,
                            'status'           => 1,
                            'measurement'      => $unitId === 1 ? $grams / 1000 : $grams,
                            'price'            => $price,
                            'discounted_price' => round($price * 0.92 / 5) * 5,
                            'stock'            => rand(15, 120),
                            'stock_unit_id'    => $unitId,
                        ]);
                        $variants++;
                    }
                });

                $this->line(sprintf('    %-24s %s', substr($name, 0, 24), basename(parse_url($image, PHP_URL_PATH))));
            }

            $this->line("  <info>{$made}</info> product(s), {$variants} variant(s) " . ($dry ? 'would be added' : 'added'));
            $totalProducts += $made;
            $totalVariants += $variants;
        }

        $this->newLine();
        $this->info("{$totalProducts} products / {$totalVariants} variants " . ($dry ? 'would be added.' : 'added.'));

        if ($noImage) {
            $this->warn('No usable photo, skipped: ' . implode(', ', $noImage));
        }

        return self::SUCCESS;
    }

    /**
     * Item name => the category it belongs in. Anything unlisted falls back to
     * the store's most common category rather than a round-robin pick.
     */
    private const CATEGORY_FOR = [
        'Exotic Fruits' => [
            'Litchi', 'Plum', 'Peach', 'Apricot', 'Fig', 'Cherry', 'Blackberry',
            'Raspberry', 'Star Fruit', 'Passion Fruit', 'Dragon Fruit', 'Kiwi', 'Avocado', 'Blueberry',
        ],
        'Daily Fruits' => [
            'Custard Apple', 'Sapota', 'Jackfruit', 'Guava Pink', 'Pomelo',
            'Indian Gooseberry', 'Mulberry', 'Dates', 'Coconut',
        ],
        'Exotic Vegetables' => [
            'Red Cabbage', 'Brussels Sprout', 'Kohlrabi', 'Leek', 'Bok Choy',
            'Asparagus', 'Celery', 'Zucchini', 'Broccoli',
        ],
        'Leafy & Herbs' => [
            'Parsley', 'Basil',
        ],
        'Daily Vegetables' => [
            'Ash Gourd', 'Snake Gourd', 'Ivy Gourd', 'Pointed Gourd', 'Cluster Beans',
            'Broad Beans', 'Cowpea', 'Turnip', 'Yam', 'Colocasia', 'Sweet Potato',
            'Raw Banana', 'Green Chilli', 'Ginger', 'Garlic', 'Lemon', 'Pumpkin', 'Chow Chow',
        ],
    ];

    /**
     * The template row whose category actually suits this item.
     *
     * Falls back to the first template only when the name isn't mapped and no
     * matching category exists in the store.
     */
    private function templateFor(string $name, $templates, int $i)
    {
        $target = null;
        foreach (self::CATEGORY_FOR as $categoryName => $items) {
            if (in_array($name, $items, true)) {
                $target = $categoryName;
                break;
            }
        }

        if ($target) {
            $catId = DB::table('categories')->where('name', $target)->value('id');
            if ($catId) {
                $match = $templates->firstWhere('category_id', $catId);
                if ($match) {
                    return $match;
                }

                // Category exists but no template product sits in it — build a
                // placement from any product already filed there.
                $ref = DB::table('products')->where('category_id', $catId)
                    ->whereNull('deleted_at')->first();
                if ($ref) {
                    $clone = clone $templates[$i % $templates->count()];
                    $clone->category_id = $ref->category_id;
                    $clone->category_group_id = $ref->category_group_id;
                    $clone->sub_category_group_id = $ref->sub_category_group_id;
                    return $clone;
                }
            }
        }

        return $templates[$i % $templates->count()];
    }

    /**
     * Sub-category groups flagged as home-screen "special items". Hand-curated
     * — this command must never add to them or copy placement from them.
     *
     * @return array<int>
     */
    private function specialGroupIds(): array
    {
        static $ids = null;

        if ($ids === null) {
            $ids = \Schema::hasColumn('sub_category_groups', 'is_special_item')
                ? DB::table('sub_category_groups')->where('is_special_item', 1)->pluck('id')->map('intval')->all()
                : [];
        }

        return $ids;
    }

    private function wikipediaImage(string $title): ?string
    {
        static $cache = [];
        if (array_key_exists($title, $cache)) {
            return $cache[$title];
        }

        try {
            usleep(250000);
            $res = Http::withHeaders(['User-Agent' => self::UA])
                ->timeout(45)
                ->get('https://en.wikipedia.org/w/api.php', [
                    'action' => 'query', 'titles' => $title, 'prop' => 'pageimages',
                    'piprop' => 'thumbnail', 'pithumbsize' => 800,
                    'redirects' => 1, 'format' => 'json',
                ]);

            foreach ($res->json('query.pages') ?? [] as $page) {
                $url = $page['thumbnail']['source'] ?? null;
                if (!$url || !preg_match('/\.(jpg|jpeg|png)$/i', $url)) {
                    continue;
                }
                $name = strtolower(basename(parse_url($url, PHP_URL_PATH) ?: ''));
                foreach (self::BOTANICAL_REJECT as $bad) {
                    if (str_contains($name, $bad)) {
                        return $cache[$title] = null;
                    }
                }
                return $cache[$title] = $url;
            }
        } catch (\Throwable $e) {
            $this->warn("    wikipedia '{$title}' failed: " . $e->getMessage());
        }

        return $cache[$title] = null;
    }

    private function undo(): int
    {
        $ids = DB::table('products')->where('manufacturer', 'LIKE', self::MARKER . '%')->pluck('id');

        if ($this->option('dry-run')) {
            $this->line("Would remove {$ids->count()} product(s) and their variants.");
            return self::SUCCESS;
        }

        if ($ids->isEmpty()) {
            $this->info('Nothing to remove.');
            return self::SUCCESS;
        }

        $v = DB::table('product_variants')->whereIn('product_id', $ids)->delete();
        $p = DB::table('products')->whereIn('id', $ids)->delete();

        $this->info("Removed {$p} product(s) and {$v} variant(s).");

        return self::SUCCESS;
    }
}
