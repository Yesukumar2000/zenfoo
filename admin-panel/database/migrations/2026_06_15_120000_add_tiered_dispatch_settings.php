<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Seed the admin-configurable settings for tiered (nearest-first) driver
     * dispatch. Orders are offered to the nearest ring of drivers first and the
     * search radius expands one "tier step" at a time, up to "max radius", with
     * "offer timeout" seconds per ring before widening.
     */
    private array $defaults = [
        'dispatch_max_radius_km'   => '5',   // outer search limit (km)
        'dispatch_tier_step_km'    => '1',   // ring increment (km): 1 km, 2 km, 3 km, ...
        'dispatch_offer_timeout_sec' => '25', // wait per ring before expanding (seconds)
    ];

    public function up(): void
    {
        foreach ($this->defaults as $variable => $value) {
            $exists = DB::table('settings')
                ->where('variable', $variable)
                ->exists();

            if (!$exists) {
                DB::table('settings')->insert([
                    'variable' => $variable,
                    'value' => $value,
                ]);
            }
        }
    }

    public function down(): void
    {
        DB::table('settings')
            ->whereIn('variable', array_keys($this->defaults))
            ->delete();
    }
};
