import 'package:project/models/combo.dart';

class Cart {
  Cart({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  late final String status;
  late final String message;
  late final String total;
  late final CartData data;

  Cart.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    message = json['message'].toString();
    total = json['total'].toString();
    data = CartData.fromJson(json['data']);
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['status'] = status;
    itemData['message'] = message;
    itemData['total'] = total;
    itemData['data'] = data.toJson();
    return itemData;
  }
}

class CartData {
  CartData({
    required this.userBalance, 
    required this.subTotal,
    required this.savedAmount,
    required this.groupedBySeller,
    required this.adminManagedStore,
    required this.saveForLater,
    required this.selfPickupMode,
    required this.additionalCharges,
    required this.customCombos,
    required this.billingBreakdown,
    required this.billingSummary,
    required this.cartMetadata,
    required this.shopStatusCheck,
  });

  late final String userBalance;
  late final String subTotal;
  late final String savedAmount;
  late final List<SellerGroup> groupedBySeller;
  late final AdminManagedStore adminManagedStore;
  late final List<CartItem> saveForLater;
  late final String selfPickupMode;
  late final List<dynamic> additionalCharges;
  late final List<CustomCombo> customCombos;
  late final List<BillingBreakdownItem> billingBreakdown;
  late final BillingSummary billingSummary;
  late final CartMetadata cartMetadata;
  late final ShopStatusCheck shopStatusCheck;

  CartData.fromJson(Map<String, dynamic> json) {
    userBalance = (json['user_balance'] ?? 0).toString();
    subTotal = json['sub_total'].toString();
    savedAmount = (json['saved_amount'] ?? 0).toString();
    groupedBySeller = (json['grouped_by_seller'] as List?)
            ?.map((e) => SellerGroup.fromJson(e))
            .toList() ??
        [];
    adminManagedStore =
        AdminManagedStore.fromJson(json['admin_managed_store'] ?? {});
    saveForLater = (json['save_for_later'] as List?)
            ?.map((e) => CartItem.fromJson(e))
            .toList() ??
        [];
    selfPickupMode = (json['self_pickup_mode'] ?? 0).toString();
    additionalCharges = json['additional_charges'] ?? [];

    // ✅ parse custom_combos
    customCombos = (json['custom_combos'] as List?)
            ?.map((e) => CustomCombo.fromJson(e))
            .toList() ??
        [];

    billingBreakdown = (json['billing_breakdown'] as List?)
            ?.map((e) => BillingBreakdownItem.fromJson(e))
            .toList() ??
        [];

    billingSummary = BillingSummary.fromJson(json['billing_summary'] ?? {});
    cartMetadata = CartMetadata.fromJson(json['cart_metadata'] ?? {});
    shopStatusCheck = ShopStatusCheck.fromJson(json['shop_status_check'] ?? {});
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['user_balance'] = userBalance;
    itemData['sub_total'] = subTotal;
    itemData['saved_amount'] = savedAmount;
    itemData['grouped_by_seller'] =
        groupedBySeller.map((e) => e.toJson()).toList();
    itemData['admin_managed_store'] = adminManagedStore.toJson();
    itemData['save_for_later'] = saveForLater.map((e) => e.toJson()).toList();
    itemData['self_pickup_mode'] = selfPickupMode;
    itemData['additional_charges'] = additionalCharges;
    itemData['custom_combos'] = customCombos.map((e) => e.toJson()).toList();
    itemData['billing_breakdown'] =
        billingBreakdown.map((e) => e.toJson()).toList();
    itemData['billing_summary'] = billingSummary.toJson();
    itemData['cart_metadata'] = cartMetadata.toJson();
    itemData['shop_status_check'] = shopStatusCheck.toJson();
    return itemData;
  }

  /// All items including combo products if you want them merged
  List<CartItem> getAllCartItems() {
    List<CartItem> allItems = [];
    allItems.addAll(adminManagedStore.items);
    for (var sellerGroup in groupedBySeller) {
      allItems.addAll(sellerGroup.items);
    }
    // Optionally flatten combo products as generic items (if needed)
    // for (var combo in customCombos) {
    //   for (var p in combo.products) {
    //     allItems.add(p);
    //   }
    // }
    return allItems;
  }

  /// Get total count of cart items including combos
  int getTotalItemCount() {
    int regularItemsCount = getAllCartItems().length;

    // Count individual products within each combo
    int comboProductsCount = 0;
    for (var combo in customCombos) {
      comboProductsCount += combo.products.length;
    }

    return regularItemsCount + comboProductsCount;
  }
}

class CustomCombo {
  CustomCombo({
    required this.comboCustomCartId,
    required this.comboId,
    required this.comboName,
    required this.comboDescription,
    required this.comboImageUrl,
    required this.comboType,
    required this.productCount,
    required this.totalProductsPrice,
    required this.totalActualPrice,
    required this.discountPercentage,
    required this.rating,
    required this.ratingCount,
    required this.currency,
    required this.products,
  });

  late final int comboCustomCartId;
  late final int comboId;
  late final String comboName;
  late final String comboDescription;
  late final String comboImageUrl;
  late final String comboType;
  late final int productCount;
  late final double totalProductsPrice;
  late final double totalActualPrice;
  late final double discountPercentage;
  late final double rating;
  late final int ratingCount;
  late final String currency;
  late final List<ComboProduct> products;

  CustomCombo.fromJson(Map<String, dynamic> json) {
    comboCustomCartId =
        int.tryParse(json['combo_custom_cart_id'].toString()) ?? 0;
    comboId = int.tryParse(json['combo_id'].toString()) ?? 0;
    comboName = json['combo_name']?.toString() ?? '';
    comboDescription = json['combo_description']?.toString() ?? '';
    comboImageUrl = json['combo_image_url']?.toString() ?? '';
    comboType = json['combo_type']?.toString() ?? '';
    productCount = int.tryParse(json['product_count'].toString()) ?? 0;
    totalProductsPrice =
        double.tryParse(json['total_products_price'].toString()) ?? 0.0;
    totalActualPrice =
        double.tryParse(json['total_actual_price'].toString()) ?? 0.0;
    discountPercentage =
        double.tryParse(json['discount_percentage'].toString()) ?? 0.0;
    rating = double.tryParse(json['rating'].toString()) ?? 0.0;
    ratingCount = int.tryParse(json['rating_count'].toString()) ?? 0;
    currency = json['currency']?.toString() ?? '';
    products = (json['products'] as List?)
            ?.map((e) => ComboProduct.fromJson(e))
            .toList() ??
        [];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['combo_custom_cart_id'] = comboCustomCartId;
    data['combo_id'] = comboId;
    data['combo_name'] = comboName;
    data['combo_description'] = comboDescription;
    data['combo_image_url'] = comboImageUrl;
    data['combo_type'] = comboType;
    data['product_count'] = productCount;
    data['total_products_price'] = totalProductsPrice;
    data['total_actual_price'] = totalActualPrice;
    data['discount_percentage'] = discountPercentage;
    data['rating'] = rating;
    data['rating_count'] = ratingCount;
    data['currency'] = currency;
    data['products'] = products.map((e) => e.toJson()).toList();
    return data;
  }
}

class SellerGroup {
  SellerGroup({
    required this.sellerId,
    required this.sellerName,
    required this.storeName,
    required this.isSuperMart,
    required this.items,
  });

  late final String sellerId;
  late final String sellerName;
  late final String storeName;
  late final bool isSuperMart;
  late final List<CartItem> items;

  SellerGroup.fromJson(Map<String, dynamic> json) {
    sellerId = json['seller_id'].toString();
    sellerName = json['seller_name'].toString();
    storeName = json['store_name'].toString();
    isSuperMart = json['is_super_mart']?.toString() == '1';
    items =
        (json['items'] as List?)?.map((e) => CartItem.fromJson(e)).toList() ??
            [];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['seller_id'] = sellerId;
    data['seller_name'] = sellerName;
    data['store_name'] = storeName;
    data['is_super_mart'] = isSuperMart;
    data['items'] = items.map((e) => e.toJson()).toList();
    return data;
  }
}

class AdminManagedStore {
  AdminManagedStore({
    required this.items,
  });

  late final List<CartItem> items;

  AdminManagedStore.fromJson(Map<String, dynamic> json) {
    items =
        (json['items'] as List?)?.map((e) => CartItem.fromJson(e)).toList() ??
            [];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['items'] = items.map((e) => e.toJson()).toList();
    return data;
  }
}

class CartItem {
  CartItem({
    required this.productId,
    required this.sellerId,
    required this.productVariantId,
    required this.qty,
    required this.slug,
    required this.codAllowed,
    required this.isUnlimitedStock,
    required this.storeId,
    required this.longitude,
    required this.latitude,
    required this.cityId,
    required this.sellerName,
    required this.isDeliverable,
    required this.measurement,
    required this.discountedPrice,
    required this.price,
    required this.taxableAmount,
    required this.stock,
    required this.totalAllowedQuantity,
    required this.name,
    required this.unitCode,
    required this.status,
    required this.imageUrl,
    required this.isPreOrderItem,
    this.sellerStore,
  });

  late final String productId;
  late final String sellerId;
  late final String productVariantId;
  late final String qty;
  late final String slug;
  late final String codAllowed;
  late final String isUnlimitedStock;
  late final String? storeId;
  late final String longitude;
  late final String latitude;
  late final String cityId;
  late final String sellerName;
  late final String isDeliverable;
  late final String measurement;
  late final String discountedPrice;
  late final String price;
  late final String taxableAmount;
  late final String stock;
  late final String totalAllowedQuantity;
  late final String name;
  late final String unitCode;
  late final String status;
  late final String imageUrl;
  late final int isPreOrderItem;
  late final SellerStore? sellerStore;

  CartItem.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'].toString();
    productVariantId = json['product_variant_id'].toString();
    sellerId = json['seller_id'].toString();
    qty = json['qty'].toString();
    slug = json['slug']?.toString() ?? '';
    codAllowed = (json['cod_allowed'] ?? 0).toString();
    isUnlimitedStock = (json['is_unlimited_stock'] ?? 0).toString();
    storeId = json['store_id']?.toString();
    longitude = json['longitude']?.toString() ?? '';
    latitude = json['latitude']?.toString() ?? '';
    cityId = (json['city_id'] ?? 0).toString();
    sellerName = json['seller_name']?.toString() ?? '';
    isDeliverable = (json['is_deliverable'] ?? 0).toString();
    measurement = json['measurement'].toString();
    discountedPrice = json['discounted_price'].toString();
    price = json['price'].toString();
    taxableAmount = json['taxable_amount']?.toString() ??
        json['discounted_price'].toString();
    stock = json['stock'].toString();
    totalAllowedQuantity = json['total_allowed_quantity'].toString();
    name = json['name'].toString();
    unitCode = json['unit_code'].toString();
    status = json['status'].toString();
    imageUrl = json['image_url'].toString();
    isPreOrderItem = int.tryParse(
          (json['is_pre_order_item'] ?? json['product']?['is_pre_order_item'])
                  ?.toString() ??
              '0') ??
        0;
    sellerStore = json['seller_store'] != null
        ? SellerStore.fromJson(json['seller_store'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['product_id'] = productId;
    data['seller_id'] = sellerId;
    data['product_variant_id'] = productVariantId;
    data['qty'] = qty;
    data['slug'] = slug;
    data['cod_allowed'] = codAllowed;
    data['is_unlimited_stock'] = isUnlimitedStock;
    data['store_id'] = storeId;
    data['longitude'] = longitude;
    data['latitude'] = latitude;
    data['city_id'] = cityId;
    data['seller_name'] = sellerName;
    data['is_deliverable'] = isDeliverable;
    data['measurement'] = measurement;
    data['discounted_price'] = discountedPrice;
    data['price'] = price;
    data['taxable_amount'] = taxableAmount;
    data['stock'] = stock;
    data['total_allowed_quantity'] = totalAllowedQuantity;
    data['name'] = name;
    data['unit_code'] = unitCode;
    data['status'] = status;
    data['image_url'] = imageUrl;
    data['is_pre_order_item'] = isPreOrderItem;
    if (sellerStore != null) {
      data['seller_store'] = sellerStore!.toJson();
    }
    return data;
  }
}

class SellerStore {
  SellerStore({
    required this.id,
    required this.managedByAdmin,
    required this.isSuperMart,
    required this.isMeat,
    required this.isActive,
    required this.name,
    required this.icon,
    required this.description,
    required this.image,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    required this.vendorImg,
    required this.iconUrl,
    required this.imageUrl,
    required this.vendorImgUrl,
  });

  late final int id;
  late final bool managedByAdmin;
  late final bool isSuperMart;
  late final bool isMeat;
  late final bool isActive;
  late final String name;
  late final String icon;
  late final String description;
  late final String image;
  late final String color;
  late final String createdAt;
  late final String updatedAt;
  late final String vendorImg;
  late final String iconUrl;
  late final String imageUrl;
  late final String vendorImgUrl;

  SellerStore.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id'].toString()) ?? 0;
    managedByAdmin = json['managed_by_admin'] == true ||
        json['managed_by_admin'].toString() == '1';
    isSuperMart = json['is_super_mart'] == true ||
        json['is_super_mart'].toString() == '1';
    isMeat = json['is_meat'] == true || json['is_meat'].toString() == '1';
    isActive = json['is_active'] == true || json['is_active'].toString() == '1';
    name = json['name']?.toString() ?? '';
    icon = json['icon']?.toString() ?? '';
    description = json['description']?.toString() ?? '';
    image = json['image']?.toString() ?? '';
    color = json['color']?.toString() ?? '';
    createdAt = json['created_at']?.toString() ?? '';
    updatedAt = json['updated_at']?.toString() ?? '';
    vendorImg = json['vendor_img']?.toString() ?? '';
    iconUrl = json['icon_url']?.toString() ?? '';
    imageUrl = json['image_url']?.toString() ?? '';
    vendorImgUrl = json['vendor_img_url']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['managed_by_admin'] = managedByAdmin;
    data['is_super_mart'] = isSuperMart;
    data['is_active'] = isActive;
    data['name'] = name;
    data['icon'] = icon;
    data['description'] = description;
    data['image'] = image;
    data['color'] = color;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['vendor_img'] = vendorImg;
    data['icon_url'] = iconUrl;
    data['image_url'] = imageUrl;
    data['vendor_img_url'] = vendorImgUrl;
    return data;
  }
}

class BillingBreakdownItem {
  BillingBreakdownItem({
    required this.type,
    required this.label,
    required this.description,
    required this.amount,
    required this.currency,
    required this.isCredit,
    this.isTotal = false,
    this.distanceKm,
    this.sellerId,
    this.sellerName,
    this.promoCode,
    this.taxPercentage,
    this.originalAmount,
  });

  late final String type;
  late final String label;
  late final String description;
  late final double amount;
  late final String currency;
  late final bool isCredit;
  late final bool isTotal;
  late final double? distanceKm;
  late final int? sellerId;
  late final String? sellerName;
  late final String? promoCode;
  late final double? taxPercentage;
  late final double? originalAmount;

  BillingBreakdownItem.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString() ?? '';
    label = json['label']?.toString() ?? '';
    description = json['description']?.toString() ?? '';
    amount = double.tryParse(json['amount'].toString()) ?? 0.0;
    currency = json['currency']?.toString() ?? '₹';
    isCredit = json['is_credit'] == true;
    isTotal = json['is_total'] == true;
    distanceKm = json['distance_km'] != null
        ? double.tryParse(json['distance_km'].toString())
        : null;
    sellerId = json['seller_id'] != null
        ? int.tryParse(json['seller_id'].toString())
        : null;
    sellerName = json['seller_name']?.toString();
    promoCode = json['promo_code']?.toString();
    taxPercentage = json['tax_percentage'] != null
        ? double.tryParse(json['tax_percentage'].toString())
        : null;
    originalAmount = json['original_amount'] != null
        ? double.tryParse(json['original_amount'].toString())
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['type'] = type;
    data['label'] = label;
    data['description'] = description;
    data['amount'] = amount;
    data['currency'] = currency;
    data['is_credit'] = isCredit;
    data['is_total'] = isTotal;
    if (distanceKm != null) data['distance_km'] = distanceKm;
    if (sellerId != null) data['seller_id'] = sellerId;
    if (sellerName != null) data['seller_name'] = sellerName;
    if (promoCode != null) data['promo_code'] = promoCode;
    if (taxPercentage != null) data['tax_percentage'] = taxPercentage;
    if (originalAmount != null) data['original_amount'] = originalAmount;
    return data;
  }
}

class BillingSummary {
  BillingSummary({
    required this.itemsSubtotal,
    required this.deliveryCharge,
    required this.deliveryTip,
    required this.gstCharges,
    required this.additionalCharges,
    required this.discount,
    required this.savings,
    required this.toBePaid,
    required this.currency,
    this.walletDeduction = 0.0,
    this.walletAmountValue,
  });

  late final double itemsSubtotal;
  late final double deliveryCharge;
  late final double deliveryTip;
  late final double gstCharges;
  late final double additionalCharges;
  late final double discount;
  late final double savings;
  late final double toBePaid;
  late final String currency;

  /// Wallet amount actually applied to this cart.
  late final double walletDeduction;

  /// Partial wallet amount the customer chose. Null means "use the whole
  /// balance", which is the default.
  late final double? walletAmountValue;

  BillingSummary.fromJson(Map<String, dynamic> json) {
    itemsSubtotal = double.tryParse(json['items_subtotal'].toString()) ?? 0.0;
    deliveryCharge = double.tryParse(json['delivery_charge'].toString()) ?? 0.0;
    deliveryTip = double.tryParse(json['delivery_tip'].toString()) ?? 0.0;
    gstCharges = double.tryParse(json['gst_charges'].toString()) ?? 0.0;
    additionalCharges =
        double.tryParse(json['additional_charges'].toString()) ?? 0.0;
    discount = double.tryParse(json['discount'].toString()) ?? 0.0;
    savings = double.tryParse(json['savings'].toString()) ?? 0.0;
    toBePaid = double.tryParse(json['to_be_paid'].toString()) ?? 0.0;
    currency = json['currency']?.toString() ?? '₹';
    walletDeduction =
        double.tryParse(json['wallet_deduction'].toString()) ?? 0.0;
    walletAmountValue = json['wallet_amount_value'] == null
        ? null
        : double.tryParse(json['wallet_amount_value'].toString());
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['items_subtotal'] = itemsSubtotal;
    data['delivery_charge'] = deliveryCharge;
    data['delivery_tip'] = deliveryTip;
    data['gst_charges'] = gstCharges;
    data['additional_charges'] = additionalCharges;
    data['discount'] = discount;
    data['savings'] = savings;
    data['to_be_paid'] = toBePaid;
    data['currency'] = currency;
    data['wallet_deduction'] = walletDeduction;
    data['wallet_amount_value'] = walletAmountValue;
    return data;
  }
}

class CartMetadata {
  CartMetadata({
    this.promocodeId,
    required this.deliveryTip,
    this.deliveryInstructions,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    required this.sellerNotes,
    required this.comboNotes,
  });

  late final int? promocodeId;
  late final double deliveryTip;
  late final String? deliveryInstructions;
  late final String? contactName;
  late final String? contactPhone;
  late final String? contactEmail;
  late final Map<String, String> sellerNotes;
  late final Map<String, String> comboNotes;

  CartMetadata.fromJson(Map<String, dynamic> json) {
    promocodeId = json['promocode_id'] != null
        ? int.tryParse(json['promocode_id'].toString())
        : null;
    deliveryTip = double.tryParse(json['delivery_tip'].toString()) ?? 0.0;
    deliveryInstructions = json['delivery_instructions']?.toString();
    contactName = json['contact_name']?.toString();
    contactPhone = json['contact_phone']?.toString();
    contactEmail = json['contact_email']?.toString();

    // Parse seller_notes - handle both Map and List (empty array)
    if (json['seller_notes'] != null && json['seller_notes'] is Map) {
      sellerNotes = <String, String>{};
      (json['seller_notes'] as Map).forEach((key, value) {
        sellerNotes[key.toString()] = value.toString();
      });
    } else {
      // Handle null, empty array, or any other type
      sellerNotes = <String, String>{};
    }

    // Parse combo_notes - handle both Map and List (empty array)
    if (json['combo_notes'] != null && json['combo_notes'] is Map) {
      comboNotes = <String, String>{};
      (json['combo_notes'] as Map).forEach((key, value) {
        comboNotes[key.toString()] = value.toString();
      });
    } else {
      // Handle null, empty array, or any other type
      comboNotes = <String, String>{};
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (promocodeId != null) data['promocode_id'] = promocodeId;
    data['delivery_tip'] = deliveryTip;
    if (deliveryInstructions != null) {
      data['delivery_instructions'] = deliveryInstructions;
    }
    if (contactName != null) data['contact_name'] = contactName;
    if (contactPhone != null) data['contact_phone'] = contactPhone;
    if (contactEmail != null) data['contact_email'] = contactEmail;
    data['seller_notes'] = sellerNotes;
    data['combo_notes'] = comboNotes;
    return data;
  }
}

class ShopStatusCheck {
  late final bool allSellersOnline;
  late final List<OfflineProduct> offlineProducts;
  late final String message;

  ShopStatusCheck({
    required this.allSellersOnline,
    required this.offlineProducts,
    required this.message,
  });

  ShopStatusCheck.fromJson(Map<String, dynamic> json) {
    allSellersOnline = (json['all_sellers_online'] ?? 1) == 1;
    offlineProducts = (json['offline_products'] as List?)
            ?.map((e) => OfflineProduct.fromJson(e))
            .toList() ??
        [];
    message = (json['message'] ?? '').toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'all_sellers_online': allSellersOnline ? 1 : 0,
      'offline_products': offlineProducts.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}

class OfflineProduct {
  late final String productId;
  late final String productVariantId;
  late final String sellerId;
  late final String sellerName;

  OfflineProduct({
    required this.productId,
    required this.productVariantId,
    required this.sellerId,
    required this.sellerName,
  });

  OfflineProduct.fromJson(Map<String, dynamic> json) {
    productId = (json['product_id'] ?? '').toString();
    productVariantId = (json['product_variant_id'] ?? '').toString();
    sellerId = (json['seller_id'] ?? '').toString();
    sellerName = (json['seller_name'] ?? '').toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_variant_id': productVariantId,
      'seller_id': sellerId,
      'seller_name': sellerName,
    };
  }
}
