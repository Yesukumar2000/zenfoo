import 'package:zenfoo_partner/models/notification.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/firebase_notifications_service.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();
  final FirebaseNotificationsService _firebaseService = FirebaseNotificationsService();

  /// Get notifications with pagination
  Future<NotificationList> getNotifications({
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await _apiService.get(
        AppUrls.getNotifications,
        params: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      return NotificationList.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead({required int notificationId}) async {
    try {
      final response = await _apiService.post(
        '${AppUrls.getNotifications}/$notificationId/read',
        data: {},
        isToast: false,
      );

      return response.data is Map && (response.data['status'] == 1 || response.data['status'] == '1');
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await _apiService.post(
        '${AppUrls.getNotifications}/read-all',
        data: {},
        isToast: false,
      );

      return response.data is Map && (response.data['status'] == 1 || response.data['status'] == '1');
    } catch (e) {
      rethrow;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification({required int notificationId}) async {
    try {
      final response = await _apiService.delete(
        '${AppUrls.getNotifications}/$notificationId',
        isToast: false,
      );

      return response.data is Map && (response.data['status'] == 1 || response.data['status'] == '1');
    } catch (e) {
      rethrow;
    }
  }

  /// Get notification settings/preferences
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _apiService.get(
        '${AppUrls.getNotifications}/settings',
      );

      return response.data is Map ? response.data : {};
    } catch (e) {
      rethrow;
    }
  }

  /// Update notification settings/preferences
  Future<bool> updateNotificationSettings({
    required Map<String, dynamic> settings,
  }) async {
    try {
      final response = await _apiService.post(
        '${AppUrls.getNotifications}/settings/update',
        data: settings,
        isToast: false,
      );

      return response.data is Map && (response.data['status'] == 1 || response.data['status'] == '1');
    } catch (e) {
      rethrow;
    }
  }

  /// Get Firebase notification stream
  Stream<dynamic> getFirebaseNotificationStream() {
    return _firebaseService.notificationStream;
  }

  /// Initialize Firebase notifications
  Future<void> initializeFirebaseNotifications() async {
    await _firebaseService.initialize();
  }

  /// Get FCM token from Firebase
  Future<String?> getFCMToken() async {
    return await _firebaseService.getFCMToken();
  }

  /// Listen to FCM token refresh
  void listenToTokenRefresh(Function(String) onTokenRefresh) {
    _firebaseService.listenToTokenRefresh(onTokenRefresh);
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _firebaseService.areNotificationsEnabled();
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    await _firebaseService.enableNotifications();
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    await _firebaseService.disableNotifications();
  }
}
