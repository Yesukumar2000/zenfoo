import 'package:project/helper/utils/generalImports.dart';
import 'package:project/models/languageJsonData.dart';

enum LanguageState {
  initial,
  loading,
  updating,
  loaded,
  error,
}

class LanguageProvider extends ChangeNotifier {
  LanguageState languageState = LanguageState.initial;
  LanguageJsonData? jsonData;
  Map<dynamic, dynamic> currentLanguage = {};
  Map<dynamic, dynamic> currentLocalOfflineLanguage = {};
  String languageDirection = "";
  List<LanguageListData> languages = [];
  LanguageList? languageList;
  String message = "";
  String selectedLanguage = "0";

  Future getLanguageDataProvider({
    required Map<String, dynamic> params,
    required BuildContext context,
  }) async {
    languageState = LanguageState.updating;
    notifyListeners();

    try {
      Map<String, dynamic> getData =
          (await getSystemLanguageApi(context: context, params: params));

      if (getData[ApiAndParams.status].toString() == "1") {
        jsonData = LanguageJsonData.fromJson(getData);
        languageDirection = jsonData?.data?.type ?? "ltr";

        currentLanguage = jsonData?.data?.jsonData ?? {};
        Constant.session.setData(
          SessionManager.keySelectedLanguageId,
          jsonData?.data?.id?.toString() ?? "",
          false,
        );

        Constant.session.setData(
          SessionManager.keySelectedLanguageCode,
          jsonData?.data?.code?.toString() ?? "",
          false,
        );

        final String response =
            await rootBundle.loadString(Constant.getAssetsPath(4, "en"));
        context
            .read<LanguageProvider>()
            .setLocalLanguage(await json.decode(response));

        languageState = LanguageState.loaded;
        notifyListeners();
        return true;
      } else {
        message = Constant.somethingWentWrong;
        languageState = LanguageState.error;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("API Error in getLanguageDataProvider: $e");
      message = e.toString();

      // Load local offline language as fallback when API fails
      try {
        debugPrint("Loading local language file from assets/en.json");
        final String response =
            await rootBundle.loadString(Constant.getAssetsPath(4, "en"));
        currentLanguage = await json.decode(response);
        currentLocalOfflineLanguage = await json.decode(response);

        debugPrint("Local language loaded successfully. Keys count: ${currentLanguage.length}");

        // Set default language session data
        Constant.session.setData(
          SessionManager.keySelectedLanguageId,
          "1",
          false,
        );
        Constant.session.setData(
          SessionManager.keySelectedLanguageCode,
          "en",
          false,
        );

        // Set state to loaded since we successfully loaded local language
        languageState = LanguageState.loaded;
        message = ""; // Clear error message
        debugPrint("LanguageProvider state set to LOADED (offline mode)");
      } catch (localError) {
        debugPrint("Failed to load local language file: $localError");
        languageState = LanguageState.error;
      }

      notifyListeners();
    }
  }

  Future getAvailableLanguageList({
    required Map<String, dynamic> params,
    required BuildContext context,
  }) async {
    languageState = LanguageState.loading;
    notifyListeners();

    try {
      Map<String, dynamic> getData =
          (await getAvailableLanguagesApi(context: context, params: params));

      if (getData[ApiAndParams.status].toString() == "1") {
        languageList = LanguageList.fromJson(getData);
        languages = languageList?.data ?? [];
        languageState = LanguageState.loaded;
        notifyListeners();
      } else {
        message = Constant.somethingWentWrong;
        languageState = LanguageState.error;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("API Error in getAvailableLanguageList: $e");
      message = e.toString();

      // Create a default English language entry for offline use
      try {
        debugPrint("Creating default English language entry");
        languages = [
          LanguageListData(
            id: "1",
            name: "English",
            code: "en",
            isDefault: "1",
          ),
        ];
        // Set state to loaded since we have a default language available
        languageState = LanguageState.loaded;
        message = ""; // Clear error message
        debugPrint("Default language list created. State set to LOADED");
      } catch (localError) {
        debugPrint("Failed to create default language list: $localError");
        languageState = LanguageState.error;
      }

      notifyListeners();
    }
  }

  setLocalLanguage(Map<dynamic, dynamic> currentLocalLanguage) {
    currentLocalOfflineLanguage = currentLocalLanguage;
    notifyListeners();
  }

  setSelectedLanguage(String index) {
    selectedLanguage = index;
    notifyListeners();
  }
}
