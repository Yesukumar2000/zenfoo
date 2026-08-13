# Performance & Earnings API

## Overview

The Performance API provides delivery boys with comprehensive earnings and performance data across different time periods with optional date range filtering.

## Endpoint

```
GET /api/delivery-boy/performance/earnings
```

**Authentication**: Required (Bearer token)

---

## Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `period` | string | No (default: daily) | `daily`, `weekly`, or `monthly` |
| `date` | string | No | Specific date (YYYY-MM-DD) for daily view, or reference date for week/month |
| `from_date` | string | No | Range start date (YYYY-MM-DD) for weekly/monthly multi-period views |
| `to_date` | string | No | Range end date (YYYY-MM-DD) for weekly/monthly multi-period views |

---

## Usage Examples

### 1. Daily Performance (Today)

```
GET /api/delivery-boy/performance/earnings?period=daily
```

Returns earnings and performance metrics for today.

### 2. Daily Performance (Specific Date)

```
GET /api/delivery-boy/performance/earnings?period=daily&date=2026-01-09
```

Returns data for January 9, 2026.

### 3. Single Week Performance

```
GET /api/delivery-boy/performance/earnings?period=weekly&date=2026-01-09
```

Returns the full week containing January 9, 2026, with daily breakdown.

### 4. Weekly Range Performance

```
GET /api/delivery-boy/performance/earnings?period=weekly&from_date=2026-01-01&to_date=2026-01-31
```

Returns all weeks between January 1-31, grouped by week with breakdown.

### 5. Single Month Performance

```
GET /api/delivery-boy/performance/earnings?period=monthly&date=2026-01-09
```

Returns January 2026 data with weekly breakdown.

### 6. Monthly Range Performance

```
GET /api/delivery-boy/performance/earnings?period=monthly&from_date=2025-11-01&to_date=2026-01-31
```

Returns all months from November 2025 to January 2026, grouped by month.

---

## Response Structure

### Daily View Response

```json
{
  "status": true,
  "message": "Daily performance retrieved successfully",
  "data": {
    "period_type": "daily",
    "date": "2026-01-09T00:00:00+00:00",
    "earnings_overview": {
      "total_earnings": 5300.00,
      "order_earnings": 3200.00,
      "multi_order_earnings": 800.00,
      "incentive_earnings": 800.00,
      "tips": 500.00
    },
    "todays_performance": {
      "distance_covered": 120.5,
      "total_orders": 30,
      "orders_completed": 28,
      "orders_cancelled": 2,
      "login_hours": "10:30:45"
    },
    "earnings_breakdown": [
      {
        "name": "Order earnings",
        "description": "Earning you receive per order.",
        "amount": 3200.00,
        "percentage": 60.38,
        "icon": "package"
      },
      {
        "name": "Multi order earnings",
        "description": "Extra amount for multiple orders.",
        "amount": 800.00,
        "percentage": 15.09,
        "icon": "boxes"
      },
      {
        "name": "Incentives",
        "description": "Extra pay for completing gigs.",
        "amount": 800.00,
        "percentage": 15.09,
        "icon": "gift"
      },
      {
        "name": "Customer tips",
        "description": "Extra pay for completing gigs.",
        "amount": 500.00,
        "percentage": 9.43,
        "icon": "star"
      }
    ],
    "available_dates": {
      "type": "daily",
      "dates": ["2026-01-09", "2026-01-08", "2026-01-07", "..."]
    }
  }
}
```

### Weekly View Response (Single Week)

```json
{
  "status": true,
  "message": "Weekly performance retrieved successfully",
  "data": {
    "period_type": "weekly",
    "week_start": "2026-01-05T00:00:00+00:00",
    "week_end": "2026-01-11T00:00:00+00:00",
    "earnings_overview": {
      "total_earnings": 35000.00,
      "order_earnings": 22000.00,
      "multi_order_earnings": 5000.00,
      "incentive_earnings": 5000.00,
      "tips": 3000.00
    },
    "todays_performance": {
      "distance_covered": 850.5,
      "total_orders": 210,
      "orders_completed": 196,
      "orders_cancelled": 14,
      "login_hours": "70:15:30"
    },
    "daily_breakdown": [
      {
        "date": "2026-01-05",
        "day_name": "Mon",
        "earnings": 4500.00,
        "orders": 30,
        "distance": 115.5
      },
      {
        "date": "2026-01-06",
        "day_name": "Tue",
        "earnings": 5200.00,
        "orders": 32,
        "distance": 128.0
      },
      "..."
    ],
    "earnings_breakdown": [
      {
        "name": "Order earnings",
        "amount": 22000.00,
        "percentage": 62.86,
        "icon": "package"
      },
      "..."
    ],
    "available_dates": {
      "type": "weekly",
      "weeks": ["2026-01-09", "2025-12-26", "..."]
    }
  }
}
```

### Weekly Range Response (Multiple Weeks)

```json
{
  "status": true,
  "message": "Weekly performance retrieved successfully",
  "data": {
    "period_type": "weekly_range",
    "range_start": "2026-01-01T00:00:00+00:00",
    "range_end": "2026-01-31T00:00:00+00:00",
    "earnings_overview": {
      "total_earnings": 140000.00,
      "order_earnings": 88000.00,
      "multi_order_earnings": 20000.00,
      "incentive_earnings": 20000.00,
      "tips": 12000.00
    },
    "performance_summary": {
      "distance_covered": 3400.5,
      "total_orders": 840,
      "orders_completed": 784,
      "orders_cancelled": 56,
      "login_hours": "280:45:00"
    },
    "weekly_breakdown": [
      {
        "week": "Week 1",
        "start_date": "2026-01-01",
        "end_date": "2026-01-04",
        "earnings": 28000.00,
        "order_earnings": 17500.00,
        "multi_order_earnings": 4000.00,
        "incentive_earnings": 4000.00,
        "tips": 2500.00,
        "orders": 168,
        "orders_completed": 156,
        "orders_cancelled": 12,
        "distance": 680.0,
        "login_hours": "56:10:00"
      },
      {
        "week": "Week 2",
        "start_date": "2026-01-05",
        "end_date": "2026-01-11",
        "earnings": 35000.00,
        "order_earnings": 22000.00,
        "multi_order_earnings": 5000.00,
        "incentive_earnings": 5000.00,
        "tips": 3000.00,
        "orders": 210,
        "orders_completed": 196,
        "orders_cancelled": 14,
        "distance": 850.5,
        "login_hours": "70:15:30"
      },
      "..."
    ]
  }
}
```

### Monthly Range Response (Multiple Months)

```json
{
  "status": true,
  "message": "Monthly performance retrieved successfully",
  "data": {
    "period_type": "monthly_range",
    "range_start": "2025-11-01T00:00:00+00:00",
    "range_end": "2026-01-31T00:00:00+00:00",
    "earnings_overview": {
      "total_earnings": 430000.00,
      "order_earnings": 268000.00,
      "multi_order_earnings": 62000.00,
      "incentive_earnings": 62000.00,
      "tips": 38000.00
    },
    "performance_summary": {
      "distance_covered": 10500.5,
      "total_orders": 2580,
      "orders_completed": 2412,
      "orders_cancelled": 168,
      "login_hours": "870:30:00"
    },
    "monthly_breakdown": [
      {
        "month": "Nov 2025",
        "month_number": 1,
        "start_date": "2025-11-01",
        "end_date": "2025-11-30",
        "earnings": 140000.00,
        "order_earnings": 88000.00,
        "multi_order_earnings": 21000.00,
        "incentive_earnings": 21000.00,
        "tips": 10000.00,
        "orders": 840,
        "orders_completed": 784,
        "orders_cancelled": 56,
        "distance": 3400.5,
        "login_hours": "280:45:00"
      },
      {
        "month": "Dec 2025",
        "month_number": 2,
        "start_date": "2025-12-01",
        "end_date": "2025-12-31",
        "earnings": 145000.00,
        "order_earnings": 90000.00,
        "multi_order_earnings": 21000.00,
        "incentive_earnings": 21000.00,
        "tips": 13000.00,
        "orders": 870,
        "orders_completed": 814,
        "orders_cancelled": 56,
        "distance": 3535.0,
        "login_hours": "290:15:00"
      },
      {
        "month": "Jan 2026",
        "month_number": 3,
        "start_date": "2026-01-01",
        "end_date": "2026-01-31",
        "earnings": 145000.00,
        "order_earnings": 90000.00,
        "multi_order_earnings": 20000.00,
        "incentive_earnings": 20000.00,
        "tips": 15000.00,
        "orders": 870,
        "orders_completed": 814,
        "orders_cancelled": 56,
        "distance": 3565.0,
        "login_hours": "299:30:00"
      }
    ]
  }
}
```

---

## Data Breakdown

### Earnings Overview Fields

- **total_earnings**: Sum of all earning types
- **order_earnings**: Base earnings from completed orders
- **multi_order_earnings**: Bonus for picking up multiple orders
- **incentive_earnings**: Tier-based incentive bonuses
- **tips**: Customer tips received

### Performance Metrics

- **distance_covered**: Total kilometers traveled
- **total_orders**: Orders received
- **orders_completed**: Orders successfully delivered
- **orders_cancelled**: Orders cancelled
- **login_hours**: Total hours logged in (formatted as HH:MM:SS)

### Earnings Breakdown Types

Each breakdown item has:
- `name`: Display name
- `description`: What this earning type represents
- `amount`: Total amount for this type
- `percentage`: Percentage of total earnings
- `icon`: Icon name for frontend rendering (package, boxes, gift, star)

---

## Chart Data

### Weekly View - Daily Breakdown
- Used for creating line/bar charts showing daily trends within a week
- Fields: date, day_name, earnings, orders, distance

### Monthly View - Weekly Breakdown
- Used for creating line/bar charts showing weekly trends within a month
- Fields: week, start_date, end_date, earnings, orders, distance

### Weekly Range View - Weekly Breakdown
- Multiple weeks with all earnings details
- Fields: week, start_date, end_date, + all earnings types + performance metrics

### Monthly Range View - Monthly Breakdown
- Multiple months with all earnings details
- Fields: month, start_date, end_date, + all earnings types + performance metrics

---

## Available Dates Selection

Each response includes an `available_dates` section showing what dates/weeks/months have data available:

```json
"available_dates": {
  "type": "daily",
  "dates": ["2026-01-09", "2026-01-08", "2026-01-07"]
}
```

Or for weekly:
```json
"available_dates": {
  "type": "weekly",
  "weeks": ["2026-01-09", "2025-12-26", "2025-12-19"]
}
```

Or for monthly:
```json
"available_dates": {
  "type": "monthly",
  "months": ["2026-01", "2025-12", "2025-11"]
}
```

---

## Error Responses

### Unauthorized
```json
{
  "status": false,
  "message": "Unauthorized"
}
```

### Delivery Boy Not Found
```json
{
  "status": false,
  "message": "Delivery boy not found"
}
```

### Server Error
```json
{
  "status": false,
  "message": "Error message details"
}
```

---

## Implementation Notes

- **Date Format**: All dates use ISO 8601 format (YYYY-MM-DDTHH:MM:SS+00:00)
- **Calculations**: All sums are calculated from `DeliveryBoyDailyTracking` records
- **Chart Ready**: Daily breakdown in weekly view, weekly breakdown in monthly view
- **Timezone**: All times are in UTC (indicated by +00:00)
- **Range Handling**: Date ranges automatically adjust to period boundaries (weeks start Monday, months start 1st)

---

## Performance Tips

1. **For Real-Time Dashboards**: Use daily view with today's date
2. **For Weekly Reports**: Use weekly view without date range parameters
3. **For Analytics**: Use range views (from_date + to_date) for multi-period analysis
4. **For Chart Data**: Parse the `daily_breakdown` (weekly) or `weekly_breakdown` (monthly)

