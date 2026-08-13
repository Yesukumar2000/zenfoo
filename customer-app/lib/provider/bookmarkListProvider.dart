import 'package:flutter/material.dart';
import 'package:project/models/bookmarkTab.dart';
import 'package:project/repositories/homeScreenApi.dart';

enum BookmarkListState { initial, loading, loaded, error }

class BookmarkListProvider extends ChangeNotifier {
  BookmarkListState _state = BookmarkListState.initial;
  BookmarkTabsResponse? _bookmarkTabs;
  String _errorMessage = '';

  BookmarkListState get state => _state;
  BookmarkTabsResponse? get bookmarkTabs => _bookmarkTabs;
  String get errorMessage => _errorMessage;

  Future<void> fetchBookmarksList({required BuildContext context}) async {
    _state = BookmarkListState.loading;
    notifyListeners();

    try {
      final response = await fetchBookmarksListApi(context: context);

      if (response != null && response.status == 1) {
        _bookmarkTabs = response;
        _state = BookmarkListState.loaded;
      } else {
        _errorMessage = response?.message ?? 'Failed to load bookmarks';
        _state = BookmarkListState.error;
      }
    } catch (e) {
      _errorMessage = 'Error loading bookmarks: $e';
      _state = BookmarkListState.error;
    }

    notifyListeners();
  }

  void reset() {
    _state = BookmarkListState.initial;
    _bookmarkTabs = null;
    _errorMessage = '';
    notifyListeners();
  }
}
