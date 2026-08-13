<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class SeedVendorWaitChargeSettings extends Migration
{
    public function up()
    {
        $defaults = [
            'vendor_wait_grace_minutes'     => '5',
            'vendor_wait_charge_per_minute' => '2',
            'vendor_wait_charge_cap'        => '50',
        ];

        foreach ($defaults as $variable => $value) {
            DB::table('settings')->updateOrInsert(
                ['variable' => $variable],
                ['value' => $value]
            );
        }
    }

    public function down()
    {
        DB::table('settings')->whereIn('variable', [
            'vendor_wait_grace_minutes',
            'vendor_wait_charge_per_minute',
            'vendor_wait_charge_cap',
        ])->delete();
    }
}
