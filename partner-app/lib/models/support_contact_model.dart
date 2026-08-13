class SupportContact {
  final String phone;
  final String email;

  SupportContact({
    required this.phone,
    required this.email,
  });

  factory SupportContact.fromJson(Map<String, dynamic> json) {
    return SupportContact(
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}
