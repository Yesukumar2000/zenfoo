import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class MapService {
  // Navigate to a location using Google Navigation
  Future<void> navigateToLocation({
    required double latitude,
    required double longitude,
    required String title,
  }) async {
    try {
      final waypoint = NavigationWaypoint(
        title: title,
        target: LatLng(latitude: latitude, longitude: longitude),
      );

      final destinations = Destinations(
        waypoints: [waypoint],
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
        ),
        displayOptions: NavigationDisplayOptions(),
      );

      await GoogleMapsNavigator.setDestinations(destinations);
    } catch (e) {
      debugPrint('Error setting navigation destination: $e');
      rethrow;
    }
  }

  Future<void> openGoogleMaps({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    final Uri googleUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1"
      "&origin=$pickupLat,$pickupLng"
      "&destination=$dropLat,$dropLng"
      "&travelmode=driving",
    );

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open Google Maps';
    }
  }
}
