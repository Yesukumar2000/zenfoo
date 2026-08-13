class SupportChatMessage {
  final String messageId;
  final String message;
  final String sender;
  final int senderId;
  final String receiver;
  final int receiverId;
  final String date;
  final String time;
  final String timeDisplay;
  final bool read;

  SupportChatMessage({
    required this.messageId,
    required this.message,
    required this.sender,
    required this.senderId,
    required this.receiver,
    required this.receiverId,
    required this.date,
    required this.time,
    required this.timeDisplay,
    required this.read,
  });

  factory SupportChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle either string or Timestamp for time field
    String timeStr = '';
    final timeData = json['time'];
    if (timeData is String) {
      timeStr = timeData;
    } else if (timeData != null) {
      // Assuming it's a Firestore Timestamp if not a string
      try {
        timeStr = (timeData as dynamic).toDate().toIso8601String();
      } catch (e) {
        timeStr = timeData.toString();
      }
    }

    return SupportChatMessage(
      messageId: json['message_id'] ?? '',
      message: json['message'] ?? '',
      sender: json['sender'] ?? '',
      senderId: json['sender_id'] ?? 0,
      receiver: json['receiver'] ?? '',
      receiverId: json['receiver_id'] ?? 0,
      date: json['date'] ?? '',
      time: timeStr,
      timeDisplay: json['time_display'] ?? '',
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'message': message,
      'sender': sender,
      'sender_id': senderId,
      'receiver': receiver,
      'receiver_id': receiverId,
      'date': date,
      'time': time,
      'time_display': timeDisplay,
      'read': read,
    };
  }

  Map<String, dynamic> toFirebase() {
    return {
      'message_id': messageId,
      'message': message,
      'sender': sender,
      'sender_id': senderId,
      'receiver': receiver,
      'receiver_id': receiverId,
      'date': date,
      'time': time,
      'time_display': timeDisplay,
      'read': read,
    };
  }

  SupportChatMessage copyWith({
    String? messageId,
    String? message,
    String? sender,
    int? senderId,
    String? receiver,
    int? receiverId,
    String? date,
    String? time,
    String? timeDisplay,
    bool? read,
  }) {
    return SupportChatMessage(
      messageId: messageId ?? this.messageId,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      senderId: senderId ?? this.senderId,
      receiver: receiver ?? this.receiver,
      receiverId: receiverId ?? this.receiverId,
      date: date ?? this.date,
      time: time ?? this.time,
      timeDisplay: timeDisplay ?? this.timeDisplay,
      read: read ?? this.read,
    );
  }
}
