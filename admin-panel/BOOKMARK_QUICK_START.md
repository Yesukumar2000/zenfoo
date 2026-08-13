# Bookmark Quick Start Guide

## ⭐ RECOMMENDED: Toggle Bookmark (Add or Remove)

**Perfect for mobile apps - no need to track bookmark_id!**

### Endpoint
```
POST /api/customer/bookmarks/toggle
```

### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

### Request Body
```json
{
  "type": "product|seller|combo",
  "item_id": 123
}
```

### How It Works
- **If NOT bookmarked** → Adds bookmark (returns `is_bookmarked: true`, `action: added`)
- **If already bookmarked** → Removes bookmark (returns `is_bookmarked: false`, `action: removed`)

### Examples

**Toggle Product Bookmark:**
```bash
curl -X POST http://localhost/api/customer/bookmarks/toggle \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "product",
    "item_id": 456
  }'
```

**Toggle Seller Bookmark:**
```bash
curl -X POST http://localhost/api/customer/bookmarks/toggle \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "seller",
    "item_id": 78
  }'
```

**Toggle Combo Bookmark:**
```bash
curl -X POST http://localhost/api/customer/bookmarks/toggle \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "combo",
    "item_id": 123
  }'
```

### Response - When Added
```json
{
  "status": "success",
  "message": "Bookmark created successfully",
  "data": {
    "id": 42,
    "type": "product",
    "is_bookmarked": true,
    "action": "added",
    "item": {
      "id": 456,
      "name": "Product Name",
      "price": 999
    }
  }
}
```

### Response - When Removed
```json
{
  "status": "success",
  "message": "Bookmark removed successfully",
  "data": {
    "is_bookmarked": false,
    "action": "removed",
    "type": "product",
    "item_id": 456
  }
}
```

---

## Add to Bookmark (Manual)

### Endpoint
```
POST /api/customer/bookmarks
```

### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
```

### Request Body
```json
{
  "type": "product|seller|combo",
  "item_id": 123
}
```

### Examples

**Bookmark a Product:**
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "product",
    "item_id": 456
  }'
```

**Bookmark a Seller:**
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "seller",
    "item_id": 78
  }'
```

**Bookmark a Combo:**
```bash
curl -X POST http://localhost/api/customer/bookmarks \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "combo",
    "item_id": 123
  }'
```

### Success Response
```json
{
  "status": "success",
  "message": "Bookmark created successfully",
  "data": {
    "id": 42,
    "type": "product",
    "bookmarkable_type": "App\\Models\\Product",
    "bookmarkable_id": 456,
    "item": {
      "id": 456,
      "name": "Product Name",
      "price": 999,
      "image": "url"
    },
    "created_at": "2026-01-30T10:30:00Z",
    "updated_at": "2026-01-30T10:30:00Z"
  }
}
```

### Error Responses

**Item Already Bookmarked:**
```json
{
  "status": "error",
  "message": "bookmark_already_exists"
}
```

**Invalid Type:**
```json
{
  "status": "error",
  "message": "invalid_bookmark_type"
}
```

**Item Not Found:**
```json
{
  "status": "error",
  "message": "Item not found for type: product"
}
```

---

## Remove from Bookmark

### Option 1: Delete Single Bookmark

#### Endpoint
```
DELETE /api/customer/bookmarks/{bookmark_id}
```

#### Example
```bash
curl -X DELETE http://localhost/api/customer/bookmarks/42 \
  -H "Authorization: Bearer {token}"
```

#### Response
```json
{
  "status": "success",
  "message": "Bookmark deleted successfully"
}
```

---

### Option 2: Bulk Delete Multiple Bookmarks

#### Endpoint
```
POST /api/customer/bookmarks/bulk-delete
```

#### Request Body
```json
{
  "bookmark_ids": [1, 2, 3, 42, 99]
}
```

#### Example
```bash
curl -X POST http://localhost/api/customer/bookmarks/bulk-delete \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "bookmark_ids": [1, 2, 3]
  }'
```

#### Response
```json
{
  "status": "success",
  "message": "Bookmarks deleted successfully",
  "data": {
    "deleted_count": 3
  }
}
```

---

## Check Bookmark Status

### Endpoint
```
POST /api/customer/bookmarks/check-bookmarked
```

### Request Body
```json
{
  "type": "product|seller|combo",
  "item_id": 123
}
```

### Example
```bash
curl -X POST http://localhost/api/customer/bookmarks/check-bookmarked \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "product",
    "item_id": 456
  }'
```

### Response
```json
{
  "status": "success",
  "data": {
    "is_bookmarked": true,
    "type": "product",
    "item_id": 456
  }
}
```

---

## Get User's Bookmarks

### Get All Bookmarks
```
GET /api/customer/bookmarks
```

#### Query Parameters
```
?limit=20&offset=0&type=product&sort_by=created_at&sort_order=desc
```

#### Example
```bash
curl -X GET "http://localhost/api/customer/bookmarks?type=product&limit=20" \
  -H "Authorization: Bearer {token}"
```

#### Response
```json
{
  "status": "success",
  "data": [
    {
      "id": 42,
      "type": "product",
      "bookmarkable_id": 456,
      "item": {
        "id": 456,
        "name": "Product Name",
        "price": 999
      },
      "created_at": "2026-01-30T10:30:00Z"
    }
  ],
  "total": 15
}
```

### Get Bookmarks by Type
```
GET /api/customer/bookmarks/type/{type}
```

#### Examples
```bash
# Get product bookmarks
curl -X GET "http://localhost/api/customer/bookmarks/type/product" \
  -H "Authorization: Bearer {token}"

# Get seller bookmarks
curl -X GET "http://localhost/api/customer/bookmarks/type/seller" \
  -H "Authorization: Bearer {token}"

# Get combo bookmarks
curl -X GET "http://localhost/api/customer/bookmarks/type/combo" \
  -H "Authorization: Bearer {token}"
```

---

## Mobile App Implementation (Recommended)

### Simple Toggle Button Pattern

**Flutter Example:**
```dart
class BookmarkButton extends StatefulWidget {
  final String type; // 'product', 'seller', 'combo'
  final int itemId;

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  bool isBookmarked = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkBookmarkStatus();
  }

  Future<void> checkBookmarkStatus() async {
    final response = await http.post(
      Uri.parse('$API_URL/bookmarks/check-bookmarked'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': widget.type,
        'item_id': widget.itemId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        isBookmarked = data['data']['is_bookmarked'] ?? false;
      });
    }
  }

  Future<void> toggleBookmark() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('$API_URL/bookmarks/toggle'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': widget.type,
        'item_id': widget.itemId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        isBookmarked = data['data']['is_bookmarked'] ?? false;
      });

      // Show toast message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : toggleBookmark,
      child: Row(
        children: [
          Icon(isBookmarked ? Icons.favorite : Icons.favorite_border),
          SizedBox(width: 8),
          Text(isBookmarked ? 'Bookmarked' : 'Bookmark'),
        ],
      ),
    );
  }
}
```

**React Native Example:**
```javascript
const BookmarkButton = ({ type, itemId }) => {
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkBookmarkStatus();
  }, [itemId]);

  const checkBookmarkStatus = async () => {
    try {
      const response = await fetch(`${API_URL}/bookmarks/check-bookmarked`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ type, item_id: itemId }),
      });
      const data = await response.json();
      setIsBookmarked(data.data.is_bookmarked);
    } catch (error) {
      console.error('Error:', error);
    }
  };

  const toggleBookmark = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/bookmarks/toggle`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ type, item_id: itemId }),
      });
      const data = await response.json();
      setIsBookmarked(data.data.is_bookmarked);
      Alert.alert('Success', data.message);
    } catch (error) {
      console.error('Error:', error);
      Alert.alert('Error', 'Failed to update bookmark');
    }
    setLoading(false);
  };

  return (
    <TouchableOpacity onPress={toggleBookmark} disabled={loading}>
      <Text style={{ color: isBookmarked ? 'red' : 'gray' }}>
        {isBookmarked ? '❤️ Bookmarked' : '🤍 Bookmark'}
      </Text>
    </TouchableOpacity>
  );
};
```

---

## Frontend Integration Example

### React Component Pattern (Web - Using Toggle)

```jsx
const BookmarkButton = ({ type, itemId }) => {
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [loading, setLoading] = useState(false);

  // Check bookmark status on load
  useEffect(() => {
    checkBookmarkStatus();
  }, [itemId]);

  const checkBookmarkStatus = async () => {
    try {
      const response = await fetch('/api/customer/bookmarks/check-bookmarked', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ type, item_id: itemId })
      });
      const data = await response.json();
      setIsBookmarked(data.data.is_bookmarked);
    } catch (error) {
      console.error('Error checking bookmark:', error);
    }
  };

  const toggleBookmark = async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/customer/bookmarks/toggle', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ type, item_id: itemId })
      });

      const data = await response.json();

      if (response.ok) {
        setIsBookmarked(data.data.is_bookmarked);
        // Show toast notification
        showToast(data.message, 'success');
      } else {
        showToast(data.message, 'error');
      }
    } catch (error) {
      console.error('Error toggling bookmark:', error);
      showToast('Failed to update bookmark', 'error');
    }
    setLoading(false);
  };

  const showToast = (message, type) => {
    // Use your toast library here
    console.log(`${type}: ${message}`);
  };

  return (
    <button
      onClick={toggleBookmark}
      disabled={loading}
      className={`bookmark-btn ${isBookmarked ? 'bookmarked' : ''}`}
    >
      <span className="icon">{isBookmarked ? '❤️' : '🤍'}</span>
      <span className="text">{isBookmarked ? 'Bookmarked' : 'Bookmark'}</span>
    </button>
  );
};
```

---

## Common Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 404 | Bookmark/Item not found |
| 422 | Validation error |
| 401 | Unauthorized (missing token) |

---

## Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | 'product', 'seller', or 'combo' |
| `item_id` | integer | ID of the product, seller, or combo |
| `is_bookmarked` | boolean | true if bookmarked, false otherwise |
| `bookmark_id` | integer | ID of the bookmark (for deletion) |
| `bookmarkable_id` | integer | Same as item_id |
| `bookmarkable_type` | string | Full class name (App\Models\Product, etc.) |

---

## Best Practices

1. **Check before adding** - Use `check-bookmarked` endpoint first
2. **Store bookmark_id** - You need this to remove bookmarks later
3. **Handle errors** - Show user-friendly error messages
4. **Cache status** - Don't check every render, cache the status
5. **Optimistic UI** - Update UI immediately, sync with server
6. **Handle unauthenticated** - Show login prompt if user not authenticated

