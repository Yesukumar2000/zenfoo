import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/booking_model.dart';
import 'package:zenfoo_partner/repository/booking_repository.dart';

enum BookingStatus {
  idle,
  loading,
  completed,
  error,
}

class BookingProvider with ChangeNotifier {
  final BookingRepository _bookingRepository = BookingRepository();

  List<Booking> _bookings = [];
  int _total = 0;
  BookingStatus _status = BookingStatus.idle;
  String _errorMessage = '';
  BookingsResponse? _bookingsResponse;

  List<Booking> get bookings => _bookings;
  int get total => _total;
  BookingStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == BookingStatus.loading;
  BookingsResponse? get bookingsResponse => _bookingsResponse;

  /// Get bookings grouped by date
  Map<String, List<Booking>> get bookingsByDate {
    final Map<String, List<Booking>> grouped = {};

    for (final booking in _bookings) {
      final dateKey = _formatDateKey(booking.slotDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(booking);
    }

    return grouped;
  }

  /// Get today's bookings sorted by time (morning → afternoon → evening → night)
  /// Only shows upcoming bookings, filters out past time slots
  List<Booking> get todaysBookings {
    final now = DateTime.now();
    final today = DateTime.now();
    final currentTimeInMinutes = now.hour * 60 + now.minute;

    final todayBookings = _bookings.where((booking) {
      // Check if booking is today
      final isToday = booking.slotDate.year == today.year &&
          booking.slotDate.month == today.month &&
          booking.slotDate.day == today.day;

      if (!isToday) return false;
      if (!booking.isBooked) return false; // Only show booked status

      // Filter out past time slots
      final bookingEndTime = _parseTimeToMinutes(booking.endTime);
      return bookingEndTime > currentTimeInMinutes;
    }).toList();

    // Sort by start time
    todayBookings.sort((a, b) {
      final timeA = _parseTimeToMinutes(a.startTime);
      final timeB = _parseTimeToMinutes(b.startTime);
      return timeA.compareTo(timeB);
    });

    return todayBookings;
  }

  /// Parse time string (HH:MM or HH:MM:SS) to minutes since midnight
  int _parseTimeToMinutes(String time) {
    try {
      final parts = time.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (e) {
      return 0; // Default to midnight if parsing fails
    }
  }

  String _formatDateKey(DateTime date) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  /// Fetch my bookings with optional date range filtering
  Future<void> fetchMyBookings({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    _status = BookingStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _bookingRepository.getMyBookings(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      _bookingsResponse = response;
      _bookings = response.bookings;
      _total = response.total;
      _status = BookingStatus.completed;
    } catch (e, stackTrace) {
      _status = BookingStatus.error;
      _errorMessage = e.toString();
      debugPrint('Error fetching bookings: $e\n$stackTrace');
    }

    notifyListeners();
  }

  /// Refresh bookings
  Future<void> refreshBookings() async {
    await fetchMyBookings();
  }

  /// Clear bookings
  void clearBookings() {
    _bookings = [];
    _total = 0;
    _status = BookingStatus.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
