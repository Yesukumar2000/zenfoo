import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:zenfoo_partner/models/delivery_boy_location_model.dart';

class DeliveryBoyLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _locationsSubscription;

  /// Listen to all delivery boys with active locations
  /// Returns a stream of delivery boy locations that updates in real-time
  Stream<List<DeliveryBoyLocation>> listenToDeliveryBoyLocations() {
    final controller = StreamController<List<DeliveryBoyLocation>>.broadcast();

    try {
      debugPrint('🔥 Firestore: Setting up listener for all delivery boys...');

      _locationsSubscription = _firestore
          .collection('delivery_boys')
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          try {
            final locations = <DeliveryBoyLocation>[];

            for (var doc in snapshot.docs) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                final deliveryBoyId = int.tryParse(doc.id);

                if (deliveryBoyId != null) {
                  // Only include delivery boys with active orders (current_order exists)
                  if (data.containsKey('current_order')) {
                    final location = DeliveryBoyLocation.fromJson(
                      data,
                      deliveryBoyId: deliveryBoyId,
                    );

                    // Only add if has valid location
                    if (location.latitude != 0.0 && location.longitude != 0.0) {
                      locations.add(location);
                      debugPrint(
                          '📍 Delivery boy $deliveryBoyId: ${location.name} at (${location.latitude}, ${location.longitude})');
                    }
                  }
                }
              } catch (e) {
                debugPrint('❌ Error parsing delivery boy ${doc.id}: $e');
              }
            }

            debugPrint('📊 Found ${locations.length} delivery boys with active locations');
            controller.add(locations);
          } catch (e) {
            debugPrint('❌ Error processing delivery boy locations: $e');
            controller.addError(e);
          }
        },
        onError: (error) {
          debugPrint('❌ Firestore listener error: $error');
          controller.addError(error);
        },
      );

      debugPrint('✅ Delivery boy locations listener started');
    } catch (e) {
      debugPrint('❌ Error setting up delivery boy locations listener: $e');
      controller.addError(e);
    }

    return controller.stream;
  }

  /// Get a single delivery boy's location
  Future<DeliveryBoyLocation?> getDeliveryBoyLocation(int deliveryBoyId) async {
    try {
      final doc = await _firestore
          .collection('delivery_boys')
          .doc(deliveryBoyId.toString())
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return DeliveryBoyLocation.fromJson(data, deliveryBoyId: deliveryBoyId);
      }
    } catch (e) {
      debugPrint('❌ Error getting delivery boy location: $e');
    }
    return null;
  }

  /// Get multiple delivery boys' locations
  Future<List<DeliveryBoyLocation>> getDeliveryBoyLocations(
    List<int> deliveryBoyIds,
  ) async {
    try {
      final locations = <DeliveryBoyLocation>[];

      for (final id in deliveryBoyIds) {
        final location = await getDeliveryBoyLocation(id);
        if (location != null) {
          locations.add(location);
        }
      }

      return locations;
    } catch (e) {
      debugPrint('❌ Error getting delivery boy locations: $e');
      return [];
    }
  }

  /// Stop listening to delivery boy locations
  void stopListening() {
    _locationsSubscription?.cancel();
    _locationsSubscription = null;
    debugPrint('🛑 Delivery boy locations listener stopped');
  }

  /// Dispose the service
  void dispose() {
    stopListening();
  }
}
