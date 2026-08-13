# Seller Banners API Documentation

## Endpoint
```
GET /api/seller/banners
```

## Authentication
Required: Yes (Bearer Token via `auth:api` middleware)

## Description
Returns banners/sliders for the authenticated seller based on their store configuration. The banners returned depend on whether the seller's store is managed by admin or not.

## Business Logic

### Managed by Admin Stores (`managed_by_admin = 1`)
- Returns **global banners** where `store_id` is `NULL`
- These are general/platform-wide banners shown to all admin-managed stores

### Non-Admin Managed Stores (`managed_by_admin = 0`)
- Returns **store-specific banners** where `store_id` matches the seller's store
- Each store can have its own custom banners

## Response Structure

### Success Response
```json
{
  "status": 1,
  "message": "Banners fetched successfully",
  "data": {
    "store_info": {
      "id": 15,
      "name": "Sweet Shop",
      "managed_by_admin": true
    },
    "banners": [
      {
        "id": 1,
        "type": "category",
        "type_id": 5,
        "type_name": "Sweets",
        "image": "sliders/abc123.jpg",
        "image_url": "https://domain.com/storage/sliders/abc123.jpg",
        "offer_url": null,
        "store_id": null,
        "created_at": "2024-12-01T10:00:00.000000Z",
        "updated_at": "2024-12-01T10:00:00.000000Z"
      },
      {
        "id": 2,
        "type": "product",
        "type_id": 123,
        "type_name": "Gulab Jamun",
        "image": "sliders/def456.jpg",
        "image_url": "https://domain.com/storage/sliders/def456.jpg",
        "offer_url": null,
        "store_id": null,
        "created_at": "2024-12-02T10:00:00.000000Z",
        "updated_at": "2024-12-02T10:00:00.000000Z"
      },
      {
        "id": 3,
        "type": "offer_url",
        "type_id": null,
        "type_name": "https://example.com/special-offer",
        "image": "sliders/ghi789.jpg",
        "image_url": "https://domain.com/storage/sliders/ghi789.jpg",
        "offer_url": "https://example.com/special-offer",
        "store_id": null,
        "created_at": "2024-12-03T10:00:00.000000Z",
        "updated_at": "2024-12-03T10:00:00.000000Z"
      }
    ]
  }
}
```

## Banner Types

Banners can have one of three types:

### 1. Category Banner (`type: "category"`)
- `type_id`: Category ID
- `type_name`: Category name
- When tapped, should navigate to the category page

### 2. Product Banner (`type: "product"`)
- `type_id`: Product ID
- `type_name`: Product name
- When tapped, should navigate to the product detail page

### 3. Offer URL Banner (`type: "offer_url"`)
- `type_id`: null
- `type_name`: The URL string
- `offer_url`: The URL string
- When tapped, should open the URL (in-app browser or external)

## Usage Example

### Request
```bash
curl -X GET "https://your-domain.com/api/seller/banners" \
  -H "Authorization: Bearer YOUR_SELLER_TOKEN_HERE"
```

### Response (Admin-Managed Store)
```json
{
  "status": 1,
  "message": "Banners fetched successfully",
  "data": {
    "store_info": {
      "id": 15,
      "name": "Sweet Shop",
      "managed_by_admin": true
    },
    "banners": [
      // Global banners where store_id = null
    ]
  }
}
```

### Response (Non-Admin Store)
```json
{
  "status": 1,
  "message": "Banners fetched successfully",
  "data": {
    "store_info": {
      "id": 8,
      "name": "My Custom Store",
      "managed_by_admin": false
    },
    "banners": [
      // Store-specific banners where store_id = 8
    ]
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

### Store Not Found
```json
{
  "status": 0,
  "message": "Store not found for this seller."
}
```

## Notes

- All banners include the `image_url` accessor which provides the full URL to the banner image
- The `type_name` accessor automatically resolves the category/product name or offer URL based on the banner type
- Banners are returned in the order they were created (can be modified in admin panel)
- Empty array is returned if no banners are configured for the store type
- The `managed_by_admin` flag in the response helps the frontend understand which banner set is being displayed
