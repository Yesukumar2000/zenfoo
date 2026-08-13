# Incentive Progress Metrics - Mobile App Display

## Overview

The `getActiveOffers()` API now returns detailed progress metrics in the `my_progress` object to enable rich progress visualization on the mobile app. This includes percentage-based progress, target amounts, and earnings needed information.

---

## New Response Structure

### Endpoint
```
GET /api/delivery_boy/offers/active
```

### Response Format

```json
{
  "status": true,
  "message": "Active offers retrieved successfully",
  "data": {
    "offers": [
      {
        "offer_id": 1,
        "name": "Earn ₹500 Bonus",
        "description": "Complete deliveries to earn bonus",
        "banner_image_url": "https://...",
        "start_date": "2026-01-08T00:00:00Z",
        "end_date": "2026-01-15T23:59:59Z",
        "days_remaining": 7,
        "conditions": {
          "min_gigs_required": 5,
          "max_gigs_skip": 2,
          "max_orders_cancel": 1,
          "login_mandatory": true
        },
        "my_progress": {
          "current_earnings": 1200.00,
          "gigs_completed": 10,
          "gigs_skipped": 0,
          "orders_cancelled": 0,
          "is_eligible": true,

          "previous_target_amount": 1000.00,
          "current_target_amount": 1500.00,
          "total_target_amount": 1500.00,
          "amount_needed": 300.00,
          "progress_percentage": 40.00,
          "overall_progress_percentage": 80.00,

          "current_tier": {
            "tier_name": "Tier 2",
            "earnings_target": 1000.00,
            "incentive_amount": 300.00,
            "achieved": true
          },
          "next_tier": {
            "tier_name": "Tier 3",
            "earnings_target": 1500.00,
            "incentive_amount": 500.00,
            "remaining_earnings": 300.00,
            "progress_percentage": 80.00
          }
        },
        "tiers": [
          {
            "tier_name": "Start",
            "earnings_target": 0.00,
            "incentive_amount": 0.00,
            "is_achieved": true,
            "progress_percentage": 100.00,
            "order": 0
          },
          {
            "tier_name": "Tier 1",
            "earnings_target": 500.00,
            "incentive_amount": 100.00,
            "is_achieved": true,
            "progress_percentage": 100.00,
            "order": 1
          },
          {
            "tier_name": "Tier 2",
            "earnings_target": 1000.00,
            "incentive_amount": 300.00,
            "is_achieved": true,
            "progress_percentage": 100.00,
            "order": 2
          },
          {
            "tier_name": "Tier 3",
            "earnings_target": 1500.00,
            "incentive_amount": 500.00,
            "is_achieved": false,
            "progress_percentage": 80.00,
            "order": 3
          }
        ]
      }
    ],
    "total_offers": 1
  }
}
```

---

## Tiers Structure (Including Starting Tier)

The `tiers` array now includes a "Start" tier at position 0 to provide a complete progression visualization:

```
Start (₹0) → Tier 1 (₹500) → Tier 2 (₹1000) → Tier 3 (₹1500)
   ✓ Always achieved    ✓ If earned ≥ ₹500    ✓ If earned ≥ ₹1000    ◯ If earned ≥ ₹1500
```

### Starting Tier (Tier 0)
- **Name**: "Start"
- **Target**: ₹0.00
- **Incentive**: ₹0.00
- **Always Achieved**: `true` (user always starts here)
- **Purpose**: Visual anchor point for progress visualization on mobile
- **Display**: Shows the beginning of the journey

This allows the mobile app to display a complete visual timeline from start (0) to the maximum target amount.

---

## Progress Metrics Explained

### Key Fields in `my_progress`

#### 1. **current_earnings** (Float)
- **Type**: Decimal
- **Example**: `1200.00`
- **Description**: Total earnings accumulated towards this offer today

#### 2. **previous_target_amount** (Float)
- **Type**: Decimal
- **Example**: `1000.00`
- **Description**: The earnings target of the last tier that was achieved
- **Starting State**: `0` (when no tier has been achieved yet)
- **Use Case**: Show "Previous tier: ₹X" in mobile UI

#### 3. **current_target_amount** (Float)
- **Type**: Decimal
- **Example**: `1500.00`
- **Description**: The earnings target for the next tier to be achieved
- **Starting State**: Target of first tier
- **Use Case**: Show "Target: ₹X" in mobile UI

#### 4. **total_target_amount** (Float)
- **Type**: Decimal
- **Example**: `1500.00`
- **Description**: Maximum earnings target (last tier's target)
- **Use Case**: Calculate overall completion percentage

#### 5. **amount_needed** (Float)
- **Type**: Decimal
- **Example**: `300.00`
- **Description**: Amount still needed to reach the next tier
- **Calculation**: `current_target_amount - current_earnings`
- **Minimum**: `0` (when target is reached or exceeded)
- **Use Case**: Show "₹300 more needed" message

#### 6. **progress_percentage** (Float)
- **Type**: Percentage (0-100)
- **Example**: `40.00`
- **Description**: Progress towards the next tier (between previous and current targets)
- **Calculation**:
  - If between tiers: `((current_earnings - previous_target) / (current_target - previous_target)) * 100`
  - If at or beyond last tier: `100`
- **Use Case**: Progress bar fill (40% means bar is 40% filled)

#### 7. **overall_progress_percentage** (Float)
- **Type**: Percentage (0-100)
- **Example**: `80.00`
- **Description**: Overall progress from start to maximum target
- **Calculation**: `(current_earnings / total_target_amount) * 100`
- **Range**: `0-100` (capped at 100)
- **Use Case**: Show overall completion percentage "80% complete"

---

## Mobile App Implementation Examples

### Example 1: Show Progress Between Two Tiers

```dart
// Response data:
// current_earnings: 1200
// previous_target_amount: 1000
// current_target_amount: 1500
// amount_needed: 300
// progress_percentage: 40.00

// Mobile display:
Text('₹${myProgress["previous_target_amount"]} - ₹${myProgress["current_target_amount"]}');
// Output: "₹1000 - ₹1500"

Text('₹${myProgress["current_earnings"]} / ₹${myProgress["current_target_amount"]}');
// Output: "₹1200 / ₹1500"

LinearProgressIndicator(
  value: myProgress["progress_percentage"] / 100,  // 40%
);

Text('₹${myProgress["amount_needed"]} more needed');
// Output: "₹300 more needed"
```

### Example 2: Display Overall Progress

```dart
// Response data:
// current_earnings: 1200
// total_target_amount: 1500
// overall_progress_percentage: 80.00

Container(
  child: Column(
    children: [
      Text('Overall Progress'),
      LinearProgressIndicator(
        value: myProgress["overall_progress_percentage"] / 100,  // 80%
      ),
      Text('${myProgress["overall_progress_percentage"]}% Complete'),
      // Output: "80% Complete"
    ],
  ),
);
```

### Example 3: Show All Tier Targets

```dart
List<TierTarget> tierTargets = [];

// Starting point
tierTargets.add(TierTarget(amount: 0, label: 'Start'));

// Add each tier target
for (var tier in offer["tiers"]) {
  tierTargets.add(TierTarget(
    amount: tier["earnings_target"],
    label: tier["tier_name"],
    incentive: tier["incentive_amount"],
    achieved: tier["is_achieved"],
  ));
}

// Display as horizontal progress line with markers
// User at ₹1200 would be between ₹1000 and ₹1500
// previous_target_amount: 1000 (last marker passed)
// current_target_amount: 1500 (next marker to reach)
```

### Example 4: Show Starting State (No Progress)

```dart
// Response data when delivery boy just started:
// current_earnings: 0
// previous_target_amount: 0
// current_target_amount: 500 (first tier target)
// amount_needed: 500
// progress_percentage: 0

Text('Start earning to reach ₹${myProgress["current_target_amount"]} for ₹100 bonus');
// Output: "Start earning to reach ₹500 for ₹100 bonus"

Text('₹${myProgress["amount_needed"]} to go');
// Output: "₹500 to go"
```

### Example 5: Show Completion State (All Tiers Achieved)

```dart
// Response data when all tiers achieved:
// current_earnings: 1600
// previous_target_amount: 1500 (last tier)
// current_target_amount: 1500 (same as last)
// amount_needed: 0
// progress_percentage: 100
// overall_progress_percentage: 100

Container(
  color: Colors.green,
  child: Column(
    children: [
      Icon(Icons.check_circle, color: Colors.white),
      Text('Offer Completed! 🎉'),
      Text('You earned ₹${offer["my_progress"]["incentive_earned"]}'),
    ],
  ),
);
```

---

## Calculation Logic

### Progressive Calculation for Understanding

Let's walk through an example with three tiers:

```
Tier 1: ₹500 target → ₹100 incentive
Tier 2: ₹1000 target → ₹300 incentive
Tier 3: ₹1500 target → ₹500 incentive
```

**Scenario: Delivery boy earned ₹1200**

```
1. Find previous_target_amount:
   - Last tier where earnings >= target
   - ₹1200 >= ₹1000 (Tier 2)
   - ₹1200 < ₹1500 (Tier 3)
   - Result: previous_target_amount = ₹1000

2. Find current_target_amount:
   - First tier where earnings < target
   - Result: current_target_amount = ₹1500

3. Calculate amount_needed:
   - amount_needed = 1500 - 1200 = ₹300

4. Calculate progress_percentage (between tiers):
   - Range: ₹1000 to ₹1500 (₹500 range)
   - Position: ₹1200 - ₹1000 = ₹200 into range
   - Percentage: (200 / 500) * 100 = 40%

5. Calculate overall_progress_percentage:
   - Total target (last tier): ₹1500
   - Current position: ₹1200
   - Percentage: (1200 / 1500) * 100 = 80%

Response:
{
  "current_earnings": 1200,
  "previous_target_amount": 1000,
  "current_target_amount": 1500,
  "total_target_amount": 1500,
  "amount_needed": 300,
  "progress_percentage": 40.00,
  "overall_progress_percentage": 80.00
}
```

---

## Edge Cases

### Case 1: Starting State (₹0 earned)

```json
{
  "current_earnings": 0,
  "previous_target_amount": 0,
  "current_target_amount": 500,
  "total_target_amount": 1500,
  "amount_needed": 500,
  "progress_percentage": 0,
  "overall_progress_percentage": 0
}
```

### Case 2: Exceeded Maximum Target (₹1600 earned with ₹1500 max)

```json
{
  "current_earnings": 1600,
  "previous_target_amount": 1500,
  "current_target_amount": 1500,
  "total_target_amount": 1500,
  "amount_needed": 0,
  "progress_percentage": 100,
  "overall_progress_percentage": 100
}
```

### Case 3: Exactly at Target (₹1500 earned)

```json
{
  "current_earnings": 1500,
  "previous_target_amount": 1500,
  "current_target_amount": 1500,
  "total_target_amount": 1500,
  "amount_needed": 0,
  "progress_percentage": 100,
  "overall_progress_percentage": 100
}
```

---

## Files Updated

1. **[IncentiveOfferController.php](app/Http/Controllers/API/DeliveryBoy/IncentiveOfferController.php)**
   - Added `calculateProgressMetrics()` method (lines 554-610)
   - Updated `getActiveOffers()` method to use progress metrics (line 63)
   - Updated `formatOfferData()` method to include progress metrics (lines 679-684)

---

## API Methods Using Progress Metrics

1. **GET /api/delivery_boy/offers/active**
   - Uses: `getActiveOffers()` with `calculateProgressMetrics()`
   - Returns: All active offers with detailed progress

2. **GET /api/delivery_boy/all-offers**
   - Uses: `formatOfferData()` with `calculateProgressMetrics()`
   - Returns: Active, upcoming, and expired offers with progress

---

## Testing Checklist

- [ ] Test with ₹0 earnings (starting state)
- [ ] Test between two tiers (₹1200 out of ₹500-₹1500)
- [ ] Test at exact tier target (₹500 earned)
- [ ] Test beyond maximum target (₹1600 earned with ₹1500 max)
- [ ] Verify progress_percentage ranges 0-100
- [ ] Verify overall_progress_percentage ranges 0-100
- [ ] Verify amount_needed is never negative
- [ ] Mobile app displays progress bars correctly
- [ ] Mobile app shows correct target amounts

---

## Summary

The `my_progress` object now provides all necessary data for the mobile app to display:

✅ **Progress visualization** - Use `progress_percentage` for progress bars between tiers
✅ **Target tracking** - Show `current_target_amount` and `amount_needed` for user motivation
✅ **Overall completion** - Use `overall_progress_percentage` for global progress indicator
✅ **Historical context** - Show `previous_target_amount` to indicate reached milestones
✅ **Starting state support** - Handles edge cases with proper calculations

The mobile app can now provide rich, real-time incentive progress tracking with visual progress indicators!
