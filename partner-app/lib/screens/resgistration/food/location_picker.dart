import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project/models/places_model.dart';
import 'package:project/provider/place_proveder.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPoint;
  final ScrollController? scrollController;

  const LocationPickerScreen({
    Key? key,
    this.initialPoint,
    this.scrollController,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  LatLng? currentPoint;
  String selectedAddress = "";
  CameraPosition? cameraPosition;
  GoogleMapController? mapController;
  bool addressLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _lastQuery = "";
  bool _isMapMoving = false;
  late AnimationController _markerAnimationController;
  late Animation<double> _markerAnimation;
  String? _mapStyle;

  String? _pickedCity, _pickedState, _pickedCountry, _pickedPincode;

  @override
  void initState() {
    super.initState();

    // Initialize marker animation
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _markerAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _markerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Load map style
    _loadMapStyle();

    // Get current location or use default
    if (widget.initialPoint != null) {
      currentPoint = widget.initialPoint!;
      cameraPosition = CameraPosition(target: widget.initialPoint!, zoom: 16);
      _fetchAddress(widget.initialPoint!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _loadMapStyle() async {
    if (Constant.googleApiKey.isEmpty) {
      await context
          .read<SettingsProvider>()
          .getSettingsApiProvider({}, context);
    }
    try {
      final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
      final isDark = colorScheme == app_theme.AppColorScheme.dark;
      final themeFile = isDark
          ? 'assets/mapTheme/nightMode.json'
          : 'assets/mapTheme/dayMode.json';
      final style = await rootBundle.loadString(themeFile);
      if (mounted) {
        setState(() {
          _mapStyle = style;
        });
      }
    } catch (e) {
      debugPrint('Failed to load map theme: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => addressLoading = true);
    try {
      // Request location permission
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final newPoint = LatLng(position.latitude, position.longitude);
        currentPoint = newPoint;
        cameraPosition = CameraPosition(target: newPoint, zoom: 16);

        // Move camera to current location if map is already created
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: newPoint, zoom: 16),
            ),
          );
        }

        _fetchAddress(newPoint);
      } else {
        // Use default location if permission denied
        const defaultPoint = LatLng(17.4435, 78.3772);
        currentPoint = defaultPoint;
        cameraPosition = CameraPosition(target: defaultPoint, zoom: 16);
        _fetchAddress(defaultPoint);
      }
    } catch (e) {
      // Use default location on error
      const defaultPoint = LatLng(17.4435, 78.3772);
      currentPoint = defaultPoint;
      cameraPosition = CameraPosition(target: defaultPoint, zoom: 16);
      _fetchAddress(defaultPoint);
    }
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAddress(LatLng pos) async {
    if (!mounted) return;
    setState(() => addressLoading = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      final pm = placemarks.first;

      // Build address parts list, filtering out empty/null values
      final addressParts = <String>[];

      // Combine subThoroughfare and thoroughfare (street address)
      final streetParts = [
        pm.subThoroughfare,
        pm.thoroughfare,
      ].where((part) => part != null && part.isNotEmpty).join(' ');
      if (streetParts.isNotEmpty) addressParts.add(streetParts);

      // Add other address components
      if (pm.subLocality != null && pm.subLocality!.isNotEmpty) {
        addressParts.add(pm.subLocality!);
      }
      if (pm.locality != null && pm.locality!.isNotEmpty) {
        addressParts.add(pm.locality!);
      }
      if (pm.postalCode != null && pm.postalCode!.isNotEmpty) {
        addressParts.add(pm.postalCode!);
      }
      if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty) {
        addressParts.add(pm.administrativeArea!);
      }
      if (pm.country != null && pm.country!.isNotEmpty) {
        addressParts.add(pm.country!);
      }

      setState(() {
        selectedAddress = addressParts.join(', ');
        _pickedPincode = pm.postalCode ?? "";
        _pickedCity = pm.locality ?? "";
        _pickedState = pm.administrativeArea ?? "";
        _pickedCountry = pm.country ?? "";
        addressLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        selectedAddress = "Unable to fetch address";
        _pickedPincode = "";
        _pickedCity = "";
        _pickedState = "";
        _pickedCountry = "";
        addressLoading = false;
      });
    }
  }

  void _onMapMoved(CameraPosition position) {
    currentPoint = position.target;
    if (!_isMapMoving) {
      setState(() => _isMapMoving = true);
      _markerAnimationController.forward();
    }
  }

  void _onMapIdle() {
    if (_isMapMoving) {
      setState(() => _isMapMoving = false);
      _markerAnimationController.reverse();
    }
    if (currentPoint != null) {
      _fetchAddress(currentPoint!);
    }
  }

  void _onSearchChanged(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      input = input.trim();
      if (input.length < 3 || input == _lastQuery) return;
      _lastQuery = input;
      context.read<PlaceSuggestionsProvider>().fetchSuggestions(
            input: input,
          );
    });
  }

  Future<void> _selectPrediction(Suggestions suggestion) async {
    final detailsProvider = context.read<PlaceDetailsProvider>();
    await detailsProvider.fetchPlaceDetails(
      placeId: suggestion.placePrediction?.placeId ?? "",
    );
    final details = detailsProvider.placeDetails;
    final lat = double.tryParse(details?.latitude.toString() ?? "") ?? 0;
    final lng = double.tryParse(details?.longitude.toString() ?? "") ?? 0;
    if (lat != 0 && lng != 0) {
      final target = LatLng(lat, lng);
      mapController?.animateCamera(CameraUpdate.newLatLng(target));
      setState(() {
        currentPoint = target;
        _searchController.clear();
      });
      _fetchAddress(target);
    }
    context.read<PlaceSuggestionsProvider>().clearSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final suggestionsProvider = context.watch<PlaceSuggestionsProvider>();
    final suggestions = suggestionsProvider.suggestions;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: // ====== AppHeader ======
            AppHeader(
          label: 'Pick Location',
          title: 'Select on Map',
          showBackButton: true,
          onBackPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // ====== Rest of content in scrollable area ======
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ====== Search bar + suggestions ======
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.border, width: 1),
                        boxShadow: colorScheme.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: colorScheme.iconSecondary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear_rounded,
                                          color: colorScheme.iconSecondary,
                                          size: 20),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _searchController.clear();
                                          _lastQuery = "";
                                        });
                                        context
                                            .read<PlaceSuggestionsProvider>()
                                            .clearSuggestions();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              hintText: "Search for area, street name...",
                              hintStyle: GoogleFonts.inter(
                                fontSize: 15,
                                color: colorScheme.textTertiary,
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onChanged: (value) {
                              setState(() {});
                              _onSearchChanged(value);
                            },
                          ),
                          if (suggestionsProvider.state ==
                              PlaceSuggestionsState.loading)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            )
                          else if (suggestions.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: colorScheme.divider, width: 1),
                                ),
                              ),
                              constraints:
                                  BoxConstraints(maxHeight: size.height * 0.3),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: suggestions.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: colorScheme.divider,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                itemBuilder: (ctx, i) {
                                  final suggestion = suggestions[i];
                                  // Use the new fields directly
                                  String displayText = "";
                                  if (suggestion.placePrediction?.mainText !=
                                          null &&
                                      suggestion.placePrediction!.mainText!
                                          .isNotEmpty) {
                                    displayText =
                                        suggestion.placePrediction!.mainText!;
                                    if (suggestion.placePrediction
                                                ?.secondaryText !=
                                            null &&
                                        suggestion.placePrediction!
                                            .secondaryText!.isNotEmpty) {
                                      displayText +=
                                          ", ${suggestion.placePrediction!.secondaryText!}";
                                    }
                                  } else {
                                    displayText = suggestion
                                            .placePrediction?.description ??
                                        "Unknown location";
                                  }

                                  return InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      _selectPrediction(suggestion);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on_rounded,
                                              color: colorScheme.iconSecondary,
                                              size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              displayText,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: colorScheme.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (suggestionsProvider.state ==
                              PlaceSuggestionsState.error)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: colorScheme.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      suggestionsProvider.errorMessage,
                                      style: GoogleFonts.inter(
                                        color: colorScheme.error,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ====== Map section - Fixed height, no scroll interference ======
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        // Block scroll notifications from propagating to parent
                        return true;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: colorScheme.border, width: 1),
                          boxShadow: colorScheme.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: size.height * 0.4,
                            child: cameraPosition == null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "Loading map...",
                                          style: GoogleFonts.inter(
                                            color: colorScheme.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GoogleMap(
                                        initialCameraPosition: cameraPosition!,
                                        fortyFiveDegreeImageryEnabled: true,
                                        style: _mapStyle,
                                        onMapCreated: (ctrl) {
                                          mapController = ctrl;
                                          // Ensure zoom is set after map creation
                                          if (cameraPosition != null) {
                                            mapController!.animateCamera(
                                              CameraUpdate.newCameraPosition(
                                                CameraPosition(
                                                  target:
                                                      cameraPosition!.target,
                                                  zoom: 16,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        onCameraMove: _onMapMoved,
                                        onCameraIdle: _onMapIdle,
                                        myLocationEnabled: true,
                                        myLocationButtonEnabled: false,
                                        zoomGesturesEnabled: true,
                                        zoomControlsEnabled: false,
                                        minMaxZoomPreference:
                                            const MinMaxZoomPreference(
                                          10,
                                          20,
                                        ),
                                      ),
                                      // Custom Animated Marker - Compact Design
                                      IgnorePointer(
                                        ignoring: true,
                                        child: AnimatedBuilder(
                                          animation: _markerAnimation,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(
                                                  0, -_markerAnimation.value),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Compact Pin
                                                  Container(
                                                    width: 40,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          colorScheme.primary,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .only(
                                                        topLeft:
                                                            Radius.circular(20),
                                                        topRight:
                                                            Radius.circular(20),
                                                        bottomLeft:
                                                            Radius.circular(20),
                                                        bottomRight:
                                                            Radius.circular(3),
                                                      ),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 3,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: colorScheme
                                                              .primary
                                                              .withValues(
                                                                  alpha: 0.4),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 3),
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.location_on,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                  // Shadow circle at bottom
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    width:
                                                        _isMapMoving ? 24 : 16,
                                                    height:
                                                        _isMapMoving ? 6 : 4,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.25),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              50),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // My Location Button
                                      Positioned(
                                        bottom: 16,
                                        right: 16,
                                        child: GestureDetector(
                                          onTap: () async {
                                            HapticFeedback.lightImpact();
                                            _getCurrentLocation();
                                          },
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: colorScheme.border,
                                                  width: 1),
                                              boxShadow: colorScheme.cardShadow,
                                            ),
                                            child: Icon(
                                                Icons.my_location_rounded,
                                                color: colorScheme.primary,
                                                size: 22),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ====== Selected address card ======
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.border, width: 1),
                        boxShadow: colorScheme.cardShadow,
                      ),
                      child: addressLoading
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Fetching address...",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: colorScheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        color: colorScheme.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Selected Address",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: colorScheme.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  selectedAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: colorScheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ====== Confirm button + bottom padding ======
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: currentPoint == null
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                Navigator.pop(
                                  context,
                                  PlaceDetailsModel(
                                    formattedAddress: selectedAddress,
                                    latitude: currentPoint!.latitude,
                                    longitude: currentPoint!.longitude,
                                  ),
                                );
                              },
                        child: Text(
                          "Confirm Location",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
