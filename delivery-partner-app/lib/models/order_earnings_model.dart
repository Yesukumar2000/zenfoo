class OrderEarningsResponse {
  final int status;
  final String message;
  final int total;
  final OrderEarningsData data;

  OrderEarningsResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory OrderEarningsResponse.fromJson(Map<String, dynamic> json) {
    return OrderEarningsResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      data: OrderEarningsData.fromJson(json['data'] ?? {}),
    );
  }
}

class OrderEarningsData {
  final String period;
  final String periodName;
  final int isCancelled;
  final String startDate;
  final String endDate;
  final OrderEarningsSummary summary;
  final OrderEarningsPagination pagination;
  final List<OrderEarningItem> orders;

  OrderEarningsData({
    required this.period,
    required this.periodName,
    required this.isCancelled,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.pagination,
    required this.orders,
  });

  factory OrderEarningsData.fromJson(Map<String, dynamic> json) {
    return OrderEarningsData(
      period: json['period'] ?? '',
      periodName: json['period_name'] ?? '',
      isCancelled: json['is_cancelled'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      summary: OrderEarningsSummary.fromJson(json['summary'] ?? {}),
      pagination: OrderEarningsPagination.fromJson(json['pagination'] ?? {}),
      orders: (json['orders'] as List<dynamic>?)
              ?.map((o) => OrderEarningItem.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderEarningsSummary {
  final int totalOrders;
  final num totalDriverEarnings;
  final num totalDeliveryCharge;
  final num totalDeliveryTip;
  final num totalMultiOrderBonus;
  final num totalRainSurcharge;
  final num totalVendorWaitCharge;

  OrderEarningsSummary({
    required this.totalOrders,
    required this.totalDriverEarnings,
    required this.totalDeliveryCharge,
    required this.totalDeliveryTip,
    required this.totalMultiOrderBonus,
    required this.totalRainSurcharge,
    this.totalVendorWaitCharge = 0,
  });

  factory OrderEarningsSummary.fromJson(Map<String, dynamic> json) {
    return OrderEarningsSummary(
      totalOrders: json['total_orders'] ?? 0,
      totalDriverEarnings: json['total_driver_earnings'] ?? 0,
      totalDeliveryCharge: json['total_delivery_charge'] ?? 0,
      totalDeliveryTip: json['total_delivery_tip'] ?? 0,
      totalMultiOrderBonus: json['total_multi_order_bonus'] ?? 0,
      totalRainSurcharge: json['total_rain_surcharge'] ?? 0,
      totalVendorWaitCharge: json['total_vendor_wait_charge'] ?? 0,
    );
  }
}

class OrderEarningsPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  OrderEarningsPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory OrderEarningsPagination.fromJson(Map<String, dynamic> json) {
    return OrderEarningsPagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 5,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class OrderEarningItem {
  final int orderId;
  final int orderNumber;
  final String orderDate;
  final String? customerName;
  final List<String> storeNames;
  final List<int> storeSellers;
  final String? deliveryAddress;
  final bool isMultiOrder;
  final double bonusAmount;
  final double deliveryCharge;
  final double deliveryTip;
  final double rainSurcharge;
  final double vendorWaitCharge;
  final double driverEarnings;
  final String orderStatus;

  OrderEarningItem({
    required this.orderId,
    required this.orderNumber,
    required this.orderDate,
    this.customerName,
    required this.storeNames,
    required this.storeSellers,
    this.deliveryAddress,
    required this.isMultiOrder,
    required this.bonusAmount,
    required this.deliveryCharge,
    required this.deliveryTip,
    required this.rainSurcharge,
    this.vendorWaitCharge = 0.0,
    required this.driverEarnings,
    required this.orderStatus,
  });

  factory OrderEarningItem.fromJson(Map<String, dynamic> json) {
    return OrderEarningItem(
      orderId: json['order_id'] ?? 0,
      orderNumber: json['order_number'] ?? 0,
      orderDate: json['order_date'] ?? '',
      customerName: json['customer_name'],
      storeNames: (json['store_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      storeSellers: (json['store_sellers'] as List<dynamic>?)
              ?.map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0)
              .toList() ??
          [],
      deliveryAddress: json['delivery_address'],
      isMultiOrder: json['is_multi_order'] ?? false,
      bonusAmount: (json['bonus_amount'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      deliveryTip: (json['delivery_tip'] ?? 0).toDouble(),
      rainSurcharge: (json['rain_surcharge'] ?? 0).toDouble(),
      vendorWaitCharge: (json['vendor_wait_charge'] ?? 0).toDouble(),
      driverEarnings: (json['driver_earnings'] ?? 0).toDouble(),
      orderStatus: json['order_status']?.toString() ?? '',
    );
  }
}
