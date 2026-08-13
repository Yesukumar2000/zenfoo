<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Gig;
use App\Models\GigSlot;
use Carbon\Carbon;

class GigSlotsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Clear existing slots (disable foreign key checks temporarily)
        $this->command->info('Clearing existing gig slots...');
        \DB::statement('SET FOREIGN_KEY_CHECKS=0;');
        \DB::table('gig_slots')->truncate();
        \DB::statement('SET FOREIGN_KEY_CHECKS=1;');
        $this->command->info('Existing slots cleared!');

        // Get all gigs
        $gigs = Gig::all();

        if ($gigs->isEmpty()) {
            $this->command->error('No gigs found! Please create gigs first.');
            return;
        }

        // Number of days to create slots for (next 90 days)
        $daysToCreate = 90;

        $startDate = Carbon::today();
        $totalSlots = 0;

        // Count total slots to create for progress bar
        $totalSlotsToCreate = 0;
        foreach ($gigs as $gig) {
            $timeSlots = $this->generateTimeSlots($gig->start_time, $gig->end_time);
            $totalSlotsToCreate += count($timeSlots);
        }
        $totalSlotsToCreate *= $daysToCreate;

        $this->command->info('Creating gig slots...');
        $progressBar = $this->command->getOutput()->createProgressBar($totalSlotsToCreate);

        for ($day = 0; $day < $daysToCreate; $day++) {
            $currentDate = $startDate->copy()->addDays($day);

            foreach ($gigs as $gig) {
                // Generate time-based slots for this gig
                $timeSlots = $this->generateTimeSlots($gig->start_time, $gig->end_time);

                foreach ($timeSlots as $slotNum => $timeSlot) {
                    GigSlot::create([
                        'gig_id' => $gig->id,
                        'slot_number' => $slotNum + 1,
                        'slot_name' => $timeSlot['name'],
                        'slot_date' => $currentDate->toDateString(),
                        'start_time' => $timeSlot['start_time'],
                        'end_time' => $timeSlot['end_time'],
                        'max_bookings' => 50, // Each slot can have 50 bookings
                        'current_bookings' => rand(0, 10), // Random initial bookings for demo
                        'status' => 1
                    ]);

                    $totalSlots++;
                    $progressBar->advance();
                }
            }
        }

        $progressBar->finish();
        $this->command->newLine();
        $this->command->info("Successfully created {$totalSlots} gig slots!");
        $this->command->info("- {$gigs->count()} gigs");
        $this->command->info("- Time-based slots (2-hour intervals)");
        $this->command->info("- {$daysToCreate} days (from " . $startDate->toDateString() . " to " . $startDate->copy()->addDays($daysToCreate - 1)->toDateString() . ")");
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
