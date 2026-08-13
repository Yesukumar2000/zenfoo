import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/order_earnings_model.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/order_earnings_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/ist_time.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/earnings/multi_order_detail_screen.dart';

class OrderEarningsScreen extends StatefulWidget {
  const OrderEarningsScreen({super.key});

  @override
  State<OrderEarningsScreen> createState() => _OrderEarningsScreenState();
}

class _OrderEarningsScreenState extends State<OrderEarningsScreen> {
  int _offset = 0;
  int _selectedFilterIndex = 0; // 0=Today, 1=Weekly, 2=Monthly
  int _selectedTabIndex = 0; // 0=Delivered, 1=Rejected
  final List<String> _filters = ['Today', 'Weekly', 'Monthly'];
  final List<String> _periods = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<OrderEarningsProvider>();
    provider.getOrderEarnings(
      period: _periods[_selectedFilterIndex],
      offset: _offset,
      isCancelled: _selectedTabIndex == 1 ? 1 : 0,
    );
  }

  void _onFilterChanged(int index) {
    setState(() {
      _selectedFilterIndex = index;
      _offset = 0;
    });
    _loadData();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _loadData();
  }

  String _formatOrderDate(String dateStr) {
    return formatIst(dateStr, 'dd/MM/yyyy,hh:mma');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final provider = context.watch<OrderEarningsProvider>();
    final data = provider.currentOrderEarnings;
    final isLoading = provider.orderEarningsState.status == ApiStatus.loading;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('earnings'),
            title: languageProvider.getTranslatedText('total_orders'),
            showBackButton: true,
          ),
          Expanded(
            child: Column(
              children: [
                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildFilterTabs(colorScheme),
                ),
                const SizedBox(height: 16),
                // Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSummaryCard(colorScheme, data),
                ),
                const SizedBox(height: 16),
                // Delivered / Rejected Tab Bar
                _buildTabBar(colorScheme),
                const SizedBox(height: 4),
                // Orders List
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.primary))
                      : data == null || data.data.orders.isEmpty
                          ? Center(
                              child: Text(
                                languageProvider
                                    .getTranslatedText('no_orders'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: data.data.orders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(
                                    data.data.orders[index], colorScheme);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(AppColorScheme colorScheme) {
    return Row(
      children: List.generate(_filters.length, (index) {
        final isSelected = _selectedFilterIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _onFilterChanged(index);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.textPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.textPrimary
                      : colorScheme.border,
                  width: 1,
                ),
              ),
              child: Text(
                _filters[index],
                style: GoogleFonts.inter(
                  color: isSelected
                      ? colorScheme.surface
                      : colorScheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(
      AppColorScheme colorScheme, OrderEarningsResponse? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Total Orders',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data != null
                ? '${data.data.summary.totalOrders}'
                : '0',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          _buildTab('Delivered', 0, colorScheme),
          _buildTab('Rejected', 1, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, AppColorScheme colorScheme) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          _onTabChanged(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isSelected
                  ? colorScheme.textPrimary
                  : colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
      OrderEarningItem order, AppColorScheme colorScheme) {
    final isRejected = _selectedTabIndex == 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isRejected
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MultiOrderDetailScreen(orderId: order.orderId),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Single/Multi order badge + seller badges
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Text(
                    order.isMultiOrder ? 'Multi order' : 'Single order',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                ...order.storeSellers.map((seller) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$seller',
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Order number + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatOrderDate(order.orderDate),
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Store name
            if (order.storeNames.isNotEmpty)
              Text(
                order.storeNames.join(', '),
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 10),

            // Row 4: Status badge + amount + arrow
            Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? colorScheme.error
                        : colorScheme.success,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isRejected ? 'Rejected' : 'Delivered',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // Amount
                Text(
                  '₹${order.driverEarnings.toInt()}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                // Arrow icon
                Icon(
                  Icons.arrow_circle_right_outlined,
                  size: 18,
                  color: colorScheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
