import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:zenfoo_partner/models/language_model.dart';
import 'package:zenfoo_partner/repository/language_repository.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/services/local_storage.dart';

enum LanguageState { initial, loading, updating, loaded, error }

class LanguageProvider extends ChangeNotifier {
  final LanguageRepository _repository = LanguageRepository();

  LanguageState languageState = LanguageState.initial;
  LanguageJsonData? jsonData;
  Map<String, dynamic> currentLanguage = {};
  Map<String, dynamic> currentLocalOfflineLanguage = {};
  String languageDirection = "ltr"; // "ltr" or "rtl"
  List<LanguageListData> languages = [];
  String selectedLanguageId = '';
  String selectedLanguageCode = 'en';
  String message = '';

  LanguageProvider() {
    // Initialize offline language immediately when provider is created
    _initializeOfflineLanguage();
  }

  /// Initialize offline language synchronously
  void _initializeOfflineLanguage() {
    rootBundle.loadString('assets/en.json').then((jsonString) {
      try {
        debugPrint('📁 Successfully loaded en.json from assets');
        final Map<String, dynamic> parsed = jsonDecode(jsonString);
        currentLocalOfflineLanguage = Map<String, dynamic>.from(parsed);
        debugPrint('✅ Loaded offline language fallback');
        debugPrint('🔑 Total keys loaded: ${currentLocalOfflineLanguage.length}');
        
        // Check if our specific key exists
        if (currentLocalOfflineLanguage.containsKey('earn_more_with_every_delivery')) {
          debugPrint('✅ Found earn_more_with_every_delivery in offline language');
        } else {
          debugPrint('❌ earn_more_with_every_delivery NOT found in offline language');
          debugPrint('🔑 Available keys starting with "earn": ${currentLocalOfflineLanguage.keys.where((k) => k.startsWith('earn')).toList()}');
        }
        notifyListeners();
      } catch (e) {
        debugPrint('⚠️ Error parsing offline language: $e');
        currentLocalOfflineLanguage = {};
      }
    }).catchError((e) {
      debugPrint('⚠️ Could not load offline language: $e');
      currentLocalOfflineLanguage = {};
    });
  }

  /// Initialize language on app start
  Future<void> initializeLanguage() async {
    try {
      debugPrint('🚀 Starting language initialization...');
      languageState = LanguageState.loading;
      notifyListeners();

      // Get stored language preference
      final storedLanguageId = await LocalStorage.getSelectedLanguageId();
      final storedLanguageCode = await LocalStorage.getSelectedLanguageCode();

      selectedLanguageId = storedLanguageId;
      selectedLanguageCode = storedLanguageCode;

      // Load offline fallback language (English base + selected language overlay)
      debugPrint('📁 Loading offline language...');
      await _loadOfflineLanguage();
      debugPrint('✅ Offline language loaded successfully');

      // Fetch available languages
      await getAvailableLanguageList();

      // Load the selected or default language
      if (selectedLanguageId.isNotEmpty) {
        await getLanguageData(selectedLanguageId);
      } else if (languages.isNotEmpty) {
        // Use first language if nothing stored
        final defaultLanguage = languages.firstWhere(
          (l) => l.isDefault,
          orElse: () => languages.first,
        );
        await getLanguageData(defaultLanguage.id);
      }

      languageState = LanguageState.loaded;
      debugPrint('✅ Language initialization completed');
    } catch (e) {
      debugPrint('❌ Error initializing language: $e');
      languageState = LanguageState.error;
      message = 'Failed to load language: $e';
    }
    notifyListeners();
  }

  /// Fetch available languages from API
  Future<void> getAvailableLanguageList() async {
    try {
      final response = await _repository.getAvailableLanguages(
        params: {'system_type': '2'},
      );

      if (response.status == ApiStatus.success && response.data != null) {
        // The response.data is the full response object with status, message, total, and data fields
        final langList = LanguageList.fromJson(response.data!);
        languages = langList.data;
        debugPrint('✅ Loaded ${languages.length} languages');
      } else {
        debugPrint('⚠️ Failed to load languages: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching language list: $e');
      // _useDefaultLanguages();
    }
    notifyListeners();
  }

  /// Fetch language translations from API
  Future<void> getLanguageData(String languageId) async {
    try {
      languageState = LanguageState.updating;
      notifyListeners();

      final response = await _repository.getLanguageData(
        params: {
          'system_type': '2',
          'id': languageId,
        },
      );

      if (response.status == ApiStatus.success && response.data != null) {
        // The response.data contains the data object directly
        jsonData = LanguageJsonData.fromJson(response.data!);
        currentLanguage = jsonData?.data?.jsonData ?? {};
        languageDirection = jsonData?.data?.type ?? 'ltr';

        // Update stored preferences
        selectedLanguageId = languageId;
        selectedLanguageCode = jsonData?.data?.code ?? 'en';

        await LocalStorage.setSelectedLanguageId(languageId);
        await LocalStorage.setSelectedLanguageCode(selectedLanguageCode);

        debugPrint('✅ Loaded language: ${jsonData?.data?.name}');
        languageState = LanguageState.loaded;
      } else {
        throw Exception(response.message ?? 'Failed to fetch language data');
      }
    } catch (e) {
      debugPrint('❌ Error fetching language data: $e');
      // API failed — resolve the target language's code/direction from the
      // cached list so we can fall back to its bundled offline file (and still
      // apply the correct text direction, e.g. RTL for Urdu).
      try {
        final target = languages.firstWhere((l) => l.id == languageId);
        selectedLanguageId = languageId;
        selectedLanguageCode = target.code.isNotEmpty ? target.code : 'en';
        languageDirection = target.type;
        await LocalStorage.setSelectedLanguageId(languageId);
        await LocalStorage.setSelectedLanguageCode(selectedLanguageCode);
        await _overlayBundledLanguage(selectedLanguageCode);
      } catch (_) {
        // Language not in cached list — keep English base.
      }
      // Fall back to offline language
      currentLanguage = currentLocalOfflineLanguage;
      languageState = LanguageState.error;
      message = 'Using offline language: $e';
    }
    notifyListeners();
  }

  /// Change language
  Future<void> changeLanguage(String languageId) async {
    await getLanguageData(languageId);
  }

  /// Load offline fallback language.
  ///
  /// English (en.json) is always loaded as the base so every key resolves to
  /// something readable. If the selected language ships a bundled offline file
  /// (e.g. assets/ur.json for Urdu), its translations are overlaid on top so
  /// the app works in that language even when the translation API is offline.
  Future<void> _loadOfflineLanguage() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/en.json');
      debugPrint('📁 Successfully loaded en.json from assets');
      // Parse JSON and store in currentLocalOfflineLanguage
      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      currentLocalOfflineLanguage = Map<String, dynamic>.from(parsed);
      debugPrint('✅ Loaded offline language fallback');
      debugPrint('🔑 Total keys loaded: ${currentLocalOfflineLanguage.length}');

      // Overlay the selected language's bundled file (if any) on top of English.
      await _overlayBundledLanguage(selectedLanguageCode);
    } catch (e) {
      debugPrint('⚠️ Could not load offline language: $e');
      currentLocalOfflineLanguage = {};
    }
  }

  /// Overlay a bundled language file (assets/<code>.json) over the English base.
  /// Silently does nothing for English or when no bundled file exists.
  Future<void> _overlayBundledLanguage(String code) async {
    if (code.isEmpty || code == 'en') return;
    try {
      final String jsonString = await rootBundle.loadString('assets/$code.json');
      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      currentLocalOfflineLanguage.addAll(Map<String, dynamic>.from(parsed));
      debugPrint('✅ Overlaid bundled offline language: $code.json');
    } catch (e) {
      // No bundled file for this language — English base remains the fallback.
      debugPrint('ℹ️ No bundled offline file for "$code" (using English fallback)');
    }
  }

  /// Get translated text by key
  String getTranslatedText(String key) {
    // First try online language
    if (currentLanguage.containsKey(key)) {
      return currentLanguage[key].toString();
    }
    // Fall back to offline language
    if (currentLocalOfflineLanguage.containsKey(key)) {
      return currentLocalOfflineLanguage[key].toString();
    }
    // Debug: Check if offline language has any data
    if (currentLocalOfflineLanguage.isEmpty) {
      debugPrint('⚠️ Offline language is empty when looking for key: $key');
    }
    // Return key itself as last resort
    return key;
  }

  /// Set selected language
  void setSelectedLanguage(String languageId) {
    selectedLanguageId = languageId;
    notifyListeners();
  }

  /// Get language name by ID
  String getLanguageName(String languageId) {
    try {
      return languages.firstWhere((l) => l.id == languageId).displayName;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Use default hardcoded languages if API fails
  void _useDefaultLanguages() {
    languages = [
      LanguageListData(
        id: '1',
        name: 'English',
        code: 'en',
        type: 'ltr',
        systemType: '2',
        isDefault: true,
        systemTypeName: 'Seller and delivery boy App',
        displayName: 'English',
      ),
      LanguageListData(
        id: '2',
        name: 'తెలుగు',
        code: 'te',
        type: 'ltr',
        systemType: '2',
        isDefault: false,
        systemTypeName: 'Seller and delivery boy App',
        displayName: 'తెలుగు',
      ),
    ];
    debugPrint('✅ Using default languages as fallback');
  }

  /// Get text direction
  bool get isRTL => languageDirection == 'rtl';
}
