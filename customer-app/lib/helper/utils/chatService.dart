import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:project/helper/utils/constant.dart';
import 'package:project/helper/utils/generalMethods.dart';
import 'package:project/models/chatMessage.dart';
import 'package:flutter/material.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to messages for a specific order and chat type
  /// Collection path: order_chats/{orderId}/{chatType} (direct collection)
  /// chatType can be: 'customer', 'seller', 'admin', 'driver', etc.
  Stream<List<ChatMessage>> listenToMessages(
    String orderId, {
    String chatType = 'customer',
  }) {
    return _firestore
        .collection('order_chats')
        .doc(orderId)
        .collection(chatType)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Send a message to a specific chat type using API
  /// API: POST /api/admin/order/chat/send
  Future<void> sendMessage({
    required String orderId,
    required String customerId,
    required String customerName,
    required String message,
    String chatType = 'customer',
    BuildContext? context,
  }) async {
    try {
      final messageData = {
        'order_id': orderId,
        'message': message,
      };

      // Send notification via API
      if (context != null) {
        final res = await sendApiRequest(
          apiName: '${Constant.hostUrl}customer/support-chat/order/send',
          isPost: true,
          context: context,
          params: messageData,
        );
        if (res != null) {
          final decoded = jsonDecode(res);
          if (decoded['status'] != 1) {
            debugPrint('API error: ${decoded['message']}');
          }
        }
      }

      // Write to Firebase
      await _sendMessageToFirebase(
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        message: message,
        chatType: chatType,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> _sendMessageToFirebase({
    required String orderId,
    required String customerId,
    required String customerName,
    required String message,
    String chatType = 'customer',
  }) async {
    try {
      final messageData = {
        'order_id': orderId,
        'sender_id': customerId,
        'sender_name': customerName,
        'sender_type': 'customer',
        'recipient_type': 'admin',
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      await _firestore
          .collection('order_chats')
          .doc(orderId)
          .collection(chatType)
          .add(messageData);

      debugPrint('Message sent to $chatType chat for order $orderId');
    } catch (e) {
      debugPrint('Error sending message to Firebase: $e');
      rethrow;
    }
  }

  /// Update a specific message as read
  Future<void> markMessageAsRead(
    String orderId,
    String messageId, {
    String chatType = 'customer',
  }) async {
    try {
      await _firestore
          .collection('order_chats')
          .doc(orderId)
          .collection(chatType)
          .doc(messageId)
          .update({'read': true});

      debugPrint('Marked message $messageId as read in $chatType chat');
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Mark all unread messages as read for a specific chat type
  Future<void> markAllMessagesAsRead(
    String orderId, {
    String chatType = 'customer',
  }) async {
    try {
      final batch = _firestore.batch();

      final unreadMessages = await _firestore
          .collection('order_chats')
          .doc(orderId)
          .collection(chatType)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
        debugPrint(
            'Marked ${unreadMessages.docs.length} messages as read in $chatType chat for order $orderId');
      }
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }
}
