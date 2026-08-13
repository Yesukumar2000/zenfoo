import 'package:flutter/cupertino.dart';
import 'package:project/helper/utils/generalImports.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late PackageInfo packageInfo;
  String currentAppVersion = "1.0.0";

  // Minimum time the static logo splash stays on screen so it doesn't flash
  // by before the APIs resolve.
  static const Duration _minSplashDuration = Duration(milliseconds: 1800);

  bool _apisCompleted = false;
  bool _minTimeElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[SPLASH] initState start');

    // Keep the logo on screen for at least _minSplashDuration.
    Future.delayed(_minSplashDuration).then((_) {
      _minTimeElapsed = true;
      debugPrint('[SPLASH] _minTimeElapsed=true');
      _tryNavigate();
    });

    // Start API loading
    Future.delayed(const Duration(milliseconds: 300)).then((_) async {
      debugPrint('[SPLASH] post-300ms: requesting notif perm + starting APIs');
      try {
        LocalAwesomeNotification().requestNotificationPermission(context);
      } catch (e, st) {
        debugPrint('[SPLASH] notif perm threw: $e\n$st');
      }
      await callAllApis();
      _apisCompleted = true;
      debugPrint('[SPLASH] _apisCompleted=true (after callAllApis)');
      _tryNavigate();
    });

    // Hard ceiling: never wait longer than 12s on the splash regardless of
    // API state, so a stuck request can never strand the user on the splash.
    Future.delayed(const Duration(seconds: 12)).then((_) {
      if (!_apisCompleted && mounted) {
        debugPrint('[SPLASH] hard-timeout 12s -> forcing _apisCompleted=true');
        _apisCompleted = true;
        _tryNavigate();
      }
    });
    debugPrint('[SPLASH] initState end');
  }

  // Navigate only when BOTH the APIs are done AND the minimum splash time has
  // elapsed.
  void _tryNavigate() {
    debugPrint(
        '[SPLASH] _tryNavigate: navigated=$_navigated, mounted=$mounted, apis=$_apisCompleted, minTime=$_minTimeElapsed');
    if (_navigated || !mounted) return;
    if (_apisCompleted && _minTimeElapsed) {
      _navigated = true;
      debugPrint('[SPLASH] _tryNavigate: both done -> startTime()');
      startTime();
    } else {
      debugPrint(
          '[SPLASH] _tryNavigate: still waiting (apis=$_apisCompleted, minTime=$_minTimeElapsed)');
    }
  }

  Future callAllApis() async {
    debugPrint('[SPLASH] callAllApis: start');
    try {
      packageInfo = await PackageInfo.fromPlatform();
      currentAppVersion = packageInfo.version;
      debugPrint('[SPLASH] callAllApis: packageInfo loaded, version=$currentAppVersion');

      Map<String, String> params = {ApiAndParams.system_type: "1"};
      if (Constant.session
          .getData(SessionManager.keySelectedLanguageId)
          .isEmpty) {
        params[ApiAndParams.is_default] = "1";
        debugPrint('[SPLASH] callAllApis: no saved language id, using default');
      } else {
        params[ApiAndParams.id] = Constant.session.getData(
          SessionManager.keySelectedLanguageId,
        );
        debugPrint('[SPLASH] callAllApis: language id=${params[ApiAndParams.id]}');
      }

      debugPrint('[SPLASH] callAllApis: dispatching 3 API calls in parallel (timeout 15s)');
      // Execute API calls in parallel with a timeout so the splash never hangs
      await Future.wait([
        context.read<AppSettingsProvider>().getAppSettingsProvider(context).then((v) {
          debugPrint('[SPLASH] callAllApis: getAppSettingsProvider resolved');
          return v;
        }),
        context.read<LanguageProvider>().getAvailableLanguageList(
          params: {ApiAndParams.system_type: "1"},
          context: context,
        ).then((v) {
          debugPrint('[SPLASH] callAllApis: getAvailableLanguageList resolved');
          return v;
        }),
        context.read<LanguageProvider>().getLanguageDataProvider(
              params: params,
              context: context,
            ).then((v) {
          debugPrint('[SPLASH] callAllApis: getLanguageDataProvider resolved');
          return v;
        }),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("[SPLASH] callAllApis: TIMEOUT after 15s — proceeding with fallback");
          return [];
        },
      );
      debugPrint('[SPLASH] callAllApis: Future.wait returned');

      if (context.read<LanguageProvider>().languageState ==
              LanguageState.loaded &&
          context.read<AppSettingsProvider>().settingsState ==
              SettingsState.loaded) {
        debugPrint("[SPLASH] Both providers loaded. Starting app...");
      } else {
        debugPrint(
            "[SPLASH] Providers not loaded. Language: ${context.read<LanguageProvider>().languageState}, Settings: ${context.read<AppSettingsProvider>().settingsState}");
      }
    } catch (e, stackTrace) {
      debugPrint("[SPLASH] Error in callAllApis: $e\n$stackTrace");
    }
    debugPrint('[SPLASH] callAllApis: end');
  }

  startTime() async {
    debugPrint('[SPLASH] startTime: entered');
    try {
    debugPrint('[SPLASH] startTime: maintenance=${Constant.appMaintenanceMode}, '
        'isUserLogin=${Constant.session.getBoolData(SessionManager.isUserLogin)}, '
        'userStatus=${Constant.session.getIntData(SessionManager.keyUserStatus)}, '
        'skipLogin=${Constant.session.getBoolData(SessionManager.keySkipLogin)}, '
        'lat=${Constant.session.getData(SessionManager.keyLatitude)}, '
        'lng=${Constant.session.getData(SessionManager.keyLongitude)}, '
        'isVersionSystemOn=${Constant.isVersionSystemOn}, '
        'requiredVersion=${Constant.currentRequiredAppVersion}, '
        'currentVersion=$currentAppVersion');
    if (Constant.appMaintenanceMode == "1") {
      debugPrint('[SPLASH] startTime: routing -> UnderMaintenanceScreen');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => const UnderMaintenanceScreen(),
          ),
        );
      }
    } else {
      if (Constant.session.getBoolData(SessionManager.isUserLogin) &&
          Constant.session.getIntData(SessionManager.keyUserStatus) == 2) {
        if (Constant.isVersionSystemOn == "1" &&
            (Version.parse(Constant.currentRequiredAppVersion) >
                Version.parse(currentAppVersion))) {
          if (Constant.requiredForceUpdate == "1") {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => const EditProfile(),
                ),
              );
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => AppUpdateScreen(canIgnoreUpdate: true),
                ),
              );
            }
          } else {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (context) => const EditProfile(),
                ),
              );
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => AppUpdateScreen(canIgnoreUpdate: false),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              CupertinoPageRoute(
                builder: (context) => const EditProfile(),
              ),
            );
          }
        }
      } else {
        if (Constant.session.getBoolData(SessionManager.keySkipLogin) ||
            Constant.session.getBoolData(SessionManager.isUserLogin)) {
          if ((Constant.session.getData(SessionManager.keyLatitude) == "" &&
                  Constant.session.getData(SessionManager.keyLongitude) ==
                      "") ||
              (Constant.session.getData(SessionManager.keyLatitude) == "0" &&
                  Constant.session.getData(SessionManager.keyLongitude) ==
                      "0")) {
            if (Constant.isVersionSystemOn == "1" &&
                (Version.parse(Constant.currentRequiredAppVersion) >
                    Version.parse(currentAppVersion))) {
              if (Constant.requiredForceUpdate == "1") {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(
                      builder: (context) => HomeMainScreen(),
                    ),
                  );
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) =>
                          AppUpdateScreen(canIgnoreUpdate: true),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(
                      builder: (context) => HomeMainScreen(),
                    ),
                  );
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) =>
                          AppUpdateScreen(canIgnoreUpdate: false),
                    ),
                  );
                }
              }
            } else {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  CupertinoPageRoute(
                    builder: (context) => HomeMainScreen(),
                  ),
                );
              }
            }
          } else {
            if (Constant.isVersionSystemOn == "1" &&
                (Version.parse(Constant.currentRequiredAppVersion) >
                    Version.parse(currentAppVersion))) {
              if (Constant.requiredForceUpdate == "1") {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(
                      builder: (context) => HomeMainScreen(),
                    ),
                  );
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) =>
                          AppUpdateScreen(canIgnoreUpdate: true),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(
                      builder: (context) => HomeMainScreen(),
                    ),
                  );
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) =>
                          AppUpdateScreen(canIgnoreUpdate: false),
                    ),
                  );
                }
              }
            } else {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  CupertinoPageRoute(
                    builder: (context) => HomeMainScreen(),
                  ),
                );
              }
            }
          }
        } else {
          debugPrint("[SPLASH] startTime: routing -> LoginAccountScreen");
          if (mounted) {
            Navigator.of(context).pushReplacement(
              CupertinoPageRoute(
                builder: (context) => LoginAccountScreen(),
              ),
            );
          }
        }
      }
    }
    } catch (e, st) {
      debugPrint('[SPLASH] startTime: EXCEPTION $e\n$st');
    }
    debugPrint('[SPLASH] startTime: end');
  }

  bool networkCheck() {
    checkInternetConnection().then((checkInternet) {
      if (checkInternet) {
        debugPrint('Internet is available!');
        return true;
      } else {
        debugPrint('No internet connection!');
        return false;
      }
    }).catchError((e) {
      debugPrint('Error: $e');
      return e;
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Consumer<LanguageProvider>(
      builder: (contextLanguageProvider, languageProvider, child) {
        return Consumer<AppSettingsProvider>(
          builder: (context, appSettingsProvider, child) {
            if (languageProvider.languageState == LanguageState.error ||
                appSettingsProvider.settingsState == SettingsState.error) {
              bool hasTranslations =
                  languageProvider.currentLanguage.isNotEmpty ||
                      languageProvider.currentLocalOfflineLanguage.isNotEmpty;

              debugPrint(
                  "Error state detected. Has translations: $hasTranslations");

              return Scaffold(
                backgroundColor: colorScheme.primary,
                body: DefaultBlankItemMessageScreen(
                  height: context.height,
                  image: languageProvider.message.isNotEmpty
                      ? languageProvider.message
                      : appSettingsProvider.message ==
                              Constant.noInternetConnection
                          ? "no_internet_icon"
                          : "something_went_wrong",
                  title: languageProvider.message.isNotEmpty
                      ? languageProvider.message
                      : appSettingsProvider.message ==
                              Constant.noInternetConnection
                          ? noInternetTitleLabel
                          : somethingWentWrongTitleLabel,
                  description: languageProvider.message.isNotEmpty
                      ? languageProvider.message
                      : appSettingsProvider.message ==
                              Constant.noInternetConnection
                          ? noInternetDescriptionLabel
                          : somethingWentWrongDescriptionLabel,
                  buttonTitle: tryAgainLabel,
                  isTranslationKey: hasTranslations,
                  callback: () async {
                    await callAllApis();
                  },
                ),
              );
            } else {
              return Scaffold(
                // Soft off-white (not pure white) splash background.
                backgroundColor: const Color(0xFFF6F6F3),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/zenfoLogo.png',
                        width: context.width * 0.5,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "zenfoo",
                        style: TextStyle(
                          color: ColorsRes.primaryColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

}
