import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/models/payout_bank_week_model.dart';
import 'package:zenfoo_partner/models/payout_week_transaction_model.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/view/custom_widgets/image_picker_bottom_sheet.dart';
import 'package:zenfoo_partner/view/custom_widgets/request_sent.dart';
import 'package:zenfoo_partner/providers/payout_issues_provider.dart';
import 'package:zenfoo_partner/services/status.dart';

class IncorrectPayoutScreen extends StatefulWidget {
  const IncorrectPayoutScreen({super.key});

  @override
  State<IncorrectPayoutScreen> createState() => _IncorrectPayoutScreenState();
}

class _IncorrectPayoutScreenState extends State<IncorrectPayoutScreen> {
  String? _selectedWeekLabel;
  File? _selectedImage;
  Week? _selectedWeek;
  Set<int> _selectedTransactions = {};

  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayoutIssuesProvider>().getPayoutWeeks();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showImagePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = context.read<LanguageProvider>();
    ImagePickerBottomSheet.show(
      context: context,
      colorScheme: themeProvider.colorScheme,
      onImageSelected: (file) {
        if (mounted) {
          setState(() {
            _selectedImage = file;
          });
        }
      },
      onPermissionDenied: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider
                .getTranslatedText('permission_denied_camera_gallery')),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      title: languageProvider.getTranslatedText('upload_payout_issue_evidence'),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
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
            title:
                languageProvider.getTranslatedText('incorrect_payout_to_bank'),
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
                  // Week Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('select_week'),
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
                        height: 48,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                        child: Consumer<PayoutIssuesProvider>(
                          builder: (context, provider, child) {
                            if (provider.getPayoutWeeksState.status ==
                                ApiStatus.loading) {
                              return const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final weekModel =
                                provider.getPayoutWeeksState.data != null
                                    ? WeekModel.fromJson(
                                        provider.getPayoutWeeksState.data)
                                    : null;
                            final weeks = weekModel?.data?.weeks ?? [];

                            return DropdownButton<String>(
                              value: _selectedWeekLabel,
                              hint: Text(
                                languageProvider
                                    .getTranslatedText('select_a_week'),
                                style: GoogleFonts.inter(
                                  color: colorScheme.inputPlaceholder,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.05,
                                ),
                              ),
                              isExpanded: true,
                              underline: const SizedBox(),
                              onChanged: (String? newValue) {
                                if (newValue == null) return;
                                final week = weeks
                                    .firstWhere((w) => w.label == newValue);
                                setState(() {
                                  _selectedWeekLabel = newValue;
                                  _selectedWeek = week;
                                  _selectedTransactions.clear();
                                });
                                context
                                    .read<PayoutIssuesProvider>()
                                    .getWeekTransactions(
                                        week: week.id?.toString() ?? '');
                              },
                              items: weeks.map((week) {
                                return DropdownMenuItem<String>(
                                  value: week.label,
                                  child: Text(
                                    week.label ?? '',
                                    style: GoogleFonts.inter(
                                      color: colorScheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.05,
                                    ),
                                  ),
                                );
                              }).toList(),
                              dropdownColor: colorScheme.surface,
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Payout Summary and Transactions
                  if (_selectedWeek != null)
                    Consumer<PayoutIssuesProvider>(
                      builder: (context, provider, child) {
                        if (provider.getWeekTransactionsState.status ==
                            ApiStatus.loading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (provider.getWeekTransactionsState.status ==
                            ApiStatus.error) {
                          return Center(
                            child: Text(
                                provider.getWeekTransactionsState.message ??
                                    'Error loading transactions'),
                          );
                        }

                        final transactionModel =
                            provider.getWeekTransactionsState.data != null
                                ? PayoutWeekTransactionModel.fromJson(
                                    provider.getWeekTransactionsState.data)
                                : null;

                        final summary = transactionModel?.data?.summary;
                        final transactions = summary?.transactions ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (summary != null) ...[
                              _buildPayoutSummary(
                                  summary, colorScheme, languageProvider),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              languageProvider.getTranslatedText(
                                  'select_incorrect_transactions'),
                              style: GoogleFonts.inter(
                                color: colorScheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.71,
                                letterSpacing: -0.05,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (transactions.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    languageProvider.getTranslatedText(
                                        'no_transactions_found'),
                                    style: GoogleFonts.inter(
                                        color: colorScheme.textSecondary),
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: ShapeDecoration(
                                  color: colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      width: 1,
                                      color: colorScheme.border
                                          .withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: transactions.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: colorScheme.border
                                        .withValues(alpha: 0.1),
                                  ),
                                  itemBuilder: (context, index) {
                                    final transaction = transactions[index];
                                    final id = transaction.id ?? index;
                                    final isSelected =
                                        _selectedTransactions.contains(id);

                                    return CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedTransactions.add(id);
                                          } else {
                                            _selectedTransactions.remove(id);
                                          }
                                        });
                                      },
                                      title: Text(
                                        transaction.message != null
                                            ? "${transaction.message} #${transaction.orderId ?? ''}"
                                            : transaction.type ?? 'Transaction',
                                        style: GoogleFonts.inter(
                                          color: colorScheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '₹${transaction.amount ?? '0'} • ${transaction.settledAt?.toString().split(' ')[0] ?? ''}',
                                        style: GoogleFonts.inter(
                                          color: colorScheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      activeColor: const Color(0xFF9AC444),
                                      checkboxShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),

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
                        height: 97,
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
                          decoration: InputDecoration(
                            hintText: languageProvider
                                .getTranslatedText('write_about_issue'),
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

                  const SizedBox(height: 24),

                  // Attachments
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getTranslatedText('attachments'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.71,
                          letterSpacing: -0.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedImage != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 156,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: colorScheme.error,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: _showImagePicker,
                          child: Container(
                            width: double.infinity,
                            height: 156,
                            decoration: ShapeDecoration(
                              color: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: colorScheme.border,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 5,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 24,
                                  color: colorScheme.textSecondary,
                                ),
                                Text(
                                  languageProvider
                                      .getTranslatedText('upload_image'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.12,
                                  ),
                                ),
                                Text(
                                  languageProvider.getTranslatedText('png_jpg'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
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
            ),
          ),

          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<PayoutIssuesProvider>(
              builder: (context, provider, child) {
                final isLoading =
                    provider.payoutBankState.status == ApiStatus.loading;
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

  Widget _buildPayoutSummary(
    Summary summary,
    dynamic colorScheme,
    LanguageProvider languageProvider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.border.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.getTranslatedText('payout_summary'),
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (summary.totalTransactions != null)
                Text(
                  '${summary.totalTransactions} ${languageProvider.getTranslatedText('transactions')}',
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          _buildDetailRow(
            colorScheme,
            languageProvider.getTranslatedText('total_earnings'),
            '₹${summary.totalDriverEarnings ?? '0'}',
          ),
          if (summary.paymentMode != null)
            _buildDetailRow(
              colorScheme,
              languageProvider.getTranslatedText('payment_mode'),
              summary.paymentMode!,
            ),
          if (summary.paidBankNumber != null &&
              summary.paidBankNumber!.isNotEmpty)
            _buildDetailRow(
              colorScheme,
              languageProvider.getTranslatedText('account_number'),
              summary.paidBankNumber!.first,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    dynamic colorScheme,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: colorScheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    final languageProvider = context.read<LanguageProvider>();
    final provider = context.read<PayoutIssuesProvider>();

    if (_selectedWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(languageProvider.getTranslatedText('please_select_a_week')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(languageProvider
              .getTranslatedText('please_select_at_least_one_transaction')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              languageProvider.getTranslatedText('please_enter_description')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    await provider.payoutBank(
      description: _descriptionController.text.trim(),
      issueType: 'incorrect_payout',
      issueIds: _selectedTransactions.toList(),
      attachments: _selectedImage != null ? [_selectedImage!] : null,
    );

    if (mounted) {
      if (provider.payoutBankState.status == ApiStatus.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RequestSent(popTwice: true),
          ),
        );
      }
    }
  }
}
