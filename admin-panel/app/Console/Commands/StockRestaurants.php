<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Gives the seven restaurants in store 15 (Food) a real menu.
 *
 * zenfoo:stock-vendors fills the grocery, meat and fish vendors by cloning what
 * their store already sells, but that cannot work here: store 15 holds 43
 * products across all seven vendors, so cloning would put pizza in the sweet
 * shop and Mysore Pak in the café. These are per-cuisine menus instead, from
 * database/data/restaurant-menus.php.
 *
 * Every photo in restaurant-dish-images.json was looked at on a contact sheet
 * before being accepted. Ten dishes were cut from the menus because no correct
 * photo could be found for them — Pexels answered "Cinnamon Roll" with a dish
 * of chicken nuggets and Wikipedia answered "Dal Tadka" with a fish curry. A
 * missing dish costs nothing; a wrong photo on a storefront is what a client
 * notices.
 *
 * Categories and item types are seller-scoped in this schema, so each is
 * created under the restaurant that needs it. Existing categories are matched
 * by name and reused, so a shop that already has "Milk Based Sweets" keeps it.
 *
 * Additive and reversible: nothing existing is modified, and every row created
 * is journalled.
 *
 *   php artisan zenfoo:stock-restaurants --dry-run
 *   php artisan zenfoo:stock-restaurants
 *   php artisan zenfoo:stock-restaurants --undo
 */
class StockRestaurants extends Command
{
    protected $signature = 'zenfoo:stock-restaurants
        {--seller=* : Only these seller ids}
        {--dry-run : Report what would change, change nothing}
        {--undo : Delete everything this command created, then stop}';

    protected $description = 'Give the store 15 restaurants a real per-cuisine menu';

    /** Written to products.manufacturer. Also the purge marker. */
    public const MARKER = 'ZFDEMO_MENU';

    private const JOURNAL = 'restaurant-menus.json';

    /** Restaurants live in store 15 (Food). */
    private const STORE_ID = 15;

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('undo')) {
            return $this->undo();
        }

        $dry = (bool) $this->option('dry-run');
        $only = array_map('intval', (array) $this->option('seller'));

        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $menus = require database_path('data/restaurant-menus.php');
        $images = json_decode(file_get_contents(database_path('data/restaurant-dish-images.json')), true);

        if (!$images) {
            $this->error('restaurant-dish-images.json is missing or empty.');
            return self::FAILURE;
        }

        $journal = $this->loadJournal();
        $made = 0;
        $skippedNoImage = 0;

        foreach ($menus as $sellerId => $categories) {
            if ($only && !in_array((int) $sellerId, $only, true)) {
                continue;
            }

            $seller = DB::table('sellers')->where('id', $sellerId)->first(['id', 'store_name', 'status']);
            if (!$seller) {
                $this->warn("  #{$sellerId} — seller not found, skipped");
                continue;
            }

            $before = $this->liveCount($sellerId);

            // Names this shop already lists, so a re-run adds nothing twice and
            // an existing "Chicken 65" is not duplicated by the menu's own.
            $owned = DB::table('products')
                ->where('seller_id', $sellerId)
                ->whereNull('deleted_at')
                ->pluck('name')
                ->map(fn ($n) => mb_strtolower(trim($n)))
                ->flip();

            $added = 0;

            foreach ($categories as $catName => $items) {
                foreach ($items as $i => [$name, $price, $mrp, $indicator, $unitId, $q, $w]) {
                    if ($owned->has(mb_strtolower(trim($name)))) {
                        continue;
                    }
                    if (empty($images[$name])) {
                        $skippedNoImage++;
                        continue;
                    }

                    if (!$dry) {
                        $this->createItem(
                            (int) $sellerId, $catName, $images[$catName] ?? $images[$name],
                            $name, $price, $mrp, $indicator, $unitId, $images[$name], $i, $journal
                        );
                    }
                    $owned->put(mb_strtolower(trim($name)), true);
                    $added++;
                    $made++;
                }
            }

            $this->line(sprintf('  #%-4s %-24s %2d → %2d  (+%d across %d categories)',
                $sellerId, Str::limit($seller->store_name ?: '(no name)', 22),
                $before, $before + $added, $added, count($categories)));

            if ($seller->status != 1) {
                $this->line('        <comment>vendor is inactive — will not show in the app until enabled</comment>');
            }

            if (!$dry) {
                $this->saveJournal($journal);
            }
        }

        if ($skippedNoImage) {
            $this->newLine();
            $this->warn("  {$skippedNoImage} item(s) skipped: no verified photo.");
        }

        $this->newLine();
        $this->info("{$made} menu item(s) " . ($dry ? 'would be created' : 'created') . '. Nothing existing was modified.');
        if (!$dry && $made) {
            $this->line('  Revert with <comment>php artisan zenfoo:stock-restaurants --undo</comment>');
        }

        return self::SUCCESS;
    }

    private function liveCount(int $sellerId): int
    {
        return DB::table('products')
            ->where('seller_id', $sellerId)
            ->whereNull('deleted_at')
            ->where('status', 1)
            ->count();
    }

    private function createItem(
        int $sellerId, string $catName, string $catImage, string $name,
        int $price, int $mrp, int $indicator, int $unitId, string $image,
        int $rowOrder, array &$journal
    ): void {
        DB::transaction(function () use (
            $sellerId, $catName, $catImage, $name, $price, $mrp,
            $indicator, $unitId, $image, $rowOrder, &$journal
        ) {
            $categoryId = $this->ensureCategory($sellerId, $catName, $catImage, $journal);
            $typeId = $this->ensureItemType($categoryId, $indicator === 2 ? 'Non Veg' : 'Veg', $journal);

            $slug = Str::slug($name) . '-m' . $sellerId;
            if (DB::table('products')->where('slug', $slug)->exists()) {
                $slug .= '-' . $rowOrder;
            }

            $productId = DB::table('products')->insertGetId([
                'seller_id'              => $sellerId,
                'row_order'              => $rowOrder + 1,
                'name'                   => $name,
                'tags'                   => Str::lower(str_replace(' ', ',', $name)),
                'tax_id'                 => 0,
                'brand_id'               => 0,
                'slug'                   => $slug,
                'category_id'            => $categoryId,
                'sub_category_group_id'  => null,
                'category_group_id'      => null,
                'store_id'               => self::STORE_ID,
                'item_type_id'           => $typeId,
                'tax'                    => 0,
                'indicator'              => $indicator,
                'manufacturer'           => self::MARKER,
                'made_in'                => 'India',
                'return_status'          => 0,
                'cancelable_status'      => 1,
                'image'                  => $image,
                'other_images'           => null,
                'description'            => $name . ' — freshly prepared and served hot.',
                'status'                 => 1,
                'is_approved'            => 1,
                'return_days'            => 0,
                'type'                   => 'packet',
                'is_unlimited_stock'     => 0,
                'is_pre_order_item'      => 0,
                'is_skinned_one'         => 0,
                'is_cleaned'             => 0,
                'cod_allowed'            => 1,
                'total_allowed_quantity' => 10,
                'tax_included_in_price'  => 1,
                'fssai_lic_no'           => '',
                'barcode'                => null,
                'created_at'             => now()->subDays(($rowOrder * 3 % 45) + 2),
                'updated_at'             => now(),
            ]);
            $journal[] = ['t' => 'product', 'id' => $productId];

            $variantId = DB::table('product_variants')->insertGetId([
                'product_id'       => $productId,
                'type'             => 'packet',
                'status'           => 1,
                'measurement'      => 1,
                // `price` is the struck-through MRP, `discounted_price` is what
                // the customer pays — which is how the app renders the saving.
                'price'            => $mrp,
                'discounted_price' => $price,
                'stock'            => 25 + (crc32($name) % 60),
                'stock_unit_id'    => $unitId,
            ]);
            $journal[] = ['t' => 'variant', 'id' => $variantId];
        });
    }

    /** Reuse the shop's category of that name, or give it one. */
    private function ensureCategory(int $sellerId, string $name, string $image, array &$journal): int
    {
        static $cache = [];
        $key = $sellerId . '|' . $name;

        if (isset($cache[$key])) {
            return $cache[$key];
        }

        $existing = DB::table('categories')
            ->where('seller_id', $sellerId)
            ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower(trim($name))])
            ->value('id');

        if ($existing) {
            return $cache[$key] = (int) $existing;
        }

        $id = DB::table('categories')->insertGetId([
            'seller_id'          => $sellerId,
            'is_added_by_seller' => 1,
            'row_order'          => 1,
            'name'               => $name,
            // NOT NULL with no default — leaving it out fails the insert.
            'subtitle'           => $name,
            'slug'               => Str::slug($name) . '-m' . $sellerId,
            'image'              => $image,
            'status'             => 1,
            'parent_id'          => 0,
            'created_at'         => now(),
            'updated_at'         => now(),
        ]);
        $journal[] = ['t' => 'category', 'id' => $id];

        return $cache[$key] = $id;
    }

    private function ensureItemType(int $categoryId, string $name, array &$journal): int
    {
        static $cache = [];
        $key = $categoryId . '|' . $name;

        if (isset($cache[$key])) {
            return $cache[$key];
        }

        $existing = DB::table('category_types')
            ->where('category_id', $categoryId)
            ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower($name)])
            ->value('id');

        if ($existing) {
            return $cache[$key] = (int) $existing;
        }

        $id = DB::table('category_types')->insertGetId([
            'name'        => $name,
            'category_id' => $categoryId,
            'created_at'  => now(),
            'updated_at'  => now(),
        ]);
        $journal[] = ['t' => 'item_type', 'id' => $id];

        return $cache[$key] = $id;
    }

    private function undo(): int
    {
        $journal = $this->loadJournal();
        if (!$journal) {
            $this->info('No journal — nothing to remove.');
            return self::SUCCESS;
        }

        $by = ['variant' => [], 'product' => [], 'item_type' => [], 'category' => []];
        foreach ($journal as $r) {
            $by[$r['t']][] = $r['id'];
        }

        // Children first, so nothing is left pointing at a deleted parent.
        DB::table('product_variants')->whereIn('id', $by['variant'] ?: [0])->delete();
        DB::table('products')->whereIn('id', $by['product'] ?: [0])->delete();
        DB::table('category_types')->whereIn('id', $by['item_type'] ?: [0])->delete();
        DB::table('categories')->whereIn('id', $by['category'] ?: [0])->delete();

        @unlink($this->journalPath());

        $this->info(sprintf('Removed %d products, %d variants, %d item types, %d categories.',
            count($by['product']), count($by['variant']), count($by['item_type']), count($by['category'])));

        return self::SUCCESS;
    }

    private function journalPath(): string
    {
        return storage_path('app/' . self::JOURNAL);
    }

    private function loadJournal(): array
    {
        return file_exists($this->journalPath())
            ? (json_decode(file_get_contents($this->journalPath()), true) ?: [])
            : [];
    }

    private function saveJournal(array $rows): void
    {
        if (!is_dir(dirname($this->journalPath()))) {
            mkdir(dirname($this->journalPath()), 0755, true);
        }
        file_put_contents($this->journalPath(), json_encode($rows, JSON_UNESCAPED_SLASHES));
    }
}
