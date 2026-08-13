<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddMerchantUpiSettingsToSettingsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * Add merchant UPI/VPA settings for QR code generation
     * This allows delivery boys to show UPI QR codes to customers for payment
     *
     * @return void
     */
    public function up()
    {
        // Insert new settings for merchant UPI/VPA
        $settings = [
            [
                'variable' => 'merchant_upi_id',
                'value' => '' // Admin will configure this, e.g., 'zenfoo@paytm' or 'merchant123@paytm'
            ],
            [
                'variable' => 'business_name',
                'value' => 'Zenfoo' // Default business name shown on QR code
            ],
        ];

        foreach ($settings as $setting) {
            // Check if setting already exists
            $exists = DB::table('settings')
                ->where('variable', $setting['variable'])
                ->exists();

            if (!$exists) {
                DB::table('settings')->insert($setting);
            }
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove the merchant UPI settings
        DB::table('settings')
            ->whereIn('variable', ['merchant_upi_id', 'business_name'])
            ->delete();
    }
}
