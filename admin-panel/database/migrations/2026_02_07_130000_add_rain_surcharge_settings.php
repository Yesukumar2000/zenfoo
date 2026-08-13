<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $rainSettings = [
            ['variable' => 'rain_surcharge_enabled', 'value' => '1'],
            ['variable' => 'rain_surcharge_type', 'value' => 'fixed'], // 'fixed' or 'percentage'
            ['variable' => 'rain_surcharge_amount', 'value' => '20'], // Fixed amount in currency OR percentage value
            ['variable' => 'rain_surcharge_label', 'value' => 'Rain Surcharge'],
        ];

        foreach ($rainSettings as $setting) {
            $exists = DB::table('settings')
                ->where('variable', $setting['variable'])
                ->exists();

            if (!$exists) {
                DB::table('settings')->insert($setting);
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('settings')
            ->whereIn('variable', [
                'rain_surcharge_enabled',
                'rain_surcharge_type',
                'rain_surcharge_amount',
                'rain_surcharge_label',
            ])
            ->delete();
    }
};
