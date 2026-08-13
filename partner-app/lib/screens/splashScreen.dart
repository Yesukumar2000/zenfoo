import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/screens/mainScreen/bottom_nav_provider.dart';
import 'package:project/screens/mainScreen/main_tab_scaffold.dart';
import 'package:project/screens/resgistration/registeration_screen.dart';
import 'package:project/screens/resgistration/food/food_registration.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _locationController;
  late AnimationController _slideUpController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _locationFadeAnimation;
  late Animation<double> _locationScaleAnimation;
  late Animation<Offset> _slideUpAnimation;
  late Animation<double> _addressFadeAnimation;

  bool _showLocation = false;
  bool _showAddress = false;
  String _locationText = '';

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _locationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Setup animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _locationFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _locationController, curve: Curves.easeOut),
    );

    _locationScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _locationController, curve: Curves.easeOutBack),
    );

    _slideUpAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(
      CurvedAnimation(parent: _slideUpController, curve: Curves.easeInOut),
    );

    _addressFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _locationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animation sequence
    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showLocation = true;
        });
        _locationController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _showAddress = true;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _slideUpController.forward();
      }
    });

    Future.delayed(
      Duration.zero,
      () async {
        try {
          final String response =
              await rootBundle.loadString(Constant.getAssetsPath(4, "en"));
          context
              .read<LanguageProvider>()
              .setLocalLanguage(await json.decode(response));

          Map<String, String> params = {ApiAndParams.system_type: "2"};
          if (Constant.session
              .getData(SessionManager.keySelectedLanguageId)
              .isEmpty) {
            params[ApiAndParams.is_default] = "1";
          } else {
            params[ApiAndParams.id] =
                Constant.session.getData(SessionManager.keySelectedLanguageId);
          }

          await context.read<LanguageProvider>().getAvailableLanguageList(
              params: {ApiAndParams.system_type: "2"},
              context: context).then((value) {
            context
                .read<LanguageProvider>()
                .getLanguageDataProvider(
                  params: params,
                  context: context,
                )
                .then((value) async {
              if (Constant.session.isUserLoggedIn()) {
                // Check if user is a seller and needs registration
                if (Constant.session.isSeller()) {
                  // Fetch seller data to check registration status
                  try {
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
                        Constant.session.setData(
                            SessionManager.keyStoreId, storeId ?? '', true);
                        Constant.session.setData(
                            SessionManager.keyUserId, userId ?? '', true);
                        // Extract and set location text for animation
                        if (seller['store_location'] != null) {
                          setState(() {
                            _locationText = seller['store_location'].toString();
                          });
                        }

                        // Check if registration is complete
                        bool hasPersonalInfo =
                            seller['name'] != null && seller['email'] != null;
                        bool hasStoreInfo = seller['store_name'] != null &&
                            seller['store_location'] != null;

                        // Safe parse booleans
                        final managedByAdmin =
                            safeParseBool(seller['managed_by_admin']);
                        final isSweetHouse =
                            safeParseBool(seller['is_sweet_house']);
                        final isSuperMart =
                            safeParseBool(seller['is_super_mart']);

                        dev.log("managedByAdmin $managedByAdmin");
                        dev.log("isSweetHouse $isSweetHouse");
                        dev.log("isSuperMart $isSuperMart");

                        // Use refreshData for proper persistence
                        await Constant.session.refreshData(
                          SessionManager.managedByAdmin,
                          managedByAdmin ? "1" : "0",
                        );

                        await Constant.session.refreshData(
                          SessionManager.isSweetHouse,
                          isSweetHouse ? "1" : "0",
                        );

                        await Constant.session.refreshData(
                          SessionManager.isSuperMart,
                          isSuperMart ? "1" : "0",
                        );

                        await Constant.session.refreshData(
                          SessionManager.keyStoreId,
                          storeId,
                        );

                        // Store FSSAI number from registration data
                        if (seller['fssai_number'] != null) {
                          await Constant.session.refreshData(
                            SessionManager.fssai_number,
                            seller['fssai_number'].toString(),
                          );
                        }

                        // Store store type name from registration data
                        if (seller['store_type_name'] != null) {
                          await Constant.session.refreshData(
                            SessionManager.store_type_name,
                            seller['store_type_name'].toString(),
                          );
                        }

                        if (!hasPersonalInfo || !hasStoreInfo) {
                          // No personal data - go to shop type selection first
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopTypeHomeScreen(),
                            ),
                            (route) => false,
                          );
                          return;
                        } 
                        // else if (!hasStoreInfo) {
                        //   // Partial data - go to registration (will determine correct step)
                        //   Navigator.pushAndRemoveUntil(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (_) => FoodRegistrationScreen(
                        //           storeId: storeId, initialStep: 1),
                        //     ),
                        //     (route) => false,
                        //   );
                        //   return;
                        // }r
                         else {
                          // Complete data - check if approved
                          final isApproved =
                              safeParseBool(seller['is_approved']) ||
                                  seller['status'] == 'approved' ||
                                  safeParseBool(seller['approved']);

                          if (isApproved) {
                            // Approved - go to dashboard
                            // Settings API commented out
                            // context
                            //     .read<SettingsProvider>()
                            //     .getSettingsApiProvider({}, context).then(
                            //   (value) async {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MultiProvider(
                                      providers: [
                                        ChangeNotifierProvider(
                                            create: (_) => BottomNavProvider()),
                                      ],
                                      child: MaterialApp(
                                        home: MainTabScaffold(),
                                        debugShowCheckedModeBanner: false,
                                      ),
                                    ),
                                  ),
                                  (route) => false,
                                );
                            //   },
                            // );
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
                  } catch (e) {
                    print('Error checking registration status: $e');
                  }
                }

                // Default: go to dashboard
                // Settings API commented out
                // context
                //     .read<SettingsProvider>()
                //     .getSettingsApiProvider({}, context).then(
                //   (value) async {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => ShopTypeHomeScreen()),
                      (route) => false,
                    );
                //   },
                // );
              } else {
                if (Constant.appLoginType == 1) {
                  Constant.session
                      .setData(SessionManager.keyUserType, "seller", false);
                  Navigator.pushNamed(context, loginScreen);
                } else if (Constant.appLoginType == 2) {
                  Constant.session.setData(
                      SessionManager.keyUserType, "delivery_boy", false);

                  Navigator.pushNamed(context, loginScreen);
                } else {
                  Navigator.pushReplacementNamed(context, accountTypeScreen);
                }
              }
            });
          });
        } catch (e) {
          print('Error during splash initialization: $e');
          // Navigate to login screen on error
          Navigator.pushReplacementNamed(context, loginScreen);
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _locationController,                 
          _slideUpController,
        ]),
        builder: (context, child) {
          return SlideTransition(
            position: _slideUpAnimation,
            child: Stack(
              children: [
                // Logo animation
                Center(
                  child: FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                          maxWidth: 300,
                        ),
                        child: Image.asset(
                          'assets/images/Vendor.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // Location icon and address section
                if (_showLocation)
                  Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _locationFadeAnimation,
                      child: ScaleTransition(
                        scale: _locationScaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Address section with fade in
                            if (_showAddress)
                              FadeTransition(
                                opacity: _addressFadeAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 32),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                        ),
                                        child: Text(
                                          _locationText.isEmpty
                                              ? 'Loading your store location...'
                                              : _locationText,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            letterSpacing: -0.1,
                                            height: 1.5,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
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

  @override
  void dispose() {
    _logoController.dispose();
    _locationController.dispose();
    _slideUpController.dispose();
    super.dispose();
  }
}
