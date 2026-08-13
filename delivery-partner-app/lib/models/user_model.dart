class User {
  final int id;
  final String? name;
  final String? email;
  final String mobile;
  final int roleId;

  User({
    required this.id,
    this.name,
    this.email,
    required this.mobile,
    required this.roleId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'] ?? '',
      roleId: json['role_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role_id': roleId,
    };
  }
}
