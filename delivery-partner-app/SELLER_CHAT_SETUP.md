# Seller Chat with Driver - Setup Guide

This document explains the complete seller chat system for communicating with delivery drivers.

---

## 1. Overview

The seller chat system allows sellers to communicate with drivers in real-time:
- **View incoming order details** with driver information
- **Chat with driver** about order pickup, delivery status, issues, etc.
- **Send and receive messages** in real-time
- **Track message read status** and delivery status

---

## 2. Where to Access Seller Chat

### Entry Point: Order Management

**Location:** `lib/view/screens/seller/` (Seller App)

When a seller receives an incoming order:
1. **Orders Dashboard** → Click on an active order
2. **Order Details Screen** → Click **"Chat with Driver"** button
3. **OrderChatScreen** opens with driver chat interface

```dart
// Example navigation (in seller's order details screen)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OrderChatScreen(
      orderId: 12345,
      sellerId: 789,
      sellerName: 'My Store',
      sellerType: 'seller',  // Important: identifies sender as seller
    ),
  ),
);
```

---

## 3. Chat UI Components

### Screen: `OrderChatScreen`
**File:** `lib/view/screens/chat/order_chat_screen.dart`

#### Top Section
- **Header:** Shows driver name and order ID
- **Real-time messages:** All conversation history between driver and seller

#### Message Display
- **Seller messages:** Left-aligned, light background with border
- **Driver messages:** Right-aligned, blue background
- **Timestamps:** Shows time sent (HH:MM format) or "Yesterday" / "DD/MM"
- **Read status:** Tracked but not shown in UI

#### Quick Messages Bar
Pre-defined quick replies for fast communication:
```
[I have arrived]  [Order is ready]  [Package damaged]  [On the way]  [Waiting for you]
```
Tap any to send instantly.

#### Message Input Area
- **Text field:** Type custom messages (max 4 lines visible, scrollable)
- **Send button:** Blue button with send icon (disabled while sending)
- **Status:** Shows loading spinner while sending

---

## 4. Message Data Structure

### Firebase Firestore Schema
**Collection Path:** `/orders/{orderId}/chat`

Each message document contains:

```json
{
  "id": "1704067200000",                    // Timestamp-based unique ID
  "order_id": 12345,                        // Order being discussed
  "message": "I have arrived",              // Message content
  "sender_type": "seller",                  // 'seller' or 'driver'
  "receiver_type": "driver",                // Who receives it
  "sender_id": 789,                         // ID of sender (seller/driver ID)
  "receiver_id": 456,                       // ID of receiver
  "timestamp": "2024-01-01T10:30:45Z",     // ISO 8601 format
  "read": true,                             // Read status
  "metadata": {                             // Optional additional data
    "delivery_status": "in_transit",
    "attachment_url": null
  }
}
```

### API Request Format (When Sending)
**Endpoint:** `POST /api/order/chat/send-auth`

**Request Body:**
```json
{
  "order_id": 12345,
  "message": "Order is ready for pickup",
  "sender_type": "seller",                  // Always "seller" for seller app
  "receiver_type": "driver",                // Always "driver"
  "seller_id": 789                          // Current seller's ID
}
```

**Response:**
```json
{
  "status": 1,                              // 1 = success, 0 = error
  "message": "Message sent successfully",
  "data": {
    "message_id": "1704067200000",
    "timestamp": "2024-01-01T10:30:45Z"
  }
}
```

---

## 5. Message Types & Quick Messages

### Pre-defined Quick Messages
Sellers can tap these for instant replies:

| Message | Use Case |
|---------|----------|
| "I have arrived" | Seller confirms they're at their store |
| "Order is ready" | Order is prepared for driver pickup |
| "Package damaged" | Item(s) are damaged, cannot deliver |
| "On the way" | Seller is preparing order |
| "Waiting for you" | Seller is ready, waiting for driver |

### Custom Messages
Sellers can type any custom message up to 500 characters.

**Examples:**
- "Driver is 10 minutes away"
- "Can you wait 5 minutes? Still packing"
- "Order weight is 5kg, fragile items inside"
- "Please call before arrival"

---

## 6. Real-time Behavior

### Message Listening
Messages are listened to in real-time using Firebase Firestore:

```dart
// Stream setup in OrderChatScreen
_chatService.getChatMessagesStream(orderId).listen((messages) {
  // Messages automatically update when new ones arrive
  setState(() {
    _messages = messages;
  });
  _scrollToBottom(); // Auto-scroll to latest message
});
```

### Auto-scroll
When new messages arrive, the chat automatically scrolls to show the latest message.

### Sending Flow
1. Seller taps send button
2. Message sent to API endpoint: `/api/order/chat/send-auth`
3. API validates and stores in database
4. Message simultaneously written to Firebase Firestore
5. Both driver and seller see message in real-time via Firestore listener
6. Message appears in UI within 1-2 seconds

---

## 7. Implementation Details

### Key Classes

#### `ChatMessage` Model
**File:** `lib/services/order_chat_service.dart`

```dart
class ChatMessage {
  final String id;           // Unique message ID
  final int orderId;         // Order reference
  final String senderType;   // 'driver' or 'seller'
  final String receiverType; // 'seller' or 'driver'
  final String message;      // Message text
  final DateTime timestamp;  // When sent
  final bool read;           // Read status
  final int? senderId;       // ID of sender
  final int? receiverId;     // ID of receiver
}
```

#### `OrderChatService`
**File:** `lib/services/order_chat_service.dart`

Core methods:

```dart
// Get real-time messages
Stream<List<ChatMessage>> getChatMessagesStream(int orderId)

// Get messages from specific sender
Stream<List<ChatMessage>> getMessagesBySenderType(int orderId, String senderType)

// Send message
Future<void> addMessage({
  required int orderId,
  required String message,
  required String senderType,
  required String receiverType,
  required int? senderId,
  required int? receiverId,
})

// Mark as read
Future<void> markMessageAsRead(int orderId, String messageId)
Future<void> markAllMessagesAsRead(int orderId, String senderType)

// Get unread count
Future<int> getUnreadMessageCount(int orderId, String senderType)
Stream<int> getUnreadMessageCountStream(int orderId, String senderType)

// Get last message
Future<ChatMessage?> getLastMessage(int orderId)

// Metadata
Future<Map<String, dynamic>> getChatMetadata(int orderId)
Future<void> updateChatMetadata(int orderId, Map<String, dynamic> data)
```

---

## 8. Seller App Integration Points

### Where Seller Would Access This
**(For future seller app implementation)**

```
Seller App
├── Dashboard
│   └── My Orders
│       └── Active Orders
│           └── [Order #12345]
│               ├── Order Details
│               │   ├── Items List
│               │   ├── Pickup Location
│               │   └── Driver Info
│               └── [Chat with Driver] ← TAP HERE
│                   └── OrderChatScreen
│                       ├── Message History
│                       ├── Quick Messages
│                       └── Message Input
```

### Implementation Example
```dart
// In seller's order details screen
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderChatScreen(
          orderId: order.orderId,
          sellerId: authProvider.currentSeller.id,
          sellerName: authProvider.currentSeller.name,
          sellerType: 'seller',
        ),
      ),
    );
  },
  icon: const Icon(Icons.chat),
  label: const Text('Chat with Driver'),
)
```

---

## 9. Sending Message Flow

### Step-by-Step Process

```
1. Seller Types Message
   └─ Text entered in TextField

2. Seller Taps Send Button
   └─ _sendMessage() is called

3. Message Sent to API
   POST /api/order/chat/send-auth
   ├─ order_id: 12345
   ├─ message: "Order is ready"
   ├─ sender_type: "seller"
   ├─ receiver_type: "driver"
   └─ seller_id: 789

4. API Validates & Stores
   ├─ Saves to main database
   └─ Returns success/error

5. Message Written to Firebase
   ├─ Collection: /orders/{orderId}/chat
   ├─ Message document created
   └─ Timestamp set to server time

6. Real-time Sync
   ├─ Both driver and seller see message
   ├─ UI updates automatically
   └─ Scroll to bottom

7. Confirmation
   └─ Input field cleared
   └─ Send button becomes enabled again
```

---

## 10. Reading Messages

### What Sellers See

- **All messages** in chronological order
- **Message timestamp** (time of day or relative)
- **Sender identification** (layout indicates who sent it)
- **Read status** (tracked but currently not displayed)

### Message Timeline Example
```
[10:15] Seller: "Order is ready for pickup"
[10:16] Driver: "I have arrived"
[10:17] Seller: "Coming to you now"
[10:18] Driver: "Thanks! On my way up"
```

### Unread Message Notifications
*(Future feature)*
```dart
// Check for unread messages from driver
Stream<int> unreadCount = _chatService.getUnreadMessageCountStream(
  orderId,
  'driver', // Messages from driver
);
```

---

## 11. Error Handling

### What Happens If...

#### Message fails to send?
- ❌ Error toast appears: "Failed to send message"
- Message is NOT added to local list
- Seller can retry

#### Network is slow?
- ⏳ Send button shows loading spinner
- Message waits for confirmation
- Timeout after 30 seconds

#### Firebase is unavailable?
- ⚠️ Message sends via API successfully
- Firebase write fails silently (logged)
- Message still visible locally

#### Chat messages won't load?
- 📭 "No messages yet" appears
- Error toast: "Failed to load messages"
- Automatic retry on screen refresh

---

## 12. Data Flow Diagram

```
Seller App                    Backend                    Driver App
    │                            │                           │
    ├─ Types message ─────────────┤                           │
    │                            │                           │
    ├─ Taps send ────────────────>│ /api/order/chat/send-auth │
    │                            ├─────────────────────────>│
    │                            │ Message received         │
    │                            │                           │ Message appears
    │                            │ Store in database         │ in driver's chat
    │                            │ Write to Firebase    <────┤
    │                            │                           │
    │ Message appears <──────────┤                           │
    │ in seller's chat via stream │                           │
    │                            │                           │
```

---

## 13. API Endpoints Used

### Send Chat Message
- **Endpoint:** `POST /api/order/chat/send-auth`
- **File Reference:** `lib/utils/app_urls.dart` → `AppUrl.sendChatMessage`
- **Authentication:** Required (delivery boy token)

### Required Fields
```dart
{
  "order_id": int,           // Required
  "message": String,         // Required, non-empty
  "sender_type": "seller",   // Required
  "receiver_type": "driver", // Required
  "seller_id": int,          // Required
}
```

---

## 14. Testing the Chat

### Manual Testing Steps

1. **Open Order Chat**
   - Navigate to an active order in seller app
   - Tap "Chat with Driver"

2. **Send Message**
   - Type: "Testing message"
   - Tap send button
   - Verify message appears on right side

3. **Receive Message**
   - Have driver send message from their app
   - Verify it appears on left side

4. **Quick Message**
   - Tap "Order is ready"
   - Verify message sends instantly

5. **Verify Timestamps**
   - Check time format is correct
   - Check Firebase timestamp matches

---

## 15. Security Considerations

### Authentication
- Only authenticated sellers can send messages
- `seller_id` must match authenticated seller
- API validates seller has access to this order

### Data Validation
- Message length validated (max 500 chars)
- Special characters allowed
- HTML/script tags escaped

### Access Control
- Sellers can only chat on their own orders
- Sellers cannot see chats for other sellers' orders
- Message history is order-specific

---

## 16. Performance Notes

### Message Loading
- Initial load: Fetches last 100 messages
- Real-time updates: Incremental additions
- Scroll to bottom: Smooth animation (300ms)

### Firebase Costs
- Read: 1 read per listener + snapshot updates
- Write: 1 write per message sent
- Optimize: Consider archiving old messages quarterly

### Network Optimization
- Messages sent with `isToast: false` (no default toast)
- Only custom error toasts shown
- Automatic retry on network failure

---

## 17. Summary

### For Sellers
✅ **Can:**
- View all messages with driver
- Send custom messages
- Use quick reply buttons
- See message history with timestamps

❌ **Cannot:**
- Edit sent messages
- Delete messages
- See driver's read status (planned feature)
- Add attachments/images (planned feature)

### For Developers
📁 **Key Files:**
- `lib/view/screens/chat/order_chat_screen.dart` - UI
- `lib/services/order_chat_service.dart` - Logic
- `lib/utils/app_urls.dart` - Endpoints
- `/orders/{orderId}/chat` - Firebase collection

🔧 **To Add Seller App Support:**
1. Create seller version of `OrderChatScreen`
2. Set `sellerType: 'seller'` when initializing
3. Update `sender_type` to "seller" in API calls
4. Add chat link to seller's order details screen

---

## Appendix: Code Reference

### Initialize Chat Screen
```dart
OrderChatScreen(
  orderId: 12345,
  sellerId: 789,
  sellerName: 'My Store',
  sellerType: 'seller',
)
```

### Send Message Programmatically
```dart
await _chatService.addMessage(
  orderId: 12345,
  message: 'Order is ready',
  senderType: 'seller',
  receiverType: 'driver',
  senderId: 789,
  receiverId: 456,
);
```

### Listen to Messages
```dart
_chatService.getChatMessagesStream(12345).listen((messages) {
  print('New messages: ${messages.length}');
});
```

### Check Unread Messages
```dart
int unreadCount = await _chatService.getUnreadMessageCount(
  12345,
  'driver', // Check messages from driver
);
```
