import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/models/deliveryBoyOrder.dart';

/// Service for managing real-time delivery tracking via Firestore
class DeliveryTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to real-time delivery tracking updates for a specific delivery boy
  ///
  /// Returns a stream of [DeliveryBoyOrder] objects that updates whenever the
  /// delivery boy's current order changes in Firestore.
  ///
  /// Returns null if the order doesn't exist or if delivery boy hasn't been assigned
  Stream<DeliveryBoyOrder?> listenToDeliveryTracking(String deliveryBoyId) {
    return _firestore
        .collection('delivery_boys')
        .doc(deliveryBoyId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      final currentOrder = data['current_order'];
      if (currentOrder == null) {
        return null;
      }

      try {
        final order = DeliveryBoyOrder.fromJson(currentOrder as Map<String, dynamic>);
        return order;
      } catch (e) {
        return null;
      }
    }).handleError((error) {
      // Rethrow to let caller handle the error
      throw error;
    });
  }

  /// Check if Firestore is available and accessible
  ///
  /// Uses a health check query with a 5-second timeout
  Future<bool> isFirestoreAvailable() async {
    try {
      await _firestore
          .collection('delivery_boys')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Map Firebase delivery progress to Order activeStatus code
  ///
  /// Converts Firebase delivery_progress data to existing Order activeStatus format
  /// for compatibility with the current order tracking UI
  ///
  /// Firebase currentStep mapping:
  /// - 0 or 'preparing' → '2' (Processing)
  /// - 1 or 'out_for_delivery' → '3' (Out for Delivery)
  /// - 2 or 'delivered' → '4' (Delivered)
  String mapProgressToActiveStatus(DeliveryProgress? progress) {
    if (progress == null) {
      return '1'; // Default: Received/Placed
    }

    final currentStep = progress.currentStep;
    final currentStatus = progress.currentStepStatus;

    // Map by step index first
    if (currentStep != null) {
      switch (currentStep) {
        case 0:
          return '2'; // Processing
        case 1:
          return '3'; // Out for Delivery
        case 2:
          return '4'; // Delivered
        default:
          return '1'; // Default: Received
      }
    }

    // Fallback: Map by step status string if available
    if (currentStatus != null) {
      switch (currentStatus.toLowerCase()) {
        case 'preparing':
        case 'in_progress':
          return '2'; // Processing
        case 'out_for_delivery':
          return '3'; // Out for Delivery
        case 'delivered':
          return '4'; // Delivered
        default:
          return '1'; // Default: Received
      }
    }

    return '1'; // Default: Received
  }

  /// Get the human-readable status name from activeStatus code
  String getStatusName(String activeStatus) {
    switch (activeStatus) {
      case '1':
        return 'Order Placed';
      case '2':
        return 'Processing';
      case '3':
        return 'Out for Delivery';
      case '4':
        return 'Delivered';
      case '5':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
