<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddAdminPaymentSettings extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $settings = [
            ['variable' => 'admin_upi_id', 'value' => ''],
            ['variable' => 'admin_bank_name', 'value' => ''],
            ['variable' => 'admin_bank_account_number', 'value' => ''],
            ['variable' => 'admin_bank_ifsc_code', 'value' => ''],
            ['variable' => 'admin_bank_account_holder_name', 'value' => ''],
        ];

        foreach ($settings as $setting) {
            DB::table('settings')->insertOrIgnore($setting);
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::table('settings')->whereIn('variable', [
            'admin_upi_id',
            'admin_bank_name',
            'admin_bank_account_number',
            'admin_bank_ifsc_code',
            'admin_bank_account_holder_name',
        ])->delete();
    }
}
