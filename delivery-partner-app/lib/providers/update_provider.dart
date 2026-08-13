import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:zenfoo_partner/services/in_app_update_service.dart';

class UpdateProvider with ChangeNotifier {
  final InAppUpdateService _updateService = InAppUpdateService();

  bool _isCheckingForUpdate = false;
  bool get isCheckingForUpdate => _isCheckingForUpdate;

  AppUpdateInfo? _updateInfo;
  AppUpdateInfo? get updateInfo => _updateInfo;

  bool _updateAvailable = false;
  bool get updateAvailable => _updateAvailable;

  /// Check for available updates
  Future<void> checkForUpdate(BuildContext context) async {
    _isCheckingForUpdate = true;
    notifyListeners();

    try {
      _updateInfo = await InAppUpdate.checkForUpdate();

      if (_updateInfo != null) {
        _updateAvailable = _updateInfo!.updateAvailability ==
            UpdateAvailability.updateAvailable;
      }

      notifyListeners();

      // Show update dialog if update is available
      if (context.mounted && _updateAvailable) {
        _updateService.checkForUpdate(context);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isCheckingForUpdate = false;
      notifyListeners();
    }
  }

  /// Check for update on app resume
  Future<void> checkForUpdateOnAppResume(BuildContext context) async {
    await _updateService.checkForUpdateOnAppResume(context);
  }

  /// Start flexible update
  Future<void> startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      debugPrint('Error starting flexible update: $e');
    }
  }

  /// Complete flexible update (restart app)
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Error completing flexible update: $e');
    }
  }

  /// Reset update availability
  void resetUpdateAvailability() {
    _updateAvailable = false;
    _updateInfo = null;
    notifyListeners();
  }
}
