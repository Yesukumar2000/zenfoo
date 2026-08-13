<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Brings every active vendor up to a minimum number of live products.
 *
 * Most vendors on this data have one or two listings, so tapping into a store
 * in the customer app shows an almost empty shelf. This clones products the
 * same store already sells into the thin vendors, so each storefront has a
 * believable catalogue.
 *
 * Why cloning rather than sourcing new products: every source row already has
 * an image that loads, a category, an item type, variants and stock units that
 * the app renders correctly. Inventing 200 new products means inventing 200 new
 * images, and free stock photography has already proved unreliable for this
 * catalogue. Cloning carries zero image risk.
 *
 * Categories and item types are seller-scoped in this schema, so a clone cannot
 * simply keep the source category_id — it would put the product under another
 * vendor's category. Each needed category and item type is therefore recreated
 * under the target vendor first, then the product points at that copy.
 *
 * Store 15 (Food) is skipped: it holds 43 products across seven restaurants, so
 * cloning would give every restaurant the same menu — a sweet shop selling
 * pizza. Those vendors are handled by zenfoo:stock-restaurants, which uses real
 * per-cuisine menus.
 *
 *   php artisan zenfoo:stock-vendors --dry-run
 *   php artisan zenfoo:stock-vendors
 *   php artisan zenfoo:stock-vendors --undo
 */
class StockVendors extends Command
{
    protected $signature = 'zenfoo:stock-vendors
        {--min=35 : Target number of live products per vendor}
        {--seller=* : Only these seller ids}
        {--dry-run : Report what would change, change nothing}
        {--undo : Delete everything this command created, then stop}';

    protected $description = 'Clone catalogue products into thin vendors so every storefront has stock';

    /** Written to products.manufacturer. Also the purge marker. */
    public const MARKER = 'ZFDEMO_VENDOR_STOCK';

    private const JOURNAL = 'vendor-stock.json';

    /** Restaurants: cloning inside this store cross-contaminates cuisines. */
    private const SKIP_STORES = [15];

    /**
     * Stores to borrow from when a vendor's own store runs dry.
     *
     * Chicken & Meat and Mutton each hold only ~34 products, so a butcher there
     * cannot reach 35 from its own shelf. Both are butcher counters selling the
     * same kind of thing, so borrowing across them reads correctly. Deliberately
     * no entry for Fish or Camel — a fishmonger listing mutton would not.
     */
    private const RELATED_STORES = [
        14 => [18],
        18 => [14],
    ];

    /** id => [category_id, item_type_id] mapping built per vendor. */
    private array $catMap = [];
    private array $typeMap = [];

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('undo')) {
            return $this->undo();
        }

        $min = max(1, (int) $this->option('min'));
        $dry = (bool) $this->option('dry-run');
        $only = array_map('intval', (array) $this->option('seller'));

        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $vendors = DB::table('sellers')
            ->whereNull('deleted_at')
            ->where('status', 1)
            ->when($only, fn ($q) => $q->whereIn('id', $only))
            ->orderBy('id')
            ->get(['id', 'store_name', 'store_id']);

        $journal = $this->loadJournal();
        $madeTotal = 0;

        foreach ($vendors as $v) {
            $have = $this->liveCount($v->id);
            if ($have >= $min) {
                continue;
            }
            if (in_array((int) $v->store_id, self::SKIP_STORES, true)) {
                $this->line(sprintf('  #%-4s %-26s store %-3s  %2d products — <comment>skipped</comment>, use zenfoo:stock-restaurants',
                    $v->id, Str::limit($v->store_name ?: '(no name)', 24), $v->store_id, $have));
                continue;
            }

            $want = $min - $have;
            $sources = $this->sourcesFor($v, $want, [(int) $v->store_id]);

            // Own shelf exhausted — top up from a related counter.
            $related = self::RELATED_STORES[(int) $v->store_id] ?? [];
            if ($sources->count() < $want && $related) {
                $extra = $this->sourcesFor($v, $want - $sources->count(), $related,
                    $sources->pluck('id')->all());
                $sources = $sources->concat($extra);
            }

            if ($sources->isEmpty()) {
                $this->warn(sprintf('  #%-4s %-26s store %-3s  no source products available', $v->id, Str::limit($v->store_name, 24), $v->store_id));
                continue;
            }

            $this->line(sprintf('  #%-4s %-26s store %-3s  %2d → %2d  (+%d)',
                $v->id, Str::limit($v->store_name ?: '(no name)', 24), $v->store_id,
                $have, $have + $sources->count(), $sources->count()));

            if ($sources->count() < $want) {
                $this->line(sprintf('        <comment>only %d of %d available in store %s</comment>',
                    $sources->count(), $want, $v->store_id));
            }

            if ($dry) {
                $madeTotal += $sources->count();
                continue;
            }

            $this->catMap = [];
            $this->typeMap = [];

            DB::transaction(function () use ($v, $sources, &$journal, &$madeTotal) {
                foreach ($sources as $i => $src) {
                    $made = $this->cloneProduct($v, $src, $i, $journal);
                    if ($made) {
                        $madeTotal++;
                    }
                }
            });

            $this->saveJournal($journal);
        }

        $this->newLine();
        $this->info("{$madeTotal} product(s) " . ($dry ? 'would be created' : 'created') . '. Nothing existing was modified.');
        if (!$dry && $madeTotal) {
            $this->line('  Revert with <comment>php artisan zenfoo:stock-vendors --undo</comment>');
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

    /**
     * Products worth cloning into this vendor.
     *
     * Same store, live, has an image, and not something the vendor already
     * sells — matching on name, because a shop listing "Tomato" twice looks
     * like a data bug in a demo.
     */
    private function sourcesFor(object $vendor, int $limit, array $storeIds, array $exclude = [])
    {
        if ($limit < 1) {
            return collect();
        }

        $owned = DB::table('products')
            ->where('seller_id', $vendor->id)
            ->whereNull('deleted_at')
            ->pluck('name')
            ->map(fn ($n) => mb_strtolower(trim($n)))
            ->all();

        return DB::table('products')
            ->whereIn('store_id', $storeIds)
            ->when($exclude, fn ($q) => $q->whereNotIn('id', $exclude))
            ->where('status', 1)
            ->whereNull('deleted_at')
            // Admin-owned rows have seller_id NULL, and `<> id` never matches
            // NULL in SQL — which silently hid the entire meat and fish pool.
            ->where(function ($q) use ($vendor) {
                $q->whereNull('seller_id')->orWhere('seller_id', '<>', $vendor->id);
            })
            ->whereRaw("image <> ''")
            ->whereNotNull('image')
            ->where(function ($q) {
                $q->whereNull('manufacturer')->orWhere('manufacturer', '<>', self::MARKER);
            })
            // Only clone products that actually have a sellable variant —
            // a product with no variant renders with no price.
            ->whereExists(function ($q) {
                $q->select(DB::raw(1))->from('product_variants')
                    ->whereColumn('product_variants.product_id', 'products.id')
                    ->whereNull('product_variants.deleted_at');
            })
            ->when($owned, fn ($q) => $q->whereNotIn(DB::raw('LOWER(TRIM(name))'), $owned))
            ->inRandomOrder()
            ->limit($limit)
            ->get();
    }

    private function cloneProduct(object $vendor, object $src, int $i, array &$journal): bool
    {
        $slug = Str::slug($src->name) . '-v' . $vendor->id . '-' . $src->id;
        if (DB::table('products')->where('slug', $slug)->exists()) {
            return false;
        }

        $categoryId = $this->mirrorCategory($vendor, (int) $src->category_id, $journal);
        if (!$categoryId) {
            return false;
        }
        $itemTypeId = $this->mirrorItemType($vendor, (int) $src->item_type_id, $categoryId, $journal);

        $newId = DB::table('products')->insertGetId([
            'seller_id'              => $vendor->id,
            'row_order'              => $i + 1,
            'name'                   => $src->name,
            'tags'                   => $src->tags,
            'tax_id'                 => $src->tax_id,
            'brand_id'               => $src->brand_id,
            'slug'                   => $slug,
            'category_id'            => $categoryId,
            'sub_category_group_id'  => null,
            'category_group_id'      => null,
            'store_id'               => $vendor->store_id,
            'item_type_id'           => $itemTypeId,
            'tax'                    => $src->tax,
            'indicator'              => $src->indicator,
            'manufacturer'           => self::MARKER,
            'made_in'                => $src->made_in ?: 'India',
            'return_status'          => $src->return_status ?? 0,
            'cancelable_status'      => $src->cancelable_status ?? 0,
            'image'                  => $src->image,
            'other_images'           => $src->other_images,
            'description'            => $src->description ?: $src->name,
            'status'                 => 1,
            'is_approved'            => 1,
            'return_days'            => $src->return_days ?? 0,
            'type'                   => $src->type,
            'is_unlimited_stock'     => 0,
            'is_pre_order_item'      => 0,
            'is_skinned_one'         => $src->is_skinned_one,
            'is_cleaned'             => $src->is_cleaned,
            'before_cleaning_weight' => $src->before_cleaning_weight,
            'after_cleaning_weight'  => $src->after_cleaning_weight,
            'pieces'                 => $src->pieces,
            'cod_allowed'            => 1,
            'total_allowed_quantity' => max(1, (int) $src->total_allowed_quantity ?: 10),
            'tax_included_in_price'  => $src->tax_included_in_price,
            'fssai_lic_no'           => $src->fssai_lic_no ?: '',
            'barcode'                => null,
            'created_at'             => now()->subDays(($src->id % 90) + 3),
            'updated_at'             => now(),
        ]);

        $journal[] = ['t' => 'product', 'id' => $newId];

        // Same pack sizes, price nudged a few percent so two shops selling the
        // same SKU are not identical to the rupee.
        $variants = DB::table('product_variants')
            ->where('product_id', $src->id)
            ->whereNull('deleted_at')
            ->get();

        foreach ($variants as $vi => $sv) {
            $factor = 1 + ((($src->id + $vi * 7) % 17) - 8) / 100;
            $price = max(5, round($sv->price * $factor, 2));
            $disc = $sv->discounted_price > 0 ? max(1, round($sv->discounted_price * $factor, 2)) : 0;

            $vid = DB::table('product_variants')->insertGetId([
                'product_id'       => $newId,
                'type'             => $sv->type,
                'status'           => 1,
                'measurement'      => $sv->measurement,
                'price'            => $price,
                'discounted_price' => ($disc > 0 && $disc < $price) ? $disc : 0,
                'stock'            => 15 + (($src->id * 13 + $vi) % 120),
                'stock_unit_id'    => $sv->stock_unit_id,
            ]);
            $journal[] = ['t' => 'variant', 'id' => $vid];
        }

        return true;
    }

    /**
     * Give the vendor its own copy of a category, matching by name first so a
     * vendor that already has "Fresh Fish" keeps using it.
     */
    private function mirrorCategory(object $vendor, int $sourceCatId, array &$journal): ?int
    {
        if (isset($this->catMap[$sourceCatId])) {
            return $this->catMap[$sourceCatId];
        }

        $src = DB::table('categories')->where('id', $sourceCatId)->first();
        if (!$src) {
            return null;
        }

        // Admin-owned categories are shared across the store — reuse in place.
        if (empty($src->seller_id)) {
            return $this->catMap[$sourceCatId] = $sourceCatId;
        }

        $existing = DB::table('categories')
            ->where('seller_id', $vendor->id)
            ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower(trim($src->name))])
            ->value('id');

        if ($existing) {
            return $this->catMap[$sourceCatId] = (int) $existing;
        }

        $row = (array) $src;
        unset($row['id']);
        $row['seller_id'] = $vendor->id;
        $row['is_added_by_seller'] = 1;
        $row['parent_id'] = 0;
        $row['status'] = 1;
        $row['slug'] = Str::slug($src->name) . '-v' . $vendor->id;
        // subtitle and image are NOT NULL with no default, and the source row
        // is allowed to hold NULL in both.
        $row['subtitle'] = $src->subtitle ?: $src->name;
        $row['image'] = $src->image ?: '';
        $row['created_at'] = now();
        $row['updated_at'] = now();

        $newId = DB::table('categories')->insertGetId($row);
        $journal[] = ['t' => 'category', 'id' => $newId];

        return $this->catMap[$sourceCatId] = $newId;
    }

    /** Same idea for the item type (Veg / Non Veg / pack style) under a category. */
    private function mirrorItemType(object $vendor, int $sourceTypeId, int $categoryId, array &$journal): ?int
    {
        if (!$sourceTypeId) {
            return null;
        }

        $key = $categoryId . ':' . $sourceTypeId;
        if (isset($this->typeMap[$key])) {
            return $this->typeMap[$key];
        }

        $src = DB::table('category_types')->where('id', $sourceTypeId)->first();
        if (!$src) {
            return null;
        }

        if ((int) $src->category_id === $categoryId) {
            return $this->typeMap[$key] = $sourceTypeId;
        }

        $existing = DB::table('category_types')
            ->where('category_id', $categoryId)
            ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower(trim($src->name))])
            ->value('id');

        if ($existing) {
            return $this->typeMap[$key] = (int) $existing;
        }

        $newId = DB::table('category_types')->insertGetId([
            'name'        => $src->name,
            'category_id' => $categoryId,
            'created_at'  => now(),
            'updated_at'  => now(),
        ]);
        $journal[] = ['t' => 'item_type', 'id' => $newId];

        return $this->typeMap[$key] = $newId;
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
