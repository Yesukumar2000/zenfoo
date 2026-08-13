import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  static const String _tag = '🔄 InAppUpdate';

  /// Check for available updates
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      // debugPrint('$_tag: Checking for updates...');

      final updateInfo = await InAppUpdate.checkForUpdate();

      if (!context.mounted) return;

      // If an update is available, show appropriate dialog
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('$_tag: Update available');
        _showUpdateDialog(
          context,
          updateInfo,
          isFlexible: true,
        );
      } else if (updateInfo.updateAvailability ==
          UpdateAvailability.updateNotAvailable) {
        debugPrint('$_tag: App is up to date');
      } else {
        debugPrint(
            '$_tag: Update availability: ${updateInfo.updateAvailability}');
      }
    } catch (e) {
      debugPrint('$_tag: Error checking for updates: $e');
    }
  }

  /// Show update dialog
  void _showUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo, {
    required bool isFlexible,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isFlexible, // Force update - can't dismiss
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A new version of Zenfoo is available.'),
            const SizedBox(height: 8),
            const Text(
              'Please update to get the latest features and improvements.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (isFlexible)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'You can update now or later.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        actions: [
          if (isFlexible)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startUpdate(updateInfo, isFlexible: isFlexible);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Start the update process
  Future<void> _startUpdate(
    AppUpdateInfo updateInfo, {
    required bool isFlexible,
  }) async {
    try {
      if (isFlexible) {
        // Flexible update - can be done later
        debugPrint('$_tag: Starting flexible update');
        await InAppUpdate.startFlexibleUpdate();

        // Restart app after download completes
        await Future.delayed(const Duration(seconds: 2));
        await InAppUpdate.completeFlexibleUpdate();
      } else {
        // Immediate update - must be completed before using app
        debugPrint('$_tag: Starting immediate update');
        await InAppUpdate.performImmediateUpdate();
      }

      debugPrint('$_tag: Update completed successfully');
    } catch (e) {
      debugPrint('$_tag: Error during update: $e');
      if (e.toString().contains('Activity result canceled')) {
        debugPrint('$_tag: User cancelled the update');
      }
    }
  }

  /// Check for updates periodically (call from app lifecycle)
  Future<void> checkForUpdateOnAppResume(BuildContext context) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (!context.mounted) return;

      if (updateInfo.flexibleUpdateAllowed &&
          updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('$_tag: Update available on app resume');
        _showUpdateDialog(context, updateInfo, isFlexible: true);
      }
    } catch (e) {
      debugPrint('$_tag: Error in periodic check: $e');
    }
  }
}
