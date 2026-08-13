# Chart Data Guide - Performance API

## Overview

The Performance API now returns complete breakdown data for visualizing earnings across different time periods. Each breakdown includes all necessary data to display charts showing what earnings were made on each day/week/month.

---

## 1. Daily Chart Data

### Request
```
GET /api/delivery-boy/performance/earnings?period=weekly
```

### Response Structure
```json
{
  "data": {
    "period_type": "weekly",
    "week_start": "2026-01-05T00:00:00+00:00",
    "week_end": "2026-01-11T00:00:00+00:00",
    "daily_breakdown": [
      {
        "date": "2026-01-05",
        "day_name": "Mon",
        "day_number": 5,
        "total_earnings": 4500.00,
        "order_earnings": 2800.00,
        "multi_order_earnings": 600.00,
        "incentive_earnings": 700.00,
        "tips": 400.00,
        "total_orders": 30,
        "orders_completed": 28,
        "orders_cancelled": 2,
        "distance_covered": 115.5,
        "login_hours": "10:30:45"
      },
      {
        "date": "2026-01-06",
        "day_name": "Tue",
        "day_number": 6,
        "total_earnings": 5200.00,
        "order_earnings": 3200.00,
        "multi_order_earnings": 700.00,
        "incentive_earnings": 800.00,
        "tips": 500.00,
        "total_orders": 32,
        "orders_completed": 31,
        "orders_cancelled": 1,
        "distance_covered": 128.0,
        "login_hours": "11:15:30"
      },
      // ... 5 more days (Wed-Sun)
    ]
  }
}
```

### Using This Data in Charts

#### Example: Chart showing daily earnings
```javascript
const dailyData = response.data.daily_breakdown;

// Simple bar chart
const chartData = dailyData.map(day => ({
  label: day.day_name,           // Mon, Tue, Wed, etc.
  total_earnings: day.total_earnings,
  order_earnings: day.order_earnings,
  multi_order_earnings: day.multi_order_earnings,
  incentive_earnings: day.incentive_earnings,
  tips: day.tips,
  date: day.date
}));

// Result: 7 bars showing daily totals
```

#### Example: Stacked Bar Chart (Earnings by Type)
```javascript
const stackedData = dailyData.map(day => ({
  date: day.date,
  'Order': day.order_earnings,
  'Multi-Order': day.multi_order_earnings,
  'Incentive': day.incentive_earnings,
  'Tips': day.tips
}));

// Result: Stacked bars showing composition of each day's earnings
```

#### Example: Line Chart (Earnings Trend)
```javascript
const trendData = dailyData.map(day => ({
  date: day.day_name,
  earnings: day.total_earnings,
  timestamp: day.date
}));

// Result: Line graph showing earnings trend across the week
```

---

## 2. Weekly Chart Data (for Monthly View)

### Request
```
GET /api/delivery-boy/performance/earnings?period=monthly
```

### Response Structure
```json
{
  "data": {
    "period_type": "monthly",
    "month": "January 2026",
    "month_start": "2026-01-01T00:00:00+00:00",
    "month_end": "2026-01-31T00:00:00+00:00",
    "weekly_breakdown": [
      {
        "week": "Week 1",
        "start_date": "2025-12-29",
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
      // ... more weeks
    ]
  }
}
```

### Using This Data in Charts

#### Example: Weekly Earnings Bar Chart
```javascript
const weeklyData = response.data.weekly_breakdown;

const chartData = weeklyData.map(week => ({
  label: week.week,
  earnings: week.earnings,
  start_date: week.start_date,
  end_date: week.end_date
}));

// Result: Bar chart showing earnings for each week
// Example output:
// Week 1: ₹28,000
// Week 2: ₹35,000
// Week 3: ₹32,500
// Week 4: ₹29,800
```

#### Example: Week-over-Week Comparison
```javascript
const weeklyComparison = weeklyData.map(week => ({
  week: week.week,
  'Order': week.order_earnings,
  'Multi-Order': week.multi_order_earnings,
  'Incentive': week.incentive_earnings,
  'Tips': week.tips
}));

// Result: Grouped or stacked bars for each week showing earnings composition
```

#### Example: Performance Metrics Line Chart
```javascript
const performanceTrend = weeklyData.map(week => ({
  week: week.week,
  orders: week.orders,
  distance: week.distance,
  earnings: week.earnings
}));

// Result: Multi-line chart tracking orders, distance, and earnings trends
```

---

## 3. Monthly Chart Data (for Multi-Month Range)

### Request
```
GET /api/delivery-boy/performance/earnings?period=monthly&from_date=2025-11-01&to_date=2026-01-31
```

### Response Structure
```json
{
  "data": {
    "period_type": "monthly_range",
    "range_start": "2025-11-01T00:00:00+00:00",
    "range_end": "2026-01-31T00:00:00+00:00",
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

### Using This Data in Charts

#### Example: Monthly Earnings Comparison
```javascript
const monthlyData = response.data.monthly_breakdown;

const chartData = monthlyData.map(month => ({
  label: month.month,
  earnings: month.earnings,
  period: `${month.start_date} to ${month.end_date}`
}));

// Result: Bar chart comparing earnings across months
// Example output:
// Nov 2025: ₹140,000
// Dec 2025: ₹145,000
// Jan 2026: ₹145,000
```

#### Example: Month-over-Month Trend
```javascript
const monthlyTrend = monthlyData.map(month => ({
  month: month.month,
  'Order': month.order_earnings,
  'Multi-Order': month.multi_order_earnings,
  'Incentive': month.incentive_earnings,
  'Tips': month.tips,
  'Total': month.earnings
}));

// Result: Multi-series chart showing earnings breakdown per month
```

#### Example: Performance Dashboard
```javascript
const monthlyMetrics = monthlyData.map(month => ({
  month: month.month,
  earnings: month.earnings,
  orders: month.orders_completed,
  distance: parseFloat((month.distance / 1000).toFixed(2)), // Convert to thousands
  efficiency: (month.earnings / month.orders_completed).toFixed(2) // Earnings per order
}));

// Result: Comprehensive dashboard showing multiple metrics across months
```

---

## 4. Weekly Range Chart Data

### Request
```
GET /api/delivery-boy/performance/earnings?period=weekly&from_date=2026-01-01&to_date=2026-01-31
```

### Response Structure
```json
{
  "data": {
    "period_type": "weekly_range",
    "range_start": "2026-01-01T00:00:00+00:00",
    "range_end": "2026-01-31T00:00:00+00:00",
    "weekly_breakdown": [
      {
        "week": "Week 1",
        "start_date": "2025-12-29",
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
      // ... more weeks (4-5 total for January)
    ]
  }
}
```

### Using This Data in Charts

#### Example: Weekly Trend Over Month
```javascript
const weeklyRange = response.data.weekly_breakdown;

const chartData = weeklyRange.map(week => ({
  label: week.week,
  earnings: week.earnings,
  start: week.start_date,
  end: week.end_date
}));

// Result: Line or bar chart showing weekly trend across the month
```

---

## 5. Data Field Reference

### Common Fields in All Breakdowns

#### Earnings Fields
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `total_earnings` | float | Sum of all earning types | 4500.00 |
| `order_earnings` | float | Base delivery fees | 2800.00 |
| `multi_order_earnings` | float | Bonus for multiple orders | 600.00 |
| `incentive_earnings` | float | Tier-based incentives | 700.00 |
| `tips` | float | Customer tips | 400.00 |

#### Order Metrics
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `total_orders` | int | Orders received | 30 |
| `orders_completed` | int | Successfully delivered | 28 |
| `orders_cancelled` | int | Cancelled orders | 2 |

#### Performance Metrics
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `distance_covered` | float | KMs travelled | 115.5 |
| `distance` | float | KMs travelled (alternative) | 680.0 |
| `login_hours` | string | Time online (HH:MM:SS) | "10:30:45" |

#### Period Fields
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `date` | string | Specific date (daily) | "2026-01-05" |
| `day_name` | string | Day abbreviation | "Mon" |
| `day_number` | int | Day of month | 5 |
| `start_date` | string | Period start | "2026-01-05" |
| `end_date` | string | Period end | "2026-01-11" |
| `month` | string | Month name | "Nov 2025" |
| `week` | string | Week label | "Week 1" |

---

## 6. Chart Implementation Examples

### React Component Example
```jsx
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';

export function WeeklyEarningsChart() {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch('/api/delivery-boy/performance/earnings?period=weekly')
      .then(r => r.json())
      .then(json => setData(json.data));
  }, []);

  if (!data) return <div>Loading...</div>;

  return (
    <BarChart width={600} height={300} data={data.daily_breakdown}>
      <CartesianGrid />
      <XAxis dataKey="day_name" />
      <YAxis />
      <Tooltip />
      <Legend />
      <Bar dataKey="total_earnings" fill="#8884d8" />
      <Bar dataKey="orders_completed" fill="#82ca9d" />
    </BarChart>
  );
}
```

### Flutter Example
```dart
List<BarChartGroupData> createBarGroups(List<dynamic> dailyData) {
  return dailyData.asMap().entries.map((entry) {
    final day = entry.value;
    return BarChartGroupData(
      x: entry.key,
      barRods: [
        BarChartRodData(
          toY: (day['total_earnings'] as num).toDouble(),
          color: Colors.blue,
        ),
      ],
    );
  }).toList();
}
```

---

## 7. Data Transformation Helpers

### JavaScript/TypeScript
```javascript
// Get earnings totals for chart
function getChartDataFromDaily(dailyBreakdown) {
  return {
    dates: dailyBreakdown.map(d => d.date),
    earnings: dailyBreakdown.map(d => d.total_earnings),
    orders: dailyBreakdown.map(d => d.orders_completed),
    distance: dailyBreakdown.map(d => d.distance_covered),
  };
}

// Calculate daily average
function calculateDailyAverage(dailyBreakdown) {
  const total = dailyBreakdown.reduce((sum, d) => sum + d.total_earnings, 0);
  return total / dailyBreakdown.length;
}

// Find best and worst performing days
function getPerformanceRange(dailyBreakdown) {
  const earnings = dailyBreakdown.map(d => d.total_earnings);
  return {
    best: Math.max(...earnings),
    worst: Math.min(...earnings),
    average: earnings.reduce((a, b) => a + b, 0) / earnings.length
  };
}
```

---

## Summary

The Performance API provides complete breakdown data for:
- ✅ **Daily charts** (via weekly view) - 7 days of detailed data
- ✅ **Weekly charts** (via monthly view) - 4-5 weeks with full metrics
- ✅ **Weekly comparison charts** (via weekly range) - Multiple weeks in one view
- ✅ **Monthly charts** (via monthly range) - Multiple months comparison
- ✅ **Earnings breakdown** by type (order, multi-order, incentive, tips)
- ✅ **Performance metrics** (distance, orders, login hours)

All data is ready for visualization in any charting library!

