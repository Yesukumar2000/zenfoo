import 'package:flutter/material.dart';
import '../models/order_earnings_chat_model.dart';
import '../services/order_earnings_chat_service.dart';
import '../repository/order_earnings_repository.dart';
import '../services/status.dart';

class OrderEarningsChatProvider extends ChangeNotifier {
  final OrderEarningsChatService _service = OrderEarningsChatService();
  final OrderEarningsRepository _repository = OrderEarningsRepository();

  bool _isSending = false;
  bool _isLoadingFAQ = false;
  String _errorMessage = '';

  bool get isSending => _isSending;
  bool get isLoadingFAQ => _isLoadingFAQ;
  String get errorMessage => _errorMessage;

  Stream<List<OrderEarningsChatMessage>> getMessagesStream(int orderId) {
    return _service.getOrderChatMessagesStream(orderId);
  }

  Future<void> sendMessage(int orderId, String text) async {
    if (text.trim().isEmpty) return;

    _isSending = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final message = OrderEarningsChatMessage(
        messageId: '',
        message: text.trim(),
        sender: 'driver',
        timestamp: DateTime.now(),
      );
      await _service.addMessage(orderId, message);
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> markAllMessagesAsRead(int orderId) async {
    try {
      await _service.markAllMessagesAsRead(orderId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> markMessageAsRead(int orderId, String messageId) async {
    try {
      await _service.markMessageAsRead(orderId, messageId);
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Fetch FAQ questions for the chatbot
  Future<ApiResponse> fetchFAQ(int orderId) async {
    _isLoadingFAQ = true;
    notifyListeners();
    try {
      return await _repository.getChatFAQ(orderId: orderId.toString());
    } finally {
      _isLoadingFAQ = false;
      notifyListeners();
    }
  }

  /// Submit FAQ selection and get answer
  Future<ApiResponse> submitFAQ(int orderId, String questionKey) async {
    return await _repository.submitChatAnswer(
      orderId: orderId.toString(),
      questionKey: questionKey,
    );
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
