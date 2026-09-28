class UserProfileModel {
  final String id;
  final String fullName;
  final String? email;
  final String role;
  final DateTime? createdAt;

  UserProfileModel({
    required this.id,
    required this.fullName,
    this.email,
    this.role = 'cashier',
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? 'Kasir',
      email: json['email'],
      role: json['role'] ?? 'cashier',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    if (email != null) 'email': email,
    'role': role,
  };
}
