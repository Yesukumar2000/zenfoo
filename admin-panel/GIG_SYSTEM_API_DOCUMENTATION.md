# Gig Tracking System - API Documentation

## Overview
Complete delivery partner tracking and gig management system with session tracking, gig booking, location monitoring, and incentive offers.

---

## 🔐 Authentication
All APIs require authentication using Laravel Passport token.

**Header:**
```
Authorization: Bearer {token}
```

---

## 📱 Delivery Boy APIs

### 1. Session Management APIs

#### 1.1 Start Session (Login)
**Endpoint:** `POST /api/delivery_boy/session/login`

**Description:** Start work session with GPS location. Creates a new session and marks delivery boy as online.

**Request Body:**
```json
{
  "latitude": 17.4486,
  "longitude": 78.3908,
  "gig_booking_id": 5  // Optional - if starting a booked gig
}
```

**Response:**
```json
{
  "status": true,
  "message": "Session started successfully",
  "data": {
    "session_id": 12,
    "login_at": "2025-01-15T09:00:00+05:30",
    "online_status": "online"
  }
}
```

---

#### 1.2 End Session (Logout)
**Endpoint:** `POST /api/delivery_boy/session/logout`

**Description:** End work session with GPS location. Calculates session duration and updates total login time.

**Request Body:**
```json
{
  "latitude": 17.4486,
  "longitude": 78.3908
}
```

**Response:**
```json
{
  "status": true,
  "message": "Session ended successfully",
  "data": {
    "session_id": 12,
    "login_at": "2025-01-15T09:00:00+05:30",
    "logout_at": "2025-01-15T18:30:00+05:30",
    "duration_minutes": 570,
    "duration_hours": 9.5,
    "online_status": "offline"
  }
}
```

---

#### 1.3 Get Today's Stats
**Endpoint:** `GET /api/delivery_boy/tracking/today`

**Description:** Get real-time statistics for today including running clock for active sessions.

**Response:**
```json
{
  "status": true,
  "message": "Today stats retrieved successfully",
  "data": {
    "online_status": "online",
    "total_login_minutes": 320,
    "total_login_hours": 5.33,
    "login_display_time": "05:20",
    "total_earnings": 450.00,
    "total_distance_km": 25.5,
    "gigs_completed": 1,
    "gigs_booked": 2,
    "orders_delivered": 12,
    "orders_cancelled": 1,
    "first_login_at": "2025-01-15T09:00:00+05:30",
    "last_activity_at": "2025-01-15T14:20:00+05:30",
    "active_session": {
      "session_id": 12,
      "login_at": "2025-01-15T13:00:00+05:30",
      "current_duration_minutes": 80
    }
  }
}
```

**Notes:**
- `total_login_minutes` includes stored hours + active session time (real-time)
- `login_display_time` shows formatted time (HH:MM)
- `active_session` is null when offline

---

#### 1.4 Update Location
**Endpoint:** `POST /api/delivery_boy/location/update`

**Description:** Update GPS location during session. Calculates distance from last location using Haversine formula.

**Request Body:**
```json
{
  "latitude": 17.4500,
  "longitude": 78.3920
}
```

**Response:**
```json
{
  "status": true,
  "message": "Location updated successfully",
  "data": {
    "distance_from_last_km": 1.25,
    "total_distance_today_km": 26.75
  }
}
```

---

### 2. Gig Management APIs

#### 2.1 Get Available Gigs
**Endpoint:** `GET /api/delivery_boy/gigs/available`

**Description:** Get all available gig slots for a specific date. Shows slot availability and booking status.

**Query Parameters:**
- `date` (optional): Date in YYYY-MM-DD format. Defaults to today.

**Example:** `GET /api/delivery_boy/gigs/available?date=2025-01-20`

**Response:**
```json
{
  "status": true,
  "message": "Available gigs retrieved successfully",
  "data": {
    "date": "2025-01-20",
    "gigs": [
      {
        "gig_id": 1,
        "gig_name": "morning",
        "display_name": "Morning Shift",
        "start_time": "06:00:00",
        "end_time": "13:00:00",
        "duration_hours": 7,
        "base_earnings": 300.00,
        "slot_id": 5,
        "slot_date": "2025-01-20",
        "available_slots": 45,
        "total_slots": 50,
        "is_available": true,
        "is_booked": false,
        "booking_status": null,
        "booking_id": null
      },
      {
        "gig_id": 2,
        "gig_name": "afternoon",
        "display_name": "Afternoon Shift",
        "start_time": "13:00:00",
        "end_time": "18:00:00",
        "duration_hours": 5,
        "base_earnings": 250.00,
        "slot_id": 6,
        "slot_date": "2025-01-20",
        "available_slots": 0,
        "total_slots": 50,
        "is_available": false,
        "is_booked": true,
        "booking_status": "booked",
        "booking_id": 25
      }
    ]
  }
}
```

**Notes:**
- Delivery boy can book **multiple gigs** across different slots
- Can book morning AND evening on same day (different slots)
- Can book same shift on different dates (different slots)
- Cannot book the same slot twice

---

#### 2.2 Book a Gig
**Endpoint:** `POST /api/delivery_boy/gigs/book`

**Description:** Book an available gig slot. Uses database transactions and row locking to prevent race conditions.

**Request Body:**
```json
{
  "gig_slot_id": 5
}
```

**Response:**
```json
{
  "status": true,
  "message": "Gig booked successfully",
  "data": {
    "booking_id": 25,
    "gig_name": "Morning Shift",
    "slot_date": "2025-01-20",
    "start_time": "06:00:00",
    "end_time": "13:00:00",
    "base_earnings": 300.00,
    "booking_status": "booked",
    "booked_at": "2025-01-15T14:30:00+05:30"
  }
}
```

**Error Responses:**
- `"This gig slot is fully booked"` - Slot capacity reached
- `"You have already booked this gig slot"` - Cannot book same slot twice

---

#### 2.3 Get My Bookings
**Endpoint:** `GET /api/delivery_boy/gigs/my-bookings`

**Description:** Get all your gig bookings with filters.

**Query Parameters:**
- `status` (optional): Filter by booking_status (booked, active, completed, cancelled)
- `date_from` (optional): Filter from date (YYYY-MM-DD)
- `date_to` (optional): Filter to date (YYYY-MM-DD)

**Example:** `GET /api/delivery_boy/gigs/my-bookings?status=completed&date_from=2025-01-01`

**Response:**
```json
{
  "status": true,
  "message": "Bookings retrieved successfully",
  "data": {
    "bookings": [
      {
        "booking_id": 25,
        "gig_name": "Morning Shift",
        "slot_date": "2025-01-20",
        "start_time": "06:00:00",
        "end_time": "13:00:00",
        "base_earnings": 300.00,
        "actual_earnings": 350.50,
        "booking_status": "completed",
        "orders_completed": 12,
        "orders_cancelled": 1,
        "distance_km": 25.5,
        "booked_at": "2025-01-15T14:30:00+05:30",
        "started_at": "2025-01-20T06:05:00+05:30",
        "ended_at": "2025-01-20T13:15:00+05:30"
      }
    ],
    "total": 1
  }
}
```

**Booking Statuses:**
- `booked` - Reserved but not started
- `active` - Currently working
- `completed` - Finished
- `cancelled` - Cancelled by delivery boy

---

#### 2.4 Cancel Booking
**Endpoint:** `POST /api/delivery_boy/gigs/cancel`

**Description:** Cancel a booked gig. Releases the slot for others to book.

**Request Body:**
```json
{
  "booking_id": 25,
  "reason": "Personal emergency"  // Optional
}
```

**Response:**
```json
{
  "status": true,
  "message": "Booking cancelled successfully",
  "data": {
    "booking_id": 25,
    "status": "cancelled"
  }
}
```

**Error Responses:**
- `"Cannot cancel a completed gig"` - Already completed
- `"This booking is already cancelled"` - Already cancelled

---

#### 2.5 Complete Gig
**Endpoint:** `POST /api/delivery_boy/gigs/complete`

**Description:** Mark gig as completed with earnings and performance data. Updates daily tracking automatically.

**Request Body:**
```json
{
  "booking_id": 25,
  "earnings": 350.50,
  "orders_completed": 12,
  "orders_cancelled": 1,
  "distance_km": 25.5
}
```

**Response:**
```json
{
  "status": true,
  "message": "Gig completed successfully",
  "data": {
    "booking_id": 25,
    "status": "completed",
    "earnings": 350.50,
    "total_earnings_today": 450.00,
    "gigs_completed_today": 2
  }
}
```

---

### 3. Incentive Offer APIs

#### 3.1 Get Active Offers
**Endpoint:** `GET /api/delivery_boy/offers/active`

**Description:** Get all currently active incentive offers with your progress for each offer.

**Response:**
```json
{
  "status": true,
  "message": "Active offers retrieved successfully",
  "data": {
    "offers": [
      {
        "offer_id": 1,
        "name": "Sankranthi Mega Bonus 2025",
        "description": "Celebrate Sankranthi with mega bonuses! Complete gigs and earn up to ₹2000 extra. The more you earn, the bigger your bonus!",
        "banner_image_url": "https://yourapp.com/storage/offers/sankranthi.jpg",
        "start_date": "2025-01-10T00:00:00+05:30",
        "end_date": "2025-02-10T23:59:59+05:30",
        "days_remaining": 25,
        "conditions": {
          "min_gigs_required": 20,
          "max_gigs_skip": 2,
          "max_orders_cancel": 3,
          "login_mandatory": true
        },
        "my_progress": {
          "current_earnings": 1250.00,
          "gigs_completed": 15,
          "gigs_skipped": 0,
          "orders_cancelled": 2,
          "is_eligible": true,
          "current_tier": {
            "tier_name": "Silver",
            "earnings_target": 1000.00,
            "incentive_amount": 210.00,
            "achieved": true
          },
          "next_tier": {
            "tier_name": "Gold",
            "earnings_target": 2000.00,
            "incentive_amount": 500.00,
            "remaining_earnings": 750.00,
            "progress_percentage": 62.5
          }
        },
        "tiers": [
          {
            "tier_name": "Bronze",
            "earnings_target": 500.00,
            "incentive_amount": 100.00,
            "is_achieved": true,
            "order": 1
          },
          {
            "tier_name": "Silver",
            "earnings_target": 1000.00,
            "incentive_amount": 210.00,
            "is_achieved": true,
            "order": 2
          },
          {
            "tier_name": "Gold",
            "earnings_target": 2000.00,
            "incentive_amount": 500.00,
            "is_achieved": false,
            "order": 3
          },
          {
            "tier_name": "Platinum",
            "earnings_target": 5000.00,
            "incentive_amount": 1500.00,
            "is_achieved": false,
            "order": 4
          }
        ]
      }
    ],
    "total_offers": 1
  }
}
```

---

#### 3.2 Get My Progress
**Endpoint:** `GET /api/delivery_boy/offers/my-progress`

**Description:** Get your progress for all offers you're enrolled in.

**Response:**
```json
{
  "status": true,
  "message": "Progress retrieved successfully",
  "data": {
    "progress": [
      {
        "progress_id": 5,
        "offer_name": "Sankranthi Mega Bonus 2025",
        "offer_id": 1,
        "status": "active",
        "current_earnings": 1250.00,
        "gigs_completed": 15,
        "gigs_skipped": 0,
        "orders_cancelled": 2,
        "login_compliance": true,
        "is_eligible": true,
        "incentive_earned": 210.00,
        "current_tier": {
          "tier_name": "Silver",
          "earnings_target": 1000.00,
          "incentive_amount": 210.00
        },
        "next_tier": {
          "tier_name": "Gold",
          "earnings_target": 2000.00,
          "incentive_amount": 500.00,
          "remaining_earnings": 750.00,
          "progress_percentage": 62.5
        },
        "offer_end_date": "2025-02-10T23:59:59+05:30",
        "days_remaining": 25,
        "eligibility_status": {
          "is_eligible": true,
          "message": "You are eligible for this offer!",
          "issues": []
        }
      }
    ],
    "total_offers": 1
  }
}
```

---

#### 3.3 Get Offer Details
**Endpoint:** `GET /api/delivery_boy/offers/{id}`

**Description:** Get detailed information about a specific offer with your current progress.

**Example:** `GET /api/delivery_boy/offers/1`

**Response:**
```json
{
  "status": true,
  "message": "Offer details retrieved successfully",
  "data": {
    "offer_id": 1,
    "name": "Sankranthi Mega Bonus 2025",
    "description": "Celebrate Sankranthi with mega bonuses! Complete gigs and earn up to ₹2000 extra. The more you earn, the bigger your bonus!",
    "banner_image_url": "https://yourapp.com/storage/offers/sankranthi.jpg",
    "start_date": "2025-01-10T00:00:00+05:30",
    "end_date": "2025-02-10T23:59:59+05:30",
    "days_remaining": 25,
    "status": "active",
    "conditions": {
      "min_gigs_required": 20,
      "max_gigs_skip": 2,
      "max_orders_cancel": 3,
      "login_mandatory": true
    },
    "my_progress": {
      "current_earnings": 1250.00,
      "gigs_completed": 15,
      "gigs_skipped": 0,
      "orders_cancelled": 2,
      "login_compliance": true,
      "is_eligible": true,
      "incentive_earned": 210.00,
      "eligibility_status": {
        "is_eligible": true,
        "message": "You are eligible for this offer!",
        "issues": []
      }
    },
    "tiers": [
      {
        "tier_name": "Bronze",
        "earnings_target": 500.00,
        "incentive_amount": 100.00,
        "is_achieved": true,
        "progress_percentage": 100.0,
        "remaining_earnings": 0,
        "order": 1
      },
      {
        "tier_name": "Silver",
        "earnings_target": 1000.00,
        "incentive_amount": 210.00,
        "is_achieved": true,
        "progress_percentage": 100.0,
        "remaining_earnings": 0,
        "order": 2
      },
      {
        "tier_name": "Gold",
        "earnings_target": 2000.00,
        "incentive_amount": 500.00,
        "is_achieved": false,
        "progress_percentage": 62.5,
        "remaining_earnings": 750.00,
        "order": 3
      }
    ]
  }
}
```

**Eligibility Issues (when not eligible):**
```json
{
  "eligibility_status": {
    "is_eligible": false,
    "message": "Complete the requirements to become eligible",
    "issues": [
      "Complete 5 more gigs",
      "Too many orders cancelled (5/3)"
    ]
  }
}
```

---

## 🗂️ Database Schema

### Tables Created

1. **gigs** - Work shift definitions (morning, afternoon, evening, night)
2. **gig_slots** - Specific date-time slots for each gig
3. **delivery_boy_gig_bookings** - Booking records with earnings/performance
4. **delivery_boy_daily_tracking** - Daily aggregated stats
5. **delivery_boy_sessions** - Login/logout tracking with GPS
6. **incentive_offers** - Incentive campaign definitions
7. **incentive_offer_tiers** - Multi-tier reward structure
8. **delivery_boy_incentive_progress** - Individual progress tracking
9. **delivery_boy_location_history** - GPS tracking history

---

## 🚀 Setup Instructions

### 1. Run Migrations
```bash
php artisan migrate
```

This will create all 9 tables required for the gig tracking system.

### 2. Seed Sample Data
```bash
php artisan db:seed --class=GigSystemSeeder
```

This will create:
- 4 Gigs (Morning, Afternoon, Evening, Night)
- 120 Gig Slots (30 days × 4 gigs)
- 3 Incentive Offers (Sankranthi, Diwali, New Year)
- 11 Offer Tiers with different earning targets

### 3. Test APIs
Use Postman or any API testing tool with the documented endpoints.

---

## 📊 Key Features

### ✅ Multi-Gig Booking
- Delivery boys can book **multiple gigs** across different slots
- Can book morning AND evening on the same day
- Can book same shift type on different dates
- Cannot book the same slot twice

### ✅ Real-time Tracking
- Login hours calculated as: **stored hours + active session time**
- Running clock updates automatically during active session
- Location tracking with distance calculation (Haversine formula)
- Daily stats aggregation

### ✅ Transaction Safety
- Database transactions for atomic operations
- Pessimistic locking (`lockForUpdate()`) to prevent race conditions
- Slot capacity management with automatic status updates

### ✅ Multi-tier Incentives
- Flexible tier-based rewards
- Eligibility conditions (min gigs, max cancellations, login compliance)
- Auto-calculation of current tier and next tier
- Progress percentage tracking

### ✅ Comprehensive Logging
- All critical operations logged for debugging
- Error tracking with stack traces
- Audit trail for bookings and completions

---

## 🔧 Technical Implementation

### Distance Calculation
Uses **Haversine formula** for accurate spherical distance:
```php
private function calculateDistance($lat1, $lon1, $lat2, $lon2) {
    $earthRadius = 6371; // km
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);

    $a = sin($dLat/2) * sin($dLat/2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon/2) * sin($dLon/2);

    $c = 2 * atan2(sqrt($a), sqrt(1-$a));
    return $earthRadius * $c;
}
```

### Real-time Login Hours
```php
$currentLoginMinutes = $tracking->total_login_minutes;

if ($activeSession) {
    $sessionMinutes = Carbon::parse($activeSession->login_at)
        ->diffInMinutes(now());
    $currentLoginMinutes += $sessionMinutes;
}
```

### Race Condition Prevention
```php
DB::beginTransaction();
try {
    $gigSlot = GigSlot::lockForUpdate()->find($slotId);
    // ... booking logic
    DB::commit();
} catch (\Exception $e) {
    DB::rollBack();
    throw $e;
}
```

---

## 📝 Notes

- All datetime fields use ISO 8601 format
- All monetary values use 2 decimal precision
- GPS coordinates stored with 8 decimal precision
- All routes require authentication except public endpoints
- Database connection must be configured in `.env` before running migrations

---

## 🆘 Support

For issues or questions, please check:
1. Database connection in `.env` file
2. Laravel Passport authentication setup
3. Migration status: `php artisan migrate:status`
4. Application logs: `storage/logs/laravel.log`
