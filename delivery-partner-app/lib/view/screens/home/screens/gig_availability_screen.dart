import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/gig_slot_model.dart';
import 'package:zenfoo_partner/providers/gig_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/utils/globle_func.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_gradient_scaffold.dart';

class GigAvailabilityScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const GigAvailabilityScreen({super.key, this.selectedDate});

  @override
  State<GigAvailabilityScreen> createState() => _GigAvailabilityScreenState();
}

class _GigAvailabilityScreenState extends State<GigAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  int selectedFilter = 0; // 0 = All, 1 = Open, 2 = Booked
  DateTime _selectedDate = DateTime.now();
  final Set<int> _selectedSlotIds = {};
  int? _cancellingSlotId; // Track which slot is being cancelled
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    // Initialize shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGigs();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadGigs() async {
    final gigProvider = context.read<GigProvider>();
    await gigProvider.getAvailableGigs(date: _selectedDate);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlotIds.clear();
      });
      _loadGigs();
    }
  }

  List<GigSlot> _getFilteredGigs(List<GigSlot> gigs) {
    switch (selectedFilter) {
      case 1: // Open
        return gigs.where((g) => g.isAvailable && !g.isBooked).toList();
      case 2: // Booked
        return gigs.where((g) => g.isBooked).toList();
      default: // All
        return gigs;
    }
  }

  Map<String, List<GigSlot>> _groupGigsByType(List<GigSlot> gigs) {
    final Map<String, List<GigSlot>> grouped = {
      'morning_shift': [],
      'afternoon_shift': [],
      'evening': [],
      'extra_shift': []
    };

    for (var gig in gigs) {
      if (grouped.containsKey(gig.gigType)) {
        grouped[gig.gigType]!.add(gig);
      }
    }

    return grouped;
  }

  void _toggleSlotSelection(int slotId, bool isBooked) {
    if (isBooked) return; // Can't select already booked slots

    setState(() {
      if (_selectedSlotIds.contains(slotId)) {
        _selectedSlotIds.remove(slotId);
      } else {
        _selectedSlotIds.add(slotId);
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlotIds.isEmpty) {
      showCustomToast(title: 'Please select at least one gig slot');
      return;
    }

    final gigProvider = context.read<GigProvider>();
    final colorScheme = context.read<ThemeProvider>().colorScheme;

    // Show confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildConfirmationSheet(colorScheme),
    );

    if (confirmed != true) return;

    // Book all selected slots at once using bulk booking API
    final result = await gigProvider.bookGig(
      slotIds: _selectedSlotIds.toList(),
    );

    if (!mounted) return;

    // Show detailed results in bottom sheet
    await _showBookingResultsSheet(result, colorScheme);

    // Reload gigs and clear selection
    _selectedSlotIds.clear();
    _loadGigs();
  }

  /// Handle cancel booking from a slot
  Future<void> _handleCancelBookingFromSlot(
    GigSlot gig,
    AppColorScheme colorScheme,
  ) async {
    final gigProvider = context.read<GigProvider>();

    try {
      // Check if bookingId is available
      if (gig.bookingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking ID not found. Please refresh and try again.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: colorScheme.error,
          ),
        );
        // Reload to sync
        await _loadGigs();
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to cancel this gig?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Yes',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: colorScheme.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'No',
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed != true || !mounted) return;

      // Set loading state
      setState(() {
        _cancellingSlotId = gig.slotId;
      });

      // Cancel the booking using the bookingId from the gig slot
      final success = await gigProvider.cancelBooking(
        bookingId: gig.bookingId!,
      );

      // Clear loading state
      if (mounted) {
        setState(() {
          _cancellingSlotId = null;
        });
      }

      if (!mounted) return;

      if (success) {
        // Show full-screen cancelled success for 2 seconds (non-dismissible)
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: colorScheme.surface,
          builder: (ctx) => PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your gig was cancelled',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Your gig has been cancelled successfully. You can book another gig anytime.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Auto-dismiss after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();

        // Reload gigs to update the UI
        if (mounted) await _loadGigs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to cancel booking',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Handle any errors during the cancellation process
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred: ${e.toString()}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  /// Show booking results bottom sheet with detailed information
  Future<void> _showBookingResultsSheet(
    Map<String, dynamic> result,
    AppColorScheme colorScheme,
  ) async {
    debugPrint('🎯 Bottom Sheet Result: $result');
    debugPrint('🎯 totalBooked value: ${result['totalBooked']}');

    final totalBooked = result['totalBooked'] as int? ?? 0;
    final errors = result['errors'] as List? ?? [];
    final skipped = result['skipped'] as List? ?? [];
    final offerProgress = result['offerProgress'] as List? ?? [];

    debugPrint('🎯 Parsed totalBooked: $totalBooked');

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: EdgeInsets.only(
          left: AppDimensions.paddingMedium,
          right: AppDimensions.paddingMedium,
          top: AppDimensions.paddingMedium,
          bottom: MediaQuery.of(context).padding.bottom +
              AppDimensions.paddingMedium,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: totalBooked > 0
                        ? colorScheme.success.withValues(alpha: 0.15)
                        : colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    totalBooked > 0 ? Icons.check_circle : Icons.error_outline,
                    color: totalBooked > 0
                        ? colorScheme.success
                        : colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    totalBooked > 0 ? 'Booking Successful!' : 'Booking Failed',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.55,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: colorScheme.border.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success message
                    if (totalBooked > 0) ...[
                      Text(
                        'Successfully booked $totalBooked gig slot${totalBooked > 1 ? 's' : ''}!',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Offer progress
                    if (offerProgress.isNotEmpty) ...[
                      Text(
                        'Incentive Progress',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...offerProgress.map((progress) {
                        final requirementMet =
                            progress['requirement_met'] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: requirementMet
                                ? colorScheme.success.withValues(alpha: 0.1)
                                : colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: requirementMet
                                  ? colorScheme.success.withValues(alpha: 0.3)
                                  : colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    requirementMet
                                        ? Icons.celebration
                                        : Icons.trending_up,
                                    size: 18,
                                    color: requirementMet
                                        ? colorScheme.success
                                        : colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      progress['offer_name'] ?? '',
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${progress['gigs_booked']}/${progress['min_gigs_required']} gigs booked',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!requirementMet &&
                                  progress['message'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  progress['message'],
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Errors
                    if (errors.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            'Issues',
                            style: GoogleFonts.inter(
                              color: colorScheme.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...errors.map((error) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.error.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 18, color: colorScheme.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    error.toString(),
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],

                    // Skipped slots
                    if (skipped.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: colorScheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Already Booked',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...skipped.map((skip) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.border.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    colorScheme.border.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.schedule,
                                    size: 16, color: colorScheme.textSecondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    skip.toString(),
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // OK Button
            CustomButton(
              text: 'OK',
              onPressed: () => Navigator.pop(context),
              height: 52,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSheet(AppColorScheme colorScheme) {
    final gigProvider = context.read<GigProvider>();
    final selectedSlots = gigProvider.availableGigs
        .where((gig) => _selectedSlotIds.contains(gig.slotId))
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.paddingMedium,
        right: AppDimensions.paddingMedium,
        top: AppDimensions.paddingMedium,
        bottom:
            MediaQuery.of(context).padding.bottom + AppDimensions.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confirm Booking',
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.border.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.textSecondary,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You are about to book ${_selectedSlotIds.length} gig slot${_selectedSlotIds.length > 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              color: colorScheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.55,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // List of selected slots
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: selectedSlots.map((slot) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.border.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.border.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.access_time,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot.gigDisplayName,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                slot.slotName,
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
                          '₹${slot.baseEarnings.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.pop(context, false),
                  height: 52,
                  backgroundColor: colorScheme.border.withValues(alpha: 0.3),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Confirm',
                  onPressed: () => Navigator.pop(context, true),
                  height: 52,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final gigProvider = context.watch<GigProvider>();
    return CustomGradientScaffold(
      isSafeArea: false,
      statusBarColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          DateFormat('EEE,dd MMM')
              .format(_selectedDate)
              .toUpperCase(),
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: colorScheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// ================= FILTERS =================
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium, vertical: 10),
            child: Row(
              children: [
                _filterChip("All", 0, colorScheme),
                const SizedBox(width: 10),
                _filterChip("Open", 1, colorScheme),
                const SizedBox(width: 10),
                _filterChip("Booked", 2, colorScheme),
              ],
            ),
          ),

          /// ================= BODY =================
          Expanded(
            child: gigProvider.availableGigsState.status == ApiStatus.loading
                ? _buildLoadingSkeleton(colorScheme)
                : gigProvider.availableGigsState.status == ApiStatus.error
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: colorScheme.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              gigProvider.availableGigsState.message ??
                                  'Failed to load gigs',
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Retry',
                              onPressed: _loadGigs,
                            ),
                          ],
                        ),
                      )
                    : _buildGigsList(gigProvider, colorScheme),
          ),

          /// ================= CONTINUE BUTTON =================
          if (_selectedSlotIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: CustomButton(
                text: 'Continue',
                // text:
                //     "Book ${_selectedSlotIds.length} Gig${_selectedSlotIds.length > 1 ? 's' : ''}",
                onPressed: _confirmBooking,
                height: 52,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGigsList(GigProvider gigProvider, AppColorScheme colorScheme) {
    final filteredGigs = _getFilteredGigs(gigProvider.availableGigs);

    if (filteredGigs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: colorScheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No gigs available for this date',
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Booked filter: show flat list without shift sections
    if (selectedFilter == 2) {
      return RefreshIndicator(
        onRefresh: _loadGigs,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              ...filteredGigs.map((gig) => _timeSlot(gig, colorScheme)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    final groupedGigs = _groupGigsByType(filteredGigs);

    return RefreshIndicator(
      onRefresh: _loadGigs,
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (groupedGigs['morning_shift']!.isNotEmpty)
              _shiftSection(
                colorScheme: colorScheme,
                title: "Morning Gig",
                icon: AppImages.morning,
                gigs: groupedGigs['morning_shift']!,
              ),
            if (groupedGigs['morning_shift']!.isNotEmpty)
              const SizedBox(height: 20),
            if (groupedGigs['afternoon_shift']!.isNotEmpty)
              _shiftSection(
                colorScheme: colorScheme,
                title: "Afternoon Gig",
                icon: AppImages.afternoon,
                gigs: groupedGigs['afternoon_shift']!,
              ),
            if (groupedGigs['afternoon_shift']!.isNotEmpty)
              const SizedBox(height: 20),
            if (groupedGigs['evening']!.isNotEmpty)
              _shiftSection(
                colorScheme: colorScheme,
                title: "Evening Gig",
                icon: AppImages.evening,
                gigs: groupedGigs['evening']!,
              ),
            if (groupedGigs['evening']!.isNotEmpty) const SizedBox(height: 20),
            if (groupedGigs['extra_shift']!.isNotEmpty)
              _shiftSection(
                colorScheme: colorScheme,
                title: "Extra Shift",
                icon: AppImages.night,
                gigs: groupedGigs['extra_shift']!,
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String text, int index, AppColorScheme colorScheme) {
    final bool isSelected = selectedFilter == index;

    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9AC444).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9AC444)
                : const Color(0xFFD1D5DB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isSelected
                ? colorScheme.textPrimary
                : colorScheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  /// ================= SHIFT SECTION =================
  Widget _shiftSection({
    required AppColorScheme colorScheme,
    required String title,
    required String icon,
    required List<GigSlot> gigs,
  }) {
    if (gigs.isEmpty) return const SizedBox.shrink();

    // Show overall timing - get first slot start and last slot end time
    final timing = gigs.length == 1
        ? '${gigs.first.startTime} - ${gigs.first.endTime}'
        : '${gigs.first.startTime} - ${gigs.last.endTime}';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          /// SHIFT HEADER - dark background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.textPrimary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: colorScheme.background,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                ImageIcon(
                  AssetImage(icon),
                  color: colorScheme.background.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimeWithAmPm(timing),
                  style: GoogleFonts.inter(
                    color: colorScheme.background.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          /// TIME SLOTS FROM API
          ...gigs.map((gig) => _timeSlot(gig, colorScheme)),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// ================= TIME SLOT ITEM =================
  Widget _timeSlot(GigSlot gig, AppColorScheme colorScheme) {
    final bool isSelected = _selectedSlotIds.contains(gig.slotId);
    final bool isBooked = gig.isBooked && gig.bookingStatus == 'booked';
    final bool isAvailable = gig.isAvailable;

    return GestureDetector(
      onTap: isAvailable && !isBooked
          ? () => _toggleSlotSelection(gig.slotId, isBooked)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatSingleTime(gig.startTime)}  -  ${_formatSingleTime(gig.endTime)}',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                  if (isBooked) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Booked',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF3B82F6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isBooked)
              _cancellingSlotId == gig.slotId
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                  : GestureDetector(
                      onTap: () =>
                          _handleCancelBookingFromSlot(gig, colorScheme),
                      child: Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: colorScheme.error,
                        ),
                      ),
                    )
            else if (!isAvailable)
              Icon(
                Icons.close,
                size: 22,
                color: colorScheme.textSecondary.withValues(alpha: 0.5),
              )
            else
              Container(
                height: 22,
                width: 22,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: colorScheme.surface,
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  /// ================= TIME FORMAT HELPERS =================
  String _formatSingleTime(String time) {
    try {
      // Try parsing "HH:mm" or "HH:mm:ss" format
      final parts = time.trim().split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour == 0) hour = 12;
        if (hour > 12) hour -= 12;
        return '$hour:$minute $period';
      }
    } catch (_) {}
    return time; // Return as-is if parsing fails
  }

  String _formatTimeWithAmPm(String timing) {
    // timing is like "09:00 - 17:00"
    final parts = timing.split(' - ');
    if (parts.length == 2) {
      return '${_formatSingleTime(parts[0])} - ${_formatSingleTime(parts[1])}';
    }
    return timing;
  }

  /// ================= LOADING SKELETON =================
  Widget _buildLoadingSkeleton(AppColorScheme colorScheme) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      child: Column(
        children: [
          // Morning Gig Skeleton
          _shiftSectionSkeleton(colorScheme),
          const SizedBox(height: 20),
          // Afternoon Gig Skeleton
          _shiftSectionSkeleton(colorScheme),
          const SizedBox(height: 20),
          // Evening Gig Skeleton
          _shiftSectionSkeleton(colorScheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _shiftSectionSkeleton(AppColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.border.withValues(alpha: 0.3),
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            /// SHIFT HEADER SKELETON
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.border.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildShimmerBox(120, 15, 4, colorScheme),
                  ),
                  _buildShimmerBox(20, 20, 4, colorScheme),
                  const SizedBox(width: 10),
                  _buildShimmerBox(100, 13, 4, colorScheme),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// TIME SLOTS SKELETON (3 slots per section)
            _timeSlotSkeleton(colorScheme),
            _timeSlotSkeleton(colorScheme),
            _timeSlotSkeleton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _timeSlotSkeleton(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildShimmerBox(180, 14, 4, colorScheme),
          ),
          const SizedBox(width: 12),
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(
      double width, double height, double radius, AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colorScheme.surfaceVariant,
                colorScheme.surface,
                colorScheme.surfaceVariant,
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
