class Booking {
  final int bookingId;
  final String gigName;
  final DateTime slotDate;
  final String startTime;
  final String endTime;
  final double baseEarnings;
  final double actualEarnings;
  final String bookingStatus;
  final int ordersCompleted;
  final int ordersCancelled;
  final double distanceKm;
  final DateTime bookedAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  Booking({
    required this.bookingId,
    required this.gigName,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.baseEarnings,
    required this.actualEarnings,
    required this.bookingStatus,
    required this.ordersCompleted,
    required this.ordersCancelled,
    required this.distanceKm,
    required this.bookedAt,
    this.startedAt,
    this.endedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      gigName: json['gig_name'] ?? '',
      slotDate: DateTime.parse(json['slot_date']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      baseEarnings: (json['base_earnings'] ?? 0).toDouble(),
      actualEarnings: (json['actual_earnings'] ?? 0).toDouble(),
      bookingStatus: json['booking_status'] ?? '',
      ordersCompleted: json['orders_completed'] ?? 0,
      ordersCancelled: json['orders_cancelled'] ?? 0,
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      bookedAt: DateTime.parse(json['booked_at']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'gig_name': gigName,
      'slot_date': slotDate.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'base_earnings': baseEarnings,
      'actual_earnings': actualEarnings,
      'booking_status': bookingStatus,
      'orders_completed': ordersCompleted,
      'orders_cancelled': ordersCancelled,
      'distance_km': distanceKm,
      'booked_at': bookedAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  // Helper method to get formatted time range
  String getTimeRange() {
    return '$startTime - $endTime';
  }

  // Helper method to get duration in hours
  double getDurationHours() {
    try {
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      final duration = end.difference(start);
      return duration.inMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2]) : 0,
    );
  }

  // Helper to check if booking is completed
  bool get isCompleted => bookingStatus == 'completed';

  // Helper to check if booking is cancelled
  bool get isCancelled => bookingStatus == 'cancelled';

  // Helper to check if booking is active
  bool get isBooked => bookingStatus == 'booked';
}

class BookingsResponse {
  final bool status;
  final String message;
  final List<Booking> bookings;
  final int total;
  final int totalGigs;
  final int completedGigs;
  final double totalEarned;

  BookingsResponse({
    required this.status,
    required this.message,
    required this.bookings,
    required this.total,
    this.totalGigs = 0,
    this.completedGigs = 0,
    this.totalEarned = 0,
  });

  factory BookingsResponse.fromJson(Map<String, dynamic> json) {
    final statistics = json['data']['statistics'] as Map<String, dynamic>? ?? {};
    return BookingsResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      bookings: (json['data']['bookings'] as List)
          .map((booking) => Booking.fromJson(booking))
          .toList(),
      total: json['data']['total'] ?? 0,
      totalGigs: statistics['total_gigs'] ?? 0,
      completedGigs: statistics['completed_gigs'] ?? 0,
      totalEarned: (statistics['total_earned'] ?? 0).toDouble(),
    );
  }
}
