import 'package:flutter/material.dart';
import 'package:project/repositories/policyAndTermsApi.dart';

enum PolicyAndTermsState { initial, loading, loaded, error }

class PolicyAndTermsProvider with ChangeNotifier {

  PolicyAndTermsState _state = PolicyAndTermsState.initial;
  String? _content = "";
  String? _errorMessage = "";

  PolicyAndTermsState get state => _state;
  String? get content => _content;
  String? get errorMessage => _errorMessage;

  Future<void> loadPolicyAndTerms(String apiName) async {
    _state = PolicyAndTermsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await fetchPolicyAndTerms(apiName: apiName);
      _content = data;
      _state = PolicyAndTermsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = PolicyAndTermsState.error;
    }

    notifyListeners();
  }
}
