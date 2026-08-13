import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:provider/provider.dart';

class TurnByTurnNavigationScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;
  final double initialLat;
  final double initialLng;
  final VoidCallback? onExit;
  // Seller destination marker details
  final String? sellerStoreName;
  final String? sellerAddress;
  // Kept for API compatibility
  final dynamic markers;
  final dynamic polylines;
  // Bottom sheet state tracking
  final ValueNotifier<bool>? isSheetExpanded;
  final ValueNotifier<double>? sheetSize; // Track sheet size (0.0 to 1.0)

  const TurnByTurnNavigationScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    required this.initialLat,
    required this.initialLng,
    this.onExit,
    this.sellerStoreName,
    this.sellerAddress,
    this.markers,
    this.polylines,
    this.isSheetExpanded,
    this.sheetSize,
  });

  @override
  State<TurnByTurnNavigationScreen> createState() =>
      _TurnByTurnNavigationScreenState();
}

class _TurnByTurnNavigationScreenState
    extends State<TurnByTurnNavigationScreen> {
  bool _navigationSessionInitialized = false;
  GoogleNavigationViewController? _navigationController;
  double _currentZoomLevel = 17.0; // Default zoom level
  DateTime _lastZoomUpdate = DateTime.now();

  /// Set when the device cannot provide a location fix to the Navigation SDK.
  /// While non-null the screen shows a recoverable error instead of the map.
  String? _locationError;
  bool _openAppSettingsOnRetry = false;

  @override
  void initState() {
    super.initState();
    _initializeNavigationSession();
    _startSpeedMonitoring();
  }

  /// The Navigation SDK never asks for location itself — if GPS is off, the
  /// permission is missing, or it is granted as "Approximate" only, every
  /// setDestinations() call comes back as locationUnavailable. Gate the whole
  /// session on a real fix before touching the SDK.
  Future<bool> _ensureLocationReady() async {
    debugPrint('📍 [PRE-FLIGHT CHECK] Verifying location availability...');

    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('❌ [PRE-FLIGHT CHECK] Location services (GPS) are turned off');
      _setLocationError(
        'Location is turned off. Please switch on GPS to start navigation.',
        openAppSettings: false,
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    debugPrint('📍 [PRE-FLIGHT CHECK] Permission status: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('📍 [PRE-FLIGHT CHECK] Permission after request: $permission');
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setLocationError(
        'Zenfoo Partner needs location access to navigate. Please allow '
        'location permission.',
        openAppSettings: permission == LocationPermission.deniedForever,
      );
      return false;
    }

    // Android 12+ / iOS 14+ can grant "Approximate" location, which the
    // Navigation SDK rejects — it needs precise (fine) location.
    try {
      final accuracy = await Geolocator.getLocationAccuracy();
      debugPrint('📍 [PRE-FLIGHT CHECK] Location accuracy: $accuracy');
      if (accuracy == LocationAccuracyStatus.reduced) {
        _setLocationError(
          'Precise location is off. Please enable "Precise"/"Exact" location '
          'for Zenfoo Partner to navigate.',
          openAppSettings: true,
        );
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ [PRE-FLIGHT CHECK] Could not read location accuracy: $e');
    }

    // Warm up an actual fix. A cold GPS start takes several seconds and the
    // SDK reports locationUnavailable until the first fix lands.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );
      debugPrint(
          '✅ [PRE-FLIGHT CHECK] Location fix acquired: ${position.latitude}, ${position.longitude} (±${position.accuracy.toStringAsFixed(1)}m)');
      return true;
    } catch (e) {
      debugPrint('⚠️ [PRE-FLIGHT CHECK] No fresh fix yet: $e');
      // Fall back to a cached fix — the SDK can start from it and refine later.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        debugPrint(
            '✅ [PRE-FLIGHT CHECK] Using last known location: ${lastKnown.latitude}, ${lastKnown.longitude}');
        return true;
      }
      _setLocationError(
        'Could not get your location. Move to an open area and try again.',
        openAppSettings: false,
      );
      return false;
    }
  }

  void _setLocationError(String message, {required bool openAppSettings}) {
    debugPrint('❌ [LOCATION] $message');
    if (mounted) {
      setState(() {
        _locationError = message;
        _openAppSettingsOnRetry = openAppSettings;
      });
    }
  }

  Future<void> _retryAfterLocationError() async {
    if (_openAppSettingsOnRetry) {
      await Geolocator.openAppSettings();
    } else {
      // GPS-off errors are fixed in system settings, not app settings.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }
    }
    if (!mounted) return;
    setState(() {
      _locationError = null;
      _navigationSessionInitialized = false;
    });
    await _initializeNavigationSession();
  }

  Future<void> _initializeNavigationSession() async {
    try {
      debugPrint(
          '🔧 [PRE-FLIGHT CHECK] Starting Navigation SDK initialization...');

      // Location must be usable before the SDK is initialized, otherwise route
      // calculation fails with locationUnavailable and never recovers.
      if (!await _ensureLocationReady()) {
        return;
      }

      // Check if terms are accepted
      bool termsAccepted = false;
      try {
        termsAccepted = await GoogleMapsNavigator.areTermsAccepted();
        debugPrint('✅ [PRE-FLIGHT CHECK] Terms acceptance: $termsAccepted');
      } catch (e) {
        debugPrint(
            '⚠️ [PRE-FLIGHT CHECK] Could not check terms acceptance: $e');
        termsAccepted = true;
      }

      if (!termsAccepted) {
        if (mounted) {
          try {
            debugPrint(
                '📋 [PRE-FLIGHT CHECK] Showing terms and conditions dialog...');
            await GoogleMapsNavigator.showTermsAndConditionsDialog(
              'Navigation',
              'Zenfoo Partner',
            );
            debugPrint('✅ [PRE-FLIGHT CHECK] User accepted terms');
          } catch (e) {
            debugPrint('⚠️ [PRE-FLIGHT CHECK] Could not show terms dialog: $e');
          }
        }
      }

      // Initialize navigation session
      try {
        debugPrint('⚙️ [PRE-FLIGHT CHECK] Initializing navigation session...');
        await GoogleMapsNavigator.initializeNavigationSession(
          taskRemovedBehavior: TaskRemovedBehavior.continueService,
        );
        debugPrint(
            '✅ [PRE-FLIGHT CHECK] Navigation session initialized successfully');

        // Mute audio guidance
        try {
          await GoogleMapsNavigator.setAudioGuidance(
            NavigationAudioGuidanceSettings(
              isBluetoothAudioEnabled: false,
              isVibrationEnabled: true,
              guidanceType: NavigationAudioGuidanceType.silent,
            ),
          );
          debugPrint('🔇 [PRE-FLIGHT CHECK] Audio guidance muted');
        } catch (e) {
          debugPrint('⚠️ [PRE-FLIGHT CHECK] Could not mute audio guidance: $e');
        }
      } catch (e) {
        debugPrint(
            '❌ [PRE-FLIGHT CHECK] Could not initialize navigation session: $e');
        debugPrint('⚠️ [PRE-FLIGHT CHECK] This error may indicate:');
        debugPrint('   1. API key not configured in AndroidManifest.xml');
        debugPrint('   2. Navigation SDK not enabled in Google Cloud project');
        debugPrint('   3. Billing not enabled on Google Cloud project');
        debugPrint(
            '   4. API key restrictions preventing Navigation SDK access');
      }

      if (mounted) {
        setState(() {
          _navigationSessionInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing navigation: $e');
      if (mounted) {
        _endNavigation();
      }
    }
  }

  Future<void> _onViewCreated(GoogleNavigationViewController controller) async {
    try {
      // Store controller for recenter functionality
      _navigationController = controller;

      debugPrint('📱 GoogleMapsNavigationView created, setting up navigation');
      debugPrint(
          '🎯 Destination: ${widget.destinationName} (${widget.destinationLat}, ${widget.destinationLng})');
      debugPrint(
          '📍 Start Location: (${widget.initialLat}, ${widget.initialLng})');

      // Enable my location
      await controller.setMyLocationEnabled(true);
      debugPrint('✅ My location enabled');

      // Wait a moment for location to be available
      await Future.delayed(const Duration(milliseconds: 500));

      // Apply map styling based on theme
      final isDarkMode = context.read<ThemeProvider>().isDarkMode;
      try {
        final mapStyle = await _loadMapStyle(isDarkMode);
        await controller.setMapStyle(mapStyle);
        debugPrint('✅ Map style applied');
      } catch (e) {
        debugPrint('⚠️ Could not apply map style: $e');
      }

      // Set destination (destination marker will be shown via NavigationWaypoint)
      final waypointTitle = widget.sellerStoreName ?? widget.destinationName;
      final waypoint = NavigationWaypoint(
        title: waypointTitle,
        target: LatLng(
          latitude: widget.destinationLat,
          longitude: widget.destinationLng,
        ),
      );

      debugPrint(
          '🏪 Destination Marker: $waypointTitle (${widget.destinationLat}, ${widget.destinationLng})');
      if (widget.sellerAddress != null) {
        debugPrint('📍 Address: ${widget.sellerAddress}');
      }

      // Create Destinations object with waypoint markers visible
      final destinations = Destinations(
        waypoints: [waypoint],
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
          alternateRoutesStrategy: NavigationAlternateRoutesStrategy.all,
          routingStrategy: NavigationRoutingStrategy.defaultBest,
        ),
        displayOptions: NavigationDisplayOptions(
          showDestinationMarkers: true, // Display waypoint markers on map
          showStopSigns: true,
          showTrafficLights: true,
        ),
      );

      // Set the destinations and start navigation with retry logic
      try {
        debugPrint(
            '🧭 Setting navigation destination: ${widget.destinationName}');

        int retryCount = 0;
        const maxRetries = 3;
        NavigationRouteStatus? status;

        while (retryCount < maxRetries) {
          try {
            status = await GoogleMapsNavigator.setDestinations(destinations);

            if (status == NavigationRouteStatus.statusOk) {
              debugPrint('✅ Route calculated successfully');
              // Start navigation automatically
              try {
                await GoogleMapsNavigator.startGuidance();
                debugPrint('✅ Navigation guidance started');
              } catch (e) {
                debugPrint('⚠️ Could not start guidance: $e');
              }
              break; // Exit retry loop on success
            } else if (status == NavigationRouteStatus.networkError) {
              retryCount++;
              if (retryCount < maxRetries) {
                debugPrint(
                    '⚠️ Network error, retrying... (Attempt $retryCount/$maxRetries)');
                await Future.delayed(
                    Duration(seconds: 2 * retryCount)); // Progressive backoff
              } else {
                debugPrint(
                    '❌ Network error after $maxRetries attempts: $status');
                debugPrint('❌ NETWORK ERROR DIAGNOSIS:');
                debugPrint('   • Check device has working internet connection');
                debugPrint('   • Verify Google Cloud Console:');
                debugPrint('     - APIs & Services > Enabled APIs');
                debugPrint('     - Enable "Navigation SDK for Android"');
                debugPrint('     - Enable "Navigation SDK for iOS"');
                debugPrint('   • Check Billing:');
                debugPrint('     - Billing > Overview > Account is active');
                debugPrint('   • Check API Key:');
                debugPrint('     - APIs & Services > Credentials');
                debugPrint('     - Key restrictions include Navigation SDK');
                debugPrint('   • Check AndroidManifest.xml:');
                debugPrint(
                    '     - <meta-data android:name="com.google.android.geo.API_KEY" ...');
              }
            } else if (status == NavigationRouteStatus.locationUnavailable) {
              retryCount++;
              if (retryCount < maxRetries) {
                debugPrint(
                    '⚠️ Location not available, waiting for a GPS fix... (Attempt $retryCount/$maxRetries)');
                // Don't just sleep — actively wait for the device to produce a
                // fix, which is what the SDK is missing.
                try {
                  await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(
                      accuracy: LocationAccuracy.high,
                      timeLimit: Duration(seconds: 10),
                    ),
                  );
                } catch (_) {
                  await Future.delayed(Duration(seconds: 2 * retryCount));
                }
              } else {
                debugPrint('❌ Location unavailable after $maxRetries attempts');
                _setLocationError(
                  'Could not get your location to start navigation. Check that '
                  'GPS is on and you have a clear signal, then try again.',
                  openAppSettings: false,
                );
              }
            } else {
              debugPrint('❌ Route error: $status');
              break;
            }
          } catch (e) {
            retryCount++;
            if (retryCount < maxRetries) {
              debugPrint(
                  '⚠️ Exception during navigation setup, retrying... (Attempt $retryCount/$maxRetries): $e');
              await Future.delayed(Duration(seconds: 2 * retryCount));
            } else {
              debugPrint(
                  '❌ Failed to set destinations after $maxRetries attempts: $e');
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error setting destinations: $e');
      }
    } catch (e) {
      debugPrint('❌ Error setting up navigation: $e');
    }
  }

  /// Start monitoring speed and adjust zoom accordingly
  void _startSpeedMonitoring() {
    debugPrint('📡 [SPEED-BASED ZOOM] Speed monitoring initialized');

    // Listen to speed changes from SessionProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final sessionProvider =
              Provider.of<SessionProvider>(context, listen: false);

          // Schedule periodic speed checks
          _speedMonitoringTimer = Timer.periodic(
            const Duration(milliseconds: 500),
            (timer) {
              if (mounted) {
                final currentSpeed = sessionProvider.currentSpeedMs;
                _updateZoomForSpeed(currentSpeed);
              }
            },
          );

          debugPrint('✅ Speed monitoring listener attached to SessionProvider');
        } catch (e) {
          debugPrint('⚠️ Could not attach speed monitoring: $e');
        }
      }
    });
  }

  Timer? _speedMonitoringTimer;

  /// Update zoom based on current speed
  /// Call this method when you have access to current speed value
  Future<void> _updateZoomForSpeed(double speedMps) async {
    try {
      // Convert m/s to km/h for logging (1 m/s = 3.6 km/h)
      final speedKmh = speedMps * 3.6;

      // Throttle zoom updates to avoid excessive changes (max 1 update per 500ms)
      final now = DateTime.now();
      if (now.difference(_lastZoomUpdate).inMilliseconds < 500) {
        return;
      }

      // Calculate zoom level based on speed
      // Speed zones:
      // 0-5 km/h (0-1.39 m/s): Very slow, zoom to 19 (close-up for detailed directions)
      // 5-15 km/h (1.39-4.17 m/s): Slow, zoom to 18
      // 15-30 km/h (4.17-8.33 m/s): Normal, zoom to 17
      // 30-50 km/h (8.33-13.89 m/s): Fast, zoom to 16
      // 50+ km/h (13.89+ m/s): Very fast, zoom to 15

      double newZoomLevel = 17.0; // Default

      if (speedMps < 1.39) {
        newZoomLevel = 19.0; // Very close-up for detailed instructions
      } else if (speedMps < 4.17) {
        newZoomLevel = 18.0; // Close-up view
      } else if (speedMps < 8.33) {
        newZoomLevel = 17.0; // Normal street-level view
      } else if (speedMps < 13.89) {
        newZoomLevel = 16.0; // Wider view for faster navigation
      } else {
        newZoomLevel = 15.0; // Very wide view for highway speeds
      }

      // Only update if zoom level changed significantly (> 0.5 zoom difference)
      if ((newZoomLevel - _currentZoomLevel).abs() > 0.5) {
        _currentZoomLevel = newZoomLevel;
        await _applyMapZoom(newZoomLevel);

        debugPrint(
            '🎯 [SPEED-BASED ZOOM] Speed: ${speedKmh.toStringAsFixed(1)} km/h | Zoom: ${newZoomLevel.toStringAsFixed(1)}');
      }

      _lastZoomUpdate = now;
    } catch (e) {
      debugPrint('⚠️ Error updating zoom for speed: $e');
    }
  }

  /// Apply map zoom level smoothly by following current location
  Future<void> _applyMapZoom(double zoomLevel) async {
    if (_navigationController != null) {
      try {
        // Use followMyLocation with the new zoom level to smoothly update
        await _navigationController!.followMyLocation(
          CameraPerspective.tilted,
          zoomLevel: zoomLevel,
        );
        debugPrint('✅ Map zoom updated to $zoomLevel');
      } catch (e) {
        debugPrint('⚠️ Error updating map zoom: $e');
      }
    }
  }

  /// Recenter the map to follow the user's current location
  Future<void> _recenterMap() async {
    if (_navigationController != null) {
      try {
        await _navigationController!.followMyLocation(
          CameraPerspective.tilted,
          zoomLevel: _currentZoomLevel, // Use dynamic zoom level
        );
        debugPrint(
            '✅ Map recentered to current location with zoom level $_currentZoomLevel');
      } catch (e) {
        debugPrint('⚠️ Error recentering map: $e');
      }
    }
  }

  /// Load map style from assets based on theme
  Future<String> _loadMapStyle(bool isDarkMode) async {
    try {
      final themePath = isDarkMode
          ? 'assets/mapTheme/nightMode.json'
          : 'assets/mapTheme/dayMode.json';

      final styleString = await rootBundle.loadString(themePath);
      debugPrint('✅ Loaded map theme from $themePath');
      return styleString;
    } catch (e) {
      debugPrint('⚠️ Failed to load map theme: $e');
      // Return empty string (default style) as fallback
      return '';
    }
  }

  void _endNavigation() {
    widget.onExit?.call();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _speedMonitoringTimer?.cancel();
    if (_navigationSessionInitialized) {
      try {
        GoogleMapsNavigator.cleanup();
      } catch (e) {
        debugPrint('⚠️ Error during cleanup: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    if (_locationError != null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _locationError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _retryAfterLocationError,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    _openAppSettingsOnRetry ? 'Open Settings' : 'Try Again',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _endNavigation,
                  child: Text(
                    'Exit Navigation',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_navigationSessionInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Initializing Navigation...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          // Google Navigation View with theme-aware styling
          GoogleMapsNavigationView(
            onViewCreated: _onViewCreated,
            initialPadding: const EdgeInsets.only(bottom: 60, top: 10),
            initialNavigationUIEnabledPreference:
                NavigationUIEnabledPreference.automatic,
          ),

          // // Recenter button - moves with bottom sheet and uses app theme
          // ValueListenableBuilder<double>(
          //   valueListenable: widget.sheetSize ?? ValueNotifier(0.3),
          //   builder: (context, sheetSize, _) {
          //     // Calculate button position based on sheet size
          //     // Sheet size ranges from 0.3 to 1.0
          //     // As sheet expands (size increases), button should move UP
          //     // To move UP, we need to INCREASE the bottom value (further from bottom)
          //     //
          //     // Base position when collapsed: 100
          //     // As sheet expands, add more bottom padding to push button up
          //     // At 0.3 (collapsed): 100 + (0.3 * 200) = 160
          //     // At 0.5 (halfway): 100 + (0.5 * 200) = 200
          //     // At 0.8 (nearly full): button hides

          //     final bottomPosition = 150.0 + (sheetSize * 500);

          //     // Hide button when sheet is too expanded (>80% of screen)
          //     if (sheetSize > 0.8) {
          //       return const SizedBox.shrink();
          //     }

          //     return Positioned(
          //       right: 16,
          //       bottom: bottomPosition, // Moves based on sheet size
          //       child: FloatingActionButton(
          //         heroTag: 'recenterBtn',
          //         onPressed: _recenterMap,
          //         backgroundColor:
          //             isDarkMode ? colorScheme.surfaceElevated : Colors.white,
          //         elevation: 4,
          //         child: Icon(
          //           Icons.my_location,
          //           color: colorScheme.primary,
          //           size: 24,
          //         ),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }
}
