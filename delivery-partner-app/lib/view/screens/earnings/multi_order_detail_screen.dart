import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/multi_order_detail_model.dart';
import 'package:zenfoo_partner/providers/multi_order_detail_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/ist_time.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/delivery/chat_with_admin_screen.dart';

class MultiOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const MultiOrderDetailScreen({super.key, required this.orderId});

  @override
  State<MultiOrderDetailScreen> createState() => _MultiOrderDetailScreenState();
}

class _MultiOrderDetailScreenState extends State<MultiOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<MultiOrderDetailProvider>()
          .getMultiOrderDetail(orderId: widget.orderId);
    });
  }

  String _formatDate(String dateStr) {
    return formatIst(dateStr, 'dd/MM/yyyy,hh:mma');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final provider = context.watch<MultiOrderDetailProvider>();
    final detail = provider.currentDetail;
    final isLoading = provider.detailState.status == ApiStatus.loading;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: '',
            title: '#${widget.orderId}',
            showBackButton: true,
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: colorScheme.primary))
                : detail == null
                    ? Center(
                        child: Text('No data found',
                            style: GoogleFonts.inter(
                                color: colorScheme.textSecondary)))
                    : SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Top summary card
                            _buildTopCard(colorScheme, detail),
                            const SizedBox(height: 24),
                            // Route legs
                            ...detail.route.legs.map(
                              (leg) => _buildRouteLeg(colorScheme, leg),
                            ),
                            const SizedBox(height: 8),
                            // Divider
                            Divider(color: colorScheme.border, height: 1),
                            const SizedBox(height: 20),
                            // Earnings breakdown
                            _buildEarningsSection(colorScheme, detail),
                            const SizedBox(height: 20),
                            // Floating cash section
                            _buildFloatingCashSection(colorScheme, detail),
                            const SizedBox(height: 24),
                            // Support row
                            _buildSupportRow(colorScheme),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(
      AppColorScheme colorScheme, MultiOrderDetailResponse detail) {
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
          // Amount - total driver earnings
          Text(
            '₹${detail.earnings.driverEarnings.toInt()}',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          // Time | Distance
          Text(
            '${detail.totalTime} | ${detail.totalDistanceKm} Kms',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          // Delivered badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    size: 15, color: colorScheme.success),
                const SizedBox(width: 5),
                Text(
                  'Delivered',
                  style: GoogleFonts.inter(
                    color: colorScheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteLeg(
      AppColorScheme colorScheme, MultiOrderRouteLeg leg) {
    final name = leg.storeName ?? leg.customerName ?? 'Store';
    final dateStr = leg.driverArrivedAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${leg.distanceFromPreviousKm} Km | ${leg.timeTaken}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (dateStr != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _formatDate(dateStr),
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection(
      AppColorScheme colorScheme, MultiOrderDetailResponse detail) {
    final earnings = detail.earnings;
    return Column(
      children: [
        _buildEarningsRow(
            'Order pay', '₹${earnings.deliveryCharge.toInt()}', colorScheme),
        const SizedBox(height: 14),
        _buildEarningsRow(
            'Multi-order pay', '₹${earnings.multiOrderBonus.toInt()}', colorScheme),
        const SizedBox(height: 14),
        _buildEarningsRow(
            'Customer tip', '₹${earnings.deliveryTip.toInt()}', colorScheme),
        const SizedBox(height: 14),
        _buildEarningsRow(
            'Return charge', '₹${earnings.returnCharge.toInt()}', colorScheme),
        if (earnings.vendorWaitCharge > 0) ...[
          const SizedBox(height: 14),
          _buildEarningsRow(
              'Waiting charge bonus',
              '₹${earnings.vendorWaitCharge.toStringAsFixed(2)}',
              colorScheme),
        ],
      ],
    );
  }

  Widget _buildEarningsRow(
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
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCashSection(
      AppColorScheme colorScheme, MultiOrderDetailResponse detail) {
    final earnings = detail.earnings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: colorScheme.border, height: 1),
        const SizedBox(height: 16),
        _buildEarningsRow(
            'Floating cash', '₹${earnings.adminCash.toInt()}', colorScheme),
        const SizedBox(height: 6),
        Text(
          'Deposited in floating cash',
          style: GoogleFonts.inter(
            color: colorScheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        _buildEarningsRow('Collected from  the customer',
            '₹${earnings.totalOrderValue.toInt()}', colorScheme),
      ],
    );
  }

  Widget _buildSupportRow(AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'I need Support ?',
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatWithAdminScreen(orderId: widget.orderId),
              ),
            );
          },
          child: Text(
            'Contact us',
            style: GoogleFonts.inter(
              color: colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
