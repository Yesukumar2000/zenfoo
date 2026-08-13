class Report {
  String? id;
  String? customerId;
  String? orderId;
  String? orderNumber;
  String? reportType;
  String? description;
  int? status;
  String? statusName;
  String? adminRemarks;
  String? createdAt;
  String? updatedAt;
  bool? isRefundRequested;
  List<ReportStatusChange>? statusChangeJson;
  List<String>? images;
  List<ReportTimeline>? timeline;
  List<ReportStoreWiseItem>? storeWiseItems;
  List<ReportComboItem>? comboItems;
  ReportCustomer? customer;
  ReportDriver? driver;

  // Legacy fields for backward compatibility
  String? resolvedOn;
  String? refundAmount;
  String? supportNote;
  String? userName;
  String? userPhone;
  String? userEmail;
  String? reportedOn;
  String? deliveryDate;
  String? storeVendor;
  String? deliveryPartnerId;
  String? deliveryPartnerName;

  Report({
    this.id,
    this.customerId,
    this.orderId,
    this.orderNumber,
    this.reportType,
    this.description,
    this.status,
    this.statusName,
    this.adminRemarks,
    this.createdAt,
    this.updatedAt,
    this.isRefundRequested,
    this.statusChangeJson,
    this.images,
    this.timeline,
    this.storeWiseItems,
    this.comboItems,
    this.customer,
    this.driver,
    this.resolvedOn,
    this.refundAmount,
    this.supportNote,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.reportedOn,
    this.deliveryDate,
    this.storeVendor,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
  });

  Report.fromJson(Map<String, dynamic> json) {
    id = json['report_id']?.toString() ?? json['id']?.toString();
    customerId = json['customer_id']?.toString();
    orderId = json['order_id']?.toString();
    orderNumber = json['order_number']?.toString();
    reportType = json['report_type']?.toString();
    description = json['description']?.toString();

    // Parse status as int or string
    if (json['status'] is int) {
      status = json['status'];
    } else if (json['status'] is String) {
      status = int.tryParse(json['status'].toString());
    }

    statusName = json['status_name']?.toString();
    adminRemarks = json['admin_remarks']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();

    // Legacy fields
    resolvedOn = json['resolved_on']?.toString();
    refundAmount = json['refund_amount']?.toString();
    supportNote = json['support_note']?.toString();
    userName = json['user_name']?.toString();
    userPhone = json['user_phone']?.toString();
    userEmail = json['user_email']?.toString();
    reportedOn = json['reported_on']?.toString();
    deliveryDate = json['delivery_date']?.toString();
    storeVendor = json['store_vendor']?.toString();
    deliveryPartnerId = json['delivery_partner_id']?.toString();
    deliveryPartnerName = json['delivery_partner_name']?.toString();

    // Safe parse for boolean
    if (json['is_refund_requested'] != null) {
      if (json['is_refund_requested'] is bool) {
        isRefundRequested = json['is_refund_requested'];
      } else if (json['is_refund_requested'] is int) {
        isRefundRequested = json['is_refund_requested'] == 1;
      } else if (json['is_refund_requested'] is String) {
        isRefundRequested = json['is_refund_requested'].toString().toLowerCase() == 'true' ||
            json['is_refund_requested'].toString() == '1';
      }
    }

    // Safe parse for status_change_json
    if (json['status_change_json'] != null && json['status_change_json'] is List) {
      statusChangeJson = <ReportStatusChange>[];
      for (var v in json['status_change_json']) {
        try {
          statusChangeJson!.add(ReportStatusChange.fromJson(v));
        } catch (e) {
          // Skip invalid status change entries
        }
      }
    }

    // Safe parse for images list
    if (json['images'] != null) {
      try {
        images = (json['images'] as List).map((e) => e.toString()).toList();
      } catch (e) {
        images = [];
      }
    } else {
      images = [];
    }

    // Safe parse for timeline
    if (json['timeline'] != null && json['timeline'] is List) {
      timeline = <ReportTimeline>[];
      for (var v in json['timeline']) {
        try {
          timeline!.add(ReportTimeline.fromJson(v));
        } catch (e) {
          // Skip invalid timeline entries
        }
      }
    }

    // Safe parse for store_wise_items
    if (json['store_wise_items'] != null && json['store_wise_items'] is List) {
      storeWiseItems = <ReportStoreWiseItem>[];
      for (var v in json['store_wise_items']) {
        try {
          storeWiseItems!.add(ReportStoreWiseItem.fromJson(v));
        } catch (e) {
          // Skip invalid store items
        }
      }
    }

    // Safe parse for combo_items
    if (json['combo_items'] != null && json['combo_items'] is List) {
      comboItems = <ReportComboItem>[];
      for (var v in json['combo_items']) {
        try {
          comboItems!.add(ReportComboItem.fromJson(v));
        } catch (e) {
          // Skip invalid combo items
        }
      }
    }

    // Safe parse for customer object
    if (json['customer'] != null && json['customer'] is Map) {
      try {
        customer = ReportCustomer.fromJson(json['customer']);
      } catch (e) {
        // Skip if customer parsing fails
      }
    }

    // Safe parse for driver object
    if (json['driver_id'] != null ||
        json['driver_name'] != null ||
        json['delivered_at_time'] != null ||
        (json['delivery_images'] is List &&
            (json['delivery_images'] as List).isNotEmpty)) {
      try {
        driver = ReportDriver.fromJson(json);
      } catch (e) {
        // Skip if driver parsing fails
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['customer_id'] = customerId;
    data['order_id'] = orderId;
    data['order_number'] = orderNumber;
    data['report_type'] = reportType;
    data['description'] = description;
    data['status'] = status;
    data['status_name'] = statusName;
    data['admin_remarks'] = adminRemarks;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_refund_requested'] = isRefundRequested;
    data['resolved_on'] = resolvedOn;
    data['refund_amount'] = refundAmount;
    data['support_note'] = supportNote;
    data['user_name'] = userName;
    data['user_phone'] = userPhone;
    data['user_email'] = userEmail;
    data['reported_on'] = reportedOn;
    data['delivery_date'] = deliveryDate;
    data['store_vendor'] = storeVendor;
    data['delivery_partner_id'] = deliveryPartnerId;
    data['delivery_partner_name'] = deliveryPartnerName;
    data['images'] = images;
    if (statusChangeJson != null) {
      data['status_change_json'] = statusChangeJson!.map((v) => v.toJson()).toList();
    }
    if (timeline != null) {
      data['timeline'] = timeline!.map((v) => v.toJson()).toList();
    }
    if (storeWiseItems != null) {
      data['store_wise_items'] = storeWiseItems!.map((v) => v.toJson()).toList();
    }
    if (comboItems != null) {
      data['combo_items'] = comboItems!.map((v) => v.toJson()).toList();
    }
    if (customer != null) {
      data['customer'] = customer!.toJson();
    }
    if (driver != null) {
      data['driver_id'] = driver!.id;
      data['driver_name'] = driver!.name;
      data['delivered_at_time'] = driver!.deliveredAt;
    }
    return data;
  }
}

class ReportStatusChange {
  int? fromStatus;
  int? toStatus;
  String? statusName;
  String? message;
  int? refundAmount;
  String? changedAt;

  ReportStatusChange({
    this.fromStatus,
    this.toStatus,
    this.statusName,
    this.message,
    this.refundAmount,
    this.changedAt,
  });

  ReportStatusChange.fromJson(Map<String, dynamic> json) {
    if (json['from_status'] is int) {
      fromStatus = json['from_status'];
    } else if (json['from_status'] is String) {
      fromStatus = int.tryParse(json['from_status'].toString());
    }

    if (json['to_status'] is int) {
      toStatus = json['to_status'];
    } else if (json['to_status'] is String) {
      toStatus = int.tryParse(json['to_status'].toString());
    }

    statusName = json['status_name']?.toString();
    message = json['message']?.toString();

    if (json['refund_amount'] is int) {
      refundAmount = json['refund_amount'];
    } else if (json['refund_amount'] is String) {
      refundAmount = int.tryParse(json['refund_amount'].toString());
    }

    changedAt = json['changed_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['from_status'] = fromStatus;
    data['to_status'] = toStatus;
    data['status_name'] = statusName;
    data['message'] = message;
    data['refund_amount'] = refundAmount;
    data['changed_at'] = changedAt;
    return data;
  }
}

class ReportTimeline {
  String? status;
  String? message;
  String? timestamp;

  ReportTimeline({
    this.status,
    this.message,
    this.timestamp,
  });

  ReportTimeline.fromJson(Map<String, dynamic> json) {
    status = json['status']?.toString();
    message = json['message']?.toString();
    timestamp = json['timestamp']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['message'] = message;
    data['timestamp'] = timestamp;
    return data;
  }
}

class ReportStoreWiseItem {
  String? storeId;
  String? storeName;
  String? description;
  List<String>? imageUrls;
  List<ReportItemProduct>? items;

  ReportStoreWiseItem({
    this.storeId,
    this.storeName,
    this.description,
    this.imageUrls,
    this.items,
  });

  ReportStoreWiseItem.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id']?.toString();
    storeName = json['store_name']?.toString();
    description = json['description']?.toString();

    if (json['image_urls'] != null) {
      try {
        imageUrls = (json['image_urls'] as List).map((e) => e.toString()).toList();
      } catch (e) {
        imageUrls = [];
      }
    } else {
      imageUrls = [];
    }

    if (json['items'] != null && json['items'] is List) {
      items = <ReportItemProduct>[];
      for (var v in json['items']) {
        try {
          items!.add(ReportItemProduct.fromJson(v));
        } catch (e) {
          // Skip invalid items
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['description'] = description;
    data['image_urls'] = imageUrls;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ReportComboItem {
  String? id;
  String? comboId;
  String? comboName;
  String? comboQuantity;
  String? subTotal;
  String? description;
  List<String>? imageUrls;
  List<ReportComboProduct>? products;

  ReportComboItem({
    this.id,
    this.comboId,
    this.comboName,
    this.comboQuantity,
    this.subTotal,
    this.description,
    this.imageUrls,
    this.products,
  });

  ReportComboItem.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    comboId = json['combo_id']?.toString();
    comboName = json['combo_name']?.toString();
    comboQuantity = json['combo_quantity']?.toString();
    subTotal = json['sub_total']?.toString();
    description = json['description']?.toString();

    if (json['image_urls'] != null) {
      try {
        imageUrls = (json['image_urls'] as List).map((e) => e.toString()).toList();
      } catch (e) {
        imageUrls = [];
      }
    } else {
      imageUrls = [];
    }

    if (json['products'] != null && json['products'] is List) {
      products = <ReportComboProduct>[];
      for (var v in json['products']) {
        try {
          products!.add(ReportComboProduct.fromJson(v));
        } catch (e) {
          // Skip invalid products
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['combo_id'] = comboId;
    data['combo_name'] = comboName;
    data['combo_quantity'] = comboQuantity;
    data['sub_total'] = subTotal;
    data['description'] = description;
    data['image_urls'] = imageUrls;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ReportItemProduct {
  String? id;
  String? productId;
  String? productImage;
  String? productName;
  String? quantity;
  String? mrp;
  String? productPrice;
  String? subTotal;

  ReportItemProduct({
    this.id,
    this.productId,
    this.productImage,
    this.productName,
    this.quantity,
    this.mrp,
    this.productPrice,
    this.subTotal,
  });

  ReportItemProduct.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    productId = json['product_id']?.toString();
    productImage = json['product_image']?.toString();
    productName = json['product_name']?.toString();
    quantity = json['quantity']?.toString();
    mrp = json['mrp']?.toString();
    productPrice = json['product_price']?.toString();
    subTotal = json['sub_total']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['product_id'] = productId;
    data['product_image'] = productImage;
    data['product_name'] = productName;
    data['quantity'] = quantity;
    data['mrp'] = mrp;
    data['product_price'] = productPrice;
    data['sub_total'] = subTotal;
    return data;
  }
}

class ReportComboProduct {
  String? id;
  String? productId;
  String? productImage;
  String? productName;
  String? quantity;
  String? mrp;
  String? productPrice;
  String? subTotal;

  ReportComboProduct({
    this.id,
    this.productId,
    this.productImage,
    this.productName,
    this.quantity,
    this.mrp,
    this.productPrice,
    this.subTotal,
  });

  ReportComboProduct.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    productId = json['product_id']?.toString();
    productImage = json['product_image']?.toString();
    productName = json['product_name']?.toString();
    quantity = json['quantity']?.toString();
    mrp = json['mrp']?.toString();
    productPrice = json['product_price']?.toString();
    subTotal = json['sub_total']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['product_id'] = productId;
    data['product_image'] = productImage;
    data['product_name'] = productName;
    data['quantity'] = quantity;
    data['mrp'] = mrp;
    data['product_price'] = productPrice;
    data['sub_total'] = subTotal;
    return data;
  }
}

class ReportCustomer {
  String? name;
  String? phone;
  String? email;

  ReportCustomer({
    this.name,
    this.phone,
    this.email,
  });

  ReportCustomer.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    phone = json['phone']?.toString();
    email = json['email']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = email;
    return data;
  }
}

class ReportDriver {
  String? id;
  String? name;
  String? deliveredAt;
  List<String>? deliveryImages;

  ReportDriver({
    this.id,
    this.name,
    this.deliveredAt,
    this.deliveryImages,
  });

  ReportDriver.fromJson(Map<String, dynamic> json) {
    id = json['driver_id']?.toString();
    name = json['driver_name']?.toString();
    deliveredAt = json['delivered_at_time']?.toString();

    if (json['delivery_images'] != null) {
      try {
        deliveryImages =
            (json['delivery_images'] as List).map((e) => e.toString()).toList();
      } catch (e) {
        deliveryImages = [];
      }
    } else {
      deliveryImages = [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['driver_id'] = id;
    data['driver_name'] = name;
    data['delivered_at_time'] = deliveredAt;
    data['delivery_images'] = deliveryImages;
    return data;
  }
}
