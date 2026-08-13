import 'package:flutter/material.dart';
import 'package:project/models/super_mart_category_models.dart';
import 'package:project/repositories/super_mart_category_api.dart';

class SuperMartCategoryProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  SuperMartCategoryResponse? _response;
  SuperMartCategoryResponse? get response => _response;

  List<CategoryGrouping> _categoryGroups = [];
  List<CategoryGrouping> get categoryGroups => _categoryGroups;

  String _storeName = '';
  String get storeName => _storeName;

  /// Fetch Super Mart Category Groups
  Future<void> fetchCategoryGroups(String sellerId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await getSuperMartCategoryGroupsApi(sellerId: sellerId);

      if (result['status'].toString() == '1') {
        _response = SuperMartCategoryResponse.fromJson(result);

        if (_response?.data != null) {
          _categoryGroups = _response!.data!.categoryGroups;
          _storeName = _response!.data!.storeName;
        }

        _hasError = false;
      } else {
        _hasError = true;
        _errorMessage = result['message'] ?? 'Failed to load category groups';
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error: $e';
      print('Error fetching super mart categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh category groups
  Future<void> refresh(String sellerId) async {
    await fetchCategoryGroups(sellerId);
  }
}
