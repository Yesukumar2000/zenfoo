<?php

namespace Database\Seeders;

use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Stocks the demo vendors' shops.
 *
 * DemoVendorSeeder creates the vendor accounts but no catalogue, so a demo
 * vendor logging into the seller app sees an empty shop and the storefront is
 * blank in the customer app. This clones a slice of the existing catalogue into
 * each demo vendor's own store — same images, names, categories and pack sizes,
 * but owned by the demo seller, with its own prices and stock.
 *
 * Source products are picked from the vendor's OWN store_id, so a seafood
 * vendor gets fish and a supermart vendor gets groceries.
 *
 * Every cloned row is tagged in `manufacturer` with the demo marker, so --purge
 * removes exactly these and nothing from the real catalogue.
 */
class DemoVendorProductSeeder extends Seeder
{
    /** Written to products.manufacturer — the purge marker. */
    public const PRODUCT_MARKER = DemoWorld::MARKER . '_VENDOR_STOCK';

    /** Products cloned per demo vendor. */
    private const PER_VENDOR = 40;

    public function run(): void
    {
        $vendors = DB::table('sellers')
            ->where('email', 'LIKE', '%@' . DemoWorld::EMAIL_DOMAIN)
            ->get(['id', 'store_name', 'store_id', 'city_id']);

        if ($vendors->isEmpty()) {
            $this->command->error('No demo vendors found. Run DemoVendorSeeder first.');
            return;
        }

        $totalProducts = 0;
        $totalVariants = 0;

        foreach ($vendors as $vendor) {
            $key = 'vstock|' . $vendor->id;

            // Source pool: real, sellable products in the same store, never
            // another demo vendor's clones.
            $sources = DB::table('products')
                ->where('store_id', $vendor->store_id)
                ->where('status', 1)
                ->whereNull('deleted_at')
                ->where(function ($q) {
                    $q->whereNull('manufacturer')
                        ->orWhere('manufacturer', 'NOT LIKE', self::PRODUCT_MARKER . '%');
                })
                ->whereRaw("image <> ''")
                ->inRandomOrder()
                ->limit(self::PER_VENDOR)
                ->get();

            if ($sources->isEmpty()) {
                $this->command->warn("  {$vendor->store_name}: no source products in store {$vendor->store_id} — skipped");
                continue;
            }

            $made = 0;
            $variantsMade = 0;

            DB::transaction(function () use ($vendor, $sources, $key, &$made, &$variantsMade) {
                foreach ($sources as $i => $src) {
                    $skey = "$key|$i";

                    $slug = Str::slug($src->name) . '-d' . $vendor->id . '-' . $i;
                    if (DB::table('products')->where('slug', $slug)->exists()) {
                        continue;
                    }

                    $newId = DB::table('products')->insertGetId([
                        'seller_id'             => $vendor->id,
                        'row_order'             => $i + 1,
                        'name'                  => $src->name,
                        'tags'                  => $src->tags,
                        'tax_id'                => $src->tax_id,
                        'brand_id'              => $src->brand_id,
                        'slug'                  => $slug,
                        'category_id'           => $src->category_id,
                        'sub_category_group_id' => $src->sub_category_group_id,
                        'category_group_id'     => $src->category_group_id,
                        'store_id'              => $vendor->store_id,
                        'item_type_id'          => $src->item_type_id,
                        'tax'                   => $src->tax,
                        'indicator'             => $src->indicator,
                        // The purge marker. Also what tells you, in the admin
                        // panel, that this row is seeded rather than real.
                        'manufacturer'          => self::PRODUCT_MARKER,
                        'made_in'               => $src->made_in ?: 'India',
                        'return_status'         => $src->return_status,
                        'cancelable_status'     => $src->cancelable_status,
                        'image'                 => $src->image,
                        'other_images'          => $src->other_images,
                        'description'           => $src->description,
                        'status'                => 1,
                        'is_approved'           => 1,
                        'return_days'           => $src->return_days,
                        'type'                  => $src->type,
                        'is_unlimited_stock'    => 0,
                        'is_pre_order_item'     => 0,
                        'is_skinned_one'        => $src->is_skinned_one,
                        'is_cleaned'            => $src->is_cleaned,
                        'cod_allowed'           => 1,
                        'total_allowed_quantity' => DemoWorld::intFor($skey . '|maxq', 5, 20),
                        'tax_included_in_price' => $src->tax_included_in_price,
                        'fssai_lic_no'          => $src->fssai_lic_no ?: '',
                        'barcode'               => $src->barcode,
                        'created_at'            => now()->subDays(DemoWorld::intFor($skey . '|age', 5, 120)),
                        'updated_at'            => now(),
                    ]);
                    $made++;

                    // Variants: same pack sizes, price nudged +/-8% so two demo
                    // shops selling the same SKU aren't identical to the rupee.
                    $srcVariants = DB::table('product_variants')
                        ->where('product_id', $src->id)
                        ->whereNull('deleted_at')
                        ->get();

                    foreach ($srcVariants as $vi => $sv) {
                        $factor = 1 + (DemoWorld::intFor($skey . "|p$vi", -8, 8) / 100);
                        $price = max(5, round($sv->price * $factor, 2));
                        $disc = $sv->discounted_price > 0
                            ? max(1, round($sv->discounted_price * $factor, 2))
                            : 0;

                        DB::table('product_variants')->insert([
                            'product_id'       => $newId,
                            'type'             => $sv->type,
                            'status'           => 1,
                            'measurement'      => $sv->measurement,
                            'price'            => $price,
                            'discounted_price' => $disc < $price ? $disc : 0,
                            'stock'            => DemoWorld::intFor($skey . "|s$vi", 8, 150),
                            'stock_unit_id'    => $sv->stock_unit_id,
                        ]);
                        $variantsMade++;
                    }
                }
            });

            $this->command->line("  {$vendor->store_name}: {$made} products, {$variantsMade} variants");
            $totalProducts += $made;
            $totalVariants += $variantsMade;
        }

        $this->command->info("Vendor stock: {$totalProducts} products, {$totalVariants} variants across {$vendors->count()} demo vendors.");
    }
}
