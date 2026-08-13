<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class UpdateExistingOffersSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $this->command->info('Updating existing incentive offers with gig requirements...');

        // Get all existing offers that don't have gig requirements set
        $offers = DB::table('incentive_offers')
            ->where(function($query) {
                $query->whereNull('min_gigs_required')
                      ->orWhere('min_gigs_required', 0);
            })
            ->get();

        if ($offers->isEmpty()) {
            $this->command->info('No offers found to update or all offers already have requirements set.');
            return;
        }

        $updated = 0;
        foreach ($offers as $offer) {
            // Set reasonable default requirements based on offer duration
            $startDate = \Carbon\Carbon::parse($offer->start_date);
            $endDate = \Carbon\Carbon::parse($offer->end_date);
            $durationDays = $endDate->diffInDays($startDate);

            // Calculate minimum gigs based on duration
            // For weekly offers: 20 gigs
            // For monthly offers: 80 gigs
            // For daily/short offers: 5 gigs
            if ($durationDays <= 7) {
                $minGigs = 5;
                $maxSkip = 1;
                $maxCancel = 1;
            } elseif ($durationDays <= 30) {
                $minGigs = 20;
                $maxSkip = 3;
                $maxCancel = 2;
            } else {
                $minGigs = 80;
                $maxSkip = 10;
                $maxCancel = 5;
            }

            DB::table('incentive_offers')
                ->where('id', $offer->id)
                ->update([
                    'min_gigs_required' => $minGigs,
                    'max_gigs_skip' => $maxSkip,
                    'max_orders_cancel' => $maxCancel,
                    'login_mandatory' => true,
                    'updated_at' => now()
                ]);

            $updated++;
            $this->command->info("Updated offer: {$offer->name} (Duration: {$durationDays} days, Min Gigs: {$minGigs})");
        }

        $this->command->info("Successfully updated {$updated} incentive offer(s)!");
        $this->command->newLine();
        $this->command->info('Summary of requirements:');
        $this->command->info('- Daily/Short offers (≤7 days): 5 gigs min, 1 max skip, 1 max cancel');
        $this->command->info('- Weekly offers (8-30 days): 20 gigs min, 3 max skip, 2 max cancel');
        $this->command->info('- Monthly offers (>30 days): 80 gigs min, 10 max skip, 5 max cancel');
    }
}
