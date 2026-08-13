class PaytmConfigData {
  String? merchantId;
  String? website;
  String? industryType;
  String? channelId;
  String? environment;
  String? callbackUrl;

  PaytmConfigData({
    this.merchantId,
    this.website,
    this.industryType,
    this.channelId,
    this.environment,
    this.callbackUrl,
  });

  PaytmConfigData.fromJson(Map<String, dynamic> json) {
    merchantId = json['merchant_id']?.toString();
    website = json['website']?.toString();
    industryType = json['industry_type']?.toString();
    channelId = json['channel_id']?.toString();
    environment = json['environment']?.toString();
    callbackUrl = json['callback_url']?.toString();
  }

  bool get isStaging => environment == "test";
}
