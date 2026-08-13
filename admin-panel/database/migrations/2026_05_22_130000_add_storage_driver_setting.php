<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class AddStorageDriverSetting extends Migration
{
    public function up()
    {
        $exists = DB::table('settings')
            ->where('variable', 'storage_driver')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'storage_driver',
                'value' => 's3'
            ]);
        }
    }

    public function down()
    {
        DB::table('settings')
            ->where('variable', 'storage_driver')
            ->delete();
    }
}
