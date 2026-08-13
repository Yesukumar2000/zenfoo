import 'package:zenfoo_partner/models/gig_model.dart';
import 'package:zenfoo_partner/models/store_location_model.dart';

class GigBooking {
  final int bookingId;
  final int deliveryBoyId;
  final int slotId;
  final String gigType;
  final String displayName;
  final String slotDate;
  final String startTime;
  final String endTime;
  final double durationHours;
  final double? estimatedEarnings;
  final String bookingStatus; // booked, active, completed, cancelled, no_show
  final DateTime bookedAt;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime? completedAt;
  final double actualEarnings;
  final int ordersDelivered;
  final double distanceCoveredKm;
  final Gig? gig;
  final StoreLocation? storeLocation;

  GigBooking({
    required this.bookingId,
    required this.deliveryBoyId,
    required this.slotId,
    required this.gigType,
    required this.displayName,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    this.durationHours = 0.0,
    this.estimatedEarnings,
    required this.bookingStatus,
    required this.bookedAt,
    this.cancelReason,
    this.cancelledAt,
    this.completedAt,
    this.actualEarnings = 0.0,
    this.ordersDelivered = 0,
    this.distanceCoveredKm = 0.0,
    this.gig,
    this.storeLocation,
  });

  bool get isUpcoming => bookingStatus == 'booked' || bookingStatus == 'active';
  bool get isActive => bookingStatus == 'active';
  bool get isCompleted => bookingStatus == 'completed';
  bool get isCancelled =>
      bookingStatus == 'cancelled' || bookingStatus == 'no_show';

  DateTime get gigDate => DateTime.parse(slotDate);

  /// Safe parse integer from any type
  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safe parse double from any type
  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Safe parse string from any type
  static String _parseString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safe parse DateTime from any type
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory GigBooking.fromJson(Map<String, dynamic> json) {
    return GigBooking(
      bookingId: _parseInt(json['booking_id']),
      deliveryBoyId: _parseInt(json['delivery_boy_id']),
      slotId: _parseInt(json['slot_id']),
      gigType: _parseString(json['gig_type']),
      displayName: _parseString(json['display_name']),
      slotDate: _parseString(json['slot_date']),
      startTime: _parseString(json['start_time']),
      endTime: _parseString(json['end_time']),
      durationHours: _parseDouble(json['duration_hours']),
      estimatedEarnings: json['estimated_earnings'] != null
          ? _parseDouble(json['estimated_earnings'])
          : json['base_earnings'] != null
              ? _parseDouble(json['base_earnings'])
              : null,
      bookingStatus: _parseString(json['booking_status'], 'booked'),
      bookedAt: _parseDateTime(json['booked_at']) ?? DateTime.now(),
      cancelReason: json['cancel_reason'],
      cancelledAt: _parseDateTime(json['cancelled_at']),
      completedAt: _parseDateTime(json['completed_at']),
      actualEarnings: _parseDouble(json['actual_earnings']),
      ordersDelivered: _parseInt(json['orders_delivered']),
      distanceCoveredKm: _parseDouble(json['distance_covered_km']),
      gig: json['gig'] != null ? Gig.fromJson(json['gig']) : null,
      storeLocation: json['store_location'] != null
          ? StoreLocation.fromJson(json['store_location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'delivery_boy_id': deliveryBoyId,
      'slot_id': slotId,
      'gig_type': gigType,
      'display_name': displayName,
      'slot_date': slotDate,
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'estimated_earnings': estimatedEarnings,
      'booking_status': bookingStatus,
      'booked_at': bookedAt.toIso8601String(),
      'cancel_reason': cancelReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'actual_earnings': actualEarnings,
      'orders_delivered': ordersDelivered,
      'distance_covered_km': distanceCoveredKm,
      'gig': gig?.toJson(),
      'store_location': storeLocation?.toJson(),
    };
  }
}
