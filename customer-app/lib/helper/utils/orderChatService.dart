import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:project/helper/utils/constant.dart';
import 'package:project/helper/utils/generalMethods.dart';
import 'package:project/models/chatMessage.dart';
import 'package:flutter/material.dart';

class OrderChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to messages between customer and driver
  /// Chat path: /chatting/{orderId}/customer_to_driver/msg_{timestamp}
  Stream<List<ChatMessage>> listenToDriverChat(
    String orderId, {
    String chatPath = 'customer_to_driver',
  }) {
    return _firestore
        .collection('chatting')
        .doc(orderId)
        .collection(chatPath)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.id, _convertMapForChat(doc.data())))
          .toList();
    });
  }

  /// Convert message data to ChatMessage format
  Map<String, dynamic> _convertMapForChat(Map<String, dynamic> data) {
    return {
      'order_id': data['order_id']?.toString() ?? '',
      'sender_id': data['sender_id']?.toString() ?? '',
      'sender_name': data['sender_name']?.toString() ?? 'Unknown',
      'sender_type': data['sender_type']?.toString() ?? 'customer',
      'recipient_type': data['receiver_type']?.toString() ?? 'driver',
      'recipient_id': data['receiver_id']?.toString(),
      'message': data['message']?.toString() ?? '',
      'timestamp': data['timestamp'],
      'read': data['read'] ?? false,
    };
  }

  /// Send a message from customer to driver
  /// Stores in: /chatting/{orderId}/customer_to_driver/msg_{timestamp}
  Future<void> sendMessageToDriver({
    required String orderId,
    required String customerId,
    required String customerName,
    required String message,
    required int? driverId,
    BuildContext? context,
  }) async {
    try {
      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final messageId = 'msg_$timestamp';

      final messageData = {
        'id': messageId,
        'order_id': int.tryParse(orderId) ?? 0,
        'message': message.trim(),
        'sender_type': 'customer',
        'receiver_type': 'driver',
        'sender_id': int.tryParse(customerId) ?? 0,
        'receiver_id': driverId ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'metadata': {
          'delivery_status': null,
          'attachment_url': null,
        },
      };

      // Add to Firebase
      await _firestore
          .collection('chatting')
          .doc(orderId)
          .collection('customer_to_driver')
          .doc(messageId)
          .set(messageData);

      debugPrint('Message sent to driver for order $orderId');

      // Also send via API if context is available
      if (context != null) {
        try {
          await _sendMessageViaApi(
            orderId: orderId,
            message: message.trim(),
            senderType: 'customer',
            receiverType: 'driver',
            context: context,
          );
        } catch (e) {
          debugPrint('API send failed but Firebase succeeded: $e');
        }
      }
    } catch (e) {
      debugPrint('Error sending message to driver: $e');
      rethrow;
    }
  }

  /// Send message via API endpoint
  Future<void> _sendMessageViaApi({
    required String orderId,
    required String message,
    required String senderType,
    required String receiverType,
    required BuildContext context,
  }) async {
    try {
      final messageData = {
        'order_id': orderId,
        'message': message,
        'sender_type': senderType,
        'receiver_type': receiverType,
      };

      final res = await sendApiRequest(
        apiName: '${Constant.hostUrl}api/order/chat/send',
        isPost: true,
        context: context,
        params: messageData,
      );

      if (res != null) {
        final decoded = jsonDecode(res);
        if (decoded['status'] == 1) {
          debugPrint('Message sent via API for order $orderId');
        }
      }
    } catch (e) {
      debugPrint('Error sending message via API: $e');
    }
  }

  /// Mark a specific message as read
  Future<void> markMessageAsRead(
    String orderId,
    String messageId, {
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      await _firestore
          .collection('chatting')
          .doc(orderId)
          .collection(chatPath)
          .doc(messageId)
          .update({'read': true});

      debugPrint('Marked message $messageId as read');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark all unread messages from a sender as read
  Future<void> markAllMessagesAsRead(
    String orderId, {
    String senderType = 'driver',
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      final batch = _firestore.batch();

      final unreadMessages = await _firestore
          .collection('chatting')
          .doc(orderId)
          .collection(chatPath)
          .where('read', isEqualTo: false)
          .where('sender_type', isEqualTo: senderType)
          .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
        debugPrint(
            'Marked ${unreadMessages.docs.length} messages as read for order $orderId');
      }
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  /// Get count of unread messages from a specific sender
  Future<int> getUnreadMessageCount(
    String orderId, {
    String senderType = 'driver',
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      final unreadMessages = await _firestore
          .collection('chatting')
          .doc(orderId)
          .collection(chatPath)
          .where('read', isEqualTo: false)
          .where('sender_type', isEqualTo: senderType)
          .get();

      return unreadMessages.docs.length;
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }

  /// Get real-time stream of unread message count
  Stream<int> getUnreadMessageCountStream(
    String orderId, {
    String senderType = 'driver',
    String chatPath = 'customer_to_driver',
  }) {
    return _firestore
        .collection('chatting')
        .doc(orderId)
        .collection(chatPath)
        .where('read', isEqualTo: false)
        .where('sender_type', isEqualTo: senderType)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get the last message in a chat
  Future<ChatMessage?> getLastMessage(
    String orderId, {
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chatting')
          .doc(orderId)
          .collection(chatPath)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return ChatMessage.fromMap(doc.id, _convertMapForChat(doc.data()));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last message: $e');
      return null;
    }
  }

  /// Delete a message (soft delete or permanent)
  Future<void> deleteMessage(
    String orderId,
    String messageId, {
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      await _firestore
          .collection('chatting')
          .doc(orderId)
          .collection(chatPath)
          .doc(messageId)
          .delete();

      debugPrint('Deleted message $messageId');
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  /// Get paginated messages with limit and offset
  Future<List<ChatMessage>> getPaginatedMessages(
    String orderId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      Query query = _firestore
          .collection('chatting')
          .doc(orderId)
          .collection(chatPath)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.id, _convertMapForChat(doc.data() as Map<String, dynamic>)))
          .toList();
    } catch (e) {
      debugPrint('Error getting paginated messages: $e');
      return [];
    }
  }

  /// Search messages by keyword
  Future<List<ChatMessage>> searchMessages(
    String orderId,
    String keyword, {
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chatting')
          .doc(orderId)
          .collection(chatPath)
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final message = data['message']?.toString().toLowerCase() ?? '';
        return message.contains(keyword.toLowerCase());
      }).toList();

      return results
          .map((doc) => ChatMessage.fromMap(doc.id, _convertMapForChat(doc.data())))
          .toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }
}
