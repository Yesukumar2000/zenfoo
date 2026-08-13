<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\IncentiveOffer;
use App\Models\DeliveryBoyIncentiveProgress;
use App\Models\DeliveryBoyGigBooking;
use App\Models\DeliveryBoyDailyTracking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class IncentiveOfferController extends Controller
{
    /**
     * Get all active incentive offers
     *
     * GET /api/delivery_boy/offers/active
     */
    public function getActiveOffers(Request $request)
    {
        try {
            Log::info('activeOffers: [STEP 1] Request received');

            $user = Auth::user();
            if (!$user) {
                Log::warning('activeOffers: [STEP 1] Unauthorized - no authenticated user');
                return CommonHelper::responseError('Unauthorized');
            }

            Log::info('activeOffers: [STEP 2] User authenticated', ['user_id' => $user->id]);

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                Log::warning('activeOffers: [STEP 2] Delivery boy not found', ['user_id' => $user->id]);
                return CommonHelper::responseError('Delivery boy not found');
            }

            Log::info('activeOffers: [STEP 3] Delivery boy found', ['delivery_boy_id' => $deliveryBoy->id]);

            // Get today's tracking for daily metrics
            $today = Carbon::today()->toDateString();
            $todayTracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->where('tracking_date', $today)
                ->first();

            Log::info('activeOffers: [STEP 4] Today tracking', ['date' => $today, 'has_tracking' => $todayTracking ? true : false]);

            // Get active offers
            $offers = IncentiveOffer::active()
                ->with('tiers')
                ->orderBy('start_date', 'desc')
                ->get();

            Log::info('activeOffers: [STEP 5] Active offers fetched', ['count' => $offers->count()]);

            $offerData = $offers->map(function ($offer) use ($deliveryBoy, $todayTracking) {
                Log::info('activeOffers: [STEP 6] Processing offer', ['offer_id' => $offer->id, 'offer_name' => $offer->name]);

                // Calculate cumulative earnings from offer start date until now
                $offerStartDate = Carbon::parse($offer->start_date)->toDateString();
                $today = Carbon::today()->toDateString();

                $cumulativeEarnings = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->whereBetween('tracking_date', [$offerStartDate, $today])
                    ->sum('total_earnings');

                $currentEarnings = (float) $cumulativeEarnings;

                Log::info('activeOffers: [STEP 7] Cumulative earnings', ['offer_id' => $offer->id, 'earnings' => $currentEarnings, 'from' => $offerStartDate, 'to' => $today]);

                // Get or create progress for this offer
                $progress = DeliveryBoyIncentiveProgress::firstOrCreate(
                    [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'incentive_offer_id' => $offer->id
                    ],
                    [
                        'current_earnings' => 0,
                        'gigs_completed' => 0,
                        'gigs_skipped' => 0,
                        'orders_cancelled' => 0,
                        'login_compliance' => true,
                        'is_eligible' => true,
                        'incentive_earned' => 0,
                        'status' => 'active'
                    ]
                );

                Log::info('activeOffers: [STEP 8] Progress record', ['offer_id' => $offer->id, 'progress_id' => $progress->id]);

                // Update progress with cumulative earnings and metrics from offer start date
                $offerStartDate = Carbon::parse($offer->start_date)->toDateString();
                $todayStr = Carbon::today()->toDateString();

                // Get cumulative metrics from offer start date to now
                $cumulativeMetrics = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->whereBetween('tracking_date', [$offerStartDate, $todayStr])
                    ->selectRaw('SUM(gigs_completed) as total_gigs_completed, SUM(orders_cancelled) as total_orders_cancelled')
                    ->first();

                $progress->current_earnings = $currentEarnings;
                $progress->gigs_completed = (int) ($cumulativeMetrics->total_gigs_completed ?? 0);
                $progress->orders_cancelled = (int) ($cumulativeMetrics->total_orders_cancelled ?? 0);
                $progress->save();

                Log::info('activeOffers: [STEP 9] Progress updated', ['offer_id' => $offer->id, 'current_earnings' => $currentEarnings, 'gigs_completed' => $progress->gigs_completed, 'orders_cancelled' => $progress->orders_cancelled]);

                // Get credited tiers for this progress
                $creditedTiers = $progress->creditedTiers()->get();

                Log::info('activeOffers: [STEP 10] Credited tiers fetched', ['offer_id' => $offer->id, 'credited_tiers_count' => $creditedTiers->count()]);

                // Calculate detailed progress metrics
                $progressMetrics = $this->calculateProgressMetrics($progress, $offer);

                // Calculate current tier
                $currentTier = null;
                $nextTier = null;

                foreach ($offer->tiers as $tier) {
                    if ($progress->current_earnings >= $tier->earnings_target) {
                        $currentTier = [
                            'tier_name' => $tier->tier_name,
                            'earnings_target' => (float) $tier->earnings_target,
                            'incentive_amount' => (float) $tier->incentive_amount,
                            'achieved' => true
                        ];
                    } else if (!$nextTier) {
                        $nextTier = [
                            'tier_name' => $tier->tier_name,
                            'earnings_target' => (float) $tier->earnings_target,
                            'incentive_amount' => (float) $tier->incentive_amount,
                            'remaining_earnings' => (float) ($tier->earnings_target - $progress->current_earnings),
                            'progress_percentage' => round(($progress->current_earnings / $tier->earnings_target) * 100, 2)
                        ];
                    }
                }

                return [
                    'offer_id' => $offer->id,
                    'name' => $offer->name,
                    'description' => $offer->description,
                    'banner_image_url' => $offer->banner_image ? (str_starts_with($offer->banner_image, 'http') ? $offer->banner_image : asset('storage/' . $offer->banner_image)) : null,
                    'start_date' => Carbon::parse($offer->start_date)->toIso8601String(),
                    'end_date' => Carbon::parse($offer->end_date)->toIso8601String(),
                    'days_remaining' => Carbon::now()->diffInDays(Carbon::parse($offer->end_date), false),
                    'conditions' => [
                        'min_gigs_required' => $offer->min_gigs_required,
                        'max_gigs_skip' => $offer->max_gigs_skip,
                        'max_orders_cancel' => $offer->max_orders_cancel,
                        'login_mandatory' => $offer->login_mandatory
                    ],
                    'my_progress' => [
                        'current_earnings' => $progressMetrics['current_earnings'],
                        'gigs_completed' => $progress->gigs_completed,
                        'gigs_skipped' => $progress->gigs_skipped,
                        'orders_cancelled' => $progress->orders_cancelled,
                        'is_eligible' => $progress->is_eligible,
                        'previous_target_amount' => $progressMetrics['previous_target_amount'],
                        'current_target_amount' => $progressMetrics['current_target_amount'],
                        'total_target_amount' => $progressMetrics['total_target_amount'],
                        'amount_needed' => $progressMetrics['amount_needed'],
                        'progress_percentage' => $progressMetrics['progress_percentage'],
                        'overall_progress_percentage' => $progressMetrics['overall_progress_percentage'],
                        'current_tier' => $currentTier,
                        'next_tier' => $nextTier,
                        'credited_tiers' => $creditedTiers->map(function ($credit) {
                            return [
                                'tier_id' => $credit->tier_id,
                                'incentive_amount' => (float) $credit->incentive_amount,
                                'credited_at' => $credit->credited_at->toIso8601String(),
                                'transaction_id' => $credit->transaction_id
                            ];
                        })->values(),
                        'total_credited_amount' => (float) $creditedTiers->sum('incentive_amount')
                    ],
                    'tiers' => collect([
                        // Starting tier from 0
                        [
                            'tier_name' => 'Start',
                            'earnings_target' => 0,
                            'incentive_amount' => 0,
                            'is_achieved' => true,
                            'order' => 0,
                            'percentage' => 0
                        ]
                    ])->merge(
                            $offer->tiers->map(function ($tier) use ($progress, $offer) {
                                // Calculate percentage of total (last tier is max target)
                                $maxTarget = $offer->tiers->last()->earnings_target;
                                $tierPercentage = $maxTarget > 0 ? round(((float) $tier->earnings_target / (float) $maxTarget) * 100, 2) : 0;

                                return [
                                    'tier_name' => $tier->tier_name,
                                    'earnings_target' => (float) $tier->earnings_target,
                                    'incentive_amount' => (float) $tier->incentive_amount,
                                    'is_achieved' => $progress->current_earnings >= $tier->earnings_target,
                                    'order' => $tier->order_number,
                                    'percentage' => $tierPercentage
                                ];
                            })
                        )->values()
                ];
            });

            Log::info('activeOffers: [STEP 11] SUCCESS - Active offers response ready', ['total_offers' => $offerData->count()]);

            return response()->json([
                'status' => true,
                'message' => 'Active offers retrieved successfully',
                'data' => [
                    'offers' => $offerData,
                    'total_offers' => $offerData->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('activeOffers: FAILED', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get active offers without auth (debug/test endpoint)
     * Pass delivery_boy_id as query param
     *
     * GET /api/delivery_boy/active-offers-test?delivery_boy_id=33
     */
    public function getActiveOffersTest(Request $request)
    {
        try {
            Log::info('activeOffersTest: [STEP 1] Request received', ['delivery_boy_id' => $request->delivery_boy_id]);

            $deliveryBoyId = $request->delivery_boy_id;
            if (!$deliveryBoyId) {
                Log::warning('activeOffersTest: [STEP 1] delivery_boy_id is required');
                return CommonHelper::responseError('delivery_boy_id is required');
            }

            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            if (!$deliveryBoy) {
                Log::warning('activeOffersTest: [STEP 2] Delivery boy not found', ['delivery_boy_id' => $deliveryBoyId]);
                return CommonHelper::responseError('Delivery boy not found');
            }

            Log::info('activeOffersTest: [STEP 2] Delivery boy found', ['delivery_boy_id' => $deliveryBoy->id, 'name' => $deliveryBoy->name]);

            // Get today's tracking for daily metrics
            $today = Carbon::today()->toDateString();
            $todayTracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->where('tracking_date', $today)
                ->first();

            Log::info('activeOffersTest: [STEP 3] Today tracking', ['date' => $today, 'has_tracking' => $todayTracking ? true : false]);

            // Get active offers
            $offers = IncentiveOffer::active()
                ->with('tiers')
                ->orderBy('start_date', 'desc')
                ->get();

            Log::info('activeOffersTest: [STEP 4] Active offers fetched', ['count' => $offers->count()]);

            if ($offers->count() === 0) {
                Log::info('activeOffersTest: [STEP 5] No active offers found, returning empty');
                return response()->json([
                    'status' => true,
                    'message' => 'No active offers found',
                    'data' => [
                        'offers' => [],
                        'total_offers' => 0
                    ]
                ]);
            }

            $offerData = $offers->map(function ($offer) use ($deliveryBoy) {
                Log::info('activeOffersTest: [STEP 5] Processing offer', ['offer_id' => $offer->id, 'offer_name' => $offer->name]);

                $offerStartDate = Carbon::parse($offer->start_date)->toDateString();
                $today = Carbon::today()->toDateString();

                $cumulativeEarnings = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->whereBetween('tracking_date', [$offerStartDate, $today])
                    ->sum('total_earnings');

                $currentEarnings = (float) $cumulativeEarnings;

                Log::info('activeOffersTest: [STEP 6] Cumulative earnings', ['offer_id' => $offer->id, 'earnings' => $currentEarnings]);

                $progress = DeliveryBoyIncentiveProgress::firstOrCreate(
                    [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'incentive_offer_id' => $offer->id
                    ],
                    [
                        'current_earnings' => 0,
                        'gigs_completed' => 0,
                        'gigs_skipped' => 0,
                        'orders_cancelled' => 0,
                        'login_compliance' => true,
                        'is_eligible' => true,
                        'incentive_earned' => 0,
                        'status' => 'active'
                    ]
                );

                Log::info('activeOffersTest: [STEP 7] Progress record', ['offer_id' => $offer->id, 'progress_id' => $progress->id]);

                $todayStr = Carbon::today()->toDateString();
                $cumulativeMetrics = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->whereBetween('tracking_date', [$offerStartDate, $todayStr])
                    ->selectRaw('SUM(gigs_completed) as total_gigs_completed, SUM(orders_cancelled) as total_orders_cancelled')
                    ->first();

                $progress->current_earnings = $currentEarnings;
                $progress->gigs_completed = (int) ($cumulativeMetrics->total_gigs_completed ?? 0);
                $progress->orders_cancelled = (int) ($cumulativeMetrics->total_orders_cancelled ?? 0);
                $progress->save();

                Log::info('activeOffersTest: [STEP 8] Progress updated', ['offer_id' => $offer->id, 'current_earnings' => $currentEarnings, 'gigs_completed' => $progress->gigs_completed]);

                $creditedTiers = $progress->creditedTiers()->get();

                Log::info('activeOffersTest: [STEP 9] Credited tiers fetched', ['offer_id' => $offer->id, 'count' => $creditedTiers->count()]);

                $progressMetrics = $this->calculateProgressMetrics($progress, $offer);

                Log::info('activeOffersTest: [STEP 10] Progress metrics calculated', ['offer_id' => $offer->id, 'metrics' => $progressMetrics]);

                $currentTier = null;
                $nextTier = null;

                foreach ($offer->tiers as $tier) {
                    if ($progress->current_earnings >= $tier->earnings_target) {
                        $currentTier = [
                            'tier_name' => $tier->tier_name,
                            'earnings_target' => (float) $tier->earnings_target,
                            'incentive_amount' => (float) $tier->incentive_amount,
                            'achieved' => true
                        ];
                    } else if (!$nextTier) {
                        $nextTier = [
                            'tier_name' => $tier->tier_name,
                            'earnings_target' => (float) $tier->earnings_target,
                            'incentive_amount' => (float) $tier->incentive_amount,
                            'remaining_earnings' => (float) ($tier->earnings_target - $progress->current_earnings),
                            'progress_percentage' => $tier->earnings_target > 0 ? round(($progress->current_earnings / $tier->earnings_target) * 100, 2) : 0
                        ];
                    }
                }

                return [
                    'offer_id' => $offer->id,
                    'name' => $offer->name,
                    'description' => $offer->description,
                    'banner_image_url' => $offer->banner_image ? (str_starts_with($offer->banner_image, 'http') ? $offer->banner_image : asset('storage/' . $offer->banner_image)) : null,
                    'start_date' => Carbon::parse($offer->start_date)->toIso8601String(),
                    'end_date' => Carbon::parse($offer->end_date)->toIso8601String(),
                    'days_remaining' => Carbon::now()->diffInDays(Carbon::parse($offer->end_date), false),
                    'conditions' => [
                        'min_gigs_required' => $offer->min_gigs_required,
                        'max_gigs_skip' => $offer->max_gigs_skip,
                        'max_orders_cancel' => $offer->max_orders_cancel,
                        'login_mandatory' => $offer->login_mandatory
                    ],
                    'my_progress' => [
                        'current_earnings' => $progressMetrics['current_earnings'],
                        'gigs_completed' => $progress->gigs_completed,
                        'gigs_skipped' => $progress->gigs_skipped,
                        'orders_cancelled' => $progress->orders_cancelled,
                        'is_eligible' => $progress->is_eligible,
                        'previous_target_amount' => $progressMetrics['previous_target_amount'],
                        'current_target_amount' => $progressMetrics['current_target_amount'],
                        'total_target_amount' => $progressMetrics['total_target_amount'],
                        'amount_needed' => $progressMetrics['amount_needed'],
                        'progress_percentage' => $progressMetrics['progress_percentage'],
                        'overall_progress_percentage' => $progressMetrics['overall_progress_percentage'],
                        'current_tier' => $currentTier,
                        'next_tier' => $nextTier,
                        'credited_tiers' => $creditedTiers->map(function ($credit) {
                            return [
                                'tier_id' => $credit->tier_id,
                                'incentive_amount' => (float) $credit->incentive_amount,
                                'credited_at' => $credit->credited_at ? $credit->credited_at->toIso8601String() : null,
                                'transaction_id' => $credit->transaction_id
                            ];
                        })->values(),
                        'total_credited_amount' => (float) $creditedTiers->sum('incentive_amount')
                    ],
                    'tiers' => collect([
                        [
                            'tier_name' => 'Start',
                            'earnings_target' => 0,
                            'incentive_amount' => 0,
                            'is_achieved' => true,
                            'order' => 0,
                            'percentage' => 0
                        ]
                    ])->merge(
                        $offer->tiers->map(function ($tier) use ($progress, $offer) {
                            $maxTarget = $offer->tiers->last()->earnings_target;
                            $tierPercentage = $maxTarget > 0 ? round(((float) $tier->earnings_target / (float) $maxTarget) * 100, 2) : 0;

                            return [
                                'tier_name' => $tier->tier_name,
                                'earnings_target' => (float) $tier->earnings_target,
                                'incentive_amount' => (float) $tier->incentive_amount,
                                'is_achieved' => $progress->current_earnings >= $tier->earnings_target,
                                'order' => $tier->order_number,
                                'percentage' => $tierPercentage
                            ];
                        })
                    )->values()
                ];
            });

            Log::info('activeOffersTest: [STEP 11] SUCCESS', ['total_offers' => $offerData->count()]);

            return response()->json([
                'status' => true,
                'message' => 'Active offers retrieved successfully',
                'data' => [
                    'offers' => $offerData,
                    'total_offers' => $offerData->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('activeOffersTest: FAILED', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get my progress for all offers
     *
     * GET /api/delivery_boy/offers/my-progress
     */
    public function getMyProgress(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $progressList = DeliveryBoyIncentiveProgress::where('delivery_boy_id', $deliveryBoy->id)
                ->with(['incentiveOffer.tiers'])
                ->get();

            $progressData = $progressList->map(function ($progress) {
                $offer = $progress->incentiveOffer;

                // Get current and next tier
                $currentTier = null;
                $nextTier = null;
                $allTiers = $offer->tiers;

                foreach ($allTiers as $tier) {
                    if ($progress->current_earnings >= $tier->earnings_target) {
                        $currentTier = $tier;
                    } else if (!$nextTier) {
                        $nextTier = $tier;
                    }
                }

                return [
                    'progress_id' => $progress->id,
                    'offer_name' => $offer->name,
                    'offer_id' => $offer->id,
                    'status' => $progress->status,
                    'current_earnings' => (float) $progress->current_earnings,
                    'gigs_completed' => $progress->gigs_completed,
                    'gigs_skipped' => $progress->gigs_skipped,
                    'orders_cancelled' => $progress->orders_cancelled,
                    'login_compliance' => $progress->login_compliance,
                    'is_eligible' => $progress->is_eligible,
                    'incentive_earned' => (float) $progress->incentive_earned,
                    'current_tier' => $currentTier ? [
                        'tier_name' => $currentTier->tier_name,
                        'earnings_target' => (float) $currentTier->earnings_target,
                        'incentive_amount' => (float) $currentTier->incentive_amount
                    ] : null,
                    'next_tier' => $nextTier ? [
                        'tier_name' => $nextTier->tier_name,
                        'earnings_target' => (float) $nextTier->earnings_target,
                        'incentive_amount' => (float) $nextTier->incentive_amount,
                        'remaining_earnings' => (float) ($nextTier->earnings_target - $progress->current_earnings),
                        'progress_percentage' => round(($progress->current_earnings / $nextTier->earnings_target) * 100, 2)
                    ] : null,
                    'offer_end_date' => Carbon::parse($offer->end_date)->toIso8601String(),
                    'days_remaining' => Carbon::now()->diffInDays(Carbon::parse($offer->end_date), false),
                    'eligibility_status' => $this->getEligibilityStatus($progress, $offer)
                ];
            });

            return response()->json([
                'status' => true,
                'message' => 'Progress retrieved successfully',
                'data' => [
                    'progress' => $progressData,
                    'total_offers' => $progressData->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get progress', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get specific offer details
     *
     * GET /api/delivery_boy/offers/{id}
     */
    public function getOfferDetails(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $offer = IncentiveOffer::with('tiers')->find($request->offer_id);
            if (!$offer) {
                return CommonHelper::responseError('Offer not found');
            }

            // Calculate cumulative earnings from offer start date until now
            $offerStartDate = Carbon::parse($offer->start_date)->toDateString();
            $todayStr = Carbon::today()->toDateString();

            $cumulativeEarnings = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->whereBetween('tracking_date', [$offerStartDate, $todayStr])
                ->sum('total_earnings');

            // Get cumulative metrics from offer start date to now
            $cumulativeMetrics = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->whereBetween('tracking_date', [$offerStartDate, $todayStr])
                ->selectRaw('SUM(gigs_completed) as total_gigs_completed, SUM(orders_cancelled) as total_orders_cancelled')
                ->first();

            // Get or create progress
            $progress = DeliveryBoyIncentiveProgress::firstOrCreate(
                [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'incentive_offer_id' => $offer->id
                ],
                [
                    'current_earnings' => 0,
                    'gigs_completed' => 0,
                    'gigs_skipped' => 0,
                    'orders_cancelled' => 0,
                    'login_compliance' => true,
                    'is_eligible' => true,
                    'incentive_earned' => 0,
                    'status' => 'active'
                ]
            );

            // Update progress with cumulative earnings and metrics
            $progress->current_earnings = (float) $cumulativeEarnings;
            $progress->gigs_completed = (int) ($cumulativeMetrics->total_gigs_completed ?? 0);
            $progress->orders_cancelled = (int) ($cumulativeMetrics->total_orders_cancelled ?? 0);
            $progress->save();

            // Get credited tiers for this progress
            $creditedTiers = $progress->creditedTiers()->get();

            // Calculate detailed progress metrics
            $progressMetrics = $this->calculateProgressMetrics($progress, $offer);

            // Calculate current and next tier
            $currentTier = null;
            $nextTier = null;

            foreach ($offer->tiers as $tier) {
                if ($progress->current_earnings >= $tier->earnings_target) {
                    $currentTier = [
                        'tier_name' => $tier->tier_name,
                        'earnings_target' => (float) $tier->earnings_target,
                        'incentive_amount' => (float) $tier->incentive_amount,
                        'achieved' => true
                    ];
                } else if (!$nextTier) {
                    $nextTier = [
                        'tier_name' => $tier->tier_name,
                        'earnings_target' => (float) $tier->earnings_target,
                        'incentive_amount' => (float) $tier->incentive_amount,
                        'remaining_earnings' => (float) ($tier->earnings_target - $progress->current_earnings),
                        'progress_percentage' => round(($progress->current_earnings / $tier->earnings_target) * 100, 2)
                    ];
                }
            }

            return response()->json([
                'status' => true,
                'message' => 'Offer details retrieved successfully',
                'data' => [
                    'offer_id' => $offer->id,
                    'name' => $offer->name,
                    'description' => $offer->description,
                    'banner_image_url' => $offer->banner_image ? (str_starts_with($offer->banner_image, 'http') ? $offer->banner_image : asset('storage/' . $offer->banner_image)) : null,
                    'start_date' => Carbon::parse($offer->start_date)->toIso8601String(),
                    'end_date' => Carbon::parse($offer->end_date)->toIso8601String(),
                    'days_remaining' => Carbon::now()->diffInDays(Carbon::parse($offer->end_date), false),
                    'status' => $offer->status == 1 ? 'active' : 'inactive',
                    'conditions' => [
                        'min_gigs_required' => $offer->min_gigs_required,
                        'max_gigs_skip' => $offer->max_gigs_skip,
                        'max_orders_cancel' => $offer->max_orders_cancel,
                        'login_mandatory' => $offer->login_mandatory
                    ],
                    'my_progress' => [
                        'current_earnings' => $progressMetrics['current_earnings'],
                        'gigs_completed' => $progress->gigs_completed,
                        'gigs_skipped' => $progress->gigs_skipped,
                        'orders_cancelled' => $progress->orders_cancelled,
                        'is_eligible' => $progress->is_eligible,
                        'previous_target_amount' => $progressMetrics['previous_target_amount'],
                        'current_target_amount' => $progressMetrics['current_target_amount'],
                        'total_target_amount' => $progressMetrics['total_target_amount'],
                        'amount_needed' => $progressMetrics['amount_needed'],
                        'progress_percentage' => $progressMetrics['progress_percentage'],
                        'overall_progress_percentage' => $progressMetrics['overall_progress_percentage'],
                        'current_tier' => $currentTier,
                        'next_tier' => $nextTier,
                        'credited_tiers' => $creditedTiers->map(function ($credit) {
                            return [
                                'tier_id' => $credit->tier_id,
                                'incentive_amount' => (float) $credit->incentive_amount,
                                'credited_at' => $credit->credited_at->toIso8601String(),
                                'transaction_id' => $credit->transaction_id
                            ];
                        })->values(),
                        'total_credited_amount' => (float) $creditedTiers->sum('incentive_amount')
                    ],
                    'tiers' => collect([
                        // Starting tier from 0
                        [
                            'tier_name' => 'Start',
                            'earnings_target' => 0,
                            'incentive_amount' => 0,
                            'is_achieved' => true,
                            'order' => 0,
                            'percentage' => 0
                        ]
                    ])->merge(
                            $offer->tiers->map(function ($tier) use ($progress, $offer) {
                                // Calculate percentage of total (last tier is max target)
                                $maxTarget = $offer->tiers->last()->earnings_target;
                                $tierPercentage = $maxTarget > 0 ? round(((float) $tier->earnings_target / (float) $maxTarget) * 100, 2) : 0;

                                return [
                                    'tier_name' => $tier->tier_name,
                                    'earnings_target' => (float) $tier->earnings_target,
                                    'incentive_amount' => (float) $tier->incentive_amount,
                                    'is_achieved' => $progress->current_earnings >= $tier->earnings_target,
                                    'order' => $tier->order_number,
                                    'percentage' => $tierPercentage
                                ];
                            })
                        )->values()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get offer details', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update progress data from actual bookings and tracking
     */
    private function updateProgressData($deliveryBoyId, $offer, $progress)
    {
        $startDate = Carbon::parse($offer->start_date);
        $endDate = Carbon::parse($offer->end_date);

        // Get completed bookings within offer period
        $bookings = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoyId)
            ->where('booking_status', 'completed')
            ->whereHas('gigSlot', function ($q) use ($startDate, $endDate) {
                $q->whereBetween('slot_date', [$startDate->toDateString(), $endDate->toDateString()]);
            })
            ->get();

        // Calculate totals
        $totalEarnings = $bookings->sum('earnings');
        $gigsCompleted = $bookings->count();
        $ordersCancelled = $bookings->sum('orders_cancelled');

        // Update progress
        $progress->current_earnings = $totalEarnings;
        $progress->gigs_completed = $gigsCompleted;
        $progress->orders_cancelled = $ordersCancelled;

        // Check eligibility
        $isEligible = true;

        // Check min gigs requirement
        if ($gigsCompleted < $offer->min_gigs_required) {
            $isEligible = false;
        }

        // Check max cancellations
        if ($ordersCancelled > $offer->max_orders_cancel) {
            $isEligible = false;
        }

        // TODO: Check gigs_skipped and login_compliance when that logic is implemented

        $progress->is_eligible = $isEligible;

        // Calculate incentive earned (highest achieved tier)
        $incentiveEarned = 0;
        foreach ($offer->tiers as $tier) {
            if ($totalEarnings >= $tier->earnings_target && $isEligible) {
                $incentiveEarned = $tier->incentive_amount;
            }
        }
        $progress->incentive_earned = $incentiveEarned;

        $progress->save();
    }

    /**
     * Get eligibility status with detailed breakdown
     */
    private function getEligibilityStatus($progress, $offer)
    {
        $issues = [];

        if ($progress->gigs_completed < $offer->min_gigs_required) {
            $issues[] = "Complete " . ($offer->min_gigs_required - $progress->gigs_completed) . " more gigs";
        }

        if ($progress->gigs_skipped > $offer->max_gigs_skip) {
            $issues[] = "Too many gigs skipped (" . $progress->gigs_skipped . "/" . $offer->max_gigs_skip . ")";
        }

        if ($progress->orders_cancelled > $offer->max_orders_cancel) {
            $issues[] = "Too many orders cancelled (" . $progress->orders_cancelled . "/" . $offer->max_orders_cancel . ")";
        }

        if ($offer->login_mandatory && !$progress->login_compliance) {
            $issues[] = "Login compliance required";
        }

        if (empty($issues)) {
            return [
                'is_eligible' => true,
                'message' => 'You are eligible for this offer!',
                'issues' => []
            ];
        }

        return [
            'is_eligible' => false,
            'message' => 'Complete the requirements to become eligible',
            'issues' => $issues
        ];
    }

    /**
     * Get all offers (active, upcoming, and expired)
     *
     * GET /api/delivery_boy/all-offers
     */
    public function getAllOffers(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $now = now();
            $filter = $request->input('filter'); // daily, weekly, monthly
            $offset = (int) $request->input('offset', 0);
            $limit = (int) $request->input('limit', 10);

            // Determine date range based on filter
            $filterStart = null;
            $filterEnd = null;
            if ($filter === 'daily') {
                $filterStart = Carbon::today()->startOfDay();
                $filterEnd = Carbon::today()->endOfDay();
            } elseif ($filter === 'weekly') {
                $filterStart = Carbon::now()->startOfWeek();
                $filterEnd = Carbon::now()->endOfWeek();
            } elseif ($filter === 'monthly') {
                $filterStart = Carbon::now()->startOfMonth();
                $filterEnd = Carbon::now()->endOfMonth();
            }

            // Active offers query
            $activeQuery = IncentiveOffer::with('tiers')
                ->where('status', 1)
                ->where('start_date', '<=', $now)
                ->where('end_date', '>=', $now);

            if ($filterStart && $filterEnd) {
                // Offer overlaps with the filter period
                $activeQuery->where('start_date', '<=', $filterEnd)
                    ->where('end_date', '>=', $filterStart);
            }

            $activeOffers = $activeQuery->get();

            // Upcoming offers query
            $upcomingQuery = IncentiveOffer::with('tiers')
                ->where('status', 1)
                ->where('start_date', '>', $now);

            if ($filterStart && $filterEnd) {
                $upcomingQuery->where('start_date', '<=', $filterEnd)
                    ->where('start_date', '>=', $filterStart);
            }

            $upcomingOffers = $upcomingQuery->get();

            // Expired offers query with offset/limit pagination
            $expiredQuery = IncentiveOffer::with('tiers')
                ->where('end_date', '<', $now);

            if ($filterStart && $filterEnd) {
                $expiredQuery->where('end_date', '>=', $filterStart)
                    ->where('end_date', '<=', $filterEnd);
            }

            $totalExpired = $expiredQuery->count();

            $expiredOffers = $expiredQuery
                ->orderBy('end_date', 'desc')
                ->skip($offset)
                ->take($limit)
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'All offers retrieved successfully',
                'data' => [
                    'filter' => $filter ?? 'all',
                    'active' => $activeOffers->map(function ($offer) use ($deliveryBoy) {
                        return $this->formatOfferData($offer, $deliveryBoy);
                    }),
                    'upcoming' => $upcomingOffers->map(function ($offer) {
                        return [
                            'offer_id' => $offer->id,
                            'name' => $offer->name,
                            'description' => $offer->description,
                            'banner_image_url' => $offer->banner_image ? (str_starts_with($offer->banner_image, 'http') ? $offer->banner_image : asset('storage/' . $offer->banner_image)) : null,
                            'start_date' => $offer->start_date->toIso8601String(),
                            'end_date' => $offer->end_date->toIso8601String(),
                            'days_until_start' => now()->diffInDays($offer->start_date),
                            'conditions' => [
                                'min_gigs_required' => $offer->min_gigs_required,
                                'max_gigs_skip' => $offer->max_gigs_skip,
                                'max_orders_cancel' => $offer->max_orders_cancel,
                                'login_mandatory' => $offer->login_mandatory
                            ],
                            'tiers' => $offer->tiers->map(function ($tier) {
                                return [
                                    'tier_name' => $tier->tier_name,
                                    'earnings_target' => (float) $tier->earnings_target,
                                    'incentive_amount' => (float) $tier->incentive_amount,
                                    'order' => $tier->order_number
                                ];
                            })
                        ];
                    }),
                    'expired' => $expiredOffers->map(function ($offer) use ($deliveryBoy) {
                        $progress = DeliveryBoyIncentiveProgress::where('delivery_boy_id', $deliveryBoy->id)
                            ->where('incentive_offer_id', $offer->id)
                            ->first();

                        // Calculate achieved tier
                        $achievedTier = null;
                        if ($progress) {
                            foreach ($offer->tiers as $tier) {
                                if ($progress->current_earnings >= $tier->earnings_target) {
                                    $achievedTier = [
                                        'tier_name' => $tier->tier_name,
                                        'earnings_target' => (float) $tier->earnings_target,
                                        'incentive_amount' => (float) $tier->incentive_amount
                                    ];
                                }
                            }
                        }

                        return [
                            'offer_id' => $offer->id,
                            'name' => $offer->name,
                            'description' => $offer->description,
                            'banner_image_url' => $offer->banner_image ? (str_starts_with($offer->banner_image, 'http') ? $offer->banner_image : asset('storage/' . $offer->banner_image)) : null,
                            'start_date' => $offer->start_date->toIso8601String(),
                            'ended_at' => $offer->end_date->toIso8601String(),
                            'participated' => $progress !== null,
                            'my_performance' => $progress ? [
                                'earnings_achieved' => (float) $progress->current_earnings,
                                'gigs_completed' => $progress->gigs_completed,
                                'incentive_earned' => (float) $progress->incentive_earned,
                                'achieved_tier' => $achievedTier
                            ] : null,
                            'tiers' => $offer->tiers->map(function ($tier) use ($progress) {
                                return [
                                    'tier_name' => $tier->tier_name,
                                    'earnings_target' => (float) $tier->earnings_target,
                                    'incentive_amount' => (float) $tier->incentive_amount,
                                    'was_achieved' => $progress ? $progress->current_earnings >= $tier->earnings_target : false,
                                    'order' => $tier->order_number
                                ];
                            })
                        ];
                    }),
                    'pagination' => [
                        'total_expired' => $totalExpired,
                        'offset' => $offset,
                        'limit' => $limit,
                        'has_more' => ($offset + $limit) < $totalExpired
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get all offers', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }


    /**
     * Calculate detailed progress metrics for mobile app display
     */
    private function calculateProgressMetrics($progress, $offer)
    {
        $sortedTiers = $offer->tiers->sortBy('earnings_target')->values();
        $currentEarnings = (float) $progress->current_earnings;

        // Find previous tier (last tier with target <= current earnings)
        $previousTargetAmount = 0;
        $currentTargetAmount = 0;
        $nextTier = null;

        foreach ($sortedTiers as $tier) {
            if ($currentEarnings >= $tier->earnings_target) {
                $previousTargetAmount = (float) $tier->earnings_target;
            } else if (!$nextTier) {
                $nextTier = $tier;
                $currentTargetAmount = (float) $tier->earnings_target;
            }
        }

        // If no next tier, use last tier
        if (!$nextTier && $sortedTiers->count() > 0) {
            $currentTargetAmount = (float) $sortedTiers->last()->earnings_target;
        }

        // Calculate amount needed for next tier
        $amountNeeded = max(0, $currentTargetAmount - $currentEarnings);

        // Calculate progress percentage to next tier
        if ($currentTargetAmount > 0) {
            if ($previousTargetAmount == $currentTargetAmount) {
                // At or beyond last tier
                $progressPercentage = 100;
            } else {
                // Between tiers
                $rangeSize = $currentTargetAmount - $previousTargetAmount;
                $currentRangePosition = $currentEarnings - $previousTargetAmount;
                $progressPercentage = round(($currentRangePosition / $rangeSize) * 100, 2);
                $progressPercentage = min(100, max(0, $progressPercentage));
            }
        } else {
            $progressPercentage = 0;
        }

        // Calculate overall progress percentage (from 0 to last tier)
        $lastTier = $sortedTiers->last();
        $totalTargetAmount = $lastTier ? (float) $lastTier->earnings_target : 0;

        if ($totalTargetAmount > 0) {
            $overallProgressPercentage = round(($currentEarnings / $totalTargetAmount) * 100, 2);
            $overallProgressPercentage = min(100, $overallProgressPercentage);
        } else {
            $overallProgressPercentage = 0;
        }

        return [
            'current_earnings' => $currentEarnings,
            'previous_target_amount' => $previousTargetAmount,
            'current_target_amount' => $currentTargetAmount,
            'total_target_amount' => $totalTargetAmount,
            'amount_needed' => $amountNeeded,
            'progress_percentage' => $progressPercentage,
            'overall_progress_percentage' => $overallProgressPercentage
        ];
    }

    /**
     * Format offer data with progress
     */
    private function formatOfferData($offer, $deliveryBoy)
    {
        $progress = DeliveryBoyIncentiveProgress::firstOrCreate(
            [
                'delivery_boy_id' => $deliveryBoy->id,
                'incentive_offer_id' => $offer->id
            ],
            [
                'current_earnings' => 0,
                'gigs_completed' => 0,
                'gigs_skipped' => 0,
                'orders_cancelled' => 0,
                'login_compliance' => true,
                'is_eligible' => true,
                'incentive_earned' => 0,
                'status' => 'active'
            ]
        );

        // Calculate detailed progress metrics
        $progressMetrics = $this->calculateProgressMetrics($progress, $offer);

        $currentTier = null;
        $nextTier = null;

        foreach ($offer->tiers->sortBy('order_number') as $tier) {
            if ($progress->current_earnings >= $tier->earnings_target) {
                $currentTier = [
                    'tier_name' => $tier->tier_name,
                    'earnings_target' => (float) $tier->earnings_target,
                    'incentive_amount' => (float) $tier->incentive_amount,
                    'achieved' => true
                ];
            } else if (!$nextTier) {
                $nextTier = [
                    'tier_name' => $tier->tier_name,
                    'earnings_target' => (float) $tier->earnings_target,
                    'incentive_amount' => (float) $tier->incentive_amount,
                    'remaining_earnings' => (float) ($tier->earnings_target - $progress->current_earnings),
                    'progress_percentage' => round(($progress->current_earnings / $tier->earnings_target) * 100, 2)
                ];
            }
        }

        return [
            'offer_id' => $offer->id,
            'name' => $offer->name,
            'description' => $offer->description,
            'banner_image_url' => $offer->banner_image ? (str_starts_with($offer->banner_image, 'http') ? $offer->banner_image : asset('storage/' . $offer->banner_image)) : null,
            'start_date' => $offer->start_date->toIso8601String(),
            'end_date' => $offer->end_date->toIso8601String(),
            'days_remaining' => now()->diffInDays($offer->end_date, false),
            'conditions' => [
                'min_gigs_required' => $offer->min_gigs_required,
                'max_gigs_skip' => $offer->max_gigs_skip,
                'max_orders_cancel' => $offer->max_orders_cancel,
                'login_mandatory' => $offer->login_mandatory
            ],
            'my_progress' => [
                'current_earnings' => $progressMetrics['current_earnings'],
                'gigs_completed' => $progress->gigs_completed,
                'gigs_skipped' => $progress->gigs_skipped,
                'orders_cancelled' => $progress->orders_cancelled,
                'is_eligible' => $progress->is_eligible,
                'previous_target_amount' => $progressMetrics['previous_target_amount'],
                'current_target_amount' => $progressMetrics['current_target_amount'],
                'total_target_amount' => $progressMetrics['total_target_amount'],
                'amount_needed' => $progressMetrics['amount_needed'],
                'progress_percentage' => $progressMetrics['progress_percentage'],
                'overall_progress_percentage' => $progressMetrics['overall_progress_percentage'],
                'current_tier' => $currentTier,
                'next_tier' => $nextTier
            ],
            'tiers' => collect([
                // Starting tier from 0
                [
                    'tier_name' => 'Start',
                    'earnings_target' => 0,
                    'incentive_amount' => 0,
                    'is_achieved' => true,
                    'progress_percentage' => 100,
                    'order' => 0,
                    'percentage' => 0
                ]
            ])->merge(
                    $offer->tiers->sortBy('order_number')->map(function ($tier) use ($progress, $offer) {
                        // Calculate percentage of total (last tier is max target)
                        $maxTarget = $offer->tiers->last()->earnings_target;
                        $tierPercentage = $maxTarget > 0 ? round(((float) $tier->earnings_target / (float) $maxTarget) * 100, 2) : 0;

                        return [
                            'tier_name' => $tier->tier_name,
                            'earnings_target' => (float) $tier->earnings_target,
                            'incentive_amount' => (float) $tier->incentive_amount,
                            'is_achieved' => $progress->current_earnings >= $tier->earnings_target,
                            'progress_percentage' => round(min(($progress->current_earnings / $tier->earnings_target) * 100, 100), 2),
                            'order' => $tier->order_number,
                            'percentage' => $tierPercentage
                        ];
                    })
                )->values()
        ];
    }

}
