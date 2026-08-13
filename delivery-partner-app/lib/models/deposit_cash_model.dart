import 'dart:convert';

DepositCashModel depositCashModelFromJson(String str) =>
    DepositCashModel.fromJson(json.decode(str));

String depositCashModelToJson(DepositCashModel data) =>
    json.encode(data.toJson());

class DepositCashModel {
  final int? status;
  final String? message;
  final int? total;
  final DepositCashData? data;

  DepositCashModel({
    this.status,
    this.message,
    this.total,
    this.data,
  });

  factory DepositCashModel.fromJson(Map<String, dynamic> json) =>
      DepositCashModel(
        status: json["status"],
        message: json["message"],
        total: json["total"],
        data: json["data"] == null
            ? null
            : DepositCashData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": data?.toJson(),
      };
}

class DepositCashData {
  final Summary? summary;
  final Pagination? pagination;
  final List<Transaction>? transactions;

  DepositCashData({
    this.summary,
    this.pagination,
    this.transactions,
  });

  factory DepositCashData.fromJson(Map<String, dynamic> json) =>
      DepositCashData(
        summary:
            json["summary"] == null ? null : Summary.fromJson(json["summary"]),
        pagination: json["pagination"] == null
            ? null
            : Pagination.fromJson(json["pagination"]),
        transactions: json["transactions"] == null
            ? []
            : List<Transaction>.from(
                json["transactions"]!.map((x) => Transaction.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "summary": summary?.toJson(),
        "pagination": pagination?.toJson(),
        "transactions": transactions == null
            ? []
            : List<dynamic>.from(transactions!.map((x) => x.toJson())),
      };
}

class Pagination {
  final int? currentPage;
  final int? perPage;
  final int? totalItems;
  final int? totalPages;

  Pagination({
    this.currentPage,
    this.perPage,
    this.totalItems,
    this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        currentPage: (json["current_page"] as num?)?.toInt(),
        perPage: (json["per_page"] as num?)?.toInt(),
        totalItems: (json["total_items"] as num?)?.toInt(),
        totalPages: (json["total_pages"] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        "current_page": currentPage,
        "per_page": perPage,
        "total_items": totalItems,
        "total_pages": totalPages,
      };
}

class Summary {
  final double totalHandCash;
  final double settledWithAdminTotal;
  final double notSettledWithAdminTotal;
  final dynamic notSettleCount;
  

  Summary({
    required this.totalHandCash,
    required this.settledWithAdminTotal,
    required this.notSettledWithAdminTotal,
    required this.notSettleCount,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
        totalHandCash: (json["total_hand_cash"] as num?)?.toDouble() ?? 0,
        settledWithAdminTotal:
            (json["settled_with_admin_total"] as num?)?.toDouble() ?? 0,
        notSettledWithAdminTotal:
            (json["not_settled_with_admin_total"] as num?)?.toDouble() ?? 0,
        notSettleCount: (json["not_settled_count"] ?? json["not_settle_count"]) as dynamic,
      );

  Map<String, dynamic> toJson() => {
        "total_hand_cash": totalHandCash,
        "settled_with_admin_total": settledWithAdminTotal,
        "not_settled_with_admin_total": notSettledWithAdminTotal,
        "not_settle_count": notSettleCount,
      };
}

class Transaction {
  final int? id;
  final int? isHandCash;
  final int? userId;
  final String? orderId;
  final int? deliveryBoyId;
  final String? type;
  final double amount;
  final double deliveryCharge;
  final double deliveryTip;
  final double bonusAmount;
  final double driverEarnings;
  final double adminCash;
  final String? status;
  final String? message;
  final DateTime? transactionDate;
  final int? settledWithAdmin;
  final dynamic settledAt;
  final String? payoutReference;
  final dynamic bankAccNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    this.isHandCash,
    this.userId,
    this.orderId,
    this.deliveryBoyId,
    this.type,
    this.amount = 0,
    this.deliveryCharge = 0,
    this.deliveryTip = 0,
    this.bonusAmount = 0,
    this.driverEarnings = 0,
    this.adminCash = 0,
    this.status,
    this.message,
    this.transactionDate,
    this.settledWithAdmin,
    this.settledAt,
    this.payoutReference,
    this.bankAccNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: (json["id"] as num?)?.toInt(),
        isHandCash: (json["is_hand_cash"] as num?)?.toInt(),
        userId: (json["user_id"] as num?)?.toInt(),
        orderId: json["order_id"]?.toString(),
        deliveryBoyId: (json["delivery_boy_id"] as num?)?.toInt(),
        type: json["type"],
        amount: (json["amount"] as num?)?.toDouble() ?? 0,
        deliveryCharge: (json["delivery_charge"] as num?)?.toDouble() ?? 0,
        deliveryTip: (json["delivery_tip"] as num?)?.toDouble() ?? 0,
        bonusAmount: (json["bonus_amount"] as num?)?.toDouble() ?? 0,
        driverEarnings: (json["driver_earnings"] as num?)?.toDouble() ?? 0,
        adminCash: (json["admin_cash"] as num?)?.toDouble() ?? 0,
        status: json["status"],
        message: json["message"],
        transactionDate: json["transaction_date"] == null
            ? null
            : DateTime.tryParse(json["transaction_date"]),
        settledWithAdmin: (json["settled_with_admin"] as num?)?.toInt(),
        settledAt: json["settled_at"],
        payoutReference: json["payout_reference"],
        bankAccNumber: json["bank_acc_number"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.tryParse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.tryParse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "is_hand_cash": isHandCash,
        "user_id": userId,
        "order_id": orderId,
        "delivery_boy_id": deliveryBoyId,
        "type": type,
        "amount": amount,
        "delivery_charge": deliveryCharge,
        "delivery_tip": deliveryTip,
        "bonus_amount": bonusAmount,
        "driver_earnings": driverEarnings,
        "admin_cash": adminCash,
        "status": status,
        "message": message,
        "transaction_date": transactionDate?.toIso8601String(),
        "settled_with_admin": settledWithAdmin,
        "settled_at": settledAt,
        "payout_reference": payoutReference,
        "bank_acc_number": bankAccNumber,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
