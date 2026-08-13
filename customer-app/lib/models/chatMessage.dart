import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String senderType; // 'customer', 'admin', 'seller'
  final String recipientType; // 'admin', 'seller', 'customer'
  final String? recipientId; // ID of recipient (admin ID, seller ID, etc.)
  final String message;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.recipientType,
    this.recipientId,
    required this.message,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      orderId: data['order_id'] as String? ?? '',
      senderId: data['sender_id'] as String? ?? '',
      senderName: data['sender_name'] as String? ?? 'Unknown',
      senderType: data['sender_type'] as String? ?? 'customer',
      recipientType: data['recipient_type'] as String? ?? 'admin',
      recipientId: data['recipient_id'] as String?,
      message: data['message'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'recipient_type': recipientType,
      if (recipientId != null) 'recipient_id': recipientId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  ChatMessage copyWith({
    String? id,
    String? orderId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? recipientType,
    String? recipientId,
    String? message,
    DateTime? timestamp,
    bool? read,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      recipientType: recipientType ?? this.recipientType,
      recipientId: recipientId ?? this.recipientId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}
