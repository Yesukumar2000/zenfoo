<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\GigSlot;
use App\Models\DeliveryBoyGigBooking;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class DevController extends Controller
{
    /**
     * DEV ONLY: Auto-book all available gigs for today for a delivery boy
     *
     * POST /api/dev/auto-book-today-gigs
     * Body: {
     *   "delivery_boy_id": 5,
     *   "include_past_slots": false  // Optional: set true to book even past slots (default: false)
     * }
     *
     * ⚠️ WARNING: This endpoint has NO AUTHENTICATION - Use only for development/testing
     */
    public function autoBookTodayGigs(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|exists:delivery_boys,id',
                'include_past_slots' => 'nullable|boolean'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoyId = $request->delivery_boy_id;
            $includePastSlots = $request->input('include_past_slots', false); // Default: skip past slots
            $today = Carbon::today()->toDateString();
            $currentDateTime = Carbon::now();

            // Get delivery boy details
            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            // Get all gig slots for today
            $todaySlots = GigSlot::with('gig')
                ->where('slot_date', $today)
                ->where('status', 1) // Only active slots
                ->orderBy('start_time', 'asc')
                ->get();

            if ($todaySlots->isEmpty()) {
                return response()->json([
                    'status' => false,
                    'message' => 'No gig slots available for today',
                    'data' => [
                        'delivery_boy_id' => $deliveryBoyId,
                        'date' => $today,
                        'total_slots_found' => 0
                    ]
                ]);
            }

            DB::beginTransaction();

            try {
                $bookings = [];
                $alreadyBooked = [];
                $fullyBooked = [];
                $pastSlots = [];
                $errors = [];

                foreach ($todaySlots as $slot) {
                    // Check if slot time has already passed (skip past slots unless forced)
                    if (!$includePastSlots) {
                        $slotDateOnly = Carbon::parse($slot->slot_date)->format('Y-m-d');
                        $slotDateTime = Carbon::parse($slotDateOnly . ' ' . $slot->start_time);

                        if ($slotDateTime->lt($currentDateTime)) {
                            $pastSlots[] = [
                                'gig_name' => $slot->gig->display_name,
                                'slot_name' => $slot->slot_name,
                                'start_time' => $slot->start_time,
                                'reason' => 'Slot time has already passed'
                            ];
                            continue;
                        }
                    }

                    // Check if delivery boy already booked this slot
                    $existingBooking = DeliveryBoyGigBooking::where('delivery_boy_id', $deliveryBoyId)
                        ->where('gig_slot_id', $slot->id)
                        ->first();

                    if ($existingBooking) {
                        $alreadyBooked[] = [
                            'gig_name' => $slot->gig->display_name,
                            'slot_name' => $slot->slot_name,
                            'booking_status' => $existingBooking->booking_status
                        ];
                        continue;
                    }

                    // Lock the slot to prevent race conditions
                    $gigSlot = GigSlot::lockForUpdate()->find($slot->id);

                    // Check if slot has available capacity
                    if ($gigSlot->current_bookings >= $gigSlot->max_bookings) {
                        $fullyBooked[] = [
                            'gig_name' => $slot->gig->display_name,
                            'slot_name' => $slot->slot_name,
                            'capacity' => $gigSlot->max_bookings
                        ];
                        continue;
                    }

                    // Create booking
                    $booking = DeliveryBoyGigBooking::create([
                        'delivery_boy_id' => $deliveryBoyId,
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
                        'gig_name' => $slot->gig->display_name,
                        'slot_name' => $slot->slot_name,
                        'start_time' => $slot->start_time,
                        'end_time' => $slot->end_time,
                        'base_earnings' => (float) $slot->gig->base_earnings,
                        'booked_at' => $booking->booked_at->toIso8601String()
                    ];
                }

                DB::commit();

                Log::info('DEV: Auto-booked today gigs', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'date' => $today,
                    'include_past_slots' => $includePastSlots,
                    'total_slots' => $todaySlots->count(),
                    'booked' => count($bookings),
                    'already_booked' => count($alreadyBooked),
                    'fully_booked' => count($fullyBooked),
                    'past_slots_skipped' => count($pastSlots)
                ]);

                return response()->json([
                    'status' => true,
                    'message' => count($bookings) > 0
                        ? count($bookings) . ' gig slot(s) booked successfully for today'
                        : 'No new slots were booked',
                    'data' => [
                        'delivery_boy_id' => $deliveryBoyId,
                        'delivery_boy_name' => $deliveryBoy->name ?? 'N/A',
                        'date' => $today,
                        'current_time' => $currentDateTime->format('H:i:s'),
                        'include_past_slots' => $includePastSlots,
                        'summary' => [
                            'total_slots_today' => $todaySlots->count(),
                            'newly_booked' => count($bookings),
                            'already_booked' => count($alreadyBooked),
                            'fully_booked' => count($fullyBooked),
                            'past_slots_skipped' => count($pastSlots),
                        ],
                        'newly_booked_slots' => $bookings,
                        'already_booked_slots' => $alreadyBooked,
                        'fully_booked_slots' => $fullyBooked,
                        'past_slots_skipped' => $pastSlots,
                    ]
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('DEV: Failed to auto-book today gigs', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to auto-book gigs: ' . $e->getMessage());
        }
    }
}
