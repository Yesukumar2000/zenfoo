class DeliveryBoyOrderReturnRequest {
  String? status;
  String? message;
  String? total;
  List<DeliveryBoyOrderReturnRequestData>? data;

  DeliveryBoyOrderReturnRequest({this.status, this.message, this.total, this.data});

  DeliveryBoyOrderReturnRequest.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    message = json['message'];
    total = json['total'].toString();
    if (json['data'] != null) {
      data = <DeliveryBoyOrderReturnRequestData>[];
      json['data'].forEach((v) {
        data!.add(new DeliveryBoyOrderReturnRequestData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    data['total'] = this.total;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DeliveryBoyOrderReturnRequestData {
  String? id;
  String? userId;
  String? productVariantId;
  String? orderId;
  String? orderItemId;
  String? reason;
  String? status;
  String? remarks;
  String? deliveryBoyId;
  String? cancellationReason;
  String? createdAt;
  String? updatedAt;
  String? customerName;
  String? customerMobile;
  String? quantity;
  String? price;
  String? subTotal;
  String? discountedPrice;
  String? productName;
  String? variantName;
  String? deliveryAddress;
  String? deliveryMobile;
  String? finalTotal;
  String? paymentMethod;
  String? deliveryBoyName;
  String? cityId;

  DeliveryBoyOrderReturnRequestData(
      {this.id,
      this.userId,
      this.productVariantId,
      this.orderId,
      this.orderItemId,
      this.reason,
      this.status,
      this.remarks,
      this.deliveryBoyId,
      this.cancellationReason,
      this.createdAt,
      this.updatedAt,
      this.customerName,
      this.customerMobile,
      this.quantity,
      this.price,
      this.subTotal,
      this.discountedPrice,
      this.productName,
      this.variantName,
      this.deliveryAddress,
      this.deliveryMobile,
      this.finalTotal,
      this.paymentMethod,
      this.deliveryBoyName,
      this.cityId});

  DeliveryBoyOrderReturnRequestData.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    userId = json['user_id'].toString();
    productVariantId = json['product_variant_id'].toString();
    orderId = json['order_id'].toString();
    orderItemId = json['order_item_id'].toString();
    reason = json['reason']??"";
    status = json['status'].toString();
    remarks = json['remarks']??"";
    deliveryBoyId = json['delivery_boy_id'].toString();
    cancellationReason = json['cancellation_reason']??"";
    createdAt = json['created_at']??"";
    updatedAt = json['updated_at']??"";
    customerName = json['customer_name']??"";
    customerMobile = json['customer_mobile']??"";
    quantity = json['quantity'].toString();
    price = json['price'].toString();
    subTotal = json['sub_total'].toString();
    discountedPrice = json['discounted_price'].toString();
    productName = json['product_name']??"";
    variantName = json['variant_name']??"";
    deliveryAddress = json['delivery_address']??"";
    deliveryMobile = json['delivery_mobile']??"";
    finalTotal = json['final_total'].toString();
    paymentMethod = json['payment_method']??"";
    deliveryBoyName = json['delivery_boy_name']??"";
    cityId = json['city_id'].toString(); 
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['product_variant_id'] = this.productVariantId;
    data['order_id'] = this.orderId;
    data['order_item_id'] = this.orderItemId;
    data['reason'] = this.reason;
    data['status'] = this.status;
    data['remarks'] = this.remarks;
    data['delivery_boy_id'] = this.deliveryBoyId;
    data['cancellation_reason'] = this.cancellationReason;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['customer_name'] = this.customerName;
    data['customer_mobile'] = this.customerMobile;
    data['quantity'] = this.quantity;
    data['price'] = this.price;
    data['sub_total'] = this.subTotal;
    data['discounted_price'] = this.discountedPrice;
    data['product_name'] = this.productName;
    data['variant_name'] = this.variantName;
    data['delivery_address'] = this.deliveryAddress;
    data['delivery_mobile'] = this.deliveryMobile;
    data['final_total'] = this.finalTotal;
    data['payment_method'] = this.paymentMethod;
    data['delivery_boy_name'] = this.deliveryBoyName;
    data['city_id'] = this.cityId;
    return data;
  }
}