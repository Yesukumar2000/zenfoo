class NewOrderResponse {
  int? status;
  List<StatusOrderCount>? statusOrderCount;
  List<OrderData>? data;
  Pagination? pagination;

  NewOrderResponse({
    this.status,
    this.statusOrderCount,
    this.data,
    this.pagination,
  });

  factory NewOrderResponse.fromJson(Map<String, dynamic> json) {
    return NewOrderResponse(
      status: json['status'],
      statusOrderCount: json['status_order_count'] != null
          ? (json['status_order_count'] as List)
              .map((e) => StatusOrderCount.fromJson(e))
              .toList()
          : null,
      data: json['data'] != null
          ? (json['data'] as List).map((e) => OrderData.fromJson(e)).toList()
          : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class StatusOrderCount {
  int? id;
  String? status;
  int? orderCount;

  StatusOrderCount({
    this.id,
    this.status,
    this.orderCount,
  });

  factory StatusOrderCount.fromJson(Map<String, dynamic> json) {
    return StatusOrderCount(
      id: json['id'],
      status: json['status'],
      orderCount: json['order_count'],
    );
  }
}

class OrderData {
  int? orderId;
  String? ordersId;
  int? otp;
  int? userId;
  User? user;
  String? mobile;
  String? address;
  String? latitude;
  String? longitude;
  String? orderNote;
  num? total;
  num? deliveryCharge;
  num? taxAmount;
  num? taxPercentage;
  num? discount;
  String? promoCode;
  num? promoDiscount;
  num? walletBalance;
  num? finalTotal;
  String? paymentMethod;
  String? deliveryTime;
  int? deliveryBoyId;
  dynamic deliveryBoy;
  List<dynamic>? status;
  String? activeStatus;
  StatusData? statusData;
  List<OrderStatusHistory>? orderStatusHistory;
  String? preparationTime;
  String? notes;
  List<BillingBreakdown>? billingBreakdown;
  CartMetadata? cartMetadata;
  String? createdAt;
  String? updatedAt;
  List<OrderItem>? items;
  List<dynamic>? comboItems;

  // New API fields
  TrackingInfo? trackingInfo;
  OrderDataDetails? orderDataDetails;
  num? sellerTotal;
  List<ProductDetail>? products;
  List<SettlementItem>? settlementInfo;

  OrderData({
    this.orderId,
    this.ordersId,
    this.otp,
    this.userId,
    this.user,
    this.mobile,
    this.address,
    this.latitude,
    this.longitude,
    this.orderNote,
    this.total,
    this.deliveryCharge,
    this.taxAmount,
    this.taxPercentage,
    this.discount,
    this.promoCode,
    this.promoDiscount,
    this.walletBalance,
    this.finalTotal,
    this.paymentMethod,
    this.deliveryTime,
    this.deliveryBoyId,
    this.deliveryBoy,
    this.status,
    this.activeStatus,
    this.statusData,
    this.orderStatusHistory,
    this.preparationTime,
    this.notes,
    this.billingBreakdown,
    this.cartMetadata,
    this.createdAt,
    this.updatedAt,
    this.items,
    this.comboItems,
    this.trackingInfo,
    this.orderDataDetails,
    this.sellerTotal,
    this.products,
    this.settlementInfo,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    // Handle new API structure
    if (json.containsKey('tracking_info') && json.containsKey('order_data')) {
      final orderData = json['order_data'];
      return OrderData(
        orderId: orderData['id'],
        ordersId: orderData['orders_id'],
        userId: orderData['user_id'],
        mobile: orderData['mobile'],
        address: orderData['address'],
        latitude: orderData['customer_latitude'],
        longitude: orderData['customer_longitude'],
        orderNote: orderData['order_note'],
        total: orderData['total'],
        deliveryCharge: orderData['delivery_charge'],
        discount: orderData['discount'],
        promoCode: orderData['promo_code'],
        promoDiscount: orderData['promo_discount'],
        walletBalance: orderData['wallet_balance'],
        finalTotal: orderData['final_total'],
        paymentMethod: orderData['payment_method'],
        deliveryTime: orderData['delivery_time'],
        activeStatus: orderData['active_status'],
        createdAt: orderData['created_at'],
        updatedAt: orderData['updated_at'],
        trackingInfo: json['tracking_info'] != null
            ? TrackingInfo.fromJson(json['tracking_info'])
            : null,
        sellerTotal: json['seller_total'],
        notes: json['notes'],
        deliveryBoy: json['delivery_boy'] != null
            ? DeliveryBoy.fromJson(json['delivery_boy'])
            : null,
        products: json['products'] != null
            ? (json['products'] as List)
                .map((e) => ProductDetail.fromJson(e))
                .toList()
            : null,
        settlementInfo: json['settlement_info'] != null
            ? (json['settlement_info'] as List)
                .map((e) => SettlementItem.fromJson(e))
                .toList()
            : null,
        statusData: orderData['status_id'] != null
            ? StatusData(
                id: orderData['status_id'],
                code: orderData['active_status'],
                name: orderData['status_name'],
              )
            : null,
      );
    }

    // Handle legacy API structure
    return OrderData(
      orderId: json['order_id'],
      ordersId: json['orders_id'],
      otp: json['otp'],
      userId: json['user_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      mobile: json['mobile'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      orderNote: json['order_note'],
      total: json['total'],
      deliveryCharge: json['delivery_charge'],
      taxAmount: json['tax_amount'],
      taxPercentage: json['tax_percentage'],
      discount: json['discount'],
      promoCode: json['promo_code'],
      promoDiscount: json['promo_discount'],
      walletBalance: json['wallet_balance'],
      finalTotal: json['final_total'],
      paymentMethod: json['payment_method'],
      deliveryTime: json['delivery_time'],
      deliveryBoyId: json['delivery_boy_id'],
      deliveryBoy: json['delivery_boy'],
      status: json['status'],
      activeStatus: json['active_status'],
      statusData: json['status_data'] != null
          ? StatusData.fromJson(json['status_data'])
          : null,
      orderStatusHistory: json['order_status_history'] != null
          ? (json['order_status_history'] as List)
              .map((e) => OrderStatusHistory.fromJson(e))
              .toList()
          : null,
      preparationTime: json['preparation_time'],
      notes: json['notes'],
      billingBreakdown: json['billing_breakdown'] != null
          ? (json['billing_breakdown'] as List)
              .map((e) => BillingBreakdown.fromJson(e))
              .toList()
          : null,
      cartMetadata: json['cart_metadata'] != null
          ? CartMetadata.fromJson(json['cart_metadata'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
          : null,
      comboItems: json['combo_items'],
    );
  }
}

class User {
  int? id;
  String? name;
  String? email;
  int? isVerified;
  String? emailVerificationCode;
  String? profile;
  String? countryCode;
  String? mobile;
  num? balance;
  String? referralCode;
  String? friendsCode;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? stripeId;
  String? pmType;
  String? pmLastFour;
  String? trialEndsAt;
  String? type;

  User({
    this.id,
    this.name,
    this.email,
    this.isVerified,
    this.emailVerificationCode,
    this.profile,
    this.countryCode,
    this.mobile,
    this.balance,
    this.referralCode,
    this.friendsCode,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.stripeId,
    this.pmType,
    this.pmLastFour,
    this.trialEndsAt,
    this.type,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isVerified: json['is_verified'],
      emailVerificationCode: json['email_verification_code'],
      profile: json['profile'],
      countryCode: json['country_code'],
      mobile: json['mobile'],
      balance: json['balance'],
      referralCode: json['referral_code'],
      friendsCode: json['friends_code'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      stripeId: json['stripe_id'],
      pmType: json['pm_type'],
      pmLastFour: json['pm_last_four'],
      trialEndsAt: json['trial_ends_at'],
      type: json['type'],
    );
  }
}

class StatusData {
  int? id;
  String? code;
  String? name;

  StatusData({
    this.id,
    this.code,
    this.name,
  });

  factory StatusData.fromJson(Map<String, dynamic> json) {
    return StatusData(
      id: json['id'],
      code: json['code'],
      name: json['name'],
    );
  }
}

class OrderStatusHistory {
  int? id;
  String? orderId;
  int? orderItemId;
  String? status;
  int? createdBy;
  int? userType;
  String? createdAt;
  String? createdByName;
  String? displayDateTime;

  OrderStatusHistory({
    this.id,
    this.orderId,
    this.orderItemId,
    this.status,
    this.createdBy,
    this.userType,
    this.createdAt,
    this.createdByName,
    this.displayDateTime,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'],
      orderId: json['order_id'],
      orderItemId: json['order_item_id'],
      status: json['status'],
      createdBy: json['created_by'],
      userType: json['user_type'],
      createdAt: json['created_at'],
      createdByName: json['createdByName'],
      displayDateTime: json['displayDateTime'],
    );
  }
}

class BillingBreakdown {
  String? type;
  String? label;
  String? description;
  num? amount;
  String? currency;
  bool? isCredit;
  bool? isTotal;
  CalculationSummary? calculationSummary;

  BillingBreakdown({
    this.type,
    this.label,
    this.description,
    this.amount,
    this.currency,
    this.isCredit,
    this.isTotal,
    this.calculationSummary,
  });

  factory BillingBreakdown.fromJson(Map<String, dynamic> json) {
    return BillingBreakdown(
      type: json['type'],
      label: json['label'],
      description: json['description'],
      amount: json['amount'],
      currency: json['currency'],
      isCredit: json['is_credit'],
      isTotal: json['is_total'],
      calculationSummary: json['calculation_summary'] != null
          ? CalculationSummary.fromJson(json['calculation_summary'])
          : null,
    );
  }
}

class CalculationSummary {
  num? itemsMrp;
  num? itemsDiscount;
  num? comboMrp;
  num? comboDiscount;
  num? deliveryCharge;
  num? deliveryTip;
  num? additionalCharges;
  num? promocodeDiscount;
  num? finalTotal;

  CalculationSummary({
    this.itemsMrp,
    this.itemsDiscount,
    this.comboMrp,
    this.comboDiscount,
    this.deliveryCharge,
    this.deliveryTip,
    this.additionalCharges,
    this.promocodeDiscount,
    this.finalTotal,
  });

  factory CalculationSummary.fromJson(Map<String, dynamic> json) {
    return CalculationSummary(
      itemsMrp: json['items_mrp'],
      itemsDiscount: json['items_discount'],
      comboMrp: json['combo_mrp'],
      comboDiscount: json['combo_discount'],
      deliveryCharge: json['delivery_charge'],
      deliveryTip: json['delivery_tip'],
      additionalCharges: json['additional_charges'],
      promocodeDiscount: json['promocode_discount'],
      finalTotal: json['final_total'],
    );
  }
}

class CartMetadata {
  CartInfo? cartInfo;
  List<BillingBreakdown>? billingBreakdown;
  BillingSummary? billingSummary;

  CartMetadata({
    this.cartInfo,
    this.billingBreakdown,
    this.billingSummary,
  });

  factory CartMetadata.fromJson(Map<String, dynamic> json) {
    return CartMetadata(
      cartInfo: json['cart_info'] != null
          ? CartInfo.fromJson(json['cart_info'])
          : null,
      billingBreakdown: json['billing_breakdown'] != null
          ? (json['billing_breakdown'] as List)
              .map((e) => BillingBreakdown.fromJson(e))
              .toList()
          : null,
      billingSummary: json['billing_summary'] != null
          ? BillingSummary.fromJson(json['billing_summary'])
          : null,
    );
  }
}

class CartInfo {
  String? promocodeId;
  String? deliveryTip;
  String? deliveryInstructions;
  String? contactName;
  String? contactPhone;
  String? contactEmail;
  Map<String, dynamic>? sellerNotes;
  dynamic comboNotes;

  CartInfo({
    this.promocodeId,
    this.deliveryTip,
    this.deliveryInstructions,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.sellerNotes,
    this.comboNotes,
  });

  factory CartInfo.fromJson(Map<String, dynamic> json) {
    return CartInfo(
      promocodeId: json['promocode_id'],
      deliveryTip: json['delivery_tip'],
      deliveryInstructions: json['delivery_instructions'],
      contactName: json['contact_name'],
      contactPhone: json['contact_phone'],
      contactEmail: json['contact_email'],
      sellerNotes: json['seller_notes'],
      comboNotes: json['combo_notes'],
    );
  }
}

class BillingSummary {
  num? itemsMrp;
  num? itemsDiscount;
  num? comboMrp;
  num? comboDiscount;
  num? deliveryCharge;
  num? deliveryTip;
  num? gstCharges;
  num? additionalCharges;
  num? promocodeDiscount;
  num? totalSavings;
  num? toBePaid;
  String? currency;

  BillingSummary({
    this.itemsMrp,
    this.itemsDiscount,
    this.comboMrp,
    this.comboDiscount,
    this.deliveryCharge,
    this.deliveryTip,
    this.gstCharges,
    this.additionalCharges,
    this.promocodeDiscount,
    this.totalSavings,
    this.toBePaid,
    this.currency,
  });

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    return BillingSummary(
      itemsMrp: json['items_mrp'],
      itemsDiscount: json['items_discount'],
      comboMrp: json['combo_mrp'],
      comboDiscount: json['combo_discount'],
      deliveryCharge: json['delivery_charge'],
      deliveryTip: json['delivery_tip'],
      gstCharges: json['gst_charges'],
      additionalCharges: json['additional_charges'],
      promocodeDiscount: json['promocode_discount'],
      totalSavings: json['total_savings'],
      toBePaid: json['to_be_paid'],
      currency: json['currency'],
    );
  }
}

class OrderItem {
  String? type;
  int? itemId;
  String? productName;
  String? variantName;
  int? quantity;
  num? price;
  num? discountedPrice;
  num? taxAmount;
  num? taxPercentage;
  num? discount;
  num? subTotal;
  String? status;
  String? activeStatus;
  String? imageUrl;
  ProductVariant? productVariant;

  OrderItem({
    this.type,
    this.itemId,
    this.productName,
    this.variantName,
    this.quantity,
    this.price,
    this.discountedPrice,
    this.taxAmount,
    this.taxPercentage,
    this.discount,
    this.subTotal,
    this.status,
    this.activeStatus,
    this.imageUrl,
    this.productVariant,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      type: json['type'],
      itemId: json['item_id'],
      productName: json['product_name'],
      variantName: json['variant_name'],
      quantity: json['quantity'],
      price: json['price'],
      discountedPrice: json['discounted_price'],
      taxAmount: json['tax_amount'],
      taxPercentage: json['tax_percentage'],
      discount: json['discount'],
      subTotal: json['sub_total'],
      status: json['status'],
      activeStatus: json['active_status'],
      imageUrl: json['image_url'],
      productVariant: json['product_variant'] != null
          ? ProductVariant.fromJson(json['product_variant'])
          : null,
    );
  }
}

class ProductVariant {
  int? id;
  int? productId;
  String? type;
  int? status;
  num? measurement;
  num? price;
  num? discountedPrice;
  num? stock;
  int? stockUnitId;
  num? finalPriceWithTax;
  Product? product;

  ProductVariant({
    this.id,
    this.productId,
    this.type,
    this.status,
    this.measurement,
    this.price,
    this.discountedPrice,
    this.stock,
    this.stockUnitId,
    this.finalPriceWithTax,
    this.product,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      productId: json['product_id'],
      type: json['type'],
      status: json['status'],
      measurement: json['measurement'],
      price: json['price'],
      discountedPrice: json['discounted_price'],
      stock: json['stock'],
      stockUnitId: json['stock_unit_id'],
      finalPriceWithTax: json['final_price_with_tax'],
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}

class Product {
  int? id;
  int? sellerId;
  int? rowOrder;
  String? name;
  String? tags;
  int? taxId;
  int? brandId;
  String? slug;
  int? categoryId;
  int? subCategoryGroupId;
  int? categoryGroupId;
  int? storeId;
  int? itemTypeId;
  String? otherInfo;
  String? tax;
  String? indicator;
  String? manufacturer;
  String? madeIn;
  int? returnStatus;
  int? cancelableStatus;
  String? tillStatus;
  String? image;
  String? otherImages;
  String? description;
  int? status;
  int? isApproved;
  int? returnDays;
  String? type;
  int? isUnlimitedStock;
  int? codAllowed;
  int? totalAllowedQuantity;
  int? taxIncludedInPrice;
  String? fssaiLicNo;
  String? barcode;
  String? metaTitle;
  String? metaKeywords;
  String? schemaMarkup;
  String? metaDescription;
  String? imageUrl;

  Product({
    this.id,
    this.sellerId,
    this.rowOrder,
    this.name,
    this.tags,
    this.taxId,
    this.brandId,
    this.slug,
    this.categoryId,
    this.subCategoryGroupId,
    this.categoryGroupId,
    this.storeId,
    this.itemTypeId,
    this.otherInfo,
    this.tax,
    this.indicator,
    this.manufacturer,
    this.madeIn,
    this.returnStatus,
    this.cancelableStatus,
    this.tillStatus,
    this.image,
    this.otherImages,
    this.description,
    this.status,
    this.isApproved,
    this.returnDays,
    this.type,
    this.isUnlimitedStock,
    this.codAllowed,
    this.totalAllowedQuantity,
    this.taxIncludedInPrice,
    this.fssaiLicNo,
    this.barcode,
    this.metaTitle,
    this.metaKeywords,
    this.schemaMarkup,
    this.metaDescription,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sellerId: json['seller_id'],
      rowOrder: json['row_order'],
      name: json['name'],
      tags: json['tags'],
      taxId: json['tax_id'],
      brandId: json['brand_id'],
      slug: json['slug'],
      categoryId: json['category_id'],
      subCategoryGroupId: json['sub_category_group_id'],
      categoryGroupId: json['category_group_id'],
      storeId: json['store_id'],
      itemTypeId: json['item_type_id'],
      otherInfo: json['other_info'],
      tax: json['tax'],
      indicator: json['indicator'],
      manufacturer: json['manufacturer'],
      madeIn: json['made_in'],
      returnStatus: json['return_status'],
      cancelableStatus: json['cancelable_status'],
      tillStatus: json['till_status'],
      image: json['image'],
      otherImages: json['other_images'],
      description: json['description'],
      status: json['status'],
      isApproved: json['is_approved'],
      returnDays: json['return_days'],
      type: json['type'],
      isUnlimitedStock: json['is_unlimited_stock'],
      codAllowed: json['cod_allowed'],
      totalAllowedQuantity: json['total_allowed_quantity'],
      taxIncludedInPrice: json['tax_included_in_price'],
      fssaiLicNo: json['fssai_lic_no'],
      barcode: json['barcode'],
      metaTitle: json['meta_title'],
      metaKeywords: json['meta_keywords'],
      schemaMarkup: json['schema_markup'],
      metaDescription: json['meta_description'],
      imageUrl: json['image_url'],
    );
  }
}

class Pagination {
  int? total;
  String? perPage;
  int? currentPage;
  int? lastPage;
  int? from;
  int? to;

  Pagination({
    this.total,
    this.perPage,
    this.currentPage,
    this.lastPage,
    this.from,
    this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      from: json['from'],
      to: json['to'],
    );
  }
}

// New API models
class TrackingInfo {
  int? id;
  int? orderId;
  int? sellerId;
  int? storeId;
  String? status;
  String? prepTime; // Keep original for backward compatibility
  int? prepTimeMinutes; // Parsed minutes from prep_time array
  String? prepTimeString; // Parsed time string from prep_time array
  String? createdAt;
  String? updatedAt;

  TrackingInfo({
    this.id,
    this.orderId,
    this.sellerId,
    this.storeId,
    this.status,
    this.prepTime,
    this.prepTimeMinutes,
    this.prepTimeString,
    this.createdAt,
    this.updatedAt,
  });

  factory TrackingInfo.fromJson(Map<String, dynamic> json) {
    String? prepTimeStr;
    int? minutes;
    String? timeStr;

    // Parse prep_time - can be either string or array [minutes, "time"]
    if (json['prep_time'] != null) {
      if (json['prep_time'] is List) {
        final prepTimeList = json['prep_time'] as List;
        if (prepTimeList.isNotEmpty) {
          minutes = prepTimeList[0] is int ? prepTimeList[0] : int.tryParse(prepTimeList[0].toString());
          if (prepTimeList.length > 1) {
            timeStr = prepTimeList[1].toString();
          }
          prepTimeStr = timeStr ?? minutes?.toString();
        }
      } else {
        prepTimeStr = json['prep_time'].toString();
      }
    }

    return TrackingInfo(
      id: json['id'],
      orderId: json['order_id'],
      sellerId: json['seller_id'],
      storeId: json['store_id'],
      status: json['status'],
      prepTime: prepTimeStr,
      prepTimeMinutes: minutes,
      prepTimeString: timeStr,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class DeliveryBoy {
  int? id;
  String? name;
  String? mobile;
  String? imageUrl;

  DeliveryBoy({
    this.id,
    this.name,
    this.mobile,
    this.imageUrl,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: json['id'],
      name: json['name'],
      mobile: json['mobile'],
      imageUrl: json['image_url'],
    );
  }
}

class OrderDataDetails {
  int? id;
  String? ordersId;
  int? userId;
  String? userName;
  String? userEmail;
  String? userMobile;
  String? mobile;
  num? total;
  num? deliveryCharge;
  num? discount;
  String? promoCode;
  num? promoDiscount;
  num? walletBalance;
  num? finalTotal;
  String? paymentMethod;
  String? address;
  String? customerAddress;
  String? customerLandmark;
  String? customerArea;
  String? customerPincode;
  String? customerCity;
  String? customerState;
  String? customerCountry;
  String? customerLatitude;
  String? customerLongitude;
  String? deliveryTime;
  String? orderType;
  String? activeStatus;
  int? statusId;
  String? statusName;
  String? orderNote;
  String? createdAt;
  String? updatedAt;

  OrderDataDetails({
    this.id,
    this.ordersId,
    this.userId,
    this.userName,
    this.userEmail,
    this.userMobile,
    this.mobile,
    this.total,
    this.deliveryCharge,
    this.discount,
    this.promoCode,
    this.promoDiscount,
    this.walletBalance,
    this.finalTotal,
    this.paymentMethod,
    this.address,
    this.customerAddress,
    this.customerLandmark,
    this.customerArea,
    this.customerPincode,
    this.customerCity,
    this.customerState,
    this.customerCountry,
    this.customerLatitude,
    this.customerLongitude,
    this.deliveryTime,
    this.orderType,
    this.activeStatus,
    this.statusId,
    this.statusName,
    this.orderNote,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderDataDetails.fromJson(Map<String, dynamic> json) {
    return OrderDataDetails(
      id: json['id'],
      ordersId: json['orders_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userEmail: json['user_email'],
      userMobile: json['user_mobile'],
      mobile: json['mobile'],
      total: json['total'],
      deliveryCharge: json['delivery_charge'],
      discount: json['discount'],
      promoCode: json['promo_code'],
      promoDiscount: json['promo_discount'],
      walletBalance: json['wallet_balance'],
      finalTotal: json['final_total'],
      paymentMethod: json['payment_method'],
      address: json['address'],
      customerAddress: json['customer_address'],
      customerLandmark: json['customer_landmark'],
      customerArea: json['customer_area'],
      customerPincode: json['customer_pincode'],
      customerCity: json['customer_city'],
      customerState: json['customer_state'],
      customerCountry: json['customer_country'],
      customerLatitude: json['customer_latitude'],
      customerLongitude: json['customer_longitude'],
      deliveryTime: json['delivery_time'],
      orderType: json['order_type'],
      activeStatus: json['active_status'],
      statusId: json['status_id'],
      statusName: json['status_name'],
      orderNote: json['order_note'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ProductDetail {
  int? productId;
  int? productVariantId;
  String? productName;
  String? variantName;
  String? productImage;
  String? productImageUrl;
  int? storeId;
  int? quantity;
  num? price;
  num? discountedPrice;
  num? subTotal;
  num? measurement;
  String? unitName;
  String? unitShortCode;
  num? variantPrice;
  num? variantDiscountedPrice;
  num? taxAmount;
  num? taxPercentage;
  String? itemStatusName;
  String? source;

  ProductDetail({
    this.productId,
    this.productVariantId,
    this.productName,
    this.variantName,
    this.productImage,
    this.productImageUrl,
    this.storeId,
    this.quantity,
    this.price,
    this.discountedPrice,
    this.subTotal,
    this.measurement,
    this.unitName,
    this.unitShortCode,
    this.variantPrice,
    this.variantDiscountedPrice,
    this.taxAmount,
    this.taxPercentage,
    this.itemStatusName,
    this.source,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      productId: json['product_id'],
      productVariantId: json['product_variant_id'],
      productName: json['product_name'],
      variantName: json['variant_name'],
      productImage: json['product_image'],
      productImageUrl: json['product_image_url'],
      storeId: json['store_id'],
      quantity: json['quantity'],
      price: json['price'],
      discountedPrice: json['discounted_price'],
      subTotal: json['sub_total'],
      measurement: json['measurement'],
      unitName: json['unit_name'],
      unitShortCode: json['unit_short_code'],
      variantPrice: json['variant_price'],
      variantDiscountedPrice: json['variant_discounted_price'],
      taxAmount: json['tax_amount'],
      taxPercentage: json['tax_percentage'],
      itemStatusName: json['item_status_name'],
      source: json['source'],
    );
  }
}

class SettlementItem {
  final String label;
  final dynamic value;

  SettlementItem({required this.label, required this.value});

  factory SettlementItem.fromJson(Map<String, dynamic> json) {
    final raw = (json['label'] ?? '').toString();
    return SettlementItem(
      label: raw.trim().toLowerCase() == 'net seller amount'
          ? 'Net Payable Amount'
          : raw,
      value: json['value'],
    );
  }
}
