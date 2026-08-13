import 'package:project/models/additionalCharges.dart';

class Checkout {
  String? status;
  String? message;
  String? total;
  DeliveryChargeData? data;

  Checkout({this.status, this.message, this.total, this.data});

  Checkout.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    message = json['message'].toString();
    total = json['total'].toString();
    data = json['data'] != null
        ? new DeliveryChargeData.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['total'] = this.total;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class DeliveryChargeData {
  String? codAllowed;
  String? productVariantId;
  String? userBalance;
  String? quantity;
  DeliveryCharge? deliveryCharge;
  String? deliveryTip;
  String? totalAmount;
  PromocodeDetails? promocodeDetails;
  String? subTotal;
  String? savedAmount;
  String? comboTotal;
  String? comboSavings;
  List<AdditionalCharges>? additionalCharges;
  List<BillingBreakdownItem>? billingBreakdown;
  BillingSummary? billingSummary;
  CartMetadata? cartMetadata;
  SellerSelfPickup? sellerSelfPickup;
  String? selfPickupMode;

  DeliveryChargeData({
    this.codAllowed,
    this.productVariantId,
    this.userBalance,
    this.quantity,
    this.deliveryCharge,
    this.deliveryTip,
    this.totalAmount,
    this.promocodeDetails,
    this.subTotal,
    this.savedAmount,
    this.comboTotal,
    this.comboSavings,
    this.additionalCharges,
    this.billingBreakdown,
    this.billingSummary,
    this.cartMetadata,
    this.sellerSelfPickup,
    this.selfPickupMode,
  });

  DeliveryChargeData.fromJson(Map<String, dynamic> json) {
    codAllowed = json['cod_allowed'].toString();
    productVariantId = json['product_variant_id'].toString();
    userBalance = json['user_balance'].toString();
    quantity = json['quantity'].toString();
    deliveryCharge = json['delivery_charge'] != null
        ? new DeliveryCharge.fromJson(json['delivery_charge'])
        : null;
    deliveryTip = json['delivery_tip']?.toString();
    totalAmount = json['total_amount'].toString();
    promocodeDetails = json['promocode_details'] != null
        ? new PromocodeDetails.fromJson(json['promocode_details'])
        : null;
    subTotal = json['sub_total'].toString();
    savedAmount = json['saved_amount'].toString();
    comboTotal = json['combo_total']?.toString();
    comboSavings = json['combo_savings']?.toString();
    additionalCharges = (json['additional_charges'] != null &&
            json['additional_charges'] is List)
        ? List<AdditionalCharges>.from(json['additional_charges']
            .map((x) => AdditionalCharges.fromJson(x)))
        : [];
    billingBreakdown =
        (json['billing_breakdown'] != null && json['billing_breakdown'] is List)
            ? List<BillingBreakdownItem>.from(json['billing_breakdown']
                .map((x) => BillingBreakdownItem.fromJson(x)))
            : [];
    billingSummary = json['billing_summary'] != null
        ? BillingSummary.fromJson(json['billing_summary'])
        : null;
    cartMetadata = json['cart_metadata'] != null
        ? CartMetadata.fromJson(json['cart_metadata'])
        : null;
    sellerSelfPickup = json['seller_self_pickup'] != null
        ? new SellerSelfPickup.fromJson(json['seller_self_pickup'])
        : null;
    selfPickupMode = (json['self_pickup_mode'] ?? 0).toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cod_allowed'] = this.codAllowed;
    data['product_variant_id'] = this.productVariantId;
    data['user_balance'] = this.userBalance;
    data['quantity'] = this.quantity;
    if (this.deliveryCharge != null) {
      data['delivery_charge'] = this.deliveryCharge!.toJson();
    }
    data['delivery_tip'] = this.deliveryTip;
    data['total_amount'] = this.totalAmount;
    if (this.promocodeDetails != null) {
      data['promocode_details'] = this.promocodeDetails!.toJson();
    }
    data['sub_total'] = this.subTotal;
    data['saved_amount'] = this.savedAmount;
    data['combo_total'] = this.comboTotal;
    data['combo_savings'] = this.comboSavings;
    if (this.additionalCharges != null) {
      data['additional_charges'] =
          this.additionalCharges!.map((e) => e.toJson()).toList();
    }
    if (this.billingBreakdown != null) {
      data['billing_breakdown'] =
          this.billingBreakdown!.map((e) => e.toJson()).toList();
    }
    if (this.billingSummary != null) {
      data['billing_summary'] = this.billingSummary!.toJson();
    }
    if (this.cartMetadata != null) {
      data['cart_metadata'] = this.cartMetadata!.toJson();
    }
    data['self_pickup_mode'] = this.selfPickupMode;
    return data;
  }
}

class DeliveryCharge {
  String? totalDeliveryCharge;
  String? deliveryCharge;
  List<dynamic>? deliveryChargeDetails;
  List<SellersInfo>? sellersInfo;

  DeliveryCharge({
    this.totalDeliveryCharge,
    this.deliveryCharge,
    this.deliveryChargeDetails,
    this.sellersInfo,
  });

  DeliveryCharge.fromJson(Map<String, dynamic> json) {
    totalDeliveryCharge = json['total_delivery_charge']?.toString();
    deliveryCharge = json['delivery_charge']?.toString();
    deliveryChargeDetails = json['delivery_charge_details'] is List
        ? json['delivery_charge_details']
        : [];
    if (json['sellers_info'] != null) {
      sellersInfo = <SellersInfo>[];
      json['sellers_info'].forEach((v) {
        sellersInfo!.add(new SellersInfo.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_delivery_charge'] = this.totalDeliveryCharge;
    data['delivery_charge'] = this.deliveryCharge;
    data['delivery_charge_details'] = this.deliveryChargeDetails;
    if (this.sellersInfo != null) {
      data['sellers_info'] = this.sellersInfo!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SellersInfo {
  String? sellerName;
  String? deliveryCharge;
  String? distance;
  String? duration;

  SellersInfo(
      {this.sellerName, this.deliveryCharge, this.distance, this.duration});

  SellersInfo.fromJson(Map<String, dynamic> json) {
    sellerName = json['seller_name'].toString();
    deliveryCharge = json['delivery_charge'].toString();
    distance = json['distance'].toString();
    duration = json['duration'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['seller_name'] = this.sellerName;
    data['delivery_charge'] = this.deliveryCharge;
    data['distance'] = this.distance;
    data['duration'] = this.duration;
    return data;
  }
}

class BillingBreakdownItem {
  String? type;
  String? label;
  String? description;
  dynamic amount;
  String? currency;
  bool? isCredit;
  bool? isTotal;
  CalculationSummary? calculationSummary;

  BillingBreakdownItem({
    this.type,
    this.label,
    this.description,
    this.amount,
    this.currency,
    this.isCredit,
    this.isTotal,
    this.calculationSummary,
  });

  BillingBreakdownItem.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    label = json['label']?.toString();
    description = json['description']?.toString();
    amount = json['amount'];
    currency = json['currency']?.toString();
    isCredit = json['is_credit'] ?? false;
    isTotal = json['is_total'] ?? false;
    calculationSummary = json['calculation_summary'] != null
        ? CalculationSummary.fromJson(json['calculation_summary'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['label'] = this.label;
    data['description'] = this.description;
    data['amount'] = this.amount;
    data['currency'] = this.currency;
    data['is_credit'] = this.isCredit;
    data['is_total'] = this.isTotal;
    if (this.calculationSummary != null) {
      data['calculation_summary'] = this.calculationSummary!.toJson();
    }
    return data;
  }
}

class CalculationSummary {
  dynamic itemsMrp;
  dynamic itemsDiscount;
  dynamic comboMrp;
  dynamic comboDiscount;
  dynamic deliveryCharge;
  dynamic deliveryTip;
  dynamic additionalCharges;
  dynamic promocodeDiscount;
  dynamic claimableMilestoneAmount;
  dynamic finalTotal;

  CalculationSummary({
    this.itemsMrp,
    this.itemsDiscount,
    this.comboMrp,
    this.comboDiscount,
    this.deliveryCharge,
    this.deliveryTip,
    this.additionalCharges,
    this.promocodeDiscount,
    this.claimableMilestoneAmount,
    this.finalTotal,
  });

  CalculationSummary.fromJson(Map<String, dynamic> json) {
    itemsMrp = _parseToDouble(json['items_mrp']);
    itemsDiscount = _parseToDouble(json['items_discount']);
    comboMrp = _parseToDouble(json['combo_mrp']);
    comboDiscount = _parseToDouble(json['combo_discount']);
    deliveryCharge = _parseToDouble(json['delivery_charge']);
    deliveryTip = _parseToDouble(json['delivery_tip']);
    additionalCharges = _parseToDouble(json['additional_charges']);
    promocodeDiscount = _parseToDouble(json['promocode_discount']);
    claimableMilestoneAmount =
        _parseToDouble(json['claimable_milestone_amount']);
    finalTotal = _parseToDouble(json['final_total']);
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['items_mrp'] = this.itemsMrp;
    data['items_discount'] = this.itemsDiscount;
    data['combo_mrp'] = this.comboMrp;
    data['combo_discount'] = this.comboDiscount;
    data['delivery_charge'] = this.deliveryCharge;
    data['delivery_tip'] = this.deliveryTip;
    data['additional_charges'] = this.additionalCharges;
    data['promocode_discount'] = this.promocodeDiscount;
    data['claimable_milestone_amount'] = this.claimableMilestoneAmount;
    data['final_total'] = this.finalTotal;
    return data;
  }
}

class BillingSummary {
  dynamic itemsMrp;
  dynamic itemsDiscount;
  dynamic comboMrp;
  dynamic comboDiscount;
  dynamic deliveryCharge;
  dynamic deliveryTip;
  dynamic gstCharges;
  dynamic paymentGatewayFees;
  dynamic paymentGatewayFeesPercent;
  dynamic additionalCharges;
  dynamic promocodeDiscount;
  dynamic claimableMilestoneAmount;
  dynamic totalSavings;
  dynamic toBePaid;
  String? currency;

  BillingSummary({
    this.itemsMrp,
    this.itemsDiscount,
    this.comboMrp,
    this.comboDiscount,
    this.deliveryCharge,
    this.deliveryTip,
    this.gstCharges,
    this.paymentGatewayFees,
    this.paymentGatewayFeesPercent,
    this.additionalCharges,
    this.promocodeDiscount,
    this.claimableMilestoneAmount,
    this.totalSavings,
    this.toBePaid,
    this.currency,
  });

  BillingSummary.fromJson(Map<String, dynamic> json) {
    itemsMrp = _parseToDouble(json['items_mrp']);
    itemsDiscount = _parseToDouble(json['items_discount']);
    comboMrp = _parseToDouble(json['combo_mrp']);
    comboDiscount = _parseToDouble(json['combo_discount']);
    deliveryCharge = _parseToDouble(json['delivery_charge']);
    deliveryTip = _parseToDouble(json['delivery_tip']);
    gstCharges = _parseToDouble(json['gst_charges']);
    paymentGatewayFees = _parseToDouble(json['payment_gateway_fees']);
    paymentGatewayFeesPercent = _parseToDouble(json['payment_gateway_fees_percent']);
    additionalCharges = _parseToDouble(json['additional_charges']);
    promocodeDiscount = _parseToDouble(json['promocode_discount']);
    claimableMilestoneAmount = _parseToDouble(json['claimable_milestone_amount']);
    totalSavings = _parseToDouble(json['total_savings']);
    toBePaid = _parseToDouble(json['to_be_paid']);
    currency = json['currency']?.toString();
  }

  static double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['items_mrp'] = this.itemsMrp;
    data['items_discount'] = this.itemsDiscount;
    data['combo_mrp'] = this.comboMrp;
    data['combo_discount'] = this.comboDiscount;
    data['delivery_charge'] = this.deliveryCharge;
    data['delivery_tip'] = this.deliveryTip;
    data['gst_charges'] = this.gstCharges;
    data['payment_gateway_fees'] = this.paymentGatewayFees;
    data['payment_gateway_fees_percent'] = this.paymentGatewayFeesPercent;
    data['additional_charges'] = this.additionalCharges;
    data['promocode_discount'] = this.promocodeDiscount;
    data['claimable_milestone_amount'] = this.claimableMilestoneAmount;
    data['total_savings'] = this.totalSavings;
    data['to_be_paid'] = this.toBePaid;
    data['currency'] = this.currency;
    return data;
  }
}

class CartMetadata {
  int? id;
  int? userId;
  dynamic promocodeId;
  String? deliveryTip;
  String? deliveryInstructions;
  String? contactName;
  String? contactPhone;
  String? contactEmail;
  Map<String, dynamic>? sellerNotes;
  dynamic comboNotes;
  List<BillingBreakdownItem>? billingBreakdown;
  BillingSummary? billingSummary;
  String? createdAt;
  String? updatedAt;

  CartMetadata({
    this.id,
    this.userId,
    this.promocodeId,
    this.deliveryTip,
    this.deliveryInstructions,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.sellerNotes,
    this.comboNotes,
    this.billingBreakdown,
    this.billingSummary,
    this.createdAt,
    this.updatedAt,
  });

  CartMetadata.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    promocodeId = json['promocode_id'];
    deliveryTip = json['delivery_tip']?.toString();
    deliveryInstructions = json['delivery_instructions']?.toString();
    contactName = json['contact_name']?.toString();
    contactPhone = json['contact_phone']?.toString();
    contactEmail = json['contact_email']?.toString();
    sellerNotes = json['seller_notes'] is Map
        ? Map<String, dynamic>.from(json['seller_notes'])
        : null;
    comboNotes = json['combo_notes'];
    billingBreakdown =
        (json['billing_breakdown'] != null && json['billing_breakdown'] is List)
            ? List<BillingBreakdownItem>.from(json['billing_breakdown']
                .map((x) => BillingBreakdownItem.fromJson(x)))
            : [];
    billingSummary = json['billing_summary'] != null
        ? BillingSummary.fromJson(json['billing_summary'])
        : null;
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['promocode_id'] = this.promocodeId;
    data['delivery_tip'] = this.deliveryTip;
    data['delivery_instructions'] = this.deliveryInstructions;
    data['contact_name'] = this.contactName;
    data['contact_phone'] = this.contactPhone;
    data['contact_email'] = this.contactEmail;
    data['seller_notes'] = this.sellerNotes;
    data['combo_notes'] = this.comboNotes;
    if (this.billingBreakdown != null) {
      data['billing_breakdown'] =
          this.billingBreakdown!.map((e) => e.toJson()).toList();
    }
    if (this.billingSummary != null) {
      data['billing_summary'] = this.billingSummary!.toJson();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class PromocodeDetails {
  String? id;
  String? isApplicable;
  String? message;
  String? promoCode;
  String? imageUrl;
  String? promoCodeMessage;
  String? total;
  String? discount;
  String? discountedAmount;

  PromocodeDetails(
      {this.id,
      this.isApplicable,
      this.message,
      this.promoCode,
      this.imageUrl,
      this.promoCodeMessage,
      this.total,
      this.discount,
      this.discountedAmount});

  PromocodeDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    isApplicable = json['is_applicable'].toString();
    message = json['message'].toString();
    promoCode = json['promo_code'].toString();
    imageUrl = json['image_url'].toString();
    promoCodeMessage = json['promo_code_message'].toString();
    total = json['total'].toString();
    discount = json['discount'].toString();
    discountedAmount = json['discounted_amount'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['is_applicable'] = this.isApplicable;
    data['message'] = this.message;
    data['promo_code'] = this.promoCode;
    data['image_url'] = this.imageUrl;
    data['promo_code_message'] = this.promoCodeMessage;
    data['total'] = this.total;
    data['discount'] = this.discount;
    data['discounted_amount'] = this.discountedAmount;
    return data;
  }
}

class SellerSelfPickup {
  int? sellerId;
  String? sellerName;
  String? sellerMobile;
  String? pickupStoreAddress;
  String? pickupLatitude;
  String? pickupLongitude;
  String? openingTime;
  String? closingTime;

  SellerSelfPickup(
      {this.sellerId,
      this.sellerName,
      this.sellerMobile,
      this.pickupStoreAddress,
      this.pickupLatitude,
      this.pickupLongitude,
      this.openingTime,
      this.closingTime});

  SellerSelfPickup.fromJson(Map<String, dynamic> json) {
    sellerId = json['seller_id'];
    sellerName = json['seller_name'];
    sellerMobile = json['seller_mobile'];
    pickupStoreAddress = json['pickup_store_address'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    openingTime = json['opening_time'];
    closingTime = json['closing_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['seller_id'] = this.sellerId;
    data['seller_name'] = this.sellerName;
    data['seller_mobile'] = this.sellerMobile;
    data['pickup_store_address'] = this.pickupStoreAddress;
    data['pickup_latitude'] = this.pickupLatitude;
    data['pickup_longitude'] = this.pickupLongitude;
    data['opening_time'] = this.openingTime;
    data['closing_time'] = this.closingTime;
    return data;
  }
}
