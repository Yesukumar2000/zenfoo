<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Deposit-method toggles + Zenfoo QR image for the driver "Deposit Cash" flow.
     * Admin can turn each method on/off; at least one is always kept enabled.
     */
    private array $defaults = [
        'deposit_method_bank' => '1', // Bank Deposit (CDM/ATM)
        'deposit_method_upi'  => '1', // UPI Transfer
        'deposit_method_qr'   => '0', // Zenfoo QR (pay to Zenfoo QR)
        'admin_qr_image'      => '',  // Uploaded Zenfoo payment QR image URL
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
