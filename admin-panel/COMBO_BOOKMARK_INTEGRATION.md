# Combo Bookmark Integration

## Summary

Updated the **ComboController** to include bookmark status (`is_bookmarked` field) in all combo API responses.

## Changes Made

### File: `app/Http/Controllers/API/Customer/ComboController.php`

#### 1. Added Import
```php
use App\Models\Bookmark;
```

#### 2. Updated Methods

All three combo-fetching methods now check and return bookmark status:

**Method 1: `getCombosCustomerHomePage(Request $request)`**
- Gets combos for home page with store filtering
- Added bookmark check for each combo
- Returns `'is_bookmarked' => 1 | 0`

**Method 2: `getCombosCustomerBasedOnCategoryType(Request $request)`**
- Gets combos grouped by category type with filtering
- Added bookmark check for each combo
- Returns `'is_bookmarked' => 1 | 0`

**Method 3: `getCombosCustomer(Request $request)`**
- Gets combos by store
- Added bookmark check for each combo
- Returns `'is_bookmarked' => 1 | 0`

**Method 4: `getSingleCombo(Request $request)`**
- Gets single combo details with all information
- Added bookmark check for the combo
- Returns `'is_bookmarked' => 1 | 0`

## Implementation Details

### Bookmark Check Query
```php
$isBookmarked = Bookmark::where('user_id', $user_id)
    ->where('type', 'combo')
    ->where('bookmarkable_type', Combo::class)
    ->where('bookmarkable_id', $combo->id)
    ->exists();
```

### Response Field
```json
{
  "id": 1,
  "name": "Combo Name",
  "price": 999,
  "is_bookmarked": 1,  // NEW FIELD
  "is_already_added": 0,
  ...
}
```

## API Response Examples

### Get Home Page Combos
```json
{
  "status": "success",
  "data": [
    {
      "id": 123,
      "name": "Weekly Combo Pack",
      "price": 1299,
      "rating": 4.5,
      "is_bookmarked": 1,
      "is_already_added": 0,
      "products": [...],
      ...
    }
  ],
  "total": 45
}
```

### Get Single Combo
```json
{
  "status": "success",
  "data": {
    "id": 123,
    "name": "Weekly Combo Pack",
    "is_bookmarked": 1,
    "is_already_added": 0,
    "rating": 4.5,
    "stores": [...],
    "ratings": [...]
  }
}
```

## Field Values

- `is_bookmarked`: **1** if combo is bookmarked by user, **0** if not
- Works alongside existing `is_already_added` field
- Null-safe: Returns 0 if user is not authenticated

## Usage

Users can now see at a glance whether they've bookmarked a combo:

1. **Show bookmark icon/button** - Display if `is_bookmarked == 1`
2. **Toggle bookmark** - Call bookmark endpoints to change status
3. **Filter bookmarked combos** - Use bookmark endpoints to get only bookmarked items

## Related Endpoints

**Bookmark Management:**
```
POST   /api/customer/bookmarks
DELETE /api/customer/bookmarks/{id}
POST   /api/customer/bookmarks/check-bookmarked
GET    /api/customer/bookmarks/type/combo
```

See [BOOKMARK_SYSTEM_DOCS.md](BOOKMARK_SYSTEM_DOCS.md) for full bookmark API documentation.

## Testing

Test endpoints to verify bookmark status:

```bash
# Get home page combos with bookmark status
curl -X GET "http://localhost/api/customer/combos-home" \
  -H "Authorization: Bearer {token}"

# Get single combo with bookmark status
curl -X POST "http://localhost/api/customer/combo-details" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"combo_id": 123}'

# Bookmark a combo
curl -X POST "http://localhost/api/customer/bookmarks" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"type": "combo", "item_id": 123}'
```

## Notes

- Bookmark status is user-specific
- Unauthenticated requests return `is_bookmarked: 0`
- Bookmark status updates are immediate
- Works with polymorphic bookmark system supporting products, sellers, and combos
