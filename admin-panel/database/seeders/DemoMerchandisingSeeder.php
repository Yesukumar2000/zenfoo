<?php

namespace Database\Seeders;

use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The merchandising layer: everything the customer app renders around the
 * catalogue rather than in it.
 *
 *   promo_codes                    the codes demo orders already reference
 *   sliders                        home-screen carousel banners
 *   zenfoo_offers                  order-milestone reward offers
 *   brand_campaigns                "Shop the brand" hero blocks
 *   favorites / carts              so wishlists and abandoned carts aren't empty
 *   customer_app_sections(+products)  curated home rails
 *
 * Artwork comes from `zenfoo:demo-documents` (banner-*.png), which is also the
 * purge marker for the image-bearing tables: any row whose image path points at
 * images/demo-docs is ours.
 *
 * REUSE OVER DUPLICATION: sections and combos already exist on live data, so
 * this seeder fills them only when the tables are empty. It never edits a row
 * that was already there.
 */
class DemoMerchandisingSeeder extends Seeder
{
    /**
     * All demo promo codes are ZF-prefixed — that prefix is the purge marker,
     * and DemoOrderSeeder picks from the same list so orders never reference a
     * code that doesn't exist.
     */
    private const PROMOS = [
        ['code' => 'ZFWELCOME',   'message' => 'Flat Rs.100 off on your first order',        'min' => 199,  'discount' => 100, 'type' => 'amount',     'max' => 100, 'repeat' => 0],
        ['code' => 'ZF50OFF',     'message' => 'Rs.50 off on orders above Rs.399',           'min' => 399,  'discount' => 50,  'type' => 'amount',     'max' => 50,  'repeat' => 1],
        ['code' => 'ZFFRESH20',   'message' => '20% off on fruits and vegetables',           'min' => 249,  'discount' => 20,  'type' => 'percentage', 'max' => 120, 'repeat' => 1],
        ['code' => 'ZFWEEKEND15', 'message' => '15% off every weekend, up to Rs.150',        'min' => 499,  'discount' => 15,  'type' => 'percentage', 'max' => 150, 'repeat' => 1],
        ['code' => 'ZFBIGCART',   'message' => 'Rs.250 off when you spend Rs.1499 or more',  'min' => 1499, 'discount' => 250, 'type' => 'amount',     'max' => 250, 'repeat' => 1],
        ['code' => 'ZFEXPIRED',   'message' => 'Republic Day sale — now closed',             'min' => 299,  'discount' => 100, 'type' => 'amount',     'max' => 100, 'repeat' => 0, 'expired' => true],
    ];

    public function run(): void
    {
        $base = rtrim(config('app.url'), '/') . '/' . DemoWorld::DOC_DIR;

        if (!file_exists(public_path(DemoWorld::DOC_DIR . '/banner-slider-1.png'))) {
            $this->command->warn('Banner artwork missing — run: php artisan zenfoo:demo-documents');
        }

        $this->promoCodes($base);
        $this->sliders($base);
        $this->offers($base);
        $this->campaigns($base);
        $this->favouritesAndCarts();
        $this->homeSections();
    }

    /* ─────────────────────────── promo codes ─────────────────────────── */

    private function promoCodes(string $base): void
    {
        $made = 0;

        foreach (self::PROMOS as $i => $p) {
            if (DB::table('promo_codes')->where('promo_code', $p['code'])->exists()) {
                continue;
            }

            $expired = $p['expired'] ?? false;

            DB::table('promo_codes')->insert([
                'promo_code'          => $p['code'],
                'message'             => $p['message'],
                'start_date'          => $expired ? now()->subDays(120)->toDateString() : now()->subDays(30)->toDateString(),
                'end_date'            => $expired ? now()->subDays(90)->toDateString()  : now()->addDays(60)->toDateString(),
                'no_of_users'         => 1000,
                'minimum_order_amount' => $p['min'],
                'discount'            => $p['discount'],
                'discount_type'       => $p['type'],
                'max_discount_amount' => $p['max'],
                'repeat_usage'        => $p['repeat'],
                'no_of_repeat_usage'  => $p['repeat'] ? 5 : 0,
                'status'              => $expired ? 0 : 1,
                // NOT NULL with no default — must always be a string.
                'image'               => "{$base}/banner-offer-" . (($i % 3) + 1) . '.png',
                'is_specific_sellers' => 0,
                'seller_ids'          => '',
                'store_ids'           => '',
                'created_at'          => now()->subDays(30),
                'updated_at'          => now(),
            ]);
            $made++;
        }

        $this->command->info("Promo codes: {$made} created.");
    }

    /* ───────────────────────────── sliders ───────────────────────────── */

    private function sliders(string $base): void
    {
        // Point each banner at a real store so tapping it lands somewhere.
        $stores = DB::table('stores')->where('is_active', 1)->pluck('id')->all();
        $made = 0;

        for ($i = 1; $i <= 5; $i++) {
            $image = "{$base}/banner-slider-{$i}.png";
            if (DB::table('sliders')->where('image', $image)->exists()) {
                continue;
            }

            $storeId = $stores ? $stores[DemoWorld::seedOf("slider|$i") % count($stores)] : null;

            DB::table('sliders')->insert([
                'store_id'   => $storeId,
                // 'store' is the safest type: type_id is a real store id, so the
                // tap target resolves without depending on a specific product.
                'type'       => $storeId ? 'store' : 'seller',
                'type_id'    => (string) ($storeId ?: 0),
                'image'      => $image,
                'status'     => 1,
                'created_at' => now()->subDays(20 - $i),
                'updated_at' => now(),
            ]);
            $made++;
        }

        $this->command->info("Sliders: {$made} created.");
    }

    /* ───────────────────────── milestone offers ──────────────────────── */

    private function offers(string $base): void
    {
        if (!Schema::hasTable('zenfoo_offers')) {
            return;
        }

        $offers = [
            ['title' => 'Order 3, get Rs.100', 'description' => 'Place 3 orders this month and Rs.100 lands in your wallet.', 'orders' => 3, 'amount' => 100],
            ['title' => 'Order 5, get Rs.200', 'description' => 'Five orders in a month unlocks Rs.200 of wallet credit.',    'orders' => 5, 'amount' => 200],
            ['title' => 'Order 10, get Rs.500', 'description' => 'Our biggest reward — ten orders, Rs.500 back.',            'orders' => 10, 'amount' => 500],
        ];

        $made = 0;
        foreach ($offers as $i => $o) {
            if (DB::table('zenfoo_offers')->where('title', $o['title'])->exists()) {
                continue;
            }

            DB::table('zenfoo_offers')->insert([
                'title'       => $o['title'],
                'description' => $o['description'],
                'img_url'     => "{$base}/banner-offer-" . ($i + 1) . '.png',
                'order_count' => $o['orders'],
                'amount'      => $o['amount'],
                'status'      => 1,
                'start_date'  => now()->subDays(15)->toDateString(),
                'end_date'    => now()->addDays(45)->toDateString(),
                'created_at'  => now()->subDays(15),
                'updated_at'  => now(),
            ]);
            $made++;
        }

        $this->command->info("Zenfoo offers: {$made} created.");
    }

    /* ──────────────────────── brand campaigns ────────────────────────── */

    private function campaigns(string $base): void
    {
        if (!Schema::hasTable('brand_campaigns')) {
            return;
        }

        $brands = DB::table('brands')->limit(2)->get(['id', 'name']);
        if ($brands->isEmpty()) {
            $this->command->line('Brand campaigns: no brands in the catalogue — skipped.');
            return;
        }

        $made = 0;
        foreach ($brands as $i => $brand) {
            $n = $i + 1;
            $image = "{$base}/banner-campaign-{$n}.png";
            if (DB::table('brand_campaigns')->where('primary_image_url', $image)->exists()) {
                continue;
            }

            // Products actually belonging to this brand, so the campaign grid
            // isn't a random assortment.
            $productIds = DB::table('products')
                ->where('brand_id', $brand->id)
                ->whereNull('deleted_at')
                ->where('status', 1)
                ->limit(12)->pluck('id')->all();

            if (!$productIds) {
                continue;
            }

            DB::table('brand_campaigns')->insert([
                'name'              => $brand->name . ' Spotlight',
                'description'       => "Handpicked {$brand->name} products, together in one place for the week.",
                'tagline'           => 'Everything ' . $brand->name . ', one tap away',
                'primary_image_url' => $image,
                'banners'           => json_encode([$image]),
                'brand_id'          => $brand->id,
                'product_ids'       => json_encode(array_map('intval', $productIds)),
                'start_date'        => now()->subDays(7)->toDateTimeString(),
                'end_date'          => now()->addDays(21)->toDateTimeString(),
                'status'            => 1,
                'is_featured'       => $n === 1 ? 1 : 0,
                'display_order'     => $n,
                'campaign_type'     => 'brand_promotion',
                'theme_color'       => $n === 1 ? '#0f766e' : '#7c3aed',
                'created_at'        => now()->subDays(7),
                'updated_at'        => now(),
            ]);
            $made++;
        }

        $this->command->info("Brand campaigns: {$made} created.");
    }

    /* ─────────────────────── favourites and carts ────────────────────── */

    private function favouritesAndCarts(): void
    {
        $users = DB::table('users')
            ->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN)
            ->pluck('id')->all();

        if (!$users) {
            $this->command->warn('Favourites/carts: no demo customers — run DemoCustomerSeeder first.');
            return;
        }

        $variants = DB::table('product_variants as v')
            ->join('products as p', 'p.id', '=', 'v.product_id')
            ->whereNull('p.deleted_at')->whereNull('v.deleted_at')
            ->where('p.status', 1)->where('v.status', 1)
            ->limit(600)
            ->get(['v.id as variant_id', 'p.id as product_id']);

        if ($variants->isEmpty()) {
            $this->command->warn('Favourites/carts: no sellable variants — seed the catalogue first.');
            return;
        }

        $favs = 0;
        $carts = 0;

        foreach ($users as $idx => $userId) {
            $key = "merch|user|$idx";

            // ~45% of customers have saved something.
            if (DemoWorld::chance($key . '|fav', 45)) {
                $n = DemoWorld::intFor($key . '|nfav', 1, 5);
                for ($i = 0; $i < $n; $i++) {
                    $v = $variants[(DemoWorld::seedOf($key . "|f$i") + $i * 13) % $variants->count()];
                    $exists = DB::table('favorites')
                        ->where('user_id', $userId)->where('product_id', $v->product_id)->exists();
                    if ($exists) {
                        continue;
                    }
                    DB::table('favorites')->insert([
                        'user_id'    => $userId,
                        'product_id' => $v->product_id,
                        'created_at' => now()->subDays(DemoWorld::intFor($key . "|fd$i", 1, 60)),
                        'updated_at' => now(),
                    ]);
                    $favs++;
                }
            }

            // ~18% have an abandoned cart sitting there — enough to make the
            // cart-reminder notification screens meaningful, not so many that
            // every customer looks mid-checkout.
            if (DemoWorld::chance($key . '|cart', 18)) {
                $n = DemoWorld::intFor($key . '|ncart', 1, 4);
                for ($i = 0; $i < $n; $i++) {
                    $v = $variants[(DemoWorld::seedOf($key . "|c$i") + $i * 29) % $variants->count()];
                    $exists = DB::table('carts')
                        ->where('user_id', $userId)->where('product_variant_id', $v->variant_id)->exists();
                    if ($exists) {
                        continue;
                    }
                    DB::table('carts')->insert([
                        'user_id'            => $userId,
                        'product_id'         => $v->product_id,
                        'product_variant_id' => $v->variant_id,
                        'qty'                => DemoWorld::intFor($key . "|q$i", 1, 3),
                        'save_for_later'     => DemoWorld::chance($key . "|sfl$i", 20) ? 1 : 0,
                        'created_at'         => now()->subDays(DemoWorld::intFor($key . "|cd$i", 0, 6)),
                        'updated_at'         => now(),
                    ]);
                    $carts++;
                }
            }
        }

        $this->command->info("Favourites: {$favs} · cart lines: {$carts}.");
    }

    /* ───────────────────────── home rails ────────────────────────────── */

    private function homeSections(): void
    {
        if (!Schema::hasTable('customer_app_sections')) {
            return;
        }

        // Live data already has curated sections. Filling them would mean
        // editing someone else's merchandising, and there is no marker column
        // to purge by — so only seed when the table is genuinely empty.
        if (DB::table('customer_app_sections')->exists()) {
            $this->command->line('Home sections: already configured — left untouched.');
            return;
        }

        $sections = [
            ['name' => 'Best Sellers',        'order' => 1],
            ['name' => 'Fresh Picks Today',   'order' => 2],
            ['name' => 'Back in Stock',       'order' => 3],
        ];

        $products = DB::table('products')
            ->whereNull('deleted_at')->where('status', 1)
            ->limit(300)->pluck('id')->all();

        if (!$products) {
            $this->command->warn('Home sections: no products — seed the catalogue first.');
            return;
        }

        $rows = 0;
        foreach ($sections as $s) {
            $sectionId = DB::table('customer_app_sections')->insertGetId([
                'name'       => $s['name'],
                'order'      => $s['order'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            for ($i = 0; $i < 10; $i++) {
                $pid = $products[(DemoWorld::seedOf($s['name'] . "|$i") + $i * 7) % count($products)];
                DB::table('customer_app_section_products')->insert([
                    'product_id'    => $pid,
                    'section_id'    => $sectionId,
                    'display_order' => $i + 1,
                    'created_at'    => now(),
                    'updated_at'    => now(),
                ]);
                $rows++;
            }
        }

        $this->command->info('Home sections: ' . count($sections) . " created, {$rows} product rows.");
    }
}
