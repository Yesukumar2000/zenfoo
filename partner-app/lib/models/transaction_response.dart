import 'package:project/models/new_order.dart' show SettlementItem;

class TransactionResponse {
  int? status;
  String? message;
  TransactionData? data;

  TransactionResponse({this.status, this.message, this.data});

  TransactionResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'] is int
        ? json['status']
        : int.tryParse(json['status']?.toString() ?? '');
    message = json['message']?.toString();
    data = json['data'] != null ? TransactionData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['status'] = status;
    result['message'] = message;
    if (data != null) {
      result['data'] = data!.toJson();
    }
    return result;
  }
}

class TransactionData {
  List<TransactionItem>? transactions;
  TransactionSummary? summary;
  TransactionPagination? pagination;

  TransactionData({this.transactions, this.summary, this.pagination});

  TransactionData.fromJson(Map<String, dynamic> json) {
    if (json['transactions'] != null && json['transactions'] is List) {
      transactions = <TransactionItem>[];
      for (var v in (json['transactions'] as List)) {
        transactions!.add(TransactionItem.fromJson(v));
      }
    }
    summary = json['summary'] != null
        ? TransactionSummary.fromJson(json['summary'])
        : null;
    pagination = json['pagination'] != null
        ? TransactionPagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    if (transactions != null) {
      result['transactions'] = transactions!.map((v) => v.toJson()).toList();
    }
    if (summary != null) {
      result['summary'] = summary!.toJson();
    }
    if (pagination != null) {
      result['pagination'] = pagination!.toJson();
    }
    return result;
  }
}

class TransactionItem {
  int? id;
  int? orderId;
  int? orderItemId;
  String? itemName;
  String? type;
  String? typeLabel;
  bool? isCredit;
  double? amount;
  String? formattedAmount;
  double? payableAmount;
  String? formattedPayableAmount;
  bool? isRefundedToCustomer;
  double? adminCommission;
  double? vendorWaitCharge;
  String? message;
  bool? isPaidToSeller;
  String? paymentStatus;
  String? paidAt;
  String? paymentTransactionId;
  String? createdAt;
  List<SettlementItem>? settlementInfo;

  TransactionItem({
    this.id,
    this.orderId,
    this.orderItemId,
    this.itemName,
    this.type,
    this.typeLabel,
    this.isCredit,
    this.amount,
    this.formattedAmount,
    this.payableAmount,
    this.formattedPayableAmount,
    this.isRefundedToCustomer,
    this.adminCommission,
    this.vendorWaitCharge,
    this.message,
    this.isPaidToSeller,
    this.paymentStatus,
    this.paidAt,
    this.paymentTransactionId,
    this.createdAt,
    this.settlementInfo,
  });

  TransactionItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    orderId = json['order_id'] is int
        ? json['order_id']
        : int.tryParse(json['order_id']?.toString() ?? '');
    orderItemId = json['order_item_id'] is int
        ? json['order_item_id']
        : int.tryParse(json['order_item_id']?.toString() ?? '');
    itemName = json['item_name']?.toString();
    type = json['type']?.toString();
    typeLabel = json['type_label']?.toString();
    isCredit = json['is_credit'] is bool
        ? json['is_credit']
        : json['is_credit']?.toString().toLowerCase() == 'true';
    amount = json['amount'] is double
        ? json['amount']
        : double.tryParse(json['amount']?.toString() ?? '');
    formattedAmount = json['formatted_amount']?.toString();
    payableAmount = json['payable_amount'] is double
        ? json['payable_amount']
        : double.tryParse(json['payable_amount']?.toString() ?? '');
    formattedPayableAmount = json['formatted_payable_amount']?.toString();
    isRefundedToCustomer = json['is_refunded_to_customer'] is bool
        ? json['is_refunded_to_customer']
        : json['is_refunded_to_customer']?.toString().toLowerCase() == 'true';
    adminCommission = json['admin_commission'] is double
        ? json['admin_commission']
        : double.tryParse(json['admin_commission']?.toString() ?? '');
    vendorWaitCharge = json['vendor_wait_charge'] is double
        ? json['vendor_wait_charge']
        : double.tryParse(json['vendor_wait_charge']?.toString() ?? '');
    message = json['message']?.toString();
    isPaidToSeller = json['is_paid_to_seller'] is bool
        ? json['is_paid_to_seller']
        : json['is_paid_to_seller']?.toString().toLowerCase() == 'true';
    paymentStatus = json['payment_status']?.toString();
    paidAt = json['paid_at']?.toString();
    paymentTransactionId = json['payment_transaction_id']?.toString();
    createdAt = json['created_at']?.toString();
    settlementInfo = json['settlement_info'] != null &&
            json['settlement_info'] is List
        ? (json['settlement_info'] as List)
            .map((e) => SettlementItem.fromJson(e))
            .toList()
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['order_item_id'] = orderItemId;
    data['item_name'] = itemName;
    data['type'] = type;
    data['type_label'] = typeLabel;
    data['is_credit'] = isCredit;
    data['amount'] = amount;
    data['formatted_amount'] = formattedAmount;
    data['payable_amount'] = payableAmount;
    data['formatted_payable_amount'] = formattedPayableAmount;
    data['is_refunded_to_customer'] = isRefundedToCustomer;
    data['admin_commission'] = adminCommission;
    data['vendor_wait_charge'] = vendorWaitCharge;
    data['message'] = message;
    data['is_paid_to_seller'] = isPaidToSeller;
    data['payment_status'] = paymentStatus;
    data['paid_at'] = paidAt;
    data['payment_transaction_id'] = paymentTransactionId;
    data['created_at'] = createdAt;
    return data;
  }
}

class TransactionSummary {
  double? currentBalance;
  double? totalEarnings;
  double? totalDeductions;
  double? netEarnings;
  double? paidAmount;
  double? pendingAmount;
  double? adminDueAmount;
  double? totalCommission;

  TransactionSummary({
    this.currentBalance,
    this.totalEarnings,
    this.totalDeductions,
    this.netEarnings,
    this.paidAmount,
    this.pendingAmount,
    this.adminDueAmount,
    this.totalCommission,
  });

  TransactionSummary.fromJson(Map<String, dynamic> json) {
    currentBalance = json['current_balance'] is double
        ? json['current_balance']
        : double.tryParse(json['current_balance']?.toString() ?? '');
    totalEarnings = json['total_earnings'] is double
        ? json['total_earnings']
        : double.tryParse(json['total_earnings']?.toString() ?? '');
    totalDeductions = json['total_deductions'] is double
        ? json['total_deductions']
        : double.tryParse(json['total_deductions']?.toString() ?? '');
    netEarnings = json['net_earnings'] is double
        ? json['net_earnings']
        : double.tryParse(json['net_earnings']?.toString() ?? '');
    paidAmount = json['paid_amount'] is double
        ? json['paid_amount']
        : double.tryParse(json['paid_amount']?.toString() ?? '');
    pendingAmount = json['pending_amount'] is double
        ? json['pending_amount']
        : double.tryParse(json['pending_amount']?.toString() ?? '');
    adminDueAmount = json['admin_due_amount'] is double
        ? json['admin_due_amount']
        : double.tryParse(json['admin_due_amount']?.toString() ?? '');
    totalCommission = json['total_commission'] is double
        ? json['total_commission']
        : double.tryParse(json['total_commission']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_balance'] = currentBalance;
    data['total_earnings'] = totalEarnings;
    data['total_deductions'] = totalDeductions;
    data['net_earnings'] = netEarnings;
    data['paid_amount'] = paidAmount;
    data['pending_amount'] = pendingAmount;
    data['admin_due_amount'] = adminDueAmount;
    data['total_commission'] = totalCommission;
    return data;
  }
}

class TransactionPagination {
  int? total;
  int? perPage;
  int? currentPage;
  int? lastPage;
  bool? hasMore;

  TransactionPagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.hasMore,
  });

  TransactionPagination.fromJson(Map<String, dynamic> json) {
    total = json['total'] is int
        ? json['total']
        : int.tryParse(json['total']?.toString() ?? '');
    perPage = json['per_page'] is int
        ? json['per_page']
        : int.tryParse(json['per_page']?.toString() ?? '');
    currentPage = json['current_page'] is int
        ? json['current_page']
        : int.tryParse(json['current_page']?.toString() ?? '');
    lastPage = json['last_page'] is int
        ? json['last_page']
        : int.tryParse(json['last_page']?.toString() ?? '');
    hasMore = json['has_more'] is bool
        ? json['has_more']
        : json['has_more']?.toString().toLowerCase() == 'true';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    data['per_page'] = perPage;
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['has_more'] = hasMore;
    return data;
  }
}
