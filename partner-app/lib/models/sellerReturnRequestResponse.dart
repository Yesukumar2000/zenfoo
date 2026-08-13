class SellerReturnRequestResponse {
  String? status;
  String? message;
  SellerReturnRequestData? data;

  SellerReturnRequestResponse({this.status, this.message, this.data});

  SellerReturnRequestResponse.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    message = json['message']?.toString();
    data = json['data'] != null ? SellerReturnRequestData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class SellerReturnRequestData {
  List<SellerReturnRequest>? returns;
  SellerReturnRequestPagination? pagination;

  SellerReturnRequestData({this.returns, this.pagination});

  SellerReturnRequestData.fromJson(Map<String, dynamic> json) {
    if (json['returns'] != null) {
      returns = <SellerReturnRequest>[];
      json['returns'].forEach((v) {
        returns!.add(new SellerReturnRequest.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? SellerReturnRequestPagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.returns != null) {
      data['returns'] = this.returns!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class SellerReturnRequest {
  int? returnId;
  int? reportId;
  int? sellerId;
  int? customerId;
  String? date;
  List<int>? productIds;
  List<SellerReturnProduct>? products;
  int? deliveryPartnerId;
  String? deliveredDate;
  int? isReturnAccepted;
  String? returnStatus;
  SellerReturnReport? report;
  SellerReturnCustomer? customer;
  SellerReturnCustomerAddress? customerAddress;
  SellerReturnDeliveryPartner? deliveryPartner;
  String? deliveryDate;
  SellerReturnDeliveryImages? deliveryImages;

  SellerReturnRequest(
      {this.returnId,
      this.reportId,
      this.sellerId,
      this.customerId,
      this.date,
      this.productIds,
      this.products,
      this.deliveryPartnerId,
      this.deliveredDate,
      this.isReturnAccepted,
      this.returnStatus,
      this.report,
      this.customer,
      this.customerAddress,
      this.deliveryPartner,
      this.deliveryDate,
      this.deliveryImages});

  SellerReturnRequest.fromJson(Map<String, dynamic> json) {
    returnId = json['return_id'] is int ? json['return_id'] : int.tryParse(json['return_id']?.toString() ?? '');
    reportId = json['report_id'] is int ? json['report_id'] : int.tryParse(json['report_id']?.toString() ?? '');
    sellerId = json['seller_id'] is int ? json['seller_id'] : int.tryParse(json['seller_id']?.toString() ?? '');
    customerId = json['customer_id'] is int ? json['customer_id'] : int.tryParse(json['customer_id']?.toString() ?? '');
    date = json['date']?.toString();
    productIds = json['product_ids'] != null ? List<int>.from(json['product_ids'].map((x) => x is int ? x : int.tryParse(x.toString()) ?? 0)) : null;
    if (json['products'] != null) {
      products = <SellerReturnProduct>[];
      json['products'].forEach((v) {
        products!.add(new SellerReturnProduct.fromJson(v));
      });
    }
    deliveryPartnerId = json['delivery_partner_id'] is int ? json['delivery_partner_id'] : int.tryParse(json['delivery_partner_id']?.toString() ?? '');
    deliveredDate = json['delivered_date']?.toString();
    isReturnAccepted = json['is_return_accepted'] is int ? json['is_return_accepted'] : int.tryParse(json['is_return_accepted']?.toString() ?? '');
    returnStatus = json['return_status']?.toString();
    report =
        json['report'] != null ? SellerReturnReport.fromJson(json['report']) : null;
    customer = json['customer'] != null
        ? SellerReturnCustomer.fromJson(json['customer'])
        : null;
    customerAddress = json['customer_address'] != null
        ? SellerReturnCustomerAddress.fromJson(json['customer_address'])
        : null;
    deliveryPartner = json['delivery_partner'] != null
        ? SellerReturnDeliveryPartner.fromJson(json['delivery_partner'])
        : null;
    deliveryDate = json['delivery_date']?.toString();
    deliveryImages = json['delivery_images'] != null
        ? SellerReturnDeliveryImages.fromJson(json['delivery_images'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['return_id'] = this.returnId;
    data['report_id'] = this.reportId;
    data['seller_id'] = this.sellerId;
    data['customer_id'] = this.customerId;
    data['date'] = this.date;
    data['product_ids'] = this.productIds;
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    data['delivery_partner_id'] = this.deliveryPartnerId;
    data['delivered_date'] = this.deliveredDate;
    data['is_return_accepted'] = this.isReturnAccepted;
    data['return_status'] = this.returnStatus;
    if (this.report != null) {
      data['report'] = this.report!.toJson();
    }
    if (this.customer != null) {
      data['customer'] = this.customer!.toJson();
    }
    if (this.customerAddress != null) {
      data['customer_address'] = this.customerAddress!.toJson();
    }
    if (this.deliveryPartner != null) {
      data['delivery_partner'] = this.deliveryPartner!.toJson();
    }
    data['delivery_date'] = this.deliveryDate;
    if (this.deliveryImages != null) {
      data['delivery_images'] = this.deliveryImages!.toJson();
    }
    return data;
  }
}

class SellerReturnProduct {
  int? productId;
  String? productName;
  String? image;
  String? measurement;
  int? quantity;

  SellerReturnProduct(
      {this.productId, this.productName, this.image, this.measurement, this.quantity});

  SellerReturnProduct.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? '');
    productName = json['product_name']?.toString();
    image = json['image']?.toString();
    measurement = json['measurement']?.toString();
    quantity = json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['image'] = this.image;
    data['measurement'] = this.measurement;
    data['quantity'] = this.quantity;
    return data;
  }
}

class SellerReturnReport {
  int? orderId;
  String? reportType;
  String? description;
  bool? isRefundRequested;
  int? status;
  String? statusName;
  String? adminRemarks;
  List<SellerReturnSelectedItem>? selectedItems;
  List<SellerReturnSelectedComboItem>? selectedComboItems;
  String? createdAt;
  String? updatedAt;

  SellerReturnReport(
      {this.orderId,
      this.reportType,
      this.description,
      this.isRefundRequested,
      this.status,
      this.statusName,
      this.adminRemarks,
      this.selectedItems,
      this.selectedComboItems,
      this.createdAt,
      this.updatedAt});

  SellerReturnReport.fromJson(Map<String, dynamic> json) {
    orderId = json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id']?.toString() ?? '');
    reportType = json['report_type']?.toString();
    description = json['description']?.toString();
    isRefundRequested = json['is_refund_requested'] is bool ? json['is_refund_requested'] : (json['is_refund_requested']?.toString() == '1' || json['is_refund_requested']?.toString() == 'true');
    status = json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? '');
    statusName = json['status_name']?.toString();
    adminRemarks = json['admin_remarks']?.toString();
    if (json['selected_items'] != null) {
      selectedItems = <SellerReturnSelectedItem>[];
      json['selected_items'].forEach((v) {
        selectedItems!.add(new SellerReturnSelectedItem.fromJson(v));
      });
    }
    if (json['selected_combo_items'] != null) {
      selectedComboItems = <SellerReturnSelectedComboItem>[];
      json['selected_combo_items'].forEach((v) {
        selectedComboItems!.add(new SellerReturnSelectedComboItem.fromJson(v));
      });
    }
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['order_id'] = this.orderId;
    data['report_type'] = this.reportType;
    data['description'] = this.description;
    data['is_refund_requested'] = this.isRefundRequested;
    data['status'] = this.status;
    data['status_name'] = this.statusName;
    data['admin_remarks'] = this.adminRemarks;
    if (this.selectedItems != null) {
      data['selected_items'] = this.selectedItems!.map((v) => v.toJson()).toList();
    }
    if (this.selectedComboItems != null) {
      data['selected_combo_items'] =
          this.selectedComboItems!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class SellerReturnSelectedItem {
  String? storeId;
  String? storeName;
  String? description;
  List<dynamic>? imageUrls;
  List<SellerReturnSelectedItemItem>? items;

  SellerReturnSelectedItem(
      {this.storeId,
      this.storeName,
      this.description,
      this.imageUrls,
      this.items});

  SellerReturnSelectedItem.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id']?.toString();
    storeName = json['store_name']?.toString();
    description = json['description']?.toString();
    imageUrls = json['image_urls'] != null ? List<dynamic>.from(json['image_urls'].map((x) => x?.toString())) : null;
    if (json['items'] != null) {
      items = <SellerReturnSelectedItemItem>[];
      json['items'].forEach((v) {
        items!.add(new SellerReturnSelectedItemItem.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['store_name'] = this.storeName;
    data['description'] = this.description;
    data['image_urls'] = this.imageUrls;
    if (this.items != null) {
      data['items'] = this.items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SellerReturnSelectedItemItem {
  int? productId;
  String? productName;
  String? variantMeasurement;
  int? price;
  int? actualPrice;
  int? quantity;
  int? subTotal;

  SellerReturnSelectedItemItem(
      {this.productId,
      this.productName,
      this.variantMeasurement,
      this.price,
      this.actualPrice,
      this.quantity,
      this.subTotal});

  SellerReturnSelectedItemItem.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? '');
    productName = json['product_name']?.toString();
    variantMeasurement = json['variant_measurement']?.toString();
    price = json['price'] is int ? json['price'] : int.tryParse(json['price']?.toString() ?? '');
    actualPrice = json['actual_price'] is int ? json['actual_price'] : int.tryParse(json['actual_price']?.toString() ?? '');
    quantity = json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '');
    subTotal = json['sub_total'] is int ? json['sub_total'] : int.tryParse(json['sub_total']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['variant_measurement'] = this.variantMeasurement;
    data['price'] = this.price;
    data['actual_price'] = this.actualPrice;
    data['quantity'] = this.quantity;
    data['sub_total'] = this.subTotal;
    return data;
  }
}

class SellerReturnSelectedComboItem {
  SellerReturnSelectedComboItem.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    return data;
  }
}

class SellerReturnCustomer {
  int? id;
  String? name;
  String? mobile;
  String? email;

  SellerReturnCustomer({this.id, this.name, this.mobile, this.email});

  SellerReturnCustomer.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    mobile = json['mobile']?.toString();
    email = json['email']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['mobile'] = this.mobile;
    data['email'] = this.email;
    return data;
  }
}

class SellerReturnCustomerAddress {
  String? address;
  String? landmark;
  String? city;
  String? pincode;
  String? latLong;
  String? fullAddress;

  SellerReturnCustomerAddress(
      {this.address,
      this.landmark,
      this.city,
      this.pincode,
      this.latLong,
      this.fullAddress});

  SellerReturnCustomerAddress.fromJson(Map<String, dynamic> json) {
    address = json['address']?.toString();
    landmark = json['landmark']?.toString();
    city = json['city']?.toString();
    pincode = json['pincode']?.toString();
    latLong = json['lat_long']?.toString();
    fullAddress = json['full_address']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['address'] = this.address;
    data['landmark'] = this.landmark;
    data['city'] = this.city;
    data['pincode'] = this.pincode;
    data['lat_long'] = this.latLong;
    data['full_address'] = this.fullAddress;
    return data;
  }
}

class SellerReturnDeliveryPartner {
  int? id;
  String? name;
  String? mobile;

  SellerReturnDeliveryPartner({this.id, this.name, this.mobile});

  SellerReturnDeliveryPartner.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    mobile = json['mobile']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['mobile'] = this.mobile;
    return data;
  }
}

class SellerReturnDeliveryImages {
  List<dynamic>? customerGivenImages;
  List<String>? driverPickupImages;
  List<String>? deliveryBeforeImages;

  SellerReturnDeliveryImages(
      {this.customerGivenImages,
      this.driverPickupImages,
      this.deliveryBeforeImages});

  SellerReturnDeliveryImages.fromJson(Map<String, dynamic> json) {
    customerGivenImages = json['customer_given_images'] != null ? List<dynamic>.from(json['customer_given_images'].map((x) => x?.toString())) : null;
    driverPickupImages = json['driver_pickup_images'] != null ? List<String>.from(json['driver_pickup_images'].map((x) => x?.toString() ?? '')) : null;
    deliveryBeforeImages = json['delivery_before_images'] != null ? List<String>.from(json['delivery_before_images'].map((x) => x?.toString() ?? '')) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['customer_given_images'] = this.customerGivenImages;
    data['driver_pickup_images'] = this.driverPickupImages;
    data['delivery_before_images'] = this.deliveryBeforeImages;
    return data;
  }
}

class SellerReturnRequestPagination {
  int? currentPage;
  int? perPage;
  int? total;
  int? totalPages;

  SellerReturnRequestPagination(
      {this.currentPage, this.perPage, this.total, this.totalPages});

  SellerReturnRequestPagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'] is int ? json['current_page'] : int.tryParse(json['current_page']?.toString() ?? '');
    perPage = json['per_page'] is int ? json['per_page'] : int.tryParse(json['per_page']?.toString() ?? '');
    total = json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '');
    totalPages = json['total_pages'] is int ? json['total_pages'] : int.tryParse(json['total_pages']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_page'] = this.currentPage;
    data['per_page'] = this.perPage;
    data['total'] = this.total;
    data['total_pages'] = this.totalPages;
    return data;
  }
}
