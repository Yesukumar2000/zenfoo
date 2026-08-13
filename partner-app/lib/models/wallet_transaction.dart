class WalletTransaction {
  final int id;
  final int sellerId;
  final int? orderId;
  final int? orderItemId;
  final String type;
  final double amount;
  final String formattedAmount;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? message;
  final String? adminNote;
  final int status;
  final int? processedBy;
  final String createdAt;
  final String updatedAt;

  WalletTransaction({
    required this.id,
    required this.sellerId,
    this.orderId,
    this.orderItemId,
    required this.type,
    required this.amount,
    required this.formattedAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.message,
    this.adminNote,
    required this.status,
    this.processedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      orderId: json['order_id'],
      orderItemId: json['order_item_id'],
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      formattedAmount: json['formatted_amount'] ?? '',
      balanceBefore: double.tryParse(json['balance_before'].toString()) ?? 0.0,
      balanceAfter: double.tryParse(json['balance_after'].toString()) ?? 0.0,
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      message: json['message'],
      adminNote: json['admin_note'],
      status: json['status'] ?? 1,
      processedBy: json['processed_by'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isCredit =>
      type == 'order_commission' || type == 'credit' || type == 'refund';
  bool get isDebit =>
      type == 'withdrawal' || type == 'debit' || type == 'adjustment';

  // Compatibility getter for existing UI
  String get dateTime => createdAt;
}

class WalletOverview {
  final double currentBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final double pendingWithdrawals;
  final List<WalletTransaction> recentTransactions;

  WalletOverview({
    required this.currentBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.pendingWithdrawals,
    required this.recentTransactions,
  });

  factory WalletOverview.fromJson(Map<String, dynamic> json) {
    return WalletOverview(
      currentBalance:
          double.tryParse(json['current_balance'].toString()) ?? 0.0,
      totalEarned: double.tryParse(json['total_earned'].toString()) ?? 0.0,
      totalWithdrawn:
          double.tryParse(json['total_withdrawn'].toString()) ?? 0.0,
      pendingWithdrawals:
          double.tryParse(json['pending_withdrawals'].toString()) ?? 0.0,
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)
              ?.map((t) => WalletTransaction.fromJson(t))
              .toList() ??
          [],
    );
  }
}

class WalletTransactionResponse {
  final int status;
  final String message;
  final WalletOverview? data;

  WalletTransactionResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory WalletTransactionResponse.fromJson(Map<String, dynamic> json) {
    return WalletTransactionResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? WalletOverview.fromJson(json['data']) : null,
    );
  }
}

class EarningsPeriod {
  final double totalCredits;
  final double totalDebits;
  final double netEarnings;
  final int orderCount;
  final double averagePerOrder;

  EarningsPeriod({
    required this.totalCredits,
    required this.totalDebits,
    required this.netEarnings,
    required this.orderCount,
    required this.averagePerOrder,
  });

  factory EarningsPeriod.fromJson(Map<String, dynamic> json) {
    return EarningsPeriod(
      totalCredits: double.tryParse(json['total_credits'].toString()) ?? 0.0,
      totalDebits: double.tryParse(json['total_debits'].toString()) ?? 0.0,
      netEarnings: double.tryParse(json['net_earnings'].toString()) ?? 0.0,
      orderCount: json['order_count'] ?? 0,
      averagePerOrder:
          double.tryParse(json['average_per_order'].toString()) ?? 0.0,
    );
  }
}

class AllTimeEarnings extends EarningsPeriod {
  final double totalWithdrawals;
  final double currentBalance;

  AllTimeEarnings({
    required super.totalCredits,
    required super.totalDebits,
    required super.netEarnings,
    required super.orderCount,
    required super.averagePerOrder,
    required this.totalWithdrawals,
    required this.currentBalance,
  });

  factory AllTimeEarnings.fromJson(Map<String, dynamic> json) {
    return AllTimeEarnings(
      totalCredits: double.tryParse(json['total_credits'].toString()) ?? 0.0,
      totalDebits: double.tryParse(json['total_debits'].toString()) ?? 0.0,
      netEarnings: double.tryParse(json['net_earnings'].toString()) ?? 0.0,
      orderCount: json['order_count'] ?? 0,
      averagePerOrder:
          double.tryParse(json['average_per_order'].toString()) ?? 0.0,
      totalWithdrawals:
          double.tryParse(json['total_withdrawals'].toString()) ?? 0.0,
      currentBalance:
          double.tryParse(json['current_balance'].toString()) ?? 0.0,
    );
  }
}

class EarningsSummary {
  final EarningsPeriod today;
  final EarningsPeriod thisMonth;
  final EarningsPeriod thisYear;
  final AllTimeEarnings allTime;

  EarningsSummary({
    required this.today,
    required this.thisMonth,
    required this.thisYear,
    required this.allTime,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      today: EarningsPeriod.fromJson(json['today'] ?? {}),
      thisMonth: EarningsPeriod.fromJson(json['this_month'] ?? {}),
      thisYear: EarningsPeriod.fromJson(json['this_year'] ?? {}),
      allTime: AllTimeEarnings.fromJson(json['all_time'] ?? {}),
    );
  }
}
