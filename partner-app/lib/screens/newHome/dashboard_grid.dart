import 'package:flutter/material.dart';
import 'package:project/helper/styles/typography.dart';
import 'package:project/helper/utils/generalImports.dart'
    hide ProductListScreen;
import 'package:project/models/store_model.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/screens/newHome/food_dashboard_provider.dart';
import 'package:project/screens/newProductsScreen/product_list.dart';
import 'package:project/screens/newProductsScreen/sweet_shop_product_list.dart';
import 'package:project/screens/ordersScreen/orders_screen.dart';
import 'package:project/screens/resgistration/food/food_registration.dart';
import 'package:project/screens/newHome/stock_products_list_screen.dart';

class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isSweetHouse = Constant.session.getIsSweetHouse();

    return Consumer<FoodDashboardProvider>(
      builder: (context, provider, _) {
        final overview = provider.overview;
        final isManagedByAdmin = Constant.session.getManagedByAdmin();
        final isLoading = provider.isLoading && overview == null;

        // Use actual data from API or defaults
        final allStats = [
          StatBoxData(
            bgColor: Color(0xffEEFECE),
            count: "${overview?.totalOrders ?? 0}",
            label: getTranslatedValue(context, totalOrdersLabel),
            image: "assets/images/orders.png",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrdersScreen(),
                ),
              );
            },
          ),
          StatBoxData(
            bgColor: const Color(0xFFE4EBFC),
            count: "${overview?.totalProducts ?? 0}",
            label: getTranslatedValue(context, productsLabel),
            image: "assets/images/vegitables2.png",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isSweetHouse
                      ? SweetShopProductListScreen()
                      : ProductListScreen(),
                ),
              );
            },
          ),
          StatBoxData(
            bgColor: const Color(0xFFDCFCE7),
            count: "${provider.soldOutCount}",
            label: getTranslatedValue(context, soldOutProductsLabel),
            image: "assets/images/products.png",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockProductsListScreen(type: StockListType.soldOut),
                ),
              );
            },
          ),
          StatBoxData(
            bgColor: const Color(0xFFFFEADA),
            count: "${provider.lowStockCount}",
            label: getTranslatedValue(context, lowStockProductsLabel),
            image: "assets/images/stocks.png",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StockProductsListScreen(type: StockListType.lowStock),
                ),
              );
            },
          ),
        ];

        // Filter stats based on admin management status
        final soldOutLabel = getTranslatedValue(context, soldOutProductsLabel);
        final lowStockLabel =
            getTranslatedValue(context, lowStockProductsLabel);
        final stats = isManagedByAdmin
            ? allStats
                .where((stat) =>
                    stat.label != soldOutLabel && stat.label != lowStockLabel)
                .toList()
            : allStats;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const aspectRatio = 1.35;
              return GridView.builder(
                padding: EdgeInsets.zero,
                itemCount: stats.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, idx) {
                  if (isLoading) {
                    return _ShimmerStatBox(colorScheme: colorScheme);
                  }
                  final stat = stats[idx];
                  return StatBox(
                    bgColor: stat.bgColor,
                    count: stat.count,
                    label: stat.label,
                    image: stat.image,
                    onTap: stat.onTap,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class StatBoxData {
  final Color bgColor;
  final String count;
  final String label;
  final String image;
  final void Function() onTap;

  StatBoxData({
    required this.bgColor,
    required this.count,
    required this.label,
    required this.image,
    required this.onTap,
  });
}

class StatBox extends StatelessWidget {
  final Color bgColor;
  final String count;
  final String label;
  final String image;
  final void Function() onTap;

  const StatBox({
    required this.bgColor,
    required this.count,
    required this.label,
    required this.image,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: bgColor,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 12),
            child: Stack(
              children: [
                // Text/statistics
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count,
                        style: AppTypography.headingLarge(
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppTypography.inter(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.55,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                // Image in the bottom right corner
                Align(
                  alignment: Alignment.bottomRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.54,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 0.0, right: 0.0),
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
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
    );
  }
}

class StoresGrid extends StatefulWidget {
  const StoresGrid({Key? key}) : super(key: key);

  @override
  State<StoresGrid> createState() => StoresGridState();
}

class StoresGridState extends State<StoresGrid> {
  late Future<List<StoreModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchAllStores();
  }

  /// Call this to re-fetch stores from the API.
  Future<void> refresh() async {
    setState(() {
      _future = fetchAllStores();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoreModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 240);
        final stores = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stores.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 140 / 140,
          ),
          itemBuilder: (context, i) {
            final store = stores[i];
            return StoreCard(
              title: store.name,
              description: store.description ?? '',
              onTap: () {
                print(store.id.toString()); 
                Constant.session.setData(
                  SessionManager.keyStoreId,
                  store.stores.toString(),
                  false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodRegistrationScreen(
                      storeId: store.stores.toString(),
                    ),
                  ),
                );
              },
              imageUrl: store.VendorImgUrl,
            );
          },
        );
      },
    );
  }
}

class StoreCard extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final VoidCallback? onTap;

  const StoreCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    this.onTap,
    super.key,
  });

  @override
  State<StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.cardBackground,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface,
                colorScheme.surfaceVariant,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background gradient overlay for depth
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.cardBackground,
                        colorScheme.surfaceVariant,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and arrow
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 16, left: 16, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: AppTypography.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.textPrimary,
                                  letterSpacing: -0.55,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: colorScheme.iconSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 2),

                        // Description
                        Text(
                          widget.description,
                          style: AppTypography.caption(
                            color: colorScheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: colorScheme.cardShadow),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: colorScheme.surfaceVariant,
                              child: Center(
                                child: Icon(
                                  Icons.store,
                                  color: colorScheme.iconSecondary,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: colorScheme.surfaceVariant,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.iconSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Subtle shine effect on press
              if (_isPressed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surface.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shimmer loading widget for stat boxes
class _ShimmerStatBox extends StatefulWidget {
  final app_theme.AppColorScheme colorScheme;

  const _ShimmerStatBox({required this.colorScheme});

  @override
  _ShimmerStatBoxState createState() => _ShimmerStatBoxState();
}

class _ShimmerStatBoxState extends State<_ShimmerStatBox>
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            color: widget.colorScheme.surfaceVariant,
            padding: const EdgeInsets.only(left: 12, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Count shimmer
                Container(
                  height: 32,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        widget.colorScheme.surface,
                        widget.colorScheme.surfaceVariant,
                        widget.colorScheme.surface,
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
                // Label shimmer
                Container(
                  height: 16,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        widget.colorScheme.surface,
                        widget.colorScheme.surfaceVariant,
                        widget.colorScheme.surface,
                      ],
                      stops: [
                        _animation.value - 0.3,
                        _animation.value,
                        _animation.value + 0.3,
                      ].map((e) => e.clamp(0.0, 1.0)).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 16,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        widget.colorScheme.surface,
                        widget.colorScheme.surfaceVariant,
                        widget.colorScheme.surface,
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
        );
      },
    );
  }
}
