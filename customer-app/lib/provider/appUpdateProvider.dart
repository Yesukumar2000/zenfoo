import 'package:project/helper/utils/appUpdateHelper.dart';
import 'package:project/helper/utils/generalImports.dart';

class AppUpdateProvider extends ChangeNotifier {
  bool _isCheckingForUpdate = false;
  bool _isUpdateAvailable = false;
  UpdateInfo? _updateInfo;
  String _errorMessage = '';

  // Getters
  bool get isCheckingForUpdate => _isCheckingForUpdate;
  bool get isUpdateAvailable => _isUpdateAvailable;
  UpdateInfo? get updateInfo => _updateInfo;
  String get errorMessage => _errorMessage;

  /// Check for updates
  Future<void> checkForUpdates(BuildContext context) async {
    if (_isCheckingForUpdate) return; // Prevent duplicate checks

    _isCheckingForUpdate = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _updateInfo = await AppUpdateHelper.checkForUpdate(context);
      _isUpdateAvailable = _updateInfo?.isUpdateAvailable ?? false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to check for updates: $e';
      _isUpdateAvailable = false;
      debugPrint('Error in checkForUpdates: $e');
      notifyListeners();
    } finally {
      _isCheckingForUpdate = false;
      notifyListeners();
    }
  }

  /// Perform the update flow
  Future<void> performUpdate() async {
    if (_updateInfo == null) return;

    try {
      await AppUpdateHelper.performUpdate(
        isForceUpdate: _updateInfo!.isForceUpdate,
      );
    } catch (e) {
      _errorMessage = 'Failed to perform update: $e';
      debugPrint('Error in performUpdate: $e');
      notifyListeners();
    }
  }

  /// Reset update state (when user dismisses banner)
  void resetUpdateState() {
    _isUpdateAvailable = false;
    _updateInfo = null;
    _errorMessage = '';
    notifyListeners();
  }

  /// Complete flexible update on Android
  Future<void> completeFlexibleUpdate() async {
    try {
      await AppUpdateHelper.completeFlexibleUpdate();
    } catch (e) {
      _errorMessage = 'Failed to complete update: $e';
      debugPrint('Error in completeFlexibleUpdate: $e');
      notifyListeners();
    }
  }
}
