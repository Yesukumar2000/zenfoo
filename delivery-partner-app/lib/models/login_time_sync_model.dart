class LoginTimeSync {
  final int accumulatedMinutes;
  final int currentSessionMinutes;
  final DateTime serverTime;
  final DateTime? activeSessionStartedAt;

  LoginTimeSync({
    required this.accumulatedMinutes,
    required this.currentSessionMinutes,
    required this.serverTime,
    this.activeSessionStartedAt,
  });

  /// Get total elapsed minutes including real-time calculation
  int get totalElapsedMinutes {
    if (activeSessionStartedAt == null) {
      return accumulatedMinutes;
    }

    // Calculate elapsed time since session started
    final elapsedSinceSessionStart =
        DateTime.now().difference(activeSessionStartedAt!).inMinutes;

    return accumulatedMinutes + elapsedSinceSessionStart;
  }

  /// Get total elapsed seconds including real-time calculation
  int get totalElapsedSeconds {
    if (activeSessionStartedAt == null) {
      return accumulatedMinutes * 60;
    }

    // Calculate elapsed time since session started
    final elapsedSinceSessionStart =
        DateTime.now().difference(activeSessionStartedAt!).inSeconds;

    return (accumulatedMinutes * 60) + elapsedSinceSessionStart;
  }

  /// Format as "Xh Ym Zs"
  String get displayTimeDetailed {
    final totalSeconds = totalElapsedSeconds;
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format as "Xh Ym"
  String get displayTimeShort {
    final totalMinutes = totalElapsedMinutes;
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    if (hours == 0) {
      return '${mins}m';
    }
    return '${hours}h ${mins}m';
  }

  factory LoginTimeSync.fromJson(Map<String, dynamic> json) {
    return LoginTimeSync(
      accumulatedMinutes: _parseInt(json['accumulated_minutes']),
      currentSessionMinutes: _parseInt(json['current_session_minutes']),
      serverTime: _parseDateTime(json['server_time']) ?? DateTime.now(),
      activeSessionStartedAt: _parseDateTime(json['active_session_started_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accumulated_minutes': accumulatedMinutes,
      'current_session_minutes': currentSessionMinutes,
      'server_time': serverTime.toIso8601String(),
      'active_session_started_at': activeSessionStartedAt?.toIso8601String(),
    };
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
}
