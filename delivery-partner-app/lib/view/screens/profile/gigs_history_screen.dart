import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/booking_model.dart';
import 'package:zenfoo_partner/providers/booking_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:intl/intl.dart';

class GigsHistoryScreen extends StatefulWidget {
  const GigsHistoryScreen({super.key});

  @override
  State<GigsHistoryScreen> createState() => _GigsHistoryScreenState();
}

class _GigsHistoryScreenState extends State<GigsHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  final Set<String> _collapsedDates = {};

  @override
  void initState() {
    super.initState();
    _initializeWeekDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchMyBookings(
            dateFrom: _startDate,
            dateTo: _endDate,
          );
    });
  }

  void _initializeWeekDates() {
    final now = DateTime.now();
    _endDate = now;
    final daysToMonday = now.weekday - 1;
    _startDate = now.subtract(Duration(days: daysToMonday));
  }

  Map<String, List<Booking>> _groupByDate(List<Booking> bookings) {
    final Map<String, List<Booking>> grouped = {};
    for (final booking in bookings) {
      final dateKey =
          DateFormat('MMM dd, yyyy').format(booking.slotDate).toUpperCase();
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(booking);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(
            label: languageProvider.getTranslatedText('history'),
            title: languageProvider.getTranslatedText('gigs_history'),
            showBackButton: true,
            showExitButton: false,
          ),
          Expanded(
            child: _buildContent(colorScheme, bookingProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      AppColorScheme colorScheme, BookingProvider provider) {
    if (provider.status == BookingStatus.loading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (provider.status == BookingStatus.error) {
      return Center(
        child: Text(
          provider.errorMessage,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    final bookings = provider.bookings;
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No gigs found',
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    final grouped = _groupByDate(bookings);
    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final dateBookings = grouped[dateKey]!;
        final isCollapsed = _collapsedDates.contains(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isCollapsed) {
                    _collapsedDates.remove(dateKey);
                  } else {
                    _collapsedDates.add(dateKey);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateKey,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      isCollapsed
                          ? Icons.arrow_drop_down
                          : Icons.arrow_drop_up,
                      size: 24,
                      color: colorScheme.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
            // Bookings under this date
            if (!isCollapsed)
              ...dateBookings.map(
                  (booking) => _buildBookingCard(colorScheme, booking)),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(AppColorScheme colorScheme, Booking booking) {
    Color statusColor;
    String statusText;

    if (booking.isCompleted) {
      statusColor = colorScheme.success;
      statusText = 'Completed';
    } else if (booking.isCancelled) {
      statusColor = colorScheme.error;
      statusText = 'Cancelled';
    } else {
      statusColor = colorScheme.info;
      statusText = 'Booked';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status badge + Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '₹${booking.baseEarnings.toInt()}',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Trips count + Time range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booking.ordersCompleted} trips',
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                _formatTimeRange(booking),
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeRange(Booking booking) {
    try {
      final start = DateFormat('HH:mm:ss').parse(booking.startTime);
      final end = DateFormat('HH:mm:ss').parse(booking.endTime);
      final duration = end.difference(start);

      final startFormatted = DateFormat('h a').format(start);
      final endFormatted = DateFormat('h a').format(end);
      final hours = duration.inHours;

      return '$startFormatted - $endFormatted ( $hours Hours )';
    } catch (e) {
      return '${booking.startTime} - ${booking.endTime}';
    }
  }
}
