import 'dart:async';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/notification_helper.dart';
import 'package:zenfoo_partner/view/screens/delivery/delivery_confirmation_screen.dart';
import 'package:zenfoo_partner/view/screens/delivery/turn_by_turn_navigation_screen.dart'
    show TurnByTurnNavigationScreen;
import 'package:zenfoo_partner/view/screens/chat/order_chat_screen.dart';

enum DeliveryStepType { pickup, delivery }

/// Configuration flags for navigation features
class NavigationConfig {
  /// Enable real road polylines using Google Directions API
  /// Set to true to show actual road paths instead of arc lines
  static const bool enableRealRoadPolylines = false;

  /// Enable turn-by-turn navigation info card
  static const bool enableTurnByTurnNavigation = false;
}

class DeliveryDetailScreen extends StatefulWidget {
  final IncomingOrder order;
  final int currentStepIndex;
  final int totalSteps;
  final DeliveryStepType stepType;
  final SellerVisit? seller;
  final VoidCallback onActionComplete;

  const DeliveryDetailScreen({
    super.key,
    required this.order,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.stepType,
    this.seller,
    required this.onActionComplete,
  });

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // App lifecycle state - track if app is in foreground or background
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  // Live location tracking
  StreamSubscription<Position>? _locationSubscription;
  LatLng? _currentDriverLocation;
  double _distanceToDestination = 0.0;
  String _estimatedTime = '--';
  String _navigationDirection = 'Head towards destination';

  StreamSubscription<CompassEvent>? _compassSubscription;

  // Firebase order listener
  StreamSubscription<DocumentSnapshot>? _orderSubscription;

  // Firebase service for location updates
  late FirebaseOrderService _firebaseOrderService;

  // Track last Firebase location update to avoid duplicate updates
  Position? _lastFirestoreLocationUpdate;

  // Cache delivery boy ID for background location updates
  int? _deliveryBoyId;

  // Smooth marker animation
  late AnimationController _markerAnimationController;
  late Animation<double> _markerAnimation;
  VoidCallback? _animationListener;

  // Swipe to confirm action button state
  double _dragPosition = 0.0;
  bool _isActionConfirmed = false;
  bool _isActionProcessing = false;

  // Swipe hint animation
  late AnimationController _swipeHintController;
  late Animation<double> _swipeHintAnim;

  // Navigation state
  bool _isNavigationActive = false;
  Timer?
      _fitMarkersTimer; // Timer for delayed marker fitting - can be cancelled when navigation starts

  // Bottom sheet state
  late DraggableScrollableController _sheetController;
  bool _isSheetExpanded = false;
  late ValueNotifier<bool> _sheetExpandedNotifier;
  late ValueNotifier<double>
      _sheetSizeNotifier; // Track actual sheet size (0.0 to 1.0)

  @override
  void initState() {
    super.initState();

    // Auto-start turn-by-turn navigation immediately
    _isNavigationActive = true;

    // Log received parameters
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 DeliveryDetailScreen.initState()');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📋 Received Parameters:');
    debugPrint('  • currentStepIndex: ${widget.currentStepIndex}');
    debugPrint('  • totalSteps: ${widget.totalSteps}');
    debugPrint('  • stepType: ${widget.stepType}');
    debugPrint('  • order.orderId: ${widget.order.orderId}');
    if (widget.stepType == DeliveryStepType.pickup && widget.seller != null) {
      debugPrint('  • seller.sellerId: ${widget.seller!.sellerId}');
      debugPrint('  • seller.storeName: ${widget.seller!.storeName}');
      debugPrint('  • seller.storeId: ${widget.seller!.storeId}');
      debugPrint('  • seller.sellerPhoneNumber: ${widget.seller!.sellerPhoneNumber}');
      debugPrint('  • seller.sellerAddress: ${widget.seller!.sellerAddress}');
      debugPrint('  • seller.isZenfooStore: ${widget.seller!.isZenfooStore}');
    }
    debugPrint('═══════════════════════════════════════════════════════');

    // Initialize Firebase service for location updates
    _firebaseOrderService = FirebaseOrderService();

    // Cache delivery boy ID for background location updates
    try {
      final authProvider = context.read<AuthProvider>();
      _deliveryBoyId = authProvider.currentDeliveryBoy?.id;
      debugPrint(
          '🔵 Cached delivery boy ID: $_deliveryBoyId for background updates');
    } catch (e) {
      debugPrint('⚠️ Could not read delivery boy ID from AuthProvider: $e');
    }

    // Initialize animation controller for smooth marker movement
    // Reduced to 400ms to complete before next location update (5m at ~10m/s = ~0.5s)
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _markerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _markerAnimationController, curve: Curves.easeInOut),
    );

    // Initialize swipe hint blink animation
    _swipeHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _swipeHintAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _swipeHintController, curve: Curves.easeInOut),
    );

    // Initialize bottom sheet controller and state tracking
    _sheetController = DraggableScrollableController();
    _sheetExpandedNotifier = ValueNotifier<bool>(false);
    _sheetSizeNotifier = ValueNotifier<double>(0.3); // Start at 30% (collapsed)
    _sheetController.addListener(_onSheetSizeChanged);

    WidgetsBinding.instance.addObserver(this);
    _startOrderListener(); // Listen for order updates/deletions

    // Start location tracking immediately
    _startLocationTracking();
  }

  /// Start tracking device compass heading (currently disabled)
  void startCompassTracking() {
    // Compass tracking disabled - bike marker rotation handled in turn-by-turn navigation
  }

  /// Listen to Firebase for order updates or deletions
  void _startOrderListener() {
    try {
      final orderId = widget.order.orderId;
      debugPrint('🎧 Starting Firebase listener for order $orderId');

      _orderSubscription = FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId.toString())
          .snapshots()
          .listen(
        (DocumentSnapshot snapshot) {
          if (!mounted) return;

          if (!snapshot.exists) {
            // Order has been deleted from Firebase
            debugPrint(
                '❌ Order $orderId deleted from Firebase - navigating to home');
            Navigator.of(context).popUntil((route) {
              // Pop until we reach a route that's not a delivery screen
              return route.settings.name == null ||
                  !route.settings.name!.contains('delivery');
            });
          } else {
            // Order exists and might have been updated
            debugPrint('✅ Order $orderId updated in Firebase');
          }
        },
        onError: (error) {
          debugPrint('❌ Error listening to order: $error');
        },
      );

      debugPrint('✅ Firebase order listener started');
    } catch (e) {
      debugPrint('❌ Error starting order listener: $e');
    }
  }

  /// Lifecycle observer - handle app resume/pause
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    debugPrint(
        '📱 App lifecycle state: $state (animation will ${_isAppInForeground ? 'ENABLED' : 'DISABLED'})');

    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 Screen resumed');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background
      // Delivery detail location stream will continue with foreground notification
      // Firebase updates will continue to be sent every 25m
      debugPrint('📱 App backgrounded');
      debugPrint(
          '📱 Location stream continues in background (with foreground notification)');
      debugPrint('📱 Firebase location updates will continue');
    }
  }

  /// Check if app is in foreground (not in background)
  bool get _isAppInForeground =>
      _appLifecycleState == AppLifecycleState.resumed;

  /// Get optimal location settings for real-time marker updates
  LocationSettings _getOptimalLocationSettings() {
    if (io.Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters (increased from 10m to reduce glitches)
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10), // Check every 10 seconds (increased from 5)
        // Show foreground notification to keep location tracking alive in background
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Tracking your location for delivery',
          notificationTitle: 'Zenfoo Delivery - Location Tracking',
          enableWakeLock: true, // Keep device awake for continuous tracking
        ),
      );
    } else if (io.Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    // Default settings
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters
    );
  }

  /// Start tracking driver location with distance-based updates
  Future<void> _startLocationTracking() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 Location Tracking Initialization');
    debugPrint('═══════════════════════════════════════════════════════');

    // Check and request permissions
    final permission = await Geolocator.checkPermission();
    debugPrint('📍 Current permission status: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('📍 Permission is denied, requesting...');
      final requested = await Geolocator.requestPermission();
      debugPrint('📍 Permission request result: $requested');

      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        debugPrint(
            '❌ Location permission denied or denied forever - cannot track location');
        return;
      }
    } else if (permission == LocationPermission.deniedForever) {
      debugPrint(
          '❌ Location permission denied forever - user must enable in settings');
      return;
    }

    debugPrint('✅ Location permission granted: $permission');

    // Check if location service is enabled
    final isLocationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();
    debugPrint('📍 Location service enabled: $isLocationServiceEnabled');

    if (!isLocationServiceEnabled) {
      debugPrint('❌ Location service is disabled - cannot track location');
      return;
    }

    // Get initial location
    try {
      debugPrint('📍 Fetching initial location...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      debugPrint(
          '✅ Initial location obtained: ${position.latitude}, ${position.longitude}');
      _updateDriverLocation(position);
    } catch (e) {
      debugPrint('❌ Error getting initial location: $e');
    }

    // Log location settings being used
    final settings = _getOptimalLocationSettings();
    debugPrint('📍 Location stream settings: ${settings.runtimeType}');
    if (settings is AndroidSettings) {
      debugPrint('   • Distance Filter: ${settings.distanceFilter}m');
      debugPrint(
          '   • Force Location Manager: ${settings.forceLocationManager}');
      debugPrint('   • Interval Duration: ${settings.intervalDuration}');
      debugPrint(
          '   • Foreground Notification: ${settings.foregroundNotificationConfig != null}');
    } else if (settings is AppleSettings) {
      debugPrint(
          '   • Allow Background Updates: ${settings.allowBackgroundLocationUpdates}');
      debugPrint(
          '   • Pause Automatically: ${settings.pauseLocationUpdatesAutomatically}');
    }

    // Start listening to location updates with distance filter
    // Use background location settings for continuous tracking
    debugPrint('📍 Starting location stream subscription...');
    int updateCount = 0;
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        updateCount++;
        debugPrint(
            '📍 [$updateCount] Location stream emitted: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy.toStringAsFixed(1)}m)');
        debugPrint('📍 [$updateCount] Calling _updateDriverLocation...');
        _updateDriverLocation(position);
        debugPrint('📍 [$updateCount] Finished _updateDriverLocation');
      },
      onError: (error) {
        debugPrint('❌ Location stream error: $error');
      },
      onDone: () {
        debugPrint('⚠️ Location stream closed/done - THIS SHOULD NOT HAPPEN');
      },
    );

    debugPrint('✅ Location tracking started successfully');
    debugPrint('═══════════════════════════════════════════════════════');
  }

  /// Update driver location and recalculate navigation info
  void _updateDriverLocation(Position position) {
    // IMPORTANT: Update Firebase FIRST, even if widget is not mounted
    // This ensures location updates happen in the background
    _updateFirebaseLocation(position);

    // Now handle UI updates (only if widget is mounted)
    if (!mounted) return;

    final newLocation =
        LatLng(latitude: position.latitude, longitude: position.longitude);

    // Calculate distance to destination
    final destLat = _currentTargetLocation.latitude;
    final destLng = _currentTargetLocation.longitude;
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      destLat,
      destLng,
    );

    // Calculate bearing for NAVIGATION INFO only (not for bike rotation)
    final bearing = Geolocator.bearingBetween(
      position.latitude,
      position.longitude,
      destLat,
      destLng,
    );

    // Update state - only if widget is still mounted
    if (mounted) {
      setState(() {
        _currentDriverLocation = newLocation;
        _distanceToDestination = distance;
        // _estimatedTime = _calculateETA(distance);
        // _navigationDirection = _getDirectionFromBearing(bearing);
      });
    }

    debugPrint(
        '📍 Driver location updated: ${position.latitude}, ${position.longitude}');
    debugPrint('📏 Distance to destination: ${distance.toStringAsFixed(0)}m');
  }

  /// Update driver location in Firebase (distance-based to avoid excessive updates)
  void _updateFirebaseLocation(Position position) {
    try {
      debugPrint(
          '🔵 Firebase: Processing location update: ${position.latitude}, ${position.longitude}');

      // Initialize last location if not set
      if (_lastFirestoreLocationUpdate == null) {
        _lastFirestoreLocationUpdate = position;
        debugPrint('🔵 Firebase: Initialized baseline location');
        debugPrint('🔵 Firebase: Delivery Boy ID cached: $_deliveryBoyId');
        return;
      }

      // Calculate distance from last Firebase update
      final distanceTraveled = Geolocator.distanceBetween(
        _lastFirestoreLocationUpdate!.latitude,
        _lastFirestoreLocationUpdate!.longitude,
        position.latitude,
        position.longitude,
      );

      debugPrint(
          '🔵 Firebase: Distance since last update: ${distanceTraveled.toStringAsFixed(1)}m (threshold: 200.0m)');

      // Update Firebase if distance threshold exceeded (200m - increased from 25m to reduce Firebase writes and billing costs)
      if (distanceTraveled >= 200.0) {
        // Use cached delivery boy ID (works even when widget is unmounted)
        if (_deliveryBoyId != null) {
          debugPrint('🔥 Firebase: Sending location update...');
          debugPrint('🔥 Firebase: Delivery Boy ID: $_deliveryBoyId');
          debugPrint(
              '🔥 Firebase: Position: (${position.latitude}, ${position.longitude})');

          _firebaseOrderService.updateDriverLocation(
            deliveryBoyId: _deliveryBoyId!,
            latitude: position.latitude,
            longitude: position.longitude,
          );

          _lastFirestoreLocationUpdate = position;
          debugPrint(
              '🔥 Firebase: ✅ Location updated (moved ${distanceTraveled.toStringAsFixed(1)}m)');
        } else {
          debugPrint('🔥 Firebase: ❌ Cannot update - delivery boy ID is null');
          debugPrint('🔥 Firebase: Cached ID: $_deliveryBoyId');
        }
      } else {
        debugPrint(
            '🔵 Firebase: Waiting for more movement (${(200.0 - distanceTraveled).toStringAsFixed(1)}m remaining)');
      }
    } catch (e, st) {
      debugPrint('❌ Firebase: Error updating location: $e');
      debugPrint('❌ Firebase: Stack trace: $st');
    }
  }

  /// Calculate estimated time of arrival based on distance
  String _calculateETA(double distanceMeters) {
    // Assume average speed of 25 km/h in city traffic
    const avgSpeedKmh = 25.0;
    final distanceKm = distanceMeters / 1000;
    final timeHours = distanceKm / avgSpeedKmh;
    final timeMinutes = (timeHours * 60).round();

    if (timeMinutes < 1) {
      return '< 1 min';
    } else if (timeMinutes == 1) {
      return '1 min';
    } else {
      return '$timeMinutes mins';
    }
  }

  /// Get navigation direction text from bearing
  String _getDirectionFromBearing(double bearing) {
    // Normalize bearing to 0-360
    final normalizedBearing = (bearing + 360) % 360;

    if (normalizedBearing >= 337.5 || normalizedBearing < 22.5) {
      return 'Head North';
    } else if (normalizedBearing >= 22.5 && normalizedBearing < 67.5) {
      return 'Head Northeast';
    } else if (normalizedBearing >= 67.5 && normalizedBearing < 112.5) {
      return 'Head East';
    } else if (normalizedBearing >= 112.5 && normalizedBearing < 157.5) {
      return 'Head Southeast';
    } else if (normalizedBearing >= 157.5 && normalizedBearing < 202.5) {
      return 'Head South';
    } else if (normalizedBearing >= 202.5 && normalizedBearing < 247.5) {
      return 'Head Southwest';
    } else if (normalizedBearing >= 247.5 && normalizedBearing < 292.5) {
      return 'Head West';
    } else {
      return 'Head Northwest';
    }
  }

  /// Create bike marker using heading (direction device is facing)

  LatLng get _currentTargetLocation {
    if (widget.stepType == DeliveryStepType.pickup && widget.seller != null) {
      return LatLng(
          latitude: widget.seller!.latitude,
          longitude: widget.seller!.longitude);
    } else {
      return LatLng(
          latitude: widget.order.customer.lat,
          longitude: widget.order.customer.lng);
    }
  }

  String get _currentName {
    if (widget.stepType == DeliveryStepType.pickup && widget.seller != null) {
      return widget.seller!.storeName;
    } else {
      return widget.order.customer.displayName;
    }
  }

  String get _currentAddress {
    if (widget.stepType == DeliveryStepType.pickup && widget.seller != null) {
      return widget.seller!.sellerAddress.isNotEmpty
          ? widget.seller!.sellerAddress
          : '${widget.seller!.storeName} Store';
    } else {
      return widget.order.customer.address;
    }
  }

  void _endNavigation() {
    setState(() {
      _isNavigationActive = false;
    });
  }

  /// Listener for bottom sheet size changes
  void _onSheetSizeChanged() {
    if (!_sheetController.isAttached) return;

    final currentSize = _sheetController.size;

    // Update the sheet size notifier for button positioning
    _sheetSizeNotifier.value = currentSize;

    // Consider sheet "expanded" if size > 0.5 (halfway)
    final isExpanded = currentSize > 0.5;

    if (isExpanded != _isSheetExpanded) {
      _isSheetExpanded = isExpanded;
      _sheetExpandedNotifier.value = isExpanded;
    }
  }

  Future<void> _makePhoneCall() async {
    String? phone;
    String contactName = '';

    if (widget.stepType == DeliveryStepType.delivery) {
      // For delivery, call the customer
      phone = widget.order.customer.mobile;
      contactName = widget.order.customer.displayName;
    } else if (widget.stepType == DeliveryStepType.pickup) {
      // For pickup, call the current seller
      final seller = widget.seller;
      phone = seller?.sellerPhoneNumber;
      contactName = seller?.storeName ?? 'Seller';
    }

    if (phone != null && phone.isNotEmpty) {
      try {
        final url = Uri.parse('tel:$phone');
        if (await canLaunchUrl(url)) {
          debugPrint('📞 Calling $contactName at $phone');
          await launchUrl(url);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.read<LanguageProvider>().getTranslatedText('cannot_make_calls')),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.read<LanguageProvider>().getTranslatedText('error_making_call')}: $e'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        debugPrint('❌ Error making phone call: $e');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.stepType == DeliveryStepType.delivery ? 'Customer' : (widget.seller?.isHandoffPoint == true ? 'Driver' : 'Seller')} ${context.read<LanguageProvider>().getTranslatedText('phone_number_not_available')}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Open chat with customer (for delivery) or seller (for pickup)
  Future<void> _openChat() async {
    try {
      if (widget.stepType == DeliveryStepType.delivery) {
        // Chat with customer
        final customer = widget.order.customer;
        if (customer.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderChatScreen(
                orderId: widget.order.orderId,
                sellerId: customer.id!,
                sellerName: customer.name,
                sellerType: 'customer',
              ),
            ),
          );
          debugPrint('💬 Opening chat with customer: ${customer.name}');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.read<LanguageProvider>().getTranslatedText('customer_id_not_available')),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (widget.stepType == DeliveryStepType.pickup) {
        // Chat with seller
        final seller = widget.seller;
        if (seller != null && seller.sellerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderChatScreen(
                orderId: widget.order.orderId,
                sellerId: seller.sellerId!,
                sellerName: seller.storeName,
                sellerType: 'seller',
              ),
            ),
          );
          debugPrint('💬 Opening chat with seller: ${seller.storeName}');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.read<LanguageProvider>().getTranslatedText('seller_info_not_available')),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.read<LanguageProvider>().getTranslatedText('error_opening_chat')}: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Open destination address in Google Maps (Android) or Apple Maps (iOS)
  /// Open destination in maps with navigation support
  /// Opens native maps app with latitude, longitude, and location label
  /// Falls back to web maps if native app unavailable
  Future<void> _openDestinationInMaps() async {
    final location = _currentTargetLocation;
    final lat = location.latitude;
    final lng = location.longitude;
    final label = _currentName;

    // Validate coordinates
    if (lat == 0.0 && lng == 0.0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LanguageProvider>().getTranslatedText('location_coordinates_not_available')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      if (io.Platform.isIOS) {
        // Apple Maps URL scheme with directions mode
        // saddr=Current Location means "Start from current location"
        // daddr is destination with coordinates and address
        // dirflg=d for driving directions
        final encodedLabel = Uri.encodeComponent(label);
        final mapsUrl =
            'https://maps.apple.com/?saddr=Current%20Location&daddr=$lat,$lng&dirflg=d&z=16&q=$encodedLabel';

        debugPrint('📍 Opening Apple Maps Directions: $mapsUrl');

        if (await canLaunchUrl(Uri.parse(mapsUrl))) {
          await launchUrl(Uri.parse(mapsUrl),
              mode: LaunchMode.externalApplication);
        } else {
          // Fallback to basic directions without address label
          final simpleMapsUrl =
              'https://maps.apple.com/?saddr=Current%20Location&daddr=$lat,$lng&dirflg=d';
          if (await canLaunchUrl(Uri.parse(simpleMapsUrl))) {
            await launchUrl(Uri.parse(simpleMapsUrl),
                mode: LaunchMode.externalApplication);
          } else {
            // Last fallback - just show the location
            final locationUrl =
                'https://maps.apple.com/?ll=$lat,$lng&z=16&q=$encodedLabel';
            if (await canLaunchUrl(Uri.parse(locationUrl))) {
              await launchUrl(Uri.parse(locationUrl),
                  mode: LaunchMode.externalApplication);
            } else {
              _showMapsError('Unable to open maps on this device');
            }
          }
        }
      } else if (io.Platform.isAndroid) {
        // Google Maps directions URL - shows "Start" to destination navigation
        // This opens Google Maps in directions mode from current location to destination
        final encodedLabel = Uri.encodeComponent(label);
        final mapsUrl =
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$encodedLabel&travelmode=driving';

        debugPrint('📍 Opening Google Maps Directions: $mapsUrl');

        if (await canLaunchUrl(Uri.parse(mapsUrl))) {
          await launchUrl(Uri.parse(mapsUrl),
              mode: LaunchMode.externalApplication);
        } else {
          // Fallback to simpler directions URL without place_id
          final simpleMapsUrl =
              'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';

          debugPrint('📍 Fallback to simplified directions: $simpleMapsUrl');

          if (await canLaunchUrl(Uri.parse(simpleMapsUrl))) {
            await launchUrl(Uri.parse(simpleMapsUrl),
                mode: LaunchMode.externalApplication);
          } else {
            // Last fallback - geo: scheme just to show the location
            final geoUrl = 'geo:$lat,$lng';
            if (await canLaunchUrl(Uri.parse(geoUrl))) {
              await launchUrl(Uri.parse(geoUrl),
                  mode: LaunchMode.externalApplication);
            } else {
              _showMapsError(
                  'Unable to open maps. Please install Google Maps.');
            }
          }
        }
      } else {
        _showMapsError('Maps not supported on this platform');
      }
    } catch (e) {
      debugPrint('❌ Error opening maps: $e');
      _showMapsError('Error opening maps: ${e.toString()}');
    }
  }

  /// Show error message when maps cannot be opened
  void _showMapsError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Build turn-by-turn navigation panel showing current and next turns
  Widget _buildTurnByTurnNavigationPanel(AppColorScheme colorScheme) {
    // Format distance
    String distanceText;
    if (_distanceToDestination < 1000) {
      distanceText = '${_distanceToDestination.toStringAsFixed(0)} m';
    } else {
      distanceText = '${(_distanceToDestination / 1000).toStringAsFixed(1)} km';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Main navigation info (current direction)
          Row(
            children: [
              /// Large direction icon with background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getDirectionIcon(),
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              /// Main direction and destination
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _navigationDirection,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.stepType == DeliveryStepType.pickup
                          ? widget.seller?.storeName ?? "Store"
                          : widget.order.customer.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              /// Distance and ETA
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    distanceText,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _estimatedTime,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// Street-level navigation info with next turns
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Real-time status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bike,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Real-time navigation',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// Street view info showing next turns
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      /// Camera icon for street view
                      Icon(
                        Icons.streetview,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),

                      /// Street level description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Street-level view',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Follow the highlighted route ahead',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Arrow pointing forward
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          /// Full screen map or turn-by-turn navigation
          Positioned.fill(
            child: Stack(
              children: [
                /// Show Turn-by-Turn Navigation or Google Map based on state
                if (_isNavigationActive)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.15,
                    ),
                    child: TurnByTurnNavigationScreen(
                      destinationLat: _currentTargetLocation.latitude,
                      destinationLng: _currentTargetLocation.longitude,
                      destinationName:
                          widget.stepType == DeliveryStepType.pickup
                              ? widget.seller?.storeName ?? 'Store'
                              : widget.order.customer.displayName,
                      initialLat: _currentDriverLocation?.latitude ?? 0,
                      initialLng: _currentDriverLocation?.longitude ?? 0,
                      onExit: _endNavigation,
                      sellerStoreName:
                          widget.stepType == DeliveryStepType.pickup
                              ? widget.seller?.storeName
                              : null,
                      sellerAddress: widget.stepType == DeliveryStepType.pickup
                          ? widget.seller?.sellerAddress
                          : null,
                      isSheetExpanded: _sheetExpandedNotifier,
                      sheetSize: _sheetSizeNotifier,
                    ),
                  )
                else

                  /// Static Map Preview with bottom padding for sheet
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.15,
                    ),
                    child: Stack(
                      children: [
                        // Static Google Maps image
                        Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?'
                          'center=${_currentDriverLocation?.latitude ?? 0},'
                          '${_currentDriverLocation?.longitude ?? 0}&'
                          'zoom=15&'
                          'size=400x800&'
                          'markers=color:blue%7C${_currentDriverLocation?.latitude ?? 0},'
                          '${_currentDriverLocation?.longitude ?? 0}&'
                          'markers=color:red%7C${_currentTargetLocation.latitude},'
                          '${_currentTargetLocation.longitude}&'
                          'key=${Constant.googleApiKey}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE8E8E8),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Map unavailable',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Overlay with guidance text
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Tap "Start Navigation" for turn-by-turn guidance',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                /// Step indicators at top
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 100, left: 16),
                    child: Row(
                      children: [
                        /// Step bubbles
                        Expanded(
                          child: _buildStepIndicators(colorScheme),
                        ),

                        const SizedBox(width: 16),

                        // Support and tips icons removed
                      ],
                    ),
                  ),
                ),

                /// Navigation info card (turn-by-turn) - only show if enabled
                if (NavigationConfig.enableTurnByTurnNavigation)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 70,
                    child: _buildNavigationInfoCard(colorScheme),
                  ),

                /// Map control buttons (Google Maps style)
                const Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Show both driver and destination (zoom to fit)
                      // Map control buttons disabled - using turn-by-turn navigation instead
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// BOTTOM SHEET OVERLAY - Draggable from 30% to top
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: 0,
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.15,
              minChildSize: 0.15,
              maxChildSize: 0.75,
              snap: true,
              snapSizes: const [0.15, 0.75],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// DRAG HANDLE
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 12, bottom: 8),
                                  child: Center(
                                    child: Container(
                                      width: 48,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: colorScheme.textTertiary
                                            .withValues(alpha: 0.3),
                                        borderRadius:
                                            BorderRadius.circular(2.5),
                                      ),
                                    ),
                                  ),
                                ),

                                /// MAIN CONTENT
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      /// Open Map button
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          /// Order type badge (Single or Multi)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: widget.order.isMultiOrder
                                                  ? colorScheme.primary
                                                      .withValues(alpha: 0.15)
                                                  : Colors.green
                                                      .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: widget.order.isMultiOrder
                                                    ? colorScheme.primary
                                                        .withValues(alpha: 0.3)
                                                    : Colors.green
                                                        .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              widget.order.isMultiOrder
                                                  ? 'MULTI ORDER'
                                                  : 'SINGLE ORDER',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: widget.order.isMultiOrder
                                                    ? colorScheme.primary
                                                    : Colors.green,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),

                                          const Spacer(),
                                          _buildActionButton(
                                            colorScheme: colorScheme,
                                            icon: Icons.map_outlined,
                                            label: 'Open Maps',
                                            onTap: _openDestinationInMaps,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),

                                      /// DETAILS CARD - Location and ID info
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: colorScheme.cardBackground,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: colorScheme.cardBorder,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            /// Order ID
                                            Text(
                                              'ID : ${formatOrderNumber(widget.order.orderId)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    colorScheme.textSecondary,
                                                letterSpacing: -0.2,
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            /// Store/Customer name
                                            Text(
                                              widget.stepType ==
                                                      DeliveryStepType.pickup
                                                  ? 'Store Name'
                                                  : 'Customer Name',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.textTertiary,
                                                letterSpacing: -0.15,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _currentName,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: colorScheme.textPrimary,
                                                letterSpacing: -0.3,
                                              ),
                                            ),

                                            const SizedBox(height: 14),

                                            /// Divider
                                            Container(
                                              height: 1,
                                              color: colorScheme.border,
                                            ),

                                            const SizedBox(height: 14),

                                            /// Address
                                            Text(
                                              widget.stepType ==
                                                      DeliveryStepType.pickup
                                                  ? 'Store Address'
                                                  : 'Customer Address',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.textTertiary,
                                                letterSpacing: -0.15,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _currentAddress,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.textPrimary,
                                                letterSpacing: -0.2,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      /// Call and Chat buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildActionButton(
                                              colorScheme: colorScheme,
                                              icon: Icons.phone_outlined,
                                              label: 'Call',
                                              onTap: _makePhoneCall,
                                            ),
                                          ),
                                          // Hide Chat button when picking up from a
                                          // Zenfoo store (store_id 12 or 13) — no
                                          // individual seller to chat with. Same on
                                          // the handoff stop of an emergency driver
                                          // change: the counterpart is the previous
                                          // driver, reached by Call, and its
                                          // seller_id 0 would open a dead chat room.
                                          if (!(widget.stepType ==
                                                  DeliveryStepType.pickup &&
                                              widget.seller != null &&
                                              (widget.seller!.storeId == 12 ||
                                                  widget.seller!.storeId == 13 ||
                                                  widget.seller!
                                                      .isHandoffPoint))) ...[
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildActionButton(
                                                colorScheme: colorScheme,
                                                icon: Icons
                                                    .chat_bubble_outline_rounded,
                                                label: 'Chat',
                                                onTap: _openChat,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      /// Main action button (Reached/Delivered)
                                      _buildMainActionButton(colorScheme),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build step indicators at top of screen
  Widget _buildStepIndicators(AppColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(widget.totalSteps, (index) {
          final isCompleted = index < widget.currentStepIndex;
          final isCurrent = index == widget.currentStepIndex;
          final isLast = index == widget.totalSteps - 1;

          return Row(
            children: [
              /// Step circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? colorScheme.primary
                      : colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? colorScheme.border
                        : colorScheme.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isLast
                      ? Icon(
                          Icons.home_rounded,
                          color: isCompleted || isCurrent
                              ? colorScheme.surface
                              : colorScheme.textSecondary,
                          size: 18,
                        )
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCompleted || isCurrent
                                ? colorScheme.surface
                                : colorScheme.textSecondary,
                          ),
                        ),
                ),
              ),

              /// Connecting line
              if (!isLast)
                Container(
                  width: 24,
                  height: 2,
                  color: isCompleted
                      ? colorScheme.textPrimary
                      : colorScheme.border,
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Build call/chat action button
  Widget _buildActionButton({
    required AppColorScheme colorScheme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colorScheme.textPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build navigation info card with distance, ETA, and direction
  Widget _buildNavigationInfoCard(AppColorScheme colorScheme) {
    // Format distance
    String distanceText;
    if (_distanceToDestination < 1000) {
      distanceText = '${_distanceToDestination.toStringAsFixed(0)} m';
    } else {
      distanceText = '${(_distanceToDestination / 1000).toStringAsFixed(1)} km';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          /// Direction icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getDirectionIcon(),
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          /// Direction and distance info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _navigationDirection,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.stepType == DeliveryStepType.pickup
                      ? 'to ${widget.seller?.storeName ?? "Store"}'
                      : 'to ${widget.order.customer.displayName}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          /// Distance and ETA
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                distanceText,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _estimatedTime,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get direction icon based on navigation direction
  IconData _getDirectionIcon() {
    if (_navigationDirection.contains('North')) {
      if (_navigationDirection.contains('east')) {
        return Icons.north_east;
      } else if (_navigationDirection.contains('west')) {
        return Icons.north_west;
      }
      return Icons.north;
    } else if (_navigationDirection.contains('South')) {
      if (_navigationDirection.contains('east')) {
        return Icons.south_east;
      } else if (_navigationDirection.contains('west')) {
        return Icons.south_west;
      }
      return Icons.south;
    } else if (_navigationDirection.contains('East')) {
      return Icons.east;
    } else if (_navigationDirection.contains('West')) {
      return Icons.west;
    }
    return Icons.navigation;
  }

  /// Build main action button with swipe-to-confirm interaction
  Widget _buildMainActionButton(AppColorScheme colorScheme) {
    final maxDrag = MediaQuery.of(context).size.width - 120;
    final threshold = maxDrag * 0.85;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.cardBorder,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          /// Center text
          Center(
            child: _isActionProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  )
                : _isActionConfirmed
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Confirmed!',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : Padding(
                      padding: const EdgeInsets.only(left: 50),
                      child: Text(
                          widget.stepType == DeliveryStepType.pickup
                              ? 'Reached to Pickup location →'
                              : 'Reached to customer location →',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textPrimary.withValues(alpha: 0.9),
                            letterSpacing: 0.2,
                          ),
                        ),
                    ),
          ),

          /// Draggable slider
          if (!_isActionProcessing)
            Positioned(
              left: _dragPosition,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!_isActionConfirmed) {
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxDrag);
                    });
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (!_isActionConfirmed) {
                    if (_dragPosition >= threshold) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isActionConfirmed = true;
                        _isActionProcessing = true;
                      });
                      _handleActionConfirm();
                    } else {
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 4.0,
                  ),
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _swipeHintAnim,
                        builder: (context, child) {
                          final isIdle = !_isActionConfirmed && _dragPosition == 0.0;
                          return Transform.translate(
                            offset: Offset(isIdle ? _swipeHintAnim.value : 0, 0),
                            child: Icon(
                              _isActionConfirmed
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Handle action confirmation - open delivery confirmation screen with PIN verification
  /// Notifies the customer that the partner has arrived. The backend includes
  /// the delivery OTP in the push notification so the customer can hand it over.
  /// Best-effort: failures are logged but never interrupt the delivery flow.
  Future<void> _notifyCustomerArrival() async {
    try {
      final data = <String, dynamic>{
        'order_id': widget.order.orderId,
      };
      if (_currentDriverLocation != null) {
        data['latitude'] = _currentDriverLocation!.latitude;
        data['longitude'] = _currentDriverLocation!.longitude;
      }

      await ApiService().post(
        AppUrl.notifyArrival,
        data: data,
        isToast: false,
      );
      debugPrint('📨 Customer arrival notification (with OTP) requested');
    } catch (e) {
      debugPrint('⚠️ Failed to notify customer arrival: $e');
    }
  }

  /// Confirm the handover at an emergency-change handoff stop, then complete the
  /// step. No API call: the items were already marked picked by the previous
  /// driver, so there is nothing left to mark against a seller.
  Future<void> _handleHandoffCollected() async {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    final driverName = widget.seller?.storeName ?? 'the previous driver';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded,
                  size: 56, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Items collected?',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirm you have taken the items from $driverName.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colorScheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Not yet',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Collected',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    // Reset the swipe button either way - the step only advances on confirm.
    setState(() {
      _dragPosition = 0.0;
      _isActionConfirmed = false;
      _isActionProcessing = false;
    });

    if (confirmed != true) {
      debugPrint('↩️ Handoff not confirmed - staying on the stop');
      return;
    }

    debugPrint('🤝 Handoff collected from $driverName - completing step');
    widget.onActionComplete();
    Navigator.pop(context);
  }

  Future<void> _handleActionConfirm() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      // Log parameters being passed to DeliveryConfirmationScreen
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint(
          '📤 Opening DeliveryConfirmationScreen from DeliveryDetailScreen');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📋 Parameters to Pass:');
      debugPrint(
          '  • confirmationType: ${widget.stepType == DeliveryStepType.pickup ? "pickup" : "delivery"}');
      debugPrint('  • order.orderId: ${widget.order.orderId}');
      if (widget.stepType == DeliveryStepType.pickup && widget.seller != null) {
        debugPrint('  • sellerName: ${widget.seller!.storeName}');
        debugPrint('  • sellerId: ${widget.seller!.sellerId}');
        debugPrint('  • storeId: ${widget.seller!.storeId}');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      // Stop navigation when reached
      setState(() {
        _isNavigationActive = false;
      });
      debugPrint('🛑 Navigation stopped - partner has reached destination');

      // The handoff stop of an emergency driver change has no seller behind it:
      // seller-details and mark-picked both key on a real seller_id, and those
      // items were already marked picked by the previous driver. Confirm the
      // handover here and advance the step instead.
      if (widget.stepType == DeliveryStepType.pickup &&
          widget.seller?.isHandoffPoint == true) {
        await _handleHandoffCollected();
        return;
      }

      // Update Firebase with reached status
      final authProvider = context.read<AuthProvider>();
      final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

      if (deliveryBoyId != null) {
        final sellerName = widget.stepType == DeliveryStepType.pickup
            ? (widget.seller?.storeName ?? 'Seller')
            : 'customer location';

        await _firebaseOrderService.updateOrderStatusReached(
          orderId: widget.order.orderId,
          deliveryBoyId: deliveryBoyId,
          type: widget.stepType == DeliveryStepType.pickup
              ? 'reached_pickup'
              : 'reached_delivery',
          sellerName: sellerName,
        );

        // When the partner reaches the CUSTOMER, notify the customer (the backend
        // includes the delivery OTP in that push). Fire-and-forget so it never
        // blocks opening the delivery confirmation screen.
        if (widget.stepType == DeliveryStepType.delivery) {
          _notifyCustomerArrival();
        }
      }

      // Open delivery confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryConfirmationScreen(
            order: widget.order,
            confirmationType: widget.stepType == DeliveryStepType.pickup
                ? DeliveryConfirmationType.pickup
                : DeliveryConfirmationType.delivery,
            sellerName: widget.seller?.storeName,
            customerName: widget.order.customer.displayName,
            sellerId: widget.seller?.sellerId,
            storeId: widget.seller?.storeId,
            seller: widget.seller,
            onConfirmationSuccess: () {
              // Complete the current step after successful PIN verification
              widget.onActionComplete();
              // Pop back to delivery progress screen
              // The parent screen will automatically scroll to the next step via _scrollToCurrentStep()
              Navigator.pop(context);
            },
          ),
        ),
      ).then((_) {
        // Reset swipe button state when returning from confirmation screen
        if (mounted) {
          setState(() {
            _dragPosition = 0.0;
            _isActionConfirmed = false;
            _isActionProcessing = false;
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Error confirming action: $e');
      if (mounted) {
        setState(() {
          _dragPosition = 0.0;
          _isActionConfirmed = false;
          _isActionProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _compassSubscription?.cancel(); // Cancel compass
    _orderSubscription?.cancel(); // Cancel order listener
    _fitMarkersTimer?.cancel(); // Cancel marker fitting timer

    // Clean up animation listener
    if (_animationListener != null) {
      _markerAnimation.removeListener(_animationListener!);
    }
    _markerAnimationController.dispose(); // Dispose animation controller
    _swipeHintController.dispose(); // Dispose swipe hint animation

    // Clean up bottom sheet controller and notifiers
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    _sheetExpandedNotifier.dispose();
    _sheetSizeNotifier.dispose();

    super.dispose();
  }
}
