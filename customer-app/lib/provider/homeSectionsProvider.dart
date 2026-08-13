import 'package:flutter/material.dart';
import 'package:project/models/homeSection.dart';
import 'package:project/repositories/homeSectionsApi.dart';

enum HomeSectionsState { initial, loading, loaded, loadingMore, error }

class HomeSectionsProvider extends ChangeNotifier {
  HomeSectionsState state = HomeSectionsState.initial;
  List<HomeSection> sections = [];
  String message = "";
  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 3;

  bool get hasMore => _currentPage <= _totalPages;
  bool get isLoading => state == HomeSectionsState.loading;
  bool get isLoadingMore => state == HomeSectionsState.loadingMore;
  bool get hasSections => sections.isNotEmpty;

  Future<void> fetchHomeSections(BuildContext context) async {
    _currentPage = 1;
    sections = [];
    state = HomeSectionsState.loading;
    notifyListeners();

    await _loadPage(context);
  }

  Future<void> loadMore(BuildContext context) async {
    if (!hasMore || state == HomeSectionsState.loadingMore) return;

    state = HomeSectionsState.loadingMore;
    notifyListeners();

    await _loadPage(context);
  }

  Future<void> _loadPage(BuildContext context) async {
    try {
      final response = await getHomeSections(
        context: context,
        page: _currentPage,
        perPage: _perPage,
      );

      if (response['status'] == 1 && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> sectionsList = data['sections'] ?? [];

        sections.addAll(
          sectionsList.map((e) => HomeSection.fromJson(e)).toList(),
        );

        _currentPage = (data['current_page'] ?? _currentPage) + 1;
        _totalPages = data['total_pages'] ?? 1;
        state = HomeSectionsState.loaded;
      } else {
        message = response['message'] ?? "Failed to load";
        if (sections.isEmpty) {
          state = HomeSectionsState.error;
        } else {
          state = HomeSectionsState.loaded;
        }
      }
    } catch (e) {
      message = e.toString();
      if (sections.isEmpty) {
        state = HomeSectionsState.error;
      } else {
        state = HomeSectionsState.loaded;
      }
    }

    notifyListeners();
  }
}
