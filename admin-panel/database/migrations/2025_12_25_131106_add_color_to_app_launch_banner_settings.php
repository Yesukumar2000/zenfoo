<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddColorToAppLaunchBannerSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Insert app_launch_banner_color setting if it doesn't exist
        $exists = DB::table('settings')->where('variable', 'app_launch_banner_color')->first();
        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'app_launch_banner_color',
                'value' => '#FFFFFF',
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
        DB::table('settings')->where('variable', 'app_launch_banner_color')->delete();
    }
}