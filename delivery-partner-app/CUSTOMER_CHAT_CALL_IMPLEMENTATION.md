# Customer Chat & Call Implementation Guide for Delivery Partner App

This guide covers implementing in-app chat and phone call functionality with customers during delivery in the Delivery Partner (Driver) App.

---

## Overview

The Delivery Partner app now supports:
1. **In-App Chat** with customers during delivery using Firebase Firestore
2. **Phone Calls** with customers using the native phone dialer
3. **In-App Chat** with sellers during pickup using Firebase Firestore
4. **Phone Calls** with sellers during pickup using the native phone dialer

---

## Firebase Chat Structure for Customer Communication

### Chat Path: Customer ↔ Driver

```
/chatting/{orderId}/customer_to_driver/msg_{timestamp}
```

**Example:**
```
/chatting/126/customer_to_driver/msg_1704067200000
```

---

## Message Document Structure

```json
{
  "id": "msg_1704067200000",
  "order_id": 126,
  "message": "I'm outside your location",
  "sender_type": "customer",
  "receiver_type": "driver",
  "sender_id": 99,
  "receiver_id": 12,
  "timestamp": "2024-01-01T10:00:00Z",
  "read": false,
  "metadata": {
    "delivery_status": null,
    "attachment_url": null
  }
}
```

---

## Implementation in Delivery Detail Screen

### Location: `lib/view/screens/delivery/delivery_detail_screen.dart`

#### Already Implemented Features:

✅ **Call Customer** - `_makePhoneCall()` method
- Automatically detects delivery vs pickup scenario
- For delivery: calls customer
- For pickup: calls seller
- Uses native phone dialer

✅ **Chat with Customer/Seller** - `_openChat()` method
- Opens in-app `OrderChatScreen`
- For delivery: opens chat with customer using `customer_to_driver` path
- For pickup: opens chat with seller using `driver_to_seller` path
- Stores customer/seller ID and name

### Call Customer Implementation

```dart
/// Make a phone call to customer or seller
Future<void> _makePhoneCall() async {
  String? phone;
  String contactName = '';

  if (widget.stepType == DeliveryStepType.delivery) {
    // For delivery, call the customer
    phone = widget.order.customer.mobile;
    contactName = widget.order.customer.name ?? 'Customer';
  } else if (widget.stepType == DeliveryStepType.pickup) {
    // For pickup, call the current seller
    final seller = widget.seller;
    phone = seller?.sellerPhoneNumber;
    contactName = seller?.storeName ?? 'Seller';
  }

  if (phone != null && phone.isNotEmpty) {
    try {
      final url = Uri.parse('tel:$phone');
      if (await canLaunchUrl(url)) {
        debugPrint('📞 Calling $contactName at $phone');
        await launchUrl(url);
      } else {
        // Show error if phone dialer not available
        _showError('Cannot make calls on this device');
      }
    } catch (e) {
      debugPrint('❌ Error making phone call: $e');
      _showError('Error making call: $e');
    }
  } else {
    _showError('${widget.stepType == DeliveryStepType.delivery ? 'Customer' : 'Seller'} phone number not available');
  }
}
```

### Chat with Customer Implementation

```dart
/// Open chat with customer (delivery) or seller (pickup)
Future<void> _openChat() async {
  try {
    if (widget.stepType == DeliveryStepType.delivery) {
      // Chat with customer
      final customer = widget.order.customer;
      if (customer.id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderChatScreen(
              orderId: widget.order.orderId,
              sellerId: customer.id!,
              sellerName: customer.name,
              sellerType: 'customer', // Important: identifies as customer chat
            ),
          ),
        );
        debugPrint('💬 Opening chat with customer: ${customer.name}');
      } else {
        _showError('Customer ID not available');
      }
    } else if (widget.stepType == DeliveryStepType.pickup) {
      // Chat with seller
      final seller = widget.seller;
      if (seller != null && seller.sellerId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderChatScreen(
              orderId: widget.order.orderId,
              sellerId: seller.sellerId!,
              sellerName: seller.storeName,
              sellerType: 'seller',
            ),
          ),
        );
        debugPrint('💬 Opening chat with seller: ${seller.storeName}');
      } else {
        _showError('Seller information not available');
      }
    }
  } catch (e) {
    debugPrint('❌ Error opening chat: $e');
    _showError('Error opening chat: $e');
  }
}

void _showError(String message) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
```

### UI Implementation: Call & Chat Buttons

The buttons are already implemented in the bottom sheet at approximately line 1401-1420:

```dart
/// Call and Chat buttons
Row(
  children: [
    Expanded(
      child: _buildActionButton(
        colorScheme: colorScheme,
        icon: Icons.phone_outlined,
        label: 'Call',
        onTap: _makePhoneCall,
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildActionButton(
        colorScheme: colorScheme,
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Chat',
        onTap: _openChat,
      ),
    ),
  ],
),
```

---

## OrderChatScreen Integration

### Usage in Delivery Detail Screen:

```dart
OrderChatScreen(
  orderId: 126,              // Order ID from widget.order.orderId
  sellerId: 99,              // Customer ID (from customer.id)
  sellerName: 'John Doe',    // Customer name (from customer.name)
  sellerType: 'customer',    // IMPORTANT: Identifies chat type
)
```

### Chat Service Methods Used:

The `OrderChatScreen` uses these methods from `OrderChatService`:

```dart
// Listen to messages in real-time
_chatService.getChatMessagesStream(
  widget.orderId,
  senderType: widget.sellerType,  // 'customer' or 'seller'
  receiverType: 'driver',
).listen((messages) {
  // Update UI with messages
});

// Send a message
await chatService.addMessage(
  orderId: orderId,
  message: messageText,
  senderType: 'driver',
  receiverType: 'customer', // or 'seller'
  senderId: driverId,
  receiverId: customerId,
);

// Mark messages as read
await chatService.markAllMessagesAsRead(
  orderId: orderId,
  senderType: 'customer',  // or 'seller'
  receiverType: 'driver',
);
```

---

## Firebase Security Rules

Add these rules to your Firestore to protect chat data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chat messages security
    match /chatting/{orderId}/{chatPath}/{messageId} {
      // Allow read if user is driver or customer/seller
      allow read: if request.auth.uid != null;

      // Allow create if sender matches authenticated user
      allow create: if request.auth.uid != null
        && request.resource.data.sender_id == request.auth.uid;

      // Allow update only for marking as read
      allow update: if request.auth.uid != null
        && resource.data.receiver_id == request.auth.uid
        && request.resource.data.diff(resource.data).affectedKeys() == ['read'];

      // Allow delete only by sender
      allow delete: if request.auth.uid != null
        && resource.data.sender_id == request.auth.uid;
    }

    // Metadata security
    match /chatting/{orderId}/{chatPath}/_metadata {
      allow read, write: if request.auth.uid != null;
    }
  }
}
```

---

## Required Dependencies

Ensure these are in your `pubspec.yaml`:

```yaml
dependencies:
  cloud_firestore: ^4.0.0
  url_launcher: ^6.0.0
  provider: ^6.0.0
  google_fonts: ^4.0.0
  hugeicons: ^0.0.1
```

---

## Data Flow Diagram

### For Delivery (Customer Chat):

```
Delivery Partner App
         ↓
   _openChat() called
         ↓
   Checks: customer.id != null
         ↓
   Opens OrderChatScreen with:
   - orderId: order.orderId
   - sellerId: customer.id
   - sellerName: customer.name
   - sellerType: 'customer'
         ↓
   OrderChatScreen listens to Firebase:
   /chatting/{orderId}/customer_to_driver/msg_*
         ↓
   Displays messages and allows sending
         ↓
   Messages stored with:
   - senderType: 'driver'
   - receiverType: 'customer'
   - senderId: driver.id
   - receiverId: customer.id
```

### For Pickup (Seller Chat):

```
Delivery Partner App
         ↓
   _openChat() called
         ↓
   Checks: seller.sellerId != null
         ↓
   Opens OrderChatScreen with:
   - orderId: order.orderId
   - sellerId: seller.sellerId
   - sellerName: seller.storeName
   - sellerType: 'seller'
         ↓
   OrderChatScreen listens to Firebase:
   /chatting/{orderId}/driver_to_seller/msg_*
         ↓
   Displays messages and allows sending
         ↓
   Messages stored with:
   - senderType: 'driver'
   - receiverType: 'seller'
   - senderId: driver.id
   - receiverId: seller.id
```

---

## Testing Checklist

### Call Functionality:
- [ ] Call button appears during delivery and pickup
- [ ] Clicking call opens native phone dialer
- [ ] Customer/Seller phone number is dialed correctly
- [ ] Error shown if phone number not available
- [ ] Error shown if device cannot make calls

### Chat Functionality:
- [ ] Chat button appears during delivery and pickup
- [ ] Clicking chat opens OrderChatScreen
- [ ] Correct chat path used (`customer_to_driver` vs `driver_to_seller`)
- [ ] Messages appear in real-time
- [ ] Sent messages show in chat
- [ ] Received messages show in chat
- [ ] Messages marked as read after viewing
- [ ] Unread message count updates
- [ ] Chat screen closes properly on back

### Firebase:
- [ ] Messages saved to correct path in Firestore
- [ ] Message ID format: `msg__{timestamp}`
- [ ] `sender_type` and `receiver_type` set correctly
- [ ] Timestamps are server-generated
- [ ] Read status updates properly

---

## Example: Complete Call Flow

```dart
// User taps "Call" button during delivery
_makePhoneCall()
  ↓
// Checks: widget.stepType == DeliveryStepType.delivery
  ↓
// Gets customer phone: widget.order.customer.mobile
  ↓
// Validates phone number is not empty
  ↓
// Creates tel: URI
  ↓
// Launches native dialer
  ↓
// Driver can now talk to customer
```

---

## Example: Complete Chat Flow

```dart
// User taps "Chat" button during delivery
_openChat()
  ↓
// Checks: widget.stepType == DeliveryStepType.delivery
  ↓
// Validates: customer.id != null
  ↓
// Navigates to OrderChatScreen with:
//   - orderId: widget.order.orderId
//   - sellerId: customer.id
//   - sellerName: customer.name
//   - sellerType: 'customer'
  ↓
// OrderChatScreen loads and listens to:
// /chatting/{orderId}/customer_to_driver/
  ↓
// Firebase returns all messages in that path
  ↓
// Messages displayed in chat UI
  ↓
// User types and sends message
  ↓
// Message saved to Firebase with:
//   - id: msg_1704067200000
//   - senderType: 'driver'
//   - receiverType: 'customer'
//   - senderId: driverId
//   - receiverId: customerId
  ↓
// All users listening to that path receive update
  ↓
// Message appears in everyone's chat
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Call button not working | Phone number empty or null | Check that `customer.mobile` or `seller.sellerPhoneNumber` is populated |
| Chat button not working | Customer/Seller ID is null | Ensure `customer.id` or `seller.sellerId` is set from server |
| Messages not appearing | Firebase path incorrect | Verify `sellerType` parameter matches 'customer' or 'seller' |
| Messages not persisting | Firebase write permissions denied | Check Firestore security rules |
| Real-time updates not working | Firestore listener not active | Ensure OrderChatScreen is open and mounted |
| Chat screen crashes on open | Order ID is 0 | Check that `widget.order.orderId` is valid |

---

## API Integration Requirements

Ensure your backend provides:

### For Customers:
- `customer.id` (Integer) - Unique customer identifier
- `customer.name` (String) - Customer name
- `customer.mobile` (String) - Customer phone number
- `customer.address` (String) - Customer address

### For Sellers:
- `seller.sellerId` (Integer) - Unique seller identifier
- `seller.storeName` (String) - Store name
- `seller.sellerPhoneNumber` (String) - Seller phone number
- `seller.sellerAddress` (String) - Seller address

---

## Performance Optimization

1. **Message Pagination** - Currently loads all messages. For high-volume chats:
   ```dart
   .orderBy('timestamp', descending: false)
   .limit(50)  // Load first 50 messages
   ```

2. **Image Attachments** - Future enhancement using `metadata.attachment_url`

3. **Message Search** - Can be implemented using text search on message field

4. **Typing Indicators** - Can use a separate `typing` collection

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01-02 | Initial implementation with customer and seller chat |

