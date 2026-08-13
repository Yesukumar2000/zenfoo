<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Helpers\FirebaseHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyDailyTracking;
use App\Models\DeliveryBoySession;
use App\Models\DeliveryBoyLocationHistory;
use App\Models\DeliveryBoyGigBooking;
use App\Models\GigSlot;
use App\Models\DeliveryBoyNotification;
use App\Models\AdminToken;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class GigTrackingController extends Controller
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
     * Start work session (Login)
     *
     * POST /api/delivery_boy/session/login
     * Body: {
     *   "latitude": 17.4486,
     *   "longitude": 78.3908,
     * }
     */
    public function startSession(Request $request)
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
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Check if there's an unclosed session from any previous day
            $today = Carbon::today()->toDateString();
            $unclosedSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if ($unclosedSession) {
                $sessionDate = Carbon::parse($unclosedSession->login_at)->toDateString();
                $sessionTracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->where('tracking_date', $sessionDate)
                    ->first();

                // Auto-close unclosed sessions if:
                // 1. Session is from a previous day (not today), OR
                // 2. Session is from today but tracking shows offline/null status
                $shouldAutoClose = false;

                if ($sessionDate < $today) {
                    // Previous day's unclosed session - always close it
                    $shouldAutoClose = true;
                } elseif ($sessionDate === $today && $sessionTracking && $sessionTracking->online_status !== 'online') {
                    // Today's session but tracking is offline/null - close it
                    $shouldAutoClose = true;
                } elseif ($sessionDate === $today && !$sessionTracking) {
                    // Today's session but no tracking record - close it
                    $shouldAutoClose = true;
                }

                if ($shouldAutoClose) {
                    $loginTime = Carbon::parse($unclosedSession->login_at);

                    // Use the tracking's last_activity_at as logout time if available, otherwise use current time
                    $logoutTime = $sessionTracking && $sessionTracking->last_activity_at
                        ? Carbon::parse($sessionTracking->last_activity_at)
                        : now();

                    $durationMinutes = $loginTime->diffInMinutes($logoutTime);

                    $unclosedSession->logout_at = $logoutTime;
                    $unclosedSession->duration_minutes = $durationMinutes;
                    $unclosedSession->save();

                    // Update the session's daily tracking record with the duration
                    if ($sessionTracking) {
                        $sessionTracking->total_login_minutes += $durationMinutes;
                        $sessionTracking->save();

                        Log::info('Auto-closed unclosed session from previous day', [
                            'delivery_boy_id' => $deliveryBoy->id,
                            'session_id' => $unclosedSession->id,
                            'session_date' => $sessionDate,
                            'login_at' => $loginTime->toDateTimeString(),
                            'logout_at' => $logoutTime->toDateTimeString(),
                            'duration_minutes' => $durationMinutes,
                            'tracking_date' => $sessionDate,
                            'last_activity_at' => $sessionTracking->last_activity_at ? $sessionTracking->last_activity_at->toDateTimeString() : 'null'
                        ]);
                    } else {
                        Log::info('Auto-closed unclosed session with no tracking record', [
                            'delivery_boy_id' => $deliveryBoy->id,
                            'session_id' => $unclosedSession->id,
                            'session_date' => $sessionDate,
                            'login_at' => $loginTime->toDateTimeString(),
                            'logout_at' => $logoutTime->toDateTimeString(),
                            'duration_minutes' => $durationMinutes
                        ]);
                    }
                } else {
                    // Session is still active/online, don't allow new session
                    return CommonHelper::responseError('You already have an active session. Please logout first.');
                }
            }

            try {
                DeliveryBoy::where('admin_id', $user->id)->update([
                    'is_available' => 1,
                    'orders_since_last_face_verify' => 0
                ]);
            } catch (\Throwable $th) {
                Log::info('Error while making is_available to 1 : ', [
                    'driver_admin_id' => $user->id,
                ]);
            }

            // Get today's date
            $today = Carbon::today()->toDateString();
            $now = Carbon::now();

            // COMMENTED OUT: Gig checking logic - Driver can start session without gigs
            /*
            // Find all today's bookings for this delivery boy
            $bookings = DeliveryBoyGigBooking::with(['gigSlot.gig'])
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('booking_status', ['booked', 'active'])
                ->whereHas('gigSlot', function ($query) use ($today) {
                    $query->where('slot_date', $today);
                })
                ->get();

            if ($bookings->isEmpty()) {
                return CommonHelper::responseError('No active booking found for today. Please book a slot first.');
            }

            // Find the first booking where current time is valid for session start
            $validBooking = null;
            foreach ($bookings as $bookingItem) {
                $gigSlot = $bookingItem->gigSlot;
                $slotStart = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $gigSlot->start_time);
                $slotEnd = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $gigSlot->end_time);
                $allowedStartTime = $slotStart->copy()->subMinutes(30);

                // Check if current time is valid for this slot
                if ($now->gte($allowedStartTime) && $now->lte($slotEnd)) {
                    $validBooking = $bookingItem;
                    break;
                }
            }

            if (!$validBooking) {
                // No valid slot found, show all available slots
                $slotTimes = $bookings->map(function ($b) use ($today) {
                    $start = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $b->gigSlot->start_time);
                    $end = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $b->gigSlot->end_time);
                    return $start->format('h:i A') . ' - ' . $end->format('h:i A');
                })->join(', ');

                return CommonHelper::responseError('No valid slot found for current time. Your booked slots today: ' . $slotTimes);
            }

            // Mark all previous slots (that have ended) as completed
            // Count completed GIGS (not slots) - a gig is only counted as complete when ALL its slots are done
            $completedBookingsByGig = [];

            foreach ($bookings as $bookingItem) {
                $slotItemEnd = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $bookingItem->gigSlot->end_time);

                // If slot has ended and booking is still 'booked' or 'active', mark it as completed
                if ($now->gt($slotItemEnd) && in_array($bookingItem->booking_status, ['booked', 'active'])) {
                    $bookingItem->booking_status = 'completed';
                    $bookingItem->ended_at = $slotItemEnd; // Set end time to slot end time
                    $bookingItem->save();

                    // Track by gig_id to count unique gigs
                    $gigId = $bookingItem->gigSlot->gig_id;
                    if (!isset($completedBookingsByGig[$gigId])) {
                        $completedBookingsByGig[$gigId] = [];
                    }
                    $completedBookingsByGig[$gigId][] = $bookingItem->id;

                    Log::info('Previous slot marked as completed', [
                        'booking_id' => $bookingItem->id,
                        'gig_id' => $gigId,
                        'slot_end_time' => $slotItemEnd->toDateTimeString()
                    ]);
                }
            }

            // Count completed gigs: A gig is complete only when ALL its slots are completed
            $completedGigsCount = 0;
            foreach ($completedBookingsByGig as $gigId => $bookingIds) {
                // Check if ALL slots for this gig are completed (not just the ones we just completed)
                $totalSlotsForGig = DeliveryBoyGigBooking::whereHas('gigSlot', function ($q) use ($gigId, $today) {
                    $q->where('gig_id', $gigId)->where('slot_date', $today);
                })->count();

                $completedSlotsForGig = DeliveryBoyGigBooking::whereHas('gigSlot', function ($q) use ($gigId, $today) {
                    $q->where('gig_id', $gigId)->where('slot_date', $today);
                })
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->where('booking_status', 'completed')
                ->count();

                Log::info('Checking gig completion status', [
                    'gig_id' => $gigId,
                    'total_slots' => $totalSlotsForGig,
                    'completed_slots' => $completedSlotsForGig
                ]);

                // Only count as 1 completed gig if ALL slots are done
                if ($totalSlotsForGig > 0 && $completedSlotsForGig === $totalSlotsForGig) {
                    $completedGigsCount++;

                    Log::info('Gig fully completed (all slots done)', [
                        'gig_id' => $gigId,
                        'total_slots' => $totalSlotsForGig,
                        'delivery_boy_id' => $deliveryBoy->id
                    ]);
                }
            }

            // Update daily tracking with completed gigs count
            if ($completedGigsCount > 0) {
                $tracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                    ->where('tracking_date', $today)
                    ->first();

                if ($tracking) {
                    $tracking->gigs_completed += $completedGigsCount;
                    $tracking->save();

                    Log::info('Updated daily tracking with completed gigs', [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'completed_gigs_added' => $completedGigsCount,
                        'total_gigs_completed' => $tracking->gigs_completed
                    ]);
                }
            }

            // Use the valid booking
            $booking = $validBooking;
            $gigSlot = $booking->gigSlot;
            $slotStart = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $gigSlot->start_time);
            $slotEnd = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $gigSlot->end_time);
            $allowedStartTime = $slotStart->copy()->subMinutes(30);

            // Log for debugging
            Log::info('Session start time validation', [
                'now' => $now->toDateTimeString(),
                'allowedStartTime' => $allowedStartTime->toDateTimeString(),
                'slotStart' => $slotStart->toDateTimeString(),
                'slotEnd' => $slotEnd->toDateTimeString(),
                'booking_id' => $booking->id
            ]);
            */

            // Create new session (without gig booking requirement)
            $session = DeliveryBoySession::create([
                'delivery_boy_id' => $deliveryBoy->id,
                'gig_booking_id' => null, // No gig booking required
                'login_at' => now(),
                'latitude_start' => $request->latitude,
                'longitude_start' => $request->longitude,
            ]);

            // Update or create daily tracking
            $tracking = DeliveryBoyDailyTracking::firstOrCreate(
                [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'tracking_date' => $today
                ],
                [
                    'online_status' => 'online',
                    'first_login_at' => now(),
                    'last_activity_at' => now(),
                ]
            );

            $tracking->online_status = 'online';
            $tracking->last_activity_at = now();
            if (!$tracking->first_login_at) {
                $tracking->first_login_at = now();
            }
            $tracking->save();

            // COMMENTED OUT: Booking status update - No longer needed without gig requirement
            /*
            // Mark booking as started/active (only set started_at on first start)
            if ($booking->booking_status !== 'active') {
                $booking->booking_status = 'active';
                $booking->started_at = now();
                $booking->save();
            }
            */

            Log::info('Delivery boy session started', [
                'delivery_boy_id' => $deliveryBoy->id,
                'session_id' => $session->id,
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Session started successfully',
                'data' => [
                    'session_id' => $session->id,
                    'login_at' => $session->login_at->toIso8601String(),
                    'online_status' => 'online',
                    'is_available' => $deliveryBoy->is_available,
                    'delivery_boy_id' => $deliveryBoy->id,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to start session', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * End work session (Logout)
     *
     * POST /api/delivery_boy/session/logout
     * Body: {
     *   "latitude": 17.4486,
     *   "longitude": 78.3908
     * }
     */
    public function endSession(Request $request)
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
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Find active session with booking and slot details
            $session = DeliveryBoySession::with(['gigBooking.gigSlot'])
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if (!$session) {
                return CommonHelper::responseError('No active session found');
            }

            
            try {
                DeliveryBoy::where('admin_id', $user->id)->update(['is_available' => 0]);
            } catch (\Throwable $th) {
                Log::info('Error while making is_available to 0 : ', [
                    'driver_admin_id' => $user->id,
                ]);
            }

            // Calculate duration
            $loginTime = Carbon::parse($session->login_at);
            $logoutTime = now();
            $durationMinutes = $loginTime->diffInMinutes($logoutTime);

            // Update session
            $session->logout_at = $logoutTime;
            $session->duration_minutes = $durationMinutes;
            $session->latitude_end = $request->latitude;
            $session->longitude_end = $request->longitude;
            $session->save();

            // Update daily tracking
            $today = Carbon::today()->toDateString();
            $tracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->where('tracking_date', $today)
                ->first();

            if ($tracking) {
                $tracking->total_login_minutes += $durationMinutes;
                $tracking->online_status = 'offline';
                $tracking->last_activity_at = now();
                $tracking->save();
            }

            // Check if the gig slot time has ended and complete the booking
            // Count completed GIGS (not slots) - a gig is only counted as complete when ALL its slots are done
            $bookingCompleted = false;
            $gigsCompletedCount = 0;

            if ($session->gigBooking && $session->gigBooking->gigSlot) {
                $booking = $session->gigBooking;
                $gigSlot = $booking->gigSlot;
                $gigId = $gigSlot->gig_id;

                // Get current time and slot end time
                $currentTime = Carbon::now()->format('H:i:s');
                $slotEndTime = $gigSlot->end_time;
                $slotDate = Carbon::parse($gigSlot->slot_date)->toDateString();

                // Check if slot is for today and time has passed the end time
                if ($slotDate === $today && $currentTime >= $slotEndTime) {
                    // Mark booking as completed
                    if ($booking->booking_status === 'active') {
                        $booking->booking_status = 'completed';
                        $booking->ended_at = now();
                        $booking->save();
                        $bookingCompleted = true;

                        Log::info('Gig booking auto-completed on session end', [
                            'booking_id' => $booking->id,
                            'gig_slot_id' => $gigSlot->id,
                            'gig_id' => $gigId,
                            'ended_at' => $booking->ended_at
                        ]);

                        // Check if ALL slots for this gig are now completed
                        $totalSlotsForGig = DeliveryBoyGigBooking::whereHas('gigSlot', function ($q) use ($gigId, $today) {
                            $q->where('gig_id', $gigId)->where('slot_date', $today);
                        })->count();

                        $completedSlotsForGig = DeliveryBoyGigBooking::whereHas('gigSlot', function ($q) use ($gigId, $today) {
                            $q->where('gig_id', $gigId)->where('slot_date', $today);
                        })
                        ->where('delivery_boy_id', $deliveryBoy->id)
                        ->where('booking_status', 'completed')
                        ->count();

                        Log::info('Checking gig completion on session end', [
                            'gig_id' => $gigId,
                            'total_slots' => $totalSlotsForGig,
                            'completed_slots' => $completedSlotsForGig
                        ]);

                        // Only count as 1 completed gig if ALL slots are done
                        if ($totalSlotsForGig > 0 && $completedSlotsForGig === $totalSlotsForGig) {
                            $gigsCompletedCount = 1;

                            Log::info('Gig fully completed on session end (all slots done)', [
                                'gig_id' => $gigId,
                                'total_slots' => $totalSlotsForGig,
                                'delivery_boy_id' => $deliveryBoy->id
                            ]);
                        }

                        // Increment gigs_completed in daily tracking only if gig is fully complete
                        if ($tracking && $gigsCompletedCount > 0) {
                            $tracking->gigs_completed += $gigsCompletedCount;
                            $tracking->save();

                            Log::info('Gig completed and daily tracking updated on session end', [
                                'booking_id' => $booking->id,
                                'gig_slot_id' => $gigSlot->id,
                                'gig_id' => $gigId,
                                'total_gigs_completed' => $tracking->gigs_completed
                            ]);
                        }
                    }
                }
            }

            Log::info('Delivery boy session ended', [
                'delivery_boy_id' => $deliveryBoy->id,
                'session_id' => $session->id,
                'duration_minutes' => $durationMinutes,
                'booking_completed' => $bookingCompleted
            ]);

            $responseData = [
                'session_id' => $session->id,
                'login_at' => $session->login_at->toIso8601String(),
                'logout_at' => $session->logout_at->toIso8601String(),
                'duration_minutes' => $durationMinutes,
                'duration_hours' => round($durationMinutes / 60, 2),
                'online_status' => 'offline',
                'is_available' => $deliveryBoy->is_available,
                'delivery_boy_id' => $deliveryBoy->id,
            ];

            if ($bookingCompleted) {
                $responseData['booking_status'] = 'completed';
                $responseData['message'] = 'Your gig has been completed';
            }

            return response()->json([
                'status' => true,
                'message' => $bookingCompleted ? 'Session ended and gig completed successfully' : 'Session ended successfully',
                'data' => $responseData
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to end session', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get today's tracking stats
     *
     * GET /api/delivery_boy/tracking/today
     */
    public function getTodayStats(Request $request)
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

            $today = Carbon::today()->toDateString();

            // Get or create today's tracking
            $tracking = DeliveryBoyDailyTracking::firstOrCreate(
                [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'tracking_date' => $today
                ],
                [
                    'online_status' => 'offline',
                    'total_login_minutes' => 0,
                    'total_earnings' => 0,
                    'total_distance_km' => 0,
                    'gigs_completed' => 0,
                    'orders_delivered' => 0,
                    'orders_cancelled' => 0,
                ]
            );

            // Check if there's an active session from today only
            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->whereDate('login_at', $today)
                ->first();

            // Calculate cumulative login time from today's sessions
            // Base is the total from completed sessions
            $cumulativeLoginMinutes = $tracking->total_login_minutes;

            // If there's an active session, add the current session duration
            $currentSessionMinutes = 0;
            if ($activeSession) {
                $currentSessionMinutes = Carbon::parse($activeSession->login_at)->diffInMinutes(now());
                $cumulativeLoginMinutes += $currentSessionMinutes;
                $tracking->online_status = 'online';
            }

            // Get today's bookings
            $todayBookings = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoy->id)
                ->whereHas('gigSlot', function ($q) use ($today) {
                    $q->where('slot_date', $today);
                })
                ->get();

            // Get current server timestamp for real-time sync
            $now = now();

            return response()->json([
                'status' => true,
                'message' => 'Today stats retrieved successfully',
                'data' => [
                    'online_status' => $tracking->online_status,
                    // Cumulative login time from all sessions today
                    'total_login_minutes' => $cumulativeLoginMinutes,
                    'total_login_hours' => round($cumulativeLoginMinutes / 60, 2),
                    'login_display_time' => $this->formatLoginTimeFromMinutes($cumulativeLoginMinutes),
                    // For real-time updates on mobile
                    'login_time_sync' => [
                        'accumulated_minutes' => $tracking->total_login_minutes, // Minutes from completed sessions
                        'current_session_minutes' => $currentSessionMinutes,     // Minutes in current active session
                        'server_time' => $now->toIso8601String(),              // Server time for sync
                        'active_session_started_at' => $activeSession ? $activeSession->login_at->toIso8601String() : null
                    ],
                    'total_earnings' => (float) $tracking->total_earnings,
                    'total_distance_km' => (float) $tracking->total_distance_km,
                    'gigs_completed' => $tracking->gigs_completed,
                    'gigs_booked' => $todayBookings->count(),
                    'orders_delivered' => $tracking->orders_delivered,
                    'orders_cancelled' => $tracking->orders_cancelled,
                    'first_login_at' => $tracking->first_login_at ? $tracking->first_login_at->toIso8601String() : null,
                    'last_activity_at' => $tracking->last_activity_at ? $tracking->last_activity_at->toIso8601String() : null,
                    'active_session' => $activeSession ? [
                        'session_id' => $activeSession->id,
                        'login_at' => $activeSession->login_at->toIso8601String(),
                        'current_duration_minutes' => $currentSessionMinutes
                    ] : null
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get today stats', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update location
     *
     * POST /api/delivery_boy/location/update
     * Body: {
     *   "latitude": 17.4486,
     *   "longitude": 78.3908
     * }
     */
    public function updateLocation(Request $request)
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
                'latitude' => 'required|numeric',
                'longitude' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get active session
            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            // Get last location
            $lastLocation = DeliveryBoyLocationHistory::where('delivery_boy_id', $deliveryBoy->id)
                ->orderBy('tracked_at', 'desc')
                ->first();

            // Calculate distance from last location
            $distance = 0;
            if ($lastLocation) {
                $distance = $this->calculateDistance(
                    $lastLocation->latitude,
                    $lastLocation->longitude,
                    $request->latitude,
                    $request->longitude
                );
            }

            // Save location history
            $locationHistory = DeliveryBoyLocationHistory::create([
                'delivery_boy_id' => $deliveryBoy->id,
                'session_id' => $activeSession ? $activeSession->id : null,
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'distance_from_last_km' => $distance,
                'tracked_at' => now()
            ]);

            // Update daily tracking distance
            $today = Carbon::today()->toDateString();
            $tracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
                ->where('tracking_date', $today)
                ->first();

            if ($tracking) {
                $tracking->total_distance_km += $distance;
                $tracking->last_activity_at = now();
                $tracking->save();
            }

            return response()->json([
                'status' => true,
                'message' => 'Location updated successfully',
                'data' => [
                    'distance_from_last_km' => round($distance, 2),
                    'total_distance_today_km' => $tracking ? round($tracking->total_distance_km, 2) : 0
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update location', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Calculate distance between two coordinates using Haversine formula
     */
    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371; // km

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon/2) * sin($dLon/2);

        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        $distance = $earthRadius * $c;

        return $distance;
    }

    /**
     * Format login time from minutes
     * Returns format like "1 hr 21 min" or "45 min"
     */
    private function formatLoginTimeFromMinutes($totalMinutes)
    {
        if ($totalMinutes <= 0) {
            return '0 min';
        }

        $hours = floor($totalMinutes / 60);
        $minutes = $totalMinutes % 60;

        if ($hours > 0) {
            return $hours . ' hr ' . $minutes . ' min';
        } else {
            return $minutes . ' min';
        }
    }

    /**
     * Get active session
     *
     * GET /api/delivery_boy/tracking/active
     */
    public function getActiveSession(Request $request)
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

            $activeSession = DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->first();

            if (!$activeSession) {
                return response()->json([
                    'status' => true,
                    'message' => 'No active session',
                    'data' => [
                        'has_active_session' => false,
                        'session' => null
                    ]
                ]);
            }

            $sessionDuration = Carbon::parse($activeSession->login_at)->diffForHumans(now(), true);

            return response()->json([
                'status' => true,
                'message' => 'Active session retrieved',
                'data' => [
                    'has_active_session' => true,
                    'session' => [
                        'session_id' => $activeSession->id,
                        'login_at' => $activeSession->login_at->toIso8601String(),
                        'login_latitude' => $activeSession->login_latitude,
                        'login_longitude' => $activeSession->login_longitude,
                        'duration' => $sessionDuration,
                        'duration_minutes' => Carbon::parse($activeSession->login_at)->diffInMinutes(now())
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get active session', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
