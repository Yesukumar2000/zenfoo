# Delivery Tips API Documentation

## Overview

The Delivery Tips API allows delivery boys to view their customer tips based on different time periods. The API provides comprehensive tip information including order details, customer information, delivery details, and aggregate statistics.

---

## Endpoints

### 1. Weekly Tips - Get Tips by Week Offset

Retrieve all tips earned in a specific week with detailed order information.

**Endpoint:** `GET /api/delivery-boy/tips/weekly`

**Authentication:** Required (auth:api)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `offset` | integer | No | 0 | Week offset from current week. Use -1 for previous week, 0 for current week, 1 for next week |
| `date` | string | No | Today | Reference date to calculate week from (YYYY-MM-DD format) |

**Example Requests:**

```bash
# Get current week tips
GET /api/delivery-boy/tips/weekly

# Get previous week tips
GET /api/delivery-boy/tips/weekly?offset=-1

# Get next week tips
GET /api/delivery-boy/tips/weekly?offset=1

# Get specific week (week containing 2026-01-15)
GET /api/delivery-boy/tips/weekly?date=2026-01-15
```

**Response (200 OK):**

```json
{
  "status": true,
  "message": "Delivery tips retrieved successfully",
  "data": {
    "delivery_boy": {
      "id": 5,
      "name": "Ravi Kumar",
      "phone": "9876543210",
      "current_balance": 5500.00
    },
    "week_summary": {
      "week_start": "2026-01-05",
      "week_end": "2026-01-11",
      "week_range": "Jan 05 - Jan 11, 2026",
      "total_tips": 1250.50,
      "total_orders_with_tips": 15,
      "average_tip_per_order": 83.37,
      "max_tip": 150.00,
      "min_tip": 25.00,
      "total_orders_count": 45,
      "days_with_tips": {
        "2026-01-05": {
          "total_tips": 150.00
        },
        "2026-01-06": {
          "total_tips": 200.00
        },
        "2026-01-07": {
          "total_tips": 180.50
        },
        "2026-01-08": {
          "total_tips": 220.00
        },
        "2026-01-09": {
          "total_tips": 250.00
        },
        "2026-01-10": {
          "total_tips": 150.00
        },
        "2026-01-11": {
          "total_tips": 100.00
        }
      }
    },
    "tips_list": [
      {
        "order_id": 1001,
        "tip_amount": 150.00,
        "order_amount": 450.00,
        "delivery_charge": 30.00,
        "customer_name": "Amit Singh",
        "customer_phone": "9123456789",
        "delivery_address": "123 Main St, Apt 4B, Downtown",
        "order_items_count": 3,
        "payment_method": "cash",
        "order_status": "delivered",
        "order_date": "2026-01-09",
        "order_time": "14:30:45",
        "delivery_time": "14:55:30",
        "restaurant_name": "Pizza Palace",
        "restaurant_address": "45 Food Street",
        "delivery_distance_km": 2.5,
        "created_at": "2026-01-09T14:30:45Z",
        "updated_at": "2026-01-09T14:55:30Z"
      },
      {
        "order_id": 1002,
        "tip_amount": 75.00,
        "order_amount": 520.00,
        "delivery_charge": 40.00,
        "customer_name": "Priya Sharma",
        "customer_phone": "8765432109",
        "delivery_address": "567 Oak Ave, Suite 200, Midtown",
        "order_items_count": 5,
        "payment_method": "online",
        "order_status": "delivered",
        "order_date": "2026-01-09",
        "order_time": "19:20:15",
        "delivery_time": "19:45:00",
        "restaurant_name": "Burger King",
        "restaurant_address": "100 Food Street",
        "delivery_distance_km": 3.2,
        "created_at": "2026-01-09T19:20:15Z",
        "updated_at": "2026-01-09T19:45:00Z"
      }
    ],
    "navigation": {
      "current": {
        "week_start": "2026-01-05",
        "week_end": "2026-01-11",
        "offset": 0
      },
      "previous": {
        "week_start": "2025-12-29",
        "week_end": "2026-01-04",
        "offset": -1
      },
      "next": {
        "week_start": "2026-01-12",
        "week_end": "2026-01-18",
        "offset": 1
      }
    }
  }
}
```

**Error Response (401 Unauthorized):**

```json
{
  "status": false,
  "message": "Unauthorized"
}
```

---

### 2. Daily Tips - Get Tips for a Specific Day

Retrieve all tips earned on a specific day with hourly breakdown.

**Endpoint:** `GET /api/delivery-boy/tips/daily`

**Authentication:** Required (auth:api)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `date` | string | No | Today | Specific date to fetch tips from (YYYY-MM-DD format) |

**Example Requests:**

```bash
# Get today's tips
GET /api/delivery-boy/tips/daily

# Get specific date tips
GET /api/delivery-boy/tips/daily?date=2026-01-09

# Get yesterday's tips
GET /api/delivery-boy/tips/daily?date=2026-01-08
```

**Response (200 OK):**

```json
{
  "status": true,
  "message": "Daily tips retrieved successfully",
  "data": {
    "delivery_boy": {
      "id": 5,
      "name": "Ravi Kumar",
      "phone": "9876543210",
      "current_balance": 5500.00
    },
    "day_summary": {
      "date": "2026-01-09",
      "day_of_week": "Thursday",
      "total_tips": 225.00,
      "total_orders_with_tips": 5,
      "average_tip_per_order": 45.00,
      "total_delivered_orders": 12,
      "hourly_breakdown": [
        {
          "hour": "11:00",
          "total_tips": 60.00
        },
        {
          "hour": "12:00",
          "total_tips": 85.00
        },
        {
          "hour": "14:00",
          "total_tips": 150.00
        },
        {
          "hour": "19:00",
          "total_tips": 75.00
        }
      ]
    },
    "tips_list": [
      {
        "order_id": 1001,
        "tip_amount": 150.00,
        "order_amount": 450.00,
        "delivery_charge": 30.00,
        "customer_name": "Amit Singh",
        "customer_phone": "9123456789",
        "delivery_address": "123 Main St, Apt 4B, Downtown",
        "order_items_count": 3,
        "payment_method": "cash",
        "order_time": "14:30:45",
        "delivery_time": "14:55:30",
        "restaurant_name": "Pizza Palace",
        "restaurant_address": "45 Food Street",
        "delivery_distance_km": 2.5,
        "created_at": "2026-01-09T14:30:45Z",
        "updated_at": "2026-01-09T14:55:30Z"
      }
    ]
  }
}
```

---

### 3. Range Tips - Get Tips for Custom Date Range

Retrieve all tips earned within a custom date range with daily breakdown.

**Endpoint:** `GET /api/delivery-boy/tips/range`

**Authentication:** Required (auth:api)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `from_date` | string | Yes | - | Start date for range (YYYY-MM-DD format) |
| `to_date` | string | Yes | - | End date for range (YYYY-MM-DD format) |

**Example Requests:**

```bash
# Get tips for a month
GET /api/delivery-boy/tips/range?from_date=2026-01-01&to_date=2026-01-31

# Get tips for last 7 days
GET /api/delivery-boy/tips/range?from_date=2026-01-03&to_date=2026-01-09

# Get tips for a specific 3-day period
GET /api/delivery-boy/tips/range?from_date=2026-01-07&to_date=2026-01-09
```

**Response (200 OK):**

```json
{
  "status": true,
  "message": "Range tips retrieved successfully",
  "data": {
    "delivery_boy": {
      "id": 5,
      "name": "Ravi Kumar",
      "phone": "9876543210",
      "current_balance": 5500.00
    },
    "range_summary": {
      "from_date": "2026-01-01",
      "to_date": "2026-01-31",
      "date_range": "Jan 01 - Jan 31, 2026",
      "days_count": 31,
      "total_tips": 5850.00,
      "total_orders_with_tips": 120,
      "average_tip_per_order": 48.75,
      "max_tip": 200.00,
      "min_tip": 10.00,
      "daily_breakdown": [
        {
          "date": "2026-01-01",
          "day_of_week": "Wednesday",
          "total_tips": 180.00
        },
        {
          "date": "2026-01-02",
          "day_of_week": "Thursday",
          "total_tips": 210.00
        },
        {
          "date": "2026-01-03",
          "day_of_week": "Friday",
          "total_tips": 195.00
        },
        {
          "date": "2026-01-09",
          "day_of_week": "Thursday",
          "total_tips": 225.00
        }
      ]
    },
    "tips_list": [
      {
        "order_id": 1001,
        "tip_amount": 150.00,
        "order_amount": 450.00,
        "delivery_charge": 30.00,
        "customer_name": "Amit Singh",
        "customer_phone": "9123456789",
        "delivery_address": "123 Main St, Apt 4B, Downtown",
        "order_items_count": 3,
        "payment_method": "cash",
        "order_date": "2026-01-09",
        "order_time": "14:30:45",
        "delivery_time": "14:55:30",
        "restaurant_name": "Pizza Palace",
        "restaurant_address": "45 Food Street",
        "delivery_distance_km": 2.5,
        "created_at": "2026-01-09T14:30:45Z",
        "updated_at": "2026-01-09T14:55:30Z"
      }
    ]
  }
}
```

**Error Response (422 Unprocessable Entity):**

```json
{
  "status": false,
  "message": "from_date and to_date are required"
}
```

```json
{
  "status": false,
  "message": "from_date must be less than or equal to to_date"
}
```

---

## Response Fields Explanation

### Delivery Boy Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique identifier of the delivery boy |
| `name` | string | Full name of the delivery boy |
| `phone` | string | Contact phone number |
| `current_balance` | float | Current wallet balance |

### Tip Item Fields

| Field | Type | Description |
|-------|------|-------------|
| `order_id` | integer | Unique order identifier |
| `tip_amount` | float | Amount tipped by customer (₹) |
| `order_amount` | float | Total order value (₹) |
| `delivery_charge` | float | Delivery charge for this order (₹) |
| `customer_name` | string | Name of customer who placed order |
| `customer_phone` | string | Contact phone of customer |
| `delivery_address` | string | Full delivery address |
| `order_items_count` | integer | Number of items in order |
| `payment_method` | string | Payment method used ('cash', 'online', etc.) |
| `order_status` | string | Current status of order ('delivered', etc.) |
| `order_date` | string | Date order was placed (YYYY-MM-DD) |
| `order_time` | string | Time order was placed (HH:MM:SS) |
| `delivery_time` | string | Time order was delivered (HH:MM:SS) |
| `restaurant_name` | string | Name of selling restaurant/store |
| `restaurant_address` | string | Address of restaurant |
| `delivery_distance_km` | float | Distance traveled for delivery (km) |
| `created_at` | string | Full timestamp when order was created (ISO 8601) |
| `updated_at` | string | Full timestamp when order was last updated (ISO 8601) |

### Summary Statistics

**Week Summary:**
- `week_start` - Start date of week
- `week_end` - End date of week
- `week_range` - Human-readable week range
- `total_tips` - Sum of all tips in week
- `total_orders_with_tips` - Count of orders with tips
- `average_tip_per_order` - Average tip amount
- `max_tip` - Highest tip amount
- `min_tip` - Lowest tip amount
- `total_orders_count` - Total delivered orders (including those without tips)
- `days_with_tips` - Daily breakdown of tips

**Day Summary:**
- `date` - The date (YYYY-MM-DD)
- `day_of_week` - Day name (e.g., "Thursday")
- `total_tips` - Sum of all tips
- `total_orders_with_tips` - Count of orders with tips
- `average_tip_per_order` - Average tip amount
- `total_delivered_orders` - Total delivered orders
- `hourly_breakdown` - Tips grouped by hour

**Range Summary:**
- `from_date` - Start date of range
- `to_date` - End date of range
- `date_range` - Human-readable date range
- `days_count` - Number of days in range
- `total_tips` - Sum of all tips in range
- `total_orders_with_tips` - Count of orders with tips
- `average_tip_per_order` - Average tip amount
- `max_tip` - Highest tip amount
- `min_tip` - Lowest tip amount
- `daily_breakdown` - Daily breakdown with day of week

### Navigation Object

For weekly endpoint only:

```json
{
  "current": {
    "week_start": "2026-01-05",
    "week_end": "2026-01-11",
    "offset": 0
  },
  "previous": {
    "week_start": "2025-12-29",
    "week_end": "2026-01-04",
    "offset": -1
  },
  "next": {
    "week_start": "2026-01-12",
    "week_end": "2026-01-18",
    "offset": 1
  }
}
```

Provides easy navigation between weeks with exact start/end dates and offset values for API calls.

---

## Usage Examples

### JavaScript/Fetch

**Get Current Week Tips:**

```javascript
const getWeeklyTips = async (offset = 0) => {
  try {
    const response = await fetch(
      `/api/delivery-boy/tips/weekly?offset=${offset}`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Accept': 'application/json'
        }
      }
    );
    const data = await response.json();
    console.log('Weekly Tips:', data);
    return data;
  } catch (error) {
    console.error('Error:', error);
  }
};

// Call with navigation
getWeeklyTips(0);  // Current week
getWeeklyTips(-1); // Previous week
getWeeklyTips(1);  // Next week
```

**Get Daily Tips:**

```javascript
const getDailyTips = async (date) => {
  const response = await fetch(
    `/api/delivery-boy/tips/daily?date=${date}`,
    {
      headers: { 'Authorization': `Bearer ${authToken}` }
    }
  );
  return response.json();
};

getDailyTips('2026-01-09');
```

**Get Range Tips:**

```javascript
const getRangeTips = async (fromDate, toDate) => {
  const response = await fetch(
    `/api/delivery-boy/tips/range?from_date=${fromDate}&to_date=${toDate}`,
    {
      headers: { 'Authorization': `Bearer ${authToken}` }
    }
  );
  return response.json();
};

getRangeTips('2026-01-01', '2026-01-31');
```

### cURL

**Get Current Week Tips:**

```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/weekly' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN' \
  -H 'Accept: application/json'
```

**Get Previous Week Tips:**

```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/weekly?offset=-1' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN'
```

**Get Daily Tips:**

```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/daily?date=2026-01-09' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN'
```

**Get Range Tips:**

```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/range?from_date=2026-01-01&to_date=2026-01-31' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN'
```

---

## Error Handling

### Common Error Responses

**401 Unauthorized:**
```json
{
  "status": false,
  "message": "Unauthorized"
}
```
**Cause:** Missing or invalid authentication token

**422 Unprocessable Entity:**
```json
{
  "status": false,
  "message": "from_date and to_date are required"
}
```
**Cause:** Missing required parameters for range endpoint

**500 Internal Server Error:**
```json
{
  "status": false,
  "message": "Error fetching delivery tips: [error details]"
}
```
**Cause:** Server-side error (checked logs for details)

---

## Data Accuracy

### Tip Extraction Logic

Tips are extracted from the order's `cart_metadata` JSON field in the following order:

1. **Primary:** `cart_metadata['cart_info']['delivery_tip']`
2. **Fallback:** `cart_metadata['delivery_tip']`
3. **Default:** 0.00 if not found

### Delivery Charge Extraction

Delivery charges are extracted in this order:

1. **Primary:** `cart_metadata['cart_info']['delivery_charge']`
2. **Secondary:** `cart_metadata['billing_breakdown'][2]['amount']`
3. **Default:** 0.00 if not found

---

## Performance Considerations

- **Weekly Endpoint:** Queries orders for a 7-day period
- **Daily Endpoint:** Queries orders for a single day
- **Range Endpoint:** Queries orders for specified date range (can be large)

For large date ranges, consider:
- Using the weekly endpoint with pagination
- Limiting range to 30-90 days maximum
- Running during off-peak hours

---

## Database Fields Used

The API queries the following tables and columns:

**orders table:**
- `delivery_boy_id` - Identifies orders for specific delivery boy
- `status` - Filters for 'delivered' orders only
- `created_at` - Date filtering
- `user_name` - Customer name
- `user_phone` - Customer contact
- `delivery_address` - Delivery location
- `total_amount` - Order total
- `seller_name` - Restaurant name
- `seller_address` - Restaurant location
- `payment_method` - Payment type
- `delivery_distance_km` - Delivery distance
- `cart_metadata` - Contains tip amount

---

## Integration Guide

### Adding to Frontend

1. **Request Weekly Tips on Dashboard:**

```javascript
// On delivery boy dashboard load
const weeklyTips = await getWeeklyTips();
displayWeekSummary(weeklyTips.data.week_summary);
displayTipsList(weeklyTips.data.tips_list);
```

2. **Weekly Navigation:**

```javascript
// Previous week button
onClickPrevious() {
  weeklyTips = await getWeeklyTips(-1);
  refresh();
}

// Next week button
onClickNext() {
  weeklyTips = await getWeeklyTips(1);
  refresh();
}
```

3. **Display Charts:**

```javascript
// Use days_with_tips for chart
const chartData = weeklyTips.data.week_summary.days_with_tips;
renderWeekChart(chartData);
```

---

## Summary

The Delivery Tips API provides:

✅ **Weekly Tips** - View tips by week with easy navigation
✅ **Daily Tips** - Detailed breakdown by hour
✅ **Custom Range** - Flexible date range queries
✅ **Complete Order Details** - Customer, restaurant, and delivery information
✅ **Statistical Insights** - Totals, averages, min/max tips
✅ **Navigation Support** - Easy week switching
✅ **Comprehensive Logging** - All operations logged for debugging

The API is designed for delivery boy mobile/web apps to help them track and understand their tipping patterns over time.
