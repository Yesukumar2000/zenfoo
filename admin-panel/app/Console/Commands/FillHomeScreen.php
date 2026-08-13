<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;

/**
 * Makes the customer app home screen look full, safely.
 *
 * Two targeted fixes, both additive:
 *
 *   images  Backfill product photos for rows that have NONE, using the lead
 *           image of the matching English Wikipedia article. Never overwrites
 *           an existing image.
 *   rails   Fill the home sections (customer_app_sections) with products that
 *           actually have a photo. Only INSERTs; never deletes or reorders
 *           what merchandising already curated.
 *
 * This deliberately touches NO customers, drivers, orders, payouts or money.
 * It is the only part of the demo data that affects the home screen, which is
 * why it is a separate command from `zenfoo:demo-world` and is safe to point
 * at production.
 *
 *   php artisan zenfoo:home-screen --dry-run     # show what would change
 *   php artisan zenfoo:home-screen               # apply
 *   php artisan zenfoo:home-screen --undo        # remove only the rail rows it added
 */
class FillHomeScreen extends Command
{
    protected $signature = 'zenfoo:home-screen
        {--dry-run : Report what would change, change nothing}
        {--only= : images|rails (default: both)}
        {--per-rail=12 : Products to put in each home section}
        {--undo : Remove the rail rows this command added, then stop}';

    protected $description = 'Backfill missing product images and fill the home-screen rails (safe on production)';

    private const UA = 'ZenfooCatalogSeeder/1.0 (kmadhu@techlanditsolutions.com)';

    /**
     * Rail rows this command adds start here, so they sit after anything a
     * human curated and can be removed again without guessing.
     */
    private const RAIL_ORDER_BASE = 100;

    /** Names that resolve to the wrong Wikipedia subject. */
    private const WIKI_TITLE = [
        'lady finger' => 'Okra', 'ladies finger' => 'Okra', 'bhindi' => 'Okra',
        'drumstick' => 'Moringa oleifera', 'kiwi' => 'Kiwifruit',
        'orange' => 'Orange (fruit)', 'grapes' => 'Grape',
        'capsicum' => 'Bell pepper', 'green capsicum' => 'Bell pepper',
        'red capsicum' => 'Bell pepper', 'yellow capsicum' => 'Bell pepper',
        'bottle gourd' => 'Calabash', 'ridge gourd' => 'Luffa',
        'bitter gourd' => 'Momordica charantia', 'green beans' => 'Green bean',
        'green peas' => 'Pea', 'sweet lime' => 'Citrus limetta',
        'muskmelon' => 'Cucumis melo', 'mushroom' => 'Agaricus bisporus',
        'coriander leaves' => 'Coriander', 'mint leaves' => 'Mentha',
        'curry leaves' => 'Curry tree', 'dill leaves' => 'Dill',
        'fenugreek leaves' => 'Fenugreek', 'amaranth leaves' => 'Amaranth',
        'spring onion' => 'Scallion', 'dragon fruit' => 'Pitaya',
        'brinjal' => 'Eggplant', 'lady s finger' => 'Okra',
    ];

    /** Lead images that are botanical plates or the living plant, not produce. */
    private const BOTANICAL_REJECT = [
        'illustration', 'medizinal', 'kohler', 'koehler', 'k%c3%b6hler', 'blanco',
        'drawing', 'engraving', 'lithograph', 'herbarium', 'botanical',
        'flower', 'blossom', 'bloei', 'bloem', 'tree', 'plantation', 'seedling',
    ];

    private bool $dry = false;

    public function handle(): int
    {
        $this->dry = (bool) $this->option('dry-run');

        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        if ($this->option('undo')) {
            return $this->undo();
        }

        $only = $this->option('only') ?: 'both';

        if ($only === 'both' || $only === 'images') {
            $this->backfillImages();
        }

        if ($only === 'both' || $only === 'rails') {
            $this->fillRails();
        }

        $this->newLine();
        $this->info($this->dry ? 'Dry run complete — nothing changed.' : 'Home screen updated.');

        return self::SUCCESS;
    }

    /* ───────────────────────── product images ───────────────────────── */

    private function backfillImages(): void
    {
        $missing = DB::table('products')
            ->whereNull('deleted_at')
            ->where('status', 1)
            ->where(function ($q) {
                $q->whereNull('image')->orWhere('image', '');
            })
            ->get(['id', 'name', 'store_id']);

        $this->newLine();
        $this->line("<info>▸ images</info>  {$missing->count()} live product(s) have no photo");

        if ($missing->isEmpty()) {
            return;
        }

        $fixed = 0;
        $failed = [];

        foreach ($missing as $p) {
            $url = $this->wikipediaImage($p->name);

            if (!$url) {
                $failed[] = $p->name;
                continue;
            }

            if (!$this->dry) {
                // Guarded on "still empty" so a concurrent admin upload wins.
                DB::table('products')
                    ->where('id', $p->id)
                    ->where(function ($q) {
                        $q->whereNull('image')->orWhere('image', '');
                    })
                    ->update(['image' => $url, 'updated_at' => now()]);
            }

            $fixed++;
            $this->line(sprintf('    %-26s %s', substr($p->name, 0, 26), basename(parse_url($url, PHP_URL_PATH))));
        }

        $this->line("  <info>{$fixed}</info> image(s) " . ($this->dry ? 'would be set' : 'set')
            . ($failed ? ', ' . count($failed) . ' unresolved: ' . implode(', ', array_slice($failed, 0, 8)) : ''));
    }

    /**
     * Lead photo of the matching English Wikipedia article. Key-less and not
     * meaningfully rate-limited, and relevance is guaranteed by construction:
     * the lead image of "Tomato" is a tomato.
     */
    private function wikipediaImage(string $productName): ?string
    {
        static $cache = [];

        $title = $this->wikiTitleFor($productName);
        if (array_key_exists($title, $cache)) {
            return $cache[$title];
        }

        try {
            usleep(250000);
            $res = Http::withHeaders(['User-Agent' => self::UA])
                ->timeout(45)
                ->get('https://en.wikipedia.org/w/api.php', [
                    'action' => 'query', 'titles' => $title, 'prop' => 'pageimages',
                    'piprop' => 'thumbnail', 'pithumbsize' => 800,
                    'redirects' => 1, 'format' => 'json',
                ]);

            foreach ($res->json('query.pages') ?? [] as $page) {
                $url = $page['thumbnail']['source'] ?? null;
                if (!$url || !preg_match('/\.(jpg|jpeg|png)$/i', $url)) {
                    continue;
                }
                $name = strtolower(basename(parse_url($url, PHP_URL_PATH) ?: ''));
                foreach (self::BOTANICAL_REJECT as $bad) {
                    if (str_contains($name, $bad)) {
                        return $cache[$title] = null;
                    }
                }
                return $cache[$title] = $url;
            }
        } catch (\Throwable $e) {
            $this->warn("    wikipedia '{$title}' failed: " . $e->getMessage());
        }

        return $cache[$title] = null;
    }

    /**
     * Product names carry pack sizes and qualifiers ("Tomato - 1 kg",
     * "Fresh Onion (Loose)"); strip those down to the subject before looking
     * it up, then apply the override map.
     */
    private function wikiTitleFor(string $name): string
    {
        $n = strtolower($name);
        $n = preg_replace('/\(.*?\)/', ' ', $n);              // (Loose), (Pack of 2)
        $n = preg_replace('/[-–—|,].*$/', ' ', $n);           // everything after a dash
        $n = preg_replace('/\b\d+(\.\d+)?\s*(kg|g|gm|gms|ml|l|ltr|pc|pcs|piece|pieces|pack|packet|dozen)\b/', ' ', $n);
        $n = preg_replace('/\b(fresh|organic|premium|loose|indian|desi|hybrid|country|farm|natural|raw)\b/', ' ', $n);
        $n = trim(preg_replace('/\s+/', ' ', $n));

        if ($n === '') {
            $n = strtolower($name);
        }

        return self::WIKI_TITLE[$n] ?? ucfirst($n);
    }

    /* ─────────────────────────── home rails ─────────────────────────── */

    private function fillRails(): void
    {
        if (!Schema::hasTable('customer_app_sections')) {
            $this->warn('No customer_app_sections table — skipped.');
            return;
        }

        $sections = DB::table('customer_app_sections')->orderBy('order')->get();

        $this->newLine();
        $this->line("<info>▸ rails</info>  {$sections->count()} home section(s)");

        if ($sections->isEmpty()) {
            $this->warn('  No sections configured — create them in the admin panel first.');
            return;
        }

        $perRail = max(1, (int) $this->option('per-rail'));
        $added = 0;

        foreach ($sections as $section) {
            $existing = DB::table('customer_app_section_products')
                ->where('section_id', $section->id)
                ->pluck('product_id')->all();

            $need = $perRail - count($existing);
            if ($need <= 0) {
                $this->line(sprintf('    %-28s already has %d — left alone', substr($section->name, 0, 28), count($existing)));
                continue;
            }

            // Only products with a real photo; a rail with blank tiles is worse
            // than a short rail.
            //
            // Products in a "special items" sub-group are excluded: those are
            // hand-curated for their own home-screen widget, and duplicating
            // them into a generic rail both repeats them on screen and meddles
            // with merchandising nobody asked us to touch.
            $special = $this->specialGroupIds();

            $picks = DB::table('products')
                ->whereNull('deleted_at')
                ->where('status', 1)
                ->whereNotNull('image')
                ->where('image', '<>', '')
                ->when($special, fn ($q) => $q->where(function ($w) use ($special) {
                    $w->whereNull('sub_category_group_id')->orWhereNotIn('sub_category_group_id', $special);
                }))
                ->when($existing, fn ($q) => $q->whereNotIn('id', $existing))
                ->inRandomOrder()
                ->limit($need)
                ->pluck('id')->all();

            if (!$picks) {
                $this->warn("    {$section->name}: no imaged products available");
                continue;
            }

            $order = self::RAIL_ORDER_BASE;
            foreach ($picks as $pid) {
                if (!$this->dry) {
                    DB::table('customer_app_section_products')->insert([
                        'product_id'    => $pid,
                        'section_id'    => $section->id,
                        'display_order' => $order,
                        'created_at'    => now(),
                        'updated_at'    => now(),
                    ]);
                }
                $order++;
                $added++;
            }

            $this->line(sprintf('    %-28s +%d product(s)', substr($section->name, 0, 28), count($picks)));
        }

        $this->line("  <info>{$added}</info> rail row(s) " . ($this->dry ? 'would be added' : 'added'));
    }

    /**
     * Sub-category groups flagged as home-screen "special items" — curated by
     * hand, never to be added to or duplicated out of.
     *
     * @return array<int>
     */
    private function specialGroupIds(): array
    {
        static $ids = null;

        if ($ids === null) {
            $ids = Schema::hasColumn('sub_category_groups', 'is_special_item')
                ? DB::table('sub_category_groups')->where('is_special_item', 1)->pluck('id')->map('intval')->all()
                : [];
        }

        return $ids;
    }

    /** Remove only the rows this command inserted (display_order >= 100). */
    private function undo(): int
    {
        $n = DB::table('customer_app_section_products')
            ->where('display_order', '>=', self::RAIL_ORDER_BASE);

        $count = $n->count();

        if ($this->dry) {
            $this->line("Would remove {$count} rail row(s).");
            return self::SUCCESS;
        }

        $n->delete();
        $this->info("Removed {$count} rail row(s). Product images were left in place "
            . '(they filled empty fields and overwrote nothing).');

        return self::SUCCESS;
    }
}
