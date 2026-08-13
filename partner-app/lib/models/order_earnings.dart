import 'package:project/models/order_detail_item.dart';
import 'package:project/models/new_order.dart' show SettlementItem;

class SellerEarningsResponse {
  int? status;
  String? message;
  SellerEarningsData? data;

  SellerEarningsResponse({this.status, this.message, this.data});

  factory SellerEarningsResponse.fromJson(Map<String, dynamic> json) {
    return SellerEarningsResponse(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? SellerEarningsData.fromJson(json['data'])
          : null,
    );
  }
}

class SellerEarningsData {
  List<OrderEarnings>? today;
  List<OrderEarnings>? weekly;
  List<OrderEarnings>? monthly;
  List<OrderEarnings>? yearly;
  List<OrderEarnings>? total;

  SellerEarningsData(
      {this.today, this.weekly, this.monthly, this.yearly, this.total});

  factory SellerEarningsData.fromJson(Map<String, dynamic> json) {
    return SellerEarningsData(
      today: json['today'] != null
          ? (json['today'] as List)
              .map((e) => OrderEarnings.fromJson(e))
              .toList()
          : null,
      weekly: json['weekly'] != null
          ? (json['weekly'] as List)
              .map((e) => OrderEarnings.fromJson(e))
              .toList()
          : null,
      monthly: json['monthly'] != null
          ? (json['monthly'] as List)
              .map((e) => OrderEarnings.fromJson(e))
              .toList()
          : null,
      yearly: json['yearly'] != null
          ? (json['yearly'] as List)
              .map((e) => OrderEarnings.fromJson(e))
              .toList()
          : null,
      total: json['total'] != null
          ? (json['total'] as List)
              .map((e) => OrderEarnings.fromJson(e))
              .toList()
          : null,
    );
  }
}

class OrderEarnings {
  final String dateRange;
  final num totalAmount;
  final List<EarningsTransaction> transactions;
  bool isExpanded;

  OrderEarnings({
    required this.dateRange,
    required this.totalAmount,
    required this.transactions,
    this.isExpanded = false,
  });

  factory OrderEarnings.fromJson(Map<String, dynamic> json) {
    return OrderEarnings(
      dateRange: json['date_range'] ?? '',
      totalAmount: json['total_amount'] ?? 0,
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((e) => EarningsTransaction.fromJson(e))
              .toList()
          : [],
      isExpanded: false,
    );
  }

  // Format total amount for display
  String get formattedAmount => '₹${totalAmount.toStringAsFixed(2)}';
}

class EarningsTransaction {
  final String orderId;
  final String date;
  final num amount;
  final OrderDetailItem? orderDetails;
  final List<SettlementItem>? settlementInfo;

  EarningsTransaction({
    required this.orderId,
    required this.date,
    required this.amount,
    this.orderDetails,
    this.settlementInfo,
  });

  factory EarningsTransaction.fromJson(Map<String, dynamic> json) {
    return EarningsTransaction(
      orderId: json['order_id']?.toString() ?? '',
      date: json['date'] ?? '',
      amount: json['amount'] ?? 0,
      orderDetails: json['order_details'] != null
          ? OrderDetailItem.fromJson(json['order_details'])
          : null,
      settlementInfo: json['settlement_info'] != null
          ? (json['settlement_info'] as List)
              .map((e) => SettlementItem.fromJson(e))
              .toList()
          : null,
    );
  }

  // Format order ID for display
  String get formattedId => 'ID #$orderId';

  // Format amount for display
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
}
