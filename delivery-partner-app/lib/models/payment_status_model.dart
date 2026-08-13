class PaymentStatusResponse {
  final int status;
  final String message;
  final int total;
  final PaymentStatusData? data;

  PaymentStatusResponse({
    required this.status,
    required this.message,
    required this.total,
    this.data,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      data: json['data'] != null
          ? PaymentStatusData.fromJson(json['data'])
          : null,
    );
  }

  bool get hasData => status == 1 && data != null;
}

class PaymentStatusData {
  final bool isBlocked;
  final bool canAcceptOrders;
  final String responseType; // ADMIN_CASH_PENDING, etc.
  final List<BlockingReason> blockingReasons;
  final RequiredAction? requiredAction;
  final PaymentSummary? paymentSummary;

  PaymentStatusData({
    required this.isBlocked,
    required this.canAcceptOrders,
    required this.responseType,
    required this.blockingReasons,
    this.requiredAction,
    this.paymentSummary,
  });

  factory PaymentStatusData.fromJson(Map<String, dynamic> json) {
    return PaymentStatusData(
      isBlocked: json['is_blocked'] ?? false,
      canAcceptOrders: json['can_accept_orders'] ?? false,
      responseType: json['response_type'] ?? '',
      blockingReasons: (json['blocking_reasons'] as List?)
              ?.map((e) => BlockingReason.fromJson(e))
              .toList() ??
          [],
      requiredAction: json['required_action'] != null
          ? RequiredAction.fromJson(json['required_action'])
          : null,
      paymentSummary: json['payment_summary'] != null
          ? PaymentSummary.fromJson(json['payment_summary'])
          : null,
    );
  }
}

class BlockingReason {
  final String type;
  final String title;
  final String message;
  final double amount;
  final int transactionCount;
  final String action;

  BlockingReason({
    required this.type,
    required this.title,
    required this.message,
    required this.amount,
    required this.transactionCount,
    required this.action,
  });

  factory BlockingReason.fromJson(Map<String, dynamic> json) {
    return BlockingReason(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] ?? 0,
      action: json['action'] ?? '',
    );
  }
}

class RequiredAction {
  final String type;
  final String title;
  final String description;
  final double amount;
  final int transactionCount;

  RequiredAction({
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    required this.transactionCount,
  });

  factory RequiredAction.fromJson(Map<String, dynamic> json) {
    return RequiredAction(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] ?? 0,
    );
  }
}

class PaymentSummary {
  final double unsettledAdminCash;
  final int unsettledTransactionCount;
  final double totalSettledAmount;

  PaymentSummary({
    required this.unsettledAdminCash,
    required this.unsettledTransactionCount,
    required this.totalSettledAmount,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      unsettledAdminCash:
          (json['unsettled_admin_cash'] as num?)?.toDouble() ?? 0.0,
      unsettledTransactionCount: json['unsettled_transaction_count'] ?? 0,
      totalSettledAmount:
          (json['total_settled_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
