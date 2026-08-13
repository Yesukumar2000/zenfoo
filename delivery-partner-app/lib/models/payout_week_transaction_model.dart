// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

PayoutWeekTransactionModel payoutWeekTransactionModelFromJson(String str) =>
    PayoutWeekTransactionModel.fromJson(json.decode(str));

String payoutWeekTransactionModelToJson(PayoutWeekTransactionModel data) =>
    json.encode(data.toJson());

class PayoutWeekTransactionModel {
  final int? status;
  final String? message;
  final int? total;
  final PayoutWeekTransactionData? data;

  PayoutWeekTransactionModel({
    this.status,
    this.message,
    this.total,
    this.data,
  });

  factory PayoutWeekTransactionModel.fromJson(Map<String, dynamic> json) =>
      PayoutWeekTransactionModel(
        status: json["status"],
        message: json["message"],
        total: json["total"],
        data: json["data"] == null
            ? null
            : PayoutWeekTransactionData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": data?.toJson(),
      };
}

class PayoutWeekTransactionData {
  final String? week;
  final String? type;
  final DateTime? weekStart;
  final DateTime? weekEnd;
  final String? weekLabel;
  final Summary? summary;
  final DeliveryBoy? deliveryBoy;

  PayoutWeekTransactionData({
    this.week,
    this.type,
    this.weekStart,
    this.weekEnd,
    this.weekLabel,
    this.summary,
    this.deliveryBoy,
  });

  factory PayoutWeekTransactionData.fromJson(Map<String, dynamic> json) =>
      PayoutWeekTransactionData(
        week: json["week"],
        type: json["type"],
        weekStart: json["week_start"] == null
            ? null
            : DateTime.parse(json["week_start"]),
        weekEnd:
            json["week_end"] == null ? null : DateTime.parse(json["week_end"]),
        weekLabel: json["week_label"],
        summary:
            json["summary"] == null ? null : Summary.fromJson(json["summary"]),
        deliveryBoy: json["delivery_boy"] == null
            ? null
            : DeliveryBoy.fromJson(json["delivery_boy"]),
      );

  Map<String, dynamic> toJson() => {
        "week": week,
        "type": type,
        "week_start":
            "${weekStart!.year.toString().padLeft(4, '0')}-${weekStart!.month.toString().padLeft(2, '0')}-${weekStart!.day.toString().padLeft(2, '0')}",
        "week_end":
            "${weekEnd!.year.toString().padLeft(4, '0')}-${weekEnd!.month.toString().padLeft(2, '0')}-${weekEnd!.day.toString().padLeft(2, '0')}",
        "week_label": weekLabel,
        "summary": summary?.toJson(),
        "delivery_boy": deliveryBoy?.toJson(),
      };
}

class DeliveryBoy {
  final int? id;
  final String? name;

  DeliveryBoy({
    this.id,
    this.name,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) => DeliveryBoy(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class Summary {
  final int? totalTransactions;
  final String? paymentMode;
  final List<String>? paidBankNumber;
  final num? totalDriverEarnings;
  final List<Transaction>? transactions;

  Summary({
    this.totalTransactions,
    this.paymentMode,
    this.paidBankNumber,
    this.totalDriverEarnings,
    this.transactions,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        totalTransactions: json["total_transactions"],
        paymentMode: json["payment_mode"],
        paidBankNumber: json["paid_bank_number"] == null
            ? []
            : List<String>.from(json["paid_bank_number"]!.map((x) => x)),
        totalDriverEarnings: json["total_driver_earnings"],
        transactions: json["transactions"] == null
            ? []
            : List<Transaction>.from(
                json["transactions"]!.map((x) => Transaction.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "total_transactions": totalTransactions,
        "payment_mode": paymentMode,
        "paid_bank_number": paidBankNumber == null
            ? []
            : List<dynamic>.from(paidBankNumber!.map((x) => x)),
        "total_driver_earnings": totalDriverEarnings,
        "transactions": transactions == null
            ? []
            : List<dynamic>.from(transactions!.map((x) => x.toJson())),
      };
}

class Transaction {
  final int? id;
  final int? orderId;
  final num? driverEarnings;
  final num? amount;
  final String? type;
  final String? message;
  final String? bankAccNumber;
  final DateTime? settledAt;
  final DateTime? createdAt;

  Transaction({
    this.id,
    this.orderId,
    this.driverEarnings,
    this.amount,
    this.type,
    this.message,
    this.bankAccNumber,
    this.settledAt,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json["id"],
        orderId: json["order_id"],
        driverEarnings: json["driver_earnings"],
        amount: json["amount"],
        type: json["type"],
        message: json["message"],
        bankAccNumber: json["bank_acc_number"],
        settledAt: json["settled_at"] == null
            ? null
            : DateTime.parse(json["settled_at"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "order_id": orderId,
        "driver_earnings": driverEarnings,
        "amount": amount,
        "type": type,
        "message": message,
        "bank_acc_number": bankAccNumber,
        "settled_at": settledAt?.toIso8601String(),
        "created_at": createdAt?.toIso8601String(),
      };
}
