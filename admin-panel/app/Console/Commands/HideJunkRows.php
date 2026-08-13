<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Hides obvious test rows so they don't show up in a client demo.
 *
 * The catalogue carries leftovers from manual testing — products named "Hhhh",
 * "test", "Tedt", "Det", "Fan", a seller called "viiiii", a brand "Wxwxx".
 * A client seeing those is worse than a blank tile, and no image fix helps.
 *
 * DEACTIVATES ONLY. Nothing is deleted, and every row's previous status is
 * journalled so --undo puts it back exactly. This changes what is visible for
 * sale, so the id list is explicit rather than a name heuristic — use --scan to
 * review candidates before adding any.
 *
 *   php artisan zenfoo:hide-junk --scan       # suggest candidates, change nothing
 *   php artisan zenfoo:hide-junk --dry-run
 *   php artisan zenfoo:hide-junk
 *   php artisan zenfoo:hide-junk --undo
 */
class HideJunkRows extends Command
{
    protected $signature = 'zenfoo:hide-junk
        {--scan : List likely test rows for review, change nothing}
        {--dry-run : Show what would be hidden, change nothing}
        {--undo : Restore every status this command changed, then stop}';

    protected $description = 'Deactivate leftover test rows (products, sellers, brands, categories)';

    private const JOURNAL = 'hide-junk-backup.json';

    /**
     * Explicit rows to hide, confirmed by eye. table => [id => label].
     * Deliberately NOT name-matched: "Fan" could be a real product elsewhere.
     */
    private function targets(): array
    {
        return [
            'products'   => [270 => 'Hhhh', 274 => 'test', 275 => 'Tedt', 276 => 'Det', 278 => 'Fan'],
            'sellers'    => [84 => 'viiiii'],
            'brands'     => [26 => 'Wxwxx'],
            'categories' => [227 => 'Super One'],
        ];
    }

    /** Names that look like keyboard-mashing or explicit test data. */
    private const SUSPICIOUS = [
        'test', 'testing', 'demo test', 'asd', 'qwe', 'zxc', 'abc',
        'xxx', 'aaa', 'bbb', 'ccc', 'ddd', 'hhh', 'sample', 'dummy',
        'new product', 'untitled', 'no name', 'temp',
    ];

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('undo')) {
            return $this->undo();
        }
        if ($this->option('scan')) {
            return $this->scan();
        }

        $dry = (bool) $this->option('dry-run');
        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $journal = $this->loadJournal();
        $hidden = 0;

        $this->newLine();

        foreach ($this->targets() as $table => $rows) {
            if (!Schema::hasTable($table) || !Schema::hasColumn($table, 'status')) {
                $this->warn("  {$table}: no status column — skipped");
                continue;
            }

            foreach ($rows as $id => $label) {
                $row = DB::table($table)->where('id', $id)->first(['id', 'status']);

                if (!$row) {
                    $this->line(sprintf('  %-12s #%-5s %-22s (row gone)', $table, $id, $label));
                    continue;
                }
                if ((int) $row->status === 0) {
                    $this->line(sprintf('  %-12s #%-5s %-22s already hidden', $table, $id, $label));
                    continue;
                }

                $this->line(sprintf('  %-12s #%-5s %-22s hide', $table, $id, $label));

                if (!$dry) {
                    $journal[] = ['table' => $table, 'id' => $id, 'name' => $label, 'old_status' => $row->status];
                    DB::table($table)->where('id', $id)->update(['status' => 0]);
                }

                $hidden++;
            }
        }

        if (!$dry && $hidden) {
            $this->saveJournal($journal);
        }

        $this->newLine();
        $this->info("{$hidden} row(s) " . ($dry ? 'would be hidden' : 'hidden')
            . '. Nothing was deleted.');

        if (!$dry && $hidden) {
            $this->line('  Restore with <comment>php artisan zenfoo:hide-junk --undo</comment>');
        }

        return self::SUCCESS;
    }

    /** Suggest more candidates without touching anything. */
    private function scan(): int
    {
        $tables = [
            'products'   => 'name',
            'categories' => 'name',
            'brands'     => 'name',
            'sellers'    => 'store_name',
        ];

        $found = 0;
        $this->newLine();

        foreach ($tables as $table => $col) {
            if (!Schema::hasTable($table) || !Schema::hasColumn($table, $col)) {
                continue;
            }

            $q = DB::table($table);
            if (Schema::hasColumn($table, 'deleted_at')) {
                $q->whereNull('deleted_at');
            }
            if (Schema::hasColumn($table, 'status')) {
                $q->where('status', 1);
            }

            foreach ($q->get(['id', $col]) as $r) {
                $name = trim((string) $r->$col);
                $lower = strtolower($name);

                $hit = false;

                // Explicit test words.
                foreach (self::SUSPICIOUS as $s) {
                    if ($lower === $s || str_starts_with($lower, $s . ' ')) {
                        $hit = true;
                        break;
                    }
                }

                // Very short, or a single repeated letter ("Hhhh", "Wxwxx").
                if (!$hit && $name !== '') {
                    $letters = preg_replace('/[^a-z]/', '', $lower);
                    if (strlen($name) <= 4 && !preg_match('/\d/', $name)) {
                        $hit = true;
                    } elseif ($letters !== '' && count(array_unique(str_split($letters))) <= 2 && strlen($letters) >= 4) {
                        $hit = true;
                    }
                }

                if ($hit) {
                    $this->line(sprintf('  %-12s #%-6s %s', $table, $r->id, $name));
                    $found++;
                }
            }
        }

        $this->newLine();
        $this->info("{$found} candidate(s). None were changed — add ids to targets() to hide them.");

        return self::SUCCESS;
    }

    private function undo(): int
    {
        $journal = $this->loadJournal();

        if (!$journal) {
            $this->info('No journal — nothing to restore.');
            return self::SUCCESS;
        }

        $restored = 0;
        foreach (array_reverse($journal) as $r) {
            DB::table($r['table'])->where('id', $r['id'])->update(['status' => $r['old_status']]);
            $restored++;
        }

        @unlink($this->journalPath());
        $this->info("Restored {$restored} row(s) to their previous status.");

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
        file_put_contents($this->journalPath(), json_encode($rows, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }
}
