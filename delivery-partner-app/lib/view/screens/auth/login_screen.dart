import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:zenfoo_partner/main.dart';
import 'package:go_router/go_router.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/utils/app_dimensions.dart';
import 'package:zenfoo_partner/view/custom_widgets/customTextField.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_button.dart';
import 'package:zenfoo_partner/view/custom_widgets/custom_scaffold.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/banner_provider.dart';
import 'package:zenfoo_partner/models/banner_model.dart';
import 'package:video_player/video_player.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late PageController _pageController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int currentIndex = 0;
  bool _acceptedTerms = false;
  bool _hasReferralCode = false;

  final Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Fetch login banners when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bannerProvider = context.read<BannerProvider>();
      bannerProvider.fetchLoginBanners();
      bannerProvider.fetchSupportContacts();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNext();
        }
      });

    _controller.forward();
    _loadSavedMobileNumber();
  }

  void _initVideoControllers(List<BannerSliderModel> banners) {
    for (int i = 0; i < banners.length; i++) {
      final banner = banners[i];
      if (banner.isVideo && !_videoControllers.containsKey(i)) {
        final ctl =
            VideoPlayerController.networkUrl(Uri.parse(banner.imageUrl));
        _videoControllers[i] = ctl;
        ctl.initialize().then((_) {
          if (mounted) setState(() {});
          ctl.setLooping(true);
          ctl.setVolume(0);
          ctl.play();
        }).catchError((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  /// Load mobile number using Google Play Services Phone Number Hint API or local storage
  Future<void> _loadSavedMobileNumber() async {
    String? mobileNumber;
    String source = '';

    try {
      // First, try to get phone number hint from Google Play Services (Play Store compliant)
      try {
        final hint = await SmsAutoFill().hint;

        if (hint != null && hint.isNotEmpty) {
          // Remove country code and non-numeric characters
          String cleaned = hint.replaceAll(RegExp(r'[^0-9]'), '');

          // Remove +91 or 91 prefix if present
          if (cleaned.startsWith('91') && cleaned.length > 10) {
            cleaned = cleaned.substring(2);
          }

          // Ensure it's exactly 10 digits
          if (cleaned.length == 10) {
            mobileNumber = cleaned;
            source = 'Google account';
            debugPrint('📱 Detected from Google: $mobileNumber');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not get phone hint: $e');
      }

      // Fallback to local storage if hint failed
      if (mobileNumber == null || mobileNumber.isEmpty) {
        final userData = await LocalStorage.getUserData();
        if (userData != null) {
          final mobile = userData['mobile']?.toString() ?? '';
          if (mobile.isNotEmpty && mobile.length == 10) {
            mobileNumber = mobile;
            source = 'storage';
            debugPrint('📱 Loaded from storage: $mobileNumber');
          }
        }
      }

      // Update UI if number was found
      if (mobileNumber != null && mobileNumber.isNotEmpty && mounted) {
        setState(() {
          _phoneController.text = mobileNumber!;
        });

        // Show notification
        // if (mounted) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(
        //         'Number auto-filled from $source: +91 $mobileNumber',
        //         style: GoogleFonts.inter(
        //           fontSize: 14,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //       duration: const Duration(seconds: 2),
        //       behavior: SnackBarBehavior.floating,
        //       backgroundColor: Colors.green.shade600,
        //     ),
        //   );
        // }
      }
    } catch (e) {
      debugPrint('❌ Error loading mobile number: $e');
    }
  }

  int get _bannerCount {
    final banners = context.read<BannerProvider>().loginBanners;
    return banners.isNotEmpty ? banners.length : 1;
  }

  void _goToNext() {
    _controller.reset();

    if (currentIndex < _bannerCount - 1) {
      currentIndex++;
    } else {
      currentIndex = 0;
    }

    _pageController.animateToPage(
      currentIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    _controller.forward();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    _phoneController.dispose();
    _referralCodeController.dispose();
    for (final ctl in _videoControllers.values) {
      ctl.dispose();
    }
    super.dispose();
  }

  Widget _buildVideoBanner(int index) {
    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.grey.shade300);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  /// Show support dialog
  void _showSupportDialog(colorScheme, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCustomerSupport,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  languageProvider.getTranslatedText('need_help'),
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageProvider.getTranslatedText('contact_support_message'),
                style: GoogleFonts.inter(
                  color: colorScheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Call Support Option
              Builder(builder: (_) {
                final bp = context.read<BannerProvider>();
                final phone = bp.supportPhone;
                // No configured number: hide the option rather than dial a stale one.
                if (phone.isEmpty) return const SizedBox.shrink();
                return _buildSupportOption(
                  colorScheme: colorScheme,
                  icon: HugeIcons.strokeRoundedCall,
                  title: languageProvider.getTranslatedText('call_support'),
                  subtitle: '+91 $phone',
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _launchPhone('+91$phone');
                  },
                );
              }),
              const SizedBox(height: 12),
              // Email Support Option
              Builder(builder: (_) {
                final bp = context.read<BannerProvider>();
                final email = bp.supportEmail;
                if (email.isEmpty) return const SizedBox.shrink();
                return _buildSupportOption(
                  colorScheme: colorScheme,
                  icon: HugeIcons.strokeRoundedMail01,
                  title: languageProvider.getTranslatedText('email_support'),
                  subtitle: email,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _launchEmail(email);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                languageProvider.getTranslatedText('close'),
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupportOption({
    required dynamic colorScheme,
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.border.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: HugeIcon(
                icon: icon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Support Request - Zenfoo Delivery Partner',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final languageProvider = context.watch<LanguageProvider>();

    // Show loading while language is being initialized
    if (languageProvider.languageState == LanguageState.loading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return CustomScaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔹 TOP SECTION WITH IMAGE SLIDER
            Container(
              height: screenHeight * .55,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Consumer<BannerProvider>(
                builder: (context, bannerProvider, _) {
                  final loginBanners = bannerProvider.loginBanners;
                  final hasDynamic = bannerProvider.hasLoginData;
                  final itemCount = hasDynamic ? loginBanners.length : 1;

                  // Init video controllers when dynamic banners arrive
                  if (hasDynamic) {
                    _initVideoControllers(loginBanners);
                  }

                  return Stack(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            const SizedBox(height: AppDimensions.paddingSmall),

                            /// 🔹 PROGRESS BARS
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: List.generate(itemCount, (index) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: AnimatedBuilder(
                                        animation: _controller,
                                        builder: (context, _) {
                                          double value = 0;
                                          if (index < currentIndex) {
                                            value = 1;
                                          } else if (index == currentIndex) {
                                            value = _controller.value;
                                          }
                                          return LinearProgressIndicator(
                                            value: value,
                                            backgroundColor: (!isDarkMode
                                                    ? Colors.black
                                                    : Colors.white)
                                                .withValues(alpha: 0.2),
                                            valueColor: AlwaysStoppedAnimation(
                                              !isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                            minHeight: 5,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// 🔹 HEADLINE
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingMedium,
                                ),
                                child: Text(
                                  languageProvider.getTranslatedText(
                                      'earn_more_with_every_delivery'),
                                  maxLines: 2,
                                  style: GoogleFonts.inter(
                                    color: !isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.55,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// 🔹 IMAGE SLIDER
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  if (hasDynamic) {
                                    final banner = loginBanners[index];
                                    if (banner.isVideo) {
                                      return _buildVideoBanner(index);
                                    }
                                    return SizedBox.expand(
                                      child: Image.network(
                                        banner.imageUrl,
                                        key: ValueKey(banner.id),
                                        fit: BoxFit.fitHeight,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  }
                                  // Loading / no data placeholder
                                  return Container(color: colorScheme.primary);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// 🔹 SUPPORT ICON (TOP RIGHT)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showSupportDialog(colorScheme, languageProvider);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (!isDarkMode ? Colors.black : Colors.white)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCustomerSupport,
                              color: !isDarkMode ? Colors.black : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            /// 🔹 BOTTOM SECTION WITH FORM
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 WELCOME TEXT
                  Text(
                    languageProvider
                        .getTranslatedText('welcome_zenfoo_delivery_partner'),
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      color: colorScheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.55,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// 🔹 SUBTITLE
                  Text(
                    languageProvider.getTranslatedText('start_earning_today'),
                    style: GoogleFonts.inter(
                      color: colorScheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.55,
                      height: 1.02,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔹 MOBILE INPUT FORM
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextFormField(
                          title: '',
                          maxLength: 10,
                          keyboardType: TextInputType.number,
                          prefixIcon: SizedBox(
                            width: 32,
                            child: Center(
                              child: Text(
                                '+91',
                                style: GoogleFonts.inter(
                                  color: colorScheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.55,
                                  height: 1.02,
                                ),
                              ),
                            ),
                          ),
                          hintText: languageProvider
                              .getTranslatedText('enter_mobile_number'),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return languageProvider
                                  .getTranslatedText('mobile_number_empty');
                            } else if (value?.length != 10) {
                              return languageProvider
                                  .getTranslatedText('mobile_number_10_digits');
                            }
                            return null;
                          },
                          controller: _phoneController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔹 REFERRAL CODE OPTION
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasReferralCode = !_hasReferralCode;
                        if (!_hasReferralCode) {
                          _referralCodeController.clear();
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _hasReferralCode
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _hasReferralCode
                              ? 'Hide referral code'
                              : 'Have a referral code?',
                          style: GoogleFonts.inter(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_hasReferralCode) ...[
                    const SizedBox(height: 12),
                    CustomTextFormField(
                      title: '',
                      hintText: 'Enter referral code',
                      controller: _referralCodeController,
                      keyboardType: TextInputType.text,
                      prefixIcon: SizedBox(
                        width: 32,
                        child: Center(
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            color: colorScheme.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  /// 🔹 TERMS AND CONDITIONS CHECKBOX
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptedTerms = !_acceptedTerms;
                            });
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: _acceptedTerms
                                  ? colorScheme.primary
                                  : colorScheme.inputBackground,
                              border: Border.all(
                                color: _acceptedTerms
                                    ? colorScheme.primary
                                    : colorScheme.inputBorder,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _acceptedTerms
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                color: colorScheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${languageProvider.getTranslatedText('i_agree_to')} ',
                                ),
                                TextSpan(
                                  text: languageProvider.getTranslatedText(
                                      'terms_and_conditions'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    height: 1.5,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                        Uri.parse(
                                            'https://wheat-rook-708688.hostingersite.com/delivery-boy-terms-conditions'),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                ),
                                const TextSpan(
                                  text: ' and ',
                                ),
                                TextSpan(
                                  text: languageProvider
                                      .getTranslatedText('privacy_policy'),
                                  style: GoogleFonts.inter(
                                    color: colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    height: 1.5,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                        Uri.parse(
                                            'https://wheat-rook-708688.hostingersite.com/delivery-boy-privacy-policy'),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔹 CONTINUE BUTTON
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return CustomButton(
                        text: 'Continue',
                        isLoading:
                            isStatusLoading(authProvider.sendOtpState.status),
                        onPressed: () async {
                          // Check if terms are accepted first
                          if (!_acceptedTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  languageProvider.getTranslatedText(
                                      'accept_terms_continue'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          if (_formKey.currentState?.validate() ?? false) {
                            debugPrint('Validation successful');

                            // Send OTP
                            await authProvider.sendOtp(
                              phone: _phoneController.text,
                              referralCode:
                                  _referralCodeController.text.isNotEmpty
                                      ? _referralCodeController.text
                                      : null,
                            );

                            // Navigate to OTP screen if successful
                            if (isApiResponseSuccess(
                                authProvider.sendOtpState.data)) {
                              debugPrint('OTP sent successfully');
                              if (mounted) {
                                GoRouter.of(context).push(
                                  AppRouterName.otpVerify,
                                  extra: {
                                    'mobile': _phoneController.text,
                                    'otp': '',
                                    'userId': '',
                                    'isUserExist': false,
                                  },
                                );
                              }
                            }
                          }
                        },
                      ).disabled(!_acceptedTerms ||
                          (!_phoneController.text.isNotEmpty));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
