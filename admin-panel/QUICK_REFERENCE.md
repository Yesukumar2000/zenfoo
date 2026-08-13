# Incentive Offers API - Quick Reference Card

## New Fields in my_progress

```
previous_target_amount  → ₹1000  (Last tier reached)
current_target_amount   → ₹1500  (Next tier target)
total_target_amount     → ₹1500  (Maximum target)
amount_needed           → ₹300   (How much more needed)
progress_percentage     → 40%    (Progress to next tier: 0-100%)
overall_progress_percentage → 80% (Total completion: 0-100%)
```

---

## What Each Field Means

| Field | Meaning | Use Case |
|-------|---------|----------|
| `progress_percentage` | How far between current and next tier (0-100) | **Progress bar fill** |
| `amount_needed` | Exact amount still needed for next tier | **"₹300 more needed"** text |
| `previous_target_amount` | Target of last tier achieved (or 0) | **Show where user came from** |
| `current_target_amount` | Target to reach for next tier | **Show tier target** |
| `overall_progress_percentage` | Total journey progress (0-100) | **Show overall completion** |
| `total_target_amount` | Maximum possible target | **Calculate overall %** |

---

## Mobile Display Quick Guide

### Progress Bar
```dart
LinearProgressIndicator(
  value: myProgress['progress_percentage'] / 100
);
```

### Show Needed Amount
```dart
Text('₹${myProgress["amount_needed"]} to go');
```

### Show Targets
```dart
Text('₹${myProgress["previous_target_amount"]} → '
     '₹${myProgress["current_target_amount"]}');
```

### Overall Progress
```dart
Text('${myProgress["overall_progress_percentage"]}% Complete');
```

### All Tier Markers
```dart
offer['tiers'].map((tier) =>
  _marker(tier['earnings_target'], tier['is_achieved'])
)
```

---

## Starting Tier (Tier 0)

**Always present at beginning of tiers array:**

```json
{
  "tier_name": "Start",
  "earnings_target": 0.00,
  "is_achieved": true,
  "incentive_amount": 0.00
}
```

**Display as**: "₹0" marker on timeline

---

## API Endpoints

### Active Offers (Best for Mobile)
```
GET /api/delivery_boy/offers/active
```
Returns: All active offers with progress metrics

### All Offers (For Display)
```
GET /api/delivery_boy/all-offers
```
Returns: Active, upcoming, and expired offers

---

## Quick Calculation Reference

**User earned ₹1200, tiers are ₹500, ₹1000, ₹1500:**

```
Step 1: Find previous tier
  ✓ ₹1200 >= ₹500 (Tier 1)
  ✓ ₹1200 >= ₹1000 (Tier 2)
  ✗ ₹1200 < ₹1500 (Tier 3)
  → previous_target_amount = ₹1000

Step 2: Find current tier
  First tier where ₹1200 < target = ₹1500
  → current_target_amount = ₹1500

Step 3: Calculate between tiers
  Range: ₹1000 to ₹1500 (₹500 range)
  Position: ₹1200 - ₹1000 = ₹200 in
  → progress_percentage = (200/500) * 100 = 40%

Step 4: Amount needed
  → amount_needed = 1500 - 1200 = ₹300

Step 5: Overall progress
  → overall_progress_percentage = (1200/1500) * 100 = 80%
```

---

## Test Your Response

**Check these fields exist:**
```json
✅ my_progress.previous_target_amount
✅ my_progress.current_target_amount
✅ my_progress.total_target_amount
✅ my_progress.amount_needed
✅ my_progress.progress_percentage
✅ my_progress.overall_progress_percentage
✅ tiers[0].tier_name === "Start"
```

**Check these calculations:**
```
✅ progress_percentage is 0-100
✅ overall_progress_percentage is 0-100
✅ amount_needed >= 0 (never negative)
✅ Start tier is achieved
```

---

## Common Scenarios

### User Starting (₹0)
```
previous_target_amount: 0
current_target_amount: 500
progress_percentage: 0%
overall_progress_percentage: 0%
Display: "Start here → ₹500 target (0% done)"
```

### User Halfway (₹750 with ₹500-₹1000-₹1500)
```
previous_target_amount: 500
current_target_amount: 1000
progress_percentage: 50%
overall_progress_percentage: 50%
Display: "50% through tier 2 (₹250 more needed)"
```

### User Completed (₹1500)
```
previous_target_amount: 1500
current_target_amount: 1500
progress_percentage: 100%
overall_progress_percentage: 100%
Display: "✅ Completed! You earned ₹500"
```

---

## Formatting for UI

**Progress bar:**
- Value: `progress_percentage` ÷ 100
- Width: 100% of container
- Fill color: Green (or brand color)

**Text labels:**
- "₹{amount_needed} to go"
- "₹{previous_target} → ₹{current_target}"
- "{overall_progress_percentage}% complete"

**Timeline:**
- Show all items from `tiers` array
- Highlight achieved with ✓
- Show current/next distinctly

---

## No Database Changes

✅ Calculated at response time
✅ No migrations needed
✅ All data generated from existing fields
✅ Safe to deploy immediately

---

## Still Need Help?

📖 Full Reference: [INCENTIVE_PROGRESS_METRICS.md](INCENTIVE_PROGRESS_METRICS.md)
📱 Mobile Patterns: [MOBILE_INCENTIVE_DISPLAY.md](MOBILE_INCENTIVE_DISPLAY.md)
🏗️ Architecture: [STARTING_TIER_IMPLEMENTATION.md](STARTING_TIER_IMPLEMENTATION.md)
✅ Implementation: [IMPLEMENTATION_CHECKLIST.md](IMPLEMENTATION_CHECKLIST.md)
