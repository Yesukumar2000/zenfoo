import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/support_chat_model.dart';

class FirebaseSupportChatService {
  static final FirebaseSupportChatService _instance =
      FirebaseSupportChatService._internal();

  factory FirebaseSupportChatService() {
    return _instance;
  }

  FirebaseSupportChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get chat messages stream for delivery boy support
  Stream<List<SupportChatMessage>> getSupportChatMessagesStream(int deliveryBoyId) {
    return _firestore
        .collection('admin_delivery_boy_chatting')
        .doc(deliveryBoyId.toString())
        .collection('messages')
        .orderBy('time', descending: false)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => SupportChatMessage.fromJson({
                ...doc.data(),
                'message_id': doc.id,
              }))
          .toList();

      debugPrint('🔄 Firebase messages loaded: ${messages.length} messages');
      for (final msg in messages) {
        debugPrint('   - ${msg.sender}: ${msg.message} (${msg.timeDisplay})');
      }

      return messages;
    }).handleError((error) {
      debugPrint('❌ Firebase stream error: $error');
      return [];
    });
  }

  /// Add message to Firebase
  Future<void> addSupportMessage(
    int deliveryBoyId,
    SupportChatMessage message,
  ) async {
    try {
      await _firestore
          .collection('admin_delivery_boy_chatting')
          .doc(deliveryBoyId.toString())
          .collection('messages')
          .doc(message.messageId)
          .set(message.toFirebase());
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(int deliveryBoyId, String messageId) async {
    try {
      await _firestore
          .collection('admin_delivery_boy_chatting')
          .doc(deliveryBoyId.toString())
          .collection('messages')
          .doc(messageId)
          .update({'read': true});
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all messages as read
  Future<void> markAllMessagesAsRead(int deliveryBoyId) async {
    try {
      final snapshot = await _firestore
          .collection('admin_delivery_boy_chatting')
          .doc(deliveryBoyId.toString())
          .collection('messages')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count
  Future<int> getUnreadMessageCount(int deliveryBoyId) async {
    try {
      final snapshot = await _firestore
          .collection('admin_delivery_boy_chatting')
          .doc(deliveryBoyId.toString())
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('receiver', isEqualTo: 'delivery_boy')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count stream (real-time)
  Stream<int> getUnreadMessageCountStream(int deliveryBoyId) {
    return _firestore
        .collection('admin_delivery_boy_chatting')
        .doc(deliveryBoyId.toString())
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('receiver', isEqualTo: 'delivery_boy')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete message
  Future<void> deleteMessage(int deliveryBoyId, String messageId) async {
    try {
      await _firestore
          .collection('admin_delivery_boy_chatting')
          .doc(deliveryBoyId.toString())
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
