# 📮 Postman API Testing Guide - QR Code Payment

## 🎯 Overview

This guide shows you how to test the QR code payment API endpoints using Postman.

---

## 🔧 Setup Postman

### **1. Create New Request**

1. Open Postman
2. Click "New" → "Request"
3. Name it: "Generate Order QR Code"
4. Create a new collection: "Zenfoo - QR Payment"

---

## 🧪 Test Endpoints

### **Option 1: Test Endpoint (No Authentication)**

**Best for initial testing - No driver token needed!**

#### **Request Details**:
```
Method: POST
URL: http://localhost:8000/api/test/generate-qr
```

#### **Headers**:
```
Content-Type: application/json
Accept: application/json
```

#### **Body** (raw JSON):
```json
{
    "order_id": 1
}
```

#### **Postman Screenshot Setup**:

1. **Method**: Select `POST` from dropdown
2. **URL**: `http://localhost:8000/api/test/generate-qr`
3. **Headers Tab**:
   - Key: `Content-Type` | Value: `application/json`
   - Key: `Accept` | Value: `application/json`
4. **Body Tab**:
   - Select `raw`
   - Select `JSON` from dropdown
   - Paste JSON: `{"order_id": 1}`
5. Click **Send**

#### **Expected Response (Success)**:
```json
{
    "status": 1,
    "message": "QR code generated successfully",
    "data": {
        "order_id": 1,
        "amount": 450.50,
        "currency": "INR",
        "qr_code_id": "QR1234567890",
        "qr_code_string": "upi://pay?pa=paytm-xxx...",
        "qr_image_base64": "data:image/png;base64,iVBORw0KGgo...",
        "qr_type": "paytm_dynamic",
        "payment_gateway": "paytm",
        "instructions": [...]
    }
}
```

#### **Expected Response (Error - SSL Issue)**:
```json
{
    "status": 0,
    "message": "Exception: cURL error 60: SSL certificate problem..."
}
```

**Note**: SSL error is normal in local development. To fix, see "SSL Certificate Fix" section below.

---

### **Option 2: Authenticated Endpoint (Production)**

**For real testing with driver authentication**

#### **Request Details**:
```
Method: POST
URL: http://localhost:8000/api/delivery-boy/orders/generate-qr
```

#### **Headers**:
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {driver_access_token}
```

#### **Body** (raw JSON):
```json
{
    "order_id": 123
}
```

#### **Postman Setup**:

1. **Method**: `POST`
2. **URL**: `http://localhost:8000/api/delivery-boy/orders/generate-qr`
3. **Authorization Tab**:
   - Type: `Bearer Token`
   - Token: `{paste_driver_token_here}`
4. **Headers Tab**:
   - Key: `Content-Type` | Value: `application/json`
   - Key: `Accept` | Value: `application/json`
5. **Body Tab**:
   - Select `raw`
   - Select `JSON`
   - Paste: `{"order_id": 123}`
6. Click **Send**

#### **How to Get Driver Token**:

**Option A: Use Existing Login API**
```
POST http://localhost:8000/api/delivery-boy/verify-otp
Body:
{
    "phone": "1234567890",
    "otp": "123456"
}

Response will contain:
{
    "data": {
        "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc..."
    }
}
```

**Option B: Get from Database**
```sql
SELECT remember_token FROM admins WHERE type = 'delivery_boy' LIMIT 1;
```

---

## 🔐 SSL Certificate Fix (Local Development)

### **Issue**:
```
cURL error 60: SSL certificate problem: unable to get local issuer certificate
```

### **Solution 1: Disable SSL Verification (Development Only)**

Add to `app/Services/PaytmQRCodeService.php` at line 132:

```php
// Make API request to Paytm
$response = Http::withHeaders([
    'Content-Type' => 'application/json',
])
->withOptions([
    'verify' => false,  // ← Add this line (DEVELOPMENT ONLY!)
])
->post($apiUrl, [
    'head' => [
        'tokenType' => 'CHECKSUM',
        'signature' => $checksum
    ],
    'body' => $requestBody
]);
```

**⚠️ WARNING**: Only use `'verify' => false` in local development! Never in production!

### **Solution 2: Add SSL Certificate (Recommended for Production)**

1. Download cacert.pem:
   - URL: https://curl.se/ca/cacert.pem

2. Save to: `C:\xampp\php\extras\ssl\cacert.pem`

3. Edit `php.ini`:
   ```ini
   curl.cainfo = "C:\xampp\php\extras\ssl\cacert.pem"
   ```

4. Restart Apache

---

## 📊 Testing Scenarios

### **Test 1: Valid Order**
```json
Request:
{
    "order_id": 1
}

Expected: 200 OK
Response: QR code data with base64 image
```

### **Test 2: Invalid Order**
```json
Request:
{
    "order_id": 99999
}

Expected: 400 Bad Request
Response: {"status": 0, "message": "Order not found"}
```

### **Test 3: Missing Order ID**
```json
Request:
{
}

Expected: 400 Bad Request
Response: {"status": 0, "message": "Validation error"}
```

### **Test 4: Already Paid Order**
```json
Request:
{
    "order_id": 5
}

Expected: 400 Bad Request
Response: {"status": 0, "message": "Order is already paid"}
```

---

## 🌐 Production URL

### **Production Base URL**:
```
https://wheat-rook-708688.hostingersite.com
```

### **Production Endpoints**:

**Test Endpoint (if enabled)**:
```
POST https://wheat-rook-708688.hostingersite.com/api/test/generate-qr
```

**Authenticated Endpoint**:
```
POST https://wheat-rook-708688.hostingersite.com/api/delivery-boy/orders/generate-qr
```

---

## 📋 Complete Postman Collection JSON

You can import this JSON into Postman:

```json
{
    "info": {
        "name": "Zenfoo - QR Payment API",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    "item": [
        {
            "name": "Generate QR Code (Test - No Auth)",
            "request": {
                "method": "POST",
                "header": [
                    {
                        "key": "Content-Type",
                        "value": "application/json"
                    },
                    {
                        "key": "Accept",
                        "value": "application/json"
                    }
                ],
                "body": {
                    "mode": "raw",
                    "raw": "{\n    \"order_id\": 1\n}"
                },
                "url": {
                    "raw": "http://localhost:8000/api/test/generate-qr",
                    "protocol": "http",
                    "host": ["localhost"],
                    "port": "8000",
                    "path": ["api", "test", "generate-qr"]
                }
            }
        },
        {
            "name": "Generate QR Code (Authenticated)",
            "request": {
                "auth": {
                    "type": "bearer",
                    "bearer": [
                        {
                            "key": "token",
                            "value": "{{driver_token}}",
                            "type": "string"
                        }
                    ]
                },
                "method": "POST",
                "header": [
                    {
                        "key": "Content-Type",
                        "value": "application/json"
                    },
                    {
                        "key": "Accept",
                        "value": "application/json"
                    }
                ],
                "body": {
                    "mode": "raw",
                    "raw": "{\n    \"order_id\": 123\n}"
                },
                "url": {
                    "raw": "http://localhost:8000/api/delivery-boy/orders/generate-qr",
                    "protocol": "http",
                    "host": ["localhost"],
                    "port": "8000",
                    "path": ["api", "delivery-boy", "orders", "generate-qr"]
                }
            }
        }
    ]
}
```

**To Import**:
1. Copy the JSON above
2. Open Postman
3. Click "Import" button
4. Select "Raw text"
5. Paste JSON
6. Click "Continue" → "Import"

---

## 🎯 Response Fields Explained

### **Success Response**:
```json
{
    "status": 1,                          // 1 = success, 0 = error
    "message": "QR code generated successfully",
    "data": {
        "order_id": 123,                  // Order ID
        "amount": 450.50,                 // Amount to collect
        "currency": "INR",                // Currency
        "qr_code_id": "QR1234567890",    // Paytm QR code ID
        "qr_code_string": "upi://pay...", // UPI payment string
        "qr_image_base64": "data:image/png;base64,...", // QR image (ready to display)
        "qr_type": "paytm_dynamic",       // QR type
        "payment_gateway": "paytm",       // Payment gateway
        "instructions": [...]             // Instructions for driver
    }
}
```

### **Error Response**:
```json
{
    "status": 0,
    "message": "Error description here",
    "error": "Detailed error message"
}
```

---

## 🔍 Debugging Tips

### **1. Check Laravel Logs**:
```bash
tail -f storage/logs/laravel.log
```

Look for:
- `Calling Paytm Dynamic QR API`
- `Paytm Dynamic QR created successfully`
- Any error messages

### **2. Enable Debug Mode**:

In `.env`:
```
APP_DEBUG=true
```

This will show detailed error messages in API responses.

### **3. Check Order Exists**:
```sql
SELECT id, final_total, payment_status FROM orders WHERE id = 1;
```

### **4. Check Paytm Credentials**:
```sql
SELECT `key`, `value`
FROM settings
WHERE `key` LIKE 'paytm%'
OR `key` = 'store_mode';
```

---

## ✅ Checklist Before Testing

- [ ] Apache/Nginx server running
- [ ] MySQL database running
- [ ] At least one order exists in database
- [ ] Paytm credentials configured in Settings → Store Settings
- [ ] Paytm environment set (staging/production)
- [ ] SSL certificate issue fixed (if testing real Paytm API)
- [ ] Postman installed
- [ ] Test endpoint enabled (check routes/api.php line 178)

---

## 🚀 Quick Test Command

**Using cURL** (Terminal/Command Prompt):

```bash
# Test endpoint (no auth)
curl -X POST http://localhost:8000/api/test/generate-qr \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"order_id\": 1}"

# With authentication
curl -X POST http://localhost:8000/api/delivery-boy/orders/generate-qr \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d "{\"order_id\": 123}"
```

---

## 📞 Support

If you encounter issues:
1. Check Laravel logs: `storage/logs/laravel.log`
2. Verify order exists in database
3. Check Paytm credentials in admin panel
4. Check SSL certificate (if SSL error)
5. Verify routes exist: `php artisan route:list | grep generate-qr`

---

**Testing Guide Complete!** 🎉

Use the test endpoint first to verify API is working, then test with authentication for production-ready testing.