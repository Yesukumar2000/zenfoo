# Seller Store Categories API Documentation

## Endpoint
```
GET /api/seller/store-categories
```

## Authentication
Required: Yes (Bearer Token via `auth:api` middleware)

## Description
Returns the seller's store information along with category groups, subcategory groups, and their categories. This endpoint is particularly useful for sellers whose stores are managed by admin, as they need to see the hierarchical category structure defined at the store level.

## Business Logic

### Managed by Admin Stores (`managed_by_admin = 1`)
- Returns **complete store information**
- Returns **all category groups** associated with the store
- Each category group includes its **subcategory groups**
- Each subcategory group includes its **list of categories** (from `subcategory_ids` field)
- This allows admin-managed sellers to browse and select from store-defined category structures

### Non-Admin Managed Stores (`managed_by_admin = 0`)
- Returns **store information**
- Returns **empty category groups array** (these sellers manage their own categories independently)

## Response Structure

### Success Response (Admin-Managed Store)
```json
{
  "status": 1,
  "message": "Store data fetched successfully",
  "data": {
    "store": {
      "id": 15,
      "name": "Sweet Shop",
      "description": "Traditional Indian sweets and desserts",
      "icon_url": "https://domain.com/storage/stores/icons/sweet-shop.png",
      "image_url": "https://domain.com/storage/stores/sweet-shop.jpg",
      "vendor_img_url": "https://domain.com/storage/stores/vendor/sweet-shop-vendor.jpg",
      "managed_by_admin": true,
      "is_super_mart": false,
      "is_active": true
    },
    "category_groups": [
      {
        "id": 1,
        "name": "Traditional Sweets",
        "image_url": "https://domain.com/storage/category-groups/traditional.jpg",
        "status": 1,
        "sub_category_groups": [
          {
            "id": 101,
            "name": "Milk Based Sweets",
            "image_url": "https://domain.com/storage/sub-category-groups/milk-based.jpg",
            "categories": [
              {
                "id": 10,
                "name": "Gulab Jamun",
                "image_url": "https://domain.com/storage/categories/gulab-jamun.jpg",
                "parent_id": null
              },
              {
                "id": 11,
                "name": "Rasgulla",
                "image_url": "https://domain.com/storage/categories/rasgulla.jpg",
                "parent_id": null
              }
            ]
          },
          {
            "id": 102,
            "name": "Syrup Based Sweets",
            "image_url": "https://domain.com/storage/sub-category-groups/syrup-based.jpg",
            "categories": [
              {
                "id": 12,
                "name": "Jalebi",
                "image_url": "https://domain.com/storage/categories/jalebi.jpg",
                "parent_id": null
              },
              {
                "id": 13,
                "name": "Imarti",
                "image_url": "https://domain.com/storage/categories/imarti.jpg",
                "parent_id": null
              }
            ]
          }
        ]
      },
      {
        "id": 2,
        "name": "Dry Fruits",
        "image_url": "https://domain.com/storage/category-groups/dry-fruits.jpg",
        "status": 1,
        "sub_category_groups": [
          {
            "id": 201,
            "name": "Premium Dry Fruits",
            "image_url": "https://domain.com/storage/sub-category-groups/premium.jpg",
            "categories": [
              {
                "id": 20,
                "name": "Cashews",
                "image_url": "https://domain.com/storage/categories/cashews.jpg",
                "parent_id": null
              },
              {
                "id": 21,
                "name": "Almonds",
                "image_url": "https://domain.com/storage/categories/almonds.jpg",
                "parent_id": null
              }
            ]
          }
        ]
      },
      {
        "id": 3,
        "name": "Namkeen",
        "image_url": "https://domain.com/storage/category-groups/namkeen.jpg",
        "status": 1,
        "sub_category_groups": [
          {
            "id": 301,
            "name": "Spicy Namkeen",
            "image_url": "https://domain.com/storage/sub-category-groups/spicy.jpg",
            "categories": [
              {
                "id": 30,
                "name": "Mixture",
                "image_url": "https://domain.com/storage/categories/mixture.jpg",
                "parent_id": null
              },
              {
                "id": 31,
                "name": "Bhujia",
                "image_url": "https://domain.com/storage/categories/bhujia.jpg",
                "parent_id": null
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### Success Response (Non-Admin Store)
```json
{
  "status": 1,
  "message": "Store data fetched successfully",
  "data": {
    "store": {
      "id": 8,
      "name": "My Custom Store",
      "description": "Independent grocery store",
      "icon_url": "https://domain.com/storage/stores/icons/custom.png",
      "image_url": "https://domain.com/storage/stores/custom.jpg",
      "vendor_img_url": "https://domain.com/storage/stores/vendor/custom-vendor.jpg",
      "managed_by_admin": false,
      "is_super_mart": false,
      "is_active": true
    },
    "category_groups": []
  }
}
```

## Store Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Store ID |
| `name` | string | Store name |
| `description` | string/null | Store description |
| `icon_url` | string | Full URL to store icon |
| `image_url` | string | Full URL to store image |
| `vendor_img_url` | string | Full URL to vendor image |
| `managed_by_admin` | boolean | Whether store is managed by admin |
| `is_super_mart` | boolean | Whether store is a super mart |
| `is_active` | boolean | Whether store is active |

## Category Group Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Category group ID |
| `name` | string | Category group name |
| `image_url` | string/null | Full URL to category group image |
| `status` | integer | Status (1 = active, 0 = inactive) |
| `sub_category_groups` | array | Array of subcategory group objects |

## Subcategory Group Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Subcategory group ID |
| `name` | string | Subcategory group name |
| `image_url` | string/null | Full URL to subcategory group image |
| `categories` | array | Array of category objects (from `subcategory_ids` field) |

## Category Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Category ID |
| `name` | string | Category name |
| `image_url` | string/null | Full URL to category image |
| `parent_id` | integer/null | Parent category ID (for subcategories) |

## Usage Example

### Request
```bash
curl -X GET "https://your-domain.com/api/seller/store-categories" \
  -H "Authorization: Bearer YOUR_SELLER_TOKEN_HERE"
```

### Use Cases

1. **Display Category Structure**: Use this API to show sellers the three-level category hierarchy (Category Group → Subcategory Group → Categories)
2. **Product Creation**: When creating products, sellers from admin-managed stores can navigate through the hierarchy to select appropriate categories
3. **Navigation**: Build a nested category navigation menu for the seller dashboard
4. **Category Filtering**: Allow sellers to filter their products by category groups, subcategory groups, or individual categories

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

- **Admin-Managed Stores**: Category hierarchy is defined at the store level and shared across all sellers in that store
- **Non-Admin Stores**: Sellers manage their own categories independently, so category groups array will be empty
- **Three-Level Hierarchy**:
  1. **Category Groups** - Top level (e.g., "Traditional Sweets", "Dry Fruits")
  2. **Subcategory Groups** - Middle level (e.g., "Milk Based Sweets", "Premium Dry Fruits")
  3. **Categories** - Bottom level (e.g., "Gulab Jamun", "Cashews")
- All image URLs use the accessor methods from the models, providing full absolute URLs
- Categories are fetched from the `subcategory_ids` field in the `sub_category_groups` table
- The `status` field in category groups indicates if the group is active (1) or inactive (0)
- Subcategories can be identified by checking the `parent_id` field (non-null values indicate a subcategory)

## Related Endpoints

- `GET /api/seller/statistics` - Get seller dashboard statistics
- `GET /api/seller/banners` - Get banners for the seller's store
- `GET /api/seller/earnings` - Get earnings data for the seller

## Frontend Implementation Example

```javascript
// Fetch store categories
async function fetchStoreCategories() {
  const response = await fetch('https://your-domain.com/api/seller/store-categories', {
    headers: {
      'Authorization': `Bearer ${sellerToken}`
    }
  });

  const result = await response.json();

  if (result.status === 1) {
    const { store, category_groups } = result.data;

    // Check if store is managed by admin
    if (store.managed_by_admin) {
      // Display three-level category hierarchy
      category_groups.forEach(group => {
        console.log(`Category Group: ${group.name}`);

        group.sub_category_groups.forEach(subGroup => {
          console.log(`  Subcategory Group: ${subGroup.name}`);

          subGroup.categories.forEach(category => {
            console.log(`    - ${category.name}`);
          });
        });
      });
    } else {
      // Handle non-admin managed store
      console.log('This is a non-admin managed store');
    }
  }
}
```
