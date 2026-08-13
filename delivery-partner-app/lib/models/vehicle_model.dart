class Vehicle {
  final int id;
  final String name;
  final String? image;
  final String? imageUrl;

  Vehicle({
    required this.id,
    required this.name,
    this.image,
    this.imageUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'image_url': imageUrl,
    };
  }
}
