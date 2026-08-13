class NotificationResponse {
  int? status;
  String? message;
  int? total;
  NotificationData? data;

  NotificationResponse({this.status, this.message, this.total, this.data});

  NotificationResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'] is int ? json['status'] : int.tryParse(json['status']?.toString() ?? '');
    message = json['message']?.toString();
    total = json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '');
    if (json['data'] != null && json['data'] is Map) {
      data = NotificationData.fromJson(json['data']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['status'] = status;
    result['message'] = message;
    result['total'] = total;
    if (data != null) {
      result['data'] = data!.toJson();
    }
    return result;
  }
}

class NotificationData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<NotificationItem>? data;

  NotificationData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.data,
  });

  NotificationData.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'] is int ? json['current_page'] : int.tryParse(json['current_page']?.toString() ?? '');
    lastPage = json['last_page'] is int ? json['last_page'] : int.tryParse(json['last_page']?.toString() ?? '');
    perPage = json['per_page'] is int ? json['per_page'] : int.tryParse(json['per_page']?.toString() ?? '');
    total = json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '');
    if (json['data'] != null && json['data'] is List) {
      data = <NotificationItem>[];
      for (var v in (json['data'] as List)) {
        data!.add(NotificationItem.fromJson(v));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    result['current_page'] = currentPage;
    result['last_page'] = lastPage;
    result['per_page'] = perPage;
    result['total'] = total;
    if (data != null) {
      result['data'] = data!.map((v) => v.toJson()).toList();
    }
    return result;
  }
}

class NotificationItem {
  int? id;
  String? title;
  String? message;
  String? type;
  int? typeId;
  String? imageUrl;
  String? linkUrl;
  String? dateSent;

  NotificationItem({
    this.id,
    this.title,
    this.message,
    this.type,
    this.typeId,
    this.imageUrl,
    this.linkUrl,
    this.dateSent,
  });

  NotificationItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    title = json['title']?.toString();
    message = json['message']?.toString();
    type = json['type']?.toString();
    typeId = json['type_id'] is int ? json['type_id'] : int.tryParse(json['type_id']?.toString() ?? '');
    imageUrl = json['image_url']?.toString();
    linkUrl = json['link_url']?.toString();
    dateSent = json['date_sent']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['message'] = message;
    data['type'] = type;
    data['type_id'] = typeId;
    data['image_url'] = imageUrl;
    data['link_url'] = linkUrl;
    data['date_sent'] = dateSent;
    return data;
  }
}
