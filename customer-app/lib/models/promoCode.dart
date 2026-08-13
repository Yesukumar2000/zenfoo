class PromoCode {
  PromoCode({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  late final String status;
  late final String message;
  late final String total;
  late final List<PromoCodeData> data;

  PromoCode.fromJson(Map<String, dynamic> json) {
    status = json['status'].toString();
    message = json['message'].toString();
    total = json['total'].toString();
    data =
        List.from(json['data']).map((e) => PromoCodeData.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['status'] = status;
    itemData['message'] = message;
    itemData['total'] = total;
    itemData['data'] = data.map((e) => e.toJson()).toList();
    return itemData;
  }
}

class PromoCodeData {
  PromoCodeData({
    required this.id,
    required this.isApplicable,
    required this.message,
    required this.promoCode,
    required this.imageUrl,
    required this.promoCodeMessage,
    required this.total,
    required this.discount,
    required this.discountedAmount,
  });

  late final String id;
  late final String isApplicable;
  late final String message;
  late final String promoCode;
  late final String imageUrl;
  late final String promoCodeMessage;
  late final String total;
  late final String discount;
  late final String discountedAmount;
  late final List<String> seeMore;
  late final String applicableMessage;

  PromoCodeData.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    isApplicable = json['is_applicable'].toString();
    message = json['message'].toString();
    promoCode = json['promo_code'].toString();
    imageUrl = json['image_url'].toString();
    promoCodeMessage = json['promo_code_message'].toString();
    total = json['total'].toString();
    discount = json['discount'].toString();
    discountedAmount = json['discounted_amount'].toString();
    seeMore = json['see_more'] != null
        ? List<String>.from(json['see_more'])
        : [];
    applicableMessage = json['applicable_message']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['id'] = id;
    itemData['is_applicable'] = isApplicable;
    itemData['message'] = message;
    itemData['promo_code'] = promoCode;
    itemData['image_url'] = imageUrl;
    itemData['promo_code_message'] = promoCodeMessage;
    itemData['total'] = total;
    itemData['discount'] = discount;
    itemData['discounted_amount'] = discountedAmount;
    itemData['see_more'] = seeMore;
    itemData['applicable_message'] = applicableMessage;
    return itemData;
  }
}


extension PromoCodeDataExtension on PromoCodeData {
  List<String> getTermsAndConditions() {
    // Parse your terms from the API or return default terms
    return [
      'Offer valid only for select stores',
      'Coupon code can be applied only once',
      'Offer valid till ${12 ?? "Dec 31, 2025"}',
      'Cannot be clubbed with other offers',
    ];
  }
}
