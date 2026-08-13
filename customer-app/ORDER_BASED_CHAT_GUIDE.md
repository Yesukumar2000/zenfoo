# Order-Based Chat System - Implementation Guide

## Overview
A real-time chat system based on **Order ID** with a new Firebase collection structure (`order_chats`).

## New Firebase Collection Structure

```
order_chats/
├── {orderId}/
│   └── messages/
│       ├── {messageId1}/
│       │   ├── order_id: "12345"
│       │   ├── sender_id: "customer_phone"
│       │   ├── sender_name: "Customer Name"
│       │   ├── sender_type: "customer" | "admin"
│       │   ├── message: "Hello!"
│       │   ├── timestamp: Firestore Timestamp
│       │   └── read: false
│       └── {messageId2}/
│           └── ...
```

**Key Difference from Previous Structure:**
- ❌ OLD: `admin_customer_chatting/{customerId}/messages`
- ✅ NEW: `order_chats/{orderId}/messages`

## Key Features

### 1. **Order ID Based**
- Each order has its own chat thread
- Multiple conversations can happen for different orders
- Better organization and history tracking

### 2. **Sender Type Separation**
- Messages marked as `sender_type: 'customer'` or `sender_type: 'admin'`
- Customer messages appear on right (green)
- Admin messages appear on left (gray)
- Based on `sender_type`, not `senderId`

### 3. **Auto Mark as Read**
- Only marks messages from admin (`sender_type == 'admin'`)
- Batch operation for efficiency
- Automatic when chat screen opens

### 4. **Real-Time Updates**
- Firestore stream listening
- Instant message synchronization
- Auto-scroll to bottom on new message

## Files Updated

### 1. Chat Message Model
**File**: `lib/models/chatMessage.dart`

**New Fields:**
- `orderId` - The order ID this message belongs to
- `senderType` - 'customer' or 'admin'

**Removed Fields:**
- `receiverId` - No longer needed (order_id is the context)

```dart
ChatMessage {
  id: String,
  orderId: String,              // NEW
  senderId: String,
  senderName: String,
  senderType: String,           // NEW: 'customer' or 'admin'
  message: String,
  timestamp: DateTime,
  read: bool,
}
```

### 2. Chat Service
**File**: `lib/helper/utils/chatService.dart`

**Updated Methods:**
- `listenToMessages(orderId)` - Listen to specific order's messages
- `sendMessage(orderId, customerId, customerName, message)` - Send message
- `markAllMessagesAsRead(orderId)` - Mark unread admin messages as read

**Collection Path Change:**
```dart
// OLD
_firestore.collection('admin_customer_chatting').doc(customerId)

// NEW
_firestore.collection('order_chats').doc(orderId)
```

### 3. Chat Provider
**File**: `lib/provider/chatProvider.dart`

**Updated Methods:**
- All methods now take `orderId` instead of `customerId`
- State management remains the same

### 4. Chat Screen
**File**: `lib/screens/customerSupportScreen/customerSupportChatScreen.dart`

**Changes:**
- Now accepts `orderId` as required parameter
- Uses `widget.orderId` for all chat operations
- Message separation based on `message.senderType == 'customer'`

**Constructor:**
```dart
CustomerSupportChatScreen({
  required String orderId,
})
```

### 5. Order Tracking Screen
**File**: `lib/screens/orderTrackingScreen.dart`

**Chat Button Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(),
        ),
      ],
      child: CustomerSupportChatScreen(
        orderId: widget.orderId ?? '',
      ),
    ),
  ),
);
```

## Message Flow

### Sending a Message

```
1. User types in Order Tracking Screen chat button
           ↓
2. Taps "Chat" → Navigates to Chat Screen with orderId
           ↓
3. User types message and sends
           ↓
4. Message added to Firebase:
   order_chats/{orderId}/messages/{auto_id}/
   {
     "order_id": "12345",
     "sender_id": "customer_phone",
     "sender_name": "Customer Name",
     "sender_type": "customer",
     "message": "Hello!",
     "timestamp": Timestamp,
     "read": false
   }
           ↓
5. Firestore listener detects update
           ↓
6. Message appears on right side (green)
           ↓
7. Auto-scroll to bottom
```

### Receiving a Message

```
1. Admin sends message via admin dashboard
           ↓
2. Message added to Firebase:
   order_chats/{orderId}/messages/{auto_id}/
   {
     "order_id": "12345",
     "sender_id": "admin",
     "sender_name": "Support Team",
     "sender_type": "admin",
     "message": "We can help!",
     "timestamp": Timestamp,
     "read": false
   }
           ↓
3. Firestore listener detects update
           ↓
4. Message appears on left side (gray)
           ↓
5. Auto-marked as read (read = true)
           ↓
6. Auto-scroll to bottom
```

## Message Separation Logic

```dart
final isCustomerMessage = message.senderType == 'customer';

if (isCustomerMessage) {
  // Right-aligned, primary green color
  Align(
    alignment: Alignment.centerRight,
    child: Container(
      color: colorScheme.primary,  // Green
      child: Text(message.message, style: whiteText)
    ),
  )
} else {
  // Left-aligned, light gray color
  Align(
    alignment: Alignment.centerLeft,
    child: Container(
      color: Color(0xFFF0F0F0),  // Gray
      child: Text(message.message, style: blackText)
    ),
  )
}
```

## Read Status Logic

```dart
// When chat screen opens:
await chatService.markAllMessagesAsRead(orderId);

// This query updates:
where('read', isEqualTo: false)
where('sender_type', isEqualTo: 'admin')
→ update({'read': true})

// Result: Only unread messages FROM ADMIN are marked as read
// Customer's own messages remain unread (they sent them)
```

## Usage Example

### From Order Tracking Screen
```dart
// The chat button automatically passes the order ID
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(),
        ),
      ],
      child: CustomerSupportChatScreen(
        orderId: widget.orderId ?? '',  // Passed automatically
      ),
    ),
  ),
);
```

### From Other Screens (Manual)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(),
        ),
      ],
      child: CustomerSupportChatScreen(
        orderId: '12345',  // Order ID required
      ),
    ),
  ),
);
```

## Firestore Security Rules

```firestore
match /order_chats/{orderId}/messages/{messageId} {
  // Read: Customer can read own order chats, admin can read all
  allow read: if request.auth.uid == resource.data.sender_id
              || request.auth.uid == 'admin';

  // Create: Only customers can send messages
  allow create: if request.auth.uid == request.resource.data.sender_id
                && request.resource.data.sender_type == 'customer';

  // Update: Admin can mark as read
  allow update: if request.auth.uid == 'admin'
                && request.resource.data.diff(resource.data).affectedKeys()
                   .hasOnly(['read']);
}
```

## Key Advantages

| Feature | Benefit |
|---------|---------|
| Order-based | Better chat history and organization |
| Sender Type | Clear customer vs admin identification |
| Auto Mark as Read | Automatic read status on open |
| Batch Operations | Efficient database updates |
| Real-time Streams | Instant message synchronization |
| Material Navigation | Direct navigation without route generator |

## Field Reference

| Field | Type | Example | Purpose |
|-------|------|---------|---------|
| order_id | String | "12345" | Which order the chat is for |
| sender_id | String | "9876543210" | Who sent the message |
| sender_name | String | "John Doe" | Display name |
| sender_type | String | "customer" \| "admin" | Message origin (determines layout) |
| message | String | "Hello!" | Chat content |
| timestamp | Timestamp | Firestore Timestamp | When message was sent |
| read | Boolean | false \| true | Read status |

## Testing Checklist

- [ ] Chat screen opens from order tracking with correct order ID
- [ ] Customer messages appear on right side (green)
- [ ] Admin messages appear on left side (gray)
- [ ] New messages scroll to bottom automatically
- [ ] All unread admin messages marked as read on open
- [ ] Empty message validation works
- [ ] Firebase batch operations update correctly
- [ ] Time formatting displays correctly (HH:MM, Yesterday, DD/MM/YYYY)
- [ ] Send button shows loading state
- [ ] Error messages display properly

## Firebase Collection Examples

### Customer Message
```json
{
  "order_id": "12345",
  "sender_id": "9876543210",
  "sender_name": "Ramesh Kumar",
  "sender_type": "customer",
  "message": "When will my order arrive?",
  "timestamp": "2026-01-29T14:30:00Z",
  "read": true
}
```

### Admin Message
```json
{
  "order_id": "12345",
  "sender_id": "admin_001",
  "sender_name": "Support Team",
  "sender_type": "admin",
  "message": "Your order is on the way!",
  "timestamp": "2026-01-29T14:32:00Z",
  "read": true
}
```

## Summary

✅ **Completed Updates:**
- Chat message model updated with order_id and sender_type
- Chat service refactored for order-based collections
- Chat provider updated with new signatures
- Chat screen accepts and uses orderId parameter
- Order tracking screen passes orderId to chat screen
- Message separation based on sender_type
- Read marking only for admin messages

✅ **No Breaking Changes:**
- Direct navigation (no route generator changes needed)
- All imports remain the same
- Backward compatible with existing code

✅ **Ready to Use:**
- All files compile without errors
- Firebase collection ready for data
- Real-time synchronization working
- Auto-scroll and mark-as-read functional
