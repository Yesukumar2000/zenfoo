# Seller Customer Issue Report Returns API Documentation

This API allows sellers to view and manage customer issue report returns assigned to them.

## Base URL
```
{{base_url}}/api/seller
```

## Authentication
All endpoints require authentication using Bearer token obtained from seller login.

Header:
```
Authorization: Bearer {seller_access_token}
```

---

## Endpoints

### 1. Get All Return Requests

Fetch all customer issue report returns for the authenticated seller.

**Endpoint:** `GET /issue-report-returns`

**Query Parameters:**
- `status` (optional, integer): Filter by return acceptance status
  - `0` = Pending
  - `1` = Accepted
- `from_date` (optional, date): Filter returns from this date (YYYY-MM-DD)
- `to_date` (optional, date): Filter returns to this date (YYYY-MM-DD)
- `page` (optional, integer): Page number (default: 1)
- `per_page` (optional, integer): Items per page (default: 20, max: 100)

**Example Request:**
```bash
curl --location 'http://127.0.0.1:8000/api/seller/issue-report-returns?status=0&page=1&per_page=20' \
--header 'Authorization: Bearer {seller_token}'
```

**Success Response (200):**
```json
{
    "success": 1,
    "message": "Return requests fetched successfully.",
    "data": {
        "returns": [
            {
                "return_id": 1,
                "report_id": 10,
                "seller_id": 32,
                "customer_id": 13,
                "date": "2026-01-13",
                "product_ids": [],
                "delivery_partner_id": null,
                "delivered_date": null,
                "is_return_accepted": 0,
                "return_status": "Pending",
                "report": {
                    "order_id": 114,
                    "order_number": "ORD123456",
                    "report_type": "wrong",
                    "description": "Wrong items received in order",
                    "is_refund_requested": true,
                    "status": 0,
                    "status_name": "Pending",
                    "admin_remarks": null,
                    "selected_items": [
                        {
                            "store_id": 15,
                            "store_name": "Store Name",
                            "image_urls": [
                                "http://example.com/storage/wrong_item_reports/image1.jpg",
                                "http://example.com/storage/wrong_item_reports/image2.jpg"
                            ],
                            "description": "Item description"
                        }
                    ],
                    "selected_combo_items": [
                        {
                            "combo_id": 25,
                            "combo_name": "Paneer Combo",
                            "image_urls": [
                                "http://example.com/storage/wrong_item_reports/combo_image.jpg"
                            ],
                            "description": "Combo issue description"
                        }
                    ],
                    "created_at": "2026-01-13 15:13:39",
                    "updated_at": "2026-01-13 15:13:39"
                },
                "customer": {
                    "id": 13,
                    "name": "Customer Name",
                    "mobile": "9876543210",
                    "email": "customer@example.com"
                },
                "delivery_partner": {
                    "id": 5,
                    "name": "Delivery Boy Name",
                    "mobile": "9876543210"
                },
                "delivery_date": "2026-01-13 14:30:00"
            }
        ],
        "pagination": {
            "current_page": 1,
            "per_page": 20,
            "total": 1,
            "total_pages": 1
        }
    }
}
```

---

### 2. Get Single Return Request

Fetch details of a specific return request by ID.

**Endpoint:** `GET /issue-report-returns/{return_id}`

**Path Parameters:**
- `return_id` (required, integer): The ID of the return request

**Example Request:**
```bash
curl --location 'http://127.0.0.1:8000/api/seller/issue-report-returns/1' \
--header 'Authorization: Bearer {seller_token}'
```

**Success Response (200):**
```json
{
    "success": 1,
    "message": "Return request fetched successfully.",
    "data": {
        "return_id": 1,
        "report_id": 10,
        "seller_id": 32,
        "customer_id": 13,
        "date": "2026-01-13",
        "product_ids": [],
        "delivery_partner_id": null,
        "delivered_date": null,
        "is_return_accepted": 0,
        "return_status": "Pending",
        "report": {
            "order_id": 114,
            "order_number": "ORD123456",
            "report_type": "wrong",
            "description": "Wrong items received in order",
            "is_refund_requested": true,
            "status": 0,
            "status_name": "Pending",
            "admin_remarks": null,
            "selected_items": [...],
            "selected_combo_items": [...],
            "created_at": "2026-01-13 15:13:39",
            "updated_at": "2026-01-13 15:13:39"
        },
        "customer": {...},
        "delivery_partner": {...},
        "delivery_date": "2026-01-13 14:30:00"
    }
}
```

---

### 3. Update Return Status

Update the acceptance status of a return request.

**Endpoint:** `POST /issue-report-returns/update-status`

**Request Body (form-data or JSON):**
- `return_id` (required, integer): The ID of the return request
- `is_return_accepted` (required, integer): Acceptance status
  - `0` = Rejected/Pending
  - `1` = Accepted

**Example Request:**
```bash
curl --location 'http://127.0.0.1:8000/api/seller/issue-report-returns/update-status' \
--header 'Authorization: Bearer {seller_token}' \
--header 'Content-Type: application/json' \
--data '{
    "return_id": 1,
    "is_return_accepted": 1
}'
```

**Success Response (200):**
```json
{
    "success": 1,
    "message": "Return status updated successfully."
}
```

**Error Response (422):**
```json
{
    "success": 0,
    "message": "Validation error message"
}
```

---

## Error Responses

### Unauthorized (401)
```json
{
    "success": 0,
    "message": "Unauthorized. Please login to continue."
}
```

### Seller Not Found
```json
{
    "success": 0,
    "message": "Seller account not found."
}
```

### Return Request Not Found (404)
```json
{
    "success": 0,
    "message": "Return request not found."
}
```

### Server Error (500)
```json
{
    "success": 0,
    "message": "Failed to fetch return requests. Please try again later."
}
```

---

## Database Tables

### customer_issue_report_returns
Stores return requests for sellers.

**Columns:**
- `id`: Primary key
- `report_id`: Foreign key to `customer_item_missing_reports.id`
- `seller_id`: Foreign key to `sellers.id`
- `customer_id`: Foreign key to `users.id`
- `date`: Date of return request
- `product_ids`: JSON array of product IDs
- `delivery_partner_id`: Foreign key to `delivery_boys.id` (nullable)
- `delivered_date`: Date when order was delivered (nullable)
- `is_return_accepted`: 0 = Pending, 1 = Accepted
- `created_at`: Timestamp
- `updated_at`: Timestamp

### customer_item_missing_reports
Stores customer issue reports (missing or wrong items).

**Key Columns:**
- `id`: Primary key
- `customer_id`: Foreign key to `users.id`
- `order_id`: Foreign key to `orders.id`
- `report_type`: 'missing' or 'wrong'
- `selected_items`: JSON array of store-wise items
- `selected_combo_items`: JSON array of combo items
- `description`: Overall description
- `is_refund_requested`: Boolean
- `status`: 0=Pending, 1=In Progress, 2=Resolved, 3=Rejected
- `admin_remarks`: Admin comments (nullable)

---

## Notes

1. All endpoints require authentication with seller's Bearer token
2. The API automatically filters returns by authenticated seller's ID
3. Dates should be in `YYYY-MM-DD` format
4. Pagination defaults to 20 items per page with a maximum of 100
5. All responses follow the standard format with `success`, `message`, and `data` fields
6. Comprehensive error logging is implemented for debugging
