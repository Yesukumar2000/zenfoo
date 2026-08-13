import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/order_banner_service.dart';

/// Widget that listens for incoming orders and displays banner overlay
/// Wrap the home screen content with this widget to enable banner functionality
class OrderBannerListener extends StatefulWidget {
  final Widget child;

  const OrderBannerListener({
    super.key,
    required this.child,
  });

  @override
  State<OrderBannerListener> createState() => _OrderBannerListenerState();
}

class _OrderBannerListenerState extends State<OrderBannerListener>
    with WidgetsBindingObserver {
  late OrderBannerService _bannerService;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  int? _lastShownOrderId;

  @override
  void initState() {
    super.initState();
    _bannerService = OrderBannerService();
    WidgetsBinding.instance.addObserver(this);

    // Setup callbacks for banner actions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupBannerCallbacks();
      _listenForNewOrders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerService.reset();
    super.dispose();
  }

  /// Track app lifecycle to know when app is backgrounded
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _appLifecycleState = state;
    });

    if (state == AppLifecycleState.paused) {
      debugPrint('🔴 App backgrounded - banner will show for incoming orders');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('🟢 App resumed - dismissing banner if visible');
      _bannerService.dismissBanner();
      _lastShownOrderId = null;
    }
  }

  /// Setup callbacks for accept/reject actions
  void _setupBannerCallbacks() {
    final incomingOrderProvider = context.read<IncomingOrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id ?? 0;

    _bannerService.setCallbacks(
      onAccept: (order) async {
        debugPrint('✅ Banner: Accepting order ${order.orderId}');
        final position = await _getCurrentPosition();

        if (position != null) {
          final accepted = await incomingOrderProvider.acceptOrder(
            orderId: order.orderId,
            deliveryBoyId: deliveryBoyId,
            driverLat: position.latitude,
            driverLng: position.longitude,
          );

          if (accepted && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order #${order.orderId} accepted'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onReject: (order) async {
        debugPrint('❌ Banner: Rejecting order ${order.orderId}');
        final rejected = await incomingOrderProvider.rejectOrder(
          order.orderId,
          deliveryBoyId,
        );

        if (rejected && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${order.orderId} rejected'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onDismiss: () {
        debugPrint('👉 Banner dismissed by user');
      },
    );
  }

  /// Listen for new incoming orders and show banner when app is backgrounded
  void _listenForNewOrders() {
    final incomingOrderProvider = context.read<IncomingOrderProvider>();

    // Listen to changes in incoming orders
    incomingOrderProvider.addListener(() {
      // Show banner only if:
      // 1. App is backgrounded or in paused state
      // 2. New order arrived (not already shown)
      // 3. Banner not already visible
      if (incomingOrderProvider.incomingOrders.isNotEmpty &&
          _appLifecycleState == AppLifecycleState.paused &&
          !_bannerService.isBannerVisible) {
        final newestOrder = incomingOrderProvider.incomingOrders.first;

        // Only show if this is a new order we haven't shown banner for
        if (_lastShownOrderId != newestOrder.orderId) {
          _lastShownOrderId = newestOrder.orderId;
          debugPrint(
              '🔔 New order detected while app backgrounded: ${newestOrder.orderId}');

          // Show banner
          _bannerService.showOrderBanner(
            context: context,
            order: newestOrder,
          );
        }
      }
    });
  }

  /// Get current device position using geolocator
  Future<Position?> _getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
