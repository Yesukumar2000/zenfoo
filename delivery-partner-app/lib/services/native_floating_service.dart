import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeFloatingService {
  static const platform = MethodChannel('floating_button');
  static Function()? _onOpenFromOverlayCallback;

  /// Initialize the service and set up method call handler
  static void init({Function()? onOpenFromOverlay}) {
    _onOpenFromOverlayCallback = onOpenFromOverlay;
    platform.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle method calls from native side
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOpenFromOverlay':
        debugPrint('📱 App opened from overlay');
        _onOpenFromOverlayCallback?.call();
        return true;
      default:
        return null;
    }
  }

  /// Check if the app was launched from the overlay
  static Future<bool> wasLaunchedFromOverlay() async {
    try {
      final bool result = await platform.invokeMethod('wasLaunchedFromOverlay');
      debugPrint('📱 Was launched from overlay: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error checking overlay launch: $e');
      return false;
    }
  }

  /// Check if overlay permission is granted
  static Future<bool> checkPermission() async {
    try {
      final bool result = await platform.invokeMethod('checkPermission');
      return result;
    } catch (e) {
      debugPrint('❌ Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request overlay permission
  static Future<void> requestPermission() async {
    try {
      await platform.invokeMethod('requestPermission');
      debugPrint('✅ Overlay permission requested');
    } catch (e) {
      debugPrint('❌ Error requesting overlay permission: $e');
    }
  }

  /// Start the floating button overlay
  static Future<void> startFloating() async {
    try {
      await platform.invokeMethod('startFloating');
      debugPrint('✅ Floating button started');
    } catch (e) {
      debugPrint('❌ Error starting floating button: $e');
    }
  }

  /// Stop the floating button overlay
  static Future<void> stopFloating() async {
    try {
      await platform.invokeMethod('stopFloating');
      debugPrint('🛑 Floating button stopped');
    } catch (e) {
      debugPrint('❌ Error stopping floating button: $e');
    }
  }
}
