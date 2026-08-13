# Seller Products by Category API Documentation

## Endpoint
```
GET /api/seller/products-by-category
```

## Authentication
Required: Yes (Bearer Token via `auth:api` middleware)

## Description
Returns a paginated list of products with all variant details for a specific category. For sellers with admin-managed stores, this API returns all products from all sellers in that store for the given category. For non-admin stores, it returns only the authenticated seller's products.

## Business Logic

### Managed by Admin Stores (`managed_by_admin = 1`)
- Returns **all products from all sellers in the store** for the specified category
- Allows sellers to see the complete product catalog for their category within the store
- Useful for managing inventory across multiple sellers in admin-managed stores

### Non-Admin Managed Stores (`managed_by_admin = 0`)
- Returns **only the seller's own products** for the specified category
- Standard behavior for independent sellers managing their own inventory

## Request Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `category_id` | integer | Yes | - | ID of the category to filter products |
| `per_page` | integer | No | 20 | Number of products per page (1-100) |
| `page` | integer | No | 1 | Page number for pagination |
| `search` | string | No | - | Search query to filter products by name, slug, or description |

## Response Structure

### Success Response
```json
{
  "status": 1,
  "message": "Products fetched successfully",
  "data": {
    "category": {
      "id": 10,
      "name": "Gulab Jamun",
      "image_url": "https://domain.com/storage/categories/gulab-jamun.jpg"
    },
    "store_info": {
      "id": 15,
      "name": "Sweet Shop",
      "managed_by_admin": true
    },
    "products": [
      {
        "id": 101,
        "name": "Premium Gulab Jamun",
        "slug": "premium-gulab-jamun",
        "seller_id": 5,
        "category_id": 10,
        "status": 1,
        "tax_id": 2,
        "image": "products/gulab-jamun-main.jpg",
        "image_url": "https://domain.com/storage/products/gulab-jamun-main.jpg",
        "indicator": "veg",
        "is_approved": 1,
        "manufacturer": "Sweet Delights Pvt Ltd",
        "made_in": "India",
        "type": "packet",
        "description": "Soft and spongy gulab jamuns soaked in sugar syrup",
        "created_at": "2024-12-01T10:00:00.000000Z",
        "variants": [
          {
            "id": 201,
            "product_id": 101,
            "price": 250.00,
            "discounted_price": 225.00,
            "measurement": "500",
            "stock": 50,
            "stock_unit_id": 1,
            "stock_unit_name": "gm",
            "status": 1,
            "serve_for": "regular"
          },
          {
            "id": 202,
            "product_id": 101,
            "price": 450.00,
            "discounted_price": 400.00,
            "measurement": "1",
            "stock": 30,
            "stock_unit_id": 2,
            "stock_unit_name": "kg",
            "status": 1,
            "serve_for": "family"
          }
        ],
        "images": [
          {
            "id": 301,
            "image": "products/gulab-jamun-1.jpg",
            "image_url": "https://domain.com/storage/products/gulab-jamun-1.jpg"
          },
          {
            "id": 302,
            "image": "products/gulab-jamun-2.jpg",
            "image_url": "https://domain.com/storage/products/gulab-jamun-2.jpg"
          }
        ],
        "tax": {
          "id": 2,
          "title": "GST 5%",
          "percentage": 5.0
        }
      },
      {
        "id": 102,
        "name": "Special Gulab Jamun",
        "slug": "special-gulab-jamun",
        "seller_id": 8,
        "category_id": 10,
        "status": 1,
        "tax_id": 2,
        "image": "products/special-gulab-jamun.jpg",
        "image_url": "https://domain.com/storage/products/special-gulab-jamun.jpg",
        "indicator": "veg",
        "is_approved": 1,
        "manufacturer": "Traditional Sweets Co",
        "made_in": "India",
        "type": "packet",
        "description": "Traditional recipe gulab jamuns with authentic taste",
        "created_at": "2024-12-02T14:30:00.000000Z",
        "variants": [
          {
            "id": 203,
            "product_id": 102,
            "price": 300.00,
            "discounted_price": 280.00,
            "measurement": "500",
            "stock": 25,
            "stock_unit_id": 1,
            "stock_unit_name": "gm",
            "status": 1,
            "serve_for": "regular"
          }
        ],
        "images": [],
        "tax": {
          "id": 2,
          "title": "GST 5%",
          "percentage": 5.0
        }
      }
    ],
    "pagination": {
      "total": 15,
      "per_page": 20,
      "current_page": 1,
      "last_page": 1,
      "from": 1,
      "to": 15
    }
  }
}
```

## Product Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Product ID |
| `name` | string | Product name |
| `slug` | string | URL-friendly product identifier |
| `seller_id` | integer | ID of the seller who owns this product |
| `category_id` | integer | Category ID |
| `status` | integer | Product status (1 = active, 0 = inactive) |
| `tax_id` | integer/null | Tax ID associated with product |
| `image` | string | Main product image path |
| `image_url` | string | Full URL to main product image |
| `indicator` | string | Product type indicator (veg, non-veg, etc.) |
| `is_approved` | integer | Approval status (1 = approved, 0 = pending) |
| `manufacturer` | string/null | Manufacturer name |
| `made_in` | string/null | Country of origin |
| `type` | string | Product type (packet, loose) |
| `description` | string | Product description |
| `created_at` | datetime | Product creation timestamp |
| `variants` | array | Array of product variant objects |
| `images` | array | Array of additional product image objects |
| `tax` | object/null | Tax information object |

## Variant Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Variant ID |
| `product_id` | integer | Associated product ID |
| `price` | float | Original price |
| `discounted_price` | float | Discounted/selling price |
| `measurement` | string | Measurement value (e.g., "500", "1") |
| `stock` | integer | Available stock quantity |
| `stock_unit_id` | integer | Stock unit ID (1=gm, 2=kg, etc.) |
| `stock_unit_name` | string/null | Stock unit short code |
| `status` | integer | Variant status (1 = available, 0 = sold out) |
| `serve_for` | string | Serving size (regular, family, etc.) |

## Usage Examples

### Request - Get Products by Category
```bash
curl -X GET "https://your-domain.com/api/seller/products-by-category?category_id=10&per_page=20&page=1" \
  -H "Authorization: Bearer YOUR_SELLER_TOKEN_HERE"
```

### Request - With Search Filter
```bash
curl -X GET "https://your-domain.com/api/seller/products-by-category?category_id=10&search=premium&per_page=10" \
  -H "Authorization: Bearer YOUR_SELLER_TOKEN_HERE"
```

### Use Cases

1. **Category Browsing**: Display all products in a specific category from the seller's dashboard
2. **Inventory Management**: For admin-managed stores, view and manage all products across multiple sellers in a category
3. **Stock Monitoring**: Check variant stock levels for products in a category
4. **Product Search**: Search for specific products within a category
5. **Price Comparison**: Compare prices and variants across different sellers in the same category (admin-managed stores)

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

### Missing Category ID
```json
{
  "status": 0,
  "message": "Category ID is required."
}
```

### Category Not Found
```json
{
  "status": 0,
  "message": "Category not found."
}
```

## Notes

- **Admin-Managed Stores**: Products from all sellers in the store are returned for the specified category
- **Non-Admin Stores**: Only the authenticated seller's products are returned
- **Pagination**: Default is 20 items per page, maximum 100 per page
- **Search**: Searches across product name, slug, and description fields
- **Variants**: All product variants are included with full details including stock and pricing
- **Images**: Main product image plus all additional images are returned with full URLs
- **Tax Information**: Tax details are included if a tax is associated with the product
- **Stock Units**: Stock unit names are fetched from the `units` table based on `stock_unit_id`
- **Ordering**: Products are ordered by ID in descending order (newest first)

## Related Endpoints

- `GET /api/seller/store-categories` - Get store category hierarchy
- `GET /api/seller/statistics` - Get seller dashboard statistics
- `GET /api/seller/banners` - Get banners for the seller's store

## Frontend Implementation Example

```javascript
// Fetch products by category
async function fetchProductsByCategory(categoryId, page = 1, search = '') {
  const params = new URLSearchParams({
    category_id: categoryId,
    per_page: 20,
    page: page
  });

  if (search) {
    params.append('search', search);
  }

  const response = await fetch(`https://your-domain.com/api/seller/products-by-category?${params}`, {
    headers: {
      'Authorization': `Bearer ${sellerToken}`
    }
  });

  const result = await response.json();

  if (result.status === 1) {
    const { category, store_info, products, pagination } = result.data;

    console.log(`Category: ${category.name}`);
    console.log(`Store: ${store_info.name} (Managed by Admin: ${store_info.managed_by_admin})`);
    console.log(`Total Products: ${pagination.total}`);

    products.forEach(product => {
      console.log(`\nProduct: ${product.name}`);
      console.log(`Seller ID: ${product.seller_id}`);
      console.log(`Variants: ${product.variants.length}`);

      product.variants.forEach(variant => {
        console.log(`  - ${variant.measurement}${variant.stock_unit_name}: ₹${variant.discounted_price} (Stock: ${variant.stock})`);
      });
    });

    return result.data;
  } else {
    console.error('Error:', result.message);
  }
}

// Usage
fetchProductsByCategory(10, 1, 'premium');
```

## Performance Considerations

- Use pagination to avoid loading too many products at once
- The API uses Eloquent eager loading for variants, images, and tax to minimize database queries
- For large categories, consider implementing lazy loading or infinite scroll on the frontend
- Search queries use LIKE matching, which may be slower on large datasets
