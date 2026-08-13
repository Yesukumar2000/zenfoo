import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:zenfoo_partner/router/app_router.dart';
import 'package:zenfoo_partner/router/app_router_name.dart';
import 'package:zenfoo_partner/services/local_storage.dart';
import 'package:zenfoo_partner/utils/app_colors.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';
import 'package:zenfoo_partner/utils/globle_func.dart';
import 'status.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        validateStatus: (status) {
          // Accept all status codes to handle them manually
          return status != null && status < 500;
        },
        headers: {
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    _setupInterceptors();
  }

  /// Setup all interceptors
  void _setupInterceptors() {
    // Auth interceptor - must be first
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await LocalStorage.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔐 Auth: Token added to request');
          }

          handler.next(options);
        },
      ),
    );

    // Logging interceptor
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logRequest(options);
            handler.next(options);
          },
          onResponse: (response, handler) {
            _logResponse(response);
            handler.next(response);
          },
          onError: (error, handler) {
            _logError(error);
            handler.next(error);
          },
        ),
      );
    }

    // Unauthorized checker interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          _checkUnauthorized(response.data, response.requestOptions);
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response != null) {
            _checkUnauthorized(error.response!.data, error.requestOptions);
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Check if response indicates unauthorized and logout user
  void _checkUnauthorized(dynamic data, RequestOptions options) {
    if (data == null || data is! Map<String, dynamic>) return;

    // Check if logout should be skipped for this specific request
    if (options.extra['skipLogout'] == true) {
      debugPrint('🔐 skipLogout is true - skipping unauthorized check');
      return;
    }

    try {
      // Check for various unauthorized/unauthenticated patterns
      final message = data['message']?.toString().toLowerCase() ?? '';
      final error = data['error']?.toString().toLowerCase() ?? '';
      final status = data['status'];

      final isUnauthorized =
          // Pattern 1: status 0 with unauthorized/unauthenticated message
          ((status == 0 || status == '0') &&
                  (message.contains('unauthorized') ||
                      message.contains('unauthenticated') ||
                      error.contains('unauthorized') ||
                      error.contains('unauthenticated'))) ||
              // Pattern 2: message contains unauthenticated (regardless of status)
              message.contains('unauthenticated') ||
              error.contains('unauthenticated');

      if (isUnauthorized) {
        // Skip auto-logout for critical authentication routes to prevent race conditions
        final context = navigatorKey.currentContext;
        if (context != null) {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          final criticalRoutes = [
            AppRouterName.splash,
            AppRouterName.login,
            AppRouterName.otpVerify,
          ];

          if (criticalRoutes.contains(currentRoute)) {
            debugPrint(
                '🔐 Unauthorized detected but skipping logout - currently on critical route: $currentRoute');
            return;
          }
        }

        debugPrint('🔐 Unauthorized/Unauthenticated detected - logging out');
        _handleLogout();
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Handle logout when unauthorized
  Future<void> _handleLogout() async {
    try {
      debugPrint('🔐 Starting logout process...');

      // Clear all local storage
      await LocalStorage.clearToken();
      await LocalStorage.clearUserData();
      await LocalStorage.clearDeliveryBoyData();
      await LocalStorage.clearLocalStorate();

      debugPrint('🔐 Local storage cleared');

      // Show error message
      showToastError('Session expired. Please login again.');

      // Navigate to login screen using global navigator
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        debugPrint('🔐 Navigating to login screen...');
        context.go(AppRouterName.login);
      } else {
        debugPrint('🔐 Warning: No context available for navigation');
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  /// 📋 LOG REQUEST
  void _logRequest(RequestOptions options) {
    debugPrint('');
    debugPrint(
        '╔════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ 📤 REQUEST');
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ Method: ${options.method}');
    debugPrint('║ Full URL: ${options.uri}');
    debugPrint('║ Base URL: ${options.baseUrl}');
    debugPrint('║ Path: ${options.path}');
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ 📋 HEADERS:');
    options.headers.forEach((key, value) {
      log('║   $key: $value');
    });
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');

    if (options.queryParameters.isNotEmpty) {
      debugPrint('║ 🔍 QUERY PARAMETERS:');
      options.queryParameters.forEach((key, value) {
        debugPrint('║   $key: $value');
      });
      debugPrint(
          '╠════════════════════════════════════════════════════════════════════════════════');
    }

    if (options.data != null) {
      debugPrint('║ 📦 BODY:');
      debugPrint('║   Type: ${options.data.runtimeType}');
      if (options.data is FormData) {
        debugPrint('║   FormData fields:');
        final formData = options.data as FormData;
        for (var field in formData.fields) {
          debugPrint('║     ${field.key}: ${field.value}');
        }
        if (formData.files.isNotEmpty) {
          debugPrint('║   FormData files:');
          for (var file in formData.files) {
            debugPrint('║     ${file.key}: ${file.value.filename}');
          }
        }
      } else {
        try {
          final prettyJson =
              const JsonEncoder.withIndent('  ').convert(options.data);
          prettyJson.split('\n').forEach((line) {
            debugPrint('║   $line');
          });
        } catch (e) {
          debugPrint('║   ${options.data}');
        }
      }
      debugPrint(
          '╠════════════════════════════════════════════════════════════════════════════════');
    }

    debugPrint(
        '║ ⏱️  Timeout: Connect ${options.connectTimeout}, Receive ${options.receiveTimeout}');
    debugPrint(
        '╚════════════════════════════════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// 📋 LOG RESPONSE
  void _logResponse(Response response) {
    debugPrint('');
    debugPrint(
        '╔════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ 📥 RESPONSE');
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ Status Code: ${response.statusCode}');
    debugPrint('║ Status Message: ${response.statusMessage}');
    debugPrint('║ URL: ${response.requestOptions.uri}');
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ 📋 RESPONSE HEADERS:');
    response.headers.map.forEach((key, value) {
      debugPrint('║   $key: ${value.join(', ')}');
    });
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ 📦 RESPONSE DATA:');
    debugPrint('║   Type: ${response.data.runtimeType}');
    try {
      if (response.data is String) {
        final dataStr = response.data.toString();
        if (dataStr.startsWith('<!DOCTYPE') || dataStr.startsWith('<html')) {
          debugPrint(
              '║   ❌ [HTML Response - ${dataStr.length} chars - Service temporarily unavailable]');
        } else {
          debugPrint('║   $dataStr');
        }
      } else {
        final prettyJson =
            const JsonEncoder.withIndent('  ').convert(response.data);
        prettyJson.split('\n').forEach((line) {
          debugPrint('║   $line');
        });
      }
    } catch (e) {
      debugPrint('║   ${response.data}');
    }
    debugPrint(
        '╚════════════════════════════════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// 📋 LOG ERROR
  void _logError(DioException error) {
    debugPrint('');
    debugPrint(
        '╔════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ ❌ ERROR');
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ Type: ${error.type}');
    debugPrint('║ Message: ${error.message}');
    debugPrint('║ Error Object: ${error.error}');
    debugPrint('║ Error Object Type: ${error.error?.runtimeType}');
    debugPrint('║ URL: ${error.requestOptions.uri}');
    debugPrint('║ Method: ${error.requestOptions.method}');
    debugPrint(
        '╠════════════════════════════════════════════════════════════════════════════════');

    if (error.response != null) {
      debugPrint('║ 📥 ERROR RESPONSE:');
      debugPrint('║   Status Code: ${error.response?.statusCode}');
      debugPrint('║   Status Message: ${error.response?.statusMessage}');
      debugPrint(
          '╠════════════════════════════════════════════════════════════════════════════════');
      debugPrint('║ 📋 ERROR RESPONSE HEADERS:');
      error.response?.headers.map.forEach((key, value) {
        debugPrint('║   $key: ${value.join(', ')}');
      });
      debugPrint(
          '╠════════════════════════════════════════════════════════════════════════════════');
      debugPrint('║ 📦 ERROR RESPONSE DATA:');
      debugPrint('║   Type: ${error.response?.data.runtimeType}');
      try {
        if (error.response?.data is String) {
          final dataStr = error.response!.data.toString();
          if (dataStr.startsWith('<!DOCTYPE') || dataStr.startsWith('<html')) {
            debugPrint(
                '║   ❌ [HTML Response - ${dataStr.length} chars - Service temporarily unavailable]');
          } else {
            debugPrint('║   $dataStr');
          }
        } else {
          final prettyJson =
              const JsonEncoder.withIndent('  ').convert(error.response?.data);
          prettyJson.split('\n').forEach((line) {
            debugPrint('║   $line');
          });
        }
      } catch (e) {
        debugPrint('║   ${error.response?.data}');
      }
      debugPrint(
          '╠════════════════════════════════════════════════════════════════════════════════');
    }

    // Show stack trace for unknown errors
    if (error.type == DioExceptionType.unknown) {
      debugPrint('║ 📚 STACK TRACE (first 10 lines):');
      error.stackTrace.toString().split('\n').take(10).forEach((line) {
        if (line.trim().isNotEmpty) {
          debugPrint('║   $line');
        }
      });
      debugPrint(
          '╠════════════════════════════════════════════════════════════════════════════════');
    }

    debugPrint(
        '╚════════════════════════════════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// 🔹 GET REQUEST
  Future<ApiResponse> get(
    String url, {
    Map<String, dynamic>? params,
    bool isToast = true,
    bool isSuccessToast =
        false, // Changed to false - don't show success toasts by default
    bool isErrorToast = true,
    bool skipLogout = false,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: params,
        options: Options(
          extra: {'skipLogout': skipLogout},
        ),
      );

      // Check if response is HTML (403 forbidden page)
      if (response.data is String &&
          (response.data.toString().contains('<!DOCTYPE') ||
              response.data.toString().contains('<html'))) {
        debugPrint(
            '❌ Received HTML instead of JSON - likely blocked by hosting provider');

        if (isToast && isErrorToast) {
          showToastError('Service temporarily unavailable. Please try again.');
        }

        return ApiResponse.error('Service temporarily unavailable');
      }

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isToast && isSuccessToast && response.data is Map) {
          showToastSuccess(response.data);
        }
        return ApiResponse.success(response.data);
      }

      // Handle error status codes
      final errorMessage = _extractErrorMessage(response.data);
      if (isToast && isErrorToast) {
        showToastError(errorMessage);
      }
      return ApiResponse.error(errorMessage);
    } on DioException catch (e) {
      final errorMessage = _handleDioError(e);

      if (isToast && isErrorToast) {
        showToastError(errorMessage);
      }

      return ApiResponse.error(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (isToast && isErrorToast) {
        showToastError('Something went wrong');
      }

      return ApiResponse.error('Something went wrong');
    }
  }

  /// 🔹 POST REQUEST
  Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? data,
    Map<String, File>? files,
    List<MapEntry<String, File>>? multiFiles, // Multiple files with same key (e.g. images[])
    bool isToast = true,
    bool isSuccessToast =
        false, // Changed to false - don't show success toasts by default
    bool isErrorToast = true,
    bool skipLogout = false,
    bool useFormData = false, // Force form-data encoding even without files
  }) async {
    try {
      dynamic requestData;
      Options? requestOptions;

      final hasFiles = (files != null && files.isNotEmpty) ||
          (multiFiles != null && multiFiles.isNotEmpty);

      // Handle file uploads or forced form-data
      if (hasFiles) {
        final formData = FormData.fromMap(data ?? {});

        // Single-key files (one file per key)
        if (files != null) {
          for (var entry in files.entries) {
            final file = entry.value;
            final fileName = file.path.split('/').last;

            formData.files.add(
              MapEntry(
                entry.key,
                await MultipartFile.fromFile(
                  file.path,
                  filename: fileName,
                ),
              ),
            );
          }
        }

        // Multi-key files (multiple files sharing the same key, e.g. images[])
        if (multiFiles != null) {
          for (var entry in multiFiles) {
            final file = entry.value;
            final fileName = file.path.split('/').last;

            formData.files.add(
              MapEntry(
                entry.key,
                await MultipartFile.fromFile(
                  file.path,
                  filename: fileName,
                ),
              ),
            );
          }
        }

        requestData = formData;
        // FormData sets its own content-type

        // Increase timeout for file uploads (images can take longer to upload)
        requestOptions = Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        );
      } else if (useFormData) {
        // Use form-data encoding without files (for APIs that expect multipart)
        requestData = FormData.fromMap(data ?? {});
        requestOptions = Options();
      } else {
        // Regular JSON request
        requestData = data;
        requestOptions = Options(
          headers: {'Content-Type': 'application/json'},
        );
      }

      final response = await _dio.post(
        url,
        data: requestData,
        options: requestOptions.copyWith(
          extra: {'skipLogout': skipLogout},
        ),
      );

      // Check if response is HTML (403 forbidden page)
      if (response.data is String &&
          (response.data.toString().contains('<!DOCTYPE') ||
              response.data.toString().contains('<html'))) {
        debugPrint(
            '❌ Received HTML instead of JSON - likely blocked by hosting provider');

        if (isToast && isErrorToast) {
          showToastError('Service temporarily unavailable. Please try again.');
        }

        return ApiResponse.error('Service temporarily unavailable');
      }

      // Handle response based on status code and data
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if the response data indicates success
        if (response.data is Map && _isSuccessResponse(response.data)) {
          if (isToast && isSuccessToast) {
            showToastSuccess(response.data);
          }
          return ApiResponse.success(response.data);
        }

        // Response code is 200 but data indicates failure
        final errorMessage = _extractErrorMessage(response.data);
        if (isToast && isErrorToast) {
          showToastError(errorMessage);
        }
        return ApiResponse.error(errorMessage);
      }

      // Handle error status codes
      final errorMessage = _extractErrorMessage(response.data);
      if (isToast && isErrorToast) {
        showToastError(errorMessage);
      }
      return ApiResponse.error(errorMessage);
    } on DioException catch (e) {
      final errorMessage = _handleDioError(e);

      if (isToast && isErrorToast) {
        showToastError(errorMessage);
      }

      return ApiResponse.error(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (isToast && isErrorToast) {
        showToastError('Failed to process request');
      }

      return ApiResponse.error('Failed to process request');
    }
  }

  /// PUT request
  Future<ApiResponse> put(
    String url, {
    Map<String, dynamic>? data,
    bool isToast = true,
    bool isSuccessToast = false,
    bool isErrorToast = true,
  }) async {
    try {
      debugPrint('🔄 PUT Request to: $url');
      if (data != null) {
        debugPrint('📦 Request data: $data');
      }

      final response = await _dio.put(
        url,
        data: data,
      );

      debugPrint('✅ PUT Response: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      // Check for HTML response (403 forbidden page)
      if (response.data is String &&
          response.data.contains('<!DOCTYPE html>')) {
        debugPrint(
            '⚠️ Received HTML response instead of JSON (likely 403 forbidden)');

        if (isToast && isErrorToast) {
          showToastError('Access forbidden. Please contact support.');
        }

        return ApiResponse.error('Access forbidden');
      }

      final responseData = response.data;

      // Check if response indicates success
      if (_isSuccessResponse(responseData)) {
        if (isToast && isSuccessToast) {
          showToastSuccess(responseData);
        }
        return ApiResponse.success(responseData);
      } else {
        // Response indicates failure
        final errorMessage = _extractErrorMessage(responseData);
        debugPrint('❌ API Error: $errorMessage');

        if (isToast && isErrorToast) {
          showToastError(errorMessage);
        }

        return ApiResponse.error(errorMessage);
      }
    } on DioException catch (e, stackTrace) {
      debugPrint('❌ DioException in PUT request: ${e.type}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Stack trace: $stackTrace');

      final errorMessage = _handleDioError(e);

      if (isToast && isErrorToast) {
        showToastError(errorMessage);
      }

      return ApiResponse.error(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (isToast && isErrorToast) {
        showToastError('Failed to process request');
      }

      return ApiResponse.error('Failed to process request');
    }
  }

  /// DELETE request
  Future<ApiResponse> delete(
    String url, {
    Map<String, dynamic>? params,
    bool isToast = true,
    bool isSuccessToast = false,
    bool isErrorToast = true,
  }) async {
    try {
      debugPrint('🔄 DELETE Request to: $url');
      if (params != null) {
        debugPrint('📦 Query params: $params');
      }

      final response = await _dio.delete(
        url,
        queryParameters: params,
      );

      debugPrint('✅ DELETE Response: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      // Check for HTML response (403 forbidden page)
      if (response.data is String &&
          response.data.contains('<!DOCTYPE html>')) {
        debugPrint(
            '⚠️ Received HTML response instead of JSON (likely 403 forbidden)');

        if (isToast && isErrorToast) {
          showToastError('Access forbidden. Please contact support.');
        }

        return ApiResponse.error('Access forbidden');
      }

      final responseData = response.data;

      // Check if response indicates success
      if (_isSuccessResponse(responseData)) {
        if (isToast && isSuccessToast) {
          showToastSuccess(responseData);
        }
        return ApiResponse.success(responseData);
      } else {
        // Response indicates failure
        final errorMessage = _extractErrorMessage(responseData);
        debugPrint('❌ API Error: $errorMessage');

        if (isToast && isErrorToast) {
          showToastError(errorMessage);
        }

        return ApiResponse.error(errorMessage);
      }
    } on DioException catch (e, stackTrace) {
      debugPrint('❌ DioException in DELETE request: ${e.type}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Stack trace: $stackTrace');

      final errorMessage = _handleDioError(e);

      if (isToast && isErrorToast) {
        showToastError(errorMessage);
      }

      return ApiResponse.error(errorMessage);
    } catch (e, stackTrace) {
      debugPrint('❌ Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (isToast && isErrorToast) {
        showToastError('Failed to process request');
      }

      return ApiResponse.error('Failed to process request');
    }
  }

  /// Check if response indicates success
  bool _isSuccessResponse(dynamic data) {
    if (data is! Map) return false;

    // Check for 'status' field
    if (data['status'] != null) {
      return data['status'] == true ||
          data['status'] == 1 ||
          data['status'] == '1';
    }

    // Check for legacy 'Result' and 'success' fields
    if (data['Result'] is bool && data['Result'] == true) return true;
    if (data['success'] is bool && data['success'] == true) return true;

    // If no status field, assume success for 200 responses
    return true;
  }

  /// Extract error message from response
  String _extractErrorMessage(dynamic data) {
    if (data is! Map) return 'Request failed';

    // Try different message fields
    if (data['message'] != null && data['message'].toString().isNotEmpty) {
      return data['message'].toString();
    }

    if (data['error'] != null && data['error'].toString().isNotEmpty) {
      return data['error'].toString();
    }

    if (data['errors'] != null) {
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        return data['errors'][0].toString();
      }
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          return errors.values.first.toString();
        }
      }
    }

    return 'Request failed';
  }

  /// Handle Dio errors
  String _handleDioError(DioException e) {
    // Try to extract message from response first
    if (e.response?.data is Map) {
      final message = _extractErrorMessage(e.response!.data);
      if (message != 'Request failed') {
        return message;
      }
    }

    // Fallback to error type messages
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please check your internet.';

      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond';

      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 403) {
          return 'Access forbidden. Please contact support.';
        }
        if (e.response?.statusCode == 404) {
          return 'Service not found';
        }
        if (e.response?.statusCode == 401) {
          return 'Unauthorized access';
        }
        return 'Server error occurred';

      case DioExceptionType.connectionError:
        return 'No internet connection';

      case DioExceptionType.badCertificate:
        return 'Security certificate error';

      case DioExceptionType.cancel:
        return 'Request cancelled';

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return 'No internet connection';
        }
        return 'Network error occurred';
    }
  }

  /// Show toast for success response
  void showToastSuccess(dynamic data) {
    if (data is! Map) return;

    final message = data['message']?.toString() ?? 'Success';

    showCustomToast(
      title: message,
      backgroundColor: AppColors.success,
      textColor: AppColors.white,
    );
  }

  /// Show toast for error
  void showToastError(String error) {
    showCustomToast(
      title: error,
      backgroundColor: AppColors.red,
      textColor: AppColors.white,
    );
  }

  /// ⭐ Get driver ratings
  /// Fetches driver ratings with pagination
  Future<ApiResponse> getRatings({
    int page = 1,
    int perPage = 15,
    bool isToast = false,
    bool isErrorToast = true,
  }) async {
    try {
      final response = await get(
        AppUrl.ratings,
        params: {
          'page': page,
          'per_page': perPage,
        },
        isToast: isToast,
        isErrorToast: isErrorToast,
      );

      return response;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching ratings: $e');
      debugPrint('Stack trace: $stackTrace');

      if (isToast && isErrorToast) {
        showToastError('Failed to load ratings');
      }

      return ApiResponse.error('Failed to load ratings');
    }
  }

  /// 🗑️ Delete account request
  Future<ApiResponse> deleteAccount({
    required String reason,
    bool isToast = true,
    bool isErrorToast = true,
  }) async {
    try {
      final response = await post(
        AppUrl.deleteAccount,
        data: {
          'reason': reason,
        },
        isToast: isToast,
        isErrorToast: isErrorToast,
      );

      return response;
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting account: $e');
      debugPrint('Stack trace: $stackTrace');

      if (isToast && isErrorToast) {
        showToastError('Failed to submit delete request');
      }

      return ApiResponse.error('Failed to submit delete request');
    }
  }

  /// 🛍️ Get seller order details
  /// Fetches seller information and items for a specific order
  Future<ApiResponse> getSellerOrderDetails({
    required int orderId,
    required int sellerId,
    bool isToast = true,
    bool isErrorToast = true,
  }) async {
    try {
      final response = await get(
        AppUrl.getOrderSellerData,
        params: {
          'order_id': orderId,
          'seller_id': sellerId,
        },
        isToast: isToast,
        isErrorToast: isErrorToast,
      );

      return response;
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching seller order details: $e');
      debugPrint('Stack trace: $stackTrace');

      if (isToast && isErrorToast) {
        showToastError('Failed to load seller details');
      }

      return ApiResponse.error('Failed to load seller details');
    }
  }
}
