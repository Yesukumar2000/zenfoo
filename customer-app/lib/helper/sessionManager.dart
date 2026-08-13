import 'package:google_sign_in/google_sign_in.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/PlaceDetailsModel.dart';

class SessionManager extends ChangeNotifier {
  static String isUserLogin = "isUserLogin";
  static String introSlider = "introSlider";
  static String isDarkTheme = "isDarkTheme";
  static String appThemeName = "appThemeName";
  static String keySelectedLanguageId = "selectedLanguageId";
  static String keySelectedLanguageCode = "selectedLanguageCode";
  static String keyRecentAddressSearch = "recentAddress";
  static String keySkipLogin = "keySkipLogin";
  static String keyUserId = "userId";
  static String keyUserName = "username";
  static String keyUserImage = "image";
  static String keyPhone = "phone";
  static String keyEmail = "email";
  static String keyCountryCode = "countryCode";
  static String keyReferralCode = "referral_code";
  static String keyUserStatus = "userStatus";
  static String keyToken = "keyToken";
  static String keyFCMToken = "keyFCMToken";
  static String keyIsGrid = "isGrid";
  static String keyLatitude = "keyLatitude";
  static String keyLongitude = "keyLongitude";
  static String keyAddress = "keyAddress";
  static String keyAddressObject = "keyAddressObject";

  static String keyMinutes = "keyMinutes";
  static String keyWalletBalance = "keyWalletBalance";
  static String keyGuestCartItems = "keyGuestCartItems";
  static String keyLoginType = "keyLoginType";

  static String keyPermissionGalleryHidePromptPermanently =
      "keyPermissionGalleryHidePromptPermanently";
  static String keyPermissionNotificationHidePromptPermanently =
      "keyPermissionNotificationHidePromptPermanently";
  static String keyPermissionLocationHidePromptPermanently =
      "keyPermissionLocationHidePromptPermanently";
  static String keyPermissionCameraHidePromptPermanently =
      "keyPermissionCameraHidePromptPermanently";
  static String keyPermissionMicrophoneHidePromptPermanently =
      "keyPermissionMicrophoneHidePromptPermanently";

  static String keyMilestoneBottomSheetShown = "keyMilestoneBottomSheetShown";

  // App update dismissal
  static String keyUpdateBannerDismissedVersion = "keyUpdateBannerDismissedVersion";

  //search address
  static String keySuggestionsCache = "input";
  static String keyPlaceDetails = "place_id";

  late SharedPreferences prefs;
  static final Map<String, dynamic> _memoryCache = {};

  static String keyProfileImage = "profileImage";

  SessionManager({required SharedPreferences? prefs}) {
    if (prefs != null) {
      this.prefs = prefs;
    } else {
      debugPrint("⚠️ SharedPreferences is null - using in-memory cache fallback");
      // Create a temporary mock object that will trigger error handling
      // All operations will be caught and use memory cache
    }
  }

  String getData(String id, {String defaultValue = ""}) {
    try {
      return prefs.getString(id) ?? defaultValue;
    } catch (e) {
      debugPrint("Error getting data for key $id: $e");
      // Try memory cache as fallback
      return _memoryCache[id] ?? defaultValue;
    }
  }

  void setData(String id, String val, bool isRefresh) {
    try {
      prefs.setString(id, val);
      if (isRefresh) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error setting data for key $id: $e");
      // Fallback to memory cache
      _memoryCache[id] = val;
      if (isRefresh) {
        notifyListeners();
      }
    }
  }

  List<CartList> getGuestCartItems() {
    if (getData(keyGuestCartItems).isNotEmpty) {
      return CartList.JsonToCartItems(getData(keyGuestCartItems));
    } else {
      return [];
    }
  }

  void addItemIntoList(String id, String item) {
    try {
      if (!Constant.searchedItemsHistoryList.contains(item)) {
        Constant.searchedItemsHistoryList.add(item);
        prefs.setStringList(id, Constant.searchedItemsHistoryList);
      }
    } catch (e) {
      debugPrint("Error adding item to list: $e");
    }
  }

  void clearItemList(String id) {
    try {
      Constant.searchedItemsHistoryList = [];
      prefs.setStringList(id, []);
    } catch (e) {
      debugPrint("Error clearing item list: $e");
    }
  }

  Future setUserData({
    required BuildContext context,
    required String userId,
    required String name,
    required String email,
    required String profile,
    required String countryCode,
    required String mobile,
    required String referralCode,
    required int status,
    required String token,
    required String balance,
    required String type,
  }) async {
    prefs.setString(keyToken, token);

    setData(keyUserId, userId, true);
    setData(keyUserName, name, true);
    setData(keyUserImage, profile, true);
    setData(keyEmail, email, true);
    prefs.setString(keyCountryCode, countryCode);
    prefs.setString(keyPhone, mobile);
    prefs.setString(keyReferralCode, referralCode);
    prefs.setInt(keyUserStatus, status);
    setBoolData(isUserLogin, true, true);
    prefs.setString(keyWalletBalance, balance.toString());
    prefs.setString(keyLoginType, type.toString());

    notifyListeners();
  }

  void setDoubleData(String key, double value) {
    prefs.setDouble(key, value);
    notifyListeners();
  }

  double getDoubleData(String key) {
    return prefs.getDouble(key) ?? 0.0;
  }

  bool getBoolData(String key) {
    return prefs.getBool(key) ?? false;
  }

  void setBoolData(String key, bool value, bool isRefresh) {
    prefs.setBool(key, value);
    if (isRefresh) notifyListeners();
  }

  int getIntData(String key) {
    return prefs.getInt(key) ?? 0;
  }

  void setIntData(String key, int value) {
    prefs.setInt(key, value);
    notifyListeners();
  }

  bool isUserLoggedIn() {
    return getBoolData(isUserLogin);
  }

  void logoutUser(BuildContext buildContext) {
    showModalBottomSheet(
      context: buildContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _LogoutBottomSheet(
        onLogout: () {
          Navigator.pop(context);
          _performLogout(buildContext);
        },
      ),
    );
  }

  void silentLogout(BuildContext buildContext) {
    _performLogout(buildContext);
  }

  void _performLogout(BuildContext buildContext) {
    AuthProviders _authProvider;
    if (getData(keyLoginType) == "phone") {
      _authProvider = AuthProviders.phone;
    } else {
      _authProvider = AuthProviders.apple;
    }

    buildContext.read<CartProvider>().resetCartList();
    logoutApi(context: buildContext, fcmToken: getData(keyFCMToken));
    String themeName = getData(appThemeName);
    String languageId = getData(keySelectedLanguageId);
    String latitude = getData(keyLatitude);
    String longitude = getData(keyLongitude);
    String address = getData(keyAddress);

    bool isDark = false;
    if (themeName == Constant.themeList[2]) {
      isDark = true;
    } else if (themeName == Constant.themeList[1]) {
      isDark = false;
    } else if (themeName == "" || themeName == Constant.themeList[0]) {
      var brightness = PlatformDispatcher.instance.platformBrightness;
      isDark = brightness == Brightness.dark;

      if (themeName == "") {
        setData(appThemeName, Constant.themeList[0], false);
      }
    }
    signOut(
      authProvider: _authProvider,
      firebaseAuth: FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(scopes: ["profile", "email"]),
    );
    prefs.clear();
    setBoolData(introSlider, true, false);
    setBoolData(isUserLogin, false, false);
    setData(appThemeName, themeName, false);
    setData(keySelectedLanguageId, languageId, false);
    setData(keyLatitude, latitude, false);
    setData(keyLongitude, longitude, false);
    setData(keyAddress, address, false);
    setBoolData(isDarkTheme, isDark, false);
    setBoolData(introSlider, true, false);
    buildContext.read<CartListProvider>().cartList.clear();
    Navigator.of(buildContext).pushNamedAndRemoveUntil(
        loginAccountScreen, (Route<dynamic> route) => false);
  }

  void deleteUserAccount(BuildContext buildContext) {
    AuthProviders authProvider;
    if (getData(keyLoginType) == "phone") {
      authProvider = AuthProviders.phone;
    }
    // else if (getData(keyLoginType) == "google") {
    //   authProvider = AuthProviders.google;
    // }

    else {
      authProvider = AuthProviders.apple;
    }
    showDialog<String>(
      context: buildContext,
      builder: (BuildContext context) => AlertDialog(
        surfaceTintColor: ColorsRes.appColorTransparent,
        backgroundColor: Theme.of(buildContext).cardColor,
        title: CustomTextLabel(
          jsonKey: deleteUserTitleLabel,
          softWrap: true,
        ),
        content: CustomTextLabel(
          jsonKey: deleteUserMessageLabel,
          softWrap: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomTextLabel(
              jsonKey: cancelLabel,
              softWrap: true,
              style: TextStyle(color: ColorsRes.subTitleMainTextColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              buildContext.read<CartProvider>().resetCartList();
              await getDeleteAccountApi(context: context)
                  .then((response) async {
                if (response["status"].toString() == "1") {
                  String themeName = getData(appThemeName);
                  String languageId = getData(keySelectedLanguageId);
                  String latitude = getData(keyLatitude);
                  String longitude = getData(keyLongitude);
                  String address = getData(keyAddress);

                  bool isDark = false;
                  if (themeName == Constant.themeList[2]) {
                    isDark = true;
                  } else if (themeName == Constant.themeList[1]) {
                    isDark = false;
                  } else if (themeName == "" ||
                      themeName == Constant.themeList[0]) {
                    var brightness =
                        PlatformDispatcher.instance.platformBrightness;
                    isDark = brightness == Brightness.dark;

                    if (themeName == "") {
                      setData(appThemeName, Constant.themeList[0], false);
                    }
                  }
                  signOut(
                    authProvider: authProvider,
                    firebaseAuth: FirebaseAuth.instance,
                    googleSignIn: GoogleSignIn(scopes: ["profile", "email"]),
                  );
                  prefs.clear();
                  setBoolData(introSlider, true, false);
                  setBoolData(isUserLogin, false, false);
                  setData(appThemeName, themeName, false);
                  setData(keyLatitude, latitude, false);
                  setData(keyLongitude, longitude, false);
                  setData(keyAddress, address, false);
                  setBoolData(isDarkTheme, isDark, false);
                  setBoolData(introSlider, true, false);
                  setData(keySelectedLanguageId, languageId, false);
                  context.read<CartListProvider>().cartList.clear();
                  Navigator.of(buildContext).pushNamedAndRemoveUntil(
                      loginAccountScreen, (Route<dynamic> route) => false);
                  showMessage(
                    context,
                    response["message"],
                    MessageType.success,
                  );
                } else {
                  Navigator.pop(context);
                  showMessage(
                    context,
                    response["message"],
                    MessageType.error,
                  );
                }
              });
            },
            child: CustomTextLabel(
              jsonKey: okLabel,
              softWrap: true,
              style: TextStyle(color: ColorsRes.appColor),
            ),
          ),
        ],
      ),
    );
  }

  // map catch data store already search
  Future<void> saveAutocompleteSuggestions() async {
    // Keep only the last 20 entries
    final entries = Constant.autocompleteSuggestionsCache.entries.toList();
    if (entries.length > 20) {
      entries.removeRange(0, entries.length - 20); // Remove oldest
    }

    // Convert to a Map<String, List> for storage
    final limitedCache = Map.fromEntries(entries);
    await prefs.setString(
      SessionManager.keySuggestionsCache,
      jsonEncode(limitedCache),
    );
  }

  Future<void> savePlaceDetails() async {
    final entries = Constant.placeSelectionMap.entries.toList();
    if (entries.length > 20) {
      entries.removeRange(0, entries.length - 20); // Remove oldest
    }

    // Convert to Map<String, PlaceSelection> for storage
    final limitedCache = Map.fromEntries(
      entries.map((e) => MapEntry(e.key, e.value.toJson())),
    );

    await prefs.setString(
      SessionManager.keyPlaceDetails,
      jsonEncode(limitedCache),
    );
  }

  Future<void> loadAutocompleteSuggestions() async {
    final cacheJson = prefs.getString(SessionManager.keySuggestionsCache);

    if (cacheJson != null && cacheJson.trim().isNotEmpty) {
      final Map<String, dynamic> decoded = jsonDecode(cacheJson);
      Constant.autocompleteSuggestionsCache = decoded.map(
        (key, value) => MapEntry(key, List<dynamic>.from(value)),
      );
    } else {
      Constant.autocompleteSuggestionsCache = {};
    }
  }

  Future<void> loadPlaceDetails() async {
    final cacheJson = prefs.getString(SessionManager.keyPlaceDetails);

    if (cacheJson != null && cacheJson.trim().isNotEmpty) {
      final Map<String, dynamic> decoded = jsonDecode(cacheJson);
      Constant.placeSelectionMap = decoded.map(
        (key, value) => MapEntry(
          key,
          PlaceDetailsModel.fromJson(value),
        ),
      );
    } else {
      Constant.placeSelectionMap = {};
    }
  }
}

/// Beautiful logout confirmation bottom sheet
class _LogoutBottomSheet extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutBottomSheet({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.watch<ThemeProvider>().colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextLabel(
                  jsonKey: logoutTitleLabel,
                  softWrap: true,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.textPrimary,
                    letterSpacing: -0.55,
                    height: 1.02,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: colorScheme.iconSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CustomTextLabel(
                  jsonKey: logoutMessageLabel,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colorScheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.buttonSecondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.border,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: CustomTextLabel(
                              jsonKey: cancelLabel,
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.buttonSecondaryText,
                                height: 1.02,
                                letterSpacing: -0.55,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Logout button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onLogout();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: CustomTextLabel(
                              jsonKey: okLabel,
                              softWrap: true,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.02,
                                letterSpacing: -0.55,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
