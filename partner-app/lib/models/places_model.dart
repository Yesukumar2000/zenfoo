class PlacePrediction {
  final String? description;
  final String? placeId;
  final String? mainText;
  final String? secondaryText;

  PlacePrediction({
    this.description,
    this.placeId,
    this.mainText,
    this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    String? mainText;
    String? secondaryText;

    if (json['structured_formatting'] != null) {
      mainText = json['structured_formatting']['main_text'];
      secondaryText = json['structured_formatting']['secondary_text'];
    }

    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
      mainText: mainText,
      secondaryText: secondaryText,
    );
  }
}

class Suggestions {
  final PlacePrediction? placePrediction;
  Suggestions({this.placePrediction});
}

class PlaceDetailsModel {
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  PlaceDetailsModel({
    this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  factory PlaceDetailsModel.fromJson(Map<String, dynamic> json) =>
      PlaceDetailsModel(
        formattedAddress: json['result']['formatted_address'],
        latitude: json['result']['geometry']['location']['lat']?.toDouble(),
        longitude: json['result']['geometry']['location']['lng']?.toDouble(),
      );
}
