<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Gig;
use App\Models\GigSlot;
use App\Models\IncentiveOffer;
use App\Models\IncentiveOfferTier;
use Carbon\Carbon;

class GigSystemSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Create 4 Gigs (Morning, Afternoon, Evening, Night)
        $gigs = [
            [
                'name' => 'morning',
                'display_name' => 'Morning Shift',
                'start_time' => '06:00:00',
                'end_time' => '13:00:00',
                'duration_hours' => 7,
                'base_earnings' => 300.00,
                'status' => 1
            ],
            [
                'name' => 'afternoon',
                'display_name' => 'Afternoon Shift',
                'start_time' => '13:00:00',
                'end_time' => '18:00:00',
                'duration_hours' => 5,
                'base_earnings' => 250.00,
                'status' => 1
            ],
            [
                'name' => 'evening',
                'display_name' => 'Evening Shift',
                'start_time' => '18:00:00',
                'end_time' => '22:00:00',
                'duration_hours' => 4,
                'base_earnings' => 200.00,
                'status' => 1
            ],
            [
                'name' => 'night',
                'display_name' => 'Night Shift',
                'start_time' => '22:00:00',
                'end_time' => '02:00:00',
                'duration_hours' => 4,
                'base_earnings' => 250.00,
                'status' => 1
            ],
        ];

        foreach ($gigs as $gigData) {
            $gig = Gig::create($gigData);

            // Create slots for next 30 days for each gig
            for ($i = 0; $i < 30; $i++) {
                $date = Carbon::now()->addDays($i);

                GigSlot::create([
                    'gig_id' => $gig->id,
                    'slot_date' => $date->toDateString(),
                    'start_time' => $gig->start_time,
                    'end_time' => $gig->end_time,
                    'max_bookings' => 50,
                    'current_bookings' => 0,
                    'status' => 1
                ]);
            }
        }

        // Create Sankranthi Offer
        $sankranthiOffer = IncentiveOffer::create([
            'name' => 'Sankranthi Mega Bonus 2025',
            'banner_image' => null,
            'description' => 'Celebrate Sankranthi with mega bonuses! Complete gigs and earn up to ₹2000 extra. The more you earn, the bigger your bonus!',
            'start_date' => Carbon::now(),
            'end_date' => Carbon::now()->addDays(30),
            'status' => 1,
            'min_gigs_required' => 20,
            'max_gigs_skip' => 2,
            'max_orders_cancel' => 3,
            'login_mandatory' => true,
            'eligible_gig_ids' => null
        ]);

        // Create tiers for Sankranthi Offer
        $sankranthiTiers = [
            [
                'incentive_offer_id' => $sankranthiOffer->id,
                'earnings_target' => 500.00,
                'incentive_amount' => 100.00,
                'tier_name' => 'Bronze',
                'order_number' => 1
            ],
            [
                'incentive_offer_id' => $sankranthiOffer->id,
                'earnings_target' => 1000.00,
                'incentive_amount' => 210.00,
                'tier_name' => 'Silver',
                'order_number' => 2
            ],
            [
                'incentive_offer_id' => $sankranthiOffer->id,
                'earnings_target' => 2000.00,
                'incentive_amount' => 500.00,
                'tier_name' => 'Gold',
                'order_number' => 3
            ],
            [
                'incentive_offer_id' => $sankranthiOffer->id,
                'earnings_target' => 5000.00,
                'incentive_amount' => 1500.00,
                'tier_name' => 'Platinum',
                'order_number' => 4
            ],
        ];

        foreach ($sankranthiTiers as $tierData) {
            IncentiveOfferTier::create($tierData);
        }

        // Create Diwali Offer
        $diwaliOffer = IncentiveOffer::create([
            'name' => 'Diwali Dhamaka 2025',
            'banner_image' => null,
            'description' => 'Light up your Diwali with amazing bonuses! Work hard during the festive season and earn massive rewards. Complete minimum 25 gigs to qualify.',
            'start_date' => Carbon::now()->addDays(60),
            'end_date' => Carbon::now()->addDays(90),
            'status' => 1,
            'min_gigs_required' => 25,
            'max_gigs_skip' => 1,
            'max_orders_cancel' => 2,
            'login_mandatory' => true,
            'eligible_gig_ids' => null
        ]);

        // Create tiers for Diwali Offer
        $diwaliTiers = [
            [
                'incentive_offer_id' => $diwaliOffer->id,
                'earnings_target' => 1000.00,
                'incentive_amount' => 200.00,
                'tier_name' => 'Bronze',
                'order_number' => 1
            ],
            [
                'incentive_offer_id' => $diwaliOffer->id,
                'earnings_target' => 3000.00,
                'incentive_amount' => 750.00,
                'tier_name' => 'Silver',
                'order_number' => 2
            ],
            [
                'incentive_offer_id' => $diwaliOffer->id,
                'earnings_target' => 7000.00,
                'incentive_amount' => 2000.00,
                'tier_name' => 'Gold',
                'order_number' => 3
            ],
        ];

        foreach ($diwaliTiers as $tierData) {
            IncentiveOfferTier::create($tierData);
        }

        // Create New Year Bonus Offer
        $newYearOffer = IncentiveOffer::create([
            'name' => 'New Year Kickstart Bonus',
            'banner_image' => null,
            'description' => 'Start your new year with extra earnings! Quick bonus for completing gigs in the first month of the year.',
            'start_date' => Carbon::now()->addMonths(1),
            'end_date' => Carbon::now()->addMonths(2),
            'status' => 1,
            'min_gigs_required' => 15,
            'max_gigs_skip' => 3,
            'max_orders_cancel' => 5,
            'login_mandatory' => false,
            'eligible_gig_ids' => null
        ]);

        // Create tiers for New Year Offer
        $newYearTiers = [
            [
                'incentive_offer_id' => $newYearOffer->id,
                'earnings_target' => 300.00,
                'incentive_amount' => 50.00,
                'tier_name' => 'Starter',
                'order_number' => 1
            ],
            [
                'incentive_offer_id' => $newYearOffer->id,
                'earnings_target' => 800.00,
                'incentive_amount' => 150.00,
                'tier_name' => 'Achiever',
                'order_number' => 2
            ],
            [
                'incentive_offer_id' => $newYearOffer->id,
                'earnings_target' => 1500.00,
                'incentive_amount' => 350.00,
                'tier_name' => 'Champion',
                'order_number' => 3
            ],
        ];

        foreach ($newYearTiers as $tierData) {
            IncentiveOfferTier::create($tierData);
        }

        $this->command->info('✅ Gig system seeded successfully!');
        $this->command->info('   - 4 Gigs created (Morning, Afternoon, Evening, Night)');
        $this->command->info('   - 120 Gig Slots created (30 days × 4 gigs)');
        $this->command->info('   - 3 Incentive Offers created');
        $this->command->info('   - 11 Offer Tiers created');
    }
}
