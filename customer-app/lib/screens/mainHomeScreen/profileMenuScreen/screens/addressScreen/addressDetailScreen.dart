import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/repositories/storeLocationsApi.dart';
import 'package:project/provider/placeSuggestionsProvider.dart';
import 'package:project/provider/placeDetailsProvider.dart';
import 'package:project/models/placeSuggestionsModel.dart' hide Text;
import 'package:project/helper/styles/appColorScheme.dart' as app_theme;
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
  MapType _mapType = MapType.normal;
  Set<Marker> _storeMarkers = {};
  bool _isMapFullScreen = false;

  String? _pickedCity,
      _pickedState,
      _pickedCountry,
      _pickedPincode,
      _pickedBuildingName;

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

    // Get current location or use default
    if (widget.initialPoint != null) {
      currentPoint = widget.initialPoint!;
      cameraPosition = CameraPosition(target: widget.initialPoint!, zoom: 18);
      _fetchAddress(widget.initialPoint!);
    } else {
      _getCurrentLocation();
    }

    // Fetch Zenfoo store locations and render Z markers on the map
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStoreMarkers());
  }

  Future<void> _loadStoreMarkers() async {
    final stores = await getStoreLocationsApi(context: context);
    if (stores.isEmpty || !mounted) return;

    final BitmapDescriptor icon = await _buildZMarkerIcon();
    final markers = <Marker>{};
    for (final s in stores) {
      final lat = (s['latitude'] as num?)?.toDouble();
      final lng = (s['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final name = (s['name'] ?? '').toString();
      markers.add(
        Marker(
          markerId: MarkerId('zenfoo_store_${s['id']}'),
          position: LatLng(lat, lng),
          icon: icon,
          infoWindow: InfoWindow(
            title: name,
            snippet: (s['address'] ?? '').toString(),
          ),
        ),
      );
    }
    if (mounted) setState(() => _storeMarkers = markers);
  }

  Future<BitmapDescriptor> _buildZMarkerIcon() async {
    // Render at 3x for crisp display; matches the center pin (40x50) on screen.
    const double scale = 1;
    const double w = 40 * scale;
    const double h = 50 * scale;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    const Color zenfooGreen = Color(0xFF9AC444);

    // Same teardrop shape as the center selection pin:
    // borderRadius: topLeft 20, topRight 20, bottomLeft 20, bottomRight 3
    final RRect pinShape = RRect.fromRectAndCorners(
      const Rect.fromLTWH(0, 0, w, h),
      topLeft: Radius.circular(20 * scale),
      topRight: Radius.circular(20 * scale),
      bottomLeft: Radius.circular(20 * scale),
      bottomRight: Radius.circular(3 * scale),
    );

    // Soft drop shadow
    final Path shadowPath = Path()..addRRect(pinShape);
    canvas.drawShadow(shadowPath, Colors.black54, 6 * scale, true);

    // Green fill
    final Paint fill = Paint()..color = zenfooGreen;
    canvas.drawRRect(pinShape, fill);

    // White border (3px on UI -> scaled)
    final Paint border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;
    canvas.drawRRect(pinShape, border);

    // White Z centered (slightly raised, like the location_on icon position)
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'Z',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22 * scale,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((w - tp.width) / 2, (h - tp.height) / 2 - (4 * scale)),
    );

    final ui.Image image =
        await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
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
        cameraPosition = CameraPosition(target: newPoint, zoom: 18);

        // Move camera to current location if map is already created
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLng(newPoint),
          );
        }

        _fetchAddress(newPoint);
      } else {
        // Use default location if permission denied
        const defaultPoint = LatLng(17.4435, 78.3772);
        currentPoint = defaultPoint;
        cameraPosition = CameraPosition(target: defaultPoint, zoom: 18);
        _fetchAddress(defaultPoint);
      }
    } catch (e) {
      // Use default location on error
      const defaultPoint = LatLng(17.4435, 78.3772);
      currentPoint = defaultPoint;
      cameraPosition = CameraPosition(target: defaultPoint, zoom: 18);
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
      log("message1 ${placemarks.map((e) => e.toJson()).toList()}");
      final pm = placemarks.first;
      log("message ${pm.toJson()}");

      // Build address parts list, filtering out empty/null values
      final addressParts = <String>[];

      // Add building/place name first (e.g., "Siri Sampada Hitech")
      if (pm.name != null && pm.name!.isNotEmpty) {
        addressParts.add(pm.name!);
      }

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
        _pickedBuildingName = pm.name ?? "";
        addressLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        selectedAddress =
            getTranslatedValue(context, 'unable_to_fetch_address');
        _pickedPincode = "";
        _pickedCity = "";
        _pickedState = "";
        _pickedCountry = "";
        _pickedBuildingName = "";
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
            context: context,
            input: input,
          );
    });
  }

  Future<void> _selectPrediction(Suggestions suggestion) async {
    final detailsProvider = context.read<PlaceDetailsProvider>();
    await detailsProvider.fetchPlaceDetails(
      context: context,
      placeId: suggestion.placePrediction?.placeId ?? "",
    );
    final details = detailsProvider.placeDetails;
    final lat =
        double.tryParse(details?.location?.latitude.toString() ?? "") ?? 0;
    final lng =
        double.tryParse(details?.location?.longitude.toString() ?? "") ?? 0;
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
      body: Column(
        children: [
          // ====== AppHeader ======
          AppHeader(
            label: getTranslatedValue(context, 'pick_location'),
            title: getTranslatedValue(context, 'select_on_map'),
            showBackButton: true,
            onBackPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),

          // ====== Rest of content in scrollable area ======
          Expanded(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ====== Search bar + suggestions ======
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: colorScheme.cardGradient,
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
                              hintText: getTranslatedValue(
                                  context, 'search_for_area_street_name'),
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
                          if (suggestionsProvider.placeSuggestionsState ==
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
                                  // Extract the actual text from placePrediction
                                  String displayText = "";

                                  // First try to get text from the text object
                                  if (suggestion.placePrediction?.text?.text !=
                                          null &&
                                      suggestion.placePrediction!.text!.text!
                                          .isNotEmpty) {
                                    displayText =
                                        suggestion.placePrediction!.text!.text!;
                                  }
                                  // Then try structured format mainText
                                  else if (suggestion
                                              .placePrediction
                                              ?.structuredFormat
                                              ?.mainText
                                              ?.text !=
                                          null &&
                                      suggestion
                                          .placePrediction!
                                          .structuredFormat!
                                          .mainText!
                                          .text!
                                          .isNotEmpty) {
                                    displayText = suggestion.placePrediction!
                                        .structuredFormat!.mainText!.text!;
                                    // Add secondary text if available
                                    if (suggestion
                                            .placePrediction
                                            ?.structuredFormat
                                            ?.secondaryText
                                            ?.text !=
                                        null) {
                                      displayText +=
                                          ", ${suggestion.placePrediction!.structuredFormat!.secondaryText!.text!}";
                                    }
                                  }
                                  // Fallback to place field
                                  else if (suggestion.placePrediction?.place !=
                                          null &&
                                      suggestion
                                          .placePrediction!.place!.isNotEmpty) {
                                    displayText =
                                        suggestion.placePrediction!.place!;
                                  }
                                  // Last resort
                                  else {
                                    displayText = getTranslatedValue(
                                        context, 'unknown_location');
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
                          if (suggestionsProvider.placeSuggestionsState ==
                              PlaceSuggestionsState.empty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  suggestionsProvider.message.isNotEmpty
                                      ? suggestionsProvider.message
                                      : getTranslatedValue(
                                          context, 'no_result_found'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          if (suggestionsProvider.placeSuggestionsState ==
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
                                      suggestionsProvider.message,
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
                            height: _isMapFullScreen
                                ? size.height * 0.65
                                : size.height * 0.4,
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
                                          getTranslatedValue(
                                              context, 'loading_map'),
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
                                        mapType: _mapType,
                                        buildingsEnabled: true,
                                        markers: _storeMarkers,
                                        onMapCreated: (ctrl) {
                                          mapController = ctrl;
                                        },
                                        onCameraMove: _onMapMoved,
                                        onCameraIdle: _onMapIdle,
                                        myLocationEnabled: true,
                                        myLocationButtonEnabled: false,
                                        zoomGesturesEnabled: true,
                                        zoomControlsEnabled: false,
                                      ),
                                      // Custom Animated Marker - Compact Design
                                      IgnorePointer(
                                        ignoring: true,
                                        child: AnimatedBuilder(
                                          animation: _markerAnimation,
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(0,
                                                  -28 - _markerAnimation.value),
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
                                      // Fullscreen Toggle Button
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _isMapFullScreen =
                                                  !_isMapFullScreen;
                                            });
                                          },
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  colorScheme.iconTileGradient,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: colorScheme.border,
                                                  width: 1),
                                              boxShadow: colorScheme.cardShadow,
                                            ),
                                            child: Icon(
                                                _isMapFullScreen
                                                    ? Icons
                                                        .fullscreen_exit_rounded
                                                    : Icons.fullscreen_rounded,
                                                color: colorScheme.primary,
                                                size: 24),
                                          ),
                                        ),
                                      ),
                                      // Map Type Toggle Button
                                      Positioned(
                                        bottom: 70,
                                        right: 16,
                                        child: GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _mapType = _mapType ==
                                                      MapType.normal
                                                  ? MapType.hybrid
                                                  : MapType.normal;
                                            });
                                          },
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  colorScheme.iconTileGradient,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: colorScheme.border,
                                                  width: 1),
                                              boxShadow: colorScheme.cardShadow,
                                            ),
                                            child: Icon(
                                                _mapType == MapType.normal
                                                    ? Icons.satellite_alt
                                                    : Icons.map_rounded,
                                                color: colorScheme.primary,
                                                size: 22),
                                          ),
                                        ),
                                      ),
                                      // Done Button (only in fullscreen mode)
                                      if (_isMapFullScreen)
                                        Positioned(
                                          left: 16,
                                          right: 76,
                                          bottom: 16,
                                          child: SizedBox(
                                            height: 52,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    colorScheme.primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                elevation: 4,
                                              ),
                                              onPressed: currentPoint == null ||
                                                      addressLoading
                                                  ? null
                                                  : () {
                                                      HapticFeedback
                                                          .mediumImpact();
                                                      Navigator.pop(context, {
                                                        "lat": currentPoint!
                                                            .latitude,
                                                        "lng": currentPoint!
                                                            .longitude,
                                                        "address":
                                                            selectedAddress,
                                                        "pincode":
                                                            _pickedPincode ?? "",
                                                        "city":
                                                            _pickedCity ?? "",
                                                        "state":
                                                            _pickedState ?? "",
                                                        "country":
                                                            _pickedCountry ?? "",
                                                        "building":
                                                            _pickedBuildingName ??
                                                                "",
                                                      });
                                                    },
                                              icon: const Icon(
                                                  Icons.check_rounded,
                                                  size: 22),
                                              label: Text(
                                                'Done',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
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
                                              gradient:
                                                  colorScheme.iconTileGradient,
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
                        gradient: colorScheme.cardGradient,
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
                                  getTranslatedValue(
                                      context, 'fetching_address'),
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
                                      getTranslatedValue(
                                          context, 'selected_address'),
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
                                Navigator.pop(context, {
                                  "lat": currentPoint!.latitude,
                                  "lng": currentPoint!.longitude,
                                  "address": selectedAddress,
                                  "pincode": _pickedPincode ?? "",
                                  "city": _pickedCity ?? "",
                                  "state": _pickedState ?? "",
                                  "country": _pickedCountry ?? "",
                                  "building": _pickedBuildingName ?? "",
                                });
                              },
                        child: Text(
                          getTranslatedValue(context, 'confirm_location'),
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

enum AddressType { home, office, other }

class AddressDetailScreen extends StatefulWidget {
  final UserAddressData? address;
  final BuildContext addressProviderContext;
  final Map<String, dynamic>? pickedAddressData;

  const AddressDetailScreen({
    Key? key,
    this.address,
    required this.addressProviderContext,
    this.pickedAddressData,
  }) : super(key: key);

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController edtName = TextEditingController();
  final TextEditingController edtMobile = TextEditingController();
  final TextEditingController edtAltMobile = TextEditingController();
  final TextEditingController edtHouse = TextEditingController();
  final TextEditingController edtBuilding = TextEditingController();
  final TextEditingController edtLandmark = TextEditingController();
  final TextEditingController edtArea = TextEditingController();
  final TextEditingController edtCity = TextEditingController();
  final TextEditingController edtZipcode = TextEditingController();
  final TextEditingController edtState = TextEditingController();
  final TextEditingController edtCountry = TextEditingController();

  // Add more controllers as needed

  bool isLoading = false;
  bool isDefaultAddress = false;
  String longitude = "";
  String latitude = "";
  AddressType selectedAddressType = AddressType.home;

  final FocusNode mobileFocus = FocusNode();
  final FocusNode altMobileFocus = FocusNode();
  String? outOfZoneError;

  @override
  void initState() {
    super.initState();
    edtName.text = widget.address?.name ?? "";
    edtAltMobile.text = widget.address?.alternateMobile ?? "";
    edtMobile.text = widget.address?.mobile ?? "";
    edtHouse.text = widget.address?.address ?? ""; // Or split if needed
    edtBuilding.text = widget.address?.building ?? "";
    edtLandmark.text = widget.address?.landmark ?? "";
    edtZipcode.text = widget.address?.pincode ?? "";
    edtArea.text = widget.address?.area ?? "";
    edtCity.text = widget.address?.city ?? "";
    isDefaultAddress = widget.address?.isDefault == "1";
    final type = widget.address?.type?.toLowerCase();
    selectedAddressType = (type == "office")
        ? AddressType.office
        : (type == "other")
            ? AddressType.other
            : AddressType.home;
    longitude = widget.address?.longitude ?? "";
    latitude = widget.address?.latitude ?? "";

    edtCity.text = widget.address?.city ?? "";
    edtState.text = widget.address?.state ?? "";
    edtCountry.text = widget.address?.country ?? "";

    // Prefill from MAP pick (if came from picker!)
    if (widget.pickedAddressData != null) {
      latitude = widget.pickedAddressData!['lat']?.toString() ?? "";
      longitude = widget.pickedAddressData!['lng']?.toString() ?? "";
      edtArea.text = widget.pickedAddressData!['address'] ?? "";
      edtZipcode.text = widget.pickedAddressData!['pincode'] ?? "";
      edtCity.text = widget.pickedAddressData!['city'] ?? "";
      edtState.text = widget.pickedAddressData!['state'] ?? "";
      edtCountry.text = widget.pickedAddressData!['country'] ?? "";
      // Building/apartment name is left for the customer to enter themselves.
      // you may use a parser to fill other fields if you want (house/city)
    }
  }

  String? emptyValidation(String? value) => (value == null || value.isEmpty)
      ? getTranslatedValue(context, 'validation_required')
      : null;
  String? phoneValidation(String? value) => (value == null || value.length < 10)
      ? getTranslatedValue(context, 'validation_invalid_mobile')
      : null;
  String? optionalPhoneValidation(String? value) => null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: widget.address == null
              ? getTranslatedValue(context, 'new_address')
              : getTranslatedValue(context, 'edit_address'),
          title: getTranslatedValue(context, 'enter_details'),
          showBackButton: true,
          onBackPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Form(
              key: formKey,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Main Content
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        // width: width > 393 ? 393 : width,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // ====== SECTION 1: Address Label ======
                            _buildSectionHeader(
                              getTranslatedValue(context, 'address_label'),
                              colorScheme,
                              icon: Icons.label_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 72,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    buildChip(
                                      getTranslatedValue(
                                          context, 'home_address_type'),
                                      AddressType.home,
                                      selectedAddressType == AddressType.home,
                                      Icons.home_rounded,
                                      colorScheme,
                                    ),
                                    const SizedBox(width: 10),
                                    buildChip(
                                      getTranslatedValue(
                                          context, 'work_address_type'),
                                      AddressType.office,
                                      selectedAddressType == AddressType.office,
                                      Icons.business_center_rounded,
                                      colorScheme,
                                    ),
                                    const SizedBox(width: 10),
                                    buildChip(
                                      getTranslatedValue(
                                          context, 'other_address_type'),
                                      AddressType.other,
                                      selectedAddressType == AddressType.other,
                                      Icons.location_on_rounded,
                                      colorScheme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ====== SECTION 2: Location Details ======
                            _buildSectionHeader(
                              getTranslatedValue(context, 'location_details'),
                              colorScheme,
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              title: getTranslatedValue(
                                  context, 'house_no_and_floor'),
                              hintText: getTranslatedValue(
                                  context, 'house_no_placeholder'),
                              controller: edtHouse,
                              validator: emptyValidation,
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              title: getTranslatedValue(
                                  context, 'building_and_apartment_name'),
                              hintText: getTranslatedValue(
                                  context, 'building_name_placeholder'),
                              controller: edtBuilding,
                              validator: emptyValidation,
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                // Navigate to location picker
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MultiProvider(
                                      providers: [
                                        ChangeNotifierProvider(
                                            create: (_) =>
                                                PlaceSuggestionsProvider()),
                                        ChangeNotifierProvider(
                                            create: (_) =>
                                                PlaceDetailsProvider()),
                                      ],
                                      child: LocationPickerScreen(
                                        initialPoint: (latitude.isNotEmpty &&
                                                longitude.isNotEmpty)
                                            ? LatLng(
                                                double.tryParse(latitude) ??
                                                    0.0,
                                                double.tryParse(longitude) ??
                                                    0.0,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                );

                                // Update fields when returning from location picker
                                if (result != null && result is Map) {
                                  setState(() {
                                    outOfZoneError =
                                        null; // Clear any previous errors
                                    latitude = result['lat']?.toString() ?? "";
                                    longitude = result['lng']?.toString() ?? "";
                                    edtArea.text = result['address'] ?? "";
                                    edtZipcode.text = result['pincode'] ?? "";
                                    edtCity.text = result['city'] ?? "";
                                    edtState.text = result['state'] ?? "";
                                    edtCountry.text = result['country'] ?? "";
                                    // Building/apartment name is left for the
                                    // customer to enter themselves.
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: CustomTextFormField(
                                  maxLines: 5,
                                  title:
                                 getTranslatedValue(
                                      context, 'area_name_and_location'),
                                  hintText: getTranslatedValue(
                                      context, 'tap_to_select_location_on_map'),
                                  controller: edtArea,
                                  validator: (val) {
                                    if (outOfZoneError != null)
                                      return outOfZoneError;
                                    return emptyValidation(val);
                                  },
                                  suffixIcon: Icon(
                                    Icons.location_on_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              title: getTranslatedValue(context, 'landmark'),
                              hintText: getTranslatedValue(
                                  context, 'enter_landmark'),
                              controller: edtLandmark,
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              title: getTranslatedValue(context, 'pincode'),
                              hintText:
                                  getTranslatedValue(context, 'enter_pincode'),
                              controller: edtZipcode,
                              keyboardType: TextInputType.number,
                              validator: emptyValidation,
                            ),
                            const SizedBox(height: 24),

                            // ====== SECTION 3: Personal Details ======
                            _buildSectionHeader(
                              getTranslatedValue(context, 'personal_details'),
                              colorScheme,
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              title:
                                  getTranslatedValue(context, 'receivers_name'),
                              hintText: getTranslatedValue(
                                  context, 'enter_receivers_name'),
                              controller: edtName,
                              validator: emptyValidation,
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              title: getTranslatedValue(
                                  context, 'receivers_phone_number'),
                              hintText: getTranslatedValue(
                                  context, 'enter_receivers_phone_number'),
                              controller: edtMobile,
                              keyboardType: TextInputType.phone,
                              validator: phoneValidation,
                              focusNode: mobileFocus,
                              maxLength: 10,
                            ),

                            // Bottom padding for bottom nav button
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced Loading Overlay
            if (isLoading) _buildLoadingOverlay(colorScheme),
          ],
        ),
      ),

      // ====== Bottom Navigation Bar with Save Button ======
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.divider,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLoading
                    ? colorScheme.primary.withValues(alpha: 0.7)
                    : colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              onPressed: isLoading ? null : () => _handleSaveAddress(),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.address == null
                              ? getTranslatedValue(context, 'saving')
                              : getTranslatedValue(context, 'updating'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.address == null
                              ? Icons.add_location_rounded
                              : Icons.update_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.address == null
                              ? getTranslatedValue(context, 'save_address')
                              : getTranslatedValue(context, 'update_address'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    app_theme.AppColorScheme colorScheme, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: colorScheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(app_theme.AppColorScheme colorScheme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colorScheme.isDark
                ? [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.9),
                  ]
                : [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.4),
                  ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.address == null
                      ? getTranslatedValue(context, 'saving')
                      : getTranslatedValue(context, 'updating'),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getTranslatedValue(context, 'please_wait'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveAddress() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
      });

      Map<String, String> params = {};

      // For update, send ID param if present
      String id = widget.address?.id?.toString() ?? "";
      if (id.isNotEmpty) {
        params[ApiAndParams.id] = id;
      }

      params[ApiAndParams.name] = edtName.text.trim();
      params[ApiAndParams.mobile] = edtMobile.text.trim();
      params[ApiAndParams.alternateMobile] = edtAltMobile.text.trim();
      params[ApiAndParams.type] = selectedAddressType == AddressType.home
          ? "home"
          : selectedAddressType == AddressType.office
              ? "office"
              : "other";
      params[ApiAndParams.address] = edtHouse.text.trim();
      params[ApiAndParams.building] = edtBuilding.text.trim();
      params[ApiAndParams.landmark] = edtLandmark.text.trim();
      params[ApiAndParams.area] = edtArea.text.trim();
      params[ApiAndParams.pinCode] = edtZipcode.text.trim();
      params[ApiAndParams.city] = edtCity.text.trim();
      params[ApiAndParams.latitude] = latitude;
      params[ApiAndParams.longitude] = longitude;
      params[ApiAndParams.isDefault] = isDefaultAddress ? "1" : "0";

      if (edtState.text.isNotEmpty) {
        params[ApiAndParams.state] = edtState.text.trim();
      }
      if (edtCountry.text.isNotEmpty) {
        params[ApiAndParams.country] = edtCountry.text.trim();
      }
      if (edtZipcode.text.isNotEmpty) {
        params["pincode"] = edtZipcode.text.trim();
      }

      final response = await widget.addressProviderContext
          .read<AddressProvider>()
          .addOrUpdateAddress(
            context: context,
            address: widget.address ?? "",
            params: params,
            function: () {
              Navigator.pop(context);
            },
          );

      if (response[ApiAndParams.status].toString() == "0") {
        String msg = response[ApiAndParams.message] ?? "";
        if (msg.toLowerCase().contains("delivery zone")) {
          setState(() {
            outOfZoneError = msg;
          });
          formKey.currentState?.validate();
        } else {
          showMessage(context, msg, MessageType.warning);
        }
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildChip(String label, AddressType type, bool selected, IconData icon,
      app_theme.AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => selectedAddressType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : colorScheme.iconPrimary,
            ),
            if (label.isNotEmpty) const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
