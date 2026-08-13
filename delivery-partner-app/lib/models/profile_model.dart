// To parse this JSON data, do
//
//     final profileModel = profileModelFromJson(jsonString);

import 'dart:convert';

ProfileModel profileModelFromJson(String str) => ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
    int? responseCode;
    bool? result;
    String? message;
    General? general;
    CustomerData? customerData;

    ProfileModel({
        this.responseCode,
        this.result,
        this.message,
        this.general,
        this.customerData,
    });

    factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        responseCode: json["ResponseCode"],
        result: json["Result"],
        message: json["message"],
        general: json["general"] == null ? null : General.fromJson(json["general"]),
        customerData: json["customer_data"] == null ? null : CustomerData.fromJson(json["customer_data"]),
    );

    Map<String, dynamic> toJson() => {
        "ResponseCode": responseCode,
        "Result": result,
        "message": message,
        "general": general?.toJson(),
        "customer_data": customerData?.toJson(),
    };
}

class CustomerData {
    int? id;
    String? profileImage;
    String? name;
    String? email;
    String? countryCode;
    String? phone;
    String? password;
    String? status;
    String? referralCode;
    String? wallet;
    DateTime? date;
    dynamic oneSignalId;
    dynamic fcmToken;
    dynamic platform;
    dynamic tokenUpdatedAt;

    CustomerData({
        this.id,
        this.profileImage,
        this.name,
        this.email,
        this.countryCode,
        this.phone,
        this.password,
        this.status,
        this.referralCode,
        this.wallet,
        this.date,
        this.oneSignalId,
        this.fcmToken,
        this.platform,
        this.tokenUpdatedAt,
    });

    factory CustomerData.fromJson(Map<String, dynamic> json) => CustomerData(
        id: json["id"],
        profileImage: json["profile_image"],
        name: json["name"],
        email: json["email"],
        countryCode: json["country_code"],
        phone: json["phone"],
        password: json["password"],
        status: json["status"],
        referralCode: json["referral_code"],
        wallet: json["wallet"],
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
        oneSignalId: json["one_signal_id"],
        fcmToken: json["fcm_token"],
        platform: json["platform"],
        tokenUpdatedAt: json["token_updated_at"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "profile_image": profileImage,
        "name": name,
        "email": email,
        "country_code": countryCode,
        "phone": phone,
        "password": password,
        "status": status,
        "referral_code": referralCode,
        "wallet": wallet,
        "date": date?.toIso8601String(),
        "one_signal_id": oneSignalId,
        "fcm_token": fcmToken,
        "platform": platform,
        "token_updated_at": tokenUpdatedAt,
    };
}

class General {
    String? oneAppId;
    String? oneApiKey;

    General({
        this.oneAppId,
        this.oneApiKey,
    });

    factory General.fromJson(Map<String, dynamic> json) => General(
        oneAppId: json["one_app_id"],
        oneApiKey: json["one_api_key"],
    );

    Map<String, dynamic> toJson() => {
        "one_app_id": oneAppId,
        "one_api_key": oneApiKey,
    };
}
