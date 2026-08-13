import 'package:flutter/material.dart';
import 'package:zenfoo_partner/utils/order_number.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/tips_model.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/tips_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class CustomerTipsScreen extends StatefulWidget {
  const CustomerTipsScreen({super.key});

  @override
  State<CustomerTipsScreen> createState() => _CustomerTipsScreenState();
}

class _CustomerTipsScreenState extends State<CustomerTipsScreen> {
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTipsData();
    });
  }

  void _loadTipsData() {
    final provider = context.read<TipsProvider>();
    provider.getWeeklyTips(offset: _currentOffset);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final tipsProvider = context.watch<TipsProvider>();
    final tipsData = tipsProvider.currentTips;
    final isLoading = tipsProvider.tipsState.status == ApiStatus.loading;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('wallet'),
            title: languageProvider.getTranslatedText('customer_tips'),
            showBackButton: true,
          ),

          // CONTENT
          Expanded(
            child: Column(
              children: [
                // Week Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.border,
                      width: 1,
                    ),
                  ),
                  child: tipsData == null
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Previous Week Button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _currentOffset--;
                                    });
                                    _loadTipsData();
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceElevated,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.chevron_left,
                                        size: 18,
                                        color: colorScheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Amount and Label
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getWeekLabel(
                                          tipsData.weekSummary.weekStart),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        height: 1.71,
                                        letterSpacing: -0.05,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '₹${tipsData.weekSummary.totalTips.toStringAsFixed(0)}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                        letterSpacing: -0.05,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Next Week Button
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _currentOffset++;
                                    });
                                    _loadTipsData();
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceElevated,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                        color: colorScheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: colorScheme.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tipsData.weekSummary.weekRange,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                // Tips List
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      : tipsData == null || tipsData.tipsList.isEmpty
                          ? Center(
                              child: Text(
                                'No tips found',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: tipsData.tipsList.length,
                              itemBuilder: (context, index) {
                                return _buildTipItem(
                                  tipsData.tipsList[index],
                                  colorScheme,
                                );
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

  String _getWeekLabel(String weekStartStr) {
    try {
      final weekStart = DateTime.parse(weekStartStr);
      final now = DateTime.now();
      final weekStartDate =
          DateTime(weekStart.year, weekStart.month, weekStart.day);
      final currentWeekStart =
          now.subtract(Duration(days: now.weekday - 1));
      final currentWeekStartDate = DateTime(
          currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

      final difference =
          weekStartDate.difference(currentWeekStartDate).inDays ~/ 7;

      if (difference == 0) {
        return 'This week';
      } else if (difference == -1) {
        return 'Last week';
      } else if (difference == 1) {
        return 'Next week';
      } else if (difference < -1) {
        return '${difference.abs()} weeks ago';
      } else {
        return 'In $difference weeks';
      }
    } catch (e) {
      return 'Week';
    }
  }

  Widget _buildTipItem(TipItem tip, AppColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        _showTipDetails(tip, colorScheme);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ${formatOrderNumber(tip.orderId)}',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                      letterSpacing: -0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tip.orderDate} • ${tip.orderTime}',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.02,
                      letterSpacing: -0.05,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '+ ₹${tip.tipAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                      letterSpacing: -0.05,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showTipDetails(TipItem tip, AppColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tip Details',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tip Amount Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(0x1f),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withAlpha(0x4d),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tip Amount',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₹${tip.tipAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow('Order ID', formatOrderNumber(tip.orderId), colorScheme),
                  const SizedBox(height: 16),
                  _buildDetailRow('Order Date', tip.orderDate, colorScheme),
                  const SizedBox(height: 16),
                  _buildDetailRow('Order Time', tip.orderTime, colorScheme),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'Delivery Time', tip.deliveryTime, colorScheme),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'Payment Method', tip.paymentMethod, colorScheme),
                  const SizedBox(height: 16),
                  _buildDetailRow('Delivery Distance',
                      '${tip.deliveryDistanceKm.toStringAsFixed(1)} km', colorScheme),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'Restaurant', tip.restaurantName, colorScheme),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'Delivery Address', tip.deliveryAddress, colorScheme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      String label, String value, AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
