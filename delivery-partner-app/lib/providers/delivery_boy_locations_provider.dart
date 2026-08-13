import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/delivery_boy_location_model.dart';
import 'package:zenfoo_partner/services/delivery_boy_location_service.dart';

class DeliveryBoyLocationsProvider with ChangeNotifier {
  final DeliveryBoyLocationService _locationService =
      DeliveryBoyLocationService();

  List<DeliveryBoyLocation> _deliveryBoyLocations = [];
  List<DeliveryBoyLocation> get deliveryBoyLocations => _deliveryBoyLocations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription<List<DeliveryBoyLocation>>? _locationsSubscription;

  /// Start listening to delivery boy locations
  void startListeningToLocations() {
    debugPrint('🚀 Starting to listen to delivery boy locations');

    _isLoading = true;
    _error = null;
    notifyListeners();

    _locationsSubscription?.cancel();
    _locationsSubscription = _locationService.listenToDeliveryBoyLocations().listen(
      (locations) {
        _deliveryBoyLocations = locations;
        _isLoading = false;
        _error = null;
        debugPrint('✅ Updated delivery boy locations: ${locations.length} boys');
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = error.toString();
        debugPrint('❌ Error listening to locations: $error');
        notifyListeners();
      },
    );
  }

  /// Get a specific delivery boy location
  Future<DeliveryBoyLocation?> getDeliveryBoyLocation(int deliveryBoyId) async {
    try {
      return await _locationService.getDeliveryBoyLocation(deliveryBoyId);
    } catch (e) {
      debugPrint('❌ Error getting delivery boy location: $e');
      return null;
    }
  }

  /// Stop listening to locations
  void stopListening() {
    _locationsSubscription?.cancel();
    _locationsSubscription = null;
    debugPrint('🛑 Stopped listening to delivery boy locations');
  }

  /// Clear all locations
  void clearLocations() {
    _deliveryBoyLocations = [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    _locationService.dispose();
    debugPrint('🧹 DeliveryBoyLocationsProvider disposed');
    super.dispose();
  }
}
