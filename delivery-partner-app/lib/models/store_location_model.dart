class StoreLocation {
  final int id;
  final String name;
  final String address;
  final String latitude;
  final String longitude;
  final String phone;
  final String email;
  final int cityId;
  final String cityName;

  StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
    required this.cityId,
    required this.cityName,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      cityId: json['city_id'] ?? 0,
      cityName: json['city_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'city_id': cityId,
      'city_name': cityName,
    };
  }
}
