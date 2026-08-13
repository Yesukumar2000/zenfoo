# Distance-Based Delivery Charge Split Implementation

## Overview
When multiple drivers work on a single order (due to emergency driver change), the delivery charge is now split proportionally based on the **billable distance** each driver traveled.

---

## Key Rule: Billable Distance Calculation

**Excluded**:
- ❌ Driver start → First seller (driver commute to job)
- ❌ New driver → Handoff point (new driver commute to handoff)

**Included**:
- ✅ Seller 1 → Seller 2 (actual pickup work)
- ✅ Seller 2 → Seller 3 (actual pickup work)
- ✅ Last Seller → Customer (actual delivery work)

---

## Files Modified

### 1. **Database Migration**
- **File**: `database/migrations/2026_03_27_102850_add_driver_distance_split_to_orders_table.php`
- **Change**: Added `driver_distance_split` JSON column to `orders` table
- **Status**: ✅ Migrated

### 2. **Firestore Service**
- **File**: `app/Services/FirestoreDeliveryBoyService.php`

**New Methods**:
- `calculateBillableDistance()` - Calculates billable distance excluding commutes
- `getDeliveryBoyDocument()` - Retrieves driver's Firestore data
- `convertFirestoreToArray()` - Converts Firestore format to array

**Updated Methods**:
- `emergencyChangeDriver()` - Now tracks old driver's billable distance

### 3. **Order Controller**
- **File**: `app/Http/Controllers/API/DeliveryBoy/OrderController.php`

**Updated Methods**:
- `collectCash()` - Split charges for COD multi-driver orders
- `markDelivered()` - Split charges for prepaid multi-driver orders

---

## Data Structure

### Orders Table: `driver_distance_split` Column

```json
{
  "total_billable_distance_km": 5.0,
  "drivers": {
    "47": {
      "name": "Vicky",
      "billable_distance_km": 2.0,
      "percentage": 40.0,
      "earnings": 40.00,
      "completed_sellers": ["Store A", "Store B"],
      "handoff_location": {
        "latitude": 17.4389,
        "longitude": 78.3984
      }
    },
    "53": {
      "name": "New Driver",
      "billable_distance_km": 3.0,
      "percentage": 60.0,
      "earnings": 60.00
    }
  }
}
```

---

## Transaction Creation

### Multi-Driver Order (2 transactions created):

**Driver 1 (Vicky)** - Partial Delivery:
```php
delivery_charge: ₹40 (40% of ₹100)
delivery_tip: ₹0 (only completing driver gets tip)
rain_surcharge: ₹8 (40% of ₹20)
bonus_amount: ₹0 (only completing driver gets bonus)
driver_earnings: ₹48
admin_cash: ₹0 (didn't collect from customer)
message: "Partial delivery - traveled 2.00km (40.0%)"
```

**Driver 2 (New)** - Order Completed:
```php
delivery_charge: ₹60 (60% of ₹100)
delivery_tip: ₹20 (full tip to completing driver)
rain_surcharge: ₹12 (60% of ₹20)
bonus_amount: ₹50 (full bonus to completing driver)
driver_earnings: ₹142
admin_cash: ₹310 (COD: collected - earnings)
message: "Order completed - traveled 3.00km (60.0%)"
```

### Single-Driver Order (1 transaction):
Existing behavior unchanged - full amount to completing driver.

---

## Logging Points

### 1. Emergency Driver Change
```
✅ Old driver location captured
✅ Old driver route retrieved
✅ Old driver billable distance calculated
✅ Driver distance split prepared
```

### 2. Order Completion
```
✅ Checking multi-driver order status
✅ Current driver billable distance calculated
✅ Total billable distance calculated
✅ Multi-driver transaction created (for each driver)
✅ Multi-driver split completed
```

### 3. Billable Distance Calculation
```
✅ Starting calculation
✅ Skipping handoff point
✅ Skipping first seller
✅ Counting distance (for each stop)
✅ Calculation complete
```

---

## Example Scenario

### Order Route:
```
New Driver Start
    ↓ 2km (❌ SKIP - commute)
Seller 1 (pickup)
    ↓ 1.5km (✅ COUNT)
Seller 2 (pickup)
    ↓ 0.5km (✅ COUNT)
[Bike Puncture - Handoff]
    ↓ 2km (❌ SKIP - new driver commute)
Seller 3 (pickup)
    ↓ 3km (✅ COUNT)
Customer (delivery)

Total Billable: 5km (1.5 + 0.5 + 3.0)
```

### Split Calculation:
- **Driver 1**: 2km billable (40%) → ₹40 delivery charge
- **Driver 2**: 3km billable (60%) → ₹60 delivery charge
- **Tip**: 100% to Driver 2 (completed delivery)
- **Bonus**: 100% to Driver 2 (completed order)
- **Rain**: 40% to Driver 1, 60% to Driver 2

---

## Testing

### Test Order Creation:
1. Create order with 3 sellers
2. Assign to Driver 1
3. Driver 1 picks up from 2 sellers
4. Trigger emergency driver change
5. Assign to Driver 2
6. Driver 2 picks up from remaining seller and delivers

### Expected Result:
- 2 transactions created
- Split proportional to billable distance
- Both drivers see earnings in wallet
- Weekly payout includes both drivers

---

## Benefits

✅ **Fair compensation** - Based on actual work (distance traveled)
✅ **Accurate calculation** - Excludes driver commutes
✅ **Transparent** - Transaction messages show distance & percentage
✅ **Flexible** - Works for any number of drivers
✅ **Backward compatible** - Single-driver orders unchanged

---

## Implementation Date
2026-03-27

## Migration Status
✅ Database migrated
✅ Code deployed
✅ Logging enabled
✅ Ready for production
