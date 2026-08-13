import '../../../services/api_services.dart';
import '../../../services/status.dart';
import '../../../utils/app_urls.dart';

class OrderEarningIssueRepository {
  final ApiService _api = ApiService();

  Future<ApiResponse> getOrderEarningIssue({
    required int page,
    required int perPage,
  }) async {
    return await _api.get(
      '${AppUrl.getOrderEarningIssue}?page=$page&per_page=$perPage',
      isToast: false,
    );
  }

  Future<ApiResponse> orderEarningIssueDetails({
    required int orderId,
  }) async {
    try {
      final response = await _api.post(
        AppUrl.orderEarningIssueDetails,
        data: {
          'issue_ids[0]': orderId,
          'issue_type': 'order_earning',
        },
      );

      return response; // Return ApiResponse directly
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
