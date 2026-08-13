import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/orderTrackingScreen.dart';

class OrderPlacedScreen extends StatefulWidget {
  final String? orderId;
  final bool isPreOrder;

  const OrderPlacedScreen({Key? key, this.orderId, this.isPreOrder = false})
      : super(key: key);

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  Timer? _navigationTimer;

  // Colors based on order type
  Color get _themeColor =>
      widget.isPreOrder ? const Color(0xFFE8922D) : const Color(0xFF9AC444);

  IconData get _successIcon =>
      widget.isPreOrder ? Icons.schedule_rounded : Icons.check_rounded;

  @override
  void initState() {
    super.initState();

    // Clear cart and reset cart state (tips, instructions, notes)
    Future.delayed(Duration.zero).then((value) {
      context.read<CartListProvider>().clearCart(context: context);
      context.read<CartProvider>().resetCartState();
    });

    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Background color animation - transition from white to theme color
    _backgroundColorAnimation = ColorTween(
      begin: Colors.white,
      end: _themeColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Scale animation - circle grows smoothly

    // Check mark animation
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Fade animation for success text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );

    // Content fade in animation (buttons and description)
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animation and show content after animation completes
    _controller.forward().then((_) {
      log('Animation completed. Mounted: $mounted, OrderId: ${widget.orderId}');
      if (mounted) {
        setState(() {
        });

        // Auto-navigate to tracking screen after animation
        log('Checking orderId: ${widget.orderId}, isEmpty: ${widget.orderId?.isEmpty ?? "null"}');
        if (widget.orderId != null && widget.orderId!.isNotEmpty) {
          log('Starting navigation timer');
          // Delay for smoother transition (2 seconds to view the success state)
          _navigationTimer = Timer(const Duration(seconds: 2), () {
            log('Timer triggered. Mounted: $mounted');
            if (mounted) {
              log('Navigating to order tracking screen with orderId: ${widget.orderId}');
              Navigator.of(context).popUntil(
                (Route<dynamic> route) => route.isFirst,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider(
                        create: (context) => CurrentOrderProvider(),
                      ),
                    ],
                    child: OrderTrackingScreen(orderId: widget.orderId),
                  ),
                ),
              );
            }
          });
        } else {
          log('OrderId is null or empty, not navigating');
        }
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          return;
        },
        child: AnimatedBuilder(
          animation: _backgroundColorAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: _backgroundColorAnimation.value,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated icon
                            AnimatedBuilder(
                              animation: _checkAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _checkAnimation.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 30,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _successIcon,
                                      color: _themeColor,
                                      size: 70,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 40),

                            // Success text
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: Column(
                                    children: [
                                      Text(
                                        widget.isPreOrder
                                            ? 'Pre-Order Placed!'
                                            : getTranslatedValue(
                                                context, 'order_placed_title'),
                                        style: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.2,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        widget.isPreOrder
                                            ? 'Your pre-order has been confirmed'
                                            : getTranslatedValue(context,
                                                'order_placed_subtitle'),
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          height: 1.3,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Description text
                            AnimatedBuilder(
                              animation: _contentFadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _contentFadeAnimation.value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: widget.isPreOrder
                                        ? Column(
                                            children: [
                                              Text(
                                                'Your pre-order has been confirmed. Pre-order items are dispatched every Friday morning. We\'ll notify you once your order is out for delivery.',
                                                softWrap: true,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.85),
                                                  height: 1.5,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.cancel_outlined,
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.9),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Cancellation Policy',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.white,
                                                              letterSpacing:
                                                                  -0.2,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 3),
                                                          Text(
                                                            'You can cancel this pre-order before it is dispatched. Go to your order details and tap "Cancel Order" anytime before dispatch.',
                                                            style: GoogleFonts
                                                                .inter(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Colors.white
                                                                  .withValues(
                                                                      alpha:
                                                                          0.85),
                                                              height: 1.5,
                                                              letterSpacing:
                                                                  -0.1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        : CustomTextLabel(
                                            jsonKey: orderPlaceDescriptionLabel,
                                            softWrap: true,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              height: 1.5,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Buttons
                      AnimatedBuilder(
                        animation: _contentFadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _contentFadeAnimation.value,
                            child: Column(
                              children: [
                                // Track Order Button (Primary)
                                if (widget.orderId != null &&
                                    widget.orderId!.isNotEmpty)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.of(context).popUntil(
                                          (Route<dynamic> route) =>
                                              route.isFirst,
                                        );
                                        Navigator.pushNamed(
                                          context,
                                          orderTrackingScreen,
                                          arguments: widget.orderId,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: _themeColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            getTranslatedValue(
                                                context, 'track_order_button'),
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (widget.orderId != null &&
                                    widget.orderId!.isNotEmpty)
                                  const SizedBox(height: 12),
                                // Continue Shopping Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).popUntil(
                                        (Route<dynamic> route) =>
                                            route.isFirst,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      getTranslatedValue(
                                          context, 'continue_shopping_button'),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // View Orders Button
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).popUntil(
                                        (Route<dynamic> route) =>
                                            route.isFirst,
                                      );
                                      Navigator.pushNamed(
                                          context, orderHistoryScreen);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                    child: Text(
                                      getTranslatedValue(
                                          context, 'view_all_orders_button'),
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.2,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
