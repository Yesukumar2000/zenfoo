import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_earnings_chat_model.dart';

class OrderEarningsChatService {
  static final OrderEarningsChatService _instance =
      OrderEarningsChatService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory OrderEarningsChatService() {
    return _instance;
  }

  OrderEarningsChatService._internal();

  /// Get chat messages stream for a specific order
  /// Path: order_chats/{orderId}/driver
  Stream<List<OrderEarningsChatMessage>> getOrderChatMessagesStream(
      int orderId) {
    try {
      return _firestore
          .collection('order_chats')
          .doc(orderId.toString())
          .collection('driver')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        debugPrint(
            '📥 Received ${snapshot.docs.length} messages from order_chats/$orderId/driver');
        return snapshot.docs
            .map((doc) => OrderEarningsChatMessage.fromJson({
                  ...doc.data(),
                  'message_id': doc.id,
                }))
            .toList();
      }).handleError((e) {
        debugPrint('❌ Error fetching chat messages: $e');
        return <OrderEarningsChatMessage>[];
      });
    } catch (e) {
      debugPrint('❌ Error in getOrderChatMessagesStream: $e');
      return Stream.value([]);
    }
  }

  /// Add a message to the order chat
  /// Uses .doc(messageId).set() + FieldValue.serverTimestamp()
  Future<void> addMessage(int orderId, OrderEarningsChatMessage message) async {
    try {
      final messageId =
          'msg_${DateTime.now().millisecondsSinceEpoch.toString()}';

      final docRef = _firestore
          .collection('order_chats')
          .doc(orderId.toString())
          .collection('driver')
          .doc(messageId);

      debugPrint(
          '📤 Writing to Firestore: order_chats/$orderId/driver/$messageId');

      final data = {
        'message': message.message.trim(),
        'sender': message.sender,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Write the message
      await docRef.set(data);
      debugPrint('📝 Local cache write complete');

      // Verify the write reached the server
      try {
        final serverDoc =
            await docRef.get(const GetOptions(source: Source.server));
        if (serverDoc.exists) {
          debugPrint(
              '✅ Server confirmed: /order_chats/$orderId/driver/$messageId');
        } else {
          debugPrint(
              '⚠️ Server says document does not exist — possible security rule rejection');
          throw Exception(
              'Message was cached locally but rejected by server. Check Firestore security rules for path: order_chats/$orderId/driver');
        }
      } catch (e) {
        debugPrint('❌ Server verification failed: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error adding message to Firestore: $e');
      rethrow;
    }
  }

  /// Mark a single message as read
  Future<void> markMessageAsRead(int orderId, String messageId) async {
    try {
      await _firestore
          .collection('order_chats')
          .doc(orderId.toString())
          .collection('driver')
          .doc(messageId)
          .update({'read': true});
    } catch (e) {
      debugPrint('⚠️ Error marking message as read: $e');
    }
  }

  /// Mark all admin messages as read for the driver
  Future<void> markAllMessagesAsRead(int orderId) async {
    try {
      final snapshot = await _firestore
          .collection('order_chats')
          .doc(orderId.toString())
          .collection('driver')
          .where('read', isEqualTo: false)
          .where('sender', isEqualTo: 'admin')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'read': true});
      }

      debugPrint('✅ Marked ${snapshot.docs.length} messages as read');
    } catch (e) {
      debugPrint('⚠️ Error marking all messages as read: $e');
    }
  }
}
