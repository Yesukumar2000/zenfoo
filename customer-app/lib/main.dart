import 'package:app_links/app_links.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/appUpdateProvider.dart';
import 'package:project/provider/comboDetailProvider.dart';
import 'package:project/provider/combosProvider.dart';
import 'package:project/provider/orderTrackingProvider.dart';
import 'package:project/provider/appLaunchBannerProvider.dart';
import 'package:project/provider/userOffersProvider.dart';
import 'package:project/provider/reportsProvider.dart';
import 'package:project/provider/reorderProvider.dart';
import 'package:project/provider/chatProvider.dart';
import 'package:project/helper/utils/storeHoursService.dart';
import 'package:project/provider/orderChatProvider.dart';
import 'package:project/provider/exploreLogoProvider.dart';

late final SharedPreferences prefs;

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    final mapsImpl = GoogleMapsFlutterPlatform.instance;
    if (mapsImpl is GoogleMapsFlutterAndroid) {
      try {
        await mapsImpl.initializeWithRenderer(AndroidMapRenderer.latest);
      } catch (_) {
        // Renderer was already initialized (e.g. on hot restart). Safe to ignore.
      }
    }
  }

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    // Fetch store hours from Firestore
    StoreHoursService().fetchStoreHours();
  } catch (e) {
    log("Error Main ${e}");
  }

  // Initialize Firebase Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: SystemUiOverlay.values);

  // Initialize shared preferences
  prefs = await SharedPreferences.getInstance();

  // Set global navigator key
  navigatorKey = GlobalKey<NavigatorState>();

  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: ColorsRes.appColorTransparent));

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>(
          create: (context) => CartProvider(),
        ),
        ChangeNotifierProvider<HomeMainScreenProvider>(
          create: (context) => HomeMainScreenProvider(),
        ),
        ChangeNotifierProvider<CategoryListProvider>(
          create: (context) => CategoryListProvider(),
        ),
        ChangeNotifierProvider<CityByLatLongProvider>(
          create: (context) => CityByLatLongProvider(),
        ),
        ChangeNotifierProvider<HomeScreenProvider>(
          create: (context) => HomeScreenProvider(),
        ),
        ChangeNotifierProvider<ProductChangeListingTypeProvider>(
          create: (context) => ProductChangeListingTypeProvider(),
        ),
        ChangeNotifierProvider<FaqProvider>(
          create: (context) => FaqProvider(),
        ),
        ChangeNotifierProvider<SuggestionProvider>(
          create: (context) => SuggestionProvider(),
        ),
        ChangeNotifierProvider<ProductWishListProvider>(
          create: (context) => ProductWishListProvider(),
        ),
        ChangeNotifierProvider<ProductAddOrRemoveFavoriteProvider>(
          create: (context) => ProductAddOrRemoveFavoriteProvider(),
        ),
        ChangeNotifierProvider<UserProfileProvider>(
          create: (context) => UserProfileProvider(),
        ),
        ChangeNotifierProvider<CartListProvider>(
          create: (context) => CartListProvider(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (context) => LanguageProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (context) => AppSettingsProvider(),
        ),
        ChangeNotifierProvider<AppLaunchBannerProvider>(
          create: (context) => AppLaunchBannerProvider(),
        ),
        ChangeNotifierProvider<BrandCampaignProvider>(
          create: (context) => BrandCampaignProvider(),
        ),
        ChangeNotifierProvider<UserOffersProvider>(
          create: (context) => UserOffersProvider(),
        ),
        ChangeNotifierProvider<ReportsProvider>(
          create: (context) => ReportsProvider(),
        ),
        // App-wide rather than scoped to the Reorder tab, so the home screen's
        // "Buy it again" rail and the Reorder tab share one instance — and
        // one fetch — instead of loading the same orders twice.
        ChangeNotifierProvider<ReorderProvider>(
          create: (context) => ReorderProvider(),
        ),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => ComboDetailProvider()),
        ChangeNotifierProvider(create: (_) => CombosProvider()),
        ChangeNotifierProvider(create: (_) => OrderTrackingProvider()),
        ChangeNotifierProvider(create: (_) => AppUpdateProvider()),
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(),
        ),
        ChangeNotifierProvider<OrderChatProvider>(
          create: (context) => OrderChatProvider(),
        ),
        ChangeNotifierProvider<ExploreLogoProvider>(
          create: (context) => ExploreLogoProvider(),
        ),
        ChangeNotifierProvider<ThinkingItemsProvider>(
          create: (context) => ThinkingItemsProvider(),
        ),
        ChangeNotifierProvider<HomeSectionsProvider>(
          create: (context) => HomeSectionsProvider(),
        ),
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
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // zenfoo://product/{id}
    if (uri.scheme == 'zenfoo' && uri.host == 'product') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (id == null || id.isEmpty) return;
      navigatorKey.currentState?.pushNamed(
        productDetailScreen,
        arguments: [id, '', null],
      );
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
                PlatformDispatcher.instance.platformBrightness ==
                    Brightness.dark,
                false);
            Constant.session.loadAutocompleteSuggestions();
          }

          // This callback is called every time the brightness changes from the device.
          PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
            if (Constant.session.getData(SessionManager.appThemeName) ==
                Constant.themeList[0]) {
              Constant.session.setBoolData(
                  SessionManager.isDarkTheme,
                  PlatformDispatcher.instance.platformBrightness ==
                      Brightness.dark,
                  true);
            }
          };

          return Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
            return Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                if (Constant.session
                    .getData(SessionManager.appThemeName)
                    .toString()
                    .isEmpty) {
                  Constant.session.setData(SessionManager.appThemeName,
                      Constant.themeList[0], false);
                  Constant.session.setBoolData(
                      SessionManager.isDarkTheme,
                      PlatformDispatcher.instance.platformBrightness ==
                          Brightness.dark,
                      false);
                }
                // This callback is called every time the brightness changes from the device.
                PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
                  if (Constant.session.getData(SessionManager.appThemeName) ==
                      Constant.themeList[0]) {
                    Constant.session.setBoolData(
                        SessionManager.isDarkTheme,
                        PlatformDispatcher.instance.platformBrightness ==
                            Brightness.dark,
                        true);
                  }
                };
                return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    child: ScreenUtilInit(
                      designSize: const Size(392, 852),
                      minTextAdapt: true,
                      splitScreenMode: true,
                      builder: (context, child) => MaterialApp(
                          navigatorKey: navigatorKey,
                          builder: (context, child) {
                            return ScrollConfiguration(
                              behavior: GlobalScrollBehavior(),
                              child: Center(
                                child: Directionality(
                                  textDirection: languageProvider
                                              .languageDirection
                                              .toLowerCase() ==
                                          "rtl"
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  child: child!,
                                ),
                              ),
                            );
                          },
                          onGenerateRoute: RouteGenerator.generateRoute,
                          initialRoute: "/",
                          scrollBehavior: ScrollGlowBehavior(),
                          debugShowCheckedModeBanner: false,
                          title: Constant.appName,
                          theme: ColorsRes.setAppTheme().copyWith(
                            textTheme: GoogleFonts.interTextTheme(
                              Theme.of(context).textTheme,
                            ),
                          ),
                          color: ColorsRes.primaryColor,
                          localizationsDelegates: const [
                            CountryLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                          ],
                          home: SplashScreen()),
                    ));
              },
            );
          });
        },
      ),
    );
  }
}
