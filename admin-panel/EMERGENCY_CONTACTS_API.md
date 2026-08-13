# Delivery Boy Emergency Contacts API Documentation

This API allows delivery boys to manage their emergency contact information through the mobile app.

## Base URL
All endpoints are prefixed with: `/api/delivery_boy/`

## Authentication
All endpoints require authentication using Laravel Passport API token.
Include the token in the Authorization header: `Bearer {token}`

---

## Endpoints

### 1. Get All Emergency Contacts

**GET** `/api/delivery_boy/emergency-contacts`

Get a list of all emergency contacts for the authenticated delivery boy.

#### Request Headers
```
Authorization: Bearer {token}
Accept: application/json
```

#### Response (Success - 200)
```json
{
    "error": false,
    "message": "Emergency contacts retrieved successfully.",
    "data": [
        {
            "id": 1,
            "delivery_boy_id": 5,
            "name": "John Doe",
            "mobile_number": "9876543210",
            "relation": "Father",
            "created_at": "2026-01-05T10:30:00.000000Z",
            "updated_at": "2026-01-05T10:30:00.000000Z"
        },
        {
            "id": 2,
            "delivery_boy_id": 5,
            "name": "Jane Doe",
            "mobile_number": "9876543211",
            "relation": "Mother",
            "created_at": "2026-01-05T10:35:00.000000Z",
            "updated_at": "2026-01-05T10:35:00.000000Z"
        }
    ]
}
```

---

### 2. Add Emergency Contact

**POST** `/api/delivery_boy/emergency-contacts`

Add a new emergency contact.

#### Request Headers
```
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

#### Request Body
```json
{
    "name": "John Doe",
    "mobile_number": "9876543210",
    "relation": "Father"
}
```

#### Validation Rules
- `name`: Required, string, max 255 characters
- `mobile_number`: Required, string, max 15 characters, only digits
- `relation`: Required, string, max 100 characters

#### Response (Success - 200)
```json
{
    "error": false,
    "message": "Emergency contact added successfully.",
    "data": {
        "id": 1,
        "delivery_boy_id": 5,
        "name": "John Doe",
        "mobile_number": "9876543210",
        "relation": "Father",
        "created_at": "2026-01-05T10:30:00.000000Z",
        "updated_at": "2026-01-05T10:30:00.000000Z"
    }
}
```

#### Response (Error - 200)
```json
{
    "error": true,
    "message": "The mobile number field is required."
}
```

---

### 3. Get Single Emergency Contact

**GET** `/api/delivery_boy/emergency-contacts/{id}`

Get details of a specific emergency contact.

#### Request Headers
```
Authorization: Bearer {token}
Accept: application/json
```

#### URL Parameters
- `id`: Emergency contact ID

#### Response (Success - 200)
```json
{
    "error": false,
    "message": "Emergency contact retrieved successfully.",
    "data": {
        "id": 1,
        "delivery_boy_id": 5,
        "name": "John Doe",
        "mobile_number": "9876543210",
        "relation": "Father",
        "created_at": "2026-01-05T10:30:00.000000Z",
        "updated_at": "2026-01-05T10:30:00.000000Z"
    }
}
```

#### Response (Error - 200)
```json
{
    "error": true,
    "message": "Emergency contact not found!"
}
```

---

### 4. Update Emergency Contact

**PUT** `/api/delivery_boy/emergency-contacts/{id}`

Update an existing emergency contact.

#### Request Headers
```
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

#### URL Parameters
- `id`: Emergency contact ID

#### Request Body (all fields optional)
```json
{
    "name": "John Smith",
    "mobile_number": "9876543299",
    "relation": "Brother"
}
```

#### Validation Rules
- `name`: Optional, string, max 255 characters
- `mobile_number`: Optional, string, max 15 characters, only digits
- `relation`: Optional, string, max 100 characters

#### Response (Success - 200)
```json
{
    "error": false,
    "message": "Emergency contact updated successfully.",
    "data": {
        "id": 1,
        "delivery_boy_id": 5,
        "name": "John Smith",
        "mobile_number": "9876543299",
        "relation": "Brother",
        "created_at": "2026-01-05T10:30:00.000000Z",
        "updated_at": "2026-01-05T11:00:00.000000Z"
    }
}
```

---

### 5. Delete Emergency Contact

**DELETE** `/api/delivery_boy/emergency-contacts/{id}`

Delete an emergency contact.

#### Request Headers
```
Authorization: Bearer {token}
Accept: application/json
```

#### URL Parameters
- `id`: Emergency contact ID

#### Response (Success - 200)
```json
{
    "error": false,
    "message": "Emergency contact deleted successfully."
}
```

#### Response (Error - 200)
```json
{
    "error": true,
    "message": "Emergency contact not found!"
}
```

---

## Error Responses

All endpoints may return the following error responses:

### Unauthorized (200)
```json
{
    "error": true,
    "message": "Unauthorized. Please login to continue."
}
```

### Delivery Boy Not Found (200)
```json
{
    "error": true,
    "message": "Delivery boy account not found!"
}
```

### Server Error (200)
```json
{
    "error": true,
    "message": "Failed to retrieve emergency contacts: {error_details}"
}
```

---

## Database Schema

### Table: `delivery_boy_emergency_contacts`

| Column           | Type                | Description                          |
|------------------|---------------------|--------------------------------------|
| id               | BIGINT UNSIGNED     | Primary key                          |
| delivery_boy_id  | BIGINT UNSIGNED     | Foreign key to delivery_boys table   |
| name             | VARCHAR(255)        | Contact person's name                |
| mobile_number    | VARCHAR(15)         | Contact person's mobile number       |
| relation         | VARCHAR(100)        | Relationship (Father, Mother, etc.)  |
| created_at       | TIMESTAMP           | Record creation timestamp            |
| updated_at       | TIMESTAMP           | Record update timestamp              |

---

## Usage Examples

### Example 1: Get All Contacts (cURL)
```bash
curl -X GET "https://your-domain.com/api/delivery_boy/emergency-contacts" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

### Example 2: Add Contact (cURL)
```bash
curl -X POST "https://your-domain.com/api/delivery_boy/emergency-contacts" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "mobile_number": "9876543210",
    "relation": "Father"
  }'
```

### Example 3: Update Contact (cURL)
```bash
curl -X PUT "https://your-domain.com/api/delivery_boy/emergency-contacts/1" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "mobile_number": "9876543299"
  }'
```

### Example 4: Delete Contact (cURL)
```bash
curl -X DELETE "https://your-domain.com/api/delivery_boy/emergency-contacts/1" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

---

## Notes

1. Each delivery boy can have multiple emergency contacts
2. All contacts are automatically linked to the authenticated delivery boy
3. Delivery boys can only access and manage their own emergency contacts
4. The `mobile_number` field only accepts numeric values
5. All endpoints use soft authentication - errors are returned with 200 status code and `error: true`
6. The migration file creates a foreign key constraint with cascade delete - if a delivery boy is deleted, all their emergency contacts are automatically deleted

---

## Migration

To run the migration on production:

```bash
php artisan migrate
```

This will create the `delivery_boy_emergency_contacts` table with all necessary columns and foreign key constraints.
