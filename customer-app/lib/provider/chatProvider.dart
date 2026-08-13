import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project/helper/utils/chatService.dart';
import 'package:project/models/chatMessage.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSending = false;
  String _currentChatType = 'customer'; // Current chat type being viewed
  StreamSubscription? _messageSubscription;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;
  String get currentChatType => _currentChatType;

  /// Listen to messages stream for a specific order and chat type
  void listenToMessages(
    String orderId, {
    String chatType = 'customer',
  }) {
    // Cancel previous subscription if exists
    _messageSubscription?.cancel();

    _currentChatType = chatType;
    _isLoading = true;
    notifyListeners();

    _messageSubscription =
        _chatService.listenToMessages(orderId, chatType: chatType).listen(
      (messageList) {
        _messages = messageList;
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

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  /// Send a message
  Future<void> sendMessage({
    required String orderId,
    required String customerId,
    required String customerName,
    required String message,
    String chatType = 'customer',
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
      await _chatService.sendMessage(
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        message: message.trim(),
        chatType: chatType,
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

  /// Mark all messages as read
  Future<void> markAllMessagesAsRead(
    String orderId, {
    String chatType = 'customer',
  }) async {
    try {
      await _chatService.markAllMessagesAsRead(
        orderId,
        chatType: chatType,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to mark messages as read: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
