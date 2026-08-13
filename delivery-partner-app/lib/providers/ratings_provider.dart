import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/ratings_model.dart';
import 'package:zenfoo_partner/repository/ratings_repository.dart';

class RatingsProvider with ChangeNotifier {
  final RatingsRepository _repository = RatingsRepository();

  RatingsModel? _ratings;
  bool _isLoading = false;
  String? _error;

  RatingsModel? get ratings => _ratings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRatings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ratings = await _repository.getRatings();
      if (_ratings == null) {
        _error = "No ratings found";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
