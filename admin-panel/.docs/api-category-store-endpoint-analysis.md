# Category Store API Endpoint Analysis

## API Endpoint
```
GET {{dev_url}}/customer/cat_store/{id}?lat={latitude}&lon={longitude}&sort_by={sort_option}&food_type={food_filter}&category_id={category_id}
```

## Overview
This endpoint retrieves store data with sellers, categories, and sliders. It's designed to handle different store types:
- **Admin-managed stores**: Stores with `managed_by_admin = 1`
- **Super Mart stores**: Stores with `is_super_mart = 1`
- **Sweet House stores**: Individual seller stores (non-admin, non-super mart)

## Request Parameters

### Path Parameters
- `id` (optional): Store ID. If provided, returns data for that specific store. If null, returns all active stores.

### Query Parameters
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `lat` | float | **Yes** | - | User's latitude |
| `lon` | float | **Yes** | - | User's longitude |
| `sort_by` | string | No | `distance` | Sort option for sellers |
| `food_type` | string | No | `all` | Food type filter |
| `category_id` | integer | No | `null` | Category filter (sweet houses only) |
| `seller_per_page` | integer | No | `10` | Sellers per page |
| `seller_page` | integer | No | `1` | Current page number |

### Sort Options (`sort_by`)
- `distance` - Distance (Nearest) - **Default**
- `rating` - Rating (Highest)
- `price_low_to_high` - Price (Low to High)
- `price_high_to_low` - Price (High to Low)
- `name` - Name (A-Z)

### Food Type Options (`food_type`)
- `all` - All - **Default**
- `veg` - Veg Only
- `non_veg` - Non-Veg

## Response Structure

### Top Level
```json
{
    "status": 1,
    "message": "success",
    "total": 1,
    "data": [
        {
            // Store object
        }
    ]
}
```

### Store Object
```json
{
    "id": 15,
    "managed_by_admin": false,
    "is_super_mart": false,
    "is_active": true,
    "name": "Food",
    "icon": "https://...",
    "description": "...",
    "image": "https://...",
    "color": "#5d0e0e",
    "created_at": "2025-11-20T06:33:54.000000Z",
    "updated_at": "2026-01-13T05:03:17.000000Z",
    "vendor_img": "https://...",
    
    // Conditional fields based on store type and parameters
    "sliders": [...],
    "categories": [...],  // Only for sweet houses when id is provided
    "selected_category_id": null,  // Only for sweet houses when id is provided
    "sellers_pagination": {...},  // Only when id is provided
    "top_rated_sellers": [...],  // Only when id is provided
    "icon_url": "https://...",
    "image_url": "https://...",
    "vendor_img_url": "https://...",
    "category_groups": []
}
```

## Detailed Field Descriptions

### Sliders Array
**Condition**: Always included
**Logic**:
- If `id` is provided: Returns sliders where `type='store'` AND `type_id=store_id`
- If `id` is null: Returns all sliders where `type='store'`

```json
"sliders": [
    {
        "id": 12,
        "store_id": null,
        "type": "store",
        "type_id": "15",
        "image": "https://...",
        "slider_url": null,
        "status": 1,
        "created_at": "2026-01-23T06:54:38.000000Z",
        "updated_at": "2026-01-23T06:54:38.000000Z",
        "type_name": "",
        "image_url": "https://..."
    }
]
```

### Categories Array
**Condition**: Only for **Sweet House** stores when `id` parameter is provided
**Logic**: 
- Sweet House = `managed_by_admin = 0` AND `is_super_mart = 0`
- Gets all categories from sellers belonging to this store
- Filters by `status = 1`

```json
"categories": [
    {
        "id": 176,
        "name": "Sweet2",
        "seller_id": 35,
        "image": "https://...",
        "image_url": "https://...",
        "has_child": false,
        "has_active_child": false,
        "cat_active_childs": []
    }
]
```

### Selected Category ID
**Condition**: Only for **Sweet House** stores when `id` parameter is provided
**Purpose**: Indicates which category filter is currently applied

```json
"selected_category_id": null  // or integer if category_id parameter was provided
```

### Sellers Pagination Object
**Condition**: Only for **non-admin** stores when `id` parameter is provided
**Features**:
- Pagination support
- Sorting options
- Food type filtering
- Category filtering (for sweet houses)
- Distance calculation
- Bookmark status

```json
"sellers_pagination": {
    "total": 9,
    "per_page": 10,
    "current_page": 1,
    "last_page": 1,
    "sort_by": "price_low_to_high",
    "sort_options": {
        "distance": "Distance (Nearest)",
        "rating": "Rating (Highest)",
        "price_low_to_high": "Price (Low to High)",
        "price_high_to_low": "Price (High to Low)",
        "name": "Name (A-Z)"
    },
    "food_type": "all",
    "food_type_options": {
        "all": "All",
        "veg": "Veg Only",
        "non_veg": "Non-Veg"
    },
    "data": [
        // Array of seller objects
    ]
}
```

### Seller Object (in sellers_pagination.data)
```json
{
    "id": 29,
    "category_name": null,
    "aadhar_number": "363636363636",
    "fssai_number": "5655",
    "store_id": 15,
    "shop_status": 1,
    "admin_id": 27,
    "name": "Ram",
    "store_name": "Darvesh store",
    "slug": "Darvesh store",
    "email": "ram@gmail.com",
    "mobile": "7997748082",
    "balance": 0,
    "store_url": "https://store.com",
    "logo": "sellers/logo_695b846d431c4.jpg",
    "store_description": "Store",
    "store_location": "Madhapur, Hyderabad, 500033, Telangana, India",
    "store_city": "500033",
    "lat_long": "17.438928911415545,78.3983751386404",
    "commission": 20,
    "status": 1,
    
    // Computed fields
    "rating": 4.3,  // Random between 4.0-5.0 (dummy data)
    "rating_count": 497,  // Random between 50-500 (dummy data)
    "distance_km": "33.37 km",
    "travel_time_min": "142.25 min",
    "food_type": "non_veg",  // Computed based on products
    "min_price": 7,  // Minimum product price
    "is_bookmarked": 0,  // 1 if user has bookmarked, 0 otherwise
    
    "store_details": {
        "id": 15,
        "name": "Food",
        "icon": "https://...",
        "color": "#5d0e0e",
        "image": "https://...",
        "description": "...",
        "managed_by_admin": false,
        "is_super_mart": false,
        "is_sweet_house": true
    },
    
    // Other fields...
    "logo_url": "sellers/logo_695b846d431c4.jpg",
    "national_identity_card_url": "sellers/nic_695b8458d8305.jpg",
    "address_proof_url": null,
    "categories_array": "",
    "pickup_store_timings_array": [],
    "store_images_urls": [...]
}
```

### Top Rated Sellers Array
**Condition**: Only when `id` parameter is provided
**Logic**: Top 10 sellers sorted by rating (descending)

```json
"top_rated_sellers": [
    // Same structure as seller objects in sellers_pagination.data
    // Limited to top 10 by rating
]
```

## Business Logic

### 1. Store Type Detection
```php
$isManagedByAdmin = $store->managed_by_admin == 1;
$isSweetHouse = (!$isManagedByAdmin && !$store->is_super_mart);
```

### 2. Category Filtering (Sweet Houses Only)
When `category_id` parameter is provided:
1. Get all seller IDs that have products in the selected category
2. Filter sellers to only include those with the selected category
3. Still show ALL categories in the `categories` array (not filtered)

### 3. Food Type Classification
**Seller is classified as:**
- **Veg**: ALL products have `indicator = 1`
- **Non-Veg**: At least ONE product has `indicator = 2`

**Implementation**: Uses `SellerFilterService::attachFoodTypeToSellers()`

### 4. Price Sorting
**Price Low to High**:
- Gets minimum product price for each seller
- Uses `discounted_price` if available, otherwise `price`
- Sellers without products get `PHP_INT_MAX` (sorted to end)

**Price High to Low**:
- Same logic but descending order
- Sellers without products get `0` (sorted to end)

### 5. Distance Calculation
Uses `StoreDistanceService`:
1. **Haversine formula**: Calculate straight-line distance
2. **Estimate travel time**: Based on distance
3. **Google Maps API** (optional): Get actual distance and time
4. Falls back to Haversine if Google API fails

### 6. Bookmark Status
Checks `bookmarks` table:
- `user_id` = authenticated user ID
- `type` = 'seller'
- `bookmarkable_type` = 'App\Models\Seller'
- `bookmarkable_id` = seller ID

Returns `1` if bookmarked, `0` otherwise

### 7. Dummy Rating Data
```php
$seller->rating = round(mt_rand(40, 50) / 10, 1); // 4.0 - 5.0
$seller->rating_count = mt_rand(50, 500); // 50 - 500
```

## API Flow Diagram

```
Request with lat, lon, id (optional)
    ↓
Validate lat/lon (required)
    ↓
Get authenticated user (optional)
    ↓
Fetch store(s) with relationships
    ↓
For each store:
    ├─ Check store type (admin/supermart/sweet house)
    ├─ Get sliders based on id parameter
    │
    ├─ If NON-ADMIN store:
    │   ├─ Query sellers for this store
    │   ├─ Apply category filter (if category_id provided)
    │   │
    │   ├─ If id provided AND sweet house:
    │   │   ├─ Load all categories for this store
    │   │   └─ Set selected_category_id
    │   │
    │   └─ If id provided:
    │       ├─ Paginate sellers
    │       ├─ Calculate distance & travel time
    │       ├─ Add dummy ratings
    │       ├─ Add store details
    │       ├─ Check bookmark status
    │       ├─ Attach food_type
    │       ├─ Apply food_type filter
    │       ├─ Apply sorting
    │       ├─ Create sellers_pagination object
    │       └─ Create top_rated_sellers (top 10)
    │
    └─ Return store with all computed data
```

## Use Cases

### Use Case 1: Get All Stores (Home Page)
```
GET /customer/cat_store?lat=17.5481&lon=78.6915
```
**Returns**: All active stores with sliders (no sellers, no categories)

### Use Case 2: Get Specific Sweet House Store
```
GET /customer/cat_store/15?lat=17.5481&lon=78.6915
```
**Returns**: 
- Store details
- Sliders for this store
- All categories from sellers in this store
- Paginated sellers with distance, ratings, etc.
- Top 10 rated sellers

### Use Case 3: Filter Sweet House by Category
```
GET /customer/cat_store/15?lat=17.5481&lon=78.6915&category_id=176
```
**Returns**: Same as Use Case 2, but sellers filtered to only those with category 176

### Use Case 4: Sort by Price (Low to High)
```
GET /customer/cat_store/15?lat=17.5481&lon=78.6915&sort_by=price_low_to_high
```
**Returns**: Sellers sorted by minimum product price (ascending)

### Use Case 5: Filter Veg Only
```
GET /customer/cat_store/15?lat=17.5481&lon=78.6915&food_type=veg
```
**Returns**: Only sellers that have ALL veg products

### Use Case 6: Combined Filters
```
GET /customer/cat_store/15?lat=17.5481&lon=78.6915&category_id=176&food_type=veg&sort_by=rating&seller_per_page=20
```
**Returns**: 
- Sellers with category 176
- Only veg sellers
- Sorted by rating (highest first)
- 20 sellers per page

## Important Notes

1. **Authentication**: Optional. If authenticated, bookmark status is included.

2. **Lat/Lon Required**: Always required for distance calculation.

3. **Store Type Matters**: 
   - Admin-managed stores: No sellers returned
   - Super Mart stores: Sellers returned but no categories
   - Sweet House stores: Both sellers and categories returned

4. **Category Filter**: Only works for Sweet House stores

5. **Pagination**: Only applies when `id` parameter is provided

6. **Food Type Logic**: 
   - Determined by products' `indicator` field
   - Veg = ALL products indicator 1
   - Non-Veg = ANY product indicator 2

7. **Distance Calculation**: 
   - Tries Google Maps API first
   - Falls back to Haversine formula
   - Formatted as "XX.XX km" and "XX.XX min"

8. **Price Sorting**: 
   - Based on minimum variant price
   - Uses discounted_price if available
   - Only considers active, approved products

9. **Dummy Data**: 
   - Ratings (4.0-5.0) and rating counts (50-500) are randomly generated
   - Should be replaced with real data from database

10. **Bookmark Status**: 
    - Always included in response
    - 0 if not authenticated or not bookmarked
    - 1 if bookmarked by current user

## Related Services

### SellerFilterService
Located at: `app/Services/SellerFilterService.php`

**Methods**:
- `applySorting()` - Apply sorting to sellers
- `applyFoodTypeFilter()` - Filter by food type
- `attachFoodTypeToSellers()` - Attach food_type to each seller
- `getSortOptions()` - Get available sort options
- `getFoodTypeOptions()` - Get available food type options

### StoreDistanceService
**Methods**:
- `haversine()` - Calculate straight-line distance
- `estimateTravelTimeMinutes()` - Estimate travel time
- `googleMapsDistance()` - Get distance from Google Maps API
- `formatDistance()` - Format distance string
- `formatTime()` - Format time string

## Database Tables Involved

1. **stores** - Store information
2. **sellers** - Seller information
3. **categories** - Product categories
4. **sliders** - Promotional sliders
5. **products** - Product information
6. **product_variants** - Product variants with prices
7. **bookmarks** - User bookmarks
8. **category_groups** - Category groupings
9. **sub_category_groups** - Sub-category groupings

## Performance Considerations

1. **N+1 Query Problem**: Mitigated by using eager loading (`with()`)
2. **Distance Calculation**: Google Maps API calls can be slow
3. **Large Datasets**: Pagination helps with large seller lists
4. **Food Type Calculation**: Requires querying products table
5. **Price Sorting**: Requires joining product_variants table

## Potential Improvements

1. **Cache Distance Calculations**: Store calculated distances temporarily
2. **Real Ratings**: Replace dummy ratings with actual database values
3. **Optimize Food Type Query**: Consider caching or pre-computing
4. **Add Search**: Allow searching sellers by name
5. **Add More Filters**: Price range, delivery time, etc.
6. **Batch Google Maps Requests**: Reduce API calls
7. **Add Response Caching**: Cache responses for common requests
8. **Add Rate Limiting**: Prevent abuse of distance calculations
