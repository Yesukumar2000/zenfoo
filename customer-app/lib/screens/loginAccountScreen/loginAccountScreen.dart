import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/utils/keyboardOverlay.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:video_player/video_player.dart';

// enum AuthProviders { phone, google, apple, emailPassword }
enum AuthProviders { phone, apple }

class LoginAccountScreen extends StatefulWidget {
  final String? from;

  const LoginAccountScreen({Key? key, this.from}) : super(key: key);

  @override
  State<LoginAccountScreen> createState() => _LoginAccountState();
}

class _LoginAccountState extends State<LoginAccountScreen> {
  CountryCode selectedCountryCode = CountryCode(dialCode: '+91', code: 'IN');

  TextEditingController editMobileTextEditingController =
      TextEditingController(text: "");
  final TextEditingController editEmailTextEditingController =
      TextEditingController();
  final TextEditingController editPasswordTextEditingController =
      TextEditingController();
  final TextEditingController editPhonePasswordTextEditingController =
      TextEditingController();
  final TextEditingController editReferralCodeTextEditingController =
      TextEditingController();
  final pinController = TextEditingController();
  String otpVerificationId = "";
  int? forceResendingToken;
  bool showMobileNumberWidget = Constant.authTypePhoneLogin == "1",
      showOtpWidget = false,
      isLoading = false;

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  // GoogleSignIn googleSignIn = GoogleSignIn(scopes: ["profile", "email"]);

  AuthProviders authProvider = AuthProviders.phone;

  //  Constant.authTypePhoneLogin == "1"
  //     ? AuthProviders.phone
  //     : Constant.authTypeEmailLogin == "1"
  //         ? AuthProviders.emailPassword
  //         : Constant.authTypeGoogleLogin == "1"
  //             ? AuthProviders.google
  //             : AuthProviders.apple;

  final _formKey = GlobalKey<FormState>();
  String? fcmToken = "";
  bool termsAccepted = true;

  // Inline referral-code validation state (non-blocking feedback).
  Timer? _referralDebounce;
  bool _referralChecking = false;
  bool? _referralValid; // null = unchecked, true/false = result
  String _referralMessage = "";

  // The referral field stays hidden behind a disclosure button — most users
  // do not have a code, and an always-visible optional field reads as required.
  bool _showReferralField = false;
  final FocusNode _referralFocusNode = FocusNode();

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: (_isVideoInitialized && _videoController != null)
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    : Image.asset(
                        'assets/images/background_img.png',
                        fit: BoxFit.contain,
                      ),
              ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Image.asset(
                        'assets/images/zenfoLogo.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    // child:
                    loginWidgets(),
                    // ),
                  ],
                ),
              ),
              // Positioned(
              //   top: MediaQuery.of(context).padding.top + 8,
              //   right: 16,
              //   child: skipLoginText(),
              // ),
              if (isLoading && authProvider != AuthProviders.phone)
                Positioned.fill(
                  child: Container(
                    color: colorScheme.overlay,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
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

 Widget skipLoginText() {
  return GestureDetector(
    onTap: () async {
      if (isLoading == false) {
        HapticFeedback.lightImpact();
        Constant.session.setBoolData(SessionManager.keySkipLogin, true, false);
        await getRedirection();
      }
    },
    child: Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 7),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // light bg

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.7), // soft black border
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.15), // black shadow glow
            blurRadius: 10,
            spreadRadius: 1.5,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Text(
        getTranslatedValue(context, skipLoginLabel),
        style: GoogleFonts.inter(
          color: Colors.black, // ✅ black text
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
  );
}

  Widget proceedBtn(
      BuildContext context,
      bool isLoading,
      AuthProviders authProvider,
      bool showMobileNumberWidget,
      GlobalKey<FormState> _formKey,
      Function loginWithPhoneNumber,
      String continueLabel,
      String Function(BuildContext, String) getTranslatedValue,
      bool termsAccepted) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isMobileValid = editMobileTextEditingController.text.length == 10;
    final isButtonEnabled = termsAccepted && !isLoading && isMobileValid;

    return (isLoading && authProvider == AuthProviders.phone)
        ? Container(
            height: 46,
            width: double.infinity,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          )
        : GestureDetector(
            onTap: isButtonEnabled
                ? () {
                    HapticFeedback.lightImpact();
                    if (showMobileNumberWidget &&
                        authProvider != AuthProviders.phone) {
                      authProvider = AuthProviders.phone;
                    }
                    _formKey.currentState!.save();
                    if (_formKey.currentState!.validate()) {
                      if (authProvider == AuthProviders.phone) {
                        loginWithPhoneNumber();
                      }
                    }
                  }
                : null,
            child: Container(
              width: double.infinity,
              height: 52,
              padding: const EdgeInsets.all(10),
              decoration: ShapeDecoration(
                color: isButtonEnabled
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                getTranslatedValue(context, continueLabel),
                style: GoogleFonts.inter(
                  color: colorScheme.buttonPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
  }

  Widget loginWidgets() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Zenfoo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    letterSpacing: -0.55,
                  ),
                ),
                getSizedBox(height: 6),
                Text(
                  'Login with mobile number',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: colorScheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.26,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 24,
          ),

          if (Constant.authTypePhoneLogin == "1" ||
              Constant.authTypeEmailLogin == "1") ...[
            // getSizedBox(height: Constant.size40),
            AnimatedOpacity(
              opacity: showMobileNumberWidget ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Visibility(
                visible: showMobileNumberWidget,
                child: Container(
                  margin:
                      EdgeInsetsDirectional.only(start: 20, end: 20, top: 6),
                  child: mobilePasswordWidget(),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: (showMobileNumberWidget && _showReferralField) ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Visibility(
                visible: showMobileNumberWidget && _showReferralField,
                child: Container(
                  margin:
                      EdgeInsetsDirectional.only(start: 20, end: 20, top: 12),
                  child: referralCodeWidget(),
                ),
              ),
            ),
            // AnimatedOpacity(
            //   opacity: !showMobileNumberWidget ? 1.0 : 0.0,
            //   duration: Duration(milliseconds: 300),
            //   child: Visibility(
            //     visible: !showMobileNumberWidget,
            //     child: Container(
            //       margin: EdgeInsetsDirectional.only(start: 20, end: 20),
            //       child: emailPasswordWidget(),
            //     ),
            //   ),
            // ),

            getSizedBox(height: Constant.size20),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 20, end: 20),
              child: SafeArea(
                top: false,
                child: proceedBtn(
                  context,
                  isLoading,
                  authProvider,
                  showMobileNumberWidget,
                  _formKey,
                  loginWithPhoneNumber,
                  continueLabel,
                  getTranslatedValue,
                  termsAccepted,
                ),
              ),
            ),
            getSizedBox(height: Constant.size10),
            if (showMobileNumberWidget && !_showReferralField)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 20, end: 20),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _revealReferralField,
                    icon: Icon(
                      Icons.card_giftcard_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      getTranslatedValue(context, haveReferralCodeLabel),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsetsDirectional.only(start: 20, end: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        termsAccepted = !termsAccepted;
                      });
                    },
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: termsAccepted ? colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: termsAccepted ? colorScheme.primary : colorScheme.textSecondary,
                          width: 1.5,
                        ),
                      ),
                      child: termsAccepted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'I accept ',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'terms and conditions',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                HapticFeedback.lightImpact();
                                launchUrl(
                                  Uri.parse(
                                      '${Constant.hostUrl}customer/terms-conditions'),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                          ),
                          TextSpan(
                            text: ' & ',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: colorScheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                HapticFeedback.lightImpact();
                                launchUrl(
                                  Uri.parse(
                                      '${Constant.hostUrl}customer/privacy-policy'),
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
            // getSizedBox(height: Constant.size20),
            // Center(
            //   child: GestureDetector(
            //     onTap: () {
            //       HapticFeedback.lightImpact();
            //       // Navigator.of(context).pushNamed(
            //       //   editProfileScreen,
            //       //   arguments: [
            //       //     !showMobileNumberWidget ? "email_register" : "mobile_register",
            //       //     {
            //       //       ApiAndParams.type: !showMobileNumberWidget ? "email": "phone",
            //       //       ApiAndParams.fcmToken: fcmToken, //Constant.session.getData(SessionManager.keyFCMToken),
            //       //     }
            //       //   ],
            //       // );
            //     },
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 20,
            //       ),
            //       child: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         children: [
            //           CustomTextLabel(
            //             jsonKey: dontHaveAccountLabel,
            //             style: GoogleFonts.inter(
            //               color: colorScheme.textSecondary,
            //               fontWeight: FontWeight.w500,
            //               fontSize: 14,
            //               letterSpacing: -0.2,
            //             ),
            //           ),
            //           CustomTextLabel(
            //             jsonKey: "${wantsToRegisterLabel}",
            //             style: GoogleFonts.inter(
            //               color: colorScheme.primary,
            //               fontWeight: FontWeight.w700,
            //               fontSize: 14,
            //               letterSpacing: -0.2,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            getSizedBox(height: Constant.size20),
            // if (Platform.isIOS && Constant.authTypeAppleLogin == "1" || Constant.authTypeGoogleLogin == "1") buildDottedDivider(context),
            // getSizedBox(height: Constant.size20),
          ],
          // if (Platform.isIOS && Constant.authTypeAppleLogin == "1") ...[
          //   Padding(
          //     padding: EdgeInsetsDirectional.only(start: 20, end: 20),
          //     child: SocialMediaLoginButtonWidget(
          //       text: continueWithAppleLabel,
          //       logo: AppAssets.appleLogoIcon,
          //       logoColor: ColorsRes.mainTextColor,
          //       onPressed: () async {
          //         setState(() {
          //           authProvider = AuthProviders.apple;
          //         });
          //         await signInWithApple(
          //           context: context,
          //           firebaseAuth: firebaseAuth,
          //           googleSignIn: googleSignIn,
          //         ).then(
          //           (value) {
          //             print("applelogindetail:${value.runtimeType}--${value}");
          //             setState(() {
          //               isLoading = true;
          //             });
          //             if (value is UserCredential) {
          //               setState(() {
          //                 isLoading = false;
          //               });
          //               print("applelogindetailinsidetypecasting:${value.runtimeType}--${value}");
          //               backendApiProcess(value.user);
          //             } else {
          //               setState(() {
          //                 isLoading = false;
          //               });
          //               showMessage(context, value.toString(), MessageType.error);
          //             }
          //           },
          //         );
          //       },
          //     ),
          //   ),
          //   getSizedBox(height: 10),
          // ],

          // if (Constant.authTypeGoogleLogin == "1")
          //   Padding(
          //     padding: EdgeInsetsDirectional.only(start: 20, end: 20),
          //     child: SocialMediaLoginButtonWidget(
          //       text: continueWithGoogleLabel,
          //       logo: AppAssets.googleLogoIcon,
          //       onPressed: () async {
          //         setState(() {
          //           authProvider = AuthProviders.google;
          //         });
          //         signOut(googleSignIn: googleSignIn, authProvider: authProvider, firebaseAuth: firebaseAuth).then(
          //           (value) async {
          //             await signInWithGoogle(
          //               context: context,
          //               firebaseAuth: firebaseAuth,
          //               googleSignIn: googleSignIn,
          //             ).then(
          //               (value) {
          //                 if (value is UserCredential) {
          //                   backendApiProcess(value.user);
          //                 } else {
          //                   showMessage(context, value.toString(), MessageType.error);
          //                 }
          //               },
          //             );
          //           },
          //         );
          //       },
          //     ),
          //   ),

          // if ( Constant.authTypePhoneLogin == "1") ...[
          // if (showMobileNumberWidget)
          //   Padding(
          //     padding: EdgeInsetsDirectional.only(start: 20, end: 20),
          //     child: SocialMediaLoginButtonWidget(
          //       text: continueWithEmailLabel,
          //       logo: AppAssets.emailLogoIcon,
          //       logoColor: ColorsRes.appColor,
          //       onPressed: () async {
          //         setState(() {
          //           authProvider = AuthProviders.emailPassword;
          //           showMobileNumberWidget = false;
          //         });
          //       },
          //     ),
          //   ),
          if (!showMobileNumberWidget)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 20, end: 20),
              child: SocialMediaLoginButtonWidget(
                text: continueWithPhoneLabel,
                logo: AppAssets.phoneLogoIcon,
                logoColor: colorScheme.primary,
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  setState(() {
                    authProvider = AuthProviders.phone;
                    showMobileNumberWidget = true;
                  });
                },
              ),
            ),
        ],
        // getSizedBox(height: Constant.size20),
        // Divider(color: ColorsRes.subTitleMainTextColor),
        // getSizedBox(height: Constant.size20),
        // Padding(
        //   padding: EdgeInsetsDirectional.only(start: 30, end: 30),
        //   child: Center(
        //     child: RichText(
        //       textAlign: TextAlign.start,
        //       text: TextSpan(
        //         style: Theme.of(context).textTheme.titleSmall!.merge(
        //               TextStyle(
        //                 fontWeight: FontWeight.w400,
        //                 color: ColorsRes.subTitleMainTextColor,
        //               ),
        //             ),
        //         text: "${getTranslatedValue(
        //           context,
        //           agreementMessage1Label,
        //         )}\t",
        //         children: <TextSpan>[
        //           TextSpan(
        //               text: getTranslatedValue(context, termsOfServiceLabel),
        //               style: TextStyle(
        //                 color: ColorsRes.appColor,
        //                 fontWeight: FontWeight.w500,
        //               ),
        //               recognizer: TapGestureRecognizer()
        //                 ..onTap = () {
        //                   Navigator.pushNamed(context, webViewScreen,
        //                       arguments: getTranslatedValue(
        //                         context,
        //                         termsAndConditionsLabel,
        //                       ));
        //                 }),
        //           TextSpan(
        //               text: "\t${getTranslatedValue(
        //                 context,
        //                 andLabel,
        //               )}\t",
        //               style: TextStyle(
        //                 color: ColorsRes.subTitleMainTextColor,
        //               )),
        //           TextSpan(
        //             text: getTranslatedValue(context, privacyPolicyLabel),
        //             style: TextStyle(
        //               color: ColorsRes.appColor,
        //               fontWeight: FontWeight.w500,
        //             ),
        //             recognizer: TapGestureRecognizer()
        //               ..onTap = () {
        //                 Navigator.pushNamed(
        //                   context,
        //                   webViewScreen,
        //                   arguments: getTranslatedValue(
        //                     context,
        //                     privacyPolicyLabel,
        //                   ),
        //                 );
        //               },
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
        // getSizedBox(height: Constant.size20),
        // ],
      ),
    );
  }

  mobilePasswordWidget() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: showMobileNumberWidget ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: Visibility(
            visible: showMobileNumberWidget,
            child: /* Container(
              decoration: DesignConfig.boxDecoration(Theme.of(context).scaffoldBackgroundColor, 10, bordercolor: ColorsRes.subTitleMainTextColor, isboarder: true, borderwidth: 1.0),
              child: Row(
                children: [
                  getSizedBox(width: Constant.size5),
                  IgnorePointer(
                    ignoring: isLoading,
                    child: CountryCodePicker(
                      onInit: (countryCode) {
                        selectedCountryCode = countryCode;
                      },
                      onChanged: (countryCode) {
                        selectedCountryCode = countryCode;
                      },
                      initialSelection: Constant.initialCountryCode,
                      textOverflow: TextOverflow.ellipsis,
                      backgroundColor: Theme.of(context).cardColor,
                      textStyle: TextStyle(color: ColorsRes.mainTextColor),
                      dialogBackgroundColor: Theme.of(context).cardColor,
                      dialogSize: Size(context.width, context.height),
                      barrierColor: ColorsRes.subTitleMainTextColor,
                      padding: EdgeInsets.zero,
                      searchDecoration: InputDecoration(
                        iconColor: ColorsRes.subTitleMainTextColor,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorsRes.subTitleMainTextColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorsRes.subTitleMainTextColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorsRes.subTitleMainTextColor),
                        ),
                        focusColor: Theme.of(context).scaffoldBackgroundColor,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: ColorsRes.subTitleMainTextColor,
                        ),
                      ),
                      searchStyle: TextStyle(
                        color: ColorsRes.subTitleMainTextColor,
                      ),
                      dialogTextStyle: TextStyle(
                        color: ColorsRes.mainTextColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: ColorsRes.grey,
                    size: 15,
                  ),
                  getSizedBox(width: Constant.size10),
                  Expanded(
                    child: TextFormField(
                      controller: editMobileTextEditingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: TextStyle(
                        color: ColorsRes.mainTextColor,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(
                          color: ColorsRes.grey.withValues(alpha: 0.8),
                        ),
                        hintText: getTranslatedValue(context, phoneNumberHintLabel),
                      ),
                    ),
                  )
                ],
              ),
            ) */
                CustomTextFormField(
              title: "",
              hintText: "Enter your Mobile number",
              controller: editMobileTextEditingController,
              // validator: (value) => phoneValidation(value),
              keyboardType: TextInputType.number,
              focusNode: Platform.isIOS ? focusNode : FocusNode(),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
              maxLength: 10,
              prefixIcon: Text(
                "+91",
                style: GoogleFonts.inter(
                  color: ColorsRes.mainTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.05,
                ),
              ),
            ),
            // editBoxWidget(
            //   context,
            //   editMobileTextEditingController,
            //   showMobileNumberWidget
            //       ? (value) => phoneValidation(value)
            //       : (value) => optionalValidation(value), // Validator
            //   getTranslatedValue(context, phoneNumberHintLabel), // Label
            //   getTranslatedValue(context, enterValidMobileLabel), // Error Label
            //   TextInputType.number,
            //   focusNode: Platform.isIOS ? focusNode : FocusNode(),
            //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],

            /// 👇 Prefix: Country Code Picker with dropdown arrow
            // leadingIcon: Row(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     IgnorePointer(
            //       ignoring: isLoading,
            //       child: CountryCodePicker(
            //         onInit: (countryCode) {
            //           selectedCountryCode = countryCode;
            //         },
            //         onChanged: (countryCode) {
            //           selectedCountryCode = countryCode;
            //         },
            //         initialSelection: (widget.from != "header")
            //             ? Constant.initialCountryCode
            //             : CountryCode.fromDialCode(
            //                 Constant.session
            //                     .getData(SessionManager.keyCountryCode),
            //               ).code,
            //         textOverflow: TextOverflow.ellipsis,
            //         backgroundColor: Theme.of(context).cardColor,
            //         textStyle: TextStyle(color: ColorsRes.mainTextColor),
            //         dialogBackgroundColor: Theme.of(context).cardColor,
            //         dialogSize: Size(context.width, context.height),
            //         barrierColor: ColorsRes.subTitleMainTextColor,
            //         padding: EdgeInsets.zero,
            //         searchDecoration: InputDecoration(
            //           iconColor: ColorsRes.subTitleMainTextColor,
            //           fillColor: Theme.of(context).cardColor,
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(10),
            //             borderSide: BorderSide(
            //                 color: ColorsRes.subTitleMainTextColor),
            //           ),
            //           enabledBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(10),
            //             borderSide: BorderSide(
            //                 color: ColorsRes.subTitleMainTextColor),
            //           ),
            //           focusedBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(10),
            //             borderSide: BorderSide(
            //                 color: ColorsRes.subTitleMainTextColor),
            //           ),
            //           prefixIcon: Icon(
            //             Icons.search_rounded,
            //             color: ColorsRes.subTitleMainTextColor,
            //           ),
            //         ),
            //         searchStyle:
            //             TextStyle(color: ColorsRes.subTitleMainTextColor),
            //         dialogTextStyle:
            //             TextStyle(color: ColorsRes.mainTextColor),
            //       ),
            //     ),
            //     Icon(Icons.keyboard_arrow_down,
            //         color: ColorsRes.grey, size: 15),
            //   ],
            // ),
            // ),
          ),
        ),
        (context.read<AppSettingsProvider>().settingsData!.phoneAuthPassword ==
                "1")
            ? getSizedBox(height: Constant.size20)
            : const SizedBox.shrink(),
        (context.read<AppSettingsProvider>().settingsData!.phoneAuthPassword ==
                "1")
            ? AnimatedOpacity(
                opacity: showMobileNumberWidget ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Visibility(
                  visible: showMobileNumberWidget,
                  child: Consumer<PasswordShowHideProvider>(
                    builder: (context, provider, child) {
                      return editBoxWidget(
                        context,
                        editPhonePasswordTextEditingController,
                        (context
                                    .read<AppSettingsProvider>()
                                    .settingsData!
                                    .phoneAuthPassword ==
                                "1")
                            ? (value) => emptyValidation(value)
                            : (value) => optionalValidation(value),
                        getTranslatedValue(
                          context,
                          passwordLabel,
                        ),
                        getTranslatedValue(
                          context,
                          enterValidPasswordLabel,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        leadingIcon: Icon(
                          Icons.password_rounded,
                          color: colorScheme.iconSecondary,
                          size: 25,
                        ),
                        maxLines: 1,
                        fillColor: colorScheme.inputBackground,
                        obscureText: provider.isPasswordShowing(),
                        tailIcon: GestureDetector(
                          onTap: () {
                            provider.togglePasswordVisibility();
                          },
                          child: defaultImg(
                            image: provider.isPasswordShowing()
                                ? AppAssets.hidePasswordIcon
                                : AppAssets.showPasswordIcon,
                            iconColor: colorScheme.iconSecondary,
                            width: 13,
                            height: 13,
                            padding: EdgeInsetsDirectional.all(12),
                          ),
                        ),
                        optionalTextInputAction: TextInputAction.done,
                        TextInputType.text,
                      );
                    },
                  ),
                ),
              )
            : const SizedBox.shrink(),
        (context.read<AppSettingsProvider>().settingsData!.phoneAuthPassword ==
                "1")
            ? getSizedBox(height: Constant.size10)
            : const SizedBox.shrink(),
        (context.read<AppSettingsProvider>().settingsData!.phoneAuthPassword ==
                "1")
            ? Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(forgotPasswordScreen,
                        arguments: [true, "user_exist"]);
                  },
                  child: CustomTextLabel(
                    jsonKey: forgotPasswordLabel,
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: colorScheme.primary,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  // Reveals the referral field and focuses it, so the keyboard opens and the
  // field is scrolled into view — the button that triggers this sits further
  // down the form, so without the focus the field could appear off-screen.
  void _revealReferralField() {
    HapticFeedback.lightImpact();
    setState(() => _showReferralField = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _referralFocusNode.requestFocus();
    });
  }

  // Debounced, non-blocking validation of the entered referral code. Stale
  // responses (field changed again before the request returned) are ignored.
  void _onReferralCodeChanged(String value) {
    final code = value.trim();
    _referralDebounce?.cancel();

    if (code.isEmpty) {
      setState(() {
        _referralChecking = false;
        _referralValid = null;
        _referralMessage = "";
      });
      return;
    }

    setState(() {
      _referralChecking = true;
      _referralValid = null;
      _referralMessage = "";
    });

    _referralDebounce = Timer(const Duration(milliseconds: 600), () async {
      final result =
          await validateReferralCodeApi(context: context, referralCode: code);
      if (!mounted ||
          editReferralCodeTextEditingController.text.trim() != code) {
        return;
      }
      setState(() {
        _referralChecking = false;
        _referralValid = result['valid'] == true;
        _referralMessage = (result['message'] ?? "").toString();
      });
    });
  }

  Widget? _referralStatusSuffix(dynamic colorScheme) {
    if (_referralChecking) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.iconSecondary),
        ),
      );
    }
    if (_referralValid == true) {
      return Icon(Icons.check_circle_rounded,
          size: 20, color: colorScheme.success);
    }
    if (_referralValid == false) {
      return Icon(Icons.cancel_rounded, size: 20, color: colorScheme.error);
    }
    return null;
  }

  Widget referralCodeWidget() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFormField(
          title: "",
          hintText: "Referral code (optional)",
          controller: editReferralCodeTextEditingController,
          focusNode: _referralFocusNode,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          maxLines: 1,
          showClearButton: false,
          onChanged: _onReferralCodeChanged,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          prefixIcon: Icon(
            Icons.card_giftcard_rounded,
            size: 20,
            color: colorScheme.iconSecondary,
          ),
          suffixIcon: _referralStatusSuffix(colorScheme),
        ),
        // Non-blocking status line: tells the user whether the code will apply.
        if (_referralValid != null && _referralMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _referralMessage,
              style: GoogleFonts.inter(
                color: _referralValid == true
                    ? colorScheme.success
                    : colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }

  // emailPasswordWidget() {
  //   return Column(
  //     children: [
  //       editBoxWidget(
  //         context,
  //         editEmailTextEditingController,
  //         (value) => emailValidation(value),
  //         getTranslatedValue(
  //           context,
  //           emailLabel,
  //         ),
  //         getTranslatedValue(
  //           context,
  //           enterValidEmailLabel,
  //         ),
  //         floatingLabelBehavior: FloatingLabelBehavior.never,
  //         leadingIcon: Icon(
  //           Icons.alternate_email_outlined,
  //           color: ColorsRes.grey,
  //           size: 25,
  //         ),
  //         maxLines: 1,
  //         fillColor: Theme.of(context).scaffoldBackgroundColor,
  //         TextInputType.emailAddress,
  //       ),
  //       getSizedBox(height: Constant.size20),
  //       Consumer<PasswordShowHideProvider>(
  //         builder: (context, provider, child) {
  //           return editBoxWidget(
  //             context,
  //             editPasswordTextEditingController,
  //             (value) => emptyValidation(value),
  //             getTranslatedValue(
  //               context,
  //               passwordLabel,
  //             ),
  //             getTranslatedValue(
  //               context,
  //               enterValidPasswordLabel,
  //             ),
  //             floatingLabelBehavior: FloatingLabelBehavior.never,
  //             leadingIcon: Icon(
  //               Icons.password_rounded,
  //               color: ColorsRes.grey,
  //               size: 25,
  //             ),
  //             maxLines: 1,
  //             fillColor: Theme.of(context).scaffoldBackgroundColor,
  //             obscureText: provider.isPasswordShowing(),
  //             tailIcon: GestureDetector(
  //               onTap: () {
  //                 provider.togglePasswordVisibility();
  //               },
  //               child: defaultImg(
  //                 image: provider.isPasswordShowing() == true ? AppAssets.hidePasswordIcon : AppAssets.showPasswordIcon,
  //                 iconColor: ColorsRes.grey,
  //                 width: 13,
  //                 height: 13,
  //                 padding: EdgeInsetsDirectional.all(12),
  //               ),
  //             ),
  //             optionalTextInputAction: TextInputAction.done,
  //             TextInputType.text,
  //           );
  //         },
  //       ),
  //       getSizedBox(height: Constant.size10),
  //       Align(
  //         alignment: AlignmentDirectional.centerEnd,
  //         child: GestureDetector(
  //           onTap: () {
  //             Navigator.of(context).pushNamed(forgotPasswordScreen, arguments: [false, "user_exist"]);
  //           },
  //           child: CustomTextLabel(
  //             jsonKey: forgotPasswordLabel,
  //             style: TextStyle(
  //               color: ColorsRes.appColor,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ),
  //       ),
  //       if (showOtpWidget) getSizedBox(height: Constant.size10),
  //       if (showOtpWidget)
  //         AnimatedOpacity(
  //           opacity: showOtpWidget ? 1.0 : 0.0,
  //           duration: Duration(milliseconds: 300),
  //           child: Visibility(
  //             visible: showOtpWidget,
  //             child: Column(
  //               children: [SizedBox(height: Constant.size15),CustomTextLabel(
  //             jsonKey: emailVerificationNoteLabel,
  //             style: TextStyle(
  //               color: ColorsRes.appColor,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ), SizedBox(height: Constant.size15), otpPinWidget(context: context, pinController: pinController)],
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  getRedirection() async {
    if (Constant.session.getBoolData(SessionManager.keySkipLogin) ||
        Constant.session.getBoolData(SessionManager.isUserLogin)) {
      Navigator.pushReplacementNamed(
        context,
        mainHomeScreen,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        mainHomeScreen,
        (route) => false,
      );
    }
  }

  Future<bool> fieldValidation() async {
    bool checkInternet = await checkInternetConnection();
    if (!checkInternet) {
      showMessage(
        context,
        getTranslatedValue(
          context,
          checkInternetLabel,
        ),
        MessageType.warning,
      );
      return false;
    } else if (authProvider == AuthProviders.phone) {
      String? mobileValidate = await phoneValidation(
        editMobileTextEditingController.text,
      );
      if (mobileValidate == "") {
        showMessage(
          context,
          getTranslatedValue(
            context,
            enterValidMobileLabel,
          ),
          MessageType.warning,
        );
        return false;
      } else if (mobileValidate != null &&
          editMobileTextEditingController.text.length > 15) {
        showMessage(
          context,
          getTranslatedValue(
            context,
            enterValidMobileLabel,
          ),
          MessageType.warning,
        );
        return false;
      } else {
        return true;
      }
    }
    //  else if (authProvider == AuthProviders.emailPassword) {
    //   /* String? emailValidate = await emailValidation(
    //     editEmailTextEditingController.text,
    //   );

    //   String? passwordValidate = await emptyValidation(
    //     editPasswordTextEditingController.text,
    //   );

    //   if (emailValidate == "") {
    //     showMessage(
    //       context,
    //       getTranslatedValue(
    //         context,
    //         enterValidEmailLabel,
    //       ),
    //       MessageType.warning,
    //     );
    //     return false;
    //   } else if (passwordValidate == "") {
    //     showMessage(
    //       context,
    //       getTranslatedValue(
    //         context,
    //         enterValidPasswordLabel,
    //       ),
    //       MessageType.warning,
    //     );
    //     return false;
    //   } else if (editPasswordTextEditingController.text.length <= 5) {
    //     showMessage(
    //       context,
    //       getTranslatedValue(
    //         context,
    //         passwordTooShortLabel,
    //       ),
    //       MessageType.warning,
    //     );
    //     return false;
    //   } else {
    //     return true;
    //   } */
    //   return true;
    // }

    else {
      return false;
    }
  }

  loginWithPhoneNumber() async {
    var validation = await fieldValidation();
    if (validation) {
      if (isLoading) return;
      setState(() {
        isLoading = true;
      });
      firebaseLoginProcess();
    }
  }

  // loginWithEmailIdPassword() async {
  //   var validation = (await fieldValidation());
  //   if (validation) {
  //     if (isLoading) return;
  //     setState(() {
  //       isLoading = true;
  //     });
  //     backendApiProcess(null);
  //   }
  // }

  firebaseLoginProcess() async {
    setState(() {});
    if (editMobileTextEditingController.text.isNotEmpty) {
      if (context.read<AppSettingsProvider>().settingsData!.phoneAuthPassword ==
          "1") {
        callLoginApi(null);
      } else {
        // if (context
        //         .read<AppSettingsProvider>()
        //         .settingsData!
        //         .firebaseAuthentication ==
        //     "1") {
        //   await firebaseAuth.verifyPhoneNumber(
        //     timeout: Duration(minutes: 1, seconds: 30),
        //     phoneNumber:
        //         '${selectedCountryCode!.dialCode}${editMobileTextEditingController.text}',
        //     verificationCompleted: (PhoneAuthCredential credential) {},
        //     verificationFailed: (FirebaseAuthException e) {
        //       showMessage(
        //         context,
        //         e.message!,
        //         MessageType.warning,
        //       );
        //       setState(() {
        //         isLoading = false;
        //       });
        //     },
        //     codeSent: (String verificationId, int? resendToken) {
        //       forceResendingToken = resendToken;
        //       isLoading = false;
        //       setState(() {
        //         otpVerificationId = verificationId;
        //         List<dynamic> firebaseArguments = [
        //           firebaseAuth,
        //           otpVerificationId,
        //           editMobileTextEditingController.text,
        //           selectedCountryCode!,
        //           widget.from ?? null
        //         ];
        //         Navigator.pushNamed(context, otpScreen,
        //             arguments: firebaseArguments);
        //       });
        //     },
        //     codeAutoRetrievalTimeout: (String verificationId) {
        //       if (mounted) {
        //         setState(() {
        //           isLoading = false;
        //         });
        //       }
        //     },
        //     forceResendingToken: forceResendingToken,
        //   );
        // }
        // else if
        //  (Constant.customSmsGatewayOtpBased == "1") {
        context.read<UserProfileProvider>().sendCustomOTPSmsProvider(
          context: context,
          params: {
            ApiAndParams.phone: "${editMobileTextEditingController.text}",
            ApiAndParams.countryCode: "+91",
          },
        ).then(
          (value) {
            if (value == "1") {
              List<dynamic> firebaseArguments = [
                firebaseAuth,
                otpVerificationId,
                editMobileTextEditingController.text,
                selectedCountryCode,
                widget.from ?? null,
                editReferralCodeTextEditingController.text.trim(),
              ];
              Navigator.pushNamed(context, otpScreen,
                  arguments: firebaseArguments);

              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
            } else {
              setState(() {
                isLoading = false;
              });
              showMessage(
                context,
                getTranslatedValue(
                  context,
                  smsGatewayErrorLabel,
                ),
                MessageType.warning,
              );
            }
          },
        );
        //   }
      }
    }
  }

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (mounted) {
        bool hasFocus = focusNode.hasFocus;
        if (hasFocus) {
          KeyboardOverlay.showOverlay(context);
        } else {
          KeyboardOverlay.removeOverlay();
        }
      }
    });
    fcmTokendata();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      final response =
          await fetchAppMedia(context: context, type: 'login_animation');
      if (response['status'] == 1 && response['data'] != null) {
        final videoUrl = response['data']['login_animation'];
        if (videoUrl != null && videoUrl.toString().isNotEmpty) {
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl.toString()),
          );
          await controller.initialize();
          if (mounted) {
            _videoController = controller;
            controller.setLooping(true);
            controller.setVolume(0);
            controller.play();
            setState(() {
              _isVideoInitialized = true;
            });
          } else {
            controller.dispose();
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Video player init error: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    focusNode.removeListener(() {});
    focusNode.dispose();
    editMobileTextEditingController.dispose();
    editEmailTextEditingController.dispose();
    editPasswordTextEditingController.dispose();
    editPhonePasswordTextEditingController.dispose();
    editReferralCodeTextEditingController.dispose();
    _referralFocusNode.dispose();
    _referralDebounce?.cancel();
    pinController.dispose();
    KeyboardOverlay.removeOverlay();
    super.dispose();
  }

  backendApiProcess(User? user) async {
    if (showOtpWidget && pinController.text.isNotEmpty) {
      context
          .read<UserProfileProvider>()
          .verifyRegisteredEmailProvider(
              context: context,
              params: {
                ApiAndParams.code: pinController.text,
              },
              from: "login")
          .then(
        (value) async {
          await callLoginApi(user);
        },
      );
    } else {
      await callLoginApi(user);
    }
  }

  Future<String> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken() ?? "";
    } catch (e) {
      return "";
    }
  }

  fcmTokendata() async {
    fcmToken = await getFCMToken();
  }

  Future callLoginApi(User? user) async {
    Map<String, String> params = {
      ApiAndParams.id: authProvider == AuthProviders.phone
          ? editMobileTextEditingController.text
          // : authProvider == AuthProviders.emailPassword
          //     ? editEmailTextEditingController.text
          : user?.email.toString() ?? "",
      ApiAndParams.type: authProvider == AuthProviders.phone
          ? "phone"
          //     : authProvider == AuthProviders.google
          //         ? "google"
          //         : authProvider == AuthProviders.apple
          //             ? "apple"
          //             : authProvider == AuthProviders.emailPassword
          //                 ? "email"
          : "",
      ApiAndParams.platform: Platform.isAndroid ? "android" : "ios",
      ApiAndParams.fcmToken:
          fcmToken!, //Constant.session.getData(SessionManager.keyFCMToken),
    };

    // if (authProvider == AuthProviders.emailPassword) {
    //   params[ApiAndParams.password] = editPasswordTextEditingController.text.trim();
    // }
    if (authProvider == AuthProviders.phone) {
      params[ApiAndParams.password] =
          editPhonePasswordTextEditingController.text.trim();
      params[ApiAndParams.phoneAuthType] = (context
                  .read<AppSettingsProvider>()
                  .settingsData!
                  .phoneAuthPassword ==
              "1")
          ? "phone_auth_password"
          : "phone_auth_otp";
    }

    await context
        .read<UserProfileProvider>()
        .loginApi(context: context, params: params)
        .then(
      (value) async {
        isLoading = false;
        setState(() {});
        if (value == 1) {
          if (widget.from == "add_to_cart") {
            addGuestCartBulkToCartWhileLogin(
              context: context,
              params: Constant.setGuestCartParams(
                cartList: context.read<CartListProvider>().cartList,
              ),
            ).then((value) {
              Navigator.pop(context);
              Navigator.pop(context);
            }); 
          } else if (Constant.session.getBoolData(SessionManager.isUserLogin)) {
            if (context.read<CartListProvider>().cartList.isNotEmpty) {
              addGuestCartBulkToCartWhileLogin(
                context: context,
                params: Constant.setGuestCartParams(
                  cartList: context.read<CartListProvider>().cartList,
                ),
              ).then(
                (value) => Navigator.of(context).pushNamedAndRemoveUntil(
                  mainHomeScreen,
                  (Route<dynamic> route) => false,
                ),
              );
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                mainHomeScreen,
                (Route<dynamic> route) => false
              );
            }
          }
        } else if (value == 2) {
          showOtpWidget = true;
          setState(() {});
        } else if (value == 3) {
          Navigator.of(context).pushNamed(forgotPasswordScreen,
              arguments: [true, "user_exist_password_blank"]);
        } else if (value == 4) {
          showMessage(
            context,
            getTranslatedValue(
              context,
              invalidPasswordLabel,
            ),
            MessageType.warning,
          );
        } else if (value == 5) {
          showMessage(
            context,
            getTranslatedValue(
              context,
              userDeactivatedLabel,
            ),
            MessageType.warning,
          );
        } else if (value == 6) {
          showMessage(
            context,
            getTranslatedValue(
              context,
              userExistWithGoogleLabel,
            ),
            MessageType.warning,
          );
        } else {
          setState(() {
            isLoading = false;
          });
          if (user != null) {
            Constant.session.setData(SessionManager.keyUserImage,
                firebaseAuth.currentUser!.photoURL.toString(), false);

            Navigator.of(context).pushNamed(
              editProfileScreen,
              arguments: [
                widget.from ?? "register",
                {
                  ApiAndParams.id: authProvider == AuthProviders.phone
                      ? editMobileTextEditingController.text
                      : user.email.toString(),
                  ApiAndParams.type: authProvider == AuthProviders.phone
                      ? "phone"
                      // : authProvider == AuthProviders.google
                      //     ? "google"
                      : "apple",
                  ApiAndParams.name:
                      firebaseAuth.currentUser!.displayName ?? "",
                  ApiAndParams.email: firebaseAuth.currentUser!.email ?? "",
                  ApiAndParams.countryCode: "",
                  ApiAndParams.mobile:
                      firebaseAuth.currentUser!.phoneNumber ?? "",
                  ApiAndParams.platform: Platform.isAndroid ? "android" : "ios",
                  ApiAndParams.fcmToken:
                      fcmToken, //Constant.session.getData(SessionManager.keyFCMToken),
                }
              ],
            );
          } else {
            if (value == 0) {
              showMessage(
                context,
                getTranslatedValue(
                  context,
                  userNotRegisteredLabel,
                ),
                MessageType.warning,
              );
            } else {
              showMessage(
                context,
                getTranslatedValue(
                  context,
                  somethingWentWrongLabel,
                ),
                MessageType.warning,
              );
            }
          }
        }
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CountryCode?>(
        'selectedCountryCode', selectedCountryCode));
  }
}
