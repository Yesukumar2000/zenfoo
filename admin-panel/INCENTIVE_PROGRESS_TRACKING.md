# Delivery Boy Incentive Progress Tracking

## Overview

The system now automatically tracks incentive progress when delivery boys complete orders. When `markDelivered` or `collectCash` is called, the incentive progress is updated based on the delivery boy's performance metrics.

---

## How It Works

### 1. Order Completion Flow

When a delivery boy completes an order:

```
markDelivered() or collectCash()
    ↓
Order details saved to database
    ↓
Daily tracking updated (earnings, orders_delivered, etc.)
    ↓
Database transaction committed
    ↓
DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion()
    ↓
For each active incentive offer:
    ├─ Get or create progress record
    ├─ Check eligibility conditions
    ├─ Update current earnings from daily tracking
    ├─ Update gigs_completed and orders_cancelled
    └─ Check if new tier achieved
```

### 2. Files Modified

**Controller**:
- [app/Http/Controllers/API/DeliveryBoy/OrderController.php](app/Http/Controllers/API/DeliveryBoy/OrderController.php)
  - Line 20: Added import for `DeliveryBoyIncentiveService`
  - Line 1426: Added incentive tracking call in `collectCash()` method
  - Line 1825: Added incentive tracking call in `markDelivered()` method

**Service Created**:
- [app/Services/DeliveryBoyIncentiveService.php](app/Services/DeliveryBoyIncentiveService.php)
  - Centralized service for incentive tracking
  - Handles progress updates and tier achievement checks

---

## Incentive Progress Tracking Details

### What Gets Updated

When an order is completed, the service updates:

| Field | Source | Description |
|-------|--------|-------------|
| `current_earnings` | `delivery_boy_daily_tracking.total_earnings` | Total earnings for today |
| `gigs_completed` | `delivery_boy_daily_tracking.gigs_completed` | Completed gigs count |
| `orders_cancelled` | `delivery_boy_daily_tracking.orders_cancelled` | Cancelled orders count |
| `achieved_tier_id` | Calculated | ID of highest achieved tier |
| `incentive_earned` | From `incentive_offer_tiers` | Amount earned from achieved tier |
| `is_completed` | Calculated | Whether all tiers are completed |

### Eligibility Checks

The system verifies these conditions before updating progress:

1. **Minimum Gigs Required**: `offer->min_gigs_required`
   - If specified, progress must have completed at least this many gigs
   - Status remains "active" even if not met (not failed)

2. **Maximum Gigs Skipped**: `offer->max_gigs_skip`
   - If exceeded, delivery boy becomes ineligible
   - Progress status set to "ineligible"

3. **Maximum Orders Cancelled**: `offer->max_orders_cancel`
   - If exceeded, delivery boy becomes ineligible
   - Progress status set to "ineligible"

4. **Login Mandatory**: `offer->login_mandatory`
   - If required, progress must have `login_compliance = true`
   - If failed, delivery boy becomes ineligible

### Tier Achievement Logic

```
For each tier in the offer (ordered by earnings_target):
    if current_earnings >= tier.earnings_target:
        tier_achieved = true
        if tier_id != previous_achieved_tier_id:
            Update achieved_tier_id
            Update incentive_earned to tier.incentive_amount

            if this is the highest tier:
                Set is_completed = true
                Set completed_at = now()
                Set status = "completed"
```

---

## Data Structure

### DeliveryBoyIncentiveProgress Table

```sql
delivery_boy_incentive_progress {
    id: BIGINT PRIMARY KEY,
    delivery_boy_id: BIGINT,
    incentive_offer_id: BIGINT,
    current_earnings: DECIMAL(10,2),      -- Total earnings for today
    gigs_completed: INT,                   -- Completed gigs
    gigs_skipped: INT,                     -- Skipped gigs
    orders_cancelled: INT,                 -- Cancelled orders
    login_compliance: BOOLEAN,             -- Login requirement met
    is_eligible: BOOLEAN,                  -- Overall eligibility
    is_completed: BOOLEAN,                 -- All tiers achieved
    incentive_earned: DECIMAL(10,2),      -- Total incentive from highest tier
    achieved_tier_id: BIGINT,              -- ID of highest achieved tier
    payout_amount: DECIMAL(10,2),         -- Amount to payout
    payout_status: VARCHAR(50),            -- pending, completed, etc
    payout_processed_at: TIMESTAMP,
    completed_at: TIMESTAMP,               -- When offer was fully completed
    status: VARCHAR(50),                   -- active, ineligible, completed
    created_at: TIMESTAMP,
    updated_at: TIMESTAMP
}
```

---

## Integration Points

### markDelivered() Method

```php
// After saving order, daily tracking, and committing transaction:
DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion($deliveryBoy, $order);
```

**When it's called**:
- When prepaid order is marked delivered
- Called AFTER database transaction is committed
- Called AFTER daily tracking is updated with new earnings

### collectCash() Method

```php
// After saving order, daily tracking, and committing transaction:
DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion($deliveryBoy, $order);
```

**When it's called**:
- When COD order cash is collected
- Called AFTER database transaction is committed
- Called AFTER daily tracking is updated with new earnings and bonus

---

## Example Scenario

### Incentive Setup

**Offer**: "Earn ₹500 Bonus"
- Tier 1: Earn ₹500 from 5 orders → Incentive ₹100
- Tier 2: Earn ₹1000 from 10 orders → Incentive ₹300
- Tier 3: Earn ₹1500 from 15 orders → Incentive ₹500
- Min gigs required: 5
- Max gigs skip: 2
- Max orders cancel: 1
- Login mandatory: Yes

### Delivery Boy Progress

**9:00 AM**: Delivery boy logs in
- Progress created with `current_earnings = 0`

**10:30 AM**: First order delivered, Earnings = ₹120
```
current_earnings: 120
gigs_completed: 1
status: active (not yet at Tier 1)
```

**12:45 PM**: 5th order delivered, Earnings = ₹550
```
current_earnings: 550
gigs_completed: 5
achieved_tier_id: Tier 1 ID
incentive_earned: ₹100
status: active (Tier 1 achieved!)
Mobile app shows: "You earned ₹100 incentive!"
```

**4:30 PM**: 10th order delivered, Earnings = ₹1050
```
current_earnings: 1050
gigs_completed: 10
achieved_tier_id: Tier 2 ID
incentive_earned: ₹300
status: active (Tier 2 achieved!)
Mobile app shows: "You earned ₹300 incentive!"
```

**6:00 PM**: 15th order delivered, Earnings = ₹1520
```
current_earnings: 1520
gigs_completed: 15
achieved_tier_id: Tier 3 ID
incentive_earned: ₹500
is_completed: true
completed_at: 2026-01-08 18:00:00
status: completed (Offer fully completed!)
Mobile app shows: "Offer completed! You earned ₹500!"
```

---

## API Endpoints

### Get Active Offers with Progress

```
GET /api/delivery_boy/offers/active
```

Returns:
```json
{
    "status": true,
    "data": {
        "offers": [
            {
                "offer_id": 1,
                "name": "Earn ₹500 Bonus",
                "my_progress": {
                    "current_earnings": 1520.00,
                    "gigs_completed": 15,
                    "gigs_skipped": 0,
                    "orders_cancelled": 0,
                    "is_eligible": true,
                    "current_tier": {
                        "tier_name": "Tier 3",
                        "earnings_target": 1500.00,
                        "incentive_amount": 500.00,
                        "achieved": true
                    },
                    "next_tier": null  // All tiers achieved
                }
            }
        ]
    }
}
```

### Get My Progress

```
GET /api/delivery_boy/offers/my-progress
```

Returns all delivery boy's progress for active offers with tier information.

### Get Offer Details

```
GET /api/delivery_boy/offers/{id}
```

Returns specific offer details with delivery boy's current progress.

---

## Logging

All incentive progress updates are logged for debugging. Check logs:

```bash
tail -f storage/logs/laravel.log | grep "Incentive Progress"
```

### Log Examples

**Progress updated successfully**:
```
[2026-01-08 14:30:00] local.INFO: Incentive Progress: Updated successfully
{
    "delivery_boy_id": 5,
    "offer_id": 1,
    "progress_id": 12,
    "current_earnings": 550.00
}
```

**New tier achieved**:
```
[2026-01-08 14:30:00] local.INFO: Incentive Progress: New tier achieved
{
    "delivery_boy_id": 5,
    "offer_id": 1,
    "tier_id": 2,
    "tier_name": "Tier 2",
    "incentive_amount": 300.00
}
```

**Offer fully completed**:
```
[2026-01-08 18:00:00] local.INFO: Incentive Progress: Offer fully completed
{
    "delivery_boy_id": 5,
    "offer_id": 1
}
```

**Ineligibility**:
```
[2026-01-08 15:00:00] local.INFO: Incentive Progress: Delivery boy not eligible for offer
{
    "delivery_boy_id": 5,
    "offer_id": 1,
    "reason": "Failed eligibility check"
}
```

---

## Mobile App Integration

### Display Current Incentive Progress

After calling `GET /api/delivery_boy/offers/active`:

```dart
// Show current progress towards next tier
if (myProgress['next_tier'] != null) {
    String progressText =
        '₹${myProgress["current_earnings"]} / ₹${myProgress["next_tier"]["earnings_target"]}';
    String percentComplete =
        '${myProgress["next_tier"]["progress_percentage"]}%';

    showProgressBar(percentComplete);
    showProgressText(progressText);
    showRemainingAmount(myProgress["next_tier"]["remaining_earnings"]);
}
```

### Show Tier Achievement Notification

When `current_tier` changes from previous fetch:

```dart
if (previousProgress?.achievedTierId != currentProgress?.achievedTierId) {
    // New tier achieved!
    showNotification(
        title: "Tier Achieved!",
        message: "You've earned ₹${currentTier['incentive_amount']} incentive",
        icon: "🎉"
    );
}
```

### Show Offer Completion

When `is_completed` is true:

```dart
if (progress['is_completed']) {
    showBanner(
        title: "Offer Completed!",
        message: "You earned ₹${progress['incentive_earned']} from this offer",
        color: Colors.green
    );
}
```

---

## Troubleshooting

### Progress Not Updating

**Check 1**: Verify order was completed
```sql
SELECT * FROM orders WHERE id = ? AND active_status = 6;
```

**Check 2**: Verify daily tracking was updated
```sql
SELECT * FROM delivery_boy_daily_tracking
WHERE delivery_boy_id = ? AND tracking_date = CURDATE();
```

**Check 3**: Check logs for errors
```bash
grep "Incentive Progress.*Error" storage/logs/laravel.log
```

**Check 4**: Verify incentive offer is active
```sql
SELECT * FROM incentive_offers
WHERE status = 1
AND start_date <= NOW()
AND end_date >= NOW();
```

### Tier Not Updating

**Check 1**: Verify earnings are correct
```sql
SELECT current_earnings, achieved_tier_id
FROM delivery_boy_incentive_progress
WHERE delivery_boy_id = ? AND incentive_offer_id = ?;
```

**Check 2**: Compare with tier targets
```sql
SELECT tier_name, earnings_target, incentive_amount
FROM incentive_offer_tiers
WHERE incentive_offer_id = ?
ORDER BY earnings_target;
```

**Check 3**: Check for eligibility issues
```sql
SELECT is_eligible, gigs_skipped, orders_cancelled, login_compliance
FROM delivery_boy_incentive_progress
WHERE delivery_boy_id = ? AND incentive_offer_id = ?;
```

---

## Summary

✅ **Automatic Progress Tracking**: Updated when orders are delivered/cash collected
✅ **Eligibility Verification**: Checks conditions before updating
✅ **Tier Achievement Detection**: Automatically detects and records tier reaches
✅ **Comprehensive Logging**: All updates logged for debugging
✅ **Mobile Ready**: Data structure supports real-time mobile notifications

The system ensures delivery boys are rewarded accurately and in real-time!
