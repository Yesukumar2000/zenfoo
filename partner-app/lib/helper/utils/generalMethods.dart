import 'dart:core';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project/helper/generalWidgets/messageContainer.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/helper/widgets/image_picker_bottom_sheet.dart';
import 'package:dio/dio.dart' as dio;

enum MessageType { success, error, warning }

Map<MessageType, Color> messageColors = {
  MessageType.success: ColorsRes.appColorGreen,
  MessageType.error: ColorsRes.appColorRed,
  MessageType.warning: ColorsRes.appColorOrange
};

Map<MessageType, Widget> messageIcon = {
  MessageType.success:
      defaultImg(image: AppAssets.doneIcon, iconColor: ColorsRes.appColorGreen),
  MessageType.error:
      defaultImg(image: AppAssets.errorIcon, iconColor: ColorsRes.appColorRed),
  MessageType.warning: defaultImg(
      image: AppAssets.warningIcon, iconColor: ColorsRes.appColorOrange),
};

// ============= COMPREHENSIVE API LOGGING HELPER =============

class ApiLog {
  final String method;
  final String url;
  final Map<String, String> headers;
  final Map<String, dynamic> params;
  final int? statusCode;
  final String? response;
  final bool isError;
  final String? errorMessage;
  final DateTime timestamp;

  ApiLog({
    required this.method,
    required this.url,
    required this.headers,
    required this.params,
    this.statusCode,
    this.response,
    this.isError = false,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Log complete API transaction in one place
  void logComplete() {
    if (kDebugMode) {
      print('\n');
      print(
          '╔════════════════════════════════════════════════════════════════════');
      print('║ 🔗 API TRANSACTION - ${isError ? "❌ FAILED" : "✅ SUCCESS"}');
      print(
          '╠════════════════════════════════════════════════════════════════════');
      print('║ TIMESTAMP: ${timestamp.toString()}');
      print('║ METHOD: $method');
      print('║ URL: $url');
      print(
          '╠════════════════════════════════════════════════════════════════════');
      print('║ HEADERS:');
      headers.forEach((key, value) {
        print('║   $key: $value');
      });
      print(
          '╠════════════════════════════════════════════════════════════════════');
      print('║ REQUEST PARAMS:');
      if (params.isEmpty) {
        print('║   (empty)');
      } else {
        params.forEach((key, value) {
          print('║   $key: $value');
        });
      }
      print(
          '╠════════════════════════════════════════════════════════════════════');

      // Full URL with params (url already contains params for GET)
      if (params.isNotEmpty && method == 'GET') {
        print('║ FULL URL:');
        print('║   $url');
        print(
            '╠════════════════════════════════════════════════════════════════════');
      }

      // Response section
      if (statusCode != null) {
        print('║ RESPONSE:');
        print('║ Status Code: $statusCode');
        print('║ Status: ${isError ? "ERROR" : "SUCCESS"}');

        if (response != null && response!.isNotEmpty) {
          print(
              '╠════════════════════════════════════════════════════════════════════');
          print('║ RESPONSE BODY:');

          // Pretty print JSON if possible
          try {
            final decoded = json.decode(response!);
            final prettyJson = JsonEncoder.withIndent('  ').convert(decoded);
            prettyJson.split('\n').forEach((line) {
              print('║   $line');
            });
          } catch (e) {
            // If not JSON, print as-is
            response!.split('\n').forEach((line) {
              print('║   $line');
            });
          }
        }
      }

      if (errorMessage != null && errorMessage!.isNotEmpty) {
        print(
            '╠════════════════════════════════════════════════════════════════════');
        print('║ ERROR MESSAGE:');
        print('║   $errorMessage');
      }

      print(
          '╚════════════════════════════════════════════════════════════════════\n');
    }
  }
}


// ============= EXISTING FUNCTIONS =============

Future<bool> checkInternet() async {
  bool check = false;

  var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult[0] == ConnectivityResult.mobile ||
      connectivityResult[0] == ConnectivityResult.wifi ||
      connectivityResult[0] == ConnectivityResult.ethernet) {
    check = true;
  }
  return check;
}

NetworkStatus getNetworkStatus(ConnectivityResult status) {
  return status == ConnectivityResult.mobile ||
          status == ConnectivityResult.wifi ||
          status == ConnectivityResult.ethernet
      ? NetworkStatus.Online
      : NetworkStatus.Offline;
}

showMessage(
  BuildContext context,
  String msg,
  MessageType type,
) async {
  FocusScope.of(context).unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  OverlayState? overlayState = Overlay.of(context);
  OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        left: 5,
        right: 5,
        bottom: 15,
        child: MessageContainer(
          context: context,
          text: msg,
          type: type,
        ),
      );
    },
  );
  overlayState.insert(overlayEntry);
  await Future.delayed(
    Duration(
      milliseconds: Constant.messageDisplayDuration,
    ),
  );

  overlayEntry.remove();
}

Locale getLocaleFromLangCode(String languageCode) {
  List<String> result = languageCode.split("-");
  return result.length == 1
      ? Locale(result.first)
      : Locale(result.first, result.last);
}

String setFirstLetterUppercase(String value) {
  if (value.isNotEmpty) value = value.replaceAll("_", ' ');
  return value.toTitleCase();
}

Future sendApiRequest({
  required String apiName,
  required Map<String, dynamic> params,
  required bool isPost,
  bool isDelete = false, // NEW: Add DELETE flag
  bool? isRequestedForInvoice,
  bool? privacyAndTerms = false,
}) async {
  try {
    String token = Constant.session.getData(SessionManager.keyAccessToken);
    String baseUrl = "${Constant.hostUrl}api/seller/";

    if (privacyAndTerms!) {
      baseUrl = "${Constant.hostUrl}api/";
    }

    Map<String, String> headersData = {};

    if (token.trim().isNotEmpty) {
      headersData["Authorization"] = "Bearer $token";
    }

    headersData["x-access-key"] = "903361";

    String mainUrl = apiName.contains("http") ? apiName : "${baseUrl}$apiName";

    // Determine the HTTP method
    String method = isDelete ? 'DELETE' : (isPost ? 'POST' : 'GET');

    http.Response response;

    if (isDelete) {
      // DELETE request - can include body if needed
      response = await http.delete(
        Uri.parse(mainUrl),
        body: params.isNotEmpty ? params : null,
        headers: headersData,
      );
    } else if (isPost) {
      // POST request
      response = await http.post(
        Uri.parse(mainUrl),
        body: params.isNotEmpty ? params : null,
        headers: headersData,
      );
    } else {
      // GET request
      mainUrl = await Constant.getGetMethodUrlWithParams(
        apiName.contains("http") ? apiName : "${baseUrl}$apiName",
        params,
      );

      response = await http.get(Uri.parse(mainUrl), headers: headersData);
    }

    // Log the complete API transaction (request + response) in one place
    if (response.statusCode == 200) {
      if (response.body == "null") {
        ApiLog(
          method: method,
          url: mainUrl,
          headers: headersData,
          params: params,
          statusCode: response.statusCode,
          response: 'null response body',
          isError: false,
        ).logComplete();
        return null;
      }

      ApiLog(
        method: method,
        url: mainUrl,
        headers: headersData,
        params: params,
        statusCode: response.statusCode,
        response: response.body,
        isError: false,
      ).logComplete();

      return isRequestedForInvoice == true ? response.bodyBytes : response.body;
    } else {
      ApiLog(
        method: method,
        url: mainUrl,
        headers: headersData,
        params: params,
        statusCode: response.statusCode,
        response: response.body,
        isError: true,
        errorMessage: 'HTTP ${response.statusCode}',
      ).logComplete();

      if (response.statusCode == 401) {
        Constant.session.processToLogout(Constant.navigatorKay.currentContext!);
      }

      // Return response body for non-200 status codes so error message can be extracted
      // Only return null if body is empty or invalid
      if (response.body.isNotEmpty && response.body != "null") {
        return response.body;
      }
      return null;
    }
  } on SocketException {
    // Log socket exception
    ApiLog(
      method: isPost ? 'POST' : 'GET',
      url: apiName.contains("http") ? apiName : "${Constant.hostUrl}api/seller/$apiName",
      headers: {'x-access-key': '903361'},
      params: params,
      isError: true,
      errorMessage: 'SocketException: No Internet Connection',
    ).logComplete();

    await Future.delayed(const Duration(milliseconds: 1800));
    throw SocketException('No Internet Connection');
  } catch (e) {
    // Log general exception
    ApiLog(
      method: isPost ? 'POST' : 'GET',
      url: apiName.contains("http") ? apiName : "${Constant.hostUrl}api/seller/$apiName",
      headers: {'x-access-key': '903361'},
      params: params,
      isError: true,
      errorMessage: 'Exception: ${e.toString()}',
    ).logComplete();
    return e.toString();
  }
}

Future sendApiMultiPartRequest({
  required String apiName,
  required Map<String, dynamic> params,
  required Map<String, File> filesMap,
  List<MapEntry<String, File>>? filesList,
}) async {
  // Declare headers outside try block so they can be accessed in catch blocks
  String token = Constant.session.getData(SessionManager.keyAccessToken);
  // Always use seller base URL for multipart requests (like bulk upload)
  String baseUrl = "${Constant.hostUrl}api/seller/";
  String mainUrl = apiName.contains("http") ? apiName : "$baseUrl$apiName";

  // Debug print URL
  if (kDebugMode) {
    print('╔════════════════════════════════════════════════════════════════════');
    print('║ MULTIPART REQUEST URL DEBUG');
    print('║ Host URL: ${Constant.hostUrl}');
    print('║ API Name: $apiName');
    print('║ Base URL: $baseUrl');
    print('║ Final URL: $mainUrl');
    print('║ Is Seller: ${Constant.session.isSeller()}');
    print('╚════════════════════════════════════════════════════════════════════');
  }

  // Headers - same as sendApiRequest
  Map<String, String> headersData = {};

  if (token.trim().isNotEmpty) {
    headersData["Authorization"] = "Bearer $token";
  }

  headersData["x-access-key"] = "903361";

  try {
    dio.Dio dioClient = dio.Dio();

    // Form Data
    dio.FormData formData = dio.FormData.fromMap(params);

    // Add files from map (single file per key)
    if (filesMap.isNotEmpty) {
      List<String> keys = filesMap.keys.toList();
      List<File> files = filesMap.values.toList();

      for (int i = 0; i < files.length; i++) {
        final mimeType =
            lookupMimeType(files[i].path) ?? 'application/octet-stream';
        var extension = mimeType.split("/");

        formData.files.add(
          MapEntry(
            keys[i],
            await dio.MultipartFile.fromFile(
              files[i].path,
              filename: files[i].path.split('/').last,
              contentType: MediaType(extension[0], extension[1]),
            ),
          ),
        );
      }
    }

    // Add files from list (supports multiple files per key)
    if (filesList != null && filesList.isNotEmpty) {
      debugPrint('=== Adding ${filesList.length} files from filesList ===');
      for (final entry in filesList) {
        debugPrint('filesList entry: key=${entry.key}, path=${entry.value.path}');
        final mimeType =
            lookupMimeType(entry.value.path) ?? 'application/octet-stream';
        var extension = mimeType.split("/");

        formData.files.add(
          MapEntry(
            entry.key,
            await dio.MultipartFile.fromFile(
              entry.value.path,
              filename: entry.value.path.split('/').last,
              contentType: MediaType(extension[0], extension[1]),
            ),
          ),
        );
      }
    }

    debugPrint('=== Total formData files: ${formData.files.length} ===');

    // Send Request with headers in options
    dio.Response response = await dioClient.post(
      mainUrl,
      data: formData,
      options: dio.Options(
        contentType: 'multipart/form-data',
        headers: headersData,
        responseType: dio.ResponseType.json,
      ),
    );

    // Debug print response
    if (kDebugMode) {
      print('╔════════════════════════════════════════════════════════════════════');
      print('║ MULTIPART RESPONSE DEBUG');
      print('║ Status Code: ${response.statusCode}');
      print('║ Response Type: ${response.data.runtimeType}');
      print('║ Response Data: ${response.data}');
      print('╚════════════════════════════════════════════════════════════════════');
    }

    // Log the complete API transaction (request + response) in one place
    if (response.statusCode == 200) {
      ApiLog(
        method: 'POST',
        url: mainUrl,
        headers: headersData,
        params: params,
        statusCode: response.statusCode!,
        response: response.data != null ? json.encode(response.data) : 'null',
        isError: false,
      ).logComplete();
      return response.data;
    } else {
      ApiLog(
        method: 'POST',
        url: mainUrl,
        headers: headersData,
        params: params,
        statusCode: response.statusCode!,
        response: response.data != null ? json.encode(response.data) : 'null',
        isError: true,
        errorMessage: 'HTTP ${response.statusCode}',
      ).logComplete();
      return null;
    }
  } on dio.DioException catch (e) {
    // Log Dio exception with actual headers
    ApiLog(
      method: 'POST',
      url: mainUrl,
      headers: headersData,
      params: params,
      isError: true,
      errorMessage: 'DioException: ${e.message} (Status: ${e.response?.statusCode})',
    ).logComplete();

    // Return the response data if available (for validation errors etc.)
    if (e.response?.data != null) {
      return e.response!.data;
    }
    return null;
  } on SocketException {
    // Log socket exception with actual headers
    ApiLog(
      method: 'POST',
      url: mainUrl,
      headers: headersData,
      params: params,
      isError: true,
      errorMessage: 'SocketException: No Internet Connection',
    ).logComplete();

    await Future.delayed(const Duration(milliseconds: 1800));
    throw SocketException('No Internet Connection');
  } catch (e) {
    // Log general exception with actual headers
    ApiLog(
      method: 'POST',
      url: mainUrl,
      headers: headersData,
      params: params,
      isError: true,
      errorMessage: 'Exception: ${e.toString()}',
    ).logComplete();
    rethrow;
  }
}

// ============= REST OF YOUR EXISTING CODE =============
// (Keep all validation functions, extensions, etc. as they are)

String? validateEmail(String value) {
  String pattern =
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
  RegExp regex = RegExp(pattern);
  if (value.isEmpty || !regex.hasMatch(value))
    return 'Enter a valid email address';
  else
    return null;
}

emailValidation(String val, String msg) {
  return validateEmail(
    val.trim(),
  );
}

percentageValidation(String val, String msg) {
  if (val.isNotEmpty) {
    double percentage = val.toDouble!;
    if (percentage > 100 || percentage < 0) {
      return "Commission should be greater then 0% and less then 100%!";
    } else {
      return null;
    }
  } else {
    return "Commission should not be empty!";
  }
}

emptyValidation(String val, String msg) {
  if (val.trim().isEmpty) {
    return msg;
  }
  return null;
}

optionalFieldValidation(String val, String msg) {
  return null;
}

String? passwordValidation(String? value, String errorMessage) {
  if (value == null || value.trim().isEmpty) {
    return enterPasswordLabel;
  } else if (value.trim().length < 6) {
    return passwordMinLengthLabel;
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return enterConfirmPasswordLabel;
  }
  if (value != password) {
    return passwordConfirmMismatchLabel;
  }
  return null;
}

getUserLocation() async {
  LocationPermission permission;

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openLocationSettings();

    getUserLocation();
  } else if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      await Geolocator.openLocationSettings();
      getUserLocation();
    } else {
      getUserLocation();
    }
  }
}

Future<Position> determinePosition() async {
  LocationPermission permission;
  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  } else if (permission == LocationPermission.deniedForever) {
    return Future.error('Location Not Available');
  }

  return await Geolocator.getCurrentPosition();
}

Future getFileFromDevice() async {
  String path = "";
  await FilePicker.platform
      .pickFiles(
          allowMultiple: false,
          allowCompression: true,
          type: FileType.custom,
          allowedExtensions: ["jpg", "jpeg", "png"],
          lockParentWindow: true)
      .then((value) {
    path = value!.paths.first.toString();
  });
  return path;
}

phoneValidation(String value, String msg) {
  String pattern = r'[0-9]';
  RegExp regExp = RegExp(pattern);
  if (value.isEmpty ||
      !regExp.hasMatch(value) ||
      value.trim().length >= 16 ||
      value.trim().length < Constant.minimumRequiredMobileNumberLength) {
    return msg;
  }
  return null;
}

String getCurrencyFormat(double amount) {
  return NumberFormat.currency(
          symbol: Constant.currency,
          decimalDigits: int.tryParse(Constant.currencyDecimalPoint) ?? 2,
          name: Constant.currencyCode)
      .format(amount);
}

maskSensitiveInformation(text) {}

String getTranslatedValue(BuildContext context, String key) {
  return context.read<LanguageProvider>().currentLanguage[key] ??
      context.read<LanguageProvider>().currentLocalOfflineLanguage[key] ??
      key;
}

Future<bool> hasStoragePermissionGiven() async {
  if (Platform.isIOS) {
    bool permissionGiven = await Permission.storage.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.storage.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  }
  final deviceInfoPlugin = DeviceInfoPlugin();
  final androidDeviceInfo = await deviceInfoPlugin.androidInfo;
  if (androidDeviceInfo.version.sdkInt < 33) {
    bool permissionGiven = await Permission.storage.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.storage.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  } else {
    return true;
  }
}

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map(
        (str) => str.toCapitalized(),
      )
      .join(' ');
}

extension ContextExtension on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;

  double get height => MediaQuery.sizeOf(this).height;
}

extension StringParsing on String {
  double? get toDouble => double.tryParse(this) ?? 0.0;

  double? get toInt => double.tryParse(this) ?? 0;

  int get toStringToInt => int.tryParse(this) ?? 0;

  String get currency => NumberFormat.currency(
          symbol: Constant.currency,
          decimalDigits:
              int.tryParse(Constant.currencyDecimalPoint.toString()) ?? 2,
          name: Constant.currencyCode)
      .format(this.toDouble);
}

extension StringToDateTimeFormatting on String {
  DateTime toDate({String format = 'd MMM y, hh:mm a'}) {
    try {
      return DateTime.parse(this).toLocal();
    } catch (e) {
      print('Error parsing date: $e');
      return DateTime.now();
    }
  }

  String formatDate(
      {String inputFormat = 'yyyy-MM-dd',
      String outputFormat = 'd MMM y, hh:mm a'}) {
    try {
      DateTime dateTime = toDate(format: inputFormat);
      return DateFormat(outputFormat).format(dateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return this;
    }
  }
}

class CustomNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else if (RegExp(r'^[0-9]*$').hasMatch(newValue.text)) {
      if (newValue.text == '0') {
        return newValue;
      } else if (newValue.text.length > 1 &&
          newValue.text.startsWith('0') &&
          newValue.text[1] == '0') {
        return oldValue;
      } else {
        return newValue;
      }
    } else {
      return oldValue;
    }
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({required this.decimalRange})
      : assert(decimalRange > 0);

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;

    String value = newValue.text;

    if (value.contains(".") &&
        value.substring(value.indexOf(".") + 1).length > decimalRange) {
      truncated = oldValue.text;
      newSelection = oldValue.selection;
    } else if (value == ".") {
      truncated = "0.";

      newSelection = newValue.selection.copyWith(
        baseOffset: math.min(truncated.length, truncated.length + 1),
        extentOffset: math.min(truncated.length, truncated.length + 1),
      );
    }

    return TextEditingValue(
      text: truncated,
      selection: newSelection,
      composing: TextRange.empty,
    );
  }
}

extension ValidateNullString on String {
  String checkNullString() => (this == "null" ? "" : this).toString();
}

Future<File?> saveFileToLocalStorage(File file) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = file.path.split('/').last;
    final newPath = '${directory.path}/$fileName';
    return await file.copy(newPath);
  } catch (e) {
    debugPrint("Save error: $e");
    return null;
  }
}

/// Safely parses boolean values from API responses
/// Handles: true, false, 1, 0, "1", "0", "true", "false"
/// Returns false for null or invalid values
bool safeParseBool(dynamic value) {
  if (value == null) return false;

  // Handle actual boolean
  if (value is bool) return value;

  // Handle integer
  if (value is int) return value == 1;

  // Handle string
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }

  return false;
}

String safeParseString(dynamic value) {
  if (value == null) return "";

  // Handle actual string
  if (value is String) return value;

  // Handle integer
  if (value is int) return value.toString();

  // Handle double
  if (value is double) return value.toString();

  return "";
}

/// Standardize API response to a consistent format
/// Handles different field names like 'success', 'status', 'code', etc.
Map<String, dynamic> standardizeApiResponse(
    Map<String, dynamic> response) {
  // Extract success/status value from various field names
  var successValue;
  final responseMap = Map<String, dynamic>.from(response);

  // Try different field names for success/status
  if (responseMap.containsKey('success')) {
    successValue = responseMap['success'];
  } else if (responseMap.containsKey('status')) {
    successValue = responseMap['status'];
  } else if (responseMap.containsKey('code')) {
    successValue = responseMap['code'];
  } else if (responseMap.containsKey('statusCode')) {
    successValue = responseMap['statusCode'];
  }

  // Standardize to 'success' field
  if (successValue != null) {
    responseMap['success'] = successValue;
    // Remove other success-related fields to avoid confusion
    responseMap.remove('status');
    responseMap.remove('code');
    responseMap.remove('statusCode');
  }

  // Get message from various field names
  String message = '';
  if (responseMap.containsKey('message')) {
    message = responseMap['message']?.toString() ?? '';
  } else if (responseMap.containsKey('msg')) {
    message = responseMap['msg']?.toString() ?? '';
  } else if (responseMap.containsKey('error')) {
    message = responseMap['error']?.toString() ?? '';
  } else if (responseMap.containsKey('errorMessage')) {
    message = responseMap['errorMessage']?.toString() ?? '';
  }

  if (message.isNotEmpty) {
    responseMap['message'] = message;
  }

  return responseMap;
}

/// Open image picker bottom sheet and return selected files
/// Usage:
/// ```dart
/// final files = await pickImagesWithBottomSheet(
///   context,
///   allowMultiple: true,
///   title: 'Select Images'
/// );
/// ```
Future<List<File>> pickImagesWithBottomSheet(
  BuildContext context, {
  bool allowMultiple = false,
  String? title,
}) async {
  List<File>? selectedFiles;

  // ignore: use_build_context_synchronously
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) {
      return _buildImagePickerBottomSheet(
        context: context,
        allowMultiple: allowMultiple,
        title: title,
        onImagesPicked: (files) {
          selectedFiles = files;
        },
      );
    },
  );

  return selectedFiles ?? [];
}

Widget _buildImagePickerBottomSheet({
  required BuildContext context,
  required bool allowMultiple,
  String? title,
  required Function(List<File>) onImagesPicked,
}) {
  return ImagePickerBottomSheet(
    allowMultiple: allowMultiple,
    onImagesPicked: onImagesPicked,
    title: title,
  );
}
