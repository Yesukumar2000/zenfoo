<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Adds browse categories to the Chicken & Meat, Mutton, Fish and Camel stores,
 * including three pre-order categories.
 *
 * Two kinds of product go in, and the difference is entirely about photography.
 *
 *  - New lines (marinated, sausages, frozen snacks, egg varieties) come with
 *    their own photo from database/data/meat-category-images.json. These are
 *    prepared and deli products, which free stock photographs well — unlike raw
 *    Indian butchery, where a search for "mutton chops" returns a live lamb in a
 *    field and "camel" returns an animal in a zoo.
 *
 *  - Bulk, family and pre-order packs REUSE the photo of the cut they are a
 *    larger pack of, matched by name. "Mutton Curry Cut 5kg" showing the same
 *    picture as "Mutton Curry Cut" is not a duplication bug — it is how every
 *    quick-commerce catalogue presents pack sizes, and it is why these
 *    categories can be added to mutton, fish and camel at all.
 *
 * Pre-order products set is_pre_order_item, which the customer app already
 * renders as a "PRE ORDER" badge on the tile — no app change needed.
 *
 *   php artisan zenfoo:extend-meat-cats --dry-run
 *   php artisan zenfoo:extend-meat-cats
 *   php artisan zenfoo:extend-meat-cats --undo
 */
class ExtendMeatCategories extends Command
{
    protected $signature = 'zenfoo:extend-meat-cats
        {--dry-run : Report what would change, change nothing}
        {--undo : Delete everything this command created, then stop}';

    protected $description = 'Add categories (including pre-order) to the meat, fish and camel stores';

    public const MARKER = 'ZFDEMO_MEATCAT';

    private const JOURNAL = 'meat-categories.json';

    /**
     * store => [category => [preorder, [ [name, price, mrp, unit, source], ... ] ]]
     *
     * `source` is either null (the product brings its own photo, keyed by name
     * in meat-category-images.json) or the name of an existing product in the
     * same store whose photo this pack size should share.
     */
    private function plan(): array
    {
        return [
            14 => [
                'Marinated & Ready To Cook' => [false, [
                    ['Chicken Tikka Marinated 500g', 249, 299, 2, null],
                    ['Tandoori Chicken Marinated 1kg', 429, 499, 1, null],
                    ['Chicken Malai Tikka 500g', 279, 329, 2, null],
                    ['Chicken Seekh Kebab 400g', 259, 309, 2, null],
                ]],
                'Sausages & Frozen Snacks' => [false, [
                    ['Chicken Sausages 250g', 169, 199, 2, null],
                    ['Chicken Popcorn 250g', 179, 209, 2, null],
                    ['Chicken Strips 300g', 199, 239, 2, null],
                    ['Chicken Spring Roll 300g', 189, 219, 2, null],
                ]],
                'Eggs Specials' => [false, [
                    ['Duck Eggs Pack of 6', 119, 139, 3, null],
                    ['Quail Eggs Pack of 12', 99, 119, 3, null],
                    ['White Eggs Pack of 6', 59, 72, 3, null],
                    ['Organic Brown Eggs Pack of 10', 129, 149, 3, null],
                ]],
                'Pre-Order Party Packs' => [true, [
                    ['Chicken Curry Cut 5kg Party Pack', 1249, 1499, 1, 'Chicken Curry Cut'],
                    ['Chicken Biryani Cut 5kg Party Pack', 1349, 1599, 1, 'Chicken Biryani Cut 1kg'],
                    ['Whole Chicken Pack of 5', 1499, 1799, 3, 'Whole Chicken'],
                ]],
            ],

            18 => [
                'Mutton Family Packs' => [false, [
                    ['Mutton Curry Cut 2kg Family Pack', 1499, 1749, 1, 'Mutton Curry Cut'],
                    ['Mutton Keema 2kg Family Pack', 1549, 1799, 1, 'Mutton Keema'],
                    ['Mutton Boneless 2kg Family Pack', 1899, 2199, 1, 'Mutton Boneless'],
                ]],
                'Pre-Order Bulk Mutton' => [true, [
                    ['Whole Goat Dressed 10kg', 8999, 10499, 1, 'Mutton Curry Cut'],
                    ['Half Goat Dressed 5kg', 4699, 5399, 1, 'Mutton Boneless'],
                    ['Mutton Ribs 3kg Bulk', 2199, 2599, 1, 'Mutton Ribs'],
                ]],
            ],

            19 => [
                'Seafood Combos' => [false, [
                    ['Fish Curry Combo 2kg', 899, 1049, 1, 'Rohu'],
                    ['Prawns Family Pack 2kg', 1199, 1399, 1, 'Prawns Medium'],
                    ['Mixed Seafood Combo 2kg', 1349, 1599, 1, 'Crab'],
                ]],
                'Pre-Order Bulk Seafood' => [true, [
                    ['Rohu Whole 3kg Bulk', 1099, 1299, 1, 'Rohu'],
                    ['Pomfret 3kg Bulk', 2399, 2799, 1, 'Pomfret'],
                    ['Tiger Prawns 3kg Bulk', 2199, 2599, 1, 'Prawns Jumbo'],
                ]],
            ],

            20 => [
                'Camel Family Packs' => [false, [
                    ['Camel Curry Cut 3kg Family Pack', 2399, 2799, 1, 'Camel Meat Curry Cut 1kg'],
                    ['Camel Keema 2kg Family Pack', 1799, 2099, 1, 'Camel Keema 1kg'],
                    ['Camel Boneless 2kg Family Pack', 2099, 2449, 1, 'Camel Meat Boneless 1kg'],
                ]],
            ],
        ];
    }

    /** Which seller owns the new categories in each store. */
    private function sellerFor(int $storeId): ?int
    {
        return DB::table('sellers')
            ->where('store_id', $storeId)
            ->where('status', 1)
            ->whereNull('deleted_at')
            ->orderBy('id')
            ->value('id');
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

        $images = json_decode(file_get_contents(database_path('data/meat-category-images.json')), true) ?: [];
        $journal = $this->loadJournal();
        $made = 0;
        $skipped = [];

        foreach ($this->plan() as $storeId => $categories) {
            $sellerId = $this->sellerFor($storeId);
            $this->newLine();
            $this->line("<info>store {$storeId}</info>" . ($sellerId ? " (seller #{$sellerId})" : ' (admin-owned)'));

            foreach ($categories as $catName => [$preOrder, $items]) {
                $rows = [];

                foreach ($items as $i => [$name, $price, $mrp, $unitId, $source]) {
                    $image = $source
                        ? DB::table('products')->where('store_id', $storeId)->where('name', $source)
                            ->whereNull('deleted_at')->value('image')
                        : ($images[$name] ?? null);

                    if (!$image) {
                        $skipped[] = "{$name} (no photo" . ($source ? ", source '{$source}' not found" : '') . ')';
                        continue;
                    }
                    if (DB::table('products')->where('store_id', $storeId)->where('name', $name)->whereNull('deleted_at')->exists()) {
                        continue;
                    }

                    $rows[] = [$name, $price, $mrp, $unitId, $image, $i];
                }

                $this->line(sprintf('  %-28s %s %d item(s)', $catName,
                    $preOrder ? '<comment>[PRE-ORDER]</comment>' : '           ', count($rows)));

                if ($dry || !$rows) {
                    $made += count($rows);
                    continue;
                }

                DB::transaction(function () use ($storeId, $sellerId, $catName, $preOrder, $rows, $images, &$journal, &$made) {
                    $catId = $this->ensureCategory($sellerId, $catName, $rows[0][4], $journal);
                    $typeId = $this->ensureItemType($catId, 'Non Veg', $journal);

                    foreach ($rows as [$name, $price, $mrp, $unitId, $image, $i]) {
                        $this->createProduct($storeId, $sellerId, $catId, $typeId, $preOrder,
                            $name, $price, $mrp, $unitId, $image, $i, $journal);
                        $made++;
                    }
                });
            }
        }

        if (!$dry && $made) {
            $this->saveJournal($journal);
        }

        if ($skipped) {
            $this->newLine();
            $this->warn('  skipped (' . count($skipped) . '):');
            foreach ($skipped as $s) {
                $this->line("    {$s}");
            }
        }

        $this->newLine();
        $this->info("{$made} product(s) " . ($dry ? 'would be created' : 'created') . ' in new categories. Nothing existing was modified.');
        if (!$dry && $made) {
            $this->line('  Revert with <comment>php artisan zenfoo:extend-meat-cats --undo</comment>');
        }

        return self::SUCCESS;
    }

    private function createProduct(
        int $storeId, ?int $sellerId, int $catId, ?int $typeId, bool $preOrder,
        string $name, int $price, int $mrp, int $unitId, string $image, int $i, array &$journal
    ): void {
        $slug = Str::slug($name) . '-mc' . $storeId;
        if (DB::table('products')->where('slug', $slug)->exists()) {
            $slug .= '-' . $i;
        }

        $productId = DB::table('products')->insertGetId([
            'seller_id'              => $sellerId,
            'row_order'              => $i + 1,
            'name'                   => $name,
            'tags'                   => Str::lower(str_replace(' ', ',', $name)),
            'tax_id'                 => 0,
            'brand_id'               => 0,
            'slug'                   => $slug,
            'category_id'            => $catId,
            'sub_category_group_id'  => null,
            'category_group_id'      => null,
            'store_id'               => $storeId,
            'item_type_id'           => $typeId,
            'tax'                    => 0,
            // Everything in these four stores is non-vegetarian.
            'indicator'              => 2,
            'manufacturer'           => self::MARKER,
            'made_in'                => 'India',
            'return_status'          => 0,
            'cancelable_status'      => 1,
            'image'                  => $image,
            'other_images'           => null,
            'description'            => $preOrder
                ? $name . ' — pre-order item, delivered the next day.'
                : $name . ' — fresh, cleaned and delivered same day.',
            'status'                 => 1,
            'is_approved'            => 1,
            'return_days'            => 0,
            'type'                   => 'packet',
            'is_unlimited_stock'     => 0,
            // The customer app already draws a "PRE ORDER" badge off this flag.
            'is_pre_order_item'      => $preOrder ? 1 : 0,
            'is_skinned_one'         => 0,
            'is_cleaned'             => 0,
            'cod_allowed'            => 1,
            'total_allowed_quantity' => $preOrder ? 3 : 10,
            'tax_included_in_price'  => 1,
            'fssai_lic_no'           => '',
            'barcode'                => null,
            'created_at'             => now()->subDays(($i * 2 % 20) + 1),
            'updated_at'             => now(),
        ]);
        $journal[] = ['t' => 'product', 'id' => $productId];

        $variantId = DB::table('product_variants')->insertGetId([
            'product_id'       => $productId,
            'type'             => 'packet',
            'status'           => 1,
            'measurement'      => 1,
            'price'            => $mrp,
            'discounted_price' => $price,
            'stock'            => $preOrder ? 10 : 30 + (crc32($name) % 50),
            'stock_unit_id'    => $unitId,
        ]);
        $journal[] = ['t' => 'variant', 'id' => $variantId];
    }

    private function ensureCategory(?int $sellerId, string $name, string $image, array &$journal): int
    {
        $existing = DB::table('categories')
            ->when($sellerId, fn ($q) => $q->where('seller_id', $sellerId), fn ($q) => $q->whereNull('seller_id'))
            ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower(trim($name))])
            ->value('id');

        if ($existing) {
            return (int) $existing;
        }

        $id = DB::table('categories')->insertGetId([
            'seller_id'          => $sellerId,
            'is_added_by_seller' => $sellerId ? 1 : 0,
            'row_order'          => 1,
            'name'               => $name,
            // NOT NULL with no default.
            'subtitle'           => $name,
            'slug'               => Str::slug($name) . '-mc',
            'image'              => $image,
            'status'             => 1,
            'parent_id'          => 0,
            'created_at'         => now(),
            'updated_at'         => now(),
        ]);
        $journal[] = ['t' => 'category', 'id' => $id];

        return $id;
    }

    private function ensureItemType(int $categoryId, string $name, array &$journal): int
    {
        $existing = DB::table('category_types')
            ->where('category_id', $categoryId)
            ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower($name)])
            ->value('id');

        if ($existing) {
            return (int) $existing;
        }

        $id = DB::table('category_types')->insertGetId([
            'name'        => $name,
            'category_id' => $categoryId,
            'created_at'  => now(),
            'updated_at'  => now(),
        ]);
        $journal[] = ['t' => 'item_type', 'id' => $id];

        return $id;
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
