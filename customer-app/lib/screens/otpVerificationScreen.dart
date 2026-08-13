import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

class OtpVerificationScreen extends StatefulWidget {
  final String otpVerificationId;
  final String phoneNumber;
  final FirebaseAuth firebaseAuth;
  final CountryCode selectedCountryCode;
  final String? from;
  final String? referralCode;

  const OtpVerificationScreen({
    Key? key,
    required this.otpVerificationId,
    required this.phoneNumber,
    required this.firebaseAuth,
    required this.selectedCountryCode,
    this.from,
    this.referralCode,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _LoginAccountState();
}

class _LoginAccountState extends State<OtpVerificationScreen> {
  int otpLength = 4;
  bool isLoading = false;
  String resendOtpVerificationId = "";
  int? forceResendingToken;

  /// Create Controller
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
    // TODO REMOVE DEMO OTP FROM HERE
    Future.delayed(Duration.zero).then((value) {
      if (mounted) {
        startTimer();
        if (widget.phoneNumber == "") {
          pinController.setText("");
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: Size(
          double.infinity,
          double.maxFinite,
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            width: 393,
            height: 67,
            padding: const EdgeInsets.only(left: 15, right: 80),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 1.90,
                  offset: Offset(0, 5),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 12,
              children: [
                Image.asset(
                  'assets/images/back.png',
                  height: 48,
                  width: 48,
                ),
                Text(
                  'OTP Verification',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF171717),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.33,
                    letterSpacing: -0.05,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            otpWidgets(),
          ],
        ),
      ),
    );
  }

  Widget resendOtpWidget() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;
    final isActive = _timer != null && _timer!.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      // decoration: BoxDecoration(
      //   color: colorScheme.surfaceVariant,
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(
      //     color: isActive ? colorScheme.border : colorScheme.primary,
      //     width: 1.5,
      //   ),
      // ),
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
                  ? "${getTranslatedValue(context, resendOtpInLabel)} "
                  : "",
              children: <TextSpan>[
                TextSpan(
                  text: isActive
                      ? '${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                      : getTranslatedValue(context, resendOtpLabel),
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

  verifyOtp() async {
    debugPrint('verifyOtp called');

    // if (context.read<AppSettingsProvider>().settingsData!.firebaseAuthentication == "1") {
    //   debugPrint('Using Firebase authentication');
    //   isLoading = true;
    //   PhoneAuthCredential credential = PhoneAuthProvider.credential(
    //       verificationId: resendOtpVerificationId.isNotEmpty
    //           ? resendOtpVerificationId
    //           : widget.otpVerificationId,
    //       smsCode: pinController.text);

    //   widget.firebaseAuth.signInWithCredential(credential).then((value) {
    //     User? user = value.user;
    //     debugPrint('Firebase sign-in successful, user: $user');
    //     backendApiProcess(user);
    //   }).catchError((e) {
    //     debugPrint('Firebase sign-in failed: $e');
    //     showMessage(
    //       context,
    //       getTranslatedValue(context, enterValidOtpLabel),
    //       MessageType.warning,
    //     );
    //     setState(() {
    //       isLoading = false;
    //     });
    //   });
    // } else
    if (Constant.customSmsGatewayOtpBased == "1") {
      debugPrint('Using custom SMS gateway for OTP verification');
      await context.read<UserProfileProvider>().verifyUserProvider(
        context: context,
        params: {
          ApiAndParams.otp: pinController.text,
          ApiAndParams.phone: widget.phoneNumber,
          ApiAndParams.countryCode:
              widget.selectedCountryCode.dialCode.toString(),
          // Attribute the referral when the backend auto-creates a new user.
          // Sent only when the user entered a code on the login screen.
          if (widget.referralCode != null &&
              widget.referralCode!.trim().isNotEmpty)
            ApiAndParams.referralCode: widget.referralCode!.trim(),
        },
      ).then((value) async {
        debugPrint('OTP verification response: $value');
        if (value != null &&
            value is Map &&
            value['status'].toString() == '1' &&
            value['data'] != null) {
          Map<String, dynamic> responseData = Map<String, dynamic>.from(value);
          Map<String, dynamic> data =
              responseData['data'] as Map<String, dynamic>;
          debugPrint('Verification success, responseData: $responseData');
          if (data['access_token'] != null && data['user'] != null) {
            debugPrint('Access token and user found. Saving session...');
            await context
                .read<UserProfileProvider>()
                .setUserDataInSession(responseData, context);

            if (context.read<CartListProvider>().cartList.isNotEmpty) {
              debugPrint('Guest cart found, merging to user cart');
              await addGuestCartBulkToCartWhileLogin(
                context: context,
                params: Constant.setGuestCartParams(
                    cartList: context.read<CartListProvider>().cartList),
              );
            }

            debugPrint('Navigating to main home screen');
            Navigator.of(context).pushNamedAndRemoveUntil(
              mainHomeScreen,
              (Route<dynamic> route) => false,
            );
          }
        } else {
          debugPrint('Verification failed or incomplete user data');
          // Show error message to user
          String errorMessage = 'OTP verification failed';
          if (value != null && value is Map && value['message'] != null) {
            errorMessage = value['message'].toString();
          }
          showMessage(
            context,
            errorMessage,
            MessageType.error,
          );
          // Clear the OTP input
          pinController.clear();
        }
      });
    } else {
      debugPrint('Unknown OTP configuration');
    }
    setState(() {});
    debugPrint('verifyOtp finished');
  }

  otpWidgets() {
    final colorScheme = context.watch<app_theme.ThemeProvider>().colorScheme;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Title
          CustomTextLabel(
            jsonKey: otpSendMessageLabel,
            style: GoogleFonts.inter(
              color: colorScheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Phone number display
          Container(
            // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // decoration: BoxDecoration(
            //   color: colorScheme.surfaceVariant,
            //   borderRadius: BorderRadius.circular(12),
            //   border: Border.all(color: colorScheme.border),
            // ),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: colorScheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                children: [
                  TextSpan(
                    text: "${widget.selectedCountryCode} ",
                    style: GoogleFonts.inter(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: widget.phoneNumber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // OTP Input
          otpPinWidget(
            context: context,
            pinController: pinController,
            onCompleted: verifyOtp,
          ),
          const SizedBox(height: 24),

          // Resend OTP button
          GestureDetector(
            onTap: _timer != null && _timer!.isActive
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    startTimer();
                    if (Constant.customSmsGatewayOtpBased == "1") {
                      context
                          .read<UserProfileProvider>()
                          .sendCustomOTPSmsProvider(
                        context: context,
                        params: {
                          ApiAndParams.phone: "${widget.phoneNumber}",
                          ApiAndParams.countryCode:
                              "${widget.selectedCountryCode.dialCode}",
                        },
                      ).then((value) {
                        if (value[ApiAndParams.status].toString() == "1") {
                          showMessage(
                            context,
                            getTranslatedValue(
                                context, "otp_sent_successfully"),
                            MessageType.success,
                          );
                        }
                      });
                    } else if (context
                            .read<AppSettingsProvider>()
                            .settingsData!
                            .firebaseAuthentication ==
                        "1") {
                      firebaseLoginProcess();
                    }
                    setState(() {});
                  },
            child: resendOtpWidget(),
          ),
        ],
      ),
    );
  }

  backendApiProcess(User? user) async {
    if (user != null) {
      Map<String, String> params = {
        ApiAndParams.phone: widget.phoneNumber,
        ApiAndParams.type: "phone",
        ApiAndParams.countryCode:
            widget.selectedCountryCode.dialCode?.replaceAll("+", "") ?? "",
        ApiAndParams.platform: Platform.isAndroid ? "android" : "ios",
        ApiAndParams.fcmToken:
            Constant.session.getData(SessionManager.keyFCMToken),
        ApiAndParams.phoneAuthType: (context
                    .read<AppSettingsProvider>()
                    .settingsData!
                    .phoneAuthPassword ==
                "1")
            ? "phone_auth_password"
            : "phone_auth_otp",
      };

      await context
          .read<UserProfileProvider>()
          .loginApi(context: context, params: params)
          .then((value) async {
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
                (Route<dynamic> route) => false,
              );
            }
          }

          if (Constant.session.isUserLoggedIn()) {
            await context
                .read<CartProvider>()
                .getCartListProvider(context: context);
          } else {
            if (context.read<CartListProvider>().cartList.isNotEmpty) {
              await context
                  .read<CartProvider>()
                  .getGuestCartListProvider(context: context);
            }
          }
        } else {
          // User not found - need to register first
          Map<String, String> registerParams = {
            ApiAndParams.id: widget.phoneNumber,
            ApiAndParams.type: "phone",
            ApiAndParams.name: user.displayName ?? "",
            ApiAndParams.email: user.email ?? "",
            ApiAndParams.countryCode: widget.selectedCountryCode.dialCode
                    ?.replaceAll("+", "")
                    .toString() ??
                "",
            ApiAndParams.mobile: user.phoneNumber
                .toString()
                .replaceAll(widget.selectedCountryCode.dialCode.toString(), ""),
            ApiAndParams.platform: Platform.isAndroid ? "android" : "ios",
            ApiAndParams.fcmToken:
                Constant.session.getData(SessionManager.keyFCMToken),
            ApiAndParams.initialCountryCode: widget.selectedCountryCode.code!,
            if (widget.referralCode != null &&
                widget.referralCode!.trim().isNotEmpty)
              ApiAndParams.referralCode: widget.referralCode!.trim(),
          };

          // Call register API
          await context
              .read<UserProfileProvider>()
              .registerAccountApi(context: context, params: registerParams);
        }
      });
    }
  }

  customSMSBackendApiProcess() async {
    Map<String, String> params = {
      ApiAndParams.phone: widget.phoneNumber,
      ApiAndParams.type: "phone",
      ApiAndParams.countryCode:
          widget.selectedCountryCode.dialCode?.replaceAll("+", "") ?? "",
      ApiAndParams.platform: Platform.isAndroid ? "android" : "ios",
      ApiAndParams.fcmToken:
          Constant.session.getData(SessionManager.keyFCMToken),
      ApiAndParams.phoneAuthType: (context
                  .read<AppSettingsProvider>()
                  .settingsData!
                  .phoneAuthPassword ==
              "1")
          ? "phone_auth_password"
          : "phone_auth_otp",
    };

    await context
        .read<UserProfileProvider>()
        .loginApi(context: context, params: params)
        .then((value) async {
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
              (Route<dynamic> route) => false,
            );
          }
        }

        if (Constant.session.isUserLoggedIn()) {
          await context
              .read<CartProvider>()
              .getCartListProvider(context: context);
        } else {
          if (context.read<CartListProvider>().cartList.isNotEmpty) {
            await context
                .read<CartProvider>()
                .getGuestCartListProvider(context: context);
          }
        }
      }
    });
  }

  Future checkOtpValidation() async {
    bool checkInternet = await checkInternetConnection();
    String? msg;
    if (checkInternet) {
      if (pinController.text.length == 1) {
        msg = getTranslatedValue(
          context,
          enterOtpLabel,
        );
      } else if (pinController.text.length <= otpLength) {
        msg = getTranslatedValue(
          context,
          enterValidOtpLabel,
        );
      } else {
        if (isLoading) return;
        setState(() {
          isLoading = true;
        });
        msg = "";
      }
    } else {
      msg = getTranslatedValue(
        context,
        checkInternetLabel,
      );
    }
    return msg;
  }

  firebaseLoginProcess() async {
    if (widget.phoneNumber.isNotEmpty) {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber:
            '${widget.selectedCountryCode.dialCode} - ${widget.phoneNumber}',
        verificationCompleted: (PhoneAuthCredential credential) {
          pinController.setText(credential.smsCode ?? "");
        },
        verificationFailed: (FirebaseAuthException e) {
          showMessage(
            context,
            e.message!,
            MessageType.warning,
          );
          if (mounted) {
            isLoading = false;
            setState(() {});
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          forceResendingToken = resendToken;
          if (mounted) {
            isLoading = false;
            setState(() {
              resendOtpVerificationId = verificationId;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            isLoading = false;
            setState(() {
              // isLoading = false;
            });
          }
        },
        forceResendingToken: forceResendingToken,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer!.cancel();
    }
  }
}
