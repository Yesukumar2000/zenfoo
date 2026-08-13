// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

WeekModel weekModelFromJson(String str) => WeekModel.fromJson(json.decode(str));

String weekModelToJson(WeekModel data) => json.encode(data.toJson());

class WeekModel {
  final int? status;
  final String? message;
  final int? total;
  final WeekData? data;

  WeekModel({
    this.status,
    this.message,
    this.total,
    this.data,
  });

  factory WeekModel.fromJson(Map<String, dynamic> json) => WeekModel(
        status: json["status"],
        message: json["message"],
        total: json["total"],
        data: json["data"] == null ? null : WeekData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": data?.toJson(),
      };
}

class WeekData {
  final List<Week>? weeks;
  final DeliveryBoy? deliveryBoy;

  WeekData({
    this.weeks,
    this.deliveryBoy,
  });

  factory WeekData.fromJson(Map<String, dynamic> json) => WeekData(
        weeks: json["weeks"] == null
            ? []
            : List<Week>.from(json["weeks"]!.map((x) => Week.fromJson(x))),
        deliveryBoy: json["delivery_boy"] == null
            ? null
            : DeliveryBoy.fromJson(json["delivery_boy"]),
      );

  Map<String, dynamic> toJson() => {
        "weeks": weeks == null
            ? []
            : List<dynamic>.from(weeks!.map((x) => x.toJson())),
        "delivery_boy": deliveryBoy?.toJson(),
      };
}

class DeliveryBoy {
  final int? id;
  final String? name;

  DeliveryBoy({
    this.id,
    this.name,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) => DeliveryBoy(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class Week {
  final int? id;
  final String? label;

  Week({
    this.id,
    this.label,
  });

  factory Week.fromJson(Map<String, dynamic> json) => Week(
        id: json["id"],
        label: json["label"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "label": label,
      };
}
