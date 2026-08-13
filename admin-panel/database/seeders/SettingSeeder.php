<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        Setting::truncate();

        $settings = [
            [
                'variable' => 'app_name',
                'value' => 'eGrocer',
            ],
            [
                'variable' => 'support_number',
                'value' => '',
            ],
            [
                'variable' => 'support_email',
                'value' => 'support@gmail.com',
            ],
            // Per-app overrides. Blank means "use the global pair above".
            [
                'variable' => 'support_number_customer',
                'value' => '',
            ],
            [
                'variable' => 'support_email_customer',
                'value' => '',
            ],
            [
                'variable' => 'support_number_seller',
                'value' => '',
            ],
            [
                'variable' => 'support_email_seller',
                'value' => '',
            ],
            [
                'variable' => 'support_number_driver',
                'value' => '',
            ],
            [
                'variable' => 'support_email_driver',
                'value' => '',
            ],
            [
                'variable' => 'logo',
                'value' => '',
            ],
            [
                'variable' => 'purchase_code',
                'value' => '',
            ],
            [
                'variable' => 'stripe_secret_key',
                'value' => '',
            ],
            [
                'variable' => 'stripe_publishable_key',
                'value' => '',
            ],
            [
                'variable' => 'stripe_webhook_secret_key',
                'value' => '',
            ],
            [
                'variable' => 'currency',
                'value' => '₹',
            ],
            [
                'variable' => 'currency_code',
                'value' => 'INR',
            ],
            [
                'variable' => 'decimal_point',
                'value' => '2',
            ],
            [
                'variable' => 'cod_payment_method',
                'value' => '1',
            ],
            [
                'variable' => 'cod_mode',
                'value' => 'global',
            ],
        ];

        foreach ($settings as $setting){
            Setting::create($setting);
        }
    }
}
