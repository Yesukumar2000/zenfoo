<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Helpers\FirebaseHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\Gig;
use App\Models\GigSlot;
use App\Models\DeliveryBoyGigBooking;
use App\Models\DeliveryBoyDailyTracking;
use App\Models\DeliveryBoyNotification;
use App\Models\AdminToken;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class GigManagementController extends Controller
{
    /**
     * Auto-complete past bookings that are still in 'booked' status
     */
    private function autoCompletePastBookings($deliveryBoyId)
    {
        $today = Carbon::today()->toDateString();

        $bookingsToComplete = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoyId)
            ->where('booking_status', 'booked')
            ->whereHas('gigSlot', function ($q) use ($today) {
                $q->where('slot_date', '<', $today);
            })
            ->with(['gigSlot.gig'])
            ->get();

        $updatedCount = 0;

        foreach ($bookingsToComplete as $booking) {
            $booking->booking_status = 'completed';
            // Set ended_at to the slot's end time on that date
            $slotDate = Carbon::parse($booking->gigSlot->slot_date)->toDateString();
            $slotEndTime = $booking->gigSlot->end_time;
            $booking->ended_at = Carbon::parse($slotDate . ' ' . $slotEndTime);
            $booking->save();

            $updatedCount++;

            // Send notification for completed slot
            $this->sendSlotCompletedNotification($deliveryBoyId, $booking);
        }

        if ($updatedCount > 0) {
            Log::info('Auto-completed past bookings', [
                'delivery_boy_id' => $deliveryBoyId,
                'updated_count' => $updatedCount
            ]);
        }

        return $updatedCount;
    }

    /**
     * Send notification when a slot is auto-completed
     */
    private function sendSlotCompletedNotification($deliveryBoyId, $booking)
    {
        try {
            $gigName = $booking->gigSlot->gig->display_name ?? $booking->gigSlot->gig->name;
            $slotName = $booking->gigSlot->slot_name;
            $slotDate = Carbon::parse($booking->gigSlot->slot_date)->format('d M Y');

            $title = 'Gig Slot Completed';
            $message = "Your {$gigName} slot ({$slotName}) on {$slotDate} has been completed.";

            // Save notification to database
            DeliveryBoyNotification::create([
                'delivery_boy_id' => $deliveryBoyId,
                'title' => $title,
                'message' => $message,
                'type' => 'gig_completed',
                'order_item_id' => null
            ]);

            // Send push notification
            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            if ($deliveryBoy && $deliveryBoy->admin_id) {
                $adminToken = AdminToken::where('user_id', $deliveryBoy->admin_id)
                    ->where('type', Role::$roleNameDeliveryBoy)
                    ->first();

                if ($adminToken && $adminToken->fcm_token) {
                    $fcmData = [
                        'title' => $title,
                        'body' => $message,
                        'type' => 'gig_completed',
                        'gig_slot_id' => $booking->gig_slot_id,
                        'booking_id' => $booking->id
                    ];

                    FirebaseHelper::send(
                        $adminToken->platform ?? 'android',
                        $adminToken->fcm_token,
                        $fcmData,
                        []
                    );

                    Log::info('Sent gig completion notification', [
                        'delivery_boy_id' => $deliveryBoyId,
                        'booking_id' => $booking->id
                    ]);
                }
            }
        } catch (\Exception $e) {
            Log::error('Failed to send gig completion notification', [
                'delivery_boy_id' => $deliveryBoyId,
                'booking_id' => $booking->id,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Get available gigs
     *
     * GET /api/delivery_boy/gigs/available
     * Query: date (optional, defaults to today)
     */
    public function getAvailableGigs(Request $request)
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

            // Auto-complete past bookings
            $this->autoCompletePastBookings($deliveryBoy->id);

            $date = $request->input('date', Carbon::today()->toDateString());

            // Get all active gigs
            $gigs = Gig::active()->get();

            $gigData = [];
            foreach ($gigs as $gig) {
                // Get all slots for this gig on the specified date
                $slots = GigSlot::where('gig_id', $gig->id)
                    ->where('slot_date', $date)
                    ->where('status', 1)
                    ->orderBy('slot_number', 'asc')
                    ->get();

                if ($slots->isEmpty()) {
                    continue;
                }

                // Process each slot for this gig
                $slotData = [];
                $currentDateTime = Carbon::now();

                foreach ($slots as $slot) {
                    // Check if delivery boy already booked this slot
                    $booking = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoy->id)
                        ->where('gig_slot_id', $slot->id)
                        ->first();

                    // Check if slot time has passed
                    // Extract just the date part from slot_date if it contains time
                    $slotDateOnly = Carbon::parse($slot->slot_date)->format('Y-m-d');
                    $slotDateTime = Carbon::parse($slotDateOnly . ' ' . $slot->start_time);
                    $isPastSlot = $slotDateTime->lt($currentDateTime);

                    $isAvailable = $slot->current_bookings < $slot->max_bookings;
                    $isBooked = $booking !== null;

                    $slotData[] = [
                        'slot_id' => $slot->id,
                        'slot_number' => $slot->slot_number,
                        'slot_name' => $slot->slot_name ?? "Slot {$slot->slot_number}",
                        'slot_date' => $slot->slot_date,
                        'start_time' => $slot->start_time,
                        'end_time' => $slot->end_time,
                        'available_slots' => $slot->max_bookings - $slot->current_bookings,
                        'total_slots' => $slot->max_bookings,
                        'is_available' => $isAvailable && !$isBooked && !$isPastSlot,
                        'is_booked' => $isBooked,
                        'is_past' => $isPastSlot,
                        'booking_status' => $isBooked ? $booking->booking_status : null,
                        'booking_id' => $isBooked ? $booking->id : null,
                    ];
                }

                $gigData[] = [
                    'gig_id' => $gig->id,
                    'gig_name' => $gig->name,
                    'display_name' => $gig->display_name,
                    'start_time' => $gig->start_time,
                    'end_time' => $gig->end_time,
                    'duration_hours' => $gig->duration_hours,
                    'base_earnings' => (float) $gig->base_earnings,
                    'slots' => $slotData
                ];
            }

            return response()->json([
                'status' => true,
                'message' => 'Available gigs retrieved successfully',
                'data' => [
                    'date' => $date,
                    'gigs' => $gigData
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get available gigs', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Book gig slots (single or multiple)
     *
     * POST /api/delivery_boy/gigs/book
     * Body: {
     *   "gig_slot_ids": [5, 6, 7]  // Array of slot IDs
     * }
     * OR for backward compatibility:
     * Body: {
     *   "gig_slot_id": 5  // Single slot ID
     * }
     */
    public function bookGig(Request $request)
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

            // Support both single and multiple slot booking
            $slotIds = [];
            if ($request->has('gig_slot_ids')) {
                $validator = Validator::make($request->all(), [
                    'gig_slot_ids' => 'required|array|min:1',
                    'gig_slot_ids.*' => 'required|exists:gig_slots,id'
                ]);

                if ($validator->fails()) {
                    return CommonHelper::responseError($validator->errors()->first());
                }

                $slotIds = $request->gig_slot_ids;
            } else {
                // Backward compatibility for single slot
                $validator = Validator::make($request->all(), [
                    'gig_slot_id' => 'required|exists:gig_slots,id'
                ]);

                if ($validator->fails()) {
                    return CommonHelper::responseError($validator->errors()->first());
                }

                $slotIds = [$request->gig_slot_id];
            }

            DB::beginTransaction();

            try {
                $bookings = [];
                $errors = [];
                $skipped = [];

                foreach ($slotIds as $slotId) {
                    $gigSlot = GigSlot::with('gig')->lockForUpdate()->find($slotId);

                    if (!$gigSlot) {
                        $errors[] = "Slot ID {$slotId}: Slot not found";
                        continue;
                    }

                    // Check if slot is available
                    if ($gigSlot->current_bookings >= $gigSlot->max_bookings) {
                        $errors[] = "Slot '{$gigSlot->slot_name}': Fully booked";
                        continue;
                    }

                    // Check if already booked
                    $existingBooking = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoy->id)
                        ->where('gig_slot_id', $gigSlot->id)
                        ->first();

                    if ($existingBooking) {
                        $skipped[] = "Slot '{$gigSlot->slot_name}': Already booked";
                        continue;
                    }

                    // Create booking
                    $booking = DeliveryBoyGigBooking::create([
                        'delivery_boy_id' => $deliveryBoy->id,
                        'gig_slot_id' => $gigSlot->id,
                        'booking_status' => 'booked',
                        'booked_at' => now(),
                    ]);

                    // Increment current bookings
                    $gigSlot->current_bookings += 1;
                    if ($gigSlot->current_bookings >= $gigSlot->max_bookings) {
                        $gigSlot->status = 0; // Mark as full
                    }
                    $gigSlot->save();

                    $bookings[] = [
                        'booking_id' => $booking->id,
                        'gig_name' => $gigSlot->gig->display_name,
                        'slot_date' => $gigSlot->slot_date,
                        'slot_name' => $gigSlot->slot_name,
                        'start_time' => $gigSlot->start_time,
                        'end_time' => $gigSlot->end_time,
                        'base_earnings' => (float) $gigSlot->gig->base_earnings,
                        'booking_status' => $booking->booking_status,
                        'booked_at' => $booking->booked_at->toIso8601String()
                    ];
                }

                // If no bookings were created, rollback and return error
                if (empty($bookings)) {
                    DB::rollBack();
                    $errorMessage = !empty($errors) ? implode(', ', $errors) : 'No slots could be booked';
                    if (!empty($skipped)) {
                        $errorMessage .= '. Skipped: ' . implode(', ', $skipped);
                    }
                    return CommonHelper::responseError($errorMessage);
                }

                DB::commit();

                Log::info('Gig slots booked successfully', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'total_booked' => count($bookings),
                    'booking_ids' => array_column($bookings, 'booking_id')
                ]);

                // Check active incentive offers and calculate progress
                $activeOffers = \DB::table('incentive_offers')
                    ->where('status', 1)
                    ->where('start_date', '<=', now())
                    ->where('end_date', '>=', now())
                    ->get();

                $offerProgress = [];
                foreach ($activeOffers as $offer) {
                    // Check if delivery boy is enrolled in this offer
                    $progress = \DB::table('delivery_boy_incentive_progress')
                        ->where('delivery_boy_id', $deliveryBoy->id)
                        ->where('incentive_offer_id', $offer->id)
                        ->where('status', 'active')
                        ->first();

                    if ($progress) {
                        // Get total gigs booked for this offer period (including just booked ones)
                        $totalGigsBooked = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoy->id)
                            ->whereHas('gigSlot', function($q) use ($offer) {
                                $q->whereBetween('slot_date', [
                                    \Carbon\Carbon::parse($offer->start_date)->toDateString(),
                                    \Carbon\Carbon::parse($offer->end_date)->toDateString()
                                ]);
                            })
                            ->count();

                        $remaining = max(0, $offer->min_gigs_required - $totalGigsBooked);
                        $isMet = $totalGigsBooked >= $offer->min_gigs_required;

                        $offerProgress[] = [
                            'offer_name' => $offer->name,
                            'min_gigs_required' => $offer->min_gigs_required,
                            'gigs_booked' => $totalGigsBooked,
                            'gigs_remaining' => $remaining,
                            'requirement_met' => $isMet,
                            'message' => $isMet
                                ? "Congratulations! You've met the requirement for '{$offer->name}'"
                                : "You need to book {$remaining} more gig(s) to qualify for '{$offer->name}'"
                        ];
                    }
                }

                $response = [
                    'status' => true,
                    'message' => count($bookings) > 1
                        ? count($bookings) . ' gig slots booked successfully'
                        : 'Gig slot booked successfully',
                    'data' => [
                        'bookings' => $bookings,
                        'total_booked' => count($bookings)
                    ]
                ];

                // Add offer progress if available
                if (!empty($offerProgress)) {
                    $response['data']['offer_progress'] = $offerProgress;
                }

                // Add errors and skipped info if any
                if (!empty($errors)) {
                    $response['errors'] = $errors;
                }
                if (!empty($skipped)) {
                    $response['skipped'] = $skipped;
                }

                return response()->json($response);

            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('Failed to book gig', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get my bookings
     *
     * GET /api/delivery_boy/gigs/my-bookings
     * Query: status (optional), date_from, date_to
     */
    public function getMyBookings(Request $request)
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

            // Auto-complete past bookings
            $this->autoCompletePastBookings($deliveryBoy->id);

            $query = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoy->id)
                ->with(['gigSlot.gig']);

            // Filter by status
            if ($request->has('status')) {
                $query->where('booking_status', $request->status);
            }

            // Filter by date range
            if ($request->has('date_from')) {
                $query->whereHas('gigSlot', function ($q) use ($request) {
                    $q->where('slot_date', '>=', $request->date_from);
                });
            }

            if ($request->has('date_to')) {
                $query->whereHas('gigSlot', function ($q) use ($request) {
                    $q->where('slot_date', '<=', $request->date_to);
                });
            }

            $bookings = $query->orderBy('created_at', 'desc')->get();

            $bookingData = $bookings->map(function ($booking) {
                return [
                    'booking_id' => $booking->id,
                    'gig_name' => $booking->gigSlot->gig->display_name,
                    'slot_date' => $booking->gigSlot->slot_date,
                    'start_time' => $booking->gigSlot->start_time,
                    'end_time' => $booking->gigSlot->end_time,
                    'base_earnings' => (float) $booking->gigSlot->gig->base_earnings,
                    'actual_earnings' => (float) $booking->earnings,
                    'booking_status' => $booking->booking_status,
                    'orders_completed' => $booking->orders_completed,
                    'orders_cancelled' => $booking->orders_cancelled,
                    'distance_km' => (float) $booking->distance_km,
                    'booked_at' => $booking->booked_at->toIso8601String(),
                    'started_at' => $booking->started_at ? $booking->started_at->toIso8601String() : null,
                    'ended_at' => $booking->ended_at ? $booking->ended_at->toIso8601String() : null,
                ];
            });

            // Calculate statistics based on the same filters applied to bookings
            $statisticsQuery = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoy->id);

            // Apply the same date filters for statistics
            if ($request->has('date_from')) {
                $statisticsQuery->whereHas('gigSlot', function ($q) use ($request) {
                    $q->where('slot_date', '>=', $request->date_from);
                });
            }

            if ($request->has('date_to')) {
                $statisticsQuery->whereHas('gigSlot', function ($q) use ($request) {
                    $q->where('slot_date', '<=', $request->date_to);
                });
            }

            $filteredBookings = $statisticsQuery->get();

            $statistics = [
                'total_gigs' => $filteredBookings->count(),
                'completed_gigs' => $filteredBookings->where('booking_status', 'completed')->count(),
                'total_earned' => (float) $filteredBookings->where('booking_status', 'completed')->sum('earnings'),
            ];

            return response()->json([
                'status' => true,
                'message' => 'Bookings retrieved successfully',
                'data' => [
                    'bookings' => $bookingData,
                    'total' => $bookingData->count(),
                    'statistics' => $statistics
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get bookings', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Cancel a booking
     *
     * POST /api/delivery_boy/gigs/cancel
     * Body: {
     *   "booking_id": 5,
     *   "reason": "Personal emergency"
     * }
     */
    public function cancelBooking(Request $request)
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

            $validator = Validator::make($request->all(), [
                'booking_id' => 'required|exists:delivery_boy_gig_bookings,id',
                'reason' => 'nullable|string|max:500'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            DB::beginTransaction();

            try {
                $booking = DeliveryBoyGigBooking::with('gigSlot')
                    ->where('id', $request->booking_id)
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->lockForUpdate()
                    ->first();

                if (!$booking) {
                    DB::rollBack();
                    return CommonHelper::responseError('Booking not found');
                }

                // Check if booking can be cancelled
                if ($booking->booking_status === 'completed') {
                    DB::rollBack();
                    return CommonHelper::responseError('Cannot cancel a completed gig');
                }

                if ($booking->booking_status === 'cancelled') {
                    DB::rollBack();
                    return CommonHelper::responseError('This booking is already cancelled');
                }

                // Update booking
                $booking->booking_status = 'cancelled';
                $booking->cancellation_reason = $request->reason;
                $booking->save();

                // Decrease slot booking count
                $gigSlot = $booking->gigSlot;
                $gigSlot->current_bookings -= 1;
                if ($gigSlot->current_bookings < $gigSlot->max_bookings) {
                    $gigSlot->status = 1; // Re-open slot
                }
                $gigSlot->save();

                DB::commit();

                Log::info('Gig booking cancelled', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'booking_id' => $booking->id
                ]);

                return response()->json([
                    'status' => true,
                    'message' => 'Booking cancelled successfully',
                    'data' => [
                        'booking_id' => $booking->id,
                        'status' => $booking->booking_status
                    ]
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('Failed to cancel booking', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Complete a gig (mark as completed)
     *
     * POST /api/delivery_boy/gigs/complete
     * Body: {
     *   "booking_id": 5,
     *   "earnings": 350.50,
     *   "orders_completed": 12,
     *   "orders_cancelled": 1,
     *   "distance_km": 25.5
     * }
     */
    public function completeGig(Request $request)
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

            $validator = Validator::make($request->all(), [
                'booking_id' => 'required|exists:delivery_boy_gig_bookings,id',
                'earnings' => 'required|numeric|min:0',
                'orders_completed' => 'required|integer|min:0',
                'orders_cancelled' => 'required|integer|min:0',
                'distance_km' => 'required|numeric|min:0'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $booking = DeliveryBoyGigBooking::with('gigSlot')
                ->where('id', $request->booking_id)
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->first();

            if (!$booking) {
                return CommonHelper::responseError('Booking not found');
            }

            if ($booking->booking_status === 'completed') {
                return CommonHelper::responseError('This gig is already completed');
            }

            // Update booking
            $booking->booking_status = 'completed';
            $booking->ended_at = now();
            $booking->earnings = $request->earnings;
            $booking->orders_completed = $request->orders_completed;
            $booking->orders_cancelled = $request->orders_cancelled;
            $booking->distance_km = $request->distance_km;
            $booking->save();

            // Update daily tracking
            $slotDate = $booking->gigSlot->slot_date;
            $tracking = DeliveryBoyDailyTracking::firstOrCreate(
                [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'tracking_date' => $slotDate
                ]
            );

            $tracking->total_earnings += $request->earnings;
            $tracking->total_distance_km += $request->distance_km;
            $tracking->gigs_completed += 1;
            $tracking->orders_delivered += $request->orders_completed;
            $tracking->orders_cancelled += $request->orders_cancelled;
            $tracking->save();

            Log::info('Gig completed', [
                'delivery_boy_id' => $deliveryBoy->id,
                'booking_id' => $booking->id,
                'earnings' => $request->earnings
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Gig completed successfully',
                'data' => [
                    'booking_id' => $booking->id,
                    'status' => $booking->booking_status,
                    'earnings' => (float) $booking->earnings,
                    'total_earnings_today' => (float) $tracking->total_earnings,
                    'gigs_completed_today' => $tracking->gigs_completed
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to complete gig', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get gig details
     *
     * GET /api/delivery_boy/gig-details?gig_id=1
     */
    public function getGigDetails(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'gig_id' => 'required|exists:gigs,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $gig = Gig::with(['slots' => function($query) {
                $query->where('slot_date', '>=', now()->toDateString())
                      ->where('status', 1)
                      ->orderBy('slot_date', 'asc');
            }])->find($request->gig_id);

            if (!$gig) {
                return CommonHelper::responseError('Gig not found');
            }

            return response()->json([
                'status' => true,
                'message' => 'Gig details retrieved successfully',
                'data' => [
                    'gig' => [
                        'id' => $gig->id,
                        'name' => $gig->name,
                        'display_name' => $gig->display_name,
                        'start_time' => $gig->start_time,
                        'end_time' => $gig->end_time,
                        'duration_hours' => $gig->duration_hours,
                        'base_earnings' => (float) $gig->base_earnings,
                        'status' => $gig->status,
                        'available_slots' => $gig->slots->map(function($slot) {
                            return [
                                'slot_id' => $slot->id,
                                'date' => $slot->slot_date,
                                'capacity' => $slot->max_bookings,
                                'booked' => $slot->current_bookings,
                                'available' => $slot->max_bookings - $slot->current_bookings,
                                'is_full' => $slot->current_bookings >= $slot->max_bookings
                            ];
                        })
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get gig details', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get gig history
     *
     * GET /api/delivery_boy/gig-history
     */
    public function getGigHistory(Request $request)
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

            // Auto-complete past bookings
            $this->autoCompletePastBookings($deliveryBoy->id);

            $history = DeliveryBoyGigBooking::with(['gig', 'gigSlot'])
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->where('booking_status', 'completed')
                ->orderBy('created_at', 'desc')
                ->paginate(20);

            return response()->json([
                'status' => true,
                'message' => 'Gig history retrieved successfully',
                'data' => [
                    'bookings' => $history->map(function($booking) {
                        return [
                            'booking_id' => $booking->id,
                            'gig_name' => $booking->gig->gig_name,
                            'date' => $booking->gigSlot->slot_date,
                            'start_time' => $booking->gig->start_time,
                            'end_time' => $booking->gig->end_time,
                            'earnings' => (float) $booking->earnings,
                            'orders_delivered' => $booking->orders_delivered,
                            'distance_traveled' => (float) $booking->distance_traveled,
                            'completed_at' => $booking->completed_at ? $booking->completed_at->toIso8601String() : null,
                            'status' => $booking->booking_status
                        ];
                    }),
                    'pagination' => [
                        'current_page' => $history->currentPage(),
                        'total_pages' => $history->lastPage(),
                        'per_page' => $history->perPage(),
                        'total' => $history->total()
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get gig history', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
