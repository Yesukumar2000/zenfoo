import 'package:flutter/material.dart';
import 'package:zenfoo_partner/services/admin_order_chat_service.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

/// FAQ item model for chatbot questions
class ChatFAQItem {
  final String key;
  final String question;

  ChatFAQItem({
    required this.key,
    required this.question,
  });

  factory ChatFAQItem.fromJson(Map<String, dynamic> json) {
    return ChatFAQItem(
      key: json['key']?.toString() ?? '',
      question: json['question'] ?? '',
    );
  }
}

/// Local message for UI display (FAQ Q&A before Firebase)
class LocalChatMessage {
  final String message;
  final bool isDriver;
  final bool isBot;
  final DateTime timestamp;

  LocalChatMessage({
    required this.message,
    required this.isDriver,
    this.isBot = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Provider for driver-admin chat functionality
class AdminOrderChatProvider extends ChangeNotifier {
  final AdminOrderChatService _chatService = AdminOrderChatService();
  final ApiService _apiService = ApiService();

  bool _isSending = false;
  bool _isLoadingFAQ = false;
  bool _isLoadingBotResponse = false;
  String _errorMessage = '';

  bool get isSending => _isSending;
  bool get isLoadingFAQ => _isLoadingFAQ;
  bool get isLoadingBotResponse => _isLoadingBotResponse;
  String get errorMessage => _errorMessage;

  /// Get real-time messages stream from Firebase
  Stream<List<AdminChatMessage>> getMessagesStream(int orderId) {
    return _chatService.getMessagesStream(orderId);
  }

  /// Get unread message count stream
  Stream<int> getUnreadCountStream(int orderId) {
    return _chatService.getUnreadCountStream(orderId);
  }

  /// Fetch FAQ questions from API
  Future<ApiResponse> fetchFAQ() async {
    _isLoadingFAQ = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiService.get(
        AppUrl.getChatbotQuestions,
        isToast: false,
      );
      return response;
    } catch (e) {
      _errorMessage = 'Failed to load FAQ: ${e.toString()}';
      return ApiResponse.error(_errorMessage);
    } finally {
      _isLoadingFAQ = false;
      notifyListeners();
    }
  }

  /// Get answer for a FAQ question from API
  Future<ApiResponse> getFAQAnswer(int orderId, String questionKey) async {
    _isLoadingBotResponse = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppUrl.submitChatbotAnswer,
        data: {
          'order_id': orderId,
          'question': questionKey,
        },
        isToast: false,
      );
      return response;
    } catch (e) {
      _errorMessage = 'Failed to get answer: ${e.toString()}';
      return ApiResponse.error(_errorMessage);
    } finally {
      _isLoadingBotResponse = false;
      notifyListeners();
    }
  }

  /// Send message to Firebase and API (driver to admin)
  Future<void> sendMessage({
    required int orderId,
    required String message,
    required String driverId,
    required String driverName,
  }) async {
    if (message.trim().isEmpty) return;

    _isSending = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Initialize chat if needed
      await _chatService.initializeChat(orderId);

      // Add message to Firebase
      await _chatService.addMessage(
        orderId: orderId,
        message: message,
        driverId: driverId,
        driverName: driverName,
      );

      // Also notify admin via API
      await _apiService.post(
        AppUrl.sendOrderSupportChatMessage,
        data: {
          'order_id': orderId,
          'message': message,
        },
        isToast: false,
      );
      debugPrint('Message sent to admin via API');
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      debugPrint('Error sending message: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Mark all admin messages as read
  Future<void> markAllMessagesAsRead(int orderId) async {
    try {
      await _chatService.markAllMessagesAsRead(orderId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Mark a single message as read
  Future<void> markMessageAsRead(int orderId, String messageId) async {
    try {
      await _chatService.markMessageAsRead(orderId, messageId);
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
