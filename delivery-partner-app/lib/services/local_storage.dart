import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenfoo_partner/models/delivery_boy_model.dart';

class LocalStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _deliveryBoyDataKey = 'delivery_boy_data';

  /// SAVE TOKEN
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// GET TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// REMOVE TOKEN (Logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// SAVE USER DATA
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  /// GET USER DATA
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  /// SAVE DELIVERY BOY DATA (accepts both DeliveryBoy model and Map)
  static Future<void> saveDeliveryBoyData(dynamic deliveryBoyData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = deliveryBoyData is DeliveryBoy
        ? deliveryBoyData.toJson()
        : deliveryBoyData as Map<String, dynamic>;
    await prefs.setString(_deliveryBoyDataKey, jsonEncode(jsonData));
  }

  /// GET DELIVERY BOY DATA as Map
  static Future<Map<String, dynamic>?> getDeliveryBoyData() async {
    final prefs = await SharedPreferences.getInstance();
    final deliveryBoyDataString = prefs.getString(_deliveryBoyDataKey);
    if (deliveryBoyDataString != null) {
      return jsonDecode(deliveryBoyDataString);
    }
    return null;
  }

  /// GET DELIVERY BOY DATA as Model
  static Future<DeliveryBoy?> getDeliveryBoyModel() async {
    final data = await getDeliveryBoyData();
    if (data != null) {
      return DeliveryBoy.fromJson(data);
    }
    return null;
  }

  /// CLEAR USER DATA
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  /// CLEAR DELIVERY BOY DATA
  static Future<void> clearDeliveryBoyData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deliveryBoyDataKey);
  }

  /// CHECK LOGIN
  // static Future<bool> isLoggedIn() async {
  //   return (await getToken()) != null;
  // }

  // Save require signup

  static const _isRequireSignupKey = 'isRequireSignup';
  static Future<void> saveRequireSignup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRequireSignupKey, value);
  }

  static Future<bool?> getRequireSignup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRequireSignupKey);
  }

  // document approve
  static const _isDocumentApprove = 'isDocumentApprove';
  static Future<void> saveDocumentApprove(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDocumentApprove, value);
  }

  static Future<bool?> getDocument() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isDocumentApprove);
  }

  static const userIdKey = 'user_id';

  // Save require signup
  static Future<void> saveUserId(String value) async {
    print('setting  userid $value');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userIdKey, value);
    String? setedUserId =  prefs.getString(userIdKey);
    print('=============+++++++++===============');
    print(setedUserId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  static Future<bool> isLoggedIn() async {
    return (await getUserId()) != null;
  }

  // Language preferences
  static const _selectedLanguageIdKey = 'selected_language_id';
  static const _selectedLanguageCodeKey = 'selected_language_code';

  /// Set selected language ID
  static Future<void> setSelectedLanguageId(String languageId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageIdKey, languageId);
  }

  /// Get selected language ID
  static Future<String> getSelectedLanguageId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageIdKey) ?? '';
  }

  /// Set selected language code
  static Future<void> setSelectedLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageCodeKey, languageCode);
  }

  /// Get selected language code
  static Future<String> getSelectedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageCodeKey) ?? 'en';
  }

  /// Clear language preferences
  static Future<void> clearLanguagePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLanguageIdKey);
    await prefs.remove(_selectedLanguageCodeKey);
  }

  /// Clear all local storage data
  static Future<void> clearLocalStorate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_isRequireSignupKey);
    await prefs.remove(_isDocumentApprove);
    await prefs.remove(userIdKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_deliveryBoyDataKey);
    await prefs.remove(_selectedLanguageIdKey);
    await prefs.remove(_selectedLanguageCodeKey);
  }
}
