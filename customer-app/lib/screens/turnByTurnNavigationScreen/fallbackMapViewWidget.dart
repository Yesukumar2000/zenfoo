import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:provider/provider.dart';

/// Fallback map widget for turn-by-turn navigation when navigation service fails
/// Shows driver location and destination with markers and dashed polyline route
class FallbackMapViewWidget extends StatefulWidget {
  final LatLng? driverLocation;
  final LatLng? destinationLocation;
  final String destinationName;

  const FallbackMapViewWidget({
    Key? key,
    this.driverLocation,
    this.destinationLocation,
    required this.destinationName,
  }) : super(key: key);

  @override
  State<FallbackMapViewWidget> createState() => _FallbackMapViewWidgetState();
}

class _FallbackMapViewWidgetState extends State<FallbackMapViewWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverMarkerIcon;
  BitmapDescriptor? _destinationMarkerIcon;

  @override
  void initState() {
    super.initState();
    _createMarkerIcons();
  }

  Future<void> _createMarkerIcons() async {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    try {
      // Create driver marker icon
      _driverMarkerIcon = await _createDriverMarker(colorScheme);

      // Create destination marker icon
      _destinationMarkerIcon = await _createDestinationMarker(colorScheme);

      _updateMarkers();
    } catch (e) {
      log('⚠️ Error creating marker icons: $e');
    }
  }

  Future<BitmapDescriptor> _createDriverMarker(
      AppColorScheme colorScheme) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 120.0;
    const circleRadius = 20.0;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size / 2, size / 2 + 8), circleRadius + 2, shadowPaint);

    // Draw white background circle
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), circleRadius, bgPaint);

    // Draw primary color border
    final borderPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(size / 2, size / 2), circleRadius, borderPaint);

    // Draw bike/delivery icon
    final iconPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    // Bike frame (vertical line)
    final framePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size / 2, size / 2 - 5),
      Offset(size / 2, size / 2 + 5),
      framePaint,
    );

    // Bike wheels (circles)
    canvas.drawCircle(Offset(size / 2 - 5, size / 2 + 4), 2.5, iconPaint);
    canvas.drawCircle(Offset(size / 2 + 5, size / 2 + 4), 2.5, iconPaint);

    // Bike seat (small rectangle)
    final seatRect = Rect.fromCenter(
      center: Offset(size / 2, size / 2 - 4),
      width: 6,
      height: 1.5,
    );
    canvas.drawRect(seatRect, iconPaint);

    // Handlebar (small horizontal line)
    canvas.drawLine(
      Offset(size / 2 - 3, size / 2 - 3),
      Offset(size / 2 + 3, size / 2 - 3),
      framePaint,
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createDestinationMarker(
      AppColorScheme colorScheme) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 120.0;
    const pinRadius = 20.0;
    const pinTipOffset = 35.0;

    final centerX = size / 2;
    final centerY = size / 2;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowPath = Path();
    shadowPath.moveTo(centerX - 3, centerY + pinTipOffset);
    shadowPath.lineTo(centerX + 3, centerY + pinTipOffset);
    shadowPath.lineTo(centerX, centerY + pinTipOffset + 8);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw white circle background
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), pinRadius, bgPaint);

    // Draw primary color border
    final borderPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(centerX, centerY), pinRadius, borderPaint);

    // Draw pin pointer (triangle at bottom)
    final pinPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    pinPath.moveTo(centerX - 8, centerY + pinRadius - 3);
    pinPath.lineTo(centerX + 8, centerY + pinRadius - 3);
    pinPath.lineTo(centerX, centerY + pinTipOffset);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);

    // Draw location icon (circle with dot)
    final iconPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY - 2), 5, iconPaint);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add driver marker
    if (widget.driverLocation != null && _driverMarkerIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: widget.driverLocation!,
          infoWindow: const InfoWindow(
            title: 'Driver Location',
          ),
          icon: _driverMarkerIcon!,
        ),
      );
    }

    // Add destination marker
    if (widget.destinationLocation != null && _destinationMarkerIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destinationLocation!,
          infoWindow: InfoWindow(
            title: widget.destinationName,
          ),
          icon: _destinationMarkerIcon!,
        ),
      );
    }

    // Update polylines between locations
    final polylines = _createPolylines();

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });
  }

  /// Create polyline connecting driver location to destination
  Set<Polyline> _createPolylines() {
    final polylines = <Polyline>{};

    if (widget.driverLocation != null && widget.destinationLocation != null) {
      final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            widget.driverLocation!,
            widget.destinationLocation!,
          ],
          color: colorScheme.primary,
          width: 5,
          geodesic: true,
          patterns: [
            // Dashed line pattern
            PatternItem.dash(20),
            PatternItem.gap(15),
          ],
        ),
      );
    }

    return polylines;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    try {
      // Initial animation to fit bounds
      await Future.delayed(const Duration(milliseconds: 300));
      _animateToBounds();
    } catch (e) {
      log('⚠️ Error in map creation: $e');
    }
  }

  Future<void> _animateToBounds() async {
    if (_mapController == null ||
        widget.driverLocation == null ||
        widget.destinationLocation == null) {
      return;
    }

    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          (widget.driverLocation!.latitude < widget.destinationLocation!.latitude)
              ? widget.driverLocation!.latitude
              : widget.destinationLocation!.latitude,
          (widget.driverLocation!.longitude < widget.destinationLocation!.longitude)
              ? widget.driverLocation!.longitude
              : widget.destinationLocation!.longitude,
        ),
        northeast: LatLng(
          (widget.driverLocation!.latitude > widget.destinationLocation!.latitude)
              ? widget.driverLocation!.latitude
              : widget.destinationLocation!.latitude,
          (widget.driverLocation!.longitude > widget.destinationLocation!.longitude)
              ? widget.driverLocation!.longitude
              : widget.destinationLocation!.longitude,
        ),
      );

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 150),
      );

      log('✅ Map animated to fit both locations');
    } catch (e) {
      log('⚠️ Error animating to bounds: $e');
    }
  }

  @override
  void didUpdateWidget(FallbackMapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update markers if locations changed
    if (oldWidget.driverLocation != widget.driverLocation ||
        oldWidget.destinationLocation != widget.destinationLocation) {
      _updateMarkers();
      _animateToBounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.driverLocation ?? const LatLng(0, 0),
        zoom: 15,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
