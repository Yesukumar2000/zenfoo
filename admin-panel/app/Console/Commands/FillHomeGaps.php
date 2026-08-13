<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Closes the empty space on the home screen.
 *
 * Three separate causes, all visible as blank areas:
 *
 *  1. Seven category groups have no sub-groups at all ("Chicks", "Cleaning
 *     things", "gulab jamun an sweets"…). They render as a heading with
 *     nothing under it. Deactivated rather than deleted — they are somebody's
 *     admin-panel rows, and status=0 is reversible.
 *
 *  2. Several groups have only two or three tiles, so the row of four has
 *     holes. Filled by wiring up categories that already have products but no
 *     tile pointing at them.
 *
 *  3. The five sliders created by the demo-world seeder point at
 *     /images/demo-docs/banner-slider-*.png, which only exist after
 *     zenfoo:demo-documents runs AND the files are deployed to the Hostinger
 *     public directory. Until then every one returns 422 and the carousel is a
 *     grey box. Repointed at hosted photos so they work without a deploy.
 *
 *   php artisan zenfoo:fill-home-gaps --dry-run
 *   php artisan zenfoo:fill-home-gaps
 *   php artisan zenfoo:fill-home-gaps --undo
 */
class FillHomeGaps extends Command
{
    protected $signature = 'zenfoo:fill-home-gaps
        {--dry-run : Report what would change, change nothing}
        {--undo : Restore sliders and groups, remove created tiles, then stop}';

    protected $description = 'Fill the empty home-screen rails and repair the broken banner carousel';

    private const JOURNAL = 'home-gaps.json';

    /** New tiles: [category group, tile name, category ids]. */
    private const TILES = [
        // Fresh Meat sits on two tiles; these are its existing admin categories.
        [9, 'Chicken Cuts', '108,109,111,113,115'],
        [9, 'Whole Chicken', '116,117'],
        // Prawns & Seafood is one short of a full row.
        [61, 'Fish Fillets', '303'],
        // Categories created earlier that nothing points at yet.
        [37, 'Mutton Family Packs', '500'],
        [39, 'Camel Family Packs', '504'],
        [8, 'Pre-Order Fruit Boxes', '514'],
        [3, 'Cut & Ready Veggies', '515'],
        [1, 'Pre-Order Monthly Essentials', '516'],
        [1, 'Bulk & Value Packs', '517'],
        [2, 'Pre-Order Festive Hampers', '518'],
        [2, 'Breakfast Combos', '519'],
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

        $journal = $this->loadJournal();

        $this->newLine();
        $this->line('<info>1. banner carousel</info>');
        $banners = json_decode(file_get_contents(database_path('data/home-banner-images.json')), true) ?: [];
        $broken = DB::table('sliders')->where('status', 1)
            ->where('image', 'LIKE', '%demo-docs/banner-slider%')
            ->orderBy('id')->get(['id', 'image']);

        $b = 0;
        foreach ($broken as $s) {
            $url = $banners[$b % max(1, count($banners))] ?? null;
            if (!$url) {
                break;
            }
            $this->line("  slider #{$s->id} — 422 → hosted photo");
            if (!$dry) {
                $journal[] = ['t' => 'slider', 'id' => $s->id, 'old' => $s->image];
                DB::table('sliders')->where('id', $s->id)->update(['image' => $url]);
            }
            $b++;
        }
        if (!$broken->count()) {
            $this->line('  none broken');
        }

        $this->newLine();
        $this->line('<info>2. tiles for short rails</info>');
        $added = 0;

        foreach (self::TILES as [$groupId, $name, $catIds]) {
            $group = DB::table('category_groups')->where('id', $groupId)->first(['id', 'name']);
            if (!$group) {
                continue;
            }
            $exists = DB::table('sub_category_groups')
                ->where('category_group_id', $groupId)
                ->whereRaw('LOWER(TRIM(name)) = ?', [mb_strtolower($name)])
                ->exists();
            if ($exists) {
                continue;
            }

            $first = (int) explode(',', $catIds)[0];
            $image = DB::table('products')->where('category_id', $first)
                ->whereNull('deleted_at')->where('status', 1)
                ->whereRaw("image <> ''")->value('image');

            if (!$image) {
                $this->warn("  {$name} — no product image in category {$first}, skipped");
                continue;
            }

            $this->line(sprintf('  %-22s → %s', $group->name, $name));

            if (!$dry) {
                $id = DB::table('sub_category_groups')->insertGetId([
                    'name'                => $name,
                    // Never 1 — the Special Items rail stays as it is.
                    'is_special_item'     => 0,
                    'is_children_allowed' => 0,
                    'seller_id'           => null,
                    'is_super_mart'       => 0,
                    'image'               => $image,
                    'subcategory_ids'     => $catIds,
                    'category_group_id'   => $groupId,
                    'is_group'            => 0,
                    'row_order'           => 9,
                    'created_at'          => now(),
                    'updated_at'          => now(),
                ]);
                $journal[] = ['t' => 'tile', 'id' => $id];
            }
            $added++;
        }

        if (!$added) {
            $this->line('  nothing to add');
        }

        $this->newLine();
        $this->line('<info>3. groups with no tiles at all</info>');
        $empty = DB::table('category_groups')
            ->where('status', 1)
            ->whereNotExists(function ($q) {
                $q->select(DB::raw(1))->from('sub_category_groups')
                    ->whereColumn('sub_category_groups.category_group_id', 'category_groups.id');
            })
            ->orderBy('id')->get(['id', 'name']);

        foreach ($empty as $g) {
            $this->line("  #{$g->id} {$g->name} — deactivated (renders as an empty heading)");
            if (!$dry) {
                $journal[] = ['t' => 'group', 'id' => $g->id, 'old' => 1];
                DB::table('category_groups')->where('id', $g->id)->update(['status' => 0]);
            }
        }
        if (!$empty->count()) {
            $this->line('  none');
        }

        if (!$dry) {
            $this->saveJournal($journal);
        }

        $this->newLine();
        $this->info(sprintf('%d banner(s), %d tile(s), %d empty group(s) %s.',
            $b, $added, $empty->count(), $dry ? 'would change' : 'changed'));
        if (!$dry) {
            $this->line('  Revert with <comment>php artisan zenfoo:fill-home-gaps --undo</comment>');
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

        $tiles = [];
        foreach (array_reverse($journal) as $r) {
            match ($r['t']) {
                'slider' => DB::table('sliders')->where('id', $r['id'])->update(['image' => $r['old']]),
                'group'  => DB::table('category_groups')->where('id', $r['id'])->update(['status' => $r['old']]),
                default  => $tiles[] = $r['id'],
            };
        }
        DB::table('sub_category_groups')->whereIn('id', $tiles ?: [0])->delete();

        @unlink($this->journalPath());
        $this->info('Restored. ' . count($tiles) . ' tile(s) removed.');

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
