# Support Chat Firebase Integration Guide

## Overview
The support chat system reads messages from Firebase Firestore in real-time and displays them in the UI with automatic read status updates.

## Firebase Structure
```
/admin_delivery_boy_chatting
  /{deliveryBoyId}
    /messages
      /{messageId}
        - message_id: "msg_1234567890"
        - message: "hello testing"
        - sender: "delivery_boy" | "admin"
        - sender_id: 14
        - receiver: "admin" | "delivery_boy"
        - receiver_id: 1 | 14
        - date: "2026-01-30"
        - time: "2026-01-30T18:32:33+05:30" (ISO 8601)
        - time_display: "06:32 PM"
        - read: true | false
```

## How Messages Are Read From Firebase

### 1. **Firebase Service Layer** (`firebase_support_chat_service.dart`)
```dart
Stream<List<SupportChatMessage>> getSupportChatMessagesStream(int deliveryBoyId) {
  return _firestore
      .collection('admin_delivery_boy_chatting')
      .doc(deliveryBoyId.toString())
      .collection('messages')
      .orderBy('time', descending: false)  // Oldest first
      .snapshots()  // Real-time updates
      .map((snapshot) {
        // Convert Firestore documents to SupportChatMessage objects
        return snapshot.docs
            .map((doc) => SupportChatMessage.fromJson({
                  ...doc.data(),
                  'message_id': doc.id,
                }))
            .toList();
      })
      .handleError((error) {
        debugPrint('❌ Firebase stream error: $error');
        return [];
      });
}
```

**Key Features:**
- ✅ Real-time stream using `.snapshots()`
- ✅ Messages ordered by `time` (ascending - oldest first)
- ✅ Automatic error handling with fallback to empty list
- ✅ Debug logging for troubleshooting

### 2. **Provider Layer** (`support_chat_provider.dart`)
```dart
Stream<List<SupportChatMessage>> getSupportMessagesStream(int deliveryBoyId) {
  return _firebaseService.getSupportChatMessagesStream(deliveryBoyId);
}
```

Provides the Firebase stream directly to the UI layer.

### 3. **UI Layer** (`support_chat_screen.dart`)

**Reading Messages:**
```dart
StreamBuilder<List<SupportChatMessage>>(
  stream: context
      .read<SupportChatProvider>()
      .getSupportMessagesStream(deliveryBoyId),
  builder: (context, snapshot) {
    // Handle loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }

    // Handle errors
    if (snapshot.hasError) {
      return Text('Error loading messages');
    }

    // Get messages from snapshot
    final messages = snapshot.data ?? [];

    // Sort by time (oldest first for display)
    final sortedMessages = messages.toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    return ListView.builder(
      itemCount: sortedMessages.length,
      itemBuilder: (context, index) {
        final message = sortedMessages[index];
        // Display message in UI
      },
    );
  },
)
```

**Marking Messages As Read:**
```dart
// When admin message is displayed, mark it as read
if (!isDeliveryBoy && !message.read) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context
        .read<SupportChatProvider>()
        .markMessageAsRead(deliveryBoyId, message.messageId);
  });
}
```

## Message Display Logic

### Message Bubble Styling
```
DELIVERY BOY MESSAGE (Right-aligned)
┌────────────────────────┐
│ Hello, I have a problem │  ← Primary color background
│ 03:45 PM               │  ← Light text
└────────────────────────┘

ADMIN MESSAGE (Left-aligned)
┌──────────────────────────────┐
│ Hi! How can we help you?      │  ← Surface elevated background
│ 03:46 PM                      │  ← Secondary text
└──────────────────────────────┘
```

### Message Avatars
- **Delivery Boy:** Person icon in primary color circle
- **Admin:** Admin panel settings icon in primary color circle

## Auto-Scroll Behavior
```dart
// Auto scroll to latest message after frame render
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
});
```

## Real-Time Features

### ✅ Features Implemented
1. **Real-time message sync** - Firebase `snapshots()` stream
2. **Auto-scroll to latest** - Scrolls to bottom when new messages arrive
3. **Read status tracking** - Automatically marks admin messages as read
4. **Error handling** - Graceful error messages and logging
5. **Empty state** - Shows friendly message when no conversations
6. **Loading state** - Shows spinner while fetching initial messages
7. **Message sorting** - Orders by timestamp (oldest to newest)

### 🔄 Data Flow
```
Firebase Firestore
        ↓
FirebaseSupportChatService.getSupportChatMessagesStream()
        ↓
SupportChatProvider.getSupportMessagesStream()
        ↓
StreamBuilder in SupportChatScreen
        ↓
ListView displaying messages
```

## Debug Logging

The Firebase service includes detailed debug logging:

```
🔄 Firebase messages loaded: 3 messages
   - delivery_boy: hi (06:32 PM)
   - admin: Hello! (06:33 PM)
   - delivery_boy: thanks (06:34 PM)
```

Enable by checking Flutter console when messages are loaded.

## Troubleshooting

### Messages Not Loading?
1. Check Firestore database rules allow reading
2. Verify delivery boy ID is correct
3. Check network connectivity
4. Look for debug logs in console

### Messages Not Updating?
1. Ensure `snapshots()` stream is active
2. Check Firestore write permissions for Firebase service
3. Verify message is being saved to Firebase (check in prior message send)

### Read Status Not Updating?
1. Check `markMessageAsRead()` is being called
2. Verify Firestore has `write` permission
3. Check if message already marked as read

## Firebase Rules (Example)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /admin_delivery_boy_chatting/{deliveryBoyId}/messages/{messageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      allow update: if resource.data.receiver == 'delivery_boy';
    }
  }
}
```

## Summary

✅ **Complete Firebase integration for support chat**
- Real-time message reading from Firebase
- Automatic UI updates via StreamBuilder
- Read status tracking
- Error handling and logging
- Professional UI with distinct sender styling
