import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedReason;
  bool _isLoading = false;

  final List<String> reasons = [
    'Not satisfied with service',
    'Found alternative application',
    'Privacy concerns',
    'Too many notifications',
    'Account security issues',
    'Other',
  ];

  /// Clear all provider states and logout
  Future<void> _clearAllStates() async {
    try {
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

      debugPrint('✅ All provider states cleared for account deletion');
    } catch (e) {
      debugPrint('❌ Error clearing states: $e');
    }
  }

  Future<void> _handleDeleteRequest() async {
    if (_selectedReason == null) {
      final languageProvider = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider.getTranslatedText('select_reason')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the API with selected reason
      final response = await _apiService.deleteAccount(reason: _selectedReason!);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.status == ApiStatus.success) {
        // Clear all states and logout
        await _clearAllStates();

        // Navigate to login screen using go_router
        if (mounted) {
          context.go(AppRouterName.login);
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to submit request'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context){
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            AppHeader(
              label: languageProvider.getTranslatedText('profile'),
              title: languageProvider.getTranslatedText('delete_account'),
              onBackPressed: () => Navigator.pop(context),
              showBackButton: true,
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  // Reason Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Text(
                        languageProvider
                            .getTranslatedText('why_delete_account'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      Column(
                        spacing: 10,
                        children: reasons.map((reason) {
                          final isSelected = _selectedReason == reason;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedReason = reason;
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFFEF4444)
                                        : colorScheme.border
                                            .withValues(alpha: 0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: ShapeDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEF4444)
                                          : Colors.transparent,
                                      shape: const OvalBorder(),
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: GoogleFonts.inter(
                                        color: colorScheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.43,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  // Submit Button
                  CustomButton(
                    text: _isLoading
                        ? 'Submitting...'
                        : languageProvider.getTranslatedText('submit_delete_request'),
                    onPressed: _isLoading ? null : _handleDeleteRequest,
                    backgroundColor: const Color(0xFFEF4444),
                    borderRadius: 12,
                    height: 52,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}