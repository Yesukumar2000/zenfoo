<?php

namespace App\Console\Commands;

use App\Support\StockPhotoFinder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

/**
 * Replaces encyclopedic product photos with commercial, studio-style ones.
 *
 * Wikipedia lead images are correct but they look like an encyclopedia — a
 * bunch of grapes in a field, a pomegranate juice glass. A quick-commerce grid
 * wants what Zepto and Blinkit use: the product, lit, on a clean background.
 *
 * Openverse (the WordPress-run aggregator over Flickr, Rawpixel, Wikimedia and
 * others) serves exactly that, filtered to commercially-licensed work, with no
 * API key. Queries are biased with "white background" and results are ranked by
 * resolution, so the grid gets sharp, consistent tiles.
 *
 * Every replacement is journalled to storage/app/image-upgrade-backup.json
 * BEFORE the write, so --undo restores the previous URL exactly.
 *
 *   php artisan zenfoo:upgrade-images --marker=ZFDEMO_STOCKUP --dry-run
 *   php artisan zenfoo:upgrade-images --marker=ZFDEMO_STOCKUP
 *   php artisan zenfoo:upgrade-images --ids=123,456
 *   php artisan zenfoo:upgrade-images --undo
 */
class UpgradeProductImages extends Command
{
    protected $signature = 'zenfoo:upgrade-images
        {--marker= : Only products whose manufacturer starts with this}
        {--store= : Only products in this store id}
        {--ids= : Comma-separated product ids}
        {--categories= : Comma-separated CATEGORY ids — upgrades categories.image instead}
        {--min-width=800 : Reject images narrower than this}
        {--white-only : Only accept photos whose background is actually white (border pixels are sampled)}
        {--dry-run : Show what would change, change nothing}
        {--undo : Restore every image from the backup journal, then stop}
        {--undo-last= : Restore only the last N journal entries, then stop}';

    protected $description = 'Swap encyclopedic product photos for HD commercial ones (Openverse, no API key)';

    private const UA = 'ZenfooCatalogSeeder/1.0 (kmadhu@techlanditsolutions.com)';

    private const BACKUP = 'image-upgrade-backup.json';

    /** Words that mean "not a clean product shot". */
    private const REJECT_TITLE = [
        'field', 'farm', 'plantation', 'tree', 'garden', 'market', 'harvest',
        'illustration', 'drawing', 'painting', 'vintage', 'engraving', 'sketch',
        'logo', 'sign', 'poster', 'label', 'person', 'woman', 'man', 'child',
        'recipe', 'cooked', 'curry', 'soup', 'salad', 'dish', 'plate of',
    ];

    /** Photos already used, so no two tiles share an image. */
    private array $used = [];

    public function handle(): int
    {
        if ($this->option('undo')) {
            return $this->undo();
        }
        if ($this->option('undo-last')) {
            return $this->undoLast((int) $this->option('undo-last'));
        }

        $dry = (bool) $this->option('dry-run');

        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');
        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        return $this->option('categories')
            ? $this->upgradeCategories($dry)
            : $this->upgradeProducts($dry);
    }

    /* ─────────────────────────── products ─────────────────────────── */

    private function upgradeProducts(bool $dry): int
    {
        $q = DB::table('products')->whereNull('deleted_at')->where('status', 1);

        if ($m = $this->option('marker')) {
            $q->where('manufacturer', 'LIKE', $m . '%');
        }
        if ($s = $this->option('store')) {
            $q->where('store_id', (int) $s);
        }
        if ($ids = $this->option('ids')) {
            $q->whereIn('id', array_map('intval', array_map('trim', explode(',', $ids))));
        }

        if (!$this->option('marker') && !$this->option('store') && !$this->option('ids')) {
            $this->error('Refusing to rewrite every product image. Pass --marker, --store or --ids.');
            return self::FAILURE;
        }

        $products = $q->get(['id', 'name', 'image']);
        $this->line("\n{$products->count()} product(s) in scope");

        // Seed the used-set with images already on OTHER products, so an
        // upgrade never introduces a duplicate tile.
        foreach (DB::table('products')->whereNotNull('image')->where('image', '<>', '')
            ->pluck('image') as $existing) {
            $this->used[$existing] = true;
        }

        $backup = $this->loadBackup();
        $changed = 0;
        $kept = [];

        foreach ($products as $p) {
            $best = $this->findImage($p->name);

            if (!$best) {
                $kept[] = $p->name;
                continue;
            }

            $this->line(sprintf('    %-24s %sx%s  %s', substr($p->name, 0, 24),
                $best['width'], $best['height'], substr($best['title'], 0, 40)));

            if (!$dry) {
                $backup[] = ['id' => $p->id, 'name' => $p->name, 'old' => $p->image, 'new' => $best['url']];
                DB::table('products')->where('id', $p->id)
                    ->update(['image' => $best['url'], 'updated_at' => now()]);
            }

            $this->used[$best['url']] = true;
            $changed++;
        }

        if (!$dry && $changed) {
            $this->saveBackup($backup);
        }

        $this->newLine();
        $this->info("{$changed} image(s) " . ($dry ? 'would be upgraded' : 'upgraded')
            . ($kept ? ', ' . count($kept) . ' left as-is (no better match): ' . implode(', ', array_slice($kept, 0, 10)) : ''));

        if (!$dry && $changed) {
            $this->line('  Backup: storage/app/' . self::BACKUP . '  ·  restore with --undo');
        }

        return self::SUCCESS;
    }

    /* ────────────────────────── categories ────────────────────────── */

    private function upgradeCategories(bool $dry): int
    {
        $ids = array_map('intval', array_map('trim', explode(',', $this->option('categories'))));
        $cats = DB::table('categories')->whereIn('id', $ids)->get(['id', 'name', 'image']);

        $this->line("\n{$cats->count()} category(ies) in scope");

        $backup = $this->loadBackup();
        $changed = 0;

        foreach ($cats as $c) {
            $best = $this->findImage($c->name);
            if (!$best) {
                $this->warn("    {$c->name}: no better match");
                continue;
            }

            $this->line(sprintf('    %-24s %sx%s  %s', substr($c->name, 0, 24),
                $best['width'], $best['height'], substr($best['title'], 0, 40)));

            if (!$dry) {
                $backup[] = ['category_id' => $c->id, 'name' => $c->name, 'old' => $c->image, 'new' => $best['url']];
                DB::table('categories')->where('id', $c->id)
                    ->update(['image' => $best['url'], 'updated_at' => now()]);
            }

            $this->used[$best['url']] = true;
            $changed++;
        }

        if (!$dry && $changed) {
            $this->saveBackup($backup);
        }

        $this->info("\n{$changed} category image(s) " . ($dry ? 'would be upgraded' : 'upgraded'));

        return self::SUCCESS;
    }

    /* ─────────────────────────── lookup ───────────────────────────── */

    /**
     * Best commercial photo for a product name.
     *
     * Tries the "white background" phrasing first because that is what returns
     * catalogue-style shots; falls back to the plain name so nothing is left
     * without a photo just because no studio version exists.
     *
     * @return array{url:string,width:int,height:int,title:string}|null
     */
    /**
     * Hand-checked white-background photos.
     *
     * The caption filters get the subject right most of the time but not
     * reliably: they accepted a pizza for "Basil", an apricot cake for
     * "Apricot", a Diet Cherry Soda bottle cap for "Cherry" and a blackberry
     * flower for "Blackberry". These URLs were rendered to a contact sheet and
     * confirmed by eye, so they take precedence over any search.
     */
    private const VERIFIED_WHITE = [
        'Garlic'        => 'https://images.pexels.com/photos/5973583/pexels-photo-5973583.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        'Lemon'         => 'https://images.pexels.com/photos/15554373/pexels-photo-15554373.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        'Leek'          => 'https://images.pexels.com/photos/4965038/pexels-photo-4965038.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        'Fig'           => 'https://images.pexels.com/photos/15662983/pexels-photo-15662983.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        'Passion Fruit' => 'https://images.pexels.com/photos/28882153/pexels-photo-28882153.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
    ];

    private function findImage(string $name): ?array
    {
        if (isset(self::VERIFIED_WHITE[$name])) {
            return ['url' => self::VERIFIED_WHITE[$name], 'width' => 940,
                    'height' => 0, 'title' => 'hand-verified white background'];
        }

        $clean = $this->cleanName($name);

        if (!isset($this->finder)) {
            $this->finder = new StockPhotoFinder(array_keys($this->used));
            if ($this->option('white-only')) {
                $this->finder->requireWhiteBackground();
            }
        }

        // The subject itself is the relevance requirement.
        $words = array_values(array_filter(preg_split('/\s+/', $clean)));

        // matchAll: these words are the product name itself, so every one has
        // to appear — otherwise "Snake Gourd" happily accepts "Dragon Gourd".
        $hit = $this->finder->find($clean . ' white background', $words, [], [], true);

        return $hit
            ? ['url' => $hit['url'], 'width' => $hit['w'], 'height' => 0, 'title' => $hit['title']]
            : null;
    }

    private ?StockPhotoFinder $finder = null;

    /** @return array{url:string,width:int,height:int,title:string,score:int}|null */
    private function openverse(string $query, int $minWidth, string $subject): ?array
    {
        try {
            usleep(400000); // anonymous tier is rate limited; stay polite
            $res = Http::withHeaders(['User-Agent' => self::UA])
                ->timeout(45)
                ->get('https://api.openverse.org/v1/images/', [
                    'q'            => $query,
                    'license_type' => 'commercial',
                    'page_size'    => 20,
                    'mature'       => 'false',
                ]);

            $results = $res->json('results') ?? [];
        } catch (\Throwable $e) {
            $this->warn("    openverse '{$query}' failed: " . $e->getMessage());
            return null;
        }

        $best = null;

        foreach ($results as $r) {
            $url = $r['url'] ?? null;
            $w = (int) ($r['width'] ?? 0);
            $h = (int) ($r['height'] ?? 0);
            $title = (string) ($r['title'] ?? '');

            if (!$url || !str_starts_with($url, 'https://')) {
                continue;
            }
            if (!in_array(strtolower($r['filetype'] ?? ''), ['jpg', 'jpeg', 'png'], true)) {
                continue;
            }
            if ($w < $minWidth) {
                continue;
            }
            // Extreme aspect ratios crop badly into a square tile.
            if ($h > 0 && ($w / $h > 2.2 || $h / $w > 2.2)) {
                continue;
            }
            if (isset($this->used[$url])) {
                continue;
            }

            $lower = strtolower($title);
            foreach (self::REJECT_TITLE as $bad) {
                if (str_contains($lower, $bad)) {
                    continue 2;
                }
            }

            // HARD relevance gate. Without it, ranking by resolution returns
            // the biggest file for the query rather than the right subject:
            // "dates" gave a NASA black-hole image, "ginger" gave a cat.
            // Every word of the product name must appear as a whole word.
            if (!$this->titleMatches($lower, $subject)) {
                continue;
            }

            // Catalogue-style shots first, resolution only as a tie-break.
            $studio = str_contains($lower, 'white background') || str_contains($lower, 'isolated');
            $score = ($studio ? 1_000_000_000 : 0) + $w;

            if (!$best || $score > $best['score']) {
                $best = ['url' => $url, 'width' => $w, 'height' => $h, 'title' => $title, 'score' => $score];
            }
        }

        return $best;
    }

    /**
     * Every word of the subject must appear in the title as a whole word.
     *
     * Words of 3 characters or fewer ("fig", "yam") are too easy to hit by
     * accident — "Fig-01-Amaga pseudobama" matched \bfig\b and is a flatworm —
     * so those need the word plus a produce cue.
     */
    private function titleMatches(string $lowerTitle, string $subject): bool
    {
        $words = preg_split('/\s+/', trim($subject));

        foreach ($words as $w) {
            if ($w === '') {
                continue;
            }
            if (!preg_match('/\b' . preg_quote($w, '/') . '(s|es)?\b/i', $lowerTitle)) {
                return false;
            }
        }

        $shortest = min(array_map('strlen', array_filter($words)));
        if ($shortest <= 3) {
            foreach (['fruit', 'vegetable', 'food', 'fresh', 'produce', 'white background', 'isolated'] as $cue) {
                if (str_contains($lowerTitle, $cue)) {
                    return true;
                }
            }
            return false;
        }

        return true;
    }

    /** Strip pack sizes and qualifiers so the query is just the subject. */
    private function cleanName(string $name): string
    {
        $n = strtolower($name);
        $n = preg_replace('/\(.*?\)/', ' ', $n);
        $n = preg_replace('/[-–—|,].*$/', ' ', $n);
        $n = preg_replace('/\b\d+(\.\d+)?\s*(kg|g|gm|gms|ml|l|ltr|pc|pcs|piece|pieces|pack|packet|dozen)\b/', ' ', $n);
        $n = preg_replace('/\b(fresh|organic|premium|loose|indian|desi|hybrid|country|farm|natural|raw|whole)\b/', ' ', $n);

        return trim(preg_replace('/\s+/', ' ', $n)) ?: strtolower($name);
    }

    /* ─────────────────────────── backup ───────────────────────────── */

    private function backupPath(): string
    {
        return storage_path('app/' . self::BACKUP);
    }

    private function loadBackup(): array
    {
        return file_exists($this->backupPath())
            ? (json_decode(file_get_contents($this->backupPath()), true) ?: [])
            : [];
    }

    private function saveBackup(array $rows): void
    {
        if (!is_dir(dirname($this->backupPath()))) {
            mkdir(dirname($this->backupPath()), 0755, true);
        }
        file_put_contents($this->backupPath(), json_encode($rows, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }

    /**
     * Roll back only the most recent N entries.
     *
     * Full --undo reverts everything ever journalled, which is wrong when one
     * bad run needs reversing but earlier good work should stand.
     */
    private function undoLast(int $n): int
    {
        $rows = $this->loadBackup();

        if (!$rows) {
            $this->info('No backup journal — nothing to restore.');
            return self::SUCCESS;
        }

        $n = max(1, min($n, count($rows)));
        $tail = array_slice($rows, -$n);

        $this->line("Restoring the last {$n} of " . count($rows) . " journal entries:");

        foreach (array_reverse($tail) as $r) {
            if (isset($r['table'], $r['column'])) {
                DB::table($r['table'])->where('id', $r['id'])->update([$r['column'] => $r['old']]);
            } elseif (isset($r['category_id'])) {
                DB::table('categories')->where('id', $r['category_id'])->update(['image' => $r['old']]);
            } else {
                DB::table('products')->where('id', $r['id'])->update(['image' => $r['old']]);
            }
            $this->line('  restored ' . ($r['name'] ?? ('#' . ($r['id'] ?? '?'))));
        }

        // Keep the earlier history intact.
        $this->saveBackup(array_slice($rows, 0, count($rows) - $n));

        $this->info("Restored {$n} image(s). Earlier entries left untouched.");

        return self::SUCCESS;
    }

    private function undo(): int
    {
        $rows = $this->loadBackup();

        if (!$rows) {
            $this->info('No backup journal — nothing to restore.');
            return self::SUCCESS;
        }

        $restored = 0;

        // Reverse order, so a row touched twice lands on its original value.
        foreach (array_reverse($rows) as $r) {
            if (isset($r['table'], $r['column'])) {
                // Written by zenfoo:fix-broken-assets — arbitrary table/column,
                // including sliders.status.
                DB::table($r['table'])->where('id', $r['id'])->update([$r['column'] => $r['old']]);
            } elseif (isset($r['category_id'])) {
                DB::table('categories')->where('id', $r['category_id'])->update(['image' => $r['old']]);
            } else {
                DB::table('products')->where('id', $r['id'])->update(['image' => $r['old']]);
            }
            $restored++;
        }

        @unlink($this->backupPath());
        $this->info("Restored {$restored} image(s) and cleared the journal.");

        return self::SUCCESS;
    }
}
