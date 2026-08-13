# 📋 Step-by-Step Setup Guide - QR Code & Webhook

## Part 1: Paytm Dashboard Configuration

### 🔑 **What You Need from Paytm Dashboard**

Login to: **https://dashboard.paytm.com/**

---

### **Step 1: Get Merchant UPI ID (VPA)**

**Where to find:**
1. Login to Paytm Business Dashboard
2. Navigate: **Payment Gateway** → **QR Code** or **Collections**
3. Look for: **"VPA"** or **"UPI ID"** or **"Merchant UPI ID"**

**What it looks like:**
```
zenfoo@paytm
OR
merchantid123@paytm
OR
yourname@paytm
```

**Copy this value!** ✏️

---

### **Step 2: Get Merchant Credentials**

**Where to find:**
1. Navigate: **Payment Gateway** → **API Keys** or **Developer Settings**
2. You'll find:

#### **For TEST/Staging:**
- ✅ **Test Merchant ID (MID)**: `e.g., MERCHANT_TEST_12345`
- ✅ **Test Merchant Key**: `e.g., abc123xyz456...` (long string)
- ✅ **Test Website**: Usually `WEBSTAGING`
- ✅ **Test Industry Type**: Usually `Retail`
- ✅ **Test Channel ID**: Usually `WEB` or `WAP`

#### **For LIVE/Production:**
- ✅ **Live Merchant ID (MID)**: `e.g., MERCHANT_LIVE_67890`
- ✅ **Live Merchant Key**: `e.g., xyz789abc123...` (long string)
- ✅ **Live Website**: Usually `DEFAULT`
- ✅ **Live Industry Type**: Usually `Retail`
- ✅ **Live Channel ID**: Usually `WEB` or `WAP`

**Copy all these values!** ✏️

---

### **Step 3: Configure Webhook URL**

**Where to configure:**
1. Navigate: **API & Webhooks** → **Webhook Configuration**
2. Click: **"Configure Webhook"** or **"Add Webhook"**

**Webhook URL to enter:**
```
Production: https://yourdomain.com/api/paytm/payment-webhook
Staging: https://staging.yourdomain.com/api/paytm/payment-webhook
```

**Replace `yourdomain.com` with your actual domain!**

**Events to select:**
- ✅ Payment Success (TXN_SUCCESS)
- ✅ Payment Failure (TXN_FAILURE)
- ✅ Payment Pending (PENDING)

**Screenshot location:** Click **Save** and Paytm will verify the webhook

---

## Part 2: Admin Panel Configuration

### **Step 1: Configure Paytm Credentials**

**Where:** Admin Panel → **Settings** → **Store Settings**

**Section:** **"Paytm Settings"**

Fill in ALL the values you copied from Paytm dashboard:

#### **Test Credentials:**
```
Test Merchant ID (MID):     [paste: MERCHANT_TEST_12345]
Test Merchant Key:          [paste: abc123xyz456...]
Test Website Name:          [paste: WEBSTAGING]
Test Industry Type:         [paste: Retail]
Test Channel ID:            [paste: WEB]
```

#### **Live Credentials:**
```
Live Merchant ID (MID):     [paste: MERCHANT_LIVE_67890]
Live Merchant Key:          [paste: xyz789abc123...]
Live Website Name:          [paste: DEFAULT]
Live Industry Type:         [paste: Retail]
Live Channel ID:            [paste: WEB]
```

#### **Environment:**
```
Paytm Environment:          [select: Test or Live]
```

**Click:** **Save** ✅

---

### **Step 2: Configure Merchant UPI ID**

**Where:** Admin Panel → **Settings** → **Store Settings**

**Section:** **"Merchant UPI / QR Code Settings"** (at the top)

Fill in:
```
Merchant UPI ID / VPA:      [paste: zenfoo@paytm]
Business Name:              [paste: Zenfoo]
```

**Click:** **Save** ✅

---

## Part 3: Driver App Integration

### 📱 **What Driver App Needs to Call**

---

### **Scenario 1: Generate QR Code for Order**

**When:** Driver arrives at customer location and customer wants to pay via QR

**API Endpoint:**
```
POST /api/delivery-boy/orders/generate-qr
```

**Headers:**
```
Authorization: Bearer {driver_access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
    "order_id": 123,
    "generate_image": true
}
```

**Parameters:**
- `order_id` (required): The order ID
- `generate_image` (optional): `true` to get QR image, `false` for just UPI string

---

### **Success Response:**

**Status:** `200 OK`

**Response Body:**
```json
{
    "status": 1,
    "message": "QR code generated successfully",
    "data": {
        "order_id": 123,
        "amount": 450.50,
        "currency": "INR",
        "upi_string": "upi://pay?pa=zenfoo@paytm&pn=Zenfoo&am=450.50&tr=123&tn=Order+%23123+-+Zenfoo&cu=INR",
        "merchant_name": "Zenfoo",
        "merchant_vpa": "zenfoo@paytm",
        "transaction_note": "Order #123 - Zenfoo",
        "qr_type": "upi",
        "image_base64": "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIj8+PHN2ZyB4bWxucz0i...",
        "image_svg": "<svg xmlns='http://www.w3.org/2000/svg' width='300' height='300'>...</svg>",
        "size": 300,
        "format": "svg",
        "instructions": [
            "Ask customer to scan QR code using any UPI app",
            "Customer can use Paytm, PhonePe, GooglePay, or any UPI app",
            "Amount is pre-filled - customer just needs to confirm payment",
            "After payment, verify the transaction on your app"
        ]
    }
}
```

---

### **What Driver App Should Do with Response:**

#### **Option 1: Display SVG QR Code (Recommended)**

**Flutter Example:**
```dart
import 'package:flutter_svg/flutter_svg.dart';

// From API response
String svgString = response['data']['image_svg'];

// Display QR code
Widget buildQRCode() {
  return Column(
    children: [
      Text('Scan to Pay ₹${response['data']['amount']}'),
      SizedBox(height: 20),
      SvgPicture.string(
        svgString,
        width: 300,
        height: 300,
      ),
      SizedBox(height: 20),
      Text('Order #${response['data']['order_id']}'),
      Text('Payment to: ${response['data']['merchant_name']}'),
    ],
  );
}
```

**React Native Example:**
```javascript
import { SvgXml } from 'react-native-svg';

const svgString = response.data.image_svg;

<View>
  <Text>Scan to Pay ₹{response.data.amount}</Text>
  <SvgXml
    xml={svgString}
    width="300"
    height="300"
  />
  <Text>Order #{response.data.order_id}</Text>
</View>
```

#### **Option 2: Display Base64 Image**

**Flutter:**
```dart
import 'dart:convert';

String base64String = response['data']['image_base64'];
// Remove data URI prefix if present
String cleanBase64 = base64String.split(',').last;

Image.memory(
  base64Decode(cleanBase64),
  width: 300,
  height: 300,
)
```

**React Native:**
```javascript
<Image
  source={{ uri: response.data.image_base64 }}
  style={{ width: 300, height: 300 }}
/>
```

#### **Option 3: Generate QR Code Locally (From UPI String)**

**Flutter:**
```dart
import 'package:qr_flutter/qr_flutter.dart';

String upiString = response['data']['upi_string'];

QrImageView(
  data: upiString,
  version: QrVersions.auto,
  size: 300.0,
  backgroundColor: Colors.white,
)
```

---

### **Error Responses:**

#### **Order Not Found:**
```json
{
    "status": 0,
    "message": "Order not found"
}
```

#### **Order Already Paid:**
```json
{
    "status": 0,
    "message": "Cannot generate QR code for this order",
    "errors": [
        "Order is already paid"
    ]
}
```

#### **Driver Not Assigned:**
```json
{
    "status": 0,
    "message": "You are not assigned to this order"
}
```

#### **Configuration Error:**
```json
{
    "status": 0,
    "message": "Merchant UPI ID not configured"
}
```

---

### **Scenario 2: After Customer Pays (Automatic - No API Call Needed!)**

**What Happens:**
1. Customer scans QR code with UPI app
2. Customer pays the amount
3. Paytm sends webhook to our server (automatic)
4. Our server processes payment
5. Order status updated to "PAID" (automatic)
6. **Driver receives PUSH NOTIFICATION** (automatic)

**Push Notification Received by Driver:**
```json
{
    "title": "✅ Payment Confirmed!",
    "message": "Order #123 payment of ₹450.50 received via UPI. You can now hand over the order to customer.",
    "data": {
        "payment_confirmed": true,
        "order_id": 123,
        "transaction_id": "PAYTM20260311123456",
        "amount": 450.50,
        "payment_mode": "UPI",
        "page_navigation": "order_details",
        "navigation_id": 123
    }
}
```

**What Driver App Should Do:**
1. Show notification to driver
2. Update order UI to show "PAID" status
3. Enable "Hand Over Order" button
4. (Optional) Navigate to order details page

---

### **Scenario 3: Get Static Merchant QR (Optional)**

**When:** For general payments not tied to specific order

**API Endpoint:**
```
GET /api/delivery-boy/merchant-qr
```

**Headers:**
```
Authorization: Bearer {driver_access_token}
```

**Response:**
```json
{
    "status": 1,
    "message": "Static QR code generated successfully",
    "data": {
        "upi_string": "upi://pay?pa=zenfoo@paytm&pn=Zenfoo&cu=INR",
        "merchant_vpa": "zenfoo@paytm",
        "merchant_name": "Zenfoo",
        "qr_type": "static",
        "instructions": [
            "This is a static QR code for your merchant account",
            "Customers can scan and enter any amount",
            "Not linked to specific orders - manual reconciliation needed"
        ]
    }
}
```

---

## Part 4: Complete Flow Diagram

### 🔄 **Driver App Flow:**

```
1. DRIVER ARRIVES AT CUSTOMER
   ↓
2. CUSTOMER WANTS TO PAY VIA QR
   ↓
3. DRIVER APP: Call POST /api/delivery-boy/orders/generate-qr
   Request: { "order_id": 123, "generate_image": true }
   ↓
4. API RESPONSE: QR code data received
   {
     "upi_string": "upi://pay?...",
     "image_svg": "<svg>...</svg>",
     "amount": 450.50
   }
   ↓
5. DRIVER APP: Display QR code on screen
   - Show amount: ₹450.50
   - Show QR code (SVG or Base64)
   - Show instructions: "Ask customer to scan"
   ↓
6. CUSTOMER: Scans QR with UPI app (Paytm/PhonePe/GooglePay)
   ↓
7. CUSTOMER: Confirms payment in their UPI app
   ↓
8. PAYMENT PROCESSED (Paytm network)
   ↓
9. WEBHOOK SENT TO OUR SERVER (< 1 second)
   ↓
10. OUR SERVER: Processes webhook
    - Verifies signature ✅
    - Verifies amount ✅
    - Updates order to "PAID" ✅
    - Stores transaction ✅
    ↓
11. PUSH NOTIFICATION SENT TO DRIVER (automatic)
    ↓
12. DRIVER APP: Receives notification
    {
      "title": "✅ Payment Confirmed!",
      "message": "Order #123 payment received",
      "data": { "payment_confirmed": true }
    }
    ↓
13. DRIVER APP: Show notification toast/alert
    ↓
14. DRIVER APP: Update UI
    - Mark order as "PAID"
    - Show green checkmark ✅
    - Enable "Hand Over Order" button
    ↓
15. DRIVER: Hands over order to customer
    ↓
16. DRIVER: (Optional) Clicks "Mark as Delivered"
    ↓
17. DONE! ✅
```

---

## Part 5: Testing Checklist

### ✅ **Before Testing:**

**Admin Panel:**
- [ ] Paytm Test Credentials configured
- [ ] Paytm Live Credentials configured
- [ ] Environment set to "Test"
- [ ] Merchant UPI ID configured
- [ ] Business Name configured

**Paytm Dashboard:**
- [ ] Webhook URL configured
- [ ] Events selected (Payment Success, Failure, Pending)
- [ ] Webhook verified by Paytm

**Driver App:**
- [ ] API endpoint implemented: POST /generate-qr
- [ ] QR code display implemented (SVG/Base64)
- [ ] Push notification handler implemented
- [ ] Order status update on notification

---

### ✅ **Test 1: Generate QR Code**

1. Driver app calls: `POST /api/delivery-boy/orders/generate-qr`
2. Check response has:
   - ✅ `upi_string`
   - ✅ `image_svg` or `image_base64`
   - ✅ Correct `amount`
3. Display QR code in driver app
4. Verify QR code is scannable

---

### ✅ **Test 2: Make Test Payment**

1. Scan QR code with test UPI app
2. Pay ₹1 (test amount)
3. Check logs: `tail -f storage/logs/laravel.log | grep webhook`
4. Verify:
   - ✅ Webhook received
   - ✅ Payment verified
   - ✅ Order status updated to "PAID"
   - ✅ Transaction stored in database
   - ✅ Push notification sent to driver

---

### ✅ **Test 3: Driver Receives Notification**

1. After payment, check driver app receives notification
2. Verify notification has:
   - ✅ Title: "Payment Confirmed!"
   - ✅ Amount: Correct
   - ✅ Order ID: Correct
3. Tap notification → Should open order details
4. Verify order shows "PAID" status

---

## Part 6: Troubleshooting

### ❌ **Problem: QR code not generating**

**Check:**
1. Merchant UPI ID configured? → Settings → Store Settings
2. Paytm credentials configured?
3. Check logs: `storage/logs/laravel.log`

**Solution:**
```bash
# Check if settings exist
php artisan tinker
>>> App\Models\Setting::where('variable', 'merchant_upi_id')->first()
```

---

### ❌ **Problem: Payment made but order not updating**

**Check:**
1. Webhook URL configured in Paytm?
2. Webhook URL accessible from internet?
3. Check webhook logs: `tail -f storage/logs/laravel.log | grep webhook`

**Debug:**
```bash
# Test webhook endpoint
curl https://yourdomain.com/api/paytm/webhook-status

# Should return: { "status": "OK" }
```

---

### ❌ **Problem: Driver not receiving notification**

**Check:**
1. Driver has FCM token registered?
2. Firebase credentials configured?
3. Check notification logs in `storage/logs/laravel.log`

**Debug:**
```bash
# Search logs for notification
tail -100 storage/logs/laravel.log | grep "notification sent"
```

---

## Part 7: Quick Reference

### 📋 **What You Need from Paytm:**

| Item | Where to Find | Example |
|------|---------------|---------|
| **Merchant UPI ID** | Payment Gateway → QR Code | `zenfoo@paytm` |
| **Test Merchant ID** | Developer → API Keys | `MERCHANT_TEST_12345` |
| **Test Merchant Key** | Developer → API Keys | `abc123xyz...` |
| **Live Merchant ID** | Developer → API Keys | `MERCHANT_LIVE_67890` |
| **Live Merchant Key** | Developer → API Keys | `xyz789abc...` |
| **Webhook URL** | Configure yourself | `https://yourdomain.com/api/paytm/payment-webhook` |

---

### 📋 **Where to Put in Admin Panel:**

| Setting | Location | Section |
|---------|----------|---------|
| **Merchant UPI ID** | Settings → Store Settings | "Merchant UPI / QR Code Settings" |
| **Business Name** | Settings → Store Settings | "Merchant UPI / QR Code Settings" |
| **Test Credentials** | Settings → Store Settings | "Paytm Settings" → Test Credentials |
| **Live Credentials** | Settings → Store Settings | "Paytm Settings" → Live Credentials |
| **Environment** | Settings → Store Settings | "Paytm Settings" → Environment |

---

### 📋 **Driver App API Calls:**

| Action | Endpoint | Method | Auth | Response |
|--------|----------|--------|------|----------|
| **Generate QR** | `/api/delivery-boy/orders/generate-qr` | POST | Yes | QR data with SVG/Base64 |
| **Get Static QR** | `/api/delivery-boy/merchant-qr` | GET | Yes | Static merchant QR |
| **After Payment** | *(No call needed)* | - | - | Push notification auto-sent |

---

## 🎯 **Summary**

### **From Paytm Dashboard → Get:**
1. ✅ Merchant UPI ID (e.g., `zenfoo@paytm`)
2. ✅ Test Merchant ID + Key
3. ✅ Live Merchant ID + Key
4. ✅ Configure Webhook URL

### **In Admin Panel → Configure:**
1. ✅ Paytm Settings (all credentials)
2. ✅ Merchant UPI Settings (UPI ID + Business Name)

### **In Driver App → Implement:**
1. ✅ Call `/generate-qr` API
2. ✅ Display QR code (SVG/Base64)
3. ✅ Handle push notification
4. ✅ Update order UI when payment confirmed

### **Result:**
🎉 **Fully automatic QR payment system with instant verification!**

---

**Need Help?**
- Check logs: `storage/logs/laravel.log`
- Test webhook: `GET /api/paytm/webhook-status`
- Documentation: See `PAYTM_WEBHOOK_SETUP.md`

---

**Status:** ✅ Ready to implement!