import 'package:flutter/material.dart';
import 'package:project/models/category_model.dart';
import 'package:project/repositories/categoryApi.dart';

class CategoryListProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Pagination properties
  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _lastPage = 1;
  int get lastPage => _lastPage;

  bool get hasMorePages => _currentPage < _lastPage;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(bool value, {String message = ''}) {
    _hasError = value;
    _errorMessage = message;
    notifyListeners();
  }

  /// Fetch categories from API with pagination and search
  Future<void> fetchCategories({
    int? page,
    String? search,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _currentPage = 1;
      _categories.clear();
    }

    setLoading(true);
    setError(false);

    try {
      // Build params map
      final Map<String, String> params = {};

      // Add page parameter
      params['page'] = (page ?? _currentPage).toString();

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final result = await getSellerCategoriesApi(params: params);

      if (result != null && result['status'].toString() == '1') {
        final List<dynamic> data = result['data']['data'] ?? [];

        if (isRefresh || page == 1) {
          _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
        } else {
          // Append new categories to existing list
          final newCategories = data.map((json) => CategoryModel.fromJson(json)).toList();
          _categories.addAll(newCategories);
        }

        // Update pagination info if available
        if (result['data']['current_page'] != null) {
          _currentPage = int.tryParse(result['data']['current_page'].toString()) ?? 1;
        }
        if (result['data']['last_page'] != null) {
          _lastPage = int.tryParse(result['data']['last_page'].toString()) ?? 1;
        }

        setError(false);
      } else {
        setError(true, message: result?['message'] ?? 'Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setError(true, message: 'Error: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Load more categories (for pagination)
  Future<void> loadMoreCategories({String? search}) async {
    if (_isLoadingMore || !hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;

      // Build params map
      final Map<String, String> params = {};

      // Add page parameter
      params['page'] = nextPage.toString();

      // Add search parameter if provided
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final result = await getSellerCategoriesApi(params: params);

      if (result != null && result['status'].toString() == '1') {
        final List<dynamic> data = result['data']['data'] ?? [];
        final newCategories = data.map((json) => CategoryModel.fromJson(json)).toList();

        _categories.addAll(newCategories);

        // Update pagination info
        if (result['data']['current_page'] != null) {
          _currentPage = int.tryParse(result['data']['current_page'].toString()) ?? nextPage;
        }
        if (result['data']['last_page'] != null) {
          _lastPage = int.tryParse(result['data']['last_page'].toString()) ?? 1;
        }
      }
    } catch (e) {
      print('Error loading more categories: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Delete category from list (optimistic update)
  void removeCategory(String categoryId) {
    _categories.removeWhere((cat) => cat.id == categoryId);
    notifyListeners();
  }

  /// Update category in list (optimistic update)
  void updateCategory(CategoryModel updatedCategory) {
    final index = _categories.indexWhere((cat) => cat.id == updatedCategory.id);
    if (index != -1) {
      _categories[index] = updatedCategory;
      notifyListeners();
    }
  }

  /// Add category to list (optimistic update)
  void addCategory(CategoryModel newCategory) {
    _categories.insert(0, newCategory);
    notifyListeners();
  }
}
