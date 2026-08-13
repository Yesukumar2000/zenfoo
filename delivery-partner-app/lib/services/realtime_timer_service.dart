import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/models/daily_tracking_model.dart';

/// Message sent to the isolate to update time
class _TimerMessage {
  final int accumulatedMinutes;
  final DateTime? activeSessionStartedAt;
  final SendPort replyPort;

  _TimerMessage({
    required this.accumulatedMinutes,
    required this.activeSessionStartedAt,
    required this.replyPort,
  });
}

/// Response from the isolate with calculated time
class TimerUpdate {
  final int totalSeconds;
  final String displayTime;
  final String displayTimeShort;
  final int totalMinutes;

  TimerUpdate({
    required this.totalSeconds,
    required this.displayTime,
    required this.displayTimeShort,
    required this.totalMinutes,
  });

  factory TimerUpdate.fromMap(Map<String, dynamic> map) {
    return TimerUpdate(
      totalSeconds: map['totalSeconds'] ?? 0,
      displayTime: map['displayTime'] ?? '00:00:00',
      displayTimeShort: map['displayTimeShort'] ?? '0m',
      totalMinutes: map['totalMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSeconds': totalSeconds,
      'displayTime': displayTime,
      'displayTimeShort': displayTimeShort,
      'totalMinutes': totalMinutes,
    };
  }
}

/// Isolate entry point - runs on a separate thread
void _timerIsolateEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  // Listen for messages from the main thread
  receivePort.listen((message) {
    if (message is _TimerMessage) {
      // Calculate time in the isolate (separate thread)
      final timerUpdate = _calculateTimerUpdate(
        message.accumulatedMinutes,
        message.activeSessionStartedAt,
      );

      // Send result back to main thread
      message.replyPort.send(timerUpdate.toMap());
    } else if (message == 'stop') {
      receivePort.close();
    }
  });
}

/// Calculate timer update in isolate (no UI updates here)
TimerUpdate _calculateTimerUpdate(
  int accumulatedMinutes,
  DateTime? activeSessionStartedAt,
) {
  int totalSeconds;

  if (activeSessionStartedAt == null) {
    totalSeconds = accumulatedMinutes * 60;
  } else {
    // Calculate elapsed time since session started
    final elapsedSinceSessionStart =
        DateTime.now().difference(activeSessionStartedAt).inSeconds;
    totalSeconds = (accumulatedMinutes * 60) + elapsedSinceSessionStart;
  }

  // Format as "HH:MM:SS"
  final hours = totalSeconds ~/ 3600;
  final mins = (totalSeconds % 3600) ~/ 60;
  final secs = totalSeconds % 60;
  final displayTime =
      '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

  // Format as "Xh Ym"
  final totalMinutes = totalSeconds ~/ 60;
  final displayMins = totalMinutes % 60;
  final displayHours = totalMinutes ~/ 60;
  String displayTimeShort;
  if (displayHours == 0) {
    displayTimeShort = '${displayMins}m';
  } else {
    displayTimeShort = '${displayHours}h ${displayMins}m';
  }

  return TimerUpdate(
    totalSeconds: totalSeconds,
    displayTime: displayTime,
    displayTimeShort: displayTimeShort,
    totalMinutes: totalMinutes,
  );
}

/// Service to manage real-time timer updates using isolates
class RealtimeTimerService {
  static final RealtimeTimerService _instance = RealtimeTimerService._internal();

  factory RealtimeTimerService() {
    return _instance;
  }

  RealtimeTimerService._internal();

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;
  Timer? _updateTimer;

  final StreamController<TimerUpdate> _timerUpdateController =
      StreamController<TimerUpdate>.broadcast();

  Stream<TimerUpdate> get timerUpdates => _timerUpdateController.stream;

  /// Initialize the isolate
  Future<void> initialize() async {
    if (_isolate != null) return;

    debugPrint('🧵 Initializing RealtimeTimerService isolate...');

    try {
      _mainReceivePort = ReceivePort();
      _isolate = await Isolate.spawn(
        _timerIsolateEntryPoint,
        _mainReceivePort!.sendPort,
      );

      // Wait for the isolate to send back its SendPort
      _isolateSendPort = await _mainReceivePort!.first;
      debugPrint('✅ RealtimeTimerService isolate initialized');
    } catch (e) {
      debugPrint('❌ Error initializing isolate: $e');
      _isolate = null;
      _isolateSendPort = null;
    }
  }

  /// Start real-time timer updates (updates every 0.5 seconds)
  Future<void> startTimer(DailyTracking dailyTracking) async {
    if (_isolateSendPort == null) {
      await initialize();
    }

    debugPrint('⏱️ Starting real-time timer updates...');
    _updateTimer?.cancel();

    _updateTimer = Timer.periodic(
      const Duration(milliseconds: 500), // Update 2x per second for smoothness
      (timer) {
        _updateTimerValue(dailyTracking);
      },
    );

    // Send initial update immediately
    _updateTimerValue(dailyTracking);
  }

  /// Update timer value by sending message to isolate
  void _updateTimerValue(DailyTracking dailyTracking) {
    if (_isolateSendPort == null) return;

    try {
      final replyPort = ReceivePort();

      // Get time sync data
      final accumulatedMinutes =
          dailyTracking.loginTimeSync?.accumulatedMinutes ??
              dailyTracking.totalLoginMinutes;
      final activeSessionStartedAt =
          dailyTracking.loginTimeSync?.activeSessionStartedAt;

      // Send message to isolate
      _isolateSendPort!.send(
        _TimerMessage(
          accumulatedMinutes: accumulatedMinutes,
          activeSessionStartedAt: activeSessionStartedAt,
          replyPort: replyPort.sendPort,
        ),
      );

      // Listen for response with timeout
      replyPort.first.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {
          debugPrint('⚠️ Timer calculation timeout');
          replyPort.close();
          return null;
        },
      ).then((result) {
        if (result != null && result is Map<String, dynamic>) {
          final timerUpdate = TimerUpdate.fromMap(result);
          _timerUpdateController.add(timerUpdate);
        }
        replyPort.close();
      }).catchError((e) {
        debugPrint('Error in timer calculation: $e');
      });
    } catch (e) {
      debugPrint('Error sending timer message: $e');
    }
  }

  /// Stop timer updates
  void stopTimer() {
    debugPrint('⏱️ Stopping real-time timer updates...');
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopTimer();
    await _timerUpdateController.close();

    if (_isolateSendPort != null) {
      _isolateSendPort!.send('stop');
    }

    if (_mainReceivePort != null) {
      _mainReceivePort!.close();
    }

    if (_isolate != null) {
      _isolate!.kill();
      _isolate = null;
    }

    _isolateSendPort = null;
    _mainReceivePort = null;

    debugPrint('🧵 RealtimeTimerService disposed');
  }
}
