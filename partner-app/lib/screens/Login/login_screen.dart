import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:video_player/video_player.dart';
import 'package:project/helper/utils/custom_text_form_field.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart';
import 'package:project/provider/support_contact_provider.dart';
import 'package:project/repositories/loginBgApi.dart';
import 'package:project/screens/Login/otp_provider.dart';
import 'package:project/screens/Login/otp_screen.dart';
import 'package:project/screens/resgistration/food/food_registration.dart';
import 'package:project/screens/mainScreen/bottom_nav_provider.dart';
import 'package:project/screens/mainScreen/main_tab_scaffold.dart';
import 'package:project/screens/resgistration/registeration_screen.dart';
import 'package:velocity_x/velocity_x.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final phoneController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _phoneFocusNode = FocusNode();
  double _previousBottomInset = 0;

  // Dynamic background
  String? _bgUrl;
  bool _isBgVideo = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _phoneFocusNode.addListener(_onFocusChange);
    _fetchLoginBg();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportContactProvider>().fetchSupportContacts();
    });
  }

  Future<void> _fetchLoginBg() async {
    final url = await getLoginBgUrl();
    if (url != null && url.isNotEmpty && mounted) {
      final lower = url.toLowerCase();
      final isVideo = lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.webm') ||
          lower.endsWith('.avi');
      setState(() {
        _bgUrl = url;
        _isBgVideo = isVideo;
      });
      if (isVideo) {
        _initVideoPlayer(url);
      }
    }
  }

  void _initVideoPlayer(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController!.play();
        }
      });
  }

  void _onFocusChange() {
    if (_phoneFocusNode.hasFocus) {
      // Delay to allow keyboard to fully appear
      Future.delayed(Duration(milliseconds: 400), () {
        _scrollToBottom();
      });
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Called when keyboard appears/disappears
    final bottomInset = WidgetsBinding
            .instance.platformDispatcher.views.first.viewInsets.bottom /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    if (bottomInset > _previousBottomInset && _phoneFocusNode.hasFocus) {
      // Keyboard is appearing and text field is focused
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _previousBottomInset = bottomInset;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _phoneFocusNode.removeListener(_onFocusChange);
    _phoneFocusNode.dispose();
    _scrollController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget _buildBackground(BuildContext context) {
    final height = MediaQuery.of(context).size.height * .6;

    // Video background
    if (_isBgVideo && _videoController != null && _videoController!.value.isInitialized) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    // Network image/gif background
    if (_bgUrl != null && !_isBgVideo) {
      return Image.network(
        _bgUrl!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Image.asset(
            'assets/images/splash_login.png',
            width: double.infinity,
            height: height,
            fit: BoxFit.fitWidth,
          );
        },
        errorBuilder: (context, error, stack) {
          return Image.asset(
            'assets/images/splash_login.png',
            width: double.infinity,
            height: height,
            fit: BoxFit.fitWidth,
          );
        },
      );
    }

    // Fallback static asset
    return Image.asset(
      'assets/images/splash_login.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
      height: height,
    );
  }

  void _showSupportDialog() {
    final provider = context.read<SupportContactProvider>();
    final contact = provider.supportContact;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.support_agent_rounded,
                  color: Color(0xFF9AC444), size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: provider.state == SupportContactState.loading
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF9AC444)),
                ),
              )
            : contact != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Need help? Reach out to our support team through any of the options below.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Phone tile
                      if (contact.phone.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.phone_rounded,
                          label: 'Call Us',
                          value: contact.phone,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('tel:${contact.phone}'));
                          },
                        ),
                      if (contact.phone.isNotEmpty && contact.email.isNotEmpty)
                        SizedBox(height: 12),
                      // Email tile
                      if (contact.email.isNotEmpty)
                        _buildContactTile(
                          icon: Icons.email_rounded,
                          label: 'Email Us',
                          value: contact.email,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            launchUrl(Uri.parse('mailto:${contact.email}'));
                          },
                        ),
                    ],
                  )
                : Text(
                    'Unable to load support contacts. Please try again later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9AC444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF9AC444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF9AC444), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9CA3AF), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _checkRegistrationAndNavigate(BuildContext context) async {
    try {
      // Fetch seller data to check registration status
      final response = await sendApiRequest(
        apiName: 'registration-data-dev',
        params: {},
        isPost: false,
      );

      if (response != null) {
        final Map<String, dynamic> data = json.decode(response);

        if (data['status'] == 1 && data['data'] != null) {
          final seller = data['data']['seller'];
          final storeId = seller['store_id']?.toString() ?? '';

          final userId = seller['id']?.toString();

          Constant.session.setUserData(data: seller);
          Constant.session
              .setData(SessionManager.keyStoreId, storeId ?? '', true);
          Constant.session
              .setData(SessionManager.keyUserId, userId ?? '', true);
          // Safe parse booleans
          final managedByAdmin = safeParseBool(seller['managed_by_admin']);
          final isSweetHouse = safeParseBool(seller['is_sweet_house']);
          final isSuperMart = safeParseBool(seller['is_super_mart']);

          // Save store ID, managed_by_admin, is_sweet_house and is_super_mart in session
          Constant.session.setData(
            SessionManager.managedByAdmin,
            managedByAdmin ? "1" : "0",
            false,
          );

          Constant.session.setData(
            SessionManager.isSweetHouse,
            isSweetHouse ? "1" : "0",
            false,
          );

          Constant.session.setData(
            SessionManager.isSuperMart,
            isSuperMart ? "1" : "0",
            false,
          );

          Constant.session.setData(
            SessionManager.keyStoreId,
            storeId,
            false,
          );

          // Store FSSAI number from registration data
          if (seller['fssai_number'] != null) {
            Constant.session.setData(
              SessionManager.fssai_number,
              seller['fssai_number'].toString(),
              false,
            );
          }

          // Store store type name from registration data
          if (seller['store_type_name'] != null) {
            Constant.session.setData(
              SessionManager.store_type_name,
              seller['store_type_name'].toString(),
              false,
            );
          }

          // Check if registration is complete
          bool hasPersonalInfo =
              seller['name'] != null && seller['email'] != null;
          bool hasStoreInfo =
              seller['store_name'] != null && seller['store_location'] != null;

          if (!hasPersonalInfo) {
            // No personal data - go to shop type selection first
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => ShopTypeHomeScreen(),
              ),
              (route) => false,
            );
            return;
          } else if (!hasStoreInfo) {
            // Partial data - go to registration (will determine correct step)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FoodRegistrationScreen(storeId: storeId, initialStep: 1),
              ),
              (route) => false,
            );
            return;
          } else {
            // Complete data - check if approved
            final isApproved = seller['is_approved'] == 1 ||
                seller['status'] == 'approved' ||
                seller['approved'] == true;

            if (isApproved) {
              // Approved - go to dashboard
              await context
                  .read<SettingsProvider>()
                  .getSettingsApiProvider({}, context);

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider(
                          create: (_) => BottomNavProvider()),
                    ],
                    child: MainTabScaffold(),
                  ),
                ),
                (route) => false,
              );
              return;
            } else {
              // Not approved - go to step 3 (awaiting approval)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodRegistrationScreen(
                    storeId: storeId,
                    initialStep: 2, // Go to step 3 (index 2)
                  ),
                ),
                (route) => false,
              );
              return;
            }
          }
        }
      }

      // If we reach here, something went wrong with the API
      // Fall back to default navigation
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ShopTypeHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error checking registration status: $e');
      // Fall back to default navigation on error
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ShopTypeHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoginProvider>();
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Stack(
            children: [
              // Background - dynamic (image/gif/video) or fallback asset
              Column(
                children: [
                  _buildBackground(context),
                  // Spacer for the card content below image
                  SizedBox(height: MediaQuery.of(context).size.height*.45)
                ],
              ),
              // SellerWelcomeCard positioned from bottom of image
              Positioned(
                left: 0,
                right: 0,
                top: screenHeight * 0.35,
                child: SellerWelcomeCard(
                  phoneController: phoneController,
                  phoneFocusNode: _phoneFocusNode,
                  showLogo: true,
                  onContinue: () async {
                    if (provider.loading) return;
                    final sent = await provider.sendOtpSellerPhone(
                        context, phoneController.text);
                    if (sent) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OTPScreen(
                            phone: phoneController.text,
                            onOtpEntered: (otp) async {
                              final loginProvider =
                                  context.read<LoginProvider>();
                              final userData =
                                  await loginProvider.verifyOtpSellerPhone(
                                      context, phoneController.text, otp);
                              if (userData != null) {
                                await _checkRegistrationAndNavigate(context);
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Support icon in top right
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: GestureDetector(
                  onTap: _showSupportDialog,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF9AC444),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SellerWelcomeCard extends StatefulWidget {
  final TextEditingController phoneController;
  final FocusNode? phoneFocusNode;
  final VoidCallback onContinue;
  final bool showLogo;

  const SellerWelcomeCard({
    Key? key,
    required this.phoneController,
    this.phoneFocusNode,
    required this.onContinue,
    this.showLogo = true,
  }) : super(key: key);

  @override
  State<SellerWelcomeCard> createState() => _SellerWelcomeCardState();
}

class _SellerWelcomeCardState extends State<SellerWelcomeCard> {
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _loadSavedMobileNumber();
  }

  /// Load mobile number using SMS autofill or local storage
  Future<void> _loadSavedMobileNumber() async {
    String? mobileNumber;
    String source = '';

    try {
      // First, try to get phone number hint from Google Play Services
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
        final savedMobile = Constant.session.getData(SessionManager.mobile);

        if (savedMobile.isNotEmpty && savedMobile.length == 10) {
          mobileNumber = savedMobile;
          source = 'storage';
          debugPrint('📱 Loaded from storage: $mobileNumber');
        }
      }

      // Update UI if number was found
      if (mobileNumber != null && mobileNumber.isNotEmpty && mounted) {
        setState(() {
          widget.phoneController.text = mobileNumber!;
        });
        debugPrint('✅ Mobile number auto-filled from $source');
      }
    } catch (e) {
      debugPrint('❌ Error loading mobile number: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;
    final loginProvider = context.watch<LoginProvider>();

    return Container(
      // width: 353,
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo with "Seller" text - conditionally shown
          if (widget.showLogo) ...[
            Column(
              children: [
                // Logo container
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white,
                      width: 6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/play_store.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // "Seller" text below logo
                Text(
                  'Seller',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
          ],
          // Title and Subtitle
          Column(
            children: [
              Text(
                'WELCOME TO ZENFOO\nSELLER',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFF211F1F),
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Build, manage, and expand your online store — all in one place.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C6969),
                  height: 1.4,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Phone Input Field
          CustomTextFormField(
            onChanged: (value) {
              if (_agreeToTerms) {
                setState(() {});
              }
            },
            controller: widget.phoneController,
            focusNode: widget.phoneFocusNode,
            maxLength: 10,
            prefixIcon: Text(
              '+91',
              style: GoogleFonts.inter(
                color: colorScheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.02,
                letterSpacing: -0.55,
              ),
            ).centered().w(24),
            title: '',
            hintText: 'Enter your Mobile number',
            keyboardType: TextInputType.phone,
          ),

          SizedBox(height: 12),
          // Terms and Conditions Checkbox
          Row(
            children: [
              Checkbox(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                value: _agreeToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                },
                activeColor: Color(0xFF9AC444),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'I agree to the ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C6969),
                        ),
                      ),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9AC444),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrl(
                              Uri.parse('${Constant.hostUrl}api/seller-terms-conditions'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                      ),
                      TextSpan(
                        text: ' and ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C6969),
                        ),
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9AC444),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchUrl(
                              Uri.parse('${Constant.hostUrl}api/seller-privacy-policy'),
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

          SizedBox(height: 12),
          // Continue Button
          GestureDetector(
            onTap: (_agreeToTerms &&
                    !loginProvider.loading &&
                    widget.phoneController.text.length == 10)
                ? () {
                    // Save mobile number to session before continuing
                    Constant.session.setData(
                      SessionManager.mobile,
                      widget.phoneController.text,
                      false,
                    );
                    widget.onContinue();
                  }
                : null,
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: (_agreeToTerms &&
                        !loginProvider.loading &&
                        widget.phoneController.text.length == 10)
                    ? Color(0xFF9AC444)
                    : Color(0xFF9AC444).withValues(alpha: 0.6),
              ),
              child: loginProvider.loading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        color: Color(0xFFEBEBEB),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
            ).disabled(!_agreeToTerms ||
                loginProvider.loading ||
                widget.phoneController.text.length != 10),
          ),
        ],
      ),
    );
  }
}
