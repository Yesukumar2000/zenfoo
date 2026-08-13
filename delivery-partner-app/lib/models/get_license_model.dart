// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

LicenseModel licenseModelFromJson(String str) =>
    LicenseModel.fromJson(json.decode(str));

String licenseModelToJson(LicenseModel data) => json.encode(data.toJson());

class LicenseModel {
  final int? status;
  final String? message;
  final int? total;
  final LicenseData? data;

  LicenseModel({
    this.status,
    this.message,
    this.total,
    this.data,
  });

  factory LicenseModel.fromJson(Map<String, dynamic> json) => LicenseModel(
        status: json["status"],
        message: json["message"],
        total: json["total"],
        data: json["data"] == null ? null : LicenseData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": data?.toJson(),
      };
}

class LicenseData {
  final DrivingLicense? drivingLicense;

  LicenseData({
    this.drivingLicense,
  });

  factory LicenseData.fromJson(Map<String, dynamic> json) => LicenseData(
        drivingLicense: json["driving_license"] == null
            ? null
            : DrivingLicense.fromJson(json["driving_license"]),
      );

  Map<String, dynamic> toJson() => {
        "driving_license": drivingLicense?.toJson(),
      };
}

class DrivingLicense {
  final String? number;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? status;

  DrivingLicense({
    this.number,
    this.frontImageUrl,
    this.backImageUrl,
    this.status,
  });

  factory DrivingLicense.fromJson(Map<String, dynamic> json) => DrivingLicense(
        number: json["number"],
        frontImageUrl: json["front_image_url"],
        backImageUrl: json["back_image_url"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "number": number,
        "front_image_url": frontImageUrl,
        "back_image_url": backImageUrl,
        "status": status,
      };
}
