import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/repository/emergency_contact_repository.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/utils/app_images.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

class IdCardScreen extends StatefulWidget {
  const IdCardScreen({super.key});

  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen> {
  String? _emergencyContact;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  Future<void> _loadEmergencyContact() async {
    try {
      final repository = EmergencyContactRepository();
      final response = await repository.getEmergencyContacts();

      if (response.data != null) {
        final data = response.data;
        if (data['status'] == 1 && data['data'] != null) {
          final List<dynamic> contacts = data['data'];
          if (contacts.isNotEmpty) {
            setState(() {
              _emergencyContact = contacts[0]['mobile_number'];
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading emergency contact: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final deliveryBoy = authProvider.currentDeliveryBoy;

    if (deliveryBoy == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Text(
            'No user data available',
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppHeader(
              label: 'Profile',
              title: 'ID Card',
              showBackButton: true,
            ),
            // ID Card with Background
            Container(
              width: MediaQuery.of(context).size.width - 48,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                image: DecorationImage(
                  image: AssetImage(AppImages.idBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    // Company Logo/Name
                    Text(
                      'ZENFOO',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Profile Photo
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: deliveryBoy.profileImageUrl != null &&
                                deliveryBoy.profileImageUrl!.isNotEmpty
                            ? Image.network(
                                deliveryBoy.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(
                                        deliveryBoy.name, Colors.black),
                              )
                            : _buildDefaultAvatar(
                                deliveryBoy.name, Colors.black),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name
                    Text(
                      deliveryBoy.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // DP ID
                    Text(
                      'DP ID : ${deliveryBoy.id}',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Details Section (White Background)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Work Location :',
                    deliveryBoy.cityName,
                    colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    'Mobile number :',
                    deliveryBoy.mobile,
                    colorScheme,
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    'Emergency No :',
                    _isLoading ? 'Loading...' : (_emergencyContact ?? '-'),
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name, Color textColor) {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 80,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
