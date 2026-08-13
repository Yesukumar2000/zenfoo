class LearningTopic {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int videosCount;

  LearningTopic({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.videosCount,
  });

  factory LearningTopic.fromJson(Map<String, dynamic> json) {
    return LearningTopic(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      videosCount: json['videos_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'videos_count': videosCount,
    };
  }
}

class LearningVideo {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final String videoType;
  final String thumbnailUrl;
  final int duration;
  final String formattedDuration;

  LearningVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.videoType,
    required this.thumbnailUrl,
    required this.duration,
    required this.formattedDuration,
  });

  factory LearningVideo.fromJson(Map<String, dynamic> json) {
    return LearningVideo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['video_url'] ?? '',
      videoType: json['video_type'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      duration: json['duration'] ?? 0,
      formattedDuration: json['formatted_duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'video_type': videoType,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'formatted_duration': formattedDuration,
    };
  }
}

class TopicDetails {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int videosCount;
  final List<LearningVideo> videos;

  TopicDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.videosCount,
    required this.videos,
  });

  factory TopicDetails.fromJson(Map<String, dynamic> json) {
    return TopicDetails(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      videosCount: json['videos_count'] ?? 0,
      videos: (json['videos'] as List<dynamic>?)
              ?.map((video) => LearningVideo.fromJson(video))
              .toList() ??
          [],
    );
  }
}

class LearningTopicsResponse {
  final bool status;
  final String message;
  final int total;
  final List<LearningTopic> data;

  LearningTopicsResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory LearningTopicsResponse.fromJson(Map<String, dynamic> json) {
    return LearningTopicsResponse(
      status: json['status'] == 1 || json['status'] == true,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((topic) => LearningTopic.fromJson(topic))
              .toList() ??
          [],
    );
  }
}

class TopicDetailsResponse {
  final bool status;
  final String message;
  final int total;
  final TopicDetails data;

  TopicDetailsResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory TopicDetailsResponse.fromJson(Map<String, dynamic> json) {
    return TopicDetailsResponse(
      status: json['status'] == 1 || json['status'] == true,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      data: TopicDetails.fromJson(json['data']),
    );
  }
}
