import 'dart:io';

import 'package:flutter/material.dart';

import '../repository/help_center/floating_cash_issues/floating_cash_issue_repository.dart';
import '../services/status.dart';

class FloatingCashIssueProvider extends ChangeNotifier {
  final FloatingCashIssueRepository _repo = FloatingCashIssueRepository();

  ApiResponse floatingCashIssueState = ApiResponse.nothing();

  Future<void> floatingCashIssue({
    required String description,
    required String issueType,
    required List<int> issueIds,
    List<File>? attachments,
  }) async {
    floatingCashIssueState = ApiResponse.loading();
    notifyListeners();

    floatingCashIssueState = await _repo.floatingCashIssue(
      description: description,
      issueType: issueType,
      issueIds: issueIds,
      attachments: attachments,
    );

    notifyListeners();
  }
}
