class OrderPriorityOption {
  final int value;
  final String label;
  final String description;

  OrderPriorityOption({
    required this.value,
    required this.label,
    required this.description,
  });

  factory OrderPriorityOption.fromJson(Map<String, dynamic> json) {
    return OrderPriorityOption(
      value: json['value'] ?? 0,
      label: json['label'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'description': description,
    };
  }
}

class OrderPriorityData {
  final int currentPriority;
  final String currentPriorityName;
  final List<OrderPriorityOption> priorityOptions;

  OrderPriorityData({
    required this.currentPriority,
    required this.currentPriorityName,
    required this.priorityOptions,
  });

  factory OrderPriorityData.fromJson(Map<String, dynamic> json) {
    return OrderPriorityData(
      currentPriority: json['current_priority'] ?? 0,
      currentPriorityName: json['current_priority_name'] ?? '',
      priorityOptions: (json['priority_options'] as List<dynamic>?)
              ?.map((item) => OrderPriorityOption.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_priority': currentPriority,
      'current_priority_name': currentPriorityName,
      'priority_options': priorityOptions.map((e) => e.toJson()).toList(),
    };
  }
}

class OrderPriorityResponse {
  final bool status;
  final String message;
  final int total;
  final OrderPriorityData data;

  OrderPriorityResponse({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  factory OrderPriorityResponse.fromJson(Map<String, dynamic> json) {
    return OrderPriorityResponse(
      status: json['status'] == 1 || json['status'] == true,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      data: OrderPriorityData.fromJson(json['data']),
    );
  }
}

class UpdateOrderPriorityResponse {
  final int status;
  final UpdateOrderPriorityData data;

  UpdateOrderPriorityResponse({
    required this.status,
    required this.data,
  });

  factory UpdateOrderPriorityResponse.fromJson(Map<String, dynamic> json) {
    return UpdateOrderPriorityResponse(
      status: json['status'] ?? 0,
      data: UpdateOrderPriorityData.fromJson(json['data']),
    );
  }
}

class UpdateOrderPriorityData {
  final int ordersPriority;
  final String ordersPriorityName;
  final String message;

  UpdateOrderPriorityData({
    required this.ordersPriority,
    required this.ordersPriorityName,
    required this.message,
  });

  factory UpdateOrderPriorityData.fromJson(Map<String, dynamic> json) {
    return UpdateOrderPriorityData(
      ordersPriority: json['orders_priority'] ?? 0,
      ordersPriorityName: json['orders_priority_name'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
