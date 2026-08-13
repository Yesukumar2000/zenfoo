import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/gig_booking_model.dart';
import 'package:zenfoo_partner/providers/gig_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final gigProvider = context.read<GigProvider>();
    await gigProvider.getMyBookings();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final gigProvider = context.watch<GigProvider>();

    final myBookingsState = gigProvider.myBookingsState;
    final isLoading = myBookingsState.status == ApiStatus.loading;
    final hasError = myBookingsState.status == ApiStatus.error;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// ================= APP HEADER =================
          const AppHeader(
            label: 'My Schedule',
            title: 'Bookings',
            showBackButton: true,
          ),

          const SizedBox(height: 16),

          /// ================= TAB BAR =================
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colorScheme.border,
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: colorScheme.surface,
              unselectedLabelColor: colorScheme.textSecondary,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.55,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.55,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Upcoming'),
                      if (gigProvider.upcomingBookings.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${gigProvider.upcomingBookings.length}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Tab(text: 'Completed'),
                const Tab(text: 'Cancelled'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// ================= TAB BAR VIEW =================
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
            )
          else if (hasError)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load bookings',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Retry',
                      onPressed: _loadBookings,
                      height: 48,
                      width: 120,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(
                    gigProvider.upcomingBookings,
                    colorScheme,
                    'upcoming',
                  ),
                  _buildBookingsList(
                    gigProvider.completedBookings,
                    colorScheme,
                    'completed',
                  ),
                  _buildBookingsList(
                    gigProvider.cancelledBookings,
                    colorScheme,
                    'cancelled',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(
    List<GigBooking> bookings,
    colorScheme,
    String type,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming'
                  ? Icons.calendar_today_outlined
                  : type == 'completed'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 64,
              color: colorScheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming'
                  ? 'No upcoming bookings'
                  : type == 'completed'
                      ? 'No completed bookings'
                      : 'No cancelled bookings',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'upcoming'
                  ? 'Book gigs to see them here'
                  : 'You\'ll see your ${type} gigs here',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: colorScheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: 8,
        ),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, colorScheme, type);
        },
      ),
    );
  }

  Widget _buildBookingCard(
    GigBooking booking,
    colorScheme,
    String type,
  ) {
    // Parse slot date
    final slotDate = DateTime.tryParse(booking.slotDate);
    final formattedDate = slotDate != null
        ? DateFormat('EEE, dd MMM').format(slotDate)
        : booking.slotDate;

    // Status colors and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.bookingStatus) {
      case 'booked':
        statusColor = colorScheme.primary;
        statusText = 'Booked';
        statusIcon = Icons.schedule;
        break;
      case 'active':
        statusColor = colorScheme.success;
        statusText = 'Active';
        statusIcon = Icons.play_circle;
        break;
      case 'completed':
        statusColor = colorScheme.success;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = colorScheme.error;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
      case 'no_show':
        statusColor = colorScheme.textSecondary;
        statusText = 'No Show';
        statusIcon = Icons.person_off;
        break;
      default:
        statusColor = colorScheme.textSecondary;
        statusText = booking.bookingStatus;
        statusIcon = Icons.info;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.border.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          /// HEADER: Date & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colorScheme.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// MAIN CONTENT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Gig Name
                Text(
                  booking.displayName,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.55,
                  ),
                ),
                const SizedBox(height: 12),

                /// Time Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${booking.startTime} - ${booking.endTime}',
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${booking.durationHours.toStringAsFixed(1)}h',
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.55,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// Earnings Row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.success.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Base Earnings',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.55,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${booking.estimatedEarnings}',
                            style: GoogleFonts.inter(
                              color: colorScheme.success,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.55,
                            ),
                          ),
                        ],
                      ),
                      if (booking.isCompleted && booking.actualEarnings > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Actual Earnings',
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.55,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${booking.actualEarnings.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: colorScheme.success,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.55,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                /// Additional Stats for Completed Bookings
                if (booking.isCompleted &&
                    (booking.ordersDelivered > 0 ||
                        booking.distanceCoveredKm > 0)) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (booking.ordersDelivered > 0) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.border.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 20,
                                  color: colorScheme.textPrimary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.ordersDelivered}',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.55,
                                  ),
                                ),
                                Text(
                                  'Orders',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (booking.distanceCoveredKm > 0)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.border.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.route_outlined,
                                  size: 20,
                                  color: colorScheme.textPrimary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.distanceCoveredKm.toStringAsFixed(1)}',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.55,
                                  ),
                                ),
                                Text(
                                  'KM',
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                /// Cancel Reason for Cancelled Bookings
                if (booking.isCancelled && booking.cancelReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.cancelReason!,
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                /// Action Buttons for Upcoming Bookings
                if (booking.isUpcoming &&
                    booking.bookingStatus == 'booked') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () => _showCancelDialog(booking),
                          height: 40,
                          backgroundColor:
                              colorScheme.error.withValues(alpha: 0.1),
                          textColor: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(GigBooking booking) async {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Cancel Booking',
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this booking?',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason (optional):',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Enter cancellation reason...',
                hintStyle: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: colorScheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Booking',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cancel Booking',
              style: GoogleFonts.inter(
                color: colorScheme.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final gigProvider = context.read<GigProvider>();

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );

      final success = await gigProvider.cancelBooking(
        bookingId: booking.bookingId,
        reason: reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        if (success) {
          // Reload bookings
          await _loadBookings();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Booking cancelled successfully',
                style: GoogleFonts.inter(
                  color: colorScheme.surface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: colorScheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to cancel booking',
                style: GoogleFonts.inter(
                  color: colorScheme.surface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}
