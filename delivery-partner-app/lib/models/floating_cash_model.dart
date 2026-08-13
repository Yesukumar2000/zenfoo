class FloatingCashResponse {
  final int status;
  final String message;
  final int total;
  final FloatingCashData data;

  FloatingCashResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory FloatingCashResponse.fromJson(Map<String, dynamic> json) {
    return FloatingCashResponse(
      status: (json['status'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      data: FloatingCashData.fromJson(json['data'] ?? {}),
    );
  }
}

class FloatingCashData {
  final String period;
  final String periodName;
  final String startDate;
  final String endDate;
  final String status;
  final CashSummary summary;
  final List<FloatingCashTransaction> transactions;

  FloatingCashData({
    required this.period,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.summary,
    required this.transactions,
  });

  factory FloatingCashData.fromJson(Map<String, dynamic> json) {
    return FloatingCashData(
      period: json['period'] ?? '',
      periodName: json['period_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? '',
      summary: CashSummary.fromJson(json['summary'] ?? {}),
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((t) => FloatingCashTransaction.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CashSummary {
  final int totalPendingCash;
  final int totalSettledCash;
  final int totalTransactions;

  CashSummary({
    required this.totalPendingCash,
    required this.totalSettledCash,
    required this.totalTransactions,
  });

  factory CashSummary.fromJson(Map<String, dynamic> json) {
    return CashSummary(
      totalPendingCash: (json['total_pending_cash'] as num?)?.toInt() ?? 0,
      totalSettledCash: (json['total_settled_cash'] as num?)?.toInt() ?? 0,
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
    );
  }
}

class FloatingCashTransaction {
  final int orderId;
  final String orderNumber;
  final String transactionDate;
  final String transactionType;
  final int adminCash;
  final bool isSettled;
  final String? settledAt;
  final OrderDetails orderDetails;

  FloatingCashTransaction({
    required this.orderId,
    required this.orderNumber,
    required this.transactionDate,
    required this.transactionType,
    required this.adminCash,
    required this.isSettled,
    this.settledAt,
    required this.orderDetails,
  });

  factory FloatingCashTransaction.fromJson(Map<String, dynamic> json) {
    return FloatingCashTransaction(
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      orderNumber: json['order_number']?.toString() ?? 'N/A',
      transactionDate: json['transaction_date']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? '',
      adminCash: (json['admin_cash'] as num?)?.toInt() ?? 0,
      isSettled: json['is_settled'] == true || json['is_settled'] == 1,
      settledAt: json['settled_at']?.toString(),
      orderDetails: OrderDetails.fromJson(json['order_details'] ?? {}),
    );
  }
}

class OrderDetails {
  final String customerName;
  final String deliveryAddress;

  OrderDetails({
    required this.customerName,
    required this.deliveryAddress,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      customerName: json['customer_name'] ?? 'N/A',
      deliveryAddress: json['delivery_address'] ?? 'N/A',
    );
  }
}
