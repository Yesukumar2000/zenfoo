import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;

  const TripDetailsScreen({
    super.key,
    required this.tripData,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final ordersId = widget.tripData['ordersId'] ?? '';

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER with Order ID
          AppHeader(
            label: 'Trip Details',
            title: 'ID : #$ordersId',
            showBackButton: true,
            showExitButton: false,
          ),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  /// Trip Type Badge + Date
                  _buildTripHeader(colorScheme),

                  /// Trip Details Card
                  _buildTripDetailsCard(colorScheme),

                  /// Earnings Details Card
                  _buildEarningsDetailsCard(colorScheme),

                  /// Deduction Details Card
                  _buildDeductionDetailsCard(colorScheme),

                  /// Cash Handling Card
                  _buildCashHandlingCard(colorScheme),

                  /// Additional Info Card
                  _buildAdditionalInfoCard(colorScheme),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHeader(AppColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Trip type badge - solid dark pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.textPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.tripData['tripType'] ?? 'Trip',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ),
        // Date
        Text(
          widget.tripData['date'] ?? '',
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.33,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailsCard(AppColorScheme colorScheme) {
    final stops =
        widget.tripData['stops'] as List<Map<String, String>>? ?? [];
    final distance = widget.tripData['distance'] ?? '0 kms';
    final duration = widget.tripData['duration'] ?? '0 Mins';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Trip Details',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Distance + Duration row
          Row(
            children: [
              Row(
                spacing: 4,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMapsLocation01,
                    color: colorScheme.textSecondary,
                    size: 16,
                  ),
                  Text(
                    'Distance covered  $distance',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                spacing: 4,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedClock01,
                    color: colorScheme.textSecondary,
                    size: 16,
                  ),
                  Text(
                    duration,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Stops timeline
          _buildStopsTimeline(stops, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStopsTimeline(
      List<Map<String, String>> stops, AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        stops.length,
        (index) {
          final isLast = index == stops.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Numbered circle or small dot + connecting line
              Column(
                children: [
                  // Numbered dark circle or home icon for last stop
                  if (isLast)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/home.png',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colorScheme.textPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.surface,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: colorScheme.border,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              // Middle: Address
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    stops[index]['address'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Right: Time
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  stops[index]['time'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEarningsDetailsCard(AppColorScheme colorScheme) {
    final baseEarning = widget.tripData['baseEarning'] ?? '₹0';
    final multiOrderBonus = widget.tripData['multiOrderBonus'] ?? '₹0';
    final customerTip = widget.tripData['customerTip'] ?? '₹0';
    final gigBonus = widget.tripData['gigBonus'] ?? '₹0';
    final totalTripEarning = widget.tripData['totalTripEarning'] ??
        widget.tripData['earnings'] ??
        '₹0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            'Earnings Details',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: -0.3,
            ),
          ),
          Column(
            spacing: 12,
            children: [
              _buildDetailRow('Base Earning', baseEarning, colorScheme),
              _buildDetailRow('Multi- order', '+ $multiOrderBonus', colorScheme),
              _buildDetailRow('Customer Tip', '+ $customerTip', colorScheme),
              _buildDetailRow('Gig Bonus', '+ $gigBonus', colorScheme),
            ],
          ),
          Container(
            height: 1,
            color: colorScheme.border,
          ),
          _buildDetailRow(
            'Total trip Earning',
            totalTripEarning,
            colorScheme,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionDetailsCard(AppColorScheme colorScheme) {
    final lateFee = widget.tripData['lateFee'] ?? '₹0';
    final orderRelatedDeductions =
        widget.tripData['orderRelatedDeductions'] ?? '₹0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            'Dedication Details',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: -0.3,
            ),
          ),
          Column(
            spacing: 12,
            children: [
              _buildDetailRow('Late Fee', '-$lateFee', colorScheme),
              _buildDetailRow(
                  'Order-related Deductions', '-$orderRelatedDeductions', colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashHandlingCard(AppColorScheme colorScheme) {
    final cashCollected = widget.tripData['cashCollectedDetail'] ??
        widget.tripData['cashCollected'] ??
        '₹0';
    final cashBalance = widget.tripData['cashBalance'] ?? '₹0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            'Cash Handling',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: -0.3,
            ),
          ),
          _buildDetailRow('Cash collected', '+ $cashCollected', colorScheme),
          _buildDetailRow(
            'Floating cash Balance',
            cashBalance,
            colorScheme,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(AppColorScheme colorScheme) {
    final customerRating = widget.tripData['customerRating'] ?? 0.0;
    final customerReview = widget.tripData['customerReview'] ?? '';
    final ratingValue = customerRating is double
        ? customerRating
        : double.tryParse(customerRating.toString()) ?? 0.0;

    if (ratingValue <= 0 && customerReview.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            'Additional Info',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: -0.3,
            ),
          ),
          if (ratingValue > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Rating',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.02,
                    letterSpacing: -0.35,
                  ),
                ),
                Row(
                  spacing: 4,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFC107),
                      size: 18,
                    ),
                    Text(
                      ratingValue.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.02,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (customerReview.isNotEmpty)
            Text(
              customerReview,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
                letterSpacing: -0.2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    AppColorScheme colorScheme, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isBold ? colorScheme.textPrimary : colorScheme.textSecondary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            height: 1.02,
            letterSpacing: -0.35,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            height: 1.02,
            letterSpacing: 0.35,
          ),
        ),
      ],
    );
  }
}
