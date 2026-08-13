import 'package:flutter/material.dart';
import 'package:zenfoo_partner/models/learning_model.dart';
import 'package:zenfoo_partner/repository/learning_repository.dart';

enum LearningStatus {
  idle,
  loading,
  loaded,
  error,
}

class LearningProvider with ChangeNotifier {
  final LearningRepository _repository = LearningRepository();

  // Topics
  LearningStatus _topicsStatus = LearningStatus.idle;
  List<LearningTopic> _topics = [];
  String _topicsError = '';

  // Topic Details
  LearningStatus _detailsStatus = LearningStatus.idle;
  TopicDetails? _topicDetails;
  String _detailsError = '';

  // Getters
  LearningStatus get topicsStatus => _topicsStatus;
  List<LearningTopic> get topics => _topics;
  String get topicsError => _topicsError;
  bool get isLoadingTopics => _topicsStatus == LearningStatus.loading;

  LearningStatus get detailsStatus => _detailsStatus;
  TopicDetails? get topicDetails => _topicDetails;
  String get detailsError => _detailsError;
  bool get isLoadingDetails => _detailsStatus == LearningStatus.loading;

  /// Fetch all learning topics
  Future<void> fetchLearningTopics() async {
    _topicsStatus = LearningStatus.loading;
    _topicsError = '';
    notifyListeners();

    try {
      final response = await _repository.getLearningTopics();
      _topics = response.data;
      _topicsStatus = LearningStatus.loaded;
      debugPrint('✅ Learning topics fetched: ${_topics.length} topics');
    } catch (e, stackTrace) {
      _topicsStatus = LearningStatus.error;
      _topicsError = e.toString();
      debugPrint('❌ Error fetching learning topics: $e\n$stackTrace');
    }

    notifyListeners();
  }

  /// Fetch topic details with videos
  Future<void> fetchTopicDetails(int topicId) async {
    _detailsStatus = LearningStatus.loading;
    _detailsError = '';
    notifyListeners();

    try {
      final response = await _repository.getTopicDetails(topicId);
      _topicDetails = response.data;
      _detailsStatus = LearningStatus.loaded;
      debugPrint(
          '✅ Topic details fetched: ${_topicDetails?.name} with ${_topicDetails?.videos.length} videos');

      // Log each video's details for debugging
      for (int i = 0; i < (_topicDetails?.videos.length ?? 0); i++) {
        final video = _topicDetails!.videos[i];
        debugPrint('   Video $i: ${video.title}');
        debugPrint('     URL: ${video.videoUrl}');
        debugPrint('     Type: ${video.videoType}');
        debugPrint('     Duration: ${video.formattedDuration}');

        // Check if URL is valid
        if (video.videoUrl.isEmpty) {
          debugPrint('     ⚠️ WARNING: Empty video URL!');
        } else if (!video.videoUrl.startsWith('http')) {
          debugPrint('     ⚠️ WARNING: URL does not start with http!');
        }
      }
    } catch (e, stackTrace) {
      _detailsStatus = LearningStatus.error;
      _detailsError = e.toString();
      debugPrint('❌ Error fetching topic details: $e\n$stackTrace');
    }

    notifyListeners();
  }

  /// Clear topic details
  void clearTopicDetails() {
    _topicDetails = null;
    _detailsStatus = LearningStatus.idle;
    _detailsError = '';
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _topics = [];
    _topicsStatus = LearningStatus.idle;
    _topicsError = '';
    _topicDetails = null;
    _detailsStatus = LearningStatus.idle;
    _detailsError = '';
    notifyListeners();
  }
}
