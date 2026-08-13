# Performance API Testing Guide

## Quick Test Cases

Use these cURL commands or Postman to test the Performance API endpoints.

### Setup

Replace these values:
- `{BASE_URL}`: Your API base URL (e.g., `http://localhost:8000/api`)
- `{TOKEN}`: Valid Bearer token from authenticated delivery boy

### Test 1: Daily Performance (Today)

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=daily" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Expected Response:**
- Status: 200
- `data.period_type`: "daily"
- `data.earnings_overview`: Object with earnings breakdown
- `data.todays_performance`: Object with distance, orders, login_hours
- `data.earnings_breakdown`: Array of 4 items (order, multi-order, incentive, tips)
- `data.available_dates`: Object with type "daily" and dates array

**Validate:**
- ✅ All earnings values are >= 0 and float type
- ✅ Orders completed <= total orders
- ✅ Percentages sum to 100 (or 0 if no earnings)
- ✅ login_hours format is HH:MM:SS

---

### Test 2: Daily Performance (Specific Date)

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=daily&date=2026-01-05" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Expected Response:**
- Status: 200
- `data.date`: "2026-01-05T00:00:00+00:00"
- Same structure as Test 1

**Validate:**
- ✅ Date matches requested date
- ✅ Data is different from today (if different data exists)

---

### Test 3: Single Week Performance

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=weekly&date=2026-01-09" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Expected Response:**
- Status: 200
- `data.period_type`: "weekly"
- `data.week_start` and `data.week_end`: ISO 8601 dates
- `data.daily_breakdown`: Array with 7 days (or fewer if week is partial)
- Each day in breakdown has: date, day_name, earnings, orders, distance

**Validate:**
- ✅ week_start is Monday and week_end is Sunday
- ✅ daily_breakdown has >= 1 item
- ✅ Sum of daily earnings ≈ weekly earnings_overview.total_earnings
- ✅ day_name values are: Mon, Tue, Wed, Thu, Fri, Sat, Sun

---

### Test 4: Weekly Range Performance

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=weekly&from_date=2026-01-01&to_date=2026-01-31" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Expected Response:**
- Status: 200
- `data.period_type`: "weekly_range"
- `data.range_start`: "2026-01-01T00:00:00+00:00"
- `data.range_end`: "2026-01-31T00:00:00+00:00"
- `data.weekly_breakdown`: Array of weeks (4+ items)
- Each week has: week, start_date, end_date, + all earnings types + orders/distance/login_hours

**Validate:**
- ✅ weekly_breakdown has >= 1 item
- ✅ Each week.start_date is Monday
- ✅ Sum of weekly earnings ≈ range earnings_overview.total_earnings (within 1%)
- ✅ Weeks are sequential and non-overlapping

---

### Test 5: Single Month Performance

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=monthly&date=2026-01-09" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Expected Response:**
- Status: 200
- `data.period_type`: "monthly"
- `data.month`: "January 2026" (or similar format)
- `data.month_start` and `data.month_end`: ISO 8601 dates
- `data.weekly_breakdown`: Array of weeks within the month (4-5 items)
- Each week has: week, start_date, end_date, + earnings types + orders/distance/login_hours

**Validate:**
- ✅ month_start is 1st of month
- ✅ month_end is last day of month
- ✅ weekly_breakdown has >= 1 item
- ✅ Sum of weekly earnings ≈ monthly earnings_overview.total_earnings

---

### Test 6: Monthly Range Performance

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=monthly&from_date=2025-11-01&to_date=2026-01-31" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Expected Response:**
- Status: 200
- `data.period_type`: "monthly_range"
- `data.range_start`: "2025-11-01T00:00:00+00:00"
- `data.range_end`: "2026-01-31T00:00:00+00:00"
- `data.monthly_breakdown`: Array of 3 months
- Each month has: month, month_number, start_date, end_date, + all earnings types

**Validate:**
- ✅ monthly_breakdown has 3 items (Nov, Dec, Jan)
- ✅ Each month.start_date is 1st
- ✅ month_number values are 1, 2, 3
- ✅ Sum of monthly earnings ≈ range earnings_overview.total_earnings

---

### Test 7: Default Period (No parameter)

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Expected Response:**
- Status: 200
- `data.period_type`: "daily" (defaults to daily)
- Same as Test 1 (today's data)

**Validate:**
- ✅ Defaults to daily view
- ✅ Date is today

---

### Test 8: Unauthorized Access

**Request:**
```bash
curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=daily"
```

**Expected Response:**
- Status: 401 or similar
- `status`: false
- `message`: "Unauthorized"

**Validate:**
- ✅ No access without token
- ✅ Error message is clear

---

## Data Validation Checklist

### All Responses Should Have

- [ ] `status`: boolean (true for success)
- [ ] `message`: string describing the result
- [ ] `data`: object with the actual data

### Earnings Overview Should Have

- [ ] `total_earnings`: float >= 0
- [ ] `order_earnings`: float >= 0
- [ ] `multi_order_earnings`: float >= 0
- [ ] `incentive_earnings`: float >= 0
- [ ] `tips`: float >= 0
- [ ] Sum of components ≈ total_earnings (within 0.01)

### Performance Summary Should Have

- [ ] `distance_covered`: float >= 0
- [ ] `total_orders`: int >= 0
- [ ] `orders_completed`: int >= 0
- [ ] `orders_cancelled`: int >= 0
- [ ] `login_hours`: string in format HH:MM:SS
- [ ] orders_completed + orders_cancelled <= total_orders

### Earnings Breakdown Should Have

- [ ] 4 items: Order earnings, Multi order earnings, Incentives, Customer tips
- [ ] Each item has: name, description, amount, percentage, icon
- [ ] All percentages >= 0
- [ ] Sum of percentages = 100 (or 0 if no earnings)
- [ ] Icons are valid: package, boxes, gift, star

### Available Dates Should Have

- [ ] `type`: "daily", "weekly", or "monthly"
- [ ] `dates`: array (for daily)
- [ ] `weeks`: array (for weekly)
- [ ] `months`: array (for monthly)
- [ ] Arrays have at least 1 item (if data exists)

---

## Common Issues & Solutions

### Issue: Empty daily_breakdown

**Problem**: Weekly view returns empty `daily_breakdown`

**Cause**: No data in `DeliveryBoyDailyTracking` for that week

**Solution**: Check that test data exists in the database:
```sql
SELECT * FROM delivery_boy_daily_tracking
WHERE delivery_boy_id = ?
AND tracking_date BETWEEN '2026-01-05' AND '2026-01-11';
```

---

### Issue: Date Range Shows No Data

**Problem**: Monthly range returns empty `monthly_breakdown`

**Cause**: No data for the requested months

**Solution**: Use dates where data actually exists. Check available_dates first.

---

### Issue: Login Hours Show 00:00:00

**Problem**: `login_hours` always shows "00:00:00"

**Cause**: Likely `login_hours` field in tracking is NULL or 0

**Solution**: Ensure `DeliveryBoyDailyTracking.login_hours` is properly set when creating tracking records.

---

### Issue: Earnings Percentages Don't Sum to 100

**Problem**: Percentages add up to 95%, 105%, etc.

**Cause**: Rounding differences (each percentage is rounded to 2 decimal places)

**Solution**: This is expected for multi-item calculations. Check that sum is within ±1%.

---

## Performance Testing

### Load Test: Multiple Users

```bash
# Test with 5 concurrent requests
for i in {1..5}; do
  curl -X GET "{BASE_URL}/delivery-boy/performance/earnings?period=monthly&from_date=2025-11-01&to_date=2026-01-31" \
    -H "Authorization: Bearer {TOKEN}" &
done
wait
```

**Expected**: All requests complete within 2 seconds

---

### Database Query Check

Enable query logging and check:
```bash
tail -f storage/logs/laravel.log | grep -i "delivery_boy_daily_tracking"
```

**Expected**: 2-3 queries per request (tracking, orders, optional breakdown)

---

## Frontend Integration Tips

### 1. Daily Dashboard
```javascript
// Fetch today's earnings
const response = await fetch('/api/delivery-boy/performance/earnings?period=daily');
const data = response.data;

// Display total earnings and breakdown chart
displayEarningsCard(data.earnings_overview.total_earnings);
displayBreakdownChart(data.earnings_breakdown);
```

### 2. Weekly Report
```javascript
// Fetch specific week
const response = await fetch(
  `/api/delivery-boy/performance/earnings?period=weekly&date=${selectedDate}`
);

// Use daily_breakdown for line chart
drawChart(response.data.daily_breakdown);
```

### 3. Monthly Report with Range
```javascript
// Fetch 3 months
const response = await fetch(
  `/api/delivery-boy/performance/earnings?period=monthly&from_date=2025-11-01&to_date=2026-01-31`
);

// Use monthly_breakdown for comparison
drawMonthlyComparison(response.data.monthly_breakdown);
```

---

## Success Criteria

✅ All test cases pass
✅ Data is consistent across periods
✅ No missing or null fields
✅ Error handling works correctly
✅ Response time < 2 seconds
✅ Available dates show correct options

