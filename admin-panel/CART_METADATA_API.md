# Cart Metadata API Documentation

## Overview
This API allows you to save and manage cart-related metadata including:
- Delivery tip
- Delivery instructions
- Contact information (name, phone, email)
- Notes for each seller
- Notes for each combo
- Promocode selection

## Database Migration

Run the migration to create the cart_metadata table:
```bash
php artisan migrate
```

## API Endpoints

### 1. Save Cart Metadata
**Endpoint:** `POST /customer/cart/metadata/save`

**Authentication:** Required (api-customers guard)

**Request Body:**
```json
{
  "delivery_tip": 50,
  "delivery_instructions": "Please ring the doorbell twice",
  "contact_name": "John Doe",
  "contact_phone": "+1234567890",
  "contact_email": "john@example.com",
  "seller_notes": {
    "12": "Please pack vegetables separately",
    "15": "Add extra napkins"
  },
  "combo_notes": {
    "5": "No onions please",
    "8": "Extra spicy"
  },
  "promocode_id": 3
}
```

**Notes:**
- All fields are optional
- `seller_notes` is an object with seller_id as key and note as value
- `combo_notes` is an object with combo_custom_cart_id as key and note as value
- Notes are merged with existing notes (not replaced)

**Response:**
```json
{
  "error": false,
  "message": "success",
  "data": {
    "message": "Cart metadata saved successfully",
    "metadata": {
      "id": 1,
      "user_id": 123,
      "promocode_id": 3,
      "delivery_tip": "50.00",
      "delivery_instructions": "Please ring the doorbell twice",
      "contact_name": "John Doe",
      "contact_phone": "+1234567890",
      "contact_email": "john@example.com",
      "seller_notes": {
        "12": "Please pack vegetables separately",
        "15": "Add extra napkins"
      },
      "combo_notes": {
        "5": "No onions please",
        "8": "Extra spicy"
      },
      "created_at": "2025-12-13T10:00:00.000000Z",
      "updated_at": "2025-12-13T10:30:00.000000Z"
    }
  }
}
```

---

### 2. Get Cart Metadata
**Endpoint:** `GET /customer/cart/metadata`

**Authentication:** Required (api-customers guard)

**Response:**
```json
{
  "error": false,
  "message": "success",
  "data": {
    "metadata": {
      "id": 1,
      "user_id": 123,
      "promocode_id": 3,
      "delivery_tip": "50.00",
      "delivery_instructions": "Please ring the doorbell twice",
      "contact_name": "John Doe",
      "contact_phone": "+1234567890",
      "contact_email": "john@example.com",
      "seller_notes": {
        "12": "Please pack vegetables separately"
      },
      "combo_notes": {
        "5": "No onions please"
      }
    }
  }
}
```

If no metadata exists:
```json
{
  "error": false,
  "message": "success",
  "data": {
    "metadata": {
      "promocode_id": null,
      "delivery_tip": 0,
      "delivery_instructions": null,
      "contact_name": null,
      "contact_phone": null,
      "contact_email": null,
      "seller_notes": [],
      "combo_notes": []
    }
  }
}
```

---

### 3. Clear Cart Metadata
**Endpoint:** `POST /customer/cart/metadata/clear`

**Authentication:** Required (api-customers guard)

**Request Body:**
```json
{
  "fields": ["delivery_tip", "delivery_instructions", "seller_notes"]
}
```

**Available Fields:**
- `promocode_id`
- `delivery_tip`
- `delivery_instructions`
- `contact_name`
- `contact_phone`
- `contact_email`
- `seller_notes`
- `combo_notes`

**Response:**
```json
{
  "error": false,
  "message": "success",
  "data": {
    "message": "Cart metadata cleared successfully"
  }
}
```

---

## Integration with Cart API

The cart metadata is automatically included in the `getUserCart` response:

**Endpoint:** `GET /customer/cart?is_checkout=1`

**Response includes:**
```json
{
  "error": false,
  "message": "success",
  "data": {
    "grouped_by_seller": [...],
    "billing_breakdown": [...],
    "billing_summary": {...},
    "cart_metadata": {
      "id": 1,
      "user_id": 123,
      "promocode_id": 3,
      "delivery_tip": "50.00",
      "delivery_instructions": "Please ring the doorbell twice",
      "contact_name": "John Doe",
      "contact_phone": "+1234567890",
      "contact_email": "john@example.com",
      "seller_notes": {
        "12": "Please pack vegetables separately",
        "15": "Add extra napkins"
      },
      "combo_notes": {
        "5": "No onions please",
        "8": "Extra spicy"
      }
    }
  }
}
```

---

## Billing Breakdown Structure

The cart API now includes comprehensive billing information:

### billing_breakdown Array
Each item in the array has this structure:
```json
{
  "type": "items_subtotal|delivery_fee|delivery_tip|gst_charges|additional_charge|discount|savings|to_be_paid",
  "label": "Display Label",
  "description": "Detailed description",
  "amount": 100.00,
  "currency": "₹",
  "is_credit": false,
  "is_total": false
}
```

**Example:**
```json
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
    "type": "discount",
    "label": "Discount",
    "description": "Promo code: SAVE50",
    "amount": 50.00,
    "currency": "₹",
    "promo_code": "SAVE50",
    "is_credit": true
  },
  {
    "type": "to_be_paid",
    "label": "To Be Paid",
    "description": "Total amount to be paid",
    "amount": 540.00,
    "currency": "₹",
    "is_credit": false,
    "is_total": true
  }
]
```

### billing_summary Object
Quick reference for all totals:
```json
"billing_summary": {
  "items_subtotal": 500.00,
  "delivery_charge": 40.00,
  "delivery_tip": 50.00,
  "gst_charges": 0,
  "additional_charges": 0,
  "discount": 50.00,
  "savings": 0,
  "to_be_paid": 540.00,
  "currency": "₹"
}
```

---

## Usage Examples

### Example 1: Save delivery tip and instructions
```javascript
fetch('/customer/cart/metadata/save', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    delivery_tip: 30,
    delivery_instructions: "Leave package at door"
  })
})
```

### Example 2: Add notes for specific sellers
```javascript
fetch('/customer/cart/metadata/save', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    seller_notes: {
      "12": "Please pack fragile items carefully",
      "15": "Add extra ice packs"
    }
  })
})
```

### Example 3: Update contact information
```javascript
fetch('/customer/cart/metadata/save', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    contact_name: "Jane Smith",
    contact_phone: "+9876543210",
    contact_email: "jane@example.com"
  })
})
```

### Example 4: Clear specific fields
```javascript
fetch('/customer/cart/metadata/clear', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    fields: ["delivery_tip", "delivery_instructions"]
  })
})
```

---

## Important Notes

1. **Merging Notes**: When you save `seller_notes` or `combo_notes`, they are merged with existing notes, not replaced. To clear notes, use the clear endpoint.

2. **Delivery Tip in Billing**: The delivery tip from cart metadata is automatically included in the billing breakdown when viewing the cart.

3. **Per-User Storage**: Each user has their own cart metadata stored separately.

4. **Validation**:
   - Delivery tip must be numeric and >= 0
   - Contact email must be valid email format
   - Notes are limited to 500 characters each
   - Delivery instructions limited to 1000 characters

5. **Tax Compatibility**: The billing structure includes a placeholder for GST/tax charges that can be activated later without requiring mobile app updates.

---

## Future Enhancements

The billing breakdown structure is designed to be extensible. When you need to add taxes:

```php
// In CartApiController.php, update the GST section:
$gst_amount = calculateGST($sub_total); // Your calculation
if ($gst_amount > 0) {
    $billing_breakdown[] = [
        'type' => 'gst_charges',
        'label' => 'GST Charges',
        'description' => 'Goods and Services Tax',
        'amount' => CommonHelper::doubleNumber($gst_amount),
        'currency' => $currency,
        'tax_percentage' => 18, // Add percentage here
        'is_credit' => false
    ];
}
```

No mobile app changes required!
