# Paytm/UPI QR Code Payment System for Delivery Boys

## Overview

This feature enables delivery boys to show UPI QR codes to customers for direct payment via Paytm or any UPI app (PhonePe, GooglePay, BHIM, etc.). When a customer scans the QR code, the payment amount is pre-filled, making the payment process seamless.

## Implementation Date
**2026-03-11**

## How It Works

### Flow:
1. **Delivery boy arrives at customer location**
2. **Delivery boy opens the order in the app**
3. **App generates a dynamic QR code** with order amount pre-filled
4. **Customer scans QR code** using any UPI app
5. **Customer confirms payment** (amount already filled)
6. **Payment goes directly to Zenfoo's merchant account**
7. **Delivery boy verifies payment and completes delivery**

### QR Code Types:

#### 1. **Dynamic Order QR Code** (Recommended)
- Generated per order
- Amount pre-filled
- Order ID embedded for tracking
- Better reconciliation
- **Endpoint**: `POST /api/delivery-boy/orders/generate-qr`

#### 2. **Static Merchant QR Code**
- One QR for all orders
- Customer enters amount manually
- Less tracking, more flexibility
- **Endpoint**: `GET /api/delivery-boy/merchant-qr`

---

## Components Implemented

### 1. **Backend Service**
**File**: `app/Services/PaytmQRCodeService.php`

**Key Methods**:
- `generateOrderQRCode(Order $order, array $options)` - Generate dynamic QR for specific order
- `getMerchantStaticQR()` - Get static merchant QR code
- `validateOrderForQR(Order $order)` - Validate if QR can be generated
- `getMerchantDetails()` - Get UPI VPA and merchant info
- `generateUPIString()` - Create UPI payment URL

### 2. **API Endpoints**
**File**: `app/Http/Controllers/API/DeliveryBoy/OrderController.php`

**Routes** (in `routes/api.php`):
```php
// Dynamic QR for specific order
POST /api/delivery-boy/orders/generate-qr
{
    "order_id": 123,
    "generate_image": false  // Optional: set true to generate base64 image
}

// Static merchant QR
GET /api/delivery-boy/merchant-qr
```

### 3. **Database Migration**
**File**: `database/migrations/2026_03_11_113853_add_merchant_upi_settings_to_settings_table.php`

**Settings Added**:
- `merchant_upi_id` - Merchant's UPI ID/VPA (e.g., `zenfoo@paytm`)
- `business_name` - Business name shown on QR (e.g., `Zenfoo`)

### 4. **Admin Panel UI**
**File**: `resources/js/views/Setting/StoreSettings.vue`

**New Section**: "Merchant UPI / QR Code Settings"
- Configure merchant UPI ID
- Set business name
- Instructions on how to get UPI ID from Paytm

---

## Setup Instructions

### Step 1: Get Your Merchant UPI ID from Paytm

1. Login to **Paytm Business Dashboard**: https://dashboard.paytm.com/
2. Navigate to: **Payment Gateway** → **QR Code**
3. Look for **"VPA"** or **"UPI ID"** field
4. Your UPI ID will be something like: `merchantid@paytm` or `yourmerchantid@paytm`
5. Copy this UPI ID

### Step 2: Configure in Admin Panel

1. Go to: **Settings** → **Store Settings**
2. Find: **"Merchant UPI / QR Code Settings"** section
3. Enter:
   - **Merchant UPI ID**: Your UPI ID from step 1 (e.g., `zenfoo@paytm`)
   - **Business Name**: Your business name (e.g., `Zenfoo`)
4. Click **Save**

### Step 3: Test the QR Code

Use the test endpoint or mobile app to generate a QR code and verify:
```bash
curl -X POST http://your-domain.com/api/delivery-boy/orders/generate-qr \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order_id": 123}'
```

**Expected Response**:
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

## Mobile App Integration

### For Flutter/React Native/Android/iOS:

1. **Call the API** when delivery boy is ready to collect payment:
```dart
// Flutter example
Future<void> generateQRCode(int orderId) async {
  final response = await http.post(
    Uri.parse('$apiUrl/api/delivery-boy/orders/generate-qr'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'order_id': orderId}),
  );

  final data = jsonDecode(response.body);
  if (data['status'] == 1) {
    String upiString = data['data']['upi_string'];
    // Generate QR code from upiString using a QR library
    displayQRCode(upiString);
  }
}
```

2. **Generate QR Image** from UPI string using native QR library:
   - **Flutter**: Use `qr_flutter` package
   - **React Native**: Use `react-native-qrcode-svg`
   - **Android**: Use `ZXing` library
   - **iOS**: Use `CoreImage` QR generator

3. **Display QR Code** to customer with:
   - Amount clearly visible
   - Business name
   - "Scan to Pay" instruction

4. **Payment Verification**:
   - After customer pays, they'll show payment success screenshot
   - Delivery boy can verify transaction ID
   - Mark order as delivered

---

## UPI String Format

The generated UPI string follows **NPCI UPI Deep Linking Specification**:

```
upi://pay?pa=<VPA>&pn=<NAME>&am=<AMOUNT>&tr=<REF>&tn=<NOTE>&cu=INR
```

**Parameters**:
- `pa` (Payee Address): Merchant's UPI ID (e.g., `zenfoo@paytm`)
- `pn` (Payee Name): Business name (e.g., `Zenfoo`)
- `am` (Amount): Order total amount (e.g., `450.50`)
- `tr` (Transaction Reference): Order ID (e.g., `123`)
- `tn` (Transaction Note): Order description (e.g., `Order #123 - Zenfoo`)
- `cu` (Currency): Always `INR`

**Compatible Apps**: Paytm, PhonePe, GooglePay, BHIM, Amazon Pay, WhatsApp, and all UPI apps

---

## Optional: Server-Side QR Image Generation

If you want to generate QR images on the server (instead of mobile app), install the QR code library:

```bash
composer require simplesoftwareio/simple-qrcode
```

Then call the API with `generate_image: true`:

```json
{
    "order_id": 123,
    "generate_image": true
}
```

**Response** will include:
```json
{
    "data": {
        ...
        "qr_image_base64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
    }
}
```

Display this base64 image directly in your app.

---

## Security Considerations

### ✅ What's Secure:
- UPI ID is public information (like bank account for UPI)
- Amount is pre-filled (prevents customer from changing it)
- Transaction reference includes order ID for tracking
- All UPI payments are authenticated by customer's bank

### ⚠️ Important Notes:
- **Payment verification is manual**: Delivery boy should verify customer paid before completing delivery
- **No automatic order update**: Payment doesn't automatically mark order as paid (manual reconciliation needed)
- **Customer can cancel**: Like any UPI payment, customer can cancel before confirming

### 🔐 Recommendations:
1. **For automated payment tracking**, integrate Paytm Payment Gateway webhook notifications
2. **Train delivery boys** to verify payment before handing over order
3. **Regular reconciliation** of UPI payments with order database

---

## Troubleshooting

### Issue: "Paytm merchant ID not configured"
**Solution**:
1. Go to Admin Panel → Settings → Store Settings
2. Configure Paytm credentials in "Paytm Settings" section
3. Save settings

### Issue: "Merchant UPI ID not configured"
**Solution**:
1. Get your UPI ID from Paytm Business Dashboard
2. Configure it in "Merchant UPI / QR Code Settings" section
3. Save settings

### Issue: QR code not scanning
**Solution**:
1. Verify UPI ID is correct (test by sending small payment manually)
2. Ensure QR code size is adequate (minimum 200x200 pixels)
3. Check lighting conditions when scanning
4. Try different UPI apps

### Issue: Customer paid wrong amount
**Prevention**:
1. Always use **dynamic QR codes** (not static)
2. Show amount clearly on delivery boy's screen
3. Verify payment screenshot shows correct amount

---

## API Reference

### Generate Order QR Code

**Endpoint**: `POST /api/delivery-boy/orders/generate-qr`

**Headers**:
```
Authorization: Bearer {delivery_boy_token}
Content-Type: application/json
```

**Request Body**:
```json
{
    "order_id": 123,
    "generate_image": false  // Optional: true to get base64 image
}
```

**Success Response** (200):
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
        "qr_type": "upi"
    }
}
```

**Error Responses**:
- `400`: Order already paid, cancelled, or invalid
- `403`: Delivery boy not assigned to this order
- `404`: Order not found
- `500`: Configuration error or system error

---

### Get Static Merchant QR

**Endpoint**: `GET /api/delivery-boy/merchant-qr`

**Headers**:
```
Authorization: Bearer {delivery_boy_token}
```

**Success Response** (200):
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

## Testing Checklist

- [ ] Migration ran successfully
- [ ] Admin panel settings page loads
- [ ] Can save merchant UPI ID and business name
- [ ] API returns valid UPI string for order QR
- [ ] UPI string format is correct
- [ ] Amount is correctly formatted (2 decimals)
- [ ] QR code scans successfully in Paytm app
- [ ] QR code scans successfully in PhonePe app
- [ ] QR code scans successfully in GooglePay app
- [ ] Static QR code endpoint works
- [ ] Validation prevents QR for paid/cancelled orders
- [ ] Validation prevents QR for unassigned orders
- [ ] Error handling works correctly

---

## Future Enhancements

### 1. **Payment Webhook Integration**
Integrate Paytm's webhook to automatically verify and update order status when customer pays.

### 2. **Payment Screenshot Upload**
Allow delivery boys to upload customer's payment screenshot for proof.

### 3. **Auto-reconciliation**
Match UPI transaction IDs with order IDs automatically.

### 4. **QR Code Analytics**
Track how many QR codes generated, scan rate, payment success rate.

### 5. **Multiple Payment Options**
Add support for other payment gateways (Razorpay QR, PhonePe QR, etc.)

---

## Support

For issues or questions:
1. Check this documentation first
2. Review the code comments in the service files
3. Check Laravel logs: `storage/logs/laravel.log`
4. Contact development team

---

## Credits

**Implemented by**: Claude AI Assistant
**Date**: 2026-03-11
**Version**: 1.0
**Framework**: Laravel 8.x
**UPI Specification**: NPCI UPI Deep Linking v1.0