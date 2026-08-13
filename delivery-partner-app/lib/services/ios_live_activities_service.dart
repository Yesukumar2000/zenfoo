import 'dart:io';
import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';

class IOSLiveActivitiesService {
  static final LiveActivities _liveActivities = LiveActivities();
  static String? _currentActivityId;
  static const String _activityIdentifier = 'zenfoo_delivery_activity';

  /// Initialize the Live Activities service
  static Future<void> init() async {
    if (!Platform.isIOS) return;

    try {
      await _liveActivities.init(appGroupId: 'group.com.zenfoo.partner');
      debugPrint('✅ Live Activities initialized');
    } catch (e) {
      debugPrint('⚠️ Live Activities init failed: $e');
    }
  }

  /// Check if Live Activities are available (iOS 16.1+)
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;

    try {
      return await _liveActivities.areActivitiesEnabled();
    } catch (e) {
      debugPrint('⚠️ Live Activities not available: $e');
      return false;
    }
  }

  /// Start Live Activity when driver goes online
  static Future<void> startOnlineActivity({
    required String driverName,
    required String sessionStartTime,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final activityId = await _liveActivities.createActivity(
        _activityIdentifier,
        {
          'status': 'online',
          'driverName': driverName,
          'sessionStartTime': sessionStartTime,
          'activeOrders': 0,
          'lastUpdate': DateTime.now().toIso8601String(),
        },
        removeWhenAppIsKilled: false,
      );

      _currentActivityId = activityId;
      debugPrint('✅ Live Activity started: $activityId');
    } catch (e) {
      debugPrint('❌ Error starting Live Activity: $e');
      debugPrint('💡 Falling back to persistent notification');
    }
  }

  /// Update Live Activity with new information
  static Future<void> updateActivity({
    int? activeOrders,
    String? status,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!Platform.isIOS || _currentActivityId == null) return;

    try {
      final updateData = <String, dynamic>{
        'lastUpdate': DateTime.now().toIso8601String(),
      };

      if (activeOrders != null) {
        updateData['activeOrders'] = activeOrders;
      }

      if (status != null) {
        updateData['status'] = status;
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _liveActivities.updateActivity(_currentActivityId!, updateData);
      debugPrint('✅ Live Activity updated');
    } catch (e) {
      debugPrint('❌ Error updating Live Activity: $e');
    }
  }

  /// End Live Activity when driver goes offline
  static Future<void> endActivity() async {
    if (!Platform.isIOS || _currentActivityId == null) return;

    try {
      await _liveActivities.endActivity(_currentActivityId!);
      debugPrint('✅ Live Activity ended: $_currentActivityId');
      _currentActivityId = null;
    } catch (e) {
      debugPrint('❌ Error ending Live Activity: $e');
    }
  }

  /// Get all active Live Activities
  static Future<List<String>> getAllActivities() async {
    if (!Platform.isIOS) return [];

    try {
      final activities = await _liveActivities.getAllActivitiesIds();
      return activities;
    } catch (e) {
      debugPrint('❌ Error getting Live Activities: $e');
      return [];
    }
  }

  /// End all active Live Activities (cleanup)
  static Future<void> endAllActivities() async {
    if (!Platform.isIOS) return;

    try {
      await _liveActivities.endAllActivities();
      _currentActivityId = null;
      debugPrint('✅ All Live Activities ended');
    } catch (e) {
      debugPrint('❌ Error ending all Live Activities: $e');
    }
  }
}
