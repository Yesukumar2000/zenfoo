import 'package:zenfoo_partner/models/booking_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class BookingRepository {
  final ApiService _apiService = ApiService();

  /// Get all bookings for delivery boy with optional date range filtering
  Future<BookingsResponse> getMyBookings({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toString().split(' ')[0];
      }

      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toString().split(' ')[0];
      }

      final response = await _apiService.get(
        AppUrls.myBookings,
        params: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.status == ApiStatus.success) {
        return BookingsResponse.fromJson(response.data);
      } else {
        throw Exception(response.message ?? 'Failed to fetch bookings');
      }
    } catch (e, stackTrace) {
      throw Exception('Error fetching bookings: $e\n$stackTrace');
    }
  }
}
