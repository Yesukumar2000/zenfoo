import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/providers/payout_issues_provider.dart';
import 'package:zenfoo_partner/services/status.dart';

import '../../custom_widgets/request_sent.dart';

class JoiningBonusIssueScreen extends StatefulWidget {
  const JoiningBonusIssueScreen({super.key});

  @override
  State<JoiningBonusIssueScreen> createState() =>
      _JoiningBonusIssueScreenState();
}

class _JoiningBonusIssueScreenState extends State<JoiningBonusIssueScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          // Header
          AppHeader(
            label: languageProvider.getTranslatedText('payout_issues'),
            title: languageProvider.getTranslatedText('joining_bonus_issue'),
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('description'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.71,
                          letterSpacing: -0.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: ShapeDecoration(
                          color: colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: colorScheme.border.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: languageProvider.getTranslatedText(
                                'tell_us_about_joining_bonus_issue'),
                            hintStyle: GoogleFonts.inter(
                              color: colorScheme.inputPlaceholder,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.05,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<PayoutIssuesProvider>(
              builder: (context, provider, child) {
                final isLoading =
                    provider.joiningBonusState.status == ApiStatus.loading;
                return CustomButton(
                  text: languageProvider.getTranslatedText('send_enquiry'),
                  onPressed: isLoading ? null : _handleSubmit,
                  isLoading: isLoading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (_descriptionController.text.trim().isEmpty) {
      final languageProvider = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              languageProvider.getTranslatedText('please_describe_your_issue')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final provider = context.read<PayoutIssuesProvider>();
    provider
        .joiningBonus(description: _descriptionController.text.trim())
        .then((_) {
      if (mounted) {
        if (provider.joiningBonusState.status == ApiStatus.success) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              fullscreenDialog: false,
              builder: (context) => const RequestSent(popTwice: true),
            ),
          );
        } else if (provider.joiningBonusState.status == ApiStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.joiningBonusState.message ?? "Error"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }
}
