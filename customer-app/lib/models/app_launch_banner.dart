class AppLaunchBanner {
  int? status;
  String? url;
  String? color;
  int? imgWidth;
  int? imgHeight;
  String? orientation;
  String? ratio;
  SpecialItems? specialItems;

  AppLaunchBanner({
    this.status,
    this.url,
    this.color,
    this.imgWidth,
    this.imgHeight,
    this.orientation,
    this.ratio,
    this.specialItems,
  });

  AppLaunchBanner.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    url = json['url']?.toString() ?? "";
    color = json['color']?.toString() ?? "";
    imgWidth = json['img_width'] as int?;
    imgHeight = json['img_height'] as int?;
    orientation = json['orientation']?.toString();
    ratio = json['ratio']?.toString();
    specialItems = json['special_items'] != null
        ? SpecialItems.fromJson(json['special_items'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['url'] = url;
    data['color'] = color;
    data['img_width'] = imgWidth;
    data['img_height'] = imgHeight;
    data['orientation'] = orientation;
    data['ratio'] = ratio;
    if (specialItems != null) {
      data['special_items'] = specialItems!.toJson();
    }
    return data;
  }

  bool get isActive => status == 1 && (url?.isNotEmpty ?? false);

  bool get isPortrait => (orientation ?? '').toLowerCase() == 'portrait';
  bool get isLandscape => (orientation ?? '').toLowerCase() == 'landscape';

  /// Admin-picked ratio wins over the raw image dimensions so the app
  /// container matches what the admin chose, preventing the cropping/
  /// stretching that reads as blur.
  double get aspectRatio {
    final adminRatio = _parseRatio(ratio);
    if (adminRatio != null) return adminRatio;

    if ((imgWidth ?? 0) > 0 && (imgHeight ?? 0) > 0) {
      return imgWidth! / imgHeight!;
    }
    return isPortrait ? 9 / 16 : 16 / 9;
  }

  static double? _parseRatio(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final w = double.tryParse(parts[0].trim());
    final h = double.tryParse(parts[1].trim());
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }
}

class SpecialItems {
  List<SpecialItem> data;
  Pagination pagination;

  SpecialItems({required this.data, required this.pagination});

  SpecialItems.fromJson(Map<String, dynamic> json)
      : data = (json['data'] as List?)
            ?.map((item) => SpecialItem.fromJson(item))
            .toList() ??
        [],
        pagination = json['pagination'] != null
            ? Pagination.fromJson(json['pagination'])
            : Pagination(currentPage: 1, lastPage: 1, perPage: 4, total: 0);

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class SpecialItem {
  int id;
  String name;
  String imageUrl;

  SpecialItem({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  SpecialItem.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int? ?? 0,
        name = json['name'] as String? ?? "",
        imageUrl = json['image_url'] as String? ?? "";

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }
}

class Pagination {
  int currentPage;
  int lastPage;
  int perPage;
  int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  Pagination.fromJson(Map<String, dynamic> json)
      : currentPage = json['current_page'] as int? ?? 1,
        lastPage = json['last_page'] as int? ?? 1,
        perPage = int.parse((json['per_page'] ?? "4").toString()),
        total = json['total'] as int? ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }
}
