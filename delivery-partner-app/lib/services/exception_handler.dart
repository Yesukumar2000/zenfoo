class ExceptionHandler {
  // Map different HTTP error codes to custom error messages
  static String getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return "Bad request. Please check your input.";
      case 401:
        return "Unauthorized. Please check your credentials.";
      case 403:
        return "Forbidden. You don't have permission to access this resource.";
      case 404:
        return "Resource not found.";
      case 500:
        return "Internal server error. Please try again later.";
      default:
        return "Unknown error occurred. Please try again.";
    }
  }
}
