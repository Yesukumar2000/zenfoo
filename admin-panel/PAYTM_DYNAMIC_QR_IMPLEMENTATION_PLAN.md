# 🚀 Paytm Dynamic QR Code API - Implementation Plan

## 📅 Date: 2026-03-11
## 🎯 Goal: Replace Simple UPI QR with Paytm Dynamic QR API (Like Razorpay)

---

## ✅ What We're Implementing

### Current Implementation (Wrong):
```
Generate UPI string: upi://pay?pa=merchant@paytm&am=100
↓
Create QR from UPI string
↓
Money goes DIRECTLY to UPI ID's bank account
❌ NOT through Paytm Payment Gateway
```

### New Implementation (Correct - Like Razorpay):
```
Call Paytm API: POST /paymentservices/qr/create
↓
Paytm generates dynamic QR code
↓
Customer scans and pays
↓
Money goes to Paytm Payment Gateway Account ✅
↓
Paytm sends webhook
↓
Order auto-updated
↓
Settlement to bank (T+1/T+2)
```

---

## 📋 API Details

### Endpoint:
- **Staging**: `https://securestage.paytmpayments.com/paymentservices/qr/create`
- **Production**: `https://secure.paytmpayments.com/paymentservices/qr/create`

### Request Format:
```json
{
  "head": {
    "clientId": "C11",
    "version": "v1",
    "signature": "CHECKSUM_HERE"
  },
  "body": {
    "mid": "YOUR_MERCHANT_ID",
    "orderId": "ORDER_123",
    "amount": "450.50",
    "businessType": "UPI_QR_CODE",
    "posId": "DELIVERY_BOY_ID"
  }
}
```

### Response Format:
```json
{
  "head": {
    "responseTimestamp": "timestamp",
    "signature": "checksum"
  },
  "body": {
    "resultInfo": {
      "resultStatus": "SUCCESS",
      "resultCode": "0",
      "resultMsg": "QR created successfully"
    },
    "qrData": "BASE64_ENCODED_QR_IMAGE",
    "qrCodeId": "QR_CODE_ID",
    "image": "IMAGE_URL"
  }
}
```

---

## 🔧 Implementation Steps

### Step 1: Add New Method to PaytmQRCodeService

File: `app/Services/PaytmQRCodeService.php`

Add method:
```php
public static function generateDynamicQRCode(Order $order, array $options = []): array
{
    // 1. Get Paytm credentials
    // 2. Prepare request body
    // 3. Generate checksum
    // 4. Call Paytm QR API
    // 5. Parse response
    // 6. Return QR code data
}
```

### Step 2: Use Existing Paytm Helper

We already have:
- `app/Helpers/Paytm.php` - For checksum generation
- `Paytm::generateSignature()` method
- Merchant credentials in settings

### Step 3: HTTP Request

Use Laravel HTTP client:
```php
use Illuminate\Support\Facades\Http;

$response = Http::post($url, $paytmParams);
```

### Step 4: Handle Response

Parse Paytm response:
- Extract QR code image (base64)
- Extract QR code ID
- Store in response

### Step 5: Update Controller

Modify `OrderController@generateOrderQRCode` to use new method

### Step 6: Test

Test with staging credentials first, then production

---

## 📁 Files to Modify

### 1. PaytmQRCodeService.php
- Add `generateDynamicQRCode()` method
- Keep `generateOrderQRCode()` as wrapper
- Add fallback mechanism

### 2. No changes needed to:
- ✅ PaytmWebhookService.php (already handles webhooks)
- ✅ PaytmPaymentController.php (already has unified callback)
- ✅ Routes (already configured)

---

## 🎯 Benefits

### After Implementation:

✅ **Money Flow**: Customer → Paytm PG Account → Settlement to Bank
✅ **Like Razorpay**: Exact same flow
✅ **Webhook Support**: Paytm sends notification automatically
✅ **Reconciliation**: All payments in Paytm dashboard
✅ **Settlement**: T+1 or T+2 to bank account

---

## ⚠️ Important Notes

### Credentials Needed:
- ✅ Merchant ID (Already have: `eMmqJZ59036384322689` for test)
- ✅ Merchant Key (Already configured)
- ✅ Environment (test/live)

### POS ID:
- Use delivery boy ID as `posId`
- Helps track which driver generated which QR

### Checksum:
- Must use Paytm's checksum generation
- Use `Paytm::generateSignature()` helper

---

## 🧪 Testing Plan

### Test 1: Generate QR
```
1. Call API endpoint
2. Verify QR code generated
3. Check response format
```

### Test 2: Make Payment
```
1. Generate test QR
2. Scan with UPI app
3. Pay ₹1
4. Verify webhook received
5. Check order updated
```

### Test 3: Verify Money Flow
```
1. Check Paytm dashboard
2. Verify payment in PG account
3. Check settlement status
```

---

## 🚀 Ready to Implement!

All prerequisites confirmed:
- ✅ Paytm Dynamic QR API available
- ✅ API documentation reviewed
- ✅ Credentials configured
- ✅ Webhook handler ready
- ✅ Plan approved

**Let's build it!** 🎉