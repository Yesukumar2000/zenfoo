# Bookmark System Documentation

## Overview

A lightweight bookmark system that allows users to save and manage their favorite **products**, **sellers**, and **combos** (combo deals). Uses a polymorphic relationship for flexible item management.

## Database Schema

### bookmarks Table

| Column | Type | Notes |
|--------|------|-------|
| id | bigint | Primary Key |
| user_id | bigint | FK to users (cascade delete) |
| bookmarkable_type | string | Model class name (e.g., 'App\Models\Product', 'App\Models\Seller', 'App\Models\Combo') |
| bookmarkable_id | bigint | ID of the bookmarked item (product_id, seller_id, or combo_id) |
| type | string | 'product', 'seller', or 'combo' (for easier filtering) |
| created_at | timestamp | |
| updated_at | timestamp | |

**Indexes:**
- user_id
- [bookmarkable_type, bookmarkable_id] (composite)
- type
- Unique: (user_id, bookmarkable_type, bookmarkable_id)

**Benefits of Polymorphic Design:**
- Single table for all bookmark types
- Easy to extend with new model types
- Maintains referential integrity through model classes
- Cleaner schema without separate columns for each type

## Model

### Bookmark Model
Located at: `app/Models/Bookmark.php`

**Relationships:**
```php
- belongsTo(User::class)
- morphTo() - Polymorphic relationship returning Product, Seller, or Combo
```

**Scopes:**
```php
- byUser($userId)
- byType($type) - Filter by 'product', 'seller', or 'combo'
- products() - All product bookmarks
- sellers() - All seller bookmarks
- combos() - All combo bookmarks
```

**Fillable Fields:**
```php
['user_id', 'bookmarkable_type', 'bookmarkable_id', 'type']
```

## API Endpoints

### Base URL
```
/api/customer/bookmarks
```

### 1. Get All Bookmarks
```
GET /bookmarks
```

**Query Parameters:**
- `limit` (default: 10) - Items per page
- `offset` (default: 0) - Pagination offset
- `type` (optional) - Filter by type: 'product', 'seller', 'combo'
- `sort_by` (default: 'created_at') - Sort field
- `sort_order` (default: 'desc') - Sort direction: 'asc' or 'desc'

**Example Request:**
```bash
GET /api/customer/bookmarks?type=product&limit=20&offset=0
```

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "type": "product",
      "bookmarkable_type": "App\\Models\\Product",
      "bookmarkable_id": 123,
      "item": {
        "id": 123,
        "name": "Product Name",
        "price": 999,
        "image": "url",
        ...
      },
      "created_at": "2026-01-30T10:30:00Z",
      "updated_at": "2026-01-30T10:30:00Z"
    }
  ],
  "total": 45
}
```

### 2. Get Single Bookmark
```
GET /bookmarks/{id}
```

**Response:** Single bookmark object with full item details

### 3. Create Bookmark
```
POST /bookmarks
```

**Request Body:**
```json
{
  "type": "product",
  "item_id": 123
}
```

**Validation Rules:**
- `type` - required, in: product, seller, combo
- `item_id` - required, must exist in corresponding table

**Response:** Created bookmark object with success message

**Examples:**

**Product Bookmark:**
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "product",
    "item_id": 123
  }'
```

**Seller Bookmark:**
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "seller",
    "item_id": 45
  }'
```

**Combo Bookmark:**
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "combo",
    "item_id": 456
  }'
```

### 4. Delete Bookmark
```
DELETE /bookmarks/{id}
```

**Response:** Success message

**Example:**
```bash
curl -X DELETE http://localhost/api/customer/bookmarks/1 \
  -H "Authorization: Bearer {token}"
```

### 5. Bulk Delete Bookmarks
```
POST /bookmarks/bulk-delete
```

**Request Body:**
```json
{
  "bookmark_ids": [1, 2, 3, 5]
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Bookmarks deleted successfully",
  "data": {
    "deleted_count": 4
  }
}
```

### 6. Get Bookmarks by Type
```
GET /bookmarks/type/{type}
```

**URL Parameters:**
- `type` - 'product', 'seller', or 'combo' (required)

**Query Parameters:**
- `limit` (default: 10)
- `offset` (default: 0)

**Examples:**
```bash
GET /api/customer/bookmarks/type/product?limit=15
GET /api/customer/bookmarks/type/seller?offset=20
GET /api/customer/bookmarks/type/combo
```

**Response:** Paginated bookmarks of specified type

### 7. Check If Bookmarked
```
POST /bookmarks/check-bookmarked
```

**Request Body:**
```json
{
  "type": "product",
  "item_id": 123
}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "is_bookmarked": true,
    "type": "product",
    "item_id": 123
  }
}
```

**Example Usage:**
```bash
curl -X POST http://localhost/api/customer/bookmarks/check-bookmarked \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "product",
    "item_id": 123
  }'
```

## Usage Examples

### Example 1: Bookmark a Product
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "product",
    "item_id": 123
  }'
```

### Example 2: Bookmark a Seller
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "seller",
    "item_id": 45
  }'
```

### Example 3: Bookmark a Combo Deal
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "combo",
    "item_id": 789
  }'
```

### Example 4: Get All Product Bookmarks
```bash
curl -X GET "http://localhost/api/customer/bookmarks?type=product&limit=20" \
  -H "Authorization: Bearer {token}"
```

### Example 5: Check if Product is Bookmarked
```bash
curl -X POST http://localhost/api/customer/bookmarks/check-bookmarked \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "product",
    "item_id": 123
  }'
```

### Example 6: Delete a Bookmark
```bash
curl -X DELETE http://localhost/api/customer/bookmarks/1 \
  -H "Authorization: Bearer {token}"
```

### Example 7: Bulk Delete Bookmarks
```bash
curl -X POST http://localhost/api/customer/bookmarks/bulk-delete \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "bookmark_ids": [1, 2, 3, 4, 5]
  }'
```

## Migration Instructions

### Step 1: Run Migration
```bash
php artisan migrate
```

This will create the `bookmarks` table with polymorphic columns and indexes.

### Step 2: Verify Model
The Bookmark model is automatically discovered in `app/Models/Bookmark.php`

### Step 3: Ensure Model Classes Exist
Make sure the following models exist and are configured:
- `App\Models\Product`
- `App\Models\Seller`
- `App\Models\Combo` (create if doesn't exist, or adjust namespace in BookmarkController)

### Step 4: Test Endpoints
Start with creating a bookmark and fetching all bookmarks to verify functionality.

## Error Responses

### Invalid Bookmark Type
```json
{
  "status": "error",
  "message": "invalid_bookmark_type"
}
```

### Bookmark Already Exists
```json
{
  "status": "error",
  "message": "bookmark_already_exists"
}
```

### Bookmark Not Found
```json
{
  "status": "error",
  "message": "bookmark_not_found"
}
```

### Item Not Found
```json
{
  "status": "error",
  "message": "Item not found for type: product"
}
```

### No Items Found
```json
{
  "status": "error",
  "message": "no_items_found"
}
```

## Comparison with Existing Favorites System

| Feature | Bookmarks | Favorites |
|---------|-----------|-----------|
| Product Support | ✅ | ✅ |
| Seller Support | ✅ | ❌ |
| Combo Support | ✅ | ❌ |
| Check Bookmarked Status | ✅ | ❌ |
| Polymorphic Design | ✅ | ❌ |
| Multiple Bookmarks | ✅ | ✅ |

The existing `/api/customer/favorites` endpoints remain unchanged and continue to work for product favorites.

## Security Notes

1. All bookmark operations require authentication (`auth:api-customers`)
2. Users can only access and modify their own bookmarks
3. Database queries automatically filter by user_id
4. All input is validated before processing
5. SQL injection prevention through Laravel Eloquent ORM
6. Foreign key constraints ensure referential integrity via polymorphic relationships

## Integration Notes

- **Favorites System**: The bookmark system works alongside the existing favorites endpoint at `/api/customer/favorites`
- **Product Details**: Product bookmarks return full product details including pricing and tax information via `CommonHelper::getProductDetails()`
- **Polymorphic Relationship**: Uses Laravel's polymorphic relationships for clean data architecture
- **Flexible Extensibility**: Easy to add new bookmark types by updating the `getBookmarkableType()` mapping

## Performance Considerations

- Uses eager loading with `.with('bookmarkable')` to avoid N+1 queries
- Composite index on [bookmarkable_type, bookmarkable_id] for fast lookups
- Indexed on user_id, type for efficient filtering
- Unique constraint prevents duplicate bookmarks per user per item
- Pagination built-in to handle large bookmark collections

## Advanced Usage

### Using Scopes in Custom Queries

```php
// Get all product bookmarks for a user
$productBookmarks = Bookmark::byUser($userId)->products()->get();

// Get all seller bookmarks
$sellerBookmarks = Bookmark::byUser($userId)->sellers()->get();

// Get all combo bookmarks
$comboBookmarks = Bookmark::byUser($userId)->combos()->get();
```

### Accessing Bookmarked Items

```php
$bookmark = Bookmark::find(1);

// Get the actual bookmarked model instance
$item = $bookmark->bookmarkable; // Returns Product, Seller, or Combo instance
```

### Filtering by Bookmarkable Type

```php
// Get all bookmarks of a specific model type
$productBookmarks = Bookmark::byUser($userId)
    ->where('bookmarkable_type', Product::class)
    ->get();
```
