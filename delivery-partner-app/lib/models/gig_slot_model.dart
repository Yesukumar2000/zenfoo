class GigSlot {
  final int slotId;
  final int gigId;
  final String gigType;
  final String gigDisplayName;
  final String slotName;
  final String slotDate;
  final String startTime;
  final String endTime;
  final double durationHours;
  final int totalSlots;
  final int availableSlots;
  final int bookedSlots;
  final double baseEarnings;
  final String status; // active, inactive
  final bool isBooked;
  final int? slotNumber;
  final int? bookingId; // The booking ID when slot is booked
  final String? bookingStatus; // booked, active, completed, cancelled
  final DateTime createdAt;

  GigSlot({
    required this.slotId,
    required this.gigId,
    required this.gigType,
    required this.gigDisplayName,
    required this.slotName,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalSlots,
    required this.availableSlots,
    required this.bookedSlots,
    required this.baseEarnings,
    required this.status,
    this.isBooked = false,
    this.slotNumber,
    this.bookingId,
    this.bookingStatus,
    required this.createdAt,
  });

  bool get isAvailable => availableSlots > 0 && status == 'active';

  // Helper to get display name - prioritize slot name, fall back to gig display name
  String get displayName => slotName.isNotEmpty ? slotName : gigDisplayName;

  /// Create GigSlot from slot JSON with parent gig context
  factory GigSlot.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? parentGig,
  }) {
    // If parentGig is provided, this is a nested slot from the new API
    // Otherwise, handle old flat API format
    final isNestedFormat = parentGig != null;

    // Get values from slot or parent gig as appropriate
    final gigId = isNestedFormat
        ? (parentGig['gig_id'] is String
            ? int.parse(parentGig['gig_id'])
            : parentGig['gig_id'] as int)
        : (json['gig_id'] is String
            ? int.parse(json['gig_id'])
            : json['gig_id'] as int);

    final gigType = isNestedFormat
        ? (parentGig['gig_name'] ?? parentGig['gig_type'] ?? '')
        : (json['gig_type'] ?? json['gig_name'] ?? '');

    final gigDisplayName = isNestedFormat
        ? (parentGig['display_name'] ?? '')
        : (json['display_name'] ?? '');

    final slotName = json['slot_name'] ?? '';

    // Parse slot date - handle ISO format from new API
    String slotDate = json['slot_date'] ?? '';
    if (slotDate.contains('T')) {
      // ISO format - extract just the date part
      slotDate = DateTime.parse(slotDate).toString().split(' ')[0];
    }

    // Base earnings comes from parent gig in new format
    final baseEarnings = isNestedFormat
        ? (parentGig['base_earnings'] is String
            ? double.parse(parentGig['base_earnings'])
            : (parentGig['base_earnings'] is int
                ? (parentGig['base_earnings'] as int).toDouble()
                : (parentGig['base_earnings'] ?? 0.0)))
        : (json['base_earnings'] is String
            ? double.parse(json['base_earnings'])
            : (json['base_earnings'] is int
                ? (json['base_earnings'] as int).toDouble()
                : (json['base_earnings'] ?? 0.0)));

    // Duration hours - can come from parent gig or slot
    final durationHours = (json['duration_hours'] ??
            (isNestedFormat ? parentGig['duration_hours'] : null)) ??
        0;
    final durationDouble = durationHours is String
        ? double.parse(durationHours)
        : (durationHours is int
            ? durationHours.toDouble()
            : (durationHours as double? ?? 0.0));

    // Calculate booked slots if not provided
    final totalSlots = json['total_slots'] is String
        ? int.parse(json['total_slots'])
        : (json['total_slots'] ?? 0);
    final availableSlots = json['available_slots'] is String
        ? int.parse(json['available_slots'])
        : (json['available_slots'] ?? 0);
    final bookedSlots = json['booked_slots'] is String
        ? int.parse(json['booked_slots'])
        : (json['booked_slots'] ?? (totalSlots - availableSlots));

    // Determine status based on is_available flag or status field
    final status = json['status'] ??
        (json['is_available'] == true || json['is_available'] == 1
            ? 'active'
            : 'inactive');

    // Parse booking_id if present
    final bookingId = json['booking_id'] != null
        ? (json['booking_id'] is String
            ? int.parse(json['booking_id'])
            : json['booking_id'] as int?)
        : null;

    return GigSlot(
      slotId: json['slot_id'] is String
          ? int.parse(json['slot_id'])
          : json['slot_id'],
      gigId: gigId,
      gigType: gigType,
      gigDisplayName: gigDisplayName,
      slotName: slotName,
      slotDate: slotDate,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      durationHours: durationDouble,
      totalSlots: totalSlots,
      availableSlots: availableSlots,
      bookedSlots: bookedSlots,
      baseEarnings: baseEarnings,
      status: status,
      isBooked: json['is_booked'] == true ||
          json['is_booked'] == 1 ||
          json['is_booked'] == '1',
      slotNumber: json['slot_number'],
      bookingId: bookingId,
      bookingStatus: json['booking_status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot_id': slotId,
      'gig_id': gigId,
      'gig_type': gigType,
      'gig_display_name': gigDisplayName,
      'slot_name': slotName,
      'slot_date': slotDate,
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'total_slots': totalSlots,
      'available_slots': availableSlots,
      'booked_slots': bookedSlots,
      'base_earnings': baseEarnings,
      'status': status,
      'is_booked': isBooked,
      'slot_number': slotNumber,
      'booking_id': bookingId,
      'booking_status': bookingStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
