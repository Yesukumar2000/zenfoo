# Delivery Boy Login Time - Real-Time Updates Guide

## Overview

The API now provides data for accurate real-time login time tracking on the mobile app, supporting cumulative time across multiple sessions throughout the day.

## Scenario Example

**Delivery Boy Login Pattern**:
1. **Session 1**: Login at 9:00 AM, Logout at 10:00 AM = 60 minutes
2. **Session 2**: Login at 2:00 PM, Logout at 4:00 PM = 120 minutes
3. **Session 3** (Current): Login at 6:00 PM, Still logged in

**Expected Display**:
- After Session 1 ends: Total = 60 min
- After Session 2 ends: Total = 180 min (60 + 120)
- During Session 3 (real-time): Total = 180+ min (180 + current session duration)

---

## API Response Structure

### Endpoint

```
GET /api/delivery_boy/tracking/today
```

### Response

```json
{
    "status": true,
    "message": "Today stats retrieved successfully",
    "data": {
        "online_status": "online",
        "total_login_minutes": 185,
        "total_login_hours": 3.08,
        "login_display_time": "3h 5m",
        "login_time_sync": {
            "accumulated_minutes": 180,
            "current_session_minutes": 5,
            "server_time": "2026-01-08T18:05:30Z",
            "active_session_started_at": "2026-01-08T18:00:00Z"
        },
        "total_earnings": 2500.00,
        "total_distance_km": 45.50,
        "gigs_completed": 5,
        "gigs_booked": 2,
        "orders_delivered": 12,
        "orders_cancelled": 1,
        "first_login_at": "2026-01-08T09:00:00Z",
        "last_activity_at": "2026-01-08T18:05:00Z",
        "active_session": {
            "session_id": 3,
            "login_at": "2026-01-08T18:00:00Z",
            "current_duration_minutes": 5
        }
    }
}
```

---

## Key Fields for Real-Time Updates

### 1. **`login_time_sync`** (New - For Real-Time Updates)

This object provides all data needed for real-time tracking on mobile:

```json
{
    "accumulated_minutes": 180,              // Total from all COMPLETED sessions
    "current_session_minutes": 5,            // Minutes in CURRENT active session
    "server_time": "2026-01-08T18:05:30Z",  // Server timestamp when API called
    "active_session_started_at": "2026-01-08T18:00:00Z"  // When current session started
}
```

### 2. **`total_login_minutes`** (Cumulative Total)

Already calculated total including current session:
```
total_login_minutes = accumulated_minutes + current_session_minutes
```

### 3. **`total_login_hours`** & **`login_display_time`**

Formatted versions for display:
- `total_login_hours`: 3.08 (decimal)
- `login_display_time`: "3h 5m" (human readable)

---

## Mobile App Implementation

### Strategy 1: Polling Updates (Every 10-30 seconds)

Call the API every 10-30 seconds and update the display:

**Pseudocode (Flutter/Dart)**:
```dart
Future<void> startLoginTimeTracking() async {
    // Call API initially
    var response = await api.getTodayStats();
    var loginData = response.data['login_time_sync'];
    var totalMinutes = response.data['total_login_minutes'];

    // Display
    displayLoginTime(totalMinutes);

    // Poll every 10 seconds
    Timer.periodic(Duration(seconds: 10), (timer) async {
        var newResponse = await api.getTodayStats();
        var newTotal = newResponse.data['total_login_minutes'];
        displayLoginTime(newTotal);
    });
}
```

**Pros**: Simple, always accurate
**Cons**: More API calls

---

### Strategy 2: Smart Client-Side Timer (Recommended)

Use `login_time_sync` data to calculate elapsed time locally, sync every minute:

**Pseudocode (Flutter/Dart)**:
```dart
class LoginTimeTracker {
    int accumulatedMinutes = 0;
    DateTime? activeSessionStartedAt;
    DateTime? lastServerSyncTime;
    Timer? updateTimer;

    void startTracking(Map loginTimeSync) {
        // Get initial values from API
        accumulatedMinutes = loginTimeSync['accumulated_minutes'];
        activeSessionStartedAt = DateTime.parse(loginTimeSync['active_session_started_at']);
        lastServerSyncTime = DateTime.parse(loginTimeSync['server_time']);

        // Update UI every second (local calculation, no API calls)
        updateTimer = Timer.periodic(Duration(seconds: 1), (_) {
            if (activeSessionStartedAt != null) {
                int elapsedSinceSessionStart = DateTime.now()
                    .difference(activeSessionStartedAt!)
                    .inMinutes;

                int totalMinutes = accumulatedMinutes + elapsedSinceSessionStart;
                updateDisplay(totalMinutes);
            }
        });

        // Sync with server every 60 seconds
        Timer.periodic(Duration(seconds: 60), (timer) async {
            syncWithServer();
        });
    }

    Future<void> syncWithServer() async {
        try {
            var response = await api.getTodayStats();
            var loginData = response.data['login_time_sync'];

            // Update accumulated time
            accumulatedMinutes = loginData['accumulated_minutes'];
            activeSessionStartedAt = DateTime.parse(
                loginData['active_session_started_at']
            );
            lastServerSyncTime = DateTime.parse(loginData['server_time']);

            // UI updates automatically from timer
        } catch (e) {
            Log.error('Failed to sync login time: $e');
        }
    }
}
```

**Pros**:
- Smooth real-time updates (every second)
- Minimal API calls (only sync once per minute)
- Works offline briefly

**Cons**:
- More complex implementation
- Can drift if user's device time is wrong

---

### Strategy 3: Hybrid (Best Practice)

Combine both strategies:

```dart
class HybridLoginTimeTracker {
    // Initialize with smart timer (Strategy 2)
    // But if user pauses and resumes app, re-sync (Strategy 1)

    void onAppResumed() {
        // Quick sync when app comes to foreground
        syncWithServer();
    }

    void onAppPaused() {
        // Pause timer when app goes to background
        stopLocalTimer();
    }

    void onSessionTimeout() {
        // If no updates for 5 minutes, force re-sync
        syncWithServer();
    }
}
```

---

## Implementation Examples

### Complete Flutter Example

```dart
import 'package:flutter/material.dart';
import 'dart:async';

class DeliveryBoyLoginTimer extends StatefulWidget {
    @override
    _DeliveryBoyLoginTimerState createState() => _DeliveryBoyLoginTimerState();
}

class _DeliveryBoyLoginTimerState extends State<DeliveryBoyLoginTimer>
    with WidgetsBindingObserver {

    int totalLoginMinutes = 0;
    DateTime? activeSessionStartedAt;
    Timer? uiUpdateTimer;
    Timer? syncTimer;

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
        fetchAndStartTracking();
    }

    Future<void> fetchAndStartTracking() async {
        try {
            final response = await apiClient.getTodayStats();
            final data = response['data'];
            final loginSync = data['login_time_sync'];

            setState(() {
                totalLoginMinutes = data['total_login_minutes'];
                activeSessionStartedAt = DateTime.parse(
                    loginSync['active_session_started_at'] ?? 'null'
                );
            });

            // Start local timer for UI updates
            startLocalTimer();

            // Start sync timer for accuracy
            startServerSync();

        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load tracking'))
            );
        }
    }

    void startLocalTimer() {
        uiUpdateTimer = Timer.periodic(Duration(seconds: 1), (_) {
            if (activeSessionStartedAt != null) {
                setState(() {
                    int elapsedMinutes = DateTime.now()
                        .difference(activeSessionStartedAt!)
                        .inMinutes;
                });
            }
        });
    }

    void startServerSync() {
        syncTimer = Timer.periodic(Duration(seconds: 60), (_) {
            syncLoginTime();
        });
    }

    Future<void> syncLoginTime() async {
        try {
            final response = await apiClient.getTodayStats();
            final loginSync = response['data']['login_time_sync'];

            setState(() {
                totalLoginMinutes = response['data']['total_login_minutes'];
                activeSessionStartedAt = DateTime.parse(
                    loginSync['active_session_started_at'] ?? 'null'
                );
            });
        } catch (e) {
            // Silent fail, continue with local timer
            debugPrint('Sync failed: $e');
        }
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
        if (state == AppLifecycleState.resumed) {
            // Re-sync when app comes to foreground
            syncLoginTime();
        }
    }

    String formatTime(int minutes) {
        int hours = minutes ~/ 60;
        int mins = minutes % 60;
        return '${hours}h ${mins}m';
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            children: [
                Text(
                    formatTime(totalLoginMinutes),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                if (activeSessionStartedAt != null)
                    Text(
                        'Currently Online',
                        style: TextStyle(color: Colors.green)
                    ),
            ],
        );
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        uiUpdateTimer?.cancel();
        syncTimer?.cancel();
        super.dispose();
    }
}
```

---

## Data Flow Explanation

### Session 1 (9:00 AM - 10:00 AM)

**API Response at 10:00 AM (after logout)**:
```json
{
    "login_time_sync": {
        "accumulated_minutes": 60,
        "current_session_minutes": 0,
        "active_session_started_at": null
    },
    "total_login_minutes": 60
}
```

**Mobile Display**: `1h 0m`

---

### Session 2 (2:00 PM - 4:00 PM)

**API Response at 3:00 PM (during session)**:
```json
{
    "login_time_sync": {
        "accumulated_minutes": 60,
        "current_session_minutes": 60,
        "server_time": "2026-01-08T15:00:00Z",
        "active_session_started_at": "2026-01-08T14:00:00Z"
    },
    "total_login_minutes": 120
}
```

**Mobile Display** (real-time):
- Initial: `2h 0m`
- After 30 seconds (local): `2h 0m 30s`
- After 1 minute (local): `2h 1m`
- After sync at 3:01 PM: Re-sync and continue

---

### Session 3 (6:00 PM - Ongoing)

**API Response at 6:05 PM (during session)**:
```json
{
    "login_time_sync": {
        "accumulated_minutes": 180,  // 60 + 120 from previous sessions
        "current_session_minutes": 5,
        "server_time": "2026-01-08T18:05:00Z",
        "active_session_started_at": "2026-01-08T18:00:00Z"
    },
    "total_login_minutes": 185
}
```

**Mobile Display** (real-time):
- Initial: `3h 5m`
- After 30 seconds (local): `3h 5m 30s`
- After 1 minute (local): `3h 6m`
- Continues incrementing until logout or sync

---

## Key Points for Mobile Implementation

### ✅ Do This

1. **Use `login_time_sync` for local calculations**
   - Calculate elapsed time locally every second
   - Smooth UI updates without API calls

2. **Sync every 60 seconds**
   - Keep accumulated time in sync
   - Prevents drift from device clock issues

3. **Handle app lifecycle**
   - Re-sync when app resumes from background
   - Pause timer when app goes to background

4. **Format display nicely**
   - Show as "3h 5m" or "Xh Ym Zs"
   - Update every 1-5 seconds

### ❌ Don't Do This

1. **Don't use total_login_minutes as a static value**
   - It becomes stale immediately
   - Re-calculate from sync data

2. **Don't poll API every second**
   - Wastes battery and bandwidth
   - Use local timer instead

3. **Don't ignore server time**
   - Device clock can be wrong
   - Sync regularly for accuracy

---

## Testing Checklist

- [ ] Login and verify "0m" displays
- [ ] Wait 1 minute, verify time increments to "1m"
- [ ] Logout and login again, verify time continues (doesn't reset)
- [ ] Check that time shows "2m" on second session start
- [ ] Minimize and restore app, verify time updates correctly
- [ ] Check displayed time matches server total_login_minutes ±1 minute

---

## Summary

**For real-time login time tracking:**
1. Call API endpoint to get `login_time_sync` data
2. Use local timer to update display every 1-5 seconds
3. Sync with server every 60 seconds
4. Re-sync when app resumes from background

This provides smooth, responsive UI with minimal API calls and accurate time tracking across multiple sessions.
