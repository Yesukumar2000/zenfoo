<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

/**
 * Builds a reviewable JSON catalogue for the quick-commerce (Zepto / Instamart
 * style) seed data, WITHOUT touching the database.
 *
 * Two free, key-less sources:
 *   - Open Food Facts  → real packaged Indian SKUs: brand, name, pack size,
 *                        barcode and a real packshot photo.
 *                        Rate limit is ~10 search req/min, so every call is
 *                        throttled and retried with backoff.
 *   - Wikimedia Commons → real photos for loose items (vegetables, fruits,
 *                        chicken/mutton, fish) which have no packshots.
 *
 * Prices are DERIVED (OFF carries no prices): each category declares a base
 * price per 100 g / 100 ml, and the pack size scales it with a mild economy of
 * scale. Every derived number is seeded off a hash of the barcode/name, so
 * re-running produces identical output.
 *
 * Output: database/seeders/data/qc_catalog.json — read by QuickCommerceCatalogSeeder.
 *
 * Run: php artisan zenfoo:fetch-catalog
 */
class FetchQuickCommerceCatalog extends Command
{
    protected $signature = 'zenfoo:fetch-catalog
        {--out= : Output path (defaults to database/seeders/data/qc_catalog.json)}
        {--per-category=28 : Max products kept per category}
        {--sleep=13 : Seconds between Open Food Facts calls (limit is ~10/min)}
        {--only= : Comma-separated store ids to build (default: all)}
        {--resume : Keep categories already present in the output file (only fetch the ones that failed), and recompute type chips offline}
        {--skip-images : Do not call any image API for loose/fresh items, and keep items that have no photo. Reuses photos already in the output file. Use to build the data first and backfill images later.}';

    protected $description = 'Fetch real grocery catalogue data + images from Open Food Facts and Wikimedia Commons into a JSON file';

    private const UA = 'ZenfooCatalogSeeder/1.0 (kmadhu@techlanditsolutions.com)';

    /** Cache so two stores sharing an OFF tag cost one HTTP call. */
    private array $offCache = [];

    /** Names already used, so the same SKU never lands twice in one store. */
    private array $usedInStore = [];

    /** Photos already assigned, so no two tiles show the same image. */
    private array $usedImages = [];

    /** "storeId|item" => image URL, carried over from a previous run's output file. */
    private array $priorImages = [];

    /** Image-source tallies — the demo Unsplash tier allows only 50 req/hr. */
    private int $unsplashHits = 0;
    private int $wikimediaHits = 0;
    private int $wikipediaHits = 0;
    private bool $unsplashExhausted = false;

    /* ─────────────────────── taxonomy ─────────────────────── */

    /**
     * store id => group => sub-group => category => spec
     *
     * Packaged spec: ['off' => <OFF category tag>, 'base' => <INR per 100g/100ml>,
     *                 'types' => [ 'Type Name' => [keyword, ...] ], 'img' => <commons query>]
     * Fresh spec:    ['fresh' => [ 'Item Name' => [<commons query>, <INR per kg/pc>] ],
     *                 'unit' => 'Kilogram'|'Pieces', 'img' => <commons query>]
     */
    private function taxonomy(): array
    {
        return [
            // ───────────── Super Mart: the broad Zepto/Instamart catalogue ─────────────
            17 => [
                'Groceries & Kitchen' => [
                    'Atta, Rice & Dal' => [
                        'Atta & Flours' => ['off' => 'flours', 'base' => 6, 'img' => 'wheat flour atta',
                            'types' => ['Whole Wheat' => ['wheat', 'atta', 'chakki'], 'Multigrain' => ['multigrain', 'multi grain'], 'Other Flours' => []]],
                        'Rice' => ['off' => 'rices', 'base' => 11, 'img' => 'basmati rice grains',
                            'types' => ['Basmati' => ['basmati'], 'Brown Rice' => ['brown'], 'Regular' => []]],
                        'Dals & Pulses' => ['off' => 'pulses', 'base' => 14, 'img' => 'lentils dal pulses india',
                            'types' => ['Toor Dal' => ['toor', 'arhar'], 'Moong' => ['moong', 'mung'], 'Chana' => ['chana', 'chickpea', 'gram'], 'Other Dals' => []]],
                    ],
                    'Oils & Ghee' => [
                        'Edible Oils' => ['off' => 'vegetable-oils', 'base' => 15, 'img' => 'sunflower cooking oil bottle',
                            'types' => ['Sunflower' => ['sunflower'], 'Mustard' => ['mustard', 'sarson'], 'Groundnut' => ['groundnut', 'peanut'], 'Refined' => []]],
                        'Ghee & Vanaspati' => ['off' => 'ghees', 'base' => 60, 'img' => 'ghee clarified butter jar',
                            'types' => ['Cow Ghee' => ['cow'], 'Buffalo Ghee' => ['buffalo'], 'Premium' => []]],
                    ],
                    'Masala & Dry Fruits' => [
                        'Spices & Masala' => ['off' => 'spices', 'base' => 40, 'img' => 'indian spices masala bowls',
                            'types' => ['Powder' => ['powder'], 'Whole Spices' => ['whole', 'seed'], 'Blends' => ['masala', 'garam']]],
                        'Dry Fruits & Nuts' => ['off' => 'nuts', 'base' => 90, 'img' => 'dry fruits nuts almonds cashew',
                            'types' => ['Almonds' => ['almond', 'badam'], 'Cashew' => ['cashew', 'kaju'], 'Mixed' => []]],
                    ],
                    'Dairy, Bread & Eggs' => [
                        'Milk' => ['off' => 'milks', 'base' => 6, 'img' => 'milk packet carton',
                            'types' => ['Full Cream' => ['full cream', 'whole'], 'Toned' => ['toned', 'skimmed'], 'Flavoured' => ['flavoured', 'chocolate', 'badam']]],
                        'Curd & Yogurt' => ['off' => 'yogurts', 'base' => 8, 'img' => 'curd yogurt bowl dahi',
                            'types' => ['Plain Curd' => ['plain', 'dahi', 'curd'], 'Flavoured' => ['flavoured', 'fruit', 'strawberry'], 'Greek' => ['greek']]],
                        'Paneer & Cheese' => ['off' => 'cheeses', 'base' => 55, 'img' => 'paneer cheese block',
                            'types' => ['Paneer' => ['paneer'], 'Cheese Slices' => ['slice'], 'Spreads' => ['spread', 'cube']]],
                        'Butter & Spreads' => ['off' => 'butters', 'base' => 60, 'img' => 'butter block dairy',
                            'types' => ['Salted' => ['salted'], 'Unsalted' => ['unsalted', 'white'], 'Margarine' => ['margarine']]],
                        'Bread & Bakery' => ['off' => 'breads', 'base' => 12, 'img' => 'bread loaf bakery',
                            'types' => ['White Bread' => ['white', 'sandwich'], 'Brown Bread' => ['brown', 'whole wheat', 'atta'], 'Buns & Pav' => ['bun', 'pav', 'roll']]],
                    ],
                    'Sauces & Spreads' => [
                        'Ketchup & Sauces' => ['off' => 'sauces', 'base' => 20, 'img' => 'tomato ketchup sauce bottle',
                            'types' => ['Tomato Ketchup' => ['ketchup', 'tomato'], 'Chilli & Soy' => ['chilli', 'soy', 'schezwan'], 'Mayonnaise' => ['mayo']]],
                        'Jam & Honey' => ['off' => 'jams', 'base' => 30, 'img' => 'jam jar fruit preserve',
                            'types' => ['Mixed Fruit' => ['mixed'], 'Strawberry' => ['strawberry'], 'Other' => []]],
                        'Peanut Butter' => ['off' => 'nut-butters', 'base' => 45, 'img' => 'peanut butter jar',
                            'types' => ['Creamy' => ['creamy', 'smooth'], 'Crunchy' => ['crunchy', 'crisp'], 'Chocolate' => ['chocolate']]],
                    ],
                ],
                'Snacks & Drinks' => [
                    'Biscuits & Cookies' => [
                        'Biscuits' => ['off' => 'biscuits', 'base' => 22, 'img' => 'biscuits pack cookies',
                            'types' => ['Glucose & Marie' => ['glucose', 'marie', 'parle-g'], 'Cream Biscuits' => ['cream', 'bourbon'], 'Digestive' => ['digestive', 'oat'], 'Salted' => ['salt', 'monaco', 'krackjack']]],
                        'Cookies & Rusk' => ['off' => 'cookies', 'base' => 28, 'img' => 'cookies rusk tea time',
                            'types' => ['Butter Cookies' => ['butter'], 'Choco Chip' => ['choco', 'chocolate'], 'Rusk' => ['rusk', 'toast']]],
                    ],
                    'Chips & Namkeen' => [
                        'Chips & Crisps' => ['off' => 'crisps', 'base' => 40, 'img' => 'potato chips packet snack',
                            'types' => ['Salted' => ['salted', 'classic', 'plain'], 'Masala' => ['masala', 'magic', 'tangy'], 'Cream & Onion' => ['cream', 'onion']]],
                        'Namkeen & Mixture' => ['off' => 'namkeen', 'base' => 30, 'img' => 'namkeen indian snack mixture',
                            'types' => ['Bhujia' => ['bhujia'], 'Mixture' => ['mixture', 'mix'], 'Sev & Chivda' => ['sev', 'chivda', 'chiwda']]],
                    ],
                    'Chocolates & Sweets' => [
                        'Chocolates' => ['off' => 'chocolates', 'base' => 95, 'img' => 'chocolate bar candy',
                            'types' => ['Milk Chocolate' => ['milk'], 'Dark Chocolate' => ['dark'], 'Wafer & Filled' => ['wafer', 'crunch', 'nut']]],
                        'Candies & Gums' => ['off' => 'candies', 'base' => 55, 'img' => 'candy sweets colourful',
                            'types' => ['Hard Candy' => ['candy', 'lolly'], 'Chewing Gum' => ['gum'], 'Mints' => ['mint', 'polo']]],
                    ],
                    'Cold Drinks & Juices' => [
                        'Soft Drinks' => ['off' => 'sodas', 'base' => 4, 'img' => 'soft drink cola bottle',
                            'types' => ['Cola' => ['cola', 'pepsi', 'coke', 'thums'], 'Lemon & Lime' => ['lemon', 'lime', 'sprite', 'limca', '7up'], 'Orange' => ['orange', 'mirinda', 'fanta']]],
                        'Juices' => ['off' => 'fruit-juices', 'base' => 8, 'img' => 'fruit juice tetra pack',
                            'types' => ['Mixed Fruit' => ['mixed'], 'Orange' => ['orange'], 'Mango' => ['mango', 'aam'], 'Apple' => ['apple']]],
                        'Water & Soda' => ['off' => 'waters', 'base' => 2, 'img' => 'mineral water bottle',
                            'types' => ['Packaged Water' => ['water', 'mineral'], 'Sparkling' => ['sparkling', 'soda']]],
                        'Energy Drinks' => ['off' => 'energy-drinks', 'base' => 20, 'img' => 'energy drink can',
                            'types' => ['Energy' => ['energy'], 'Sports' => ['sport', 'electrolyte', 'glucose']]],
                    ],
                    'Tea, Coffee & Health Drinks' => [
                        'Tea' => ['off' => 'teas', 'base' => 55, 'img' => 'tea leaves cup chai',
                            'types' => ['Black Tea' => ['black', 'dust', 'leaf'], 'Green Tea' => ['green'], 'Masala Chai' => ['masala', 'ginger', 'elaichi']]],
                        'Coffee' => ['off' => 'coffees', 'base' => 130, 'img' => 'coffee beans jar',
                            'types' => ['Instant' => ['instant'], 'Filter Coffee' => ['filter', 'chicory'], 'Ground' => ['ground', 'bean']]],
                        // 'malted-drinks' is not a real OFF tag (returns 0, not rate-limited).
                        'Health Drinks' => ['off' => 'beverage-preparations', 'base' => 45, 'img' => 'health drink powder jar'],
                    ],
                ],
                'Instant & Frozen' => [
                    'Noodles & Pasta' => [
                        'Noodles' => ['off' => 'noodles', 'base' => 22, 'img' => 'instant noodles packet',
                            'types' => ['Instant Noodles' => ['instant', 'maggi', '2-minute'], 'Hakka & Chowmein' => ['hakka', 'chowmein', 'chow'], 'Cup Noodles' => ['cup']]],
                        // No pasta category: OFF's `pastas` tag returns Maggi instant noodles for
                        // India (a duplicate of Noodles) and `dry-pasta` yields only ~3 usable
                        // SKUs — too sparse to sit beside 30-product categories.
                    ],
                    'Breakfast & Cereal' => [
                        'Breakfast Cereal' => ['off' => 'breakfast-cereals', 'base' => 40, 'img' => 'breakfast cereal corn flakes bowl',
                            'types' => ['Corn Flakes' => ['flake', 'corn'], 'Muesli' => ['muesli', 'granola'], 'Choco' => ['choco', 'chocolate']]],
                        'Oats & Poha' => ['off' => 'oatmeals', 'base' => 22, 'img' => 'oats bowl breakfast',
                            'types' => ['Plain Oats' => ['plain', 'rolled', 'white'], 'Masala Oats' => ['masala', 'flavour'], 'Instant' => ['instant', 'quick']]],
                    ],
                    'Ice Cream & Desserts' => [
                        'Ice Cream' => ['off' => 'ice-creams', 'base' => 30, 'img' => 'ice cream tub scoop',
                            'types' => ['Vanilla' => ['vanilla'], 'Chocolate' => ['chocolate'], 'Cone & Bar' => ['cone', 'bar', 'stick', 'kulfi']]],
                        'Desserts & Mixes' => ['off' => 'desserts', 'base' => 35, 'img' => 'indian dessert sweets',
                            'types' => ['Mixes' => ['mix', 'instant'], 'Ready Sweets' => ['gulab', 'rasgulla', 'halwa']]],
                    ],
                ],

                // ── Non-food. Open Food Facts has none of this, so these pull
                //    from its sibling databases via 'source' (see SOURCE_HOSTS).
                //    Coverage is thinner than the food side and not India-filtered,
                //    so expect fewer SKUs per category — still real products with
                //    real packshots, which is what matters for the demo.
                'Personal Care' => [
                    'Bath & Body' => [
                        'Soaps & Body Wash' => ['source' => 'obf', 'off' => 'soaps', 'base' => 18, 'img' => 'soap bar bathroom',
                            'types' => ['Bar Soap' => ['bar', 'soap'], 'Body Wash' => ['wash', 'gel', 'shower'], 'Handwash' => ['hand']]],
                        'Shampoo & Conditioner' => ['source' => 'obf', 'off' => 'shampoos', 'base' => 25, 'img' => 'shampoo bottle hair care',
                            'types' => ['Anti-Dandruff' => ['dandruff'], 'Damage Repair' => ['repair', 'damage'], 'Everyday' => []]],
                        'Deodorants & Perfume' => ['source' => 'obf', 'off' => 'deodorants', 'base' => 40, 'img' => 'deodorant spray bottle',
                            'types' => ['Spray' => ['spray', 'aerosol'], 'Roll-On' => ['roll'], 'Perfume' => ['perfume', 'eau']]],
                    ],
                    'Oral & Skin Care' => [
                        'Toothpaste & Brush' => ['source' => 'obf', 'off' => 'toothpastes', 'base' => 22, 'img' => 'toothpaste tube brush',
                            'types' => ['Cavity Protection' => ['cavity', 'protect'], 'Herbal' => ['herbal', 'neem', 'ayurvedic'], 'Whitening' => ['white']]],
                        'Face & Skin Care' => ['source' => 'obf', 'off' => 'face-creams', 'base' => 45, 'img' => 'face cream jar skincare',
                            'types' => ['Moisturiser' => ['moistur', 'cream'], 'Face Wash' => ['wash', 'cleanser'], 'Sunscreen' => ['sun', 'spf']]],
                    ],
                ],

                'Home & Cleaning' => [
                    'Cleaning Essentials' => [
                        'Detergents & Laundry' => ['source' => 'opf', 'off' => 'laundry-detergents', 'base' => 12, 'img' => 'detergent powder laundry',
                            'types' => ['Powder' => ['powder'], 'Liquid' => ['liquid', 'gel'], 'Bar' => ['bar', 'soap']]],
                        'Dishwash' => ['source' => 'opf', 'off' => 'dishwashing-products', 'base' => 15, 'img' => 'dishwash liquid bottle sink',
                            'types' => ['Liquid Gel' => ['liquid', 'gel'], 'Bar & Powder' => ['bar', 'powder'], 'Scrubs' => ['scrub', 'sponge']]],
                        'Floor & Toilet Cleaners' => ['source' => 'opf', 'off' => 'cleaning-products', 'base' => 14, 'img' => 'floor cleaner bottle household',
                            'types' => ['Floor' => ['floor', 'surface'], 'Toilet' => ['toilet', 'bathroom'], 'Disinfectant' => ['disinfect', 'germ']]],
                    ],
                ],

                'Baby & Pet Care' => [
                    'Baby Care' => [
                        'Baby Food & Formula' => ['off' => 'baby-foods', 'base' => 70, 'img' => 'baby food jar cereal',
                            'types' => ['Cereal' => ['cereal', 'porridge'], 'Formula' => ['formula', 'milk'], 'Puree' => ['puree', 'fruit']]],
                        'Diapers & Wipes' => ['source' => 'opf', 'off' => 'diapers', 'base' => 30, 'img' => 'baby diapers pack',
                            'types' => ['Pants' => ['pant'], 'Tape Diapers' => ['tape', 'adhesive'], 'Wipes' => ['wipe']]],
                    ],
                    'Pet Care' => [
                        'Pet Food' => ['source' => 'opf', 'off' => 'pet-foods', 'base' => 35, 'img' => 'pet food dog cat bowl',
                            'types' => ['Dog Food' => ['dog'], 'Cat Food' => ['cat'], 'Treats' => ['treat', 'biscuit', 'chew']]],
                    ],
                ],
            ],

            // ───────────── Grocery & Kitchen: everyday staples ─────────────
            12 => [
                'Daily Staples' => [
                    'Atta, Rice & Dal' => [
                        'Atta & Flours' => ['off' => 'flours', 'base' => 6, 'img' => 'wheat flour atta',
                            'types' => ['Whole Wheat' => ['wheat', 'atta', 'chakki'], 'Multigrain' => ['multigrain'], 'Other Flours' => []]],
                        'Rice' => ['off' => 'rices', 'base' => 11, 'img' => 'basmati rice grains',
                            'types' => ['Basmati' => ['basmati'], 'Brown Rice' => ['brown'], 'Regular' => []]],
                        'Dals & Pulses' => ['off' => 'pulses', 'base' => 14, 'img' => 'lentils dal pulses india',
                            'types' => ['Toor Dal' => ['toor', 'arhar'], 'Moong' => ['moong'], 'Chana' => ['chana', 'gram'], 'Other Dals' => []]],
                    ],
                    'Oil, Ghee & Masala' => [
                        'Edible Oils' => ['off' => 'vegetable-oils', 'base' => 15, 'img' => 'sunflower cooking oil bottle',
                            'types' => ['Sunflower' => ['sunflower'], 'Mustard' => ['mustard'], 'Groundnut' => ['groundnut', 'peanut'], 'Refined' => []]],
                        'Ghee' => ['off' => 'ghees', 'base' => 60, 'img' => 'ghee clarified butter jar',
                            'types' => ['Cow Ghee' => ['cow'], 'Premium' => []]],
                        'Spices & Masala' => ['off' => 'spices', 'base' => 40, 'img' => 'indian spices masala bowls',
                            'types' => ['Powder' => ['powder'], 'Whole Spices' => ['whole', 'seed'], 'Blends' => ['masala', 'garam']]],
                        'Salt & Sugar' => ['off' => 'sugars', 'base' => 6, 'img' => 'sugar salt kitchen',
                            'types' => ['Sugar' => ['sugar'], 'Jaggery' => ['jaggery', 'gur'], 'Salt' => ['salt']]],
                    ],
                    'Dairy, Bread & Eggs' => [
                        'Milk' => ['off' => 'milks', 'base' => 6, 'img' => 'milk packet carton',
                            'types' => ['Full Cream' => ['full cream', 'whole'], 'Toned' => ['toned'], 'Flavoured' => ['flavoured', 'badam']]],
                        'Curd & Paneer' => ['off' => 'yogurts', 'base' => 8, 'img' => 'curd yogurt bowl dahi',
                            'types' => ['Curd' => ['curd', 'dahi', 'plain'], 'Flavoured' => ['flavoured', 'fruit'], 'Greek' => ['greek']]],
                        'Bread & Bakery' => ['off' => 'breads', 'base' => 12, 'img' => 'bread loaf bakery',
                            'types' => ['White Bread' => ['white'], 'Brown Bread' => ['brown', 'atta'], 'Buns & Pav' => ['bun', 'pav']]],
                    ],
                    'Tea, Coffee & Biscuits' => [
                        'Tea' => ['off' => 'teas', 'base' => 55, 'img' => 'tea leaves cup chai',
                            'types' => ['Black Tea' => ['black', 'dust'], 'Green Tea' => ['green'], 'Masala Chai' => ['masala', 'ginger']]],
                        'Coffee' => ['off' => 'coffees', 'base' => 130, 'img' => 'coffee beans jar',
                            'types' => ['Instant' => ['instant'], 'Filter Coffee' => ['filter', 'chicory']]],
                        'Biscuits' => ['off' => 'biscuits', 'base' => 22, 'img' => 'biscuits pack cookies',
                            'types' => ['Glucose & Marie' => ['glucose', 'marie'], 'Cream Biscuits' => ['cream', 'bourbon'], 'Digestive' => ['digestive']]],
                    ],
                ],
            ],

            // ───────────── Vegetables & Fruits: loose, Commons photos ─────────────
            13 => [
                'Fresh Produce' => [
                    'Vegetables' => [
                        'Daily Vegetables' => ['unit' => 'Kilogram', 'img' => 'fresh vegetables basket market', 'fresh' => [
                            'Tomato'            => ['fresh red tomato vegetable', 32],
                            'Onion'             => ['red onion bulbs vegetable', 38],
                            'Potato'            => ['potatoes raw vegetable', 30],
                            'Brinjal'           => ['brinjal eggplant aubergine vegetable', 45],
                            'Lady Finger'       => ['okra lady finger vegetable', 55],
                            'Carrot'            => ['fresh carrots vegetable', 60],
                            'Cauliflower'       => ['cauliflower head vegetable', 48],
                            'Cabbage'           => ['cabbage head vegetable', 35],
                            'Green Capsicum'    => ['green bell pepper capsicum', 80],
                            'Bottle Gourd'      => ['bottle gourd lauki vegetable', 40],
                            'Ridge Gourd'       => ['ridge gourd turai vegetable', 50],
                            'Bitter Gourd'      => ['bitter gourd karela vegetable', 60],
                            'Cucumber'          => ['fresh cucumber vegetable', 40],
                            'Beetroot'          => ['beetroot vegetable raw', 55],
                            'Radish'            => ['white radish daikon vegetable', 35],
                            'Green Beans'       => ['green beans vegetable fresh', 70],
                            'Green Peas'        => ['green peas pods vegetable', 90],
                            'Drumstick'         => ['drumstick moringa pods vegetable', 75],
                            'Sweet Corn'        => ['sweet corn cob maize', 45],
                            'Mushroom'          => ['button mushrooms fresh', 120],
                        ]],
                        'Leafy & Herbs' => ['unit' => 'Pieces', 'img' => 'leafy greens herbs coriander', 'fresh' => [
                            'Coriander Leaves'  => ['coriander leaves cilantro bunch', 15],
                            'Mint Leaves'       => ['mint leaves pudina bunch', 15],
                            'Curry Leaves'      => ['curry leaves fresh', 12],
                            'Spinach'           => ['spinach leaves palak bunch', 25],
                            'Fenugreek Leaves'  => ['fenugreek leaves methi bunch', 25],
                            'Amaranth Leaves'   => ['amaranth leaves greens bunch', 20],
                            'Spring Onion'      => ['spring onion scallion bunch', 30],
                            'Dill Leaves'       => ['dill leaves herb bunch', 22],
                        ]],
                        'Exotic Vegetables' => ['unit' => 'Kilogram', 'img' => 'exotic vegetables broccoli zucchini', 'fresh' => [
                            'Broccoli'          => ['broccoli fresh vegetable', 180],
                            'Zucchini'          => ['zucchini courgette vegetable', 150],
                            'Red Capsicum'      => ['red bell pepper capsicum', 200],
                            'Yellow Capsicum'   => ['yellow bell pepper capsicum', 210],
                            'Celery'            => ['celery stalks vegetable', 160],
                            'Lettuce'           => ['iceberg lettuce head', 140],
                            'Baby Corn'         => ['baby corn vegetable', 170],
                            'Cherry Tomato'     => ['cherry tomatoes fresh', 190],
                        ]],
                    ],
                    'Fruits' => [
                        'Daily Fruits' => ['unit' => 'Kilogram', 'img' => 'fresh fruits basket market', 'fresh' => [
                            'Banana'            => ['ripe bananas fruit bunch', 55],
                            'Apple'             => ['red apples fruit', 180],
                            'Orange'            => ['oranges citrus fruit', 110],
                            'Sweet Lime'        => ['sweet lime mosambi fruit', 90],
                            'Papaya'            => ['papaya fruit sliced', 60],
                            'Watermelon'        => ['watermelon fruit sliced', 35],
                            'Muskmelon'         => ['muskmelon cantaloupe fruit', 50],
                            'Guava'             => ['guava fruit fresh', 80],
                            'Pineapple'         => ['pineapple fruit whole', 70],
                            'Pomegranate'       => ['pomegranate fruit arils', 220],
                            'Grapes'            => ['green grapes bunch fruit', 130],
                            'Mango'             => ['mango fruit alphonso', 160],
                        ]],
                        'Exotic Fruits' => ['unit' => 'Kilogram', 'img' => 'exotic fruits kiwi dragon fruit', 'fresh' => [
                            'Kiwi'              => ['kiwi fruit sliced', 280],
                            'Dragon Fruit'      => ['dragon fruit pitaya', 320],
                            'Avocado'           => ['avocado fruit halved', 400],
                            'Blueberry'         => ['blueberries fresh fruit', 650],
                            'Strawberry'        => ['strawberries fresh fruit', 350],
                            'Pear'              => ['pears fruit fresh', 220],
                        ]],
                    ],
                ],
            ],

            // ───────────── Chicken & Meat ─────────────
            14 => [
                'Meat & Poultry' => [
                    'Chicken' => [
                        'Fresh Chicken' => ['unit' => 'Kilogram', 'img' => 'raw chicken meat cuts', 'fresh' => [
                            'Chicken Curry Cut'      => ['raw chicken curry cut pieces', 240],
                            'Chicken Breast Boneless' => ['raw chicken breast fillet', 340],
                            'Chicken Legs'           => ['raw chicken drumsticks legs', 260],
                            'Chicken Wings'          => ['raw chicken wings', 220],
                            'Chicken Mince (Keema)'  => ['ground chicken mince meat', 300],
                            'Whole Chicken'          => ['whole raw chicken', 230],
                            'Chicken Liver'          => ['raw chicken liver', 150],
                            'Country Chicken'        => ['country chicken raw meat', 420],
                        ]],
                        'Eggs' => ['unit' => 'Pieces', 'img' => 'eggs tray fresh', 'fresh' => [
                            'Farm Eggs'    => ['chicken eggs tray white', 7],
                            'Brown Eggs'   => ['brown chicken eggs', 9],
                            'Country Eggs' => ['free range eggs basket', 12],
                        ]],
                    ],
                ],
            ],

            // ───────────── Mutton (store 18 got its own seller) ─────────────
            18 => [
                'Mutton & Lamb' => [
                    'Mutton' => [
                        'Fresh Mutton' => ['unit' => 'Kilogram', 'img' => 'raw mutton goat meat', 'fresh' => [
                            'Mutton Curry Cut'   => ['raw mutton curry cut goat meat', 850],
                            'Mutton Boneless'    => ['raw boneless mutton lamb', 980],
                            'Mutton Keema'       => ['ground lamb mince meat', 900],
                            'Mutton Ribs'        => ['raw mutton ribs goat', 820],
                            'Mutton Leg'         => ['raw mutton leg goat meat', 940],
                            'Mutton Shoulder'    => ['raw lamb shoulder meat', 880],
                        ]],
                        'Lamb & Offal' => ['unit' => 'Kilogram', 'img' => 'raw lamb chops meat', 'fresh' => [
                            'Lamb Chops'      => ['raw lamb chops', 1050],
                            'Mutton Liver'    => ['raw mutton liver', 600],
                            'Mutton Kidney'   => ['raw mutton kidney offal', 520],
                            'Mutton Paya'     => ['lamb trotters raw meat', 380],
                            'Mutton Brain'    => ['raw goat brain offal', 450],
                        ]],
                    ],
                ],
            ],

            // ───────────── Fish & Seafood ─────────────
            19 => [
                'Fish & Seafood' => [
                    'Fish' => [
                        'Fresh Fish' => ['unit' => 'Kilogram', 'img' => 'fresh fish market seafood', 'fresh' => [
                            'Rohu'          => ['rohu fish labeo fresh', 220],
                            'Katla'         => ['carp fish whole raw', 240],
                            'Tilapia'       => ['tilapia fish fresh', 200],
                            'Pomfret'       => ['pomfret fish silver fresh', 750],
                            'Seer Fish'     => ['kingfish steak raw fish', 900],
                            'Mackerel'      => ['mackerel raw fish whole', 320],
                            'Sardine'       => ['sardine fish fresh', 260],
                            'Basa'          => ['basa fish fillet', 380],
                            'Tuna'          => ['tuna fish fresh', 550],
                            'Anchovy'       => ['anchovy fish nethili fresh', 280],
                        ]],
                        'Prawns & Shellfish' => ['unit' => 'Kilogram', 'img' => 'prawns shrimp seafood fresh', 'fresh' => [
                            'Prawns Medium' => ['raw prawns shrimp fresh', 620],
                            'Prawns Jumbo'  => ['jumbo prawns tiger shrimp', 950],
                            'Crab'          => ['fresh crab seafood', 500],
                            'Squid'         => ['squid calamari fresh seafood', 450],
                            'Clams'         => ['clams shellfish fresh', 300],
                        ]],
                    ],
                ],
            ],
        ];
    }

    /**
     * "Filters by Type" chips, tuned against the names Open Food Facts actually
     * returns for India rather than what the category name suggests — OFF's
     * `butters` tag is ghee-dominated here, and `cookies` overlaps `biscuits`.
     *
     * Order matters: the first keyword hit wins, so put the specific chips above
     * the general ones. The entry with an empty keyword list is the catch-all.
     * Shared by every store so a category means the same thing everywhere.
     */
    private function typesFor(string $cat): ?array
    {
        $map = [
            'Milk' => [
                'Buttermilk & Cream' => ['buttermilk', 'chaas', 'cream'],
                'Flavoured & Shakes' => ['flavou', 'shake', 'badam', 'chocolate', 'caramel', 'smoodh', 'epigamia', 'toffee'],
                'Full Cream'         => ['full cream', 'buffalo', 'a2', 'whole', 'gold'],
                'Toned'              => ['toned', 'slim', 'taaza', 'cow milk', 'pasteuris', 'lite', 'milk'],
                'Other Dairy'        => [],
            ],
            'Butter & Spreads' => [
                'Ghee'          => ['ghee', 'gee'],
                'Butter'        => ['butter'],
                'Spreads'       => ['spread', 'margarine', 'nutralite'],
                'Other Spreads' => [],
            ],
            'Cookies & Rusk' => [
                'Rusk & Toast'    => ['rusk', 'toast', 'tostea', 'toastea', 'rusky'],
                'Digestive'       => ['digestive', 'nutri'],
                'Cream & Wafer'   => ['cream', 'wafer', 'bourbon', 'oreo', 'waffy', 'chocochip', 'choco chip', 'krunch', 'fantasy'],
                'Cookies'         => ['cookie', 'butter', 'cashew', 'badam'],
                'Other Biscuits'  => [],
            ],
            'Biscuits' => [
                'Glucose & Marie' => ['glucose', 'marie', 'parle-g', 'parle g', 'royale'],
                'Cream Biscuits'  => ['cream', 'bourbon', 'jimjam', 'jim jam', 'oreo', '20-20', 'fantasy'],
                'Digestive'       => ['digestive', 'nutri', 'oat'],
                'Cookies'         => ['cookie', 'cashew', 'badam', 'good day'],
                'Salted'          => ['salt', 'monaco', 'krackjack', 'happy', 'namkeen'],
                'Other Biscuits'  => [],
            ],
            'Chips & Crisps' => [
                'Cream & Onion'     => ['cream', 'onion'],
                'Masala & Spicy'    => ['masala', 'tadka', 'chilli', 'magic', 'tedh', 'chataka', 'masti', 'panjabi', 'punjabi', 'hot', 'peri', 'achari'],
                'Salted'            => ['salted', 'classic', 'simply', 'plain'],
                'Puffs & Extruded'  => ['kurkure', 'puff', 'popring', 'crunchex', 'bingo', 'wafer'],
                'Other Chips'       => [],
            ],
            'Namkeen & Mixture' => [
                'Bhujia'           => ['bhujia'],
                'Sev & Chivda'     => ['sev', 'chivda', 'chiwda', 'gathiya'],
                'Mixture'          => ['mixture', 'khatta', 'navratan', 'chana', 'dal', 'mix'],
                'Puffs & Nachos'   => ['kurkure', 'puff', 'dorito', 'nacho', 'jowar'],
                'Other Namkeen'    => [],
            ],
            'Bread & Bakery' => [
                'Rusk & Toast'        => ['rusk', 'toast', 'tostea', 'toastea', 'rusky'],
                'Brown & Whole Wheat' => ['brown', 'whole wheat', 'atta', 'multi grain', 'multigrain', 'multgrain', 'zero maida', 'fibre'],
                'Buns & Pav'          => ['bun', 'pav', 'chapati', 'papad', 'roll'],
                'White Bread'         => ['white', 'sandwich', 'milk bread', 'everyday', 'bread'],
                'Other Bakery'        => [],
            ],
            'Peanut Butter' => [
                'Chocolate' => ['chocolate', 'choco', 'hazlenut', 'hazelnut'],
                'Crunchy'   => ['crunch', 'nutty'],
                'Creamy'    => ['creamy', 'smooth'],
                'Classic'   => [],
            ],
            'Pasta & Macaroni' => [
                'Penne'         => ['penne'],
                'Macaroni'      => ['macaroni', 'elbow'],
                'Spaghetti'     => ['spaghetti', 'vermicelli'],
                'Fusilli'       => ['fusilli', 'rotini', 'spiral'],
                'Instant Pasta' => ['instant', 'masala', 'cheese', 'cup'],
                'Other Pasta'   => [],
            ],
            // OFF's `desserts` tag for India is dominated by ice cream and Indian
            // dairy sweets, not the mixes the category name implies.
            'Desserts & Mixes' => [
                'Kulfi'              => ['kulfi'],
                'Shrikhand & Mishti' => ['shrikhand', 'shrikand', 'amrakhand', 'rajbhog', 'lassi', 'dahi', 'yogurt', 'skyr', 'gulab', 'rasgulla', 'rasmalai', 'peda', 'halwa'],
                'Ice Cream & Bars'   => ['ice cream', 'icecream', 'sundae', 'cone', 'cornetto', 'bar', 'stick', 'sandwich', 'royale', 'bliss', 'fantasy'],
                'Chocolate'          => ['chocolate', 'choco', '5 star', 'crackle', 'brownie'],
                'Other Desserts'     => [],
            ],
            'Candies & Gums' => [
                'Chewing Gum'      => ['gum', 'chewing', 'bubble'],
                'Mints'            => ['mint', 'polo', 'mentos'],
                'Toffee & Eclairs' => ['toffee', 'eclair', 'caramel', 'coffy', 'kopiko', 'chocolate'],
                'Lollipop'         => ['lolly', 'lollipop'],
                'Hard Candy'       => [],
            ],
            'Coffee' => [
                'Filter Coffee'   => ['filter', 'chicory', 'degree'],
                'Ground & Beans'  => ['ground', 'bean', 'roast', 'arabica', 'robusta', 'brew'],
                'Instant'         => ['instant', 'classic', 'gold', 'sunrise', 'bru', 'nescafe', 'cappuccino'],
                'Other Coffee'    => [],
            ],
            'Tea' => [
                'Green Tea'        => ['green'],
                'Masala Chai'      => ['masala', 'ginger', 'elaichi', 'cardamom', 'tulsi', 'spiced', 'adrak'],
                'Black Tea'        => ['black', 'dust', 'leaf', 'premium', 'gold', 'red label', 'strong', 'tea'],
                'Herbal & Others'  => [],
            ],
            'Noodles' => [
                'Cup Noodles'      => ['cup'],
                'Hakka & Chowmein' => ['hakka', 'chowmein', 'chow', 'schezwan'],
                'Instant Noodles'  => ['instant', 'maggi', '2-minute', 'yippee', 'ramen', 'masala', 'noodle'],
                'Other Noodles'    => [],
            ],
            'Ice Cream' => [
                'Cone & Bar'      => ['cone', 'bar', 'stick', 'kulfi', 'sandwich', 'cup'],
                'Chocolate'       => ['chocolate', 'choco'],
                'Vanilla'         => ['vanilla'],
                'Fruit & Sorbet'  => ['mango', 'strawberry', 'fruit', 'sorbet', 'butterscotch'],
                'Other Flavours'  => [],
            ],
            'Energy Drinks' => [
                'Sports & Electrolyte' => ['sport', 'electrolyte', 'glucose', 'gatorade', 'prolyte', 'ors', 'hydra'],
                'Energy'               => ['energy', 'red bull', 'sting', 'monster', 'charged'],
                'Other Drinks'         => [],
            ],
            'Spices & Masala' => [
                'Blends'          => ['masala', 'garam', 'sambar', 'rasam', 'chaat', 'biryani', 'pav bhaji'],
                'Whole Spices'    => ['whole', 'seed', 'jeera', 'cumin', 'elaichi', 'clove', 'pepper', 'methi', 'hing', 'ajwain', 'saunf', 'bay', 'cinnamon'],
                'Powder'          => ['powder', 'haldi', 'turmeric', 'mirchi', 'chilli', 'dhania', 'coriander'],
                'Salt & Others'   => [],
            ],
            'Curd & Yogurt' => [
                'Greek'        => ['greek', 'protein'],
                'Flavoured'    => ['flavou', 'fruit', 'strawberry', 'mango', 'blueberry', 'vanilla'],
                'Plain Curd'   => ['plain', 'dahi', 'curd', 'yog'],
                'Other Dairy'  => [],
            ],
            'Curd & Paneer' => [
                'Paneer'       => ['paneer'],
                'Greek'        => ['greek', 'protein'],
                'Flavoured'    => ['flavou', 'fruit', 'strawberry', 'mango', 'blueberry'],
                'Curd'         => ['plain', 'dahi', 'curd', 'yog'],
                'Other Dairy'  => [],
            ],
            'Breakfast Cereal' => [
                'Muesli & Granola' => ['muesli', 'granola'],
                'Choco'            => ['choco', 'chocolate'],
                'Corn Flakes'      => ['flake', 'corn'],
                'Other Cereal'     => [],
            ],
            'Oats & Poha' => [
                'Masala Oats'  => ['masala', 'flavou', 'veggie'],
                'Instant'      => ['instant', 'quick'],
                'Plain Oats'   => ['plain', 'rolled', 'white', 'oat'],
                'Other Grains' => [],
            ],
            'Juices' => [
                'Mango'        => ['mango', 'aam', 'maaza', 'slice', 'frooti'],
                'Orange'       => ['orange'],
                'Apple'        => ['apple'],
                'Mixed Fruit'  => ['mixed', 'tropical'],
                'Other Juices' => [],
            ],
            'Water & Soda' => [
                'Sparkling & Soda' => ['sparkling', 'soda', 'club'],
                'Packaged Water'   => ['water', 'mineral', 'aqua', 'bisleri', 'kinley'],
                'Flavoured Water'  => [],
            ],
            'Ketchup & Sauces' => [
                'Mayonnaise'      => ['mayo'],
                'Chilli & Soy'    => ['chilli', 'soy', 'schezwan', 'hot', 'vinegar'],
                'Tomato Ketchup'  => ['ketchup', 'tomato'],
                'Other Sauces'    => [],
            ],
            'Chocolates' => [
                'Wafer & Filled'  => ['wafer', 'crunch', 'nut', 'almond', 'kitkat', 'munch', 'perk', 'oreo'],
                'Dark Chocolate'  => ['dark', 'bournville', '70%'],
                'Milk Chocolate'  => ['milk', 'dairy', 'silk'],
                'Other Chocolate' => [],
            ],
            'Dry Fruits & Nuts' => [
                'Almonds'      => ['almond', 'badam'],
                'Cashew'       => ['cashew', 'kaju'],
                'Raisins'      => ['raisin', 'kishmish'],
                'Pista & Walnut' => ['pista', 'walnut', 'akhrot'],
                'Mixed & Others' => [],
            ],
            'Dals & Pulses' => [
                'Toor Dal'    => ['toor', 'arhar', 'tur'],
                'Moong'       => ['moong', 'mung'],
                'Chana'       => ['chana', 'chickpea', 'gram', 'besan'],
                'Urad & Masoor' => ['urad', 'masoor', 'lentil'],
                'Other Dals'  => [],
            ],
            'Ghee & Vanaspati' => [
                'Cow Ghee'      => ['cow'],
                'Buffalo Ghee'  => ['buffalo'],
                'Vanaspati'     => ['vanaspati', 'dalda'],
                'Premium Ghee'  => [],
            ],
            'Ghee' => [
                'Cow Ghee'     => ['cow'],
                'Buffalo Ghee' => ['buffalo'],
                'Premium Ghee' => [],
            ],
            'Salt & Sugar' => [
                'Salt'          => ['salt', 'namak'],
                'Jaggery'       => ['jaggery', 'gur'],
                'Sugar'         => ['sugar', 'shakkar'],
                'Other Sweeteners' => [],
            ],
            'Jam & Honey' => [
                'Honey'        => ['honey', 'shahad'],
                'Strawberry'   => ['strawberry'],
                'Mixed Fruit'  => ['mixed', 'fruit'],
                'Other Spreads' => [],
            ],
            'Soft Drinks' => [
                'Cola'          => ['cola', 'pepsi', 'coke', 'thums'],
                'Lemon & Lime'  => ['lemon', 'lime', 'sprite', 'limca', '7up', 'mountain'],
                'Orange'        => ['orange', 'mirinda', 'fanta'],
                'Other Drinks'  => [],
            ],
            'Paneer & Cheese' => [
                'Paneer'        => ['paneer'],
                'Cheese Slices' => ['slice', 'block', 'cheddar', 'mozzarella'],
                'Spreads'       => ['spread', 'cube', 'dip'],
                'Other Cheese'  => [],
            ],
            'Atta & Flours' => [
                'Whole Wheat'   => ['wheat', 'atta', 'chakki'],
                'Multigrain'    => ['multigrain', 'multi grain'],
                'Besan & Maida' => ['besan', 'maida', 'gram flour'],
                'Rice & Ragi'   => ['rice flour', 'ragi', 'bajra', 'jowar'],
                'Other Flours'  => [],
            ],
            'Rice' => [
                'Poha & Murmura' => ['poha', 'aval', 'flaked', 'murmura', 'kurmura', 'jada', 'mota'],
                'Biryani & Pulav' => ['biryani', 'pulav', 'pulao', 'khichdi', 'fried rice'],
                'Basmati'        => ['basmati', 'mogra', 'dubar'],
                'Sona Masoori'   => ['sona', 'masoori', 'masuri', 'raw rice'],
                'Brown & Red Rice' => ['brown', 'red rice'],
                'Other Rice'     => [],
            ],
            'Health Drinks' => [
                'Malt Based'     => ['malt', 'horlicks', 'boost', 'complan', 'maltova'],
                'Chocolate'      => ['chocolate', 'bournvita', 'choco', 'cocoa'],
                'Protein'        => ['protein', 'whey', 'ensure'],
                'Juice & Squash' => ['squash', 'syrup', 'sharbat', 'rooh', 'concentrate'],
                'Other Mixes'    => [],
            ],
            'Edible Oils' => [
                'Sunflower'  => ['sunflower'],
                'Mustard'    => ['mustard', 'sarson', 'kachi ghani'],
                'Groundnut'  => ['groundnut', 'peanut'],
                'Coconut'    => ['coconut'],
                'Rice Bran & Others' => ['rice bran', 'soya', 'olive', 'sesame', 'gingelly'],
                'Refined'    => [],
            ],
        ];

        return $map[$cat] ?? null;
    }

    /** Pack sizes offered for loose/fresh items, by unit. [label, measurement, unitName, factor] */
    private array $freshSizes = [
        'Kilogram' => [['250 g', 250, 'Grams', 0.25], ['500 g', 500, 'Grams', 0.5], ['1 kg', 1, 'Kilogram', 1.0]],
        'Pieces'   => [['1 pc', 1, 'Pieces', 1.0], ['6 pcs', 6, 'Pieces', 5.7], ['12 pcs', 12, 'Pieces', 11.0]],
    ];

    /* ─────────────────────── main ─────────────────────── */

    public function handle(): int
    {
        $out    = $this->option('out') ?: database_path('seeders/data/qc_catalog.json');
        $perCat = (int) $this->option('per-category');
        $only   = array_filter(array_map('intval', explode(',', (string) $this->option('only'))));

        $taxonomy = $this->taxonomy();
        if ($only) {
            $taxonomy = array_intersect_key($taxonomy, array_flip($only));
        }

        // --resume: reuse whatever a previous run already managed to fetch, so a
        // category lost to an OFF rate-limit can be filled without re-pulling the rest.
        $existing = [];
        if ($this->option('resume') && is_file($out)) {
            $existing = json_decode((string) file_get_contents($out), true)['stores'] ?? [];
            $this->info('Resuming from ' . $out);
        }

        // Remember photos an earlier run already found, so a --skip-images pass
        // rebuilds the data without throwing away images we paid API quota for.
        if (is_file($out)) {
            $prev = json_decode((string) file_get_contents($out), true)['stores'] ?? [];
            foreach ($prev as $sid => $sd) {
                foreach ($sd['groups'] ?? [] as $gd) {
                    foreach ($gd['subgroups'] ?? [] as $subd) {
                        foreach ($subd['categories'] ?? [] as $cd) {
                            foreach ($cd['products'] ?? [] as $p) {
                                if (!empty($p['image'])) {
                                    $this->priorImages[$sid . '|' . strtolower($p['name'])] = $p['image'];
                                }
                            }
                        }
                    }
                }
            }
            if ($this->priorImages) {
                $this->line('Carried over ' . count($this->priorImages) . ' existing image(s).');
            }
        }

        $result = ['stores' => [], 'summary' => []];
        $grand  = 0;

        foreach ($taxonomy as $storeId => $groups) {
            $this->usedInStore = [];
            $storeOut = ['groups' => []];
            $storeTotal = 0;

            foreach ($groups as $groupName => $subGroups) {
                $groupOut = ['image' => null, 'subgroups' => []];

                foreach ($subGroups as $subName => $cats) {
                    $subOut = ['image' => null, 'categories' => []];

                    foreach ($cats as $catName => $spec) {
                        $this->line("[store {$storeId}] {$groupName} › {$subName} › <info>{$catName}</info>");

                        $cached = $existing[$storeId]['groups'][$groupName]['subgroups'][$subName]['categories'][$catName] ?? null;

                        if ($cached && $cached['products']) {
                            // Recompute the type chips offline so classification fixes
                            // land without spending another API call.
                            $products = array_map(function ($p) use ($spec, $catName) {
                                if (!isset($spec['fresh'])) {
                                    $p['name']      = $this->squash($p['name']);
                                    $p['type_name'] = $this->matchType($p['name'], $this->typesFor($catName) ?? $spec['types'] ?? []);
                                }
                                return $p;
                            }, $cached['products']);
                            $catImage = $cached['image'];
                            $this->line('    <comment>' . count($products) . '</comment> products (cached)');
                        } else {
                            $products = isset($spec['fresh'])
                                ? $this->buildFresh($storeId, $catName, $spec)
                                : $this->buildPackaged($storeId, $catName, $spec, $perCat);

                            if (!$products) {
                                $this->warn("    no products resolved — category skipped");
                                continue;
                            }
                            $catImage = $this->option('skip-images')
                                ? ($products[0]['image'] ?? '')
                                : ($this->commonsImage($spec['img'] ?? $catName) ?? $products[0]['image']);
                            $this->line('    <comment>' . count($products) . '</comment> products');
                        }

                        $types = array_values(array_unique(array_column($products, 'type_name')));

                        $subOut['categories'][$catName] = [
                            'image'    => $catImage,
                            'types'    => $types,
                            'products' => $products,
                        ];
                        $subOut['image']   = $subOut['image'] ?? $catImage;
                        $groupOut['image'] = $groupOut['image'] ?? $catImage;
                        $storeTotal += count($products);
                    }

                    if ($subOut['categories']) {
                        $groupOut['subgroups'][$subName] = $subOut;
                    }
                }

                if ($groupOut['subgroups']) {
                    $storeOut['groups'][$groupName] = $groupOut;
                }
            }

            $result['stores'][$storeId] = $storeOut;
            $result['summary'][$storeId] = $storeTotal;
            $grand += $storeTotal;
            $this->info("store {$storeId}: {$storeTotal} products");
        }

        // Carry forward stores the existing file has but this run filtered out with
        // --only, so building the catalogue across several rate-limit windows
        // accumulates instead of overwriting.
        foreach ($existing as $storeId => $storeData) {
            if (!isset($result['stores'][$storeId])) {
                $result['stores'][$storeId] = $storeData;
                $kept = 0;
                foreach ($storeData['groups'] ?? [] as $gd) {
                    foreach ($gd['subgroups'] ?? [] as $sd) {
                        foreach ($sd['categories'] ?? [] as $cd) {
                            $kept += count($cd['products'] ?? []);
                        }
                    }
                }
                $result['summary'][$storeId] = $kept;
                $grand += $kept;
                $this->line("store {$storeId}: {$kept} products (carried forward)");
            }
        }

        $result['summary']['total'] = $grand;

        @mkdir(dirname($out), 0775, true);
        file_put_contents($out, json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));

        $this->newLine();
        if ($this->unsplashHits || $this->wikimediaHits || $this->wikipediaHits) {
            $this->info("Images — wikipedia: {$this->wikipediaHits}, unsplash: {$this->unsplashHits}, wikimedia: {$this->wikimediaHits}"
                . ($this->unsplashExhausted ? '  (Unsplash quota exhausted mid-run; re-run with --resume after it resets to upgrade the fallbacks)' : ''));
        }
        $this->info("Wrote {$grand} products to {$out}");
        return self::SUCCESS;
    }

    /* ─────────────────────── packaged (Open Food Facts) ─────────────────────── */

    private function buildPackaged(int $storeId, string $catName, array $spec, int $perCat): array
    {
        $raw = $this->offSearch($spec['off'], $spec['source'] ?? 'off');
        $out = [];

        foreach ($raw as $p) {
            if (count($out) >= $perCat) {
                break;
            }

            $name  = $this->titleCase(trim((string) ($p['product_name'] ?? '')));
            $brand = $this->titleCase(trim(explode(',', (string) ($p['brands'] ?? ''))[0]));
            $image = $p['image_front_url'] ?? $p['image_url'] ?? null;

            if ($name === '' || $brand === '' || !$image) {
                continue;
            }
            if (mb_strlen($name) > 90 || mb_strlen($brand) > 60) {
                continue;
            }

            // Prefix the brand unless the name already carries it.
            $display = stripos($name, $brand) === false ? "{$brand} {$name}" : $name;
            $display = $this->squash($display);

            $dedupe = $storeId . '|' . strtolower($display);
            if (isset($this->usedInStore[$dedupe])) {
                continue;
            }
            $this->usedInStore[$dedupe] = true;

            $qty = $this->parseQuantity($p['quantity'] ?? null);
            if (!$qty) {
                // No usable pack size — fall back to a plausible one for the category.
                $qty = $this->defaultQuantity($spec['base']);
            }

            $seed  = crc32((string) ($p['code'] ?? $display));
            $price = $this->derivePrice($spec['base'], $qty['norm'], $seed);
            $disc  = $this->deriveDiscount($price, $seed);

            $out[] = [
                'name'              => $display,
                'brand'             => $brand,
                'barcode'           => (string) ($p['code'] ?? ''),
                'image'             => $image,
                'type_name'         => $this->matchType($display, $this->typesFor($catName) ?? $spec['types'] ?? []),
                'measurement'       => $qty['measurement'],
                'unit'              => $qty['unit'],
                'size_label'        => $qty['label'],
                'price'             => $price,
                'discounted_price'  => $disc,
                'stock'             => 25 + ($seed % 175),
                'description'       => "<p>{$display} — {$qty['label']} pack. Genuine {$brand} product, sealed and quality checked.</p>",
                'tags'              => implode(',', array_filter([$brand, $catName, $qty['label']])),
            ];
        }

        return $out;
    }

    /**
     * Sibling databases run by the same project, same API shape. Open Food
     * Facts is food-only, so personal care, home care and general merchandise
     * — which a Zepto-style catalogue needs — come from these instead.
     */
    private const SOURCE_HOSTS = [
        'off' => 'https://world.openfoodfacts.org',      // food & drink
        'obf' => 'https://world.openbeautyfacts.org',    // personal care, cosmetics
        'opf' => 'https://world.openproductsfacts.org',  // everything else
    ];

    /**
     * One throttled, retried Open * Facts search. Cached per source+tag so two
     * stores sharing a tag cost a single HTTP call.
     */
    private function offSearch(string $tag, string $source = 'off'): array
    {
        $cacheKey = $source . ':' . $tag;
        if (isset($this->offCache[$cacheKey])) {
            return $this->offCache[$cacheKey];
        }

        $host = self::SOURCE_HOSTS[$source] ?? self::SOURCE_HOSTS['off'];
        $url = $host . '/api/v2/search';
        $params = [
            'categories_tags_en' => $tag,
            'fields'             => 'code,product_name,brands,quantity,image_front_url,image_url',
            'page_size'          => 100,
            'json'               => 1,
        ];

        // Only Open Food Facts has enough Indian coverage to filter by country;
        // the beauty and general-product databases would return almost nothing.
        if ($source === 'off') {
            $params['countries_tags_en'] = 'india';
        }

        $sleep = (int) $this->option('sleep');
        $products = [];

        for ($attempt = 1; $attempt <= 4; $attempt++) {
            sleep($attempt === 1 ? $sleep : $sleep * $attempt);

            try {
                $res = Http::withHeaders(['User-Agent' => self::UA])
                    ->timeout(60)
                    ->get($url, $params);
            } catch (\Throwable $e) {
                $this->warn("    {$source} '{$tag}' attempt {$attempt} failed: " . $e->getMessage());
                continue;
            }

            $body = $res->body();
            if (!str_starts_with(ltrim($body), '{')) {
                // These sites serve an HTML "temporarily unavailable" page when rate-limited.
                $this->warn("    {$source} '{$tag}' rate-limited (attempt {$attempt}), backing off…");
                continue;
            }

            $json = json_decode($body, true);
            $products = $json['products'] ?? [];
            break;
        }

        if (!$products) {
            $this->warn("    {$source} '{$tag}' returned nothing after retries.");
        }

        // Prefer entries that actually have a photo and a pack size.
        usort($products, function ($a, $b) {
            $score = fn ($p) => (empty($p['image_front_url']) ? 0 : 2) + (empty($p['quantity']) ? 0 : 1);
            return $score($b) <=> $score($a);
        });

        return $this->offCache[$cacheKey] = $products;
    }

    /* ─────────────────────── fresh (Wikimedia Commons) ─────────────────────── */

    private function buildFresh(int $storeId, string $catName, array $spec): array
    {
        $unit  = $spec['unit'] ?? 'Kilogram';
        $sizes = $this->freshSizes[$unit];
        $out   = [];

        foreach ($spec['fresh'] as $item => [$query, $perUnit]) {
            // Always reuse a photo an earlier run already found — image APIs are the
            // scarce resource here (Unsplash demo tier is 50 req/hr), so a backfill
            // pass should only spend quota on the items still missing one.
            $image = $this->priorImages[$storeId . '|' . strtolower($item)] ?? '';

            if (!$image && !$this->option('skip-images')) {
                // Wikipedia's article lead image first: relevance is guaranteed
                // by construction and there is no quota to run out of, which is
                // what left all 54 vegetables and fruits blank on the last run.
                // Unsplash/Commons stay as the fallback for items with no article.
                $image = $this->wikipediaImage($item)
                    ?? $this->commonsImage($query)
                    ?? '';

                if (!$image) {
                    $this->warn("    no image found for '{$item}' — kept without one");
                }
            }

            $dedupe = $storeId . '|' . strtolower($item);
            if (isset($this->usedInStore[$dedupe])) {
                continue;
            }
            $this->usedInStore[$dedupe] = true;

            $seed = crc32($item);
            $variants = [];
            foreach ($sizes as [$label, $measurement, $unitName, $factor]) {
                $price = max(5, (int) round($perUnit * $factor / 5) * 5);
                $variants[] = [
                    'size_label'       => $label,
                    'measurement'      => $measurement,
                    'unit'             => $unitName,
                    'price'            => $price,
                    'discounted_price' => $this->deriveDiscount($price, $seed),
                    'stock'            => 20 + ($seed % 120),
                ];
            }

            $out[] = [
                'name'        => $item,
                'brand'       => 'Farm Fresh',
                'barcode'     => '',
                'image'       => $image,
                'type_name'   => $catName,
                'variants'    => $variants,
                'description' => "<p>Fresh {$item}, sourced daily from local farms. Hand-picked and quality checked before delivery.</p>",
                'tags'        => implode(',', [$item, $catName, 'Fresh']),
            ];
        }

        return $out;
    }

    /**
     * Best available photo for a loose item / category tile.
     *
     * Unsplash first when UNSPLASH_ACCESS_KEY is configured — its food
     * photography is far cleaner than Commons, which happily returns a cooked
     * curry, the wrong species, or a 1913 book plate. Commons stays as the
     * key-less fallback.
     */
    private function commonsImage(string $query): ?string
    {
        static $cache = [];
        $key = strtolower($query);
        if (array_key_exists($key, $cache)) {
            return $cache[$key];
        }

        if ($url = $this->unsplashImage($query)) {
            return $cache[$key] = $url;
        }

        return $cache[$key] = $this->wikimediaImage($query);
    }

    /**
     * Item name => English Wikipedia article title, where the plain name would
     * resolve to the wrong thing. These matter: "Kiwi" is a bird, "Drumstick"
     * is a drum stick, "Ladyfinger" is a sponge biscuit, and "Orange" is a
     * disambiguation page. Anything not listed uses the item name as-is and
     * relies on Wikipedia's own redirects (Brinjal → Eggplant, and so on).
     */
    private const WIKI_TITLE = [
        'Lady Finger'      => 'Okra',
        'Drumstick'        => 'Moringa oleifera',
        'Kiwi'             => 'Kiwifruit',
        'Orange'           => 'Orange (fruit)',
        'Grapes'           => 'Grape',
        'Green Capsicum'   => 'Bell pepper',
        'Red Capsicum'     => 'Bell pepper',
        'Yellow Capsicum'  => 'Bell pepper',
        'Bottle Gourd'     => 'Calabash',
        'Ridge Gourd'      => 'Luffa',
        'Bitter Gourd'     => 'Momordica charantia',
        'Green Beans'      => 'Green bean',
        'Green Peas'       => 'Pea',
        'Sweet Lime'       => 'Citrus limetta',
        'Muskmelon'        => 'Cucumis melo',
        'Mushroom'         => 'Agaricus bisporus',
        'Coriander Leaves' => 'Coriander',
        'Mint Leaves'      => 'Mentha',
        'Curry Leaves'     => 'Curry tree',
        'Dill Leaves'      => 'Dill',
        'Fenugreek Leaves' => 'Fenugreek',
        'Amaranth Leaves'  => 'Amaranth',
        'Spring Onion'     => 'Scallion',
        'Dragon Fruit'     => 'Pitaya',
        'Sweet Corn'       => 'Sweet corn',
        'Baby Corn'        => 'Baby corn',
        'Cherry Tomato'    => 'Cherry tomato',
    ];

    /**
     * The lead photo of an English Wikipedia article, via the PageImages API.
     *
     * This is the most RELEVANT source available for loose produce, meat and
     * fish: the lead image of "Tomato" is a tomato by construction, whereas a
     * Commons keyword search happily returns a cooked curry or a 1913 book
     * plate, and Unsplash runs out after 50 requests an hour.
     *
     * Key-less, no meaningful rate limit, and `redirects=1` resolves the Indian
     * names Wikipedia already knows (Brinjal → Eggplant).
     */
    private function wikipediaImage(string $item): ?string
    {
        static $cache = [];
        $title = self::WIKI_TITLE[$item] ?? $item;
        if (array_key_exists($title, $cache)) {
            return $cache[$title];
        }

        try {
            usleep(250000); // ~4 req/s, well inside Wikipedia's limits
            $res = Http::withHeaders(['User-Agent' => self::UA])
                ->timeout(45)
                ->get('https://en.wikipedia.org/w/api.php', [
                    'action'      => 'query',
                    'titles'      => $title,
                    'prop'        => 'pageimages',
                    'piprop'      => 'thumbnail',
                    'pithumbsize' => 800,
                    'redirects'   => 1,
                    'format'      => 'json',
                ]);

            $pages = $res->json('query.pages') ?? [];
            foreach ($pages as $page) {
                $url = $page['thumbnail']['source'] ?? null;
                if (!$url) {
                    continue;
                }
                // Flutter can't decode svg/tif — keep to raster formats.
                if (!preg_match('/\.(jpg|jpeg|png)$/i', $url)) {
                    continue;
                }
                // Taxonomically right is not commercially right: the lead image
                // of "Coriander" is an 1887 lithograph and "Curry tree" is a
                // tree. A shopper expects the edible part, so hand those to the
                // photo sources instead.
                if ($this->looksBotanical($url)) {
                    $this->line("    wikipedia '{$title}' lead image is a plate/plant — trying photo sources");
                    break;
                }
                $this->wikipediaHits++;
                return $cache[$title] = $url;
            }
        } catch (\Throwable $e) {
            $this->warn("    wikipedia '{$title}' failed: " . $e->getMessage());
        }

        return $cache[$title] = null;
    }

    /**
     * Filename markers for a botanical plate, a herbarium scan, or a photo of
     * the living plant rather than the harvested produce.
     *
     * Matched against the file name only — 'Koehler'/'Medizinal' catch the 1887
     * Köhler plates, 'bloei'/'blossom'/'flower'/'tree' catch the plant shots
     * (e.g. Spinacia_oleracea_Spinazie_bloeiend.jpg, DrumstickFlower.jpg).
     */
    private const WIKI_BOTANICAL_REJECT = [
        'illustration', 'medizinal', 'kohler', 'koehler', 'k%c3%b6hler', 'blanco',
        'drawing', 'engraving', 'lithograph', 'plate', 'herbarium', 'botanical',
        'flower', 'blossom', 'bloei', 'bloem', 'tree', 'plantation', 'field',
        'seedling', 'sapling', 'foliage',
    ];

    private function looksBotanical(string $url): bool
    {
        $name = strtolower(basename(parse_url($url, PHP_URL_PATH) ?: $url));

        foreach (self::WIKI_BOTANICAL_REJECT as $bad) {
            if (str_contains($name, $bad)) {
                return true;
            }
        }

        return false;
    }

    /** Unsplash search. Returns null (silently) when no key is configured. */
    private function unsplashImage(string $query): ?string
    {
        $accessKey = env('UNSPLASH_ACCESS_KEY');
        if (!$accessKey) {
            return null;
        }

        try {
            usleep(300000);
            $res = Http::withHeaders([
                    'Authorization' => 'Client-ID ' . $accessKey,
                    'Accept-Version' => 'v1',
                    'User-Agent'    => self::UA,
                ])
                ->timeout(45)
                ->get('https://api.unsplash.com/search/photos', [
                    'query'       => $query,
                    'per_page'    => 5,
                    'orientation' => 'squarish',
                    'content_filter' => 'high',
                ]);

            if ($res->status() === 403) {
                $this->unsplashExhausted = true;
                $this->warn('    unsplash rate limit reached (50/hr on the demo tier) — falling back to Wikimedia');
                return null;
            }

            // Must use urls.raw, NOT the `id` field: the API id (e.g. "sgmS2e95QO0")
            // is unrelated to the image path (photo-1615486171815-2611a6e3cd02), so
            // building the URL from the id yields a 404.
            //
            // Take the first result not already used: "chicken legs" and "chicken
            // wings" return the same top photo, and a grid of identical tiles reads
            // as obviously fake.
            $raw = null;
            foreach ($res->json('results') ?? [] as $hit) {
                $candidate = $hit['urls']['raw'] ?? null;
                if ($candidate && !isset($this->usedImages[$candidate])) {
                    $raw = $candidate;
                    break;
                }
            }
            if (!$raw) {
                return null;
            }

            $this->usedImages[$raw] = true;
            $this->unsplashHits++;

            // fm=jpg, NOT auto=format: with auto=format Unsplash serves AVIF to
            // clients that accept it, which Flutter can't decode (blank tiles).
            // urls.raw already carries ?ixid=…, so these append with &.
            return $raw . '&w=600&q=75&fm=jpg&fit=crop';
        } catch (\Throwable $e) {
            $this->warn("    unsplash '{$query}' failed: " . $e->getMessage());
            return null;
        }
    }

    /** Words that signal a cooked dish, a restaurant scene or a book scan. */
    private const COMMONS_REJECT = [
        'recipe', 'cooked', 'grilled', 'fried', 'curry', 'roast', 'baked', 'soup',
        'salad', 'restaurant', 'dish', 'plate', 'meal', 'stew', 'sauce', 'pizza',
        'sandwich', 'drawing', 'illustration', 'painting', 'engraving', 'diagram',
        'map', 'logo', 'stamp', 'poster', 'label', 'sizzling', 'skewered', 'boiled',
    ];

    /** Wikimedia Commons image search — key-less, returns a 600 px thumbnail URL. */
    private function wikimediaImage(string $query): ?string
    {
        try {
            usleep(400000); // be polite: ~2.5 req/s
            $res = Http::withHeaders(['User-Agent' => self::UA])
                ->timeout(45)
                ->get('https://commons.wikimedia.org/w/api.php', [
                    'action'      => 'query',
                    'generator'   => 'search',
                    'gsrsearch'   => 'filetype:bitmap ' . $query,
                    'gsrlimit'    => 8,
                    'gsrnamespace' => 6,
                    'prop'        => 'imageinfo',
                    'iiprop'      => 'url|mime',
                    'iiurlwidth'  => 600,
                    'format'      => 'json',
                ]);

            $pages = $res->json('query.pages') ?? [];
            $first = strtok(strtolower($query), ' ');
            $onTopic = null;   // title mentions the subject AND looks like a raw ingredient
            $anyClean = null;  // at least not a cooked dish / illustration

            foreach ($pages as $page) {
                $url = $page['imageinfo'][0]['thumburl'] ?? null;
                if (!$url) {
                    continue;
                }
                // Flutter can't decode svg/tif; keep to jpg/png.
                if (!preg_match('/\.(jpg|jpeg|png)$/i', $url)) {
                    continue;
                }

                $title = strtolower((string) ($page['title'] ?? ''));
                foreach (self::COMMONS_REJECT as $bad) {
                    if (str_contains($title, $bad)) {
                        continue 2;
                    }
                }

                if (isset($this->usedImages[$url])) {
                    continue;   // never show the same photo on two tiles
                }

                $anyClean = $anyClean ?? $url;
                if ($first && str_contains($title, $first)) {
                    $onTopic = $url;
                    break;
                }
            }

            // Wrong-subject photos are worse than no photo: the caller skips the
            // item rather than showing a Pacu where a Pomfret should be.
            $pick = $onTopic ?? $anyClean;
            if ($pick) {
                $this->usedImages[$pick] = true;
                $this->wikimediaHits++;
            }
            return $pick;
        } catch (\Throwable $e) {
            $this->warn("    commons '{$query}' failed: " . $e->getMessage());
            return null;
        }
    }

    /* ─────────────────────── helpers ─────────────────────── */

    /** "500 g" / "1kg" / "6 x 50 g" → measurement + unit + normalised g/ml. */
    private function parseQuantity(?string $q): ?array
    {
        if (!$q) {
            return null;
        }
        $q = strtolower(str_replace(',', '.', trim($q)));

        $mult = 1;
        if (preg_match('/^\s*(\d+)\s*[x×*]\s*(.+)$/u', $q, $m)) {
            $mult = max(1, (int) $m[1]);
            $q = $m[2];
        }

        if (!preg_match('/([\d.]+)\s*(kilograms?|kgs?|grams?|gms?|gr|g|milligrams?|mg|litres?|liters?|ltrs?|ltr|l|millilitres?|milliliters?|mls?|ml|cl)\b/u', $q, $m)) {
            return null;
        }

        $val  = (float) $m[1];
        $unit = $m[2];
        if ($val <= 0) {
            return null;
        }

        $volume = false;
        // Normalise to grams (solids) or millilitres (liquids).
        if (preg_match('/^(kilograms?|kgs?)$/', $unit))            { $norm = $val * 1000; }
        elseif (preg_match('/^(grams?|gms?|gr|g)$/', $unit))       { $norm = $val; }
        elseif (preg_match('/^(milligrams?|mg)$/', $unit))         { $norm = $val / 1000; }
        elseif (preg_match('/^(litres?|liters?|ltrs?|ltr|l)$/', $unit)) { $norm = $val * 1000; $volume = true; }
        elseif ($unit === 'cl')                                    { $norm = $val * 10;   $volume = true; }
        else                                                       { $norm = $val;        $volume = true; }

        $norm *= $mult;
        if ($norm < 1 || $norm > 25000) {
            return null;
        }

        // Pick the display unit the way a shopper would read it.
        if ($volume) {
            [$measurement, $unitName, $label] = $norm >= 1000
                ? [$norm / 1000, 'Litre', $this->num($norm / 1000) . ' L']
                : [$norm, 'Millilitre', $this->num($norm) . ' ml'];
        } else {
            [$measurement, $unitName, $label] = $norm >= 1000
                ? [$norm / 1000, 'Kilogram', $this->num($norm / 1000) . ' kg']
                : [$norm, 'Grams', $this->num($norm) . ' g'];
        }

        return [
            'measurement' => round($measurement, 2),
            'unit'        => $unitName,
            'label'       => $label,
            'norm'        => $norm,
        ];
    }

    /** Plausible pack size when OFF has none, chosen to suit the price band. */
    private function defaultQuantity(float $base): array
    {
        $norm = $base >= 60 ? 100 : ($base >= 20 ? 250 : 500);
        return [
            'measurement' => $norm,
            'unit'        => 'Grams',
            'label'       => $this->num($norm) . ' g',
            'norm'        => $norm,
        ];
    }

    /** base = INR per 100 g/ml; larger packs get a mild bulk discount. */
    private function derivePrice(float $base, float $norm, int $seed): int
    {
        $price = $base * pow($norm / 100, 0.93);
        $price *= 0.9 + (($seed % 26) / 100);            // ±  deterministic jitter
        $price = max(5, $price);
        return $price < 30 ? (int) round($price) : (int) (round($price / 5) * 5);
    }

    /** price is MRP; the returned value is the selling price shown to shoppers. */
    private function deriveDiscount(int $price, int $seed): int
    {
        $steps = [0, 5, 10, 12, 15, 18, 20, 25];
        $pct = $steps[($seed >> 3) % count($steps)];
        return max(1, (int) round($price * (100 - $pct) / 100));
    }

    /** Assign a "Filters by Type" chip by keyword. */
    private function matchType(string $name, array $types): string
    {
        if (!$types) {
            return 'Regular';
        }
        $lower = strtolower($name);
        foreach ($types as $type => $keywords) {
            foreach ($keywords as $kw) {
                if (str_contains($lower, $kw)) {
                    return $type;
                }
            }
        }
        // Types with an empty keyword list act as the declared catch-all.
        foreach ($types as $type => $keywords) {
            if (!$keywords) {
                return $type;
            }
        }
        // Never dump unmatched items into the last named chip — that turns a real
        // filter ("Salted") into a junk bucket. Give them their own chip instead.
        return 'Others';
    }

    private function titleCase(string $s): string
    {
        $s = preg_replace('/\s+/', ' ', trim($s));
        if ($s === '') {
            return '';
        }
        // Leave names that are already mixed-case alone (e.g. "McVitie's").
        if ($s !== mb_strtolower($s) && $s !== mb_strtoupper($s)) {
            return $s;
        }
        return mb_convert_case(mb_strtolower($s), MB_CASE_TITLE, 'UTF-8');
    }

    /**
     * Tidy the raw OFF title: collapse an accidental "Britannia Britannia Good Day"
     * repeat, and drop the size/packaging noise shoppers don't need to read
     * ("Jimjam 57g (57)" → "Jimjam") since the pack size has its own field.
     */
    private function squash(string $s): string
    {
        $s = preg_replace('/\s+/', ' ', trim($s));
        $s = preg_replace('/\b(\w+)(\s+\1\b)+/iu', '$1', $s);
        $s = preg_replace('/\s*\([^)]*\)\s*$/u', '', $s);                 // trailing "(57)"
        $s = preg_replace('/[\s\-]+\d+(\.\d+)?\s*(g|gm|gms|kg|ml|l|ltr)\b\.?$/iu', '', $s); // trailing "57g" / "-225g"
        $s = preg_replace('/[\s\-–,:;.]+$/u', '', $s);                     // dangling punctuation
        return trim($s);
    }

    private function num(float $n): string
    {
        return rtrim(rtrim(number_format($n, 2, '.', ''), '0'), '.');
    }
}
