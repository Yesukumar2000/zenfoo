import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project/helper/utils/orderChatService.dart';
import 'package:project/models/chatMessage.dart';

class OrderChatProvider extends ChangeNotifier {
  final OrderChatService _chatService = OrderChatService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSending = false;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _unreadCountSubscription;

  int _unreadCount = 0;
  ChatMessage? _lastMessage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;
  int get unreadCount => _unreadCount;
  ChatMessage? get lastMessage => _lastMessage;

  /// Listen to messages stream for driver-customer chat
  void listenToDriverChat(
    String orderId, {
    String chatPath = 'customer_to_driver',
  }) {
    // Cancel previous subscription
    _messageSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _messageSubscription =
        _chatService.listenToDriverChat(orderId, chatPath: chatPath).listen(
      (messageList) {
        _messages = messageList;
        if (messageList.isNotEmpty) {
          _lastMessage = messageList.first;
        }
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Listen to unread message count in real-time
  void listenToUnreadCount(
    String orderId, {
    String senderType = 'driver',
    String chatPath = 'customer_to_driver',
  }) {
    // Cancel previous subscription
    _unreadCountSubscription?.cancel();

    _unreadCountSubscription = _chatService
        .getUnreadMessageCountStream(
          orderId,
          senderType: senderType,
          chatPath: chatPath,
        )
        .listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to unread count: $error');
      },
    );
  }

  /// Send a message to the driver
  Future<void> sendMessageToDriver({
    required String orderId,
    required String customerId,
    required String customerName,
    required String message,
    required int? driverId,
    BuildContext? context,
  }) async {
    if (message.trim().isEmpty) {
      _errorMessage = 'Message cannot be empty';
      notifyListeners();
      return;
    }

    _isSending = true;
    notifyListeners();

    try {
      await _chatService.sendMessageToDriver(
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        message: message.trim(),
        driverId: driverId,
        context: context,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Mark a specific message as read
  Future<void> markMessageAsRead(
    String orderId,
    String messageId, {
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      await _chatService.markMessageAsRead(
        orderId,
        messageId,
        chatPath: chatPath,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to mark message as read: $e';
      notifyListeners();
    }
  }

  /// Mark all unread messages from driver as read
  Future<void> markAllMessagesAsRead(
    String orderId, {
    String senderType = 'driver',
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      await _chatService.markAllMessagesAsRead(
        orderId,
        senderType: senderType,
        chatPath: chatPath,
      );
      _errorMessage = null;
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to mark messages as read: $e';
      notifyListeners();
    }
  }

  /// Get unread message count (one-time fetch)
  Future<int> getUnreadCount(
    String orderId, {
    String senderType = 'driver',
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      final count = await _chatService.getUnreadMessageCount(
        orderId,
        senderType: senderType,
        chatPath: chatPath,
      );
      _unreadCount = count;
      notifyListeners();
      return count;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get last message in the chat
  Future<ChatMessage?> getLastMessage(
    String orderId, {
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      final message = await _chatService.getLastMessage(
        orderId,
        chatPath: chatPath,
      );
      _lastMessage = message;
      notifyListeners();
      return message;
    } catch (e) {
      debugPrint('Error getting last message: $e');
      return null;
    }
  }

  /// Search messages by keyword
  Future<List<ChatMessage>> searchMessages(
    String orderId,
    String keyword, {
    String chatPath = 'customer_to_driver',
  }) async {
    try {
      return await _chatService.searchMessages(
        orderId,
        keyword,
        chatPath: chatPath,
      );
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
