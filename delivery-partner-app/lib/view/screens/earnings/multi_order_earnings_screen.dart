import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/multi_order_earnings_model.dart';
import 'package:zenfoo_partner/providers/multi_order_earnings_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/ist_time.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/earnings/multi_order_detail_screen.dart';

class MultiOrderEarningsScreen extends StatefulWidget {
  const MultiOrderEarningsScreen({super.key});

  @override
  State<MultiOrderEarningsScreen> createState() =>
      _MultiOrderEarningsScreenState();
}

class _MultiOrderEarningsScreenState extends State<MultiOrderEarningsScreen> {
  int _offset = 0;
  int _selectedFilterIndex = 1; // 0=Today, 1=Weekly, 2=Monthly
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
    final provider = context.read<MultiOrderEarningsProvider>();
    provider.getMultiOrderEarnings(
      period: _periods[_selectedFilterIndex],
      offset: _offset,
    );
  }

  void _onFilterChanged(int index) {
    setState(() {
      _selectedFilterIndex = index;
      _offset = 0;
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
    final multiOrderProvider = context.watch<MultiOrderEarningsProvider>();
    final multiOrderData = multiOrderProvider.currentMultiOrderEarnings;
    final isLoading =
        multiOrderProvider.multiOrderEarningsState.status == ApiStatus.loading;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('wallet'),
            title: 'Multi orders',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Summary Card
                  _buildSummaryCard(colorScheme, multiOrderData),
                  const SizedBox(height: 20),
                  // Filter Tabs
                  _buildFilterTabs(colorScheme),
                  const SizedBox(height: 12),
                  // Period Navigation
                  _buildPeriodNavigation(colorScheme, multiOrderData),
                  const SizedBox(height: 16),
                  // Orders List
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  else if (multiOrderData == null ||
                      multiOrderData.orders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        languageProvider.getTranslatedText('no_orders'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    ...multiOrderData.orders.map(
                      (order) => _buildOrderCard(order, colorScheme),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      AppColorScheme colorScheme, MultiOrderEarningsResponse? data) {
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
            'Total Multi - Orders',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data != null
                ? '${data.summary.totalMultiOrderBonus}'
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

  Widget _buildPeriodNavigation(
      AppColorScheme colorScheme, MultiOrderEarningsResponse? data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _offset--);
            _loadData();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.border),
            ),
            child: Icon(Icons.chevron_left,
                size: 18, color: colorScheme.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        // Period label
        Text(
          data?.periodName ?? '...',
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        // Next (disabled if offset >= 0)
        GestureDetector(
          onTap: _offset < 0
              ? () {
                  HapticFeedback.lightImpact();
                  setState(() => _offset++);
                  _loadData();
                }
              : null,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _offset < 0
                    ? colorScheme.border
                    : colorScheme.border.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(Icons.chevron_right,
                size: 18,
                color: _offset < 0
                    ? colorScheme.textSecondary
                    : colorScheme.textSecondary.withValues(alpha: 0.4)),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(MultiOrderItem order, AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiOrderDetailScreen(orderId: order.orderId),
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
          // Row 1: Multi order badge + store_sellers numbered badges
          Row(
            children: [
              // "Multi order" badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Multi order',
                  style: GoogleFonts.inter(
                    color: colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              // Store seller numbered badges
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
                '#${order.orderNumber ?? order.orderId}',
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
          const SizedBox(height: 10),

          // Row 3: Store name(s)
          if (order.storeNames.isNotEmpty)
            Text(
              order.storeNames.join(', '),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 8),

          // Row 4: "Order earning" + amount with info icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order earning',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${order.bonusAmount}',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
