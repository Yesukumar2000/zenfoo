import 'dart:async';
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:project/helper/utils/constant.dart';
import 'package:project/models/routesApiResponse.dart';

/// Service for Google Maps Routes API
/// Replaces deprecated Directions API with modern Routes API
class GoogleRoutesApiService {
  static const String _baseUrl = 'https://routes.googleapis.com/directions/v2:computeRoutes';

  /// Field mask - specifies which fields to return from Routes API
  /// This is required by Routes API and helps optimize response size
  static const List<String> _fieldMask = [
    'routes.distanceMeters',
    'routes.duration',
    'routes.polyline.encodedPolyline',
  ];

  /// Cache for routes to reduce API calls
  static final Map<String, _CachedRoute> _routeCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Computes a route between origin and destination
  /// Uses cached result if available (5-minute TTL)
  ///
  /// Returns null if the API request fails
  Future<RoutesApiResponse?> computeRoute({
    required LatLng origin,
    required LatLng destination,
    required BuildContext context,
  }) async {
    try {
      debugPrint('🔄 [Routes API] Fetching route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');

      // Check cache first
      final cacheKey = _getCacheKey(origin, destination);
      if (_routeCache.containsKey(cacheKey)) {
        final cachedRoute = _routeCache[cacheKey]!;
        if (DateTime.now().isBefore(cachedRoute.expiresAt)) {
          debugPrint('✅ [Routes API] Using cached route (expires in ${cachedRoute.expiresAt.difference(DateTime.now()).inSeconds}s)');
          return cachedRoute.response;
        } else {
          // Cache expired, remove it
          _routeCache.remove(cacheKey);
        }
      }

      // Build request body
      final body = _buildRequestBody(origin, destination);
      debugPrint('📤 [Routes API] Request body prepared');

      // Make API request with custom headers
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _buildHeaders(),
        body: convert.jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ [Routes API] Request timeout (10s)');
          throw TimeoutException('Routes API request timeout');
        },
      );

      debugPrint('📬 [Routes API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = convert.jsonDecode(response.body);
        debugPrint('✅ [Routes API] Valid JSON response received');

        // Parse response
        final routesResponse = RoutesApiResponse.fromJson(jsonResponse);

        if (routesResponse.routes.isEmpty) {
          debugPrint('⚠️ [Routes API] No routes found in response');
          return null;
        }

        // Decode polylines for all routes
        final decodedRoutes = routesResponse.routes.map((route) {
          try {
            final decodedPolyline = _decodePolyline(route.polylineEncoded);
            debugPrint('✅ [Routes API] Decoded polyline with ${decodedPolyline.length} points');
            return route.copyWith(decodedPolyline: decodedPolyline);
          } catch (e) {
            debugPrint('❌ [Routes API] Error decoding polyline: $e');
            return route;
          }
        }).toList();

        final decodedResponse = RoutesApiResponse(routes: decodedRoutes);

        // Cache the result
        _routeCache[cacheKey] = _CachedRoute(
          response: decodedResponse,
          expiresAt: DateTime.now().add(_cacheDuration),
        );
        debugPrint('💾 [Routes API] Route cached (5-minute TTL)');

        // Auto-cleanup cache after expiration
        Future.delayed(_cacheDuration, () {
          if (_routeCache.containsKey(cacheKey)) {
            _routeCache.remove(cacheKey);
            debugPrint('🗑️ [Routes API] Cache expired and removed');
          }
        });

        return decodedResponse;
      } else if (response.statusCode == 400) {
        debugPrint('❌ [Routes API] Bad request (400): ${response.body}');
        _logApiError(response.body);
        return null;
      } else if (response.statusCode == 403) {
        debugPrint('❌ [Routes API] Forbidden (403): API key invalid or Routes API not enabled');
        debugPrint('⚠️  [Routes API] Ensure Routes API is enabled in Google Cloud Console');
        return null;
      } else if (response.statusCode == 429) {
        debugPrint('❌ [Routes API] Rate limited (429): Too many requests');
        return null;
      } else {
        debugPrint('❌ [Routes API] Unexpected status code: ${response.statusCode}');
        debugPrint('Response: ${response.body.substring(0, 200)}');
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ [Routes API] Timeout: $e');
      return null;
    } catch (e) {
      debugPrint('❌ [Routes API] Unexpected error: $e');
      debugPrint('Stack: ${StackTrace.current}');
      return null;
    }
  }

  /// Build HTTP request body for Routes API
  Map<String, dynamic> _buildRequestBody(LatLng origin, LatLng destination) {
    return {
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          }
        }
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          }
        }
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'routeModifiers': {
        'avoidTolls': false,
        'avoidHighways': false,
        'avoidFerries': false,
      },
      'languageCode': 'en-US',
      'units': 'METRIC',
    };
  }

  /// Build HTTP headers for Routes API
  /// Critical: X-Goog-FieldMask specifies which fields to return
  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': Constant.googleApiKey,
      'X-Goog-FieldMask': _fieldMask.join(','),
    };
  }

  /// Generate cache key from coordinates
  String _getCacheKey(LatLng origin, LatLng destination) {
    return '${origin.latitude},${origin.longitude}->${destination.latitude},${destination.longitude}';
  }

  /// Decode Google Maps encoded polyline string to list of LatLng points
  /// Uses the standard Google polyline encoding algorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      // Decode latitude
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  }

  /// Helper to extract and log API error details
  void _logApiError(String responseBody) {
    try {
      final error = convert.jsonDecode(responseBody);
      final errorDetails = error['error'] ?? {};
      final message = errorDetails['message'] ?? 'Unknown error';
      debugPrint('📋 [Routes API] Error details: $message');

      if (message.contains('legacy API')) {
        debugPrint('⚠️  [Routes API] Legacy API error detected');
      } else if (message.contains('Field mask')) {
        debugPrint('⚠️  [Routes API] Field mask error - check _fieldMask');
      }
    } catch (e) {
      debugPrint('❌ [Routes API] Could not parse error response: $e');
    }
  }

  /// Clear route cache (for testing or manual cleanup)
  static void clearCache() {
    _routeCache.clear();
    debugPrint('🗑️ [Routes API] Cache cleared');
  }

  /// Get cache statistics (for debugging)
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _routeCache.length,
      'cachedRoutes': _routeCache.keys.toList(),
    };
  }
}

/// Internal class to store cached routes with expiration
class _CachedRoute {
  final RoutesApiResponse response;
  final DateTime expiresAt;

  _CachedRoute({
    required this.response,
    required this.expiresAt,
  });
}
