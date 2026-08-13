class DeliveryBoyLocation {
  final int deliveryBoyId;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final String? phone;
  final String? status;

  DeliveryBoyLocation({
    required this.deliveryBoyId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.phone,
    this.status,
  });

  factory DeliveryBoyLocation.fromJson(
    Map<String, dynamic> json, {
    required int deliveryBoyId,
  }) {
    final currentOrder = json['current_order'] as Map<String, dynamic>?;
    final driverLocation = currentOrder?['driver_location'] as Map<String, dynamic>?;

    return DeliveryBoyLocation(
      deliveryBoyId: deliveryBoyId,
      name: json['name'] as String? ?? 'Unknown',
      latitude: (driverLocation?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (driverLocation?['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAt: _parseDateTime(driverLocation?['updated_at']),
      phone: json['phone'] as String?,
      status: currentOrder != null ? 'on_delivery' : 'offline',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    // Handle Firestore Timestamp
    if (value is Map && value.containsKey('_seconds')) {
      final seconds = value['_seconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_boy_id': deliveryBoyId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': updatedAt.toIso8601String(),
      'phone': phone,
      'status': status,
    };
  }
}
