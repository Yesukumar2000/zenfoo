class PayoutSectionsResponse {
  final int status;
  final String message;
  final PayoutSectionsData? data;

  PayoutSectionsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory PayoutSectionsResponse.fromJson(Map<String, dynamic> json) {
    return PayoutSectionsResponse(
      status: json['status'] is int
          ? json['status']
          : int.tryParse(json['status'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? PayoutSectionsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PayoutSectionsData {
  final String period;
  final String periodName;
  final String startDate;
  final String endDate;
  final int totalEarnings;
  final double grandTotal;
  final List<PayoutSection> sections;

  PayoutSectionsData({
    required this.period,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.totalEarnings,
    required this.grandTotal,
    required this.sections,
  });

  factory PayoutSectionsData.fromJson(Map<String, dynamic> json) {
    return PayoutSectionsData(
      period: json['period']?.toString() ?? '',
      periodName: json['period_name']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalEarnings: json['total_earnings'] is int
          ? json['total_earnings']
          : int.tryParse(json['total_earnings'].toString()) ?? 0,
      grandTotal: (json['grand_total'] is num)
          ? (json['grand_total'] as num).toDouble()
          : double.tryParse(json['grand_total'].toString()) ?? 0,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => PayoutSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PayoutSection {
  final String key;
  final String label;
  final double total;
  final int count;
  final List<PayoutSectionTransaction> transactions;

  PayoutSection({
    required this.key,
    required this.label,
    required this.total,
    required this.count,
    required this.transactions,
  });

  factory PayoutSection.fromJson(Map<String, dynamic> json) {
    return PayoutSection(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.tryParse(json['total'].toString()) ?? 0,
      count: json['count'] is int
          ? json['count']
          : int.tryParse(json['count'].toString()) ?? 0,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) =>
                  PayoutSectionTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PayoutSectionTransaction {
  final int id;
  final int? orderId;
  final double amount;
  final String message;
  final String? payoutReference;
  final int isSettled;
  final String? settledAt;
  final String date;

  PayoutSectionTransaction({
    required this.id,
    this.orderId,
    required this.amount,
    required this.message,
    this.payoutReference,
    required this.isSettled,
    this.settledAt,
    required this.date,
  });

  factory PayoutSectionTransaction.fromJson(Map<String, dynamic> json) {
    return PayoutSectionTransaction(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      orderId: json['order_id'] != null
          ? (json['order_id'] is int
              ? json['order_id']
              : int.tryParse(json['order_id'].toString()))
          : null,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount'].toString()) ?? 0,
      message: json['message']?.toString() ?? '',
      payoutReference: json['payout_reference']?.toString(),
      isSettled: json['is_settled'] is int
          ? json['is_settled']
          : int.tryParse(json['is_settled'].toString()) ?? 0,
      settledAt: json['settled_at']?.toString(),
      date: json['date']?.toString() ?? '',
    );
  }
}
