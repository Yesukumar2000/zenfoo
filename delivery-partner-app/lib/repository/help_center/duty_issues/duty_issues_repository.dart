import 'package:zenfoo_partner/services/status.dart';

import '../../../services/api_services.dart';
import '../../../utils/app_urls.dart';

class DutyIssuesRepository {
  final ApiService _api = ApiService();

  Future<ApiResponse> dutyIssues() async {
    return await _api.get(
      AppUrls.notGettingOrders,
      isToast: false,
    );
  }

  Future<ApiResponse> ordersIssue() async {
    return await _api.post(
      AppUrls.ordersIssue,
      data: {
        'issue_type': 'not_getting_order_issue',
      },
    );
  }
}
