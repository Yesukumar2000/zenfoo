import 'dart:io';

import 'package:zenfoo_partner/services/api_services.dart';

import '../../../services/status.dart';
import '../../../utils/app_urls.dart';

class FloatingCashIssueRepository {
  final ApiService _api = ApiService();

  Future<ApiResponse> floatingCashIssue({
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
      AppUrl.pockettingIssue,
      data: data,
      files: files.isNotEmpty ? files : null,
    );
  }
}
