import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/driver_issue_model.dart';
import 'package:zenfoo_partner/repository/driver_issue_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class DriverIssueProvider extends ChangeNotifier {
  final DriverIssueRepository _repository = DriverIssueRepository();

  ApiResponse<List<DriverIssue>> _issuesResponse = ApiResponse.nothing();
  List<DriverIssue> _issues = [];
  bool _hasMore = false;
  int _offset = 0;
  final int _limit = 10;
  bool _isLoadingMore = false;

  ApiResponse<List<DriverIssue>> get issuesResponse => _issuesResponse;
  List<DriverIssue> get issues => _issues;
  bool get isLoading => _issuesResponse.status == ApiStatus.loading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> fetchIssues({
    String? filter,
    String? issueType,
    String? status,
    int periodOffset = 0,
  }) async {
    _offset = 0;
    _issuesResponse = ApiResponse.loading();
    notifyListeners();

    try {
      final result = await _repository.getIssues(
        filter: filter,
        issueType: issueType,
        status: status,
        offset: _offset,
        limit: _limit,
        periodOffset: periodOffset,
      );

      _issues = result['issues'] as List<DriverIssue>;
      _hasMore = result['hasMore'] as bool;
      _offset = _issues.length;
      _issuesResponse = ApiResponse.success(_issues);
    } catch (e) {
      _issuesResponse = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  Future<void> loadMore({
    String? filter,
    String? issueType,
    String? status,
    int periodOffset = 0,
  }) async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.getIssues(
        filter: filter,
        issueType: issueType,
        status: status,
        offset: _offset,
        limit: _limit,
        periodOffset: periodOffset,
      );

      final newIssues = result['issues'] as List<DriverIssue>;
      _issues.addAll(newIssues);
      _hasMore = result['hasMore'] as bool;
      _offset = _issues.length;
      _issuesResponse = ApiResponse.success(_issues);
    } catch (e) {
      debugPrint('Error loading more issues: $e');
    }

    _isLoadingMore = false;
    notifyListeners();
  }
}
