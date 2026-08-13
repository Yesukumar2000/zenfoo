import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' as io;
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/models/delivery_boy_model.dart';
import 'package:zenfoo_partner/models/store_location_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/order_priority_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/custom_page_routing.dart';
import 'package:zenfoo_partner/view/screens/help_center/help_center_screen.dart';
import 'package:zenfoo_partner/widgets/shimmer_loading_widget.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/learning/learning_screen.dart';
import 'package:zenfoo_partner/view/screens/notifications/notifications_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/profile_full_view_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/gigs_history_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/all_offers_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/delete_account_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/referral_tracking_screen.dart';
import 'package:zenfoo_partner/view/screens/trip_history/trip_history_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/emergency_contacts_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/all_reviews_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/webview_screen.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _appVersion = 'Loading...';
  String _appBuild = 'Loading...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderPriority();
      _loadAppInfo();
    });
  }

  Future<void> _loadOrderPriority() async {
    final orderPriorityProvider = context.read<OrderPriorityProvider>();
    await orderPriorityProvider.fetchOrderPriority();
  }

  /// Load app version and build info from pubspec
  Future<void> _loadAppInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      if (mounted) {
        setState(() {
          // Version format: "1.0.5" from pubspec.yaml
          _appVersion = packageInfo.version;
          // Build number: "6" from pubspec.yaml (version: 1.0.5+6)
          _appBuild = packageInfo.buildNumber;
        });
      }

      debugPrint(
          'App Info Loaded: v${packageInfo.version}+${packageInfo.buildNumber}');
    } catch (e) {
      debugPrint('Error loading app info: $e');
      // Keep default values if loading fails
    }
  }

  /// Show image picker bottom sheet for profile image update
  void _showProfileImagePicker(
    BuildContext context,
    AppColorScheme colorScheme,
    AuthProvider authProvider,
  ) {
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: colorScheme,
      title: 'Update Profile Photo',
      onImageSelected: (file) async {
        await authProvider.updateProfileImage(imagePath: file.path);

        if (mounted) {
          if (authProvider.updateProfileImageState.status ==
              ApiStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile photo updated successfully'),
                backgroundColor: colorScheme.success,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (authProvider.updateProfileImageState.status ==
              ApiStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.updateProfileImageState.message ??
                    'Failed to update profile photo'),
                backgroundColor: colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      onPermissionDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Permission denied. Please allow camera/photo access in settings.'),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final deliveryBoy = authProvider.currentDeliveryBoy;

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Header
          AppHeader(
            label: languageProvider.getTranslatedText('settings'),
            title: languageProvider.getTranslatedText('profile_management'),
            showBackButton: true,
            showExitButton: false,
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Card
                  _buildProfileCard(
                      colorScheme, deliveryBoy, languageProvider, authProvider),

                  const SizedBox(height: 20),

                  // Quick Actions
                  _buildQuickActions(colorScheme),

                  const SizedBox(height: 20),

                  // Order Types Section
                  _buildOrderTypesSection(colorScheme),

                  const SizedBox(height: 20),

                  // Manage Section
                  _buildManageSection(colorScheme),

                  const SizedBox(height: 20),

                  // Other Information
                  _buildOtherInfoSection(colorScheme),

                  const SizedBox(height: 20),

                  // App Settings
                  _buildAppSettingsSection(
                      colorScheme, themeProvider, languageProvider),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AppColorScheme colorScheme, DeliveryBoy? deliveryBoy,
      LanguageProvider languageProvider, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile banner: image, name/ID, and view button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.10),
                  colorScheme.primary.withValues(alpha: 0.02),
                ],
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.20),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Profile Image with Edit Button
              GestureDetector(
                onTap: () =>
                    _showProfileImagePicker(context, colorScheme, authProvider),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: ShapeDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(57),
                        ),
                      ),
                      child: authProvider.updateProfileImageState.status ==
                              ApiStatus.loading
                          ? Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                            )
                          : deliveryBoy?.profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(57),
                                  child: Image.network(
                                    deliveryBoy!.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          deliveryBoy.name.isNotEmpty
                                              ? deliveryBoy.name[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.inter(
                                            color: colorScheme.primary,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    deliveryBoy?.name.isNotEmpty == true
                                        ? deliveryBoy!.name[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.inter(
                                      color: colorScheme.primary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                    ),
                    // Edit icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Name and ID
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryBoy?.name ?? 'User',
                      style: GoogleFonts.inter(
                        color: colorScheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.38,
                        letterSpacing: -0.18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: ShapeDecoration(
                        color: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: colorScheme.border.withValues(alpha: 0.4),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: colorScheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${deliveryBoy?.id ?? 'N/A'}',
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // View button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileFullViewScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: ShapeDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.10),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languageProvider.getTranslatedText('view'),
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colorScheme.primary,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Store location and button row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShapeDecoration(
              color: colorScheme.surfaceElevated,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: colorScheme.border.withValues(alpha: 0.15),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Store location
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedStore01,
                        color: colorScheme.textSecondary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (deliveryBoy?.storeLocations?.isNotEmpty ?? false)
                              ? deliveryBoy!.storeLocations![0].name
                                  .toUpperCase()
                              : languageProvider
                                  .getTranslatedText('default_store_location'),
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.46,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Go to Store button
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _openMapsToStore(deliveryBoy);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 34,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 21, vertical: 6),
                    decoration: ShapeDecoration(
                      color: colorScheme.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      shadows: [
                        BoxShadow(
                          color: colorScheme.success.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        languageProvider.getTranslatedText('go_to_store'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.instrumentSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppColorScheme colorScheme) {
    final languageProvider = context.read<LanguageProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: _buildQuickAction(
            colorScheme,
            languageProvider.getTranslatedText('gigs_history'),
            'assets/images/p1.png',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            colorScheme,
            languageProvider.getTranslatedText('trip_history'),
            'assets/images/p2.png',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            colorScheme,
            languageProvider.getTranslatedText('your_offers'),
            'assets/images/p3.png',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    AppColorScheme colorScheme,
    String label,
    String imagePath,
  ) {
    final languageProvider = context.read<LanguageProvider>();
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (label == languageProvider.getTranslatedText('gigs_history')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GigsHistoryScreen(),
            ),
          );
        } else if (label == languageProvider.getTranslatedText('your_offers')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AllOffersScreen(),
            ),
          );
        } else if (label ==
            languageProvider.getTranslatedText('trip_history')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TripHistoryScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        // minHeight (not a fixed height) so taller scripts like Telugu/Urdu
        // can grow the card a couple px instead of overflowing.
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: ShapeDecoration(
          color: colorScheme.cardBackground,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: colorScheme.border.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: colorScheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 12,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(
              width: 84.67,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                  letterSpacing: -0.12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypesSection(AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          SizedBox(
            width: double.infinity,
            child: Text(
              context
                  .read<LanguageProvider>()
                  .getTranslatedText('choose_order_type'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.50,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Order type options
          _buildOrderTypeOptions(context, colorScheme),

          const SizedBox(height: 8),

          // Pickup point locations
          // InkWell(
          //   onTap: () {
          //     HapticFeedback.lightImpact();
          //     // Navigate to pickup locations
          //   },
          //   borderRadius: BorderRadius.circular(12),
          //   child: Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          //     decoration: ShapeDecoration(
          //       color: colorScheme.surfaceElevated,
          //       shape: RoundedRectangleBorder(
          //         side: BorderSide(
          //           color: colorScheme.border.withValues(alpha: 0.15),
          //         ),
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       crossAxisAlignment: CrossAxisAlignment.center,
          //       children: [
          //         Row(
          //           mainAxisSize: MainAxisSize.min,
          //           mainAxisAlignment: MainAxisAlignment.start,
          //           crossAxisAlignment: CrossAxisAlignment.center,
          //           children: [
          //             HugeIcon(
          //               icon: HugeIcons.strokeRoundedLocation01,
          //               color: colorScheme.textPrimary,
          //               size: 24,
          //             ),
          //             const SizedBox(width: 8),
          //             Text(
          //               context
          //                   .read<LanguageProvider>()
          //                   .getTranslatedText('pickup_point_locations'),
          //               style: GoogleFonts.inter(
          //                 color: colorScheme.textPrimary,
          //                 fontSize: 12,
          //                 fontWeight: FontWeight.w500,
          //                 height: 1.33,
          //                 letterSpacing: -0.12,
          //               ),
          //             ),
          //           ],
          //         ),
          //         Transform.rotate(
          //           angle: -1.57,
          //           child: HugeIcon(
          //             icon: HugeIcons.strokeRoundedArrowDown01,
          //             color: colorScheme.textSecondary,
          //             size: 24,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  /// Build order type options from API
  Widget _buildOrderTypeOptions(
      BuildContext context, AppColorScheme colorScheme) {
    final orderPriorityProvider = context.watch<OrderPriorityProvider>();
    final isLoading = orderPriorityProvider.isLoading;
    final priorityOptions = orderPriorityProvider.priorityOptions;
    final currentPriority = orderPriorityProvider.currentPriority;

    if (isLoading) {
      return ShimmerLoadingWidget(
        colorScheme: colorScheme,
        itemCount: 3,
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 0),
      );
    }

    if (priorityOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Map icons for each option
    dynamic getIconForValue(int value) {
      switch (value) {
        case 0:
          return HugeIcons.strokeRoundedShoppingBag02; // Both
        case 1:
          return HugeIcons.strokeRoundedServingFood; // Food + Grocery
        case 2:
          return HugeIcons.strokeRoundedPackage02; // Multi Orders
        default:
          return HugeIcons.strokeRoundedShoppingBag02;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: priorityOptions.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isLast = index == priorityOptions.length - 1;

        return Column(
          children: [
            _buildOrderTypeOption(
              colorScheme,
              option.label,
              option.description,
              getIconForValue(option.value),
              currentPriority == option.value,
              highlightNote: option.value == 2
                  ? '(you get more money from multi order)'
                  : null,
              () async {
                HapticFeedback.lightImpact();
                final success = await orderPriorityProvider
                    .updateOrderPriority(option.value);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order priority updated to ${option.label}',
                        style: GoogleFonts.inter(
                          color: colorScheme.surface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: colorScheme.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            if (!isLast) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignCenter,
                      color: colorScheme.border.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildOrderTypeOption(
    AppColorScheme colorScheme,
    String title,
    String subtitle,
    dynamic icon,
    bool isSelected,
    VoidCallback onTap, {
    String? highlightNote,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    HugeIcon(
                      icon: icon,
                      color: colorScheme.textPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    // Text content
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.43,
                                  letterSpacing: -0.16,
                                ),
                              ),
                              if (highlightNote != null)
                                Text(
                                  highlightNote,
                                  style: GoogleFonts.inter(
                                    color: colorScheme.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.43,
                                    letterSpacing: -0.16,
                                  ),
                                ),
                            ],
                          ),
                          // const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Radio button with tickmark
              Container(
                width: 28,
                height: 28,
                decoration: ShapeDecoration(
                  color: isSelected
                      ? colorScheme.success
                      : colorScheme.border.withValues(alpha: 0.3),
                  shape: OvalBorder(
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.success
                          : colorScheme.border.withValues(alpha: 0.5),
                      width: isSelected ? 0 : 1.5,
                    ),
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageSection(AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              context.read<LanguageProvider>().getTranslatedText('manage'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.38,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListItemWithDivider(
                colorScheme,
                context
                    .read<LanguageProvider>()
                    .getTranslatedText('notifications'),
                HugeIcons.strokeRoundedNotification02,
                onTap: () {
                  context.navigateWithFadeScale(const NotificationsScreen());
                },
              ),
              const SizedBox(height: 12),
              _buildListItemWithDivider(
                colorScheme,
                context
                    .read<LanguageProvider>()
                    .getTranslatedText('learning_center'),
                HugeIcons.strokeRoundedPlayCircle,
                onTap: () {
                  context.navigateWithFadeScale(const LearningScreen());
                },
              ),
              const SizedBox(height: 12),
              _buildListItemWithDivider(
                colorScheme,
                context
                    .read<LanguageProvider>()
                    .getTranslatedText('emergency_contacts'),
                HugeIcons.strokeRoundedCall,
                onTap: () {
                  context
                      .navigateWithFadeScale(const EmergencyContactsScreen());
                },
              ),
              const SizedBox(height: 12),
              _buildListItemWithDivider(
                colorScheme,
                'Ratings',
                HugeIcons.strokeRoundedStar,
                onTap: () {
                  context.navigateWithFadeScale(const AllReviewsScreen());
                },
              ),
              const SizedBox(height: 12),
              _buildListItemWithDivider(
                colorScheme,
                'Referral Tracking',
                HugeIcons.strokeRoundedUserGroup,
                onTap: () {
                  context.navigateWithFadeScale(const ReferralTrackingScreen());
                },
              ),
              const SizedBox(height: 12),
              _buildListItem(
                  colorScheme,
                  context
                      .read<LanguageProvider>()
                      .getTranslatedText('help_center'),
                  HugeIcons.strokeRoundedHelpCircle, onTap: () {
                context.navigateWithFadeScale(const HelpCenterScreen());
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherInfoSection(AppColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              context
                  .read<LanguageProvider>()
                  .getTranslatedText('other_information'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.38,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListItemWithDivider(
                colorScheme,
                context
                    .read<LanguageProvider>()
                    .getTranslatedText('terms_of_service'),
                HugeIcons.strokeRoundedFile02,
                onTap: () {
                  context.navigateWithFadeScale(
                    WebViewScreen(
                      title: context
                          .read<LanguageProvider>()
                          .getTranslatedText('terms_of_service'),
                      apiEndpoint: '/delivery-boy-terms-conditions',
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildListItem(
                colorScheme,
                context
                    .read<LanguageProvider>()
                    .getTranslatedText('privacy_policy'),
                HugeIcons.strokeRoundedShieldUser,
                onTap: () {
                  context.navigateWithFadeScale(
                    WebViewScreen(
                      title: context
                          .read<LanguageProvider>()
                          .getTranslatedText('privacy_policy'),
                      apiEndpoint: '/delivery-boy-privacy-policy',
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection(AppColorScheme colorScheme,
      ThemeProvider themeProvider, LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              languageProvider.getTranslatedText('app_settings'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.38,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dark mode toggle commented out for now — app stays in Light mode.
              // _buildListItemWithDivider(
              //   colorScheme,
              //   languageProvider.getTranslatedText('dark_theme'),
              //   HugeIcons.strokeRoundedDarkMode,
              //   trailing: Switch(
              //     value: themeProvider.isDarkMode,
              //     onChanged: (value) {
              //       themeProvider.toggleTheme();
              //     },
              //     activeTrackColor: colorScheme.primary,
              //   ),
              // ),
              // const SizedBox(height: 12),
              // Appearance (theme) — hidden
              // _buildListItemWithDivider(
              //   colorScheme,
              //   'Appearance',
              //   HugeIcons.strokeRoundedPaintBoard,
              //   onTap: () => _showAppearanceBottomSheet(colorScheme),
              // ),
              // const SizedBox(height: 12),
              _buildListItemWithDivider(
                colorScheme,
                languageProvider.getTranslatedText('app_language'),
                HugeIcons.strokeRoundedTranslate,
                onTap: () => _showLanguageBottomSheet(colorScheme),
              ),
              const SizedBox(height: 12),
              _buildListItemWithDivider(
                colorScheme,
                languageProvider.getTranslatedText('share_the_app'),
                HugeIcons.strokeRoundedShare03,
                onTap: _shareApp,
              ),
              const SizedBox(height: 12),
              _buildListItemWithDivider(
                colorScheme,
                languageProvider.getTranslatedText('about_us'),
                HugeIcons.strokeRoundedInformationCircle,
                onTap: () =>
                    _showAboutBottomSheet(colorScheme, languageProvider),
              ),
              const SizedBox(height: 12),
              _buildDeleteAccountItem(colorScheme, languageProvider),
              const SizedBox(height: 12),
              _buildLogoutItem(colorScheme, languageProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountItem(
    AppColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeleteAccountScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    languageProvider.getTranslatedText('delete_account'),
                    style: GoogleFonts.inter(
                      color: colorScheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(
    AppColorScheme colorScheme,
    String title,
    dynamic icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return _buildListItemWithLoading(
      title: title,
      icon: icon,
      colorScheme: colorScheme,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildListItemWithDivider(
    AppColorScheme colorScheme,
    String title,
    dynamic icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListItem(
          colorScheme,
          title,
          icon,
          trailing: trailing,
          onTap: onTap,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 1,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                strokeAlign: BorderSide.strokeAlignCenter,
                color: colorScheme.border,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutItem(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showLogoutBottomSheet(colorScheme, languageProvider);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedLogout01,
                    color: colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context
                        .read<LanguageProvider>()
                        .getTranslatedText('log_out'),
                    style: GoogleFonts.inter(
                      color: colorScheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                    ),
                  ),
                ],
              ),
              Transform.rotate(
                angle: -1.57,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: colorScheme.error,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Clear all provider states and cached data
  Future<void> _clearAllStates() async {
    try {
      // Get references to providers before clearing
      final authProvider = context.read<AuthProvider>();
      final sessionProvider = context.read<SessionProvider>();
      final documentProvider = context.read<DocumentProvider>();

      // Clear Auth Provider (user data, tokens, shared preferences)
      await authProvider.clearUserData();

      if (!mounted) return;

      // Clear Session Provider (timers, active session, stats)
      sessionProvider.resetStates();

      // Clear Document Provider (uploaded documents, images)
      documentProvider.clearAll();

      debugPrint('✅ All provider states and caches cleared');
    } catch (e) {
      debugPrint('❌ Error clearing states: $e');
    }
  }

  void _showLogoutBottomSheet(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout01,
                  color: colorScheme.error,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              languageProvider.getTranslatedText('logout'),
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.55,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              languageProvider.getTranslatedText('logout_confirmation'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.25,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();

                // Close bottom sheet first
                Navigator.pop(context);

                // Small delay to ensure bottom sheet is fully closed
                await Future.delayed(const Duration(milliseconds: 100));

                // Clear all provider states and caches
                await _clearAllStates();

                // Navigate to login screen using go_router
                if (mounted) {
                  context.go(AppRouterName.login);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.error.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  languageProvider.getTranslatedText('yes_logout'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  languageProvider.getTranslatedText('cancel'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Share the Zenfoo app with other apps
  void _shareApp() {
    HapticFeedback.lightImpact();
    try {
      Share.share(
        'Download Zenfoo Partner App - Earn money by delivering orders!\n\n'
        'Join thousands of delivery partners and start earning.\n\n'
        'Download from: https://play.google.com/store/apps/details?id=com.zenfoo.partner\n\n'
        'Get started today!',
        subject: 'Check out Zenfoo Partner App',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
    }
  }

  /// Show About Us bottom sheet with app details (dynamic from API)
  void _showAboutBottomSheet(
      AppColorScheme colorScheme, LanguageProvider languageProvider) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AboutUsBottomSheet(
        colorScheme: colorScheme,
        languageProvider: languageProvider,
        appVersion: _appVersion,
        appBuild: _appBuild,
      ),
    );
  }

  /// Build a row for about info display
  Widget _buildAboutInfoRow(
    String label,
    String value,
    AppColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.25,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }

  /// Build feature item with icon
  Widget _buildFeatureItem(String feature, AppColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              color: colorScheme.primary,
              size: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            feature,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.25,
            ),
          ),
        ),
      ],
    );
  }

  /// Show language selection bottom sheet
  /// Appearance (theme) selector.
  /// Only Light is selectable for now — System and Dark are commented out,
  /// matching the customer and vendor apps.
  // ignore: unused_element
  void _showAppearanceBottomSheet(AppColorScheme colorScheme) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Choose Theme',
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.55,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select your preferred appearance',
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Theme options — only Light for now.
                  // _buildThemeOptionTile(
                  //   colorScheme,
                  //   themeProvider,
                  //   mode: ThemeMode.system,
                  //   title: 'System',
                  //   subtitle: 'Follow system settings',
                  //   icon: HugeIcons.strokeRoundedComputer,
                  // ),
                  // const SizedBox(height: 12),
                  _buildThemeOptionTile(
                    colorScheme,
                    themeProvider,
                    mode: ThemeMode.light,
                    title: 'Light',
                    subtitle: 'Light appearance',
                    icon: HugeIcons.strokeRoundedSun01,
                  ),
                  // const SizedBox(height: 12),
                  // _buildThemeOptionTile(
                  //   colorScheme,
                  //   themeProvider,
                  //   mode: ThemeMode.dark,
                  //   title: 'Dark',
                  //   subtitle: 'Dark appearance',
                  //   icon: HugeIcons.strokeRoundedMoon02,
                  // ),

                  const SizedBox(height: 20),

                  // Close Button
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary),
                      ),
                      child: Text(
                        context
                            .read<LanguageProvider>()
                            .getTranslatedText('close'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// A single selectable theme option row for the appearance sheet.
  Widget _buildThemeOptionTile(
    AppColorScheme colorScheme,
    ThemeProvider themeProvider, {
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required dynamic icon,
  }) {
    final isSelected = themeProvider.themeMode == mode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.border),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: isSelected ? Colors.white : colorScheme.iconSecondary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(AppColorScheme colorScheme) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: colorScheme.cardBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                )),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    languageProvider.getTranslatedText('select_language'),
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.55,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Loading state
                  if (languageProvider.languageState == LanguageState.loading)
                    Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  // Error state
                  else if (languageProvider.languageState ==
                      LanguageState.error)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.border),
                      ),
                      child: Text(
                        languageProvider
                            .getTranslatedText('failed_load_languages'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  // Languages list
                  else if (languageProvider.languages.isNotEmpty)
                    Column(
                      children: List.generate(
                        languageProvider.languages.length,
                        (index) {
                          final language = languageProvider.languages[index];
                          final isSelected =
                              languageProvider.selectedLanguageId ==
                                  language.id;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              languageProvider
                                  .changeLanguage(language.id.toString());
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.1)
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            language.name,
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            language.code,
                                            style: GoogleFonts.inter(
                                              color: colorScheme.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: HugeIcon(
                                            icon: HugeIcons
                                                .strokeRoundedCheckmarkCircle01,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        languageProvider
                            .getTranslatedText('no_languages_available'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Close Button
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary),
                      ),
                      child: Text(
                        languageProvider.getTranslatedText('close'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Open store selection dialog and navigate to Google Maps
  Future<void> _openMapsToStore(DeliveryBoy? deliveryBoy) async {
    if (deliveryBoy == null ||
        deliveryBoy.storeLocations == null ||
        deliveryBoy.storeLocations!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<LanguageProvider>().getTranslatedText('no_data')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final storeLocations = deliveryBoy.storeLocations!;
    final languageProvider = context.read<LanguageProvider>();

    // If only one store, navigate directly
    if (storeLocations.length == 1) {
      _navigateToStore(storeLocations[0]);
      return;
    }

    // Show store selection dialog if multiple stores
    if (mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final colorScheme = Theme.of(context).extension<AppColorScheme>();

          return Container(
            decoration: BoxDecoration(
              color: colorScheme?.surfaceElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('choose_order_type'),
                        style: GoogleFonts.inter(
                          color: colorScheme?.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageProvider
                            .getTranslatedText('pickup_point_locations'),
                        style: GoogleFonts.inter(
                          color: colorScheme?.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Store list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: storeLocations.length,
                    itemBuilder: (context, index) {
                      final store = storeLocations[index];
                      final hasCoordinates =
                          store.latitude != null && store.longitude != null;

                      return InkWell(
                        onTap: hasCoordinates
                            ? () {
                                Navigator.pop(context);
                                _navigateToStore(store);
                              }
                            : null,
                        child: Container(
                          color: hasCoordinates
                              ? Colors.transparent
                              : colorScheme?.surfaceElevated
                                  .withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colorScheme?.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedStore01,
                                    color: colorScheme?.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      style: GoogleFonts.inter(
                                        color: colorScheme?.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      store.address ?? 'No address available',
                                      style: GoogleFonts.inter(
                                        color: colorScheme?.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (hasCoordinates)
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colorScheme?.success
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: colorScheme?.success,
                                      size: 18,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: colorScheme?.error
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedAlertCircle,
                                      color: colorScheme?.error,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }
  }

  /// Navigate to store location in Google Maps
  Future<void> _navigateToStore(StoreLocation store) async {
    final latitude = double.tryParse(store.latitude.toString());
    final longitude = double.tryParse(store.longitude.toString());

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<LanguageProvider>().getTranslatedText('no_data')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      Uri mapsUrl;

      // iOS: Use Apple Maps
      if (io.Platform.isIOS) {
        mapsUrl = Uri.parse(
          'maps://maps.apple.com/?q=$latitude,$longitude&ll=$latitude,$longitude',
        );
      }
      // Android & others: Use Google Maps
      else {
        mapsUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );
      }

      if (await canLaunchUrl(mapsUrl)) {
        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Google Maps web URL if native app not available
        final googleMapsUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context
                    .read<LanguageProvider>()
                    .getTranslatedText('error')),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                context.read<LanguageProvider>().getTranslatedText('error')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Widget for list item with loading state and animated arrow
  Widget _buildListItemWithLoading({
    required String title,
    required dynamic icon,
    required AppColorScheme colorScheme,
    required Widget? trailing,
    required VoidCallback? onTap,
  }) {
    return _ListItemLoadingWidget(
      title: title,
      icon: icon,
      colorScheme: colorScheme,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Stateful widget for list item with loading animation
class _ListItemLoadingWidget extends StatefulWidget {
  final String title;
  final dynamic icon;
  final AppColorScheme colorScheme;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ListItemLoadingWidget({
    required this.title,
    required this.icon,
    required this.colorScheme,
    required this.trailing,
    required this.onTap,
  });

  @override
  State<_ListItemLoadingWidget> createState() => _ListItemLoadingWidgetState();
}

class _ListItemLoadingWidgetState extends State<_ListItemLoadingWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading || widget.onTap == null) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    _rotationController.repeat();

    try {
      await Future.microtask(() => widget.onTap!());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : _handleTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: widget.icon,
                    color: _isLoading
                        ? widget.colorScheme.textSecondary
                        : widget.colorScheme.textPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Hero(
                    tag: widget.title,
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: _isLoading
                            ? widget.colorScheme.textSecondary
                            : widget.colorScheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                  ),
                ],
              ),
              widget.trailing ??
                  Hero(
                    tag: 'arrow_${widget.title}',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: widget.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isLoading
                          ? RotationTransition(
                              turns: _rotationController,
                              child: Transform.rotate(
                                angle: -1.57,
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowDown01,
                                  color: widget.colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                            )
                          : Transform.rotate(
                              angle: -1.57,
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowDown01,
                                color: widget.colorScheme.textSecondary,
                                size: 18,
                              ),
                            ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// About Us Bottom Sheet Widget with dynamic API content
class _AboutUsBottomSheet extends StatefulWidget {
  final AppColorScheme colorScheme;
  final LanguageProvider languageProvider;
  final String appVersion;
  final String appBuild;

  const _AboutUsBottomSheet({
    required this.colorScheme,
    required this.languageProvider,
    required this.appVersion,
    required this.appBuild,
  });

  @override
  State<_AboutUsBottomSheet> createState() => _AboutUsBottomSheetState();
}

class _AboutUsBottomSheetState extends State<_AboutUsBottomSheet> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _aboutContent = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAboutUs();
  }

  Future<void> _fetchAboutUs() async {
    try {
      final response = await _apiService.get(
        AppUrl.aboutUs,
        isToast: false,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.data != null) {
            // Handle different response formats
            if (response.data is String) {
              _aboutContent = _stripHtmlTags(response.data);
            } else if (response.data is Map &&
                response.data['content'] != null) {
              _aboutContent =
                  _stripHtmlTags(response.data['content'].toString());
            } else if (response.data is Map && response.data['data'] != null) {
              _aboutContent = _stripHtmlTags(response.data['data'].toString());
            } else {
              _aboutContent = _stripHtmlTags(response.data.toString());
            }
          } else {
            _errorMessage = 'Failed to load content';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load about us content';
        });
      }
      debugPrint('Error fetching about us: $e');
    }
  }

  /// Strip HTML tags from content
  String _stripHtmlTags(String htmlContent) {
    // Remove HTML tags
    final RegExp htmlTagRegExp = RegExp(r'<[^>]*>', multiLine: true);
    String result = htmlContent.replaceAll(htmlTagRegExp, '');

    // Decode HTML entities
    result = result
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"');

    // Clean up extra whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.colorScheme.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: widget.colorScheme.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              widget.languageProvider.getTranslatedText('app_about'),
              style: GoogleFonts.inter(
                color: widget.colorScheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.55,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 20),

            // App Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.colorScheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAboutInfoRow(
                    widget.languageProvider.getTranslatedText('app_name'),
                    'Zenfoo Partner',
                  ),
                  const SizedBox(height: 12),
                  _buildAboutInfoRow(
                    widget.languageProvider.getTranslatedText('version'),
                    widget.appVersion,
                  ),
                  const SizedBox(height: 12),
                  _buildAboutInfoRow(
                    widget.languageProvider.getTranslatedText('build'),
                    widget.appBuild,
                  ),
                  const SizedBox(height: 12),
                  _buildAboutInfoRow(
                    widget.languageProvider.getTranslatedText('developer'),
                    'Zenfoo Products Pvt. Ltd.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // About Us Content Section
            Text(
              widget.languageProvider.getTranslatedText('about_section_title'),
              style: GoogleFonts.inter(
                color: widget.colorScheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 8),

            // Dynamic Content from API
            if (_isLoading)
              _buildLoadingState()
            else if (_errorMessage != null)
              _buildErrorState()
            else
              Text(
                _aboutContent,
                style: GoogleFonts.inter(
                  color: widget.colorScheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.25,
                  height: 1.5,
                ),
              ),

            const SizedBox(height: 20),

            // Close Button
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.languageProvider.getTranslatedText('got_it'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: widget.colorScheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.25,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: widget.colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(widget.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: widget.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Failed to load content',
              style: GoogleFonts.inter(
                color: widget.colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: widget.colorScheme.error,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchAboutUs();
            },
          ),
        ],
      ),
    );
  }
}
