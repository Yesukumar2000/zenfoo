class CashCollectionResponse {
  final int status;
  final String message;
  final CashCollectionData data;

  CashCollectionResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CashCollectionResponse.fromJson(Map<String, dynamic> json) {
    return CashCollectionResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: CashCollectionData.fromJson(json['data'] ?? {}),
    );
  }
}

class CashCollectionData {
  final int orderId;
  final double totalCollected;
  final double deliveryCharge;
  final double deliveryTip;
  final double bonusAmount;
  final double vendorWaitCharge;
  final double driverEarnings;
  final double adminCash;
  final int transactionId;
  final double cashToSettleWithAdmin;
  final int travelTimeMinutes;

  CashCollectionData({
    required this.orderId,
    required this.totalCollected,
    required this.deliveryCharge,
    required this.deliveryTip,
    required this.bonusAmount,
    this.vendorWaitCharge = 0.0,
    required this.driverEarnings,
    required this.adminCash,
    required this.transactionId,
    required this.cashToSettleWithAdmin,
    required this.travelTimeMinutes,
  });

  factory CashCollectionData.fromJson(Map<String, dynamic> json) {
    return CashCollectionData(
      orderId: json['order_id'] ?? 0,
      totalCollected: (json['total_collected'] ?? 0).toDouble(),
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      deliveryTip: (json['delivery_tip'] ?? 0).toDouble(),
      bonusAmount: (json['bonus_amount'] ?? 0).toDouble(),
      vendorWaitCharge: (json['vendor_wait_charge'] ?? 0).toDouble(),
      driverEarnings: (json['driver_earnings'] ?? 0).toDouble(),
      adminCash: (json['admin_cash'] ?? 0).toDouble(),
      transactionId: json['transaction_id'] ?? 0,
      cashToSettleWithAdmin: (json['cash_to_settle_with_admin'] ?? 0).toDouble(),
      travelTimeMinutes: json['travel_time_minutes'] ?? 0,
    );
  }
}

class DeliveryData {
  final int orderId;
  final String paymentMethod;
  final double deliveryCharge;
  final double deliveryTip;
  final double bonusAmount;
  final double vendorWaitCharge;
  final double driverEarnings;
  final double adminOweDriver;
  final int transactionId;
  final List<String> deliveryTimeBeforeImages;
  final int? travelTimeMinutes;

  DeliveryData({
    required this.orderId,
    required this.paymentMethod,
    required this.deliveryCharge,
    required this.deliveryTip,
    required this.bonusAmount,
    this.vendorWaitCharge = 0.0,
    required this.driverEarnings,
    required this.adminOweDriver,
    required this.transactionId,
    required this.deliveryTimeBeforeImages,
    this.travelTimeMinutes,
  });

  factory DeliveryData.fromJson(Map<String, dynamic> json) {
    return DeliveryData(
      orderId: json['order_id'] ?? 0,
      paymentMethod: json['payment_method'] ?? '',
      deliveryCharge: (json['delivery_charge'] ?? 0).toDouble(),
      deliveryTip: (json['delivery_tip'] ?? 0).toDouble(),
      bonusAmount: (json['bonus_amount'] ?? 0).toDouble(),
      vendorWaitCharge: (json['vendor_wait_charge'] ?? 0).toDouble(),
      driverEarnings: (json['driver_earnings'] ?? 0).toDouble(),
      adminOweDriver: (json['admin_owes_driver'] ?? 0).toDouble(),
      transactionId: json['transaction_id'] ?? 0,
      deliveryTimeBeforeImages: List<String>.from(
        json['delivery_time_before_images'] ?? [],
      ),
      travelTimeMinutes: json['travel_time_minutes'],
    );
  }
}
