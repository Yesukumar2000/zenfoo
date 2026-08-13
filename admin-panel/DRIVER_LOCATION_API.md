# Driver Location History API Documentation

## Overview

The Driver Location History API provides delivery boys with access to their location tracking history for completed orders. This API returns the complete GPS tracking data collected during order delivery, including delivery address coordinates and route statistics.

**Base URL**: `/api/delivery-boy/location`

**Authentication**: Required (Bearer Token via API)

---

## Endpoints

### 1. Get Order Location History

Retrieve complete location tracking history for a delivered order.

**Endpoint**: `GET /api/delivery-boy/location/order-history`

**Authentication**: Required (Bearer Token)

#### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `order_id` | Integer | Yes | The ID of the order to fetch location history for |

#### Query Examples

```
GET /api/delivery-boy/location/order-history?order_id=12345
```

#### Response Success (200 OK)

```json
{
  "status": true,
  "message": "Driver location history retrieved successfully",
  "data": {
    "order": {
      "id": 12345,
      "order_number": "ORD-12345",
      "status": 6,
      "created_at": "2026-01-12T08:30:00Z",
      "updated_at": "2026-01-12T09:15:00Z"
    },
    "delivery_boy": {
      "id": 5,
      "name": "John Doe",
      "phone": "9876543210",
      "current_location": {
        "latitude": 28.6139,
        "longitude": 77.2090
      }
    },
    "delivery_address": {
      "address": "123 Main Street, Delhi",
      "latitude": 28.6240,
      "longitude": 77.2150,
      "area": "Connaught Place",
      "zip_code": "110001"
    },
    "location_history": [
      {
        "latitude": 28.6100,
        "longitude": 77.2050,
        "distance_from_last_km": 0,
        "tracked_at": "2026-01-12",
        "tracked_time": "08:35:00",
        "timestamp": "2026-01-12T08:35:00Z"
      },
      {
        "latitude": 28.6150,
        "longitude": 77.2080,
        "distance_from_last_km": 0.78,
        "tracked_at": "2026-01-12",
        "tracked_time": "08:40:00",
        "timestamp": "2026-01-12T08:40:00Z"
      },
      {
        "latitude": 28.6200,
        "longitude": 77.2120,
        "distance_from_last_km": 0.65,
        "tracked_at": "2026-01-12",
        "tracked_time": "08:45:00",
        "timestamp": "2026-01-12T08:45:00Z"
      },
      {
        "latitude": 28.6240,
        "longitude": 77.2150,
        "distance_from_last_km": 0.58,
        "tracked_at": "2026-01-12",
        "tracked_time": "08:50:00",
        "timestamp": "2026-01-12T08:50:00Z"
      }
    ],
    "route_statistics": {
      "total_distance_km": 2.01,
      "total_locations_tracked": 4,
      "tracking_duration_minutes": 15,
      "average_time_between_points_minutes": 5
    }
  }
}
```

#### Response Errors

**400 Bad Request** - Missing required parameter:
```json
{
  "status": false,
  "message": "order_id is required"
}
```

**401 Unauthorized** - Missing or invalid authentication:
```json
{
  "status": false,
  "message": "Unauthorized"
}
```

**404 Not Found** - Order doesn't exist:
```json
{
  "status": false,
  "message": "Order not found"
}
```

**422 Unprocessable Entity** - Order not delivered:
```json
{
  "status": false,
  "message": "Order is not yet delivered. Tracking available only for delivered orders."
}
```

**500 Internal Server Error** - Server error:
```json
{
  "status": false,
  "message": "Error fetching location history: {error details}"
}
```

---

## Response Fields

### Order Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Unique order identifier |
| `order_number` | String | Order number/reference |
| `status` | Integer | Order status (5 = picked/delivered, 6 = cash collected) |
| `created_at` | ISO 8601 | Order creation timestamp |
| `updated_at` | ISO 8601 | Last order update timestamp |

### Delivery Boy Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Delivery boy unique ID |
| `name` | String | Full name of delivery boy |
| `phone` | String | Phone number |
| `current_location` | Object | Current GPS coordinates |
| `current_location.latitude` | Float | Latitude of current position |
| `current_location.longitude` | Float | Longitude of current position |

### Delivery Address Object

| Field | Type | Description |
|-------|------|-------------|
| `address` | String | Full delivery address |
| `latitude` | Float | Latitude of delivery location (nullable) |
| `longitude` | Float | Longitude of delivery location (nullable) |
| `area` | String | Area/locality name |
| `zip_code` | String | Postal code |

### Location History Array

Each location object in the array contains:

| Field | Type | Description |
|-------|------|-------------|
| `latitude` | Float | GPS latitude coordinate |
| `longitude` | Float | GPS longitude coordinate |
| `distance_from_last_km` | Float | Distance traveled from previous location (in km) |
| `tracked_at` | Date | Date of tracking (YYYY-MM-DD format) |
| `tracked_time` | String | Time of tracking (HH:mm:ss format) |
| `timestamp` | ISO 8601 | Full timestamp of location record |

### Route Statistics Object

| Field | Type | Description |
|-------|------|-------------|
| `total_distance_km` | Float | Total distance traveled during delivery (in km) |
| `total_locations_tracked` | Integer | Number of location points recorded |
| `tracking_duration_minutes` | Integer | Total duration of tracking (in minutes) |
| `average_time_between_points_minutes` | Float | Average time interval between location records |

---

## Features

### 1. Comprehensive Route Tracking
- Complete GPS coordinates for every tracked location point
- Distance calculation between consecutive points
- Precise timestamps for each location record

### 2. Delivery Address Integration
- Delivery address details with coordinates
- Comparison point for verifying delivery at correct location
- Area and zip code information

### 3. Route Statistics
- Total distance traveled
- Number of location points tracked
- Tracking duration
- Average time between location updates

### 4. Data Validation
- Ensures order exists
- Verifies order has been delivered (active_status 5 or 6)
- Confirms delivery boy exists
- Validates authentication

---

## Usage Examples

### cURL Request

```bash
curl -X GET "https://example.com/api/delivery-boy/location/order-history?order_id=12345" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Accept: application/json"
```

### JavaScript/Fetch

```javascript
const orderId = 12345;
const token = 'YOUR_API_TOKEN';

fetch(`/api/delivery-boy/location/order-history?order_id=${orderId}`, {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/json'
  }
})
.then(response => response.json())
.then(data => {
  if (data.status) {
    console.log('Location history:', data.data.location_history);
    console.log('Route stats:', data.data.route_statistics);
  } else {
    console.error('Error:', data.message);
  }
})
.catch(error => console.error('Request error:', error));
```

### PHP Example

```php
<?php
$orderId = 12345;
$token = 'YOUR_API_TOKEN';

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "https://example.com/api/delivery-boy/location/order-history?order_id=" . $orderId);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token,
    'Accept: application/json'
]);

$response = curl_exec($ch);
curl_close($ch);

$data = json_decode($response, true);

if ($data['status']) {
    $locationHistory = $data['data']['location_history'];
    $routeStats = $data['data']['route_statistics'];

    echo "Total Distance: " . $routeStats['total_distance_km'] . " km\n";
    echo "Locations Tracked: " . $routeStats['total_locations_tracked'] . "\n";
} else {
    echo "Error: " . $data['message'];
}
?>
```

### Python Example

```python
import requests
import json

order_id = 12345
token = 'YOUR_API_TOKEN'

headers = {
    'Authorization': f'Bearer {token}',
    'Accept': 'application/json'
}

params = {
    'order_id': order_id
}

response = requests.get(
    'https://example.com/api/delivery-boy/location/order-history',
    headers=headers,
    params=params
)

if response.status_code == 200:
    data = response.json()
    if data['status']:
        location_history = data['data']['location_history']
        route_stats = data['data']['route_statistics']

        print(f"Total Distance: {route_stats['total_distance_km']} km")
        print(f"Locations Tracked: {route_stats['total_locations_tracked']}")
        print(f"Duration: {route_stats['tracking_duration_minutes']} minutes")

        for loc in location_history:
            print(f"Location: ({loc['latitude']}, {loc['longitude']}) at {loc['tracked_time']}")
    else:
        print(f"Error: {data['message']}")
else:
    print(f"HTTP Error: {response.status_code}")
```

---

## Business Logic

### Order Status Validation
- Only accepts orders with `active_status` of 5 (picked/delivered) or 6 (cash collected)
- Prevents location history retrieval for orders still in transit or not yet delivered
- Returns 422 error for incomplete orders

### Location History Retrieval
- Fetches all location points tracked during order delivery period
- Includes 2-hour buffer before order creation to capture pickup journey
- Orders locations chronologically from earliest to latest
- Handles cases where no location data exists (empty array returned)

### Route Statistics Calculation
- Sums all `distance_from_last_km` values for total distance
- Counts total location points tracked
- Calculates duration from first to last location record
- Computes average time between location points (for tracking frequency analysis)

### Error Handling
- Validates all required parameters before processing
- Returns appropriate HTTP status codes
- Logs all errors for debugging
- Provides clear error messages to client

---

## Integration Points

### Related Models
- `Order` - Order information and delivery details
- `DeliveryBoy` - Driver information
- `DeliveryBoyLocationHistory` - GPS location records
- `DeliveryBoySession` - Driver session information

### Database Tables
- `orders` - Order data with delivery boy ID
- `delivery_boys` - Driver information with current coordinates
- `delivery_boy_location_history` - GPS tracking records

### Related APIs
- [Multi-Order Earnings API](/MULTI_ORDER_EARNINGS_API.md)
- [Delivery Tips API](/DELIVERY_TIPS_API.md)
- Performance API

---

## Best Practices

1. **Always validate order_id parameter** before making API calls
2. **Check status in response** to ensure successful data retrieval
3. **Use timestamps** for accurate sorting and filtering
4. **Cache location history** to reduce API calls for frequently accessed data
5. **Handle empty location arrays** gracefully (may occur if tracking not enabled)
6. **Respect authentication tokens** and keep them secure
7. **Log API errors** for debugging and monitoring
8. **Use route statistics** for performance analysis and metrics

---

## API Rate Limiting

Currently, no rate limiting is enforced. Implementers should implement their own rate limiting based on usage patterns.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-12 | Initial release |

---

## Support

For issues or questions regarding this API, please contact the development team.
