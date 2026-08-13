import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/place_proveder.dart';
import 'package:project/provider/support_contact_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/newHome/banners_home.dart';
import 'package:project/screens/newHome/dashboard_grid.dart';
import 'package:project/screens/newHome/dialogs/store_relocation_dialog.dart';
import 'package:project/screens/newHome/food_dashboard_provider.dart';
import 'package:project/screens/newHome/food_topbar.dart';
import 'package:project/screens/newHome/home_chart.dart';
import 'package:project/screens/newHome/stock_products_list_screen.dart';
import 'package:project/screens/newHome/stock_products_section.dart';
import 'package:project/screens/newHome/today_stats.dart';
import 'package:project/screens/ordersScreen/admin_chat.dart';
import 'package:project/screens/resgistration/food/location_picker.dart';

class FoodDashboard extends StatefulWidget {
  const FoodDashboard({super.key});

  @override
  State<FoodDashboard> createState() => _FoodDashboardState();
}

class _FoodDashboardState extends State<FoodDashboard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final provider = context.read<FoodDashboardProvider>();
      provider.fetchStoreData();
      provider.fetchStatistics(context);
      provider.fetchSoldOutProducts();
      provider.fetchLowStockProducts();
      context.read<SupportContactProvider>().fetchSupportContacts();
    });
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
            : Column(
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
                  if (contact != null && contact.phone.isNotEmpty)
                    _buildContactTile(
                      icon: Icons.phone_rounded,
                      label: 'Call Us',
                      value: contact.phone,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        launchUrl(Uri.parse('tel:${contact.phone}'));
                      },
                    ),
                  if (contact != null && contact.phone.isNotEmpty)
                    SizedBox(height: 12),
                  // Email tile
                  if (contact != null && contact.email.isNotEmpty)
                    _buildContactTile(
                      icon: Icons.email_rounded,
                      label: 'Email Us',
                      value: contact.email,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        launchUrl(Uri.parse('mailto:${contact.email}'));
                      },
                    ),
                  if (contact != null && contact.email.isNotEmpty)
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

  void _handleLocationTap() {
    final provider = context.read<FoodDashboardProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (bottomSheetContext) => StoreRelocationDialog(
        onConfirm: () async {
          Navigator.pop(bottomSheetContext);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                      create: (_) => PlaceSuggestionsProvider()),
                  ChangeNotifierProvider(create: (_) => PlaceDetailsProvider()),
                ],
                child: LocationPickerScreen(
                  initialPoint:
                      provider.latitude != null && provider.longitude != null
                          ? LatLng(provider.latitude!, provider.longitude!)
                          : null,
                ),
              ),
            ),
          );

          if (result != null) {
            final lat = result.latitude as double;
            final lng = result.longitude as double;
            final address = result.formattedAddress as String;

            await provider.updateStoreLocation(
              context: context,
              newLocation: address,
              lat: lat,
              lng: lng,
            );
          }
        },
        onCancel: () {
          Navigator.pop(bottomSheetContext);
        },
      ),
    );
  }

  void _handleStatusToggle(bool value) async {
    final provider = context.read<FoodDashboardProvider>();

    // Confirm before going OFFLINE — while offline the store stops receiving
    // new orders, so it's a disruptive action worth a double-check. Going
    // back online is harmless and proceeds without a prompt.
    if (!value) {
      final confirmed = await _confirmGoOffline();
      if (confirmed != true) return;
    }

    await provider.updateStoreStatus(
      context: context,
      isOpen: value,
    );
  }

  Future<bool?> _confirmGoOffline() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Go Offline?',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to go offline? You won't receive new orders until you go back online.",
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.45,
              color: const Color(0xFF6B7280),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'No',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: colorScheme.background,
          body: Consumer<FoodDashboardProvider>(
            builder: (context, provider, _) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Sliver App Bar with Header
                  SliverAppBar(
                    expandedHeight: 130,
                    floating: true,
                    pinned: false,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      background: FoodHomeHeader(
                        businessName: provider.businessName.isEmpty
                            ? "Zenfoo Business"
                            : provider.businessName,
                        storeName: provider.storeName.isEmpty
                            ? getTranslatedValue(context, loadingLabel)
                            : provider.storeName,
                        address: provider.storeLocation.isEmpty
                            ? "${getTranslatedValue(context, loadingLabel)} ${getTranslatedValue(context, addressLabel)}"
                            : provider.storeLocation,
                        switchValue: provider.isStoreOpen,
                        onSwitchChanged: _handleStatusToggle,
                        onLocationTap: _handleLocationTap,
                        isUpdatingStatus: provider.isUpdatingStatus,
                        onHelp: () {
                          _showSupportDialog();
                        },
                      ),
                    ),
                  ),

                  // Dashboard Stats Grid
                  const SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 400),
                      child: DashboardStatsGrid(),
                    ),
                  ),

                  // Spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Banner Carousel 1
                  const SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 500),
                      child: BannerCarousel(section: 1),
                    ),
                  ),

                  // Spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Today's Statistics
                  const SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 600),
                      child: TodaysStatisticsGrid(),
                    ),
                  ),

                  // Spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Banner Carousel 2
                  const SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 700),
                      child: BannerCarousel(section: 2),
                    ),
                  ),

                  // Spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Sold Out Products
                  SliverToBoxAdapter(
                    child: Consumer<LanguageProvider>(
                      builder: (context, _, __) {
                        return StockProductsSection(
                          title: getTranslatedValue(
                              context, soldOutProductsLabel),
                          products: provider.soldOutProducts,
                          accentColor: const Color(0xFFEF4444),
                          isLoading: provider.isLoadingSoldOut,
                          totalCount: provider.soldOutCount,
                          onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StockProductsListScreen(
                                        type: StockListType.soldOut),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Low Stock Products
                  SliverToBoxAdapter(
                    child: Consumer<LanguageProvider>(
                      builder: (context, _, __) {
                        return StockProductsSection(
                          title: getTranslatedValue(
                              context, lowStockProductsLabel),
                          products: provider.lowStockProducts,
                          accentColor: const Color(0xFFF97316),
                          isLoading: provider.isLoadingLowStock,
                          totalCount: provider.lowStockCount,
                          onViewAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StockProductsListScreen(
                                        type: StockListType.lowStock),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Product Category Chart
                  const SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 800),
                      child: ProductCategoryPieChart(),
                    ),
                  ),

                  // Zenfoo Seller Branding
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 900),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white10,
                                Colors.white24,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'ZENFOO\nBUSINESS',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                // color: colorScheme.textPrimary,
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                height: 0.9,
                                letterSpacing: -3.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
