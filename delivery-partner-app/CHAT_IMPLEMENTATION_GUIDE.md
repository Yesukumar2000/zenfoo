# Chat Implementation Guide for Seller & Customer Apps

## Firebase Chat Structure

All chat messages are stored in the following Firebase structure:

```
/chatting/{orderId}/{chatPath}/msg_{timestamp}
```

### Chat Paths

| Scenario | Chat Path | Example |
|----------|-----------|---------|
| Customer ↔ Driver | `customer_to_driver` | `/chatting/126/customer_to_driver/msg_1234567890` |
| Driver ↔ Seller | `driver_to_seller` | `/chatting/126/driver_to_seller/msg_1234567890` |

---

## Message Structure

Each message document contains:

```json
{
  "id": "msg_1704067200000",
  "order_id": 126,
  "message": "Your order is ready",
  "sender_type": "seller",
  "receiver_type": "driver",
  "sender_id": 45,
  "receiver_id": 12,
  "timestamp": "2024-01-01T10:00:00Z",
  "read": false,
  "metadata": {
    "delivery_status": null,
    "attachment_url": null
  }
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique message ID (format: `msg_{timestamp}`) |
| `order_id` | Integer | Order ID associated with the message |
| `message` | String | Message content |
| `sender_type` | String | Who sent the message: `seller`, `driver`, or `customer` |
| `receiver_type` | String | Who receives the message: `seller`, `driver`, or `customer` |
| `sender_id` | Integer | User ID of the sender |
| `receiver_id` | Integer | User ID of the receiver |
| `timestamp` | DateTime | Message timestamp (server-generated) |
| `read` | Boolean | Whether message has been read by receiver |
| `metadata` | Object | Additional metadata (future use) |

---

## Implementation Steps

### 1. For Seller App

#### Import Required Files

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zenfoo_partner/services/order_chat_service.dart';
import 'package:zenfoo_partner/view/screens/chat/order_chat_screen.dart';
```

#### Integrate Chat Service

```dart
// Initialize the chat service
final chatService = OrderChatService();

// Get current user ID from auth provider
final authProvider = context.read<AuthProvider>();
final sellerId = authProvider.currentUser?.id;
```

#### Listen to Messages from Driver

```dart
// Listen to customer_to_driver messages (Driver -> Seller)
chatService.getChatMessagesStream(
  orderId: 126,
  senderType: 'driver',
  receiverType: 'seller',
).listen((messages) {
  // Update UI with messages
  for (var message in messages) {
    print('${message.senderType}: ${message.message}');
  }
});
```

#### Send Message to Driver

```dart
Future<void> sendMessageToDriver({
  required int orderId,
  required String message,
  required int sellerId,
  required int driverId,
}) async {
  await chatService.addMessage(
    orderId: orderId,
    message: message,
    senderType: 'seller',
    receiverType: 'driver',
    senderId: sellerId,
    receiverId: driverId,
  );
}
```

#### Open Chat Screen in Seller App

```dart
// Open chat with driver
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OrderChatScreen(
      orderId: 126,
      sellerId: 45, // Seller's ID
      sellerName: 'Your Store Name',
      sellerType: 'seller',
    ),
  ),
);
```

#### Mark Messages as Read

```dart
// Mark all unread driver messages as read
await chatService.markAllMessagesAsRead(
  orderId: 126,
  senderType: 'driver',
  receiverType: 'seller',
);
```

#### Get Unread Message Count

```dart
// Get real-time unread message count
chatService.getUnreadMessageCountStream(
  orderId: 126,
  senderType: 'driver',
  receiverType: 'seller',
).listen((unreadCount) {
  print('Unread messages from driver: $unreadCount');
});
```

---

### 2. For Customer App

#### Import Required Files

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zenfoo_partner/services/order_chat_service.dart';
import 'package:zenfoo_partner/view/screens/chat/order_chat_screen.dart';
```

#### Integrate Chat Service

```dart
// Initialize the chat service
final chatService = OrderChatService();

// Get current user ID from auth provider
final authProvider = context.read<AuthProvider>();
final customerId = authProvider.currentCustomer?.id;
```

#### Listen to Messages from Driver

```dart
// Listen to customer_to_driver messages (Driver -> Customer)
chatService.getChatMessagesStream(
  orderId: 126,
  senderType: 'driver',
  receiverType: 'customer',
).listen((messages) {
  // Update UI with messages
  for (var message in messages) {
    print('${message.senderType}: ${message.message}');
  }
});
```

#### Send Message to Driver

```dart
Future<void> sendMessageToDriver({
  required int orderId,
  required String message,
  required int customerId,
  required int driverId,
}) async {
  await chatService.addMessage(
    orderId: orderId,
    message: message,
    senderType: 'customer',
    receiverType: 'driver',
    senderId: customerId,
    receiverId: driverId,
  );
}
```

#### Open Chat Screen in Customer App

```dart
// Open chat with driver
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OrderChatScreen(
      orderId: 126,
      sellerId: 12, // Driver's ID
      sellerName: 'Delivery Partner',
      sellerType: 'customer',
    ),
  ),
);
```

#### Mark Messages as Read

```dart
// Mark all unread driver messages as read
await chatService.markAllMessagesAsRead(
  orderId: 126,
  senderType: 'driver',
  receiverType: 'customer',
);
```

#### Get Unread Message Count

```dart
// Get real-time unread message count
chatService.getUnreadMessageCountStream(
  orderId: 126,
  senderType: 'driver',
  receiverType: 'customer',
).listen((unreadCount) {
  print('Unread messages from driver: $unreadCount');
});
```

---

## API Reference

### OrderChatService Methods

#### `getChatMessagesStream()`
Get real-time stream of messages

```dart
Stream<List<ChatMessage>> getChatMessagesStream(
  int orderId,
  {String senderType = 'driver', String receiverType = 'seller'}
)
```

**Parameters:**
- `orderId`: Order ID
- `senderType`: Who sent the message (optional, default: 'driver')
- `receiverType`: Who receives the message (optional, default: 'seller')

**Returns:** Stream of ChatMessage list

---

#### `addMessage()`
Send a new message

```dart
Future<void> addMessage({
  required int orderId,
  required String message,
  required String senderType,
  required String receiverType,
  required int? senderId,
  required int? receiverId,
})
```

**Parameters:**
- `orderId`: Order ID
- `message`: Message text
- `senderType`: `'seller'`, `'driver'`, or `'customer'`
- `receiverType`: `'seller'`, `'driver'`, or `'customer'`
- `senderId`: Sender's user ID
- `receiverId`: Receiver's user ID

---

#### `markMessageAsRead()`
Mark a single message as read

```dart
Future<void> markMessageAsRead(
  int orderId,
  String messageId,
  {String senderType = 'driver', String receiverType = 'seller'}
)
```

**Parameters:**
- `orderId`: Order ID
- `messageId`: Message ID to mark as read
- `senderType`: Sender type (optional)
- `receiverType`: Receiver type (optional)

---

#### `markAllMessagesAsRead()`
Mark all unread messages from a sender as read

```dart
Future<void> markAllMessagesAsRead(
  int orderId,
  String senderType,
  {String receiverType = 'seller'}
)
```

**Parameters:**
- `orderId`: Order ID
- `senderType`: Who sent the messages
- `receiverType`: Receiver type (optional)

---

#### `getUnreadMessageCount()`
Get the number of unread messages

```dart
Future<int> getUnreadMessageCount(
  int orderId,
  String senderType,
  {String receiverType = 'seller'}
)
```

**Parameters:**
- `orderId`: Order ID
- `senderType`: Who sent the messages
- `receiverType`: Receiver type (optional)

**Returns:** Integer count of unread messages

---

#### `getUnreadMessageCountStream()`
Get real-time unread message count

```dart
Stream<int> getUnreadMessageCountStream(
  int orderId,
  String senderType,
  {String receiverType = 'seller'}
)
```

**Parameters:**
- `orderId`: Order ID
- `senderType`: Who sent the messages
- `receiverType`: Receiver type (optional)

**Returns:** Stream of unread message count

---

#### `getLastMessage()`
Get the most recent message

```dart
Future<ChatMessage?> getLastMessage(
  int orderId,
  {String senderType = 'driver', String receiverType = 'seller'}
)
```

**Parameters:**
- `orderId`: Order ID
- `senderType`: Sender type (optional)
- `receiverType`: Receiver type (optional)

**Returns:** ChatMessage or null if no messages

---

#### `deleteMessage()`
Delete a message (use with caution)

```dart
Future<void> deleteMessage(
  int orderId,
  String messageId,
  {String senderType = 'driver', String receiverType = 'seller'}
)
```

**Parameters:**
- `orderId`: Order ID
- `messageId`: Message ID to delete
- `senderType`: Sender type (optional)
- `receiverType`: Receiver type (optional)

---

## Example: Complete Chat Screen

### Seller App

```dart
class SellerChatScreen extends StatefulWidget {
  final int orderId;
  final int driverId;

  const SellerChatScreen({
    required this.orderId,
    required this.driverId,
  });

  @override
  State<SellerChatScreen> createState() => _SellerChatScreenState();
}

class _SellerChatScreenState extends State<SellerChatScreen> {
  late TextEditingController _messageController;
  late OrderChatService _chatService;
  late int _sellerId;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _chatService = OrderChatService();

    // Get seller ID from auth
    final authProvider = context.read<AuthProvider>();
    _sellerId = authProvider.currentUser?.id ?? 0;

    // Mark messages as read
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    _chatService.markAllMessagesAsRead(
      widget.orderId,
      'driver',
      receiverType: 'seller',
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _chatService.addMessage(
        orderId: widget.orderId,
        message: message,
        senderType: 'seller',
        receiverType: 'driver',
        senderId: _sellerId,
        receiverId: widget.driverId,
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Driver'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getChatMessagesStream(
                widget.orderId,
                senderType: 'driver',
                receiverType: 'seller',
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isSender = msg.senderType == 'seller';

                    return Align(
                      alignment: isSender
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.all(8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSender
                            ? Colors.blue
                            : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.message,
                          style: TextStyle(
                            color: isSender
                              ? Colors.white
                              : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
```

### Customer App (Similar Implementation)

Replace `senderType: 'seller'` with `senderType: 'customer'` and `receiverType: 'seller'` with `receiverType: 'customer'` in the above code.

---

## Firebase Security Rules

Add these Firestore security rules to protect chat data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chat rules
    match /chatting/{orderId}/{chatPath}/{messageId} {
      // Allow read if user is sender or receiver
      allow read: if request.auth.uid != null;

      // Allow write if user is sender
      allow create: if request.auth.uid != null
        && request.resource.data.sender_id == request.auth.uid;

      // Allow update only for marking as read
      allow update: if request.auth.uid != null
        && resource.data.receiver_id == request.auth.uid
        && request.resource.data.diff(resource.data).affectedKeys() == ['read'];

      // Allow delete only by sender or admin
      allow delete: if request.auth.uid != null
        && (resource.data.sender_id == request.auth.uid);
    }
  }
}
```

---

## Testing the Chat System

### Test Case 1: Send Message from Seller to Driver

```dart
void testSellerSendMessage() async {
  final chatService = OrderChatService();

  await chatService.addMessage(
    orderId: 126,
    message: 'Order is ready for pickup',
    senderType: 'seller',
    receiverType: 'driver',
    senderId: 45,
    receiverId: 12,
  );

  // Verify in Firebase: /chatting/126/driver_to_seller/msg_*
}
```

### Test Case 2: Listen to Messages in Real-Time

```dart
void testListenToMessages() {
  final chatService = OrderChatService();

  chatService.getChatMessagesStream(
    126,
    senderType: 'driver',
    receiverType: 'seller',
  ).listen((messages) {
    print('Received ${messages.length} messages');
    for (var msg in messages) {
      print('${msg.senderType}: ${msg.message}');
    }
  });
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Messages not appearing | Check Firebase rules and ensure `senderType` matches the sending user |
| Real-time updates not working | Verify Firestore listener is active and connection is stable |
| Messages marked as read not updating | Ensure `receiverType` parameter matches the receiving user type |
| Permission denied errors | Check Firebase security rules and user authentication |

---

## Best Practices

1. **Always mark messages as read** after displaying them to users
2. **Use real-time streams** for live chat updates
3. **Validate message content** before sending (no empty messages)
4. **Handle network errors** gracefully with try-catch blocks
5. **Clean up streams** when screens are disposed to prevent memory leaks
6. **Store sender and receiver IDs** for proper message attribution
7. **Use server timestamp** for accurate message ordering
8. **Implement pagination** for high-volume chats (implement in future)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-01-02 | Initial implementation with customer_to_driver and driver_to_seller paths |

