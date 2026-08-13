import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

class AppTrackingTransparencyService {
  /// Request App Tracking Transparency permission on iOS 14+
  static Future<bool> requestTrackingPermission() async {
    try {
      // Only request on iOS devices
      if (!Platform.isIOS) {
        return true;
      }

      // Get the current tracking status
      final TrackingStatus status =
          await AppTrackingTransparency.trackingAuthorizationStatus;

      // If already denied or restricted, return false
      if (status == TrackingStatus.denied ||
          status == TrackingStatus.restricted) {
        debugPrint('App Tracking Transparency: Permission denied or restricted');
        return false;
      }

      // If already authorized, return true
      if (status == TrackingStatus.authorized) {
        debugPrint('App Tracking Transparency: Already authorized');
        return true;
      }

      // Otherwise, request the permission (status == TrackingStatus.notDetermined)
      debugPrint('App Tracking Transparency: Requesting permission...');
      final TrackingStatus newStatus =
          await AppTrackingTransparency.requestTrackingAuthorization();

      final isAuthorized = newStatus == TrackingStatus.authorized;
      debugPrint(
          'App Tracking Transparency: Permission ${isAuthorized ? 'granted' : 'denied'}');

      return isAuthorized;
    } catch (e) {
      debugPrint('Error requesting App Tracking Transparency: $e');
      return false;
    }
  }

  /// Get the current tracking authorization status
  static Future<TrackingStatus> getTrackingStatus() async {
    try {
      if (!Platform.isIOS) {
        return TrackingStatus.authorized;
      }

      return await AppTrackingTransparency.trackingAuthorizationStatus;
    } catch (e) {
      debugPrint('Error getting tracking status: $e');
      return TrackingStatus.notDetermined;
    }
  }
}
