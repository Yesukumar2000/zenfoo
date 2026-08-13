<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Per-app support contact overrides for the customer, seller and driver
     * apps. Seeded blank on purpose: a blank override falls back to the global
     * support_number/support_email, so behaviour is unchanged until an admin
     * fills one in under Settings -> Store -> Per-App Contacts.
     */
    private array $defaults = [
        'support_number_customer' => '',
        'support_email_customer'  => '',
        'support_number_seller'   => '',
        'support_email_seller'    => '',
        'support_number_driver'   => '',
        'support_email_driver'    => '',
    ];

    public function up(): void
    {
        foreach ($this->defaults as $variable => $value) {
            $exists = DB::table('settings')->where('variable', $variable)->exists();
            if (!$exists) {
                DB::table('settings')->insert([
                    'variable' => $variable,
                    'value' => $value,
                ]);
            }
        }
    }

    public function down(): void
    {
        DB::table('settings')
            ->whereIn('variable', array_keys($this->defaults))
            ->delete();
    }
};
