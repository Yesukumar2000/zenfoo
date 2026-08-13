<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class InsertOfferClaimableBannerSetting extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Insert the offer_claimable_banner setting
        DB::table('settings')->insert([
            'variable' => 'offer_claimable_banner',
            'value' => '',
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove the setting
        DB::table('settings')->where('variable', 'offer_claimable_banner')->delete();
    }
}
