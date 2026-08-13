// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

PhoneNumberModel phoneNumberModelFromJson(String str) =>
    PhoneNumberModel.fromJson(json.decode(str));

String phoneNumberModelToJson(PhoneNumberModel data) =>
    json.encode(data.toJson());

class PhoneNumberModel {
  final int? status;
  final String? message;
  final int? total;
  final PhoneNumberData? data;

  PhoneNumberModel({
    this.status,
    this.message,
    this.total,
    this.data,
  });

  factory PhoneNumberModel.fromJson(Map<String, dynamic> json) =>
      PhoneNumberModel(
        status: json["status"],
        message: json["message"],
        total: json["total"],
        data: json["data"] == null
            ? null
            : PhoneNumberData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": data?.toJson(),
      };
}

class PhoneNumberData {
  final String? mobile;
  final int? deliveryBoyId;
  final String? name;

  PhoneNumberData({
    this.mobile,
    this.deliveryBoyId,
    this.name,
  });

  factory PhoneNumberData.fromJson(Map<String, dynamic> json) =>
      PhoneNumberData(
        mobile: json["mobile"],
        deliveryBoyId: json["delivery_boy_id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "mobile": mobile,
        "delivery_boy_id": deliveryBoyId,
        "name": name,
      };
}
