import 'package:zenfoo_partner/models/session_model.dart';
import 'package:zenfoo_partner/models/login_time_sync_model.dart';

class DailyTracking {
  final String onlineStatus; // online, offline
  final int totalLoginMinutes;
  final double totalLoginHours;
  final String? loginDisplayTime;
  final double totalEarnings;
  final double totalDistanceKm;
  final int gigsCompleted;
  final int gigsBooked;
  final int ordersDelivered;
  final int ordersCancelled;
  final DateTime? firstLoginAt;
  final DateTime? lastActivityAt;
  final Session? activeSession;
  final LoginTimeSync? loginTimeSync;

  DailyTracking({
    this.onlineStatus = 'offline',
    this.totalLoginMinutes = 0,
    this.totalLoginHours = 0.0,
    this.loginDisplayTime,
    this.totalEarnings = 0.0,
    this.totalDistanceKm = 0.0,
    this.gigsCompleted = 0,
    this.gigsBooked = 0,
    this.ordersDelivered = 0,
    this.ordersCancelled = 0,
    this.firstLoginAt,
    this.lastActivityAt,
    this.activeSession,
    this.loginTimeSync,
  });

  bool get isOnline => onlineStatus == 'online';

  int get currentTotalLoginMinutes {
    int total = totalLoginMinutes;
    if (activeSession != null && activeSession!.isActive) {
      total += activeSession!.currentLoginMinutes;
    }
    return total;
  }

  int get currentTotalLoginSeconds {
    // Prefer new login_time_sync if available (more accurate for multiple sessions)
    if (loginTimeSync != null) {
      return loginTimeSync!.totalElapsedSeconds;
    }
    // Fall back to activeSession calculation
    if (activeSession != null && activeSession!.isActive) {
      return activeSession!.currentLoginSeconds;
    }
    // Otherwise use stored total minutes
    return totalLoginMinutes * 60;
  }

  String get displayLoginTime {
    final totalSeconds = currentTotalLoginSeconds;
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Safe parse integer from any type
  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safe parse double from any type
  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safe parse string from any type
  static String _parseString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safe parse DateTime from any type
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory DailyTracking.fromJson(Map<String, dynamic> json) {
    return DailyTracking(
      onlineStatus: _parseString(json['online_status'], 'offline'),
      totalLoginMinutes: _parseInt(json['total_login_minutes']),
      totalLoginHours: _parseDouble(json['total_login_hours']),
      loginDisplayTime: json['login_display_time'],
      totalEarnings: _parseDouble(json['total_earnings']),
      totalDistanceKm: _parseDouble(json['total_distance_km']),
      gigsCompleted: _parseInt(json['gigs_completed']),
      gigsBooked: _parseInt(json['gigs_booked']),
      ordersDelivered: _parseInt(json['orders_delivered']),
      ordersCancelled: _parseInt(json['orders_cancelled']),
      firstLoginAt: _parseDateTime(json['first_login_at']),
      lastActivityAt: _parseDateTime(json['last_activity_at']),
      activeSession: json['active_session'] != null
          ? Session.fromJson(json['active_session'])
          : null,
      loginTimeSync: json['login_time_sync'] != null
          ? LoginTimeSync.fromJson(json['login_time_sync'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'online_status': onlineStatus,
      'total_login_minutes': totalLoginMinutes,
      'total_login_hours': totalLoginHours,
      'login_display_time': loginDisplayTime,
      'total_earnings': totalEarnings,
      'total_distance_km': totalDistanceKm,
      'gigs_completed': gigsCompleted,
      'gigs_booked': gigsBooked,
      'orders_delivered': ordersDelivered,
      'orders_cancelled': ordersCancelled,
      'first_login_at': firstLoginAt?.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'active_session': activeSession?.toJson(),
      'login_time_sync': loginTimeSync?.toJson(),
    };
  }
}
