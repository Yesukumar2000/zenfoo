# Customer Support Chat Screen Implementation

## Overview
Real-time chat screen integrated with Firebase Firestore for customer-admin communication.

## Features Implemented

### 1. **Real-Time Messaging**
- Messages stored in Firebase at: `admin_customer_chatting/{customerId}/messages`
- Live message updates using Firestore streams
- Messages separated by sender (customer on right, admin on left)

### 2. **Message Structure**
```json
{
  "sender_id": "customer_phone",
  "sender_name": "Customer Name",
  "receiver_id": "admin" | "customer_phone",
  "message": "Message text",
  "time": "2026-01-29T...",
  "read": false
}
```

### 3. **Auto-Scroll to Bottom**
- Automatically scrolls to latest messages when new ones arrive
- Smooth animation with 300ms duration

### 4. **Mark as Read**
- All unread messages marked as read when chat screen opens
- Only messages received by the customer are marked (receiver_id == customerId)
- Uses batch operations for efficiency

### 5. **Message Status**
- Outlined/filled stars for ratings (already implemented in tracking screen)
- Delivery boy and product rating cards visible when order delivered

## Files Created

### 1. **Model**: `lib/models/chatMessage.dart`
- `ChatMessage` class with Firestore serialization
- Fields: id, senderId, senderName, receiverId, message, timestamp, read
- Timestamp parsing for Firestore Timestamp type

### 2. **Service**: `lib/helper/utils/chatService.dart`
- `ChatService` class for Firebase operations
- Methods:
  - `listenToMessages(customerId)` - Stream of messages
  - `sendMessage()` - Send new message
  - `markMessageAsRead()` - Mark single message
  - `markAllMessagesAsRead()` - Mark all unread as read (batch operation)

### 3. **Provider**: `lib/provider/chatProvider.dart`
- `ChatProvider` extends ChangeNotifier
- State management for chat
- Properties:
  - `messages` - List of chat messages
  - `isLoading` - Loading state
  - `errorMessage` - Error handling
  - `isSending` - Send button state

### 4. **Screen**: `lib/screens/customerSupportScreen/customerSupportChatScreen.dart`
- Full chat UI with Material design
- Components:
  - **AppBar**: "Customer Support" header with back button
  - **Message List**: Reverse ListView with auto-scroll
  - **Message Bubbles**:
    - Customer messages: Right-aligned, primary color background
    - Admin messages: Left-aligned, light gray background
    - Time display: HH:MM format (today), "Yesterday HH:MM", or DD/MM/YYYY
  - **Input Field**: TextField with send button
  - **Send Button**: Circular icon button with loading indicator

## Integration Points

### Navigation
**File**: `lib/screens/orderTrackingScreen.dart` (lines ~5741-5757)

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
      child: const CustomerSupportChatScreen(),
    ),
  ),
);
```

The chat button in Order Tracking Screen now navigates directly using MaterialPageRoute.

## User Flow

1. **User opens Order Tracking Screen**
2. **Taps "Chat" button**
3. **Navigation to Customer Support Chat Screen**
4. **On screen load**:
   - Initializes Firebase stream listener
   - Fetches all messages ordered by time (newest first)
   - Marks all unread messages as read in Firestore
5. **User types message and sends**
   - Message added to Firestore with `read: false`
   - UI updates immediately via stream
   - Scroll animates to bottom
6. **Receives admin response**
   - Firestore listener detects new message
   - Message appears on left side (admin color)
   - Auto-marked as read

## Firebase Collection Structure

```
admin_customer_chatting/
├── {customerId}/
│   └── messages/
│       ├── {messageId1}/
│       │   ├── sender_id: "customer_phone"
│       │   ├── sender_name: "Customer Name"
│       │   ├── receiver_id: "admin" | "customer_phone"
│       │   ├── message: "Hello"
│       │   ├── time: Timestamp
│       │   └── read: true/false
│       └── {messageId2}/
│           └── ...
```

## Time Format Display

- **Today**: `14:30` (HH:MM)
- **Yesterday**: `Yesterday 14:30`
- **Older**: `29/01/2026`

## Styling

| Element | Color | Style |
|---------|-------|-------|
| App Bar | Primary Green | Material design |
| Customer Message | Primary Green | White text |
| Admin Message | Light Gray (#F0F0F0) | Black text |
| Input Border | Light Gray (#E0E0E0) | Rounded 24px |
| Send Button | Primary Green | Circular icon |

## Message Separation Logic

```dart
final isCustomerMessage = message.senderId == _customerId;

if (isCustomerMessage) {
  // Right-aligned, primary color
} else {
  // Left-aligned, gray color
}
```

## Error Handling

- Empty message validation
- Firebase send errors caught and displayed
- Read marking errors logged but don't block chat
- Connection errors show in provider error state

## Performance Optimizations

- Batch operations for marking all as read
- Stream-based real-time updates (not polling)
- Reverse ListView to show newest first
- Conditional rendering for empty state

## Testing Checklist

- [ ] Chat screen opens from order tracking
- [ ] Messages display correctly (customer right, admin left)
- [ ] New messages appear in real-time
- [ ] Scroll animates to bottom on new message
- [ ] All unread messages marked as read when opened
- [ ] Message timestamps display correctly
- [ ] Send button shows loading state
- [ ] Empty message validation works
- [ ] Firebase errors handled gracefully

## Future Enhancements

1. **Message Typing Indicator**: Show "Admin is typing..."
2. **Message Search**: Search chat history
3. **File Attachments**: Send images/documents
4. **Emoji Support**: Emoji picker
5. **Typing Animation**: Smooth message appearance
6. **Read Receipts**: Show when message read
7. **Chat History Export**: Download chat transcript
8. **Notification Badge**: Show unread count
