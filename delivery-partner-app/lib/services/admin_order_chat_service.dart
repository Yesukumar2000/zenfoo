import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Chat message model for driver-admin communication
class AdminChatMessage {
  final String id;
  final String orderId;
  final String message;
  final String senderType; // 'driver' or 'admin'
  final String senderId;
  final String senderName;
  final String recipientType; // 'driver' or 'admin'
  final DateTime timestamp;
  final bool read;

  AdminChatMessage({
    required this.id,
    required this.orderId,
    required this.message,
    required this.senderType,
    required this.senderId,
    required this.senderName,
    required this.recipientType,
    required this.timestamp,
    required this.read,
  });

  factory AdminChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminChatMessage(
      id: doc.id,
      orderId: data['order_id']?.toString() ?? '',
      message: data['message'] ?? '',
      senderType: data['sender_type'] ?? 'admin',
      senderId: data['sender_id']?.toString() ?? '',
      senderName: data['sender_name'] ?? '',
      recipientType: data['recipient_type'] ?? 'driver',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'message': message,
      'sender_type': senderType,
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient_type': recipientType,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read,
    };
  }
}

/// Service to handle driver-admin chat operations via Firebase
class AdminOrderChatService {
  static final AdminOrderChatService _instance = AdminOrderChatService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AdminOrderChatService() {
    return _instance;
  }

  AdminOrderChatService._internal();

  /// Get collection reference for driver messages
  CollectionReference _getDriverMessagesCollection(int orderId) {
    return _firestore
        .collection('order_chats')
        .doc(orderId.toString())
        .collection('driver');
  }

  /// Get real-time stream of all messages for an order
  Stream<List<AdminChatMessage>> getMessagesStream(int orderId) {
    try {
      return _getDriverMessagesCollection(orderId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AdminChatMessage.fromFirestore(doc))
            .toList();
      }).handleError((e) {
        debugPrint('Error fetching admin chat messages: $e');
        return <AdminChatMessage>[];
      });
    } catch (e) {
      debugPrint('Error in getMessagesStream: $e');
      return Stream.value([]);
    }
  }

  /// Add message to Firestore
  Future<void> addMessage({
    required int orderId,
    required String message,
    required String driverId,
    required String driverName,
  }) async {
    try {
      await _getDriverMessagesCollection(orderId).add({
        'order_id': orderId.toString(),
        'message': message.trim(),
        'sender_type': 'driver',
        'sender_id': driverId,
        'sender_name': driverName,
        'recipient_type': 'admin',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      debugPrint('Message added to order_chats/$orderId/driver');
    } catch (e) {
      debugPrint('Error adding message to Firestore: $e');
      rethrow;
    }
  }

  /// Mark a single message as read
  Future<void> markMessageAsRead(int orderId, String messageId) async {
    try {
      await _getDriverMessagesCollection(orderId)
          .doc(messageId)
          .update({'read': true});
      debugPrint('Message marked as read: $messageId');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark all unread messages from admin as read
  Future<void> markAllMessagesAsRead(int orderId) async {
    try {
      final unreadMessages = await _getDriverMessagesCollection(orderId)
          .where('sender_type', isEqualTo: 'admin')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'read': true});
      }

      debugPrint('Marked ${unreadMessages.docs.length} messages as read');
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  /// Get unread message count from admin
  Stream<int> getUnreadCountStream(int orderId) {
    try {
      return _getDriverMessagesCollection(orderId)
          .where('sender_type', isEqualTo: 'admin')
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('Error in getUnreadCountStream: $e');
      return Stream.value(0);
    }
  }

  /// Initialize chat document for an order (creates parent doc if needed)
  Future<void> initializeChat(int orderId) async {
    try {
      final docRef = _firestore.collection('order_chats').doc(orderId.toString());
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'order_id': orderId.toString(),
          'created_at': FieldValue.serverTimestamp(),
        });
        debugPrint('Initialized chat for order $orderId');
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    }
  }
}
