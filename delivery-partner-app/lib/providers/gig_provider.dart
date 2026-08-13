import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenfoo_partner/models/gig_booking_model.dart';
import 'package:zenfoo_partner/models/gig_slot_model.dart';
import 'package:zenfoo_partner/repository/gig_repository.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'dart:developer' as dev;

class GigProvider with ChangeNotifier {
  final GigRepository _gigRepository = GigRepository();

  // State for available gigs
  ApiResponse<List<GigSlot>> availableGigsState = ApiResponse.nothing();
  List<GigSlot> _availableGigs = [];
  List<GigSlot> get availableGigs => _availableGigs;

  // State for my bookings
  ApiResponse<List<GigBooking>> myBookingsState = ApiResponse.nothing();
  List<GigBooking> _myBookings = [];
  List<GigBooking> get myBookings => _myBookings;
  List<GigBooking> get upcomingBookings =>
      _myBookings.where((b) => b.isUpcoming).toList();
  List<GigBooking> get completedBookings =>
      _myBookings.where((b) => b.isCompleted).toList();
  List<GigBooking> get cancelledBookings =>
      _myBookings.where((b) => b.isCancelled).toList();

  // State for single gig details
  ApiResponse<GigSlot> gigDetailsState = ApiResponse.nothing();
  GigSlot? _currentGigDetails;
  GigSlot? get currentGigDetails => _currentGigDetails;

  // State for booking action
  ApiResponse bookGigState = ApiResponse.nothing();

  // State for cancel booking action
  ApiResponse cancelBookingState = ApiResponse.nothing();

  // State for complete gig action
  ApiResponse completeGigState = ApiResponse.nothing();

  // State for gig history
  ApiResponse<List<GigBooking>> gigHistoryState = ApiResponse.nothing();
  List<GigBooking> _gigHistory = [];
  List<GigBooking> get gigHistory => _gigHistory;

  /// Get available gigs for a specific date
  Future<void> getAvailableGigs({
    DateTime? date,
    String? gigType,
  }) async {
    availableGigsState = ApiResponse.loading();
    notifyListeners();

    try {
      final formattedDate =
          date != null ? DateFormat('yyyy-MM-dd').format(date) : null;

      final response = await _gigRepository.getAvailableGigs(
        date: formattedDate,
        gigType: gigType,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;
        // API response structure: { data: { gigs: [...] } }
        // New format has nested slots within each gig
        if (data != null &&
            data['data'] != null &&
            data['data']['gigs'] != null) {
          final gigs = data['data']['gigs'] as List;
          _availableGigs = [];

          // Flatten the nested structure: each gig has multiple slots
          for (var gigData in gigs) {
            final slots = gigData['slots'] as List?;

            if (slots != null && slots.isNotEmpty) {
              // Create a GigSlot for each time slot within this gig
              for (var slotData in slots) {
                _availableGigs.add(
                  GigSlot.fromJson(slotData, parentGig: gigData),
                );
              }
            }
          }

          availableGigsState = ApiResponse.success(_availableGigs);
        } else {
          availableGigsState = ApiResponse.error('No gigs data found');
        }
      } else {
        availableGigsState =
            ApiResponse.error(response.message ?? 'Failed to load gigs');
      }
    } catch (e, s) {
      availableGigsState = ApiResponse.error(e.toString());
      dev.log('📦 Error in getAvailableGigs: $e',
          name: 'GigProvider', error: e, stackTrace: s);
    }

    notifyListeners();
  }

  /// Get details of a specific gig slot
  Future<void> getGigDetails({required int slotId}) async {
    gigDetailsState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _gigRepository.getGigDetails(slotId: slotId);

      if (response.status == ApiStatus.success) {
        final data = response.data;
        // API response structure: { data: { gig: {...} } }
        if (data != null &&
            data['data'] != null &&
            data['data']['gig'] != null) {
          _currentGigDetails = GigSlot.fromJson(data['data']['gig']);
          gigDetailsState = ApiResponse.success(_currentGigDetails);
        } else {
          gigDetailsState = ApiResponse.error('Gig details not found');
        }
      } else {
        gigDetailsState =
            ApiResponse.error(response.message ?? 'Failed to load gig details');
      }
    } catch (e, s) {
      gigDetailsState = ApiResponse.error(e.toString());
      dev.log('📦 Error in getGigDetails: $e',
          name: 'GigProvider', error: e, stackTrace: s);
    }

    notifyListeners();
  }

  /// Book gig slots (supports both single and multiple slots)
  /// Returns a map with booking results:
  /// - success: bool
  /// - totalBooked: int
  /// - bookings: List of booking details
  /// - errors: List of error messages
  /// - skipped: List of skipped slot messages
  /// - offerProgress: List of offer progress updates
  Future<Map<String, dynamic>> bookGig({
    List<int>? slotIds,
    int? slotId,
  }) async {
    bookGigState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _gigRepository.bookGig(
        slotIds: slotIds,
        slotId: slotId,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;

        dev.log('📦 Book Gig Response Data: $data', name: 'GigProvider');
        dev.log('📦 data["data"]: ${data?['data']}', name: 'GigProvider');
        dev.log('📦 total_booked: ${data?['data']?['total_booked']}',
            name: 'GigProvider');

        // Extract booking results from response
        final result = {
          'success': true,
          'totalBooked': data?['data']?['total_booked'] ?? 0,
          'bookings': data?['data']?['bookings'] ?? [],
          'errors': data?['errors'] ?? [],
          'skipped': data?['skipped'] ?? [],
          'offerProgress': data?['data']?['offer_progress'] ?? [],
          'message': data?['message'] ?? 'Booking successful',
        };

        dev.log('✅ Constructed result: $result', name: 'GigProvider');
        dev.log('✅ totalBooked value: ${result['totalBooked']}',
            name: 'GigProvider');

        bookGigState = ApiResponse.success(result);
        notifyListeners();
        return result;
      } else {
        bookGigState =
            ApiResponse.error(response.message ?? 'Failed to book gig');
        notifyListeners();
        return {
          'success': false,
          'totalBooked': 0,
          'bookings': [],
          'errors': [response.message ?? 'Failed to book gig'],
          'skipped': [],
          'offerProgress': [],
          'message': response.message ?? 'Failed to book gig',
        };
      }
    } catch (e) {
      bookGigState = ApiResponse.error(e.toString());
      notifyListeners();
      return {
        'success': false,
        'totalBooked': 0,
        'bookings': [],
        'errors': [e.toString()],
        'skipped': [],
        'offerProgress': [],
        'message': e.toString(),
      };
    }
  }

  /// Get all bookings
  Future<void> getMyBookings({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    myBookingsState = ApiResponse.loading();
    notifyListeners();

    try {
      final formattedFromDate =
          fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : null;
      final formattedToDate =
          toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null;

      final response = await _gigRepository.getMyBookings(
        status: status,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;
        // API response structure: { data: { bookings: [...] } }
        if (data != null &&
            data['data'] != null &&
            data['data']['bookings'] != null) {
          _myBookings = (data['data']['bookings'] as List)
              .map((bookingJson) => GigBooking.fromJson(bookingJson))
              .toList();
          myBookingsState = ApiResponse.success(_myBookings);
        } else {
          _myBookings = [];
          myBookingsState = ApiResponse.success(_myBookings);
        }
      } else {
        myBookingsState =
            ApiResponse.error(response.message ?? 'Failed to load bookings');
      }
    } catch (e) {
      myBookingsState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  /// Cancel a booking
  Future<bool> cancelBooking({
    required int bookingId,
    String? reason,
  }) async {
    cancelBookingState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _gigRepository.cancelBooking(
        bookingId: bookingId,
        reason: reason,
      );

      if (response.status == ApiStatus.success) {
        cancelBookingState = ApiResponse.success(response.data);
        notifyListeners();
        return true;
      } else {
        cancelBookingState =
            ApiResponse.error(response.message ?? 'Failed to cancel booking');
        notifyListeners();
        return false;
      }
    } catch (e) {
      cancelBookingState = ApiResponse.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Complete a gig
  Future<bool> completeGig({
    required int bookingId,
    required double actualEarnings,
    required int ordersDelivered,
    required double distanceCoveredKm,
  }) async {
    completeGigState = ApiResponse.loading();
    notifyListeners();

    try {
      final response = await _gigRepository.completeGig(
        bookingId: bookingId,
        actualEarnings: actualEarnings,
        ordersDelivered: ordersDelivered,
        distanceCoveredKm: distanceCoveredKm,
      );

      if (response.status == ApiStatus.success) {
        completeGigState = ApiResponse.success(response.data);
        notifyListeners();
        return true;
      } else {
        completeGigState =
            ApiResponse.error(response.message ?? 'Failed to complete gig');
        notifyListeners();
        return false;
      }
    } catch (e) {
      completeGigState = ApiResponse.error(e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Get gig history
  Future<void> getGigHistory({
    DateTime? fromDate,
    DateTime? toDate,
    int? page,
    int? limit,
  }) async {
    gigHistoryState = ApiResponse.loading();
    notifyListeners();

    try {
      final formattedFromDate =
          fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : null;
      final formattedToDate =
          toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : null;

      final response = await _gigRepository.getGigHistory(
        fromDate: formattedFromDate,
        toDate: formattedToDate,
        page: page,
        limit: limit,
      );

      if (response.status == ApiStatus.success) {
        final data = response.data;
        // API response structure: { data: { history: [...] } }
        if (data != null &&
            data['data'] != null &&
            data['data']['history'] != null) {
          _gigHistory = (data['data']['history'] as List)
              .map((historyJson) => GigBooking.fromJson(historyJson))
              .toList();
          gigHistoryState = ApiResponse.success(_gigHistory);
        } else {
          _gigHistory = [];
          gigHistoryState = ApiResponse.success(_gigHistory);
        }
      } else {
        gigHistoryState =
            ApiResponse.error(response.message ?? 'Failed to load gig history');
      }
    } catch (e) {
      gigHistoryState = ApiResponse.error(e.toString());
    }

    notifyListeners();
  }

  /// Reset all states
  void resetStates() {
    availableGigsState = ApiResponse.nothing();
    myBookingsState = ApiResponse.nothing();
    gigDetailsState = ApiResponse.nothing();
    bookGigState = ApiResponse.nothing();
    cancelBookingState = ApiResponse.nothing();
    completeGigState = ApiResponse.nothing();
    gigHistoryState = ApiResponse.nothing();

    _availableGigs = [];
    _myBookings = [];
    _gigHistory = [];
    _currentGigDetails = null;

    notifyListeners();
  }
}
