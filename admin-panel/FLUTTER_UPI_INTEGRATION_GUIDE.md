# Flutter App - UPI Verification Integration Guide

## Overview
This guide explains how to integrate UPI verification for delivery boys in the Flutter mobile app using Paytm payment gateway.

---

## 📋 Prerequisites

1. **Paytm SDK for Flutter**
   - Add dependency: `paytm_allinonesdk: ^latest_version`
   - Or use HTTP calls to Paytm APIs

2. **API Authentication**
   - Delivery boy must be logged in (auth token required)
   - Store auth token after OTP verification

---

## 🔄 Complete Flow

### **Step 1: Create UPI Input Screen**

Create a new screen `UpiVerificationScreen.dart`:

```dart
import 'package:flutter/material.dart';

class UpiVerificationScreen extends StatefulWidget {
  final int deliveryBoyId;

  const UpiVerificationScreen({Key? key, required this.deliveryBoyId}) : super(key: key);

  @override
  State<UpiVerificationScreen> createState() => _UpiVerificationScreenState();
}

class _UpiVerificationScreenState extends State<UpiVerificationScreen> {
  final TextEditingController _upiController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  // Check if UPI is already verified
  Future<void> _checkVerificationStatus() async {
    // API call to check status
    // GET /api/delivery-boy/upi/status?delivery_boy_id=123
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UPI Verification'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isVerified) ...[
              _buildVerifiedCard(),
            ] else ...[
              _buildVerificationForm(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Your UPI ID',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'We need to verify your UPI ID for payments',
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _upiController,
          decoration: InputDecoration(
            labelText: 'UPI ID',
            hintText: '9876543210@paytm',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payment),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _initiateVerification,
          child: _isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Verify with ₹1 Payment'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 16),
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildVerifiedCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 16),
            Text(
              'UPI Verified Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Show UPI ID, verified date, etc.
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ℹ️ How it works:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. Enter your UPI ID'),
            Text('2. Pay ₹1 via Paytm'),
            Text('3. Your UPI ID will be verified'),
            Text('4. This UPI will be used for future payments'),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateVerification() async {
    // Validate UPI ID format
    String upiId = _upiController.text.trim();
    if (!_validateUpiId(upiId)) {
      _showError('Please enter a valid UPI ID (e.g., 9876543210@paytm)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Generate unique order ID
      String orderId = 'VERIFY_UPI_${widget.deliveryBoyId}_${DateTime.now().millisecondsSinceEpoch}';

      // Step 2: Initiate Paytm payment
      await _initiatePaytmPayment(orderId, upiId);

    } catch (e) {
      _showError('Verification failed: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _validateUpiId(String upiId) {
    // Basic UPI ID validation
    if (upiId.isEmpty) return false;
    if (!upiId.contains('@')) return false;

    List<String> parts = upiId.split('@');
    if (parts.length != 2) return false;
    if (parts[0].length < 3 || parts[1].length < 2) return false;

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
```

---

### **Step 2: Integrate Paytm Payment**

#### **Option A: Using Paytm SDK (Recommended)**

```dart
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';

Future<void> _initiatePaytmPayment(String orderId, String upiId) async {
  try {
    // Get Paytm token from backend
    Map<String, dynamic> tokenResponse = await _getPaytmToken(orderId, 1.00);

    String txnToken = tokenResponse['txnToken'];
    String mid = tokenResponse['mid']; // Merchant ID

    // Configure Paytm
    AllInOneSdk.startTransaction(
      mid,                    // Merchant ID
      orderId,               // Order ID
      "1.00",                // Amount (₹1)
      txnToken,              // Transaction token
      "https://securegw-stage.paytm.in/theia/api/v1/showPaymentPage?mid=$mid&orderId=$orderId",  // Callback URL
      false,                 // isStaging (true for test, false for production)
      false                  // restrictAppInvoke
    ).then((response) {
      _handlePaytmResponse(response, orderId, upiId);
    }).catchError((error) {
      _showError("Payment failed: $error");
      setState(() => _isLoading = false);
    });

  } catch (e) {
    _showError("Failed to initiate payment: $e");
    setState(() => _isLoading = false);
  }
}

// Get transaction token from your backend
Future<Map<String, dynamic>> _getPaytmToken(String orderId, double amount) async {
  // Call your backend API to generate Paytm token
  // This is a server-side operation for security

  final response = await http.post(
    Uri.parse('YOUR_BACKEND_URL/api/paytm/generate-token'),
    headers: {'Authorization': 'Bearer $authToken'},
    body: {
      'order_id': orderId,
      'amount': amount.toString(),
      'delivery_boy_id': widget.deliveryBoyId.toString(),
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['data'];
  } else {
    throw Exception('Failed to generate payment token');
  }
}

void _handlePaytmResponse(dynamic response, String orderId, String upiId) async {
  setState(() => _isLoading = false);

  if (response != null) {
    // Check response status
    String status = response['STATUS'] ?? '';

    if (status == 'TXN_SUCCESS') {
      // Payment successful, now verify with backend
      await _verifyWithBackend(orderId, upiId);
    } else {
      _showError('Payment failed: ${response['RESPMSG'] ?? 'Unknown error'}');
    }
  } else {
    _showError('Payment cancelled or failed');
  }
}
```

#### **Option B: Using HTTP Calls (Alternative)**

If not using Paytm SDK, you can use WebView or browser to complete payment, then verify using the order ID.

---

### **Step 3: Verify with Backend**

```dart
Future<void> _verifyWithBackend(String paytmOrderId, String upiId) async {
  try {
    final response = await http.post(
      Uri.parse('YOUR_API_URL/api/delivery-boy/upi/verify'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'delivery_boy_id': widget.deliveryBoyId,
        'upi_id': upiId,
        'paytm_order_id': paytmOrderId,
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == true || data['status'] == 1) {
        // Success!
        setState(() => _isVerified = true);
        _showSuccess('UPI verified successfully!');

        // Navigate back or update UI
        Navigator.pop(context, true);
      } else {
        _showError(data['message'] ?? 'Verification failed');
      }
    } else {
      _showError('Server error: ${response.statusCode}');
    }

  } catch (e) {
    _showError('Network error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

void _showSuccess(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.green),
  );
}
```

---

### **Step 4: Check Verification Status (On App Launch)**

```dart
Future<void> _checkVerificationStatus() async {
  try {
    final response = await http.get(
      Uri.parse('YOUR_API_URL/api/delivery-boy/upi/status?delivery_boy_id=${widget.deliveryBoyId}'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == true && data['data'] != null) {
        setState(() {
          _isVerified = data['data']['is_verified'] ?? false;
          if (_isVerified) {
            _upiController.text = data['data']['upi_id'] ?? '';
          }
        });
      }
    }
  } catch (e) {
    print('Error checking verification status: $e');
  }
}
```

---

## 📡 API Endpoints

### 1. **Verify UPI**
```
POST /api/delivery-boy/upi/verify
Headers: Authorization: Bearer {token}
Body:
{
  "delivery_boy_id": 123,
  "upi_id": "9876543210@paytm",
  "paytm_order_id": "VERIFY_UPI_123_1234567890"
}

Response:
{
  "status": true,
  "data": {
    "message": "UPI ID verified successfully",
    "delivery_boy": {...},
    "verification_details": {
      "upi_id": "9876543210@paytm",
      "verified_at": "2024-03-06 12:30:00",
      "transaction_id": "20240306123456789",
      "amount_paid": 1.00
    }
  }
}
```

### 2. **Get Verification Status**
```
GET /api/delivery-boy/upi/status?delivery_boy_id=123
Headers: Authorization: Bearer {token}

Response:
{
  "status": true,
  "data": {
    "is_verified": true,
    "upi_id": "9876543210@paytm",
    "verified_at": "2024-03-06 12:30:00",
    "payment_mode": "UPI",
    "verification_transaction_id": "20240306123456789"
  }
}
```

### 3. **Re-verify UPI** (Change UPI ID)
```
POST /api/delivery-boy/upi/re-verify
Headers: Authorization: Bearer {token}
Body:
{
  "delivery_boy_id": 123,
  "new_upi_id": "newupi@paytm",
  "paytm_order_id": "VERIFY_UPI_123_9876543210"
}
```

---

## 🔐 Security Considerations

1. **Never store Paytm credentials in Flutter app**
   - Always get transaction tokens from backend
   - Backend generates tokens using stored Paytm credentials

2. **Validate on backend**
   - Flutter app only submits order ID
   - Backend verifies actual payment with Paytm API

3. **Use HTTPS**
   - All API calls must use HTTPS

4. **Auth token required**
   - All endpoints require valid auth token

---

## 🧪 Testing

### Test UPI IDs (Paytm Staging):
- `success@paytm` - Always successful
- `failure@paytm` - Always fails
- Use your actual UPI ID in production

### Test Flow:
1. Enter test UPI ID
2. Click "Verify with ₹1 Payment"
3. Complete payment in Paytm sandbox
4. Check if status updates to "Verified"

---

## 📱 UI/UX Best Practices

1. **Show clear instructions**
   - Explain why UPI verification is needed
   - Show example UPI ID format

2. **Validation feedback**
   - Real-time UPI ID format validation
   - Clear error messages

3. **Loading states**
   - Show loading during payment
   - Show loading during backend verification

4. **Success confirmation**
   - Show success message with checkmark
   - Display verified UPI ID

5. **Re-verification option**
   - Allow changing UPI ID if needed
   - Confirm before re-verification

---

## 🐛 Common Issues

### Issue: Payment successful but verification fails
**Solution:** Check backend logs, ensure Paytm credentials are correct

### Issue: "Invalid UPI ID format"
**Solution:** Ensure format is `username@provider` (e.g., `9876543210@paytm`)

### Issue: "UPI ID already verified with another delivery boy"
**Solution:** Each UPI ID can only be used once

### Issue: Payment mode not UPI
**Solution:** Ensure payment is made via UPI, not card/netbanking

---

## 📞 Support

For issues, contact:
- Backend Team: backend@zenfoo.com
- Flutter Team: mobile@zenfoo.com

---

## ✅ Checklist

Before deploying:
- [ ] Paytm credentials configured in admin panel (StoreSettings)
- [ ] Test in staging environment first
- [ ] Switch Paytm environment to 'live' for production
- [ ] Test with real ₹1 payment
- [ ] Verify backend logging is working
- [ ] Test re-verification flow
- [ ] Test error scenarios