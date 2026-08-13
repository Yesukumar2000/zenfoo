import 'package:zenfoo_partner/utils/safe_parser.dart';

class PayoutHistoryResponse {
  final String period;
  final String periodName;
  final String startDate;
  final String endDate;
  final PayoutSummary payoutSummary;
  final List<PayoutTransaction> transactions;

  PayoutHistoryResponse({
    required this.period,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.payoutSummary,
    required this.transactions,
  });

  factory PayoutHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = SafeParser.parseMap(json['data']);

    return PayoutHistoryResponse(
      period: SafeParser.parseString(data['period']),
      periodName: SafeParser.parseString(data['period_name']),
      startDate: SafeParser.parseString(data['start_date']),
      endDate: SafeParser.parseString(data['end_date']),
      payoutSummary: PayoutSummary.fromJson(SafeParser.parseMap(data['payout_summary'])),
      transactions: (SafeParser.parseList<Map<String, dynamic>>(data['transactions']))
          .map((t) => PayoutTransaction.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PayoutSummary {
  final double totalPaidOut;
  final int totalTransactions;
  final double averagePayoutAmount;

  PayoutSummary({
    required this.totalPaidOut,
    required this.totalTransactions,
    required this.averagePayoutAmount,
  });

  factory PayoutSummary.fromJson(Map<String, dynamic> json) {
    return PayoutSummary(
      totalPaidOut: SafeParser.parseDouble(json['total_paid_out']),
      totalTransactions: SafeParser.parseInt(json['total_transactions']),
      averagePayoutAmount: SafeParser.parseDouble(json['average_payout_amount']),
    );
  }
}

class PayoutTransaction {
  final int id;
  final int orderId;
  final String type;
  final double amount;
  final String payoutReference;
  final String status;
  final String message;
  final String transactionDate;

  PayoutTransaction({
    required this.id,
    required this.orderId,
    required this.type,
    required this.amount,
    required this.payoutReference,
    required this.status,
    required this.message,
    required this.transactionDate,
  });

  factory PayoutTransaction.fromJson(Map<String, dynamic> json) {
    return PayoutTransaction(
      id: SafeParser.parseInt(json['id']),
      orderId: SafeParser.parseInt(json['order_id']),
      type: SafeParser.parseString(json['type']),
      amount: SafeParser.parseDouble(json['amount']),
      payoutReference: SafeParser.parseString(json['payout_reference']),
      status: SafeParser.parseString(json['status']),
      message: SafeParser.parseString(json['message']),
      transactionDate: SafeParser.parseString(json['transaction_date']),
    );
  }
}
