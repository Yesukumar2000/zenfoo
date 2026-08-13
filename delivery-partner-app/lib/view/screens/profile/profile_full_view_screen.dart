import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/delivery_boy_model.dart';
import 'package:zenfoo_partner/models/ratings_model.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/custom_page_routing.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/profile/all_reviews_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/bank_details_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/emergency_contacts_screen.dart';
import 'package:zenfoo_partner/view/screens/profile/id_card_screen.dart';

class ProfileFullViewScreen extends StatefulWidget {
  const ProfileFullViewScreen({super.key});

  @override
  State<ProfileFullViewScreen> createState() => _ProfileFullViewScreenState();
}

class _ProfileFullViewScreenState extends State<ProfileFullViewScreen> {
  final ApiService _apiService = ApiService();
  RatingsModel? _ratingsModel;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final response = await _apiService.getRatings(page: 1, perPage: 50);

    if (response.status == ApiStatus.success && response.data != null) {
      final data = response.data['data'];
      if (data != null) {
        setState(() {
          _ratingsModel = RatingsModel.fromJson(data);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final deliveryBoy = authProvider.currentDeliveryBoy;
    final languageProvider = context.watch<LanguageProvider>();

    // Tinted backdrop in light mode so the white cards stand out (iOS
    // grouped-list look); dark mode already has enough surface contrast.
    final pageBackground = themeProvider.isDarkMode
        ? colorScheme.background
        : colorScheme.surfaceContainer;

    return CustomScaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          // Header
          AppHeader(
            label: languageProvider.getTranslatedText('profile'),
            title: languageProvider.getTranslatedText('profile_details'),
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

                  // Profile Header Card
                  _buildProfileHeaderCard(colorScheme, deliveryBoy, context),

                  const SizedBox(height: 12),

                  // Work Details
                  _buildWorkDetailsCard(colorScheme, deliveryBoy, context),

                  const SizedBox(height: 12),

                  // Personal Details
                  _buildPersonalDetailsCard(colorScheme, deliveryBoy, context),

                  const SizedBox(height: 12),

                  // Documents Section
                  _buildDocumentsCard(context, colorScheme),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(
      AppColorScheme colorScheme, DeliveryBoy? deliveryBoy, BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.10),
            colorScheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image and Name
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image with Border
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 3,
                      color: colorScheme.primary,
                    ),
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: deliveryBoy?.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            deliveryBoy!.profileImageUrl!,
                            fit: BoxFit.cover,
                            width: 82,
                            height: 82,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  deliveryBoy.name.isNotEmpty
                                      ? deliveryBoy.name[0].toUpperCase()
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
                const SizedBox(width: 12),
                // Name and ID
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryBoy?.name.toUpperCase() ?? 'USER NAME',
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          height: 1.35,
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
                              'DP ID : ${deliveryBoy?.id ?? 'N/A'}',
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.15,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // Rating - Clickable to navigate to Ratings screen
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                context.navigateWithFadeScale(
                  AllReviewsScreen(initialRatings: _ratingsModel),
                );
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Star Icons with average rating value
                      Row(
                        children: [
                          // Stars
                          ...List.generate(
                            5,
                            (index) {
                              final rating = _ratingsModel?.averageRating ?? 0;
                              return Padding(
                                padding: EdgeInsets.only(right: index < 4 ? 4 : 0),
                                child: Icon(
                                  index < rating.floor()
                                      ? Icons.star
                                      : (index < rating
                                          ? Icons.star_half
                                          : Icons.star_border),
                                  color: colorScheme.warning,
                                  size: 18,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Average rating value
                          Text(
                            (_ratingsModel?.averageRating ?? 0).toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              color: colorScheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            languageProvider.getTranslatedText('rating'),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.15,
                              height: 1.4,
                            ),
                          ),
                          // Red notification dot
                          if (_ratingsModel != null && _ratingsModel!.reviews.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  // Arrow icon
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.textSecondary,
                    size: 24,
                  ),
                ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Joining Date and Delivery Category
          Row(
            children: [
              // Joining Date
              Expanded(
                child: Container(
                  height: 64,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.border.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        deliveryBoy?.createdAt != null &&
                                deliveryBoy!.createdAt.isNotEmpty
                            ? () {
                                try {
                                  final date =
                                      DateTime.parse(deliveryBoy.createdAt);
                                  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                } catch (e) {
                                  return 'N/A';
                                }
                              }()
                            : 'N/A',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageProvider.getTranslatedText('joining_date'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Delivery Category
              Expanded(
                child: Container(
                  height: 64,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.border.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        deliveryBoy?.ordersPriorityName ?? 'Both',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageProvider.getTranslatedText('delivery_category'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDetailsCard(
      AppColorScheme colorScheme, DeliveryBoy? deliveryBoy, BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.7),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              colorScheme, languageProvider.getTranslatedText('work_details')),
          const SizedBox(height: 4),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('store'),
            deliveryBoy?.storeLocations?.isNotEmpty == true
                ? deliveryBoy!.storeLocations![0].name
                : languageProvider.getTranslatedText('default_store'),
          ),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('zone'),
            'Madhapur',
          ),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('vehicle'),
            deliveryBoy?.vehicleName ?? 'Bike',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(
      AppColorScheme colorScheme, DeliveryBoy? deliveryBoy, BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.7),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(colorScheme,
              languageProvider.getTranslatedText('personal_details')),
          const SizedBox(height: 4),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('date_of_birth'),
            deliveryBoy?.dob ?? '',
          ),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('email_id'),
            deliveryBoy?.email ?? 'user@example.com',
          ),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('mobile_number'),
            deliveryBoy?.mobile ?? '9876543210',
          ),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('address'),
            deliveryBoy?.address ?? '9-134., Madhapur, Hyderabad',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AppColorScheme colorScheme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      AppColorScheme colorScheme, String label, String value,
      {bool showDivider = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label : ',
                style: GoogleFonts.inter(
                  color: colorScheme.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  height: 1.5,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.border.withValues(alpha: 0.2),
          ),
      ],
    );
  }

  Widget _buildDocumentsCard(BuildContext context, AppColorScheme colorScheme) {
    final languageProvider = context.read<LanguageProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.cardBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.7),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: colorScheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildDocumentItem(
            context,
            colorScheme,
            languageProvider.getTranslatedText('zenfoo_id_card'),
            'assets/images/pv1.png',
            onTap: () => context.navigateWithFadeScale(const IdCardScreen()),
          ),
          Divider(
            height: 16,
            thickness: 1,
            color: colorScheme.border.withValues(alpha: 0.2),
          ),
          _buildDocumentItem(
            context,
            colorScheme,
            languageProvider.getTranslatedText('emergency_details'),
            'assets/images/pv2.png',
            onTap: () => context.navigateWithFadeScale(const EmergencyContactsScreen()),
          ),
          Divider(
            height: 16,
            thickness: 1,
            color: colorScheme.border.withValues(alpha: 0.2),
          ),
          _buildDocumentItem(
            context,
            colorScheme,
            languageProvider.getTranslatedText('bank_details'),
            'assets/images/pv3.png',
            onTap: () => context.navigateWithFadeScale(const BankDetailsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(BuildContext context, AppColorScheme colorScheme,
      String title, dynamic icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          Row(
            children: [
              Image.asset(
                icon,
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.25,
                  height: 1.5,
                ),
              ),
            ],
          ),
          Transform.rotate(
            angle: -1.57,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(4)),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                color: colorScheme.textSecondary,
                size: 16,
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
