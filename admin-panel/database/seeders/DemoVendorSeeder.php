<?php

namespace Database\Seeders;

use App\Models\Role;
use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Demo vendors, spread across Hyderabad and Kurnool.
 *
 * Mirrors exactly what SellerRegistrationController writes on a real signup:
 *   admins row (role_id = Seller, bcrypt password)  ← the login identity
 *   sellers row linked by admin_id                  ← the vendor profile
 *   seller_bank_accounts row                        ← payout destination
 *
 * Every vendor lands on a store that matches its kind (supermart / vegetable /
 * meat / fish), gets a KYC document set from `zenfoo:demo-documents`, and is
 * left in a mix of statuses so the admin panel's Pending / Approved / Rejected
 * tabs all have something in them.
 *
 * Nothing pre-existing is modified. Identified by email @demo.zenfoo.test.
 */
class DemoVendorSeeder extends Seeder
{
    /**
     * Store kind → how to find a matching row in `stores`.
     *
     * Name keywords are tried first because the flags are too coarse: on the
     * live data Chicken & Meat, Mutton, Fish and Camel all carry is_meat=1, so
     * a flag-only match would drop a seafood vendor into the mutton store.
     */
    private const KIND_MATCH = [
        'supermart' => ['names' => ['super mart', 'grocery'], 'flag' => 'is_super_mart'],
        'vegetable' => ['names' => ['vegetable', 'fruit'],    'flag' => 'is_vegetable'],
        'meat'      => ['names' => ['chicken', 'meat', 'mutton'], 'flag' => 'is_meat'],
        'fish'      => ['names' => ['fish', 'sea'],           'flag' => 'is_meat'],
    ];

    public function run(): void
    {
        $docBase = rtrim(config('app.url'), '/') . '/' . DemoWorld::DOC_DIR;

        $hyderabad = DemoWorld::ensureCity('Hyderabad');
        $kurnool   = DemoWorld::ensureCity('Kurnool');

        $stores = DB::table('stores')->get();
        if ($stores->isEmpty()) {
            $this->command->error('No rows in `stores`. Create the storefronts first — vendors must attach to one.');
            return;
        }

        $created = 0;
        $skipped = 0;

        foreach (DemoWorld::VENDOR_TEMPLATES as $i => $tpl) {
            $n = $i + 1;
            $key = "vendor|$n";

            // Two thirds Hyderabad, one third Kurnool.
            $cityName = $n % 3 === 0 ? 'Kurnool' : 'Hyderabad';
            $cityId   = $cityName === 'Kurnool' ? $kurnool : $hyderabad;
            $city     = DemoWorld::CITIES[$cityName];

            $person = DemoWorld::fullName($key);
            $email  = DemoWorld::email($person, $n);

            if (DB::table('sellers')->where('email', $email)->exists()) {
                $skipped++;
                continue;
            }

            $storeId = $this->storeFor($stores, $tpl['kind'], $key);
            if (!$storeId) {
                $this->command->warn("  no store matches kind '{$tpl['kind']}' — {$tpl['name']} skipped");
                $skipped++;
                continue;
            }

            [$lat, $lng] = DemoWorld::pointNear($cityName, $key);
            $locality = DemoWorld::pick($key . '|loc', $city['localities']);
            $bank = DemoWorld::pick($key . '|bank', DemoWorld::BANKS);
            $account = DemoWorld::accountNumber($key);
            $ifsc = DemoWorld::ifsc($bank[1], $key);

            // Status mix: 8 approved, 2 awaiting review, 1 rejected, 1 deactivated.
            $status = match (true) {
                $n === 9  => 0, // Registered / pending review
                $n === 10 => 0,
                $n === 11 => 2, // Rejected
                $n === 12 => 3, // Deactivated
                default   => 1, // Active
            };

            DB::transaction(function () use (
                $n, $key, $tpl, $person, $email, $storeId, $cityId, $cityName,
                $city, $lat, $lng, $locality, $bank, $account, $ifsc, $status, $docBase, &$created
            ) {
                $adminId = DB::table('admins')->insertGetId([
                    'username'   => $person,
                    'email'      => $email,
                    // admins.mobile is varchar(10) — the seller app logs in by
                    // mobile OTP, so this has to be populated to be usable.
                    'mobile'     => (string) (DemoWorld::MOBILE_VENDOR_BASE + $n),
                    'password'   => bcrypt(DemoWorld::PASSWORD),
                    'role_id'    => Role::$roleSeller,
                    'created_by' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Spatie role, so panel permission checks behave normally.
                $roleRow = DB::table('roles')->where('name', Role::$roleNameSeller)->first();
                if ($roleRow) {
                    DB::table('model_has_roles')->insertOrIgnore([
                        'role_id'    => $roleRow->id,
                        'model_type' => 'App\\Models\\Admin',
                        'model_id'   => $adminId,
                    ]);
                }

                $row = [
                    'admin_id'          => $adminId,
                    'name'              => $person,
                    'store_name'        => $tpl['name'],
                    'slug'              => \Illuminate\Support\Str::slug($tpl['name']) . '-' . $n,
                    'email'             => $email,
                    'mobile'            => (string) (DemoWorld::MOBILE_VENDOR_BASE + $n),
                    'balance'           => DemoWorld::intFor($key . '|bal', 0, 45000),
                    'store_url'         => 'https://' . \Illuminate\Support\Str::slug($tpl['name']) . '.demo.zenfoo.test',
                    'logo'              => "{$docBase}/vendor-{$n}-store.png",
                    'store_description' => $this->description($tpl),
                    'street'            => DemoWorld::intFor($key . '|door', 1, 120) . '-' . DemoWorld::intFor($key . '|d2', 1, 99)
                                            . '/' . DemoWorld::intFor($key . '|d3', 1, 9) . ', ' . $locality,
                    'city_id'           => $cityId,
                    'state'             => $city['state'],
                    'categories'        => null,
                    'account_number'    => $account,
                    'bank_ifsc_code'    => $ifsc,
                    'account_name'      => $person,
                    'bank_name'         => $bank[0],
                    'commission'        => DemoWorld::pick($key . '|comm', [15, 18, 20, 22, 25]),
                    'status'            => $status,
                    'require_products_approval' => 0,
                    'national_identity_card' => "{$docBase}/vendor-{$n}-aadhaar.png",
                    'address_proof'     => "{$docBase}/vendor-{$n}-aadhaar.png",
                    'pan_number'        => DemoWorld::pan($key),
                    'tax_name'          => 'GST',
                    'tax_number'        => DemoWorld::gstin($key, $city['state']),
                    'latitude'          => (string) $lat,
                    'longitude'         => (string) $lng,
                    'place_name'        => $locality,
                    'formatted_address' => "{$locality}, {$cityName}, {$city['state']}",
                    'view_order_otp'    => 1,
                    'assign_delivery_boy' => 0,
                    'remark'            => $status === 2 ? DemoWorld::MARKER . ': documents unreadable, please re-upload'
                                                         : DemoWorld::MARKER . ' demo vendor',
                    'created_at'        => now()->subDays(DemoWorld::intFor($key . '|age', 20, 400)),
                    'updated_at'        => now(),
                ];

                // Columns added by later migrations — only set the ones this
                // database actually has, so the seeder survives a partial migrate.
                $optional = [
                    'store_id'         => $storeId,
                    'category_name'    => ucfirst($tpl['kind']),
                    'aadhar_number'    => DemoWorld::aadhaar($key),
                    'fssai_number'     => DemoWorld::fssai($key),
                    'fssai_lic_no'     => DemoWorld::fssai($key),
                    'store_location'   => "{$locality}, {$cityName}",
                    'store_city'       => $cityName,
                    'lat_long'         => "{$lat},{$lng}",
                    'pan_img'          => "{$docBase}/vendor-{$n}-pan.png",
                    'fssai_img'        => "{$docBase}/vendor-{$n}-fssai.png",
                    'store_images'     => json_encode(["{$docBase}/vendor-{$n}-store.png"]),
                    'shop_status'      => $status === 1 ? 1 : 0,
                    'aadhar_status'    => $status === 1 ? 1 : ($status === 2 ? 2 : 0),
                    'pan_status'       => $status === 1 ? 1 : ($status === 2 ? 2 : 0),
                    'fssai_status'     => $status === 1 ? 1 : 0,
                    'agreement_pdf'    => "{$docBase}/vendor-{$n}-gst.png",
                    'agreement_status' => $status === 1 ? 1 : 0,
                    // Real columns are two TIME fields, not a JSON blob.
                    'shop_opening_time' => DemoWorld::pick($key . '|open', ['06:00:00', '06:30:00', '07:00:00', '08:00:00']),
                    'shop_closing_time' => DemoWorld::pick($key . '|close', ['21:00:00', '22:00:00', '22:30:00', '23:00:00']),
                    'vendor_gst_percent'        => 18.00,
                    'vendor_commission_percent' => (float) DemoWorld::pick($key . '|comm', [15, 18, 20, 22, 25]),
                    'self_pickup_mode' => 0,
                ];
                foreach ($optional as $col => $val) {
                    if (Schema::hasColumn('sellers', $col)) {
                        $row[$col] = $val;
                    }
                }

                $sellerId = DB::table('sellers')->insertGetId($row);

                if (Schema::hasTable('seller_bank_accounts')) {
                    DB::table('seller_bank_accounts')->insert([
                        'seller_id'           => $sellerId,
                        'bank_name'           => $bank[0],
                        'account_number'      => $account,
                        'ifsc_code'           => $ifsc,
                        'account_holder_name' => $person,
                        'document'            => "{$docBase}/vendor-{$n}-cheque.png",
                        'document_type'       => 'cheque',
                        'is_default'          => true,
                        'is_verified'         => $status === 1,
                        'created_at'          => now(),
                        'updated_at'          => now(),
                    ]);
                }

                $created++;
            });
        }

        $this->command->info("Vendors: {$created} created, {$skipped} skipped.");
        $this->command->line('  login: <vendor email> / ' . DemoWorld::PASSWORD
            . '  ·  mobiles ' . (DemoWorld::MOBILE_VENDOR_BASE + 1) . '…');
    }

    /** Name keyword first, then the flag, then any active store. */
    private function storeFor($stores, string $kind, string $key): ?int
    {
        $rule = self::KIND_MATCH[$kind] ?? null;
        $active = $stores->filter(fn ($s) => !isset($s->is_active) || (int) $s->is_active === 1)->values();
        if ($active->isEmpty()) {
            $active = $stores;
        }

        if ($rule) {
            $byName = $active->filter(function ($s) use ($rule) {
                $name = strtolower((string) ($s->name ?? ''));
                foreach ($rule['names'] as $needle) {
                    if (str_contains($name, $needle)) {
                        return true;
                    }
                }
                return false;
            })->values();

            if ($byName->isNotEmpty()) {
                return (int) $byName[DemoWorld::seedOf($key . '|storeName') % $byName->count()]->id;
            }

            $flag = $rule['flag'];
            $byFlag = $active->filter(fn ($s) => isset($s->$flag) && (int) $s->$flag === 1)->values();
            if ($byFlag->isNotEmpty()) {
                return (int) $byFlag[DemoWorld::seedOf($key . '|storeFlag') % $byFlag->count()]->id;
            }
        }

        return $active->isNotEmpty() ? (int) $active[DemoWorld::seedOf($key . '|any') % $active->count()]->id : null;
    }

    private function description(array $tpl): string
    {
        return match ($tpl['kind']) {
            'supermart' => "{$tpl['name']} stocks everyday groceries — atta, rice, dals, oils, masalas, snacks, beverages and household essentials — picked and packed for 10-minute delivery.",
            'vegetable' => "{$tpl['name']} sources vegetables and fruits directly from local farms every morning. Nothing sits in cold storage overnight.",
            'meat'      => "{$tpl['name']} sells fresh, halal-cut chicken and mutton. Cut to order, cleaned, and delivered chilled within the hour.",
            'fish'      => "{$tpl['name']} brings in the day's catch from the coast. Fish and prawns are cleaned to your preference before packing.",
            default     => $tpl['name'],
        };
    }

}
