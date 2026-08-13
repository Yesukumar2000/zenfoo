<?php

namespace App\Console\Commands;

use Database\Seeders\DemoCustomerSeeder;
use Database\Seeders\DemoDriverSeeder;
use Database\Seeders\DemoMerchandisingSeeder;
use Database\Seeders\DemoOrderSeeder;
use Database\Seeders\DemoVendorProductSeeder;
use Database\Seeders\DemoVendorSeeder;
use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Builds (or removes) the Zenfoo demo world: vendors, customers, drivers and
 * 90 days of orders on top of the catalogue that `zenfoo:fetch-catalog` +
 * QuickCommerceCatalogSeeder already produce.
 *
 *   php artisan zenfoo:demo-world              # build
 *   php artisan zenfoo:demo-world --only=orders
 *   php artisan zenfoo:demo-world --purge      # remove everything it made
 *
 * SAFETY
 * ------
 * The command refuses to run against a database that looks like the live
 * Hostinger one unless you pass --i-know-this-is-live. That guard exists
 * because .env in this repo currently points at production even though
 * APP_ENV=local — see DemoWorld::looksLikeProduction().
 *
 * Everything it writes is marker-tagged, so --purge deletes exactly its own
 * rows and leaves real signups alone.
 */
class SeedDemoWorld extends Command
{
    protected $signature = 'zenfoo:demo-world
        {--purge : Delete every row the demo world created, then stop}
        {--only= : Comma-separated stages: vendors,stock,customers,drivers,orders,merchandising}
        {--dry-run : Do everything inside a transaction, report the exact row counts, then roll back}
        {--i-know-this-is-live : Required to run against the production database}';

    protected $description = 'Seed or purge the Zenfoo demo world (vendors, customers, drivers, orders, merchandising)';

    /**
     * Stages that create rows the live apps will act on: demo vendors become
     * orderable, demo drivers enter the dispatch pool, and demo orders land in
     * real revenue / payout / earnings reports. Refused on production unless
     * explicitly confirmed.
     */
    private const RISKY_ON_LIVE = ['vendors', 'customers', 'drivers', 'orders'];

    /** Every table the seeders touch — used for the dry-run delta report. */
    private const TOUCHED_TABLES = [
        'admins', 'sellers', 'seller_bank_accounts', 'users', 'user_addresses',
        'delivery_boys', 'delivery_boy_documents', 'delivery_boy_emergency_contacts',
        'delivery_boy_store_location', 'delivery_boy_transactions', 'vehicles',
        'store_locations', 'cities', 'orders', 'order_items', 'transactions',
        'wallet_transactions', 'product_ratings', 'promo_codes', 'sliders',
        'zenfoo_offers', 'brand_campaigns', 'favorites', 'carts',
        'customer_app_sections', 'customer_app_section_products', 'model_has_roles',
    ];

    public function handle(): int
    {
        $conn = config('database.default');
        $host = config("database.connections.$conn.host");
        $name = config("database.connections.$conn.database");

        $isLive = DemoWorld::looksLikeProduction();
        $dryRun = (bool) $this->option('dry-run');

        $this->line("Database: <comment>{$name}</comment> @ <comment>{$host}</comment>"
            . ($isLive ? '  <fg=red>[LIVE]</>' : ''));

        if ($isLive && !$this->option('i-know-this-is-live')) {
            $this->error('This looks like the LIVE Hostinger database.');
            $this->line('  .env has APP_ENV=local but DB_HOST points at production.');
            $this->line('  Point DB_* at a local database, or re-run with --i-know-this-is-live.');
            $this->line('  To see what WOULD be written without writing it:');
            $this->line('    <comment>php artisan zenfoo:demo-world --dry-run --i-know-this-is-live</comment>');
            return self::FAILURE;
        }

        if ($this->option('purge')) {
            return $this->purge();
        }

        $stages = [
            'vendors'       => DemoVendorSeeder::class,
            // Stocks the demo vendors' shops; must follow 'vendors' and precede
            // 'orders', which builds baskets out of whatever is sellable.
            'stock'         => DemoVendorProductSeeder::class,
            'customers'     => DemoCustomerSeeder::class,
            'drivers'       => DemoDriverSeeder::class,
            'orders'        => DemoOrderSeeder::class,
            // Last: it links promo codes, favourites and carts to rows the
            // earlier stages create.
            'merchandising' => DemoMerchandisingSeeder::class,
        ];

        $only = $this->option('only')
            ? array_map('trim', explode(',', $this->option('only')))
            : array_keys($stages);

        $only = array_values(array_filter($only, function ($s) use ($stages) {
            if (isset($stages[$s])) {
                return true;
            }
            $this->warn("Unknown stage '{$s}' — skipped.");
            return false;
        }));

        if (!$only) {
            $this->error('No valid stages selected.');
            return self::FAILURE;
        }

        // On a live database, writing people and orders needs a second, explicit yes.
        if ($isLive && !$dryRun) {
            $risky = array_intersect($only, self::RISKY_ON_LIVE);
            if ($risky) {
                $this->newLine();
                $this->error('These stages write rows the live apps will act on:');
                foreach ($risky as $s) {
                    $this->line('  - ' . $s . ': ' . $this->riskNote($s));
                }
                $this->newLine();
                $this->line('Safer: <comment>--only=merchandising</comment>, or seed a local copy of the dump.');
                $this->newLine();

                if (!$this->confirm('Write these to PRODUCTION anyway?', false)) {
                    $this->line('Nothing written.');
                    return self::SUCCESS;
                }
            }
        }

        if ($dryRun) {
            return $this->dryRun($stages, $only);
        }

        foreach ($only as $stage) {
            $this->newLine();
            $this->line("<info>▸ {$stage}</info>");
            $this->call('db:seed', ['--class' => $stages[$stage], '--force' => true]);
        }

        $this->newLine();
        $this->info('Demo world ready.');
        $this->line('  Documents: run <comment>php artisan zenfoo:demo-documents</comment> if the KYC images are missing.');
        $this->line('  Purge any time with <comment>php artisan zenfoo:demo-world --purge</comment>.');

        return self::SUCCESS;
    }

    private function riskNote(string $stage): string
    {
        return match ($stage) {
            'vendors'   => 'demo shops become visible and orderable by real customers',
            'customers' => 'fake accounts appear in customer counts and marketing exports',
            'drivers'   => 'demo riders join the dispatch pool and can be assigned real orders',
            'orders'    => 'fake orders land in revenue reports, seller payouts and driver earnings',
            default     => '',
        };
    }

    /**
     * Run the real seeders inside a transaction, measure the row deltas, then
     * roll back. This actually executes every INSERT, so the numbers are exact
     * and any constraint violation surfaces here rather than on the real run.
     *
     * Safe to point at production: nothing is committed. All the tables
     * involved are InnoDB, and the seeders' own DB::transaction() calls nest as
     * savepoints inside this one.
     */
    private function dryRun(array $stages, array $only): int
    {
        $this->newLine();
        $this->line('<comment>DRY RUN</comment> — everything below is rolled back at the end.');

        $before = $this->counts();
        $failed = null;

        DB::beginTransaction();
        try {
            foreach ($only as $stage) {
                $this->newLine();
                $this->line("<info>▸ {$stage}</info>");
                $this->call('db:seed', ['--class' => $stages[$stage], '--force' => true]);
            }
            $after = $this->counts();
        } catch (\Throwable $e) {
            $failed = $e;
            $after = $before;
        } finally {
            DB::rollBack();
        }

        $this->newLine();

        if ($failed) {
            $this->error('Dry run FAILED — nothing was written.');
            $this->line('  ' . $failed->getMessage());
            return self::FAILURE;
        }

        $this->line('<info>Would write:</info>');
        $any = false;
        foreach ($after as $table => $count) {
            $delta = $count - ($before[$table] ?? 0);
            if ($delta !== 0) {
                $this->line(sprintf('  %-34s %+d', $table, $delta));
                $any = true;
            }
        }
        if (!$any) {
            $this->line('  (nothing — the demo world is already present)');
        }

        $this->newLine();
        $this->info('Rolled back. Database is unchanged.');

        return self::SUCCESS;
    }

    /** @return array<string,int> table => row count, for tables that exist */
    private function counts(): array
    {
        $out = [];
        foreach (self::TOUCHED_TABLES as $table) {
            if (Schema::hasTable($table)) {
                $out[$table] = (int) DB::table($table)->count();
            }
        }
        return $out;
    }

    /**
     * Delete in reverse dependency order. Every WHERE clause keys off a marker
     * this command's seeders wrote, so a real seller/user/order can't be caught
     * by it even if the ids overlap.
     */
    private function purge(): int
    {
        if (!$this->confirm('Delete every demo-world row (vendors, customers, drivers, orders)?', false)) {
            $this->line('Nothing removed.');
            return self::SUCCESS;
        }

        $demoUserIds   = DB::table('users')->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN)->pluck('id');
        $demoOrderIds  = DB::table('orders')->where('orders_id', 'LIKE', DemoWorld::MARKER . '%')->pluck('id');
        $demoSellerIds = DB::table('sellers')->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN)->pluck('id');
        $demoDriverIds = DB::table('delivery_boys')->where('remark', 'LIKE', DemoWorld::MARKER . '%')->pluck('id');

        $adminIds = DB::table('admins')->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN)->pluck('id');

        // Demo artwork all lives under this path — it is the marker for every
        // merchandising row that carries an image.
        $art = '%' . DemoWorld::DOC_DIR . '%';

        $removed = [];

        $del = function (string $table, callable $where) use (&$removed) {
            if (!Schema::hasTable($table)) {
                return;
            }
            $n = $where(DB::table($table))->delete();
            if ($n) {
                $removed[$table] = ($removed[$table] ?? 0) + $n;
            }
        };

        // ── merchandising ────────────────────────────────────────────────
        $del('promo_codes', fn ($q) => $q->where('promo_code', 'LIKE', 'ZF%'));
        $del('sliders', fn ($q) => $q->where('image', 'LIKE', $art));
        $del('zenfoo_offers', fn ($q) => $q->where('img_url', 'LIKE', $art));
        $del('brand_campaigns', fn ($q) => $q->where('primary_image_url', 'LIKE', $art));

        // Home rails are only ever created into an empty table, so these exact
        // names can only be ours.
        $railNames = ['Best Sellers', 'Fresh Picks Today', 'Back in Stock'];
        if (Schema::hasTable('customer_app_sections')) {
            $railIds = DB::table('customer_app_sections')->whereIn('name', $railNames)->pluck('id');
            if ($railIds->isNotEmpty()) {
                $del('customer_app_section_products', fn ($q) => $q->whereIn('section_id', $railIds));
                $del('customer_app_sections', fn ($q) => $q->whereIn('name', $railNames));
            }
        }

        // ── order tail ───────────────────────────────────────────────────
        if ($demoOrderIds->isNotEmpty()) {
            $del('order_items', fn ($q) => $q->whereIn('order_id', $demoOrderIds));
            $del('delivery_boy_transactions', fn ($q) => $q->whereIn('order_id', $demoOrderIds));
            $del('wallet_transactions', fn ($q) => $q->whereIn('order_id', $demoOrderIds));
            $del('transactions', fn ($q) => $q->whereIn('order_id', $demoOrderIds->map(fn ($i) => (string) $i)));
        }
        $del('orders', fn ($q) => $q->where('orders_id', 'LIKE', DemoWorld::MARKER . '%'));

        // ── customer tail ────────────────────────────────────────────────
        if ($demoUserIds->isNotEmpty()) {
            $del('product_ratings', fn ($q) => $q->whereIn('user_id', $demoUserIds));
            $del('order_product_ratings', fn ($q) => $q->whereIn('user_id', $demoUserIds));
            $del('user_addresses', fn ($q) => $q->whereIn('user_id', $demoUserIds));
            $del('wallet_transactions', fn ($q) => $q->whereIn('user_id', $demoUserIds));
            $del('favorites', fn ($q) => $q->whereIn('user_id', $demoUserIds));
            $del('carts', fn ($q) => $q->whereIn('user_id', $demoUserIds));
        }
        $del('users', fn ($q) => $q->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN));

        // ── drivers ──────────────────────────────────────────────────────
        if ($demoDriverIds->isNotEmpty()) {
            $del('delivery_boy_documents', fn ($q) => $q->whereIn('delivery_boy_id', $demoDriverIds));
            $del('delivery_boy_emergency_contacts', fn ($q) => $q->whereIn('delivery_boy_id', $demoDriverIds));
            $del('delivery_boy_store_location', fn ($q) => $q->whereIn('delivery_boy_id', $demoDriverIds));
            $del('delivery_boy_transactions', fn ($q) => $q->whereIn('delivery_boy_id', $demoDriverIds));
        }
        $del('delivery_boys', fn ($q) => $q->where('remark', 'LIKE', DemoWorld::MARKER . '%'));

        // ── vendors ──────────────────────────────────────────────────────
        // Cloned vendor stock first: variants, then the products themselves.
        $stockIds = Schema::hasTable('products')
            ? DB::table('products')
                ->where('manufacturer', 'LIKE', DemoVendorProductSeeder::PRODUCT_MARKER . '%')
                ->pluck('id')
            : collect();

        if ($stockIds->isNotEmpty()) {
            $del('product_variants', fn ($q) => $q->whereIn('product_id', $stockIds));
            $del('products', fn ($q) => $q->whereIn('id', $stockIds));
        }

        if ($demoSellerIds->isNotEmpty()) {
            $del('seller_bank_accounts', fn ($q) => $q->whereIn('seller_id', $demoSellerIds));
        }
        $del('sellers', fn ($q) => $q->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN));

        // ── logins ───────────────────────────────────────────────────────
        if ($adminIds->isNotEmpty()) {
            $del('model_has_roles', fn ($q) => $q->where('model_type', 'App\\Models\\Admin')->whereIn('model_id', $adminIds));
        }
        $del('admins', fn ($q) => $q->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN));

        // ── hubs ─────────────────────────────────────────────────────────
        $del('store_locations', fn ($q) => $q->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN));

        if (!$removed) {
            $this->info('Nothing to remove — the demo world is not present.');
            return self::SUCCESS;
        }

        foreach ($removed as $table => $n) {
            $this->line(sprintf('  %-34s %d', $table, $n));
        }
        $this->info('Demo world removed. Cities and vehicles were left in place (harmless, and real data may reference them).');

        return self::SUCCESS;
    }
}
