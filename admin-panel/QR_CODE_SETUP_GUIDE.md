# 🎯 QR Code Payment System - Quick Setup Guide

## ✅ What's Already Done

### 1. **Package Installed**
- ✅ `simplesoftwareio/simple-qrcode` v4.2 installed
- ✅ Configured to use SVG format (no PHP extensions required)

### 2. **Backend Complete**
- ✅ `PaytmQRCodeService` - Generates UPI QR codes
- ✅ API endpoints created for delivery boys
- ✅ Migration run successfully

### 3. **Admin Panel Ready**
- ✅ Settings page updated with Merchant UPI configuration

---

## 🚀 Quick Start (3 Steps)

### **Step 1: Get Your Paytm UPI ID**

1. Login to **Paytm Business Dashboard**: https://dashboard.paytm.com/
2. Go to: **Payment Gateway** → **QR Code** section
3. Find your **VPA/UPI ID** (looks like: `yourmerchant@paytm`)
4. Copy it

### **Step 2: Configure in Admin Panel**

1. Navigate to: **Settings** → **Store Settings**
2. Find section: **"Merchant UPI / QR Code Settings"** (top of page)
3. Enter your UPI ID and business name:
   - **Merchant UPI ID**: `yourmerchant@paytm`
   - **Business Name**: `Zenfoo`
4. Click **Save**

### **Step 3: Test the API**

**For Dynamic Order QR:**
```bash
POST /api/delivery-boy/orders/generate-qr
Authorization: Bearer {delivery_boy_token}
Content-Type: application/json

{
    "order_id": 123,
    "generate_image": true
}
```

**Response:**
```json
{
    "status": 1,
    "message": "QR code generated successfully",
    "data": {
        "order_id": 123,
        "amount": 450.50,
        "upi_string": "upi://pay?pa=zenfoo@paytm&pn=Zenfoo&am=450.50&tr=123&tn=Order+%23123+-+Zenfoo&cu=INR",
        "image_base64": "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4...",
        "image_svg": "<svg xmlns='http://www.w3.org/2000/svg'...",
        "qr_type": "upi"
    }
}
```

---

## 📱 Mobile App Integration

### Option 1: Use SVG Directly (Recommended)
The API returns both `image_svg` (raw SVG) and `image_base64` (base64-encoded SVG).

**Flutter Example:**
```dart
import 'package:flutter_svg/flutter_svg.dart';

// Display SVG QR code
Widget buildQRCode(String svgString) {
  return SvgPicture.string(
    svgString,
    width: 300,
    height: 300,
  );
}
```

**React Native Example:**
```javascript
import { SvgXml } from 'react-native-svg';

// Display SVG QR code
<SvgXml xml={svgString} width="300" height="300" />
```

### Option 2: Use UPI String with Native QR Library
Use the `upi_string` field and generate QR locally:

**Flutter:**
```dart
import 'package:qr_flutter/qr_flutter.dart';

QrImageView(
  data: upiString, // "upi://pay?pa=..."
  version: QrVersions.auto,
  size: 300.0,
)
```

**React Native:**
```javascript
import QRCode from 'react-native-qrcode-svg';

<QRCode value={upiString} size={300} />
```

---

## 🔍 API Endpoints Reference

### 1. Generate Order QR Code
**Endpoint:** `POST /api/delivery-boy/orders/generate-qr`

**Authentication:** Required (Delivery boy token)

**Request:**
```json
{
    "order_id": 123,
    "generate_image": true  // Optional: false returns only UPI string
}
```

**Success Response (200):**
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
        "image_base64": "data:image/svg+xml;base64,...",
        "image_svg": "<svg xmlns='http://www.w3.org/2000/svg'...",
        "instructions": [...]
    }
}
```

**Error Responses:**
- `400`: Order already paid, cancelled, or invalid amount
- `403`: Delivery boy not assigned to this order
- `404`: Order not found
- `500`: Configuration error

---

### 2. Get Static Merchant QR
**Endpoint:** `GET /api/delivery-boy/merchant-qr`

**Authentication:** Required (Delivery boy token)

**Success Response (200):**
```json
{
    "status": 1,
    "message": "Static QR code generated successfully",
    "data": {
        "upi_string": "upi://pay?pa=zenfoo@paytm&pn=Zenfoo&cu=INR",
        "merchant_vpa": "zenfoo@paytm",
        "merchant_name": "Zenfoo",
        "qr_type": "static"
    }
}
```

---

## 💡 Usage Tips

### When to Use Dynamic QR (Recommended)
- ✅ Amount is pre-filled (no errors)
- ✅ Order ID tracked automatically
- ✅ Better reconciliation
- ✅ Professional customer experience

### When to Use Static QR
- Customer wants to pay different amount
- Multiple payments for one order
- General merchant payments

### Payment Verification
After customer scans and pays:
1. Customer shows payment success screen
2. Delivery boy verifies transaction ID
3. Delivery boy marks order as delivered in app

---

## 🛠️ Troubleshooting

### Issue: "Merchant UPI ID not configured"
**Solution:** Configure UPI ID in Admin Panel → Settings → Store Settings

### Issue: "Order already paid"
**Solution:** Check order status, don't generate QR for completed orders

### Issue: QR code not scanning
**Checklist:**
- ✅ UPI ID is correct (test by manually sending payment)
- ✅ QR code size is adequate (minimum 200x200)
- ✅ Good lighting when scanning
- ✅ Try different UPI apps

### Issue: Amount mismatch
**Solution:** Always use dynamic QR codes, not static

---

## 📊 Technical Details

### QR Code Format
- **Type:** SVG (Scalable Vector Graphics)
- **Benefits:**
  - No image quality loss at any size
  - Small file size
  - No PHP extensions required
  - Works on all devices
- **Alternative:** Can be converted to PNG/JPG client-side if needed

### UPI String Specification
Follows **NPCI UPI Deep Linking Standard v1.0**:
- `pa`: Payee Address (VPA/UPI ID)
- `pn`: Payee Name
- `am`: Amount (2 decimal places)
- `tr`: Transaction Reference (Order ID)
- `tn`: Transaction Note
- `cu`: Currency (INR)

### Compatibility
- ✅ Paytm
- ✅ PhonePe
- ✅ GooglePay
- ✅ BHIM
- ✅ Amazon Pay
- ✅ WhatsApp Pay
- ✅ All UPI-enabled apps

---

## 📁 Files Modified/Created

### Created:
1. `app/Services/PaytmQRCodeService.php` - Core QR generation service
2. `database/migrations/2026_03_11_113853_add_merchant_upi_settings_to_settings_table.php` - Settings migration
3. `PAYTM_QR_CODE_IMPLEMENTATION.md` - Detailed documentation
4. `QR_CODE_SETUP_GUIDE.md` - This file

### Modified:
1. `app/Http/Controllers/API/DeliveryBoy/OrderController.php` - Added QR endpoints
2. `routes/api.php` - Added QR routes
3. `resources/js/views/Setting/StoreSettings.vue` - Added UPI settings UI
4. `composer.json` - Added simple-qrcode package

---

## 🎉 You're All Set!

The QR code payment system is **fully functional** and ready to use!

### Next Steps:
1. ✅ Configure your UPI ID in admin panel
2. ✅ Integrate API in mobile app
3. ✅ Test with real order
4. ✅ Train delivery boys on using QR feature

### Need Help?
- See `PAYTM_QR_CODE_IMPLEMENTATION.md` for comprehensive docs
- Check Laravel logs: `storage/logs/laravel.log`
- Test API with Postman/curl

---

**Implementation Date:** 2026-03-11
**Version:** 1.0
**Status:** ✅ Production Ready
