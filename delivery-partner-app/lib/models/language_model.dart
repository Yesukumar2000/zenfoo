import 'package:zenfoo_partner/utils/safe_parser.dart';

class LanguageList {
  final String status;
  final String message;
  final int total;
  final List<LanguageListData> data;

  LanguageList({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory LanguageList.fromJson(Map<String, dynamic> json) {
    return LanguageList(
      status: SafeParser.parseString(json['status']),
      message: SafeParser.parseString(json['message']),
      total: SafeParser.parseInt(json['total']),
      data: (json['data'] as List?)
              ?.map((item) => LanguageListData.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class LanguageListData {
  final String id;
  final String name;
  final String code;
  final String type;
  final String systemType;
  final bool isDefault;
  final String systemTypeName;
  final String displayName;

  LanguageListData({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.systemType,
    required this.isDefault,
    required this.systemTypeName,
    required this.displayName,
  });

  factory LanguageListData.fromJson(Map<String, dynamic> json) {
    return LanguageListData(
      id: SafeParser.parse<String>(json['id'], defaultValue: ''),
      name: SafeParser.parseString(json['name']),
      code: SafeParser.parseString(json['code']),
      type: SafeParser.parse<String>(json['type'] is String ? json['type'].toLowerCase() : 'ltr', defaultValue: 'ltr'),
      systemType: SafeParser.parse<String>(json['system_type'], defaultValue: '2'),
      isDefault: SafeParser.parseBool(json['is_default']),
      systemTypeName: SafeParser.parseString(json['system_type_name']),
      displayName: SafeParser.parseString(json['display_name'] ?? json['name']),
    );
  }
}

class LanguageJsonData {
  final Data? data;

  LanguageJsonData({this.data});

  factory LanguageJsonData.fromJson(Map<String, dynamic> json) {
    return LanguageJsonData(
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }
}

class Data {
  final String id;
  final String name;
  final String code;
  final String type;
  final Map<String, dynamic> jsonData;

  Data({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.jsonData,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: SafeParser.parse<String>(json['id'], defaultValue: ''),
      name: SafeParser.parseString(json['name']),
      code: SafeParser.parseString(json['code']),
      type: SafeParser.parse<String>(json['type'] is String ? json['type'].toLowerCase() : 'ltr', defaultValue: 'ltr'),
      jsonData: SafeParser.parseMap(json['json_data']),
    );
  }
}
