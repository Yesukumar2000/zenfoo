import 'package:project/models/combo.dart';

class CombosPageData {
  List<ComboSection>? data;
  List<ComboType>? comboTypes;
  int? status;
  String? message;

  CombosPageData({this.data, this.comboTypes, this.status, this.message});

  CombosPageData.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ComboSection>[];
      json['data'].forEach((v) {
        data!.add(ComboSection.fromJson(v));
      });
    }
    if (json['combo_types'] != null) {
      comboTypes = <ComboType>[];
      json['combo_types'].forEach((v) {
        comboTypes!.add(ComboType.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (comboTypes != null) {
      data['combo_types'] = comboTypes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ComboSection {
  String? name;
  List<Combo>? combos;

  ComboSection({this.name, this.combos});

  ComboSection.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    if (json['combos'] != null) {
      combos = <Combo>[];
      json['combos'].forEach((v) {
        combos!.add(Combo.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (combos != null) {
      data['combos'] = combos!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ComboType {
  int? id;
  String? name;
  String? createdAt;
  String? updatedAt;

  ComboType({this.id, this.name, this.createdAt, this.updatedAt});

  ComboType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
