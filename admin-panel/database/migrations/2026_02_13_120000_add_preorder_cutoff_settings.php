<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddPreorderCutoffSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Insert preorder_cutoff_day setting (default: 5 = Friday)
        DB::table('settings')->insertOrIgnore([
            'variable' => 'preorder_cutoff_day',
            'value' => '5'
        ]);

        // Insert preorder_cutoff_time setting (default: 06:30 = 6:30 AM)
        DB::table('settings')->insertOrIgnore([
            'variable' => 'preorder_cutoff_time',
            'value' => '06:30'
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove preorder cutoff settings
        DB::table('settings')->where('variable', 'preorder_cutoff_day')->delete();
        DB::table('settings')->where('variable', 'preorder_cutoff_time')->delete();
    }
}