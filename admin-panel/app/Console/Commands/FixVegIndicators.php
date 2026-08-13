<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Marks the meat, fish and camel catalogue non-vegetarian.
 *
 * Fifty-four products in the Chicken & Meat, Mutton, Fish and Camel stores
 * carried indicator = 1, so the app drew the green vegetarian dot on chicken,
 * mutton, prawns and fish. In an Indian storefront that is not a cosmetic
 * detail — the veg/non-veg mark is the first thing a customer looks at, and
 * getting it backwards discredits everything else on the screen.
 *
 * The bad rows came from an earlier seeder (ZENFO_QC_SEED) and were then copied
 * into the demo vendors, because cloning faithfully carries the source's
 * indicator across.
 *
 * Scope is deliberately the whole store rather than a name match: stores 14,
 * 18, 19 and 20 sell nothing vegetarian. Eggs are included — Indian apps mark
 * them non-veg.
 *
 *   php artisan zenfoo:fix-veg-flags --dry-run
 *   php artisan zenfoo:fix-veg-flags
 *   php artisan zenfoo:fix-veg-flags --undo
 */
class FixVegIndicators extends Command
{
    protected $signature = 'zenfoo:fix-veg-flags
        {--stores=14,18,19,20 : Stores whose entire catalogue is non-vegetarian}
        {--dry-run : Report what would change, change nothing}
        {--undo : Restore the previous indicators, then stop}';

    protected $description = 'Set the non-veg indicator on every meat, fish and camel product';

    private const JOURNAL = 'veg-flags.json';

    /** products.indicator: 1 = veg (green dot), 2 = non-veg (red dot). */
    private const NON_VEG = 2;

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('undo')) {
            return $this->undo();
        }

        $stores = array_map('intval', explode(',', (string) $this->option('stores')));
        $dry = (bool) $this->option('dry-run');

        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $wrong = DB::table('products')
            ->whereIn('store_id', $stores)
            ->whereNull('deleted_at')
            ->where(function ($q) {
                $q->where('indicator', '<>', self::NON_VEG)->orWhereNull('indicator');
            })
            ->orderBy('store_id')
            ->orderBy('name')
            ->get(['id', 'store_id', 'name', 'indicator']);

        if ($wrong->isEmpty()) {
            $this->info('Every product in these stores is already marked non-vegetarian.');
            return self::SUCCESS;
        }

        $journal = $this->loadJournal();

        foreach ($wrong->groupBy('store_id') as $storeId => $rows) {
            $this->newLine();
            $this->line("<info>store {$storeId}</info> — " . $rows->count() . ' product(s) marked vegetarian');

            foreach ($rows as $p) {
                if (!$dry) {
                    $journal[] = ['id' => $p->id, 'old' => $p->indicator];
                    DB::table('products')->where('id', $p->id)->update(['indicator' => self::NON_VEG]);
                }
            }

            $this->line('    ' . $rows->take(6)->pluck('name')->implode(', ')
                . ($rows->count() > 6 ? ', +' . ($rows->count() - 6) . ' more' : ''));
        }

        if (!$dry) {
            $this->saveJournal($journal);
        }

        $this->newLine();
        $this->info($wrong->count() . ' product(s) ' . ($dry ? 'would be' : '') . ' set to non-vegetarian.');
        if (!$dry) {
            $this->line('  Revert with <comment>php artisan zenfoo:fix-veg-flags --undo</comment>');
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

        foreach (array_reverse($journal) as $r) {
            DB::table('products')->where('id', $r['id'])->update(['indicator' => $r['old']]);
        }

        @unlink($this->journalPath());
        $this->info('Restored ' . count($journal) . ' indicator(s).');

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
