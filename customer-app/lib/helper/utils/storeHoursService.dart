import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StoreHoursService extends ChangeNotifier {
  static final StoreHoursService _instance = StoreHoursService._internal();
  factory StoreHoursService() => _instance;
  StoreHoursService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _openingTime;
  String? _closingTime;
  Timer? _countdownTimer;

  String? get openingTime => _openingTime;
  String? get closingTime => _closingTime;

  bool get isLoaded => _openingTime != null && _closingTime != null;

  Future<void> fetchStoreHours() async {
    try {
      final doc = await _firestore
          .collection('settings_zenfoo')
          .doc('store_hours')
          .get();

      if (doc.exists) {
        final data = doc.data();
        _openingTime = data?['store_opening_time']?.toString();
        _closingTime = data?['store_closing_time']?.toString();
        debugPrint("StoreHours: open=$_openingTime, close=$_closingTime");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("StoreHours fetch error: $e");
    }
  }

  /// Returns formatted time like "09:00 AM"
  String formatTime(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (_) {
      return time24;
    }
  }

  String get formattedOpeningTime => formatTime(_openingTime);
  String get formattedClosingTime => formatTime(_closingTime);

  /// Check if store is currently open
  bool get isStoreOpen {
    if (!isLoaded) return true; // Default to open if not loaded
    try {
      final now = DateTime.now();
      final openParts = _openingTime!.split(':');
      final closeParts = _closingTime!.split(':');

      final openMinutes =
          int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMinutes =
          int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
      final nowMinutes = now.hour * 60 + now.minute;

      if (closeMinutes > openMinutes) {
        // Normal hours (e.g. 09:00 - 22:30)
        return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
      } else {
        // Overnight hours (e.g. 22:00 - 06:00)
        return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
      }
    } catch (_) {
      return true;
    }
  }

  /// Returns remaining seconds until store closes, or -1 if not applicable
  int get secondsUntilClosing {
    if (!isLoaded || !isStoreOpen) return -1;
    try {
      final now = DateTime.now();
      final closeParts = _closingTime!.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      var closeTime = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

      // If overnight hours and close time is next day
      if (closeTime.isBefore(now)) {
        closeTime = closeTime.add(const Duration(days: 1));
      }

      return closeTime.difference(now).inSeconds;
    } catch (_) {
      return -1;
    }
  }

  /// True if store is open but less than 30 minutes remain
  bool get isClosingSoon {
    final remaining = secondsUntilClosing;
    return remaining >= 0 && remaining <= 30 * 60;
  }

  /// Returns countdown string in "mm:ss" format
  String get closingCountdown {
    final remaining = secondsUntilClosing;
    if (remaining <= 0) return "00:00";
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return "${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s";
  }

  /// Starts a 1-second periodic timer to update countdown
  void startCountdownTimer() {
    if (_countdownTimer != null) return; // Already running
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosingSoon) {
        notifyListeners();
      } else {
        stopCountdownTimer();
      }
    });
  }

  /// Stops the countdown timer
  void stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
}
