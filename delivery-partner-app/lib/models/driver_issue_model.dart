class DriverIssue {
  final int id;
  final String issueType;
  final List<int> issueIds;
  final String description;
  final List<String> attachments;
  final String status;
  final String? adminMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverIssue({
    required this.id,
    required this.issueType,
    required this.issueIds,
    required this.description,
    required this.attachments,
    required this.status,
    this.adminMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverIssue.fromJson(Map<String, dynamic> json) {
    return DriverIssue(
      id: json['id'] ?? 0,
      issueType: json['issue_type'] ?? '',
      issueIds: (json['issue_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      description: json['description'] ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] ?? 'pending',
      adminMessage: json['admin_message'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get issueTypeDisplay {
    switch (issueType) {
      case 'incorrect_payout':
        return 'Incorrect Payout';
      case 'incentive':
        return 'Incentive Issue';
      case 'multi_order':
        return 'Multi-order Issue';
      case 'joining_bonus':
        return 'Joining Bonus';
      case 'order_earning':
        return 'Order Earning';
      case 'pocketing_issue':
        return 'Pocketing Issue';
      case 'not_getting_order_issue':
        return 'Not Getting Orders';
      default:
        return issueType.replaceAll('_', ' ');
    }
  }
}
