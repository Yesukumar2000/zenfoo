import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Response model for Google Routes API
class RoutesApiResponse {
  final List<RouteData> routes;

  RoutesApiResponse({required this.routes});

  factory RoutesApiResponse.fromJson(Map<String, dynamic> json) {
    final routes = (json['routes'] as List?)?.map((route) {
          return RouteData.fromJson(route as Map<String, dynamic>);
        }).toList() ??
        [];

    return RoutesApiResponse(routes: routes);
  }
}

/// Individual route data from Routes API
class RouteData {
  final int distanceMeters;
  final String duration; // Format: "300s" (seconds)
  final String polylineEncoded;
  final List<LatLng> decodedPolyline;

  RouteData({
    required this.distanceMeters,
    required this.duration,
    required this.polylineEncoded,
    required this.decodedPolyline,
  });

  /// Parse duration string (e.g., "300s") to seconds as double
  double getDurationInSeconds() {
    try {
      return double.parse(duration.replaceAll('s', ''));
    } catch (e) {
      return 0.0;
    }
  }

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      distanceMeters: json['distanceMeters'] ?? 0,
      duration: json['duration'] ?? '0s',
      polylineEncoded: json['polyline']?['encodedPolyline'] ?? '',
      decodedPolyline: [], // Will be set after polyline decoding
    );
  }

  /// Create a copy with decoded polyline
  RouteData copyWith({List<LatLng>? decodedPolyline}) {
    return RouteData(
      distanceMeters: this.distanceMeters,
      duration: this.duration,
      polylineEncoded: this.polylineEncoded,
      decodedPolyline: decodedPolyline ?? this.decodedPolyline,
    );
  }
}
