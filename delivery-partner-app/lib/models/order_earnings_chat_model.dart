import 'package:cloud_firestore/cloud_firestore.dart';

class OrderEarningsChatMessage {
  final String messageId;
  final String message;
  final String sender; // 'driver' or 'admin'
  final DateTime timestamp;
  final bool read;

  OrderEarningsChatMessage({
    required this.messageId,
    required this.message,
    required this.sender,
    required this.timestamp,
    this.read = false,
  });

  factory OrderEarningsChatMessage.fromJson(Map<String, dynamic> json) {
    return OrderEarningsChatMessage(
      messageId: json['message_id'] ?? '',
      message: json['message'] ?? '',
      sender: json['sender'] ?? 'driver',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
              DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'sender': sender,
      'timestamp': FieldValue.serverTimestamp(),
      'read': read,
    };
  }

  String get timeDisplay {
    final hour = timestamp.hour > 12
        ? timestamp.hour - 12
        : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
