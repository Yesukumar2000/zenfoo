import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

/// PhonePe SDK Helper Class (v3.0.2)
///
/// IMPORTANT: This SDK version requires a backend server integration!
/// It CANNOT work fully client-side as it needs:
/// 1. Backend server to call PhonePe's Payment Gateway API (/pg/v1/pay)
/// 2. Backend to receive response with 'token' from PhonePe
/// 3. Backend to return orderId + token to this Flutter app
///
/// The SDK's startTransaction() expects a JSON object with:
/// {
///   "orderId": "merchant_order_id",      // Your backend's order ID
///   "token": "phonepe_session_token",    // Token from PhonePe API response
///   "paymentMode": "UPI|CARD|WALLET",   // Payment method
///   "targetAppPackageName": "..."        // (Optional) Specific UPI app
/// }
///
/// This is NOT the same as the standard Payment Gateway API that uses base64 + checksum!
class PhonePeSdkHelper {
  static bool _isInitialized = false;

  /// PhonePe SDK Environment
  /// Use "SANDBOX" for testing, "PRODUCTION" for live
  static const String environment =
      "SANDBOX"; // Change to "PRODUCTION" for live

  /// Enable logging for debugging
  static const bool enableLogging = true;

  /// Store merchant ID and app ID from backend
  static String? _merchantId;
  static String? _appId;

  /// PhonePe Test Credentials (SANDBOX)
  static const String testMerchantId = 'PGTESTPAYUAT';
  static const String testSaltKey = '96434309-7796-489d-8924-ab56988a6076';
  static const String testSaltIndex = '1';

  /// Initialize PhonePe SDK with dynamic credentials
  /// According to official PhonePe documentation
  ///
  /// Params:
  ///   - environment: "SANDBOX" or "PRODUCTION"
  ///   - merchantId: The merchant id provided by PhonePe at the time of onboarding
  ///   - flowId: An alphanumeric string for tracking user journeys
  ///             Recommended: Pass user-specific information or merchant user-id
  ///   - enableLogging: Enable/disable SDK logging
  static Future<bool> initPhonePeSDK({
    required String merchantId,
    String? flowId,
  }) async {
    if (_isInitialized && _merchantId == merchantId) {
      debugPrint('📱 [PhonePe SDK] Already initialized for merchant: $merchantId');
      return true;
    }

    try {
      _merchantId = merchantId;
      _appId = flowId ?? merchantId;

      debugPrint('📱 [PhonePe SDK] Initializing...');
      debugPrint('📱 [PhonePe SDK] Environment: $environment');
      debugPrint('📱 [PhonePe SDK] Merchant ID: $_merchantId');
      debugPrint('📱 [PhonePe SDK] Flow ID: $_appId');

      bool result = await PhonePePaymentSdk.init(
        environment,
        _merchantId!,
        _appId!,
        true,
      ).then((isInitialized) {
        _isInitialized = isInitialized;
        debugPrint('📱 [PhonePe SDK] Init result: $isInitialized');
        return isInitialized;
      }).catchError((error) {
        debugPrint('❌ [PhonePe SDK] Init Error: $error');
        _isInitialized = false;
        return false;
      });

      return result;
    } catch (e) {
      debugPrint('❌ [PhonePe SDK] Init Exception: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Check if SDK is initialized
  static bool isInitialized() {
    return _isInitialized;
  }

  /// Start PhonePe transaction with SDK v3.0.2
  ///
  /// IMPORTANT: The 'body' parameter should be a JSON string (NOT base64!) with format:
  /// {
  ///   "orderId": "merchant_order_id",
  ///   "token": "token_from_phonepe_api",
  ///   "paymentMode": "UPI" or "CARD" or "WALLET",
  ///   "targetAppPackageName": "com.phonepe.app" (optional)
  /// }
  ///
  /// Parameters:
  /// - body: JSON string with orderId, token, and paymentMode (from backend!)
  /// - checksum: Not used by SDK v3.0.2 (kept for backward compatibility)
  /// - merchantId: Merchant ID (used to verify SDK is initialized)
  /// - appId: (Optional) App ID
  /// - appSchema: Callback URL scheme for the app (e.g., "zenfoo")
  /// - packageName: (Optional) Specific UPI app package name (used as targetAppPackageName in request)
  /// - callback: Callback function to handle response
  static Future<void> startTransaction({
    required String body,
    required String checksum,
    required String merchantId,
    String? appId,
    String? appSchema,
    String? packageName,
    required Function(Map<String, dynamic>) callback,
  }) async {
    if (!_isInitialized || _merchantId != merchantId) {
      debugPrint('📱 [PhonePe SDK] Not initialized for merchant $merchantId. Initializing...');
      bool initialized = await initPhonePeSDK(
        merchantId: merchantId,
        flowId: appId,
      );
      if (!initialized) {
        debugPrint('❌ [PhonePe SDK] SDK initialization failed in startTransaction');
        callback({
          'status': 'FAILED',
          'error': 'SDK initialization failed',
        });
        return;
      }
    }

    try {
      debugPrint('📱 [PhonePe SDK] Starting transaction...');
      debugPrint('📱 [PhonePe SDK] Body: $body');
      debugPrint('📱 [PhonePe SDK] App Schema: ${appSchema ?? "zenfoo"}');
      if (packageName != null) {
        debugPrint('📱 [PhonePe SDK] Package Name: $packageName');
      }

      // PhonePe SDK v3.0.2 startTransaction signature:
      // static Future<Map?> startTransaction(String request, String appSchema)
      //
      // The 'request' parameter must be a JSON string with orderId, token, and paymentMode
      // NOT the base64-encoded body from Payment Gateway API!
      try {
        debugPrint('📱 [PhonePe SDK] Calling PhonePePaymentSdk.startTransaction');
        debugPrint('📱 [PhonePe SDK] Request JSON: $body');
        debugPrint('📱 [PhonePe SDK] Package: ${packageName ?? "empty"}');

        // SDK call with 2 parameters: (requestJSON, appSchema)
        final result = await PhonePePaymentSdk.startTransaction(
          body,
          packageName ?? '',
        );

        debugPrint('📱 [PhonePe SDK] Transaction Response: $result');

        if (result != null) {
          if (result['status'] == 'FAILURE') {
            debugPrint('❌ [PhonePe SDK] Transaction failed with status FAILURE');
            callback({
              'status': 'FAILED',
              'error': result['error'] ?? 'Transaction failed',
            });
          } else {
            debugPrint('📱 [PhonePe SDK] Transaction succeeded');
            callback({
              'status': 'SUCCESS',
              'data': result,
            });
          }
        } else {
          debugPrint('❌ [PhonePe SDK] No response from PhonePe SDK');
          callback({
            'status': 'FAILED',
            'error': 'No response from PhonePe SDK',
          });
        }
      } catch (sdkError) {
        debugPrint('❌ [PhonePe SDK] SDK Error: $sdkError');

        final errorMsg = sdkError.toString();
        if (errorMsg.contains('cannot be converted to JSONObject')) {
          callback({
            'status': 'FAILED',
            'error':
                'SDK Error: Second parameter should be appSchema (callback URL scheme), not checksum. Error: $errorMsg',
          });
        } else {
          callback({
            'status': 'FAILED',
            'error': 'SDK Error: ${sdkError.toString()}',
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [PhonePe SDK] Transaction Exception: $e');
      callback({
        'status': 'FAILED',
        'error': e.toString(),
      });
    }
  }

  /// Get list of UPI apps installed on device
  /// Uses PhonePe SDK's platform-specific methods
  static Future<List<Map<String, String>>> getUpiApps({String? merchantId}) async {
    try {
      debugPrint('📱 [PhonePe SDK] getUpiApps() called, isInitialized: $_isInitialized');
      // Initialize with provided merchantId or test credentials
      if (!_isInitialized) {
        final initMerchantId = merchantId ?? 'PGTESTPAYUAT';
        debugPrint('📱 [PhonePe SDK] Initializing for getUpiApps with merchantId: $initMerchantId');
        await initPhonePeSDK(
            merchantId: initMerchantId, flowId: initMerchantId);
      }

      List<Map<String, String>> appsList = [];

      // Android: getUpiAppsForAndroid returns JSON string
      if (Platform.isAndroid) {
        try {
          final String? upiAppsJson =
              await PhonePePaymentSdk.getUpiAppsForAndroid();
          log('PhonePe SDK getUpiAppsForAndroid response: $upiAppsJson');

          if (upiAppsJson != null && upiAppsJson.isNotEmpty) {
            final List<dynamic> upiApps = json.decode(upiAppsJson);

            for (var app in upiApps) {
              if (app is Map) {
                appsList.add({
                  'packageName': app['packageName']?.toString() ?? '',
                  'appName': app['applicationName']?.toString() ??
                      app['appName']?.toString() ??
                      '',
                });
              }
            }

            log('Processed ${appsList.length} UPI apps from PhonePe SDK (Android)');
          }
        } catch (e) {
          log('PhonePe SDK getUpiAppsForAndroid failed: $e');
        }
      }
      // iOS: getInstalledUpiAppsForiOS returns List of app names
      else if (Platform.isIOS) {
        try {
          final List<Object?>? upiApps =
              await PhonePePaymentSdk.getInstalledUpiAppsForiOS();
          log('PhonePe SDK getInstalledUpiAppsForiOS response: $upiApps');

          if (upiApps != null) {
            for (var appName in upiApps) {
              if (appName != null) {
                appsList.add({
                  'packageName':
                      appName.toString().toLowerCase().replaceAll(' ', '.'),
                  'appName': appName.toString(),
                });
              }
            }

            log('Processed ${appsList.length} UPI apps from PhonePe SDK (iOS)');
          }
        } catch (e) {
          log('PhonePe SDK getInstalledUpiAppsForiOS failed: $e');
        }
      }

      return appsList;
    } catch (e) {
      debugPrint('❌ [PhonePe SDK] Error getting UPI apps: $e');
      return [];
    }
  }

  /// Generate unique transaction ID
  static String generateTransactionId(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(9999);
    return 'TXN_${userId}_${timestamp}_$random';
  }

  /// Create PhonePe transaction payload
  static Map<String, dynamic> createTransactionPayload({
    required String merchantId,
    required String merchantTransactionId,
    required String userId,
    required int amountInPaise,
    required String mobileNumber,
    String? callbackUrl,
    String? redirectUrl,
  }) {
    return {
      'merchantId': merchantId,
      'merchantTransactionId': merchantTransactionId,
      'merchantUserId': userId,
      'amount': amountInPaise,
      'mobileNumber': mobileNumber,
      'callbackUrl': callbackUrl ?? 'https://webhook.site/callback-url',
      'redirectUrl': redirectUrl ?? 'https://webhook.site/redirect-url',
      'redirectMode': 'POST',
      'paymentInstrument': {
        'type': 'PAY_PAGE',
      }
    };
  }

  /// Generate checksum for PhonePe transaction
  /// Format: SHA256(base64Body + "/pg/v1/pay" + saltKey) + "###" + saltIndex
  static String generateChecksum(
    String base64Body,
    String saltKey,
    String saltIndex,
  ) {
    final checksumString = '$base64Body/pg/v1/pay$saltKey';
    final bytes = utf8.encode(checksumString);
    final digest = sha256.convert(bytes);
    final checksum = '$digest###$saltIndex';

    log('Checksum String (for verification): ${checksumString.substring(0, 50)}...');
    log('Generated Checksum: $checksum');

    return checksum;
  }

  /// Create SDK request JSON according to official PhonePe documentation
  ///
  /// Sample Request Payload:
  /// {
  ///   "orderId": "merchant_order_id",
  ///   "merchantId": "your_merchant_id",
  ///   "token": "token_from_backend",
  ///   "paymentMode": {"type": "PAY_PAGE"}
  /// }
  ///
  /// IMPORTANT: The 'token' MUST come from your backend server!
  ///
  /// Your backend must:
  /// 1. Call PhonePe's Payment Gateway API: POST /pg/v1/pay
  /// 2. Receive response with instrumentResponse.redirectInfo.url
  /// 3. Extract the 'token' parameter from that URL
  /// 4. Return it to this Flutter app along with the orderId
  ///
  /// Parameters:
  /// - orderId: Your backend's unique order/transaction ID
  /// - merchantId: Your PhonePe merchant ID
  /// - token: Session token received from PhonePe API (via backend)
  static String createSDKRequest({
    required String orderId,
    required String merchantId,
    required String token,
  }) {
    final Map<String, dynamic> payload = {
      'orderId': orderId,
      'merchantId': merchantId,
      'token': token,
      'paymentMode': {'type': 'PG'},
      "paymentInstrument": {
        "type": "UPI_INTENT",
        "targetApp": "com.phonepe.app" // Ensure this is a valid package name
      },
      'targetAppPackageName': 'com.phonepe.app',
      'packageName': 'com.phonepe.app',
    };

    final String request = json.encode(payload);
    log('Payment Request: $request');
    return request;
  }

  /// Create complete PhonePe transaction (Payment Gateway API - requires backend)
  ///
  /// NOTE: This method creates the payload for Payment Gateway API (/pg/v1/pay)
  /// which must be called from your BACKEND server, not from this Flutter app!
  ///
  /// The SDK v3.0.2 does NOT use this format directly. Instead:
  /// 1. Your backend uses this to call /pg/v1/pay API
  /// 2. Backend receives token from PhonePe
  /// 3. Backend sends token + orderId to Flutter app
  /// 4. Flutter app uses createSDKRequest() to format it for the SDK
  static Map<String, String> createCompleteTransaction({
    required String userId,
    required int amountInRupees,
    required String mobileNumber,
    String? merchantId,
    String? saltKey,
    String? saltIndex,
  }) {
    try {
      // Use test credentials if not provided
      final _merchantId = merchantId ?? testMerchantId;
      final _saltKey = saltKey ?? testSaltKey;
      final _saltIndex = saltIndex ?? testSaltIndex;

      // Generate unique transaction ID
      final transactionId = generateTransactionId(userId);

      // Convert amount to paise (1 rupee = 100 paise)
      final amountInPaise = amountInRupees * 100;

      log('Creating transaction:');
      log('- Merchant ID: $_merchantId');
      log('- Transaction ID: $transactionId');
      log('- Amount: ₹$amountInRupees ($amountInPaise paise)');
      log('- Mobile: $mobileNumber');

      // Create transaction payload
      final payload = createTransactionPayload(
        merchantId: _merchantId,
        merchantTransactionId: transactionId,
        userId: userId,
        amountInPaise: amountInPaise,
        mobileNumber: mobileNumber,
      );

      // Convert payload to JSON string
      final jsonPayload = json.encode(payload);
      log('Payload JSON: $jsonPayload');

      // Encode to base64
      final base64Body = base64.encode(utf8.encode(jsonPayload));
      log('Base64 Body (first 100 chars): ${base64Body.substring(0, base64Body.length > 100 ? 100 : base64Body.length)}...');

      // Generate checksum
      final checksum = generateChecksum(base64Body, _saltKey, _saltIndex);

      return {
        'body': base64Body,
        'checksum': checksum,
        'transactionId': transactionId,
        'merchantId': _merchantId,
      };
    } catch (e) {
      log('Error creating transaction: $e');
      rethrow;
    }
  }

  /// Check transaction status
  /// This should typically be done via backend API call
  static Future<Map<String, dynamic>> checkTransactionStatus({
    required String merchantId,
    required String transactionId,
  }) async {
    // This should be implemented via backend API call
    // PhonePe provides status check API endpoint
    log('Checking transaction status for: $transactionId');

    // TODO: Implement backend API call to check status
    return {
      'status': 'PENDING',
      'message': 'Status check not implemented',
    };
  }
}
