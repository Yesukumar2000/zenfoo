import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the current order data stored in Firestore delivery_boys collection
class DeliveryBoyOrder {
  final String? orderId;
  final DateTime? acceptedAt;
  final DriverLocation? driverLocation;
  final Map<String, dynamic>? orderDetails;
  final DeliveryProgress? deliveryProgress;
  final List<SellerVisit>? sellersVisitOrder;

  DeliveryBoyOrder({
    this.orderId,
    this.acceptedAt,
    this.driverLocation,
    this.orderDetails,
    this.deliveryProgress,
    this.sellersVisitOrder,
  });

  /// Create from Firestore document data
  factory DeliveryBoyOrder.fromJson(Map<String, dynamic> json) {
    // Extract sellers_visit_order from order_details if available
    List<SellerVisit>? sellers;

    // Try to get sellers_visit_order from top level first
    if (json['sellers_visit_order'] != null) {
      sellers = (json['sellers_visit_order'] as List)
          .map((e) => SellerVisit.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // If not at top level, try to get from order_details
    else if (json['order_details'] != null) {
      final orderDetails = json['order_details'];

      if (orderDetails is Map<String, dynamic>) {
        if (orderDetails['sellers_visit_order'] != null) {
          final visitOrder = orderDetails['sellers_visit_order'];

          if (visitOrder is List && visitOrder.isNotEmpty) {
            sellers = visitOrder
                .map((e) => SellerVisit.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
    }

    return DeliveryBoyOrder(
      orderId: json['order_id']?.toString(),
      acceptedAt: _parseTimestamp(json['accepted_at']),
      driverLocation: json['driver_location'] != null
          ? DriverLocation.fromJson(json['driver_location'] as Map<String, dynamic>)
          : null,
      orderDetails: json['order_details'] as Map<String, dynamic>?,
      deliveryProgress: json['delivery_progress'] != null
          ? DeliveryProgress.fromJson(json['delivery_progress'] as Map<String, dynamic>)
          : null,
      sellersVisitOrder: sellers,
    );
  }

  /// Convert to JSON for potential future use
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'accepted_at': acceptedAt?.toIso8601String(),
      'driver_location': driverLocation?.toJson(),
      'order_details': orderDetails,
      'delivery_progress': deliveryProgress?.toJson(),
      'sellers_visit_order': sellersVisitOrder?.map((e) => e.toJson()).toList(),
    };
  }

  /// Helper to parse Firestore Timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  @override
  String toString() => 'DeliveryBoyOrder(orderId: $orderId, acceptedAt: $acceptedAt)';
}

/// Model for driver location data
class DriverLocation {
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  DriverLocation({
    this.latitude,
    this.longitude,
    this.updatedAt,
  });

  /// Create from Firestore document data
  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Check if location is valid
  bool get isValid => latitude != null && longitude != null &&
                      latitude != 0.0 && longitude != 0.0;

  /// Helper to parse doubles from Firestore
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Helper to parse Firestore Timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  @override
  String toString() => 'DriverLocation(lat: $latitude, lng: $longitude, updatedAt: $updatedAt)';
}

/// Model for delivery progress tracking
class DeliveryProgress {
  final int? currentStep;
  final List<String>? stepStatuses;
  final DateTime? updatedAt;

  DeliveryProgress({
    this.currentStep,
    this.stepStatuses,
    this.updatedAt,
  });

  /// Create from Firestore document data
  factory DeliveryProgress.fromJson(Map<String, dynamic> json) {
    return DeliveryProgress(
      currentStep: json['current_step'] as int?,
      stepStatuses: json['step_statuses'] != null
          ? List<String>.from(json['step_statuses'] as List)
          : null,
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'current_step': currentStep,
      'step_statuses': stepStatuses,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get current step status
  String? get currentStepStatus {
    if (currentStep == null || stepStatuses == null) return null;
    if (currentStep! < 0 || currentStep! >= stepStatuses!.length) return null;
    return stepStatuses![currentStep!];
  }

  /// Helper to parse Firestore Timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  @override
  String toString() => 'DeliveryProgress(step: $currentStep, status: $currentStepStatus)';
}

/// Model for seller visit information in sellers_visit_order array
class SellerVisit {
  final String? sellerId;
  final String? storeName;
  final double? latitude;
  final double? longitude;
  final String? sellerAddress;
  final Map<String, dynamic>? additionalData;

  SellerVisit({
    this.sellerId,
    this.storeName,
    this.latitude,
    this.longitude,
    this.sellerAddress,
    this.additionalData,
  });

  /// Create from Firestore document data
  factory SellerVisit.fromJson(Map<String, dynamic> json) {
    return SellerVisit(
      sellerId: json['seller_id']?.toString(),
      storeName: json['store_name']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      sellerAddress: json['seller_address']?.toString(),
      additionalData: json,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'seller_id': sellerId,
      'store_name': storeName,
      'latitude': latitude,
      'longitude': longitude,
      'seller_address': sellerAddress,
      ...?additionalData,
    };
  }

  /// Check if location is valid
  bool get hasValidLocation =>
      latitude != null &&
      longitude != null &&
      latitude != 0.0 &&
      longitude != 0.0;

  /// Helper to parse doubles from Firestore
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  @override
  String toString() => 'SellerVisit(sellerId: $sellerId, storeName: $storeName, lat: $latitude, lng: $longitude)';
}
