# Total Amount Calculation Flow

## Complete Calculation Order

The `total_amount` (which becomes `to_be_paid` in billing breakdown) is calculated in the following exact order:

### Step-by-Step Calculation

```
STEP 1: Items Subtotal
├─ Source: $total->total_amount (sum of all cart items)
├─ Location: Line 241, 349
└─ Example: ₹500.00

STEP 1b: Add Combo Prices
├─ Source: combo_custom_cart + combo_custom_products
├─ Location: Lines 389-520
├─ Calculation: Sum of all custom combo product prices
├─ Always calculated (both checkout and non-checkout modes)
└─ Example: +₹200.00 → Running Total: ₹700.00

STEP 2: Add Delivery Charge
├─ Source: $data['data']['total_delivery_charge']
├─ Location: Line 352
├─ Calculation: Based on distance, seller location
└─ Example: +₹40.00 → Running Total: ₹740.00

STEP 3: Add Delivery Tip
├─ Source: cart_metadata.delivery_tip OR request.delivery_tip
├─ Location: Line 364
├─ Priority: Request parameter > Saved metadata
└─ Example: +₹50.00 → Running Total: ₹790.00

STEP 4: Subtract Discount (Promocode)
├─ Source: CommonHelper::getValidatedPromoCode()
├─ Location: Line 374
├─ Applied if: promocode_id is provided and valid
└─ Example: -₹50.00 → Running Total: ₹740.00

STEP 5: Add Additional Charges
├─ Source: Setting::get_value('additional_charges')
├─ Location: Line 574-576
├─ Includes: Platform fees, packaging, service charges
└─ Example: +₹10.00 → FINAL TOTAL: ₹750.00

STEP 6: GST/Tax (Future)
├─ Ready for implementation
├─ Will be added before final total
└─ Currently: ₹0.00
```

## Code Flow Visualization

```php
// Line 241, 349: Start with items
$sub_total = $total->total_amount;  // ₹500
$total_amount = $total->total_amount;  // ₹500

// Lines 389-520: Calculate and add combos
$total_combo_price = 200;  // Calculated from combo_custom_cart
$sub_total += $total_combo_price;  // ₹700

// Line 523-525: Add combos to checkout total
if ($is_checkout == 1) {
    $total_amount += $total_combo_price;  // ₹700
}

// Line 352: Add delivery
$total_amount += $delivery_charge;  // ₹740

// Line 364: Add tip
$total_amount += $delivery_tip;  // ₹790

// Line 374: Subtract discount
$total_amount -= $discount;  // ₹740

// Lines 574-576: Add additional charges
$total_amount += $additional_charges;  // ₹750

// Final total
$to_be_paid = $total_amount;  // ₹750 ✓
```

## All Bills Tracked

### ✅ Additions (Charges)
| Item | Variable | Line | Included |
|------|----------|------|----------|
| Items Subtotal | `$total->total_amount` | 241, 349 | ✓ |
| Combo Subtotal | `$total_combo_price` | 389-520 | ✓ |
| Delivery Fee | `$data['data']['total_delivery_charge']` | 352 | ✓ |
| Delivery Tip | `$delivery_tip_amount` | 364 | ✓ |
| Additional Charges | `$additional_charges_total` | 574-576 | ✓ |
| GST/Tax | `$gst_amount` | Future | Placeholder |

### ✅ Subtractions (Discounts)
| Item | Variable | Line | Included |
|------|----------|------|----------|
| Promocode Discount | `$promocode_details['discount']` | 374 | ✓ |

### ℹ️ Informational Only (Not in Total)
| Item | Variable | Purpose |
|------|----------|---------|
| Savings | `$saved_amount` | Shows MRP vs selling price difference |

## Response Structure

The total amount appears in multiple places:

### 1. Direct Fields
```json
{
  "total_amount": 550.00,        // Main total field
  "delivery_tip": 50.00,         // Individual tip amount
  "sub_total": 500.00,           // Items only
  "saved_amount": 100.00         // Informational
}
```

### 2. Billing Breakdown (Detailed)
```json
{
  "billing_breakdown": [
    {"type": "items_subtotal", "amount": 500.00},
    {"type": "delivery_fee", "amount": 40.00},
    {"type": "delivery_tip", "amount": 50.00},
    {"type": "additional_charge", "amount": 10.00},
    {"type": "discount", "amount": 50.00, "is_credit": true},
    {"type": "to_be_paid", "amount": 550.00, "is_total": true}
  ]
}
```

### 3. Billing Summary (Quick Reference)
```json
{
  "billing_summary": {
    "items_subtotal": 500.00,
    "delivery_charge": 40.00,
    "delivery_tip": 50.00,
    "additional_charges": 10.00,
    "discount": 50.00,
    "to_be_paid": 550.00
  }
}
```

## Verification Checklist

To verify all bills are included:

```
✓ Items Subtotal (500) is the base
✓ Delivery Fee (40) is added
✓ Delivery Tip (50) is added
✓ Additional Charges (10) are added
✓ Discount (50) is subtracted
= Final Total (550) is correct

Formula: 500 + 40 + 50 + 10 - 50 = 550 ✓
```

## Example Scenarios

### Scenario 1: No Discount, With Tip
```
Items:              ₹500.00
Delivery:          +₹ 40.00
Tip:               +₹ 50.00
Platform Fee:      +₹ 10.00
─────────────────────────
To Be Paid:        =₹600.00
```

### Scenario 2: With Discount, No Tip
```
Items:              ₹500.00
Delivery:          +₹ 40.00
Platform Fee:      +₹ 10.00
Discount (SAVE50): -₹ 50.00
─────────────────────────
To Be Paid:        =₹500.00
```

### Scenario 3: Full Example (All Charges)
```
Items:              ₹500.00
Delivery:          +₹ 40.00
Tip:               +₹ 50.00
Platform Fee:      +₹ 10.00
Discount:          -₹ 50.00
─────────────────────────
To Be Paid:        =₹550.00

Savings (MRP):      ₹100.00 (informational)
```

### Scenario 4: Multiple Sellers
```
Items:              ₹500.00
Delivery (Seller A):+₹ 30.00
Delivery (Seller B):+₹ 20.00
Tip (Global):      +₹ 50.00
Platform Fee:      +₹ 10.00
Discount:          -₹ 50.00
─────────────────────────
To Be Paid:        =₹560.00
```

## Common Questions

### Q: Why is my total different from items + delivery?
**A:** The total includes ALL charges:
- Items subtotal
- ALL delivery fees (one per seller if multiple sellers)
- Delivery tip (from metadata or request)
- Additional charges (platform fees, etc.)
- Minus any discounts

### Q: How do I verify the calculation?
**A:** Use `billing_breakdown` array:
```javascript
let calculated_total = 0;
response.billing_breakdown.forEach(item => {
  if (item.type === 'to_be_paid') return; // Skip total itself

  if (item.is_credit) {
    calculated_total -= item.amount;  // Subtract discounts
  } else {
    calculated_total += item.amount;  // Add charges
  }
});

// calculated_total should equal response.total_amount
```

### Q: Does delivery tip affect the total?
**A:** YES! Delivery tip is:
1. Retrieved from cart_metadata (or request parameter)
2. Added to total_amount at line 364
3. Shown in billing_breakdown
4. Included in "To Be Paid"

### Q: What about GST/taxes?
**A:** Currently set to ₹0. When implemented:
1. Calculate `$gst_amount` based on your tax rules
2. It will automatically appear in billing_breakdown
3. It will be included in the total
4. No changes needed in mobile app

## Testing Commands

### Test 1: Basic Total
```bash
GET /customer/cart?is_checkout=1
```
Verify: `total_amount` = items + delivery

### Test 2: With Tip
```bash
# Save tip
POST /customer/cart/metadata/save
{"delivery_tip": 50}

# Get cart
GET /customer/cart?is_checkout=1
```
Verify: `total_amount` includes the ₹50 tip

### Test 3: With Discount
```bash
GET /customer/cart?is_checkout=1&promocode_id=3
```
Verify: `total_amount` = (items + delivery + tip) - discount

### Test 4: All Charges
```bash
# Setup:
# - Items in cart
# - Saved delivery tip
# - Additional charges in settings
# - Promocode applied

GET /customer/cart?is_checkout=1&promocode_id=3
```
Verify: All amounts match the formula above

## Important Notes

1. **All amounts are in billing_breakdown**: Every single charge and discount appears as a separate item

2. **to_be_paid is the final truth**: This is the amount customer will pay

3. **Savings is informational**: The "You Saved" amount doesn't affect the total - it's just showing MRP difference

4. **Multiple delivery fees**: If order has items from multiple sellers, each seller's delivery fee appears separately in the breakdown

5. **Tip is always global**: Currently, there's one delivery tip for the entire order, not per seller

---

**Implementation Date:** December 13, 2025
**Last Updated:** December 13, 2025
**Status:** ✅ Complete and Working
