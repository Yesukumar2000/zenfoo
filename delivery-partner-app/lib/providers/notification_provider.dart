import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/notification.dart';
import 'package:zenfoo_partner/repository/notification_repository.dart';

enum NotificationState {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  NotificationState _notificationState = NotificationState.initial;
  NotificationState get notificationState => _notificationState;

  List<NotificationListData> _notifications = [];
  List<NotificationListData> get notifications => _notifications;

  String _message = '';
  String get message => _message;

  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;

  int _totalData = 0;
  int get totalData => _totalData;

  int _offset = 0;
  int get offset => _offset;

  bool _isFetching = false;
  bool _firebaseInitialized = false;
  bool get firebaseInitialized => _firebaseInitialized;

  StreamSubscription<dynamic>? _firebaseNotificationSubscription;

  static const int _limit = 20; // Default data load limit

  /// Initialize Firebase Notifications
  Future<void> initializeFirebaseNotifications() async {
    if (_firebaseInitialized) return;

    try {
      await _repository.initializeFirebaseNotifications();
      _firebaseInitialized = true;

      // Subscribe to Firebase notification stream
      _firebaseNotificationSubscription = _repository.getFirebaseNotificationStream().listen(
        (notification) {
          if (notification is NotificationListData) {
            debugPrint('📲 Firebase notification received: ${notification.name}');
            // Add to the beginning of notifications list
            _notifications.insert(0, notification);
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('❌ Firebase notification stream error: $error');
        },
      );

      // Setup token refresh listener
      _repository.listenToTokenRefresh((newToken) {
        debugPrint('🔄 FCM token refreshed: $newToken');
        // Token refresh is handled by FCM token service
        // which will automatically update the backend
      });

      debugPrint('✅ Firebase notifications initialized in provider');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing Firebase notifications: $e');
    }
  }

  /// Get FCM Token
  Future<String?> getFCMToken() async {
    try {
      return await _repository.getFCMToken();
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      return await _repository.areNotificationsEnabled();
    } catch (e) {
      debugPrint('❌ Error checking notifications status: $e');
      return false;
    }
  }

  /// Fetch notifications with pagination
  Future<void> fetchNotifications({bool loadMore = false}) async {
    // Prevent duplicate fetches
    if (_isFetching || (!loadMore && !_hasMoreData && _offset > 0)) return;

    _isFetching = true;

    // Reset if not loading more
    if (!loadMore) {
      _offset = 0;
      _notifications.clear();
      _hasMoreData = true;
    }

    // Set state
    if (_offset == 0) {
      _notificationState = NotificationState.loading;
    } else {
      _notificationState = NotificationState.loadingMore;
    }
    notifyListeners();

    try {
      final response = await _repository.getNotifications(
        offset: _offset,
        limit: _limit,
      );

      if (response.status == 1) {
        _totalData = response.data.total;

        _notifications.addAll(response.data.data);

        _hasMoreData = _notifications.length < _totalData;

        if (_hasMoreData) {
          _offset += _limit;
        }

        _notificationState = NotificationState.loaded;
        _message = response.message;
      } else {
        _hasMoreData = false;
        if (_notifications.isEmpty) {
          _notificationState = NotificationState.error;
          _message = response.message;
        } else {
          _notificationState = NotificationState.loaded;
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      _message = e.toString();

      if (_notifications.isEmpty) {
        _notificationState = NotificationState.error;
      } else {
        _notificationState = NotificationState.loaded;
      }
      _hasMoreData = false;
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Refresh notifications (pull to refresh)
  Future<void> refreshNotifications() async {
    _offset = 0;
    _notifications.clear();
    _hasMoreData = true;
    await fetchNotifications();
  }

  /// Reset provider state
  void reset() {
    _notifications.clear();
    _notificationState = NotificationState.initial;
    _offset = 0;
    _hasMoreData = true;
    _totalData = 0;
    _message = '';
    _isFetching = false;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _firebaseNotificationSubscription?.cancel();
    super.dispose();
  }

  /// Mark single notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final success = await _repository.markNotificationAsRead(notificationId: notificationId);
      if (success) {
        debugPrint('✅ Notification $notificationId marked as read');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final success = await _repository.markAllNotificationsAsRead();
      if (success) {
        debugPrint('✅ All notifications marked as read');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final success = await _repository.deleteNotification(notificationId: notificationId);
      if (success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
        debugPrint('✅ Notification $notificationId deleted');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Get notification settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      return await _repository.getNotificationSettings();
    } catch (e) {
      debugPrint('❌ Error fetching notification settings: $e');
      return {};
    }
  }

  /// Update notification settings
  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    try {
      final success = await _repository.updateNotificationSettings(settings: settings);
      if (success) {
        debugPrint('✅ Notification settings updated');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error updating notification settings: $e');
      return false;
    }
  }
}
