import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:zenfoo_partner/models/incoming_order_model.dart';

typedef OrderBannerCallback = void Function(IncomingOrder order);

/// Service to manage order arrival banner display and callbacks
class OrderBannerService {
  static final OrderBannerService _instance = OrderBannerService._internal();
  factory OrderBannerService() => _instance;
  OrderBannerService._internal();

  OverlayEntry? _bannerOverlayEntry;
  OrderBannerCallback? _onAccept;
  OrderBannerCallback? _onReject;
  VoidCallback? _onDismiss;

  /// Register callbacks for accept and reject actions
  void setCallbacks({
    required OrderBannerCallback onAccept,
    required OrderBannerCallback onReject,
    VoidCallback? onDismiss,
  }) {
    _onAccept = onAccept;
    _onReject = onReject;
    _onDismiss = onDismiss;
  }

  /// Show order banner overlay
  void showOrderBanner({
    required BuildContext context,
    required IncomingOrder order,
  }) {
    // Remove existing banner if any
    dismissBanner();

    _bannerOverlayEntry = OverlayEntry(
      builder: (context) => OrderBannerOverlay(
        order: order,
        onAccept: () {
          _onAccept?.call(order);
          dismissBanner();
        },
        onReject: () {
          _onReject?.call(order);
          dismissBanner();
        },
        onDismiss: () {
          dismissBanner();
          _onDismiss?.call();
        },
      ),
    );

    Overlay.of(context).insert(_bannerOverlayEntry!);
  }

  /// Dismiss the banner
  void dismissBanner() {
    _bannerOverlayEntry?.remove();
    _bannerOverlayEntry = null;
  }

  /// Check if banner is currently shown
  bool get isBannerVisible => _bannerOverlayEntry != null;

  /// Reset service (call on dispose)
  void reset() {
    dismissBanner();
    _onAccept = null;
    _onReject = null;
    _onDismiss = null;
  }
}

/// Overlay banner widget to display incoming order
class OrderBannerOverlay extends StatefulWidget {
  final IncomingOrder order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onDismiss;

  const OrderBannerOverlay({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onDismiss,
  });

  @override
  State<OrderBannerOverlay> createState() => _OrderBannerOverlayState();
}

class _OrderBannerOverlayState extends State<OrderBannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for banner sliding in from top
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Auto-dismiss after 8 seconds if not interacted
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _animationController.isCompleted) {
        _dismissBanner();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissBanner() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Order',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Order ${formatOrderNumber(widget.order.orderId)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismissBanner,
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Order details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Distance and Earnings
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDetailItem(
                              icon: Icons.location_on_outlined,
                              label: 'Distance',
                              value: '${widget.order.totalRouteDistanceKm.toStringAsFixed(1)} km',
                              color: Colors.blue,
                            ),
                            _buildDetailItem(
                              icon: Icons.currency_rupee,
                              label: 'Delivery',
                              value:
                                  '₹${widget.order.deliveryCharge.toStringAsFixed(0)}',
                              color: Colors.green,
                            ),
                            _buildDetailItem(
                              icon: Icons.card_giftcard,
                              label: 'Tip',
                              value: '₹${widget.order.deliveryTip.toStringAsFixed(0)}',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Customer location
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 18,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.order.customer.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[900],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.order.customer.address,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
