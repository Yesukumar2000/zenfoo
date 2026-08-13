import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/payout_sections_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/earnings/payout_section_detail_screen.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  static const String _apiUrl =
      '${AppUrl.baseUrl}/api/delivery-boy/performance/earnings-sections';

  String _selectedPeriod = 'weekly';
  int _offset = 0;
  PayoutSectionsData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPayoutSections();
  }

  Future<void> _fetchPayoutSections() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final url =
          '$_apiUrl?period=$_selectedPeriod&offset=$_offset';

      final response = await apiService.get(url, isToast: false);

      if (mounted) {
        setState((){
          _isLoading = false;
          if (response.status == 'success' && response.data != null) {
            final parsed = PayoutSectionsResponse.fromJson(
                response.data as Map<String, dynamic>);
            if (parsed.status == 1 && parsed.data != null) {
              _data = parsed.data;
              _errorMessage = null;
            } else {
              _errorMessage = parsed.message.isNotEmpty
                  ? parsed.message
                  : 'No data available';
            }
          } else {
            _errorMessage = 'Failed to load payout data';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching payout sections: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load payout data';
        });
      }
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _offset = 0;
    });
    _fetchPayoutSections();
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case 'daily':
        return "Today's Payout";
      case 'weekly':
        return 'This week Payout';
      case 'monthly':
        return 'This month Payout';
      default:
        return 'Payout';
    }
  }

  String _formatDateRange() {
    if (_data == null) return '';
    try {
      final start = DateTime.parse(_data!.startDate);
      final end = DateTime.parse(_data!.endDate);
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';
    } catch (e) {
      return '${_data!.startDate} - ${_data!.endDate}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          const AppHeader(
            label: '',
            title: 'Payout',
            showBackButton: true,
            showExitButton: false,
          ),

          /// CONTENT
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorState(colorScheme)
                    : _buildContent(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchPayoutSections,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppColorScheme colorScheme) {
    final sections = _data?.sections ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Payout Summary Card
          _buildPayoutSummaryCard(colorScheme),
          const SizedBox(height: 24),

          /// Section Rows
          ...sections.map((section) => _buildSectionRow(section, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildPayoutSummaryCard(AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        children: [
          // Period label
          Text(
            _getPeriodLabel(),
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),

          // Grand total amount
          Text(
            '₹${_data?.grandTotal.toInt() ?? 0}',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Date range with offset navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous period button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _offset--);
                  _fetchPayoutSections();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: colorScheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Date range dropdown
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showPeriodPicker(colorScheme);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDateRange(),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colorScheme.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Next period button (disabled at offset 0)
              GestureDetector(
                onTap: _offset < 0
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _offset++);
                        _fetchPayoutSections();
                      }
                    : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.border, width: 1),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _offset < 0
                        ? colorScheme.textPrimary
                        : colorScheme.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRow(PayoutSection section, AppColorScheme colorScheme) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PayoutSectionDetailScreen(
                  sectionKey: section.key,
                  sectionLabel: section.label,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section.label,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₹${section.total.toInt()}',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.border,
        ),
      ],
    );
  }

  void _showPeriodPicker(AppColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Period',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildPeriodOption('Daily', 'daily', colorScheme),
              _buildPeriodOption('Weekly', 'weekly', colorScheme),
              _buildPeriodOption('Monthly', 'monthly', colorScheme),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(
      String label, String value, AppColorScheme colorScheme) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        _changePeriod(value);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? colorScheme.primary : colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
