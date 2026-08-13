# Billing Breakdown Guide

## Overview
The cart API now includes a comprehensive billing breakdown that shows every charge, discount, and the final amount to be paid. This guide explains how all amounts are calculated and displayed.

## How It Works

### 1. **Delivery Tip Integration**
The delivery tip is:
- Stored in `cart_metadata` table
- Automatically retrieved from saved metadata
- Can be overridden by passing `delivery_tip` in the request
- **Included in the total amount calculation**
- **Displayed in the billing breakdown**

### 2. **Total Amount Calculation Flow**

```
Items Subtotal (from cart items)
+ Combo Subtotal (from custom combos)
+ Delivery Charge (calculated based on distance)
+ Delivery Tip (from cart_metadata or request)
+ Additional Charges (platform fees, packaging, etc.)
+ GST/Tax Charges (when implemented)
- Discount (from promocode)
= To Be Paid

Savings Calculation:
Items Savings (MRP - Selling Price on cart items)
+ Combo Savings (MRP - Selling Price on combos)
= Total Savings (informational only)
```

### 3. **Response Structure**

The cart API response includes three billing-related sections:

#### A. `billing_breakdown` (Detailed Line Items)
Array of all charges with full details:

```json
{
  "billing_breakdown": [
    {
      "type": "items_subtotal",
      "label": "Items Subtotal",
      "description": "Total price of all items in cart",
      "amount": 500.00,
      "currency": "₹",
      "is_credit": false
    },
    {
      "type": "delivery_fee",
      "label": "Delivery Fee",
      "description": "Delivery from Fresh Mart (~3.5 km)",
      "amount": 40.00,
      "currency": "₹",
      "distance_km": 3.5,
      "seller_id": 12,
      "seller_name": "Fresh Mart",
      "is_credit": false
    },
    {
      "type": "delivery_tip",
      "label": "Delivery Tip",
      "description": "Tip for delivery partner",
      "amount": 50.00,
      "currency": "₹",
      "is_credit": false
    },
    {
      "type": "additional_charge",
      "label": "Platform Fee",
      "description": "Service charge",
      "amount": 10.00,
      "currency": "₹",
      "is_credit": false
    },
    {
      "type": "discount",
      "label": "Discount",
      "description": "Promo code: SAVE50",
      "amount": 50.00,
      "currency": "₹",
      "promo_code": "SAVE50",
      "is_credit": true
    },
    {
      "type": "savings",
      "label": "You Saved",
      "description": "Items MRP savings: 80.00, Combo savings: 20.00",
      "amount": 100.00,
      "currency": "₹",
      "is_credit": true,
      "breakdown": {
        "items_savings": 80.00,
        "combo_savings": 20.00
      }
    },
    {
      "type": "to_be_paid",
      "label": "To Be Paid",
      "description": "Total amount to be paid",
      "amount": 550.00,
      "currency": "₹",
      "is_credit": false,
      "is_total": true
    }
  ]
}
```

#### B. `billing_summary` (Quick Totals)
Object with all amounts for easy access:

```json
{
  "billing_summary": {
    "items_subtotal": 500.00,
    "combo_subtotal": 150.00,
    "delivery_charge": 40.00,
    "delivery_tip": 50.00,
    "gst_charges": 0,
    "additional_charges": 10.00,
    "discount": 50.00,
    "savings": 100.00,
    "items_savings": 80.00,
    "combo_savings": 20.00,
    "to_be_paid": 700.00,
    "currency": "₹"
  }
}
```

#### C. `cart_metadata` (User Preferences)
All saved cart metadata including delivery tip:

```json
{
  "cart_metadata": {
    "id": 1,
    "user_id": 123,
    "promocode_id": 3,
    "delivery_tip": "50.00",
    "delivery_instructions": "Ring doorbell twice",
    "contact_name": "John Doe",
    "contact_phone": "+1234567890",
    "contact_email": "john@example.com",
    "seller_notes": {
      "12": "Pack vegetables separately"
    },
    "combo_notes": {
      "5": "No onions"
    }
  }
}
```

## Breakdown Types

| Type | Label | Description | Credit? | Affects Total |
|------|-------|-------------|---------|---------------|
| `items_subtotal` | Items Subtotal | Total price of cart items | No | Base amount |
| `combo_subtotal` | Combos | Custom combo meals total | No | Adds to total |
| `delivery_fee` | Delivery Fee | Delivery charge with distance | No | Adds to total |
| `delivery_tip` | Delivery Tip | Tip for delivery partner | No | Adds to total |
| `gst_charges` | GST Charges | Tax amount (when implemented) | No | Adds to total |
| `additional_charge` | Platform Fee / Packaging | Extra charges | No | Adds to total |
| `discount` | Discount | Promocode discount | Yes | Subtracts from total |
| `savings` | You Saved | MRP vs selling price (items + combos) | Yes | Informational only |
| `to_be_paid` | To Be Paid | Final amount | No | **Final Total** |

### Understanding `is_credit`
- `false`: This amount is a charge (adds to total)
- `true`: This amount is a credit/saving (reduces total or is informational)

### Understanding `is_total`
- Only set on the `to_be_paid` item
- Indicates this is the final amount to be paid

## API Usage Examples

### Example 1: Get Cart with Delivery Tip
```bash
GET /customer/cart?is_checkout=1
Authorization: Bearer TOKEN
```

Response will include:
- All cart items grouped by seller
- Billing breakdown with delivery tip from saved metadata
- Cart metadata with all saved preferences

### Example 2: Override Delivery Tip Temporarily
```bash
GET /customer/cart?is_checkout=1&delivery_tip=75
Authorization: Bearer TOKEN
```

Response will use `75` as delivery tip instead of the saved value.

### Example 3: Save Delivery Tip Permanently
```bash
POST /customer/cart/metadata/save
Authorization: Bearer TOKEN
Content-Type: application/json

{
  "delivery_tip": 60,
  "delivery_instructions": "Leave at door"
}
```

Future cart requests will use `60` as the default delivery tip.

## Mobile App Integration

### Displaying the Breakdown

```javascript
// Loop through billing_breakdown
response.billing_breakdown.forEach(item => {
  if (item.is_total) {
    // This is the final total - display prominently
    displayTotal(item.label, item.amount, item.currency);
  } else if (item.is_credit) {
    // This is a discount or saving - display in green/positive
    displayCredit(item.label, item.amount, item.description);
  } else {
    // This is a charge - display normally
    displayCharge(item.label, item.amount, item.description);
  }
});
```

### Using the Summary

```javascript
// Quick access to totals without looping
const summary = response.billing_summary;

// Display order summary
displayOrderSummary({
  subtotal: summary.items_subtotal,
  delivery: summary.delivery_charge,
  tip: summary.delivery_tip,
  discount: summary.discount,
  total: summary.to_be_paid
});
```

## Important Notes

### 1. **Delivery Tip Flow**
1. User saves tip via `/cart/metadata/save`
2. Tip is stored in `cart_metadata` table
3. When getting cart, tip is automatically:
   - Retrieved from metadata
   - Added to billing breakdown
   - Included in total amount calculation
4. User can override tip temporarily by passing `delivery_tip` parameter

### 2. **Total Amount Includes Everything**
The `total_amount` and `to_be_paid` values include:
- Items subtotal
- **Combo subtotal** ✓
- Delivery charges
- **Delivery tip** ✓
- Additional charges
- Minus any discounts

### 3. **Savings vs Discount**
- **Savings**: MRP vs selling price difference (informational, doesn't affect total)
  - Includes both items savings and combo savings
  - Shows breakdown: `items_savings` + `combo_savings` = `savings`
  - Combo savings calculated from MRP - selling price on combo products
- **Discount**: Promocode discount (actually reduces the total amount)

### 4. **Multiple Delivery Fees**
If order has items from multiple sellers, you'll see multiple `delivery_fee` entries in the breakdown, one per seller.

### 5. **Tax Compatibility**
The `gst_charges` section is ready for future implementation. When activated:
- Calculate GST amount
- It will automatically appear in billing breakdown
- No mobile app changes needed

## Sample Calculation

```
Items Subtotal:        ₹500.00
Delivery Fee:          ₹ 40.00  (Fresh Mart, 3.5 km)
Delivery Tip:          ₹ 50.00  (from cart_metadata)
Platform Fee:          ₹ 10.00
                       -------
Subtotal:              ₹600.00
Discount (SAVE50):     -₹ 50.00
                       -------
To Be Paid:            ₹550.00

You Saved:             ₹100.00  (MRP difference - informational)
```

## Testing Checklist

- [ ] Save delivery tip via metadata API
- [ ] Get cart and verify tip appears in billing_breakdown
- [ ] Verify tip is included in total_amount
- [ ] Override tip with request parameter
- [ ] Test with multiple sellers (multiple delivery fees)
- [ ] Test with promocode (verify discount reduces total)
- [ ] Test with additional charges
- [ ] Verify all amounts in billing_summary match billing_breakdown

## Common Issues

### Q: Delivery tip not showing in breakdown?
**A:** Make sure:
1. Tip is saved in cart_metadata OR passed in request
2. Tip amount is greater than 0
3. You're calling the cart API with `is_checkout=1` (for full breakdown)

### Q: Total amount doesn't include tip?
**A:** Check that you're on the latest code. The tip is added at line 361 in CartApiController.

### Q: Can I have different tips for different sellers?
**A:** Currently, delivery tip is global per order. Use `seller_notes` in cart_metadata to add seller-specific instructions.

### Q: How do I clear a saved delivery tip?
**A:** Call `/cart/metadata/clear` with `"fields": ["delivery_tip"]`

---

**Last Updated:** December 13, 2025
