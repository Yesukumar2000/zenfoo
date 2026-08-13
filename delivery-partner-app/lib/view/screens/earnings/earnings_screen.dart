import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_image_icon.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/status_toggle_widget.dart';
import 'package:zenfoo_partner/view/screens/earnings/cash_in_hand_screen.dart';
import 'package:zenfoo_partner/view/screens/emergency/emergency_support_screen.dart';
import 'package:zenfoo_partner/view/screens/face_verification/face_verification_screen.dart';
import 'package:zenfoo_partner/view/screens/help_center/help_center_screen.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/weekly_summary_provider.dart';
import 'package:zenfoo_partner/view/screens/earnings/payout_section_detail_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/deductions_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/earnings_detail_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/multi_order_earnings_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/order_earnings_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/payout_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/payment_history_screen.dart';
import 'package:zenfoo_partner/view/screens/earnings/transfer_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/profile_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeeklySummaryData();
    });
  }

  void _loadWeeklySummaryData() {
    final provider = context.read<WeeklySummaryProvider>();
    provider.getWeeklySummary(period: 'weekly', offset: 0);
  }

  Future<void> _refreshEarnings() async {
    if (!mounted) return;
    final provider = context.read<WeeklySummaryProvider>();
    await provider.getWeeklySummary(period: 'weekly', offset: 0);
  }

  /// Handle status toggle - start or end session
  Future<void> _handleStatusToggle(SessionProvider sessionProvider) async {
    if (_isTogglingStatus) return;

    if (sessionProvider.isOnline) {
      // Go offline
      await _endSession(sessionProvider);
    } else {
      // Go online - with face verification
      await _startSession(sessionProvider);
    }
  }

  /// Start a new session - Navigate to face verification
  Future<void> _startSession(SessionProvider sessionProvider) async {
    setState(() => _isTogglingStatus = true);

    // Get providers before async gap
    final incomingOrderProvider = context.read<IncomingOrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final deliveryBoyId = authProvider.currentDeliveryBoy?.id;

    try {
      // Navigate to face verification screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FaceVerificationScreen(),
        ),
      );

      setState(() => _isTogglingStatus = false);
      if (!mounted) return;

      // If face verification was successful and session started
      if (result == true) {
        _showSuccessSnackBar('You are now online!');

        // Start listening for incoming orders
        if (deliveryBoyId != null) {
          debugPrint('✅ Session started, starting Firebase order listener');
          incomingOrderProvider.startListening(deliveryBoyId);
        }
      }
    } catch (e) {
      setState(() => _isTogglingStatus = false);
      if (!mounted) return;
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// End the active session
  Future<void> _endSession(SessionProvider sessionProvider) async {
    setState(() => _isTogglingStatus = true);

    // Get provider before async gap
    final incomingOrderProvider = context.read<IncomingOrderProvider>();

    try {
      // Show confirmation dialog
      if (mounted) {
        final shouldLogout = await _showOfflineConfirmation();
        if (!shouldLogout) {
          setState(() => _isTogglingStatus = false);
          return;
        }
      }

      // Get current location
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() => _isTogglingStatus = false);
        if (!mounted) return;
        _showErrorSnackBar('Unable to get your location. Please enable GPS.');
        return;
      }

      // End session
      final success = await sessionProvider.endSession(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() => _isTogglingStatus = false);
      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('You are now offline');

        // Stop listening for incoming orders
        incomingOrderProvider.stopListening();
      } else {
        _showErrorSnackBar('Failed to end session');
      }
    } catch (e) {
      setState(() => _isTogglingStatus = false);
      if (!mounted) return;
      debugPrint('Error ending session: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  /// Show confirmation dialog before going offline
  Future<bool> _showOfflineConfirmation() async {
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                languageProvider.getTranslatedText('go_offline_title'),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.textPrimary,
                ),
              ),
              content: Text(
                languageProvider
                    .getTranslatedText('offline_confirmation_message'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textSecondary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'No',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(
                    'Yes',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final sessionProvider = context.watch<SessionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final weeklySummaryProvider = context.watch<WeeklySummaryProvider>();
    final weeklySummaryData = weeklySummaryProvider.currentWeeklySummary;
    final deliveryBoy = authProvider.currentDeliveryBoy;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('wallet'),
            title: languageProvider.getTranslatedText('earnings'),
            showBackButton: false,
            showExitButton: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusToggleWidget(
                  sessionProvider: sessionProvider,
                  isTogglingStatus: _isTogglingStatus,
                  onToggle: () => _handleStatusToggle(sessionProvider),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpCenterScreen(),
                      ),
                    );
                  },
                  child: const CustomImageIcon(imagePath: AppImages.headPhone),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencySupportScreen(),
                      ),
                    );
                  },
                  child: const CustomImageIcon(imagePath: AppImages.bulb),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: colorScheme.surface,
                    radius: 18,
                    backgroundImage: deliveryBoy?.profileImageUrl != null
                        ? NetworkImage(deliveryBoy!.profileImageUrl!)
                        : const AssetImage(AppImages.profilePerson)
                            as ImageProvider,
                    child: deliveryBoy?.profileImageUrl == null
                        ? Text(
                            deliveryBoy?.name.isNotEmpty == true
                                ? deliveryBoy!.name[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),

          // CONTENT
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshEarnings,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paid History button (top-right above card)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PaymentHistoryScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('Paid History',
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Earnings Summary Card
                    _buildEarningsCard(colorScheme, weeklySummaryData),
                    const SizedBox(height: 16),

                    // Section Divider - Floating Cash
                    _buildSectionDivider(
                        languageProvider.getTranslatedText('floating_cash'),
                        colorScheme),
                    const SizedBox(height: 16),

                    // Total Orders & Floating Cash Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            weeklySummaryData != null
                                ? '${weeklySummaryData.statistics.totalOrders}'
                                : '0',
                            languageProvider.getTranslatedText('total_orders'),
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            weeklySummaryData != null
                                ? '₹${weeklySummaryData.summary.floatingCashPending}'
                                : '₹0',
                            languageProvider.getTranslatedText('floating_cash'),
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Deposit Button
                    _buildDepositButton(colorScheme, languageProvider),
                    const SizedBox(height: 16),

                    // Section Divider - Payout History
                    _buildSectionDivider(
                        languageProvider.getTranslatedText('payout_history'),
                        colorScheme),
                    const SizedBox(height: 16),

                    // Payout History Card
                    _buildPayoutCard(
                        colorScheme, weeklySummaryData, languageProvider),
                    const SizedBox(height: 16),

                    // Section Divider - Other
                    _buildSectionDivider(
                        languageProvider.getTranslatedText('other'),
                        colorScheme),
                    const SizedBox(height: 16),

                    // Multi-order & Deductions Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            weeklySummaryData != null
                                ? '₹${weeklySummaryData.summary.breakdown.multiOrderBonus}'
                                : '₹0',
                            languageProvider.getTranslatedText('multi_order'),
                            colorScheme,
                          ),
                        ),
                        // const SizedBox(width: 16),
                        // Expanded(
                        //   child: _buildStatCard(
                        //     '₹400',
                        //     languageProvider.getTranslatedText('deductions'),
                        //     colorScheme,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer Tips Card
                    _buildOtherCard(
                      languageProvider.getTranslatedText('customer_tips'),
                      colorScheme,
                      weeklySummaryData != null
                          ? '₹${weeklySummaryData.summary.breakdown.customerTips}'
                          : '₹0',
                    ),
                    const SizedBox(height: 16),

                    // Incentive Earnings Card
                    _buildOtherCard(
                      'Incentive Earnings',
                      colorScheme,
                      weeklySummaryData != null
                          ? '₹${weeklySummaryData.summary.breakdown.incentiveEarnings}'
                          : '₹0',
                    ),
                    const SizedBox(height: 16),

                    // Referral Bonus Card
                    _buildOtherCard(
                      'Referral Bonus',
                      colorScheme,
                      weeklySummaryData != null
                          ? '₹${weeklySummaryData.summary.breakdown.referralBonus}'
                          : '₹0',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get current GPS position
  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
            'Location permission permanently denied. Enable in settings.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to get location: ${e.toString()}');
      return null;
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: colorScheme.surface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final colorScheme = context.read<ThemeProvider>().colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: colorScheme.surface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String formatEarnings(double value) {
    return value.round().toString();
  }

  Widget _buildEarningsCard(
      AppColorScheme colorScheme, dynamic weeklySummaryData) {
    final languageProvider = context.read<LanguageProvider>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EarningsDetailScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: colorScheme.border,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    weeklySummaryData != null
                        ? '₹${formatEarnings(weeklySummaryData.summary.totalEarnings)}'
                        : '₹0',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.05,
                    ),
                  ),
                  Text(
                    languageProvider.getTranslatedText('earnings'),
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 2,
                      letterSpacing: -0.05,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    weeklySummaryData != null
                        ? weeklySummaryData.periodName
                        : '...',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.71,
                      letterSpacing: -0.05,
                    ),
                  ),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: colorScheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider(String title, AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: DashedLinePainter(color: colorScheme.border),
              child: const SizedBox(height: 1),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: colorScheme.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 2.40,
              letterSpacing: -0.05,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomPaint(
              painter: DashedLinePainter(color: colorScheme.border),
              child: const SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String amount, String label, AppColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (label ==
              context
                  .read<LanguageProvider>()
                  .getTranslatedText('total_orders')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderEarningsScreen(),
              ),
            );
          } else if (label ==
              context
                  .read<LanguageProvider>()
                  .getTranslatedText('floating_cash')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CashInHandScreen(),
              ),
            );
          } else if (label ==
              context
                  .read<LanguageProvider>()
                  .getTranslatedText('deductions')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DeductionsScreen(),
              ),
            );
          } else if (label ==
              context
                  .read<LanguageProvider>()
                  .getTranslatedText('multi_order')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MultiOrderEarningsScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: colorScheme.border,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.50,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 2,
                        letterSpacing: -0.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: colorScheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositButton(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransferScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: 48,
          decoration: ShapeDecoration(
            color: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Center(
            child: Text(
              languageProvider.getTranslatedText('deposit'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutCard(AppColorScheme colorScheme, dynamic weeklySummaryData,
      LanguageProvider languageProvider) {
    final payoutAmount = weeklySummaryData != null
        ? weeklySummaryData.summary.payoutDetails.totalPaidOut
        : 0;
    final periodName =
        weeklySummaryData != null ? weeklySummaryData.periodName : 'Loading...';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PayoutScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: colorScheme.border,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${languageProvider.getTranslatedText('payout')} $periodName',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 2,
                      letterSpacing: -0.05,
                    ),
                  ),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: colorScheme.textSecondary,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '₹$payoutAmount',
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.71,
                  letterSpacing: -0.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherCard(
      String label, AppColorScheme colorScheme, String amount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          String? sectionKey;
          String? sectionLabel;

          if (label ==
              context
                  .read<LanguageProvider>()
                  .getTranslatedText('customer_tips')) {
            sectionKey = 'customer_tips';
            sectionLabel = 'Customer tips';
          } else if (label == 'Incentive Earnings') {
            sectionKey = 'incentive';
            sectionLabel = 'Incentives';
          } else if (label == 'Referral Bonus') {
            sectionKey = 'referral';
            sectionLabel = 'Referral Bonus';
          }

          if (sectionKey != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PayoutSectionDetailScreen(
                  sectionKey: sectionKey!,
                  sectionLabel: sectionLabel!,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: colorScheme.border,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 2,
                      letterSpacing: -0.05,
                    ),
                  ),
                  Text(
                    amount,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.05,
                    ),
                  ),
                ],
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: colorScheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 5,
    this.dashSpace = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
