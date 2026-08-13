import 'package:zenfoo_partner/models/learning_model.dart';
import 'package:zenfoo_partner/services/api_services.dart';
import 'package:zenfoo_partner/services/status.dart';
import 'package:zenfoo_partner/utils/app_urls.dart';

class LearningRepository {
  final ApiService _apiService = ApiService();

  /// Get all learning topics
  Future<LearningTopicsResponse> getLearningTopics() async {
    try {
      final response = await _apiService.get(
        AppUrls.getLearningTopics,
      );

      if (response.status == ApiStatus.success) {
        return LearningTopicsResponse.fromJson(response.data);
      } else {
        throw Exception(response.message ?? 'Failed to fetch learning topics');
      }
    } catch (e, stackTrace) {
      throw Exception('Error fetching learning topics: $e\n$stackTrace');
    }
  }

  /// Get topic details with videos
  Future<TopicDetailsResponse> getTopicDetails(int topicId) async {
    try {
      final response = await _apiService.get(
        AppUrls.getTopicDetails(topicId),
      );

      if (response.status == ApiStatus.success) {
        return TopicDetailsResponse.fromJson(response.data);
      } else {
        throw Exception(response.message ?? 'Failed to fetch topic details');
      }
    } catch (e, stackTrace) {
      throw Exception('Error fetching topic details: $e\n$stackTrace');
    }
  }
}
