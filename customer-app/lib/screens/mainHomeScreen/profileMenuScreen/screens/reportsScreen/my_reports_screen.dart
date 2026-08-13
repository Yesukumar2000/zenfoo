import 'package:project/helper/styles/appColorScheme.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/reportsProvider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';
import 'package:project/models/report.dart';
import 'package:project/screens/mainHomeScreen/profileMenuScreen/screens/reportsScreen/report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.delayed(Duration.zero, () {
      context.read<ReportsProvider>().fetchReports(
            context: context,
            isReset: true,
          );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<ReportsProvider>();
      if (provider.state != ReportsState.loadingMore && provider.hasMoreData) {
        provider.fetchReports(context: context, isReset: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: AppHeader(
                label: getTranslatedValue(context, 'support'),
                title: getTranslatedValue(context, 'my_reports'),
                showBackButton: true,
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () async {
            await context.read<ReportsProvider>().fetchReports(
                  context: context,
                  isReset: true,
                );
          },
          color: colorScheme.primary,
          backgroundColor: colorScheme.cardBackground,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Consumer<ReportsProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Tabs - Always visible
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final types = [
                      ReportFilterType.all,
                      ReportFilterType.pending,
                      ReportFilterType.resolved,
                    ];
                    final labelKeys = [
                      'all_reports',
                      'pending_status',
                      'resolved_status',
                    ];
                    final labels = labelKeys
                        .map((key) => getTranslatedValue(context, key))
                        .toList();
                    final type = types[index];
                    final label = labels[index];
                    final isSelected = provider.filterType == type;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context
                            .read<ReportsProvider>()
                            .setFilterType(type, context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: colorScheme.border,
                                  width: 1,
                                ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (type == ReportFilterType.pending)
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.buttonPrimaryText
                                        : colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (type == ReportFilterType.resolved)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: isSelected
                                        ? colorScheme.buttonPrimaryText
                                        : colorScheme.success,
                                  ),
                                ),
                              Text(
                                label,
                                style: GoogleFonts.inter(
                                  color: isSelected
                                      ? colorScheme.buttonPrimaryText
                                      : colorScheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  height: 1.2,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Content based on state
              if (provider.state == ReportsState.loading)
                ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ShimmerReportCard(),
                )
              else if (provider.state == ReportsState.error)
                _buildErrorState(provider.message)
              else if (provider.state == ReportsState.empty)
                _buildEmptyState()
              else
                Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.filteredReports.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final report = provider.filteredReports[index];
                        return _ReportCard(
                          report: report,
                          colorScheme: colorScheme,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailScreen(
                                  report: report,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (provider.state == ReportsState.loadingMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.report_outlined,
                size: 56,
                color: colorScheme.iconSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTranslatedValue(context, 'no_reports_found'),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getTranslatedValue(context, 'submitted_reports_will_appear_here'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
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
              getTranslatedValue(context, 'unable_to_load_reports'),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message.isEmpty
                  ? getTranslatedValue(
                      context, 'something_went_wrong_try_again')
                  : message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();

                context.read<ReportsProvider>().fetchReports(
                      context: context,
                      isReset: true,
                    );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: colorScheme.buttonPrimaryText,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      getTranslatedValue(context, 'try_again'),
                      style: GoogleFonts.inter(
                        color: colorScheme.buttonPrimaryText,
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
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final AppColorScheme colorScheme;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.colorScheme,
    required this.onTap,
  });

  String _getReportTypeDisplay(BuildContext context) {
    final type = report.reportType?.toLowerCase() ?? '';
    switch (type) {
      case 'wrong':
        return getTranslatedValue(context, 'wrong_item');
      case 'missing':
        return getTranslatedValue(context, 'missing_item');
      case 'return':
        return getTranslatedValue(context, 'return_item');
      case 'misbehavior':
        return getTranslatedValue(context, 'misbehavior');
      case 'complaint':
        return getTranslatedValue(context, 'complaint');
      case 'others':
        return getTranslatedValue(context, 'other_report_type');
      default:
        return report.reportType ?? 'Unknown';
    }
  }

  int _getTotalItemsCount() {
    int count = 0;
    if (report.storeWiseItems != null) {
      count += report.storeWiseItems!.length;
    }
    if (report.comboItems != null) {
      count += report.comboItems!.length;
    }
    return count;
  }

  int _getTotalImagesCount() {
    int count = 0;

    if (report.images != null && report.images!.isNotEmpty) {
      count += report.images!.length;
    }

    if (report.storeWiseItems != null) {
      for (var item in report.storeWiseItems!) {
        if (item.imageUrls != null) {
          count += item.imageUrls!.length;
        }
      }
    }

    if (report.comboItems != null) {
      for (var item in report.comboItems!) {
        if (item.imageUrls != null) {
          count += item.imageUrls!.length;
        }
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPending = report.status == '0';
    final totalItems = _getTotalItemsCount();
    final totalImages = _getTotalImagesCount();

    return GestureDetector(
      onTap: onTap,
      child: GradientBorderCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 18,
        gradient: colorScheme.cardGradient,
        borderGradient: colorScheme.borderGradient,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row - Order ID and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${report.orderNumber ?? report.orderId ?? "N/A"}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.textPrimary,
                    height: 1.2,
                    letterSpacing: -0.55,
                  ),
                ),
                Text(
                  report.reportedOn ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                    height: 1.2,
                    letterSpacing: -0.55,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Divider
            Container(
              height: 1,
              color: colorScheme.border,
            ),

            const SizedBox(height: 14),

            // Report Type and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Report Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslatedValue(context, 'report_type'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textSecondary,
                          height: 1.2,
                          letterSpacing: -0.55,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: (){
                          print('=++++++++++++++');
                          print(report.reportType);
                        },
                        child: Text(
                          _getReportTypeDisplay(context),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textPrimary,
                            height: 1.3,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? colorScheme.error.withValues(alpha: 0.1)
                        : colorScheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isPending ? colorScheme.error : colorScheme.success,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isPending
                              ? colorScheme.error
                              : colorScheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        report.statusName ??
                            (isPending ? 'Pending' : 'Resolved'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isPending
                              ? colorScheme.error
                              : colorScheme.success,
                          height: 1.2,
                          letterSpacing: -0.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Description
            if (report.description != null && report.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTranslatedValue(context, 'description'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                      height: 1.2,
                      letterSpacing: -0.55,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.storeWiseItems?.isNotEmpty == true
                        ? report.storeWiseItems!.first.description ?? ''
                        : (report.comboItems?.isNotEmpty == true
                            ? report.comboItems!.first.description ?? ''
                            : ''),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                      height: 1.4,
                      letterSpacing: -0.55,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                ],
              ),

            // Additional Info Row
            Row(
              children: [
                // Items count
                if (totalItems > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 14,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalItems item${totalItems > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Images Indicator
                if (totalImages > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalImages image${totalImages > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                            height: 1.2,
                            letterSpacing: -0.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Refund Requested Indicator
                if (report.isRefundRequested == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getTranslatedValue(context, 'refund'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.success,
                            height: 1.2,
                            letterSpacing: -0.55,
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
    );
  }
}

class _ShimmerReportCard extends StatefulWidget {
  const _ShimmerReportCard({Key? key}) : super(key: key);

  @override
  State<_ShimmerReportCard> createState() => _ShimmerReportCardState();
}

class _ShimmerReportCardState extends State<_ShimmerReportCard>
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
        return GradientBorderCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 18,
          gradient: colorScheme.cardGradient,
          borderGradient: colorScheme.borderGradient,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer - Order ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(130, 16, colorScheme),
                  _buildShimmerBox(100, 13, colorScheme),
                ],
              ),
              const SizedBox(height: 14),

              // Divider
              Container(
                height: 1,
                color: colorScheme.border.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 14),

              // Report Type and Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Report Type shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(80, 12, colorScheme),
                        const SizedBox(height: 6),
                        _buildShimmerBox(140, 14, colorScheme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status badge shimmer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildShimmerCircle(7, colorScheme),
                        const SizedBox(width: 7),
                        _buildShimmerBox(60, 13, colorScheme),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description shimmer
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(90, 12, colorScheme),
                  const SizedBox(height: 6),
                  _buildShimmerBox(double.infinity, 14, colorScheme),
                  const SizedBox(height: 4),
                  _buildShimmerBox(220, 14, colorScheme),
                ],
              ),
              const SizedBox(height: 14),

              // Image badge shimmer
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShimmerBox(16, 16, colorScheme),
                    const SizedBox(width: 8),
                    _buildShimmerBox(100, 12, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox(
      double width, double height, AppColorScheme colorScheme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.surfaceVariant,
            colorScheme.surfaceVariant.withValues(alpha: 0.5),
            colorScheme.surfaceVariant,
          ],
          stops: [
            _animation.value - 1,
            _animation.value,
            _animation.value + 1,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }

  Widget _buildShimmerCircle(double size, AppColorScheme colorScheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            colorScheme.surfaceVariant,
            colorScheme.surfaceVariant.withValues(alpha: 0.5),
            colorScheme.surfaceVariant,
          ],
          stops: [
            _animation.value - 1,
            _animation.value,
            _animation.value + 1,
          ].map((e) => e.clamp(0.0, 1.0)).toList(),
        ),
      ),
    );
  }
}
