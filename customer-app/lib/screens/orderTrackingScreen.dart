import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/groupedByStore.dart';
import 'package:project/models/rating.dart' as rm;
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/models/deliveryBoyOrder.dart';
import 'package:project/provider/orderTrackingProvider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/services/googleRoutesApiService.dart';
import 'package:project/provider/chatProvider.dart';
import 'package:project/screens/customerSupportScreen/customerSupportChatScreen.dart';
import 'package:project/repositories/ordersApi.dart';
import 'package:project/screens/orderChatScreen.dart';
// import 'package:project/screens/turnByTurnNavigationScreen.dart';

class PromotionalBanner {
  final int id;
  final String? storeId;
  final String type;
  final String typeId;
  final String image;
  final String? sliderUrl;
  final int status;
  final String createdAt;
  final String updatedAt;
  final String typeName;
  final String imageUrl;

  PromotionalBanner({
    required this.id,
    this.storeId,
    required this.type,
    required this.typeId,
    required this.image,
    this.sliderUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.typeName,
    required this.imageUrl,
  });

  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    return PromotionalBanner(
      id: json['id'] ?? 0,
      storeId: json['store_id']?.toString(),
      type: json['type'] ?? '',
      typeId: json['type_id']?.toString() ?? '',
      image: json['image'] ?? '',
      sliderUrl: json['slider_url']?.toString(),
      status: json['status'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      typeName: json['type_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;

  const OrderTrackingScreen({Key? key, this.orderId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  late AnimationController _refreshAnimationController;
  Order? _currentOrder;
  bool _isLoading = true;
  bool _isRefreshing = false; // Track if manual refresh is in progress
  bool _isUpdatingMarkers = false; // Prevent concurrent marker updates

  // Promotional banners
  List<PromotionalBanner> _promotionalBanners = [];
  bool _isLoadingBanners = false;
  late PageController _bannerController;
  Timer? _autoScrollTimer;
  int _currentBannerIndex = 0;

  // Map markers
  Set<Marker> _markers = {};

  // Map polylines
  Set<Polyline> _polylines = {};

  // User location (from order address)
  LatLng? _userLocation;

  // Delivery person location (latest position received from Firebase)
  LatLng? _deliveryLocation;

  // ===== Smooth driver marker movement =====
  // The driver app pushes its location every 30 seconds, so the raw position
  // arrives in jumps. We interpolate between the last drawn position and the
  // new one so the marker glides instead of teleporting.
  LatLng? _renderedDeliveryLocation; // position actually drawn on the map
  LatLng? _markerAnimFrom;
  LatLng? _markerAnimTo;
  Timer? _markerAnimTimer;
  int _markerAnimElapsedMs = 0;
  double _driverBearing = 0; // heading of travel, used to rotate the marker
  static const int _markerAnimDurationMs = 4000; // glide over 4s
  static const int _markerAnimTickMs = 50; // ~20 fps
  static const double _markerTeleportThresholdMeters =
      3000; // GPS re-acquire / order switch - snap instead of gliding

  // Cached route so we don't hit the Routes API on every location push
  List<LatLng>? _cachedRoutePoints;
  LatLng? _cachedRouteOrigin;
  LatLng? _cachedRouteTarget;
  static const double _routeRefreshDistanceMeters = 200;

  // Camera re-fit throttle
  LatLng? _lastCameraFitDriverPosition;
  static const double _cameraRefitDistanceMeters = 150;

  // Map style
  String? _mapStyle;

  // Custom marker icons
  BitmapDescriptor? _userMarkerIcon;
  BitmapDescriptor? _deliveryMarkerIcon;

  // Route duration (real-time from Routes API)
  String _routeDuration = '';

  // Status 1 countdown timer
  Timer? _countdownTimer;
  int _countdownSeconds = 900; // 15 minutes in seconds
  DateTime? _orderPlacedTime;

  // ETA Firebase subscription
  StreamSubscription? _etaSubscription;
  int? _etaMinutes; // ETA in minutes from stored_at
  DateTime?
      _etaTargetTime; // Calculated target completion time (stored_at + eta minutes)
  int _displayedEtaSeconds = 0; // Smooth countdown display
  Timer? _etaCountdownTimer; // Separate timer for smooth ETA countdown
  int? _lastEtaValue; // Track last ETA value to detect changes

  // Firebase status from order_eta collection
  String?
      _firebaseOrderStatus; // Status text from Firebase (e.g., "Your order was placed")
  String? _firebaseOrderStatusDesc; // Status description from Firebase

  // Firebase driver status from order_eta collection (takes priority over regular status)
  String? _firebaseDriverOrderStatus; // Driver status text from Firebase
  String?
      _firebaseDriverOrderStatusDesc; // Driver status description from Firebase

  // Firebase order preparation flag
  bool _isPreparation = false; // Order is in preparation stage

  // Firebase order checkout flag
  bool _showCheckoutFromFirebase =
      false; // Show checkout button from Firebase flag

  // Initialization tracking to prevent redundant operations
  bool _isFirebaseInitialized = false;
  String? _lastInitializedOrderId;
  String? _lastInitializedDeliveryBoyId;
  DateTime? _lastApiCallTime;
  static const Duration _minApiCallInterval = Duration(seconds: 3);

  // Cancel order loading state
  bool _isCancellingOrder = false;

  // Checkout state (when delivery in final step)
  bool _isCheckoutCompleted = false;

  // Rating state
  rm.RatingModel? _ratingModel;
  rm.RatingData? _ratingData;
  int _driverRating = 0;
  // When true, the Delivered screen swaps its bottom-sheet content to show
  // only the rating cards (and the bottom action becomes a single
  // "Back to Home" button). Toggled by the "Give Ratings" CTA.
  bool _showRatingsPage = false;
  final TextEditingController _driverReviewController = TextEditingController();
  bool _driverSubmitting = false;
  Map<int, int> _productRatings = {}; // productId -> rating
  Map<int, bool> _productSubmitting = {}; // productId -> submitting

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize refresh animation controller
    _refreshAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Initialize banner controller
    _bannerController = PageController();

    _createCustomMarkers();
    // Load order details after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
      _loadPromotionalBanners();
      // Fetch weather data to check for rain
      context.read<HomeScreenProvider>().fetchWeatherData(context);
    });
    // Auto-refresh markers every 2 seconds when Firebase is active
    // This ensures markers update with real-time Firebase data (driver location, status changes)
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        final trackingProvider = context.read<OrderTrackingProvider>();
        final isFirebaseActive = trackingProvider.isFirebaseActive;

        if (isFirebaseActive) {
          // Firebase is active - update markers to show latest driver location and delivery status
          debugPrint(
              '🔄 [OrderTracking] Firebase active, updating markers with latest data');
          _updateMapMarkers();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMapStyle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came back from background/screen lock
      // Use provider's refresh method which refreshes API data and restarts Firebase
      context.read<OrderTrackingProvider>().refreshTracking(context: context);
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      // Get current theme mode
      final themeProvider = context.read<app_theme.ThemeProvider>();
      final isDark = themeProvider.themeMode == app_theme.ThemeMode.dark ||
          (themeProvider.themeMode == app_theme.ThemeMode.system &&
              MediaQuery.of(context).platformBrightness == Brightness.dark);

      // Load appropriate map style
      _mapStyle = await rootBundle.loadString(isDark
          ? 'assets/mapTheme/nightMode.json'
          : 'assets/mapTheme/dayMode.json');
    } catch (e) {
      log('Error loading map style: $e');
      _mapStyle = null; // Fallback to default map style
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    try {
      // Map style is now applied via the GoogleMap widget's style property
      // Animate camera to show all markers after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _animateToBounds();
    } catch (e) {
      log('Error in _onMapCreated: $e');
    }
  }

  Future<void> _createCustomMarkers() async {
    try {
      final themeProvider = context.read<app_theme.ThemeProvider>();
      final colorScheme = themeProvider.colorScheme;

      // Create custom user location marker (home icon with theme colors)
      _userMarkerIcon = await _createCustomUserMarker(colorScheme);
      // Create custom delivery person marker (delivery icon with theme colors)
      _deliveryMarkerIcon = await _createCustomDeliveryMarker(colorScheme);
    } catch (e) {
      log('Error creating custom markers: $e');
      // Markers will use default icons if creation fails
    }
  }

  Future<BitmapDescriptor> _createCustomUserMarker(
      AppColorScheme colorScheme) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 150.0; // Significantly reduced to prevent cutoff
    const cardWidth = 85.0; // Much smaller width
    const cardHeight = 36.0; // Compact height
    const circleRadius = 15.0; // Smaller pin circle
    const cardTop = 8.0;
    const pinTop = cardTop + cardHeight + 10.0; // Pin below the card
    const cardLeft = size / 3; // Very close to the pin

    final pinCenterX = size / 2;
    final pinCenterY = pinTop + circleRadius;

    // Draw info card (positioned to the right)
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight),
      const Radius.circular(10),
    );

    // Card shadow
    final cardShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
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
    final address = _currentOrder?.orderAddress ??
        getTranslatedValue(context, 'delivery_address_fallback');

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
        text: getTranslatedValue(context, 'delivery_to_label'),
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
    pinPath.moveTo(pinCenterX - 6, pinCenterY + circleRadius - 2); // Left point
    pinPath.lineTo(
        pinCenterX + 6, pinCenterY + circleRadius - 2); // Right point
    pinPath.lineTo(pinCenterX,
        pinCenterY + circleRadius + 14); // Bottom point (exact location)
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
    roofPath.moveTo(pinCenterX, pinCenterY - 5); // Top point
    roofPath.lineTo(pinCenterX - 6, pinCenterY + 1); // Bottom left
    roofPath.lineTo(pinCenterX + 6, pinCenterY + 1); // Bottom right
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

  Future<BitmapDescriptor> _createCustomDeliveryMarker(
      AppColorScheme colorScheme) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 80.0; // Compact size for just the bike icon
    const iconSize = 64.0; // Size of the bike image
    const centerX = size / 2;
    const centerY = size / 2;

    // Draw shadow under the bike
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowPath = Path();
    shadowPath.moveTo(centerX - 8, centerY + iconSize / 2 + 8);
    shadowPath.lineTo(centerX + 8, centerY + iconSize / 2 + 8);
    shadowPath.lineTo(centerX, centerY + iconSize / 2 + 2);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw delivery bike icon from asset image
    try {
      final byteData = await rootBundle.load('assets/images/bike_map.png');
      final codec =
          await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Center the bike icon
      final bikeIconRect = Rect.fromLTWH(
        (size - iconSize) / 2,
        (size - iconSize) / 2,
        iconSize,
        iconSize,
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bikeIconRect,
        Paint(),
      );
    } catch (e) {
      // Fallback: Draw simplified motorcycle if image loading fails
      final deliveryIconPaint = Paint()
        ..color = colorScheme.info
        ..style = PaintingStyle.fill;

      // Motorcycle wheels
      canvas.drawCircle(
        Offset(centerX - 12, centerY + 4),
        4,
        deliveryIconPaint,
      );
      canvas.drawCircle(
        Offset(centerX + 12, centerY + 4),
        4,
        deliveryIconPaint,
      );
      // Motorcycle body
      canvas.drawRect(
        Rect.fromLTWH(centerX - 8, centerY - 10, 16, 8),
        deliveryIconPaint,
      );
      // Delivery box
      canvas.drawRect(
        Rect.fromLTWH(centerX - 6, centerY - 12, 12, 6),
        Paint()
          ..color = colorScheme.info
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(buffer);
  }

  Future<BitmapDescriptor> _createCustomSellerMarker(AppColorScheme colorScheme,
      {String sellerName = 'Seller'}) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 150.0; // Match other markers
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
      const Radius.circular(10),
    );

    // Card shadow
    final cardShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(cardRect, cardShadowPaint);

    // Card background
    final cardBgPaint = Paint()..color = colorScheme.surface;
    canvas.drawRRect(cardRect, cardBgPaint);

    // Card border
    final cardBorderPaint = Paint()
      ..color = colorScheme.warning.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cardRect, cardBorderPaint);

    // Icon background (smaller)
    final iconBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft + 6, cardTop + 6, 18, 18),
      const Radius.circular(4),
    );
    final iconBgPaint = Paint()
      ..color = colorScheme.warning.withValues(alpha: 0.15);
    canvas.drawRRect(iconBgRect, iconBgPaint);

    // Draw shopping bag icon in card
    final cardIconPaint = Paint()
      ..color = colorScheme.warning
      ..style = PaintingStyle.fill;
    final iconCenterX = cardLeft + 15;
    final iconCenterY = cardTop + 15;

    // Shopping bag body
    final bagPath = Path();
    bagPath.moveTo(iconCenterX - 3.5, iconCenterY - 1);
    bagPath.lineTo(iconCenterX - 4, iconCenterY + 4);
    bagPath.lineTo(iconCenterX + 4, iconCenterY + 4);
    bagPath.lineTo(iconCenterX + 3.5, iconCenterY - 1);
    bagPath.close();
    canvas.drawPath(bagPath, cardIconPaint);

    // Shopping bag handle
    final handlePaint = Paint()
      ..color = colorScheme.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final handlePath = Path();
    handlePath.moveTo(iconCenterX - 2, iconCenterY - 1);
    handlePath.quadraticBezierTo(
        iconCenterX, iconCenterY - 4, iconCenterX + 2, iconCenterY - 1);
    canvas.drawPath(handlePath, handlePaint);

    // Draw "Preparing at" label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: getTranslatedValue(context, 'preparing_at_label'),
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

    // Draw seller name
    final namePainter = TextPainter(
      text: TextSpan(
        text: sellerName.length > 10
            ? '${sellerName.substring(0, 9)}...'
            : sellerName,
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

    // Draw white circle background
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      circlePaint,
    );

    // Draw warning color border
    final borderPaint = Paint()
      ..color = colorScheme.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      borderPaint,
    );

    // Draw pin pointer (triangle at bottom)
    final pinPaint = Paint()
      ..color = colorScheme.warning
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

    // Draw shopping bag icon in pin
    final pinBagPaint = Paint()
      ..color = colorScheme.warning
      ..style = PaintingStyle.fill;

    // Shopping bag body (larger for pin)
    final pinBagPath = Path();
    pinBagPath.moveTo(pinCenterX - 6, pinCenterY - 4);
    pinBagPath.lineTo(pinCenterX - 7, pinCenterY + 6);
    pinBagPath.lineTo(pinCenterX + 7, pinCenterY + 6);
    pinBagPath.lineTo(pinCenterX + 6, pinCenterY - 4);
    pinBagPath.close();
    canvas.drawPath(pinBagPath, pinBagPaint);

    // Shopping bag handle (larger for pin)
    final pinHandlePaint = Paint()
      ..color = colorScheme.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final pinHandlePath = Path();
    pinHandlePath.moveTo(pinCenterX - 4, pinCenterY - 4);
    pinHandlePath.quadraticBezierTo(
        pinCenterX, pinCenterY - 10, pinCenterX + 4, pinCenterY - 4);
    canvas.drawPath(pinHandlePath, pinHandlePaint);

    // White accent on bag
    final bagAccentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final bagAccentRect = Rect.fromLTWH(
      pinCenterX - 3,
      pinCenterY + 1,
      6,
      3,
    );
    canvas.drawRect(bagAccentRect, bagAccentPaint);

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(buffer);
  }

  Future<BitmapDescriptor> _createCustomCustomerMarker(
      AppColorScheme colorScheme,
      {String? addressLine}) async {
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
      const Radius.circular(10),
    );

    // Card shadow
    final cardShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(cardRect, cardShadowPaint);

    // Card background
    final cardBgPaint = Paint()..color = colorScheme.surface;
    canvas.drawRRect(cardRect, cardBgPaint);

    // Card border
    final cardBorderPaint = Paint()
      ..color = colorScheme.success.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(cardRect, cardBorderPaint);

    // Icon background (smaller)
    final iconBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cardLeft + 6, cardTop + 6, 18, 18),
      const Radius.circular(4),
    );
    final iconBgPaint = Paint()
      ..color = colorScheme.success.withValues(alpha: 0.15);
    canvas.drawRRect(iconBgRect, iconBgPaint);

    // Draw home/destination icon in card
    final cardIconPaint = Paint()
      ..color = colorScheme.success
      ..style = PaintingStyle.fill;
    final iconCenterX = cardLeft + 15;
    final iconCenterY = cardTop + 15;

    // Home icon (house shape)
    final housePath = Path();
    housePath.moveTo(iconCenterX - 4, iconCenterY + 1);
    housePath.lineTo(iconCenterX - 4, iconCenterY + 4);
    housePath.lineTo(iconCenterX + 4, iconCenterY + 4);
    housePath.lineTo(iconCenterX + 4, iconCenterY + 1);
    housePath.lineTo(iconCenterX, iconCenterY - 2);
    housePath.close();
    canvas.drawPath(housePath, cardIconPaint);

    // Door
    final doorPaint = Paint()
      ..color = colorScheme.success.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(iconCenterX - 1, iconCenterY + 1.5, 2, 2.5),
      doorPaint,
    );

    // Draw "Delivery to" label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: getTranslatedValue(context, 'delivery_to_label'),
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

    // Show the actual delivery address on the marker (truncated to fit the
    // small map card). Falls back to a generic label when no address is set.
    final String markerText = (addressLine != null && addressLine.trim().isNotEmpty)
        ? addressLine.trim()
        : 'Your Address';
    final namePainter = TextPainter(
      text: TextSpan(
        text: markerText,
        style: GoogleFonts.inter(
          color: colorScheme.textPrimary,
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
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

    // Draw white circle background
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      circlePaint,
    );

    // Draw success color border
    final borderPaint = Paint()
      ..color = colorScheme.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      circleRadius,
      borderPaint,
    );

    // Draw pin pointer (triangle at bottom)
    final pinPaint = Paint()
      ..color = colorScheme.success
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

    // Draw home icon in pin
    final pinHomePaint = Paint()
      ..color = colorScheme.success
      ..style = PaintingStyle.fill;

    // Home icon body (larger for pin)
    final pinHousePath = Path();
    pinHousePath.moveTo(pinCenterX - 6, pinCenterY - 2);
    pinHousePath.lineTo(pinCenterX - 6, pinCenterY + 6);
    pinHousePath.lineTo(pinCenterX + 6, pinCenterY + 6);
    pinHousePath.lineTo(pinCenterX + 6, pinCenterY - 2);
    pinHousePath.lineTo(pinCenterX, pinCenterY - 6);
    pinHousePath.close();
    canvas.drawPath(pinHousePath, pinHomePaint);

    // White accent on house
    final houseAccentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(pinCenterX - 2, pinCenterY + 1, 4, 4),
      houseAccentPaint,
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(buffer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _etaCountdownTimer?.cancel();
    _etaSubscription?.cancel();
    _refreshAnimationController.dispose();
    _bannerController.dispose();
    _autoScrollTimer?.cancel();
    _markerAnimTimer?.cancel();
    // Firebase subscription cleanup is now handled by OrderTrackingProvider.dispose()
    _mapController?.dispose();
    _driverReviewController.dispose();
    super.dispose();
  }

  /// Refresh order data from API when Firebase status updates
  /// This fetches fresh order details including OTP, checkout buttons, etc.
  Future<void> _refreshOrderDataFromAPI() async {
    try {
      debugPrint('🔄 [API Refresh] Starting API call to refresh order data');

      if (!mounted || widget.orderId == null) {
        debugPrint('❌ [API Refresh] Widget not mounted or orderId is null');
        return;
      }

      final params = {
        ApiAndParams.orderId: widget.orderId!,
      };

      final orderData =
          await context.read<CurrentOrderProvider>().getCurrentOrder(
                params: params,
                context: context,
              );

      if (orderData != null && mounted) {
        debugPrint('✅ [API Refresh] Successfully fetched fresh order data');
        debugPrint(
            '✅ [API Refresh] Order status: ${orderData.activeStatus}, Items: ${orderData.items?.length}');

        setState(() {
          _currentOrder = orderData;
        });

        // Update any UI that depends on order data (OTP, buttons, etc.)
        debugPrint('✅ [API Refresh] Updated UI with fresh order data');
      } else {
        debugPrint('❌ [API Refresh] Failed to fetch order data');
      }
    } catch (e) {
      debugPrint('❌ [API Refresh] Error refreshing order data: $e');
    }
  }


  void _startCountdownTimer(Order order) {
    // Stop any existing countdown timer
    _countdownTimer?.cancel();

    // Set the order placed time
    _orderPlacedTime = DateTime.now();
    _countdownSeconds = 900; // 15 minutes

    // Start countdown timer that updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdownSeconds--;
      });

      // Stop timer when countdown reaches 0
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _countdownTimer = null;
      }
    });
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownSeconds = 900;
    _orderPlacedTime = null;
  }

  String _formatCountdownTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startEtaFirebaseSubscription(String orderId) {
    // Skip if already subscribed to the same order
    if (_etaSubscription != null && _lastInitializedOrderId == orderId) {
      debugPrint('📡 [ETA] Already subscribed to order: $orderId, skipping');
      return;
    }

    // Cancel any existing ETA subscription
    _etaSubscription?.cancel();
    _lastInitializedOrderId = orderId;

    debugPrint('📡 [ETA] Starting Firebase subscription for order: $orderId');

    try {
      // Listen to order_eta collection for this specific order
      _etaSubscription = FirebaseFirestore.instance
          .collection('order_eta')
          .doc(orderId)
          .snapshots()
          .listen(
        (snapshot) {
          if (!mounted) return;

          debugPrint('📡 [ETA] Firebase snapshot received for order: $orderId');

          try {
            if (snapshot.exists) {
              final data = snapshot.data();
              debugPrint('📡 [ETA] Firebase data: $data');

              // Extract ETA data from Firebase
              final eta = data?['eta']; // ETA in minutes
              final storedAt = data?['stored_at']; // Order placement time
              final updatedAt = data?['updated_at']; // Latest update timestamp
              final delayedTime =
                  data?['delayed_time']; // Can be null or a value
              final orderStatus =
                  data?['order_status']; // Status text from Firebase
              final orderStatusDesc = data?[
                  'order_status_desc']; // Status description from Firebase
              final driverOrderStatus = data?[
                  'driver_order_status']; // Driver status text from Firebase
              final driverOrderStatusDesc = data?[
                  'driver_order_status_desc']; // Driver status description from Firebase
              final currentOrder = data?['current_order'];
              final isDelivered =
                  data?['is_delivered']; // Check if order is delivered
              final isPreparation =
                  data?['is_preparation']; // Check if order is in preparation
              final isCheckout = data?[
                  'is_checkout']; // Check if checkout button should be shown

              debugPrint(
                  '📡 [ETA] ETA: $eta, StoredAt: $storedAt, UpdatedAt: $updatedAt, DelayedTime: $delayedTime, OrderStatus: $orderStatus, OrderStatusDesc: $orderStatusDesc, DriverOrderStatus: $driverOrderStatus, DriverOrderStatusDesc: $driverOrderStatusDesc, CurrentOrder: $currentOrder, IsDelivered: $isDelivered, IsPreparation: $isPreparation, IsCheckout: $isCheckout');

              // Check if order is cancelled from Firebase
              final isCancelled = data?['is_cancelled'];
              if (isCancelled == 1 ||
                  isCancelled == "1" ||
                  isCancelled == true) {
                debugPrint(
                    '❌ [Firebase] Order is_cancelled flag set to 1, showing cancelled state');
                _stopEtaSubscription();
                _stopCountdownTimer();

                // Update order status to 7 (cancelled) to trigger _buildCancelledState()
                if (mounted && _currentOrder != null) {
                  setState(() {
                    _currentOrder!.activeStatus = '7';
                  });
                  debugPrint(
                      '❌ [Firebase] activeStatus updated to 7, triggering _buildCancelledState()');
                }
                return; // Exit early to prevent further processing
              }

              // Check if order is delivered from Firebase
              if (isDelivered == 1 ||
                  isDelivered == "1" ||
                  isDelivered == true) {
                debugPrint(
                    '✅ [Firebase] Order is_delivered flag set to 1, showing delivered state');
                _stopEtaSubscription();
                _stopCountdownTimer();

                // Update order status to 6 (delivered) to trigger _buildDeliveredState()
                if (mounted && _currentOrder != null) {
                  setState(() {
                    _currentOrder!.activeStatus = '6';
                  });
                  debugPrint(
                      '✅ [Firebase] activeStatus updated to 6, triggering _buildDeliveredState()');
                }
                return; // Exit early to prevent further processing
              }

              // Update preparation flag from Firebase
              if (isPreparation == 1 ||
                  isPreparation == "1" ||
                  isPreparation == true) {
                debugPrint(
                    '👨‍🍳 [Firebase] Order is in preparation, hiding cancel button');
                if (mounted) {
                  setState(() {
                    _isPreparation = true;
                  });
                }
              } else {
                if (mounted && _isPreparation) {
                  setState(() {
                    _isPreparation = false;
                  });
                }
              }

              // Update checkout flag from Firebase
              if (isCheckout == 1 || isCheckout == "1" || isCheckout == true) {
                debugPrint(
                    '💳 [Firebase] is_checkout flag set to 1, showing checkout button');
                if (mounted) {
                  setState(() {
                    _showCheckoutFromFirebase = true;
                  });
                }
              } else {
                if (mounted && _showCheckoutFromFirebase) {
                  setState(() {
                    _showCheckoutFromFirebase = false;
                  });
                }
              }

              // Continue showing ETA even if delivery boy not assigned yet
              if (eta != null && storedAt != null) {
                // Parse the stored_at timestamp
                DateTime orderTime;
                try {
                  if (storedAt is Timestamp) {
                    orderTime = storedAt.toDate();
                  } else if (storedAt is String) {
                    // Handle different date formats
                    if (storedAt.contains(':') &&
                        (storedAt.contains('PM') || storedAt.contains('AM'))) {
                      // Time-only format like "03:27 PM"
                      // Use updated_at date if available, otherwise use today's date
                      DateTime referenceDate;

                      if (updatedAt != null) {
                        // Use the date from updated_at for accurate date context
                        if (updatedAt is Timestamp) {
                          referenceDate = updatedAt.toDate();
                        } else if (updatedAt is String) {
                          referenceDate = DateTime.parse(updatedAt);
                        } else {
                          referenceDate = DateTime.now();
                        }
                      } else {
                        referenceDate = DateTime.now();
                      }

                      final timeLower = storedAt.toLowerCase();
                      final isPM = timeLower.contains('pm');

                      // Remove AM/PM and extra spaces
                      final cleanTime = storedAt
                          .replaceAll(' PM', '')
                          .replaceAll(' AM', '')
                          .replaceAll(' pm', '')
                          .replaceAll(' am', '');

                      final timeSplit = cleanTime.split(':');
                      int hour = int.parse(timeSplit[0]);
                      final minute = int.parse(timeSplit[1]);

                      // Convert to 24-hour format
                      if (isPM && hour != 12) {
                        hour += 12;
                      } else if (!isPM && hour == 12) {
                        hour = 0;
                      }

                      orderTime = DateTime(referenceDate.year,
                          referenceDate.month, referenceDate.day, hour, minute);
                      debugPrint(
                          '📡 [ETA] Parsed time format: $storedAt -> $orderTime (using date from updatedAt)');
                    } else {
                      // Full ISO format
                      orderTime = DateTime.parse(storedAt);
                    }
                  } else {
                    debugPrint(
                        '❌ [ETA] Unknown storedAt type: ${storedAt.runtimeType}');
                    return;
                  }
                } catch (parseError) {
                  debugPrint(
                      '❌ [ETA] Error parsing storedAt: $parseError, value: $storedAt');
                  return;
                }

                final newEta = eta as int;

                // Compute statusChanged BEFORE setState updates the tracked values
                final statusChanged = (orderStatus != null &&
                        orderStatus != _firebaseOrderStatus) ||
                    (driverOrderStatus != null &&
                        driverOrderStatus != _firebaseDriverOrderStatus);

                // Update Firebase status texts on every update (outside ETA change check)
                setState(() {
                  // Update driver status (takes priority)
                  if (driverOrderStatus != null) {
                    _firebaseDriverOrderStatus = driverOrderStatus as String;
                  }
                  if (driverOrderStatusDesc != null) {
                    _firebaseDriverOrderStatusDesc =
                        driverOrderStatusDesc as String;
                  }

                  // Update regular order status
                  if (orderStatus != null) {
                    _firebaseOrderStatus = orderStatus as String;
                  }
                  if (orderStatusDesc != null) {
                    _firebaseOrderStatusDesc = orderStatusDesc as String;

                    // Check is_delivered flag from Firebase
                    if (isDelivered == 1 ||
                        isDelivered == "1" ||
                        isDelivered == true) {
                      debugPrint(
                          '✅ [Firebase] is_delivered flag = 1, Order delivered! Updating activeStatus to 6');
                      // Update order status to delivered
                      if (_currentOrder != null) {
                        _currentOrder!.activeStatus = '6';
                      }
                      // Stop all timers and subscriptions
                      _stopEtaSubscription();
                      _stopCountdownTimer();
                    }
                  }
                });

                // Call API once if status actually changed (e.g. driver accepted)
                if (mounted && widget.orderId != null && statusChanged) {
                  debugPrint(
                      '📡 [Firebase Status Update] Status changed, refreshing order data from API');
                  _refreshOrderDataFromAPI();
                }

                // Only recalculate if ETA value actually changed
                if (_lastEtaValue != newEta) {
                  debugPrint(
                      '📡 [ETA] ETA changed from $_lastEtaValue to $newEta minutes');
                  _lastEtaValue = newEta;

                  // Calculate target completion time: stored_at + eta minutes
                  final targetTime = orderTime.add(Duration(minutes: newEta));

                  setState(() {
                    _etaMinutes = newEta;
                    _etaTargetTime = targetTime;

                    // Calculate seconds remaining from now to target time
                    final now = DateTime.now();
                    final secondsRemaining =
                        targetTime.difference(now).inSeconds;

                    // Apply ±5 min buffer to the remaining time
                    _displayedEtaSeconds = secondsRemaining;

                    debugPrint(
                        '📡 [ETA] Target time: $targetTime, Seconds remaining: $secondsRemaining');
                  });

                  // Only restart countdown timer if ETA changed significantly
                  // Don't restart on every Firebase update (independence)
                  if (_etaCountdownTimer == null) {
                    debugPrint('📡 [ETA] Starting new countdown timer');
                    _startEtaCountdown();
                  } else {
                    debugPrint(
                        '📡 [ETA] Countdown timer already running, updating target time only');
                  }
                } else {
                  debugPrint(
                      '📡 [ETA] ETA value unchanged, countdown continues independently');
                }
              }
            }
          } catch (e) {
            debugPrint('❌ [ETA] Error processing Firebase ETA data: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ [ETA] Firebase subscription error: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ [ETA] Failed to start Firebase subscription: $e');
    }
  }

  void _startEtaCountdown() {
    // Cancel any existing countdown
    _etaCountdownTimer?.cancel();

    // Update every second for smooth countdown
    _etaCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_displayedEtaSeconds > 0) {
          _displayedEtaSeconds--;
        } else {
          // Stop timer when ETA reaches 0
          timer.cancel();
        }
      });
    });
  }

  void _stopEtaSubscription() {
    _etaSubscription?.cancel();
    _etaSubscription = null;
    _etaCountdownTimer?.cancel();
    _etaCountdownTimer = null;
    _etaMinutes = null;
    _etaTargetTime = null;
    _lastEtaValue = null;
    _displayedEtaSeconds = 0;
  }

  String _formatEtaTime(int seconds) {
    if (seconds <= 0) return '00:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _drawDeliveryRouteArc() {
    // Draw an arc route from seller location to customer location
    if (_userLocation == null || _currentOrder == null) return;

    // Get seller location from first order item
    google_maps.LatLng? sellerLocation;
    String? sellerName;
    if (_currentOrder!.items != null && _currentOrder!.items!.isNotEmpty) {
      final firstItem = _currentOrder!.items![0];
      if (firstItem.sellerLatitude != null &&
          firstItem.sellerLongitude != null &&
          firstItem.sellerLatitude!.isNotEmpty &&
          firstItem.sellerLongitude!.isNotEmpty) {
        try {
          final sellerLat = double.parse(firstItem.sellerLatitude!);
          final sellerLng = double.parse(firstItem.sellerLongitude!);
          sellerLocation = google_maps.LatLng(sellerLat, sellerLng);
          sellerName = firstItem.sellerName;
          debugPrint('✅ [OrderTracking] Seller location: $sellerLocation');
        } catch (e) {
          debugPrint('❌ [OrderTracking] Failed to parse seller location: $e');
        }
      }
    }

    // Get customer location (order address coordinates)
    final customerLocation = _userLocation!;

    // Determine start point: seller location if available, else delivery location
    final startPoint = sellerLocation ?? _deliveryLocation ?? customerLocation;
    final endPoint = customerLocation;

    // Only draw if we have valid start and end points
    if (startPoint == endPoint) return;

    // Create polyline points for the arc
    List<google_maps.LatLng> arcPoints =
        _generateArcPoints(startPoint, endPoint);

    setState(() {
      // Clear delivery boy and driver related markers for delivered state
      // Only keep seller and customer markers
      _markers.removeWhere((marker) =>
          marker.markerId.value.contains('driver') ||
          marker.markerId.value.contains('delivery_boy') ||
          marker.markerId.value.contains('user_location') ||
          marker.markerId.value.contains('seller_') ||
          marker.markerId.value.contains('target_'));

      // Clear all polylines except delivery route
      _polylines.removeWhere(
          (polyline) => polyline.polylineId.value != 'delivery_route_arc');

      // Add the route arc polyline
      _polylines.add(
        google_maps.Polyline(
          polylineId: google_maps.PolylineId('delivery_route_arc'),
          points: arcPoints,
          color: const Color(0xFF9AC444),
          width: 4,
          geodesic: true,
          zIndex: 2,
        ),
      );

      // Add seller marker if we have seller location
      if (sellerLocation != null) {
        _markers.add(
          google_maps.Marker(
            markerId: const google_maps.MarkerId('seller_location'),
            position: sellerLocation,
            infoWindow: google_maps.InfoWindow(
              title: sellerName ?? 'Seller',
              snippet: 'Order picked from here',
            ),
          ),
        );
      }

      // Add customer marker
      _markers.add(
        google_maps.Marker(
          markerId: const google_maps.MarkerId('customer_location'),
          position: customerLocation,
          infoWindow: const google_maps.InfoWindow(
            title: 'Delivery Address',
            snippet: 'Order delivered here',
          ),
        ),
      );

      debugPrint(
          '✅ [OrderTracking] Delivered state map: Showing only seller → customer route');
    });

    // Animate camera to fit both seller and customer locations
    _animateCameraToFitBounds(startPoint, endPoint);
  }

  Future<void> _animateCameraToFitBounds(
      google_maps.LatLng sellerLoc, google_maps.LatLng customerLoc) async {
    if (_mapController == null) return;

    try {
      // Calculate bounds that include both locations
      final northeastLat = sellerLoc.latitude > customerLoc.latitude
          ? sellerLoc.latitude
          : customerLoc.latitude;
      final northeastLng = sellerLoc.longitude > customerLoc.longitude
          ? sellerLoc.longitude
          : customerLoc.longitude;
      final southwestLat = sellerLoc.latitude < customerLoc.latitude
          ? sellerLoc.latitude
          : customerLoc.latitude;
      final southwestLng = sellerLoc.longitude < customerLoc.longitude
          ? sellerLoc.longitude
          : customerLoc.longitude;

      // Create bounds with padding
      final bounds = google_maps.LatLngBounds(
        northeast: google_maps.LatLng(northeastLat, northeastLng),
        southwest: google_maps.LatLng(southwestLat, southwestLng),
      );

      // Animate camera to fit bounds with padding (200px padding on all sides)
      final cameraUpdate =
          google_maps.CameraUpdate.newLatLngBounds(bounds, 200);
      _mapController!.animateCamera(cameraUpdate);

      debugPrint(
          '✅ [OrderTracking] Camera animated to fit seller and customer bounds');
    } catch (e) {
      debugPrint('❌ [OrderTracking] Failed to animate camera to bounds: $e');
    }
  }

  List<google_maps.LatLng> _generateArcPoints(
    google_maps.LatLng start,
    google_maps.LatLng end,
  ) {
    const int steps = 50;
    List<google_maps.LatLng> points = [];

    for (int i = 0; i <= steps; i++) {
      final fraction = i / steps;

      // Interpolate latitude and longitude
      final lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final lng =
          start.longitude + (end.longitude - start.longitude) * fraction;

      // Add arc curvature using sine function
      final arcHeight = 0.01 * math.sin(fraction * math.pi);
      final curvedLat = lat + arcHeight;

      points.add(google_maps.LatLng(curvedLat, lng));
    }

    return points;
  }

  Future<void> _onRefreshPressed() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    setState(() {
      _isRefreshing = true;
    });

    // Start the refresh animation (360 degree rotation)
    _refreshAnimationController.repeat();

    try {
      // Fetch latest order details
      await _loadOrderDetails(isRefresh: true);

      // Show success message
      if (mounted) {
        showMessage(
          context,
          'Refreshed Successfully!',
          MessageType.success,
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        showMessage(
          context,
          'Failed to refresh: ${e.toString()}',
          MessageType.error,
        );
      }
    } finally {
      if (mounted) {
        // Stop animation after refresh completes
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();

        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadPromotionalBanners() async {
    if (!mounted) return;

    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final response = await orderTrackingBanners(context: context);

      if (response['status'] == 1 && response['data'] != null) {
        if (!mounted) return;
        setState(() {
          _promotionalBanners = (response['data'] as List)
              .map((item) => PromotionalBanner.fromJson(item))
              .where((banner) => banner.type == 'order_page')
              .toList();
          _isLoadingBanners = false;
        });

        // Start auto-scrolling if there are multiple banners
        _startAutoScroll();
      } else {
        if (!mounted) return;
        setState(() {
          _promotionalBanners = [];
          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      log('Error loading promotional banners: $e');
      if (!mounted) return;
      setState(() {
        _promotionalBanners = [];
        _isLoadingBanners = false;
      });
    }
  }

  void _startAutoScroll() {
    if (_promotionalBanners.length <= 1) return;

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerController.hasClients && mounted) {
        final nextPage = _currentBannerIndex + 1;
        if (nextPage >= _promotionalBanners.length) {
          _currentBannerIndex = 0;
          _bannerController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _currentBannerIndex = nextPage;
          _bannerController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

        // Update UI to show current page indicator
        setState(() {});
      }
    });
  }

  Future<void> _loadOrderDetails({bool isRefresh = false}) async {
    if (widget.orderId == null || !mounted) return;

    // Prevent excessive API calls - skip if called too frequently during polling
    if (!isRefresh && _lastApiCallTime != null) {
      final timeSinceLastCall = DateTime.now().difference(_lastApiCallTime!);
      if (timeSinceLastCall < _minApiCallInterval) {
        debugPrint(
            '⏭️ [OrderTracking] Skipping API call - too soon (${timeSinceLastCall.inMilliseconds}ms since last call)');
        return;
      }
    }

    if (mounted) {
      setState(() {
        if (!isRefresh) {
          _isLoading = true;
        }
      });
    }

    try {
      // Track API call time
      _lastApiCallTime = DateTime.now();

      // Fetch order from API
      Map<String, String> params = {
        ApiAndParams.orderId: widget.orderId!,
      };

      if (!mounted) return;
      final orderData =
          await context.read<CurrentOrderProvider>().getCurrentOrder(
                params: params,
                context: context,
              );

      if (orderData != null && mounted) {
        setState(() {
          _currentOrder = orderData;
          _isLoading = false;
        });

        // Start countdown timer for status 1
        if (orderData.activeStatus == '2') {
          _startCountdownTimer(orderData);
        } else {
          _stopCountdownTimer();
        }

        // Update provider (which automatically starts Firebase if needed)
        final trackingProvider = context.read<OrderTrackingProvider>();
        trackingProvider.updateCurrentOrder(orderData);

        // Check if delivery boy has been assigned
        final hasDeliveryBoy = orderData.deliveryBoyName != null &&
            orderData.deliveryBoyName!.isNotEmpty &&
            orderData.deliveryBoyName != 'null';

        if (hasDeliveryBoy) {
          // Delivery boy is assigned
          debugPrint(
              '✅ [OrderTracking] Delivery boy assigned: ${orderData.deliveryBoyName}');
          debugPrint(
              '✅ [OrderTracking] Delivery boy ID: ${orderData.deliveryBoyId}');

          // Keep ETA subscription running even after delivery boy is assigned
          // to continue showing status updates from Firebase
          if (['1', '2', '3', '4', '5'].contains(orderData.activeStatus)) {
            debugPrint(
                '📡 [ETA] Delivery boy assigned, keeping order_eta subscription active for status updates');
            _startEtaFirebaseSubscription(widget.orderId!);
          }

          // Firebase tracking is already started by updateCurrentOrder()
          // Only start if it's a new delivery boy (avoid redundant initialization)
          if (_lastInitializedDeliveryBoyId != orderData.deliveryBoyId) {
            debugPrint(
                '🔥 [OrderTracking] New delivery boy detected, switching to delivery boy Firebase tracking');
            _lastInitializedDeliveryBoyId = orderData.deliveryBoyId;
            // Delivery boy Firebase tracking will be handled by OrderTrackingProvider
          }
        } else {
          // No delivery boy assigned yet - start ETA subscription for real-time ETA updates
          if (['1', '2', '3', '4', '5'].contains(orderData.activeStatus)) {
            debugPrint(
                '📡 [ETA] Delivery boy not assigned, starting order_eta subscription for status ${orderData.activeStatus}');
            _startEtaFirebaseSubscription(widget.orderId!);
          } else {
            // Status outside 1-5, stop ETA subscription
            _stopEtaSubscription();
          }
        }

        _updateMapMarkers();

        // Fetch existing ratings using the GET API (only on initial load, not on polling refreshes)
        if (!isRefresh) try {
          final ratingsResponse = await ratingApi(
            orderId: int.parse(orderData.id!),
            context: context,
          );

          if (ratingsResponse[ApiAndParams.status].toString() == "1") {
            _ratingModel = rm.RatingModel.fromJson(ratingsResponse);
            _ratingData = _ratingModel?.data;
            if (_ratingData != null) {
              if (_ratingData!.deliveryBoy?.rating != null) {
                _driverRating =
                    int.tryParse(_ratingData!.deliveryBoy!.rating.toString()) ?? 0;
              }
              if (_ratingData!.deliveryBoy?.review != null &&
                  _ratingData!.deliveryBoy!.review.toString() != 'null' &&
                  _ratingData!.deliveryBoy!.review.toString().isNotEmpty) {
                _driverReviewController.text =
                    _ratingData!.deliveryBoy!.review.toString();
              }
              if (_ratingData!.sellers != null) {
                for (var seller in _ratingData!.sellers!) {
                  if (seller.items != null) {
                    for (var item in seller.items!) {
                      if (item.rating != null && item.productId != null) {
                        _productRatings[item.productId!] =
                            int.tryParse(item.rating.toString()) ?? 0;
                      }
                    }
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching ratings: $e');
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (!isRefresh) {
          showMessage(context, "Failed to load order details: ${e.toString()}",
              MessageType.error);
        }
      }
    }
  }

  void _updateMapMarkers() async {
    debugPrint('🗺️ [OrderTracking] _updateMapMarkers() called');
    if (_currentOrder == null) {
      debugPrint('❌ [OrderTracking] _currentOrder is null, returning');
      return;
    }

    // Prevent concurrent updates
    if (_isUpdatingMarkers) {
      debugPrint(
          '⚠️ [OrderTracking] Already updating markers, skipping concurrent update');
      return;
    }

    _isUpdatingMarkers = true;
    debugPrint('🔄 [OrderTracking] Starting marker update process');

    try {
      Set<Marker> markers = {};

      // Use user's delivery address location from order's latitude and longitude
      // instead of fetching from API every time (which was causing repeated address calls)
      if (_currentOrder!.latitude != null &&
          _currentOrder!.longitude != null &&
          _currentOrder!.latitude != 'null' &&
          _currentOrder!.longitude != 'null') {
        try {
          double? userLat = double.tryParse(_currentOrder!.latitude!);
          double? userLng = double.tryParse(_currentOrder!.longitude!);

          if (userLat != null &&
              userLng != null &&
              userLat != 0.0 &&
              userLng != 0.0) {
            _userLocation = LatLng(userLat, userLng);
          }
        } catch (e) {
          debugPrint('❌ [OrderTracking] Error parsing user location: $e');
        }
      }

      // Get Firebase state from provider
      final trackingProvider = context.read<OrderTrackingProvider>();
      final isFirebaseActive = trackingProvider.isFirebaseActive;
      final firebaseData = trackingProvider.firebaseData;

      debugPrint('📡 [OrderTracking] Firebase active: $isFirebaseActive');
      debugPrint(
          '📡 [OrderTracking] Firebase data: ${firebaseData != null ? 'Present' : 'Null'}');

      // Prefer Firebase location over API location for delivery person
      if (isFirebaseActive &&
          firebaseData?.driverLocation != null &&
          firebaseData!.driverLocation!.latitude != null &&
          firebaseData.driverLocation!.longitude != null) {
        // Use Firebase real-time location (highest priority)
        _deliveryLocation = LatLng(
          firebaseData.driverLocation!.latitude!,
          firebaseData.driverLocation!.longitude!,
        );
        debugPrint(
            '✅ [OrderTracking] Using Firebase location: $_deliveryLocation');
      } else if (_currentOrder!.deliveryLocation != null &&
          _currentOrder!.deliveryLocation!['latitude'] != null &&
          _currentOrder!.deliveryLocation!['longitude'] != null) {
        // Use delivery_location from API response (second priority)
        double? deliveryLat = double.tryParse(
            _currentOrder!.deliveryLocation!['latitude'].toString());
        double? deliveryLng = double.tryParse(
            _currentOrder!.deliveryLocation!['longitude'].toString());

        if (deliveryLat != null &&
            deliveryLng != null &&
            deliveryLat != 0.0 &&
            deliveryLng != 0.0) {
          _deliveryLocation = LatLng(deliveryLat, deliveryLng);
          debugPrint(
              '✅ [OrderTracking] Using API delivery location: $_deliveryLocation');
        }
      } else if (_currentOrder!.deliveryBoyName != null &&
          _currentOrder!.deliveryBoyName!.isNotEmpty &&
          _currentOrder!.deliveryBoyName != 'null' &&
          _currentOrder!.latitude != null &&
          _currentOrder!.longitude != null &&
          _currentOrder!.latitude != 'null' &&
          _currentOrder!.longitude != 'null') {
        // Fallback to API latitude/longitude fields (third priority)
        double? deliveryLat = double.tryParse(_currentOrder!.latitude!);
        double? deliveryLng = double.tryParse(_currentOrder!.longitude!);

        if (deliveryLat != null &&
            deliveryLng != null &&
            deliveryLat != 0.0 &&
            deliveryLng != 0.0) {
          _deliveryLocation = LatLng(deliveryLat, deliveryLng);
        }
      }

      // Add delivery person marker (only if delivery boy is assigned AND location available)
      bool hasDeliveryBoyAssigned = _currentOrder!.deliveryBoyName != null &&
          _currentOrder!.deliveryBoyName!.isNotEmpty &&
          _currentOrder!.deliveryBoyName != 'null';

      debugPrint(
          '👤 [OrderTracking] Delivery boy assigned: $hasDeliveryBoyAssigned');
      debugPrint('📍 [OrderTracking] User location: $_userLocation');
      debugPrint('📍 [OrderTracking] Delivery location: $_deliveryLocation');

      if (hasDeliveryBoyAssigned && _deliveryLocation != null) {
        debugPrint('✅ [OrderTracking] Adding delivery person marker');

        // Start gliding the marker towards the newly received position
        _animateDriverTo(_deliveryLocation!);

        // Draw at the interpolated position, not the raw one
        final LatLng drawnPosition =
            _renderedDeliveryLocation ?? _deliveryLocation!;

        // Point the marker along the direction of travel; fall back to facing
        // the customer while the driver hasn't moved yet
        double bearing = _driverBearing;
        if (bearing == 0 && _userLocation != null) {
          bearing = _calculateBearing(drawnPosition, _userLocation!);
        }

        markers.add(
          Marker(
            markerId: const MarkerId('delivery_person'),
            position: drawnPosition,
            icon: _deliveryMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
            anchor: const Offset(0.5, 0.65),
            rotation: bearing,
            infoWindow: InfoWindow(
              title: _currentOrder!.deliveryBoyName ?? 'Delivery Person',
              snippet: isFirebaseActive ? 'Live tracking' : 'On the way',
            ),
          ),
        );

        // Use delivery location as fallback for map center
        // if (_userLocation == null) {
        //   _userLocation = _deliveryLocation;
        // }
      }

      // Add user location marker ONLY if no delivery boy assigned
      // Once delivery boy is assigned, we show target marker instead
      if (!hasDeliveryBoyAssigned && _userLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: _userLocation!,
            icon: _userMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
            anchor: const Offset(0.5, 0.65),
            infoWindow: InfoWindow(
              title: 'Delivery Address',
              snippet: _currentOrder!.orderAddress ?? '',
            ),
          ),
        );
      }

      // Show seller markers only when delivery boy is NOT assigned
      // Once delivery boy is assigned, show delivery marker instead
      if (!mounted) return;

      Set<Polyline> polylines = {};
      final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

      debugPrint('📊 [OrderTracking] Creating polylines...');
      debugPrint(
          '📊 [OrderTracking] DeliveryBoyAssigned: $hasDeliveryBoyAssigned');

      // Note: Waypoint calculation removed - polyline will only show current target

      // Get delivery progress and sellers_visit_order from Firebase
      final deliveryProgress = trackingProvider.deliveryProgress;
      final currentStep = deliveryProgress?.currentStep;
      final sellersVisitOrder = firebaseData?.sellersVisitOrder ?? [];

      debugPrint('📊 [OrderTracking] Current step from Firebase: $currentStep');
      debugPrint(
          '📊 [OrderTracking] Sellers in visit order: ${sellersVisitOrder.length}');
      debugPrint(
          '📊 [OrderTracking] Step meanings: 0..N-1=Going to seller N, N=Going to customer');

      // Determine target location based on current step and sellers_visit_order
      LatLng? targetLocation;
      String? targetName;
      bool isGoingToSeller = false;

      debugPrint(
          '🔍 [OrderTracking] Step comparison: currentStep=$currentStep, sellersVisitOrder.length=${sellersVisitOrder.length}');

      if (hasDeliveryBoyAssigned &&
          currentStep != null &&
          _deliveryLocation != null) {
        // Build complete route from driver's current location through all remaining stops
        List<LatLng> completeRoutePath = [_deliveryLocation!];

        if (currentStep < sellersVisitOrder.length) {
          // Driver is going to sellers
          // Add remaining sellers from current step onwards
          for (int i = currentStep; i < sellersVisitOrder.length; i++) {
            final seller = sellersVisitOrder[i];
            if (seller.latitude != null && seller.longitude != null) {
              completeRoutePath
                  .add(LatLng(seller.latitude!, seller.longitude!));
            }
          }
          // Add customer location at the end
          if (_userLocation != null) {
            completeRoutePath.add(_userLocation!);
          }

          // Set immediate target
          final currentSeller = sellersVisitOrder[currentStep];
          if (currentSeller.latitude != null &&
              currentSeller.longitude != null) {
            targetLocation =
                LatLng(currentSeller.latitude!, currentSeller.longitude!);
            targetName = currentSeller.storeName ?? 'Seller ${currentStep + 1}';
            isGoingToSeller = true;
            debugPrint(
                '🏪 [OrderTracking] Driver going to seller $currentStep: $targetName');
            debugPrint('📍 [OrderTracking] Seller location: $targetLocation');
          }
        } else {
          // currentStep >= sellersVisitOrder.length means going to customer
          targetLocation = _userLocation;
          targetName = 'Customer';
          completeRoutePath.add(_userLocation!);
          debugPrint(
              '🚚 [OrderTracking] Driver going to customer (final delivery) - step $currentStep >= ${sellersVisitOrder.length} sellers');
        }

        // Store for use in polyline creation
        debugPrint(
            '📍 [OrderTracking] Complete route path has ${completeRoutePath.length} points');
      } else {
        debugPrint(
            '⚠️ [OrderTracking] Cannot determine route: hasDeliveryBoyAssigned=$hasDeliveryBoyAssigned, currentStep=$currentStep, deliveryLocation=$_deliveryLocation');
      }

      // Show marker only for current seller being visited
      if (isGoingToSeller &&
          currentStep != null &&
          currentStep < sellersVisitOrder.length) {
        final currentSeller = sellersVisitOrder[currentStep];
        if (currentSeller.latitude != null && currentSeller.longitude != null) {
          BitmapDescriptor sellerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          try {
            sellerIcon = await _createCustomSellerMarker(
              colorScheme,
              sellerName:
                  currentSeller.storeName ?? 'Seller ${currentStep + 1}',
            );
          } catch (e) {
            // Use default marker as fallback
          }

          markers.add(
            Marker(
              markerId:
                  MarkerId('seller_${currentSeller.sellerId}_$currentStep'),
              position:
                  LatLng(currentSeller.latitude!, currentSeller.longitude!),
              icon: sellerIcon,
              anchor: const Offset(0.5, 0.65),
              infoWindow: InfoWindow(
                title: currentSeller.storeName ?? 'Seller ${currentStep + 1}',
                snippet: 'Current pickup location',
              ),
            ),
          );
        }
      }

      // Create SIMPLE polyline: only show delivery boy → current target
      if (hasDeliveryBoyAssigned &&
          currentStep != null &&
          _deliveryLocation != null &&
          targetLocation != null) {
        debugPrint(
            '🛣️ [OrderTracking] Creating polyline: Driver → $targetName (step $currentStep)');
        debugPrint('🚗 [OrderTracking] Driver location: $_deliveryLocation');
        debugPrint('🎯 [OrderTracking] Target location: $targetLocation');

        // Only show active route from driver to target.
        // Reuses the cached route while the driver is still on it, so the line
        // doesn't flicker (and we don't bill a Routes API call) every 30s.
        final List<LatLng> routePoints = await _getRouteForDriver(
          _deliveryLocation!,
          targetLocation,
          drawnOrigin: _renderedDeliveryLocation ?? _deliveryLocation!,
        );

        // Single bold blue polyline showing active route
        polylines.add(
          Polyline(
            polylineId: const PolylineId('driver_to_target'),
            points: routePoints,
            color: colorScheme.primary,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            geodesic: true,
            zIndex: 3,
          ),
        );

        // Add destination marker at target location using existing marker icons
        if (targetName != null) {
          BitmapDescriptor targetIcon = isGoingToSeller
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          try {
            if (isGoingToSeller) {
              targetIcon = await _createCustomSellerMarker(
                colorScheme,
                sellerName: targetName,
              );
            } else {
              final cartAddr = _currentOrder
                  ?.cartInfo?['delivery_address']
                  ?.toString();
              final addressLine = (cartAddr != null && cartAddr.isNotEmpty)
                  ? cartAddr
                  : _currentOrder?.orderAddress;
              targetIcon = await _createCustomCustomerMarker(
                colorScheme,
                addressLine: addressLine,
              );
            }
          } catch (e) {
            debugPrint('❌ [OrderTracking] Failed to create target marker: $e');
          }

          markers.add(
            Marker(
              markerId: const MarkerId('target_destination'),
              position: targetLocation,
              icon: targetIcon,
              anchor: const Offset(0.5, 0.65),
              infoWindow: InfoWindow(
                title: targetName,
                snippet: isGoingToSeller
                    ? 'Pickup location'
                    : 'Delivery destination',
              ),
            ),
          );
          debugPrint(
              '🎯 [OrderTracking] Added destination marker: $targetName at $targetLocation');
        }

        debugPrint('✅ [OrderTracking] Added polyline: Driver → $targetName');
      } else if (!hasDeliveryBoyAssigned &&
          _currentOrder!.groupedByStore != null) {
        // Show all sellers and arcs when delivery boy is NOT assigned yet
        debugPrint(
            '🏪 [OrderTracking] Delivery boy not assigned - showing all sellers');
        Map<String, Map<String, dynamic>> uniqueSellers = {};

        for (var store in _currentOrder!.groupedByStore!) {
          if (store.sellers != null) {
            for (var seller in store.sellers!) {
              if (seller.sellerId != null && seller.hasValidLocation()) {
                double lat = seller.getLatitude()!;
                double lng = seller.getLongitude()!;

                uniqueSellers[seller.sellerId.toString()] = {
                  'position': LatLng(lat, lng),
                  'name': seller.sellerName ?? 'Seller',
                };

                BitmapDescriptor sellerIcon =
                    BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange);
                try {
                  sellerIcon = await _createCustomSellerMarker(
                    colorScheme,
                    sellerName: seller.sellerName ?? 'Seller',
                  );
                } catch (e) {
                  // Use default orange marker as fallback
                }

                markers.add(
                  Marker(
                    markerId: MarkerId('seller_${seller.sellerId}'),
                    position: LatLng(lat, lng),
                    icon: sellerIcon,
                    anchor: const Offset(0.5, 0.65),
                    infoWindow: InfoWindow(
                      title: seller.sellerName ?? 'Seller',
                      snippet: 'Preparing your order',
                    ),
                  ),
                );
              }
            }
          }
        }

        // Create polylines from sellers to user location
        if (_userLocation != null && uniqueSellers.isNotEmpty) {
          List<LatLng> sellerPositions = uniqueSellers.values
              .map((seller) => seller['position'] as LatLng)
              .toList();

          debugPrint(
              '🎯 [OrderTracking] Creating routes for ${sellerPositions.length} seller(s)');

          for (int i = 0; i < sellerPositions.length; i++) {
            // Try to fetch real waypoints, fallback to arc if API fails
            List<LatLng> routePoints =
                await getRouteWaypoints(sellerPositions[i], _userLocation!);

            if (routePoints.isEmpty) {
              routePoints =
                  _createArcPolyline(sellerPositions[i], _userLocation!);
              debugPrint(
                  '🎯 [OrderTracking] Seller $i arc fallback created with ${routePoints.length} points');
            } else {
              debugPrint(
                  '🎯 [OrderTracking] Seller $i waypoints fetched with ${routePoints.length} points');
            }

            polylines.add(
              Polyline(
                polylineId: PolylineId('seller_${i}_to_user'),
                points: routePoints,
                color: colorScheme.primary,
                width: 2,
                patterns: [PatternItem.dash(25), PatternItem.gap(15)],
                geodesic: false,
              ),
            );
          }
        }

        // Show Zenfoo store location marker when order has admin-managed store items
        final hasAdminStoreItems = _currentOrder!.groupedByStore!
            .any((s) => s.managedByAdmin == true);
        final zenfooLocation = _currentOrder!.zenfooStoreLocation;
        if (hasAdminStoreItems && zenfooLocation != null) {
          final storeLatLng =
              LatLng(zenfooLocation.latitude, zenfooLocation.longitude);
          BitmapDescriptor storeIcon = BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange);
          try {
            storeIcon = await _createCustomSellerMarker(colorScheme,
                sellerName: zenfooLocation.name);
          } catch (_) {}

          markers.add(Marker(
            markerId: const MarkerId('zenfoo_store'),
            position: storeLatLng,
            icon: storeIcon,
            anchor: const Offset(0.5, 0.65),
            infoWindow: InfoWindow(
              title: zenfooLocation.name,
              snippet: 'Zenfoo Store',
            ),
          ));

          if (_userLocation != null) {
            List<LatLng> routePoints =
                await getRouteWaypoints(storeLatLng, _userLocation!);
            if (routePoints.isEmpty) {
              routePoints = _createArcPolyline(storeLatLng, _userLocation!);
            }
            polylines.add(Polyline(
              polylineId: const PolylineId('zenfoo_store_to_user'),
              points: routePoints,
              color: colorScheme.primary,
              width: 2,
              patterns: [PatternItem.dash(25), PatternItem.gap(15)],
              geodesic: false,
            ));
          }
        }
      } else {
        debugPrint('⚠️ [OrderTracking] No routing information available');
      }

      if (mounted) {
        // Only update markers if they've changed to prevent unnecessary rebuilds.
        // Positions must be part of this check - comparing ids/lengths alone
        // meant a moved driver never repainted.
        final markersChanged = !_areMarkersEqual(_markers, markers);
        final polylinesChanged = !_arePolylinesEqual(_polylines, polylines);

        if (markersChanged || polylinesChanged) {
          debugPrint(
              '📌 [OrderTracking] Setting state with ${markers.length} markers and ${polylines.length} polylines');
          setState(() {
            _markers = markers;
            _polylines = polylines;
          });
        } else {
          debugPrint(
              '⏭️ [OrderTracking] Markers/polylines unchanged - skipping state update');
        }

        debugPrint(
            '✅ [OrderTracking] State updated - markers: ${_markers.length}, polylines: ${_polylines.length}');

        // Animate camera to show all markers
        int sellerCount = markers
            .where((m) =>
                m.markerId.value.startsWith('seller_') ||
                m.markerId.value == 'zenfoo_store')
            .length;

        if ((_userLocation != null &&
                _deliveryLocation != null &&
                _deliveryLocation != _userLocation) ||
            (_userLocation != null && sellerCount > 0) ||
            (_deliveryLocation != null && sellerCount > 0)) {
          // Only re-fit the camera once the driver has actually covered ground.
          // Re-fitting on every 2s tick fights the marker glide and makes the
          // map feel twitchy.
          final bool shouldRefit = _deliveryLocation == null ||
              _lastCameraFitDriverPosition == null ||
              _distanceMeters(_lastCameraFitDriverPosition!,
                      _deliveryLocation!) >
                  _cameraRefitDistanceMeters;

          if (shouldRefit) {
            _lastCameraFitDriverPosition = _deliveryLocation;
            _animateToBounds();
          }
        } else if (_userLocation != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_userLocation!, 14),
          );
        }
      }
    } finally {
      // Always reset the update flag
      _isUpdatingMarkers = false;
    }
  }

  /// Compare marker sets by id AND position/rotation, so driver movement counts
  /// as a change (an id-only comparison left the map frozen).
  bool _areMarkersEqual(Set<Marker> a, Set<Marker> b) {
    if (a.length != b.length) return false;

    final Map<String, Marker> byId = {
      for (final marker in a) marker.markerId.value: marker
    };

    for (final marker in b) {
      final existing = byId[marker.markerId.value];
      if (existing == null) return false;
      if (existing.position.latitude != marker.position.latitude ||
          existing.position.longitude != marker.position.longitude ||
          existing.rotation != marker.rotation) {
        return false;
      }
    }
    return true;
  }

  /// Compare polyline sets by id and by their endpoints/length - enough to
  /// detect a re-routed or re-anchored line without walking every point.
  bool _arePolylinesEqual(Set<Polyline> a, Set<Polyline> b) {
    if (a.length != b.length) return false;

    final Map<String, Polyline> byId = {
      for (final polyline in a) polyline.polylineId.value: polyline
    };

    for (final polyline in b) {
      final existing = byId[polyline.polylineId.value];
      if (existing == null) return false;
      if (existing.points.length != polyline.points.length) return false;
      if (existing.points.isEmpty) continue;
      if (existing.points.first != polyline.points.first ||
          existing.points.last != polyline.points.last) {
        return false;
      }
    }
    return true;
  }

  // Create arc polyline between two points
  List<LatLng> _createArcPolyline(LatLng start, LatLng end) {
    List<LatLng> arcPoints = [];
    const int segments = 50; // Number of points in the arc

    // Offset the start/end points to match the visual top of the marker pin circles
    // Pin tip is at anchor (0.5, 0.65) = pixel 98/150
    // Pin circle top is at pixel 54/150 = 0.36
    // Offset needed: (0.65 - 0.36) = 0.29 of marker height
    // Marker height in degrees ≈ 0.0003 (approximate), so offset = 0.29 * 0.0003 = 0.000087
    const double markerOffsetDegrees =
        0.00009; // Offset to reach top of pin circle

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
    // For a visual "upward" arc, we want to offset in the direction that increases latitude
    double perpLat = -lngDiff;
    double perpLng = latDiff;

    // Normalize the perpendicular vector
    double perpLength = math.sqrt(perpLat * perpLat + perpLng * perpLng);
    if (perpLength > 0) {
      perpLat /= perpLength;
      perpLng /= perpLength;
    }

    // Calculate arc height based on distance
    double distance = math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
    double arcHeight = distance * 0.2; // 20% of distance for subtle arc

    // Ensure arc curves upward by using absolute perpendicular offset in latitude direction
    // If perpLat is negative, flip the direction to always curve upward
    if (perpLat < 0) {
      perpLat = -perpLat;
      perpLng = -perpLng;
    }

    // Arc peak point (midpoint + perpendicular offset)
    double peakLat = midLat + perpLat * arcHeight;
    double peakLng = midLng + perpLng * arcHeight;

    // Generate points along the arc using quadratic bezier curve
    for (int i = 0; i <= segments; i++) {
      double t = i / segments;

      // Quadratic Bezier curve formula: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
      double lat = math.pow(1 - t, 2) * adjustedStart.latitude +
          2 * (1 - t) * t * peakLat +
          math.pow(t, 2) * adjustedEnd.latitude;

      double lng = math.pow(1 - t, 2) * adjustedStart.longitude +
          2 * (1 - t) * t * peakLng +
          math.pow(t, 2) * adjustedEnd.longitude;

      arcPoints.add(LatLng(lat, lng));
    }

    return arcPoints;
  }

  /// Route from driver to target, reusing the cached one until the driver has
  /// strayed [_routeRefreshDistanceMeters] from where it was computed.
  ///
  /// [drawnOrigin] is the marker's interpolated position, so the line always
  /// starts under the marker even mid-glide.
  Future<List<LatLng>> _getRouteForDriver(
    LatLng origin,
    LatLng target, {
    required LatLng drawnOrigin,
  }) async {
    final bool sameTarget = _cachedRouteTarget != null &&
        _cachedRouteTarget!.latitude == target.latitude &&
        _cachedRouteTarget!.longitude == target.longitude;
    final bool strayedOffRoute = _cachedRouteOrigin == null ||
        _distanceMeters(_cachedRouteOrigin!, origin) >
            _routeRefreshDistanceMeters;

    if (_cachedRoutePoints != null && sameTarget && !strayedOffRoute) {
      debugPrint('♻️ [OrderTracking] Reusing cached route');
      return _trimRouteToDriver(_cachedRoutePoints!, drawnOrigin);
    }

    List<LatLng> routePoints = await getRouteWaypoints(origin, target);

    if (routePoints.isEmpty) {
      debugPrint('⚠️ [OrderTracking] Using arc fallback for route');
      _cachedRoutePoints = null;
      _cachedRouteOrigin = null;
      _cachedRouteTarget = null;
      return _createArcPolyline(drawnOrigin, target);
    }

    debugPrint(
        '✅ [OrderTracking] Got route with ${routePoints.length} waypoints');
    _cachedRoutePoints = routePoints;
    _cachedRouteOrigin = origin;
    _cachedRouteTarget = target;
    return _trimRouteToDriver(routePoints, drawnOrigin);
  }

  /// Drop the part of the route the driver has already covered and re-anchor
  /// the line to the marker's current position.
  List<LatLng> _trimRouteToDriver(List<LatLng> route, LatLng driver) {
    if (route.isEmpty) return route;

    int nearestIndex = 0;
    double nearestDistance = double.infinity;
    for (int i = 0; i < route.length; i++) {
      final double distance = _distanceMeters(route[i], driver);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    return [driver, ...route.sublist(nearestIndex)];
  }

  // Fetch real waypoints from Google Routes API
  Future<List<LatLng>> getRouteWaypoints(
      LatLng origin, LatLng destination) async {
    try {
      debugPrint(
          '🔄 [OrderTracking] Fetching waypoints from Google Routes API...');
      debugPrint(
          '📍 [OrderTracking] Origin: $origin, Destination: $destination');

      final routesService = GoogleRoutesApiService();
      final response = await routesService.computeRoute(
        origin: origin,
        destination: destination,
        context: context,
      );

      if (response != null && response.routes.isNotEmpty) {
        final route = response.routes.first;

        debugPrint(
            '📊 [OrderTracking] Route decoded with ${route.decodedPolyline.length} waypoints');

        // Store real-time duration from Routes API (convert from "300s" format to "X min")
        final durationSeconds = route.getDurationInSeconds();
        final durationMinutes = (durationSeconds / 60).toInt();
        _routeDuration =
            durationMinutes > 0 ? '$durationMinutes min' : '< 1 min';
        debugPrint(
            '⏱️  [OrderTracking] Real-time duration: $_routeDuration (${durationSeconds.toInt()}s)');

        List<LatLng> waypoints = [];

        // Add origin point
        waypoints.add(origin);

        // Add all decoded polyline points
        if (route.decodedPolyline.isNotEmpty) {
          waypoints.addAll(route.decodedPolyline);
        }

        // Ensure destination is included
        if (waypoints.isEmpty || waypoints.last != destination) {
          waypoints.add(destination);
        }

        debugPrint(
            '✅ [OrderTracking] Total waypoints collected: ${waypoints.length}');
        return waypoints;
      } else {
        debugPrint('❌ [OrderTracking] Routes API failed - no response');
        return [];
      }
    } catch (e) {
      debugPrint('❌ [OrderTracking] Error fetching waypoints: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Calculate waypoints with durations for sequential delivery through sellers to customer
  // Decode polyline string to list of LatLng points
  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      double latitude = (lat / 1e5).toDouble();
      double longitude = (lng / 1e5).toDouble();
      poly.add(LatLng(latitude, longitude));
    }

    return poly;
  }

  // Create optimal route through multiple sellers to user location

  // Calculate distance between two LatLng points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    double lat1Rad = point1.latitude * 3.14159265359 / 180;
    double lat2Rad = point2.latitude * 3.14159265359 / 180;
    double deltaLat = (point2.latitude - point1.latitude) * 3.14159265359 / 180;
    double deltaLng =
        (point2.longitude - point1.longitude) * 3.14159265359 / 180;

    double a = (deltaLat / 2).abs() * (deltaLat / 2).abs() +
        lat1Rad.abs() *
            lat2Rad.abs() *
            (deltaLng / 2).abs() *
            (deltaLng / 2).abs();
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Calculate bearing (direction) from one point to another
  double _calculateBearing(LatLng from, LatLng to) {
    double lat1 = from.latitude * 3.14159265359 / 180;
    double lat2 = to.latitude * 3.14159265359 / 180;
    double deltaLng = (to.longitude - from.longitude) * 3.14159265359 / 180;

    double y = math.sin(deltaLng) * math.cos(lat2);
    double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    double bearing = math.atan2(y, x) * 180 / 3.14159265359;

    // Normalize bearing to 0-360 degrees
    bearing = (bearing + 360) % 360;
    return bearing;
  }

  // Accurate great-circle distance in meters (Haversine)
  double _distanceMeters(LatLng from, LatLng to) {
    const double earthRadius = 6371000;
    const double toRad = math.pi / 180;

    final double dLat = (to.latitude - from.latitude) * toRad;
    final double dLng = (to.longitude - from.longitude) * toRad;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(from.latitude * toRad) *
            math.cos(to.latitude * toRad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Glide the driver marker from its currently drawn position to [target].
  ///
  /// The driver app pushes a location every 30 seconds; without this the marker
  /// would jump. Interpolating over a few seconds makes the movement readable.
  void _animateDriverTo(LatLng target) {
    // First fix - nothing to animate from
    if (_renderedDeliveryLocation == null) {
      _renderedDeliveryLocation = target;
      _markerAnimTo = target;
      return;
    }

    // Already animating towards this exact target
    if (_markerAnimTo != null &&
        _markerAnimTo!.latitude == target.latitude &&
        _markerAnimTo!.longitude == target.longitude) {
      return;
    }

    final double distance = _distanceMeters(_renderedDeliveryLocation!, target);

    // Ignore GPS jitter
    if (distance < 3) {
      _markerAnimTo = target;
      return;
    }

    // Snap on implausible jumps (GPS re-acquire, order switch, app resumed)
    if (distance > _markerTeleportThresholdMeters) {
      debugPrint(
          '⚡ [OrderTracking] Driver jumped ${distance.toStringAsFixed(0)}m - snapping marker');
      _markerAnimTimer?.cancel();
      _markerAnimTimer = null;
      _driverBearing = _calculateBearing(_renderedDeliveryLocation!, target);
      _renderedDeliveryLocation = target;
      _markerAnimTo = target;
      _updateDriverMarkerPosition();
      return;
    }

    _markerAnimFrom = _renderedDeliveryLocation;
    _markerAnimTo = target;
    _markerAnimElapsedMs = 0;
    _driverBearing = _calculateBearing(_markerAnimFrom!, target);

    debugPrint(
        '🛵 [OrderTracking] Gliding driver marker ${distance.toStringAsFixed(0)}m over ${_markerAnimDurationMs}ms');

    _markerAnimTimer?.cancel();
    _markerAnimTimer =
        Timer.periodic(const Duration(milliseconds: _markerAnimTickMs), (timer) {
      if (!mounted || _markerAnimFrom == null || _markerAnimTo == null) {
        timer.cancel();
        _markerAnimTimer = null;
        return;
      }

      _markerAnimElapsedMs += _markerAnimTickMs;
      final double t =
          (_markerAnimElapsedMs / _markerAnimDurationMs).clamp(0.0, 1.0);
      final double eased = Curves.easeInOut.transform(t);

      _renderedDeliveryLocation = LatLng(
        _markerAnimFrom!.latitude +
            (_markerAnimTo!.latitude - _markerAnimFrom!.latitude) * eased,
        _markerAnimFrom!.longitude +
            (_markerAnimTo!.longitude - _markerAnimFrom!.longitude) * eased,
      );

      _updateDriverMarkerPosition();

      if (t >= 1.0) {
        timer.cancel();
        _markerAnimTimer = null;
      }
    });
  }

  /// Repaint only the driver marker - cheap enough to run every animation tick
  /// (a full `_updateMapMarkers()` would rebuild icons and refetch the route).
  void _updateDriverMarkerPosition() {
    if (!mounted || _renderedDeliveryLocation == null) return;

    Marker? driverMarker;
    for (final marker in _markers) {
      if (marker.markerId.value == 'delivery_person') {
        driverMarker = marker;
        break;
      }
    }
    if (driverMarker == null) return;

    final updated = driverMarker.copyWith(
      positionParam: _renderedDeliveryLocation,
      rotationParam: _driverBearing,
    );

    setState(() {
      _markers = {
        ..._markers.where((m) => m.markerId.value != 'delivery_person'),
        updated,
      };
    });
  }

  Future<void> _animateToBounds() async {
    if (!mounted || _mapController == null) {
      return;
    }

    // Collect all marker positions to include in bounds
    List<LatLng> positions = [];

    if (_userLocation != null) positions.add(_userLocation!);
    if (_deliveryLocation != null) positions.add(_deliveryLocation!);

    // Add all seller marker positions
    for (var marker in _markers) {
      if (marker.markerId.value.startsWith('seller_')) {
        positions.add(marker.position);
      }
    }

    // Need at least 2 positions to create bounds
    if (positions.length < 2) {
      if (positions.isNotEmpty) {
        // Only one position, just zoom to it
        try {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(positions.first, 14),
          );
        } catch (e) {}
      }
      return;
    }

    try {
      // Calculate bounds that include all positions
      double minLat = positions.first.latitude;
      double maxLat = positions.first.latitude;
      double minLng = positions.first.longitude;
      double maxLng = positions.first.longitude;

      for (var position in positions) {
        if (position.latitude < minLat) minLat = position.latitude;
        if (position.latitude > maxLat) maxLat = position.latitude;
        if (position.longitude < minLng) minLng = position.longitude;
        if (position.longitude > maxLng) maxLng = position.longitude;
      }

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {}
  }

  String _getOrderStatusText() {
    if (_currentOrder == null)
      return getTranslatedValue(context, 'loading_order_tracking');

    String status = _currentOrder!.activeStatus ?? '1';
    switch (status) {
      case '1':
      case '2':
        return getTranslatedValue(context, 'order_placed_status');
      case '3':
      case '4':
        return getTranslatedValue(context, 'processing_status');
      case '5':
        return getTranslatedValue(context, 'out_for_delivery_status');
      case '6':
        return getTranslatedValue(context, 'delivered_status');
      case '7':
        return getTranslatedValue(
            context, 'order_status_display_names_cancelled');
      default:
        return getTranslatedValue(context, 'preparing_status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Show loading state
    if (_isLoading) {
      return _buildLoadingState(colorScheme);
    }

    // Show cancelled state for cancelled orders
    if (_currentOrder?.activeStatus == '7') {
      return _buildCancelledState(colorScheme);
    }

    // Show delivered state for completed orders
    if (_currentOrder?.activeStatus == '6') {
      return _buildDeliveredState(colorScheme);
    }

    // Regular map view for non-delivery orders
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: AppHeader(
          label: getTranslatedValue(context, 'track_order_button'),
          title:
              '#${_currentOrder?.id ?? getTranslatedValue(context, 'loading_order_tracking')}',
          showBackButton: true,
          trailing: _buildRefreshButton(colorScheme),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            // Google Map
            SizedBox.expand(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _userLocation ?? const google_maps.LatLng(0, 0),
                  zoom: 15.5,
                ),
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                trafficEnabled: false,
                tiltGesturesEnabled: true,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                style: _mapStyle,
                padding: EdgeInsets.only(
                  // top: 20,
                  bottom: 400,
                ),
              ),
            ),

            // Rain Notification Overlay
            _buildRainNotification(colorScheme),

            // Bottom Sheet
            DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.6,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.6, 0.7, 0.85],
              builder: (context, scrollController) {
                final mediaQuery = MediaQuery.of(context);
                return Container(
                  // decoration: BoxDecoration(
                  //   color: colorScheme.surface,
                  //   borderRadius: const BorderRadius.vertical(
                  //     top: Radius.circular(24),
                  //   ),
                  // ),
                  child: Column(
                    children: [
                      // Status card (different UI for early stages 1-3)
                      if (_currentOrder != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: _buildStatusCard(colorScheme),
                        ),
                      // Bottom sheet content
                      Expanded(
                        child: _buildBottomSheet(scrollController, colorScheme),
                      ),
                      // Add padding at bottom to prevent navigation bar overlap
                      SizedBox(height: mediaQuery.viewInsets.bottom),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRainNotification(AppColorScheme colorScheme) {
    return Consumer<HomeScreenProvider>(
      builder: (context, homeProvider, child) {
        if (!homeProvider.isRaining) return const SizedBox.shrink();

        return Positioned(
          top: 10,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/rains.gif',
                  height: 36,
                  width: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "It's raining! We will find a delivery partner at the earliest to deliver your order.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveredState(AppColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: Color(0xff28A745),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 32),
                  Image.asset(
                    'assets/images/order.png',
                    height: 240,
                    width: 240,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Delivered!',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    'Thank you for shopping with us',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom sheet with floating map and order details
            DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.62,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.62, 0.72, 0.85],
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Floating map card (overlaps with bottom sheet)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            onMapCreated: (controller) {
                              _onMapCreated(controller);
                              _drawDeliveryRouteArc();
                            },
                            initialCameraPosition: CameraPosition(
                              target: _userLocation ??
                                  const google_maps.LatLng(0, 0),
                              zoom: 14.5,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                            myLocationButtonEnabled: false,
                            myLocationEnabled: false,
                            mapToolbarEnabled: false,
                            zoomControlsEnabled: true,
                            trafficEnabled: false,
                            tiltGesturesEnabled: false,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            rotateGesturesEnabled: false,
                            style: _mapStyle,
                          ),
                        ),
                      ),
                    ),
                    // Bottom sheet container
                    Expanded(
                      child: Container(
                        decoration: ShapeDecoration(
                          color: colorScheme.cardBackground,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            children: [
                              // Drag handle
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Scrollable content
                              Expanded(
                                child: ListView(
                                  controller: scrollController,
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 8,
                                    bottom:
                                        100, // Increased bottom padding to prevent overlap with fixed button
                                  ),
                                  children: _showRatingsPage
                                      ? [
                                          // Ratings-only mode: header + rating
                                          // cards. Order details are hidden;
                                          // user reaches this by tapping the
                                          // "Give Ratings" CTA.
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4, bottom: 12),
                                            child: Text(
                                              'Rate your order',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: colorScheme.textPrimary,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                          ),
                                          if (_ratingData != null) ...[
                                            if (_ratingData!.deliveryBoy != null)
                                              _buildDriverRatingCard(colorScheme),
                                            const SizedBox(height: 16),
                                            _buildSellerProductsRating(colorScheme),
                                          ] else
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 32),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                        ]
                                      : [
                                          // Order Products Banner
                                          if (_currentOrder?.items != null &&
                                              _currentOrder!.items!.isNotEmpty) ...[
                                            _buildOrderItemsBanner(colorScheme),
                                            const SizedBox(height: 16),
                                          ],

                                          // Customer Details
                                          _buildCustomerDetailsCard(colorScheme),
                                          const SizedBox(height: 16),

                                          // Order Details
                                          _buildOrderDetailsCard(colorScheme),
                                          const SizedBox(height: 16),

                                          // Store Contact Card
                                          _buildStoreContactCard(colorScheme),
                                          const SizedBox(height: 16),

                                          // Why this order had no Cancel option
                                          _buildOrderCancelNote(),

                                          // Customer Support
                                          _buildCustomerSupportCard(colorScheme),
                                          const SizedBox(height: 24),
                                        ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Fixed Bottom Navigation
            // - Default: Back to Home + Give Ratings (Give Ratings flips the
            //   sheet to the ratings-only view).
            // - Ratings view: single Back to Home button.
            SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _showRatingsPage
                      ? Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                mainHomeScreen,
                                (route) => false,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Back to Home',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                      mainHomeScreen,
                                      (route) => false,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Back to Home',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _showRatingsPage = true);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Give Ratings',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledState(AppColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: Color(0xffDC3545),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 32),
                  Icon(
                    Icons.cancel_outlined,
                    size: 240,
                    color: colorScheme.textPrimary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Order Cancelled!',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    'Your order has been cancelled.',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom sheet with order details
            DraggableScrollableSheet(
              initialChildSize: 0.52,
              minChildSize: 0.52,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.52, 0.6, 0.85],
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Bottom sheet container
                    Expanded(
                      child: Container(
                        decoration: ShapeDecoration(
                          color: colorScheme.cardBackground,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            children: [
                              // Drag handle
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Scrollable content
                              Expanded(
                                child: ListView(
                                  controller: scrollController,
                                  physics: const ClampingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  children: [
                                    // Cancellation reason if available
                                    if (_currentOrder?.orderNote != null &&
                                        _currentOrder!.orderNote!.isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: ShapeDecoration(
                                          color: Color(0xffDC3545)
                                              .withValues(alpha: 0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Cancellation Reason',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    colorScheme.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _currentOrder!.orderNote ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_currentOrder?.orderNote != null &&
                                        _currentOrder!.orderNote!.isNotEmpty)
                                      const SizedBox(height: 16),

                                    // Order Products Banner
                                    if (_currentOrder?.items != null &&
                                        _currentOrder!.items!.isNotEmpty) ...[
                                      _buildOrderItemsBanner(colorScheme),
                                      const SizedBox(height: 16),
                                    ],

                                    // Customer Details
                                    _buildCustomerDetailsCard(colorScheme),
                                    const SizedBox(height: 16),

                                    // Order Details
                                    _buildOrderDetailsCard(colorScheme),
                                    const SizedBox(height: 16),

                                    // Store Contact Card
                                    _buildStoreContactCard(colorScheme),
                                    const SizedBox(height: 16),

                                    // Customer Support
                                    _buildCustomerSupportCard(colorScheme),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Fixed Bottom Navigation - Back to Home Button
            SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          mainHomeScreen,
                          (route) => false,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Back to Home',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: _isRefreshing ? null : _onRefreshPressed,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RotationTransition(
          turns: _refreshAnimationController,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.refresh,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppColorScheme colorScheme) {
    return Stack(
      children: [
        // Map placeholder shimmer
        Container(
          color: colorScheme.surfaceVariant,
          child: CustomShimmer(
            height: double.infinity,
            width: double.infinity,
            borderRadius: 0,
          ),
        ),

        // Top App Bar

        // Bottom Sheet Shimmer
        DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: const [
                        // Status card shimmer
                        CustomShimmer(
                          height: 80,
                          width: double.infinity,
                          borderRadius: 18,
                          margin: EdgeInsets.symmetric(vertical: 8),
                        ),

                        // Delivery person shimmer
                        CustomShimmer(
                          height: 120,
                          width: double.infinity,
                          borderRadius: 18,
                          margin: EdgeInsets.symmetric(vertical: 8),
                        ),

                        // Items banner shimmer
                        CustomShimmer(
                          height: 150,
                          width: double.infinity,
                          borderRadius: 18,
                          margin: EdgeInsets.symmetric(vertical: 8),
                        ),

                        // Customer details shimmer
                        CustomShimmer(
                          height: 100,
                          width: double.infinity,
                          borderRadius: 18,
                          margin: EdgeInsets.symmetric(vertical: 8),
                        ),

                        // Order details shimmer
                        CustomShimmer(
                          height: 200,
                          width: double.infinity,
                          borderRadius: 18,
                          margin: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeBadge(AppColorScheme colorScheme, String? prepTimeText) {
    if (_currentOrder == null) return const SizedBox.shrink();

    final orderStatus = _currentOrder!.activeStatus ?? '1';
    String timeText = '';
    bool showBadge = false;

    // Show prep time when status is "Processing" (activeStatus = '2')
    if (orderStatus == '2' && prepTimeText != null) {
      timeText = prepTimeText;
      showBadge = true;
    }
    // Show delivery time when status is "Out for Delivery" (activeStatus = '3')
    else if (orderStatus == '3') {
      // Use real-time duration from Routes API if available
      if (_routeDuration.isNotEmpty &&
          _routeDuration != "Error" &&
          _routeDuration != "N/A") {
        timeText = _routeDuration;
        showBadge = true;
        debugPrint(
            '⏱️  [TimeBadge] Using real-time duration from Routes API: $_routeDuration');
      }
      // Fallback to approximate calculation if API duration not available
      else if (_deliveryLocation != null && _userLocation != null) {
        final distance = _calculateDistance(_deliveryLocation!, _userLocation!);
        final timeInMinutes = (distance / 40 * 60).toInt();
        timeText = '$timeInMinutes mins';
        showBadge = true;
        debugPrint('⏱️  [TimeBadge] Using fallback calculation: $timeText');
      }
    }

    if (!showBadge || timeText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        timeText,
        style: GoogleFonts.inter(
          color: const Color(0xFF9AC444),
          fontSize: 16,
          fontWeight: FontWeight.w900,
          height: 1.08,
        ),
      ),
    );
  }

  Widget _buildStatusCard(AppColorScheme colorScheme) {
    // Use new UI for statuses 1, 2, 3; use old UI for others
    final status = _currentOrder?.activeStatus ?? '1';
    // if (['1', '2', '3', '4', '5', '6'].contains(status)) {
    return _buildStatusCardForEarlyStages(colorScheme);
    // }
    // return _buildFloatingStatusCard(colorScheme);
  }

  Widget _buildFloatingStatusCard(AppColorScheme colorScheme) {
    if (_currentOrder == null) return const SizedBox.shrink();

    // Get prep time from grouped_by_store
    String? prepTimeText;
    if (_currentOrder!.groupedByStore != null &&
        _currentOrder!.groupedByStore!.isNotEmpty) {
      final firstStore = _currentOrder!.groupedByStore![0];
      if (firstStore.sellers != null && firstStore.sellers!.isNotEmpty) {
        final firstSeller = firstStore.sellers![0];
        final prepTimeData = firstSeller.prepTime;
        if (prepTimeData != null && prepTimeData.isNotEmpty) {
          prepTimeText = prepTimeData;
        }
      }
    }

    final statusText = _getOrderStatusText();
    final statusDescription = _getStatusDescription();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and time badge row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.03,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusDescription,
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            height: 1.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Time badge
                  _buildTimeBadge(colorScheme, prepTimeText),
                ],
              ),
            ),
            // Delivery partner card - COMMENTED OUT (duplicate)
            // if (_currentOrder?.deliveryBoyName != null &&
            //     _currentOrder!.deliveryBoyName!.isNotEmpty &&
            //     _currentOrder!.deliveryBoyName != 'null') ...[
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 16),
            //     child: Container(
            //       width: double.infinity,
            //       padding: const EdgeInsets.all(8),
            //       decoration: ShapeDecoration(
            //         color: colorScheme.surfaceVariant,
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //       child: Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         children: [
            //           // Delivery partner info
            //           Expanded(
            //             child: Row(
            //               children: [
            //                 // Partner avatar
            //                 Container(
            //                   width: 44,
            //                   height: 44,
            //                   decoration: ShapeDecoration(
            //                     color:
            //                         colorScheme.primary.withValues(alpha: 0.1),
            //                     shape: const OvalBorder(),
            //                   ),
            //                   child: Center(
            //                     child: Text(
            //                       (_currentOrder?.deliveryBoyName
            //                                   ?.substring(0, 1) ??
            //                               'D')
            //                           .toUpperCase(),
            //                       style: GoogleFonts.inter(
            //                         fontSize: 18,
            //                         fontWeight: FontWeight.w700,
            //                         letterSpacing: -0.3,
            //                         color: colorScheme.primary,
            //                         height: 1.02,
            //                       ),
            //                     ),
            //                   ),
            //                 ),
            //                 const SizedBox(width: 10),
            //                 // Partner details
            //                 Expanded(
            //                   child: Column(
            //                     crossAxisAlignment: CrossAxisAlignment.start,
            //                     mainAxisSize: MainAxisSize.min,
            //                     children: [
            //                       Text(
            //                         _currentOrder?.deliveryBoyName ??
            //                             getTranslatedValue(
            //                                 context, 'delivery_partner_label'),
            //                         style: GoogleFonts.inter(
            //                           color: colorScheme.textPrimary,
            //                           fontSize: 14,
            //                           fontWeight: FontWeight.w600,
            //                           letterSpacing: -0.3,
            //                           height: 1.02,
            //                         ),
            //                         maxLines: 1,
            //                         overflow: TextOverflow.ellipsis,
            //                       ),
            //                       const SizedBox(height: 2),
            //                       Text(
            //                         'Delivery Partner',
            //                         style: GoogleFonts.inter(
            //                           color: colorScheme.textSecondary,
            //                           fontSize: 12,
            //                           fontWeight: FontWeight.w500,
            //                           letterSpacing: -0.2,
            //                           height: 1.02,
            //                         ),
            //                       ),
            //                       const SizedBox(height: 3),
            //                       Row(
            //                         mainAxisSize: MainAxisSize.min,
            //                         children: [
            //                           Icon(
            //                             Icons.star_rounded,
            //                             size: 13,
            //                             color: const Color(0xFFFFB800),
            //                           ),
            //                           const SizedBox(width: 3),
            //                           Text(
            //                             getTranslatedValue(
            //                                 context, 'default_rating'),
            //                             style: GoogleFonts.inter(
            //                               color: colorScheme.textSecondary,
            //                               fontSize: 11,
            //                               fontWeight: FontWeight.w500,
            //                               letterSpacing: -0.2,
            //                               height: 1.02,
            //                             ),
            //                           ),
            //                         ],
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //           const SizedBox(width: 8),
            //           // Action buttons
            //           Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               // Call button
            //               Material(
            //                 color: Colors.transparent,
            //                 child: InkWell(
            //                   onTap: () {
            //                     HapticFeedback.lightImpact();
            //                     final deliveryPhone =
            //                         _currentOrder?.deliveryBoyNumber ?? '';
            //                     if (deliveryPhone.isNotEmpty &&
            //                         deliveryPhone != 'null') {
            //                       launchUrl(Uri.parse('tel:$deliveryPhone'));
            //                     }
            //                   },
            //                   borderRadius: BorderRadius.circular(10),
            //                   child: Container(
            //                     width: 36,
            //                     height: 36,
            //                     decoration: ShapeDecoration(
            //                       color: colorScheme.surface,
            //                       shape: const OvalBorder(),
            //                       shadows: [
            //                         BoxShadow(
            //                           color:
            //                               Colors.black.withValues(alpha: 0.04),
            //                           blurRadius: 6,
            //                           offset: const Offset(0, 1),
            //                         ),
            //                       ],
            //                     ),
            //                     child: Icon(
            //                       Icons.phone_outlined,
            //                       size: 16,
            //                       color: colorScheme.primary,
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //               const SizedBox(width: 8),
            //               // Message button
            //               Material(
            //                 color: Colors.transparent,
            //                 child: InkWell(
            //                   onTap: () {
            //                     HapticFeedback.lightImpact();
            //                     // Add chat/message functionality here
            //                   },
            //                   borderRadius: BorderRadius.circular(10),
            //                   child: Container(
            //                     width: 36,
            //                     height: 36,
            //                     decoration: ShapeDecoration(
            //                       color: colorScheme.surface,
            //                       shape: const OvalBorder(),
            //                       shadows: [
            //                         BoxShadow(
            //                           color:
            //                               Colors.black.withValues(alpha: 0.04),
            //                           blurRadius: 6,
            //                           offset: const Offset(0, 1),
            //                         ),
            //                       ],
            //                     ),
            //                     child: Icon(
            //                       Icons.chat_outlined,
            //                       size: 16,
            //                       color: colorScheme.primary,
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            //   const SizedBox(height: 8),
            // ],
            // Delivery PIN & Note section in a Row
            if (_currentOrder?.deliveryPin != null &&
                _currentOrder!.deliveryPin!.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: colorScheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                getTranslatedValue(
                                    context, 'check_items_instruction'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delivery PIN
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getTranslatedValue(context, 'pin_label'),
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentOrder!.deliveryPin!,
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Note section
                  ],
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: colorScheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Check items on delivery. Report missing or wrong items immediately.',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCardForEarlyStages(AppColorScheme colorScheme) {
    if (_currentOrder == null) return const SizedBox.shrink();

    final status = _currentOrder!.activeStatus ?? '1';

    // Show checkout items card if in final delivery step (driver going to customer)
    final trackingProvider = context.read<OrderTrackingProvider>();
    final deliveryProgress = trackingProvider.deliveryProgress;
    final currentStep = deliveryProgress?.currentStep;
    final firebaseData = trackingProvider.firebaseData;
    final sellersVisitOrder = firebaseData?.sellersVisitOrder ?? [];

    final hasDeliveryBoyAssigned = _currentOrder?.deliveryBoyName != null &&
        _currentOrder!.deliveryBoyName!.isNotEmpty &&
        _currentOrder!.deliveryBoyName != 'null';

    final isInFinalDelivery = hasDeliveryBoyAssigned &&
        currentStep != null &&
        currentStep >= sellersVisitOrder.length;
    // Get prep time from grouped_by_store
    String? prepTimeText;
    if (_currentOrder!.groupedByStore != null &&
        _currentOrder!.groupedByStore!.isNotEmpty) {
      final firstStore = _currentOrder!.groupedByStore![0];
      if (firstStore.sellers != null && firstStore.sellers!.isNotEmpty) {
        final firstSeller = firstStore.sellers![0];
        final prepTimeData = firstSeller.prepTime;
        if (prepTimeData != null && prepTimeData.isNotEmpty) {
          prepTimeText = prepTimeData;
        }
      }
    }

    // Determine status text: Prioritize driver status > regular Firebase status > hardcoded
    String statusTitle;
    String statusDescription;

    // Check if we have driver status from ETA subscription (takes priority)
    if (_firebaseDriverOrderStatus != null &&
        _firebaseDriverOrderStatus!.isNotEmpty) {
      debugPrint(
          '✅ [StatusCard] Using Firebase driver status: $_firebaseDriverOrderStatus');
      statusTitle = _firebaseDriverOrderStatus!;
      statusDescription = _firebaseDriverOrderStatusDesc ?? '';
    }
    // Otherwise use regular Firebase status
    else if (_firebaseOrderStatus != null && _firebaseOrderStatus!.isNotEmpty) {
      debugPrint(
          '✅ [StatusCard] Using Firebase order status: $_firebaseOrderStatus');
      statusTitle = _firebaseOrderStatus!;
      statusDescription = _firebaseOrderStatusDesc ?? '';
    }
    // Fallback to hardcoded status based on order status
    else {
      debugPrint(
          '⚠️ [StatusCard] No Firebase status, using hardcoded status for status=$status');
      switch (status) {
        case '2':
          statusTitle = 'Your order was placed';
          statusDescription = 'Your order has been successfully placed.';
          break;
        case '3':
          statusTitle = 'Preparing your order';
          statusDescription = 'We\'re getting your order ready.';
          break;
        case '4':
          statusTitle = 'Order is ready';
          statusDescription = 'Your order is ready for delivery.';
          break;
        case '5':
          statusTitle = 'Order in delivery';
          statusDescription = 'Your order is on the way.';
          break;
        default:
          return const SizedBox.shrink();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: ShapeDecoration(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 0),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Icon - Using order_img.gif animation
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/animations/order_img.gif',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 7),
              // Status Text and Time
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            child: Text(
                              statusTitle,
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.02,
                                letterSpacing: -0.55,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            child: Text(
                              statusDescription,
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.02,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Time Badge - Show ETA if available, or "Order Delayed" if time elapsed
                    if (_etaMinutes != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_displayedEtaSeconds > 0)
                            // Show countdown timer
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: ShapeDecoration(
                                color: colorScheme.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _formatEtaTime(_displayedEtaSeconds),
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF9AC444),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  height: 1.04,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            )
                          else
                            // Show "Order Delayed" when time has elapsed
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: ShapeDecoration(
                                color: colorScheme.error,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Order Delayed',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      height: 1.02,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    else if (status == '1' && _countdownSeconds > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: ShapeDecoration(
                          color: colorScheme.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _formatCountdownTime(_countdownSeconds),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF9AC444),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                height: 1.04,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),

          if (_isCheckoutCompleted &&
              isInFinalDelivery &&
              _currentOrder?.deliveryPin != null &&
              _currentOrder!.deliveryPin!.isNotEmpty)
            _buildCheckoutItemsCard(colorScheme),

          // Checkout Items Section (Below status and time badge row)
          // Show when delivery boy is assigned (regardless of checkout state)
          if (_currentOrder?.deliveryBoyName != null &&
              _currentOrder!.deliveryBoyName!.isNotEmpty &&
              _currentOrder!.deliveryBoyName != 'null' &&
              !_isCheckoutCompleted)
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                // Delivery Partner Section
                // Delivery partner card (with avatar, rating, call & message)
                if (_currentOrder?.deliveryBoyName != null &&
                    _currentOrder!.deliveryBoyName!.isNotEmpty &&
                    _currentOrder!.deliveryBoyName != 'null') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: ShapeDecoration(
                      color: colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Delivery partner info
                        Expanded(
                          child: Row(
                            children: [
                              // Partner avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: ShapeDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  shape: const OvalBorder(),
                                ),
                                child: _currentOrder?.deliveryBoyProfileImage !=
                                            null &&
                                        _currentOrder!.deliveryBoyProfileImage!
                                            .isNotEmpty &&
                                        _currentOrder!
                                                .deliveryBoyProfileImage !=
                                            'null'
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: _currentOrder!
                                              .deliveryBoyProfileImage!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Shimmer.fromColors(
                                            baseColor: const Color(0xFFE0E0E0),
                                            highlightColor: const Color(0xFFF5F5F5),
                                            child: Container(width: 44, height: 44, color: Colors.white),
                                          ),
                                          errorWidget:
                                              (context, url, error) {
                                            return Center(
                                              child: Text(
                                                (_currentOrder?.deliveryBoyName
                                                            ?.substring(0, 1) ??
                                                        'D')
                                                    .toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.3,
                                                  color: colorScheme.primary,
                                                  height: 1.02,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          (_currentOrder?.deliveryBoyName
                                                      ?.substring(0, 1) ??
                                                  'D')
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                            color: colorScheme.primary,
                                            height: 1.02,
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              // Partner details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentOrder?.deliveryBoyName ??
                                          'Delivery Partner',
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                        height: 1.02,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Delivery Partner',
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.2,
                                        height: 1.02,
                                      ),
                                    ),
                                    if (_currentOrder?.deliveryBoyRating !=
                                            null &&
                                        _currentOrder!.deliveryBoyRating !=
                                            'null' &&
                                        _currentOrder!
                                            .deliveryBoyRating!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 13,
                                            color: const Color(0xFFFFB800),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _currentOrder!.deliveryBoyRating!,
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.2,
                                              height: 1.02,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Call button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final deliveryPhone =
                                      _currentOrder?.deliveryBoyNumber ?? '';
                                  if (deliveryPhone.isNotEmpty &&
                                      deliveryPhone != 'null') {
                                    launchUrl(Uri.parse('tel:$deliveryPhone'));
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: ShapeDecoration(
                                    color: colorScheme.surface,
                                    shape: const OvalBorder(),
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Message button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final driverName =
                                      _currentOrder?.deliveryBoyName ??
                                          'Delivery Partner';
                                  final driverId = int.tryParse(
                                      _currentOrder?.deliveryBoyId ?? '');
                                  final orderId =
                                      _currentOrder?.id ?? widget.orderId ?? '';

                                  if (orderId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderChatScreen(
                                          orderId: orderId,
                                          driverName: driverName,
                                          driverId: driverId,
                                          driverPhone:
                                              _currentOrder?.deliveryBoyNumber,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Order information not available'),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: ShapeDecoration(
                                    color: colorScheme.surface,
                                    shape: const OvalBorder(),
                                    shadows: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.04),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.chat_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Container(
                //   width: double.infinity,
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                //   decoration: ShapeDecoration(
                //     color: colorScheme.surfaceVariant,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     mainAxisAlignment: MainAxisAlignment.start,
                //     crossAxisAlignment: CrossAxisAlignment.center,
                //     children: [
                //       // Delivery Partner Avatar
                //       Container(
                //         width: 48,
                //         height: 48,
                //         decoration: BoxDecoration(
                //           shape: BoxShape.circle,
                //           color: colorScheme.textPrimary.withValues(alpha: 0.1),
                //         ),
                //         child: Center(
                //           child: Text(
                //             _currentOrder!.deliveryBoyName
                //                     ?.substring(0, 1)
                //                     .toUpperCase() ??
                //                 'D',
                //             style: GoogleFonts.inter(
                //               color: colorScheme.textPrimary,
                //               fontSize: 18,
                //               fontWeight: FontWeight.w700,
                //             ),
                //           ),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       // Delivery Partner Info
                //       Expanded(
                //         child: Column(
                //           mainAxisSize: MainAxisSize.min,
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Text(
                //               _currentOrder!.deliveryBoyName ??
                //                   'Delivery Partner',
                //               style: GoogleFonts.inter(
                //                 color: colorScheme.textPrimary,
                //                 fontSize: 14,
                //                 fontWeight: FontWeight.w600,
                //                 height: 1.2,
                //               ),
                //             ),
                //             const SizedBox(height: 4),
                //             Row(
                //               mainAxisSize: MainAxisSize.min,
                //               children: [
                //                 const Icon(
                //                   Icons.star_rounded,
                //                   color: Color(0xFFFFC107),
                //                   size: 16,
                //                 ),
                //                 const SizedBox(width: 4),
                //                 Text(
                //                   '4.8 (120 reviews)',
                //                   style: GoogleFonts.inter(
                //                     color: colorScheme.textSecondary,
                //                     fontSize: 12,
                //                     fontWeight: FontWeight.w500,
                //                     height: 1.2,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 12),
                // Bottom Note Section
                // Show checkout items card when checkout is completed and has PIN

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: ShapeDecoration(
                    color: colorScheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Check items on delivery. Report missing or wrong items immediately.',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCheckoutItemsCard(AppColorScheme colorScheme) {
    if (_currentOrder?.deliveryPin == null ||
        _currentOrder!.deliveryPin!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Instruction section (left side)
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: colorScheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'Share this '),
                            TextSpan(
                              text: 'PIN',
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                height: 1.4,
                              ),
                            ),
                            const TextSpan(text: ' with your delivery partner '),
                            TextSpan(
                              text: 'after checkout',
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Delivery PIN (right side)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getTranslatedValue(context, 'pin_label'),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentOrder!.deliveryPin!,
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.4,
                            ),
                          ),
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
  }

  Widget _buildBottomSheet(
      ScrollController scrollController, AppColorScheme colorScheme) {
    return Container(
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Order Products Banner
                  if (_currentOrder?.items != null &&
                      _currentOrder!.items!.isNotEmpty) ...[
                    _buildOrderItemsBanner(colorScheme),
                    const SizedBox(height: 16),
                  ],

                  // Delivery Progress Widget (shows real-time progress from Firebase)
                  // Consumer<OrderTrackingProvider>(
                  //   builder: (context, trackingProvider, _) {
                  //     if (trackingProvider.isFirebaseActive &&
                  //         trackingProvider.deliveryProgress != null) {
                  //       return Column(
                  //         children: [
                  //           _buildDeliveryProgressWidget(
                  //               trackingProvider.deliveryProgress!,
                  //               colorScheme),
                  //           const SizedBox(height: 16),
                  //         ],
                  //       );
                  //     }
                  //     return const SizedBox.shrink();
                  //   },
                  // ),

                  // Customer Details
                  _buildCustomerDetailsCard(colorScheme),
                  const SizedBox(height: 16),

                  // Order Details
                  _buildOrderDetailsCard(colorScheme),
                  const SizedBox(height: 16),

                  // Store Contact Card
                  _buildStoreContactCard(colorScheme),
                  const SizedBox(height: 16),

                  // Promotional Banner (if applicable)
                  _buildPromotionalBanner(colorScheme),
                  const SizedBox(height: 16),

                  // Delivery partner card - COMMENTED OUT (duplicate)
                  // if (_currentOrder?.deliveryBoyName != null &&
                  //     _currentOrder!.deliveryBoyName!.isNotEmpty &&
                  //     _currentOrder!.deliveryBoyName != 'null') ...[
                  //   Container(
                  //     width: double.infinity,
                  //     padding: const EdgeInsets.all(16),
                  //     decoration: ShapeDecoration(
                  //       color: colorScheme.surfaceVariant,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       crossAxisAlignment: CrossAxisAlignment.center,
                  //       children: [
                  //         // Delivery partner info
                  //         Expanded(
                  //           child: Row(
                  //             children: [
                  //               // Partner avatar
                  //               Container(
                  //                 width: 44,
                  //                 height: 44,
                  //                 decoration: ShapeDecoration(
                  //                   color: colorScheme.primary
                  //                       .withValues(alpha: 0.1),
                  //                   shape: const OvalBorder(),
                  //                 ),
                  //                 child: Center(
                  //                   child: Text(
                  //                     (_currentOrder?.deliveryBoyName
                  //                                 ?.substring(0, 1) ??
                  //                             'D')
                  //                         .toUpperCase(),
                  //                     style: GoogleFonts.inter(
                  //                       fontSize: 18,
                  //                       fontWeight: FontWeight.w700,
                  //                       letterSpacing: -0.3,
                  //                       color: colorScheme.primary,
                  //                       height: 1.02,
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),
                  //               const SizedBox(width: 10),
                  //               // Partner details
                  //               Expanded(
                  //                 child: Column(
                  //                   crossAxisAlignment:
                  //                       CrossAxisAlignment.start,
                  //                   mainAxisSize: MainAxisSize.min,
                  //                   children: [
                  //                     Text(
                  //                       _currentOrder?.deliveryBoyName ??
                  //                           'Delivery Partner',
                  //                       style: GoogleFonts.inter(
                  //                         color: colorScheme.textPrimary,
                  //                         fontSize: 14,
                  //                         fontWeight: FontWeight.w600,
                  //                         letterSpacing: -0.3,
                  //                         height: 1.02,
                  //                       ),
                  //                       maxLines: 1,
                  //                       overflow: TextOverflow.ellipsis,
                  //                     ),
                  //                     const SizedBox(height: 2),
                  //                     Text(
                  //                       'Delivery Partner',
                  //                       style: GoogleFonts.inter(
                  //                         color: colorScheme.textSecondary,
                  //                         fontSize: 12,
                  //                         fontWeight: FontWeight.w500,
                  //                         letterSpacing: -0.2,
                  //                         height: 1.02,
                  //                       ),
                  //                     ),
                  //                     const SizedBox(height: 3),
                  //                     Row(
                  //                       mainAxisSize: MainAxisSize.min,
                  //                       children: [
                  //                         Icon(
                  //                           Icons.star_rounded,
                  //                           size: 13,
                  //                           color: const Color(0xFFFFB800),
                  //                         ),
                  //                         const SizedBox(width: 3),
                  //                         Text(
                  //                           '4.5',
                  //                           style: GoogleFonts.inter(
                  //                             color: colorScheme.textSecondary,
                  //                             fontSize: 11,
                  //                             fontWeight: FontWeight.w500,
                  //                             letterSpacing: -0.2,
                  //                             height: 1.02,
                  //                           ),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //         // Action buttons
                  //         const SizedBox(width: 8),
                  //         Row(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             // Call button
                  //             Material(
                  //               color: Colors.transparent,
                  //               child: InkWell(
                  //                 onTap: () {
                  //                   HapticFeedback.lightImpact();
                  //                   final deliveryPhone =
                  //                       _currentOrder?.deliveryBoyNumber ?? '';
                  //                   if (deliveryPhone.isNotEmpty &&
                  //                       deliveryPhone != 'null') {
                  //                     launchUrl(
                  //                         Uri.parse('tel:$deliveryPhone'));
                  //                   }
                  //                 },
                  //                 borderRadius: BorderRadius.circular(10),
                  //                 child: Container(
                  //                   width: 36,
                  //                   height: 36,
                  //                   decoration: ShapeDecoration(
                  //                     color: colorScheme.surface,
                  //                     shape: const OvalBorder(),
                  //                     shadows: [
                  //                       BoxShadow(
                  //                         color: Colors.black
                  //                             .withValues(alpha: 0.04),
                  //                         blurRadius: 6,
                  //                         offset: const Offset(0, 1),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                   child: Icon(
                  //                     Icons.phone_outlined,
                  //                     size: 16,
                  //                     color: colorScheme.primary,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //             const SizedBox(width: 8),
                  //             // Message button
                  //             Material(
                  //               color: Colors.transparent,
                  //               child: InkWell(
                  //                 onTap: () {
                  //                   HapticFeedback.lightImpact();
                  //                   final driverName =
                  //                       _currentOrder?.deliveryBoyName ??
                  //                           'Delivery Partner';
                  //                   final driverId = int.tryParse(
                  //                       _currentOrder?.deliveryBoyId ?? '');
                  //                   final orderId = _currentOrder?.id ??
                  //                       widget.orderId ??
                  //                       '';
                  //
                  //                   if (orderId.isNotEmpty) {
                  //                     Navigator.push(
                  //                       context,
                  //                       MaterialPageRoute(
                  //                         builder: (context) => OrderChatScreen(
                  //                           orderId: orderId,
                  //                           driverName: driverName,
                  //                           driverId: driverId,
                  //                           driverPhone: _currentOrder
                  //                               ?.deliveryBoyNumber,
                  //                         ),
                  //                       ),
                  //                     );
                  //                   } else {
                  //                     ScaffoldMessenger.of(context)
                  //                         .showSnackBar(
                  //                       const SnackBar(
                  //                         content: Text(
                  //                             'Order information not available'),
                  //                       ),
                  //                     );
                  //                   }
                  //                 },
                  //                 borderRadius: BorderRadius.circular(10),
                  //                 child: Container(
                  //                   width: 36,
                  //                   height: 36,
                  //                   decoration: ShapeDecoration(
                  //                     color: colorScheme.surface,
                  //                     shape: const OvalBorder(),
                  //                     shadows: [
                  //                       BoxShadow(
                  //                         color: Colors.black
                  //                             .withValues(alpha: 0.04),
                  //                         blurRadius: 6,
                  //                         offset: const Offset(0, 1),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                   child: Icon(
                  //                     Icons.chat_outlined,
                  //                     size: 16,
                  //                     color: colorScheme.primary,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  //   const SizedBox(height: 16),
                  // ],

                  // Why this order has no Cancel option
                  _buildOrderCancelNote(),

                  // Customer Support
                  _buildCustomerSupportCard(colorScheme),
                  const SizedBox(height: 16),

                  // Cancel Order Button (hidden when order is in preparation)
                  if (!_isPreparation) _buildCancelOrderButton(colorScheme),

                  SizedBox(height: 40),
                ],
              ),
            ),
            // Fixed Bottom Navigation - Checkout Button
            if (!_isCheckoutCompleted)
              ..._buildCheckoutButtonSection(colorScheme),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription() {
    if (_currentOrder == null) return '';
    String status = _currentOrder!.activeStatus ?? '1';
    switch (status) {
      case '1':
        return getTranslatedValue(context, 'order_confirmed_message');
      case '2':
      case '3':
      case '4':
        return getTranslatedValue(context, 'order_preparing_message');

      case '5':
        return getTranslatedValue(context, 'partner_on_way_message');
      case '6':
        return getTranslatedValue(context, 'order_delivered_message');
      case '7':
        return getTranslatedValue(context, 'order_cancelled_message');
      default:
        return getTranslatedValue(context, 'order_ready_message');
    }
  }

  Widget _buildDeliveryPersonCard(AppColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslatedValue(context, 'delivery_partner_label'),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.textSecondary,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _currentOrder!.deliveryBoyName!
                        .substring(0, 1)
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentOrder!.deliveryBoyName!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFB800),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textPrimary,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          getTranslatedValue(context, 'deliveries_count'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textSecondary,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_currentOrder!.deliveryBoyNumber != null &&
                  _currentOrder!.deliveryBoyNumber!.isNotEmpty &&
                  _currentOrder!.deliveryBoyNumber != 'null')
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      launchUrl(
                          Uri.parse('tel:${_currentOrder!.deliveryBoyNumber}'));
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.phone,
                        color: colorScheme.surface,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build delivery progress widget showing current step and status from Firebase
  /// Displays pickup and delivery progress with visual indicators
  Widget _buildDeliveryProgressWidget(
      DeliveryProgress progress, AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            getTranslatedValue(context, 'delivery_progress_label'),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Progress steps
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 0: Pickup
              _buildProgressStep(
                stepIndex: 0,
                stepName: getTranslatedValue(context, 'pickup_label'),
                status: progress.stepStatuses?[0] ?? 'notStarted',
                colorScheme: colorScheme,
              ),

              // Vertical connector between steps
              if ((progress.stepStatuses?.length ?? 0) > 1)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    width: 2,
                    height: 24,
                    color: _getStepStatusColor(
                            progress.stepStatuses?[0] ?? 'notStarted')
                        .withValues(alpha: 0.3),
                  ),
                ),

              // Step 1: Out for Delivery
              if ((progress.stepStatuses?.length ?? 0) > 1)
                _buildProgressStep(
                  stepIndex: 1,
                  stepName:
                      getTranslatedValue(context, 'out_for_delivery_label'),
                  status: progress.stepStatuses?[1] ?? 'notStarted',
                  colorScheme: colorScheme,
                ),

              // Vertical connector to delivery completed
              if ((progress.stepStatuses?.length ?? 0) > 2)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    width: 2,
                    height: 24,
                    color: _getStepStatusColor(
                            progress.stepStatuses?[1] ?? 'notStarted')
                        .withValues(alpha: 0.3),
                  ),
                ),

              // Step 2: Delivered
              if ((progress.stepStatuses?.length ?? 0) > 2)
                _buildProgressStep(
                  stepIndex: 2,
                  stepName: getTranslatedValue(context, 'delivered_label'),
                  status: progress.stepStatuses?[2] ?? 'notStarted',
                  colorScheme: colorScheme,
                ),
            ],
          ),

          // Last update time
          if (progress.updatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Last updated: ${_formatTimeAgo(progress.updatedAt!)}',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build a single progress step with visual indicator
  Widget _buildProgressStep({
    required int stepIndex,
    required String stepName,
    required String status,
    required AppColorScheme colorScheme,
  }) {
    final isCompleted = status == 'completed';
    final isInProgress = status == 'inProgress';
    final statusColor = _getStepStatusColor(status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Status circle indicator
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withValues(alpha: 0.1),
            border: Border.all(
              color: statusColor,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    color: statusColor,
                    size: 16,
                  )
                : isInProgress
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 12),

        // Step name and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stepName,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusLabel(status),
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get the color for a specific step status
  Color _getStepStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'inprogress':
        return Colors.orange;
      case 'notstarted':
      default:
        return Colors.grey;
    }
  }

  /// Get the human-readable label for a step status
  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return getTranslatedValue(context, 'completed_label');
      case 'inprogress':
        return getTranslatedValue(context, 'in_progress_label');
      case 'notstarted':
      default:
        return getTranslatedValue(context, 'not_started_label');
    }
  }

  /// Format DateTime to "time ago" format
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildOrderItemsBanner(AppColorScheme colorScheme) {
    // Calculate total items from grouped_by_store structure
    int totalItems = 0;
    String storeName = getTranslatedValue(context, 'store_label');
    String? storeIcon;
    Map<String, dynamic>? firstItem;
    List<Map<String, dynamic>> allItems = [];

    if (_currentOrder?.groupedByStore != null &&
        _currentOrder!.groupedByStore!.isNotEmpty) {
      final firstStore = _currentOrder!.groupedByStore![0];
      storeName =
          firstStore.storeName ?? getTranslatedValue(context, 'store_label');
      storeIcon = firstStore.storeIcon;

      // Collect ALL items from all stores and sellers
      for (var store in _currentOrder!.groupedByStore!) {
        // Get admin-managed items from store level
        if (store.items != null) {
          for (var item in store.items!) {
            if (item is Map<String, dynamic>) {
              allItems.add(item);
              totalItems++;
              if (firstItem == null) {
                firstItem = item;
              }
            }
          }
        }

        // Get seller-managed items
        if (store.sellers != null) {
          for (var seller in store.sellers!) {
            final sellerName = seller.sellerName ?? '';
            if (seller.items != null) {
              for (var item in seller.items!) {
                if (item is Map<String, dynamic>) {
                  // Add seller name to the item for display
                  final itemWithSeller = Map<String, dynamic>.from(item);
                  itemWithSeller['seller_name'] = sellerName;
                  allItems.add(itemWithSeller);
                  totalItems++;
                  if (firstItem == null) {
                    firstItem = itemWithSeller;
                  }
                }
              }
            }
          }
        }
      }
    }

    // Add custom combo items from order level
    if (_currentOrder?.customCombos != null) {
      for (var combo in _currentOrder!.customCombos!) {
        if (combo is Map<String, dynamic>) {
          final comboName = combo['combo_name']?.toString() ?? 'Custom Combo';
          final comboQty = combo['quantity']?.toString() ?? '1';
          final comboPrice = combo['price']?.toString() ?? '0';

          final comboItem = {
            'product_name': comboName,
            'quantity': comboQty,
            'price': comboPrice,
            'measurement': '',
            'unit': '',
          };
          allItems.add(comboItem);
          totalItems++;
          if (firstItem == null) {
            firstItem = comboItem;
          }
        }
      }
    }

    return Column(
      children: [
        // Store header with icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
          child: Row(
            children: [
              // Store Icon
              if (storeIcon != null && storeIcon.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: setNetworkImg(
                    image: storeIcon,
                    width: 40,
                    height: 40,
                    boxFit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: colorScheme.border,
                    size: 24,
                  ),
                ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$totalItems item${totalItems > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        DashedDivider(
          color: Colors.black12,
          height: 1,
        ),

        // First 2 items preview
        ...allItems.take(2).map((item) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: ShapeDecoration(
                color: colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.divider,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item['quantity']}x',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name']?.toString() ?? '',
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        // Show seller name if available (for seller-managed items)
                        if (item['seller_name'] != null &&
                            item['seller_name'].toString().isNotEmpty) ...[
                          Text(
                            'by ${item['seller_name']}',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                        Text(
                          '${item['measurement']} ${item['unit']}',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '₹${item['price']}',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            )),

        // More items indicator
        if (totalItems > 2)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAllItemsBottomSheet(allItems, storeName, storeIcon);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'View all items',
                      style: GoogleFonts.inter(
                        color: colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomerDetailsCard(AppColorScheme colorScheme) {
    // Extract customer details from cart info
    String customerName = _currentOrder?.cartInfo?['contact_name'] ??
        getTranslatedValue(context, 'customer_label');
    String customerMobile = _currentOrder?.cartInfo?['contact_phone'] ?? '';
    String customerAddress = _currentOrder?.orderAddress ??
        getTranslatedValue(context, 'no_address_provided');
    String? deliveryInstructions;

    if (_currentOrder?.cartInfo != null) {
      final cartInfo = _currentOrder!.cartInfo!;
      // Get receiver details from cart info
      if (cartInfo['receiver_name'] != null &&
          cartInfo['receiver_name'].toString().isNotEmpty) {
        customerName = cartInfo['receiver_name'].toString();
      }
      if (cartInfo['receiver_mobile'] != null &&
          cartInfo['receiver_mobile'].toString().isNotEmpty) {
        customerMobile = cartInfo['receiver_mobile'].toString();
      }
      if (cartInfo['delivery_address'] != null &&
          cartInfo['delivery_address'].toString().isNotEmpty) {
        customerAddress = cartInfo['delivery_address'].toString();
      }
      if (cartInfo['delivery_instructions'] != null &&
          cartInfo['delivery_instructions'].toString().isNotEmpty) {
        deliveryInstructions = cartInfo['delivery_instructions'].toString();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promotional Banner Carousel
          if (_promotionalBanners.isNotEmpty) ...[
            Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _promotionalBanners.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                  // Restart auto-scroll timer when user manually changes page
                  _startAutoScroll();
                },
                itemBuilder: (context, index) {
                  final banner = _promotionalBanners[index];
                  return GestureDetector(
                    onTap: () {
                      // Handle banner tap - optional: open URL if slider_url exists
                      if (banner.sliderUrl != null &&
                          banner.sliderUrl!.isNotEmpty) {
                        // You could launch URL here
                        // launchUrl(Uri.parse(banner.sliderUrl!));
                      }
                    },
                    onPanStart: (_) {
                      // Pause auto-scroll when user starts interacting
                      _autoScrollTimer?.cancel();
                    },
                    onPanEnd: (_) {
                      // Resume auto-scroll after user interaction
                      _startAutoScroll();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surface,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => imgErrorWidget(icon: Icons.restaurant_menu_rounded),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Page indicators
            if (_promotionalBanners.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _promotionalBanners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentBannerIndex
                          ? colorScheme.primary
                          : colorScheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],

          Text(
            getTranslatedValue(context, 'delivery_details_title'),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_outline,
                    size: 18, color: colorScheme.textSecondary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  customerName.toCapitalized(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          if (customerMobile.isNotEmpty) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.phone_outlined,
                      size: 18, color: colorScheme.textSecondary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    customerMobile,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.location_on_outlined,
                    size: 18, color: colorScheme.textSecondary),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  customerAddress,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          if (deliveryInstructions != null) ...[
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.note_outlined,
                      size: 18, color: colorScheme.textSecondary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Instructions',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        deliveryInstructions,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.textPrimary,
                          height: 1.4,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslatedValue(context, 'bill_details_title'),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 16),

          // Payment Method
          if (_currentOrder?.paymentMethod != null &&
              _currentOrder!.paymentMethod!.isNotEmpty)
            _buildOrderDetailRow(
                getTranslatedValue(context, 'payment_method_label'),
                _currentOrder!.paymentMethod!,
                colorScheme),

          // Transaction ID
          if (_currentOrder?.transactionId != null &&
              _currentOrder!.transactionId!.isNotEmpty &&
              _currentOrder!.transactionId != '0')
            _buildOrderDetailRow(
                getTranslatedValue(context, 'transaction_id_label'),
                _currentOrder!.transactionId!,
                colorScheme),

          SizedBox(height: 4),

          // Use billing_breakdown if available
          if (_currentOrder?.billingBreakdown != null &&
              _currentOrder!.billingBreakdown!.isNotEmpty)
            ..._buildBillingBreakdown(colorScheme)
          else
            // Fallback to old method if billing_breakdown not available
            ..._buildFallbackBilling(colorScheme),

          Container(
            height: 1,
            color: colorScheme.divider,
            margin: EdgeInsets.symmetric(vertical: 12),
          ),

          // Total - Find the total from billing_breakdown or use fallback
          _buildTotalRow(colorScheme),

          // Pre-order badge
          if (_hasPreOrderItems) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF856404)),
                  SizedBox(width: 6),
                  Text(
                    'Pre-Order',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF856404),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasPreOrderItems {
    final stores = _currentOrder?.groupedByStore ?? [];
    for (final store in stores) {
      for (final item in store.items ?? []) {
        if (item is Map && (item['is_pre_order_item'] == 1 || item['is_pre_order_item'] == '1')) return true;
      }
      for (final seller in store.sellers ?? []) {
        for (final item in seller.items ?? []) {
          if (item is Map && (item['is_pre_order_item'] == 1 || item['is_pre_order_item'] == '1')) return true;
        }
      }
    }
    return false;
  }

  List<Widget> _buildBillingBreakdown(AppColorScheme colorScheme) {
    List<Widget> widgets = [];

    for (var item in _currentOrder!.billingBreakdown!) {
      if (item is Map<String, dynamic>) {
        final label = item['label']?.toString() ?? '';
        final amount = item['amount'];
        final currency = item['currency']?.toString() ?? '₹';
        final isCredit = item['is_credit'] == true;
        final isTotal = item['is_total'] == true;

        // Skip the total row as we display it separately
        if (isTotal) continue;

        // Skip 'Multi Order Charge' if it's a single order (only one store/seller)
        if (label.toLowerCase().contains('multi order charge') &&
            (_currentOrder?.groupedByStore?.length ?? 0) <= 1) {
          continue;
        }

        String displayAmount = '';
        if (amount != null) {
          if (isCredit) {
            displayAmount = '-$currency${amount.toString()}';
          } else {
            displayAmount = '$currency${amount.toString()}';
          }
        }

        widgets.add(
          _buildOrderDetailRow(
            label,
            displayAmount,
            colorScheme,
            valueColor: isCredit ? colorScheme.primary : null,
          ),
        );
      }
    }

    return widgets;
  }

  List<Widget> _buildFallbackBilling(AppColorScheme colorScheme) {
    List<Widget> widgets = [];

    // Subtotal
    widgets.add(_buildOrderDetailRow(
      getTranslatedValue(context, 'subtotal_label'),
      _currentOrder?.remainingTotal?.currency ??
          _currentOrder?.total?.currency ??
          '₹0',
      colorScheme,
    ));

    // Additional Charges
    if (_currentOrder?.additionalCharges != null &&
        _currentOrder!.additionalCharges!.isNotEmpty) {
      for (var charge in _currentOrder!.additionalCharges!) {
        widgets.add(_buildOrderDetailRow(
          charge.title ?? getTranslatedValue(context, 'charge_label'),
          charge.amount?.toString().currency ?? '₹0',
          colorScheme,
        ));
      }
    }

    // Delivery Charge
    widgets.add(_buildOrderDetailRow(
      getTranslatedValue(context, 'delivery_charge_label'),
      _currentOrder?.deliveryCharge?.currency ?? '₹0',
      colorScheme,
    ));

    // Promo Discount
    if (_currentOrder?.promoDiscount != null &&
        double.parse(_currentOrder!.promoDiscount ?? "0.0") > 0.0) {
      widgets.add(_buildOrderDetailRow(
        'Discount${_currentOrder!.promoCode != null && _currentOrder!.promoCode!.isNotEmpty ? ' (${_currentOrder!.promoCode})' : ''}',
        '-${_currentOrder!.promoDiscount?.currency ?? '₹0'}',
        colorScheme,
        valueColor: colorScheme.primary,
      ));
    }

    // Wallet Balance
    if (_currentOrder?.walletBalance != null &&
        double.parse(_currentOrder!.walletBalance ?? "0.0") > 0.0) {
      widgets.add(_buildOrderDetailRow(
        getTranslatedValue(context, 'wallet_label'),
        '-${_currentOrder!.walletBalance?.currency ?? '₹0'}',
        colorScheme,
        valueColor: colorScheme.primary,
      ));
    }

    return widgets;
  }

  Widget _buildTotalRow(AppColorScheme colorScheme) {
    String totalLabel = getTranslatedValue(context, 'total_label');
    String totalAmount = '₹0';

    // Try to get from billing_breakdown first
    if (_currentOrder?.billingBreakdown != null) {
      for (var item in _currentOrder!.billingBreakdown!) {
        if (item is Map<String, dynamic> && item['is_total'] == true) {
          totalLabel = item['label']?.toString() ??
              getTranslatedValue(context, 'total_label');
          final amount = item['amount'];
          final currency = item['currency']?.toString() ?? '₹';
          if (amount != null) {
            totalAmount = '$currency${amount.toString()}';
          }
          break;
        }
      }
    }

    // Fallback to remainingFinal or finalTotal
    if (totalAmount == '₹0') {
      totalAmount = _currentOrder?.remainingFinal?.currency ??
          _currentOrder?.finalTotal?.currency ??
          '₹0';
    }

    return Container(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalLabel,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            totalAmount,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(
      String label, String value, AppColorScheme colorScheme,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? colorScheme.textPrimary,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner(AppColorScheme colorScheme) {
    // Only show if there's a promo code applied
    if (_currentOrder?.promoCode == null || _currentOrder!.promoCode!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_offer_outlined,
              color: colorScheme.surface,
              size: 24,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslatedValue(context, 'promo_applied_label'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.surface,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _currentOrder!.promoCode!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.surface.withValues(alpha: 0.95),
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          if (_currentOrder!.promoDiscount != null &&
              _currentOrder!.promoDiscount!.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '-${_currentOrder!.promoDiscount!.currency}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Note shown right above the customer-support card telling the customer why
  /// this order has no Cancel option. Collapses to nothing while the order is
  /// still cancellable.
  Widget _buildOrderCancelNote() {
    final ItemCancelNote? note = resolveOrderCancelNote(_currentOrder);
    if (note == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ItemCancelNoteRow(
        note: note,
        overrideText: note.orderMessage(context),
        fontSize: 12.5,
        margin: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCustomerSupportCard(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.headset_mic_outlined,
              color: colorScheme.textSecondary,
              size: 24,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslatedValue(context, 'need_help_title'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(getTranslatedValue(context, 'contact_support_message'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textSecondary,
                      height: 1.3,
                      letterSpacing: -0.2,
                    )),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider<ChatProvider>(
                          create: (context) => ChatProvider(),
                        ),
                      ],
                      child: CustomerSupportChatScreen(
                        orderId: widget.orderId ?? '',
                      ),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  getTranslatedValue(context, 'chat_button'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.surface,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelOrderButton(AppColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showCancelOrderDialog();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.error, width: 1.5),
          ),
          child: Text(
            getTranslatedValue(context, 'cancel_order_button'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCheckoutButtonSection(AppColorScheme colorScheme) {
    // Show checkout button ONLY when Firebase flag is_checkout is set to 1
    final showCheckout = _showCheckoutFromFirebase;

    // Only show if conditions met
    if (!showCheckout) {
      return [];
    }

    return [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showCheckoutConfirmationDialog(colorScheme);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Checkout',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  void _showCheckoutConfirmationDialog(AppColorScheme colorScheme) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shopping bag icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Are you sure',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  'Please check your order and confirm if all items\nare delivered.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Buttons
                Row(
                  children: [
                    // No button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'No',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Yes button
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _isCheckoutCompleted = true;
                              _showCheckoutFromFirebase =
                                  false; // Hide checkout button after completion
                            });
                            // Show success message
                            showMessage(
                              context,
                              'Checkout completed!',
                              MessageType.success,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Yes',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllItemsBottomSheet(
      List<Map<String, dynamic>> items, String storeName, String? storeIcon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme =
            context.watch<app_theme.ThemeProvider>().colorScheme;

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: colorScheme.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header with gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surface,
                        colorScheme.surfaceVariant.withValues(alpha: 0.3),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                  child: Row(
                    children: [
                      // Icon with gradient background
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Items',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.textPrimary,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              getTranslatedValue(
                                  context, 'order_breakdown_subtitle'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.textSecondary,
                                letterSpacing: -0.1,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close button with hover effect
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.border,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colorScheme.iconPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Items list with store-wise and combo-wise grouping
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    // physics: const BouncingScrollPhysics(),
                    children: [
                      if (_currentOrder?.groupedByStore != null)
                        ...() {
                          final stores = _currentOrder!.groupedByStore!;
                          final adminStores = stores
                              .where((s) => s.managedByAdmin == true)
                              .toList();
                          final nonAdminStores = stores
                              .where((s) => s.managedByAdmin != true)
                              .toList();
                          final combos = (_currentOrder?.customCombos ?? [])
                              .whereType<Map<String, dynamic>>()
                              .toList();
                          return [
                            if (adminStores.isNotEmpty)
                              _buildZenfooCard(adminStores, colorScheme,
                                  combos: combos),
                            ...nonAdminStores.map(
                                (store) => _buildStoreCard(store, colorScheme)),
                          ];
                        }(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZenfooCard(
      List<GroupedByStore> adminStores, AppColorScheme colorScheme,
      {List<Map<String, dynamic>> combos = const []}) {
    // Aggregate all items from all admin-managed stores
    final List<Widget> itemWidgets = [];
    for (final store in adminStores) {
      for (final seller in store.sellers ?? []) {
        for (final item
            in (seller.items ?? []).whereType<Map<String, dynamic>>()) {
          itemWidgets.add(_buildProductCard(item, colorScheme,
              storeId: store.storeId,
              isSuperMart: store.isSuperMart ?? false));
        }
      }
      for (final item
          in (store.items ?? []).whereType<Map<String, dynamic>>()) {
        itemWidgets.add(_buildProductCard(item, colorScheme,
            storeId: store.storeId,
            isSuperMart: store.isSuperMart ?? false));
      }
    }

    final comboProductCount = combos.fold<int>(
        0, (sum, c) => sum + ((c['products'] as List?)?.length ?? 0));
    final totalItems = itemWidgets.length + comboProductCount;
    final displayIcon = adminStores.first.storeIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceVariant.withValues(alpha: 0.4),
                  colorScheme.surfaceVariant.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.border.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: displayIcon != null && displayIcon.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: setNetworkImg(
                            image: displayIcon,
                            width: 52,
                            height: 52,
                            boxFit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.15),
                                colorScheme.primary.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zenfoo Store',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_basket_rounded,
                                    size: 14, color: colorScheme.primary),
                                const SizedBox(width: 5),
                                Text(
                                  '$totalItems item${totalItems > 1 ? 's' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...itemWidgets,
                // Combo sub-section
                if (combos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Combo',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF9800),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  ...combos.expand((combo) {
                    final productsList = combo['products'] as List? ?? [];
                    return productsList
                        .whereType<Map<String, dynamic>>()
                        .map((p) => _buildProductCard(p, colorScheme,
                            isCombo: true));
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(GroupedByStore store, AppColorScheme colorScheme,
      {List<Map<String, dynamic>> combos = const []}) {
    final isManagedByAdmin = store.managedByAdmin == true;
    final sellers = store.sellers ?? [];
    final directItems =
        (store.items ?? []).whereType<Map<String, dynamic>>().toList();

    // Heading: "Zenfoo" for admin-managed, seller name otherwise
    final displayName = isManagedByAdmin
        ? 'Zenfoo Store'
        : (sellers.isNotEmpty
            ? sellers.first.sellerName ?? store.storeName ?? ''
            : store.storeName ?? '');

    // Icon: store icon for admin-managed, seller image otherwise
    final displayIcon = isManagedByAdmin
        ? store.storeIcon
        : (sellers.isNotEmpty ? sellers.first.sellerImage : null);

    // Calculate total items
    int totalItems = directItems.length +
        sellers.fold<int>(0, (sum, s) => sum + (s.items?.length ?? 0));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceVariant.withValues(alpha: 0.4),
                  colorScheme.surfaceVariant.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.border.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: displayIcon != null && displayIcon.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: setNetworkImg(
                            image: displayIcon,
                            width: 52,
                            height: 52,
                            boxFit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.15),
                                colorScheme.primary.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_basket_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$totalItems item${totalItems > 1 ? 's' : ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sellers.isNotEmpty)
                  ...sellers.map((seller) {
                    final itemsList = seller.items ?? [];
                    final items =
                        itemsList.whereType<Map<String, dynamic>>().toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items.map((item) {
                        final itemWithSeller = Map<String, dynamic>.from(item);
                        itemWithSeller['seller_name'] = seller.sellerName ?? '';
                        return _buildProductCard(itemWithSeller, colorScheme,
                            storeId: store.storeId,
                            isSuperMart: store.isSuperMart ?? false);
                      }).toList(),
                    );
                  }).toList(),

                if (directItems.isNotEmpty)
                  ...directItems
                      .map((item) => _buildProductCard(item, colorScheme,
                          storeId: store.storeId,
                          isSuperMart: store.isSuperMart ?? false))
                      .toList(),

                // Combo sub-section (only for Zenfoo / admin-managed stores)
                if (combos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Combo',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF9800),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  ...combos.expand((combo) {
                    final productsList = combo['products'] as List? ?? [];
                    return productsList
                        .whereType<Map<String, dynamic>>()
                        .map((p) => _buildProductCard(p, colorScheme,
                            isCombo: true));
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboCard(
      Map<String, dynamic> combo, AppColorScheme colorScheme) {
    final productsList = combo['products'] as List? ?? [];
    final products = productsList.whereType<Map<String, dynamic>>().toList();
    final comboName = combo['combo_name']?.toString() ?? 'Combo';
    final subTotal =
        combo['sub_total']?.toString() ?? combo['price']?.toString() ?? '0';
    final discount = combo['discount_percentage']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combo Header with attractive gradient
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9800).withValues(alpha: 0.08),
                  const Color(0xFFFF9800).withValues(alpha: 0.03),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Combo Icon with vibrant gradient
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF9800),
                        Color(0xFFFF6B00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              comboName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.textPrimary,
                                letterSpacing: -0.4,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFF6B00)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              getTranslatedValue(context, 'combo_badge'),
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF9800).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                const Color(0xFFFF9800).withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_rounded,
                              size: 14,
                              color: Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${products.length} item${products.length > 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFF9800),
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Price section with better alignment
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹$subTotal",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    if (discount != null && discount != "0.00")
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.success.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "$discount% OFF",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.success,
                              height: 1.0,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Combo Products
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: products
                  .map((product) =>
                      _buildProductCard(product, colorScheme, isCombo: true))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> item, AppColorScheme colorScheme,
      {bool isCombo = false, int? storeId, bool isSuperMart = false}) {
    final measurement = item['measurement']?.toString() ??
        item['variant_measurement']?.toString() ??
        '';
    final unit = item['unit']?.toString() ?? '';
    final hasSize = measurement.isNotEmpty && unit.isNotEmpty;
    final imageUrl = item['image_url']?.toString() ??
        item['product_image']?.toString() ??
        item['image']?.toString() ??
        '';
    final productName = item['product_name']?.toString() ?? '';
    final price = item['price']?.toString() ?? '0';
    final quantity = item['quantity']?.toString() ?? '1';
    // Explains why this item has no cancel option (seller setting vs. the
    // cancellation window having already passed). Null when it is cancellable.
    final ItemCancelNote? cancelNote =
        resolveItemCancelNoteFromMap(item, _currentOrder?.activeStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image with quantity badge
          Stack(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: colorScheme.surface,
                  border: Border.all(
                    color: colorScheme.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: setNetworkImg(
                    boxFit: BoxFit.cover,
                    image: imageUrl,
                    width: 45,
                    height: 45,
                    storeId: storeId,
                    isSuperMart: isSuperMart,
                  ),
                ),
              ),
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    "×$quantity",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Show seller name if available (for seller-managed items)
                if (item['seller_name'] != null &&
                    item['seller_name'].toString().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item['seller_name'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasSize)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              colorScheme.surfaceVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.border.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$measurement $unit',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    if (!isCombo)
                      Text(
                        '₹$price',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
          ),
          if (cancelNote != null)
            ItemCancelNoteRow(
              note: cancelNote,
              margin: const EdgeInsetsDirectional.only(top: 8),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreContactCard(AppColorScheme colorScheme) {
    // Get first store from grouped_by_store
    if (_currentOrder?.groupedByStore == null ||
        _currentOrder!.groupedByStore!.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstStore = _currentOrder!.groupedByStore![0];
    if (firstStore is! Map<String, dynamic>) {
      return SizedBox.shrink();
    }

    final sellersList = firstStore.sellers ?? [];

    // Get delivery boy info
    final deliveryBoyName = _currentOrder?.deliveryBoyName;
    final deliveryBoyMobile = _currentOrder?.deliveryBoyNumber;
    final hasDeliveryBoy = deliveryBoyName != null &&
        deliveryBoyName.isNotEmpty &&
        deliveryBoyName != 'null';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sellers list
          ...sellersList.asMap().entries.map((entry) {
            final index = entry.key;
            final seller = entry.value;

            final sellerName = seller.sellerName ?? 'Seller';
            final sellerImage = seller.sellerImage;
            final sellerAddress = seller.sellerAddress ??
                seller.sellerPlaceName ??
                'Seller Address';

            return Column(
              children: [
                if (index > 0) ...[
                  // Dashed divider between sellers
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: List.generate(
                        150 ~/ 4,
                        (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0
                                ? colorScheme.border
                                : Colors.transparent,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Row(
                  children: [
                    // Seller Image (44x44)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                colorScheme.textPrimary.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: sellerImage != null && sellerImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: setNetworkImg(
                                image: sellerImage,
                                width: 44,
                                height: 44,
                                boxFit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    Color(0xFF87B23D)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.store_rounded,
                                color: colorScheme.surface,
                                size: 22,
                              ),
                            ),
                    ),
                    SizedBox(width: 12),
                    // Seller Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sellerName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3),
                          Text(
                            sellerAddress,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.textSecondary,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Chat & Call Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Chat Button
                        GestureDetector(
                          onTap: () {
                            // Navigate to order chat screen with seller/store info
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderChatScreen(
                                  orderId: _currentOrder?.id ?? '',
                                  driverName: sellerName,
                                  driverId: seller.sellerId,
                                  driverPhone: null,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Call Button - Disabled (seller phone not available in model)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.border.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.phone_outlined,
                            color: colorScheme.textSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }).toList(),

          // Delivery Boy Section
          if (hasDeliveryBoy) ...[
            // Dashed divider before delivery boy
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: List.generate(
                  150 ~/ 4,
                  (index) => Expanded(
                    child: Container(
                      color: index % 2 == 0
                          ? colorScheme.border
                          : Colors.transparent,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            // Delivery Boy Row
            Row(
              children: [
                // Delivery Boy Icon (44x44, blue gradient)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B82F6).withValues(alpha: 0.9),
                        Color(0xFF2563EB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3B82F6).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delivery_dining_rounded,
                    color: colorScheme.surface,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                // Delivery Boy Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryBoyName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Delivery Partner',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.textSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Call Button
                if (deliveryBoyMobile != null && deliveryBoyMobile.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        launchUrl(Uri.parse('tel:$deliveryBoyMobile'));
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.phone_outlined,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryBoyContactCard(AppColorScheme colorScheme) {
    final deliveryBoyName = _currentOrder?.deliveryBoyName;
    final deliveryBoyMobile = _currentOrder?.deliveryBoyNumber;

    // Don't show if no delivery boy assigned
    if (deliveryBoyName == null ||
        deliveryBoyName.isEmpty ||
        deliveryBoyName == 'null') {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Delivery Boy Icon (44x44, blue gradient)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6).withValues(alpha: 0.9),
                  Color(0xFF2563EB),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.delivery_dining_rounded,
              color: colorScheme.surface,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          // Delivery Boy Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliveryBoyName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Text(
                  'Delivery Partner',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          // Call Button
          if (deliveryBoyMobile != null &&
              deliveryBoyMobile.isNotEmpty &&
              deliveryBoyMobile != 'null')
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  launchUrl(Uri.parse('tel:$deliveryBoyMobile'));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colorScheme =
            context.watch<app_theme.ThemeProvider>().colorScheme;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            getTranslatedValue(context, 'cancel_order_dialog_title'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.textPrimary,
            ),
          ),
          content: Text(
            getTranslatedValue(context, 'cancel_order_dialog_message'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: colorScheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                getTranslatedValue(context, 'keep_order_button'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: _isCancellingOrder
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _cancelOrderApiCall();
                    },
              child: _isCancellingOrder
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.error,
                        ),
                      ),
                    )
                  : Text(
                      getTranslatedValue(context, 'cancel_order_button'),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOrderApiCall() async {
    try {
      setState(() {
        _isCancellingOrder = true;
      });

      final orderId = _currentOrder?.id;
      if (orderId == null) {
        setState(() {
          _isCancellingOrder = false;
        });
        _showSnackBar(getTranslatedValue(context, 'error_message'),
            isError: true);
        return;
      }

      final response = await cancelOrderApi(
        params: {ApiAndParams.orderId: orderId.toString()},
        context: context,
      );

      final status = response[ApiAndParams.status];
      final message = response[ApiAndParams.message] ?? '';

      if (!mounted) return;
      setState(() {
        _isCancellingOrder = false;
      });

      if (status == 1) {
        // Order cancelled successfully
        _showSnackBar(message, isError: false);
        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            mainHomeScreen,
            (route) => false,
          );
        });
      } else if (status == 0) {
        // Order is not cancellable
        _showSnackBar(
          message.isNotEmpty
              ? message
              : getTranslatedValue(context, 'order_not_cancellable'),
          isError: true,
        );
      } else {
        _showSnackBar(
          message.isNotEmpty
              ? message
              : getTranslatedValue(context, 'error_message'),
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      if (!mounted) return;
      setState(() {
        _isCancellingOrder = false;
      });
      _showSnackBar(getTranslatedValue(context, 'error_message'),
          isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- Driver Rating Card ---
  Widget _buildDriverRatingCard(AppColorScheme colorScheme) {
    final driver = _ratingData!.deliveryBoy!;
    final hasExistingRating = driver.rating != null &&
        driver.rating.toString() != 'null' &&
        driver.rating.toString() != '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Driver info row
          Row(
            children: [
              // Profile image
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: driver.profileImage != null &&
                        driver.profileImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: driver.profileImage!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: const Color(0xFFE0E0E0),
                          highlightColor: const Color(0xFFF5F5F5),
                          child: Container(width: 56, height: 56, color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delivery_dining,
                              color: colorScheme.primary, size: 28),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delivery_dining,
                            color: colorScheme.primary, size: 28),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name?.toString() ?? 'Delivery Partner',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Delivery Partner',
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Star rating
          Row(
            children: List.generate(5, (index) {
              final isFilled = index < _driverRating;
              return GestureDetector(
                onTap: hasExistingRating
                    ? null
                    : () {
                        setState(() => _driverRating = index + 1);
                      },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 32,
                    color: const Color(0xFFFFC107),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // Review text field
          if (!hasExistingRating) ...[
            TextField(
              controller: _driverReviewController,
              maxLines: 3,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Write your review...',
                hintStyle: GoogleFonts.inter(
                  color: colorScheme.textTertiary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            // Post button
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _driverSubmitting || _driverRating == 0
                    ? null
                    : () => _submitDriverRating(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: _driverRating > 0
                        ? colorScheme.primaryGradient
                        : null,
                    color: _driverRating > 0 ? null : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _driverSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.buttonPrimaryText,
                          ),
                        )
                      : Text(
                          'Post',
                          style: GoogleFonts.inter(
                            color: _driverRating > 0
                                ? colorScheme.buttonPrimaryText
                                : colorScheme.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ] else ...[
            // Show existing review
            if (driver.review != null &&
                driver.review.toString() != 'null' &&
                driver.review.toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  driver.review.toString(),
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // --- Submit Driver Rating ---
  Future<void> _submitDriverRating() async {
    if (_driverRating == 0 || !mounted) return;
    setState(() => _driverSubmitting = true);
    try {
      final orderId = int.tryParse(_currentOrder?.id ?? widget.orderId ?? '0') ?? 0;
      final response = await ratingDriver(
        orderId: orderId,
        rating: _driverRating,
        review: _driverReviewController.text.trim(),
        context: context,
      );
      if (!mounted) return;
      if (response['status'] == 1) {
        showMessage(
            context, response['message'] ?? 'Rating submitted', MessageType.success);
        await _fetchRatings();
      } else {
        showMessage(
            context, response['message'] ?? 'Failed to submit', MessageType.error);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Something went wrong', MessageType.error);
      }
    }
    if (mounted) setState(() => _driverSubmitting = false);
  }

  // --- Seller Products Rating ---
  Widget _buildSellerProductsRating(AppColorScheme colorScheme) {
    final sellers = _ratingData?.sellers;
    if (sellers == null || sellers.isEmpty) return const SizedBox.shrink();

    return Column(
      children: sellers.map((seller) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              // Items list
              if (seller.items != null)
                ...seller.items!.map((item) {
                  final productId = item.productId ?? 0;
                  final currentRating = _productRatings[productId] ?? 0;
                  final hasExistingRating = item.rating != null &&
                      item.rating.toString() != 'null' &&
                      item.rating.toString() != '0';
                  final displayRating =
                      hasExistingRating
                          ? (int.tryParse(item.rating.toString()) ?? 0)
                          : currentRating;
                  final isSubmitting = _productSubmitting[productId] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.itemName ?? 'Product',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Stars and Post button row
                        Row(
                          children: [
                            // Star rating
                            ...List.generate(5, (index) {
                              final isFilled = index < displayRating;
                              return GestureDetector(
                                onTap: hasExistingRating
                                    ? null
                                    : () {
                                        setState(() {
                                          _productRatings[productId] =
                                              index + 1;
                                        });
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    isFilled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 26,
                                    color: const Color(0xFFFFC107),
                                  ),
                                ),
                              );
                            }),
                            const Spacer(),
                            // Post button (only if no existing rating)
                            if (!hasExistingRating)
                              GestureDetector(
                                onTap: isSubmitting || currentRating == 0
                                    ? null
                                    : () => _submitProductRating(productId),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: currentRating > 0
                                        ? colorScheme.primaryGradient
                                        : null,
                                    color: currentRating > 0
                                        ? null
                                        : colorScheme.border,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: isSubmitting
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                colorScheme.buttonPrimaryText,
                                          ),
                                        )
                                      : Text(
                                          'Post',
                                          style: GoogleFonts.inter(
                                            color: currentRating > 0
                                                ? colorScheme.buttonPrimaryText
                                                : colorScheme.textTertiary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- Submit Product Rating ---
  Future<void> _submitProductRating(int productId) async {
    final rating = _productRatings[productId] ?? 0;
    if (rating == 0 || !mounted) return;
    setState(() => _productSubmitting[productId] = true);
    try {
      final orderId = int.tryParse(_currentOrder?.id ?? widget.orderId ?? '0') ?? 0;
      final response = await ratingProduct(
        orderId: orderId,
        productId: productId,
        rating: rating,
        context: context,
      );
      if (!mounted) return;
      if (response['status'] == 1) {
        showMessage(
            context, response['message'] ?? 'Rating submitted', MessageType.success);
        await _fetchRatings();
      } else {
        showMessage(
            context, response['message'] ?? 'Failed to submit', MessageType.error);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'Something went wrong', MessageType.error);
      }
    }
    if (mounted) setState(() => _productSubmitting[productId] = false);
  }

  // --- Fetch Ratings (standalone for re-fetching after submit) ---
  Future<void> _fetchRatings() async {
    if (!mounted) return;
    try {
      final orderId = int.tryParse(_currentOrder?.id ?? widget.orderId ?? '0') ?? 0;
      if (orderId == 0) return;
      final ratingsResponse = await ratingApi(
        orderId: orderId,
        context: context,
      );
      if (!mounted) return;
      if (ratingsResponse[ApiAndParams.status].toString() == "1") {
        setState(() {
          _ratingModel = rm.RatingModel.fromJson(ratingsResponse);
          _ratingData = _ratingModel?.data;
          if (_ratingData != null) {
            if (_ratingData!.deliveryBoy?.rating != null) {
              _driverRating =
                  int.tryParse(_ratingData!.deliveryBoy!.rating.toString()) ?? 0;
            }
            if (_ratingData!.deliveryBoy?.review != null &&
                _ratingData!.deliveryBoy!.review.toString() != 'null' &&
                _ratingData!.deliveryBoy!.review.toString().isNotEmpty) {
              _driverReviewController.text =
                  _ratingData!.deliveryBoy!.review.toString();
            }
            if (_ratingData!.sellers != null) {
              for (var seller in _ratingData!.sellers!) {
                if (seller.items != null) {
                  for (var item in seller.items!) {
                    if (item.rating != null && item.productId != null) {
                      _productRatings[item.productId!] =
                          int.tryParse(item.rating.toString()) ?? 0;
                    }
                  }
                }
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching ratings: $e');
    }
  }
}
