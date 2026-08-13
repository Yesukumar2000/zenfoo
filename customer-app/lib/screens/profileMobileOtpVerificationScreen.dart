import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/generalWidgets/appHeader.dart';

class ProfileMobileOtpVerificationScreen extends StatefulWidget {
  final String mobileNumber;
  final Map<String, String>? profileData;

  const ProfileMobileOtpVerificationScreen({
    Key? key,
    required this.mobileNumber,
    this.profileData,
  }) : super(key: key);

  @override
  State<ProfileMobileOtpVerificationScreen> createState() =>
      _ProfileMobileOtpVerificationScreenState();
}

class _ProfileMobileOtpVerificationScreenState
    extends State<ProfileMobileOtpVerificationScreen> {
  int otpLength = 4;
  final pinController = TextEditingController();

  static const _duration = Duration(seconds: 30);
  Timer? _timer;
  Duration _remaining = _duration;

  void startTimer() {
    _remaining = _duration;
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - Duration(seconds: 1);
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((value) {
      if (mounted) {
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _verifyOtp() {
    debugPrint('=== OTP Verification ===');
    debugPrint('Entered OTP: ${pinController.text}');
    debugPrint('OTP Length: ${pinController.text.length}');

    if (pinController.text.length == otpLength) {
      debugPrint('OTP is valid, returning to previous screen');
      HapticFeedback.lightImpact();
      Navigator.pop(context, pinController.text);
    } else {
      debugPrint('OTP is not complete');
    }
  }

  void _resendOtp() async {
    debugPrint('=== Resend OTP ===');
    HapticFeedback.lightImpact();

    try {
      // If profileData is provided, resend OTP by calling the API again
      if (widget.profileData != null && widget.profileData!.isNotEmpty) {
        debugPrint('Profile data available, calling API to resend OTP');
        debugPrint('Profile Data: ${widget.profileData}');

        final result =
            await context.read<UserProfileProvider>().updateUserProfile(
                  context: context,
                  selectedImagePath: "",
                  params: widget.profileData!,
                );

        debugPrint('Resend OTP Response: $result');
        debugPrint('Response Type: ${result.runtimeType}');

        if (result is bool && result) {
          debugPrint('OTP resent successfully');
          startTimer();
          setState(() {});
          showMessage(
            context,
            getTranslatedValue(context, 'otp_sent_successfully'),
            MessageType.success,
          );
        } else {
          debugPrint('Resend OTP failed: $result');
          showMessage(
            context,
            result.toString(),
            MessageType.error,
          );
        }
      } else {
        debugPrint('No profile data, just restarting timer');
        // Fallback: just restart the timer without API call
        startTimer();
        setState(() {});
        showMessage(
          context,
          getTranslatedValue(context, 'otp_sent_successfully'),
          MessageType.success,
        );
      }
    } catch (e) {
      debugPrint('Error in _resendOtp: $e');
      showMessage(
        context,
        e.toString(),
        MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_theme.ThemeProvider>(
      builder: (context, themeProvider, _) {
        final colorScheme = themeProvider.colorScheme;

        return Scaffold(
          backgroundColor: colorScheme.background,
          body: Column(
            children: [
              AppHeader(
                label: getTranslatedValue(context, 'verification'),
                title: getTranslatedValue(context, 'otp_verification'),
                showBackButton: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon with gradient background
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.phone_android_rounded,
                          color: colorScheme.buttonPrimaryText,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        getTranslatedValue(context, 'otp_send_message')
                            .replaceAll(
                                '{{mobile_number}}', widget.mobileNumber),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mobile number display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.border),
                        ),
                        child: Text(
                          widget.mobileNumber,
                          style: GoogleFonts.inter(
                            color: colorScheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // OTP Input
                      otpPinWidget(
                        context: context,
                        pinController: pinController,
                        onCompleted: _verifyOtp,
                      ),
                      const SizedBox(height: 48),

                      // Resend OTP button
                      GestureDetector(
                        onTap: _timer != null && _timer!.isActive
                            ? null
                            : _resendOtp,
                        child: _buildResendOtpWidget(colorScheme),
                      ),
                      const SizedBox(height: 32),

                      // Help text
                      Text(
                        getTranslatedValue(context,
                            'otp_help_text'), // Fallback text if translation doesn't exist
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.textTertiary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.1,
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
    );
  }

  Widget _buildResendOtpWidget(dynamic colorScheme) {
    final isActive = _timer != null && _timer!.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? colorScheme.border : colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.timer_outlined : Icons.refresh_rounded,
            color: isActive ? colorScheme.textSecondary : colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: colorScheme.textPrimary,
                letterSpacing: -0.2,
              ),
              text: isActive
                  ? "${getTranslatedValue(context, 'resend_otp_in')} "
                  : "",
              children: <TextSpan>[
                TextSpan(
                  text: isActive
                      ? '${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                      : getTranslatedValue(context, 'resend_otp'),
                  style: GoogleFonts.inter(
                    color: isActive
                        ? colorScheme.textSecondary
                        : colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
