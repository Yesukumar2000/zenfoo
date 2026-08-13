import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:zenfoo_partner/utils/notification_helper.dart';

enum PlaceDetailsState {
  initial,
  loading,
  loaded,
  error,
}

class PlaceDetailsProvider extends ChangeNotifier {
  PlaceDetailsState placeDetailsState = PlaceDetailsState.initial;
  Place? placeDetails;
  String message = '';

  /// Lazily initialize Google Places SDK with dynamic API key
  late final FlutterGooglePlacesSdk _places = FlutterGooglePlacesSdk(
    Constant.googleApiKey,
  );

  Future<void> fetchPlaceDetails({
    required BuildContext context,
    required String placeId,
  }) async {
    placeDetailsState = PlaceDetailsState.loading;
    placeDetails = null;
    message = '';
    notifyListeners();

    try {
      final response = await _places.fetchPlace(
        placeId,
        fields: [
          PlaceField.Location,
          PlaceField.Address,
          PlaceField.AddressComponents,
        ],
      );

      placeDetails = response.place;
      placeDetailsState = PlaceDetailsState.loaded;
    } catch (e) {
      message = e.toString();
      placeDetailsState = PlaceDetailsState.error;
    }

    notifyListeners();
  }

  void clearDetails() {
    placeDetails = null;
    message = '';
    placeDetailsState = PlaceDetailsState.initial;
    notifyListeners();
  }
}
