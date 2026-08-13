import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/ist_time.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/repository/trip_history_repository.dart';
import 'trip_details_screen.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  String _selectedFilter = 'Daily';
  final List<String> _filters = ['Daily', 'Weekly', 'Monthly'];
  late DateTime _startDate;
  late DateTime _endDate;
  final TripHistoryRepository _repository = TripHistoryRepository();
  TripHistoryData? _tripHistoryData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
    _fetchTripHistory();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    _endDate = now;

    switch (_selectedFilter) {
      case 'Daily':
        _startDate = now;
        break;
      case 'Weekly':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Monthly':
        _startDate = DateTime(now.year, now.month, 1);
        break;
    }
  }

  void _setPreviousPeriod() {
    setState(() {
      switch (_selectedFilter) {
        case 'Daily':
          _endDate = _startDate.subtract(const Duration(days: 1));
          _startDate = _endDate;
          break;
        case 'Weekly':
          _endDate = _startDate.subtract(const Duration(days: 1));
          _startDate = _endDate.subtract(Duration(days: _endDate.weekday - 1));
          break;
        case 'Monthly':
          _endDate = DateTime(_startDate.year, _startDate.month, 0);
          _startDate = DateTime(_endDate.year, _endDate.month, 1);
          break;
      }
    });
    _fetchTripHistory();
  }

  void _setNextPeriod() {
    final now = DateTime.now();
    setState(() {
      switch (_selectedFilter) {
        case 'Daily':
          _startDate = _endDate.add(const Duration(days: 1));
          _endDate = _startDate;
          if (_endDate.isAfter(now)) {
            _startDate = now;
            _endDate = now;
          }
          break;
        case 'Weekly':
          _startDate = _endDate.add(const Duration(days: 1));
          _endDate = _startDate.add(Duration(days: 6 - _startDate.weekday + 1));
          if (_endDate.isAfter(now)) {
            _endDate = now;
          }
          break;
        case 'Monthly':
          _startDate = DateTime(_endDate.year, _endDate.month + 1, 1);
          _endDate = _startDate.month == 12
              ? DateTime(_startDate.year + 1, 1, 0)
              : DateTime(_startDate.year, _startDate.month + 1, 0);
          if (_endDate.isAfter(now)) {
            _endDate = now;
          }
          break;
      }
    });
    _fetchTripHistory();
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _updateDateRange();
      _fetchTripHistory();
    });
  }

  Future<void> _fetchTripHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final period = _selectedFilter.toLowerCase();
      final dateString = DateFormat('yyyy-MM-dd').format(_startDate);

      final response = await _repository.getTripHistory(
        period: period,
        date: dateString,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.status == 1) {
            _tripHistoryData = response.data;
            _errorMessage = null;
          } else {
            _errorMessage = response.message;
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching trip history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load trip history';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    final languageProvider = context.watch<LanguageProvider>();
    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('history'),
            title: languageProvider.getTranslatedText('trip_history'),
            showBackButton: true,
            showExitButton: false,
          ),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Filter Tabs
                  _buildFilterTabs(colorScheme),
                  const SizedBox(height: 16),

                  /// Trip Statistics Card
                  _buildTripStatisticsCard(colorScheme),
                  const SizedBox(height: 24),

                  /// Trips List
                  _buildTripsList(colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStatisticsCard(AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          /// Header with title and navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getFilterLabel(),
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _setPreviousPeriod();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.border, width: 1),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: colorScheme.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _setNextPeriod();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.border, width: 1),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: colorScheme.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// Statistics Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Trips',
                  _tripHistoryData?.summary.totalTrips.toString() ?? '0',
                  colorScheme,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: colorScheme.border,
              ),
              Expanded(
                child: _buildStatItem(
                    'Total Distance',
                    '${_tripHistoryData?.summary.totalDistanceKm ?? 0} Km',
                    colorScheme),
              ),
              Container(
                width: 1,
                height: 50,
                color: colorScheme.border,
              ),
              Expanded(
                child: _buildStatItem(
                  'Earnings',
                  '₹ ${_tripHistoryData?.summary.totalEarnings.numCurrency ?? 0}',
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'Daily':
        return DateFormat('EEEE, dd MMM').format(_startDate);
      case 'Weekly':
        return 'Week of ${DateFormat('dd MMM').format(_startDate)}';
      case 'Monthly':
        return DateFormat('MMMM yyyy').format(_startDate);
      default:
        return '';
    }
  }

  Widget _buildStatItem(
      String label, String value, AppColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.0,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            height: 1.09,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(AppColorScheme colorScheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _changeFilter(filter);
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? colorScheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected ? colorScheme.cardShadow : null,
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? colorScheme.textPrimary
                            : const Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripsList(AppColorScheme colorScheme) {
    // Show loading state
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                  height: 1.0,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final trips = _tripHistoryData?.trips ?? [];

    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedDeliveryBox02,
                color: colorScheme.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No trips found',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textSecondary,
                  height: 1.0,

                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      spacing: 16,
      children:
          trips.map((trip) => _buildApiTripCard(trip, colorScheme)).toList(),
    );
  }

  Widget _buildApiTripCard(Trip trip, AppColorScheme colorScheme)
  {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        _navigateToApiTripDetails(trip);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Badge + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.textPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    trip.tripType,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      trip.earningsFormatted,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.textSecondary,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 8,
                          color: colorScheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Cash Collected
            Text(
              'Cash Collected :${trip.cashCollectedFormatted}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Content: Timeline for multi-order, simple row for single order
            if (trip.isMultiOrder)
              _buildApiStopsTimeline(trip, colorScheme)
            else
              _buildSingleOrderContent(trip, colorScheme),

            // Customer tip
            const SizedBox(height: 10),
            Text(
              'Customer tip : ₹${trip.earningsDetails?.customerTip.toInt() ?? 0}',
              style: GoogleFonts.inter(
                color: colorScheme.success,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleOrderContent(Trip trip, AppColorScheme colorScheme) {
    final storeName =
        trip.addresses.isNotEmpty ? trip.addresses.first.name : '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            storeName,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatTime(trip.deliveryTime),
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _formatTime(String dateStr) {
    return formatIst(dateStr, 'h:mma').toLowerCase();
  }

  String _formatDate(String dateStr) {
    final date = parseIst(dateStr);
    if (date == null) {
      return dateStr;
    }
    return '${DateFormat('dd/MM/yyyy').format(date)}, ${DateFormat('h:mma').format(date).toLowerCase()}';
  }

  void _navigateToApiTripDetails(Trip trip) {
    final tripData = {
      'ordersId': trip.ordersId,
      'tripType': trip.tripType,
      'earnings': trip.earningsFormatted,
      'cashCollected': trip.cashCollectedFormatted,
      'customerTip': trip.earningsDetails != null
          ? '₹${trip.earningsDetails!.customerTip.toInt()}'
          : '₹0',
      'stops': trip.addresses
          .map((addr) => {
                'address': addr.address,
                'time': _formatTime(trip.deliveryTime),
              })
          .toList(),
      'date': _formatDate(trip.deliveryTime),
      'distance': trip.distanceKm > 0
          ? '${trip.distanceKm.toStringAsFixed(1)} kms'
          : '0 kms',
      'duration':
          trip.durationMins > 0 ? '${trip.durationMins} Mins' : '0 Mins',
      'baseEarning': trip.earningsDetails != null
          ? '₹${trip.earningsDetails!.baseEarning.toInt()}'
          : '₹0',
      'multiOrderBonus': trip.earningsDetails != null
          ? '₹${trip.earningsDetails!.multiOrderBonus.toInt()}'
          : '₹0',
      'gigBonus': trip.earningsDetails != null
          ? '₹${trip.earningsDetails!.gigBonus.toInt()}'
          : '₹0',
      'totalTripEarning': trip.earningsDetails != null
          ? '₹${trip.earningsDetails!.totalTripEarning.toInt()}'
          : trip.earningsFormatted,
      'lateFee': trip.deductionsDetails != null
          ? '₹${trip.deductionsDetails!.lateFee.toInt()}'
          : '₹0',
      'orderRelatedDeductions': trip.deductionsDetails != null
          ? '₹${trip.deductionsDetails!.orderRelatedDeductions.toInt()}'
          : '₹0',
      'cashCollectedDetail': trip.cashHandling != null
          ? '₹${trip.cashHandling!.cashCollected.toInt()}'
          : trip.cashCollectedFormatted,
      'cashBalance': trip.cashHandling != null
          ? '₹${trip.cashHandling!.cashBalance.toInt()}'
          : '₹0',
      'customerRating': trip.customerRating,
      'customerReview': trip.customerReview,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TripDetailsScreen(tripData: tripData),
      ),
    );
  }

  Widget _buildApiStopsTimeline(Trip trip, AppColorScheme colorScheme) {
    return Column(
      children: List.generate(trip.addresses.length, (index) {
        final address = trip.addresses[index];
        final isLast = index == trip.addresses.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Circle + Line
            Column(
              children: [
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
                  address.address,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textPrimary,
                    height: 1.3,
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
                _formatTime(trip.deliveryTime),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
