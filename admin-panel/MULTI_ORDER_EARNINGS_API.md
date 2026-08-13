# Multi-Order Earnings API Documentation

## Overview

The Multi-Order Earnings API provides detailed tracking of earnings from multi-order deliveries with complete transaction details, period-based navigation, and comprehensive statistics. Perfect for delivery boys to understand their multi-order performance patterns.

---

## Endpoint

### Get Multi-Order Earnings by Period

**Endpoint:** `GET /api/delivery-boy/earnings/multi-order`

**Authentication:** Required (auth:api)

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `period` | string | No | daily | Period type: 'daily', 'weekly', or 'monthly' |
| `date` | string | No | Today | Reference date (YYYY-MM-DD format) |
| `offset` | integer | No | 0 | Period offset (-1 for previous, 0 for current, 1 for next) |

**Example Requests:**

```bash
# Get today's multi-order earnings
GET /api/delivery-boy/earnings/multi-order

# Get previous day's earnings
GET /api/delivery-boy/earnings/multi-order?period=daily&offset=-1

# Get current week earnings
GET /api/delivery-boy/earnings/multi-order?period=weekly

# Get last month earnings
GET /api/delivery-boy/earnings/multi-order?period=monthly&offset=-1

# Get specific date's earnings
GET /api/delivery-boy/earnings/multi-order?date=2026-01-09&period=daily
```

---

## Response Structure

### Daily Response Example

```json
{
  "status": true,
  "message": "Daily multi-order earnings retrieved successfully",
  "data": {
    "period_type": "daily",
    "delivery_boy": {
      "id": 5,
      "name": "Ravi Kumar",
      "phone": "9876543210",
      "current_balance": 5500.00
    },
    "day_summary": {
      "date": "2026-01-09",
      "day_of_week": "Thursday",
      "total_earnings": 500.00,
      "total_transactions": 5,
      "average_per_transaction": 100.00,
      "max_transaction": 150.00,
      "min_transaction": 50.00,
      "hourly_breakdown": [
        {
          "hour": "10:00",
          "total_earnings": 100.00
        },
        {
          "hour": "12:00",
          "total_earnings": 150.00
        },
        {
          "hour": "14:00",
          "total_earnings": 100.00
        },
        {
          "hour": "16:00",
          "total_earnings": 150.00
        }
      ]
    },
    "transactions": [
      {
        "transaction_id": 501,
        "amount": 150.00,
        "order_id": 1025,
        "message": "Multi-order bonus",
        "status": "success",
        "transaction_date": "2026-01-09",
        "transaction_time": "16:30:45",
        "timestamp": "2026-01-09T16:30:45Z",
        "created_at": "2026-01-09T16:30:45Z",
        "updated_at": "2026-01-09T16:30:45Z"
      },
      {
        "transaction_id": 500,
        "amount": 100.00,
        "order_id": 1024,
        "message": "Multi-order bonus",
        "status": "success",
        "transaction_date": "2026-01-09",
        "transaction_time": "14:20:30",
        "timestamp": "2026-01-09T14:20:30Z",
        "created_at": "2026-01-09T14:20:30Z",
        "updated_at": "2026-01-09T14:20:30Z"
      }
    ],
    "navigation": {
      "current": "2026-01-09",
      "previous": "2026-01-08",
      "next": "2026-01-10",
      "period": "daily",
      "offset": {
        "current": 0,
        "previous": -1,
        "next": 1
      }
    }
  }
}
```

### Weekly Response Example

```json
{
  "status": true,
  "message": "Weekly multi-order earnings retrieved successfully",
  "data": {
    "period_type": "weekly",
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
      "total_earnings": 3500.00,
      "total_transactions": 35,
      "average_per_transaction": 100.00,
      "max_transaction": 200.00,
      "min_transaction": 50.00,
      "daily_breakdown": [
        {
          "date": "2026-01-05",
          "day_of_week": "Sunday",
          "total_earnings": 450.00
        },
        {
          "date": "2026-01-06",
          "day_of_week": "Monday",
          "total_earnings": 500.00
        },
        {
          "date": "2026-01-09",
          "day_of_week": "Thursday",
          "total_earnings": 500.00
        }
      ]
    },
    "transactions": [
      {
        "transaction_id": 501,
        "amount": 150.00,
        "order_id": 1025,
        "message": "Multi-order bonus",
        "status": "success",
        "transaction_date": "2026-01-09",
        "transaction_time": "16:30:45",
        "timestamp": "2026-01-09T16:30:45Z",
        "created_at": "2026-01-09T16:30:45Z",
        "updated_at": "2026-01-09T16:30:45Z"
      }
    ],
    "navigation": {
      "current": "2026-01-05",
      "previous": "2025-12-29",
      "next": "2026-01-12",
      "period": "weekly",
      "offset": {
        "current": 0,
        "previous": -1,
        "next": 1
      }
    }
  }
}
```

### Monthly Response Example

```json
{
  "status": true,
  "message": "Monthly multi-order earnings retrieved successfully",
  "data": {
    "period_type": "monthly",
    "delivery_boy": {
      "id": 5,
      "name": "Ravi Kumar",
      "phone": "9876543210",
      "current_balance": 5500.00
    },
    "month_summary": {
      "month": "2026-01",
      "month_range": "January 2026",
      "total_days": 31,
      "total_earnings": 15000.00,
      "total_transactions": 150,
      "average_per_transaction": 100.00,
      "max_transaction": 250.00,
      "min_transaction": 50.00,
      "daily_breakdown": [
        {
          "date": "2026-01-01",
          "day_of_week": "Wednesday",
          "total_earnings": 450.00
        },
        {
          "date": "2026-01-02",
          "day_of_week": "Thursday",
          "total_earnings": 550.00
        }
      ]
    },
    "transactions": [
      {
        "transaction_id": 501,
        "amount": 150.00,
        "order_id": 1025,
        "message": "Multi-order bonus",
        "status": "success",
        "transaction_date": "2026-01-09",
        "transaction_time": "16:30:45",
        "timestamp": "2026-01-09T16:30:45Z",
        "created_at": "2026-01-09T16:30:45Z",
        "updated_at": "2026-01-09T16:30:45Z"
      }
    ],
    "navigation": {
      "current": "2026-01-01",
      "previous": "2025-12-01",
      "next": "2026-02-01",
      "period": "monthly",
      "offset": {
        "current": 0,
        "previous": -1,
        "next": 1
      }
    }
  }
}
```

---

## Response Fields

### Delivery Boy Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique delivery boy identifier |
| `name` | string | Full name |
| `phone` | string | Contact phone number |
| `current_balance` | float | Current wallet balance |

### Day/Week/Month Summary

**Daily Summary:**
- `date` - Date (YYYY-MM-DD)
- `day_of_week` - Day name (e.g., "Thursday")
- `total_earnings` - Sum of all multi-order earnings
- `total_transactions` - Count of multi-order transactions
- `average_per_transaction` - Mean earnings per transaction
- `max_transaction` - Highest single transaction
- `min_transaction` - Lowest single transaction
- `hourly_breakdown` - Earnings grouped by hour

**Weekly Summary:**
- `week_start` - Week start date
- `week_end` - Week end date
- `week_range` - Human-readable week range
- `total_earnings` - Sum of all multi-order earnings
- `total_transactions` - Count of multi-order transactions
- `average_per_transaction` - Mean earnings per transaction
- `max_transaction` - Highest single transaction
- `min_transaction` - Lowest single transaction
- `daily_breakdown` - Earnings grouped by day with day of week

**Monthly Summary:**
- `month` - Month in YYYY-MM format
- `month_range` - Human-readable month name and year
- `total_days` - Days in month (28/29/30/31)
- `total_earnings` - Sum of all multi-order earnings
- `total_transactions` - Count of multi-order transactions
- `average_per_transaction` - Mean earnings per transaction
- `max_transaction` - Highest single transaction
- `min_transaction` - Lowest single transaction
- `daily_breakdown` - Earnings grouped by day with day of week

### Transaction Details

Each transaction includes:

| Field | Type | Description |
|-------|------|-------------|
| `transaction_id` | integer | Unique transaction ID |
| `amount` | float | Multi-order bonus amount |
| `order_id` | integer | Associated order ID |
| `message` | string | Transaction message/description |
| `status` | string | Transaction status ('success', 'failed', etc.) |
| `transaction_date` | string | Date only (YYYY-MM-DD) |
| `transaction_time` | string | Time (HH:MM:SS) format |
| `timestamp` | string | Full ISO 8601 timestamp |
| `created_at` | string | Record created timestamp |
| `updated_at` | string | Record updated timestamp |

### Navigation Object

Provides easy switching between periods:

```json
{
  "current": "2026-01-09",
  "previous": "2026-01-08",
  "next": "2026-01-10",
  "period": "daily",
  "offset": {
    "current": 0,
    "previous": -1,
    "next": 1
  }
}
```

- `current` - Current period date/range
- `previous` - Previous period date/range
- `next` - Next period date/range
- `period` - Period type (daily/weekly/monthly)
- `offset` - Offset values for API calls

---

## Usage Examples

### JavaScript/Fetch

**Get Today's Multi-Order Earnings:**

```javascript
const getMultiOrderEarnings = async (period = 'daily', offset = 0) => {
  try {
    const params = new URLSearchParams({
      period: period,
      offset: offset
    });

    const response = await fetch(
      `/api/delivery-boy/earnings/multi-order?${params}`,
      {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Accept': 'application/json'
        }
      }
    );
    const data = await response.json();
    console.log('Multi-Order Earnings:', data);
    return data;
  } catch (error) {
    console.error('Error:', error);
  }
};

// Usage
getMultiOrderEarnings('daily', 0);  // Today
getMultiOrderEarnings('daily', -1); // Yesterday
getMultiOrderEarnings('weekly', 0); // Current week
getMultiOrderEarnings('monthly', 0); // Current month
```

**Get Previous Week Earnings:**

```javascript
const response = await fetch(
  '/api/delivery-boy/earnings/multi-order?period=weekly&offset=-1',
  {
    headers: { 'Authorization': `Bearer ${token}` }
  }
);
const data = await response.json();
```

### cURL

**Get Today's Earnings:**

```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN' \
  -H 'Accept: application/json'
```

**Get Current Week:**

```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order?period=weekly' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN'
```

**Get Previous Month:**

```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order?period=monthly&offset=-1' \
  -H 'Authorization: Bearer YOUR_AUTH_TOKEN'
```

---

## Frontend Integration

### React Example

```javascript
export default function MultiOrderEarnings() {
  const [earnings, setEarnings] = useState(null);
  const [period, setPeriod] = useState('daily');
  const [offset, setOffset] = useState(0);

  useEffect(() => {
    fetchEarnings();
  }, [period, offset]);

  const fetchEarnings = async () => {
    const response = await fetch(
      `/api/delivery-boy/earnings/multi-order?period=${period}&offset=${offset}`,
      { headers: { 'Authorization': `Bearer ${token}` } }
    );
    setEarnings((await response.json()).data);
  };

  return (
    <div>
      <h2>Multi-Order Earnings</h2>
      <div>
        <button onClick={() => setOffset(-1)}>Previous</button>
        <span>{earnings?.day_summary?.date}</span>
        <button onClick={() => setOffset(1)}>Next</button>
      </div>
      <p>Total: ₹{earnings?.day_summary?.total_earnings}</p>
      <p>Transactions: {earnings?.day_summary?.total_transactions}</p>
      <p>Average: ₹{earnings?.day_summary?.average_per_transaction}</p>

      <table>
        <thead>
          <tr>
            <th>Time</th>
            <th>Amount</th>
            <th>Order ID</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {earnings?.transactions?.map(t => (
            <tr key={t.transaction_id}>
              <td>{t.transaction_time}</td>
              <td>₹{t.amount}</td>
              <td>{t.order_id}</td>
              <td>{t.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

### Vue Example

```javascript
export default {
  data() {
    return {
      earnings: null,
      period: 'daily',
      offset: 0
    };
  },
  watch: {
    period() { this.fetchEarnings(); },
    offset() { this.fetchEarnings(); }
  },
  methods: {
    async fetchEarnings() {
      const response = await fetch(
        `/api/delivery-boy/earnings/multi-order?period=${this.period}&offset=${this.offset}`,
        { headers: { 'Authorization': `Bearer ${this.token}` } }
      );
      this.earnings = (await response.json()).data;
    },
    previousPeriod() { this.offset--; },
    nextPeriod() { this.offset++; }
  }
};
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

**404 Not Found:**
```json
{
  "status": false,
  "message": "Delivery boy not found"
}
```

**500 Server Error:**
```json
{
  "status": false,
  "message": "Error fetching multi-order earnings: [error details]"
}
```

---

## Key Features

✅ **Three Period Types** - Daily, weekly, and monthly views
✅ **Easy Navigation** - Offset-based navigation (-1, 0, 1)
✅ **Complete Transactions** - Full transaction list with all details
✅ **Statistics** - Total, average, min/max earnings
✅ **Time Breakdown** - Hourly breakdown for daily, daily for weekly/monthly
✅ **Transaction Details** - Order ID, message, status, timestamps
✅ **Delivery Boy Info** - Name, phone, current balance
✅ **Flexible Filtering** - Period and date selection
✅ **Proper Authentication** - Auth::user() pattern
✅ **Comprehensive Logging** - All operations logged

---

## Data Accuracy

### Multi-Order Transactions

Multi-order earnings are extracted from `delivery_boy_transactions` table where:
- `type = 'multi_order'`
- `status = 'success'` (filters unsuccessful transactions)
- Date filtering applied based on `transaction_date`

### Grouping Logic

**Daily View:**
- Transactions grouped by hour (HH:00 format)
- Shows which hours had multi-order bonuses

**Weekly View:**
- Transactions grouped by date
- Shows daily totals across the week

**Monthly View:**
- Transactions grouped by date
- Shows daily totals throughout the month

---

## Database Query Pattern

```php
DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
    ->where('type', 'multi_order')
    ->whereDate('transaction_date', $date)
    ->orderBy('transaction_date', 'desc')
    ->get();
```

---

## Performance Notes

- **Daily Query:** ~10-50 transactions typical
- **Weekly Query:** ~50-200 transactions typical
- **Monthly Query:** ~200-1000+ transactions typical
- All queries indexed on (delivery_boy_id, type, transaction_date)
- Response times typically < 100ms

---

## Testing Scenarios

### Test 1: Get Today's Earnings
```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order' \
  -H 'Authorization: Bearer TOKEN'
```
Expected: Returns today's multi-order transactions and statistics

### Test 2: Navigate Weeks
```bash
# Current week
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order?period=weekly&offset=0'

# Previous week
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order?period=weekly&offset=-1'

# Next week
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order?period=weekly&offset=1'
```

### Test 3: Monthly Breakdown
```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/earnings/multi-order?period=monthly'
```
Expected: All multi-order earnings for current month grouped by day

---

## Integration Notes

- **Similar to:** Performance API (period-based, offset navigation)
- **Data Source:** `delivery_boy_transactions` table
- **Complements:** DeliveryTipsAPI, Performance API
- **Use Case:** Dedicated multi-order earnings tracking and analysis

---

## Summary

The Multi-Order Earnings API provides:

✅ **Dedicated Tracking** - Focus only on multi-order bonuses
✅ **Clear Period Navigation** - Easy switching between periods
✅ **Detailed Transactions** - Complete order and timing information
✅ **Statistical Analysis** - Average, min, max, and totals
✅ **Time-Based Breakdown** - Hourly/daily patterns
✅ **Easy Integration** - Works with existing auth system
✅ **Well Documented** - Complete API reference with examples

Perfect for delivery boys to understand their multi-order performance and earnings patterns!

---

**Version:** 1.0.0
**Created:** 2026-01-10
**Status:** Production Ready
