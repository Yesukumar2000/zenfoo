class ApiStatus {
  static const nothing = "nothing";
  static const loading = "loading";
  static const success = "success";
  static const error = "error";
}

class ApiResponse<T> {
  final T? data;
  final String? message;
  final String status;

  ApiResponse.nothing() : status = ApiStatus.nothing, data = null, message = null;
  ApiResponse.loading() : status = ApiStatus.loading, data = null, message = null;
  ApiResponse.success(this.data) : status = ApiStatus.success, message = null;
  ApiResponse.error(this.message) : status = ApiStatus.error, data = null;
}

bool isStatusSuccess(String status){
  return ApiStatus.success == status;
}

/// Check if raw API response data indicates success
/// Checks for status: 1, status: '1', or other success indicators
bool isApiResponseSuccess(dynamic data) {
  if (data == null) return false;

  // Check for 'status' field with value 1 or '1'
  if (data['status'] != null) {
    if (data['status'] == 1 || data['status'] == '1') {
      return true;
    }
  }

  // Check for legacy 'Result' and 'success' fields
  return ((data['Result'].runtimeType == bool) ? data['Result'] : false) ||
      ((data['success'].runtimeType == bool) ? data['success'] : false);
}

bool isStatusLoading(String status){
  return ApiStatus.loading == status;
}
bool isStatusError(String status){
  return ApiStatus.error == status;
}

bool isStatusLoadingOrError(String status){
  return (ApiStatus.loading == status)|| (ApiStatus.error == status);
}