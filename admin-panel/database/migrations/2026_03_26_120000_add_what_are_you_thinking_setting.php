<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class AddWhatAreYouThinkingSetting extends Migration
{
    public function up()
    {
        $exists = DB::table('settings')
            ->where('variable', 'what_are_you_thinking')
            ->exists();

        if (!$exists) {
            DB::table('settings')->insert([
                'variable' => 'what_are_you_thinking',
                'value' => "what's your taste today?"
            ]);
        }
    }

    public function down()
    {
        DB::table('settings')
            ->where('variable', 'what_are_you_thinking')
            ->delete();
    }
}
