# Incentive Wallet Crediting - Per-Tier Automatic Balance Updates

## Overview

When a delivery boy achieves a tier in an incentive offer, the earned incentive amount is **automatically credited to their wallet balance**. If multiple tiers are crossed at once, all their incentive amounts are summed and credited together. This ensures immediate reward distribution without manual intervention and prevents double-crediting.

---

## How It Works

### Flow Diagram

```
Order Completed
    ↓
markDelivered() or collectCash()
    ↓
DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion()
    ↓
checkAndUpdateAchievedTier()
    ↓
Find all achievable tiers based on current_earnings
    ↓
Check which tiers already credited (via tier_credits table)
    ↓
Calculate newly crossed tiers (achievable but not credited)
    ↓
If new tiers to credit:
    ├─ Calculate total incentive amount
    ├─ Call creditIncentiveToWallet() with tier info
    │   ├─ Create DeliveryBoyTransaction record
    │   ├─ Increment delivery_boy.balance by total_amount
    │   └─ Log the credit operation
    ├─ Create DeliveryBoyIncentiveTierCredit records
    │   └─ Link each tier to transaction (for audit trail)
    └─ Return transaction
    ↓
Update progress.achieved_tier_id to highest tier
    ↓
If highest tier is final tier:
    ├─ Mark offer as completed
    └─ Set completed_at timestamp
```

### Key Points

✅ **Per-Tier Crediting**: Each tier is credited individually as achieved
✅ **Multiple Tiers at Once**: If delivery boy crosses 2+ tiers, all are credited together
✅ **Avoid Double-Crediting**: Checked against `delivery_boy_incentive_tier_credits` table
✅ **Audit Trail**: Each tier credit is linked to transaction record
✅ **Current Earnings Update**: Already updated from daily tracking before this process

---

## Database Changes

### New Table: DeliveryBoyIncentiveTierCredit

Tracks which tiers have been credited to avoid double-crediting:

```sql
CREATE TABLE delivery_boy_incentive_tier_credits (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    delivery_boy_incentive_progress_id BIGINT UNSIGNED NOT NULL,
    tier_id BIGINT UNSIGNED NOT NULL,
    incentive_amount DECIMAL(10,2) NOT NULL,
    transaction_id BIGINT UNSIGNED NULL,
    credited_at DATETIME NOT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    FOREIGN KEY (delivery_boy_incentive_progress_id)
        REFERENCES delivery_boy_incentive_progress(id) ON DELETE CASCADE,
    FOREIGN KEY (tier_id)
        REFERENCES incentive_offer_tiers(id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id)
        REFERENCES delivery_boy_transactions(id) ON DELETE SET NULL
);
```

**Example Records** (when delivery boy crosses Tier 1 and Tier 2 together):

```sql
INSERT INTO delivery_boy_incentive_tier_credits (
    delivery_boy_incentive_progress_id, tier_id, incentive_amount, transaction_id, credited_at
) VALUES
    (1, 1, 100.00, 123, NOW()),  -- Tier 1 credit
    (1, 2, 300.00, 123, NOW());  -- Tier 2 credit (same transaction)
```

### DeliveryBoyTransaction Table

Single transaction created for all newly crossed tiers:

```sql
INSERT INTO delivery_boy_transactions (
    delivery_boy_id,
    type,
    amount,
    status,
    message,
    transaction_date,
    created_at,
    updated_at
) VALUES (
    5,                                    -- delivery_boy_id
    'incentive',                          -- type
    400.00,                               -- amount (100 + 300 for 2 tiers)
    'success',                            -- status
    'Incentives earned for tiers: Tier 1, Tier 2',  -- message
    NOW(),                                -- transaction_date
    NOW(),
    NOW()
);
```

### DeliveryBoy Table

Balance incremented with total from all credited tiers:

```sql
UPDATE delivery_boys
SET balance = balance + 400.00  -- Total from both tiers
WHERE id = 5;
```

---

## Implementation Details

### Service Method: `creditIncentiveToWallet()`

**Location**: [app/Services/DeliveryBoyIncentiveService.php:314-370](app/Services/DeliveryBoyIncentiveService.php#L314-L370)

Creates transaction and credits wallet for all newly crossed tiers:

```php
private static function creditIncentiveToWallet(
    DeliveryBoy $deliveryBoy,
    IncentiveOffer $offer,
    $incentiveAmount,
    $tiersInfo = null  // array of tiers being credited
) {
    try {
        $incentiveAmount = (float) $incentiveAmount;

        // Build meaningful message based on tiers being credited
        if ($tiersInfo && !empty($tiersInfo)) {
            $tierNames = collect($tiersInfo)->pluck('tier_name')->implode(', ');
            $message = count($tiersInfo) > 1
                ? "Incentives earned for tiers: {$tierNames}"
                : "Incentive earned: {$tierNames}";
        } else {
            $message = 'Incentive earned: ' . $offer->name;
        }

        // 1. Create transaction record for all tiers
        $transaction = DeliveryBoyTransaction::create([
            'delivery_boy_id' => $deliveryBoy->id,
            'type' => 'incentive',
            'amount' => $incentiveAmount,
            'status' => DeliveryBoyTransaction::$statusSuccess,
            'message' => $message,
            'transaction_date' => now()
        ]);

        // 2. Update delivery boy's wallet balance
        $deliveryBoy->increment('balance', $incentiveAmount);

        // 3. Log the operation
        Log::info('Incentive Progress: Amount credited to wallet', [
            'delivery_boy_id' => $deliveryBoy->id,
            'offer_id' => $offer->id,
            'incentive_amount' => $incentiveAmount,
            'transaction_id' => $transaction->id,
            'tier_count' => $tiersInfo ? count($tiersInfo) : 0,
            'new_balance' => $deliveryBoy->balance
        ]);

        return $transaction;

    } catch (\Exception $e) {
        Log::error('Incentive Progress: Error crediting wallet', [
            'delivery_boy_id' => $deliveryBoy->id,
            'offer_id' => $offer->id,
            'amount' => $incentiveAmount,
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);

        return null;
    }
}
```

### Core Logic: `checkAndUpdateAchievedTier()`

**Location**: [app/Services/DeliveryBoyIncentiveService.php:197-303](app/Services/DeliveryBoyIncentiveService.php#L197-L303)

**Process**:

1. **Find Achievable Tiers**: Loop through all tiers, find those where `current_earnings >= tier.earnings_target`

2. **Get Already Credited Tiers**: Query `delivery_boy_incentive_tier_credits` table to find which tiers have been credited

3. **Find Newly Crossed Tiers**: Compare achievable tiers with credited tiers to find new ones

4. **Credit All New Tiers**: If new tiers exist:
   - Calculate total incentive amount by summing all new tier incentives
   - Call `creditIncentiveToWallet()` with tier info and total amount
   - Create `DeliveryBoyIncentiveTierCredit` records linking each tier to the transaction

5. **Update Progress**: Set `achieved_tier_id` to the highest tier achieved

6. **Check Completion**: If highest tier is final tier, mark offer as completed

**Key Code Section**:

```php
// Find newly crossed tiers
$newTiersToCredit = [];
foreach ($achievableTiers as $tier) {
    if (!in_array($tier->id, $creditedTierIds)) {
        $newTiersToCredit[] = $tier;
    }
}

// If new tiers to credit, process them
if (!empty($newTiersToCredit)) {
    // Calculate total incentive amount from all newly crossed tiers
    $totalCreditAmount = 0;
    foreach ($newTiersToCredit as $tier) {
        $totalCreditAmount += (float) $tier->incentive_amount;
    }

    // Credit all newly crossed tiers in a single transaction
    $transaction = self::creditIncentiveToWallet(
        $deliveryBoy,
        $offer,
        $totalCreditAmount,
        $newTiersToCredit  // Pass all new tiers for message generation
    );

    // Create individual credit records for each tier (all linked to same transaction)
    foreach ($newTiersToCredit as $tier) {
        DeliveryBoyIncentiveTierCredit::create([
            'delivery_boy_incentive_progress_id' => $progress->id,
            'tier_id' => $tier->id,
            'incentive_amount' => (float) $tier->incentive_amount,
            'transaction_id' => $transaction ? $transaction->id : null,
            'credited_at' => now()
        ]);
    }
}
```

---

## Example Scenarios

### Incentive Offer Setup

**Offer**: "Earn ₹500 Bonus"

```
Tier 1: ₹500 earnings → ₹100 incentive
Tier 2: ₹1000 earnings → ₹300 incentive
Tier 3: ₹1500 earnings → ₹500 incentive ← FINAL TIER
```

### Scenario 1: Single Tier Achievement

**Initial State**:
```
delivery_boys.balance = 5000.00
```

**Order Completed** (earning ₹600):
```
New total earnings = ₹600
Achievable tiers: Tier 1 (earnings ₹600 >= ₹500)
Already credited: None
New tiers to credit: Tier 1
↓
creditIncentiveToWallet() called
↓
Transaction created (ID: 100):
  type: 'incentive'
  amount: 100.00
  message: 'Incentive earned: Tier 1'
↓
delivery_boys.balance updated:
  5000.00 + 100.00 = 5100.00
↓
DeliveryBoyIncentiveTierCredit created:
  tier_id: 1
  incentive_amount: 100.00
  transaction_id: 100
```

**Result**:
```
delivery_boys.balance = 5100.00
delivery_boy_incentive_progress.achieved_tier_id = 1
```

---

### Scenario 2: Multiple Tiers Crossed at Once

**Initial State**:
```
delivery_boys.balance = 5000.00
delivery_boy_incentive_progress:
  - achieved_tier_id: null (no tiers crossed yet)
  - current_earnings: 0
```

**Single Order Completed** (earning ₹1200):
```
New total earnings = ₹1200
Achievable tiers: Tier 1, Tier 2 (both <= 1200)
Already credited: None
New tiers to credit: Tier 1, Tier 2
Total amount: 100 + 300 = 400
↓
Single creditIncentiveToWallet() call:
↓
Transaction created (ID: 101):
  type: 'incentive'
  amount: 400.00
  message: 'Incentives earned for tiers: Tier 1, Tier 2'
↓
delivery_boys.balance updated:
  5000.00 + 400.00 = 5400.00
↓
Two DeliveryBoyIncentiveTierCredit records created:
  (1) tier_id: 1, incentive_amount: 100.00, transaction_id: 101
  (2) tier_id: 2, incentive_amount: 300.00, transaction_id: 101
```

**Result**:
```
delivery_boys.balance = 5400.00
delivery_boy_incentive_progress.achieved_tier_id = 2
Tier 1 and Tier 2 both marked as credited
```

---

### Scenario 3: Avoid Double-Crediting

**Starting State**:
```
delivery_boys.balance = 5400.00  (from Scenario 2)
Already credited: Tier 1, Tier 2 (in tier_credits table)
current_earnings: 1200
```

**Next Order Completed** (earning ₹500 more = ₹1700 total):
```
New total earnings = 1700
Achievable tiers: Tier 1, Tier 2, Tier 3 (all <= 1700)
Already credited: Tier 1, Tier 2  ← Key!
New tiers to credit: Tier 3 only  ← Not Tier 1 & 2 again!
Total amount: 500 (only Tier 3)
↓
creditIncentiveToWallet() called with only Tier 3:
↓
Transaction created (ID: 102):
  type: 'incentive'
  amount: 500.00
  message: 'Incentive earned: Tier 3'
↓
delivery_boys.balance updated:
  5400.00 + 500.00 = 5900.00
↓
One DeliveryBoyIncentiveTierCredit created:
  tier_id: 3, incentive_amount: 500.00, transaction_id: 102
```

**Result**:
```
delivery_boys.balance = 5900.00
delivery_boy_incentive_progress:
  - achieved_tier_id = 3 (highest tier)
  - is_completed = true  (final tier reached)
  - completed_at = now()
Total tier credits: 3 records (Tier 1, Tier 2, Tier 3)
Total earned: 100 + 300 + 500 = 900
```

---

## Database Fields

### DeliveryBoy Model

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `balance` | Double | 0 | Wallet balance for delivery boy |
| `cash_received` | Double | 0 | Total cash received from orders |

**Migration**: `database/migrations/2022_04_19_163656_create_delivery_boys_table.php`

```php
$table->double('balance')->nullable()->default(0);
```

### DeliveryBoyTransaction Model

| Field | Type | Purpose |
|-------|------|---------|
| `delivery_boy_id` | BigInt | Link to delivery boy |
| `type` | String | Transaction type ('incentive', 'payout', etc.) |
| `amount` | Decimal | Amount credited/debited |
| `status` | String | 'success' or 'failed' |
| `message` | Text | Description (e.g., "Incentive earned: Earn ₹500 Bonus") |
| `transaction_date` | DateTime | When transaction occurred |

---

## Key Features

✅ **Per-Tier Tracking**: Each tier achievement is tracked individually in the tier_credits table
✅ **Summed Crediting**: If multiple tiers are crossed at once, their amounts are summed and credited in a single transaction
✅ **Avoid Double-Crediting**: System tracks which tiers have been credited using `delivery_boy_incentive_tier_credits` table
✅ **Automatic Crediting**: No manual intervention needed - triggered when order is delivered/cash collected
✅ **Transaction Tracking**: All tier credits linked to a single transaction record for easy audit trail
✅ **Immediate Update**: Balance updates instantly when tiers are achieved
✅ **Meaningful Messages**: Transaction message shows which tiers were credited (e.g., "Incentives earned for tiers: Tier 1, Tier 2")
✅ **Error Handling**: Failures logged but don't break the system
✅ **Multiple Offers**: Each offer handles independently
✅ **Comprehensive Logging**: All operations logged with full context including tier counts and amounts

---

## Logging Examples

### Success Log

```
[2026-01-08 18:00:00] local.INFO: Incentive Progress: Amount credited to wallet
{
    "delivery_boy_id": 5,
    "offer_id": 1,
    "incentive_amount": 500.00,
    "transaction_id": 123,
    "new_balance": 5500.00
}
```

### Error Log

```
[2026-01-08 18:00:00] local.ERROR: Incentive Progress: Error crediting wallet
{
    "delivery_boy_id": 5,
    "offer_id": 1,
    "amount": 500.00,
    "error": "DeliveryBoyTransaction model error..."
}
```

---

## Integration Points

### OrderController Methods

**1. markDelivered()** (Prepaid Orders)
```php
// After order saved and transaction committed
DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion(
    $deliveryBoy,
    $order
);
// This may trigger wallet crediting if offer completes
```

**2. collectCash()** (COD Orders)
```php
// After order saved and cash recorded
DeliveryBoyIncentiveService::updateIncentiveProgressOnOrderCompletion(
    $deliveryBoy,
    $order
);
// This may trigger wallet crediting if offer completes
```

---

## Query Examples

### Check Delivery Boy's Balance

```sql
SELECT id, name, balance
FROM delivery_boys
WHERE id = 5;
```

### View All Incentive Transactions

```sql
SELECT *
FROM delivery_boy_transactions
WHERE delivery_boy_id = 5
AND type = 'incentive'
ORDER BY transaction_date DESC;
```

### Calculate Total Incentives Earned

```sql
SELECT
    delivery_boy_id,
    COUNT(*) as total_incentives,
    SUM(amount) as total_amount
FROM delivery_boy_transactions
WHERE type = 'incentive'
AND status = 'success'
GROUP BY delivery_boy_id;
```

### Track Balance History

```sql
SELECT
    id,
    delivery_boy_id,
    type,
    amount,
    status,
    message,
    transaction_date
FROM delivery_boy_transactions
WHERE delivery_boy_id = 5
ORDER BY transaction_date DESC;
```

---

## Troubleshooting

### Balance Not Updated

**Check 1**: Verify offer is fully completed
```sql
SELECT *
FROM delivery_boy_incentive_progress
WHERE delivery_boy_id = 5
AND is_completed = 1;
```

**Check 2**: Verify transaction was created
```sql
SELECT *
FROM delivery_boy_transactions
WHERE delivery_boy_id = 5
AND type = 'incentive'
AND DATE(transaction_date) = CURDATE();
```

**Check 3**: Check logs for errors
```bash
grep "Error crediting wallet" storage/logs/laravel.log
```

### Balance Discrepancy

**Verify increments**:
```sql
SELECT
    SUM(amount) as total_credited
FROM delivery_boy_transactions
WHERE delivery_boy_id = 5
AND type = 'incentive'
AND status = 'success';

SELECT balance
FROM delivery_boys
WHERE id = 5;
```

---

## Files Modified

| File | Changes | Lines |
|------|---------|-------|
| [DeliveryBoyIncentiveService.php](app/Services/DeliveryBoyIncentiveService.php) | Added import for DeliveryBoyTransaction | 10 |
| [DeliveryBoyIncentiveService.php](app/Services/DeliveryBoyIncentiveService.php) | Updated checkAndUpdateAchievedTier() signature | 205-209 |
| [DeliveryBoyIncentiveService.php](app/Services/DeliveryBoyIncentiveService.php) | Added wallet credit call | 249 |
| [DeliveryBoyIncentiveService.php](app/Services/DeliveryBoyIncentiveService.php) | Added creditIncentiveToWallet() method | 268-305 |

---

## Testing Checklist

- [ ] Offer with single tier - credits on completion
- [ ] Offer with multiple tiers - credits only on final tier completion
- [ ] Multiple offers - each credits separately
- [ ] Transaction record created for each credit
- [ ] Balance increments correctly
- [ ] Logs show successful credits
- [ ] Error handling works if transaction fails
- [ ] Balance persists after server restart

---

## Summary

✅ **Automatic Incentive Distribution**: When delivery boys complete incentive offers, the earned amount is instantly credited to their wallet balance.

✅ **Transaction Tracking**: Every credit creates an audit trail in the `delivery_boy_transactions` table.

✅ **Real-Time Updates**: Balance updates immediately without requiring manual settlement.

✅ **Error Safe**: Even if crediting fails, the progress tracking is not affected (separate error handling).

The system ensures delivery boys receive their incentives instantly and transparently with full transaction history!
