import 'package:in_app_update/in_app_update.dart';
import 'package:project/helper/utils/generalImports.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String currentVersion;
  final String newVersion;
  final bool isForceUpdate;

  UpdateInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.newVersion,
    required this.isForceUpdate,
  });
}

class AppUpdateHelper {
  /// Check if app update is available from Play Store/App Store
  static Future<UpdateInfo> checkForUpdate(
    BuildContext context,
  ) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (Platform.isAndroid) {
        return await _checkAndroidUpdate(currentVersion);
      } else if (Platform.isIOS) {
        return await _checkIOSUpdate(currentVersion);
      }

      return UpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        newVersion: currentVersion,
        isForceUpdate: false,
      );
    } catch (e) {
      debugPrint('Error checking for update: $e');
      rethrow;
    }
  }

  /// Check for Android update via Play Store
  static Future<UpdateInfo> _checkAndroidUpdate(String currentVersion) async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      debugPrint(
          'Android Update Check - Availability: ${info.updateAvailability}');
      debugPrint('Flexible Version: ${info.flexibleUpdateAllowed}');
      debugPrint('Immediate Version: ${info.immediateUpdateAllowed}');

      // Check if update is available
      bool updateAvailable =
          info.updateAvailability == UpdateAvailability.updateAvailable;
      bool isForceUpdate = info.immediateUpdateAllowed && updateAvailable;

      return UpdateInfo(
        isUpdateAvailable: updateAvailable,
        currentVersion: currentVersion,
        newVersion: currentVersion, // Play Store doesn't return version directly
        isForceUpdate: isForceUpdate,
      );
    } catch (e) {
      debugPrint('Error checking Android update: $e');
      return UpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        newVersion: currentVersion,
        isForceUpdate: false,
      );
    }
  }

  /// Check for iOS update via App Store
  static Future<UpdateInfo> _checkIOSUpdate(String currentVersion) async {
    try {
      // iOS doesn't have built-in in-app update checks
      // Return no update available by default
      return UpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        newVersion: currentVersion,
        isForceUpdate: false,
      );
    } catch (e) {
      debugPrint('Error checking iOS update: $e');
      return UpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        newVersion: currentVersion,
        isForceUpdate: false,
      );
    }
  }

  /// Trigger Android in-app update flow
  static Future<void> performAndroidInAppUpdate({
    bool isForceUpdate = false,
  }) async {
    try {
      if (isForceUpdate) {
        // Immediate update - blocks app until installed
        await InAppUpdate.performImmediateUpdate();
      } else {
        // Flexible update - user can continue using app
        await InAppUpdate.startFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('Android in-app update error: $e');
      // Fallback to opening Play Store directly
      await openPlayStore();
    }
  }

  /// Open Play Store directly (Android fallback)
  static Future<void> openPlayStore() async {
    if (Constant.playStoreUrl.isEmpty) {
      debugPrint('Play Store URL is empty');
      return;
    }

    try {
      await launchUrl(
        Uri.parse(Constant.playStoreUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
    }
  }

  /// Open App Store directly (iOS)
  static Future<void> openAppStore() async {
    if (Constant.appStoreUrl.isEmpty) {
      debugPrint('App Store URL is empty');
      return;
    }

    try {
      await launchUrl(
        Uri.parse(Constant.appStoreUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error opening App Store: $e');
    }
  }

  /// Perform update based on platform
  static Future<void> performUpdate({
    bool isForceUpdate = false,
  }) async {
    if (Platform.isAndroid) {
      await performAndroidInAppUpdate(isForceUpdate: isForceUpdate);
    } else if (Platform.isIOS) {
      await openAppStore();
    }
  }

  /// Complete flexible update on Android (call after download completes)
  static Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Error completing flexible update: $e');
    }
  }
}
