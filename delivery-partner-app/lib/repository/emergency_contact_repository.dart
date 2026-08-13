import 'package:http/http.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class EmergencyContactRepository {
  final ApiService _apiService = ApiService();

  /// Get all emergency contacts for the authenticated delivery boy
  Future<ApiResponse<dynamic>> getEmergencyContacts() async {
    try {
      final response = await _apiService.get(AppUrls.emergencyContacts);
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Add a new emergency contact
  Future<ApiResponse<dynamic>> addEmergencyContact({
    required String name,
    required String mobileNumber,
    required String relation,
  }) async {
    try {
      final response = await _apiService.post(
        AppUrls.emergencyContacts,
        data: {
          'name': name,
          'mobile_number': mobileNumber,
          'relation': relation,
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Update an existing emergency contact
  Future<ApiResponse<dynamic>> updateEmergencyContact({
    required int id,
    String? name,
    String? mobileNumber,
    String? relation,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (mobileNumber != null) data['mobile_number'] = mobileNumber;
      if (relation != null) data['relation'] = relation;

      final response = await _apiService.put(
        '${AppUrls.emergencyContacts}/$id',
        data: data,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Delete an emergency contact
  Future<ApiResponse<dynamic>> deleteEmergencyContact(int id) async {
    try {
      final response = await _apiService.delete(
        '${AppUrls.emergencyContacts}/$id',
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
