import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/banner_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/document_verification/screens/aadhar_screen.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/document_verification/screens/bank_detail_screen.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/document_verification/screens/driving_license_screen.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/document_verification/screens/pan_details_screen.dart';
import 'package:zenfoo_partner/view/screens/documents/screens/document_verification/screens/rc_detail_screen.dart';
import 'package:zenfoo_partner/view/screens/home/widgets/home_banner_carousel.dart';

class DocumentVerificationStep extends StatefulWidget {
  const DocumentVerificationStep({super.key});

  @override
  State<DocumentVerificationStep> createState() =>
      _DocumentVerificationStepState();
}

class _DocumentVerificationStepState extends State<DocumentVerificationStep> {
  void navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen))
        .then((_) => _refreshDocuments());
  }

  Future<void> _refreshDocuments() async {
    try {
      final docProvider = context.read<DocumentProvider>();
      await docProvider.fetchDocuments();
    } catch (e) {
      debugPrint('Error refreshing documents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Consumer<DocumentProvider>(
      builder: (context, docProvider, _) {
        debugPrint(
            '🎬 DocumentVerificationStep rendering - DL Status: ${docProvider.drivingLicenseStatus}, DL URL: ${docProvider.drivingLicenseFrontUrl}');

        return RefreshIndicator(
          onRefresh: _refreshDocuments,
          color: colorScheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                /// TITLE
                Text(
                  'Finish your verification to start working.',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 16),

                /// DYNAMIC BANNER CAROUSEL
                Consumer<BannerProvider>(
                  builder: (context, bannerProvider, _) {
                    if (bannerProvider.isLoading) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 140,
                          color: Colors.grey.shade300,
                        ),
                      );
                    }
                    if (bannerProvider.hasError || !bannerProvider.hasData) {
                      return const SizedBox.shrink();
                    }
                    return HomeBannerCarousel(banners: bannerProvider.banners);
                  },
                ),

                const SizedBox(height: 24),

                /// DOCUMENT LIST
                Column(
                  children: [
                    _documentTile(
                      context,
                      colorScheme: colorScheme,
                      title: 'Driving License',
                      subtitle: docProvider.drivingLicenseNumber != null &&
                              docProvider.drivingLicenseNumber!.isNotEmpty
                          ? docProvider.drivingLicenseNumber!
                          : 'Front side Photo & Back side Photo',
                      icon: Icons.credit_card_outlined,
                      isCompleted: docProvider.hasDrivingLicense ||
                          docProvider.drivingLicenseNumber != null ||
                          docProvider.drivingLicenseFrontUrl != null,
                      status: docProvider.drivingLicenseStatus,
                      hasLocalFile: docProvider.drivingLicenseFront != null,
                      onTap: () =>
                          navigate(context, const DrivingLicenseScreen()),
                    ),
                    _documentTile(
                      context,
                      colorScheme: colorScheme,
                      title: 'RC',
                      subtitle: docProvider.rcNumber != null &&
                              docProvider.rcNumber!.isNotEmpty
                          ? docProvider.rcNumber!
                          : 'Front side Photo & Back side Photo',
                      icon: Icons.description_outlined,
                      isCompleted: docProvider.hasRc ||
                          docProvider.rcNumber != null ||
                          docProvider.rcFrontUrl != null,
                      status: docProvider.rcStatus,
                      hasLocalFile: docProvider.rcFront != null,
                      onTap: () => navigate(context, const RcDetailsScreen()),
                    ),
                    _documentTile(
                      context,
                      colorScheme: colorScheme,
                      title: 'Aadhar Details',
                      subtitle: docProvider.aadharNumber != null &&
                              docProvider.aadharNumber!.isNotEmpty
                          ? 'XXXX XXXX ${docProvider.aadharNumber!.substring(docProvider.aadharNumber!.length > 4 ? docProvider.aadharNumber!.length - 4 : 0)}'
                          : 'Front side & Back side',
                      icon: Icons.badge_outlined,
                      isCompleted: docProvider.hasAadhar ||
                          docProvider.aadharNumber != null ||
                          docProvider.aadharFrontUrl != null,
                      status: docProvider.aadharStatus,
                      hasLocalFile: docProvider.aadharFront != null,
                      onTap: () =>
                          navigate(context, const AadhaarDetailsScreen()),
                    ),
                    _documentTile(
                      context,
                      colorScheme: colorScheme,
                      title: 'PAN Card',
                      subtitle: docProvider.panNumber != null &&
                              docProvider.panNumber!.isNotEmpty
                          ? docProvider.panNumber!
                          : 'Front side Photo & Back side Photo',
                      icon: Icons.credit_card,
                      isCompleted: docProvider.hasPan ||
                          docProvider.panNumber != null ||
                          docProvider.panFrontUrl != null,
                      status: docProvider.panStatus,
                      hasLocalFile: docProvider.panFront != null,
                      onTap: () => navigate(context, const PanDetailsScreen()),
                    ),
                    _documentTile(
                      context,
                      colorScheme: colorScheme,
                      title: 'Bank Details',
                      subtitle: docProvider.bankName != null &&
                              docProvider.bankName!.isNotEmpty
                          ? '${docProvider.bankName} - ${docProvider.accountNumber ?? ''}'
                          : 'Add your bank details to receive your payments.',
                      icon: Icons.account_balance_outlined,
                      isCompleted: docProvider.hasBankDetails ||
                          docProvider.bankName != null ||
                          docProvider.bankPassbookImageUrl != null,
                      status: docProvider.bankDetailsStatus,
                      hasLocalFile: docProvider.bankPassbookImage != null,
                      onTap: () => navigate(context, const BankDetailsScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  /// DOCUMENT TILE
  Widget _documentTile(
    BuildContext context, {
    required colorScheme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    String? status,
    bool hasLocalFile = false,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    final bool isReuploaded = status == 'rejected' && hasLocalFile;

    if (isReuploaded) {
      statusColor = const Color(0xFF3B82F6);
    } else if (status == 'verified') {
      statusColor = colorScheme.success;
    } else if (status == 'rejected') {
      statusColor = colorScheme.error;
    } else if (status == 'pending_verification') {
      statusColor = colorScheme.warning;
    } else if (isCompleted) {
      statusColor = colorScheme.primary;
    } else {
      statusColor = colorScheme.textSecondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              /// TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black45,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              /// STATUS LABEL
              if (status != null && status.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isReuploaded
                        ? 'Re-uploaded'
                        : status == 'verified'
                            ? 'Verified'
                            : status == 'rejected'
                                ? 'Rejected'
                                : status == 'pending_verification'
                                    ? 'Pending'
                                    : 'Uploaded',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],

              /// CHEVRON
              const Icon(
                Icons.chevron_right,
                color: Colors.black38,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
