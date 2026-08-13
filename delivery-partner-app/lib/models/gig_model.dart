class Gig {
  final int gigId;
  final String gigType; // morning, afternoon, evening, night
  final String displayName;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Gig({
    required this.gigId,
    required this.gigType,
    required this.displayName,
    required this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      gigId: json['gig_id'] is String
          ? int.parse(json['gig_id'])
          : json['gig_id'],
      gigType: json['gig_type'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gig_id': gigId,
      'gig_type': gigType,
      'display_name': displayName,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
