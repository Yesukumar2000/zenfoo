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
 * Seeds a full quick-commerce (Zepto / Instamart style) catalogue from the JSON
 * built by `php artisan zenfoo:fetch-catalog`.
 *
 * The JSON is the single source of truth — this seeder does no network calls and
 * invents no data, so what you review in the file is exactly what lands in the DB.
 *
 * For each store it creates the whole browse hierarchy the customer app needs:
 *   category_groups      → the top-level tabs
 *   sub_category_groups  → the category filter chips (subcategory_ids CSV)
 *   categories           → the tiles, with a real photo
 *   category_types       → the "Filters by Type" chips
 *   brands.category_ids  → the "Shop By Brands" strip (plain CSV, see note below)
 *   products / variants  → the SKUs, with real packshots and pack sizes
 *
 * Re-runnable: everything it creates is tagged with MARKER in products.manufacturer,
 * so a re-run removes exactly its own rows first and nothing else.
 *
 * Run: php artisan db:seed --class=QuickCommerceCatalogSeeder
 */
class QuickCommerceCatalogSeeder extends Seeder
{
    /** Marks seeder-created products so re-runs clean only their own rows. */
    private const MARKER = 'ZENFO_QC_SEED';

    /**
     * Legacy markers cleared for the sellers this seeder touches. The older
     * SuperMartDmartSeeder left products with NO image, which would show as blank
     * tiles next to the imaged ones. Re-run that seeder to bring them back.
     */
    private const LEGACY_MARKERS = ['ZENFO_SEED', 'Brand'];

    /** JSON catalogues to load, relative to database/seeders/data. */
    private const SOURCES = ['qc_catalog_packaged.json', 'qc_catalog_fresh.json'];

    /** store id => seller resolved by store_name (first match wins). */
    private const SELLER_FOR_STORE = [
        17 => ['Super Mart Dmart'],
        12 => ['Harsha Store'],
        13 => ['Fresh veggies'],
        14 => ['Fresh meat@'],
        18 => ['Zenfoo Mutton Mart'],
        // A dedicated demo seller, so the catalogue never lands on a real
        // registered account (store 19's other seller is a live signup).
        19 => ['Ocean Fresh Seafood'],
    ];

    private const CITY_NAME = 'Hyderabad';

    public function run(): void
    {
        $catalogue = $this->loadSources();
        if (!$catalogue) {
            $this->command->error('No catalogue JSON found. Run: php artisan zenfoo:fetch-catalog');
            return;
        }

        $cityId = DB::table('cities')->whereRaw('LOWER(name) = ?', [strtolower(self::CITY_NAME)])->value('id');

        $unitByName = collect(DB::table('units')->get(['id', 'name']))
            ->mapWithKeys(fn ($u) => [strtolower(trim($u->name)) => $u->id]);
        $resolveUnit = fn (string $n) => $unitByName[strtolower($n)] ?? $unitByName['pieces'] ?? $unitByName->first();

        $totals = [];

        foreach ($catalogue as $storeId => $storeData) {
            $seller = $this->resolveSeller((int) $storeId);
            if (!$seller) {
                $this->command->warn("store {$storeId}: no matching seller — skipped.");
                continue;
            }

            // Categories mirror the seller's STORE flag (see CategoryApiController).
            $isSuperMart = (int) DB::table('stores')->where('id', $storeId)->value('is_super_mart') === 1 ? 1 : 0;

            $this->command->info("store {$storeId} → seller #{$seller->id} '" . ($seller->store_name ?: $seller->name) . "' (is_super_mart={$isSuperMart})");

            DB::beginTransaction();
            try {
                // Location-based browse needs the seller pinned to a city.
                if (empty($seller->city_id) && $cityId) {
                    $seller->city_id = $cityId;
                    $seller->save();
                    $this->command->line("    assigned to city '" . self::CITY_NAME . "' (#{$cityId})");
                }

                $removed = $this->clearPreviousRows($seller->id);
                if ($removed) {
                    $this->command->line("    cleared {$removed} previously seeded product(s)");
                }

                $counts = $this->seedStore($seller, (int) $storeId, $storeData, $isSuperMart, $resolveUnit);

                $swept = $this->sweepLeftovers($seller->id, $counts['keep']);
                if ($swept['categories'] || $swept['subgroups'] || $swept['groups']) {
                    $this->command->line("    swept leftovers: {$swept['categories']} empty categorie(s) deactivated, "
                        . "{$swept['subgroups']} sub-group(s) and {$swept['groups']} group(s) removed");
                }

                DB::commit();
                $totals[$storeId] = $counts;
                $this->command->line("    <info>{$counts['products']}</info> products / <info>{$counts['variants']}</info> variants / {$counts['categories']} categories");
            } catch (\Throwable $e) {
                DB::rollBack();
                $this->command->error("store {$storeId} failed: " . $e->getMessage());
                Log::error('QuickCommerceCatalogSeeder failed', [
                    'store' => $storeId,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
            }
        }

        $p = array_sum(array_column($totals, 'products'));
        $v = array_sum(array_column($totals, 'variants'));
        $this->command->info("Done: {$p} products / {$v} variants across " . count($totals) . ' store(s).');
    }

    /* ─────────────────────── per-store seeding ─────────────────────── */

    private function seedStore(Seller $seller, int $storeId, array $storeData, int $isSuperMart, callable $resolveUnit): array
    {
        $sellerId = $seller->id;
        $brandId = [];
        $brandCats = [];

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
        $counts = ['products' => 0, 'variants' => 0, 'categories' => 0];

        // Ids this run touched, so the sweep can tell them from older leftovers.
        $keep = ['categories' => [], 'subgroups' => [], 'groups' => []];

        $groupOrder = 0;
        foreach ($storeData['groups'] ?? [] as $groupName => $groupData) {
            $group = CategoryGroup::firstOrNew(['seller_id' => $sellerId, 'name' => $groupName]);
            $group->status        = 1;
            $group->is_super_mart = $isSuperMart;
            $group->row_order     = $groupOrder++;
            $group->image         = $groupData['image'] ?: ($group->image ?: '');
            $group->save();
            $keep['groups'][] = $group->id;

            $subOrder = 0;
            foreach ($groupData['subgroups'] ?? [] as $subName => $subData) {
                // Categories first, so the sub-group can reference their ids.
                $catIdsInOrder = [];
                foreach ($subData['categories'] ?? [] as $catName => $catData) {
                    $cat = Category::firstOrNew(['seller_id' => $sellerId, 'name' => $catName]);
                    $cat->status               = 1;
                    $cat->is_added_by_seller   = 1;
                    $cat->is_super_mart        = $isSuperMart;
                    $cat->is_sweet_house_store = 0;
                    $cat->parent_id            = 0;
                    $cat->subtitle             = $catName;
                    $cat->slug                 = $cat->slug ?: $this->slugify($catName);
                    $cat->image                = $catData['image'] ?: ($cat->image ?: '');
                    if (!$cat->exists) {
                        $cat->row_order = ++$catRow;
                    }
                    $cat->save();
                    $catIdsInOrder[$catName] = $cat->id;
                    $keep['categories'][] = $cat->id;
                    $counts['categories']++;
                }

                if (!$catIdsInOrder) {
                    continue;
                }

                $sub = CategorySubGroup::firstOrNew(['seller_id' => $sellerId, 'name' => $subName]);
                $sub->category_group_id   = $group->id;
                $sub->subcategory_ids     = implode(',', array_values($catIdsInOrder));
                $sub->is_group            = 1;
                $sub->is_children_allowed = 1;
                $sub->is_special_item     = 0;
                $sub->is_super_mart       = $isSuperMart;
                $sub->row_order           = $subOrder++;
                $sub->image               = $subData['image'] ?: ($sub->image ?: '');
                $sub->save();
                $keep['subgroups'][] = $sub->id;

                foreach ($subData['categories'] as $catName => $catData) {
                    $catId = $catIdsInOrder[$catName];

                    // "Filters by Type" chips — rebuilt to match this catalogue.
                    DB::table('category_types')->where('category_id', $catId)->delete();
                    $typeId = [];
                    foreach ($catData['types'] ?? [] as $t) {
                        $typeId[$t] = DB::table('category_types')->insertGetId([
                            'name' => $t, 'category_id' => $catId,
                            'created_at' => now(), 'updated_at' => now(),
                        ]);
                    }

                    foreach ($catData['products'] ?? [] as $p) {
                        $bId = $brandIdFor($p['brand']);
                        $brandCats[$bId][$catId] = $catId;

                        $product = $this->makeProduct($p, [
                            'row'       => ++$pRow,
                            'catId'     => $catId,
                            'groupId'   => $group->id,
                            'subId'     => $sub->id,
                            'typeId'    => $typeId[$p['type_name']] ?? null,
                            'storeId'   => $storeId,
                            'sellerId'  => $sellerId,
                            'brandId'   => $bId,
                        ]);
                        $counts['products']++;

                        // Fresh items carry explicit variants; packaged SKUs have one pack size.
                        $variants = $p['variants'] ?? [[
                            'measurement'      => $p['measurement'],
                            'unit'             => $p['unit'],
                            'price'            => $p['price'],
                            'discounted_price' => $p['discounted_price'],
                            'stock'            => $p['stock'],
                        ]];

                        foreach ($variants as $v) {
                            $variant = new ProductVariant();
                            $variant->product_id       = $product->id;
                            $variant->type             = 'packet';
                            $variant->measurement      = $v['measurement'];
                            $variant->price            = $v['price'];
                            $variant->discounted_price = $v['discounted_price'];
                            $variant->stock            = $v['stock'];
                            $variant->stock_unit_id    = $resolveUnit($v['unit']);
                            $variant->status           = 1;
                            $variant->save();
                            $counts['variants']++;
                        }
                    }
                }
            }
        }

        $this->linkBrandsToCategories($brandCats);

        $counts['keep'] = $keep;
        return $counts;
    }

    /**
     * Older seeders left categories and sub-groups behind whose products are gone
     * (e.g. 'Atta' superseded by 'Atta & Flours'). They render as empty tiles, so
     * clear them out.
     *
     * Categories are only DEACTIVATED — a category can carry manual edits and may
     * still be referenced, so this stays reversible. Sub-groups and groups are pure
     * UI scaffolding with no user data, and a stale one points at ids that no longer
     * resolve, so those are removed outright.
     */
    private function sweepLeftovers(int $sellerId, array $keep): array
    {
        $emptyCats = Category::where('seller_id', $sellerId)
            ->whereNotIn('id', $keep['categories'] ?: [0])
            ->where('status', 1)
            ->whereNotExists(function ($q) {
                $q->select(DB::raw(1))->from('products')->whereColumn('products.category_id', 'categories.id');
            })
            ->pluck('id');

        if ($emptyCats->isNotEmpty()) {
            Category::whereIn('id', $emptyCats)->update(['status' => 0]);
        }

        $subs = CategorySubGroup::where('seller_id', $sellerId)
            ->whereNotIn('id', $keep['subgroups'] ?: [0])->pluck('id');
        if ($subs->isNotEmpty()) {
            CategorySubGroup::whereIn('id', $subs)->delete();
        }

        $groups = CategoryGroup::where('seller_id', $sellerId)
            ->whereNotIn('id', $keep['groups'] ?: [0])->pluck('id');
        if ($groups->isNotEmpty()) {
            CategoryGroup::whereIn('id', $groups)->delete();
        }

        return [
            'categories' => $emptyCats->count(),
            'subgroups'  => $subs->count(),
            'groups'     => $groups->count(),
        ];
    }

    private function makeProduct(array $p, array $ctx): Product
    {
        $slug = $this->slugify($p['name']);
        $existing = Product::where('slug', 'LIKE', "{$slug}%")->count();

        $product = new Product();
        $product->name                   = $p['name'];
        $product->slug                   = $existing ? "{$slug}-{$existing}" : $slug;
        $product->row_order              = $ctx['row'];
        $product->description            = $p['description'];
        $product->category_id            = $ctx['catId'];
        $product->category_group_id      = $ctx['groupId'];
        $product->sub_category_group_id  = $ctx['subId'];
        $product->item_type_id           = $ctx['typeId'];
        $product->store_id               = $ctx['storeId'];
        $product->seller_id              = $ctx['sellerId'];
        $product->brand_id               = $ctx['brandId'];
        $product->tags                   = mb_substr($p['tags'], 0, 190);
        $product->barcode                = $p['barcode'] ?: null;
        $product->tax_id                 = 0;
        $product->tax                    = '0.00';
        $product->type                   = 'packet';
        $product->indicator              = 1;
        $product->manufacturer           = self::MARKER;
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
        $product->image                  = $p['image'];
        $product->save();

        return $product;
    }

    /**
     * The browse query uses FIND_IN_SET(category_id, brands.category_ids), which needs a
     * PLAIN CSV. The Brand model casts category_ids to 'array' (JSON), so write the raw
     * column via the query builder to bypass the cast.
     */
    private function linkBrandsToCategories(array $brandCats): void
    {
        foreach ($brandCats as $bId => $catSet) {
            $raw = DB::table('brands')->where('id', $bId)->value('category_ids');
            $existing = array_filter(array_map('intval', preg_split('/[^0-9]+/', (string) $raw)));
            $merged = array_values(array_unique(array_merge($existing, array_keys($catSet))));
            sort($merged);
            DB::table('brands')->where('id', $bId)->update(['category_ids' => implode(',', $merged)]);
        }
    }

    /* ─────────────────────── helpers ─────────────────────── */

    private function loadSources(): array
    {
        $merged = [];
        foreach (self::SOURCES as $file) {
            $path = database_path('seeders/data/' . $file);
            if (!is_file($path)) {
                continue;
            }
            $json = json_decode((string) file_get_contents($path), true);
            foreach ($json['stores'] ?? [] as $storeId => $data) {
                // Two files never describe the same store, but merge groups defensively.
                $merged[$storeId]['groups'] = array_merge(
                    $merged[$storeId]['groups'] ?? [],
                    $data['groups'] ?? []
                );
            }
        }
        return $merged;
    }

    private function resolveSeller(int $storeId): ?Seller
    {
        foreach (self::SELLER_FOR_STORE[$storeId] ?? [] as $name) {
            $seller = Seller::where('store_id', $storeId)->where('store_name', $name)->first();
            if ($seller) {
                return $seller;
            }
        }
        // Fall back to the store's first active seller so the seeder still runs
        // on an environment where the demo sellers were renamed.
        return Seller::where('store_id', $storeId)->where('status', 1)->orderBy('id')->first();
    }

    private function clearPreviousRows(int $sellerId): int
    {
        $ids = Product::where('seller_id', $sellerId)
            ->whereIn('manufacturer', array_merge([self::MARKER], self::LEGACY_MARKERS))
            ->pluck('id');

        if ($ids->isEmpty()) {
            return 0;
        }

        ProductVariant::whereIn('product_id', $ids)->forceDelete();
        Product::whereIn('id', $ids)->forceDelete();
        return $ids->count();
    }

    private function slugify(string $name): string
    {
        $clean = preg_replace('/[^\p{L}\p{N} ]/u', '', $name);
        return trim(preg_replace('/\s+/', '-', trim($clean)), '-') ?: 'item';
    }
}
