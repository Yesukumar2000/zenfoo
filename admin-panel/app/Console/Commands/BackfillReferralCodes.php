<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class BackfillReferralCodes extends Command
{
    protected $signature = 'referral:backfill-codes {--dry-run : List how many users would be updated without writing}';

    protected $description = 'Generate a unique referral_code for existing customers that do not have one yet';

    public function handle()
    {
        $dryRun = (bool) $this->option('dry-run');

        $missing = User::where(function ($q) {
            $q->whereNull('referral_code')->orWhere('referral_code', '');
        })->get(['id', 'referral_code']);

        $total = $missing->count();
        $this->info("Customers without a referral_code: {$total}");

        if ($total === 0 || $dryRun) {
            if ($dryRun) {
                $this->line('Dry run — no changes written.');
            }
            return self::SUCCESS;
        }

        // Seed the in-memory set with every code already in use so generated
        // codes stay unique across the whole table, not just this batch.
        $used = User::whereNotNull('referral_code')
            ->where('referral_code', '!=', '')
            ->pluck('referral_code')
            ->flip();

        $updated = 0;
        foreach ($missing as $user) {
            $code = $this->generateUniqueCode($used);
            $used->put($code, true);

            // Direct update so we don't depend on $fillable mass-assignment rules.
            DB::table('users')->where('id', $user->id)->update(['referral_code' => $code]);
            $updated++;
        }

        $this->info("Done. Generated referral codes for {$updated} customers.");

        return self::SUCCESS;
    }

    /**
     * Mirrors the 6-char uppercase code used in CustomerAuthController, with a
     * collision check against codes already handed out.
     */
    private function generateUniqueCode($used): string
    {
        do {
            $code = strtoupper(substr(sha1(microtime() . mt_rand()), 0, 6));
        } while ($used->has($code));

        return $code;
    }
}
