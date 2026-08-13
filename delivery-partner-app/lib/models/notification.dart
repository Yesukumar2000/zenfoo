class NotificationList {
  NotificationList({
    required this.status,
    required this.message,
    required this.total,
    required this.data,
  });

  late final int status;
  late final String message;
  late final int total;
  late final NotificationData data;

  NotificationList.fromJson(Map<String, dynamic> json) {
    status = json['status'] ?? 0;
    message = json['message']?.toString() ?? '';
    total = json['total'] ?? 0;
    data = json['data'] != null
        ? NotificationData.fromJson(json['data'])
        : NotificationData(status: 0, total: 0, data: []);
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['status'] = status;
    itemData['message'] = message;
    itemData['total'] = total;
    itemData['data'] = data.toJson();
    return itemData;
  }
}

class NotificationData {
  NotificationData({
    required this.status,
    required this.total,
    required this.data,
  });

  late final int status;
  late final int total;
  late final List<NotificationListData> data;

  NotificationData.fromJson(Map<String, dynamic> json) {
    status = json['status'] ?? 0;
    total = json['total'] ?? 0;
    data = json['data'] != null
        ? List.from(json['data'])
            .map((e) => NotificationListData.fromJson(e))
            .toList()
        : [];
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['status'] = status;
    itemData['total'] = total;
    itemData['data'] = data.map((e) => e.toJson()).toList();
    return itemData;
  }
}

class NotificationListData {
  NotificationListData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.type,
    this.typeId,
    this.imageUrl,
  });

  late final int id;
  late final String name;
  late final String subtitle;
  late final String type;
  late final int? typeId;
  late final String? imageUrl;

  NotificationListData.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    name = json['name']?.toString() ?? '';
    subtitle = json['subtitle']?.toString() ?? '';
    type = json['type']?.toString() ?? '';
    typeId = json['type_id'];
    imageUrl = json['image_url'];
  }

  Map<String, dynamic> toJson() {
    final itemData = <String, dynamic>{};
    itemData['id'] = id;
    itemData['name'] = name;
    itemData['subtitle'] = subtitle;
    itemData['type'] = type;
    itemData['type_id'] = typeId;
    itemData['image_url'] = imageUrl;
    return itemData;
  }
}
