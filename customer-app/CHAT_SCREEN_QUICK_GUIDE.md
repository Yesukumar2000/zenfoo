# Chat Screen - Quick Implementation Guide

## What Was Created

### 1. Chat Model
**File**: `lib/models/chatMessage.dart`
- Handles message serialization to/from Firebase
- Auto-parses Firestore Timestamp fields

### 2. Firebase Service
**File**: `lib/helper/utils/chatService.dart`
- All Firebase Firestore operations
- Real-time message stream listener
- Mark as read functionality

### 3. State Management
**File**: `lib/provider/chatProvider.dart`
- Manages chat state with ChangeNotifier
- Handles message list, loading, errors

### 4. Chat UI Screen
**File**: `lib/screens/customerSupportScreen/customerSupportChatScreen.dart`
- Complete Material Design chat interface
- Auto-scrolls to bottom on new messages
- Customer messages on right (green), Admin on left (gray)

## How It Works

```
User taps Chat Button (Order Tracking Screen)
           ↓
Navigate to Chat Screen (MaterialPageRoute)
           ↓
On Load:
  1. Listen to Firebase messages stream
  2. Display all messages in reverse order (newest first)
  3. Mark all unread messages as read
           ↓
User sends message:
  1. Type message → tap send
  2. Message added to Firebase
  3. Stream listener detects update
  4. Message appears in list
  5. Auto-scroll to bottom
           ↓
Admin sends message:
  1. Admin updates Firebase
  2. Stream listener detects new message
  3. Message appears on left side
  4. Auto-marked as read
```

## Firebase Structure

```
admin_customer_chatting/
└── {customer_phone}/
    └── messages/
        └── {auto_generated_id}/
            ├── sender_id: "customer_phone" or "admin"
            ├── sender_name: "Customer Name" or "Admin"
            ├── receiver_id: "admin" or "customer_phone"
            ├── message: "Hello!"
            ├── time: Firestore Timestamp
            └── read: false/true
```

## Key Features

| Feature | Implementation |
|---------|-----------------|
| Real-Time Messages | Firestore Stream snapshots |
| Auto-Scroll | ScrollController animateTo() |
| Message Separation | sender_id == customerId check |
| Auto Mark as Read | listenToMessages() → markAllMessagesAsRead() |
| Loading State | isSending flag |
| Empty State | No messages message |
| Time Format | Custom _formatTime() method |
| Error Handling | Provider errorMessage property |

## Navigation Setup

**From**: Order Tracking Screen chat button
**To**: Customer Support Chat Screen
**Method**: `Navigator.push()` with MaterialPageRoute
**Provider**: ChatProvider injected via MultiProvider

## Firestore Rules Required

```firestore rules
match /admin_customer_chatting/{customerId}/messages/{messageId} {
  allow read: if request.auth.uid == customerId || request.auth.uid == 'admin'
  allow create: if request.auth.uid == customerId
  allow update: if request.auth.uid == 'admin' || request.auth.uid == customerId
}
```

## Message Read Logic

- **When marked as read**: Only messages where `receiver_id == customerId`
- **Batch operation**: Uses Firestore batch for efficiency
- **Automatic**: Runs on screen load via `markAllMessagesAsRead()`

## UI Layout

```
┌─────────────────────────────────┐
│  ◄  Customer Support            │  ← AppBar (Primary Color)
├─────────────────────────────────┤
│                                 │
│                      You  13:45  │  ← Customer Message (Right, Green)
│                       Hello!     │
│                                 │
│ Admin  13:47                    │  ← Admin Message (Left, Gray)
│  Hi there, how can we help?     │
│                                 │
│                      You  14:20  │
│                I have a question │
│                                 │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Type message...         [→] │ │  ← Input Field + Send Button
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## Usage Example

From Order Tracking Screen:
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

## Testing

1. **Send Message**: Type and send a message → appears on right side
2. **Admin Reply**: Manually add message to Firebase with sender_id: "admin"
3. **Read Status**: Check Firebase - received messages should have read: true
4. **Auto Scroll**: Send message → chat scrolls to bottom automatically
5. **Time Display**: Verify correct time format based on current date

## Files Modified

- ✅ `lib/screens/orderTrackingScreen.dart` - Added chat button navigation
- ✅ `lib/provider/chatProvider.dart` - New file
- ✅ `lib/helper/utils/chatService.dart` - New file
- ✅ `lib/models/chatMessage.dart` - New file
- ✅ `lib/screens/customerSupportScreen/customerSupportChatScreen.dart` - New file

## No Changes Required

❌ `lib/helper/utils/routeGenerator.dart` - Using MaterialPageRoute directly
❌ Route constants - Not needed, direct navigation
❌ Other files - All self-contained

## Ready to Use ✅

The chat implementation is complete and ready for testing. Just ensure:
1. Firebase is initialized
2. Firestore has the correct collection structure
3. User is authenticated (customer phone number in session)

All real-time synchronization will work automatically through Firestore streams!
