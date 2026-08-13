<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Makes the home screen's "Pre Order" rail actually show the pre-order ranges.
 *
 * The rail is built in BasicApiController from products that have
 * is_pre_order_item = 1 AND a non-null sub_category_group_id, and it renders
 * the SUB CATEGORY GROUP, not the category. The pre-order products created by
 * zenfoo:extend-meat-cats and zenfoo:add-preorder-cats have
 * sub_category_group_id = NULL, so the rail showed a single tile — "Camel
 * Meat", from one older product that happened to have the field set.
 *
 * This creates one sub_category_group per pre-order category and points the
 * products at it.
 *
 * Two limits worth knowing, both in the API rather than the data:
 *
 *  - The rail filters on meat stores only (`where('is_meat', true)`), so the
 *    grocery, produce, supermart and food pre-order ranges cannot appear in it
 *    however they are tagged. They are still reachable by browsing their store.
 *  - is_special_item is set to 0 on every row created here, so nothing joins
 *    the Special Items rail, which was to be left alone.
 *
 *   php artisan zenfoo:wire-preorder-rail --dry-run
 *   php artisan zenfoo:wire-preorder-rail
 *   php artisan zenfoo:wire-preorder-rail --undo
 */
class WirePreorderRail extends Command
{
    protected $signature = 'zenfoo:wire-preorder-rail
        {--dry-run : Report what would change, change nothing}
        {--undo : Remove the groups and unset the products, then stop}';

    protected $description = 'Wire the pre-order categories into the home screen Pre Order rail';

    private const JOURNAL = 'preorder-rail.json';

    /**
     * store => category group the new sub-group belongs under.
     *
     * These are the existing meat groups the home screen already renders:
     * Fresh Meat, Fresh Mutton, Fresh Fish, Camel Meat.
     */
    private const GROUP_FOR_STORE = [
        14 => 9,
        18 => 37,
        19 => 38,
        20 => 39,
    ];

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

        // Only meat stores can surface in the rail, so only they are wired.
        $meatStores = DB::table('stores')->where('is_meat', 1)->where('is_active', 1)->pluck('id')->all();

        $targets = DB::table('products as p')
            ->join('categories as c', 'c.id', '=', 'p.category_id')
            ->where('p.is_pre_order_item', 1)
            ->where('p.status', 1)
            ->whereNull('p.deleted_at')
            ->whereNull('p.sub_category_group_id')
            ->whereIn('p.store_id', $meatStores)
            ->groupBy('p.store_id', 'p.category_id', 'c.name')
            ->select('p.store_id', 'p.category_id', 'c.name', DB::raw('COUNT(*) as n'), DB::raw('MIN(p.image) as image'))
            ->get();

        if ($targets->isEmpty()) {
            $this->info('Every pre-order product in a meat store is already wired.');
            return self::SUCCESS;
        }

        $journal = $this->loadJournal();
        $wired = 0;

        foreach ($targets as $t) {
            $groupId = self::GROUP_FOR_STORE[$t->store_id] ?? null;
            if (!$groupId) {
                $this->warn("  store {$t->store_id} — no category group mapped, skipped");
                continue;
            }

            $this->line(sprintf('  store %-3s %-32s %d product(s) → new sub-group under group %d',
                $t->store_id, $t->name, $t->n, $groupId));

            if ($dry) {
                $wired += $t->n;
                continue;
            }

            DB::transaction(function () use ($t, $groupId, &$journal, &$wired) {
                $scgId = DB::table('sub_category_groups')->insertGetId([
                    'name'              => $t->name,
                    // Never 1: the Special Items rail is to be left as it is.
                    'is_special_item'   => 0,
                    'is_children_allowed' => 0,
                    'seller_id'         => null,
                    'is_super_mart'     => 0,
                    'image'             => $t->image,
                    'subcategory_ids'   => (string) $t->category_id,
                    'category_group_id' => $groupId,
                    'is_group'          => 0,
                    'row_order'         => 1,
                    'created_at'        => now(),
                    'updated_at'        => now(),
                ]);
                $journal[] = ['t' => 'group', 'id' => $scgId];

                $ids = DB::table('products')
                    ->where('store_id', $t->store_id)
                    ->where('category_id', $t->category_id)
                    ->where('is_pre_order_item', 1)
                    ->whereNull('deleted_at')
                    ->pluck('id');

                foreach ($ids as $id) {
                    $journal[] = ['t' => 'product', 'id' => $id];
                }

                DB::table('products')->whereIn('id', $ids)->update(['sub_category_group_id' => $scgId]);
                $wired += $ids->count();
            });
        }

        if (!$dry && $wired) {
            $this->saveJournal($journal);
        }

        $this->newLine();
        $this->info("{$wired} pre-order product(s) " . ($dry ? 'would be wired' : 'wired') . ' into the Pre Order rail.');

        $nonMeat = DB::table('products')
            ->where('is_pre_order_item', 1)->where('status', 1)->whereNull('deleted_at')
            ->whereNotIn('store_id', $meatStores)->count();

        if ($nonMeat) {
            $this->newLine();
            $this->warn("  {$nonMeat} pre-order product(s) sit outside the meat stores.");
            $this->line('  The rail filters on is_meat in BasicApiController, so they cannot appear');
            $this->line('  in it without an API change. They still show inside their own store.');
        }

        if (!$dry && $wired) {
            $this->line('  Revert with <comment>php artisan zenfoo:wire-preorder-rail --undo</comment>');
        }

        return self::SUCCESS;
    }

    private function undo(): int
    {
        $journal = $this->loadJournal();
        if (!$journal) {
            $this->info('No journal — nothing to restore.');
            return self::SUCCESS;
        }

        $products = $groups = [];
        foreach ($journal as $r) {
            $r['t'] === 'product' ? $products[] = $r['id'] : $groups[] = $r['id'];
        }

        DB::table('products')->whereIn('id', $products ?: [0])->update(['sub_category_group_id' => null]);
        DB::table('sub_category_groups')->whereIn('id', $groups ?: [0])->delete();

        @unlink($this->journalPath());
        $this->info(sprintf('Unset %d product(s), removed %d sub-group(s).', count($products), count($groups)));

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
