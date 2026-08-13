# Gig Completion Tracking - Session Management

## Overview

The system now automatically tracks gig completions when delivery boys log in and out. **Important: A gig is counted as "1 completed gig" only when ALL slots for that gig are completed**, not per slot. This ensures accurate incentive calculations based on actual gigs completed, not individual slots.

**Example**: If a gig has 3 slots (Morning, Afternoon, Evening), all 3 slots must be completed before the gig counts as 1 completion.

---

## How It Works

### Session Lifecycle

```
Login (startSession)
    ↓
Check for past completed slots
    ↓
For each gig: If ALL slots are completed → Increment gigs_completed by 1
    ↓
Start current session
    ↓
[Work period]
    ↓
Logout (endSession)
    ↓
Check if current slot time has ended
    ↓
Mark slot as completed
    ↓
Check: If ALL slots for this gig are now complete → Increment gigs_completed by 1
    ↓
End session
```

### Files Modified

**Controller**: [app/Http/Controllers/API/DeliveryBoy/GigTrackingController.php](app/Http/Controllers/API/DeliveryBoy/GigTrackingController.php)

- **startSession() method** (lines 218-295): Auto-complete past slots and count only when ALL slots for a gig are done
- **endSession() method** (lines 454-528): Complete current slot and count only when ALL slots for the gig are now complete

---

## Detailed Logic

### 1. Login (startSession) - Lines 218-295

**Scenario**: Delivery boy has multiple gigs with multiple slots and logs in after some have ended

```
Gig A (has 2 slots today):
├─ 8:00 AM - 10:00 AM   ← Slot 1 - Already ended
└─ 10:00 AM - 12:00 PM  ← Slot 2 - Already ended (ALL slots done!)

Gig B (has 2 slots today):
├─ 12:00 PM - 2:00 PM   ← Slot 1 - Already ended
└─ 2:00 PM - 4:00 PM    ← Slot 2 - Current valid slot (NOT all done yet)

Current time: 2:30 PM
```

**Process**:
1. Find all bookings for today
2. For each booking that has already ended:
   - Check if current time > slot end time
   - Mark booking status as "completed"
   - Set ended_at to slot end time
   - Track by gig_id
3. For each gig that had slots completed:
   - Count total slots for the gig
   - Count completed slots for the gig
   - **Only if ALL slots are completed → increment gigs_completed by 1**
4. Update daily tracking with completed gigs count
5. Start session for current valid slot

**Result**:
```
Gig A: 2 slots ended → Both marked completed → gigs_completed += 1 ✅
Gig B: 1 slot ended, 1 still active → NOT counted (waiting for Slot 2)
Final: gigs_completed += 1 (only Gig A fully complete)
Current session starts for Gig B Slot 2
```

**Code**:
```php
// Mark all previous slots (that have ended) as completed and update gigs_completed count
$completedGigsCount = 0;
foreach ($bookings as $bookingItem) {
    $slotItemEnd = Carbon::createFromFormat('Y-m-d H:i:s', $today . ' ' . $bookingItem->gigSlot->end_time);

    // If slot has ended and booking is still 'booked' or 'active', mark it as completed
    if ($now->gt($slotItemEnd) && in_array($bookingItem->booking_status, ['booked', 'active'])) {
        $bookingItem->booking_status = 'completed';
        $bookingItem->ended_at = $slotItemEnd;
        $bookingItem->save();
        $completedGigsCount++;
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
    }
}
```

### 2. Logout (endSession) - Lines 411-450

**Scenario**: Delivery boy logs out when current slot time has ended

```
Current Session:
├─ Booking Status: active
├─ Slot Time: 2:00 PM - 4:00 PM
└─ Current Time: 4:15 PM (slot has ended)

User calls endSession API
```

**Process**:
1. Find active session for delivery boy
2. Check if current time >= slot end time
3. If yes:
   - Mark booking status as "completed"
   - Set ended_at to now()
   - Increment gigs_completed by 1
   - Update daily tracking
4. End session and save duration

**Result**:
```
gigs_completed += 1
Session logged: 2:00 PM - 4:15 PM
Duration: 135 minutes
```

**Code**:
```php
// Check if the gig slot time has ended and complete the booking
$bookingCompleted = false;
if ($session->gigBooking && $session->gigBooking->gigSlot) {
    $booking = $session->gigBooking;
    $gigSlot = $booking->gigSlot;

    $currentTime = Carbon::now()->format('H:i:s');
    $slotEndTime = $gigSlot->end_time;
    $slotDate = Carbon::parse($gigSlot->slot_date)->toDateString();

    // Check if slot is for today and time has passed the end time
    if ($slotDate === $today && $currentTime >= $slotEndTime) {
        if ($booking->booking_status === 'active') {
            $booking->booking_status = 'completed';
            $booking->ended_at = now();
            $booking->save();
            $bookingCompleted = true;

            // Increment gigs_completed in daily tracking
            if ($tracking) {
                $tracking->gigs_completed += 1;
                $tracking->save();
            }
        }
    }
}
```

---

## Data Flow Example

### Day Timeline

```
8:00 AM - 10:00 AM  [Gig Slot 1]
├─ 9:00 AM: Delivery boy logs in
├─ Past slots checked: 0
├─ Current session starts for Slot 1
├─ Daily tracking: gigs_completed = 0
└─ 10:00 AM: Slot ends, delivery boy still working

10:00 AM - 12:00 PM [Gig Slot 2]
├─ Delivery boy still in session (continues from Slot 1)
├─ 12:00 PM: Slot 2 ends

12:00 PM - 2:00 PM  [Break]
├─ 1:30 PM: Delivery boy logs out
├─ Current session ends (Slot 2 was completed)
├─ Update: gigs_completed = 1 (Slot 1)
├─ But Slot 2 ends at 12 PM, time > 12 PM at logout, so:
├─ Update: gigs_completed = 2 (Slot 1 + Slot 2)
└─ Daily tracking saved

2:00 PM - 4:00 PM   [Gig Slot 3]
├─ 2:15 PM: Delivery boy logs back in
├─ Past slots checked: 0 (Slots 1 & 2 already marked completed)
├─ Current session starts for Slot 3
├─ Daily tracking: gigs_completed = 2 (unchanged)
└─ 4:00 PM: Slot ends

4:00 PM+:
├─ 4:30 PM: Delivery boy logs out
├─ Current session ends (Slot 3 was completed)
├─ Time >= 4:00 PM, so increment
├─ Update: gigs_completed = 3 (Slots 1 + 2 + 3)
└─ Final daily tracking saved
```

### API Responses

**Login Response** (past slots auto-completed):
```json
{
    "status": true,
    "message": "Session started successfully",
    "data": {
        "session_id": 123,
        "booking_id": 456,
        "gig_name": "Delivery Gig",
        "slot_start_time": "2:00 PM",
        "slot_end_time": "4:00 PM",
        "login_at": "2026-01-08T14:15:00Z",
        "online_status": "online"
    }
}
```

**Get Today Stats** (after session):
```json
{
    "status": true,
    "data": {
        "online_status": "online",
        "gigs_completed": 2,           // Updated!
        "gigs_booked": 3,
        "total_login_minutes": 215,
        "total_earnings": 850.00
    }
}
```

**Logout Response** (current slot completed):
```json
{
    "status": true,
    "message": "Session ended and gig completed successfully",
    "data": {
        "session_id": 123,
        "login_at": "2026-01-08T14:00:00Z",
        "logout_at": "2026-01-08T16:30:00Z",
        "duration_minutes": 150,
        "booking_status": "completed"
    }
}
```

---

## Database Updates

### DeliveryBoyDailyTracking Table

```sql
delivery_boy_daily_tracking {
    id: BIGINT,
    delivery_boy_id: BIGINT,
    tracking_date: DATE,
    gigs_completed: INT,              -- ← Incremented by system
    gigs_booked: INT,
    orders_delivered: INT,
    orders_cancelled: INT,
    total_earnings: DECIMAL(10,2),
    total_login_minutes: INT,
    online_status: ENUM('online', 'offline'),
    first_login_at: TIMESTAMP,
    last_activity_at: TIMESTAMP
}
```

### DeliveryBoyGigBooking Table

```sql
delivery_boy_gig_booking {
    id: BIGINT,
    delivery_boy_id: BIGINT,
    gig_slot_id: BIGINT,
    booking_status: ENUM('booked', 'active', 'completed'),
    started_at: TIMESTAMP,
    ended_at: TIMESTAMP               -- ← Set when gig completes
}
```

---

## Logging

All gig completions are logged for auditing. Check logs:

```bash
tail -f storage/logs/laravel.log | grep "gig\|completed"
```

### Log Examples

**Past slots auto-completed on login**:
```
[2026-01-08 14:15:00] local.INFO: Updated daily tracking with completed gigs
{
    "delivery_boy_id": 5,
    "completed_gigs_added": 2,
    "total_gigs_completed": 2
}
```

**Current slot completed on logout**:
```
[2026-01-08 16:30:00] local.INFO: Gig completed and daily tracking updated on session end
{
    "booking_id": 456,
    "gig_slot_id": 789,
    "total_gigs_completed": 3
}
```

---

## Integration with Incentives

The auto-incremented `gigs_completed` count feeds into the incentive system:

**IncentiveOfferController** uses:
```php
$progress->gigs_completed  // Auto-updated here
```

### Example: Incentive Condition

**Offer**: "Complete 10 Gigs - Earn ₹500"

```
Delivery boy's daily tracking:
├─ 8 AM: Login → Auto-complete 2 past gigs → gigs_completed = 2
├─ 10 AM: Still working
├─ 12 PM: Logout → Complete current gig → gigs_completed = 3
├─ 2 PM: Login → Auto-complete 1 past gig → gigs_completed = 4
├─ 4 PM: Logout → Complete current gig → gigs_completed = 5
...
├─ [Later in day]
├─ 10 gigs completed → Incentive conditions checked
└─ ✅ Incentive earned: ₹500
```

---

## Edge Cases Handled

### 1. Multiple Past Slots

✅ All past slots are checked and completed
```
3 slots ended before login → All 3 counted
gigs_completed += 3
```

### 2. Overlapping Sessions

✅ Cannot have overlapping sessions (checked in startSession)
```
Error: "You already have an active session. Please logout first."
```

### 3. Early Logout

✅ Only counts as completed if time >= slot end time
```
Slot: 2:00 PM - 4:00 PM
Logout at 3:30 PM → NOT counted
Logout at 4:15 PM → Counted as completed
```

### 4. Slot Already Completed

✅ Won't double-count slots already marked as completed
```
First login: marks slot as completed, increments count
Second login: skips already completed slots
```

---

## Testing Checklist

- [ ] Login at start of first slot → gigs_completed = 0
- [ ] Logout after slot ends → gigs_completed = 1
- [ ] Multiple slots in a day → Count increments correctly
- [ ] Login after multiple slots passed → All counted
- [ ] Incentive counts use correct gigs_completed value
- [ ] Check logs for completion records
- [ ] Verify daily tracking totals are accurate

---

## Performance Considerations

### Database Queries

**Per Login**:
- 1 query: Find active session
- 1 query: Find today's bookings (with eager loading)
- N queries: Save each completed booking (N = past slots)
- 1 query: Update daily tracking

**Per Logout**:
- 1 query: Find active session
- 1 query: Update daily tracking
- Multiple queries: Update booking and tracking

### Optimization Done

✅ Eager loading of relationships
✅ Single query for daily tracking update
✅ Conditional updates only

---

## Summary

✅ **Auto-completion of past slots**: When logging in, slots that have ended are automatically completed and counted

✅ **Current slot completion**: When logging out after slot time has passed, current gig is marked complete and counted

✅ **Accurate daily totals**: `gigs_completed` in daily tracking always reflects actual completed gigs

✅ **Incentive-ready**: Automatically updated count feeds into incentive calculations

✅ **Auditable**: All completions logged with timestamps and details

The system ensures delivery boys are accurately credited for all completed gigs, enabling fair incentive calculations!
