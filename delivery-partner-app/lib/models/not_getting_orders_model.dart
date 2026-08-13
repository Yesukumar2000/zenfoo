// To parse this JSON data, do
//
//     final welcome = welcomeFromJson(jsonString);

import 'dart:convert';

NotGettingOrdersModel notGettingOrdersModelFromJson(String str) =>
    NotGettingOrdersModel.fromJson(json.decode(str));

String notGettingOrdersModelToJson(NotGettingOrdersModel data) =>
    json.encode(data.toJson());

class NotGettingOrdersModel {
  final int? status;
  final String? message;
  final int? total;
  final NotGettingOrdersData? data;

  NotGettingOrdersModel({
    this.status,
    this.message,
    this.total,
    this.data,
  });

  factory NotGettingOrdersModel.fromJson(Map<String, dynamic> json) =>
      NotGettingOrdersModel(
        status: json["status"],
        message: json["message"],
        total: json["total"],
        data: json["data"] == null
            ? null
            : NotGettingOrdersData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "total": total,
        "data": data?.toJson(),
      };
}

class NotGettingOrdersData {
  final String? videoUrl;
  final String? title;
  final List<Step>? steps;

  NotGettingOrdersData({
    this.videoUrl,
    this.title,
    this.steps,
  });

  factory NotGettingOrdersData.fromJson(Map<String, dynamic> json) =>
      NotGettingOrdersData(
        videoUrl: json["video_url"],
        title: json["title"],
        steps: json["steps"] == null
            ? []
            : List<Step>.from(json["steps"]!.map((x) => Step.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "video_url": videoUrl,
        "title": title,
        "steps": steps == null
            ? []
            : List<dynamic>.from(steps!.map((x) => x.toJson())),
      };
}

class Step {
  final int? stepNumber;
  final String? title;

  Step({
    this.stepNumber,
    this.title,
  });

  factory Step.fromJson(Map<String, dynamic> json) => Step(
        stepNumber: json["step_number"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "step_number": stepNumber,
        "title": title,
      };
}
