<?php

namespace App\Console\Commands;

use App\Support\StockPhotoFinder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Repairs assets that render blank or broken in the customer app.
 *
 * Two distinct faults, both found by looking at the app on a real phone:
 *
 *  1. 22 rows across products, categories, sliders, sellers, brands and
 *     thinking_items point at `zenfoo-bucket-01.s3.ap-southeast-2.amazonaws.com`,
 *     which now returns **403 Forbidden**. Those tiles are blank in the app.
 *  2. Slider #27 is a 147x149 px image stretched across the full screen width,
 *     so it renders as a pixelated smear.
 *
 * Meaningful rows get a real photo from Openverse (commercially licensed, no
 * API key). Broken banners are hidden rather than patched — a missing slider
 * looks better than a pixelated one.
 *
 * Every change is journalled to the same file `zenfoo:upgrade-images` uses, so
 * `php artisan zenfoo:upgrade-images --undo` reverts all of it.
 *
 *   php artisan zenfoo:fix-broken-assets --dry-run
 *   php artisan zenfoo:fix-broken-assets
 */
class FixBrokenAssets extends Command
{
    protected $signature = 'zenfoo:fix-broken-assets
        {--dry-run : Report what would change, change nothing}
        {--seller-logos : Also replace vendor logos whose uploaded image is wrong}
        {--scan : Only list assets on the dead S3 bucket, then stop}';

    protected $description = 'Repair blank/broken images (dead S3 bucket, undersized sliders)';

    private const UA = 'ZenfooCatalogSeeder/1.0 (kmadhu@techlanditsolutions.com)';

    private const DEAD_HOST = 'zenfoo-bucket-01';

    /** Photos already chosen this run, so no two tiles share one. */
    private array $used = [];

    /**
     * Rows worth repairing, with the search subject and the words that must
     * appear in a candidate's title for it to count as relevant.
     *
     * table => [ [id, column, label, subject, must-match words], ... ]
     */
    private function targets(): array
    {
        return [
            'thinking_items' => [
                [6, 'img_url', 'Briyani', 'biryani rice dish', ['biryani', 'biriyani', 'pilaf', 'rice']],
                [7, 'img_url', 'Burgers', 'hamburger',         ['burger', 'hamburger']],
            ],
            'products' => [
                [273, 'image', 'Apple',      'apple fruit',       ['apple']],
                [277, 'image', 'Tomatoes',   'tomato',            ['tomato']],
                [76,  'image', 'Full meals', 'indian thali meal', ['thali', 'meal', 'lunch', 'curry']],
                [269, 'image', 'Tea cup',    'tea cup',           ['tea']],
            ],
            'categories' => [
                [224, 'image', 'Vegetables', 'fresh vegetables', ['vegetable']],
                [226, 'image', 'Grocery',    'grocery items',    ['grocery', 'groceries']],
                [223, 'image', 'Cups',       'cup',              ['cup', 'mug']],
            ],
            'sellers' => [
                [86, 'logo', 'Dreamy Delight Cake and snacks', 'bakery cake', ['cake', 'bakery', 'pastry']],
            ],
        ];
    }

    /**
     * Vendor logos whose URL works fine but whose CONTENT is wrong — spotted by
     * looking at Top Rated Restaurants on a real phone.
     *
     * Behind --seller-logos because this overwrites a vendor's own upload,
     * which is a different kind of change from repairing a dead link.
     *
     * [id, label, why, search subject, must-match words]
     */
    private const SELLER_LOGOS = [
        [62, 'Sugar Silo',    'a screenshot of a competitor grocery app', 'indian sweets mithai', ['sweet', 'mithai', 'dessert', 'laddu']],
        [96, 'Maharaja chat', 'a blank grey surface',                     'indian street food chaat', ['chaat', 'street food', 'snack', 'samosa']],
        [45, 'Masala Magic',  'a photo of blue fabric',                   'indian food thali curry', ['thali', 'curry', 'indian food', 'biryani']],
        [99, 'BPK Events',    'floral event decor, not food',             'catering buffet food', ['buffet', 'catering', 'food']],
    ];

    /** Sliders to hide, with the reason. */
    private const HIDE_SLIDERS = [
        27 => '147x149 px stretched to full width',
        41 => 'image on the dead S3 bucket',
    ];

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('scan')) {
            return $this->scan();
        }

        $dry = (bool) $this->option('dry-run');
        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $backup = $this->loadBackup();
        $fixed = 0;
        $failed = [];

        $this->newLine();

        foreach ($this->targets() as $table => $rows) {
            if (!Schema::hasTable($table)) {
                continue;
            }

            foreach ($rows as [$id, $col, $label, $subject, $words]) {
                $current = DB::table($table)->where('id', $id)->value($col);
                if ($current === null) {
                    $failed[] = "{$table}#{$id} (row missing)";
                    continue;
                }

                $hit = $this->findImage($subject, $words);
                if (!$hit) {
                    $failed[] = "{$label} (no relevant photo)";
                    continue;
                }

                $this->line(sprintf('  %-15s #%-5s %-24s %5dpx  %s',
                    $table, $id, substr($label, 0, 24), $hit['w'], substr($hit['title'], 0, 32)));

                if (!$dry) {
                    $backup[] = [
                        'table' => $table, 'id' => $id, 'column' => $col,
                        'name' => $label, 'old' => $current, 'new' => $hit['url'],
                    ];
                    DB::table($table)->where('id', $id)->update([$col => $hit['url']]);
                }

                $fixed++;
            }
        }

        if ($this->option('seller-logos')) {
            $this->newLine();
            $this->line('<info>vendor logos</info> (content wrong, URL fine)');

            foreach (self::SELLER_LOGOS as [$id, $label, $why, $subject, $words]) {
                $current = DB::table('sellers')->where('id', $id)->value('logo');
                if ($current === null) {
                    continue;
                }

                $hit = $this->findImage($subject, $words);
                if (!$hit) {
                    $failed[] = "{$label} (no relevant photo)";
                    continue;
                }

                $this->line(sprintf('  #%-4s %-16s %5dpx  was: %s', $id, $label, $hit['w'], $why));

                if (!$dry) {
                    $backup[] = ['table' => 'sellers', 'id' => $id, 'column' => 'logo',
                                 'name' => $label, 'old' => $current, 'new' => $hit['url']];
                    DB::table('sellers')->where('id', $id)->update(['logo' => $hit['url']]);
                }

                $fixed++;
            }
        }

        $this->newLine();
        $this->line('<info>sliders</info>');

        foreach (self::HIDE_SLIDERS as $sid => $why) {
            $s = DB::table('sliders')->where('id', $sid)->first(['id', 'status']);
            if (!$s) {
                continue;
            }
            if ((int) $s->status === 0) {
                $this->line("  #{$sid} already hidden");
                continue;
            }

            $this->line("  #{$sid} hide — {$why}");

            if (!$dry) {
                $backup[] = ['table' => 'sliders', 'id' => $sid, 'column' => 'status',
                             'name' => "slider {$sid}", 'old' => $s->status, 'new' => 0];
                DB::table('sliders')->where('id', $sid)->update(['status' => 0]);
            }

            $fixed++;
        }

        if (!$dry && $fixed) {
            $this->saveBackup($backup);
        }

        $this->newLine();
        $this->info("{$fixed} fix(es) " . ($dry ? 'would be applied' : 'applied')
            . ($failed ? '. Unresolved: ' . implode(', ', $failed) : '.'));

        if (!$dry && $fixed) {
            $this->line('  Revert everything with <comment>php artisan zenfoo:upgrade-images --undo</comment>');
        }

        return self::SUCCESS;
    }

    /** List every row still pointing at the dead bucket. */
    private function scan(): int
    {
        $cols = [
            'products' => ['image', 'name'], 'categories' => ['image', 'name'],
            'sliders' => ['image', 'type'], 'sellers' => ['logo', 'store_name'],
            'thinking_items' => ['img_url', 'name'], 'brands' => ['image', 'name'],
            'stores' => ['image', 'name'], 'combos' => ['image', 'name'],
        ];

        $total = 0;
        foreach ($cols as $table => [$col, $label]) {
            if (!Schema::hasTable($table) || !Schema::hasColumn($table, $col)) {
                continue;
            }
            $rows = DB::table($table)->where($col, 'LIKE', '%' . self::DEAD_HOST . '%')->get(['id', $label]);
            foreach ($rows as $r) {
                $this->line(sprintf('  %-15s #%-6s %s', $table, $r->id, $r->$label));
                $total++;
            }
        }

        $this->info("\n{$total} asset(s) on the dead S3 bucket (403 Forbidden).");

        return self::SUCCESS;
    }

    /* ─────────────────────────── lookup ───────────────────────────── */

    /**
     * Pexels first, Openverse as the key-less fallback.
     *
     * This used to query Openverse directly, which is why "Burgers" and
     * "Briyani" never resolved — Openverse has little food photography, while
     * Pexels has thousands of both.
     *
     * @return array{url:string,title:string,w:int,source:string}|null
     */
    private function findImage(string $subject, array $mustWords): ?array
    {
        if (!isset($this->finder)) {
            $seed = DB::table('products')->whereNotNull('image')
                ->where('image', '<>', '')->pluck('image')->all();
            $this->finder = new StockPhotoFinder($seed);
        }

        return $this->finder->find($subject, $mustWords);
    }

    private ?StockPhotoFinder $finder = null;

    /* ─────────────────────────── backup ───────────────────────────── */

    private function backupPath(): string
    {
        return storage_path('app/image-upgrade-backup.json');
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
}
