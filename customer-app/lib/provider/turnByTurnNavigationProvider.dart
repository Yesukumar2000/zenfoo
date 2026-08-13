import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/models/deliveryBoyOrder.dart';
import 'package:project/helper/utils/deliveryTrackingService.dart';

/// Enum for navigation tracking states
enum NavigationTrackingState {
  initializing,
  active,
  fallbackUI,
  error,
  disposed
}

/// Enum for map view modes in fallback UI
enum ViewMode {
  fitBounds,
  driverFocused
}

/// Provider that manages real-time driver location tracking and fallback UI state
/// for turn-by-turn navigation
class TurnByTurnNavigationProvider extends ChangeNotifier {
  // Dependencies
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();

  // Navigation state
  NavigationTrackingState _trackingState = NavigationTrackingState.initializing;
  String? _navigationError;

  // Location data
  DriverLocation? _driverLocation;
  LatLng? _destinationLocation;
  LatLng? _initialLocation; // Fallback location if driver location unavailable

  // Firebase & connectivity
  bool _isFirebaseConnected = false;
  bool _firestoreAvailable = true;

  // View mode
  ViewMode _currentViewMode = ViewMode.fitBounds;

  // Streams
  StreamSubscription<DeliveryBoyOrder?>? _deliveryTracking;
  StreamSubscription<bool>? _firebaseAvailabilityCheck;

  // Debounce timer for location updates
  Timer? _locationUpdateDebounce;

  // Getters
  NavigationTrackingState get trackingState => _trackingState;
  String? get navigationError => _navigationError;
  DriverLocation? get driverLocation => _driverLocation;
  LatLng? get destinationLocation => _destinationLocation;
  LatLng? get initialLocation => _initialLocation;
  bool get isFirebaseConnected => _isFirebaseConnected;
  bool get firestoreAvailable => _firestoreAvailable;
  ViewMode get currentViewMode => _currentViewMode;

  // Computed getters
  bool get isFallbackUIActive => _trackingState == NavigationTrackingState.fallbackUI;
  bool get isNavigationActive => _trackingState == NavigationTrackingState.active;
  bool get isError => _trackingState == NavigationTrackingState.error;
  bool get isInitializing => _trackingState == NavigationTrackingState.initializing;

  /// Initialize tracking with Firebase delivery boy location
  /// Call this during screen initialization
  Future<void> initializeTracking({
    required String deliveryBoyId,
    required double destinationLat,
    required double destinationLng,
    required double initialLat,
    required double initialLng,
  }) async {
    try {
      log('🔧 [TurnByTurnProvider] Initializing tracking for delivery boy: $deliveryBoyId');

      // Store destination and initial location
      _destinationLocation = LatLng(destinationLat, destinationLng);
      _initialLocation = LatLng(initialLat, initialLng);

      // Check Firebase availability
      _firestoreAvailable = await _trackingService.isFirestoreAvailable();

      if (!_firestoreAvailable) {
        log('⚠️ [TurnByTurnProvider] Firestore not available, using fallback mode');
        _trackingState = NavigationTrackingState.fallbackUI;
        _navigationError = 'Firebase unavailable';
        _isFirebaseConnected = false;
        notifyListeners();
        return;
      }

      // Subscribe to real-time delivery tracking
      _deliveryTracking = _trackingService
          .listenToDeliveryTracking(deliveryBoyId)
          .listen(
        (DeliveryBoyOrder? order) {
          if (order?.driverLocation?.isValid ?? false) {
            log('📍 [TurnByTurnProvider] Received driver location update: (${order!.driverLocation!.latitude}, ${order.driverLocation!.longitude})');
            _updateDriverLocation(order.driverLocation!);
            _isFirebaseConnected = true;
          }
        },
        onError: (error) {
          log('❌ [TurnByTurnProvider] Tracking stream error: $error');
          _navigationError = 'Location tracking failed';
          _isFirebaseConnected = false;
          if (_trackingState == NavigationTrackingState.active) {
            switchToFallbackUI('Location tracking failed');
          }
        },
      );

      // Update state to active once we're listening
      _trackingState = NavigationTrackingState.active;
      log('✅ [TurnByTurnProvider] Tracking initialized successfully');
      notifyListeners();
    } catch (e) {
      log('❌ [TurnByTurnProvider] Error initializing tracking: $e');
      _navigationError = 'Initialization failed: $e';
      _trackingState = NavigationTrackingState.error;
      notifyListeners();
    }
  }

  /// Update driver location (called from stream listener)
  /// Includes debouncing to avoid excessive rebuilds
  void _updateDriverLocation(DriverLocation location) {
    // Cancel previous debounce timer
    _locationUpdateDebounce?.cancel();

    // Set new debounce timer
    _locationUpdateDebounce = Timer(const Duration(milliseconds: 300), () {
      _driverLocation = location;
      notifyListeners();
    });
  }

  /// Switch to fallback UI when navigation fails
  Future<void> switchToFallbackUI(String error) async {
    log('🔄 [TurnByTurnProvider] Switching to fallback UI: $error');

    _trackingState = NavigationTrackingState.fallbackUI;
    _navigationError = error;

    // Reset to fit bounds view mode when switching to fallback
    _currentViewMode = ViewMode.fitBounds;

    notifyListeners();
  }

  /// Switch to fit bounds view mode
  void switchToFitBoundsView() {
    log('📍 [TurnByTurnProvider] Switching to fit bounds view');

    _currentViewMode = ViewMode.fitBounds;
    notifyListeners();
  }

  /// Switch to driver-focused view mode
  void switchToDriverFocusedView() {
    log('🔍 [TurnByTurnProvider] Switching to driver-focused view');

    _currentViewMode = ViewMode.driverFocused;
    notifyListeners();
  }

  /// Check if we have valid locations to display
  bool get hasValidLocations {
    final driverLoc = _driverLocation ?? _initialLocation;
    return driverLoc != null && _destinationLocation != null;
  }

  /// Get driver location, fallback to initial location
  LatLng? get displayedDriverLocation {
    if (_driverLocation?.isValid ?? false) {
      return LatLng(_driverLocation!.latitude!, _driverLocation!.longitude!);
    }
    return _initialLocation;
  }

  /// Clear any ongoing operations and prepare for disposal
  Future<void> stopTracking() async {
    try {
      log('🛑 [TurnByTurnProvider] Stopping tracking');

      _locationUpdateDebounce?.cancel();
      _deliveryTracking?.cancel();
      _firebaseAvailabilityCheck?.cancel();

      _trackingState = NavigationTrackingState.disposed;
      notifyListeners();
    } catch (e) {
      log('⚠️ [TurnByTurnProvider] Error stopping tracking: $e');
    }
  }

  /// Dispose provider and clean up resources
  @override
  Future<void> dispose() async {
    await stopTracking();
    super.dispose();
  }
}
