class PaymentHistoryResponse {
  final int status;
  final String message;
  final PaymentHistoryData data;

  PaymentHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResponse(
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      data: PaymentHistoryData.fromJson(json['data'] ?? {}),
    );
  }
}

class PaymentHistoryData {
  final String period;
  final String periodName;
  final String startDate;
  final String endDate;
  final PaymentHistorySummary summary;
  final PaymentHistoryPagination pagination;
  final List<PaymentHistoryItem> payments;

  PaymentHistoryData({
    required this.period,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.pagination,
    required this.payments,
  });

  factory PaymentHistoryData.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryData(
      period: json['period'] ?? '',
      periodName: json['period_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      summary: PaymentHistorySummary.fromJson(json['summary'] ?? {}),
      pagination: PaymentHistoryPagination.fromJson(json['pagination'] ?? {}),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PaymentHistorySummary {
  final int totalPayments;
  final int totalAmount;
  final int approvedAmount;
  final int pendingAmount;

  PaymentHistorySummary({
    required this.totalPayments,
    required this.totalAmount,
    required this.approvedAmount,
    required this.pendingAmount,
  });

  factory PaymentHistorySummary.fromJson(Map<String, dynamic> json) {
    return PaymentHistorySummary(
      totalPayments: json['total_payments'] ?? 0,
      totalAmount: json['total_amount'] ?? 0,
      approvedAmount: json['approved_amount'] ?? 0,
      pendingAmount: json['pending_amount'] ?? 0,
    );
  }
}

class PaymentHistoryPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaymentHistoryPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaymentHistoryPagination.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryPagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 5,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class PaymentHistoryItem {
  final int id;
  final String transactionId;
  final String amount;
  final String status;
  final String? proofImage;
  final String? adminNotes;
  final String submittedAt;
  final String? approvedAt;

  PaymentHistoryItem({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.status,
    this.proofImage,
    this.adminNotes,
    required this.submittedAt,
    this.approvedAt,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'] ?? 0,
      transactionId: json['transaction_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'pending',
      proofImage: json['proof_image']?.toString(),
      adminNotes: json['admin_notes']?.toString(),
      submittedAt: json['submitted_at']?.toString() ?? '',
      approvedAt: json['approved_at']?.toString(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
