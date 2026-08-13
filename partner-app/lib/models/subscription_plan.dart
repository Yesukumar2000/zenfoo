class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String duration;
  final List<String> benefits;
  final bool isPopular;
  final bool isSelected;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.benefits,
    this.isPopular = false,
    this.isSelected = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      duration: json['duration'] ?? '',
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPopular: json['is_popular'] == true || json['is_popular'] == 1,
      isSelected: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'benefits': benefits,
      'is_popular': isPopular,
    };
  }

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    double? price,
    String? duration,
    List<String>? benefits,
    bool? isPopular,
    bool? isSelected,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      benefits: benefits ?? this.benefits,
      isPopular: isPopular ?? this.isPopular,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
