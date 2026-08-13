<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddDimensionsToAppLaunchBannerSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Insert app_launch_banner_img_height setting if it doesn't exist
        $existsHeight = DB::table('settings')->where('variable', 'app_launch_banner_img_height')->first();
        if (!$existsHeight) {
            DB::table('settings')->insert([
                'variable' => 'app_launch_banner_img_height',
                'value' => '0',
            ]);
        }

        // Insert app_launch_banner_img_width setting if it doesn't exist
        $existsWidth = DB::table('settings')->where('variable', 'app_launch_banner_img_width')->first();
        if (!$existsWidth) {
            DB::table('settings')->insert([
                'variable' => 'app_launch_banner_img_width',
                'value' => '0',
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
        DB::table('settings')->where('variable', 'app_launch_banner_img_height')->delete();
        DB::table('settings')->where('variable', 'app_launch_banner_img_width')->delete();
    }
}