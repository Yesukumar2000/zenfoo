<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Gig;
use App\Models\GigSlot;
use App\Models\IncentiveOffer;
use Carbon\Carbon;

class AddSlotsToExistingOffersSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $this->command->info('Adding gig slots for existing incentive offer periods...');

        // Get all active offers
        $offers = IncentiveOffer::where('status', 1)->get();

        if ($offers->isEmpty()) {
            $this->command->warn('No active incentive offers found.');
            return;
        }

        // Get all gigs
        $gigs = Gig::all();

        if ($gigs->isEmpty()) {
            $this->command->error('No gigs found! Please create gigs first.');
            return;
        }

        $totalSlotsCreated = 0;
        $totalSlotsSkipped = 0;

        foreach ($offers as $offer) {
            $this->command->newLine();
            $this->command->info("Processing offer: {$offer->name}");
            $this->command->info("  Period: {$offer->start_date->format('Y-m-d')} to {$offer->end_date->format('Y-m-d')}");

            $startDate = $offer->start_date->copy();
            $endDate = $offer->end_date->copy();

            // Make sure we don't create slots for dates that have already passed
            if ($startDate->lt(Carbon::today())) {
                $startDate = Carbon::today();
            }

            $daysToCreate = $startDate->diffInDays($endDate) + 1;

            $this->command->info("  Creating slots for {$daysToCreate} days...");

            $offerSlotsCreated = 0;
            $offerSlotsSkipped = 0;

            for ($day = 0; $day < $daysToCreate; $day++) {
                $currentDate = $startDate->copy()->addDays($day);

                foreach ($gigs as $gig) {
                    // Generate time-based slots for this gig
                    $timeSlots = $this->generateTimeSlots($gig->start_time, $gig->end_time);

                    foreach ($timeSlots as $slotNum => $timeSlot) {
                        // Check if slot already exists
                        $existingSlot = GigSlot::where('gig_id', $gig->id)
                            ->where('slot_date', $currentDate->toDateString())
                            ->where('slot_number', $slotNum + 1)
                            ->first();

                        if ($existingSlot) {
                            $offerSlotsSkipped++;
                            continue;
                        }

                        GigSlot::create([
                            'gig_id' => $gig->id,
                            'slot_number' => $slotNum + 1,
                            'slot_name' => $timeSlot['name'],
                            'slot_date' => $currentDate->toDateString(),
                            'start_time' => $timeSlot['start_time'],
                            'end_time' => $timeSlot['end_time'],
                            'max_bookings' => 50,
                            'current_bookings' => 0,
                            'status' => 1
                        ]);

                        $offerSlotsCreated++;
                    }
                }
            }

            $totalSlotsCreated += $offerSlotsCreated;
            $totalSlotsSkipped += $offerSlotsSkipped;

            $this->command->info("  ✓ Created {$offerSlotsCreated} slots, skipped {$offerSlotsSkipped} existing slots");
        }

        $this->command->newLine();
        $this->command->info("========================================");
        $this->command->info("Summary:");
        $this->command->info("- Processed {$offers->count()} incentive offer(s)");
        $this->command->info("- Created {$totalSlotsCreated} new gig slots");
        $this->command->info("- Skipped {$totalSlotsSkipped} existing slots");
        $this->command->info("========================================");
    }

    /**
     * Generate time-based slots for a gig (2-hour intervals)
     */
    private function generateTimeSlots($startTime, $endTime)
    {
        $slots = [];
        $start = Carbon::createFromFormat('H:i:s', $startTime);
        $end = Carbon::createFromFormat('H:i:s', $endTime);

        // Handle overnight shifts (e.g., 22:00 - 02:00)
        if ($end->lessThan($start)) {
            $end->addDay();
        }

        $slotDuration = 2; // 2 hours per slot
        $current = $start->copy();

        while ($current->lessThan($end)) {
            $slotEnd = $current->copy()->addHours($slotDuration);

            // If slot end exceeds gig end, use gig end time
            if ($slotEnd->greaterThan($end)) {
                $slotEnd = $end->copy();
            }

            $slots[] = [
                'start_time' => $current->format('H:i:s'),
                'end_time' => $slotEnd->format('H:i:s'),
                'name' => $current->format('h:i A') . ' - ' . $slotEnd->format('h:i A')
            ];

            $current->addHours($slotDuration);
        }

        return $slots;
    }
}
