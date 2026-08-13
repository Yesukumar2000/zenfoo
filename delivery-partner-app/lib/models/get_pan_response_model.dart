// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

PanModel panModelFromJson(String str) => PanModel.fromJson(json.decode(str));

String panModelToJson(PanModel data) => json.encode(data.toJson());

class PanModel {
  final int? status;
  final String? message;
  final int? total;
  final PanDataModel? data;

  PanModel({
    this.status,
    this.message,
    this.total,
    this.data,
  });

  factory PanModel.fromJson(Map<String, dynamic> json) => PanModel(
        status: json["status"],
        message: json["message"],
        total: json["total"],
        data: json["data"] == null ? null : PanDataModel.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": data?.toJson(),
      };
}

class PanDataModel {
  final Pan? pan;

  PanDataModel({
    this.pan,
  });

  factory PanDataModel.fromJson(Map<String, dynamic> json) => PanDataModel(
        pan: json["pan"] == null ? null : Pan.fromJson(json["pan"]),
      );

  Map<String, dynamic> toJson() => {
        "pan": pan?.toJson(),
      };
}

class Pan {
  final String? number;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String? status;

  Pan({
    this.number,
    this.frontImageUrl,
    this.backImageUrl,
    this.status,
  });

  factory Pan.fromJson(Map<String, dynamic> json) => Pan(
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
