import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';

class OrderRouteMap extends StatefulWidget {
  final IncomingOrder order;
  final double height;

  const OrderRouteMap({
    super.key,
    required this.order,
    this.height = 250,
  });

  @override
  State<OrderRouteMap> createState() => _OrderRouteMapState();
}

class _OrderRouteMapState extends State<OrderRouteMap> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};
  String? _mapStyle;
  late AppColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    colorScheme = context.read<ThemeProvider>().colorScheme;
    _loadMapStyle();
    _initializeMapElements();
  }

  Future<void> _loadMapStyle() async {
    try {
      final isDarkMode =
          context.read<ThemeProvider>().isDarkMode;
      final styleFile = isDarkMode
          ? 'assets/mapTheme/nightMode.json'
          : 'assets/mapTheme/dayMode.json';

      final String styleString = await rootBundle.loadString(styleFile);
      if (mounted) {
        setState(() {
          _mapStyle = styleString;
        });
      }
    } catch (e) {
      debugPrint('Error loading map style: $e');
    }
  }

  void _initializeMapElements() {
    markers.clear();
    polylines.clear();

    // Add markers for all delivery points
    _addMarkers();

    // Draw polylines connecting all points
    _drawPolylines();
  }

  void _addMarkers() async {
    // Add driver starting position marker
    final driverIcon = await _createDriverMarker();
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(
          widget.order.driver.latitude,
          widget.order.driver.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: driverIcon,
        anchor: const Offset(0.5, 0.65),
      ),
    );

    // Add markers for each seller/delivery point
    for (int i = 0; i < widget.order.sellersVisitOrder.length; i++) {
      final seller = widget.order.sellersVisitOrder[i];
      final markerIcon = i == 0
          ? await _createPickupMarker(seller.storeName)
          : await _createDeliveryMarker(i, seller.storeName);

      markers.add(
        Marker(
          markerId: MarkerId('seller_$i'),
          position: LatLng(seller.latitude, seller.longitude),
          infoWindow: InfoWindow(
            title: seller.storeName,
            snippet: seller.sellerAddress,
          ),
          icon: markerIcon,
          anchor: const Offset(0.5, 0.65),
        ),
      );
    }

    // Add marker for customer delivery location
    final customerIcon = await _createCustomerMarker();
    markers.add(
      Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(
          widget.order.customer.lat,
          widget.order.customer.lng,
        ),
        infoWindow: InfoWindow(
          title: 'Customer: ${widget.order.customer.name}',
          snippet: widget.order.customer.address,
        ),
        icon: customerIcon,
        anchor: const Offset(0.5, 0.65),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  /// Create driver location marker with bike icon only
  Future<BitmapDescriptor> _createDriverMarker() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 100.0;
    const circleRadius = 15.0;
    const pinTop = 20.0;

    final pinCenterX = size / 2;
    final pinCenterY = pinTop + circleRadius;

    // Draw pin shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowPath = Path();
    shadowPath.moveTo(pinCenterX - 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX + 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX, pinCenterY + circleRadius + 6);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw white circle background
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      circlePaint,
    );

    // Draw primary color border
    final borderPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      borderPaint,
    );

    // Draw pin pointer (triangle at bottom)
    final pinPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    pinPath.moveTo(pinCenterX - 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX + 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX, pinCenterY + circleRadius + 14);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);

    // Draw pin border
    final pinBorderPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(pinPath, pinBorderPaint);

    // Draw bike icon (simplified motorcycle shape)
    final bikePaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    // Front wheel (circle)
    canvas.drawCircle(Offset(pinCenterX + 3, pinCenterY + 1), 2.5, bikePaint);

    // Rear wheel (circle)
    canvas.drawCircle(Offset(pinCenterX - 3, pinCenterY + 1), 2.5, bikePaint);

    // Bike frame (line connecting wheels)
    final framePaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(pinCenterX - 3, pinCenterY + 1),
      Offset(pinCenterX + 3, pinCenterY + 1),
      framePaint,
    );

    // Seat/handlebar (small lines)
    canvas.drawLine(
      Offset(pinCenterX - 1, pinCenterY - 2),
      Offset(pinCenterX + 1, pinCenterY - 2),
      framePaint,
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Create pickup location marker with info card (Green)
  Future<BitmapDescriptor> _createPickupMarker(String storeName) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 150.0;
    const cardWidth = 85.0;
    const cardHeight = 36.0;
    const circleRadius = 15.0;
    const cardTop = 8.0;
    const pinTop = cardTop + cardHeight + 10.0;
    const cardLeft = size / 3;
    const pickupGreen = Color(0xFF10B981);

    final pinCenterX = size / 2;
    final pinCenterY = pinTop + circleRadius;

    // Draw info card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(12),
    );

    // Card shadow - design system specs: 22px blur, 10% opacity in light mode
    final cardShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawRRect(cardRect, cardShadowPaint);

    // Card background
    final cardBgPaint = Paint()..color = colorScheme.surface;
    canvas.drawRRect(cardRect, cardBgPaint);

    // Card border
    final cardBorderPaint = Paint()
      ..color = pickupGreen.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cardRect, cardBorderPaint);

    // Icon background
    final iconBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft + 6, cardTop + 6, 18, 18),
      const Radius.circular(4),
    );
    final iconBgPaint = Paint()
      ..color = pickupGreen.withValues(alpha: 0.15);
    canvas.drawRRect(iconBgRect, iconBgPaint);

    // Draw package icon
    final iconPaint = Paint()
      ..color = pickupGreen
      ..style = PaintingStyle.fill;
    final iconCenterX = cardLeft + 15;
    final iconCenterY = cardTop + 15;

    // Package box
    final boxPath = Path();
    boxPath.moveTo(iconCenterX - 5, iconCenterY - 4);
    boxPath.lineTo(iconCenterX + 5, iconCenterY - 4);
    boxPath.lineTo(iconCenterX + 5, iconCenterY + 4);
    boxPath.lineTo(iconCenterX - 5, iconCenterY + 4);
    boxPath.close();
    canvas.drawPath(boxPath, iconPaint);

    // Top flap
    canvas.drawLine(Offset(iconCenterX - 5, iconCenterY - 4), Offset(iconCenterX, iconCenterY - 7), iconPaint);
    canvas.drawLine(Offset(iconCenterX + 5, iconCenterY - 4), Offset(iconCenterX, iconCenterY - 7), iconPaint);

    // Draw "Pickup" label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Pickup From',
        style: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout(maxWidth: cardWidth - 30);
    labelPainter.paint(canvas, Offset(cardLeft + 28, cardTop + 8));

    // Draw store name
    final namePainter = TextPainter(
      text: TextSpan(
        text: storeName.length > 10 ? '${storeName.substring(0, 9)}...' : storeName,
        style: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    namePainter.layout(maxWidth: cardWidth - 30);
    namePainter.paint(canvas, Offset(cardLeft + 28, cardTop + 20));

    // Draw pin shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowPath = Path();
    shadowPath.moveTo(pinCenterX - 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX + 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX, pinCenterY + circleRadius + 6);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw white circle
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pinCenterX, pinCenterY), circleRadius, circlePaint);

    // Draw green border
    final borderPaint = Paint()
      ..color = pickupGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(pinCenterX, pinCenterY), circleRadius, borderPaint);

    // Draw pin pointer
    final pinPaint = Paint()
      ..color = pickupGreen
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    pinPath.moveTo(pinCenterX - 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX + 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX, pinCenterY + circleRadius + 14);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);

    // Draw pin border
    final pinBorderPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(pinPath, pinBorderPaint);

    // Draw package icon in circle
    final packagePaint = Paint()
      ..color = pickupGreen
      ..style = PaintingStyle.fill;

    final packagePath = Path();
    packagePath.moveTo(pinCenterX - 4, pinCenterY - 3);
    packagePath.lineTo(pinCenterX + 4, pinCenterY - 3);
    packagePath.lineTo(pinCenterX + 4, pinCenterY + 3);
    packagePath.lineTo(pinCenterX - 4, pinCenterY + 3);
    packagePath.close();
    canvas.drawPath(packagePath, packagePaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Create delivery location marker with info card (Orange)
  Future<BitmapDescriptor> _createDeliveryMarker(int index, String storeName) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 150.0;
    const cardWidth = 85.0;
    const cardHeight = 36.0;
    const circleRadius = 15.0;
    const cardTop = 8.0;
    const pinTop = cardTop + cardHeight + 10.0;
    const cardLeft = size / 3;
    const deliveryOrange = Color(0xFFF59E0B);

    final pinCenterX = size / 2;
    final pinCenterY = pinTop + circleRadius;

    // Draw info card
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(12),
    );

    // Card shadow - design system specs: 22px blur, 10% opacity in light mode
    final cardShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawRRect(cardRect, cardShadowPaint);

    // Card background
    final cardBgPaint = Paint()..color = colorScheme.surface;
    canvas.drawRRect(cardRect, cardBgPaint);

    // Card border
    final cardBorderPaint = Paint()
      ..color = deliveryOrange.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cardRect, cardBorderPaint);

    // Icon background
    final iconBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft + 6, cardTop + 6, 18, 18),
      const Radius.circular(4),
    );
    final iconBgPaint = Paint()
      ..color = deliveryOrange.withValues(alpha: 0.15);
    canvas.drawRRect(iconBgRect, iconBgPaint);

    // Draw location pin icon
    final iconPaint = Paint()
      ..color = deliveryOrange
      ..style = PaintingStyle.fill;
    final iconCenterX = cardLeft + 15;
    final iconCenterY = cardTop + 15;

    // Pin circle
    canvas.drawCircle(Offset(iconCenterX, iconCenterY - 1), 2.5, iconPaint);

    // Pin pointer
    final iconPinPath = Path();
    iconPinPath.moveTo(iconCenterX - 2, iconCenterY + 1);
    iconPinPath.lineTo(iconCenterX, iconCenterY + 3.5);
    iconPinPath.lineTo(iconCenterX + 2, iconCenterY + 1);
    iconPinPath.close();
    canvas.drawPath(iconPinPath, iconPaint);

    // Draw "Delivery Stop" label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Stop $index',
        style: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout(maxWidth: cardWidth - 30);
    labelPainter.paint(canvas, Offset(cardLeft + 28, cardTop + 8));

    // Draw store name
    final namePainter = TextPainter(
      text: TextSpan(
        text: storeName.length > 10 ? '${storeName.substring(0, 9)}...' : storeName,
        style: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    namePainter.layout(maxWidth: cardWidth - 30);
    namePainter.paint(canvas, Offset(cardLeft + 28, cardTop + 20));

    // Draw pin shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowPath = Path();
    shadowPath.moveTo(pinCenterX - 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX + 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX, pinCenterY + circleRadius + 6);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw white circle
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pinCenterX, pinCenterY), circleRadius, circlePaint);

    // Draw orange border
    final borderPaint = Paint()
      ..color = deliveryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(pinCenterX, pinCenterY), circleRadius, borderPaint);

    // Draw pin pointer
    final pinPaint = Paint()
      ..color = deliveryOrange
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    pinPath.moveTo(pinCenterX - 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX + 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX, pinCenterY + circleRadius + 14);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);

    // Draw pin border
    final pinBorderPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(pinPath, pinBorderPaint);

    // Draw location pin icon in circle
    final circlePinPaint = Paint()
      ..color = deliveryOrange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(pinCenterX, pinCenterY - 3), 2, circlePinPaint);

    final circlePinPath = Path();
    circlePinPath.moveTo(pinCenterX - 1.5, pinCenterY);
    circlePinPath.lineTo(pinCenterX, pinCenterY + 2);
    circlePinPath.lineTo(pinCenterX + 1.5, pinCenterY);
    circlePinPath.close();
    canvas.drawPath(circlePinPath, circlePinPaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  /// Create customer delivery marker with info card (Red)
  Future<BitmapDescriptor> _createCustomerMarker() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 150.0;
    const cardWidth = 85.0;
    const cardHeight = 36.0;
    const circleRadius = 15.0;
    const cardTop = 8.0;
    const pinTop = cardTop + cardHeight + 10.0;
    const cardLeft = size / 3;

    final pinCenterX = size / 2;
    final pinCenterY = pinTop + circleRadius;

    // Draw info card (positioned to the right)
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(12),
    );

    // Card shadow - design system specs: 22px blur, 10% opacity in light mode
    final cardShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawRRect(cardRect, cardShadowPaint);

    // Card background
    final cardBgPaint = Paint()..color = colorScheme.surface;
    canvas.drawRRect(cardRect, cardBgPaint);

    // Card border
    final cardBorderPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cardRect, cardBorderPaint);

    // Draw text on card
    final address = widget.order.customer.name;

    // Icon background (smaller)
    final iconBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft + 6, cardTop + 6, 18, 18),
      const Radius.circular(4),
    );
    final iconBgPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.15);
    canvas.drawRRect(iconBgRect, iconBgPaint);

    // Draw location icon (simplified)
    final iconPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;
    final iconPath = Path();
    final iconCenterX = cardLeft + 15;
    final iconCenterY = cardTop + 15;
    iconPath.addOval(Rect.fromCircle(
        center: Offset(iconCenterX, iconCenterY - 1.5), radius: 2.5));
    iconPath.moveTo(iconCenterX - 2, iconCenterY + 1);
    iconPath.lineTo(iconCenterX, iconCenterY + 3.5);
    iconPath.lineTo(iconCenterX + 2, iconCenterY + 1);
    iconPath.close();
    canvas.drawPath(iconPath, iconPaint);

    // Draw "Delivery To" label (smaller)
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Delivery To',
        style: GoogleFonts.inter(
          color: colorScheme.textSecondary,
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout(maxWidth: cardWidth - 30);
    labelPainter.paint(canvas, Offset(cardLeft + 28, cardTop + 8));

    // Draw address text (smaller and more compact)
    final addressPainter = TextPainter(
      text: TextSpan(
        text: address.length > 10 ? '${address.substring(0, 9)}...' : address,
        style: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    addressPainter.layout(maxWidth: cardWidth - 30);
    addressPainter.paint(canvas, Offset(cardLeft + 28, cardTop + 20));

    // Draw pin shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Shadow for the pin point
    final shadowPath = Path();
    shadowPath.moveTo(pinCenterX - 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX + 1.5, pinCenterY + circleRadius + 15);
    shadowPath.lineTo(pinCenterX, pinCenterY + circleRadius + 6);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw white circle background
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      circlePaint,
    );

    // Draw primary color border
    final borderPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      borderPaint,
    );

    // Draw pin pointer (triangle at bottom)
    final pinPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    final pinPath = Path();
    pinPath.moveTo(pinCenterX - 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX + 6, pinCenterY + circleRadius - 2);
    pinPath.lineTo(pinCenterX, pinCenterY + circleRadius + 14);
    pinPath.close();
    canvas.drawPath(pinPath, pinPaint);

    // Draw pin border
    final pinBorderPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(pinPath, pinBorderPaint);

    // Draw home icon (simplified house shape)
    final homeIconPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    // House roof (triangle)
    final roofPath = Path();
    roofPath.moveTo(pinCenterX, pinCenterY - 5);
    roofPath.lineTo(pinCenterX - 6, pinCenterY + 1);
    roofPath.lineTo(pinCenterX + 6, pinCenterY + 1);
    roofPath.close();
    canvas.drawPath(roofPath, homeIconPaint);

    // House body (rectangle)
    final bodyRect = Rect.fromLTWH(
      pinCenterX - 5,
      pinCenterY + 1,
      10,
      7,
    );
    canvas.drawRect(bodyRect, homeIconPaint);

    // Door (small rectangle)
    final doorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final doorRect = Rect.fromLTWH(
      pinCenterX - 1.5,
      pinCenterY + 3,
      3,
      5,
    );
    canvas.drawRect(doorRect, doorPaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(buffer);
  }

  void _drawPolylines() {
    // Create list of all points in order: driver -> sellers -> customer
    final List<LatLng> allPoints = [
      LatLng(widget.order.driver.latitude, widget.order.driver.longitude),
      ...widget.order.sellersVisitOrder
          .map((seller) => LatLng(seller.latitude, seller.longitude)),
      LatLng(widget.order.customer.lat, widget.order.customer.lng),
    ];

    // Draw polylines connecting consecutive points with arc curves
    for (int i = 0; i < allPoints.length - 1; i++) {
      final arcPoints = _createArcPolyline(allPoints[i], allPoints[i + 1]);
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: arcPoints,
          color: colorScheme.primary,
          width: 4,
          geodesic: true,
        ),
      );
    }
  }

  /// Create a smooth arc polyline between two points using quadratic Bezier curve
  List<LatLng> _createArcPolyline(LatLng start, LatLng end) {
    List<LatLng> arcPoints = [];
    const int segments = 50; // Number of points in the arc

    // Offset the start/end points to match the visual top of the marker pin circles
    const double markerOffsetDegrees = 0.00009; // Offset to reach top of pin circle

    LatLng adjustedStart =
        LatLng(start.latitude - markerOffsetDegrees, start.longitude);
    LatLng adjustedEnd =
        LatLng(end.latitude - markerOffsetDegrees, end.longitude);

    // Calculate the midpoint
    double midLat = (adjustedStart.latitude + adjustedEnd.latitude) / 2;
    double midLng = (adjustedStart.longitude + adjustedEnd.longitude) / 2;

    // Calculate line direction
    double latDiff = adjustedEnd.latitude - adjustedStart.latitude;
    double lngDiff = adjustedEnd.longitude - adjustedStart.longitude;

    // Calculate perpendicular direction (rotated 90 degrees)
    double perpLat = -lngDiff;
    double perpLng = latDiff;

    // Normalize the perpendicular vector
    double perpLength = sqrt(perpLat * perpLat + perpLng * perpLng);
    if (perpLength > 0) {
      perpLat /= perpLength;
      perpLng /= perpLength;
    }

    // Calculate arc height based on distance
    double distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);
    double arcHeight = distance * 0.2; // 20% of distance for subtle arc

    // Ensure arc curves upward by using absolute perpendicular offset
    if (perpLat < 0) {
      perpLat = -perpLat;
      perpLng = -perpLng;
    }

    // Arc peak point (midpoint + perpendicular offset)
    double peakLat = midLat + perpLat * arcHeight;
    double peakLng = midLng + perpLng * arcHeight;

    // Generate points along the arc using quadratic Bezier curve
    for (int i = 0; i <= segments; i++) {
      double t = i / segments;

      // Quadratic Bezier curve formula: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
      double lat = pow(1 - t, 2).toDouble() * adjustedStart.latitude +
          2 * (1 - t) * t * peakLat +
          pow(t, 2).toDouble() * adjustedEnd.latitude;

      double lng = pow(1 - t, 2).toDouble() * adjustedStart.longitude +
          2 * (1 - t) * t * peakLng +
          pow(t, 2).toDouble() * adjustedEnd.longitude;

      arcPoints.add(LatLng(lat, lng));
    }

    return arcPoints;
  }

  LatLngBounds _getMapBounds() {
    // Calculate bounds to fit all markers
    double minLat = widget.order.driver.latitude;
    double maxLat = widget.order.driver.latitude;
    double minLng = widget.order.driver.longitude;
    double maxLng = widget.order.driver.longitude;

    for (final seller in widget.order.sellersVisitOrder) {
      minLat = minLat > seller.latitude ? seller.latitude : minLat;
      maxLat = maxLat < seller.latitude ? seller.latitude : maxLat;
      minLng = minLng > seller.longitude ? seller.longitude : minLng;
      maxLng = maxLng < seller.longitude ? seller.longitude : maxLng;
    }

    final customerLat = widget.order.customer.lat;
    final customerLng = widget.order.customer.lng;
    minLat = minLat > customerLat ? customerLat : minLat;
    maxLat = maxLat < customerLat ? customerLat : maxLat;
    minLng = minLng > customerLng ? customerLng : minLng;
    maxLng = maxLng < customerLng ? customerLng : maxLng;

    // Add padding (0.003 degrees ≈ 300 meters) for better visibility
    const double padding = 0.00001; 
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
            // Add slight delay to ensure map is rendered
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                final bounds = _getMapBounds();
                mapController.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    bounds,
                    120, // Increased padding for better marker visibility
                  ),
                );
              }
            });
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.order.driver.latitude,
              widget.order.driver.longitude,
            ),
            zoom: 14,
          ),
          style: _mapStyle,
          markers: markers,
          polylines: polylines,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
