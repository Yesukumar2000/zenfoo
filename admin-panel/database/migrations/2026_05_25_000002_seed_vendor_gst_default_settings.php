<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class SeedVendorGstDefaultSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $defaults = [
            'vendor_gst_vegetables_fruits' => '2',
            'vendor_gst_chicken_meat'      => '5',
            'vendor_gst_food'              => '5',
            'vendor_gst_super_mart'        => '5',
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
            'vendor_gst_vegetables_fruits',
            'vendor_gst_chicken_meat',
            'vendor_gst_food',
            'vendor_gst_super_mart',
        ])->delete();
    }
}
