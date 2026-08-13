<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $settings = [
            [
                'variable' => 'not_getting_orders_video',
                'value' => ''
            ],
            [
                'variable' => 'not_getting_orders_title',
                'value' => "If you're not getting orders, you should follow these steps"
            ],
            [
                'variable' => 'not_getting_orders_steps',
                'value' => json_encode([
                    [
                        'step_number' => 1,
                        'title' => "Make sure you're in the right zone"
                    ],
                    [
                        'step_number' => 2,
                        'title' => 'Start your duty and stay online'
                    ],
                    [
                        'step_number' => 3,
                        'title' => 'Move closer to high-demand food stores and zenfoo stores'
                    ]
                ])
            ]
        ];

        foreach ($settings as $setting) {
            // Only insert if not exists
            $exists = DB::table('settings')->where('variable', $setting['variable'])->exists();
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
        DB::table('settings')->whereIn('variable', [
            'not_getting_orders_video',
            'not_getting_orders_title',
            'not_getting_orders_steps'
        ])->delete();
    }
};
