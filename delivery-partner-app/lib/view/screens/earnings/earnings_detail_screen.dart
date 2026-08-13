import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/performance_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class EarningsDetailScreen extends StatefulWidget {
  const EarningsDetailScreen({super.key});

  @override
  State<EarningsDetailScreen> createState() => _EarningsDetailScreenState();
}

class _EarningsDetailScreenState extends State<EarningsDetailScreen> {
  String _selectedFilter = 'Daily';
  final List<String> _filters = ['Daily', 'Weekly', 'Monthly'];

  // Offset tracking for each filter (for API navigation)
  int _dailyOffset = 0;
  int _weeklyOffset = 0;
  int _monthlyOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPerformanceData();
    });
  }

  void _loadPerformanceData() {
    final provider = context.read<PerformanceProvider>();
    switch (_selectedFilter.toLowerCase()) {
      case 'weekly':
        provider.getPerformanceEarnings(
          period: 'weekly',
          offset: _weeklyOffset,
        );
        break;
      case 'monthly':
        provider.getPerformanceEarnings(
          period: 'monthly',
          offset: _monthlyOffset,
        );
        break;
      default:
        provider.getPerformanceEarnings(
          period: 'daily',
          offset: _dailyOffset,
        );
    }
  }


  List<EarningsData> _generateChartDataForWeekly(List<dynamic>? dailyBreakdown) {
    if (dailyBreakdown == null || dailyBreakdown.isEmpty) {
      return [];
    }

    try {
      return List.generate(dailyBreakdown.length, (index) {
        final day = dailyBreakdown[index];

        // Extract dayName safely
        String dayName = 'Day ${index + 1}';
        if (day is Map<String, dynamic>) {
          dayName = (day['day_name'] ?? 'Day ${index + 1}').toString();
        } else if (day.dayName != null) {
          dayName = day.dayName.toString();
        }

        // Extract totalEarnings safely
        double amount = 0.0;
        if (day is Map<String, dynamic>) {
          amount = (day['total_earnings'] ?? 0).toDouble();
        } else if (day.totalEarnings != null) {
          amount = (day.totalEarnings as num).toDouble();
        }

        String label = dayName.length >= 3
          ? dayName.substring(0, 3).toUpperCase()
          : dayName.toUpperCase();

        return EarningsData(label, amount);
      });
    } catch (e) {
      debugPrint('Error generating chart data for weekly: $e');
      return [];
    }
  }

  List<EarningsData> _generateChartDataForMonthly(List<dynamic>? weeklyBreakdown) {
    if (weeklyBreakdown == null || weeklyBreakdown.isEmpty) {
      return [];
    }

    try {
      return List.generate(weeklyBreakdown.length, (index) {
        final week = weeklyBreakdown[index];

        // Extract earnings safely
        double amount = 0.0;
        if (week is Map<String, dynamic>) {
          amount = (week['earnings'] ?? 0).toDouble();
        } else if (week.earnings != null) {
          amount = (week.earnings as num).toDouble();
        }

        String label = 'Week ${index + 1}';
        return EarningsData(label, amount);
      });
    } catch (e) {
      debugPrint('Error generating chart data for monthly: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final performanceProvider = context.watch<PerformanceProvider>();

    final isLoading =
        performanceProvider.performanceState.status == ApiStatus.loading;
    final hasError =
        performanceProvider.performanceState.status == ApiStatus.error;
    final performance = performanceProvider.currentPerformance;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('earnings'),
            title: languageProvider.getTranslatedText('performance_details'),
            showBackButton: true,
          ),

          // CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Tabs
                  _buildFilterTabs(colorScheme),
                  const SizedBox(height: 24),

                  // Date Filter Navigation
                  _buildDateFilter(colorScheme),
                  const SizedBox(height: 24),

                  // Bar Chart or Loading (not shown for daily view)
                  if (_selectedFilter != 'Daily')
                    if (isLoading)
                      _buildChartSkeleton(colorScheme)
                    else if (hasError || performance == null)
                      _buildErrorWidget(colorScheme)
                    else
                      _buildBarChart(colorScheme, performance),
                  if (_selectedFilter != 'Daily') const SizedBox(height: 32),

                  // Today's Performance Card
                  if (performance != null)
                    _buildPerformanceCard(colorScheme, performance),
                  if (performance != null) const SizedBox(height: 16),

                  // Earnings Breakdown
                  if (performance != null)
                    Text(
                      'Earnings Breakdown',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (performance != null) const SizedBox(height: 16),

                  // Earnings Breakdown Items
                  if (performance != null)
                    ...performance.earningsBreakdown.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildEarningsRow(
                        item.name,
                        item.description,
                        '+ ₹${item.amount.toStringAsFixed(0)}',
                        colorScheme,
                      ),
                    )),
                  if (performance != null) const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
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
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _loadPerformanceData();
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.surface : Colors.transparent,
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
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
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

  String _getWeekLabel(DateTime weekStart) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStartDateOnly = DateTime(weekStart.year, weekStart.month, weekStart.day);

    if (weekStartDateOnly == today) {
      return 'This Week';
    } else if (weekStartDateOnly.add(const Duration(days: 7)) == today) {
      return 'Last Week';
    } else if (weekStartDateOnly.subtract(const Duration(days: 7)) == today) {
      return 'Next Week';
    }
    return 'Week of ${DateFormat('MMM d').format(weekStart)}';
  }

  String _getMonthLabelFromString(String monthStr) {
    final now = DateTime.now();
    try {
      final month = DateFormat('yyyy-MM').parse(monthStr);
      if (month.year == now.year && month.month == now.month) {
        return 'This Month';
      } else if ((month.year == now.year && month.month == now.month - 1) ||
          (now.month == 1 && month.year == now.year - 1 && month.month == 12)) {
        return 'Last Month';
      } else if ((month.year == now.year && month.month == now.month + 1) ||
          (now.month == 12 && month.year == now.year + 1 && month.month == 1)) {
        return 'Next Month';
      }
      return DateFormat('MMMM').format(month);
    } catch (e) {
      debugPrint('Error parsing month string: $e');
    }
    return monthStr;
  }

  bool _isCurrentPeriod() {
    final performance = context.read<PerformanceProvider>().currentPerformance;
    if (performance == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedFilter == 'Daily') {
      if (performance.availableDates.currentDate != null) {
        final date = DateTime.parse(performance.availableDates.currentDate!);
        final dateOnly = DateTime(date.year, date.month, date.day);
        return dateOnly == today;
      }
    } else if (_selectedFilter == 'Weekly') {
      if (performance.availableDates.currentWeekStart != null) {
        final weekStart = DateTime.parse(performance.availableDates.currentWeekStart!);
        final weekEnd = weekStart.add(const Duration(days: 6));
        // Check if today falls within this week
        return !today.isBefore(weekStart) && !today.isAfter(weekEnd);
      }
    } else {
      // Monthly
      if (performance.availableDates.currentMonth != null) {
        final monthStr = performance.availableDates.currentMonth!;
        try {
          final month = DateFormat('yyyy-MM').parse(monthStr);
          return month.year == today.year && month.month == today.month;
        } catch (e) {
          debugPrint('Error parsing month: $e');
        }
      }
    }
    return false;
  }

  Widget _buildDateFilter(AppColorScheme colorScheme) {
    String dateText = '';
    String periodLabel = '';
    final performance = context.watch<PerformanceProvider>().currentPerformance;

    if (performance == null) {
      dateText = 'Loading...';
      periodLabel = '';
    } else if (_selectedFilter == 'Daily') {
      // Use current_date from API
      if (performance.availableDates.currentDate != null) {
        final date = DateTime.parse(performance.availableDates.currentDate!);
        dateText = DateFormat('dd MMM yyyy').format(date);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final selectedDateOnly = DateTime(date.year, date.month, date.day);
        if (selectedDateOnly == today) {
          periodLabel = 'Today';
        } else if (selectedDateOnly.add(const Duration(days: 1)) == today) {
          periodLabel = 'Yesterday';
        } else if (selectedDateOnly.subtract(const Duration(days: 1)) == today) {
          periodLabel = 'Tomorrow';
        }
      }
    } else if (_selectedFilter == 'Weekly') {
      // Use API dates if available
      if (performance.availableDates.currentWeekStart != null) {
        final weekStart = DateTime.parse(performance.availableDates.currentWeekStart!);
        // Calculate week end (6 days after start)
        final weekEnd = weekStart.add(const Duration(days: 6));
        dateText = '${DateFormat('dd MMM').format(weekStart)} - ${DateFormat('dd MMM yyyy').format(weekEnd)}';
        periodLabel = _getWeekLabel(weekStart);
      }
    } else {
      // Monthly
      if (performance.availableDates.currentMonth != null) {
        final monthStr = performance.availableDates.currentMonth!;
        periodLabel = _getMonthLabelFromString(monthStr);
        dateText = monthStr;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _navigatePrevious();
              },
              borderRadius: BorderRadius.circular(17),
              child: Ink(
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
          ),
          const SizedBox(width: 16),
          // Date Text with Period Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (periodLabel.isNotEmpty)
                  Text(
                    periodLabel.replaceAll(' • ', ''),
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.05,
                    ),
                  ),
                Text(
                  dateText,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.05,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Next Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCurrentPeriod()
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _navigateNext();
                    },
              borderRadius: BorderRadius.circular(17),
              child: Ink(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _isCurrentPeriod()
                      ? colorScheme.surfaceElevated.withValues(alpha: 0.5)
                      : colorScheme.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _isCurrentPeriod()
                        ? colorScheme.textSecondary.withValues(alpha: 0.5)
                        : colorScheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigatePrevious() {
    setState(() {
      if (_selectedFilter == 'Daily') {
        _dailyOffset--;
      } else if (_selectedFilter == 'Weekly') {
        _weeklyOffset--;
      } else {
        _monthlyOffset--;
      }
    });
    _loadPerformanceData();
  }

  void _navigateNext() {
    setState(() {
      if (_selectedFilter == 'Daily') {
        _dailyOffset++;
      } else if (_selectedFilter == 'Weekly') {
        _weeklyOffset++;
      } else {
        _monthlyOffset++;
      }
    });
    _loadPerformanceData();
  }

  Widget _buildBarChart(AppColorScheme colorScheme, performance) {
    // Generate chart data based on period type
    late List<EarningsData> chartData;

    if (_selectedFilter == 'Weekly') {
      chartData = _generateChartDataForWeekly(performance.dailyBreakdown);
    } else if (_selectedFilter == 'Monthly') {
      chartData = _generateChartDataForMonthly(performance.weeklyBreakdown);
    } else {
      chartData = [];
    }

    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(color: colorScheme.textSecondary),
        ),
      );
    }

    final maxY = chartData.isNotEmpty
        ? chartData.map((e) => e.amount).reduce((a, b) => a > b ? a : b)
        : 1000;
    final roundedMaxY = ((maxY / 100).ceil() * 100).toDouble();

    return Container(
      height: 280,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings Overview',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹${performance.earningsOverview.totalEarnings.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: roundedMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => colorScheme.surface,
                    tooltipBorderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toInt()}',
                        GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              chartData[value.toInt()].label,
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: roundedMaxY <= 5000 ? 1000 : (roundedMaxY <= 10000 ? 2000 : 5000),
                      getTitlesWidget: (value, meta) {
                        // Only show labels at intervals
                        if (value % (roundedMaxY <= 5000 ? 1000 : (roundedMaxY <= 10000 ? 2000 : 5000)) == 0) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}k',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < chartData.length) {
                          final dataPoint = chartData[value.toInt()];
                          // Show top price label on the highest earning bar
                          final maxAmount =
                              chartData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
                          if (dataPoint.amount == maxAmount) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '₹${dataPoint.amount.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(
                                        color: colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
                        color: colorScheme.primary,
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton(AppColorScheme colorScheme) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(AppColorScheme colorScheme) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load earnings',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(AppColorScheme colorScheme, performance) {
    String cardTitle;
    late Widget distanceWidget;
    late Widget ordersWidget;
    late Widget hoursWidget;

    if (_selectedFilter == 'Daily') {
      cardTitle = 'Today\'s Performance';
      distanceWidget = _buildStatItem(
        'Distance covered',
        '${performance.todaysPerformance.distanceCovered.toStringAsFixed(0)} Km',
        colorScheme,
      );
      ordersWidget = _buildStatItem(
        'Orders',
        '${performance.todaysPerformance.totalOrders}',
        colorScheme,
      );
      hoursWidget = _buildStatItem(
        'Login Hours',
        performance.todaysPerformance.loginHours,
        colorScheme,
      );
    } else if (_selectedFilter == 'Weekly') {
      cardTitle = 'Week\'s Performance';

      // Use todays_performance which contains aggregated weekly data
      final weeklyData = performance.todaysPerformance;

      distanceWidget = _buildStatItem(
        'Distance covered',
        '${weeklyData.distanceCovered.toStringAsFixed(0)} Km',
        colorScheme,
      );
      ordersWidget = _buildStatItem(
        'Orders',
        '${weeklyData.totalOrders}',
        colorScheme,
      );
      hoursWidget = _buildStatItem(
        'Login Hours',
        weeklyData.loginHours,
        colorScheme,
      );
    } else {
      // Monthly
      cardTitle = 'Month\'s Performance';

      // Use todays_performance which contains aggregated monthly data
      final monthlyData = performance.todaysPerformance;

      distanceWidget = _buildStatItem(
        'Distance covered',
        '${monthlyData.distanceCovered.toStringAsFixed(0)} Km',
        colorScheme,
      );
      ordersWidget = _buildStatItem(
        'Orders',
        '${monthlyData.totalOrders}',
        colorScheme,
      );
      hoursWidget = _buildStatItem(
        'Login Hours',
        monthlyData.loginHours,
        colorScheme,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: distanceWidget),
              Container(
                width: 1,
                height: 50,
                color: colorScheme.border,
              ),
              Expanded(child: ordersWidget),
              Container(
                width: 1,
                height: 50,
                color: colorScheme.border,
              ),
              Expanded(child: hoursWidget),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, AppColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsRow(
    String title,
    String subtitle,
    String amount,
    AppColorScheme colorScheme,
  ) {
    return Container(
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedTick02,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EarningsData {
  final String label;
  final double amount;

  EarningsData(this.label, this.amount);
}
