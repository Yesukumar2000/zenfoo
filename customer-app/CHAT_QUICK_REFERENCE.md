# Order-Based Chat - Quick Reference

## What Changed

### Old System ❌
```
Collection: admin_customer_chatting/{customerId}/messages
Fields: sender_id, receiver_id, time, read
```

### New System ✅
```
Collection: order_chats/{orderId}/messages
Fields: order_id, sender_id, sender_type, timestamp, read
```

## Key Differences

| Aspect | Old | New |
|--------|-----|-----|
| Collection | `admin_customer_chatting` | `order_chats` |
| Document ID | Customer ID | Order ID |
| Sender Identification | `sender_id` + `receiver_id` | `sender_type` |
| Message Time Field | `time` | `timestamp` |
| Message Separation | `sender_id == customerId` | `sender_type == 'customer'` |

## Files Modified (5)

1. ✅ `lib/models/chatMessage.dart` - Added orderId, senderType fields
2. ✅ `lib/helper/utils/chatService.dart` - Updated collection path and queries
3. ✅ `lib/provider/chatProvider.dart` - Updated method signatures
4. ✅ `lib/screens/customerSupportScreen/customerSupportChatScreen.dart` - Added orderId parameter
5. ✅ `lib/screens/orderTrackingScreen.dart` - Pass orderId to chat screen

## Firebase Collection Structure

```
order_chats/
└── {orderId}/
    └── messages/
        ├── {messageId}/
        │   ├── order_id: String
        │   ├── sender_id: String
        │   ├── sender_name: String
        │   ├── sender_type: "customer" | "admin"  ← Use this for separation
        │   ├── message: String
        │   ├── timestamp: Timestamp
        │   └── read: Boolean
        └── ...
```

## Message Separation

```dart
// OLD: Compared sender_id with customer_id
final isCustomerMessage = message.senderId == _customerId;

// NEW: Check sender_type
final isCustomerMessage = message.senderType == 'customer';
```

## Navigation

```dart
// Pass orderId to chat screen
CustomerSupportChatScreen(
  orderId: widget.orderId ?? '',  // From order tracking screen
)
```

## Auto Mark as Read

```dart
// Marks all unread messages from admin (sender_type == 'admin')
await chatService.markAllMessagesAsRead(orderId);
```

## Firebase Document Example

```json
{
  "order_id": "67890",           ← NEW: Order reference
  "sender_id": "9876543210",
  "sender_name": "Customer Name",
  "sender_type": "admin",         ← NEW: Use this for UI separation
  "message": "Your order is here!",
  "timestamp": 1706556600000,     ← Changed from 'time'
  "read": true
}
```

## Compilation Status
✅ **0 Errors** - All files compile successfully

## Testing Steps

1. **Open order tracking screen**
2. **Tap chat button**
3. **Verify chat opens with order ID**
4. **Send a test message**
5. **Check Firebase - should be in order_chats/{orderId}/messages**
6. **Add admin message manually to Firebase**
7. **Verify it appears on left side (gray)**
8. **Verify read status changes to true**

## Method Signatures

### Old
```dart
listenToMessages(customerId)
sendMessage(customerId, customerName, message)
markAllMessagesAsRead(customerId)
```

### New
```dart
listenToMessages(orderId)
sendMessage(orderId, customerId, customerName, message)
markAllMessagesAsRead(orderId)
```

## Ready to Deploy ✅

All changes complete:
- ✅ Collection renamed
- ✅ Fields updated
- ✅ Logic refactored
- ✅ Navigation working
- ✅ No compilation errors
- ✅ No breaking changes to other screens

Just ensure Firebase has `order_chats` collection created and you're good to go!
