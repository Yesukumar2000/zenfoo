import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/helper/widgets/order_details_card.dart';
import 'package:project/models/order_detail_item.dart';
import 'package:project/models/order_earnings.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/repositories/sellerEarningsApi.dart';
import 'package:project/models/new_order.dart' show SettlementItem;

class OrderEarningsScreen extends StatefulWidget {
  final String title;
  final String totalAmount;
  final Color accentColor;
  final String? filterType;

  const OrderEarningsScreen({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.accentColor,
    this.filterType,
  });

  @override
  State<OrderEarningsScreen> createState() => _OrderEarningsScreenState();
}

class _OrderEarningsScreenState extends State<OrderEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<OrderEarnings> todayData = [];
  List<OrderEarnings> weeklyData = [];
  List<OrderEarnings> monthlyData = [];
  List<OrderEarnings> yearlyData = [];
  List<OrderEarnings> totalData = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getActiveTabTotal() {
    final data = [todayData, weeklyData, monthlyData, yearlyData, totalData];
    final activeData = data[_tabController.index];
    final total = activeData.fold<num>(0, (sum, e) => sum + e.totalAmount);
    return '₹${total.toStringAsFixed(2)}';
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? apiStatus = _getApiStatusParameter();

      final response = await getSellerEarnings(
        context: context,
        status: apiStatus,
      );

      if (response != null && response.data != null) {
        final filteredToday = apiStatus == null
            ? _filterByStatus(response.data!.today ?? [])
            : response.data!.today ?? [];
        final filteredWeekly = apiStatus == null
            ? _filterByStatus(response.data!.weekly ?? [])
            : response.data!.weekly ?? [];
        final filteredMonthly = apiStatus == null
            ? _filterByStatus(response.data!.monthly ?? [])
            : response.data!.monthly ?? [];
        final filteredYearly = apiStatus == null
            ? _filterByStatus(response.data!.yearly ?? [])
            : response.data!.yearly ?? [];
        final filteredTotal = apiStatus == null
            ? _filterByStatus(response.data!.total ?? [])
            : response.data!.total ?? [];

        setState(() {
          todayData = filteredToday;
          weeklyData = filteredWeekly;
          monthlyData = filteredMonthly;
          yearlyData = filteredYearly;
          totalData = filteredTotal;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String? _getApiStatusParameter() {
    if (widget.filterType == null ||
        widget.filterType == 'earnings' ||
        widget.filterType == 'orders') {
      return null;
    }

    return widget.filterType;
  }

  List<OrderEarnings> _filterByStatus(List<OrderEarnings> data) {
    if (widget.filterType == null || widget.filterType == 'earnings') {
      return data;
    }

    String targetStatus;
    switch (widget.filterType) {
      case 'completed':
        targetStatus = 'delivered';
        break;
      case 'cancelled':
        targetStatus = 'cancelled';
        break;
      case 'returned':
        targetStatus = 'returned';
        break;
      case 'orders':
        return data;
      default:
        return data;
    }

    return data.map((earning) {
      final filteredTransactions = earning.transactions.where((transaction) {
        return transaction.orderDetails?.status.toLowerCase() == targetStatus;
      }).toList();

      final newTotalAmount = filteredTransactions.fold<num>(
        0,
        (sum, transaction) => sum + transaction.amount,
      );

      return OrderEarnings(
        dateRange: earning.dateRange,
        totalAmount: newTotalAmount,
        transactions: filteredTransactions,
        isExpanded: false,
      );
    }).where((earning) {
      return earning.transactions.isNotEmpty;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return Column(
            children: [
              AppHeader(
                label: getTranslatedValue(context, allEarningsLabel),
                title: getTranslatedValue(context, earningsLabel),
                showBackButton: true,
              ),
              _buildTotalAmountCard(colorScheme),
              _buildTabBar(colorScheme),
              Expanded(
                child: isLoading
                    ? ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: 5,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ShimmerEarningsCard(
                          colorScheme: colorScheme,
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEarningsList(todayData, colorScheme),
                          _buildEarningsList(weeklyData, colorScheme),
                          _buildEarningsList(monthlyData, colorScheme),
                          _buildEarningsList(yearlyData, colorScheme),
                          _buildEarningsList(totalData, colorScheme),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalAmountCard(app_theme.AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.textSecondary,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getActiveTabTotal(),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: widget.accentColor,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(app_theme.AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          boxShadow: colorScheme.cardShadow,
        ),
        indicatorPadding: const EdgeInsets.all(4),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colorScheme.textPrimary,
        unselectedLabelColor: colorScheme.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: getTranslatedValue(context, todayLabel)),
          Tab(text: getTranslatedValue(context, weeklyLabel)),
          Tab(text: getTranslatedValue(context, monthlyLabel)),
          Tab(text: getTranslatedValue(context, yearlyLabel)),
          Tab(text: getTranslatedValue(context, totalLabel)),
        ],
      ),
    );
  }

  Widget _buildEarningsList(
      List<OrderEarnings> data, app_theme.AppColorScheme colorScheme) {
    if (data.isEmpty) {
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
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: colorScheme.iconSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                getTranslatedValue(context, noEarningsDataLabel),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                getTranslatedValue(context, noEarningsDataMessageLabel),
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildEarningsItem(data[index], index, colorScheme);
      },
    );
  }

  Widget _buildEarningsItem(
      OrderEarnings item, int index, app_theme.AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  item.isExpanded = !item.isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: widget.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.dateRange,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.textPrimary,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.transactions.length} ${item.transactions.length == 1 ? getTranslatedValue(context, transactionLabel) : getTranslatedValue(context, transactionsLabel)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.formattedAmount,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: widget.accentColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: item.isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.iconSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.border,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: item.transactions.map((transaction) {
                  return _buildTransactionItem(transaction, colorScheme);
                }).toList(),
              ),
            ),
            crossFadeState: item.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  void showOrderDetailsBottomSheet(
      BuildContext context, OrderDetailItem orderDetail,
      {List<dynamic>? settlementInfo}) {
    final colorScheme = context.read<app_theme.ThemeProvider>().colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        getTranslatedValue(context, orderDetailsLabelKey),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            color: colorScheme.iconSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.border),
              OrderDetailsCard(
                orderDetail: orderDetail,
                settlementInfo: settlementInfo?.cast<SettlementItem>(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(
      EarningsTransaction transaction, app_theme.AppColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (transaction.orderDetails != null) {
            showOrderDetailsBottomSheet(context, transaction.orderDetails!,
                settlementInfo: transaction.settlementInfo);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.border,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: colorScheme.iconSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.formattedId,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textPrimary,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.date,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                transaction.formattedAmount,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.iconSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerEarningsCard extends StatefulWidget {
  final app_theme.AppColorScheme colorScheme;

  const _ShimmerEarningsCard({
    Key? key,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<_ShimmerEarningsCard> createState() => _ShimmerEarningsCardState();
}

class _ShimmerEarningsCardState extends State<_ShimmerEarningsCard>
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
          decoration: BoxDecoration(
            color: widget.colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.colorScheme.border, width: 1),
            boxShadow: widget.colorScheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
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
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
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
                const SizedBox(width: 12),
                Container(
                  width: 80,
                  height: 32,
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
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }
}
