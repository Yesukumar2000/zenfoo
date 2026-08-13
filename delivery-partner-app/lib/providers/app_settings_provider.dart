import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenfoo_partner/repository/app_settings_repository.dart';
import 'package:zenfoo_partner/utils/notification_helper.dart';

const platform = MethodChannel('com.zenfoo.partner/google_maps');

class AppSettingsProvider extends ChangeNotifier {
  final AppSettingsRepository _repository = AppSettingsRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch and store app settings from backend
  /// This should be called during app initialization
  Future<bool> initializeAppSettings({
    required Map<String, dynamic> params,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📱 Initializing app settings...');

      final settings = await _repository.getAppSettings(params: params);

      if (settings == null) {
        _errorMessage = 'Failed to fetch app settings';
        _isLoading = false;
        notifyListeners();
        debugPrint('❌ Settings initialization failed: $_errorMessage');
        return false;
      }

      // Update Constant class with fetched settings
      _updateConstantWithSettings(settings);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      debugPrint('✅ App settings initialized successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Error initializing app settings: $_errorMessage');
      return false;
    }
  }

  /// Update Constant class with fetched settings
  void _updateConstantWithSettings(Map<String, dynamic> settings) {
    // Update API key first
    if (settings['googlePlaceApiKey'] != null) {
      Constant.googleApiKey = settings['googlePlaceApiKey'];
      debugPrint('🔑 Google API Key: ${Constant.googleApiKey}');

      // Update iOS Google Maps API key via method channel
      if (Platform.isIOS) {
        _updateIOSGoogleApiKey(Constant.googleApiKey);
      }
    }

    // Update app settings
    Constant.currency = settings['currency'] ?? '';
    Constant.currencyCode = settings['currencyCode'] ?? '';
    Constant.currencyDecimalPoint = settings['decimalPoint'] ?? '';
    Constant.privacyPolicy = settings['privacyPolicy'] ?? '';
    Constant.termsConditions = settings['termsConditions'] ?? '';

    // Delivery boy specific settings
    if (settings['appModeDeliveryBoy'] != null) {
      Constant.appMaintenanceMode = settings['appModeDeliveryBoy'];
    }
    if (settings['appModeDeliveryBoyRemark'] != null) {
      Constant.appMaintenanceModeRemark = settings['appModeDeliveryBoyRemark'];
    }
    if (settings['enableRoadPathTracking'] != null) {
      Constant.enableRoadPathTracking = settings['enableRoadPathTracking'];
    }

    // Seller specific settings
    if (settings['sellerCommission'] != null) {
      Constant.sellerCommission = settings['sellerCommission'];
    }
    if (settings['appModeSeller'] != null) {
      Constant.appMaintenanceMode = settings['appModeSeller'];
    }
    if (settings['viewCustomerDetail'] != null) {
      Constant.viewCustomerDetail = settings['viewCustomerDetail'];
    }

    debugPrint('📊 Settings updated: currency=${{Constant.currency}}, '
        'enableRoadPathTracking=${Constant.enableRoadPathTracking}');
  }

  /// Update iOS Google Maps API key via method channel
  Future<void> _updateIOSGoogleApiKey(String apiKey) async {
    try {
      final result = await platform.invokeMethod<bool>('updateGoogleApiKey', {
        'apiKey': apiKey,
      });

      if (result == true) {
        debugPrint('✅ iOS Google API Key updated successfully');
      } else {
        debugPrint('⚠️ iOS Google API Key update returned false');
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to update iOS Google API Key: ${e.message}');
    }
  }

  /// Get current Google API key
  String getGoogleApiKey() {
    return Constant.googleApiKey;
  }
}
