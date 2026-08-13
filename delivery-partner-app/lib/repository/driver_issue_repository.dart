import 'dart:developer' as dev;
import 'package:zenfoo_partner/models/driver_issue_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class DriverIssueRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getIssues({
    String? filter,
    String? issueType,
    String? status,
    int offset = 0,
    int limit = 10,
    int periodOffset = 0,
  }) async {
    try {
      final params = <String, dynamic>{
        'offset': offset,
        'limit': limit,
      };
      if (filter != null) params['filter'] = filter;
      if (issueType != null) params['issue_type'] = issueType;
      if (status != null) params['status'] = status;
      if (periodOffset != 0) params['period_offset'] = periodOffset;

      final response = await _apiService.get(
        AppUrl.driverIssues,
        params: params,
      );

      if (response.data != null &&
          (response.data['status'] == true ||
              response.data['status'] == 1 ||
              response.data['status'] == '1')) {
        final data = response.data['data'] ?? {};
        final List<dynamic> issuesList = data['issues'] ?? [];
        final pagination = data['pagination'] ?? {};

        return {
          'issues':
              issuesList.map((e) => DriverIssue.fromJson(e)).toList(),
          'hasMore': pagination['has_more'] ?? false,
          'total': pagination['total'] ?? 0,
        };
      }

      return {'issues': <DriverIssue>[], 'hasMore': false, 'total': 0};
    } catch (e) {
      dev.log('DriverIssueRepository.getIssues error: $e');
      rethrow;
    }
  }
}
