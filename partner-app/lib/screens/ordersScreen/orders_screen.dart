import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/new_orders_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/provider/support_contact_provider.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/screens/ordersScreen/order_details_screen.dart';
import 'package:project/screens/ordersScreen/seller_order_chat_screen.dart';
import 'package:project/screens/ordersScreen/admin_chat.dart';
import 'package:project/screens/ordersScreen/orders_tab_bar.dart';
import 'package:project/screens/ordersScreen/order_list_view.dart';
import 'package:project/screens/ordersScreen/status/pickup_order_screen.dart';
import 'package:project/models/new_order.dart' as new_order;
import 'package:project/repositories/newOrdersApi.dart';
import 'package:project/services/firebase_orders_service.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class OrdersScreen extends StatefulWidget {
  final int? initialStatusId;
  final bool filterToday;

  const OrdersScreen({
    super.key,
    this.initialStatusId,
    this.filterToday = false,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late ScrollController scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  NewOrdersProvider? _provider;

  Map<int, int> orderMinutes = {};
  Map<int, GlobalKey<AnimatedOrderCardState>> cardKeys = {};

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      // Fetch support contacts for Help Us dialog
      context.read<SupportContactProvider>().fetchSupportContacts();

      // Reset Firebase tracker when entering orders screen
      _resetFirebaseTracker();

      // Start Firebase real-time listener instead of API polling
      _startFirebaseListener();

      // Apply initial filters if provided (e.g. from Today's Statistics cards)
      final provider = context.read<NewOrdersProvider>();
      _provider = provider;
      if (widget.initialStatusId != null) {
        await provider.changeSelectedStatus(widget.initialStatusId!);
      } else {
        // Reset status when opened normally (not from Today's Statistics)
        await provider.changeSelectedStatus(0);
      }
      if (widget.filterToday) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        provider.setDateRange(today, today);
      } else {
        // Clear any stale date filter from a previous navigation
        provider.clearDateRange();
      }

      // Initial load from API to get complete data
      await _loadOrders(reset: true);
      searchController.addListener(_onSearchChanged);
      scrollController.addListener(_scrollListener);
    });
  }

  void _startFirebaseListener() {
    final provider = context.read<NewOrdersProvider>();
    // Use keyUserId because setUserData() converts "id" to "user_id" when storing
    final sellerIdStr = Constant.session.getData(SessionManager.keyUserId);
    final sellerId = int.tryParse(sellerIdStr) ?? 0;

    if (sellerId != 0) {
      provider.startFirebaseListener(sellerId: sellerId);
      debugPrint('✅ Firebase real-time listener started for seller $sellerId');
    } else {
      debugPrint('⚠️ Seller ID not found in session: "$sellerIdStr"');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    scrollController.dispose();

    // Clear filters applied from Today's Statistics so they don't persist
    // Use addPostFrameCallback to avoid notifyListeners() during dispose
    if (_provider != null && (widget.filterToday || widget.initialStatusId != null)) {
      final provider = _provider!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.filterToday) provider.clearDateRange();
        if (widget.initialStatusId != null) provider.changeSelectedStatus(0);
      });
    }

    super.dispose();
  }

  /// Reset Firebase tracker to clear existing orders and prepare for fresh notifications
  void _resetFirebaseTracker() {
    try {
      final firebaseOrdersService = FirebaseOrdersService();
      firebaseOrdersService.resetTracker();
      debugPrint(
          '🔄 Firebase listener tracker reset - cleared existing orders');
    } catch (e) {
      debugPrint('⚠️ Error resetting Firebase tracker: $e');
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadOrders(reset: true);
    });
  }

  void _scrollListener() {
    var nextPageTrigger = 0.7 * scrollController.position.maxScrollExtent;

    if (scrollController.position.pixels > nextPageTrigger) {
      if (mounted) {
        final provider = context.read<NewOrdersProvider>();
        if (provider.hasMoreData &&
            provider.ordersState != NewOrdersState.loadingMore) {
          _loadOrders(reset: false);
        }
      }
    }
  }

  Future<void> _loadOrders({bool reset = false, bool silent = false}) async {
    Map<String, String> params = {};

    if (searchController.text.trim().isNotEmpty) {
      params[ApiAndParams.search] = searchController.text.trim();
      debugPrint('=== Search Query: ${searchController.text.trim()} ===');
    }

    await context.read<NewOrdersProvider>().getOrders(
          context: context,
          params: params,
          silentLoading: silent,
          reset: reset,
        );
  }

  Future<void> _onTabSelected(int tabIndex, int statusId) async {
    await context.read<NewOrdersProvider>().changeSelectedStatus(statusId);
    await _loadOrders(reset: true);
  }

  /// Returns the status id of the API-driven "Ongoing" tab, or null if the
  /// backend doesn't expose one. Used to auto-switch tabs after a preparation
  /// time is set.
  int? _ongoingStatusId(NewOrdersProvider provider) {
    for (final status in provider.statusOrderCounts) {
      if ((status.status ?? '').toLowerCase().contains('ongoing')) {
        return status.id;
      }
    }
    return null;
  }

  Order _convertToOrder(new_order.OrderData apiOrder) {
    final trackingStatus = apiOrder.trackingInfo?.status;
    final orderStatusId = apiOrder.statusData?.id;
    final hasDeliveryPartner = apiOrder.deliveryBoy is new_order.DeliveryBoy;
    OrderStatus status =
        _mapStatus(trackingStatus, orderStatusId, hasDeliveryPartner);

    // Check activeStatus for cancelled/returned orders not caught by trackingStatus or statusId
    final activeStatus = apiOrder.activeStatus?.toLowerCase() ?? '';
    if (activeStatus == 'cancelled' || activeStatus == 'returned') {
      status = OrderStatus.cancelled;
    }

    return Order(
      orderData: apiOrder,
      status: status,
      minutes: orderMinutes[apiOrder.orderId] ?? 15,
    );
  }

  OrderStatus _mapStatus(
      String? trackingStatus, int? orderStatusId, bool hasDeliveryPartner) {
    if (trackingStatus != null) {
      switch (trackingStatus) {
        case 'assigned_to_seller':
          return OrderStatus.preparing;
        case 'packed_by_seller':
          if (orderStatusId == 3) {
            return OrderStatus.otp;
          }
          return OrderStatus.readyForPickup;
        case 'given_to_delivery_partner':
          if (orderStatusId != null && orderStatusId >= 6) {
            return OrderStatus.delivered;
          }
          if (orderStatusId == 5) {
            return OrderStatus.outForDelivery;
          }
          return OrderStatus.picked;
        case 'out_for_delivery':
          return OrderStatus.outForDelivery;
        case 'delivered':
          return OrderStatus.delivered;
        case 'cancelled':
        case 'returned':
          return OrderStatus.cancelled;
        default:
          break;
      }
    }

    switch (orderStatusId) {
      case 1:
        return OrderStatus.preparing;
      case 2:
        return OrderStatus.preparing;
      case 3:
        return OrderStatus.otp;
      case 4:
        return OrderStatus.picked;
      case 5:
        return OrderStatus.outForDelivery;
      case 6:
        return OrderStatus.delivered;
      case 7:
        return OrderStatus.cancelled;
      case 8:
        return OrderStatus.cancelled;
      default:
        return OrderStatus.preparing;
    }
  }

  void _showDateRangePicker() async {
    final provider = context.read<NewOrdersProvider>();
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        selectedDayHighlightColor: ColorsRes.appColor,
        selectedRangeHighlightColor: ColorsRes.appColor.withValues(alpha: 0.2),
        weekdayLabelTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.textSecondary,
        ),
        controlsTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.textPrimary,
        ),
        dayTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.textPrimary,
        ),
        disabledDayTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.textTertiary,
        ),
        selectedDayTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        todayTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ColorsRes.appColor,
        ),
        yearTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.textPrimary,
        ),
        selectedYearTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        okButtonTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ColorsRes.appColor,
          letterSpacing: -0.3,
        ),
        cancelButtonTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.textSecondary,
          letterSpacing: -0.3,
        ),
        dayBorderRadius: BorderRadius.circular(8),
        yearBorderRadius: BorderRadius.circular(8),
        centerAlignModePicker: true,
        customModePickerIcon: const SizedBox.shrink(),
      ),
      dialogSize: const Size(340, 400),
      value: provider.fromDate != null && provider.toDate != null
          ? [provider.fromDate!, provider.toDate!]
          : [],
      borderRadius: BorderRadius.circular(20),
      dialogBackgroundColor: colorScheme.surface,
      barrierColor: Colors.black.withOpacity(0.5),
    );

    if (results != null && results.isNotEmpty) {
      final startDate = results[0];
      final endDate = results.length >= 2 ? results[1] : results[0];
      if (startDate != null && endDate != null) {
        provider.setDateRange(startDate, endDate);
        _loadOrders(reset: true);
      }
    }
  }

  void _clearDateRange() {
    context.read<NewOrdersProvider>().clearDateRange();
    _loadOrders(reset: true);
  }

  void _showSupportDialog() {
    final provider = context.read<SupportContactProvider>();
    final contact = provider.supportContact;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.support_agent_rounded,
                  color: Color(0xFF9AC444), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: provider.state == SupportContactState.loading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF9AC444)),
                ),
              )
            : contact != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Need help? Reach out to our support team through any of the options below.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Phone tile
                      if (contact.phone.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.phone_rounded,
                          label: 'Call Us',
                          value: contact.phone,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('tel:${contact.phone}'));
                          },
                        ),
                      if (contact.phone.isNotEmpty && contact.email.isNotEmpty)
                        SizedBox(height: 12),
                      // Email tile
                      if (contact.email.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.email_rounded,
                          label: 'Email Us',
                          value: contact.email,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('mailto:${contact.email}'));
                          },
                        ),
                      SizedBox(height: 12),
                      // Chat tile
                      _buildContactTile(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat with Us',
                        value: 'Start a live chat',
                        onTap: () {
                          Navigator.pop(dialogContext);
                          final sellerId = int.tryParse(Constant.session
                                  .getData(SessionManager.keyUserId)) ??
                              0;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SellerAdminChatScreen(sellerId: sellerId),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Text(
                    'Unable to load support contacts. Please try again later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9AC444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF9AC444), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, double.maxFinite),
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return AppHeader(
              label: getTranslatedValue(context, orderManagementLabel),
              title: getTranslatedValue(context, ordersLabel),
              trailing: Material(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: StadiumBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: _showSupportDialog,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          getTranslatedValue(context, helpUsLabel),
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            height: 1.02,
                            letterSpacing: -0.55,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(Icons.headset_mic_rounded,
                            size: 20, color: colorScheme.iconPrimary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: Consumer<NewOrdersProvider>(
        builder: (context, provider, child) {
          final tabs = provider.statusOrderCounts.map((statusCount) {
            final title = statusCount.id == 0
                ? 'New Orders'
                : (statusCount.status ?? '');
            return OrderTabData(title, statusCount.orderCount ?? 0);
          }).toList();

          int currentTabIndex = 0;
          if (provider.statusOrderCounts.isNotEmpty) {
            currentTabIndex = provider.statusOrderCounts
                .indexWhere((s) => s.id == provider.selectedStatus);
            if (currentTabIndex == -1) currentTabIndex = 0;
          }

          final filteredOrders = provider.ordersList;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => _loadOrders(reset: true),
                color: ColorsRes.appColor,
                backgroundColor: colorScheme.cardBackground,
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        color: colorScheme.surface,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colorScheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.border,
                                    width: 1,
                                  ),
                                ),
                                child: Consumer<LanguageProvider>(
                                  builder: (context, languageProvider, child) {
                                    return TextField(
                                      controller: searchController,
                                      onChanged: (_) => setState(() {}),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: getTranslatedValue(
                                            context, searchOrdersLabel),
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.textTertiary,
                                          letterSpacing: -0.3,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: colorScheme.iconSecondary,
                                          size: 20,
                                        ),
                                        suffixIcon: searchController
                                                .text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.close_rounded,
                                                  color:
                                                      colorScheme.iconSecondary,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  searchController.clear();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showDateRangePicker,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 48,
                                  // padding: EdgeInsets.symmetric(horizontal: 16),
                                  // decoration: BoxDecoration(
                                  //   color: provider.fromDate != null &&
                                  //           provider.toDate != null
                                  //       ? ColorsRes.appColor
                                  //       : colorScheme.cardBackground,
                                  //   borderRadius: BorderRadius.circular(12),
                                  //   border: Border.all(
                                  //     color: provider.fromDate != null &&
                                  //             provider.toDate != null
                                  //         ? ColorsRes.appColor
                                  //         : colorScheme.border,
                                  //     width: 1,
                                  //   ),
                                  // ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: colorScheme.cardBackground,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colorScheme.border,
                                            width: 1,
                                          ),
                                        ),
                                        child: HugeIcon(
                                          icon:
                                              HugeIcons.strokeRoundedCalendar02,
                                          color: Color(0xFF9AC444),
                                          size: 20,
                                        ),
                                      ),
                                      if (provider.fromDate != null &&
                                          provider.toDate != null) ...[
                                        SizedBox(width: 8),
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _clearDateRange,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (provider.fromDate != null && provider.toDate != null)
                      SliverToBoxAdapter(
                        child: Container(
                          color: colorScheme.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: ColorsRes.appColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.date_range,
                                  color: ColorsRes.appColor,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${DateFormat('dd MMM yyyy').format(provider.fromDate!)} - ${DateFormat('dd MMM yyyy').format(provider.toDate!)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ColorsRes.appColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _clearDateRange,
                                  child: Icon(
                                    Icons.close,
                                    color: ColorsRes.appColor,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (tabs.isNotEmpty)
                      SliverPersistentHeader(
                        pinned: true,
                        floating: false,
                        delegate: _SliverTabBarDelegate(
                          child: OrdersTabBar(
                            selectedIndex: currentTabIndex,
                            tabs: tabs,
                            onTabSelected: (i) async {
                              if (i < provider.statusOrderCounts.length) {
                                final statusId =
                                    provider.statusOrderCounts[i].id ?? 0;
                                await _onTabSelected(i, statusId);
                              }
                            },
                          ),
                          topPadding: MediaQuery.of(context).padding.top,
                          colorScheme: colorScheme,
                        ),
                      ),
                    if (provider.ordersState == NewOrdersState.loading)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: index < 9 ? 16.0 : 0.0,
                              ),
                              child: _buildShimmer(colorScheme),
                            ),
                            childCount: 10,
                          ),
                        ),
                      ),
                    if (provider.ordersState == NewOrdersState.error)
                      SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Consumer<LanguageProvider>(
                              builder: (context, languageProvider, child) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      getTranslatedValue(
                                          context, unableToLoadOrdersLabel),
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      provider.message,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colorScheme.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    InkWell(
                                      onTap: () => _loadOrders(reset: true),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ColorsRes.appColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: ColorsRes.appColor
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.refresh_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              getTranslatedValue(
                                                  context, tryAgainLabel),
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (provider.ordersState == NewOrdersState.empty ||
                        (provider.ordersState == NewOrdersState.loaded &&
                            filteredOrders.isEmpty))
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Consumer<LanguageProvider>(
                              builder: (context, languageProvider, child) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 56,
                                        color: colorScheme.iconSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      getTranslatedValue(
                                          context, noOrdersFoundLabel),
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      searchController.text.isNotEmpty
                                          ? getTranslatedValue(
                                              context, noOrdersMatchSearchLabel)
                                          : getTranslatedValue(
                                              context, ordersAppearHereLabel),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colorScheme.textSecondary,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (provider.ordersState == NewOrdersState.loaded ||
                        provider.ordersState == NewOrdersState.loadingMore ||
                        provider.ordersState == NewOrdersState.silentLoading)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == filteredOrders.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildShimmer(colorScheme),
                                );
                              }

                              final apiOrder = filteredOrders[index];
                              final order = _convertToOrder(apiOrder);

                              final orderId = apiOrder.orderId!;
                              if (!cardKeys.containsKey(orderId)) {
                                cardKeys[orderId] =
                                    GlobalKey<AnimatedOrderCardState>();
                              }

                              return _OrderEntryAnimation(
                                index: index,
                                child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < filteredOrders.length - 1
                                      ? 16.0
                                      : 0.0,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailsScreen(
                                          order: order,
                                          onCall: () async {
                                            // Call the driver
                                            final phoneNumber =
                                                order.orderData.deliveryBoy
                                                    is new_order.DeliveryBoy
                                                    ? (order.orderData.deliveryBoy
                                                            as new_order.DeliveryBoy)
                                                        .mobile
                                                    : null;
                                            if (phoneNumber != null &&
                                                phoneNumber.isNotEmpty) {
                                              try {
                                                final Uri phoneUri = Uri(
                                                    scheme: 'tel',
                                                    path: phoneNumber);
                                                if (await canLaunchUrl(
                                                    phoneUri)) {
                                                  await launchUrl(phoneUri);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Could not launch phone call',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error: ${e.toString()}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Driver phone number not available',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          onChat: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    SellerOrderChatScreen(
                                                  orderId: order.orderId ?? 0,
                                                  driverId: order.orderData
                                                      .deliveryBoyId,
                                                  driverName: order
                                                          .deliveryPerson
                                                          .isNotEmpty
                                                      ? order.deliveryPerson
                                                      : 'Delivery Partner',
                                                ),
                                              ),
                                            );
                                          },
                                          onTimeChanged: (mins) {},
                                          onAdvance: () async {
                                            String newStatus = '';
                                            switch (order.status) {
                                              case OrderStatus.preparing:
                                                newStatus = 'packed_by_seller';
                                                break;
                                              case OrderStatus.readyForPickup:
                                                newStatus = 'packed_by_seller';
                                                break;
                                              default:
                                                return;
                                            }

                                            if (order.orderId != null) {
                                              final response =
                                                  await updateTrackingStatus(
                                                orderId: order.orderId!,
                                                status: newStatus,
                                                context: context,
                                              );

                                              if (response['status'] == 1) {
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  await context
                                                      .read<NewOrdersProvider>()
                                                      .getOrders(
                                                        context: context,
                                                        params: {},
                                                        silentLoading: false,
                                                        reset: true,
                                                      );
                                                }
                                              }
                                            }
                                          },
                                          onSubmitOtp: (code) async {
                                            if (order.orderId != null &&
                                                code.length == 4) {
                                              final response =
                                                  await verifyOtpAndUpdateStatus(
                                                orderId: order.orderId!,
                                                otp: code,
                                                context: context,
                                              );

                                              if (response['status'] == 1) {
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  await context
                                                      .read<NewOrdersProvider>()
                                                      .getOrders(
                                                        context: context,
                                                        params: {},
                                                        silentLoading: false,
                                                        reset: true,
                                                      );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                    _loadOrders(
                                      reset: true,
                                    );
                                  },
                                  child: AnimatedOrderCard(
                                    key: cardKeys[orderId],
                                    order: order,
                                    onTimeChanged: (mins) {
                                      setState(() {
                                        orderMinutes[apiOrder.orderId!] = mins;
                                      });
                                    },
                                    onAdvance: () {
                                      setState(() {});
                                    },
                                    onCall: () async {
                                      // Call the driver
                                      final phoneNumber =
                                          order.orderData.deliveryBoy
                                              is new_order.DeliveryBoy
                                              ? (order.orderData.deliveryBoy
                                                      as new_order.DeliveryBoy)
                                                  .mobile
                                              : null;
                                      if (phoneNumber != null &&
                                          phoneNumber.isNotEmpty) {
                                        try {
                                          final Uri phoneUri =
                                              Uri(scheme: 'tel', path: phoneNumber);
                                          if (await canLaunchUrl(phoneUri)) {
                                            await launchUrl(phoneUri);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not launch phone call',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Driver phone number not available',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    onChat: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SellerOrderChatScreen(
                                            orderId: order.orderId ?? 0,
                                            driverId: order.orderData
                                                .deliveryBoyId,
                                            driverName: order.deliveryPerson,
                                            
                                          ),
                                        ),
                                      );
                                    },
                                    onConfirmOtp: () {},
                                    onPrepTimeSet: () async {
                                      // Prep time set successfully → the order
                                      // moves to the "Ongoing" stage. Auto-switch
                                      // to that tab so the vendor follows it, and
                                      // the list slide-in animation replays.
                                      final ordersProvider =
                                          context.read<NewOrdersProvider>();
                                      final ongoingId =
                                          _ongoingStatusId(ordersProvider);
                                      if (ongoingId != null &&
                                          ordersProvider.selectedStatus !=
                                              ongoingId) {
                                        await ordersProvider
                                            .changeSelectedStatus(ongoingId);
                                        await _loadOrders(reset: true);
                                      } else {
                                        await ordersProvider.getOrders(
                                          context: context,
                                          params: {},
                                          silentLoading: true,
                                          reset: false,
                                        );
                                      }
                                    },
                                    onStatusUpdateSuccess: () async {
                                      await context
                                          .read<NewOrdersProvider>()
                                          .getOrders(
                                            context: context,
                                            params: {},
                                            silentLoading: false,
                                            reset: true,
                                          );
                                    },
                                    onStatusChanged: () async {
                                      await context
                                          .read<NewOrdersProvider>()
                                          .getOrders(
                                            context: context,
                                            params: {},
                                            silentLoading: false,
                                            reset: true,
                                          );
                                    },
                                  ),
                                ),
                                ),
                              );
                            },
                            childCount: filteredOrders.length +
                                (provider.ordersState ==
                                        NewOrdersState.loadingMore
                                    ? 1
                                    : 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmer(app_theme.AppColorScheme colorScheme) {
    return _ShimmerOrderCard(colorScheme: colorScheme);
  }
}

class _ShimmerOrderCard extends StatefulWidget {
  final app_theme.AppColorScheme colorScheme;

  const _ShimmerOrderCard({Key? key, required this.colorScheme})
      : super(key: key);

  @override
  State<_ShimmerOrderCard> createState() => _ShimmerOrderCardState();
}

class _ShimmerOrderCardState extends State<_ShimmerOrderCard>
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.colorScheme.border, width: 1),
            boxShadow: widget.colorScheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 18,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          widget.colorScheme.surfaceVariant,
                          widget.colorScheme.surface,
                          widget.colorScheme.surfaceVariant,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          widget.colorScheme.surfaceVariant,
                          widget.colorScheme.surface,
                          widget.colorScheme.surfaceVariant,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: widget.colorScheme.border),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          widget.colorScheme.surfaceVariant,
                          widget.colorScheme.surface,
                          widget.colorScheme.surfaceVariant,
                        ],
                        stops: [
                          _animation.value - 0.3,
                          _animation.value,
                          _animation.value + 0.3,
                        ].map((e) => e.clamp(0.0, 1.0)).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                widget.colorScheme.surfaceVariant,
                                widget.colorScheme.surface,
                                widget.colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                widget.colorScheme.surfaceVariant,
                                widget.colorScheme.surface,
                                widget.colorScheme.surfaceVariant,
                              ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            widget.colorScheme.surfaceVariant,
                            widget.colorScheme.surface,
                            widget.colorScheme.surfaceVariant,
                          ],
                          stops: [
                            _animation.value - 0.3,
                            _animation.value,
                            _animation.value + 0.3,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            widget.colorScheme.surfaceVariant,
                            widget.colorScheme.surface,
                            widget.colorScheme.surfaceVariant,
                          ],
                          stops: [
                            _animation.value - 0.3,
                            _animation.value,
                            _animation.value + 0.3,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double topPadding;
  final app_theme.AppColorScheme colorScheme;

  _SliverTabBarDelegate({
    required this.child,
    required this.topPadding,
    required this.colorScheme,
  });

  @override
  double get minExtent => 72.0;

  @override
  double get maxExtent => 72.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final showTopPadding = overlapsContent;

    return Container(
      height: 72.0 + (showTopPadding ? topPadding : 0),
      padding: EdgeInsets.only(top: showTopPadding ? topPadding : 0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: overlapsContent ? colorScheme.cardShadow : null,
      ),
      child: SizedBox(
        height: 72.0,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return topPadding != oldDelegate.topPadding;
  }
}

/// Plays a one-shot entrance animation (fade + upward slide + subtle scale)
/// when an order card first mounts. Because the orders list is cleared and
/// rebuilt on every tab switch, each card re-mounts and replays this — giving
/// the tab change a smooth, staggered "slide-in" feel. Cards appended during
/// pagination animate in too, while already-visible cards keep their State and
/// stay put (no re-animation on silent refresh).
class _OrderEntryAnimation extends StatefulWidget {
  final int index;
  final Widget child;

  const _OrderEntryAnimation({
    Key? key,
    required this.index,
    required this.child,
  }) : super(key: key);

  @override
  State<_OrderEntryAnimation> createState() => _OrderEntryAnimationState();
}

class _OrderEntryAnimationState extends State<_OrderEntryAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.07),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: 0.97, end: 1.0).animate(curve);

    // Subtle stagger so the cards cascade in instead of moving as one block.
    // Capped so cards far down the list don't wait too long.
    final delayMs = widget.index.clamp(0, 6) * 55;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}
