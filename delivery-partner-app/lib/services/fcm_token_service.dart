import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();

  factory FcmTokenService() {
    return _instance;
  }

  FcmTokenService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  static const String _fcmTokenKey = 'fcm_token';

  /// Get current FCM token
  Future<String?> getFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token obtained: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Get platform type (android or ios)
  String getPlatformType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown';
  }

  /// Update FCM token to backend
  Future<bool> updateFcmToken() async {
    try {
      final fcmToken = await getFcmToken();
      if (fcmToken == null) {
        debugPrint('⚠️ FCM token is null, cannot update');
        return false;
      }

      final platform = getPlatformType();

      debugPrint('📤 Updating FCM token: $fcmToken (platform: $platform)');

      final response = await _apiService.post(
        AppUrl.updateFcmToken,
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
        },
        useFormData: true, // API expects multipart form-data, not JSON
        isErrorToast: false, // Don't show error toast for background task
      );

      if (isStatusSuccess(response.status)) {
        debugPrint('✅ FCM token updated successfully');

        // Save FCM token to local storage for future reference
        await _saveFcmTokenLocally(fcmToken);
        return true;
      } else {
        debugPrint(
            '⚠️ Failed to update FCM token (not critical): ${response.status} - ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
      return false;
    }
  }

  /// Save FCM token locally for reference
  Future<void> _saveFcmTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      debugPrint('💾 FCM token saved locally');
    } catch (e) {
      debugPrint('⚠️ Error saving FCM token locally: $e');
    }
  }

  /// Get previously saved FCM token from local storage
  Future<String?> getSavedFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      debugPrint('⚠️ Error retrieving saved FCM token: $e');
      return null;
    }
  }

  /// Setup token refresh listener to update on token changes
  void setupTokenRefreshListener(Function(String token) onTokenRefresh) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM token refreshed: $newToken');
      onTokenRefresh(newToken);
    });
  }
}
