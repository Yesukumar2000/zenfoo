<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddPreorderSettingToSettingsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Insert preorder_enabled setting
        DB::table('settings')->insertOrIgnore([
            'variable' => 'preorder_enabled',
            'value' => '0'
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove preorder_enabled setting
        DB::table('settings')->where('variable', 'preorder_enabled')->delete();
    }
}
