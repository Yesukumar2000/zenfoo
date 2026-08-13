<?php

namespace Database\Seeders\DemoWorld;

use Illuminate\Support\Facades\DB;

/**
 * Shared constants + helpers for the Zenfoo demo world seeders.
 *
 * ─────────────────────────── SAFETY CONTRACT ───────────────────────────
 * Every row these seeders create is identifiable, so a re-run or a purge
 * removes EXACTLY its own rows and never touches a real signup:
 *
 *   sellers          email LIKE '%@demo.zenfoo.test'
 *   users            email LIKE '%@demo.zenfoo.test'  (+ referral_code 'ZFDEMO…')
 *   delivery_boys    email LIKE '%@demo.zenfoo.test'  (+ remark 'ZFDEMO…')
 *   orders           orders_id LIKE 'ZFDEMO%'
 *   everything else  reached through the ids above
 *
 * `users` has no auth_uid column — it was dropped in 2024 — which is why the
 * customer marker is the email domain rather than an id prefix.
 *
 * Nothing is ever UPDATEd on a pre-existing row. If a name collides with a
 * real record the seeder skips it rather than overwriting.
 *
 * ─────────────────────────── RESERVED NUMBERS ──────────────────────────
 * Deterministic so you can actually log in during a demo:
 *
 *   customers  9000000001 … 9000000150
 *   drivers    9100000001 … 9100000025
 *   vendors    9200000001 … 9200000012
 *
 * All emails are @demo.zenfoo.test, a reserved TLD that can never receive
 * mail — no chance of a demo blast reaching a real inbox.
 */
final class DemoWorld
{
    /** Purge/identify marker. Appears in remark/note columns too. */
    public const MARKER = 'ZFDEMO';

    /** Reserved, non-deliverable domain (RFC 6761 .test). */
    public const EMAIL_DOMAIN = 'demo.zenfoo.test';

    public const MOBILE_CUSTOMER_BASE = 9000000000;
    public const MOBILE_DRIVER_BASE   = 9100000000;
    public const MOBILE_VENDOR_BASE   = 9200000000;

    /** Default volumes (overridable per seeder via --). */
    public const N_VENDORS   = 12;
    public const N_CUSTOMERS = 150;
    public const N_DRIVERS   = 25;
    public const N_ORDERS    = 800;
    public const DAYS_BACK   = 90;

    /** Fixed password for every demo account, so a demo login always works. */
    public const PASSWORD = 'Zenfoo@Demo1';

    /** Where generated KYC/document images live, relative to public/. */
    public const DOC_DIR = 'images/demo-docs';

    /* ───────────────────────────── cities ───────────────────────────── */

    /**
     * The two demo cities. lat/lng is the city centre; `spread` is the radius
     * in degrees used to scatter addresses, sellers and drivers around it
     * (~0.045° ≈ 5 km, comfortably inside a quick-commerce delivery radius).
     */
    public const CITIES = [
        'Hyderabad' => [
            'state'     => 'Telangana',
            'lat'       => 17.3850,
            'lng'       => 78.4867,
            'spread'    => 0.055,
            'zone'      => 'South',
            'pincodes'  => ['500001', '500016', '500032', '500034', '500072', '500081', '500084'],
            'localities' => [
                'Banjara Hills', 'Jubilee Hills', 'Gachibowli', 'Madhapur', 'Kondapur',
                'Kukatpally', 'Miyapur', 'Ameerpet', 'Begumpet', 'Secunderabad',
                'Manikonda', 'Hitec City', 'LB Nagar', 'Dilsukhnagar', 'Uppal',
            ],
        ],
        'Kurnool' => [
            'state'     => 'Andhra Pradesh',
            'lat'       => 15.8281,
            'lng'       => 78.0373,
            'spread'    => 0.030,
            'zone'      => 'South',
            'pincodes'  => ['518001', '518002', '518003', '518004', '518005'],
            'localities' => [
                'Kothapeta', 'Budhawarpeta', 'Gayatri Estate', 'Nandyal Road',
                'Bellary Road', 'Ashok Nagar', 'Balaji Nagar', 'C Camp',
                'Krishna Nagar', 'Park Road',
            ],
        ],
    ];

    /* ────────────────────────── people pools ────────────────────────── */

    public const FIRST_NAMES = [
        'Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Krishna',
        'Ishaan', 'Rohan', 'Karthik', 'Naveen', 'Sandeep', 'Praveen', 'Mahesh',
        'Ramesh', 'Suresh', 'Venkat', 'Srinivas', 'Bhargav', 'Kiran', 'Manoj',
        'Ananya', 'Diya', 'Aadhya', 'Saanvi', 'Pari', 'Anika', 'Navya', 'Sri',
        'Lakshmi', 'Padma', 'Swathi', 'Divya', 'Sneha', 'Priya', 'Keerthi',
        'Harika', 'Vasudha', 'Meghana', 'Rashmi', 'Nikhitha', 'Anusha',
    ];

    public const LAST_NAMES = [
        'Reddy', 'Rao', 'Naidu', 'Sharma', 'Verma', 'Kumar', 'Prasad', 'Chowdary',
        'Goud', 'Yadav', 'Shetty', 'Patel', 'Gupta', 'Bhat', 'Nair', 'Menon',
        'Iyer', 'Krishnan', 'Varma', 'Sastry', 'Acharya', 'Pillai',
    ];

    /** Vendor/store names, paired with the store type they best fit. */
    public const VENDOR_TEMPLATES = [
        ['name' => 'Sri Balaji Super Mart',      'kind' => 'supermart'],
        ['name' => 'Annapurna Daily Needs',      'kind' => 'supermart'],
        ['name' => 'Green Basket Kirana',        'kind' => 'supermart'],
        ['name' => 'Ratnadeep Express',          'kind' => 'supermart'],
        ['name' => 'Vasavi Fresh Farms',         'kind' => 'vegetable'],
        ['name' => 'Nature Fresh Vegetables',    'kind' => 'vegetable'],
        ['name' => 'Rythu Bazaar Direct',        'kind' => 'vegetable'],
        ['name' => 'Al-Madina Chicken Centre',   'kind' => 'meat'],
        ['name' => 'Deccan Mutton House',        'kind' => 'meat'],
        ['name' => 'Golden Gate Meat Mart',      'kind' => 'meat'],
        ['name' => 'Blue Wave Sea Foods',        'kind' => 'fish'],
        ['name' => 'Coastal Catch Fish Mart',    'kind' => 'fish'],
    ];

    public const BANKS = [
        ['State Bank of India', 'SBIN0'], ['HDFC Bank', 'HDFC0'], ['ICICI Bank', 'ICIC0'],
        ['Axis Bank', 'UTIB0'], ['Kotak Mahindra Bank', 'KKBK0'], ['Union Bank of India', 'UBIN0'],
        ['Canara Bank', 'CNRB0'], ['Bank of Baroda', 'BARB0'],
    ];

    public const VEHICLES = ['Bike', 'Scooter', 'Electric Scooter', 'Bicycle', 'Three Wheeler'];

    /* ─────────────────────── deterministic RNG ─────────────────────── */

    /**
     * A tiny seeded PRNG. Every random-looking value in the demo world is
     * derived from a string key, so two runs on two machines produce the
     * SAME data — which is what makes screenshots and re-runs stable.
     */
    public static function seedOf(string $key): int
    {
        return (int) hexdec(substr(md5(self::MARKER . '|' . $key), 0, 8));
    }

    /** Integer in [$min, $max] derived from $key. */
    public static function intFor(string $key, int $min, int $max): int
    {
        if ($max <= $min) {
            return $min;
        }
        return $min + (self::seedOf($key) % ($max - $min + 1));
    }

    /** Float in [$min, $max] derived from $key. */
    public static function floatFor(string $key, float $min, float $max): float
    {
        $unit = (self::seedOf($key) % 1000000) / 1000000;
        return $min + ($max - $min) * $unit;
    }

    /** Deterministic pick from a list. */
    public static function pick(string $key, array $list)
    {
        return $list[self::seedOf($key) % count($list)];
    }

    /** True with probability $percent, derived from $key. */
    public static function chance(string $key, int $percent): bool
    {
        return (self::seedOf($key) % 100) < $percent;
    }

    /* ───────────────────────────── geo ─────────────────────────────── */

    /**
     * A point scattered around a city centre. Uses a square-root radius so
     * points spread evenly over the disc instead of clustering at the middle.
     *
     * @return array{0: float, 1: float} [lat, lng]
     */
    public static function pointNear(string $cityName, string $key): array
    {
        $city = self::CITIES[$cityName];
        $angle = self::floatFor($key . '|angle', 0, 2 * M_PI);
        $r = $city['spread'] * sqrt(self::floatFor($key . '|radius', 0.05, 1.0));

        return [
            round($city['lat'] + $r * cos($angle), 6),
            round($city['lng'] + $r * sin($angle), 6),
        ];
    }

    /** Straight-line km between two lat/lng pairs (haversine). */
    public static function distanceKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return round(6371 * 2 * atan2(sqrt($a), sqrt(1 - $a)), 2);
    }

    /* ─────────────────── synthetic identity numbers ────────────────── */
    /*
     * These are deliberately INVALID:
     *   - Aadhaar is masked to the format the UI renders and fails the
     *     Verhoeff checksum, so it can never be mistaken for a real UID.
     *   - PAN uses the reserved 'ZZ' series.
     *   - GSTIN / FSSAI / DL are format-correct but non-issued ranges.
     * They exercise your validation + display code without producing anything
     * that resembles a genuine identity document.
     */

    public static function aadhaar(string $key): string
    {
        return 'XXXX XXXX ' . str_pad((string) self::intFor($key . '|aad', 1000, 9999), 4, '0', STR_PAD_LEFT);
    }

    public static function pan(string $key): string
    {
        $letters = 'ABCDEFGHJKLMNPQRSTUVWXY';
        $l = fn (string $s) => $letters[self::seedOf($key . $s) % strlen($letters)];

        // 'ZZ' prefix marks it as a sample series.
        return 'ZZ' . $l('c') . 'P' . $l('n')
            . str_pad((string) self::intFor($key . '|pan', 1000, 9999), 4, '0', STR_PAD_LEFT)
            . $l('x');
    }

    public static function gstin(string $key, string $state): string
    {
        $code = $state === 'Telangana' ? '36' : '37'; // TS / AP
        return $code . self::pan($key) . '1Z' . chr(65 + (self::seedOf($key . '|gz') % 26));
    }

    public static function fssai(string $key): string
    {
        // 14 digits, leading '1' = state licence, as the real format goes.
        return '1' . str_pad((string) self::intFor($key . '|fs', 1, 9999999999999), 13, '0', STR_PAD_LEFT);
    }

    public static function drivingLicence(string $key, string $state): string
    {
        $prefix = $state === 'Telangana' ? 'TS' : 'AP';
        return $prefix . str_pad((string) self::intFor($key . '|dl1', 1, 39), 2, '0', STR_PAD_LEFT)
            . ' ' . self::intFor($key . '|dl2', 2010, 2023)
            . str_pad((string) self::intFor($key . '|dl3', 1, 999999), 7, '0', STR_PAD_LEFT);
    }

    public static function ifsc(string $bankPrefix, string $key): string
    {
        return $bankPrefix . str_pad((string) self::intFor($key . '|ifsc', 1, 9999), 6, '0', STR_PAD_LEFT);
    }

    public static function accountNumber(string $key): string
    {
        return (string) self::intFor($key . '|acc', 10000000000, 99999999999);
    }

    public static function vehicleNumber(string $key, string $state): string
    {
        $prefix = $state === 'Telangana' ? 'TS' : 'AP';
        $letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
        return $prefix . str_pad((string) self::intFor($key . '|v1', 1, 36), 2, '0', STR_PAD_LEFT)
            . ' ' . $letters[self::seedOf($key . '|v2') % 24] . $letters[self::seedOf($key . '|v3') % 24]
            . ' ' . str_pad((string) self::intFor($key . '|v4', 1, 9999), 4, '0', STR_PAD_LEFT);
    }

    /* ────────────────────────── misc helpers ───────────────────────── */

    public static function fullName(string $key): string
    {
        return self::pick($key . '|fn', self::FIRST_NAMES) . ' ' . self::pick($key . '|ln', self::LAST_NAMES);
    }

    public static function email(string $name, int $n): string
    {
        $slug = strtolower(preg_replace('/[^a-z0-9]+/i', '.', trim($name)));
        return trim($slug, '.') . '.' . $n . '@' . self::EMAIL_DOMAIN;
    }

    /** Ensure a city row exists; returns its id. Never edits an existing one. */
    public static function ensureCity(string $name): int
    {
        $existing = DB::table('cities')->whereRaw('LOWER(name) = ?', [strtolower($name)])->value('id');
        if ($existing) {
            return (int) $existing;
        }

        $c = self::CITIES[$name];

        return (int) DB::table('cities')->insertGetId([
            'name'                        => $name,
            'state'                       => $c['state'],
            'formatted_address'           => "{$name}, {$c['state']}, India",
            'latitude'                    => (string) $c['lat'],
            'longitude'                   => (string) $c['lng'],
            'min_amount_for_free_delivery' => '299',
            'delivery_charge_method'       => '1',
            'fixed_charge'                => 25,
            'per_km_charge'               => 8,
            'time_to_travel'              => 3,
            'geolocation_type'            => 'radius',
            'radius'                      => '12',
            'max_deliverable_distance'    => 15,
            'zone'                        => $c['zone'],
        ]);
    }

    /** True when the configured DB looks like the live Hostinger database. */
    public static function looksLikeProduction(): bool
    {
        $host = (string) config('database.connections.' . config('database.default') . '.host');
        $name = (string) config('database.connections.' . config('database.default') . '.database');

        return str_contains($host, 'hstgr.io')
            || str_contains($host, 'hostinger')
            || str_starts_with($name, 'u675966105');
    }
}
