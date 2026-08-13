import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:project/models/places_model.dart';
import 'package:project/helper/utils/generalImports.dart';

enum PlaceSuggestionsState { idle, loading, loaded, error }

class PlaceSuggestionsProvider extends ChangeNotifier {
  List<Suggestions> suggestions = [];
  PlaceSuggestionsState state = PlaceSuggestionsState.idle;
  String errorMessage = '';

  Future<void> fetchSuggestions({required String input}) async {
    state = PlaceSuggestionsState.loading;
    notifyListeners();
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?key=${Constant.googleApiKey}&input=$input',
    );
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        suggestions = (data['predictions'] as List)
            .map((item) => Suggestions(placePrediction: PlacePrediction.fromJson(item)))
            .toList();
        state = PlaceSuggestionsState.loaded;
      } else {
        errorMessage = data['error_message'] ?? data['status'];
        state = PlaceSuggestionsState.error;
      }
    } catch (e) {
      errorMessage = e.toString();
      state = PlaceSuggestionsState.error;
    }
    notifyListeners();
  }

  void clearSuggestions() {
    suggestions = [];
    state = PlaceSuggestionsState.idle;
    notifyListeners();
  }
}

enum PlaceDetailsState { initial, loading, loaded, error }

class PlaceDetailsProvider extends ChangeNotifier {
  PlaceDetailsModel? placeDetails;
  PlaceDetailsState state = PlaceDetailsState.initial;
  String errorMessage = '';

  Future<void> fetchPlaceDetails({required String placeId}) async {
    state = PlaceDetailsState.loading;
    notifyListeners();
    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?key=${Constant.googleApiKey}&place_id=$placeId');
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        placeDetails = PlaceDetailsModel.fromJson(data);
        state = PlaceDetailsState.loaded;
      } else {
        errorMessage = data['error_message'] ?? data['status'];
        state = PlaceDetailsState.error;
      }
    } catch (e) {
      errorMessage = e.toString();
      state = PlaceDetailsState.error;
    }
    notifyListeners();
  }

  void clearDetails() {
    placeDetails = null;
    state = PlaceDetailsState.initial;
    errorMessage = '';
    notifyListeners();
  }
}
