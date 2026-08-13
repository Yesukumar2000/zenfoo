import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:project/screens/Login/otp_provider.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/app_header.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class OTPProvider extends ChangeNotifier {
  String otp = "";
  int timer = 30;
  bool canResend = false;
  final String phone;
  bool _disposed = false;

  OTPProvider(this.phone) {
    startTimer();
  }

  void startTimer() {
    canResend = false;
    timer = 30;
    notifyListeners();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_disposed) return false; // Stop timer if disposed
      timer--;
      if (!_disposed) notifyListeners();
      if (timer == 0) {
        canResend = true;
        if (!_disposed) notifyListeners();
      }
      return timer > 0 && !_disposed;
    });
  }

  void onOtpChange(String v) {
    otp = v;
    notifyListeners();
  }

  void resend(Function() resendApiCall) {
    resendApiCall();
    startTimer();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class OTPScreen extends StatefulWidget {
  final String phone;
  final Function(String otp) onOtpEntered;
  const OTPScreen({
    required this.phone,
    required this.onOtpEntered,
    Key? key,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  late TextEditingController _pinController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _focusNode = FocusNode();
    debugPrint('👂 OTP screen initialized - ready to receive OTP');

    // Request autofill focus after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAutoFillFocus();
    });
  }

  /// Request autofill focus and listen for SMS OTP
  Future<void> _requestAutoFillFocus() async {
    try {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
        debugPrint('✅ Autofill focus requested');
      }
    } catch (e) {
      debugPrint('⚠️ Could not request autofill: $e');
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return ChangeNotifierProvider(
      create: (_) => OTPProvider(widget.phone),
      child: Consumer<OTPProvider>(
        builder: (context, provider, _) {
          final loginProvider = context.watch<LoginProvider>();
          return Scaffold(
            backgroundColor: colorScheme.background,
            body: Column(
              children: [
                AppHeader(
                  label: 'Verification',
                  title: 'OTP Verification',
                  showBackButton: true,
                  onBackPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Lock Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          "Enter Verification Code",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "We've sent a 4-digit code to\n",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.textSecondary,
                                  height: 1.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              TextSpan(
                                text: "+91 ${provider.phone}",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.textPrimary,
                                  height: 1.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // OTP INPUT with Autofill
                        AutofillGroup(
                          onDisposeAction: AutofillContextAction.commit,
                          child: Pinput(
                            controller: _pinController,
                            focusNode: _focusNode,
                            length: 4,
                            defaultPinTheme: PinTheme(
                              width: 64,
                              height: 64,
                              textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                color: colorScheme.textPrimary,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.border,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 64,
                              height: 64,
                              textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                color: colorScheme.textPrimary,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.background,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            submittedPinTheme: PinTheme(
                              width: 64,
                              height: 64,
                              textStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                color: colorScheme.textPrimary,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            useNativeKeyboard: true,
                            animationDuration: const Duration(milliseconds: 250),
                            autofillHints: const [AutofillHints.oneTimeCode],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (pin) {
                              provider.onOtpChange(pin);
                            },
                            onCompleted: (pin) {
                              debugPrint('✅ OTP ENTERED: $pin');
                              HapticFeedback.lightImpact();
                              widget.onOtpEntered(pin);
                            },
                          ),
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

                        const SizedBox(height: 32),

                        // Loading or Resend section
                        if (loginProvider.loading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary),
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Verifying...',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.textSecondary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (provider.canResend)
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                provider.resend(() async {
                                  await loginProvider.sendOtpSellerPhone(
                                      context, widget.phone);
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Resend OTP",
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: colorScheme.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Resend in ",
                                        style: GoogleFonts.inter(
                                          color: colorScheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "${provider.timer}s",
                                        style: GoogleFonts.inter(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Help text
                        Text(
                          "Didn't receive the code? Check your phone number",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textTertiary,
                            height: 1.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
