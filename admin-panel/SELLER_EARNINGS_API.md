# Seller Earnings API Documentation

## Endpoint
```
GET /api/seller/earnings
```

## Authentication
Required: Yes (Bearer Token via `auth:api` middleware)

## Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | String | No | Filter earnings by order status. Options: `delivered`, `out_for_delivery`, `shipped`, `processed`, `received`, `payment_pending`, `cancelled`, `returned` |

**Note:** All time periods are always included in the response, even if there are no transactions. Periods with no transactions will have `total_amount: 0` and `transactions: []`.

## Description
Returns seller earnings data grouped by time periods (Weekly, Monthly, Yearly, Total) with detailed transaction information for each period.

## Response Structure

```json
{
  "status": 1,
  "message": "Seller earnings fetched successfully",
  "data": {
    "weekly": [
      {
        "date_range": "13 Dec 2025 - 19 Dec 2025",
        "total_amount": 5000.00,
        "transactions": [
          {
            "order_id": "123",
            "date": "15 Dec 2025",
            "amount": 1250.00,
            "order_details": {
              "id": "#123",
              "status": "Delivered",
              "status_color": "green",
              "products": [
                {
                  "name": "Banana",
                  "quantity": "2X",
                  "weight": "500 GM",
                  "price": "25.00"
                },
                {
                  "name": "Apple",
                  "quantity": "3X",
                  "weight": "1 KG",
                  "price": "400.00"
                }
              ],
              "total_amount": "1250.00"
            }
          }
        ]
      },
      {
        "date_range": "06 Dec 2025 - 12 Dec 2025",
        "total_amount": 0,
        "transactions": []
      }
    ],
    "monthly": [
      {
        "date_range": "Dec 2025",
        "total_amount": 15000.00,
        "transactions": [...]
      },
      {
        "date_range": "Nov 2025",
        "total_amount": 0,
        "transactions": []
      }
    ],
    "yearly": [
      {
        "date_range": "2025",
        "total_amount": 120000.00,
        "transactions": [...]
      },
      {
        "date_range": "2024",
        "total_amount": 0,
        "transactions": []
      }
    ],
    "total": [
      {
        "date_range": "2025",
        "total_amount": 120000.00,
        "transactions": [...]
      },
      {
        "date_range": "2024",
        "total_amount": 0,
        "transactions": []
      }
    ]
  }
}
```

## Data Groupings

### Weekly
- Returns last 12 weeks of earnings
- Date range format: `"01 Jan 2025 - 07 Jan 2025"`
- Grouped by week (Monday to Sunday)

### Monthly
- Returns last 12 months of earnings
- Date range format: `"Jan 2025"`
- Grouped by calendar month

### Yearly
- Returns last 5 years of earnings
- Date range format: `"2025"`
- Grouped by calendar year

### Total
- Returns all-time earnings grouped by year
- Date range format: `"2025"`
- Only includes years with earnings > 0
- Sorted from newest to oldest

## Transaction Details

Each transaction includes:
- `order_id`: String - The order ID
- `date`: String - Transaction date (format: "dd MMM yyyy")
- `amount`: Float - Transaction total amount
- `order_details`: Object with:
  - `id`: String - Order ID with # prefix
  - `status`: String - Order status name
  - `status_color`: String - Color for status badge
  - `products`: Array of products in the order
  - `total_amount`: String - Formatted total amount

## Product Details

Each product includes:
- `name`: String - Product name
- `quantity`: String - Quantity with X suffix (e.g., "2X")
- `weight`: String - Product weight/measurement with unit
- `price`: String - Product price (formatted to 2 decimals)

## Status Colors

| Status | Color |
|--------|-------|
| Payment Pending | orange |
| Received | blue |
| Processed | purple |
| Shipped | cyan |
| Out for Delivery | indigo |
| Delivered | green |
| Cancelled | red |
| Returned | amber |

## Calculation Logic

1. Only includes orders from `order_seller_status_tracking` table (seller's orders)
2. Only counts orders with status 5 (Out for Delivery) or 6 (Delivered)
3. Revenue calculated as: `SUM(quantity * discounted_price)`
4. Transactions are grouped by order_id within each time period
5. Products fetched from order_items with product variant details

## Usage Examples

### Request - All Earnings (No Filter)
```bash
curl -X GET "https://your-domain.com/api/seller/earnings" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Request - Filter by Delivered Orders
```bash
curl -X GET "https://your-domain.com/api/seller/earnings?status=delivered" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Request - Filter by Cancelled Orders
```bash
curl -X GET "https://your-domain.com/api/seller/earnings?status=cancelled" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Request - Filter by Returned Orders
```bash
curl -X GET "https://your-domain.com/api/seller/earnings?status=returned" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Response
```json
{
  "status": 1,
  "message": "Seller earnings fetched successfully",
  "data": {
    "weekly": [...],
    "monthly": [...],
    "yearly": [...],
    "total": [...]
  }
}
```

## Error Responses

### Unauthorized
```json
{
  "status": 0,
  "message": "Invalid token or unauthorized access."
}
```

### Seller Not Found
```json
{
  "status": 0,
  "message": "Seller profile not found."
}
```

## Notes

- All amounts are returned as floats for calculation purposes
- Date ranges are formatted for display
- Empty periods (no earnings) are still included with `total_amount: 0` and empty `transactions` array
- Product weight includes the unit short code from the stock unit
- Order details are embedded within each transaction for the bottom sheet display

## Status Filter Behavior

### Without Status Filter (Default)
When no `status` parameter is provided, the API returns only orders that generate earnings:
- Orders with seller-specific statuses: `packed_by_seller` (Processed) or `given_to_delivery_partner` (Shipped)
- Orders with status 5 (Out for Delivery) or 6 (Delivered)

### With Status Filter
When a `status` parameter is provided, the API returns only orders matching that specific status:
- `delivered` - Shows only delivered orders (status 6)
- `out_for_delivery` - Shows only out for delivery orders (status 5)
- `shipped` - Shows only shipped orders (status 4 or `given_to_delivery_partner`)
- `processed` - Shows only processed orders (status 3 or `packed_by_seller`)
- `received` - Shows only received orders (status 2)
- `payment_pending` - Shows only payment pending orders (status 1)
- `cancelled` - Shows only cancelled orders (status 7)
- `returned` - Shows only returned orders (status 8)

### Seller-Specific Status Mapping
- `packed_by_seller` tracking status → Maps to "Processed" (status 3)
- `given_to_delivery_partner` tracking status → Maps to "Shipped" (status 4)
