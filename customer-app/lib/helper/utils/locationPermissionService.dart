import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service to handle location permissions across iOS and Android platforms
class LocationPermissionService {
  /// Request location permission
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Request location permission with custom messaging
  static Future<bool> requestLocationPermissionWithDialog(
    BuildContext context, {
    String title = 'Location Permission Required',
    String message =
        'We need access to your location to show nearby sellers and provide better delivery experience.',
  }) async {
    final status = await Permission.location.status;

    if (status.isDenied) {
      // Permission not requested yet
      return await _showPermissionDialog(
        context,
        title: title,
        message: message,
        onAllow: () async {
          final result = await Permission.location.request();
          return result.isGranted;
        },
      );
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied
      return await _showPermissionDialog(
        context,
        title: 'Location Access Denied',
        message:
            'Location permission has been permanently denied. Please enable it in settings.',
        isPermanentlyDenied: true,
        onAllow: () async {
          openAppSettings();
          return false;
        },
      );
    }

    return status.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check location permission status
  static Future<PermissionStatus> getLocationPermissionStatus() async {
    return await Permission.location.status;
  }

  /// Show permission dialog
  static Future<bool> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required Function() onAllow,
    bool isPermanentlyDenied = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final granted = await onAllow();
              if (context.mounted) {
                Navigator.pop(context, granted);
              }
            },
            child: Text(isPermanentlyDenied ? 'Open Settings' : 'Allow'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Request location permission without UI prompts (silent)
  /// Useful for background permission checks
  static Future<bool> requestLocationPermissionSilent() async {
    final status = await Permission.location.status;

    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }

    return status.isGranted;
  }

  /// Open app settings for location permission
  static Future<void> openLocationSettings() async {
    await openAppSettings();
  }

  /// Get human-readable permission status
  static String getPermissionStatusMessage(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Location permission granted';
      case PermissionStatus.denied:
        return 'Location permission denied';
      case PermissionStatus.restricted:
        return 'Location permission restricted';
      case PermissionStatus.limited:
        return 'Location permission limited';
      case PermissionStatus.permanentlyDenied:
        return 'Location permission permanently denied';
      case PermissionStatus.provisional:
        return 'Location permission provisional';
    }
  }
}
