import 'dart:ui' as ui;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/provider/policyAndTermsProvider.dart';
import 'package:project/provider/sellerStatusProvider.dart';
import 'package:project/provider/new_orders_provider.dart';
import 'package:project/provider/eta_provider.dart';
import 'package:project/provider/support_contact_provider.dart';
import 'package:project/screens/Login/otp_provider.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;
import 'package:project/helper/utils/awsomeNotification.dart';
import 'package:project/repositories/fcmTokenApi.dart';
import 'package:project/services/notification_sheet_service.dart';
import 'package:project/services/app_tracking_transparency_service.dart';
import 'helper/utils/generalImports.dart';

late final SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: SystemUiOverlay.values);
      
  prefs = await SharedPreferences.getInstance();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    // Firebase Crashlytics setup
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {}
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: ColorsRes.appColorTransparent));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<app_theme.ThemeProvider>(create: (context) {
          return app_theme.ThemeProvider();
        }),
        ChangeNotifierProvider<LanguageProvider>(
          create: (context) {
            return LanguageProvider();
          },
        ),
        ChangeNotifierProvider<ProductListProvider>(
          create: (context) {
            return ProductListProvider();
          },
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (context) {
            return SettingsProvider();
          },
        ),
        ChangeNotifierProvider<SellerStatusProvider>(
          create: (context) {
            return SellerStatusProvider();
          },
        ),
        ChangeNotifierProvider<CategoryListProvider>(
          create: (context) {
            return CategoryListProvider();
          },
        ),
        ChangeNotifierProvider<PolicyAndTermsProvider>(
          create: (context) {
            return PolicyAndTermsProvider();
          },
        ),
        ChangeNotifierProvider<LoginProvider>(
          create: (context) {
            return LoginProvider();
          },
        ),
        ChangeNotifierProvider<NewOrdersProvider>(
          create: (context) {
            return NewOrdersProvider();
          },
        ),
        ChangeNotifierProvider<EtaProvider>(
          create: (context) {
            return EtaProvider();
          },
        ),
        ChangeNotifierProvider<SupportContactProvider>(
          create: (context) {
            return SupportContactProvider();
          },
        )
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications after app is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  /// Initialize push notifications (Firebase + Awesome Notifications)
  Future<void> _initializeNotifications() async {
    try {
      // Request App Tracking Transparency permission (iOS 14+)
      await AppTrackingTransparencyService.requestTrackingPermission();

      // Initialize Awesome Notifications
      await LocalAwesomeNotification().init(context);

      // Get and store initial FCM token
      await _updateFCMToken();

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveFCMTokenToPrefs(newToken);
      });

      // Start Firebase real-time listener for orders (even if Orders screen not opened)
      _startFirebaseOrderListener();

      // Check and display pending notification if app was opened from background
      // Add a longer delay to ensure all providers are ready
      await Future.delayed(Duration(milliseconds: 800), () {
        _checkAndDisplayPendingNotification();
      });
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Check for pending notifications stored while app was in background
  Future<void> _checkAndDisplayPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingNotificationJson = prefs.getString('pending_notification');

      if (pendingNotificationJson != null &&
          pendingNotificationJson.isNotEmpty) {
        debugPrint('📦 Found pending notification, displaying...');

        try {
          final notificationData = json.decode(pendingNotificationJson);
          final orderId = notificationData['orderId'];

          if (orderId != null && orderId.isNotEmpty) {
            final orderIdInt = int.tryParse(orderId);
            if (orderIdInt != null) {
              // Display the order notification sheet
              NotificationSheetService().showNewOrderNotification(
                orderId: orderIdInt,
                onDismiss: () {
                  debugPrint('📦 Pending notification dismissed');
                  // Clear the pending notification
                  prefs.remove('pending_notification');
                },
                onOpenOrders: () {
                  debugPrint('📦 Opening orders from pending notification');
                  // Clear the pending notification
                  prefs.remove('pending_notification');
                },
              );
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing pending notification: $e');
          prefs.remove('pending_notification');
        }
      }
    } catch (e) {
      debugPrint('Error checking pending notifications: $e');
    }
  }

  /// Start Firebase listener for real-time order updates
  void _startFirebaseOrderListener() {
    try {
      final sellerIdStr = Constant.session.getData(SessionManager.keyUserId);
      final sellerId = int.tryParse(sellerIdStr) ?? 0;

      if (sellerId != 0) {
        // Get the provider and start listening
        Future.delayed(Duration(milliseconds: 500), () {
          final provider =
              Provider.of<NewOrdersProvider>(context, listen: false);
          provider.startFirebaseListener(sellerId: sellerId);
          debugPrint(
              '✅ Firebase order listener started from main.dart for seller $sellerId');
        });
      } else {
        debugPrint(
            '⚠️ Seller ID not available yet, Firebase listener will start when Orders screen opens');
      }
    } catch (e) {
      debugPrint('Error starting Firebase order listener: $e');
    }
  }

  /// Get FCM token and save to preferences
  Future<void> _updateFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveFCMTokenToPrefs(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Save FCM token to local preferences and update server
  Future<void> _saveFCMTokenToPrefs(String token) async {
    try {
      // Save to local preferences
      Constant.session.setData(SessionManager.keyFCMToken, token, false);
      debugPrint('FCM Token saved locally: $token');

      // Update token on server if user is logged in
      if (Constant.session.isUserLoggedIn()) {
        await updateFCMTokenRepository(fcmToken: token);
        debugPrint('FCM Token updated on server: $token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionManager>(
      create: (_) => SessionManager(prefs: prefs),
      child: Consumer<SessionManager>(
        builder: (context, SessionManager sessionNotifier, child) {
          Constant.session =
              Provider.of<SessionManager>(context, listen: false);

          if (Constant.session
              .getData(SessionManager.appThemeName)
              .toString()
              .isEmpty) {
            Constant.session.setData(
                SessionManager.appThemeName, Constant.themeList[0], false);
            Constant.session.setBoolData(
                SessionManager.isDarkTheme,
                ui.PlatformDispatcher.instance.platformBrightness ==
                    Brightness.dark,
                false);
          }

          // This callback is called every time the brightness changes from the device.
          ui.PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
            if (Constant.session.getData(SessionManager.appThemeName) ==
                Constant.themeList[0]) {
              Constant.session.setBoolData(
                  SessionManager.isDarkTheme,
                  ui.PlatformDispatcher.instance.platformBrightness ==
                      Brightness.dark,
                  true);
            }
          };

          return Consumer2<LanguageProvider, app_theme.ThemeProvider>(
            builder: (context, languageProvider, themeProvider, child) {
              Constant.session = Provider.of<SessionManager>(context);

              if (Constant.session
                  .getData(SessionManager.appThemeName)
                  .toString()
                  .isEmpty) {
                Constant.session.setData(
                    SessionManager.appThemeName, Constant.themeList[0], false);
                Constant.session.setBoolData(
                    SessionManager.isDarkTheme,
                    ui.PlatformDispatcher.instance.platformBrightness ==
                        Brightness.dark,
                    false);
              }

              // Update theme provider with system brightness
              themeProvider.updateSystemBrightness(
                  ui.PlatformDispatcher.instance.platformBrightness);

              // This callback is called every time the brightness changes from the device.
              ui.PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
                if (Constant.session.getData(SessionManager.appThemeName) ==
                    Constant.themeList[0]) {
                  Constant.session.setBoolData(
                      SessionManager.isDarkTheme,
                      ui.PlatformDispatcher.instance.platformBrightness ==
                          Brightness.dark,
                      true);
                }
                // Update theme provider
                themeProvider.updateSystemBrightness(
                    ui.PlatformDispatcher.instance.platformBrightness);
              };

              return /* AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle(systemNavigationBarColor:
                        ColorsRes.appColorTransparent,
                        systemNavigationBarDividerColor: ColorsRes.appColorTransparent,
                        statusBarColor: Theme.of(context).colorScheme.onSurface,
                        systemStatusBarContrastEnforced: true
                    ),
                    child: */
                  MaterialApp(
                builder: (context, child) {
                  return ScrollConfiguration(
                    behavior: GlobalScrollBehavior(),
                    child: Directionality(
                      textDirection:
                          languageProvider.languageDirection.toLowerCase() ==
                                  "rtl"
                              ? ui.TextDirection.rtl
                              : ui.TextDirection.ltr,
                      child: /* SafeArea(bottom: true, top: false, child: */
                          child! /* ) */,
                    ),
                  );
                },
                navigatorKey: Constant.navigatorKay,
                onGenerateRoute: RouteGenerator.generateRoute,
                initialRoute: "/",
                scrollBehavior: ScrollGlowBehavior(),
                debugShowCheckedModeBanner: false,
                title: Constant.appName,
                theme: themeProvider.themeData,
                darkTheme: themeProvider.themeData,
                themeMode: themeProvider.themeMode == app_theme.ThemeMode.system
                    ? ThemeMode.system
                    : themeProvider.themeMode == app_theme.ThemeMode.dark
                        ? ThemeMode.dark
                        : ThemeMode.light,
                home: SplashScreen(),
              ) /* ) */;
            },
          );
        },
      ),
    );
  }
}
