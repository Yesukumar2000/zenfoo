import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  bool _isOverlayActive = false;
  bool get isOverlayActive => _isOverlayActive;

  /// Show explanation dialog and request permission
  Future<bool> requestOverlayPermission(BuildContext context) async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();

      if (hasPermission) {
        return true;
      }

      // Show explanation dialog
      if (!context.mounted) return false;

      final userAgreed = await _showPermissionDialog(context);

      if (!userAgreed) {
        debugPrint('⚠️ User declined overlay permission explanation');
        return false;
      }

      // Request system permission with timeout protection
      try {
        final granted = await FlutterOverlayWindow.requestPermission()
            .timeout(const Duration(seconds: 30), onTimeout: () {
          debugPrint('⚠️ Overlay permission request timed out');
          return false;
        });

        if (granted != true) {
          debugPrint('⚠️ Overlay permission denied by user');
          return false;
        }

        debugPrint('✅ Overlay permission granted');
        return true;
      } catch (permissionError) {
        debugPrint('❌ Error requesting overlay permission: $permissionError');
        // Return false but don't crash - overlay is optional
        return false;
      }
    } catch (e) {
      debugPrint('❌ Unexpected error in requestOverlayPermission: $e');
      // Return false but don't crash - overlay is optional
      return false;
    }
  }

  /// Show dialog explaining why overlay permission is needed
  Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.layers,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Stay Connected',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To help you stay online and receive orders while using other apps, we need permission to show a floating widget.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.notifications_active,
                    'Quick Access',
                    'Tap the widget to return to the app instantly',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.visibility,
                    'Stay Visible',
                    'See your online status even when app is in background',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    Icons.timer,
                    'Track Time',
                    'Monitor your login duration at a glance',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Not Now',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF3B82F6),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show the overlay when app goes to background and user is online
  Future<void> showOverlay() async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();

      if (!hasPermission) {
        debugPrint('⚠️ Overlay permission not granted');
        return;
      }

      if (_isOverlayActive) {
        debugPrint('⚠️ Overlay already active');
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Zenfoo Delivery",
        overlayContent: "Tap to open app",
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: 80,
        height: 80,
      );

      _isOverlayActive = true;
      debugPrint('✅ Overlay shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing overlay: $e');
    }
  }

  /// Close the overlay
  Future<void> closeOverlay() async {
    try {
      if (!_isOverlayActive) {
        return;
      }

      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }

      _isOverlayActive = false;
      debugPrint('✅ Overlay closed successfully');
    } catch (e) {
      debugPrint('❌ Error closing overlay: $e');
    }
  }

  /// Share data to overlay
  static Future<void> shareDataToOverlay(Map<String, dynamic> data) async {
    try {
      await FlutterOverlayWindow.shareData(data);
    } catch (e) {
      debugPrint('❌ Error sharing data to overlay: $e');
    }
  }
}
