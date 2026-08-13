<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Adds pre-order and bulk/value categories across the rest of the stores.
 *
 * zenfoo:extend-meat-cats covered Chicken & Meat, Mutton, Fish and Camel. This
 * covers Grocery, Vegetables & Fruits, Super Mart, Food and the camel bulk
 * line, so pre-order is visible wherever a client happens to browse rather than
 * only in the meat sections.
 *
 * Every product here is a bulk, hamper or party pack of something the store
 * already sells, and REUSES that product's photo, matched by name. That is both
 * honest — a 5 kg pack of the same rice is the same rice — and the only way to
 * add this much at once: free stock photography cannot supply eighty new
 * correct product shots, as several rounds of trying established.
 *
 * Pre-order products set is_pre_order_item, which the customer app already
 * renders as a "PRE ORDER" badge. No app change needed.
 *
 *   php artisan zenfoo:add-preorder-cats --dry-run
 *   php artisan zenfoo:add-preorder-cats
 *   php artisan zenfoo:add-preorder-cats --undo
 */
class AddPreorderCategories extends Command
{
    protected $signature = 'zenfoo:add-preorder-cats
        {--dry-run : Report what would change, change nothing}
        {--undo : Delete everything this command created, then stop}';

    protected $description = 'Add pre-order and bulk categories to the grocery, produce, supermart and food stores';

    public const MARKER = 'ZFDEMO_PREORDER';

    private const JOURNAL = 'preorder-categories.json';

    /**
     * store => [seller, [category => [preOrder, indicator, [ [name, price, mrp, unit, donor], ... ]]]]
     *
     * `donor` is an existing product in the same store whose photo this pack
     * reuses. `indicator`: 1 = veg, 2 = non-veg.
     */
    private function plan(): array
    {
        return [
            // ── Camel: the bulk line the meat command did not cover ──────
            20 => [null, [
                'Pre-Order Bulk Camel' => [true, 2, [
                    ['Whole Camel Leg 5kg', 4499, 5299, 1, 'Camel Meat Leg Cut 1kg'],
                    ['Camel Curry Cut 5kg Bulk', 3999, 4699, 1, 'Camel Meat Curry Cut 1kg'],
                    ['Camel Keema 3kg Bulk', 2699, 3199, 1, 'Camel Keema 1kg'],
                ]],
            ]],

            // ── Vegetables & Fruits ──────────────────────────────────────
            13 => [31, [
                'Pre-Order Fruit Boxes' => [true, 1, [
                    ['Seasonal Fruit Box 5kg', 899, 1099, 1, 'Apple Shimla'],
                    ['Exotic Fruit Hamper 3kg', 1249, 1499, 1, 'Papaya Ripe'],
                    ['Premium Dates Gift Box 1kg', 749, 899, 1, 'Dates'],
                ]],
                'Cut & Ready Veggies' => [false, 1, [
                    ['Cut Vegetable Mix 500g', 89, 109, 2, 'Cauliflower'],
                    ['Salad Combo Pack 400g', 99, 119, 2, 'Spring Onion'],
                    ['Stir Fry Mix 400g', 119, 139, 2, 'Yellow Capsicum'],
                ]],
            ]],

            // ── Grocery & Kitchen ────────────────────────────────────────
            12 => [18, [
                'Pre-Order Monthly Essentials' => [true, 1, [
                    ['Monthly Atta Pack 10kg', 549, 649, 1, 'Pilsbury fresh Atta'],
                    ['Cashew Whole Bulk 1kg', 1049, 1249, 1, 'Cashew Whole W320'],
                    ['Cow Ghee Bulk 5L', 3299, 3899, 7, 'Heritage Cow Ghee'],
                ]],
                'Bulk & Value Packs' => [false, 1, [
                    ['Instant Coffee Value Pack 500g', 899, 1049, 2, 'Nescafe Classic Coffee'],
                    ['Masala Combo Pack 6 x 100g', 449, 529, 15, 'Everest Kitchen King Masala'],
                    ['Biscuit Family Pack 12 x 100g', 249, 299, 15, 'Parle-G Biscuit'],
                ]],
            ]],

            // ── Super Mart ───────────────────────────────────────────────
            17 => [30, [
                'Pre-Order Festive Hampers' => [true, 1, [
                    ['Diwali Dry Fruit Hamper', 1899, 2249, 17, 'Greenfinity Nuts Fusion'],
                    ['Basmati Rice Bulk 25kg', 2699, 3199, 1, 'Flipkart Grocery Queen\'s Choice MOGRA BASMATI RICE'],
                    ['Snacks Party Hamper', 999, 1199, 17, 'Haldiram\'s Peanuts'],
                ]],
                'Breakfast Combos' => [false, 1, [
                    ['Oats & Peanut Butter Combo', 549, 649, 15, 'Saffola Peanut Butter Crunchy'],
                    ['Bread & Yogurt Combo', 189, 229, 15, 'Amul Dahi Yogurt'],
                    ['Coffee & Cookies Combo', 449, 529, 15, 'Sunfeast Dark Fantasy'],
                ]],
            ]],

            // ── Food: catering, which is genuinely ordered a day ahead ───
            15 => [29, [
                'Pre-Order Party Catering' => [true, 2, [
                    ['Biryani Party Pack 5kg', 2499, 2999, 1, 'Chicken Dum Biryani'],
                    ['Non-Veg Catering Combo 10 Plates', 3299, 3899, 34, 'Chicken biryani special'],
                    ['Sweets Party Box 2kg', 1199, 1399, 1, 'Rassgola'],
                ]],
            ]],
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

        $journal = $this->loadJournal();
        $made = 0;
        $skipped = [];

        foreach ($this->plan() as $storeId => [$sellerId, $categories]) {
            $this->newLine();
            $this->line("<info>store {$storeId}</info>" . ($sellerId ? " (seller #{$sellerId})" : ' (admin-owned)'));

            foreach ($categories as $catName => [$preOrder, $indicator, $items]) {
                $rows = [];

                foreach ($items as $i => [$name, $price, $mrp, $unitId, $donor]) {
                    $image = DB::table('products')
                        ->where('store_id', $storeId)
                        ->where('name', $donor)
                        ->whereNull('deleted_at')
                        ->whereRaw("image <> ''")
                        ->value('image');

                    if (!$image) {
                        $skipped[] = "{$name} — donor '{$donor}' not found in store {$storeId}";
                        continue;
                    }
                    if (DB::table('products')->where('store_id', $storeId)->where('name', $name)->whereNull('deleted_at')->exists()) {
                        continue;
                    }

                    $rows[] = [$name, $price, $mrp, $unitId, $image, $i];
                }

                $this->line(sprintf('  %-32s %s %d item(s)', $catName,
                    $preOrder ? '<comment>[PRE-ORDER]</comment>' : '           ', count($rows)));

                if ($dry || !$rows) {
                    $made += count($rows);
                    continue;
                }

                DB::transaction(function () use ($storeId, $sellerId, $catName, $preOrder, $indicator, $rows, &$journal, &$made) {
                    $catId = $this->ensureCategory($sellerId, $catName, $rows[0][4], $journal);
                    $typeId = $this->ensureItemType($catId, $indicator === 2 ? 'Non Veg' : 'Veg', $journal);

                    foreach ($rows as [$name, $price, $mrp, $unitId, $image, $i]) {
                        $this->createProduct($storeId, $sellerId, $catId, $typeId, $preOrder,
                            $indicator, $name, $price, $mrp, $unitId, $image, $i, $journal);
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
        $this->info("{$made} product(s) " . ($dry ? 'would be created' : 'created') . '. Nothing existing was modified.');
        if (!$dry && $made) {
            $this->line('  Revert with <comment>php artisan zenfoo:add-preorder-cats --undo</comment>');
        }

        return self::SUCCESS;
    }

    private function createProduct(
        int $storeId, ?int $sellerId, int $catId, ?int $typeId, bool $preOrder,
        int $indicator, string $name, int $price, int $mrp, int $unitId,
        string $image, int $i, array &$journal
    ): void {
        $slug = Str::slug($name) . '-po' . $storeId;
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
            'indicator'              => $indicator,
            'manufacturer'           => self::MARKER,
            'made_in'                => 'India',
            'return_status'          => 0,
            'cancelable_status'      => 1,
            'image'                  => $image,
            'other_images'           => null,
            'description'            => $preOrder
                ? $name . ' — pre-order item, delivered the next day.'
                : $name . ' — value pack, delivered same day.',
            'status'                 => 1,
            'is_approved'            => 1,
            'return_days'            => 0,
            'type'                   => 'packet',
            'is_unlimited_stock'     => 0,
            'is_pre_order_item'      => $preOrder ? 1 : 0,
            'is_skinned_one'         => 0,
            'is_cleaned'             => 0,
            'cod_allowed'            => 1,
            'total_allowed_quantity' => $preOrder ? 3 : 10,
            'tax_included_in_price'  => 1,
            'fssai_lic_no'           => '',
            'barcode'                => null,
            'created_at'             => now()->subDays(($i * 3 % 25) + 1),
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
            'stock'            => $preOrder ? 10 : 40 + (crc32($name) % 40),
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
            'slug'               => Str::slug($name) . '-po',
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
