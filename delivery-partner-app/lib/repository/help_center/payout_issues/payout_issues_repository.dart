import 'dart:io';

import 'package:zenfoo_partner/services/api_services.dart';

import '../../../services/status.dart';
import '../../../utils/app_urls.dart';

class PayoutIssuesRepository {
  final ApiService _api = ApiService();

  // ================== joining bonus ==================
  Future<ApiResponse> joiningBonus({
    required String description,
  }) async {
    return await _api.post(
      AppUrl.joiningBonus,
      data: {
        'description': description,
        'issue_type': "joining_bonus",
      },
    );
  }

//============ payout weeks ==============

  Future<ApiResponse> payoutWeeks() async {
    return await _api.get(
      AppUrl.payoutWeeks,
    );
  }

//============ get week  payout transactions ==============

  Future<ApiResponse> getweektransactions({
    required String week,
  }) async {
    return await _api.get(
      '${AppUrl.getWeekPayoutTransactions}?week=$week&type=payout',
    );
  }

  // ================== payout bank ==================
  Future<ApiResponse> payoutBank({
    required String description,
    required String issueType,
    required List<int> issueIds,
    List<File>? attachments,
  }) async {
    final Map<String, dynamic> data = {
      'description': description,
      'issue_type': issueType,
    };

    for (int i = 0; i < issueIds.length; i++) {
      data['issue_ids[$i]'] = issueIds[i];
    }

    final Map<String, File> files = {};
    if (attachments != null) {
      for (int i = 0; i < attachments.length; i++) {
        files['attachments[$i]'] = attachments[i];
      }
    }

    return await _api.post(
      AppUrl.joiningBonus,
      data: data,
      files: files.isNotEmpty ? files : null,
    );
  }

  // incentive issues

  Future<ApiResponse> incentiveWeeks() async {
    return await _api.get(
      AppUrl.incentiveWeeks,
    );
  }

  Future<ApiResponse> getWeekIncentiveTransactions({
    required String week,
  }) async {
    return await _api.get(
      '${AppUrl.getWeekIncentiveTransactions}?week=$week&type=incentive',
    );
  }

  Future<ApiResponse> incentiveBank({
    required String description,
    required String issueType,
    required List<int> issueIds,
    List<File>? attachments,
  }) async {
    final Map<String, dynamic> data = {
      'description': description,
      'issue_type': issueType,
    };

    for (int i = 0; i < issueIds.length; i++) {
      data['issue_ids[$i]'] = issueIds[i];
    }

    final Map<String, File> files = {};
    if (attachments != null) {
      for (int i = 0; i < attachments.length; i++) {
        files['attachments[$i]'] = attachments[i];
      }
    }

    return await _api.post(
      AppUrl.incentiveBank,
      data: data,
      files: files.isNotEmpty ? files : null,
    );
  }

  // Multi order

  Future<ApiResponse> multiOrderWeeks() async {
    return await _api.get(
      AppUrl.multiOrderWeeks,
    );
  }

  Future<ApiResponse> getWeekMultiOrderTransactions({
    required String week,
  }) async {
    return await _api.get(
      '${AppUrl.getWeekMultiOrderTransactions}?week=$week&type=multi_order',
    );
  }

  Future<ApiResponse> multiOrderBank({
    required String description,
    required String issueType,
    required List<int> issueIds,
    List<File>? attachments,
  }) async {
    final Map<String, dynamic> data = {
      'description': description,
      'issue_type': issueType,
    };

    for (int i = 0; i < issueIds.length; i++) {
      data['issue_ids[$i]'] = issueIds[i];
    }

    final Map<String, File> files = {};
    if (attachments != null) {
      for (int i = 0; i < attachments.length; i++) {
        files['attachments[$i]'] = attachments[i];
      }
    }

    return await _api.post(
      AppUrl.multiOrderBank,
      data: data,
      files: files.isNotEmpty ? files : null,
    );
  }
}
