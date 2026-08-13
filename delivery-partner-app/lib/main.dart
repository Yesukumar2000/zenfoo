import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer;
import 'package:provider/provider.dart';
import 'package:zenfoo_partner/firebase_options.dart';
import 'package:zenfoo_partner/providers/app_settings_provider.dart';
import 'package:zenfoo_partner/providers/auth_provider.dart';
import 'package:zenfoo_partner/providers/booking_provider.dart';
import 'package:zenfoo_partner/providers/deposit_cash_provider.dart';
import 'package:zenfoo_partner/providers/document_provider.dart';
import 'package:zenfoo_partner/providers/floating_cash_issue_provider.dart';
import 'package:zenfoo_partner/providers/duty_issues_provider.dart';
import 'package:zenfoo_partner/providers/driver_issue_provider.dart';
import 'package:zenfoo_partner/providers/personal_details_provider.dart';
import 'package:zenfoo_partner/providers/gig_provider.dart';
import 'package:zenfoo_partner/providers/incentive_provider.dart';
import 'package:zenfoo_partner/providers/incoming_order_provider.dart';
import 'package:zenfoo_partner/providers/language_provider.dart';
import 'package:zenfoo_partner/providers/learning_provider.dart';
import 'package:zenfoo_partner/providers/notification_provider.dart';
import 'package:zenfoo_partner/providers/order_priority_provider.dart';
import 'package:zenfoo_partner/providers/payment_status_provider.dart';
import 'package:zenfoo_partner/providers/update_provider.dart';
import 'package:zenfoo_partner/providers/performance_provider.dart';
import 'package:zenfoo_partner/providers/place_details_provider.dart';
import 'package:zenfoo_partner/providers/place_suggestions_provider.dart';
import 'package:zenfoo_partner/providers/session_provider.dart';
import 'package:zenfoo_partner/providers/tips_provider.dart';
import 'package:zenfoo_partner/providers/weather_provider.dart';
import 'package:zenfoo_partner/providers/multi_order_earnings_provider.dart';
import 'package:zenfoo_partner/providers/delivery_boy_locations_provider.dart';
import 'package:zenfoo_partner/providers/floating_cash_provider.dart';
import 'package:zenfoo_partner/providers/order_earnings_provider.dart';
import 'package:zenfoo_partner/providers/weekly_summary_provider.dart';
import 'package:zenfoo_partner/providers/emergency_support_provider.dart';
import 'package:zenfoo_partner/providers/update_personal_info_provider.dart';
import 'package:zenfoo_partner/providers/order_earning_issue_provider.dart';
import 'package:zenfoo_partner/providers/support_chat_provider.dart';
import 'package:zenfoo_partner/providers/order_earnings_chat_provider.dart';
import 'package:zenfoo_partner/providers/admin_order_chat_provider.dart';
import 'package:zenfoo_partner/providers/payout_issues_provider.dart';
import 'package:zenfoo_partner/providers/terms_and_conditions_provider.dart';
import 'package:zenfoo_partner/providers/ratings_provider.dart';
import 'package:zenfoo_partner/providers/referral_provider.dart';
import 'package:zenfoo_partner/providers/admin_payment_details_provider.dart';
import 'package:zenfoo_partner/providers/banner_provider.dart';
import 'package:zenfoo_partner/providers/payment_proof_provider.dart';
import 'package:zenfoo_partner/providers/multi_order_detail_provider.dart';
import 'package:zenfoo_partner/providers/payment_history_provider.dart';
import 'package:zenfoo_partner/repository/incoming_order_repository.dart';
import 'package:zenfoo_partner/router/app_router.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/app_lifecycle_observer.dart';
import 'package:zenfoo_partner/services/firebase_order_service.dart';
import 'package:zenfoo_partner/theme/app_theme.dart';
import 'package:zenfoo_partner/theme/theme_provider.dart';
import 'package:zenfoo_partner/utils/awsomeNotification.dart';

/// Entry point for overlay window
// @pragma("vm:entry-point")
// void overlayMain() {
//   runApp(const OverlayApp());
// }

/// Firebase Messaging background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalAwesomeNotification.onBackgroundMessageHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio context for sound notifications
  try {
    await AudioPlayer.clearAssetCache();
    debugPrint('✅ Audio context initialized');
  } catch (e) {
    debugPrint('⚠️ Audio context initialization warning: $e');
  }

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Override SSL certificate validation (for development only)
  // WARNING: This should be removed in production!
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

/// HTTP overrides to allow self-signed certificates
/// WARNING: Only use this in development. Remove for production!
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allow all certificates (insecure - for development only)
        debugPrint('⚠️  SSL: Accepting certificate for $host:$port');
        return true;
      };
  }
}

double screenHeight = 0;
double screenWidth = 0;

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLifecycleObserver _lifecycleObserver;
  bool _isNotificationInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  /// Initialize AwesomeNotifications
  Future<void> _initializeNotifications(BuildContext context) async {
    if (!_isNotificationInitialized) {
      await LocalAwesomeNotification().init(context);
      _isNotificationInitialized = true;
      // Initialize Firebase Notifications
      if (context.mounted) {
        _initializeFirebaseNotifications(context);
      }
    }
  }

  /// Initialize Firebase Notifications with NotificationProvider
  void _initializeFirebaseNotifications(BuildContext context) {
    final notificationProvider = context.read<NotificationProvider>();
    notificationProvider.initializeFirebaseNotifications().then((_) {
      debugPrint('✅ Firebase notifications initialized in main');
    }).catchError((e) {
      debugPrint('❌ Error initializing Firebase notifications: $e');
    });
  }

  @override
  void dispose() {
    _lifecycleObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppSettingsProvider(),
          ),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => LanguageProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => DocumentProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => PersonalDetailsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => PlaceSuggestionsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => PlaceDetailsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => GigProvider(),
          ),
          ChangeNotifierProxyProvider<AuthProvider, SessionProvider>(
            create: (context) =>
                SessionProvider(authProvider: context.read<AuthProvider>()),
            update: (context, authProvider, sessionProvider) =>
                sessionProvider ?? SessionProvider(authProvider: authProvider),
          ),
          ChangeNotifierProvider(
            create: (_) => IncentiveProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => BookingProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => OrderPriorityProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => PaymentStatusProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => UpdateProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => LearningProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => PerformanceProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => IncomingOrderProvider(
              IncomingOrderRepository(
                ApiService(),
              ),
              FirebaseOrderService(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => TipsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => MultiOrderEarningsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => DeliveryBoyLocationsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => FloatingCashProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => OrderEarningsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => WeeklySummaryProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => EmergencySupportProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => UpdatePersonalInfoProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => OrderEarningIssueProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => SupportChatProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => PayoutIssuesProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => FloatingCashIssueProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => DutyIssuesProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => TermsAndConditionsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => DepositCashProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => RatingsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => OrderEarningsChatProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminOrderChatProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => ReferralProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => BannerProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => WeatherProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminPaymentDetailsProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => PaymentProofProvider(),
          ),
          ChangeNotifierProvider(create: (_) => PaymentHistoryProvider()),
          ChangeNotifierProvider(
            create: (_) => MultiOrderDetailProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => DriverIssueProvider(),
          ),
        ],
        child: Consumer5<ThemeProvider, SessionProvider, AppSettingsProvider,
                LanguageProvider, UpdateProvider>(
            builder: (context, themeProvider, sessionProvider, settingsProvider,
                languageProvider, updateProvider, _) {
          // Initialize app settings after frame
          // if (!_isAppSettingsInitialized) {
          //   _isAppSettingsInitialized = true;
          //   WidgetsBinding.instance.addPostFrameCallback((_) {
          //     _initializeAppSettings(context, settingsProvider);
          //   });
          // }
          // Initialize language system
          if (!_isLanguageInitialized) {
            _isLanguageInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              languageProvider.initializeLanguage();
            });
          }

          // Initialize lifecycle observer with SessionProvider
          if (!_isLifecycleInitialized) {
            _lifecycleObserver = AppLifecycleObserver(sessionProvider);
            _lifecycleObserver.initialize();
            _isLifecycleInitialized = true;
          }

          // Initialize AwesomeNotifications
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeNotifications(context);
          });

          // Check for app updates (only once)
          if (!_isUpdateChecked) {
            _isUpdateChecked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                updateProvider.checkForUpdate(context);
              }
            });
          }
          return MaterialApp.router(
            routerConfig: appRouter,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            title: 'Zenfoo Delivery',
            // Apply the text direction of the selected language (e.g. rtl for
            // Urdu) across the entire app. Driven by LanguageProvider.
            builder: (context, child) {
              return Directionality(
                textDirection: languageProvider.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        }));
  }

  bool _isLifecycleInitialized = false;
  bool _isLanguageInitialized = false;
  bool _isUpdateChecked = false;
}
