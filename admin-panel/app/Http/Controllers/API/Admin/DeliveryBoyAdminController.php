<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyDailyTracking;
use App\Models\DeliveryBoyGigBooking;
use App\Models\DeliveryBoyIncentiveProgress;
use App\Models\DeliveryBoySession;
use App\Models\Gig;
use App\Models\GigSlot;
use App\Models\IncentiveOffer;
use App\Models\IncentiveOfferTier;
use App\Models\Order;
use App\Models\OrderStatusList;
use App\Services\MediaUploadService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DeliveryBoyAdminController extends Controller
{
    /**
     * Get live tracking data for all delivery boys
     */
    public function getLiveTracking(Request $request)
    {
        try {
            $search = $request->get('search', '');
            $cityId = $request->get('city_id');
            $status = $request->get('status');

            // Build query
            $query = DeliveryBoy::with(['city', 'activeSessions' => function($q) {
                $q->whereNull('logout_at');
            }])
            ->where('status', 1); // Only active delivery boys

            // Apply filters
            if ($search) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('phone', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }

            if ($cityId) {
                $query->where('city_id', $cityId);
            }

            $deliveryBoys = $query->get();

            // Get today's tracking data
            $today = now()->toDateString();
            $trackingData = DeliveryBoyDailyTracking::whereDate('tracking_date', $today)
                ->get()
                ->keyBy('delivery_boy_id');

            // Format response data
            $formattedData = $deliveryBoys->map(function($deliveryBoy) use ($trackingData) {
                $tracking = $trackingData->get($deliveryBoy->id);
                $activeSession = $deliveryBoy->activeSessions->first();

                $isOnline = $activeSession !== null;
                $totalLoginHours = 0;
                $loginDisplayTime = '00:00';

                if ($tracking) {
                    $totalLoginHours = round($tracking->total_login_minutes / 60, 2);
                }

                // Calculate running clock if online
                if ($isOnline && $activeSession) {
                    $sessionMinutes = Carbon::parse($activeSession->login_at)->diffInMinutes(now());
                    $totalLoginHours += $sessionMinutes / 60;

                    // Format display time
                    $hours = floor($sessionMinutes / 60);
                    $minutes = $sessionMinutes % 60;
                    $loginDisplayTime = sprintf('%02d:%02d', $hours, $minutes);
                }

                return [
                    'id' => $deliveryBoy->id,
                    'name' => $deliveryBoy->name,
                    'phone' => $deliveryBoy->phone,
                    'profile_image_url' => $deliveryBoy->profile_image ? (str_starts_with($deliveryBoy->profile_image, 'http') ? $deliveryBoy->profile_image : asset('storage/' . $deliveryBoy->profile_image)) : null,
                    'city_name' => $deliveryBoy->city->name ?? 'N/A',
                    'online_status' => $isOnline ? 'online' : 'offline',
                    'login_display_time' => $loginDisplayTime,
                    'total_login_hours' => $totalLoginHours,
                    'total_earnings_today' => $tracking ? $tracking->total_earnings : 0,
                    'gigs_completed_today' => $tracking ? $tracking->gigs_completed : 0,
                    'total_distance_today' => $tracking ? $tracking->total_distance_km : 0,
                    'last_latitude' => $activeSession ? $activeSession->latitude_start : null,
                    'last_longitude' => $activeSession ? $activeSession->longitude_start : null,
                    'last_location_update' => $activeSession ? $activeSession->updated_at->toIso8601String() : null,
                    'session_duration' => $isOnline ? $loginDisplayTime : null
                ];
            });

            // Apply status filter after formatting
            if ($status) {
                $formattedData = $formattedData->filter(function($item) use ($status) {
                    return $item['online_status'] === $status;
                });
            }

            // Calculate stats
            $stats = [
                'online_count' => $formattedData->where('online_status', 'online')->count(),
                'total_earnings_today' => $formattedData->sum('total_earnings_today'),
                'gigs_completed_today' => $formattedData->sum('gigs_completed_today'),
                'total_distance_today' => $formattedData->sum('total_distance_today')
            ];

            return response()->json([
                'status' => true,
                'message' => 'Live tracking data retrieved successfully',
                'data' => [
                    'delivery_boys' => $formattedData->values(),
                    'stats' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get live tracking data', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get all gigs (admin)
     */
    public function getAllGigs(Request $request)
    {
        try {
            $gigs = Gig::withCount('slots')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Gigs retrieved successfully',
                'data' => [
                    'gigs' => $gigs->map(function($gig) {
                        // Count bookings through gig_slots
                        $bookingsCount = \DB::table('delivery_boy_gig_bookings')
                            ->join('gig_slots', 'delivery_boy_gig_bookings.gig_slot_id', '=', 'gig_slots.id')
                            ->where('gig_slots.gig_id', $gig->id)
                            ->count();

                        return [
                            'id' => $gig->id,
                            'gig_name' => $gig->display_name ?? $gig->name,
                            'description' => $gig->description,
                            'start_time' => $gig->start_time,
                            'end_time' => $gig->end_time,
                            'duration_hours' => $gig->duration_hours,
                            'base_earning' => (float) $gig->base_earnings,
                            'is_active' => $gig->status,
                            'slots_count' => $gig->slots_count,
                            'bookings_count' => $bookingsCount,
                            'created_at' => $gig->created_at->toIso8601String()
                        ];
                    })
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get gigs', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Create a new gig
     */
    public function createGig(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'gig_name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'start_time' => 'required|string',
                'end_time' => 'required|string',
                'base_earning' => 'required|numeric|min:0',
                'is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Parse time - accept both H:i and H:i:s formats
            $startTime = strlen($request->start_time) > 5 ? substr($request->start_time, 0, 5) : $request->start_time;
            $endTime = strlen($request->end_time) > 5 ? substr($request->end_time, 0, 5) : $request->end_time;

            // Calculate duration
            $start = Carbon::createFromFormat('H:i', $startTime);
            $end = Carbon::createFromFormat('H:i', $endTime);

            // Handle overnight shifts
            if ($end->lessThan($start)) {
                $end->addDay();
            }

            $durationHours = $start->diffInHours($end);

            $gig = Gig::create([
                'name' => strtolower(str_replace(' ', '_', $request->gig_name)),
                'display_name' => $request->gig_name,
                'description' => $request->description,
                'start_time' => $startTime . ':00',
                'end_time' => $endTime . ':00',
                'duration_hours' => $durationHours,
                'base_earnings' => $request->base_earning,
                'status' => $request->get('is_active', 1)
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Gig created successfully',
                'data' => ['gig' => $gig]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create gig', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get a single gig
     */
    public function getGig($id)
    {
        try {
            $gig = Gig::findOrFail($id);

            return response()->json([
                'status' => true,
                'message' => 'Gig retrieved successfully',
                'data' => [
                    'gig' => [
                        'id' => $gig->id,
                        'gig_name' => $gig->display_name ?? $gig->name,
                        'description' => $gig->description,
                        'start_time' => $gig->start_time,
                        'end_time' => $gig->end_time,
                        'duration_hours' => $gig->duration_hours,
                        'base_earning' => (float) $gig->base_earnings,
                        'is_active' => $gig->status,
                        'created_at' => $gig->created_at->toIso8601String()
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get gig', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update a gig
     */
    public function updateGig(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'gig_id' => 'required|exists:gigs,id',
                'gig_name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'start_time' => 'required|string',
                'end_time' => 'required|string',
                'base_earning' => 'required|numeric|min:0',
                'is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $gig = Gig::findOrFail($request->gig_id);

            // Parse time - accept both H:i and H:i:s formats
            $startTime = strlen($request->start_time) > 5 ? substr($request->start_time, 0, 5) : $request->start_time;
            $endTime = strlen($request->end_time) > 5 ? substr($request->end_time, 0, 5) : $request->end_time;

            // Calculate duration
            $start = Carbon::createFromFormat('H:i', $startTime);
            $end = Carbon::createFromFormat('H:i', $endTime);

            // Handle overnight shifts
            if ($end->lessThan($start)) {
                $end->addDay();
            }

            $durationHours = $start->diffInHours($end);

            $gig->update([
                'name' => strtolower(str_replace(' ', '_', $request->gig_name)),
                'display_name' => $request->gig_name,
                'description' => $request->description,
                'start_time' => $startTime . ':00',
                'end_time' => $endTime . ':00',
                'duration_hours' => $durationHours,
                'base_earnings' => $request->base_earning,
                'status' => $request->get('is_active', $gig->status)
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Gig updated successfully',
                'data' => ['gig' => $gig]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update gig', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete a gig
     */
    public function deleteGig(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'gig_id' => 'required|exists:gigs,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $gig = Gig::findOrFail($request->gig_id);

            // Check if gig has active bookings
            $activeBookingsCount = $gig->bookings()
                ->whereIn('booking_status', ['pending', 'confirmed', 'in_progress'])
                ->count();

            if ($activeBookingsCount > 0) {
                return CommonHelper::responseError('Cannot delete gig with active bookings');
            }

            $gig->delete();

            return response()->json([
                'status' => true,
                'message' => 'Gig deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to delete gig', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Create gig slots
     */
    public function createGigSlots(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'gig_id' => 'required|exists:gigs,id',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
                'capacity' => 'required|integer|min:1',
                'is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $gig = Gig::findOrFail($request->gig_id);
            $startDate = Carbon::parse($request->start_date);
            $endDate = Carbon::parse($request->end_date);
            $capacity = $request->capacity;
            $isActive = $request->get('is_active', true);

            $slotsCreated = 0;
            $currentDate = $startDate->copy();

            while ($currentDate->lte($endDate)) {
                // Check if slot already exists
                $existingSlot = GigSlot::where('gig_id', $gig->id)
                    ->where('slot_date', $currentDate->toDateString())
                    ->first();

                if (!$existingSlot) {
                    GigSlot::create([
                        'gig_id' => $gig->id,
                        'slot_date' => $currentDate->toDateString(),
                        'capacity' => $capacity,
                        'booked_count' => 0,
                        'is_active' => $isActive
                    ]);
                    $slotsCreated++;
                }

                $currentDate->addDay();
            }

            return response()->json([
                'status' => true,
                'message' => "{$slotsCreated} gig slots created successfully",
                'data' => [
                    'slots_created' => $slotsCreated
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create gig slots', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get all incentive offers (admin)
     */
    public function getAllOffers(Request $request)
    {
        try {
            $offers = IncentiveOffer::with('tiers')
                ->withCount('participants')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Offers retrieved successfully',
                'data' => [
                    'offers' => $offers->map(function($offer) {
                        $maxIncentive = $offer->tiers->max('incentive_amount') ?? 0;

                        return [
                            'id' => $offer->id,
                            'name' => $offer->name,
                            'description' => $offer->description,
                            'banner_image_url' => $offer->banner_image ?: null,
                            'start_date' => $offer->start_date->toIso8601String(),
                            'end_date' => $offer->end_date->toIso8601String(),
                            'status' => $offer->status,
                            'min_gigs_required' => $offer->min_gigs_required,
                            'max_gigs_skip' => $offer->max_gigs_skip,
                            'max_orders_cancel' => $offer->max_orders_cancel,
                            'login_mandatory' => $offer->login_mandatory,
                            'tiers_count' => $offer->tiers->count(),
                            'participants_count' => $offer->participants_count,
                            'enrolled_count' => $offer->participants_count,
                            'max_incentive' => (float) $maxIncentive,
                            'is_active' => $offer->start_date->lte(now()) && $offer->end_date->gte(now()),
                            'created_at' => $offer->created_at->toIso8601String()
                        ];
                    })
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get offers', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get single incentive offer by ID
     */
    public function getOffer(Request $request, $id)
    {
        try {
            $offer = IncentiveOffer::with('tiers')->findOrFail($id);

            // Add banner image URL (already a full S3 URL from MediaUploadService)
            $offer->banner_image_url = $offer->banner_image ?: null;

            return response()->json([
                'status' => true,
                'data' => ['offer' => $offer]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get offer', ['error' => $e->getMessage()]);
            return CommonHelper::responseError('Offer not found');
        }
    }

    /**
     * Create incentive offer
     */
    public function createOffer(Request $request)
    {
        try {
            // Parse tiers if sent as JSON string
            $tiers = $request->tiers;
            if (is_string($tiers)) {
                $tiers = json_decode($tiers, true);
                $request->merge(['tiers' => $tiers]);
            }

            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'banner_image' => 'nullable|image|max:2048',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after:start_date',
                'status' => 'required|boolean',
                'tiers' => 'required|array|min:1',
                'tiers.*.tier_name' => 'required|string',
                'tiers.*.earnings_target' => 'required|numeric|min:0',
                'tiers.*.incentive_amount' => 'required|numeric|min:0'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Handle banner image upload using MediaUploadService
            $bannerImageUrl = null;
            if ($request->hasFile('banner_image')) {
                $bannerImageUrl = MediaUploadService::upload(
                    $request->file('banner_image'),
                    'incentive_offers'
                );
            }

            // Create offer
            $offer = IncentiveOffer::create([
                'name' => $request->name,
                'description' => $request->description,
                'banner_image' => $bannerImageUrl,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'min_gigs_required' => $request->min_gigs_required ?? 0,
                'max_gigs_skip' => $request->max_gigs_skip ?? 0,
                'max_orders_cancel' => $request->max_orders_cancel ?? 0,
                'login_mandatory' => $request->login_mandatory ?? false,
                'status' => $request->status
            ]);

            // Create tiers
            foreach ($request->tiers as $index => $tierData) {
                IncentiveOfferTier::create([
                    'incentive_offer_id' => $offer->id,
                    'tier_name' => $tierData['tier_name'],
                    'earnings_target' => $tierData['earnings_target'],
                    'incentive_amount' => $tierData['incentive_amount'],
                    'order_number' => $tierData['order_number'] ?? ($index + 1)
                ]);
            }

            return response()->json([
                'status' => true,
                'message' => 'Offer created successfully',
                'data' => ['offer' => $offer->load('tiers')]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create offer', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update incentive offer
     */
    public function updateOffer(Request $request)
    {
        try {
            // Parse tiers if sent as JSON string
            $tiers = $request->tiers;
            if (is_string($tiers)) {
                $tiers = json_decode($tiers, true);
                $request->merge(['tiers' => $tiers]);
            }

            $validator = Validator::make($request->all(), [
                'offer_id' => 'required|exists:incentive_offers,id',
                'name' => 'required|string|max:255',
                'description' => 'nullable|string',
                'banner_image' => 'nullable|image|max:2048',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after:start_date',
                'status' => 'required|boolean',
                'tiers' => 'required|array|min:1',
                'tiers.*.tier_name' => 'required|string',
                'tiers.*.earnings_target' => 'required|numeric|min:0',
                'tiers.*.incentive_amount' => 'required|numeric|min:0'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $offer = IncentiveOffer::findOrFail($request->offer_id);

            // Handle banner image upload using MediaUploadService
            if ($request->hasFile('banner_image')) {
                $offer->banner_image = MediaUploadService::upload(
                    $request->file('banner_image'),
                    'incentive_offers',
                    'public',
                    $offer->banner_image // Pass old URL for deletion
                );
            }

            // Update offer
            $offer->update([
                'name' => $request->name,
                'description' => $request->description,
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
                'min_gigs_required' => $request->min_gigs_required ?? $offer->min_gigs_required,
                'max_gigs_skip' => $request->max_gigs_skip ?? $offer->max_gigs_skip,
                'max_orders_cancel' => $request->max_orders_cancel ?? $offer->max_orders_cancel,
                'login_mandatory' => $request->login_mandatory ?? $offer->login_mandatory,
                'status' => $request->status
            ]);

            // Delete existing tiers and create new ones
            $offer->tiers()->delete();
            foreach ($request->tiers as $index => $tierData) {
                IncentiveOfferTier::create([
                    'incentive_offer_id' => $offer->id,
                    'tier_name' => $tierData['tier_name'],
                    'earnings_target' => $tierData['earnings_target'],
                    'incentive_amount' => $tierData['incentive_amount'],
                    'order_number' => $index + 1
                ]);
            }

            return response()->json([
                'status' => true,
                'message' => 'Offer updated successfully',
                'data' => ['offer' => $offer->load('tiers')]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update offer', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update incentive offer status only
    */
    public function updateOfferStatus(Request $request)
    {
        try {

            $validator = Validator::make($request->all(), [
                'offer_id' => 'required|exists:incentive_offers,id',
                'status'   => 'required|boolean',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError(
                    $validator->errors()->first()
                );
            }

            $offer = IncentiveOffer::findOrFail($request->offer_id);

            $offer->update([
                'status' => $request->status
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Offer status updated successfully',
                'data' => [
                    'offer_id' => $offer->id,
                    'status' => $offer->status
                ]
            ]);

        } catch (\Exception $e) {

            Log::error('Offer status update failed', [
                'error' => $e->getMessage()
            ]);

            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete incentive offer
     */
    public function deleteOffer(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'offer_id' => 'required|exists:incentive_offers,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $offer = IncentiveOffer::findOrFail($request->offer_id);

            // Delete banner image using MediaUploadService
            if ($offer->banner_image) {
                MediaUploadService::deleteByUrl($offer->banner_image);
            }

            // Delete tiers and progress records
            $offer->tiers()->delete();
            $offer->progress()->delete();
            $offer->delete();

            return response()->json([
                'status' => true,
                'message' => 'Offer deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to delete offer', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Create multiple gig slots with custom timings
     */
    public function createMultipleGigSlots(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'gig_id' => 'required|exists:gigs,id',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after_or_equal:start_date',
                'slots' => 'required|array|min:1',
                'slots.*.name' => 'nullable|string|max:255',
                'slots.*.start_time' => 'required|string',
                'slots.*.end_time' => 'required|string',
                'slots.*.capacity' => 'required|integer|min:1',
                'slots.*.is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $gig = Gig::findOrFail($request->gig_id);
            $startDate = Carbon::parse($request->start_date);
            $endDate = Carbon::parse($request->end_date);
            $slotsData = $request->slots;

            $slotsCreated = 0;
            $currentDate = $startDate->copy();

            // Validate that all slot times are within gig's time range
            $gigStart = Carbon::parse($gig->start_time);
            $gigEnd = Carbon::parse($gig->end_time);

            foreach ($slotsData as $slotData) {
                $slotStart = Carbon::parse($slotData['start_time']);
                $slotEnd = Carbon::parse($slotData['end_time']);

                // Normalize times to just H:i for comparison
                if ($slotStart->format('H:i') < $gigStart->format('H:i') ||
                    $slotStart->format('H:i') > $gigEnd->format('H:i')) {
                    return CommonHelper::responseError("Slot '{$slotData['name']}' start time must be within gig timing ({$gig->start_time} - {$gig->end_time})");
                }

                if ($slotEnd->format('H:i') < $gigStart->format('H:i') ||
                    $slotEnd->format('H:i') > $gigEnd->format('H:i')) {
                    return CommonHelper::responseError("Slot '{$slotData['name']}' end time must be within gig timing ({$gig->start_time} - {$gig->end_time})");
                }

                if ($slotStart->format('H:i') >= $slotEnd->format('H:i')) {
                    return CommonHelper::responseError("Slot '{$slotData['name']}' start time must be before end time");
                }
            }

            // Create slots for each date in the range
            while ($currentDate->lte($endDate)) {
                // Check if ANY slots already exist for this gig on this date
                $existingSlotsCount = GigSlot::where('gig_id', $gig->id)
                    ->where('slot_date', $currentDate->toDateString())
                    ->count();

                // Skip this date if any slots already exist
                if ($existingSlotsCount > 0) {
                    $currentDate->addDay();
                    continue;
                }

                // Create all slots for this date
                foreach ($slotsData as $slotData) {
                    GigSlot::create([
                        'gig_id' => $gig->id,
                        'slot_date' => $currentDate->toDateString(),
                        'slot_name' => $slotData['name'],
                        'start_time' => $slotData['start_time'],
                        'end_time' => $slotData['end_time'],
                        'max_bookings' => $slotData['capacity'],
                        'current_bookings' => 0,
                        'status' => $slotData['is_active'] ?? 1
                    ]);
                    $slotsCreated++;
                }

                $currentDate->addDay();
            }

            return response()->json([
                'status' => true,
                'message' => "{$slotsCreated} gig slots created successfully",
                'data' => [
                    'slots_created' => $slotsCreated
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create multiple gig slots', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get gig slots
     */
    public function getGigSlots(Request $request)
    {
        try {
            $gigId = $request->get('gig_id');
            $fromDate = $request->get('from_date');
            $toDate = $request->get('to_date');

            $query = GigSlot::with('gig');

            if ($gigId) {
                $query->where('gig_id', $gigId);
            }

            if ($fromDate) {
                $query->where('slot_date', '>=', $fromDate);
            }

            if ($toDate) {
                $query->where('slot_date', '<=', $toDate);
            }

            $slots = $query->orderBy('slot_date', 'asc')->get();

            return response()->json([
                'status' => true,
                'message' => 'Slots retrieved successfully',
                'data' => [
                    'slots' => $slots
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get gig slots', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update gig slot
     */
    public function updateGigSlot(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'slot_id' => 'required|exists:gig_slots,id',
                'capacity' => 'required|integer|min:1',
                'is_active' => 'boolean'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $slot = GigSlot::findOrFail($request->slot_id);

            // Cannot reduce capacity below booked count
            if ($request->capacity < $slot->booked_count) {
                return CommonHelper::responseError('Cannot set capacity below current bookings count');
            }

            $slot->update([
                'capacity' => $request->capacity,
                'is_active' => $request->get('is_active', $slot->is_active)
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Slot updated successfully',
                'data' => ['slot' => $slot]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update gig slot', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get slot bookings
     */
    public function getSlotBookings(Request $request)
    {
        try {
            $slotId = $request->get('slot_id');

            if (!$slotId) {
                return CommonHelper::responseError('Slot ID is required');
            }

            $bookings = DeliveryBoyGigBooking::with(['deliveryBoy'])
                ->where('gig_slot_id', $slotId)
                ->orderBy('booked_at', 'desc')
                ->get();

            return response()->json([
                'status' => true,
                'message' => 'Slot bookings retrieved successfully',
                'data' => [
                    'bookings' => $bookings->map(function($booking) {
                        return [
                            'id' => $booking->id,
                            'delivery_boy' => [
                                'id' => $booking->deliveryBoy->id,
                                'name' => $booking->deliveryBoy->name,
                                'phone' => $booking->deliveryBoy->phone,
                                'profile_image_url' => $booking->deliveryBoy->profile_image ? (str_starts_with($booking->deliveryBoy->profile_image, 'http') ? $booking->deliveryBoy->profile_image : asset('storage/' . $booking->deliveryBoy->profile_image)) : null
                            ],
                            'booking_status' => $booking->booking_status,
                            'booked_at' => $booking->booked_at ? $booking->booked_at->toIso8601String() : null,
                            'started_at' => $booking->started_at ? $booking->started_at->toIso8601String() : null,
                            'completed_at' => $booking->completed_at ? $booking->completed_at->toIso8601String() : null,
                            'orders_completed' => $booking->orders_completed,
                            'earnings_amount' => (float) $booking->earnings_amount
                        ];
                    })
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get slot bookings', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get all bookings
     */
    public function getAllBookings(Request $request)
    {
        try {
            $search = $request->get('search', '');
            $gigId = $request->get('gig_id');
            $status = $request->get('status');
            $fromDate = $request->get('from_date');
            $toDate = $request->get('to_date');

            $query = DeliveryBoyGigBooking::with(['deliveryBoy', 'gigSlot.gig']);

            // Apply filters
            if ($search) {
                $query->whereHas('deliveryBoy', function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('phone', 'like', "%{$search}%");
                });
            }

            if ($gigId) {
                $query->whereHas('gigSlot', function($q) use ($gigId) {
                    $q->where('gig_id', $gigId);
                });
            }

            if ($status) {
                $query->where('booking_status', $status);
            }

            if ($fromDate) {
                $query->whereHas('gigSlot', function($q) use ($fromDate) {
                    $q->where('slot_date', '>=', $fromDate);
                });
            }

            if ($toDate) {
                $query->whereHas('gigSlot', function($q) use ($toDate) {
                    $q->where('slot_date', '<=', $toDate);
                });
            }

            $bookings = $query->orderBy('booked_at', 'desc')->get();

            // Calculate stats
            $today = now()->toDateString();
            $stats = [
                'total_bookings' => $bookings->count(),
                'active_today' => DeliveryBoyGigBooking::whereHas('gigSlot', function($q) use ($today) {
                    $q->where('slot_date', $today);
                })->where('booking_status', 'active')->count(),
                'completed_today' => DeliveryBoyGigBooking::whereHas('gigSlot', function($q) use ($today) {
                    $q->where('slot_date', $today);
                })->where('booking_status', 'completed')->count(),
                'total_earnings' => $bookings->sum('earnings_amount')
            ];

            return response()->json([
                'status' => true,
                'message' => 'Bookings retrieved successfully',
                'data' => [
                    'bookings' => $bookings->map(function($booking) {
                        return [
                            'id' => $booking->id,
                            'delivery_boy' => [
                                'id' => $booking->deliveryBoy->id,
                                'name' => $booking->deliveryBoy->name,
                                'phone' => $booking->deliveryBoy->phone,
                                'profile_image_url' => $booking->deliveryBoy->profile_image ? (str_starts_with($booking->deliveryBoy->profile_image, 'http') ? $booking->deliveryBoy->profile_image : asset('storage/' . $booking->deliveryBoy->profile_image)) : null,
                                'city_name' => $booking->deliveryBoy->city->name ?? 'N/A'
                            ],
                            'gig_slot' => [
                                'id' => $booking->gigSlot->id,
                                'slot_date' => $booking->gigSlot->slot_date,
                                'gig' => [
                                    'id' => $booking->gigSlot->gig->id,
                                    'gig_name' => $booking->gigSlot->gig->gig_name,
                                    'start_time' => $booking->gigSlot->gig->start_time,
                                    'end_time' => $booking->gigSlot->gig->end_time,
                                    'base_earning' => (float) $booking->gigSlot->gig->base_earning
                                ]
                            ],
                            'booking_status' => $booking->booking_status,
                            'booked_at' => $booking->booked_at ? $booking->booked_at->toIso8601String() : null,
                            'started_at' => $booking->started_at ? $booking->started_at->toIso8601String() : null,
                            'completed_at' => $booking->completed_at ? $booking->completed_at->toIso8601String() : null,
                            'cancelled_at' => $booking->cancelled_at ? $booking->cancelled_at->toIso8601String() : null,
                            'cancellation_reason' => $booking->cancellation_reason,
                            'orders_completed' => $booking->orders_completed,
                            'earnings_amount' => (float) $booking->earnings_amount,
                            'actual_login_hours' => $booking->actual_login_hours ? (float) $booking->actual_login_hours : null
                        ];
                    }),
                    'stats' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get all bookings', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Cancel booking
     */
    public function cancelBooking(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'booking_id' => 'required|exists:delivery_boy_gig_bookings,id',
                'cancellation_reason' => 'required|string'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $booking = DeliveryBoyGigBooking::with('gigSlot')->findOrFail($request->booking_id);

            if ($booking->booking_status !== 'booked') {
                return CommonHelper::responseError('Only booked slots can be cancelled');
            }

            $booking->update([
                'booking_status' => 'cancelled',
                'cancelled_at' => now(),
                'cancellation_reason' => $request->cancellation_reason
            ]);

            // Decrease booked count in slot
            $slot = $booking->gigSlot;
            $slot->decrement('booked_count');

            return response()->json([
                'status' => true,
                'message' => 'Booking cancelled successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to cancel booking', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Export bookings
     */
    public function exportBookings(Request $request)
    {
        try {
            // This is a placeholder - implement actual Excel export using Laravel Excel package
            return CommonHelper::responseError('Export functionality not yet implemented');

        } catch (\Exception $e) {
            Log::error('Failed to export bookings', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Export live tracking
     */
    public function exportLiveTracking(Request $request)
    {
        try {
            // This is a placeholder - implement actual Excel export using Laravel Excel package
            return CommonHelper::responseError('Export functionality not yet implemented');

        } catch (\Exception $e) {
            Log::error('Failed to export live tracking', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get all payouts
     */
    public function getAllPayouts(Request $request)
    {
        try {
            $search = $request->get('search', '');
            $offerId = $request->get('offer_id');
            $status = $request->get('status');
            $fromDate = $request->get('from_date');
            $toDate = $request->get('to_date');

            $query = DeliveryBoyIncentiveProgress::with(['deliveryBoy', 'incentiveOffer', 'achievedTier']);

            // Only show completed and eligible for payout
            $query->where('is_completed', true)
                  ->where('is_eligible', true);

            // Apply filters
            if ($search) {
                $query->whereHas('deliveryBoy', function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('phone', 'like', "%{$search}%");
                });
            }

            if ($offerId) {
                $query->where('incentive_offer_id', $offerId);
            }

            if ($status) {
                $query->where('payout_status', $status);
            }

            if ($fromDate) {
                $query->where('updated_at', '>=', $fromDate);
            }

            if ($toDate) {
                $query->where('updated_at', '<=', $toDate);
            }

            $payouts = $query->orderBy('updated_at', 'desc')->get();

            // Calculate stats
            $stats = [
                'total_payouts' => $payouts->count(),
                'pending_amount' => $payouts->where('payout_status', 'pending')->sum('payout_amount'),
                'processed_amount' => $payouts->where('payout_status', 'processed')->sum('payout_amount'),
                'total_amount' => $payouts->sum('payout_amount')
            ];

            return response()->json([
                'status' => true,
                'message' => 'Payouts retrieved successfully',
                'data' => [
                    'payouts' => $payouts->map(function($payout) {
                        return [
                            'id' => $payout->id,
                            'delivery_boy' => [
                                'id' => $payout->deliveryBoy->id,
                                'name' => $payout->deliveryBoy->name,
                                'phone' => $payout->deliveryBoy->phone,
                                'profile_image_url' => $payout->deliveryBoy->profile_image ? (str_starts_with($payout->deliveryBoy->profile_image, 'http') ? $payout->deliveryBoy->profile_image : asset('storage/' . $payout->deliveryBoy->profile_image)) : null
                            ],
                            'incentive_offer' => [
                                'id' => $payout->incentiveOffer->id,
                                'name' => $payout->incentiveOffer->name,
                                'start_date' => $payout->incentiveOffer->start_date,
                                'end_date' => $payout->incentiveOffer->end_date
                            ],
                            'achieved_tier' => $payout->achievedTier ? [
                                'id' => $payout->achievedTier->id,
                                'tier_name' => $payout->achievedTier->tier_name,
                                'earnings_target' => (float) $payout->achievedTier->earnings_target,
                                'incentive_amount' => (float) $payout->achievedTier->incentive_amount
                            ] : null,
                            'current_earnings' => (float) $payout->current_earnings,
                            'gigs_completed' => $payout->gigs_completed,
                            'incentive_earned' => (float) $payout->incentive_earned,
                            'payout_amount' => (float) $payout->payout_amount,
                            'payout_status' => $payout->payout_status,
                            'is_eligible' => $payout->is_eligible,
                            'completed_at' => $payout->completed_at ? $payout->completed_at->toIso8601String() : null,
                            'payout_processed_at' => $payout->payout_processed_at ? $payout->payout_processed_at->toIso8601String() : null
                        ];
                    }),
                    'stats' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get payouts', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Process payout
     */
    public function processPayout(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'progress_id' => 'required|exists:delivery_boy_incentive_progress,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $progress = DeliveryBoyIncentiveProgress::findOrFail($request->progress_id);

            if ($progress->payout_status === 'processed') {
                return CommonHelper::responseError('Payout already processed');
            }

            $progress->update([
                'payout_status' => 'processed',
                'payout_processed_at' => now()
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Payout processed successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to process payout', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Export payouts
     */
    public function exportPayouts(Request $request)
    {
        try {
            // This is a placeholder - implement actual Excel export using Laravel Excel package
            return CommonHelper::responseError('Export functionality not yet implemented');

        } catch (\Exception $e) {
            Log::error('Failed to export payouts', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get session history
     */
    public function getSessions(Request $request)
    {
        try {
            $search = $request->get('search', '');
            $cityId = $request->get('city_id');
            $fromDate = $request->get('from_date');
            $toDate = $request->get('to_date');

            $query = DeliveryBoySession::with(['deliveryBoy.city', 'gigBooking']);

            // Apply filters
            if ($search) {
                $query->whereHas('deliveryBoy', function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('phone', 'like', "%{$search}%");
                });
            }

            if ($cityId) {
                $query->whereHas('deliveryBoy', function($q) use ($cityId) {
                    $q->where('city_id', $cityId);
                });
            }

            if ($fromDate) {
                $query->where('login_at', '>=', $fromDate);
            }

            if ($toDate) {
                $query->where('login_at', '<=', $toDate . ' 23:59:59');
            }

            $sessions = $query->orderBy('login_at', 'desc')->get();

            // Calculate stats
            $totalSessions = $sessions->count();
            $totalMinutes = $sessions->sum('duration_minutes');
            $totalHours = round($totalMinutes / 60, 2);
            $avgDuration = $totalSessions > 0 ? round($totalMinutes / $totalSessions) : 0;

            $activeToday = DeliveryBoySession::whereDate('login_at', now()->toDateString())
                ->whereNull('logout_at')
                ->count();

            $stats = [
                'total_sessions' => $totalSessions,
                'total_hours' => $totalHours,
                'avg_session_duration' => floor($avgDuration / 60) . 'h ' . ($avgDuration % 60) . 'm',
                'active_today' => $activeToday
            ];

            return response()->json([
                'status' => true,
                'message' => 'Sessions retrieved successfully',
                'data' => [
                    'sessions' => $sessions->map(function($session) {
                        return [
                            'id' => $session->id,
                            'delivery_boy' => [
                                'id' => $session->deliveryBoy->id,
                                'name' => $session->deliveryBoy->name,
                                'phone' => $session->deliveryBoy->phone,
                                'profile_image_url' => $session->deliveryBoy->profile_image ? (str_starts_with($session->deliveryBoy->profile_image, 'http') ? $session->deliveryBoy->profile_image : asset('storage/' . $session->deliveryBoy->profile_image)) : null
                            ],
                            'login_at' => $session->login_at ? $session->login_at->toIso8601String() : null,
                            'logout_at' => $session->logout_at ? $session->logout_at->toIso8601String() : null,
                            'duration_minutes' => $session->duration_minutes,
                            'login_latitude' => $session->latitude_start,
                            'login_longitude' => $session->longitude_start,
                            'orders_delivered' => $session->gigBooking ? $session->gigBooking->orders_completed : 0,
                            'earnings' => $session->gigBooking ? (float) $session->gigBooking->earnings : 0
                        ];
                    }),
                    'stats' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get sessions', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Export sessions
     */
    public function exportSessions(Request $request)
    {
        try {
            // This is a placeholder - implement actual Excel export using Laravel Excel package
            return CommonHelper::responseError('Export functionality not yet implemented');

        } catch (\Exception $e) {
            Log::error('Failed to export sessions', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get daily reports - fetches from orders table grouped by delivery boy and date
     */
    public function getDailyReports(Request $request)
    {
        try {
            $search = $request->get('search', '');
            $cityId = $request->get('city_id');
            $fromDate = $request->get('from_date', Carbon::now()->subDays(7)->format('Y-m-d'));
            $toDate = $request->get('to_date', Carbon::now()->format('Y-m-d'));

            // Build query to get daily reports from orders table
            // Using delivery_charge as earnings since driver_earnings is in delivery_boy_transactions table
            $query = Order::select(
                    'delivery_boy_id',
                    DB::raw('DATE(updated_at) as order_date'),
                    DB::raw('COUNT(*) as total_orders'),
                    DB::raw('SUM(CASE WHEN active_status = ' . OrderStatusList::$delivered . ' THEN 1 ELSE 0 END) as orders_delivered'),
                    DB::raw('SUM(CASE WHEN active_status = ' . OrderStatusList::$cancelled . ' THEN 1 ELSE 0 END) as orders_cancelled'),
                    DB::raw('SUM(CASE WHEN active_status = ' . OrderStatusList::$delivered . ' THEN COALESCE(delivery_charge, 0) ELSE 0 END) as total_earnings')
                )
                ->whereNotNull('delivery_boy_id')
                ->whereBetween(DB::raw('DATE(updated_at)'), [$fromDate, $toDate])
                ->groupBy('delivery_boy_id', DB::raw('DATE(updated_at)'));

            // Apply search filter
            if ($search) {
                $query->whereHas('deliveryBoy', function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('phone', 'like', "%{$search}%");
                });
            }

            // Apply city filter
            if ($cityId) {
                $query->whereHas('deliveryBoy', function($q) use ($cityId) {
                    $q->where('city_id', $cityId);
                });
            }

            $dailyData = $query->orderBy('order_date', 'desc')->get();

            // Get delivery boy details
            $deliveryBoyIds = $dailyData->pluck('delivery_boy_id')->unique();
            $deliveryBoys = DeliveryBoy::with('city')
                ->whereIn('id', $deliveryBoyIds)
                ->get()
                ->keyBy('id');

            // Format reports
            $reports = $dailyData->map(function($row) use ($deliveryBoys) {
                $deliveryBoy = $deliveryBoys->get($row->delivery_boy_id);
                if (!$deliveryBoy) return null;

                return [
                    'id' => $row->delivery_boy_id . '_' . $row->order_date,
                    'delivery_boy' => [
                        'id' => $deliveryBoy->id,
                        'name' => $deliveryBoy->name,
                        'phone' => $deliveryBoy->phone,
                        'profile_image_url' => $deliveryBoy->profile_image_url,
                        'city_name' => $deliveryBoy->city->name ?? 'N/A'
                    ],
                    'date' => $row->order_date,
                    'total_orders' => (int) $row->total_orders,
                    'orders_delivered' => (int) $row->orders_delivered,
                    'orders_cancelled' => (int) $row->orders_cancelled,
                    'total_earnings' => (float) $row->total_earnings
                ];
            })->filter()->values();

            // Calculate stats
            $stats = [
                'total_earnings' => round($reports->sum('total_earnings'), 2),
                'total_orders' => $reports->sum('total_orders'),
                'total_delivered' => $reports->sum('orders_delivered'),
                'total_cancelled' => $reports->sum('orders_cancelled')
            ];

            return response()->json([
                'status' => true,
                'message' => 'Daily reports retrieved successfully',
                'data' => [
                    'reports' => $reports,
                    'stats' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get daily reports', ['error' => $e->getMessage(), 'trace' => $e->getTraceAsString()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Export reports
     */
    public function exportReports(Request $request)
    {
        try {
            // This is a placeholder - implement actual Excel export using Laravel Excel package
            return CommonHelper::responseError('Export functionality not yet implemented');

        } catch (\Exception $e) {
            Log::error('Failed to export reports', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get partner progress
     */
    public function getPartnerProgress(Request $request)
    {
        try {
            $search = $request->get('search', '');
            $offerId = $request->get('offer_id');
            $status = $request->get('status');

            $query = DeliveryBoyIncentiveProgress::with(['deliveryBoy.city', 'incentiveOffer.tiers']);

            // Apply filters
            if ($search) {
                $query->whereHas('deliveryBoy', function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('phone', 'like', "%{$search}%");
                });
            }

            if ($offerId) {
                $query->where('incentive_offer_id', $offerId);
            }

            if ($status === 'eligible') {
                $query->where('is_eligible', true);
            } elseif ($status === 'not_eligible') {
                $query->where('is_eligible', false);
            }

            $progressList = $query->get();

            // Calculate stats
            $stats = [
                'total_participants' => $progressList->count(),
                'eligible_count' => $progressList->where('is_eligible', true)->count(),
                'in_progress_count' => $progressList->where('is_completed', false)->count(),
                'total_potential_payout' => $progressList->where('is_eligible', true)->sum('payout_amount')
            ];

            return response()->json([
                'status' => true,
                'message' => 'Partner progress retrieved successfully',
                'data' => [
                    'progress' => $progressList->map(function($progress) {
                        // Get current tier
                        $currentTier = null;
                        $nextTier = null;

                        if ($progress->incentiveOffer && $progress->incentiveOffer->tiers) {
                            $currentTier = $progress->incentiveOffer->tiers()
                                ->where('earnings_target', '<=', $progress->current_earnings)
                                ->orderBy('earnings_target', 'desc')
                                ->first();

                            $nextTier = $progress->incentiveOffer->tiers()
                                ->where('earnings_target', '>', $progress->current_earnings)
                                ->orderBy('earnings_target', 'asc')
                                ->first();
                        }

                        return [
                            'id' => $progress->id,
                            'delivery_boy' => [
                                'id' => $progress->deliveryBoy->id,
                                'name' => $progress->deliveryBoy->name,
                                'phone' => $progress->deliveryBoy->phone,
                                'profile_image_url' => $progress->deliveryBoy->profile_image ? (str_starts_with($progress->deliveryBoy->profile_image, 'http') ? $progress->deliveryBoy->profile_image : asset('storage/' . $progress->deliveryBoy->profile_image)) : null,
                                'city_name' => $progress->deliveryBoy->city->name ?? 'N/A'
                            ],
                            'incentive_offer' => [
                                'id' => $progress->incentiveOffer->id,
                                'name' => $progress->incentiveOffer->name,
                                'start_date' => $progress->incentiveOffer->start_date->toIso8601String(),
                                'end_date' => $progress->incentiveOffer->end_date->toIso8601String(),
                                'min_gigs_required' => $progress->incentiveOffer->min_gigs_required,
                                'max_gigs_skip' => $progress->incentiveOffer->max_gigs_skip,
                                'max_orders_cancel' => $progress->incentiveOffer->max_orders_cancel,
                                'login_mandatory' => $progress->incentiveOffer->login_mandatory
                            ],
                            'current_earnings' => (float) $progress->current_earnings,
                            'gigs_completed' => $progress->gigs_completed,
                            'gigs_skipped' => $progress->gigs_skipped,
                            'orders_cancelled' => $progress->orders_cancelled,
                            'login_compliance' => $progress->login_compliance,
                            'is_eligible' => $progress->is_eligible,
                            'current_tier' => $currentTier ? [
                                'tier_name' => $currentTier->tier_name,
                                'reward_amount' => (float) $currentTier->incentive_amount
                            ] : null,
                            'next_tier' => $nextTier ? [
                                'tier_name' => $nextTier->tier_name,
                                'earnings_target' => (float) $nextTier->earnings_target,
                                'reward_amount' => (float) $nextTier->incentive_amount
                            ] : null
                        ];
                    }),
                    'stats' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get partner progress', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Export progress
     */
    public function exportProgress(Request $request)
    {
        try {
            // This is a placeholder - implement actual Excel export using Laravel Excel package
            return CommonHelper::responseError('Export functionality not yet implemented');

        } catch (\Exception $e) {
            Log::error('Failed to export progress', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get active offers
     */
    public function getActiveOffers(Request $request)
    {
        try {
            $offers = IncentiveOffer::with('tiers')
                ->withCount('participants')
                ->active()
                ->orderBy('created_at', 'desc')
                ->get();

            // Calculate stats
            $stats = [
                'active_offers' => $offers->count(),
                'total_participants' => $offers->sum('participants_count'),
                'eligible_partners' => DeliveryBoyIncentiveProgress::where('is_eligible', true)->count(),
                'total_rewards_pool' => $offers->sum(function($offer) {
                    return $offer->tiers->sum('incentive_amount');
                })
            ];

            return response()->json([
                'status' => true,
                'message' => 'Active offers retrieved successfully',
                'data' => [
                    'offers' => $offers->map(function($offer) {
                        return [
                            'id' => $offer->id,
                            'name' => $offer->name,
                            'description' => $offer->description,
                            'banner_image_url' => $offer->banner_image_url,
                            'start_date' => $offer->start_date->toIso8601String(),
                            'end_date' => $offer->end_date->toIso8601String(),
                            'min_gigs_required' => $offer->min_gigs_required,
                            'max_gigs_skip' => $offer->max_gigs_skip,
                            'max_orders_cancel' => $offer->max_orders_cancel,
                            'login_mandatory' => $offer->login_mandatory,
                            'participants_count' => $offer->participants_count,
                            'tiers' => $offer->tiers->map(function($tier) {
                                return [
                                    'id' => $tier->id,
                                    'tier_name' => $tier->tier_name,
                                    'earnings_target' => (float) $tier->earnings_target,
                                    'reward_amount' => (float) $tier->incentive_amount,
                                    'order_number' => $tier->order_number
                                ];
                            })
                        ];
                    }),
                    'stats' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get active offers', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
