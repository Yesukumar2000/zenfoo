import 'dart:io' as io;
import 'package:intl/intl.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/screens/orderTrackingScreen.dart';
import 'package:project/screens/orderIssueReportScreen/order_issue_report_screen.dart';
import 'package:project/models/rating.dart' as rm;
import 'package:project/repositories/ordersApi.dart' as ordersRepo;
import 'package:project/models/groupedByStore.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String from;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.from,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order order;

  // Rating state
  rm.RatingData? _ratingData;
  bool _ratingsLoading = false;
  int _driverRating = 0;
  final TextEditingController _driverReviewController = TextEditingController();
  bool _driverSubmitting = false;
  Map<int, int> _productRatings = {}; // productId -> rating
  Map<int, bool> _productSubmitting = {}; // productId -> submitting

  @override
  void initState() {
    super.initState();
    Future.microtask(callApi);
  }

  @override
  void dispose() {
    _driverReviewController.dispose();
    super.dispose();
  }

  Future<void> callApi() async {
    final res = await context.read<CurrentOrderProvider>().getCurrentOrder(
      params: {ApiAndParams.orderId: widget.orderId},
      context: context,
    );
    if (res is Order) {
      setState(() => order = res);
      if (order.activeStatus == '6') {
        _fetchRatings();
      }
    }
  }

  Future<void> _fetchRatings() async {
    if (!mounted) return;
    setState(() => _ratingsLoading = true);
    try {
      final response = await ordersRepo.ratingApi(
        orderId: int.parse(widget.orderId),
        context: context,
      );
      if (!mounted) return;
      final model = rm.RatingModel.fromJson(response);
      if (model.status == 1 && model.data != null) {
        setState(() {
          _ratingData = model.data;
          // Pre-fill existing ratings
          if (_ratingData!.deliveryBoy?.rating != null) {
            _driverRating =
                int.tryParse(_ratingData!.deliveryBoy!.rating.toString()) ?? 0;
          }
          if (_ratingData!.deliveryBoy?.review != null &&
              _ratingData!.deliveryBoy!.review.toString().isNotEmpty &&
              _ratingData!.deliveryBoy!.review.toString() != 'null') {
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
        });
      }
    } catch (e) {
      debugPrint('Error fetching ratings: $e');
    }
    if (mounted) setState(() => _ratingsLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, order);
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: Consumer<CurrentOrderProvider>(
          builder: (context, currentOrderProvider, _) {
            final state = currentOrderProvider.currentOrderState;

            if (state == CurrentOrderState.loading) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: const [
                    // Items card shimmer
                    _ItemsCardShimmer(),
                    SizedBox(height: 12),
                    // Bills card shimmer
                    _BillsCardShimmer(),
                    SizedBox(height: 12),
                    // Cart info card shimmer
                    _CartInfoCardShimmer(),
                  ],
                ),
              );
            }

            if (state != CurrentOrderState.loaded &&
                state != CurrentOrderState.silentLoading) {
              return DefaultBlankItemMessageScreen(
                height: context.height,
                image: "something_went_wrong",
                title:
                    getTranslatedValue(context, somethingWentWrongTitleLabel),
                description: getTranslatedValue(
                    context, somethingWentWrongDescriptionLabel),
                buttonTitle: getTranslatedValue(context, tryAgainLabel),
                callback: callApi,
              );
            }

            // Check if order should show tracking overlay (not cancelled, delivered, or returned)
            final shouldShowTracking = order.activeStatus != null &&
                order.activeStatus != "6" && // Not cancelled
                order.activeStatus != "7"; // Not returned

            return Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      _buildGradientSliverAppBar(context, colorScheme),
                    ];
                  },
                  body: Container(
                    color: colorScheme.background,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ItemsCard(
                              order: order, from: widget.from, reload: callApi),
                          const SizedBox(height: 12),
                          if (order.cartInfo != null) ...[
                            _TipCard(order: order),
                            const SizedBox(height: 12),
                          ],
                          _BillsCard(order: order),
                          const SizedBox(height: 12),
                          _CartInfoCard(order: order),
                          const SizedBox(height: 12),
                          // Hide store and delivery boy contact cards when order is delivered
                          if (order.activeStatus != '6')
                            Column(
                              children: [
                                _StoreContactCard(order: order),
                                const SizedBox(height: 12),
                                _DeliveryBoyContactCard(order: order),
                              ],
                            ),
                          // Show ratings section when order is delivered
                          if (order.activeStatus == '6')
                            _ratingsLoading
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : _ratingData != null
                                    ? Column(
                                        children: [
                                          if (_ratingData!.deliveryBoy != null)
                                            _buildDriverRatingCard(colorScheme),
                                          const SizedBox(height: 16),
                                          _buildSellerProductsRating(
                                              colorScheme),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                // Order tracking button for active orders
                if (shouldShowTracking)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiProvider(
                              providers: [
                                ChangeNotifierProvider(
                                  create: (context) => CurrentOrderProvider(),
                                ),
                              ],
                              child:
                                  OrderTrackingScreen(orderId: widget.orderId),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: colorScheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: colorScheme.buttonPrimaryText,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              getTranslatedValue(context, 'track_order'),
                              style: GoogleFonts.inter(
                                color: colorScheme.buttonPrimaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: colorScheme.buttonPrimaryText,
                              size: 20,
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
      ),
    );
  }

  Widget _buildGradientSliverAppBar(
      BuildContext context, AppColorScheme colorScheme) {
    // Extract store locations from grouped_by_store
    final stores = order.groupedByStore ?? [];

    // Get delivery address
    final deliveryAddress = order.orderAddress ?? '';

    // Prepare store locations list
    List<Map<String, String>> locations = [];

    // Add stores
    for (var store in stores) {
      final storeName = store.storeName ?? getTranslatedValue(context, 'store');
      String? storeAddress;

      if (store.sellers != null && store.sellers!.isNotEmpty) {
        final firstSeller = store.sellers![0];
        storeAddress = firstSeller.sellerAddress;
        if (storeAddress == null || storeAddress.isEmpty) {
          storeAddress = firstSeller.sellerPlaceName;
        }
      }

      if (storeAddress != null && storeAddress.isNotEmpty) {
        locations.add({
          'label': storeName,
          'address': storeAddress,
        });
      }
    }

    // Add delivery location at the end
    if (deliveryAddress.isNotEmpty) {
      locations.add({
        'label': getTranslatedValue(context, 'delivery_location'),
        'address': deliveryAddress,
      });
    }

    // Calculate total items
    int totalItems = 0;
    if (order.groupedByStore != null) {
      for (var store in order.groupedByStore!) {
        // Count store-level items
        if (store.items != null) {
          totalItems += store.items!.length;
        }
        // Count seller items
        if (store.sellers != null) {
          for (var seller in store.sellers!) {
            if (seller.items != null) {
              totalItems += seller.items!.length;
            }
          }
        }
      }
    }
    if (order.customCombos != null) {
      totalItems += order.customCombos!.length;
    }

    // Calculate dynamic height
    final routeCardHeight = 70.0 + (locations.length * 70.0);
    final expandedHeight = 80.0 + routeCardHeight;

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      expandedHeight: expandedHeight,
      collapsedHeight: 70,
      toolbarHeight: 70,
      backgroundColor: Colors.transparent,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isCollapsed = constraints.biggest.height <=
              70 + MediaQuery.of(context).padding.top;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary,
                  colorScheme.surface,
                ],
                stops: const [0, 0.85],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header (always visible)
                  _buildHeader(context, totalItems, colorScheme),
                  // Route card (collapses on scroll)
                  if (!isCollapsed)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: _buildRouteCard(locations, colorScheme),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, int totalItems, AppColorScheme colorScheme) {
    // Show help button only when order is delivered
    final showHelpButton = order.activeStatus == '6';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, order),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getTranslatedValue(context, 'order_details'),
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${getTranslatedValue(context, 'order_number_prefix')}${order.displayNumber}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (showHelpButton)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderIssueReportScreen(
                      orderId: widget.orderId.toString(),
                    ),
                  ),
                );
              },
              child: Container(
                height: 38,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.headset_mic_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      getTranslatedValue(context, 'help'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
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

  Widget _buildRouteCard(
      List<Map<String, String>> locations, AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        children: locations.asMap().entries.map((entry) {
          final index = entry.key;
          final location = entry.value;
          final isLast = index == locations.length - 1;
          final isFirst = index == 0;

          Color dotColor;
          IconData locationIcon;
          if (isFirst) {
            dotColor = const Color(0xFF9AC444); // Green for start
            locationIcon = Icons.storefront_rounded;
          } else if (isLast) {
            dotColor = const Color(0xFFFF6B6B); // Red for delivery
            locationIcon = Icons.home_rounded;
          } else {
            dotColor = const Color(0xFFFF9800); // Orange for intermediate
            locationIcon = Icons.location_on_rounded;
          }

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact icon with connector
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor,
                          boxShadow: [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          locationIcon,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                dotColor.withValues(alpha: 0.3),
                                dotColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Compact text content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location['label'] ?? '',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            location['address'] ?? '',
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Driver Rating Card ───
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

  Future<void> _submitDriverRating() async {
    if (_driverRating == 0 || !mounted) return;
    setState(() => _driverSubmitting = true);
    try {
      final response = await ordersRepo.ratingDriver(
        orderId: int.parse(widget.orderId),
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

  // ─── Seller Products Rating ───
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
              // // Store & seller info
              // Text(
              //   seller.storeName ?? 'Store',
              //   style: GoogleFonts.inter(
              //     color: colorScheme.textPrimary,
              //     fontSize: 16,
              //     fontWeight: FontWeight.w700,
              //     height: 1.2,
              //   ),
              // ),
              // if (seller.sellerName != null) ...[
              //   const SizedBox(height: 3),
              //   Text(
              //     seller.sellerName!,
              //     style: GoogleFonts.inter(
              //       color: colorScheme.textSecondary,
              //       fontSize: 13,
              //       fontWeight: FontWeight.w500,
              //       height: 1.2,
              //     ),
              //   ),
              // ],
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
                        // Item name and quantity
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
                            // Text(
                            //   'Qty: ${item.quantity ?? 1}',
                            //   style: GoogleFonts.inter(
                            //     color: colorScheme.textSecondary,
                            //     fontSize: 12,
                            //     fontWeight: FontWeight.w500,
                            //   ),
                            // ),
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

  Future<void> _submitProductRating(int productId) async {
    final rating = _productRatings[productId] ?? 0;
    if (rating == 0 || !mounted) return;
    setState(() => _productSubmitting[productId] = true);
    try {
      final response = await ordersRepo.ratingProduct(
        orderId: int.parse(widget.orderId),
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
}

/// Generic card

class _ZenCard extends StatelessWidget {
  final Widget child;
  const _ZenCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: colorScheme.cardShadow,
      ),
      child: child,
    );
  }
}

/// Route card (top three points)

class _RouteCard extends StatelessWidget {
  final Order order;
  const _RouteCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteRow(
            color: const Color(0xFF4CAF50),
            label: getTranslatedValue(context, 'zenfoo_location'),
            address: order.orderAddress ?? "",
          ),
          const SizedBox(height: 8),
          _RouteRow(
            color: const Color(0xFFFFC107),
            label: getTranslatedValue(context, 'sweet_house_location'),
            address: order.orderAddress ?? "",
          ),
          const SizedBox(height: 8),
          _RouteRow(
            color: const Color(0xFFE53935),
            label: getTranslatedValue(context, 'delivery_location'),
            address: order.orderAddress ?? "",
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final Color color;
  final String label;
  final String address;

  const _RouteRow({
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Container(
              width: 2,
              height: 22,
              color: color.withOpacity(0.3),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Items card - Store-wise grouped items

class _ItemsCard extends StatelessWidget {
  final Order order;
  final String from;
  final VoidCallback reload;

  const _ItemsCard({
    required this.order,
    required this.from,
    required this.reload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final groupedByStore = order.groupedByStore ?? [];
    final adminStores =
        groupedByStore.where((s) => s.managedByAdmin == true).toList();
    final nonAdminStores =
        groupedByStore.where((s) => s.managedByAdmin != true).toList();
    final combos = (order.customCombos ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Column(
      children: [
        if (adminStores.isNotEmpty)
          _buildZenfooCard(context, colorScheme, adminStores, combos),
        ...nonAdminStores
            .map((store) => _buildSellerCard(context, colorScheme, store)),
      ],
    );
  }

  Widget _buildZenfooCard(
      BuildContext context,
      AppColorScheme colorScheme,
      List<GroupedByStore> adminStores,
      List<Map<String, dynamic>> combos) {
    final List<Widget> itemWidgets = [];
    for (final store in adminStores) {
      for (final seller in store.sellers ?? []) {
        for (final item
            in (seller.items ?? []).whereType<Map<String, dynamic>>()) {
          itemWidgets.add(
              _OrderItemCard(item: item, order: order, from: from, reload: reload));
        }
      }
      for (final item
          in (store.items ?? []).whereType<Map<String, dynamic>>()) {
        itemWidgets.add(
            _OrderItemCard(item: item, order: order, from: from, reload: reload));
      }
    }

    final comboProductCount = combos.fold<int>(
        0, (sum, c) => sum + ((c['products'] as List?)?.length ?? 0));
    final totalItems = itemWidgets.length + comboProductCount;
    final displayIcon = adminStores.first.storeIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: displayIcon != null && displayIcon.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: setNetworkImg(
                            image: displayIcon,
                            width: 48,
                            height: 48,
                            boxFit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storefront_rounded,
                              color: colorScheme.iconSecondary, size: 26),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zenfoo',
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
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$totalItems item${totalItems == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
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

          // Items + Combo sub-section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...itemWidgets,
                if (combos.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
                        .map((p) {
                      final mapped = Map<String, dynamic>.from(p);
                      if (mapped['image_url'] == null &&
                          mapped['product_image'] != null) {
                        mapped['image_url'] = mapped['product_image'];
                      }
                      return _OrderItemCard(
                          item: mapped,
                          order: order,
                          from: from,
                          reload: reload);
                    });
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(BuildContext context, AppColorScheme colorScheme,
      GroupedByStore store) {
    final sellers = store.sellers ?? [];
    final directItems =
        (store.items ?? []).whereType<Map<String, dynamic>>().toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: store.storeIcon != null &&
                              store.storeIcon!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: setNetworkImg(
                                image: store.storeIcon!,
                                width: 48,
                                height: 48,
                                boxFit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.storefront_rounded,
                                  color: colorScheme.iconSecondary, size: 26),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.storeName ??
                                getTranslatedValue(context, 'store'),
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
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${directItems.length + sellers.fold<int>(0, (sum, s) => sum + (s.items?.length ?? 0))} items',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (store.isSuperMart ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: colorScheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          getTranslatedValue(context, 'super_mart'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.buttonPrimaryText,
                            letterSpacing: -0.2,
                          ),
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
                        final items = (seller.items ?? [])
                            .whereType<Map<String, dynamic>>()
                            .toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items
                              .map((item) => _OrderItemCard(
                                    item: item,
                                    order: order,
                                    from: from,
                                    reload: reload,
                                  ))
                              .toList(),
                        );
                      }).toList(),
                    if (directItems.isNotEmpty)
                      ...directItems
                          .map((item) => _OrderItemCard(
                                item: item,
                                order: order,
                                from: from,
                                reload: reload,
                              ))
                          .toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Individual Order Item Card
class _OrderItemCard extends StatelessWidget {
  final dynamic item;
  final Order order;
  final String from;
  final VoidCallback reload;

  const _OrderItemCard({
    required this.item,
    required this.order,
    required this.from,
    required this.reload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with quantity badge
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.surfaceVariant,
                  border: Border.all(
                    color: colorScheme.border,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: setNetworkImg(
                    boxFit: BoxFit.cover,
                    image: item['image_url']?.toString() ?? "",
                    width: 70,
                    height: 70,
                  ),
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.textPrimary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Text(
                    "×${item['quantity']}",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.surface,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name']?.toString() ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "${item['measurement']} ${item['unit']}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "₹${item['price']}",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                if (item['active_status'] == "7")
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorsRes.appColorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: CustomTextLabel(
                        jsonKey: orderStatusCancelledLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: ColorsRes.appColorRed,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Combos Card
class _CombosCard extends StatelessWidget {
  final Order order;
  const _CombosCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final combos = order.customCombos ?? [];

    return Column(
      children: combos.map((combo) {
        if (combo is! Map<String, dynamic>) return const SizedBox.shrink();

        final productsList = combo['products'] as List? ?? [];
        final products =
            productsList.whereType<Map<String, dynamic>>().toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.border,
              width: 1,
            ),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Combo Header - Modern Premium Design
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Combo Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF9800),
                            Color(0xFFFF6B00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF9800).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            combo['combo_name']?.toString() ??
                                getTranslatedValue(context, 'combo'),
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
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${products.length} ${products.length > 1 ? getTranslatedValue(context, 'items') : getTranslatedValue(context, 'item')}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF9800),
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price and discount section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${combo['sub_total']}",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (combo['discount_percentage'] != null &&
                            combo['discount_percentage'] != "0.00")
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${combo['discount_percentage']}% OFF",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                  height: 1.0,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Combo Products Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: products.map((product) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.border,
                          width: 1,
                        ),
                        boxShadow: colorScheme.cardShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image with quantity badge
                          Stack(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: colorScheme.surfaceVariant,
                                  border: Border.all(
                                    color: colorScheme.border,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: setNetworkImg(
                                    boxFit: BoxFit.cover,
                                    image:
                                        product['product_image']?.toString() ??
                                            "",
                                    width: 70,
                                    height: 70,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.textPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: colorScheme.surface, width: 2),
                                  ),
                                  child: Text(
                                    "×${product['quantity']}",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.surface,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['product_name']?.toString() ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.textPrimary,
                                    height: 1.3,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: colorScheme.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "${product['variant_measurement']} ${_getUnitName(product['variant_stock_unit_id'], context)}",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.textSecondary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      "₹${product['price']}",
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.primary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getUnitName(dynamic unitId, BuildContext context) {
    if (unitId == null) return '';
    final id = unitId.toString();
    switch (id) {
      case '1':
        return getTranslatedValue(context, 'units_kg');
      case '2':
        return getTranslatedValue(context, 'units_gm');
      case '3':
        return getTranslatedValue(context, 'units_ltr');
      case '4':
        return getTranslatedValue(context, 'units_ml');
      case '5':
        return getTranslatedValue(context, 'units_pcs');
      default:
        return '';
    }
  }
}

/// Cart Info Card - Shows delivery instructions, contact details, seller notes

class _CartInfoCard extends StatelessWidget {
  final Order order;
  const _CartInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final cartInfo = order.cartInfo;

    final deliveryInstructions =
        cartInfo?['delivery_instructions']?.toString() ?? '';
    final contactName = cartInfo?['contact_name']?.toString() ?? '';
    final contactPhone = cartInfo?['contact_phone']?.toString() ?? '';
    final contactEmail = cartInfo?['contact_email']?.toString() ?? '';

    return _ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            getTranslatedValue(context, 'order_information'),
            style: GoogleFonts.inter(
              fontSize: 18,
              letterSpacing: -0.55,
              fontWeight: FontWeight.w700,
              height: 1.02,
              color: colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Order ID & Date
          _buildInfoItem(
            icon: Icons.receipt_long_outlined,
            iconColor: colorScheme.primary,
            title: 'Order ${order.displayNumber}',
            subtitle: _formatDate(order.createdAt ?? '', context),
            showDivider: true,
            colorScheme: colorScheme,
          ),

          // Payment Method
          if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
            _buildInfoItem(
              icon: Icons.payment_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: order.paymentMethod!,
              subtitle: getTranslatedValue(context, 'payment_method'),
              showDivider: true,
              colorScheme: colorScheme,
            ),

          // Delivery Address
          if (order.orderAddress != null && order.orderAddress!.isNotEmpty)
            _buildInfoItem(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFFEF4444),
              title:
                  '${getTranslatedValue(context, 'delivering_to')} ${contactName.isNotEmpty ? contactName : getTranslatedValue(context, 'customer')}',
              subtitle: order.orderAddress!,
              showDivider:
                  contactPhone.isNotEmpty || deliveryInstructions.isNotEmpty,
              colorScheme: colorScheme,
            ),

          // Contact Phone
          if (contactPhone.isNotEmpty)
            _buildInfoItem(
              icon: Icons.phone_outlined,
              iconColor: const Color(0xFF10B981),
              title: contactPhone,
              subtitle: contactName.isNotEmpty
                  ? contactName
                  : getTranslatedValue(context, 'contact_number'),
              showDivider: deliveryInstructions.isNotEmpty,
              colorScheme: colorScheme,
            ),

          // Delivery Instructions
          if (deliveryInstructions.isNotEmpty)
            _buildInfoItem(
              icon: Icons.description_outlined,
              iconColor: colorScheme.primary,
              title: getTranslatedValue(context, 'delivery_instructions'),
              subtitle: deliveryInstructions,
              showDivider: false,
              colorScheme: colorScheme,
            ),

          const SizedBox(height: 24),

          // Invoice Download
          Consumer<OrderInvoiceProvider>(
            builder: (context, orderInvoiceProvider, child) {
              return GestureDetector(
                onTap: () {
                  orderInvoiceProvider.getOrderInvoiceApiProvider(
                    params: {ApiAndParams.orderId: order.id.toString()},
                    context: context,
                  ).then(
                    (pdfContent) async {
                      if (pdfContent == null) return;
                      try {
                        final dir = await getApplicationDocumentsDirectory();
                        final targetFileName =
                            "${getTranslatedValue(context, appNameLabel)}-${getTranslatedValue(context, invoiceLabel)}-${order.displayNumber}.pdf";
                        final file = io.File("${dir.path}/$targetFileName");
                        await file.writeAsBytes(pdfContent);

                        final result = await OpenFile.open(file.path);
                        if (result.type != ResultType.done) {
                          if (context.mounted) {
                            showMessage(context, result.message, MessageType.warning);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showMessage(context, e.toString(), MessageType.warning);
                        }
                      }
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextLabel(
                          text:
                              getTranslatedValue(context, yourBillSummaryLabel),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.02,
                            letterSpacing: -0.55,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ),
                      if (orderInvoiceProvider.orderInvoiceState ==
                          OrderInvoiceState.loading)
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              getTranslatedValue(context, 'download'),
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.02,
                                letterSpacing: -0.55,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.download_outlined,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showDivider = true,
    required AppColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.1,
                        height: 1.2,
                        
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.textSecondary,
                        letterSpacing: 0,
                        height: 1.2,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            color: colorScheme.divider,
          ),
      ],
    );
  }

  String _formatDate(String dateStr, BuildContext context) {
    if (dateStr.isEmpty) return getTranslatedValue(context, 'not_available');
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

/// Tip Card - Display delivery tip details

class _TipCard extends StatelessWidget {
  final Order order;
  const _TipCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final cartInfo = order.cartInfo;
    if (cartInfo == null) return const SizedBox.shrink();

    final deliveryTip = cartInfo['delivery_tip']?.toString() ?? '0';
    if (deliveryTip == '0' || deliveryTip == '0.00') {
      return const SizedBox.shrink();
    }

    return _ZenCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/delivery_tip.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.volunteer_activism_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslatedValue(context, 'delivery_tip'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  getTranslatedValue(
                      context, 'thanks_for_supporting_delivery_partner'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '₹$deliveryTip',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                height: 1.0,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bills card - Using billing breakdown from cart_metadata

class _BillsCard extends StatelessWidget {
  final Order order;
  const _BillsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final billingBreakdown = order.billingBreakdown ?? [];

    // Separate total and non-total items
    final regularItems =
        billingBreakdown.where((item) => item['is_total'] != true).toList();
    final totalItems =
        billingBreakdown.where((item) => item['is_total'] == true).toList();

    return _ZenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslatedValue(context, 'bill_details'),
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.02,
              letterSpacing: -0.55,
            ),
          ),
          SizedBox(height: 20),

          // Regular billing items
          ...regularItems.map((item) {
            final isCredit = item['is_credit'] == true;
            final amount = item['amount'];
            final currency = item['currency'] ?? '₹';
            final label = item['label'] ?? '';
            final description = item['description']?.toString() ?? '';

            return Column(
              children: [
                _buildBillRow(
                  label,
                  '${isCredit ? '-' : ''}$currency${_formatAmount(amount)}',
                  isDiscount: isCredit,
                  showInfo: description.isNotEmpty,
                  description: description,
                  colorScheme: colorScheme,
                ),
                SizedBox(height: 12),
              ],
            );
          }).toList(),

          // Divider before total
          if (totalItems.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.only(top: 4, bottom: 16),
              height: 1,
              color: colorScheme.divider,
            ),
          ],

          // Total
          ...totalItems.map((item) {
            final amount = item['amount'];
            final currency = item['currency'] ?? '₹';
            final label = item['label'] ?? '';

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
                Text(
                  '$currency${_formatAmount(amount)}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                    letterSpacing: -0.55,
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value,
      {bool showInfo = false,
      bool isDiscount = false,
      String? description,
      required AppColorScheme colorScheme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (showInfo &&
                    description != null &&
                    description.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isDiscount ? colorScheme.primary : colorScheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = num.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  }
}

/// Order details + invoice card

/// Store ratings section (bottom list)

class _StoreRatingsSection extends StatelessWidget {
  final Order order;
  const _StoreRatingsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    // adapt with your own store list / ratings
    final stores = [
      {
        "name": "Zenfoo store",
        "rating": 4,
      },
      {
        "name": "Sri Krishna sweet H...",
        "rating": 3,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in stores) ...[
          Text(
            s["name"] as String,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.02,
              letterSpacing: -0.55,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < (s["rating"] as int) ? Icons.star : Icons.star_border,
                size: 16,
                color: Color(0xFF9AC444),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Store Contact Card - Shows store details with calling option
class _StoreContactCard extends StatelessWidget {
  final Order order;
  const _StoreContactCard({required this.order});

  void _makePhoneCall(String phoneNumber, BuildContext context) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    // Get first store from grouped_by_store
    if (order.groupedByStore == null || order.groupedByStore!.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstStore = order.groupedByStore![0];

    final storeName =
        firstStore.storeName ?? getTranslatedValue(context, 'store');
    final storeIcon = firstStore.storeIcon;

    // Get seller phone from first seller if available
    // Note: SellerInfo model doesn't have phone fields currently
    String? sellerPhone;

    return _ZenCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Store Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: storeIcon != null && storeIcon.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: setNetworkImg(
                        image: storeIcon,
                        width: 56,
                        height: 56,
                        boxFit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.storefront_rounded,
                          color: colorScheme.iconSecondary, size: 28),
                    ),
            ),
            const SizedBox(width: 14),
            // Store Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (firstStore.sellers?.isNotEmpty == true
                            ? (firstStore.sellers!.first.sellerAddress ??
                                firstStore.sellers!.first.sellerPlaceName)
                            : null) ??
                        'Store Address',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.textSecondary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Call Button
            if (sellerPhone != null && sellerPhone.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _makePhoneCall(sellerPhone, context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Delivery Boy Contact Card - Shows delivery person details with calling option
class _DeliveryBoyContactCard extends StatelessWidget {
  final Order order;
  const _DeliveryBoyContactCard({required this.order});

  void _makePhoneCall(String phoneNumber, BuildContext context) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryBoyName = order.deliveryBoyName;
    final deliveryBoyMobile = order.deliveryBoyNumber;

    // Don't show if no delivery boy assigned
    if (deliveryBoyName == null ||
        deliveryBoyName.isEmpty ||
        deliveryBoyName == 'null') {
      return const SizedBox.shrink();
    }

    return _ZenCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Delivery Boy Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.9),
                    const Color(0xFF2563EB),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            // Delivery Boy Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveryBoyName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    getTranslatedValue(context, 'delivery_partner'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      letterSpacing: -0.2,
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
                    _makePhoneCall(deliveryBoyMobile, context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer widget for Items Card
class _ItemsCardShimmer extends StatefulWidget {
  const _ItemsCardShimmer();

  @override
  State<_ItemsCardShimmer> createState() => _ItemsCardShimmerState();
}

class _ItemsCardShimmerState extends State<_ItemsCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header shimmer
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    _buildShimmerBox(48, 48, 12, colorScheme),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerBox(16, 150, 6, colorScheme),
                          const SizedBox(height: 6),
                          _buildShimmerBox(12, 80, 6, colorScheme),
                        ],
                      ),
                    ),
                    _buildShimmerBox(28, 90, 10, colorScheme),
                  ],
                ),
              ),
              // Items shimmer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(
                    2,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colorScheme.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          _buildShimmerBox(70, 70, 10, colorScheme),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildShimmerBox(
                                    14, double.infinity, 6, colorScheme),
                                const SizedBox(height: 8),
                                _buildShimmerBox(20, 80, 6, colorScheme),
                                const SizedBox(height: 8),
                                _buildShimmerBox(16, 60, 6, colorScheme),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(double height, double width, double borderRadius,
      AppColorScheme colorScheme) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.shimmerBase,
            colorScheme.shimmerHighlight,
            colorScheme.shimmerBase,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }
}

/// Shimmer widget for Bills Card
class _BillsCardShimmer extends StatefulWidget {
  const _BillsCardShimmer();

  @override
  State<_BillsCardShimmer> createState() => _BillsCardShimmerState();
}

class _BillsCardShimmerState extends State<_BillsCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              _buildShimmerBox(20, 120, 6, colorScheme),
              const SizedBox(height: 20),
              // Billing rows shimmer
              ...List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShimmerBox(14, 100, 6, colorScheme),
                      _buildShimmerBox(14, 60, 6, colorScheme),
                    ],
                  ),
                ),
              ),
              // Divider
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 16),
                height: 1,
                color: colorScheme.divider,
              ),
              // Total row shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(18, 100, 6, colorScheme),
                  _buildShimmerBox(18, 80, 6, colorScheme),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(double height, double width, double borderRadius,
      AppColorScheme colorScheme) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.shimmerBase,
            colorScheme.shimmerHighlight,
            colorScheme.shimmerBase,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }
}

/// Shimmer widget for Cart Info Card
class _CartInfoCardShimmer extends StatefulWidget {
  const _CartInfoCardShimmer();

  @override
  State<_CartInfoCardShimmer> createState() => _CartInfoCardShimmerState();
}

class _CartInfoCardShimmerState extends State<_CartInfoCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(18),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              _buildShimmerBox(20, 150, 6, colorScheme),
              const SizedBox(height: 16),
              // Divider
              Container(height: 1, color: colorScheme.divider),
              const SizedBox(height: 16),
              // Info rows with icons
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(40, 40, 10, colorScheme),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildShimmerBox(12, 100, 6, colorScheme),
                            const SizedBox(height: 6),
                            _buildShimmerBox(14, 180, 6, colorScheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Download button shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(14, 120, 6, colorScheme),
                  _buildShimmerBox(16, 90, 6, colorScheme),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(double height, double width, double borderRadius,
      AppColorScheme colorScheme) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.shimmerBase,
            colorScheme.shimmerHighlight,
            colorScheme.shimmerBase,
          ],
          stops: [
            _animation.value - 0.3,
            _animation.value,
            _animation.value + 0.3,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }
}

// class OrderDetailScreen extends StatefulWidget {
//   final String orderId;
//   final String from;

//   const OrderDetailScreen({
//     super.key,
//     required this.orderId,
//     required this.from,
//   });

//   @override
//   State<OrderDetailScreen> createState() => _OrderDetailScreenState();
// }

// class _OrderDetailScreenState extends State<OrderDetailScreen> {
//   late Order order;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(callApi);
//   }

//   Future<void> callApi() async {
//     final res = await context.read<CurrentOrderProvider>().getCurrentOrder(
//       params: {ApiAndParams.orderId: widget.orderId},
//       context: context,
//     );
//     if (res is Order) {
//       setState(() => order = res);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, _) {
//         if (didPop) return;
//         Navigator.pop(context, order);
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF5F5F5),
//         appBar: getAppBar(
//           context: context,
//           title: CustomTextLabel(
//             jsonKey: orderSummaryLabel,
//             style: TextStyle(
//               color: ColorsRes.mainTextColor,
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ),
//         body: Consumer<CurrentOrderProvider>(
//           builder: (context, currentOrderProvider, _) {
//             final state = currentOrderProvider.currentOrderState;

//             if (state == CurrentOrderState.loading) {
//               return ListView.builder(
//                 padding: const EdgeInsets.all(12),
//                 itemCount: 6,
//                 itemBuilder: (_, __) => const CustomShimmer(
//                   height: 120,
//                   width: double.infinity,
//                   borderRadius: 12,
//                   margin: EdgeInsets.symmetric(vertical: 6),
//                 ),
//               );
//             }

//             if (state != CurrentOrderState.loaded &&
//                 state != CurrentOrderState.silentLoading) {
//               return DefaultBlankItemMessageScreen(
//                 height: context.height,
//                 image: "something_went_wrong",
//                 title:
//                     getTranslatedValue(context, somethingWentWrongTitleLabel),
//                 description: getTranslatedValue(
//                     context, somethingWentWrongDescriptionLabel),
//                 buttonTitle: getTranslatedValue(context, tryAgainLabel),
//                 callback: callApi,
//               );
//             }

//             return CustomScrollView(
//               physics: const BouncingScrollPhysics(),
//               slivers: [
//                 SliverPadding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                   sliver: SliverList(
//                     delegate: SliverChildListDelegate(
//                       [
//                         OrderInformationWidget(order: order),
//                         if (order.orderNote.toString().isNotEmpty &&
//                             order.orderNote.toString() != "null")
//                           _OrderNoteCard(order: order),
//                         OrderInvoiceWidget(order: order),
//                         OrderProductsWidget(
//                           order: order,
//                           voidCallback: callApi,
//                           from: widget.from,
//                         ),
//                         OrderDeliveryAddressWidget(
//                           order: order,
//                           from: widget.from,
//                         ),
//                         OrderBillingDetailsWidget(order: order),
//                         const SizedBox(height: 16),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),

//     );
//   }
// }

class _OrderNoteCard extends StatelessWidget {
  final Order order;
  const _OrderNoteCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextLabel(
            jsonKey: orderNoteTitleLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ColorsRes.mainTextColor,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 8),
          CustomTextLabel(
            text: order.orderNote,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ColorsRes.mainTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:project/helper/utils/generalImports.dart';

// import 'package:project/screens/orderDetailScreen/widgets/orderBillingDetailsWidget.dart';
// import 'package:project/screens/orderDetailScreen/widgets/orderDeliveryAddressWidget.dart';
// import 'package:project/screens/orderDetailScreen/widgets/orderInformationWidget.dart';
// import 'package:project/screens/orderDetailScreen/widgets/orderInvoiceWidget.dart';
// import 'package:project/screens/orderDetailScreen/widgets/orderProductsWidget.dart';

// class OrderDetailScreen extends StatefulWidget {
//   final String orderId;
//   final String from;

//   const OrderDetailScreen({super.key, required this.orderId, required this.from});

//   @override
//   State<OrderDetailScreen> createState() => _OrderDetailScreenState();
// }

// class _OrderDetailScreenState extends State<OrderDetailScreen> {
//   late Order order;

//   @override
//   void initState() {
//     Future.delayed(Duration.zero).then((value) async {
//       await callApi();
//     });
//     super.initState();
//   }

//   Future callApi() async {
//     context.read<CurrentOrderProvider>().getCurrentOrder(params: {ApiAndParams.orderId: widget.orderId}, context: context).then((value) {
//       if (value is Order) {
//         order = value;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, _) {
//         if (didPop) {
//           return;
//         } else {
//           Navigator.pop(context, order);
//         }
//       },
//       child: Scaffold(
//         appBar: getAppBar(
//           context: context,
//           title: CustomTextLabel(
//             jsonKey: orderSummaryLabel,
//             style: TextStyle(color: ColorsRes.mainTextColor),
//           ),
//         ),
//         body: Consumer<CurrentOrderProvider>(
//           builder: (context, currentOrderProvider, child) {
//             if (currentOrderProvider.currentOrderState == CurrentOrderState.loaded ||
//                 currentOrderProvider.currentOrderState == CurrentOrderState.silentLoading) {
//               return SingleChildScrollView(
//                 child: Padding(
//                   padding: EdgeInsetsDirectional.all(10),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       // Order details container
//                       OrderInformationWidget(order: order),
//                       // Order Note
//                       if (order.orderNote.toString() != "" && order.orderNote.toString() != "null")
//                         Container(
//                           width: context.width,
//                           margin: const EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)),
//                           child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsetsDirectional.only(start: 10.0, top: 10.0),
//                                 child: CustomTextLabel(
//                                   jsonKey: orderNoteTitleLabel,
//                                   softWrap: true,
//                                   style: TextStyle(
//                                     fontSize: 16.0,
//                                     fontWeight: FontWeight.bold,
//                                     color: ColorsRes.mainTextColor,
//                                   ),
//                                 ),
//                               ),
//                               getDivider(),
//                               Padding(
//                                 padding: const EdgeInsetsDirectional.only(start: 10.0, bottom: 10.0),
//                                 child: CustomTextLabel(
//                                   text: "${order.orderNote}",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w500,
//                                     color: ColorsRes.mainTextColor,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       // Download invoice button
//                       OrderInvoiceWidget(order: order),
//                       // Order details container
//                       OrderProductsWidget(
//                         order: order,
//                         voidCallback: () {
//                           callApi();
//                         },
//                         from: widget.from,
//                       ),
//                       // Delivery address container
//                       OrderDeliveryAddressWidget(
//                         order: order,
//                         from: widget.from,
//                       ),
//                       // Billing details container
//                       OrderBillingDetailsWidget(order: order),
//                     ],
//                   ),
//                 ),
//               );
//             } else if (currentOrderProvider.currentOrderState == CurrentOrderState.loading) {
//               return ListView(
//                 children: List.generate(
//                   20,
//                   (index) {
//                     return CustomShimmer(
//                       height: 120,
//                       width: context.width,
//                       borderRadius: 10,
//                       margin: EdgeInsetsDirectional.only(
//                         top: 10,
//                         start: 10,
//                         end: 10,
//                       ),
//                     );
//                   },
//                 ),
//               );
//             } else {
//               return Container(
//                 alignment: Alignment.center,
//                 height: context.height,
//                 width: context.width,
//                 child: DefaultBlankItemMessageScreen(
//                   height: context.height,
//                   image: "something_went_wrong",
//                   title: getTranslatedValue(context, somethingWentWrongTitleLabel),
//                   description: getTranslatedValue(context, somethingWentWrongDescriptionLabel),
//                   buttonTitle: getTranslatedValue(context, tryAgainLabel),
//                   callback: () async {
//                     callApi();
//                   },
//                 ),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
