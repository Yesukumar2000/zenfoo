import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';

import '../../../providers/update_personal_info_provider.dart';
import '../../../services/status.dart';

class ChangePhoneNumberScreen extends StatefulWidget {
  const ChangePhoneNumberScreen({super.key});

  @override
  State<ChangePhoneNumberScreen> createState() =>
      _ChangePhoneNumberScreenState();
}

class _ChangePhoneNumberScreenState extends State<ChangePhoneNumberScreen> {
  final TextEditingController _currentPhoneController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();

  // 4 OTP Box Controllers and FocusNodes
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isUpdating = false;
  bool _otpSent = false;
  bool _showOtpField = false;
  int _resendTimer = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdatePersonalInfoProvider>().getPhoneNumber();
    });
  }

  @override
  void dispose() {
    _currentPhoneController.dispose();
    _newPhoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final languageProvider = context.read<LanguageProvider>();
    final provider = context.read<UpdatePersonalInfoProvider>();

    final phoneNumber = _newPhoneController.text.trim();

    // Validation
    if (phoneNumber.isEmpty || phoneNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(languageProvider.getTranslatedText('invalid_phone_number')),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    await provider.sendOtp(phoneNumber: phoneNumber);

    if (mounted) {
      setState(() => _isUpdating = false);

      if (provider.sendOtpState.status == ApiStatus.success) {
        setState(() {
          _otpSent = true;
          _showOtpField = true;
          _resendTimer = 60;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                languageProvider.getTranslatedText('otp_sent_successfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Start resend timer
        _startResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.sendOtpState.message ??
                languageProvider.getTranslatedText('something_went_wrong')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() => _resendTimer--);
        _startResendTimer();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final languageProvider = context.read<LanguageProvider>();
    final provider = context.read<UpdatePersonalInfoProvider>();

    String otp = _otpControllers.map((c) => c.text).join();

    // Validation
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(languageProvider.getTranslatedText('enter_4_digit_otp')),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    await provider.verifyotp(
      phone: _newPhoneController.text.trim(),
      otp: otp,
    );

    if (mounted) {
      setState(() => _isUpdating = false);

      if (provider.verifyOtpState.status == ApiStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                languageProvider.getTranslatedText('phone_number_updated')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reset state and fetch updated phone number
        provider.getPhoneNumber();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.verifyOtpState.message ??
                languageProvider.getTranslatedText('invalid_otp')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final languageProvider = context.read<LanguageProvider>();

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: languageProvider.getTranslatedText('profile_management'),
            title: languageProvider.getTranslatedText('change_phone_number'),
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// INFO BOX
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            languageProvider
                                .getTranslatedText('phone_change_info'),
                            style: GoogleFonts.inter(
                              color: colorScheme.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// CURRENT PHONE (READ ONLY)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider
                            .getTranslatedText('current_phone_number'),
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.border.withValues(alpha: 0.3),
                          ),
                          color: colorScheme.surface.withValues(alpha: 0.5),
                        ),
                        child: Consumer<UpdatePersonalInfoProvider>(
                          builder: (context, provider, child) {
                            if (provider.getPhoneNumberState.status ==
                                ApiStatus.loading) {
                              return Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            }

                            final phoneNumber = provider
                                    .getPhoneNumberState.data?.data?.mobile ??
                                languageProvider
                                    .getTranslatedText('phone_format_example');

                            return Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: colorScheme.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  phoneNumber,
                                  style: GoogleFonts.inter(
                                    color: colorScheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// NEW PHONE
                  if (!_otpSent)
                    Column(
                      children: [
                        CustomTextFormField(
                          title: languageProvider
                              .getTranslatedText('new_phone_number'),
                          controller: _newPhoneController,
                          hintText: languageProvider
                              .getTranslatedText('enter_new_phone'),
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  /// OTP FIELD (4 Boxes)
                  if (_showOtpField)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.getTranslatedText('enter_otp'),
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            return SizedBox(
                              width: 60,
                              height: 60,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    if (index < 3) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else {
                                      _focusNodes[index].unfocus();
                                    }
                                  } else {
                                    if (index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  }
                                },
                                decoration: InputDecoration(
                                  counterText: "",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.border
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.border
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: colorScheme.surface
                                      .withValues(alpha: 0.5),
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.textPrimary,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider
                                  .getTranslatedText('didnt_receive_otp'),
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (_resendTimer > 0)
                              Text(
                                '${languageProvider.getTranslatedText('resend_in')} ${_resendTimer}s',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textSecondary,
                                  fontSize: 13,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _sendOtp,
                                child: Text(
                                  languageProvider
                                      .getTranslatedText('resend_otp'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  /// TIPS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              languageProvider
                                  .getTranslatedText('important_information'),
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip(
                          textTheme,
                          colorScheme,
                          languageProvider
                              .getTranslatedText('phone_must_be_valid'),
                        ),
                        _buildTip(
                          textTheme,
                          colorScheme,
                          languageProvider
                              .getTranslatedText('otp_valid_for_10_minutes'),
                        ),
                        _buildTip(
                          textTheme,
                          colorScheme,
                          languageProvider
                              .getTranslatedText('secure_your_account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// SUBMIT BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomButton(
              text: _otpSent
                  ? languageProvider.getTranslatedText('verify_otp')
                  : languageProvider.getTranslatedText('send_otp'),
              onPressed:
                  _isUpdating ? null : (_otpSent ? _verifyOtp : _sendOtp),
              isLoading: _isUpdating,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(TextTheme textTheme, colorScheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: colorScheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
