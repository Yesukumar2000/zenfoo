import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:zenfoo_partner/utils/notification_helper.dart';

enum PlaceSuggestionsState {
  initial,
  loading,
  loaded,
  empty,
  error,
}

class PlaceSuggestionsProvider extends ChangeNotifier {
  PlaceSuggestionsState placeSuggestionsState = PlaceSuggestionsState.initial;
  List<AutocompletePrediction> suggestions = [];
  String message = '';

  /// Lazily initialize Google Places SDK with dynamic API key
  late final FlutterGooglePlacesSdk _places = FlutterGooglePlacesSdk(
    Constant.googleApiKey,
  );

  Future<void> fetchSuggestions({
    required BuildContext context,
    required String input,
  }) async {
    if (input.trim().length < 3) {
      clearSuggestions();
      return;
    }

    placeSuggestionsState = PlaceSuggestionsState.loading;
    suggestions = [];
    message = '';
    notifyListeners();

    try {
      final response = await _places.findAutocompletePredictions(
        input,
        countries: ['IN'], // Limit to India
      );

      suggestions = response.predictions;

      if (suggestions.isEmpty) {
        placeSuggestionsState = PlaceSuggestionsState.empty;
        message = 'No suggestions found';
      } else {
        placeSuggestionsState = PlaceSuggestionsState.loaded;
      }
    } catch (e) {
      message = e.toString();
      placeSuggestionsState = PlaceSuggestionsState.error;
    }

    notifyListeners();
  }

  void clearSuggestions() {
    suggestions = [];
    message = '';
    placeSuggestionsState = PlaceSuggestionsState.initial;
    notifyListeners();
  }
}
