<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Add Paytm Test/Staging credentials
        DB::table('settings')->insert([
            'variable' => 'paytm_test_merchant_id',
            'value' => ''
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_test_merchant_key',
            'value' => ''
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_test_website',
            'value' => 'WEBSTAGING'
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_test_industry_type',
            'value' => 'Retail'
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_test_channel_id',
            'value' => 'WEB'
        ]);

        // Add Paytm Live/Production credentials
        DB::table('settings')->insert([
            'variable' => 'paytm_live_merchant_id',
            'value' => ''
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_live_merchant_key',
            'value' => ''
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_live_website',
            'value' => 'DEFAULT'
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_live_industry_type',
            'value' => 'Retail'
        ]);

        DB::table('settings')->insert([
            'variable' => 'paytm_live_channel_id',
            'value' => 'WEB'
        ]);

        // Add Paytm environment setting (test or live)
        DB::table('settings')->insert([
            'variable' => 'paytm_environment',
            'value' => 'test'
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::table('settings')->whereIn('variable', [
            'paytm_test_merchant_id',
            'paytm_test_merchant_key',
            'paytm_test_website',
            'paytm_test_industry_type',
            'paytm_test_channel_id',
            'paytm_live_merchant_id',
            'paytm_live_merchant_key',
            'paytm_live_website',
            'paytm_live_industry_type',
            'paytm_live_channel_id',
            'paytm_environment'
        ])->delete();
    }
};
