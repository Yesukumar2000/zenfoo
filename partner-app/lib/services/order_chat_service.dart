import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Chat message model
class ChatMessage {
  final String id;
  final int orderId;
  final String senderType; // 'driver' or 'seller'
  final String receiverType; // 'seller' or 'driver'
  final String message;
  final DateTime timestamp;
  final bool read;
  final int? senderId;
  final int? receiverId;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderType,
    required this.receiverType,
    required this.message,
    required this.timestamp,
    required this.read,
    this.senderId,
    this.receiverId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? 0,
      senderType: json['sender_type'] ?? 'driver',
      receiverType: json['receiver_type'] ?? 'seller',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      read: json['read'] ?? false,
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'sender_type': senderType,
      'receiver_type': receiverType,
      'message': message,
      'timestamp': timestamp,
      'read': read,
      'sender_id': senderId,
      'receiver_id': receiverId,
    };
  }
}

/// Service to handle order chat operations
class OrderChatService {
  static final OrderChatService _instance = OrderChatService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory OrderChatService() {
    return _instance;
  }

  OrderChatService._internal();

  /// Get real-time stream of messages with specific sender and receiver types
  /// Firebase path: /chatting/{orderId}/{chatPath}/msg_{timestamp}
  /// chatPath examples: 'customer_to_driver', 'driver_to_seller'
  Stream<List<ChatMessage>> getChatMessagesStream(
    int orderId, {
    String senderType = 'driver',
    String receiverType = 'seller',
  }) {
    try {
      // Determine chat path based on sender and receiver types
      final chatPath = _getChatPath(senderType, receiverType);

      return _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      }).handleError((e) {
        debugPrint('❌ Error fetching chat messages: $e');
        return <ChatMessage>[];
      });
    } catch (e) {
      debugPrint('❌ Error in getChatMessagesStream: $e');
      return Stream.value([]);
    }
  }

  /// Determine the chat path based on sender and receiver types
  String _getChatPath(String senderType, String receiverType) {
    // Map sender_to_receiver patterns
    if (senderType == 'customer' && receiverType == 'driver') {
      return 'customer_to_driver';
    } else if (senderType == 'driver' && receiverType == 'customer') {
      return 'customer_to_driver'; // Same path, both directions
    } else if (senderType == 'driver' && receiverType == 'seller') {
      return 'driver_to_seller';
    } else if (senderType == 'seller' && receiverType == 'driver') {
      return 'driver_to_seller'; // Same path, both directions
    }
    return 'driver_to_seller'; // Default fallback
  }

  /// Get messages sent by a specific sender type in a given chat path
  Stream<List<ChatMessage>> getMessagesBySenderType(
    int orderId,
    String senderType, {
    String receiverType = 'seller',
  }) {
    try {
      final chatPath = _getChatPath(senderType, receiverType);

      return _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .where('sender_type', isEqualTo: senderType)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      });
    } catch (e) {
      debugPrint('❌ Error in getMessagesBySenderType: $e');
      return Stream.value([]);
    }
  }

  /// Add message to Firestore
  /// Firebase path: /chatting/{orderId}/{chatPath}/msg_{timestamp}
  Future<void> addMessage({
    required int orderId,
    required String message,
    required String senderType,
    required String receiverType,
    required int? senderId,
    required int? receiverId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = 'msg_$timestamp';
      final chatPath = _getChatPath(senderType, receiverType);

      await _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .doc(messageId)
          .set({
            'id': messageId,
            'order_id': orderId,
            'message': message.trim(),
            'sender_type': senderType,
            'receiver_type': receiverType,
            'sender_id': senderId,
            'receiver_id': receiverId,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'metadata': {
              'delivery_status': null,
              'attachment_url': null,
            }
          });

      debugPrint('✅ Message added to Firestore: $messageId at /chatting/$orderId/$chatPath/');
    } catch (e) {
      debugPrint('❌ Error adding message to Firestore: $e');
      rethrow;
    }
  }

  /// Mark a single message as read
  Future<void> markMessageAsRead(
    int orderId,
    String messageId, {
    String senderType = 'driver',
    String receiverType = 'seller',
  }) async {
    try {
      final chatPath = _getChatPath(senderType, receiverType);

      await _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .doc(messageId)
          .update({'read': true});

      debugPrint('✅ Message marked as read: $messageId');
    } catch (e) {
      debugPrint('⚠️ Error marking message as read: $e');
    }
  }

  /// Mark all unread messages from a sender type as read
  Future<void> markAllMessagesAsRead(
    int orderId,
    String senderType, {
    String receiverType = 'seller',
  }) async {
    try {
      final chatPath = _getChatPath(senderType, receiverType);

      final unreadMessages = await _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .where('sender_type', isEqualTo: senderType)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'read': true});
      }

      debugPrint(
          '✅ Marked ${unreadMessages.docs.length} messages as read from $senderType in $chatPath');
    } catch (e) {
      debugPrint('⚠️ Error marking all messages as read: $e');
    }
  }

  /// Get unread message count
  Future<int> getUnreadMessageCount(
    int orderId,
    String senderType, {
    String receiverType = 'seller',
  }) async {
    try {
      final chatPath = _getChatPath(senderType, receiverType);

      final snapshot = await _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .where('sender_type', isEqualTo: senderType)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('⚠️ Error getting unread count: $e');
      return 0;
    }
  }

  /// Get unread message count stream (real-time)
  Stream<int> getUnreadMessageCountStream(
    int orderId,
    String senderType, {
    String receiverType = 'seller',
  }) {
    try {
      final chatPath = _getChatPath(senderType, receiverType);

      return _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .where('sender_type', isEqualTo: senderType)
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('⚠️ Error in getUnreadMessageCountStream: $e');
      return Stream.value(0);
    }
  }

  /// Delete a message (use with caution)
  Future<void> deleteMessage(
    int orderId,
    String messageId, {
    String senderType = 'driver',
    String receiverType = 'seller',
  }) async {
    try {
      final chatPath = _getChatPath(senderType, receiverType);

      await _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .doc(messageId)
          .delete();

      debugPrint('✅ Message deleted: $messageId');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      rethrow;
    }
  }

  /// Get last message in chat
  Future<ChatMessage?> getLastMessage(
    int orderId, {
    String senderType = 'driver',
    String receiverType = 'seller',
  }) async {
    try {
      final chatPath = _getChatPath(senderType, receiverType);

      final snapshot = await _firestore
          .collection('chatting')
          .doc(orderId.toString())
          .collection(chatPath)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return ChatMessage.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      debugPrint('⚠️ Error getting last message: $e');
      return null;
    }
  }
}
