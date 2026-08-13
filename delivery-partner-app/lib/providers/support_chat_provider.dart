import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/support_chat_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/firebase_support_chat_service.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class SupportChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseSupportChatService _firebaseService =
      FirebaseSupportChatService();

  final List<SupportChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String _errorMessage = '';

  List<SupportChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String get errorMessage => _errorMessage;

  /// Stream for real-time messages
  Stream<List<SupportChatMessage>> getSupportMessagesStream(int deliveryBoyId) {
    return _firebaseService.getSupportChatMessagesStream(deliveryBoyId);
  }

  /// Send message to admin
  Future<void> sendSupportMessage(
    int deliveryBoyId,
    String message,
  ) async {
    try {
      _isSending = true;
      _errorMessage = '';
      notifyListeners();

      // Create message object
      // Note: We don't save to Firebase manually here anymore because the
      // backend API likely handles it, preventing message duplication.

      // Call API to send message
      final response = await _apiService.post(
        AppUrl.sendSupportChatMessage,
        data: {
          'message': message,
        },
      );

      if (response.status == ApiStatus.success) {
        debugPrint('✅ Support message sent successfully');
      } else {
        _errorMessage = response.message ?? 'Failed to send message';
      }
    } catch (e) {
      _errorMessage = 'Error sending message: $e';
      debugPrint('❌ Error sending support message: $e');
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(int deliveryBoyId, String messageId) async {
    try {
      await _firebaseService.markMessageAsRead(deliveryBoyId, messageId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error marking message as read: $e');
    }
  }

  /// Mark all messages as read
  Future<void> markAllMessagesAsRead(int deliveryBoyId) async {
    try {
      await _firebaseService.markAllMessagesAsRead(deliveryBoyId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error marking all messages as read: $e');
    }
  }

  /// Get unread message count stream
  Stream<int> getUnreadCountStream(int deliveryBoyId) {
    return _firebaseService.getUnreadMessageCountStream(deliveryBoyId);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
