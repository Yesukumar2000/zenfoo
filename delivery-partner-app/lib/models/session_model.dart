class Session {
  final int sessionId;
  final DateTime loginAt;
  final int currentDurationMinutes;
  final DateTime _apiResponseTime;

  Session({
    required this.sessionId,
    required this.loginAt,
    this.currentDurationMinutes = 0,
    DateTime? apiResponseTime,
  }) : _apiResponseTime = apiResponseTime ?? DateTime.now();

  bool get isActive => currentDurationMinutes > 0;

  int get currentLoginMinutes {
    // Use current_duration_minutes from API + elapsed time since API response
    final elapsedSeconds = DateTime.now().difference(_apiResponseTime).inSeconds;
    final totalSeconds = (currentDurationMinutes * 60) + elapsedSeconds;
    return totalSeconds ~/ 60;
  }

  int get currentLoginSeconds {
    // Use current_duration_minutes from API + elapsed time since API response
    final elapsedSeconds = DateTime.now().difference(_apiResponseTime).inSeconds;
    return (currentDurationMinutes * 60) + elapsedSeconds;
  }

  String get displayTime {
    final totalSeconds = currentLoginSeconds;
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

  factory Session.fromJson(Map<String, dynamic> json) {
    // Parse login_at first as it's required
    final loginAt = _parseDateTime(json['login_at']) ?? DateTime.now();

    return Session(
      sessionId: _parseInt(json['session_id']),
      loginAt: loginAt,
      currentDurationMinutes: _parseInt(json['current_duration_minutes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'login_at': loginAt.toIso8601String(),
      'current_duration_minutes': currentDurationMinutes,
    };
  }
}
