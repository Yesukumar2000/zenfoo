class Suggestion {
  final int id;
  final int customerId;
  final String suggestion;
  final String? adminResponse;
  final String createdAt;

  Suggestion({
    required this.id,
    required this.customerId,
    required this.suggestion,
    this.adminResponse,
    required this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'],
      customerId: json['customer_id'],
      suggestion: json['suggestion'].toString(),
      adminResponse: json['admin_response']?.toString(),
      createdAt: json['created_at'].toString(),
    );
  }
}
