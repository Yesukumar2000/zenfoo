import 'dart:core';

import 'package:project/models/additionalCharges.dart';
import 'package:project/models/groupedByStore.dart';

class Order {
  Order(
      {this.id,
      this.ordersId,
      this.userId,
      this.transactionId,
      this.otp,
      this.mobile,
      this.orderNote,
      this.total,
      this.deliveryCharge,
      this.taxAmount,
      this.taxPercentage,
      this.walletBalance,
      this.discount,
      this.promoCode,
      this.promoDiscount,
      this.finalTotal,
      this.paymentMethod,
      this.orderAddress,
      this.deliveryBoyName,
      this.deliveryBoyNumber,
      this.deliveryBoyId,
      this.deliveryBoyProfileImage,
      this.deliveryBoyRating,
      this.latitude,
      this.longitude,
      this.deliveryLocation,
      this.deliveryTime,
      this.deliveryPin,
      this.activeStatus,
      this.orderFrom,
      this.pincodeId,
      this.addressId,
      this.areaId,
      this.bankTransferMessage,
      this.bankTransferStatus,
      this.userName,
      this.discountRupees,
      this.items,
      this.date,
      this.createdAt,
      this.status,
      this.additionalCharges,
      this.remainingTotal,
      this.remainingFinal,
      this.orderType,
      this.pickupAddress,
      this.groupedByStore,
      this.customCombos,
      this.cartInfo,
      this.billingBreakdown,
      this.billingSummary,
      this.zenfooStoreLocation});

  String? id;

  /// Customer facing order number, e.g. "ZF-0451". Null on orders placed
  /// before order numbers existed - use [displayNumber] rather than this.
  String? ordersId;

  /// What to show the customer after the word "Order": the order number when
  /// there is one, otherwise the raw id so the order is still identifiable.
  String get displayNumber {
    final number = ordersId;
    if (number != null && number.isNotEmpty && number != 'null') {
      return number;
    }
    return '#${id ?? ''}';
  }

  List<List>? status;
  String? userId;
  String? transactionId;
  String? otp;
  String? mobile;
  String? orderNote;
  String? total;
  String? deliveryCharge;
  String? taxAmount;
  String? taxPercentage;
  String? walletBalance;
  String? discount;
  String? promoCode;
  String? promoDiscount;
  String? finalTotal;
  String? paymentMethod;
  String? orderAddress;
  String? deliveryBoyName;
  String? deliveryBoyNumber;
  String? deliveryBoyId;
  String? deliveryBoyProfileImage;
  String? deliveryBoyRating;
  String? latitude;
  String? longitude;
  Map<String, dynamic>? deliveryLocation;
  String? deliveryTime;
  String? deliveryPin;
  String? activeStatus;
  String? orderFrom;
  String? pincodeId;
  String? addressId;
  String? areaId;
  String? bankTransferMessage;
  String? bankTransferStatus;
  String? userName;
  String? discountRupees;
  String? date;
  String? createdAt;
  List<OrderItem>? items;
  List<AdditionalCharges>? additionalCharges;
  String? remainingTotal;
  String? remainingFinal;
  String? orderType;
	PickupAddress? pickupAddress;
  List<GroupedByStore>? groupedByStore;
  List<dynamic>? customCombos;
  Map<String, dynamic>? cartInfo;
  List<dynamic>? billingBreakdown;
  Map<String, dynamic>? billingSummary;
  ZenfooStoreLocation? zenfooStoreLocation;

  Order copyWith(
      {List<OrderItem>? orderItems,
      String? updatedActiveStatus,
      String? newTotal,
      String? newFinalTotal}) {
    return Order(
      id: id,
      ordersId: ordersId,
      userId: userId,
      transactionId: transactionId,
      otp: otp,
      mobile: mobile,
      orderNote: orderNote,
      total: newTotal ?? total,
      deliveryCharge: deliveryCharge,
      taxAmount: taxAmount,
      taxPercentage: taxPercentage,
      walletBalance: walletBalance,
      discount: discount,
      promoCode: promoCode,
      promoDiscount: promoDiscount,
      finalTotal: newFinalTotal ?? finalTotal,
      paymentMethod: paymentMethod,
      orderAddress: orderAddress,
      deliveryBoyName: deliveryBoyName,
      deliveryBoyNumber: deliveryBoyNumber,
      deliveryBoyId: deliveryBoyId,
      deliveryBoyProfileImage: deliveryBoyProfileImage,
      deliveryBoyRating: deliveryBoyRating,
      latitude: latitude,
      longitude: longitude,
      deliveryLocation: deliveryLocation,
      deliveryTime: deliveryTime,
      activeStatus: updatedActiveStatus ?? activeStatus,
      orderFrom: orderFrom,
      pincodeId: pincodeId,
      addressId: addressId,
      areaId: areaId,
      bankTransferMessage: bankTransferMessage,
      bankTransferStatus: bankTransferStatus,
      userName: userName,
      discountRupees: discountRupees,
      items: orderItems ?? items,
      date: date,
      createdAt: createdAt,
      status: status,
      remainingTotal: remainingTotal,
      remainingFinal: remainingFinal,
      orderType: orderType,
      pickupAddress: pickupAddress
    );
  }

  Order.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    // order_number is the server side accessor, which already normalises legacy
    // rows. The raw orders_id column can still hold a pre-launch random value.
    ordersId = json['order_number']?.toString();
    date = json['date'].toString();
    createdAt = json['created_at'].toString();
    userId = json['user_id'].toString();
    transactionId = json['transaction_id'].toString();
    otp = json['otp'].toString();
    mobile = json['mobile'].toString();
    orderNote = json['order_note'].toString();
    total = json['total'].toString();
    deliveryCharge = json['delivery_charge'].toString();
    taxAmount = json['tax_amount'].toString();
    taxPercentage = json['tax_percentage'].toString();
    walletBalance = json['wallet_balance'].toString();
    discount = json['discount'].toString();
    promoCode = json['promo_code'].toString();
    promoDiscount = json['promo_discount'].toString();
    finalTotal = json['final_total'].toString();
    paymentMethod = json['payment_method'].toString();
    orderAddress = json['order_address'].toString();
    deliveryBoyName = json['delivery_boy_name'].toString();
    deliveryBoyNumber = json['delivery_boy_mobile'].toString();
    deliveryBoyId = json['delivery_boy_id']?.toString();
    deliveryBoyProfileImage = json['delivery_boy_profile_image']?.toString();
    deliveryBoyRating = json['delivery_boy_rating']?.toString();
    latitude = json['latitude'].toString();
    longitude = json['longitude'].toString();
    deliveryLocation = json['delivery_location'] is Map<String, dynamic> ? json['delivery_location'] as Map<String, dynamic> : null;
    deliveryTime = json['delivery_time'].toString();
    deliveryPin = json['delivery_pin']?.toString() ?? '';
    activeStatus = json['active_status'].toString();
    orderFrom = json['order_from'].toString();
    pincodeId = json['pincode_id'].toString();
    addressId = json['address_id'].toString();
    areaId = json['area_id'].toString();
    bankTransferMessage = json['bank_transfer_message'].toString();
    bankTransferStatus = json['bank_transfer_status'].toString();
    userName = json['user_name'].toString();
    discountRupees = json['discount_rupees'].toString();

    status = ((json['status'] ?? []) as List)
        .map((orderStatus) => List.from(orderStatus))
        .toList();

    items = ((json['items'] ?? []) as List)
        .map((orderItem) => OrderItem.fromJson(Map.from(orderItem ?? {})))
        .toList();
    additionalCharges = (json['additional_charges'] != null && json['additional_charges'] is List)
        ? List<AdditionalCharges>.from(json['additional_charges'].map((x) => AdditionalCharges.fromJson(x)))
        : [];
    remainingTotal = (json['remaining_total']??"0.0").toString();
    remainingFinal = (json['remaining_final']??"0.0").toString();
    orderType = json['order_type']??"doorstep";
    // pickupAddress = (json['pickup_address'] != null && json['pickup_address'].isNotEmpty) ? PickupAddress.fromJson(json['pickup_address'][0]) : null;
    List pickupAddressList = [];

    if (json['pickup_address'] != null) {
      if (json['pickup_address'] is List) {
        pickupAddressList = json['pickup_address'];
      } else if (json['pickup_address'] is Map) {
        pickupAddressList = [json['pickup_address']];
      }
    }

    pickupAddress = pickupAddressList.isNotEmpty ? PickupAddress.fromJson(pickupAddressList[0]) : null;

    // Parse new fields
    groupedByStore = (json['grouped_by_store'] as List<dynamic>?)
        ?.map((e) => GroupedByStore.fromJson(e as Map<String, dynamic>))
        .toList();
    customCombos = json['custom_combos'] as List?;
    cartInfo = json['cart_info'] is Map<String, dynamic> ? json['cart_info'] as Map<String, dynamic> : null;
    billingBreakdown = json['billing_breakdown'] as List?;
    billingSummary = json['billing_summary'] is Map<String, dynamic> ? json['billing_summary'] as Map<String, dynamic> : null;
    zenfooStoreLocation = json['zenfoo_store_location'] is Map<String, dynamic>
        ? ZenfooStoreLocation.fromJson(json['zenfoo_store_location'] as Map<String, dynamic>)
        : null;
  }
}

class OrderItem {
  OrderItem({
    this.id,
    this.userId,
    this.orderId,
    this.productName,
    this.variantName,
    this.productId,
    this.quantity,
    this.price,
    this.taxAmount,
    this.taxPercentage,
    this.subTotal,
    this.status,
    this.activeStatus,
    this.sellerId,
    this.variantId,
    this.name,
    this.manufacturer,
    this.madeIn,
    this.measurement,
    this.unit,
    this.imageUrl,
    this.cancelableStatus,
    this.returnStatus,
    this.sellerName,
    this.tillStatus,
    this.returnRequested,
    this.returnReason,
    this.itemRating,
    this.returnRemarks,
    this.refundAmount,
    this.sellerLatitude,
    this.sellerLongitude,
    this.sellerLatLong,
  });

  String? id;
  String? userId;
  String? orderId;
  String? productName;
  String? variantName;
  String? productId;
  String? quantity;
  String? price;
  String? taxAmount;
  String? taxPercentage;
  String? subTotal;
  String? status;
  String? activeStatus;
  String? sellerId;
  String? variantId;
  String? name;
  String? manufacturer;
  String? madeIn;
  String? measurement;
  String? unit;
  String? imageUrl;
  String? cancelableStatus;
  String? returnStatus;
  String? tillStatus;
  String? sellerName;
  String? returnRequested;
  String? returnReason;
  List<ItemRating>? itemRating;
  String? returnRemarks;
  String? refundAmount;
  String? sellerLatitude;
  String? sellerLongitude;
  String? sellerLatLong;

  OrderItem copyWith(
      {String? itemActiveStatus, List<ItemRating>? updatedItemRating}) {
    return OrderItem(
      id: id,
      userId: userId,
      orderId: orderId,
      productName: productName,
      variantName: variantName,
      productId: productId,
      quantity: quantity,
      price: price,
      taxAmount: taxAmount,
      taxPercentage: taxPercentage,
      subTotal: subTotal,
      status: status,
      activeStatus: itemActiveStatus ?? activeStatus,
      sellerId: sellerId,
      variantId: variantId,
      name: name,
      manufacturer: manufacturer,
      madeIn: madeIn,
      measurement: measurement,
      unit: unit,
      imageUrl: imageUrl,
      cancelableStatus: cancelableStatus,
      returnStatus: returnStatus,
      sellerName: sellerName,
      tillStatus: tillStatus,
      returnRequested: returnRequested,
      returnReason: returnStatus,
      itemRating: updatedItemRating ?? itemRating,
      returnRemarks: returnRemarks,
      refundAmount: refundAmount,
      sellerLatitude: sellerLatitude,
      sellerLongitude: sellerLongitude,
      sellerLatLong: sellerLatLong,
    );
  }

  OrderItem.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    userId = json['user_id'].toString();
    returnStatus = json['return_status'].toString();
    cancelableStatus = json['cancelable_status'].toString();
    tillStatus = json['till_status'].toString();
    orderId = json['order_id'].toString();
    productName = json['product_name'].toString();
    variantName = json['variant_name'].toString();
    productId = json['product_id'].toString();
    quantity = json['quantity'].toString();
    price = json['price'].toString();
    taxAmount = json['tax_amount'].toString();
    taxPercentage = json['tax_percentage'].toString();
    subTotal = json['sub_total'].toString();
    status = json['status'].toString();
    activeStatus = json['active_status'].toString();
    sellerId = json['seller_id'].toString();
    variantId = json['variant_id'].toString();
    name = json['name'].toString();
    manufacturer = json['manufacturer'].toString();
    madeIn = json['made_in'].toString();
    measurement = json['measurement'].toString();
    unit = json['unit'].toString();
    imageUrl = json['image_url'].toString();
    sellerName = json['seller_name'].toString();
    returnRequested = json['return_requested'].toString();
    returnReason = json['return_reason'].toString();

    itemRating = ((json['item_rating'] ?? []) as List)
        .map((orderItem) => ItemRating.fromJson(Map.from(orderItem ?? {})))
        .toList();
    returnRemarks = json['return_remarks']??"";
    refundAmount = (json['refund_amount']??0).toString();

    // Parse seller location from seller_lat_long field
    // The items array only has seller_lat_long, not separate lat/lng fields
    sellerLatLong = json['seller_lat_long']?.toString() ?? '';

    // Initialize as empty
    sellerLatitude = '';
    sellerLongitude = '';

    // Split seller_lat_long if it exists and is not empty
    if (sellerLatLong != null && sellerLatLong!.isNotEmpty && sellerLatLong != 'null') {
      List<String> latLong = sellerLatLong!.split(',');
      if (latLong.length == 2) {
        sellerLatitude = latLong[0].trim();
        sellerLongitude = latLong[1].trim();
      }
    }
  }
}

//

class ItemRating {
  String? id;
  String? productId;
  String? userId;
  String? rate;
  String? review;
  String? status;
  String? updatedAt;
  ItemRatingUser? user;
  List<ItemRatingImages>? images;

  ItemRating(
      {this.id,
      this.productId,
      this.userId,
      this.rate,
      this.review,
      this.status,
      this.updatedAt,
      this.user,
      this.images});

  ItemRating.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    productId = json['product_id'].toString();
    userId = json['user_id'].toString();
    rate = json['rate'].toString();
    review = json['review'].toString();
    status = json['status'].toString();
    updatedAt = json['updated_at'].toString();
    user =
        json['user'] != null ? new ItemRatingUser.fromJson(json['user']) : null;
    if (json['images'] != null) {
      images = <ItemRatingImages>[];
      json['images'].forEach((v) {
        images!.add(new ItemRatingImages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['product_id'] = this.productId;
    data['user_id'] = this.userId;
    data['rate'] = this.rate;
    data['review'] = this.review;
    data['status'] = this.status;
    data['updated_at'] = this.updatedAt;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ItemRatingUser {
  String? id;
  String? name;
  String? profile;

  ItemRatingUser({this.id, this.name, this.profile});

  ItemRatingUser.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'].toString();
    profile = json['profile'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['profile'] = this.profile;
    return data;
  }
}

class ItemRatingImages {
  String? id;
  String? productRatingId;
  String? image;
  String? imageUrl;

  ItemRatingImages({this.id, this.productRatingId, this.image, this.imageUrl});

  ItemRatingImages.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    productRatingId = json['product_rating_id'].toString();
    image = json['image'].toString();
    imageUrl = json['image_url'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['product_rating_id'] = this.productRatingId;
    data['image'] = this.image;
    data['image_url'] = this.imageUrl;
    return data;
  }
}

class ZenfooStoreLocation {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  ZenfooStoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory ZenfooStoreLocation.fromJson(Map<String, dynamic> json) {
    return ZenfooStoreLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PickupAddress {
  String? pickupLatitude;
  String? pickupLongitude;
  String? pickupStoreAddress;
  String? openingTime;
  String? closingTime;
  String? sellerMobile;

  PickupAddress({this.pickupLatitude, this.pickupLongitude, this.pickupStoreAddress, this.openingTime, this.closingTime, this.sellerMobile});

  PickupAddress.fromJson(Map<String, dynamic> json) {
    pickupLatitude = json['pickup_latitude']??"";
    pickupLongitude = json['pickup_longitude']??"";
    pickupStoreAddress = json['pickup_store_address']??"";
    openingTime = json['opening_time']??"";
    closingTime = json['closing_time']??"";
    sellerMobile = json['seller_mobile']??"";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pickup_latitude'] = this.pickupLatitude;
    data['pickup_longitude'] = this.pickupLongitude;
    data['pickup_store_address'] = this.pickupStoreAddress;
    data['opening_time'] = this.openingTime;
    data['closing_time'] = this.closingTime;
    data['seller_mobile'] = this.sellerMobile;
    return data;
  }
}
