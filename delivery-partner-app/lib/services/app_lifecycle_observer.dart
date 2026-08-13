import 'dart:io';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/services/native_floating_service.dart';
import 'package:zenfoo_partner/services/ios_live_activities_service.dart';
import 'package:zenfoo_partner/utils/awsomeNotification.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  final SessionProvider sessionProvider;
  bool _hasLiveActivitiesSupport = false;

  AppLifecycleObserver(this.sessionProvider);

  void initialize() async {
    WidgetsBinding.instance.addObserver(this);

    // Check if Live Activities are available (iOS 16.1+)
    if (Platform.isIOS) {
      _hasLiveActivitiesSupport = await IOSLiveActivitiesService.isAvailable();
      debugPrint('📱 Live Activities support: $_hasLiveActivitiesSupport');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.inactive:
        // Transient interruption (notification shade, permission dialog, app
        // switcher). The app is still in front, so don't raise the overlay -
        // doing so made the floating button overlap the app itself.
        break;

      case AppLifecycleState.paused:
        // App went to background
        if (sessionProvider.isOnline) {
          if (Platform.isAndroid) {
            // Android: Show floating button
            debugPrint('🔄 App paused - showing floating button (Android)');
            NativeFloatingService.startFloating();
          } else if (Platform.isIOS) {
            // iOS: Show Live Activity or persistent notification
            _showIOSBackgroundUI();
          }
        }
        break;

      case AppLifecycleState.resumed:
        // App came to foreground
        if (Platform.isAndroid) {
          debugPrint('🔄 App resumed - hiding floating button (Android)');
          NativeFloatingService.stopFloating();
        } else if (Platform.isIOS) {
          debugPrint('🔄 App resumed - hiding iOS background UI');
          _hideIOSBackgroundUI();
        }
        break;

      case AppLifecycleState.detached:
        // App is being torn down (swiped away / closed). Tear the overlay down
        // with it, otherwise the floating button outlives the app.
        if (Platform.isAndroid) {
          debugPrint('🔄 App detached - removing floating button (Android)');
          NativeFloatingService.stopFloating();
        } else if (Platform.isIOS) {
          _hideIOSBackgroundUI();
        }
        break;

      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _showIOSBackgroundUI() async {
    if (_hasLiveActivitiesSupport) {
      // iOS 16.1+: Use Live Activities (better UX)
      debugPrint('🔄 App paused - showing Live Activity (iOS 16.1+)');
      // Note: Live Activity is already created when going online
      // Just update it to show it's in background
      await IOSLiveActivitiesService.updateActivity(
        status: 'online',
        additionalData: {
          'inBackground': true,
        },
      );
    } else {
      // iOS < 16.1: Use persistent notification
      debugPrint('🔄 App paused - showing persistent notification (iOS < 16.1)');
      await LocalAwesomeNotification.showOnlineNotification(
        title: 'Zenfoo Delivery - You\'re Online',
        body: 'Tap to return to app',
      );
    }
  }

  Future<void> _hideIOSBackgroundUI() async {
    if (_hasLiveActivitiesSupport) {
      // Update Live Activity (don't end it, just update status)
      await IOSLiveActivitiesService.updateActivity(
        additionalData: {
          'inBackground': false,
        },
      );
    } else {
      // Cancel persistent notification
      await LocalAwesomeNotification.cancelOnlineNotification();
    }
  }
}
