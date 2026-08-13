class BulkUploadInstructionsModel {
  final int status;
  final String message;
  final BulkUploadInstructionsData? data;

  BulkUploadInstructionsModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory BulkUploadInstructionsModel.fromJson(Map<String, dynamic> json) {
    return BulkUploadInstructionsModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? BulkUploadInstructionsData.fromJson(json['data'])
          : null,
    );
  }
}

class BulkUploadInstructionsData {
  final String title;
  final String subtitle;
  final List<InstructionStep> steps;
  final List<String> tips;
  final List<ColumnInfo> columns;

  BulkUploadInstructionsData({
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.tips,
    required this.columns,
  });

  factory BulkUploadInstructionsData.fromJson(Map<String, dynamic> json) {
    return BulkUploadInstructionsData(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => InstructionStep.fromJson(e))
              .toList() ??
          [],
      tips: (json['tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      columns: (json['columns'] as List<dynamic>?)
              ?.map((e) => ColumnInfo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class InstructionStep {
  final int step;
  final String title;
  final String description;
  final String icon;

  InstructionStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      step: json['step'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

class ColumnInfo {
  final String column;
  final String header;
  final bool required;
  final String description;

  ColumnInfo({
    required this.column,
    required this.header,
    required this.required,
    required this.description,
  });

  factory ColumnInfo.fromJson(Map<String, dynamic> json) {
    return ColumnInfo(
      column: json['column'] ?? '',
      header: json['header'] ?? '',
      required: json['required'] ?? false,
      description: json['description'] ?? '',
    );
  }
}
