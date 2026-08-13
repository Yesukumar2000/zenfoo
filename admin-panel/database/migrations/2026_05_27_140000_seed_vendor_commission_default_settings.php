<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class SeedVendorCommissionDefaultSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * Mirrors the vendor_gst_* seed: ensures the four vendor commission
     * variables exist in the settings table so the admin's "Vendor
     * Commission Configurations" card has values to display on first
     * load. Existing rows are not touched.
     *
     * @return void
     */
    public function up()
    {
        $defaults = [
            'vendor_commission_vegetables_fruits' => '5',
            'vendor_commission_chicken_meat'      => '10',
            'vendor_commission_food'              => '15',
            'vendor_commission_super_mart'        => '8',
        ];

        foreach ($defaults as $variable => $value) {
            DB::table('settings')->updateOrInsert(
                ['variable' => $variable],
                ['value' => $value]
            );
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::table('settings')->whereIn('variable', [
            'vendor_commission_vegetables_fruits',
            'vendor_commission_chicken_meat',
            'vendor_commission_food',
            'vendor_commission_super_mart',
        ])->delete();
    }
}
