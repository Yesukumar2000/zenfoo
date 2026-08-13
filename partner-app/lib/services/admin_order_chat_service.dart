import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin chat message model for seller-to-admin communication
class AdminChatMessage {
  final String id;
  final int sellerId;
  final int orderId;
  final String senderType; // 'seller' or 'admin'
  final String senderId;
  final String senderName;
  final String recipientType;
  final String message;
  final DateTime timestamp;
  final bool read;

  AdminChatMessage({
    required this.id,
    required this.sellerId,
    required this.orderId,
    required this.senderType,
    this.senderId = '',
    this.senderName = '',
    this.recipientType = '',
    required this.message,
    required this.timestamp,
    required this.read,
  });

  factory AdminChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    try {
      if (json['timestamp'] is Timestamp) {
        ts = (json['timestamp'] as Timestamp).toDate();
      } else if (json['timestamp_ms'] is int) {
        ts = DateTime.fromMillisecondsSinceEpoch(json['timestamp_ms']);
      } else if (json['timestamp'] is String) {
        ts = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
      } else {
        ts = DateTime.now();
      }
    } catch (e) {
      debugPrint("Timestamp parse error: $e");
      ts = DateTime.now();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AdminChatMessage(
      id: json['id']?.toString() ?? '',
      sellerId: parseInt(json['seller_id']),
      orderId: parseInt(json['order_id']),
      senderType: json['sender_type']?.toString() ?? 'seller',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      recipientType: json['recipient_type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: ts,
      read: json['read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'order_id': orderId,
      'sender_type': senderType,
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient_type': recipientType,
      'message': message,
      'timestamp': timestamp,
      'read': read,
    };
  }
}

/// Firestore Chat Service
class AdminChatService {
  static final AdminChatService _instance = AdminChatService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AdminChatService() => _instance;
  AdminChatService._internal();

  /// Get reference to the order_chats/{orderId} document
  DocumentReference _orderChatDoc(int orderId) {
    return _firestore.collection('order_chats').doc(orderId.toString());
  }

  /// Get reference to the messages collection: order_chats/{orderId}/seller_{sellerId}
  CollectionReference _messagesCollection(int orderId, int sellerId) {
    return _orderChatDoc(orderId).collection('seller_$sellerId');
  }

  /// Ensure order chat document exists
  Future<void> _ensureOrderChatExists(int orderId, int sellerId) async {
    try {
      final orderDoc = _orderChatDoc(orderId);
      final docSnapshot = await orderDoc.get();

      if (!docSnapshot.exists) {
        // Create the order chat document
        await orderDoc.set({
          'order_id': orderId.toString(),
          'created_at': FieldValue.serverTimestamp(),
        });
        debugPrint("Created order_chats/$orderId document");
      }

      // Check if seller subcollection metadata exists
      final sellerDocRef = orderDoc.collection('seller_$sellerId').doc('_metadata');
      final sellerDoc = await sellerDocRef.get();

      if (!sellerDoc.exists) {
        await sellerDocRef.set({
          'seller_id': sellerId,
          'order_id': orderId.toString(),
          'created_at': FieldValue.serverTimestamp(),
        });
        debugPrint("Created seller_$sellerId metadata");
      }
    } catch (e) {
      debugPrint("Error ensuring chat exists: $e");
    }
  }

  /// STREAM MESSAGES
  Stream<List<AdminChatMessage>> getChatMessagesStream(int orderId, int sellerId) {
    debugPrint("Subscribing to chat: order_chats/$orderId/seller_$sellerId");

    try {
      return _messagesCollection(orderId, sellerId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        final msgs = snapshot.docs
            .where((doc) => doc.id != '_metadata') // Exclude metadata doc
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return AdminChatMessage.fromJson({
            ...data,
            'id': doc.id,
          });
        }).toList();

        debugPrint("Chat messages received: ${msgs.length}");
        return msgs;
      }).handleError((e) {
        debugPrint("Stream error: $e");
        return <AdminChatMessage>[];
      });
    } catch (e) {
      debugPrint("Stream init error: $e");
      return Stream.value([]);
    }
  }

  /// ADD MESSAGE
  Future<void> addMessage({
    required int sellerId,
    required int orderId,
    required String message,
    required String senderType,
    String? senderName,
    String? senderId,
  }) async {
    debugPrint("Adding message: order=$orderId seller=$sellerId");

    try {
      // Ensure the document structure exists
      await _ensureOrderChatExists(orderId, sellerId);

      final now = DateTime.now();
      final collection = _messagesCollection(orderId, sellerId);

      final payload = {
        'seller_id': sellerId,
        'order_id': orderId.toString(),
        'sender_type': senderType,
        'sender_id': senderId ?? sellerId.toString(),
        'sender_name': senderName ?? (senderType == 'seller' ? 'Seller' : 'Admin'),
        'recipient_type': senderType == 'seller' ? 'admin' : 'seller',
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'timestamp_ms': now.millisecondsSinceEpoch,
        'read': false,
      };

      final docRef = await collection.add(payload);
      debugPrint("Message sent: ${docRef.path}");
    } catch (e) {
      debugPrint("Send message error: $e");
      rethrow;
    }
  }

  /// MARK SINGLE MESSAGE READ
  Future<void> markMessageAsRead(int orderId, int sellerId, String messageId) async {
    try {
      await _messagesCollection(orderId, sellerId).doc(messageId).update({'read': true});
    } catch (e) {
      debugPrint("Mark read error: $e");
    }
  }

  /// MARK ALL READ (for admin messages received by seller)
  Future<void> markAllMessagesAsRead(int orderId, int sellerId) async {
    try {
      final snapshot = await _messagesCollection(orderId, sellerId)
          .where('read', isEqualTo: false)
          .where('recipient_type', isEqualTo: 'seller')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'read': true});
      }
      debugPrint("Marked ${snapshot.docs.length} messages as read");
    } catch (e) {
      debugPrint("Mark all read error: $e");
    }
  }

  /// UNREAD COUNT (messages from admin to seller)
  Future<int> getUnreadMessageCount(int orderId, int sellerId) async {
    try {
      final snapshot = await _messagesCollection(orderId, sellerId)
          .where('read', isEqualTo: false)
          .where('recipient_type', isEqualTo: 'seller')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint("Unread count error: $e");
      return 0;
    }
  }

  /// UNREAD COUNT STREAM
  Stream<int> getUnreadMessageCountStream(int orderId, int sellerId) {
    try {
      return _messagesCollection(orderId, sellerId)
          .where('read', isEqualTo: false)
          .where('recipient_type', isEqualTo: 'seller')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint("Unread stream error: $e");
      return Stream.value(0);
    }
  }

  /// DELETE MESSAGE
  Future<void> deleteMessage(int orderId, int sellerId, String messageId) async {
    try {
      await _messagesCollection(orderId, sellerId).doc(messageId).delete();
    } catch (e) {
      debugPrint("Delete error: $e");
      rethrow;
    }
  }

  /// LAST MESSAGE
  Future<AdminChatMessage?> getLastMessage(int orderId, int sellerId) async {
    try {
      final snapshot = await _messagesCollection(orderId, sellerId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      if (doc.id == '_metadata') return null;

      return AdminChatMessage.fromJson({
        ...(doc.data() as Map<String, dynamic>? ?? {}),
        'id': doc.id,
      });
    } catch (e) {
      debugPrint("Get last message error: $e");
      return null;
    }
  }
}
