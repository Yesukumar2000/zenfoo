import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';

/// Helper class for notification constants
class ColorsRes {
  static const Color appColor = AppColors.primaryColor;
}

/// Session manager keys
class SessionManager {
  static const String keyPermissionNotificationHidePromptPermanently =
      'permission_notification_hide_prompt_permanently';
}

/// Constant class for global app constants
class Constant {
  static final SessionStorage session = SessionStorage();

  // API Keys and Settings
  static String googleApiKey = "AIzaSyDbBK9qmNgAVBK0-t0tEN3tRE-XhDdS4_8"; // Default fallback

  // App Settings
  static String currency = "";
  static String currencyCode = "";
  static String sellerCommission = "";
  static String privacyPolicy = "";
  static String termsConditions = "";
  static String currencyDecimalPoint = "";
  static String appMaintenanceMode = "";
  static String appMaintenanceModeRemark = "";
  static String viewCustomerDetail = "0";
  static String demoMode = "";
  static String selfPickupMode = "";
  static String enableRoadPathTracking = "0";
}

/// Simple session storage for permissions
class SessionStorage {
  final Map<String, dynamic> _storage = {};

  bool getBoolData(String key) {
    return _storage[key] ?? false;
  }

  void setBoolData(String key, bool value) {
    _storage[key] = value;
  }

  String getStringData(String key) {
    return _storage[key] ?? '';
  }

  void setStringData(String key, String value) {
    _storage[key] = value;
  }
}

/// Notification permission labels
const String notificationPermissionTitleLabel = 'Notification Permission Required';
const String notificationPermissionMessageLabel =
    'To receive order notifications and updates, please enable notifications in your device settings.';
