<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddOrientationToAppLaunchBannerSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $exists = DB::table('settings')->where('variable', 'app_launch_banner_orientation')->first();
        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'app_launch_banner_orientation',
                'value' => 'portrait',
            ]);
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::table('settings')->where('variable', 'app_launch_banner_orientation')->delete();
    }
}
