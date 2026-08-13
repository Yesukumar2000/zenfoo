import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenfoo_partner/models/emergency_support_model.dart';
import 'package:zenfoo_partner/providers/emergency_support_provider.dart';
import 'package:zenfoo_partner/theme/app_color_scheme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/screens/profile/emergency_contacts_screen.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencySupportProvider>().fetchEmergencyContacts();
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make calls on this device'),
              duration: const Duration(seconds: 2),
              backgroundColor: context.read<ThemeProvider>().colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: context.read<ThemeProvider>().colorScheme.error,
          ),
        );
      }
    }
  }

  /// Get phone number for a static call option from API contacts
  String? _getPhoneForType(
      List<EmergencySupportContact> contacts, String type) {
    for (final contact in contacts) {
      final name = contact.name.toLowerCase();
      if (name.contains(type)) return contact.phone;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();
    final emergencyProvider = context.watch<EmergencySupportProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Top red section with gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A0000),
                  Color(0xFF8B0000),
                  Color(0xFF5C0000),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Emergency support image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/emergency_support.png',
                        width: 64,
                        height: 64,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    languageProvider
                        .getTranslatedText('do_you_need_emergency_support'),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      languageProvider
                          .getTranslatedText('choose_this_option_if_emergency'),
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // Bottom white section
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                transform: Matrix4.translationValues(0, -20, 0),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Call Section
                      Text(
                        languageProvider.getTranslatedText('quick_call'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCallOption(
                        title: 'Call to Zenfoo SUPPORT',
                        imagePath: 'assets/images/zenfoo_support.png',
                        colorScheme: colorScheme,
                        onCall: () {
                          final phone = _getPhoneForType(
                              emergencyProvider.emergencyContacts, 'support');
                          if (phone != null) _makeCall(phone);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildCallOption(
                        title: 'Call to Police',
                        imagePath: 'assets/images/call_police.png',
                        colorScheme: colorScheme,
                        onCall: () {
                          final phone = _getPhoneForType(
                              emergencyProvider.emergencyContacts, 'police');
                          if (phone != null) {
                            _makeCall(phone);
                          } else {
                            _makeCall('100');
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildCallOption(
                        title: 'Call to Ambulance',
                        imagePath: 'assets/images/ambulance.png',
                        colorScheme: colorScheme,
                        onCall: () {
                          final phone = _getPhoneForType(
                              emergencyProvider.emergencyContacts, 'ambulance');
                          if (phone != null) {
                            _makeCall(phone);
                          } else {
                            _makeCall('108');
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // Bottom cards - Emergency contacts & Insurance Details
                      Row(
                        children: [
                          Expanded(
                            child: _buildBottomCard(
                              colorScheme: colorScheme,
                              title: 'Emergency\ncontacts',
                              imagePath: 'assets/images/emergency_contact.png',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EmergencyContactsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBottomCard(
                              colorScheme: colorScheme,
                              title: 'Insurance\nDetails',
                              imagePath: 'assets/images/insurance_details.png',
                              onTap: () {
                                HapticFeedback.lightImpact();
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallOption({
    required String title,
    required String imagePath,
    required AppColorScheme colorScheme,
    required VoidCallback onCall,
  }) {
    return GestureDetector(
      onTap: onCall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.border.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Image.asset(
              imagePath,
              width: 52,
              height: 52,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard({
    required AppColorScheme colorScheme,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.border.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Image.asset(
              imagePath,
              width: 44,
              height: 44,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCall,
                      color: colorScheme.textSecondary,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
