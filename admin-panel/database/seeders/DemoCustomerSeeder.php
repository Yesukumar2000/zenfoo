<?php

namespace Database\Seeders;

use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Demo customers with deliverable addresses in Hyderabad and Kurnool.
 *
 * Each customer gets 1–3 saved addresses (Home / Work / Other) scattered inside
 * the city's delivery radius, a wallet balance with a matching transaction
 * history, and — for about a third of them — a referral link to an earlier
 * customer via `friends_code`, so the referral payout job has real pairs to
 * work on instead of an empty table.
 *
 * Identified by email LIKE '%@demo.zenfoo.test' (and, as a second signal, a
 * referral_code prefixed ZFDEMO). Never touches an existing user.
 *
 * NOTE: `users` has no auth_uid column — it was dropped in 2024
 * (remove_auth_id_from_users_table). Real accounts are identified by mobile.
 */
class DemoCustomerSeeder extends Seeder
{
    private const ADDRESS_TYPES = ['Home', 'Work', 'Other'];

    public function run(): void
    {
        $hyderabad = DemoWorld::ensureCity('Hyderabad');
        $kurnool   = DemoWorld::ensureCity('Kurnool');

        $created = 0;
        $skipped = 0;
        $addresses = 0;
        $referred = 0;

        /** @var array<int,string> referral codes of customers already inserted */
        $pool = [];

        for ($n = 1; $n <= DemoWorld::N_CUSTOMERS; $n++) {
            $key = "customer|$n";

            $cityName = DemoWorld::chance($key . '|city', 72) ? 'Hyderabad' : 'Kurnool';
            $cityId   = $cityName === 'Kurnool' ? $kurnool : $hyderabad;
            $city     = DemoWorld::CITIES[$cityName];

            $person = DemoWorld::fullName($key);
            $mobile = (string) (DemoWorld::MOBILE_CUSTOMER_BASE + $n);
            $email  = DemoWorld::email($person, $n);

            if (DB::table('users')->where('mobile', $mobile)->orWhere('email', $email)->exists()) {
                $skipped++;
                continue;
            }

            $referralCode = DemoWorld::MARKER . strtoupper(substr(md5($key), 0, 6));

            // A third of customers arrive through someone else's referral link.
            $friendsCode = null;
            if ($pool && DemoWorld::chance($key . '|ref', 33)) {
                $friendsCode = $pool[DemoWorld::seedOf($key . '|refwho') % count($pool)];
                $referred++;
            }

            // 6 in 100 are blocked/inactive so the customer list filters have data.
            $status = DemoWorld::chance($key . '|status', 94) ? 1 : 0;
            $balance = DemoWorld::chance($key . '|haswallet', 45)
                ? (float) DemoWorld::intFor($key . '|wallet', 20, 2500)
                : 0.0;

            $joinedAt = now()->subDays(DemoWorld::intFor($key . '|age', 1, 420))
                ->setTime(DemoWorld::intFor($key . '|h', 7, 22), DemoWorld::intFor($key . '|mi', 0, 59));

            DB::transaction(function () use (
                $n, $key, $person, $mobile, $email, $referralCode, $friendsCode,
                $status, $balance, $joinedAt, $cityId, $cityName, $city,
                &$created, &$addresses
            ) {
                $row = [
                    'name'          => $person,
                    'email'         => $email,
                    'password'      => bcrypt(DemoWorld::PASSWORD),
                    'country_code'  => '91',
                    'mobile'        => $mobile,
                    'balance'       => $balance,
                    'referral_code' => $referralCode,
                    'friends_code'  => $friendsCode,
                    'status'        => $status,
                    'created_at'    => $joinedAt,
                    'updated_at'    => $joinedAt,
                ];
                foreach ([
                    // `type` is an enum('email','google','apple','phone'); real
                    // signups are all 'phone' (mobile OTP), so match that.
                    'type'                => 'phone',
                    'is_verified'         => 1,
                    'is_children_allowed' => DemoWorld::chance($key . '|kids', 25) ? 1 : 0,
                ] as $col => $val) {
                    if (Schema::hasColumn('users', $col)) {
                        $row[$col] = $val;
                    }
                }

                $userId = DB::table('users')->insertGetId($row);

                // ── addresses ─────────────────────────────────────────────
                $count = DemoWorld::intFor($key . '|naddr', 1, 3);
                for ($a = 0; $a < $count; $a++) {
                    $akey = "$key|addr|$a";
                    [$lat, $lng] = DemoWorld::pointNear($cityName, $akey);
                    $locality = DemoWorld::pick($akey . '|loc', $city['localities']);

                    $addr = [
                        'user_id'          => $userId,
                        'type'             => self::ADDRESS_TYPES[$a] ?? 'Other',
                        'name'             => $person,
                        'mobile'           => $mobile,
                        'alternate_mobile' => DemoWorld::chance($akey . '|alt', 30)
                            ? (string) (DemoWorld::MOBILE_CUSTOMER_BASE + DemoWorld::intFor($akey . '|alt2', 1, 150))
                            : null,
                        'address'          => sprintf(
                            'Flat %d%s, %s Residency, %s',
                            DemoWorld::intFor($akey . '|flat', 101, 906),
                            DemoWorld::pick($akey . '|blk', ['A', 'B', 'C', 'D']),
                            DemoWorld::pick($akey . '|apt', ['Sai', 'Lakshmi', 'Ananda', 'Vasavi', 'Silver Oak', 'Green Park']),
                            $locality
                        ),
                        'landmark'         => 'Near ' . DemoWorld::pick($akey . '|lm', [
                            'Reliance Fresh', 'Metro Station', 'HP Petrol Pump', 'Community Hall',
                            'Government School', 'Water Tank', 'Bus Stop', 'Temple',
                        ]),
                        'area'             => $locality,
                        'pincode'          => DemoWorld::pick($akey . '|pin', $city['pincodes']),
                        'city_id'          => $cityId,
                        'city'             => $cityName,
                        'state'            => $city['state'],
                        'country'          => 'India',
                        'latitude'         => (string) $lat,
                        'longitude'        => (string) $lng,
                        'is_default'       => $a === 0 ? 1 : 0,
                        'created_at'       => $joinedAt,
                        'updated_at'       => $joinedAt,
                    ];
                    if (Schema::hasColumn('user_addresses', 'building')) {
                        $addr['building'] = DemoWorld::pick($akey . '|apt', ['Sai', 'Lakshmi', 'Ananda', 'Vasavi', 'Silver Oak', 'Green Park']) . ' Residency';
                    }

                    DB::table('user_addresses')->insert($addr);
                    $addresses++;
                }

                // ── wallet history ───────────────────────────────────────
                if ($balance > 0) {
                    DB::table('wallet_transactions')->insert([
                        'user_id'    => $userId,
                        'type'       => 'credit',
                        'amount'     => $balance,
                        'message'    => DemoWorld::MARKER . ' opening wallet credit',
                        'status'     => 1,
                        'created_at' => $joinedAt,
                        'updated_at' => $joinedAt,
                    ]);
                }

                $created++;
            });

            $pool[] = $referralCode;
        }

        $this->command->info("Customers: {$created} created ({$referred} via referral), {$addresses} addresses, {$skipped} skipped.");
        $this->command->line('  login: mobile ' . (DemoWorld::MOBILE_CUSTOMER_BASE + 1)
            . '…' . (DemoWorld::MOBILE_CUSTOMER_BASE + DemoWorld::N_CUSTOMERS)
            . '  ·  password ' . DemoWorld::PASSWORD);
    }
}
