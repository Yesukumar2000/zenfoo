# Delivery Tips API - Quick Reference

## Three Endpoints Overview

### 1. **Weekly Tips** - Most Used for Dashboard
```
GET /api/delivery-boy/tips/weekly?offset=0
```
- Shows all tips for a complete week
- Perfect for dashboard weekly view
- Supports week navigation with offset (-1, 0, 1)
- Includes daily breakdown and statistics
- **Response includes:** week summary, tips list, navigation

### 2. **Daily Tips** - For Specific Day Analysis
```
GET /api/delivery-boy/tips/daily?date=2026-01-09
```
- Shows all tips for a single day
- Includes hourly breakdown
- Perfect for detailed daily analysis
- **Response includes:** day summary with hourly breakdown, tips list

### 3. **Range Tips** - For Custom Period Analysis
```
GET /api/delivery-boy/tips/range?from_date=2026-01-01&to_date=2026-01-31
```
- Shows all tips for any custom date range
- Includes daily breakdown within range
- Perfect for monthly or period analysis
- **Response includes:** range summary, daily breakdown, tips list

---

## Example API Calls

### Current Week Tips
```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/weekly' \
  -H 'Authorization: Bearer TOKEN'
```

### Previous Week Tips
```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/weekly?offset=-1' \
  -H 'Authorization: Bearer TOKEN'
```

### Specific Day Tips
```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/daily?date=2026-01-09' \
  -H 'Authorization: Bearer TOKEN'
```

### Monthly Tips
```bash
curl -X GET 'http://localhost:8000/api/delivery-boy/tips/range?from_date=2026-01-01&to_date=2026-01-31' \
  -H 'Authorization: Bearer TOKEN'
```

---

## Response Data Structure

Every endpoint returns:

```json
{
  "status": true/false,
  "message": "description",
  "data": {
    "delivery_boy": {
      "id": 5,
      "name": "Ravi Kumar",
      "phone": "9876543210",
      "current_balance": 5500.00
    },
    "[week/day/range]_summary": {
      // Statistics and breakdown
    },
    "tips_list": [
      {
        "order_id": 1001,
        "tip_amount": 150.00,
        "customer_name": "Amit Singh",
        "restaurant_name": "Pizza Palace",
        "order_time": "14:30:45",
        "delivery_time": "14:55:30",
        "delivery_distance_km": 2.5,
        // ... more fields
      }
    ],
    "navigation": {} // Only in weekly endpoint
  }
}
```

---

## Key Statistics Provided

### For All Endpoints:
- ✅ `total_tips` - Sum of all tips
- ✅ `total_orders_with_tips` - Count of tipped orders
- ✅ `average_tip_per_order` - Mean tip amount
- ✅ `max_tip` - Highest single tip
- ✅ `min_tip` - Lowest single tip

### Weekly Endpoint:
- `days_with_tips` - Breakdown by each day of week

### Daily Endpoint:
- `hourly_breakdown` - Breakdown by each hour of day

### Range Endpoint:
- `daily_breakdown` - Breakdown by each day in range
- `days_count` - Total days in range

---

## Key Order Details in Tips List

Each tip entry includes:

**Tip Information:**
- `tip_amount` - Amount tipped
- `order_amount` - Total order value
- `delivery_charge` - Delivery fee

**Customer Information:**
- `customer_name` - Customer's name
- `customer_phone` - Customer's phone
- `payment_method` - How customer paid (cash/online)

**Restaurant Information:**
- `restaurant_name` - Seller/restaurant name
- `restaurant_address` - Seller location

**Delivery Information:**
- `delivery_address` - Where food was delivered
- `delivery_distance_km` - Distance traveled
- `order_time` - When order was placed
- `delivery_time` - When order was delivered
- `order_items_count` - Number of items

**Timestamps:**
- `order_date` - Date only (YYYY-MM-DD)
- `created_at` - Full ISO 8601 timestamp
- `updated_at` - Last update timestamp

---

## Frontend Integration Examples

### React Example
```javascript
// Fetch weekly tips
const [weeklyTips, setWeeklyTips] = useState(null);

useEffect(() => {
  fetchWeeklyTips();
}, []);

const fetchWeeklyTips = async (offset = 0) => {
  const response = await fetch(
    `/api/delivery-boy/tips/weekly?offset=${offset}`,
    {
      headers: { 'Authorization': `Bearer ${authToken}` }
    }
  );
  const data = await response.json();
  setWeeklyTips(data.data);
};

// Display summary
<div>
  <h2>Week: {weeklyTips.week_summary.week_range}</h2>
  <p>Total Tips: ₹{weeklyTips.week_summary.total_tips}</p>
  <p>Average: ₹{weeklyTips.week_summary.average_tip_per_order}</p>
</div>

// Display tips list
{weeklyTips.tips_list.map(tip => (
  <div key={tip.order_id}>
    <p>{tip.restaurant_name} - ₹{tip.tip_amount}</p>
    <p>{tip.customer_name} @ {tip.order_time}</p>
  </div>
))}
```

### Vue Example
```javascript
export default {
  data() {
    return {
      weeklyTips: null,
      offset: 0
    }
  },
  methods: {
    async fetchWeeklyTips() {
      const response = await fetch(
        `/api/delivery-boy/tips/weekly?offset=${this.offset}`,
        {
          headers: { 'Authorization': `Bearer ${this.authToken}` }
        }
      );
      this.weeklyTips = (await response.json()).data;
    },
    previousWeek() {
      this.offset = -1;
      this.fetchWeeklyTips();
    },
    nextWeek() {
      this.offset = 1;
      this.fetchWeeklyTips();
    }
  }
}
```

---

## Summary Statistics Display

### Weekly Summary Example
```
Week: Jan 05 - Jan 11, 2026
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Tips:        ₹1250.50
Orders with Tips:  15
Average Tip:       ₹83.37
Max Tip:           ₹150.00
Min Tip:           ₹25.00
Total Delivered:   45 orders
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Daily Breakdown:
Mon: ₹150.00 | Tue: ₹200.00 | Wed: ₹180.50
Thu: ₹220.00 | Fri: ₹250.00 | Sat: ₹150.00 | Sun: ₹100.00
```

### Daily Summary Example
```
Thursday, January 09, 2026
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Tips:        ₹225.00
Orders with Tips:  5
Average Tip:       ₹45.00
Total Delivered:   12 orders
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hourly Breakdown:
11:00 - ₹60.00
12:00 - ₹85.00
14:00 - ₹150.00
19:00 - ₹75.00
```

---

## Filtering & Pagination Notes

- API returns all tips for selected period (no pagination built-in)
- For large date ranges, consider limiting to 30-90 days
- Use weekly endpoint for dashboard (data size ~ 15-30 orders)
- Daily endpoint ideal for detailed analysis

---

## Files Created

1. **Controller:** `app/Http/Controllers/API/DeliveryBoy/DeliveryTipsController.php`
   - Location: Handles all tip-related requests
   - Methods: getWeeklyTips(), getDailyTips(), getRangeTips()
   - Private helpers: extractTipFromOrder(), extractDeliveryCharge(), etc.

2. **Routes:** Updated in `routes/api.php`
   - Added three new authenticated routes
   - All under `/api/delivery-boy/tips/` prefix

3. **Documentation:** `DELIVERY_TIPS_API.md`
   - Complete API documentation
   - Response examples
   - Error handling guide
   - Integration examples

---

## Important Notes

### Tip Extraction
- Tips are extracted from `orders.cart_metadata` JSON field
- Primary path: `cart_metadata['cart_info']['delivery_tip']`
- Fallback: `cart_metadata['delivery_tip']`
- Only delivered orders are included

### Delivery Charge Extraction
- Primary: `cart_metadata['cart_info']['delivery_charge']`
- Secondary: `cart_metadata['billing_breakdown'][2]['amount']`
- Used for reference in response

### Filtering
- Only shows "delivered" order status
- Only includes orders with tip_amount > 0
- Date filtering uses `created_at` field

### Authentication
- All endpoints require `auth:api` middleware
- Must include Authorization header with Bearer token

---

## Testing the API

### Using Postman
1. Create new GET request
2. URL: `http://localhost:8000/api/delivery-boy/tips/weekly`
3. Headers: `Authorization: Bearer YOUR_TOKEN`
4. Click Send

### Using API Client
```bash
# Get current week tips
API_TOKEN="your_token_here"

curl -X GET 'http://localhost:8000/api/delivery-boy/tips/weekly' \
  -H "Authorization: Bearer $API_TOKEN" \
  -H 'Accept: application/json'
```

---

## Common Issues & Solutions

**Issue:** 401 Unauthorized
- **Solution:** Make sure auth token is valid and included in header

**Issue:** Empty tips_list
- **Solution:** Check if delivery boy has delivered orders with tips in selected period

**Issue:** Wrong date in response
- **Solution:** Verify date parameter is in YYYY-MM-DD format

**Issue:** date_range parameter error
- **Solution:** Ensure both from_date and to_date are provided and from_date ≤ to_date

---

**Version:** 1.0.0
**Created:** 2026-01-10
**Last Updated:** 2026-01-10
