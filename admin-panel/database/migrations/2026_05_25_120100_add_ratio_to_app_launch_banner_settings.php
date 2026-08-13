<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddRatioToAppLaunchBannerSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $exists = DB::table('settings')->where('variable', 'app_launch_banner_ratio')->first();
        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'app_launch_banner_ratio',
                'value' => '9:16',
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
        DB::table('settings')->where('variable', 'app_launch_banner_ratio')->delete();
    }
}
