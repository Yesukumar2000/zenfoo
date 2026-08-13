<?php

namespace App\Services;

use App\Models\DeliveryBoy;
use App\Models\IncentiveOffer;
use App\Models\DeliveryBoyIncentiveProgress;
use App\Models\DeliveryBoyDailyTracking;
use App\Models\Order;
use App\Models\DeliveryBoyTransaction;
use App\Models\DeliveryBoyIncentiveTierCredit;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class DeliveryBoyIncentiveService
{
    /**
     * Update incentive progress when an order is completed
     * Called from markDelivered or collectCash
     *
     * @param DeliveryBoy $deliveryBoy
     * @param Order $order
     * @return void
     */
    public static function updateIncentiveProgressOnOrderCompletion(DeliveryBoy $deliveryBoy, Order $order)
    {
        try {
            Log::info('Incentive Progress: Processing order completion', [
                'delivery_boy_id' => $deliveryBoy->id,
                'order_id' => $order->id
            ]);

            // Get today's tracking for earnings
            $today = Carbon::today()->toDateString();
            $todayTracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->where('tracking_date', $today)
                ->first();

            if (!$todayTracking) {
                Log::warning('Incentive Progress: No daily tracking found', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'date' => $today
                ]);
                return;
            }

            // Get all active incentive offers
            $activeOffers = IncentiveOffer::active()->get();

            if ($activeOffers->isEmpty()) {
                Log::info('Incentive Progress: No active offers found');
                return;
            }

            // Update progress for each active offer
            foreach ($activeOffers as $offer) {
                self::updateProgressForOffer($deliveryBoy, $offer, $order, $todayTracking);
            }

        } catch (\Exception $e) {
            Log::error('Incentive Progress: Error updating incentive progress', [
                'delivery_boy_id' => $deliveryBoy->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
        }
    }

    /**
     * Update progress for a specific offer
     *
     * @param DeliveryBoy $deliveryBoy
     * @param IncentiveOffer $offer
     * @param Order $order
     * @param DeliveryBoyDailyTracking $todayTracking
     * @return void
     */
    private static function updateProgressForOffer(
        DeliveryBoy $deliveryBoy,
        IncentiveOffer $offer,
        Order $order,
        DeliveryBoyDailyTracking $todayTracking
    ) {
        try {
            // Get or create progress
            $progress = DeliveryBoyIncentiveProgress::firstOrCreate(
                [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'incentive_offer_id' => $offer->id
                ]
            );

            // Check if offer is still eligible for this delivery boy
            if (!self::isEligibleForOffer($progress, $offer)) {
                Log::info('Incentive Progress: Delivery boy not eligible for offer', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'offer_id' => $offer->id,
                    'reason' => 'Failed eligibility check'
                ]);
                $progress->is_eligible = false;
                $progress->save();
                return;
            }

            // Calculate cumulative earnings from offer start date (not just today)
            $offerStartDate = Carbon::parse($offer->start_date)->toDateString();
            $cumulativeTracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->where('tracking_date', '>=', $offerStartDate)
                ->where('tracking_date', '<=', Carbon::today()->toDateString())
                ->get();

            // Sum earnings from all days within offer period
            $currentEarnings = (float) $cumulativeTracking->sum('total_earnings');
            $totalGigsCompleted = (int) $cumulativeTracking->sum('gigs_completed');
            $totalOrdersCancelled = (int) $cumulativeTracking->sum('orders_cancelled');

            Log::info('Incentive Progress: Current earnings', [
                'delivery_boy_id' => $deliveryBoy->id,
                'offer_id' => $offer->id,
                'current_earnings' => $currentEarnings,
                'offer_start_date' => $offerStartDate,
                'tracking_days' => $cumulativeTracking->count()
            ]);

            // Update progress with cumulative data
            $progress->current_earnings = $currentEarnings;
            $progress->gigs_completed = $totalGigsCompleted;
            $progress->orders_cancelled = $totalOrdersCancelled;
            $progress->save();

            // Check if new tier is achieved
            self::checkAndUpdateAchievedTier($progress, $offer, $deliveryBoy);

            Log::info('Incentive Progress: Updated successfully', [
                'delivery_boy_id' => $deliveryBoy->id,
                'offer_id' => $offer->id,
                'progress_id' => $progress->id,
                'current_earnings' => $progress->current_earnings
            ]);

        } catch (\Exception $e) {
            Log::error('Incentive Progress: Error updating progress for offer', [
                'delivery_boy_id' => $deliveryBoy->id,
                'offer_id' => $offer->id,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Check if delivery boy is eligible for the offer
     * Verifies:
     * - Minimum gigs requirement
     * - Maximum gigs skipped limit
     * - Maximum orders cancelled limit
     * - Login mandatory requirement
     *
     * @param DeliveryBoyIncentiveProgress $progress
     * @param IncentiveOffer $offer
     * @return bool
     */
    private static function isEligibleForOffer(DeliveryBoyIncentiveProgress $progress, IncentiveOffer $offer)
    {
        // Check minimum gigs requirement
        if ($offer->min_gigs_required > 0 && $progress->gigs_completed < $offer->min_gigs_required) {
            Log::debug('Incentive Progress: Min gigs requirement not met', [
                'required' => $offer->min_gigs_required,
                'completed' => $progress->gigs_completed
            ]);
            return true; // Still eligible, just not completed
        }

        // Check maximum gigs skipped
        if ($offer->max_gigs_skip >= 0 && $progress->gigs_skipped > $offer->max_gigs_skip) {
            Log::debug('Incentive Progress: Max gigs skip exceeded', [
                'max' => $offer->max_gigs_skip,
                'skipped' => $progress->gigs_skipped
            ]);
            return false;
        }

        // Check maximum orders cancelled
        if ($offer->max_orders_cancel >= 0 && $progress->orders_cancelled > $offer->max_orders_cancel) {
            Log::debug('Incentive Progress: Max orders cancelled exceeded', [
                'max' => $offer->max_orders_cancel,
                'cancelled' => $progress->orders_cancelled
            ]);
            return false;
        }

        // Check login mandatory
        if ($offer->login_mandatory && !$progress->login_compliance) {
            Log::debug('Incentive Progress: Login mandatory requirement not met');
            return false;
        }

        return true;
    }

    /**
     * Check if new tiers have been achieved and credit wallet for all newly crossed tiers
     *
     * @param DeliveryBoyIncentiveProgress $progress
     * @param IncentiveOffer $offer
     * @param DeliveryBoy $deliveryBoy
     * @return void
     */
    private static function checkAndUpdateAchievedTier(
        DeliveryBoyIncentiveProgress $progress,
        IncentiveOffer $offer,
        DeliveryBoy $deliveryBoy
    ) {
        try {
            // Get all tiers for this offer sorted by earnings target
            $tiers = $offer->tiers()->orderBy('earnings_target', 'asc')->get();

            // Step 1: Find all tiers that current earnings can achieve
            $achievableTiers = [];
            $highestAchievedTier = null;

            foreach ($tiers as $tier) {
                if ($progress->current_earnings >= $tier->earnings_target) {
                    $achievableTiers[] = $tier;
                    $highestAchievedTier = $tier;
                }
            }

            // Step 2: Get tier IDs that have already been credited
            $creditedTierIds = DeliveryBoyIncentiveTierCredit::where(
                'delivery_boy_incentive_progress_id',
                $progress->id
            )->pluck('tier_id')->toArray();

            // Step 3: Find newly crossed tiers (achievable but not yet credited)
            $newTiersToCredit = [];
            foreach ($achievableTiers as $tier) {
                if (!in_array($tier->id, $creditedTierIds)) {
                    $newTiersToCredit[] = $tier;
                }
            }

            // Step 4: If there are new tiers to credit, process them
            if (!empty($newTiersToCredit)) {
                Log::info('Incentive Progress: New tiers to credit', [
                    'delivery_boy_id' => $progress->delivery_boy_id,
                    'offer_id' => $offer->id,
                    'tier_count' => count($newTiersToCredit),
                    'tier_ids' => collect($newTiersToCredit)->pluck('id')->toArray()
                ]);

                // Calculate total incentive amount from all newly crossed tiers
                $totalCreditAmount = 0;
                foreach ($newTiersToCredit as $tier) {
                    $totalCreditAmount += (float) $tier->incentive_amount;
                }

                // Credit all newly crossed tiers in a single transaction
                $transaction = self::creditIncentiveToWallet(
                    $deliveryBoy,
                    $offer,
                    $totalCreditAmount,
                    $newTiersToCredit  // Pass all new tiers
                );

                // Create individual credit records for each tier (linked to same transaction)
                foreach ($newTiersToCredit as $tier) {
                    DeliveryBoyIncentiveTierCredit::create([
                        'delivery_boy_incentive_progress_id' => $progress->id,
                        'tier_id' => $tier->id,
                        'incentive_amount' => (float) $tier->incentive_amount,
                        'transaction_id' => $transaction ? $transaction->id : null,
                        'credited_at' => now()
                    ]);

                    Log::info('Incentive Progress: Tier credited', [
                        'delivery_boy_id' => $progress->delivery_boy_id,
                        'tier_id' => $tier->id,
                        'tier_name' => $tier->tier_name,
                        'incentive_amount' => $tier->incentive_amount,
                        'transaction_id' => $transaction ? $transaction->id : null
                    ]);
                }

                Log::info('Incentive Progress: Tiers credited to wallet', [
                    'delivery_boy_id' => $progress->delivery_boy_id,
                    'offer_id' => $offer->id,
                    'total_amount' => $totalCreditAmount,
                    'tier_count' => count($newTiersToCredit),
                    'transaction_id' => $transaction ? $transaction->id : null
                ]);
            }

            // Step 5: Update progress with highest achieved tier
            if ($highestAchievedTier && $progress->achieved_tier_id !== $highestAchievedTier->id) {
                $progress->achieved_tier_id = $highestAchievedTier->id;
                $progress->incentive_earned = $highestAchievedTier->incentive_amount;

                Log::info('Incentive Progress: Tier achievement updated', [
                    'delivery_boy_id' => $progress->delivery_boy_id,
                    'offer_id' => $offer->id,
                    'highest_tier_id' => $highestAchievedTier->id,
                    'tier_name' => $highestAchievedTier->tier_name
                ]);

                // Check if all tiers are completed
                $maxTier = $tiers->last();
                if ($highestAchievedTier->id === $maxTier->id) {
                    $progress->is_completed = true;
                    $progress->completed_at = now();
                    $progress->status = 'completed';

                    Log::info('Incentive Progress: Offer fully completed', [
                        'delivery_boy_id' => $progress->delivery_boy_id,
                        'offer_id' => $offer->id
                    ]);
                }

                $progress->save();
            }

        } catch (\Exception $e) {
            Log::error('Incentive Progress: Error checking tier achievement', [
                'delivery_boy_id' => $progress->delivery_boy_id ?? null,
                'offer_id' => $offer->id ?? null,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
        }
    }

    /**
     * Credit incentive earnings to delivery boy's wallet/balance
     *
     * @param DeliveryBoy $deliveryBoy
     * @param IncentiveOffer $offer
     * @param float $incentiveAmount
     * @param array $tiersInfo Optional - array of tier objects being credited
     * @return DeliveryBoyTransaction|null
     */
    private static function creditIncentiveToWallet(
        DeliveryBoy $deliveryBoy,
        IncentiveOffer $offer,
        $incentiveAmount,
        $tiersInfo = null
    ) {
        try {
            $incentiveAmount = (float) $incentiveAmount;

            // Build meaningful message based on tiers being credited
            if ($tiersInfo && !empty($tiersInfo)) {
                $tierNames = collect($tiersInfo)->pluck('tier_name')->implode(', ');
                if (count($tiersInfo) > 1) {
                    $message = "Incentives earned for tiers: {$tierNames}";
                } else {
                    $message = "Incentive earned: {$tierNames}";
                }
            } else {
                $message = 'Incentive earned: ' . $offer->name;
            }

            // Create transaction record for incentive credit
            $transaction = DeliveryBoyTransaction::create([
                'delivery_boy_id' => $deliveryBoy->id,
                'type' => 'incentive',
                'amount' => $incentiveAmount,
                'status' => "pending",
                // 'status' => DeliveryBoyTransaction::$statusPending,
                'message' => $message,
                'transaction_date' => now()
            ]);

            // Update delivery boy's wallet balance
            $deliveryBoy->increment('balance', $incentiveAmount);

            Log::info('Incentive Progress: Amount credited to wallet', [
                'delivery_boy_id' => $deliveryBoy->id,
                'offer_id' => $offer->id,
                'incentive_amount' => $incentiveAmount,
                'transaction_id' => $transaction->id,
                'tier_count' => $tiersInfo ? count($tiersInfo) : 0,
                'new_balance' => $deliveryBoy->balance
            ]);

            return $transaction;

        } catch (\Exception $e) {
            Log::error('Incentive Progress: Error crediting wallet', [
                'delivery_boy_id' => $deliveryBoy->id,
                'offer_id' => $offer->id,
                'amount' => $incentiveAmount,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return null;
        }
    }

    /**
     * Get incentive progress summary for a delivery boy
     *
     * @param DeliveryBoy $deliveryBoy
     * @return array
     */
    public static function getProgressSummary(DeliveryBoy $deliveryBoy)
    {
        try {
            $progressList = DeliveryBoyIncentiveProgress::where('delivery_boy_id', $deliveryBoy->id)
                ->with(['incentiveOffer.tiers', 'achievedTier'])
                ->where('status', 'active')
                ->get();

            $summary = [
                'total_active_offers' => $progressList->count(),
                'total_incentive_earned' => (float) $progressList->sum('incentive_earned'),
                'offers' => $progressList->map(function ($progress) {
                    return [
                        'offer_id' => $progress->incentive_offer_id,
                        'offer_name' => $progress->incentiveOffer->name,
                        'current_earnings' => (float) $progress->current_earnings,
                        'incentive_earned' => (float) $progress->incentive_earned,
                        'achieved_tier' => $progress->achievedTier ? $progress->achievedTier->tier_name : 'None',
                        'is_completed' => (bool) $progress->is_completed
                    ];
                })
            ];

            return $summary;

        } catch (\Exception $e) {
            Log::error('Incentive Progress: Error getting progress summary', [
                'delivery_boy_id' => $deliveryBoy->id,
                'error' => $e->getMessage()
            ]);
            return [];
        }
    }
}
