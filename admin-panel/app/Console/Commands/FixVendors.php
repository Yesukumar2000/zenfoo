<?php

namespace App\Console\Commands;

use App\Support\StockPhotoFinder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Two specific storefront corrections requested after reviewing the app:
 *
 *  - BPK Events is an events/decor business whose imagery is floral staging,
 *    not food. Deactivated rather than re-photographed.
 *  - CinnaMan's Café's logo is a stock photo of a Reliance Industries office
 *    block. Replaced with a café photo.
 *
 * Status changes and the previous logo are journalled, so --undo restores both
 * exactly. Nothing is deleted.
 *
 *   php artisan zenfoo:fix-vendors --dry-run
 *   php artisan zenfoo:fix-vendors
 *   php artisan zenfoo:fix-vendors --undo
 */
class FixVendors extends Command
{
    protected $signature = 'zenfoo:fix-vendors
        {--dry-run : Report what would change, change nothing}
        {--empty : Also deactivate every active vendor that has zero live products}
        {--store-images : Copy the (already corrected) logo into store_images, which is what the restaurant cards render}
        {--list-empty : Just list the empty vendors, change nothing}
        {--undo : Restore vendor status and logo from the journal, then stop}';

    protected $description = 'Deactivate BPK Events and replace the CinnaMan\'s Café logo';

    private const JOURNAL = 'vendor-fixes.json';

    /** Vendors to deactivate: [id, name, reason]. */
    private const DEACTIVATE = [
        [99, 'BPK Events', 'events/decor business, imagery is not food'],
    ];

    /**
     * Sellers whose store_images still hold the wrong picture.
     *
     * These four had their `logo` corrected, but the customer app's restaurant
     * cards render `store_images[0]`, so the old image stayed on screen —
     * a Reliance Industries office block for CinnaMan's Café and a screenshot
     * of a competitor's grocery app for Sugar Silo.
     */
    private const STORE_IMAGE_SELLERS = [
        32 => "CinnaMan's Café",
        45 => 'Masala Magic',
        62 => 'Sugar Silo',
        96 => 'Maharaja chat',
    ];

    /** Vendors needing a new logo: [id, name, what is wrong, query, must-match words]. */
    private const RELOGO = [
        [32, "CinnaMan's Café", 'logo is a Reliance Industries office block',
         'cafe coffee shop interior', ['cafe', 'coffee', 'espresso', 'bakery']],
    ];

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('undo')) {
            return $this->undo();
        }
        if ($this->option('list-empty')) {
            return $this->listEmpty();
        }

        $dry = (bool) $this->option('dry-run');
        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $journal = $this->loadJournal();
        $changed = 0;

        $this->newLine();
        $this->line('<info>deactivate</info>');

        foreach (self::DEACTIVATE as [$id, $name, $why]) {
            $row = DB::table('sellers')->where('id', $id)->first(['id', 'store_name', 'status']);
            if (!$row) {
                $this->warn("  #{$id} {$name} — not found");
                continue;
            }
            if ((int) $row->status === 0) {
                $this->line("  #{$id} {$name} — already inactive");
                continue;
            }

            $this->line("  #{$id} {$name} — {$why}");

            if (!$dry) {
                $journal[] = ['type' => 'status', 'id' => $id, 'name' => $name, 'old' => $row->status];
                DB::table('sellers')->where('id', $id)->update(['status' => 0]);
            }
            $changed++;
        }

        $this->newLine();
        $this->line('<info>replace logo</info>');

        $finder = new StockPhotoFinder();

        foreach (self::RELOGO as [$id, $name, $why, $query, $words]) {
            $row = DB::table('sellers')->where('id', $id)->first(['id', 'store_name', 'logo']);
            if (!$row) {
                $this->warn("  #{$id} {$name} — not found");
                continue;
            }

            $hit = $finder->find($query, $words);
            if (!$hit) {
                $this->warn("  #{$id} {$name} — no suitable photo found");
                continue;
            }

            $this->line(sprintf('  #%-4s %-18s %5dpx  %s', $id, $name, $hit['w'], substr($hit['title'], 0, 34)));
            $this->line("        was: {$why}");

            if (!$dry) {
                $journal[] = ['type' => 'logo', 'id' => $id, 'name' => $name, 'old' => $row->logo];
                DB::table('sellers')->where('id', $id)->update(['logo' => $hit['url']]);
            }
            $changed++;
        }

        if ($this->option('store-images')) {
            $this->newLine();
            $this->line('<info>store_images</info> (what the restaurant cards actually render)');

            // The Top Rated / Nearby Restaurant cards read store_images, NOT
            // logo. Fixing only the logo left the Reliance Industries building
            // and the competitor-app screenshot still on screen.
            foreach (self::STORE_IMAGE_SELLERS as $id => $label) {
                $row = DB::table('sellers')->where('id', $id)->first(['id', 'store_name', 'logo', 'store_images']);
                if (!$row) {
                    $this->warn("  #{$id} {$label} — not found");
                    continue;
                }
                if (!$row->logo || !str_contains((string) $row->logo, 'pexels.com')) {
                    $this->warn("  #{$id} {$label} — logo is not a corrected image yet, skipped");
                    continue;
                }

                $new = json_encode([$row->logo]);
                if ($row->store_images === $new) {
                    $this->line("  #{$id} {$label} — already matches");
                    continue;
                }

                $this->line("  #{$id} {$label} — store_images ← corrected logo");

                if (!$dry) {
                    $journal[] = ['type' => 'store_images', 'id' => $id,
                                  'name' => $label, 'old' => $row->store_images];
                    DB::table('sellers')->where('id', $id)->update(['store_images' => $new]);
                }
                $changed++;
            }
        }

        if ($this->option('empty')) {
            $this->newLine();
            $this->line('<info>empty vendors</info> (active, zero live products)');

            foreach ($this->emptyVendors() as $v) {
                $this->line(sprintf('  #%-4s %s', $v->id, $v->store_name ?: '(no name)'));

                if (!$dry) {
                    $journal[] = ['type' => 'status', 'id' => $v->id,
                                  'name' => $v->store_name ?: '(no name)', 'old' => $v->status];
                    DB::table('sellers')->where('id', $v->id)->update(['status' => 0]);
                }
                $changed++;
            }
        }

        if (!$dry && $changed) {
            $this->saveJournal($journal);
        }

        $this->newLine();
        $this->info("{$changed} change(s) " . ($dry ? 'would be applied' : 'applied') . '. Nothing deleted.');
        if (!$dry && $changed) {
            $this->line('  Revert with <comment>php artisan zenfoo:fix-vendors --undo</comment>');
        }

        return self::SUCCESS;
    }

    /**
     * Active vendors with no live products.
     *
     * A storefront with nothing to sell is dead weight in the vendor list, and
     * on this data they are almost all test signups — "(no name)", "Ggg",
     * "Stote", "bbbbv", "bhjjjh". Zero-product is used as the rule rather than
     * name matching, because it is objective and cannot catch a real shop that
     * simply has an odd name.
     */
    private function emptyVendors()
    {
        return DB::table('sellers')
            ->whereNull('deleted_at')
            ->where('status', 1)
            ->whereNotExists(function ($q) {
                $q->select(DB::raw(1))->from('products')
                    ->whereColumn('products.seller_id', 'sellers.id')
                    ->whereNull('products.deleted_at')
                    ->where('products.status', 1);
            })
            ->orderBy('id')
            ->get(['id', 'store_name', 'status']);
    }

    private function listEmpty(): int
    {
        $rows = $this->emptyVendors();

        $this->newLine();
        foreach ($rows as $v) {
            $this->line(sprintf('  #%-4s %s', $v->id, $v->store_name ?: '(no name)'));
        }

        $this->newLine();
        $this->info($rows->count() . ' active vendor(s) with zero live products. Nothing changed.');
        $this->line('  Deactivate them with <comment>php artisan zenfoo:fix-vendors --empty</comment>');

        return self::SUCCESS;
    }

    private function undo(): int
    {
        $journal = $this->loadJournal();
        if (!$journal) {
            $this->info('No journal — nothing to restore.');
            return self::SUCCESS;
        }

        $n = 0;
        foreach (array_reverse($journal) as $r) {
            $col = match ($r['type']) {
                'status'       => 'status',
                'store_images' => 'store_images',
                default        => 'logo',
            };
            DB::table('sellers')->where('id', $r['id'])->update([$col => $r['old']]);
            $n++;
        }

        @unlink($this->journalPath());
        $this->info("Restored {$n} vendor field(s).");

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
