<?php

namespace App\Console\Commands;

use App\Support\StockPhotoFinder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Fills out the meat, fish and camel sections so the home screen looks stocked.
 *
 * PLACEMENT: everything lands in a NON-special category by default —
 * "Fresh Chicken", "Fresh Mutton", "Lamb & Offal", "Fresh Fish",
 * "Prawns & Shellfish" — so the hand-curated Special Items widget is untouched.
 *
 * The one exception is Camel: store 20 has only the special "Camel Meat"
 * category, so camel items REQUIRE --allow-special. Existing rows are never
 * modified either way; this only inserts.
 *
 * IMAGES: meat is where Wikipedia fails badly — its lead image for "Quail" is a
 * live bird and for "Rabbit meat" a live rabbit, which looks wrong on a
 * butcher's storefront. So photos come from Openverse with butchery-specific
 * queries and a live-animal reject list.
 *
 *   php artisan zenfoo:add-meat-items --dry-run
 *   php artisan zenfoo:add-meat-items
 *   php artisan zenfoo:add-meat-items --allow-special      # includes camel
 *   php artisan zenfoo:add-meat-items --undo
 */
class AddMeatItems extends Command
{
    protected $signature = 'zenfoo:add-meat-items
        {--dry-run : Show what would be added, add nothing}
        {--allow-special : Permit inserts into a special-items category (needed for Camel)}
        {--only= : Comma-separated store ids}
        {--undo : Remove everything this command added, then stop}';

    protected $description = 'Add chicken, mutton, fish and camel products with proper butchery photos';

    public const MARKER = 'ZFDEMO_MEAT';

    private const UA = 'ZenfooCatalogSeeder/1.0 (kmadhu@techlanditsolutions.com)';

    /**
     * A butcher's counter sells RAW product. Two failure modes to exclude:
     *
     *  - the animal alive ("portrait of brown goat", "flock", "swimming")
     *  - the finished dish ("lamb biryani", "tuna salad", "shrimp sushi",
     *    "grilled fish") — appetising, but it is a restaurant photo, not a
     *    product shot, and a customer cannot buy it by the kilo.
     */
    private const REJECT = [
        // The animal alive.
        'live ', 'alive', 'farm', 'field', 'flock', 'herd', 'wildlife', 'zoo',
        'aquarium', 'swimming', 'underwater', 'reef', 'pasture', 'grazing',
        'standing', 'browsing', 'portrait', 'hen', 'rooster', 'chick ', 'feather',
        // A finished dish — appetising, but not sold by the kilo.
        'grilled', 'fried', 'roasted', 'baked', 'barbecue', 'bbq', 'cooked',
        'curry', 'biryani', 'biriyani', 'sushi', 'sashimi', 'salad', 'soup',
        'stew', 'kebab', 'kabab', 'skewer', 'samosa', 'sandwich', 'burger',
        'pizza', 'pasta', 'platter', 'poke', 'bowl', 'kabsa', 'restaurant',
        // Not a photo of the product at all.
        'illustration', 'drawing', 'painting', 'logo', 'cartoon', 'diagram',
        'portal', 'butcher shop',
    ];
    // NOTE: deliberately NOT rejecting 'garnished with', 'delicious', 'dish' or
    // 'served'. Pexels captions its best product shots as e.g. "Raw chicken
    // breasts garnished with rosemary" — banning those words threw away exactly
    // the images we want. The positive 'raw'/'fillet' requirement carries the
    // filtering instead.

    /**
     * HAND-VERIFIED photos.
     *
     * Automated caption matching failed repeatedly here — across 31 candidates
     * it returned eggs for "chicken liver", a live lamb for "mutton chops", a
     * live camel for "camel meat", raw beef for tuna, and cooked dishes for
     * most of the rest. Free stock libraries simply do not carry Indian
     * butchery and seafood product photography at this granularity.
     *
     * So these URLs were chosen by rendering every candidate to a contact sheet
     * and LOOKING at it. Each one below has been visually confirmed to show the
     * right thing. Do not swap them for a search call.
     *
     * product name => Pexels URL
     */
    private const VERIFIED_IMAGE = [
        // raw chicken breasts on a board with tomatoes
        'Chicken Breast Boneless'    => 'https://images.pexels.com/photos/7368041/pexels-photo-7368041.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        // raw herb-seasoned chicken
        'Chicken Curry Cut Fresh'    => 'https://images.pexels.com/photos/9219086/pexels-photo-9219086.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        // raw rack of lamb chops with rosemary
        'Mutton Chops Fresh'         => 'https://images.pexels.com/photos/36691281/pexels-photo-36691281.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        // raw red meat steak on a wooden board
        'Mutton Boneless Cubes'      => 'https://images.pexels.com/photos/1314041/pexels-photo-1314041.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        // fresh whole fish stacked on ice
        'Fresh Fish Whole Cut'       => 'https://images.pexels.com/photos/14879230/pexels-photo-14879230.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        // raw meat hanging on a butcher's hook
        'Camel Meat Curry Cut Fresh' => 'https://images.pexels.com/photos/5643415/pexels-photo-5643415.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        // butcher slicing raw red meat
        'Camel Meat Steak Cut'       => 'https://images.pexels.com/photos/36829374/pexels-photo-36829374.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
        // raw minced red meat on a plate
        'Camel Keema Mince'          => 'https://images.pexels.com/photos/32986453/pexels-photo-32986453.jpeg?auto=compress&cs=tinysrgb&h=650&w=940',
    ];

    /**
     * store => category name => [ [product name, search query, must-match words, ₹/kg], ... ]
     *
     * Category names are resolved to the real row, so placement is by meaning
     * rather than by copying whatever product happened to be first.
     */
    private function catalogue(): array
    {
        // Only items with a hand-verified photo. Adding more would mean either
        // a blank tile or a wrong one, and on a butcher's counter both look
        // worse than a shorter list.
        return [
            14 => ['Fresh Chicken' => [
                ['Chicken Breast Boneless', '', [], 340],
                ['Chicken Curry Cut Fresh', '', [], 280],
            ]],

            18 => ['Fresh Mutton' => [
                ['Mutton Chops Fresh',    '', [], 940],
                ['Mutton Boneless Cubes', '', [], 980],
            ]],

            19 => ['Fresh Fish' => [
                ['Fresh Fish Whole Cut', '', [], 320],
            ]],

            20 => ['Camel Meat' => [
                ['Camel Meat Curry Cut Fresh', '', [], 720],
                ['Camel Meat Steak Cut',       '', [], 760],
                ['Camel Keema Mince',          '', [], 700],
            ]],
        ];
    }

    /** Kept for items that fall back to a live search. */
    private const FISH_PRICE = [];

    private array $used = [];

    private ?StockPhotoFinder $photoFinder = null;

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

        // Never reuse a photo already on the catalogue.
        foreach (DB::table('products')->whereNotNull('image')->where('image', '<>', '')->pluck('image') as $img) {
            $this->used[$img] = true;
        }

        $catalogue = $this->catalogue();
        if ($only = $this->option('only')) {
            $ids = array_map('intval', array_map('trim', explode(',', $only)));
            $catalogue = array_intersect_key($catalogue, array_flip($ids));
        }

        $madeTotal = 0;
        $skipped = [];

        foreach ($catalogue as $storeId => $byCategory) {
            $storeName = DB::table('stores')->where('id', $storeId)->value('name') ?? "store {$storeId}";
            $this->newLine();
            $this->line("<info>▸ {$storeName}</info> (store {$storeId})");

            foreach ($byCategory as $categoryName => $items) {
                $place = $this->resolvePlacement($storeId, $categoryName);

                if (!$place) {
                    $this->warn("    {$categoryName}: category not found in this store — skipped");
                    continue;
                }

                if ($place->is_special && !$this->option('allow-special')) {
                    $this->warn("    {$categoryName}: is a SPECIAL ITEMS category — skipped."
                        . ' Re-run with --allow-special to include it.');
                    continue;
                }

                $this->line("    <comment>{$categoryName}</comment>"
                    . ($place->is_special ? ' (special — inserting by explicit request)' : ''));

                foreach ($items as $spec) {
                    [$name, $query, $words] = $spec;
                    $price = $spec[3] ?? self::FISH_PRICE[$name] ?? 400;

                    if (DB::table('products')->where('store_id', $storeId)->where('name', $name)->exists()) {
                        continue;
                    }

                    // A hand-checked photo always wins over a live search.
                    $image = isset(self::VERIFIED_IMAGE[$name])
                        ? ['url' => self::VERIFIED_IMAGE[$name], 'title' => 'hand-verified', 'w' => 940]
                        : $this->findPhoto($query, $words);

                    if (!$image) {
                        $skipped[] = $name;
                        continue;
                    }

                    $this->line(sprintf('      %-28s %5dpx  %s', substr($name, 0, 28),
                        $image['w'], substr($image['title'], 0, 30)));

                    if (!$dry) {
                        $this->insertProduct($storeId, $place, $name, $image['url'], (int) $price);
                    }

                    $madeTotal++;
                }
            }
        }

        $this->newLine();
        $this->info("{$madeTotal} product(s) " . ($dry ? 'would be added' : 'added')
            . ($skipped ? '. No usable photo for: ' . implode(', ', $skipped) : '.'));

        if (!$dry && $madeTotal) {
            $this->line('  Remove again with <comment>php artisan zenfoo:add-meat-items --undo</comment>');
        }

        return self::SUCCESS;
    }

    /** Resolve the category row plus the group ids an existing product uses. */
    private function resolvePlacement(int $storeId, string $categoryName)
    {
        return DB::table('products as p')
            ->join('categories as c', 'c.id', '=', 'p.category_id')
            ->leftJoin('sub_category_groups as g', 'g.id', '=', 'p.sub_category_group_id')
            ->where('p.store_id', $storeId)
            ->where('c.name', $categoryName)
            ->whereNull('p.deleted_at')
            ->selectRaw('p.category_id, p.category_group_id, p.sub_category_group_id,
                         COALESCE(g.is_special_item, 0) as is_special,
                         p.tax_id, p.tax, p.indicator, p.cod_allowed,
                         p.tax_included_in_price, p.fssai_lic_no, p.type')
            ->first();
    }

    private function insertProduct(int $storeId, $place, string $name, string $image, int $pricePerKg): void
    {
        $productId = DB::table('products')->insertGetId([
            'seller_id'              => null,
            'row_order'              => 600,
            'name'                   => $name,
            'tags'                   => $name,
            'tax_id'                 => $place->tax_id,
            'brand_id'               => 0,
            'slug'                   => Str::slug($name) . '-' . $storeId,
            'category_id'            => $place->category_id,
            'category_group_id'      => $place->category_group_id,
            'sub_category_group_id'  => $place->sub_category_group_id,
            'store_id'               => $storeId,
            'tax'                    => $place->tax,
            // Meat and fish are non-veg; 2 is the non-veg indicator.
            'indicator'              => $place->indicator ?: 2,
            'manufacturer'           => self::MARKER,
            'made_in'                => 'India',
            'image'                  => $image,
            'description'            => "<p>Fresh {$name}. Cut to order, cleaned and packed hygienically, "
                                        . 'delivered chilled to keep it fresh.</p>',
            'status'                 => 1,
            'is_approved'            => 1,
            'return_days'            => 0,
            'type'                   => $place->type,
            'is_unlimited_stock'     => 0,
            'cod_allowed'            => $place->cod_allowed ?? 1,
            'total_allowed_quantity' => 10,
            'tax_included_in_price'  => $place->tax_included_in_price,
            'fssai_lic_no'           => $place->fssai_lic_no ?: '',
            'created_at'             => now(),
            'updated_at'             => now(),
        ]);

        // Meat sells in 250 g / 500 g / 1 kg, priced off the per-kg rate.
        foreach ([[250, 0.27], [500, 0.52], [1000, 1.00]] as [$grams, $factor]) {
            $price = max(20, (int) round($pricePerKg * $factor / 10) * 10);
            DB::table('product_variants')->insert([
                'product_id'       => $productId,
                'type'             => 'packet',
                'status'           => 1,
                'measurement'      => $grams / 1000,
                'price'            => $price,
                'discounted_price' => (int) round($price * 0.93 / 10) * 10,
                'stock'            => rand(10, 90),
                'stock_unit_id'    => 1, // Kilogram
            ]);
        }
    }

    /**
     * Pexels first (it understands "raw chicken breast"), Openverse as the
     * key-less fallback. Live-animal captions are rejected either way.
     *
     * @return array{url:string,title:string,w:int,source:string}|null
     */
    private function findPhoto(string $query, array $mustWords): ?array
    {
        // The caption must positively say this is uncut/raw product.
        return $this->finder()->find($query, $mustWords, self::REJECT, [
            'raw', 'uncooked', 'fillet', 'butcher', 'meat cut', 'fresh meat',
        ]);
    }

    private function finder(): StockPhotoFinder
    {
        if (!isset($this->photoFinder)) {
            $this->photoFinder = new StockPhotoFinder(array_keys($this->used));
        }

        return $this->photoFinder;
    }

    private function undo(): int
    {
        $ids = DB::table('products')->where('manufacturer', self::MARKER)->pluck('id');

        if ($ids->isEmpty()) {
            $this->info('Nothing to remove.');
            return self::SUCCESS;
        }

        $v = DB::table('product_variants')->whereIn('product_id', $ids)->delete();
        $p = DB::table('products')->whereIn('id', $ids)->delete();

        $this->info("Removed {$p} product(s) and {$v} variant(s).");

        return self::SUCCESS;
    }
}
