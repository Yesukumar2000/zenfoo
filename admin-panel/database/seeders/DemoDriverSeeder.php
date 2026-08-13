<?php

namespace Database\Seeders;

use App\Models\Role;
use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Demo delivery partners for Hyderabad and Kurnool.
 *
 * Creates, in the same shape the driver app's signup produces:
 *   vehicles              (Bike / Scooter / EV / Bicycle / Three Wheeler)
 *   store_locations       (the dark stores drivers are attached to)
 *   admins + delivery_boys with a KYC document set
 *   delivery_boy_store_location assignments
 *
 * The status mix deliberately includes registered-but-unapproved, rejected and
 * deactivated drivers so the Driver Management filters aren't all one colour.
 * A few are flagged problematic so that list isn't empty either.
 *
 * Drivers are given fresh lat/lng and `is_available`, but NOT an online
 * session — sessions are what the dispatch funnel reads, and inventing stale
 * ones is exactly the phantom-online problem. Bring drivers online from the
 * app when you want to demo dispatch.
 *
 * Identified by email @demo.zenfoo.test.
 */
class DemoDriverSeeder extends Seeder
{
    public function run(): void
    {
        $docBase = rtrim(config('app.url'), '/') . '/' . DemoWorld::DOC_DIR;

        $cities = [
            'Hyderabad' => DemoWorld::ensureCity('Hyderabad'),
            'Kurnool'   => DemoWorld::ensureCity('Kurnool'),
        ];

        $vehicleIds = $this->ensureVehicles();
        $storeLocationIds = $this->ensureStoreLocations($cities);

        $created = 0;
        $skipped = 0;

        for ($n = 1; $n <= DemoWorld::N_DRIVERS; $n++) {
            $key = "driver|$n";

            $cityName = $n % 4 === 0 ? 'Kurnool' : 'Hyderabad';
            $cityId   = $cities[$cityName];
            $city     = DemoWorld::CITIES[$cityName];

            $person = DemoWorld::fullName($key);
            $email  = DemoWorld::email($person, 1000 + $n);
            $mobile = (string) (DemoWorld::MOBILE_DRIVER_BASE + $n);

            if (DB::table('delivery_boys')->where('mobile', $mobile)->exists()
                || DB::table('admins')->where('email', $email)->exists()) {
                $skipped++;
                continue;
            }

            [$lat, $lng] = DemoWorld::pointNear($cityName, $key);
            $locality = DemoWorld::pick($key . '|loc', $city['localities']);
            $bank = DemoWorld::pick($key . '|bank', DemoWorld::BANKS);
            $account = DemoWorld::accountNumber($key);
            $ifsc = DemoWorld::ifsc($bank[1], $key);

            // 19 active, 3 awaiting approval, 1 rejected, 2 deactivated.
            $status = match (true) {
                $n >= 20 && $n <= 22 => 0,  // Registered
                $n === 23            => 2,  // Rejected
                $n >= 24             => 3,  // Deactivated
                default              => 1,  // Active
            };

            DB::transaction(function () use (
                $n, $key, $person, $email, $mobile, $status, $cityId, $cityName, $city,
                $lat, $lng, $locality, $bank, $account, $ifsc, $docBase,
                $vehicleIds, $storeLocationIds, &$created
            ) {
                $adminId = DB::table('admins')->insertGetId([
                    'username'   => $person,
                    'email'      => $email,
                    'mobile'     => $mobile, // varchar(10); driver app logs in by mobile
                    'password'   => bcrypt(DemoWorld::PASSWORD),
                    'role_id'    => Role::$roleDeliveryBoy,
                    'created_by' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $roleRow = DB::table('roles')->where('name', Role::$roleNameDeliveryBoy)->first();
                if ($roleRow) {
                    DB::table('model_has_roles')->insertOrIgnore([
                        'role_id'    => $roleRow->id,
                        'model_type' => 'App\\Models\\Admin',
                        'model_id'   => $adminId,
                    ]);
                }

                $row = [
                    'admin_id'                => $adminId,
                    'city_id'                 => $cityId,
                    'name'                    => $person,
                    'mobile'                  => $mobile,
                    'address'                 => sprintf('H.No %d-%d, %s, %s, %s',
                        DemoWorld::intFor($key . '|h1', 1, 40),
                        DemoWorld::intFor($key . '|h2', 1, 300),
                        $locality, $cityName, $city['state']),
                    // No plain `bonus` column on this table — the bonus scheme is
                    // bonus_type + the three amount/percentage columns.
                    'bonus_type'              => DemoWorld::chance($key . '|btype', 30) ? 1 : 0,
                    'bonus_percentage'        => DemoWorld::chance($key . '|btype', 30)
                                                    ? (float) DemoWorld::pick($key . '|bpct', [2, 3, 5]) : 0,
                    'bonus_min_amount'        => 0,
                    'bonus_max_amount'        => DemoWorld::chance($key . '|btype', 30) ? 50 : 0,
                    'balance'                 => (float) DemoWorld::intFor($key . '|bal', 0, 6500),
                    'driving_license'         => "{$docBase}/driver-{$n}-licence.png",
                    'national_identity_card'  => "{$docBase}/driver-{$n}-aadhaar.png",
                    'dob'                     => now()->subYears(DemoWorld::intFor($key . '|yr', 21, 45))
                                                    ->subDays(DemoWorld::intFor($key . '|dd', 0, 364))->toDateString(),
                    'bank_account_number'     => $account,
                    'bank_name'               => $bank[0],
                    'account_name'            => $person,
                    'ifsc_code'               => $ifsc,
                    'status'                  => $status,
                    'is_available'            => $status === 1 ? 1 : 0,
                    'cash_received'           => (float) DemoWorld::intFor($key . '|cash', 0, 4200),
                    'created_at'              => now()->subDays(DemoWorld::intFor($key . '|age', 10, 300)),
                    'updated_at'              => now(),
                ];

                $optional = [
                    'email'          => $email,
                    'profile_image'  => "{$docBase}/driver-{$n}-photo.png",
                    'latitude'       => $lat,
                    'longitude'      => $lng,
                    'vehicle_id'     => $vehicleIds ? $vehicleIds[DemoWorld::seedOf($key . '|veh') % count($vehicleIds)] : null,
                    // 0 = Both. Never 1 here: orders_priority = 1 makes a driver
                    // invisible to seller orders, which silently breaks dispatch demos.
                    'orders_priority'    => DemoWorld::chance($key . '|prio', 20) ? 2 : 0,
                    'referral_code'      => DemoWorld::MARKER . 'D' . strtoupper(substr(md5($key), 0, 5)),
                    'hand_cash_limit'    => 3000,
                    'remark'             => $status === 2 ? DemoWorld::MARKER . ': licence expired' : DemoWorld::MARKER . ' demo driver',
                    'rejection_remark'   => $status === 2 ? 'Licence expired — re-apply with a valid document' : null,
                    'is_problematic'     => in_array($n, [7, 13], true) ? 1 : 0,
                ];
                foreach ($optional as $col => $val) {
                    if (Schema::hasColumn('delivery_boys', $col)) {
                        $row[$col] = $val;
                    }
                }

                $driverId = DB::table('delivery_boys')->insertGetId($row);

                // ── documents ────────────────────────────────────────────
                if (Schema::hasTable('delivery_boy_documents')) {
                    $verified = $status === 1 ? 'verified' : ($status === 2 ? 'rejected' : 'pending_verification');
                    DB::table('delivery_boy_documents')->insert([
                        'delivery_boy_id'            => $driverId,
                        'driving_license_number'     => DemoWorld::drivingLicence($key, $city['state']),
                        'driving_license_front_path' => "{$docBase}/driver-{$n}-licence.png",
                        'driving_license_back_path'  => "{$docBase}/driver-{$n}-licence.png",
                        'driving_license_status'     => $verified,
                        'rc_number'                  => DemoWorld::vehicleNumber($key, $city['state']),
                        'rc_front_path'              => "{$docBase}/driver-{$n}-licence.png",
                        'rc_status'                  => $verified,
                        // Column is char(12); store digits only, still a masked sample range.
                        'aadhar_number'              => '0000' . str_pad((string) DemoWorld::intFor($key . '|aad12', 1, 99999999), 8, '0', STR_PAD_LEFT),
                        'aadhar_front_path'          => "{$docBase}/driver-{$n}-aadhaar.png",
                        'aadhar_status'              => $verified,
                        'pan_number'                 => DemoWorld::pan($key),
                        'pan_status'                 => $status === 1 ? 'verified' : 'not_uploaded',
                        'bank_name'                  => $bank[0],
                        'account_holder_name'        => $person,
                        'account_number'             => $account,
                        'ifsc_code'                  => $ifsc,
                        'bank_details_status'        => $status === 1 ? 'verified' : 'pending_verification',
                        'created_at'                 => now(),
                        'updated_at'                 => now(),
                    ]);
                }

                // ── emergency contact ────────────────────────────────────
                if (Schema::hasTable('delivery_boy_emergency_contacts')) {
                    DB::table('delivery_boy_emergency_contacts')->insert([
                        'delivery_boy_id' => $driverId,
                        'name'            => DemoWorld::fullName($key . '|kin'),
                        'mobile_number'   => (string) (DemoWorld::MOBILE_DRIVER_BASE + 500 + $n),
                        'relation'        => DemoWorld::pick($key . '|rel', ['Father', 'Mother', 'Brother', 'Spouse', 'Friend']),
                        'created_at'      => now(),
                        'updated_at'      => now(),
                    ]);
                }

                // ── store attachment ─────────────────────────────────────
                $forCity = $storeLocationIds[$cityName] ?? [];
                if ($forCity && Schema::hasTable('delivery_boy_store_location')) {
                    $pickCount = min(count($forCity), DemoWorld::intFor($key . '|nsl', 1, 2));
                    for ($s = 0; $s < $pickCount; $s++) {
                        DB::table('delivery_boy_store_location')->insertOrIgnore([
                            'delivery_boy_id'   => $driverId,
                            'store_location_id' => $forCity[(DemoWorld::seedOf($key . "|sl$s") + $s) % count($forCity)],
                            'created_at'        => now(),
                            'updated_at'        => now(),
                        ]);
                    }
                }

                $created++;
            });
        }

        $this->command->info("Drivers: {$created} created, {$skipped} skipped.");
        $this->command->line('  login: mobile ' . (DemoWorld::MOBILE_DRIVER_BASE + 1)
            . '…' . (DemoWorld::MOBILE_DRIVER_BASE + DemoWorld::N_DRIVERS)
            . '  ·  password ' . DemoWorld::PASSWORD);
        $this->command->line('  drivers are offline by design — bring them online from the app to demo dispatch.');
    }

    /**
     * Reuse whatever vehicles the admin panel already has — the live data has
     * real ones ("Bike [Two Wheeler]", "Ev-Electric Bike") and adding parallel
     * demo entries would just clutter the dropdown. Only seed if empty.
     *
     * @return array<int> vehicle ids
     */
    private function ensureVehicles(): array
    {
        if (!Schema::hasTable('vehicles')) {
            return [];
        }

        $existing = DB::table('vehicles')->whereNull('deleted_at')->where('status', 1)->pluck('id')->all();
        if ($existing) {
            return array_map('intval', $existing);
        }

        $ids = [];
        foreach (DemoWorld::VEHICLES as $name) {
            $ids[] = (int) DB::table('vehicles')->insertGetId([
                'name'       => $name,
                'status'     => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return $ids;
    }

    /**
     * The hubs drivers report to.
     *
     * Prefers the real store_locations already configured for each city — the
     * live data has operational Zenfoo hubs in both Hyderabad and Kurnool, and
     * attaching demo drivers to those is more useful than inventing parallel
     * ones. Only creates a hub for a city that has none.
     *
     * @param array<string,int> $cities city name => city id
     * @return array<string,array<int>> city name => store_location ids
     */
    private function ensureStoreLocations(array $cities): array
    {
        if (!Schema::hasTable('store_locations')) {
            return [];
        }

        $out = [];

        foreach ($cities as $cityName => $cityId) {
            $existing = DB::table('store_locations')
                ->where('city_id', $cityId)
                ->where('status', 1)
                ->pluck('id')->all();

            if ($existing) {
                $out[$cityName] = array_map('intval', $existing);
                $this->command->line("  {$cityName}: reusing " . count($existing) . ' existing hub(s)');
                continue;
            }

            $city = DemoWorld::CITIES[$cityName];
            [$lat, $lng] = DemoWorld::pointNear($cityName, "hub|$cityName");
            $name = "Zenfoo Hub - {$cityName}";

            $out[$cityName] = [(int) DB::table('store_locations')->insertGetId([
                'name'       => $name,
                'address'    => "{$cityName}, {$city['state']}, India",
                'latitude'   => $lat,
                'longitude'  => $lng,
                'phone'      => (string) (DemoWorld::MOBILE_VENDOR_BASE + 900),
                'email'      => 'hub.' . strtolower($cityName) . '@' . DemoWorld::EMAIL_DOMAIN,
                'city_id'    => $cityId,
                'status'     => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ])];
        }

        return $out;
    }
}
