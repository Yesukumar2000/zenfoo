# Mobile Incentive Display - Quick Reference

## Quick Start for Mobile Developers

This guide shows how to display the incentive progress using the new API response structure.

---

## Response Data Structure

```dart
class IncentiveProgress {
  double currentEarnings;           // ₹1200
  double previousTargetAmount;      // ₹1000
  double currentTargetAmount;       // ₹1500
  double totalTargetAmount;         // ₹1500
  double amountNeeded;              // ₹300
  double progressPercentage;        // 40%
  double overallProgressPercentage; // 80%
}
```

---

## Display Patterns

### Pattern 1: Simple Progress Bar

Shows progress between current tier and next tier.

```dart
// ₹1000 - ₹1500 (40% filled)

Column(
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('₹${progress.previousTargetAmount}'),
        Text('₹${progress.currentTargetAmount}'),
      ],
    ),
    SizedBox(height: 8),
    LinearProgressIndicator(
      value: progress.progressPercentage / 100,
      minHeight: 6,
    ),
    SizedBox(height: 8),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('₹${progress.currentEarnings} earned'),
        Text('₹${progress.amountNeeded} to go'),
      ],
    ),
  ],
)
```

**Output:**
```
₹1000            ₹1500
████████░░░░░░░░░░ (40%)
₹1200 earned     ₹300 to go
```

---

### Pattern 2: Multi-Tier Horizontal Timeline

Shows all tier targets on a horizontal line from Start (₹0) to final target.

```dart
// Start: ₹0, Tier 1: ₹500, Tier 2: ₹1000, Tier 3: ₹1500
// User position: ₹1200

Container(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Overall progress indicator
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Overall Progress'),
          Text('${progress.overallProgressPercentage}%'),
        ],
      ),
      SizedBox(height: 4),
      LinearProgressIndicator(
        value: progress.overallProgressPercentage / 100,
        minHeight: 8,
      ),
      SizedBox(height: 12),

      // Tier markers (including Start)
      Stack(
        children: [
          Container(
            height: 2,
            color: Colors.grey[300],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTierMarker('₹0', true),     // Start - always achieved
              _buildTierMarker('₹500', true),   // Tier 1 - Achieved
              _buildTierMarker('₹1000', true),  // Tier 2 - Achieved
              _buildTierMarker('₹1500', false), // Tier 3 - Current
            ],
          ),
        ],
      ),
      SizedBox(height: 8),
      Text('Current: ₹${progress.currentEarnings} / ₹${progress.currentTargetAmount}'),
    ],
  ),
)

Widget _buildTierMarker(String amount, bool achieved) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: achieved ? Colors.green : Colors.grey[300],
    ),
    child: Center(
      child: Text(
        amount,
        style: TextStyle(
          color: achieved ? Colors.white : Colors.black,
          fontSize: 10,
        ),
      ),
    ),
  );
}
```

**Output:**
```
Overall Progress                80%
────●────●────●────●────

₹0    ₹500  ₹1000  ₹1500
✓      ✓      ✓      ◯

Current: ₹1200 / ₹1500
```

---

### Pattern 3: Card View with Details

Complete card showing all incentive information.

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Earn ₹500 Bonus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('7 days remaining', style: TextStyle(color: Colors.grey)),
              ],
            ),
            if (progress.overallProgressPercentage == 100)
              Icon(Icons.check_circle, color: Colors.green, size: 24)
            else
              Text('${progress.overallProgressPercentage}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 12),

        // Main progress bar
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress to next tier'),
                Text('${progress.progressPercentage}%'),
              ],
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress.progressPercentage / 100,
              minHeight: 8,
            ),
          ],
        ),
        SizedBox(height: 12),

        // Amount breakdown
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('Earned', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('₹${progress.currentEarnings}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Column(
                children: [
                  Text('Target', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('₹${progress.currentTargetAmount}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey[300]),
              Column(
                children: [
                  Text('Needed', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('₹${progress.amountNeeded}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12),

        // Tier list (including Start tier)
        Text('Tier Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...offer.tiers.map((tier) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                tier.isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                color: tier.isAchieved ? Colors.green : Colors.grey,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.tierName),
                    if (tier.incentiveAmount > 0)
                      Text('Earn ₹${tier.incentiveAmount}', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      Text('Starting point', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
              Text('₹${tier.earningsTarget}', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )).toList(),
      ],
    ),
  ),
)
```

**Output:**
```
╔════════════════════════════════════════╗
║ Earn ₹500 Bonus                    80% ║
║ 7 days remaining                       ║
║                                        ║
║ Progress to next tier          40%     ║
║ ████████░░░░░░░░░░░░░░░░░░░░░░░░░░  ║
║                                        ║
║ ┌────────────────────────────────────┐ ║
║ │ Earned │ Target │ Needed           │ ║
║ │ ₹1200  │ ₹1500  │ ₹300             │ ║
║ └────────────────────────────────────┘ ║
║                                        ║
║ Tier Progress                          ║
║ ✓ Start         Starting point ... ₹0  ║
║ ✓ Tier 1        Earn ₹100    ... ₹500  ║
║ ✓ Tier 2        Earn ₹300    ... ₹1000 ║
║ ◯ Tier 3        Earn ₹500    ... ₹1500 ║
╚════════════════════════════════════════╝
```

---

### Pattern 4: Notification Banner (Tier Achieved)

Show when a new tier is achieved.

```dart
// Trigger when: previousResponse.achievedTierId != currentResponse.achievedTierId

Container(
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.green[50],
    border: Border(
      left: BorderSide(color: Colors.green, width: 4),
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(Icons.celebration, color: Colors.green, size: 24),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tier Achieved!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            Text('You earned ₹${newTier.incentiveAmount} incentive', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      Icon(Icons.close, color: Colors.grey, size: 20),
    ],
  ),
)
```

**Output:**
```
┌─ ✓ Tier Achieved!                    ╳ ┐
│   You earned ₹300 incentive            │
└────────────────────────────────────────┘
```

---

## Data Validation

Before using the progress metrics, validate the data:

```dart
bool isValidProgress(Map<String, dynamic> progress) {
  // Check required fields
  if (progress['current_earnings'] == null ||
      progress['current_target_amount'] == null) {
    return false;
  }

  // Validate percentage ranges
  if (progress['progress_percentage'] < 0 ||
      progress['progress_percentage'] > 100) {
    return false;
  }

  if (progress['overall_progress_percentage'] < 0 ||
      progress['overall_progress_percentage'] > 100) {
    return false;
  }

  // Validate amount_needed is never negative
  if (progress['amount_needed'] < 0) {
    return false;
  }

  return true;
}
```

---

## Refresh Strategy

The mobile app should refresh at these intervals:

```dart
// 1. Refresh after every order completion
Future<void> refreshIncentiveOffers() async {
  final response = await apiClient.get('/api/delivery_boy/offers/active');
  setState(() {
    offers = response['data']['offers'];
  });
}

// 2. Periodic refresh every 2 minutes (if app is in foreground)
Timer.periodic(Duration(minutes: 2), (_) {
  if (appIsInForeground) {
    refreshIncentiveOffers();
  }
});

// 3. Refresh on app resume
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    refreshIncentiveOffers();
  }
}
```

---

## Caching Strategy

To reduce API calls while maintaining accuracy:

```dart
class IncentiveOfferCache {
  static const Duration CACHE_DURATION = Duration(minutes: 2);
  DateTime? _lastFetchTime;
  List<OfferData>? _cachedOffers;

  Future<List<OfferData>> getOffers() async {
    // If cache is fresh, return cached data
    if (_cachedOffers != null &&
        DateTime.now().difference(_lastFetchTime!) < CACHE_DURATION) {
      return _cachedOffers!;
    }

    // Fetch fresh data
    final response = await apiClient.get('/api/delivery_boy/offers/active');
    _cachedOffers = response['data']['offers'];
    _lastFetchTime = DateTime.now();

    return _cachedOffers!;
  }

  void invalidateCache() {
    _cachedOffers = null;
    _lastFetchTime = null;
  }
}

// Usage:
final cache = IncentiveOfferCache();

// After order completion - refresh immediately
await OrderController.completeOrder(order);
cache.invalidateCache();
offers = await cache.getOffers();

// Normal page load - use cache
offers = await cache.getOffers();
```

---

## Summary

**New fields available for display:**
- `progress_percentage` → Progress bar between tiers (0-100%)
- `overall_progress_percentage` → Overall completion (0-100%)
- `previous_target_amount` → Last achieved tier target
- `current_target_amount` → Next tier target
- `amount_needed` → Amount still needed for next tier

**Use cases:**
- Pattern 1: Simple progress bar between two tiers
- Pattern 2: Multi-tier timeline with all targets
- Pattern 3: Complete card with all details
- Pattern 4: Tier achievement notifications

**Implementation tips:**
- Always validate progress data before displaying
- Refresh after order completion
- Cache response to reduce API calls
- Show celebration UI on tier achievements
