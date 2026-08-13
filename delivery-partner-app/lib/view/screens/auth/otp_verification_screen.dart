import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/router/app_router.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/appHeader.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:pinput/pinput.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobile;
  final String otp;
  final String userId;
  final bool isUserExist;

  const OTPVerificationScreen({
    super.key,
    required this.mobile,
    required this.otp,
    required this.userId,
    required this.isUserExist,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  final pinController = TextEditingController();
  final focusNode = FocusNode();

  late AnimationController fadeController;
  late Animation<double> fadeAnim;
  bool _otpFlowCompleted = false;

  Future<void> _handleOtpSuccess(AuthProvider provider) async {
    if (_otpFlowCompleted) return;
    _otpFlowCompleted = true;

    debugPrint('🚀 Handling OTP success (safe flow)');

    // 👤 Fetch personal details with skipLogout=true
    // This prevents a 401 from logging the user out during this critical navigation transition
    await provider.getPersonalDetails(skipLogout: true);

    debugPrint(
        '👤 Personal details fetch attempt completed. Status: ${provider.currentDeliveryBoy?.status}');

    if (!mounted) return;

    // Trigger navigation immediately using data from verify-otp
    debugPrint('🚦 Triggering immediate navigation flow...');
    _navigateToNextScreen(provider);

    // 🔕 Fire-and-forget FCM update
    unawaited(provider.updateFcmTokenSafe());
  }

  int countdown = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    pinController.text = widget.otp;
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fadeAnim = Tween<double>(begin: 0, end: 1).animate(fadeController);
    fadeController.forward();
    startTimer();
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    timer?.cancel();
    fadeController.dispose();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() => countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _navigateToNextScreen(AuthProvider provider) async {
    debugPrint('🚦 Entered _navigateToNextScreen');
    if (!mounted) {
      debugPrint('🚫 _navigateToNextScreen: Screen not mounted, aborting.');
      return;
    }

    final deliveryBoy = provider.currentDeliveryBoy;
    if (deliveryBoy == null) {
      debugPrint('⚠️ No DeliveryBoy in provider, falling back to LocalStorage');
      final deliveryBoyData = await LocalStorage.getDeliveryBoyData();
      if (deliveryBoyData == null) {
        debugPrint('📝 No data anywhere - Going to multi-step form');
        if (!mounted) return;
        context.go(AppRouterName.multiStepForm);
        return;
      }
      await _handleNavigationWithData(deliveryBoyData, provider);
    } else {
      debugPrint(
          '📦 Using provider DeliveryBoy data (Status: ${deliveryBoy.status})');
      await _handleNavigationWithData(deliveryBoy.toJson(), provider);
    }
  }

  Future<void> _handleNavigationWithData(
      Map<String, dynamic> data, AuthProvider provider) async {
    debugPrint('🚦 Processing navigation with data: $data');
    if (!mounted) return;

    // Get status: 0=Registered, 1=Pending, 2=Approved, 3=Rejected
    final rawStatus = data['status'];
    final status = rawStatus is int
        ? rawStatus
        : int.tryParse(rawStatus?.toString() ?? '') ?? 0;
    final documents = data['documents'];

    debugPrint(
        '🔍 Nav Logic - Status: $status, Has Docs: ${documents != null}');

    // Load documents into DocumentProvider if available
    if (documents != null && mounted) {
      try {
        final docProvider = context.read<DocumentProvider>();
        docProvider.loadDocumentsFromApi(documents);
        debugPrint('📄 Documents loaded into docProvider');
      } catch (e) {
        debugPrint('❌ Error loading docs into provider: $e');
      }
    }

    if (!mounted) return;

    // Route based on status
    if (status == 1) {
      // Status 1: Approved
      debugPrint('✅ Status 1 (Approved) - Navigating to home screen');
      final incomingOrderProvider = context.read<IncomingOrderProvider>();
      final deliveryBoyId = provider.currentDeliveryBoy?.id ?? 0;

      if (deliveryBoyId > 0) {
        // Check if there's an active order in Firebase - preserve it, don't clear
        final currentOrder =
            await incomingOrderProvider.getCurrentAcceptedOrder(deliveryBoyId);
        if (currentOrder != null) {
          debugPrint(
              '📦 Found active order ${currentOrder.orderId} - preserving it');
          incomingOrderProvider.setCurrentAcceptedOrder(currentOrder);
        } else {
          // No active order - start listening for new orders
          incomingOrderProvider.startListening(deliveryBoyId);
        }
      }

      // Ensure keyboard is dismissed
      focusNode.unfocus();

      debugPrint('🚀 Preparation complete. Current mounted status: $mounted');
      if (!mounted) {
        debugPrint(
            '🚫 Aborting navigation: OTP screen unmounted after background tasks.');
        return;
      }

      debugPrint(
          '🚀 Calling context.go(${AppRouterName.bottomNavScreen}) now...');
      try {
        context.go(AppRouterName.bottomNavScreen);
        debugPrint('✅ context.go called successfully');
      } catch (e) {
        debugPrint('❌ Error during context.go: $e');
        // Fallback to global navigator
        debugPrint('🔄 Attempting fallback global navigation...');
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRouterName.bottomNavScreen,
          (route) => false,
        );
      }
      return;
    }

    if (status == 2) {
      // Status 2: Rejected - Go back to form to fix rejected documents
      debugPrint('❌ Status 2 (Rejected) - Going to form');
      context.go(AppRouterName.multiStepForm);
      return;
    }

    // Status 0: Registered - Check registration progress and navigate accordingly
    final deliveryBoy = provider.currentDeliveryBoy;

    if (deliveryBoy == null) {
      // No delivery boy data - start from beginning
      debugPrint('📝 No delivery boy data - Going to form');
      context.go(AppRouterName.multiStepForm);
      return;
    }

    // Check if documents are uploaded and pending verification
    if (documents != null) {
      final overallStatus = documents['overall_status'];
      if (overallStatus == 'pending_verification' ||
          overallStatus == 'verified') {
        debugPrint(
            '📄 Documents pending verification - Going to verifying details');
        context.go(AppRouterName.verifyingDetails);
        return;
      }
    }

    // Otherwise, navigate to multi-step form (registration incomplete)
    debugPrint(
        '📝 Registration incomplete or unhandled status - Going to form');
    context.go(AppRouterName.multiStepForm);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    final defaultPinTheme = PinTheme(
      width: 55,
      height: 60,
      textStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.55,
        height: 1.02,
        color: colorScheme.textPrimary,
      ),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.inputBorder),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: colorScheme.primary, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      color: colorScheme.primary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
    );

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          /// APP HEADER
          AppHeader(
            label: context
                .watch<LanguageProvider>()
                .getTranslatedText('verification'),
            title: context
                .watch<LanguageProvider>()
                .getTranslatedText('enter_otp'),
            showBackButton: true,
          ),

          /// CONTENT
          Expanded(
            child: FadeTransition(
              opacity: fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    Text(
                      "We've sent a verification code to",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: colorScheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.55,
                        height: 1.02,
                      ),
                    ),
                    // const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "+91 ${widget.mobile}",
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.55,
                            height: 1.02,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit',
                                style: GoogleFonts.inter(
                                  color: colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.55,
                                  height: 1.02,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    /// OTP INPUT FIELD
                    Consumer<AuthProvider>(
                      builder: (context, provider, _) {
                        return Pinput(
                          controller: pinController,
                          focusNode: focusNode,
                          length: 4,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: submittedPinTheme,
                          showCursor: true,
                          onChanged: (value) {
                            debugPrint('Current OTP: $value');
                          },
                          autofillHints: const [AutofillHints.oneTimeCode],
                          keyboardType: TextInputType.number,
                          onCompleted: (pin) async {
                            if (pin.length != 4) return;

                            debugPrint('🎯 OTP entry completed: $pin');
                            await provider.verifyOtp(
                              otp: pin,
                              phone: widget.mobile,
                            );

                            debugPrint(
                                '🔍 verifyOtp status: ${provider.verifyOtpState.status}');
                            if (isStatusSuccess(
                                provider.verifyOtpState.status)) {
                              debugPrint(
                                  '✅ Success status detected, calling _handleOtpSuccess');
                              await _handleOtpSuccess(provider);
                            } else {
                              debugPrint(
                                  '❌ verifyOtp failed in UI: ${provider.verifyOtpState.message}');
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Auto-read hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sms_outlined,
                          size: 16,
                          color: colorScheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'OTP will be auto-filled from SMS',
                          style: GoogleFonts.inter(
                            color: colorScheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// RESEND OTP
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        final isResending =
                            isStatusLoading(authProvider.sendOtpState.status);

                        if (countdown > 0) {
                          return RichText(
                            text: TextSpan(
                              text: "Resend OTP in ",
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.55,
                                height: 1.02,
                              ),
                              children: [
                                TextSpan(
                                  text: "${countdown}s",
                                  style: GoogleFonts.inter(
                                    color: colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.55,
                                    height: 1.02,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (isResending) {
                          return SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(colorScheme.primary),
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () async {
                            // Send OTP
                            await authProvider.sendOtp(phone: widget.mobile);

                            // Reset timer and clear input if successful
                            if (isStatusSuccess(
                                authProvider.sendOtpState.status)) {
                              setState(() => countdown = 30);
                              startTimer();
                              pinController.clear();
                              focusNode.requestFocus();
                            }
                          },
                          child: Text(
                            "Resend OTP",
                            style: GoogleFonts.inter(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.55,
                              height: 1.02,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    /// VERIFY BUTTON
                    Consumer<AuthProvider>(
                      builder: (context, provider, _) {
                        return CustomButton(
                          isLoading:
                              isStatusLoading(provider.verifyOtpState.status),
                          onPressed: () async {
                            if (pinController.text.length != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Please enter a valid OTP",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: colorScheme.error,
                                ),
                              );
                              return;
                            }

                            debugPrint(
                                '🎯 Verify button pressed with OTP: ${pinController.text}');
                            await provider.verifyOtp(
                              otp: pinController.text,
                              phone: widget.mobile,
                            );

                            debugPrint(
                                '🔍 verifyOtp status: ${provider.verifyOtpState.status}');
                            if (isStatusSuccess(
                                provider.verifyOtpState.status)) {
                              debugPrint(
                                  '✅ Success status detected, calling _handleOtpSuccess');
                              await _handleOtpSuccess(provider);
                            } else {
                              debugPrint(
                                  '❌ verifyOtp failed in UI: ${provider.verifyOtpState.message}');
                            }
                          },
                          text: 'Verify OTP',
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
