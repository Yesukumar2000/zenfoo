import 'dart:async';
import 'dart:io' as io;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zenfoo_partner/models/daily_tracking_model.dart';
import 'package:zenfoo_partner/models/session_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/repository/session_repository.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/services/overlay_service.dart';
import 'package:zenfoo_partner/services/native_floating_service.dart';
import 'package:zenfoo_partner/services/realtime_timer_service.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';

class SessionProvider with ChangeNotifier {
  final SessionRepository _sessionRepository = SessionRepository();
  final OverlayService _overlayService = OverlayService();
  final RealtimeTimerService _realtimeTimerService = RealtimeTimerService();
  final FirebaseOrderService _firebaseOrderService = FirebaseOrderService();
  final AuthProvider _authProvider;

  SessionProvider({required AuthProvider authProvider})
      : _authProvider = authProvider;

  // State for daily tracking stats
  ApiResponse<DailyTracking> todayStatsState = ApiResponse.nothing();
  DailyTracking? _todayStats;
  DailyTracking? get todayStats => _todayStats;

  // State for active session
  ApiResponse<Session> activeSessionState = ApiResponse.nothing();
  Session? _activeSession;
  Session? get activeSession => _activeSession;

  // State for session actions
  ApiResponse startSessionState = ApiResponse.nothing();
  ApiResponse endSessionState = ApiResponse.nothing();
  ApiResponse updateLocationState = ApiResponse.nothing();

  // Real-time timer data
  TimerUpdate? _currentTimerUpdate;
  TimerUpdate? get currentTimerUpdate => _currentTimerUpdate;

  // Online/Offline status
  bool get isOnline {
    final online = _todayStats?.isOnline ?? false;
    return online;
  }

  // Display time (running clock)
  String get loginDisplayTime {
    if (_currentTimerUpdate != null) {
      return _currentTimerUpdate!.displayTime;
    }
    if (_todayStats == null) return '00:00:00';
    return _todayStats!.displayLoginTime;
  }

  // Location tracking timer and distance tracking
  Timer? _locationTimer;
  Timer? _statsRefreshTimer;
  Timer? _overlayUpdateTimer;
  StreamSubscription<TimerUpdate>? _timerUpdateSubscription;

  // Firestore location push interval - the customer's live tracking map reads
  // this, so the driver marker moves on the customer side every 30 seconds.
  // (Previously this was distance-based at 500m, which made the marker look
  // frozen for minutes at a time.)
  static const Duration FIRESTORE_LOCATION_UPDATE_INTERVAL =
      Duration(seconds: 30);
  Timer? _firestoreLocationTimer;

  // Latest position from the GPS stream, pushed to Firestore by the 30s timer
  Position? _latestPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Speed tracking for zoom adjustment (m/s)
  double _currentSpeedMs = 0.0;
  double get currentSpeedMs => _currentSpeedMs;

  /// Start a new work session
  Future<bool> startSession({
    required double latitude,
    required double longitude,
    int? gigBookingId,
  }) async {
    startSessionState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _sessionRepository.startSession(
        latitude: latitude,
        longitude: longitude,
        gigBookingId: gigBookingId,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;
        debugPrint('🚀 SessionProvider - startSession response data: $data');

        if (data != null && data['data'] != null) {
          debugPrint(
              '🚀 SessionProvider - Parsing session data: ${data['data']}');
          _activeSession = Session.fromJson(data['data']);
          activeSessionState = ApiResponse.success(_activeSession);
          debugPrint(
              '🚀 SessionProvider - Active session created: ${_activeSession?.sessionId}');
        }

        startSessionState = ApiResponse.success(response.data);

        // Force update Firestore location immediately to ensure document exists
        final deliveryBoyId = _authProvider.currentDeliveryBoy?.id;
        if (deliveryBoyId != null) {
          debugPrint(
              '🚀 Forcing initial Firestore location update on session start');
          await _firebaseOrderService.updateDriverLocation(
            deliveryBoyId: deliveryBoyId,
            latitude: latitude,
            longitude: longitude,
          );
        }

        // Start location tracking and stats refresh
        _startLocationTracking();
        _startStatsRefresh();
        debugPrint(
            '🚀 SessionProvider - Started location tracking and stats refresh');

        // Refresh today stats
        await getTodayStats();

        notifyListeners();
        return true;
      } else {
        startSessionState =
            ApiResponse.error(response.message ?? 'Failed to start session');
        notifyListeners();
        return false;
      }
    } catch (e) {
      startSessionState = ApiResponse.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// End the active work session
  Future<bool> endSession({
    required double latitude,
    required double longitude,
  }) async {
    endSessionState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _sessionRepository.endSession(
        latitude: latitude,
        longitude: longitude,
      );

      if (response.status == ApiStatus.success) {
        _activeSession = null;
        activeSessionState = ApiResponse.nothing();
        endSessionState = ApiResponse.success(response.data);

        // Stop location tracking and stats refresh
        _stopLocationTracking();
        _stopStatsRefresh();

        // Driver is offline now - tear down the floating button too
        _stopOverlayUpdates();
        await _overlayService.closeOverlay();
        if (io.Platform.isAndroid) {
          await NativeFloatingService.stopFloating();
        }

        // Refresh today stats
        await getTodayStats();

        notifyListeners();
        return true;
      } else {
        endSessionState =
            ApiResponse.error(response.message ?? 'Failed to end session');
        notifyListeners();
        return false;
      }
    } catch (e) {
      endSessionState = ApiResponse.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Update current location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _sessionRepository.updateLocation(
        latitude: latitude,
        longitude: longitude,
      );

      if (response.status == ApiStatus.success) {
        updateLocationState = ApiResponse.success(response.data);
      } else {
        updateLocationState =
            ApiResponse.error(response.message ?? 'Failed to update location');
      }
    } catch (e) {
      updateLocationState = ApiResponse.error(e.toString());
    }

    // Don't notify listeners for background location updates
  }

  /// Get today's tracking stats
  Future<void> getTodayStats() async {
    final deliveryBoyId = _authProvider.currentDeliveryBoy?.id;
    if (deliveryBoyId == null || deliveryBoyId == 0) {
      debugPrint(
          '📊 SessionProvider - Skipping getTodayStats - No delivery boy ID available');
      return;
    }

    todayStatsState = ApiResponse.loading();
    notifyListeners();

    // try {
    final response = await _sessionRepository.getTodayStats();

    debugPrint(
        '📊 SessionProvider - getTodayStats response status: ${response.status}');
    debugPrint(
        '📊 SessionProvider - getTodayStats response data: ${response.data}');

    if (response.status == ApiStatus.success) {
      final data = response.data;
      if (data != null && data['data'] != null) {
        debugPrint(
            '📊 SessionProvider - Parsing tracking data: ${data['data']}');
        _todayStats = DailyTracking.fromJson(data['data']);
        _activeSession = _todayStats!.activeSession;

        debugPrint(
            '📊 SessionProvider - Online status: ${_todayStats!.onlineStatus}');
        debugPrint('📊 SessionProvider - Is online: ${isOnline}');
        debugPrint(
            '📊 SessionProvider - Login display time: ${_todayStats!.displayLoginTime}');
        debugPrint(
            '📊 SessionProvider - Active session: ${_activeSession?.sessionId}');

        todayStatsState = ApiResponse.success(_todayStats);

        // If online but no tracking timers, start them
        if (isOnline && _locationTimer == null) {
          _startLocationTracking();
          _startStatsRefresh();
        }
      } else {
        debugPrint('📊 SessionProvider - No tracking data in response');
        todayStatsState = ApiResponse.error('No tracking data found');
      }
    } else {
      debugPrint('📊 SessionProvider - API error: ${response.message}');
      todayStatsState =
          ApiResponse.error(response.message ?? 'Failed to load stats');
    }
    // } catch (e) {
    //   debugPrint('📊 SessionProvider - Exception: $e');
    //   todayStatsState = ApiResponse.error(e.toString());
    // }

    notifyListeners();
  }

  /// Get active session details
  Future<void> getActiveSession() async {
    activeSessionState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _sessionRepository.getActiveSession();

      if (response.status == ApiStatus.success) {
        final data = response.data;
        if (data != null &&
            data['data'] != null &&
            data['data']['active_session'] != null) {
          _activeSession = Session.fromJson(data['data']['active_session']);
          activeSessionState = ApiResponse.success(_activeSession);
        } else {
          _activeSession = null;
          activeSessionState = ApiResponse.nothing();
        }
      } else {
        activeSessionState = ApiResponse.error(
            response.message ?? 'Failed to get active session');
      }
    } catch (e) {
      activeSessionState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  /// Start location tracking (every 1 minute to API + every 30 seconds to Firestore)
  void _startLocationTracking() {
    _locationTimer?.cancel();
    _firestoreLocationTimer?.cancel();
    _positionStreamSubscription?.cancel();

    // Update API every 1 minute
    _locationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {
        try {
          final position = await _getCurrentPosition();
          if (position != null) {
            await updateLocation(
              latitude: position.latitude,
              longitude: position.longitude,
            );
          }
        } catch (e) {
          // Silent fail - location tracking is background task
          debugPrint('Location update failed: $e');
        }
      },
    );

    // Push the latest location to Firestore every 30 seconds so the customer's
    // live tracking map keeps showing the delivery boy moving
    _firestoreLocationTimer = Timer.periodic(
      FIRESTORE_LOCATION_UPDATE_INTERVAL,
      (timer) => _pushLocationToFirestore(),
    );

    // Stream keeps _latestPosition fresh for the 30-second Firestore push
    _startPositionStream();
  }

  /// Write the driver's most recent position to Firestore.
  ///
  /// Runs unconditionally on the 30s timer - even when the driver is stationary -
  /// so `updated_at` also acts as a heartbeat the customer app can trust.
  Future<void> _pushLocationToFirestore() async {
    try {
      final deliveryBoyId = _authProvider.currentDeliveryBoy?.id;
      if (deliveryBoyId == null) {
        debugPrint(
            '⚠️ Cannot update Firestore location - delivery boy ID not available in AuthProvider');
        return;
      }

      // Prefer the streamed position; fall back to a fresh fix if the stream
      // hasn't emitted yet (driver stationary, or stream just started)
      final position = _latestPosition ?? await _getCurrentPosition();
      if (position == null) {
        debugPrint('⚠️ No position available for Firestore location update');
        return;
      }

      await _firebaseOrderService.updateDriverLocation(
        deliveryBoyId: deliveryBoyId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      debugPrint('✅ Firestore location updated (30s interval)');
    } catch (e) {
      debugPrint('❌ Error pushing location to Firestore: $e');
    }
  }

  /// Get platform-specific location settings for background tracking
  LocationSettings _getBackgroundLocationSettings() {
    if (io.Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter:
            10, // Emit every 10+ meters so the 30s Firestore push has a fresh fix
        forceLocationManager: true, // Use GPS when available
        intervalDuration: const Duration(
            seconds: 10), // Check location every 10 seconds (increased from 5)
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Zenfoo is tracking your location for deliveries',
          notificationTitle: 'Location Tracking Active',
          enableWakeLock: true, // Keep device awake
        ),
      );
    } else if (io.Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }
    // Default settings
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Emit every 10+ meters
    );
  }

  /// Start position stream to keep the latest fix in memory (works in background)
  /// The 30-second timer is what writes to Firestore; this only feeds it.
  void _startPositionStream() {
    try {
      debugPrint('🔵 Setting up background location tracking...');

      // Configure platform-specific background location settings
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: _getBackgroundLocationSettings(),
      ).listen((Position position) async {
        try {
          // Track current speed (m/s)
          _currentSpeedMs = position.speed;
          final speedKmh = _currentSpeedMs * 3.6;

          final isFirstFix = _latestPosition == null;
          _latestPosition = position;

          debugPrint(
              '📍 Location update: (${position.latitude}, ${position.longitude}) | Speed: ${speedKmh.toStringAsFixed(1)} km/h');

          // Push the first fix immediately so the Firestore document exists
          // right away - critical if the app restarted mid-session
          if (isFirstFix) {
            debugPrint(
                '🚀 First location fix - Ensuring Firestore document exists');
            await _pushLocationToFirestore();
          }
        } catch (e) {
          debugPrint('❌ Error in position stream listener: $e');
        }
      }, onError: (error) {
        debugPrint('❌ Position stream error: $error');
      });

      debugPrint('🔵 Position stream started (feeds 30s Firestore updates)');
    } catch (e) {
      debugPrint('❌ Error starting position stream: $e');
    }
  }

  /// Stop location tracking
  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _firestoreLocationTimer?.cancel();
    _firestoreLocationTimer = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _latestPosition = null;
  }

  /// Calculate distance between two coordinates using Haversine formula (in meters)
  // ignore: unused_element
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth radius in meters

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Start stats refresh with real-time timer (using isolate)
  void _startStatsRefresh() {
    _statsRefreshTimer?.cancel();
    _timerUpdateSubscription?.cancel();

    debugPrint('🚀 Starting real-time stats refresh with isolate...');

    // Start the realtime timer service if we have stats
    if (_todayStats != null) {
      _realtimeTimerService.startTimer(_todayStats!);

      // Listen to timer updates from isolate
      _timerUpdateSubscription =
          _realtimeTimerService.timerUpdates.listen((timerUpdate) {
        _currentTimerUpdate = timerUpdate;
        notifyListeners();
      });

      debugPrint('✅ Real-time timer started');
    } else {
      // Fallback: use regular timer if no stats yet
      _statsRefreshTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (isOnline) {
            notifyListeners();
          }
        },
      );
    }
  }

  /// Stop stats refresh
  void _stopStatsRefresh() {
    _statsRefreshTimer?.cancel();
    _statsRefreshTimer = null;
    _timerUpdateSubscription?.cancel();
    _timerUpdateSubscription = null;
    _realtimeTimerService.stopTimer();
    debugPrint('⏹️ Real-time stats refresh stopped');
  }

  /// Start overlay update timer
  void _startOverlayUpdates() {
    _overlayUpdateTimer?.cancel();
    _overlayUpdateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        if (isOnline) {
          await _updateOverlayData();
        }
      },
    );
  }

  /// Stop overlay updates
  void _stopOverlayUpdates() {
    _overlayUpdateTimer?.cancel();
    _overlayUpdateTimer = null;
  }

  /// Update data sent to overlay and update location in Firebase
  Future<void> _updateOverlayData() async {
    try {
      // Update overlay UI data
      await OverlayService.shareDataToOverlay({
        'loginTime': loginDisplayTime,
        'userName': 'Delivery Partner', // You can get this from AuthProvider
        'isOnline': isOnline,
      });

      // Update Firebase location while overlay is shown
      await _updateLocationWhileOverlayActive();
    } catch (e) {
      debugPrint('❌ Error updating overlay data: $e');
    }
  }

  /// Update driver location in Firebase while overlay is active
  Future<void> _updateLocationWhileOverlayActive() async {
    try {
      final position = await _getCurrentPosition();
      if (position != null) {
        // Get delivery boy ID from auth provider
        final deliveryBoyId = _authProvider.currentDeliveryBoy?.id;
        if (deliveryBoyId == null) {
          debugPrint('⚠️ [OVERLAY] Delivery boy ID not available');
          return;
        }

        // Get Firebase service and update location
        final firebaseService = FirebaseOrderService();

        debugPrint('📍 [OVERLAY] Updating location in Firebase');
        debugPrint('📍 [OVERLAY] Delivery Boy ID: $deliveryBoyId');
        debugPrint(
            '📍 [OVERLAY] Position: (${position.latitude}, ${position.longitude})');

        await firebaseService.updateDriverLocation(
          deliveryBoyId: deliveryBoyId,
          latitude: position.latitude,
          longitude: position.longitude,
        );

        debugPrint('✅ [OVERLAY] Location updated in Firebase successfully');
      } else {
        debugPrint('⚠️ [OVERLAY] Could not get current position');
      }
    } catch (e) {
      debugPrint('❌ [OVERLAY] Error updating location in Firebase: $e');
    }
  }

  /// Show overlay when app goes to background
  Future<void> showOverlay() async {
    if (isOnline) {
      await _overlayService.showOverlay();
      _startOverlayUpdates();
    }
  }

  /// Hide overlay when app comes to foreground
  Future<void> hideOverlay() async {
    await _overlayService.closeOverlay();
    _stopOverlayUpdates();
  }

  /// Get current GPS position
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting position: $e');
      return null;
    }
  }

  /// Reset all states
  void resetStates() {
    todayStatsState = ApiResponse.nothing();
    activeSessionState = ApiResponse.nothing();
    startSessionState = ApiResponse.nothing();
    endSessionState = ApiResponse.nothing();
    updateLocationState = ApiResponse.nothing();

    _todayStats = null;
    _activeSession = null;

    _stopLocationTracking();
    _stopStatsRefresh();
    _stopOverlayUpdates();
    _overlayService.closeOverlay();
    if (io.Platform.isAndroid) {
      NativeFloatingService.stopFloating();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _firestoreLocationTimer?.cancel();
    _statsRefreshTimer?.cancel();
    _overlayUpdateTimer?.cancel();
    _timerUpdateSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _overlayService.closeOverlay();
    if (io.Platform.isAndroid) {
      NativeFloatingService.stopFloating();
    }
    _realtimeTimerService.dispose();
    debugPrint('🧹 SessionProvider disposed');
    super.dispose();
  }
}
