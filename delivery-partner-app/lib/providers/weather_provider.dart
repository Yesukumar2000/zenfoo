import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zenfoo_partner/repository/weather_repository.dart';
import 'package:zenfoo_partner/services/status.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherRepository _weatherRepository = WeatherRepository();

  bool _isRaining = false;
  bool get isRaining => _isRaining;

  bool _rainExpected = false;
  bool get rainExpected => _rainExpected;

  ApiResponse weatherState = ApiResponse.nothing();

  /// Fetch rain status for the given coordinates.
  /// Mirrors the customer app: any failure simply leaves the icon hidden.
  Future<void> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    weatherState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _weatherRepository.checkRain(
        latitude: latitude,
        longitude: longitude,
      );

      if (response.status == ApiStatus.success) {
        final body = response.data;

        // API shape: { status: 1, message: "...", data: { is_raining_now, rain_expected, ... } }
        final isSuccess = body != null &&
            (body['status'] == 1 ||
                body['status'] == '1' ||
                body['status'] == true);

        final data = isSuccess ? body['data'] : null;

        if (data != null) {
          _isRaining = _parseBool(data['is_raining_now']);
          _rainExpected = _parseBool(data['rain_expected']);
        } else {
          _isRaining = false;
          _rainExpected = false;
        }

        dev.log(
          '🌧️ isRaining: $_isRaining, rainExpected: $_rainExpected',
          name: 'WeatherProvider',
        );
        weatherState = ApiResponse.success(data);
      } else {
        dev.log('❌ Weather API error: ${response.message}',
            name: 'WeatherProvider');
        _isRaining = false;
        _rainExpected = false;
        weatherState = ApiResponse.error(response.message);
      }
    } catch (e) {
      dev.log('💥 Unexpected error: $e', name: 'WeatherProvider');
      _isRaining = false;
      _rainExpected = false;
      weatherState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  bool _parseBool(dynamic value) =>
      value == true || value == 1 || value == '1' || value == 'true';
}
