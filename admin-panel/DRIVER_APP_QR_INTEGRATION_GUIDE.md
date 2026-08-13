# 📱 Driver App - QR Code Payment Integration Guide

## 🎯 Overview

This guide is for the **Delivery Boy Mobile App** developer to implement QR code payment functionality where drivers can show QR codes to customers for instant UPI payment collection.

---

## 🔄 Complete Flow

```
1. Driver reaches customer location with order
2. Driver opens order in app
3. Driver clicks "Show QR Code" button
4. App calls API to generate QR code
5. App displays QR code on screen
6. Customer scans QR with any UPI app (Google Pay, PhonePe, Paytm, etc.)
7. Customer completes payment
8. Paytm sends webhook to server (automatic)
9. Server updates order payment_status = "paid"
10. Driver receives Firebase notification: "✅ Payment Confirmed!"
11. App shows "Payment Received" message
12. Driver hands over order to customer
13. Driver takes delivery photos
14. Driver clicks "Mark as Delivered" button
15. Order completed ✅
```

---

## 📡 API Endpoint

### **Generate QR Code for Order**

**Endpoint**: `POST /api/delivery-boy/orders/generate-qr`

**Authentication**: Required (Bearer Token)

**Headers**:
```
Authorization: Bearer {driver_access_token}
Content-Type: application/json
Accept: application/json
```

**Request Body**:
```json
{
    "order_id": 123
}
```

**Success Response (200)**:
```json
{
    "status": 1,
    "message": "QR code generated successfully",
    "data": {
        "order_id": 123,
        "amount": 450.50,
        "currency": "INR",
        "qr_code_id": "QR1234567890",
        "qr_code_string": "upi://pay?pa=paytm-xxx@paytm&pn=Zenfoo&am=450.50&tr=123&tn=Order%20123&cu=INR",
        "qr_image_base64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAA...",
        "qr_type": "paytm_dynamic",
        "payment_gateway": "paytm",
        "instructions": [
            "Ask customer to scan QR code using any UPI app",
            "Payment will go to Paytm Payment Gateway account",
            "You will receive notification when payment is confirmed",
            "Order will be automatically marked as paid"
        ]
    }
}
```

**Error Response (400/401/500)**:
```json
{
    "status": 0,
    "message": "Error message here",
    "error": "Detailed error description"
}
```

**Possible Errors**:
- `401`: Unauthorized - Invalid/expired token
- `400`: Order not found or already paid
- `500`: Paytm API error or server error

---

## 💻 Implementation Examples

### **Flutter Implementation**

#### 1. **API Call to Generate QR**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class QRCodeService {
  static const String baseUrl = 'https://wheat-rook-708688.hostingersite.com';

  Future<Map<String, dynamic>> generateOrderQR(int orderId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/delivery-boy/orders/generate-qr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'order_id': orderId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate QR code');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

#### 2. **Display QR Code Screen**

```dart
import 'package:flutter/material.dart';
import 'dart:convert';

class QRCodeDisplayScreen extends StatefulWidget {
  final int orderId;
  final String token;

  const QRCodeDisplayScreen({
    required this.orderId,
    required this.token,
  });

  @override
  _QRCodeDisplayScreenState createState() => _QRCodeDisplayScreenState();
}

class _QRCodeDisplayScreenState extends State<QRCodeDisplayScreen> {
  bool isLoading = true;
  String? qrImageBase64;
  double? amount;
  String? errorMessage;
  bool paymentConfirmed = false;

  @override
  void initState() {
    super.initState();
    generateQRCode();
    listenForPaymentNotification();
  }

  Future<void> generateQRCode() async {
    try {
      final qrService = QRCodeService();
      final result = await qrService.generateOrderQR(
        widget.orderId,
        widget.token,
      );

      if (result['status'] == 1) {
        setState(() {
          qrImageBase64 = result['data']['qr_image_base64'];
          amount = result['data']['amount'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to generate QR code: $e';
        isLoading = false;
      });
    }
  }

  void listenForPaymentNotification() {
    // Listen to Firebase notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['payment_confirmed'] == true ||
          message.data['payment_confirmed'] == 'true') {
        setState(() {
          paymentConfirmed = true;
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('✅ Payment Received!'),
            content: Text('Payment of ₹$amount has been confirmed.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close QR screen
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collect Payment'),
        backgroundColor: paymentConfirmed ? Colors.green : Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(errorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Amount display
                        Text(
                          'Amount to Collect',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '₹${amount?.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 32),

                        // Payment status
                        if (paymentConfirmed)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 32),
                                SizedBox(width: 12),
                                Text(
                                  'Payment Received!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Waiting for payment...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 32),

                        // QR Code Image
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.memory(
                            base64Decode(
                              qrImageBase64!.split(',')[1], // Remove data:image/png;base64, prefix
                            ),
                            width: 300,
                            height: 300,
                          ),
                        ),

                        SizedBox(height: 24),

                        // Instructions
                        Text(
                          'Ask customer to scan this QR code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Using any UPI app (Google Pay, PhonePe, Paytm)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 32),

                        // Close button (only show when payment confirmed)
                        if (paymentConfirmed)
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                            ),
                            child: Text(
                              'Continue to Delivery',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
```

#### 3. **Firebase Notification Handler**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received notification: ${message.data}');

      // Check if it's a payment confirmation
      if (message.data['payment_confirmed'] == true ||
          message.data['payment_confirmed'] == 'true') {

        // Handle payment confirmation
        handlePaymentConfirmation(message);
      }
    });

    // Handle notification tap (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
      // Navigate to order details
      if (message.data['navigationId'] != null) {
        // Navigate to order screen
        navigateToOrder(message.data['navigationId']);
      }
    });
  }

  void handlePaymentConfirmation(RemoteMessage message) {
    // Show local notification or update UI
    print('Payment confirmed!');
    print('Transaction ID: ${message.data['transaction_id']}');
    print('Amount: ${message.data['amount']}');

    // You can use EventBus or Provider to update QR screen
    // eventBus.fire(PaymentConfirmedEvent(message.data));
  }

  void navigateToOrder(String orderId) {
    // Navigate to order details screen
    // Navigator.push(...);
  }
}
```

---

### **React Native Implementation**

#### 1. **API Call to Generate QR**

```javascript
import axios from 'axios';

const BASE_URL = 'https://wheat-rook-708688.hostingersite.com';

export const generateOrderQR = async (orderId, token) => {
  try {
    const response = await axios.post(
      `${BASE_URL}/api/delivery-boy/orders/generate-qr`,
      {
        order_id: orderId,
      },
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      }
    );

    return response.data;
  } catch (error) {
    throw new Error(error.response?.data?.message || 'Failed to generate QR code');
  }
};
```

#### 2. **QR Code Display Component**

```javascript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  Image,
  ActivityIndicator,
  StyleSheet,
  Alert,
} from 'react-native';
import messaging from '@react-native-firebase/messaging';
import { generateOrderQR } from './api';

const QRCodeScreen = ({ route, navigation }) => {
  const { orderId, token } = route.params;
  const [loading, setLoading] = useState(true);
  const [qrData, setQrData] = useState(null);
  const [error, setError] = useState(null);
  const [paymentConfirmed, setPaymentConfirmed] = useState(false);

  useEffect(() => {
    fetchQRCode();
    setupNotificationListener();
  }, []);

  const fetchQRCode = async () => {
    try {
      const result = await generateOrderQR(orderId, token);
      if (result.status === 1) {
        setQrData(result.data);
      } else {
        setError(result.message);
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const setupNotificationListener = () => {
    // Listen for foreground messages
    const unsubscribe = messaging().onMessage(async remoteMessage => {
      console.log('Notification received:', remoteMessage);

      if (remoteMessage.data?.payment_confirmed === 'true') {
        setPaymentConfirmed(true);
        Alert.alert(
          '✅ Payment Received!',
          `Payment of ₹${qrData?.amount} has been confirmed.`,
          [
            {
              text: 'OK',
              onPress: () => navigation.goBack(),
            },
          ]
        );
      }
    });

    return unsubscribe;
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Generating QR Code...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>{error}</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.amountLabel}>Amount to Collect</Text>
      <Text style={styles.amount}>₹{qrData?.amount?.toFixed(2)}</Text>

      {paymentConfirmed ? (
        <View style={styles.successBadge}>
          <Text style={styles.successText}>✅ Payment Received!</Text>
        </View>
      ) : (
        <View style={styles.waitingBadge}>
          <ActivityIndicator size="small" color="#FF9500" />
          <Text style={styles.waitingText}>Waiting for payment...</Text>
        </View>
      )}

      <View style={styles.qrContainer}>
        <Image
          source={{ uri: qrData?.qr_image_base64 }}
          style={styles.qrImage}
        />
      </View>

      <Text style={styles.instruction}>
        Ask customer to scan this QR code
      </Text>
      <Text style={styles.subInstruction}>
        Using any UPI app (Google Pay, PhonePe, Paytm)
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    backgroundColor: '#F5F5F5',
    alignItems: 'center',
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  amountLabel: {
    fontSize: 18,
    color: '#666',
    marginTop: 20,
  },
  amount: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#4CAF50',
    marginVertical: 8,
  },
  successBadge: {
    backgroundColor: '#E8F5E9',
    padding: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#4CAF50',
    marginVertical: 16,
  },
  successText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#4CAF50',
  },
  waitingBadge: {
    backgroundColor: '#FFF3E0',
    padding: 16,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 16,
  },
  waitingText: {
    fontSize: 16,
    color: '#F57C00',
    marginLeft: 12,
  },
  qrContainer: {
    backgroundColor: '#FFF',
    padding: 16,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 5,
    marginVertical: 24,
  },
  qrImage: {
    width: 300,
    height: 300,
  },
  instruction: {
    fontSize: 16,
    fontWeight: '500',
    textAlign: 'center',
    marginTop: 16,
  },
  subInstruction: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    marginTop: 8,
  },
  errorText: {
    fontSize: 16,
    color: '#F44336',
    textAlign: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#666',
  },
});

export default QRCodeScreen;
```

---

## 🔔 Firebase Notification Format

### **Notification Payload**

When payment is confirmed, driver will receive this notification:

```json
{
  "notification": {
    "title": "✅ Payment Confirmed!",
    "body": "Order #123 payment of ₹450.50 received via UPI. You can now hand over the order to customer."
  },
  "data": {
    "payment_confirmed": "true",
    "transaction_id": "PAYTM20260311123456",
    "amount": "450.50",
    "payment_mode": "UPI",
    "pageNavigation": "order_details",
    "navigationId": "123"
  }
}
```

### **How to Handle**

```dart
// Flutter
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.data['payment_confirmed'] == 'true') {
    // Payment confirmed - close QR screen, show success
    showPaymentSuccessDialog();
  }
});
```

```javascript
// React Native
messaging().onMessage(async remoteMessage => {
  if (remoteMessage.data?.payment_confirmed === 'true') {
    // Payment confirmed - close QR screen, show success
    showPaymentSuccessDialog();
  }
});
```

---

## 🎨 UI/UX Recommendations

### **QR Code Screen Should Show**:

1. ✅ **Amount to collect** - Large, prominent display
2. ✅ **QR code image** - Clear, centered, 300x300 pixels minimum
3. ✅ **Payment status** - "Waiting for payment..." or "Payment Received!"
4. ✅ **Instructions** - "Ask customer to scan with any UPI app"
5. ✅ **Loading state** - Show spinner while generating QR
6. ✅ **Error handling** - Show error if QR generation fails

### **User Flow**:

```
Order Details Screen
       ↓
[Show QR Code] button
       ↓
QR Code Screen (loading)
       ↓
QR Code Screen (displaying QR + waiting)
       ↓
← Notification received →
       ↓
QR Code Screen (payment confirmed!)
       ↓
Auto-close or [Continue] button
       ↓
Back to Order Details
```

---

## ✅ Testing Checklist

### **For App Developer**:

- [ ] API call works with valid token
- [ ] QR code image displays correctly
- [ ] Amount displays correctly
- [ ] Loading state shows while generating
- [ ] Error handling works (invalid order, network error)
- [ ] Notification received when payment confirmed
- [ ] Screen updates when notification received
- [ ] Can navigate back to order details
- [ ] Works on both Android and iOS
- [ ] Works with Firebase Cloud Messaging

---

## 🚨 Error Handling

### **Common Errors**:

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid/expired token | Refresh auth token and retry |
| 400 Order not found | Invalid order ID | Verify order exists |
| 400 Order already paid | Payment already received | Show message and close screen |
| 500 Server error | Paytm API or server issue | Show error, allow retry |
| Network timeout | Poor connection | Show error, allow retry |

### **Error Handling Example**:

```dart
try {
  final result = await generateOrderQR(orderId, token);
  // Handle success
} on UnauthorizedException {
  // Refresh token and retry
  await refreshAuthToken();
  return generateOrderQR(orderId, token);
} on NotFoundException {
  // Order not found
  showError('Order not found');
} on ServerException {
  // Server error
  showError('Server error. Please try again.');
} catch (e) {
  // Generic error
  showError('Failed to generate QR code');
}
```

---

## 📊 Important Notes

### **Payment Confirmation**:
- ✅ Payment is confirmed **automatically** via webhook
- ✅ Driver receives **Firebase notification** when payment received
- ✅ Order `payment_status` is updated to "paid"
- ❌ Order is **NOT** marked as delivered yet

### **After Payment Confirmed**:
Driver must still:
1. Hand over order to customer
2. Take delivery photos
3. Click "Mark as Delivered" button
4. This triggers delivery completion logic

### **Two Separate Actions**:
1. **Payment** (automatic via QR + webhook)
2. **Delivery** (manual by driver with photos)

---

## 🔧 Backend Details (For Reference)

### **Base URL**:
- Production: `https://wheat-rook-708688.hostingersite.com`

### **Webhook URL** (configured in Paytm):
- `https://wheat-rook-708688.hostingersite.com/api/paytm/callback`

### **Money Flow**:
```
Customer pays → Paytm PG Account → Webhook sent → Order updated → Settlement to bank (T+1/T+2)
```

---

## 📞 Support

If you encounter any issues:
1. Check API response for error messages
2. Check Laravel logs: `storage/logs/laravel.log`
3. Verify Firebase notification setup
4. Test with staging credentials first
5. Contact backend team with error logs

---

## 🎉 Summary

### **What App Developer Needs to Do**:

1. ✅ Add "Show QR Code" button on order details screen
2. ✅ Call `/api/delivery-boy/orders/generate-qr` API
3. ✅ Display QR code image from base64 response
4. ✅ Show amount and instructions
5. ✅ Listen for Firebase notification
6. ✅ Update UI when payment confirmed
7. ✅ Handle errors gracefully
8. ✅ Test end-to-end flow

### **What Backend Already Handles**:

1. ✅ QR code generation via Paytm API
2. ✅ Payment verification via webhook
3. ✅ Order update (payment_status = paid)
4. ✅ Firebase notification to driver
5. ✅ Transaction logging
6. ✅ Security (signature verification, amount verification)

**Ready to implement! 🚀**