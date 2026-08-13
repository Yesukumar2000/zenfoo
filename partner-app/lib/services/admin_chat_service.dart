import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin chat message model for seller-to-admin communication
class AdminChatMessage {
  final String id;
  final String message;
  final String sender;
  final String receiver;
  final int senderId;
  final int receiverId;
  final bool read;
  final DateTime? time;
  final String date;
  final String timeDisplay;

  AdminChatMessage({
    required this.id,
    required this.message,
    required this.sender,
    required this.receiver,
    required this.senderId,
    required this.receiverId,
    required this.read,
    required this.time,
    required this.date,
    required this.timeDisplay,
  });

  factory AdminChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parsedTime;

    final rawTime = data['time'];

    if (rawTime is Timestamp) {
      parsedTime = rawTime.toDate();
    } else if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime);
    }

    int parseInt(v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AdminChatMessage(
      id: data['message_id'] ?? doc.id,
      message: data['message'] ?? '',
      sender: data['sender'] ?? '',
      receiver: data['receiver'] ?? '',
      senderId: parseInt(data['sender_id']),
      receiverId: parseInt(data['receiver_id']),
      read: data['read'] ?? false,
      time: parsedTime,
      date: '',
      timeDisplay: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': id,
      'message': message,
      'sender': sender,
      'receiver': receiver,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'read': read,
      'time': time?.toIso8601String(),
      'date': date,
      'time_display': timeDisplay,
    };
  }
}

/// Service to handle seller-to-admin chat operations
/// Firebase structure: order_chats/{orderId}/driver/seller_{sellerId}/messages/{message_id}
class AdminChat {
  static final AdminChat _instance = AdminChat._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AdminChat() {
    return _instance;
  }

  AdminChat._internal();

  /// Helper: reference to the messages collection for a seller inside an order
  /// Helper: reference to the messages collection for a seller for admin chats
  /// New path: admin_seller_chatting/{sellerId}/messages/{messageId}
  /// Note: `orderId` parameter is kept for compatibility but not used in path.
  CollectionReference _messagesCollections(int sellerId) {
    return _firestore
        .collection('admin_seller_chatting')
        .doc(sellerId.toString())
        .collection('messages');
  }

  /// Get real-time stream of messages for a specific seller + order
  /// Firebase path: order_chats/{orderId}/seller_{sellerId}/
  Stream<List<AdminChatMessage>> getChatMessagesStreams(int sellerId) {
    return _messagesCollections(sellerId)
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AdminChatMessage.fromDoc(doc))
          .where((msg) => msg.time != null) // filter null timestamps
          .toList();

      return list;
    });
  }

  /// Add message to Firestore for seller-to-admin communication
  /// Firebase path: order_chats/{orderId}/seller_{sellerId}/{message_id}
  Future<void> addMessages({
    required int sellerId,
    required int orderId,
    required String message,
    required String senderType, // 'seller' or 'admin'
  }) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final messageId = 'msg_$timestamp';

      // Write the message into the seller collection inside order_chats
      await _messagesCollections(sellerId).doc(messageId).set({
        'message_id': messageId,
        'message': message.trim(),
        'sender': senderType,
        'receiver': 'admin',
        'sender_id': sellerId,
        'receiver_id': sellerId,
        'read': false,
        'time': Timestamp.now(),
      });

    
    } catch (e) {
      debugPrint('❌ Error adding admin message to Firestore: $e');
      rethrow;
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(int sellerId, String messageId) async {
    try {
      await _messagesCollections(sellerId)
          .doc(messageId)
          .update({'read': true});

      debugPrint('✅ Admin message marked as read: $messageId');
    } catch (e) {
      debugPrint('⚠️ Error marking admin message as read: $e');
    }
  }

  /// Mark all unread messages as read
  Future<void> markAllMessagesAsRead(int sellerId) async {
    try {
      final unreadMessages = await _messagesCollections(sellerId)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'read': true});
      }

      debugPrint(
          '✅ Marked ${unreadMessages.docs.length} admin messages as read for seller_$sellerId');
    } catch (e) {
      debugPrint('⚠️ Error marking all admin messages as read: $e');
    }
  }

  /// Get unread message count
  Future<int> getUnreadMessageCount(int sellerId) async {
    try {
      final snapshot = await _messagesCollections(sellerId)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('⚠️ Error getting admin unread count: $e');
      return 0;
    }
  }

  /// Get unread message count stream (real-time)
  Stream<int> getUnreadMessageCountStream(int orderId, int sellerId) {
    try {
      return _messagesCollections(sellerId)
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('⚠️ Error in getUnreadMessageCountStream: $e');
      return Stream.value(0);
    }
  }

  /// Delete a message (use with caution)
  Future<void> deleteMessage(int sellerId, String messageId) async {
    try {
      await _messagesCollections(sellerId).doc(messageId).delete();

      debugPrint('✅ Admin message deleted: $messageId');
    } catch (e) {
      debugPrint('❌ Error deleting admin message: $e');
      rethrow;
    }
  }

  /// Get last message in chat
  Future<AdminChatMessage?> getLastMessages(int sellerId) async {
    try {
      final snapshot = await _messagesCollections(sellerId).get();

      if (snapshot.docs.isEmpty) return null;

      final docs =
          snapshot.docs.map((d) => AdminChatMessage.fromDoc(d)).toList();

      docs.sort(
          (a, b) => (b.time ?? DateTime(0)).compareTo(a.time ?? DateTime(0)));

      return docs.first;
    } catch (e) {
      debugPrint('⚠️ Error getting last admin message: $e');
      return null;
    }
  }
}
