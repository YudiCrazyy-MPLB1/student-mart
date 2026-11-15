import 'utils.dart';

class UserProfile {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;
  final int balance;
  final bool isSupplier;
  final DateTime? emailVerifiedAt;
  final DateTime? tosAgreedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.balance = 0,
    this.isSupplier = false,
    this.emailVerifiedAt,
    this.tosAgreedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final dynamic rawSupplier = json['is_supplier'];
    final bool supplier = rawSupplier == true ||
        rawSupplier == 1 ||
        rawSupplier?.toString() == '1' ||
        rawSupplier?.toString().toLowerCase() == 'true';

    return UserProfile(
      id: AppUtils.toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      balance: AppUtils.toInt(json['balance']),
      isSupplier: supplier,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
      tosAgreedAt: json['tos_agreed_at'] != null
          ? DateTime.tryParse(json['tos_agreed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      'balance': balance,
      'is_supplier': isSupplier,
      if (emailVerifiedAt != null)
        'email_verified_at': emailVerifiedAt!.toIso8601String(),
      if (tosAgreedAt != null) 'tos_agreed_at': tosAgreedAt!.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
    int? balance,
    bool? isSupplier,
    DateTime? emailVerifiedAt,
    DateTime? tosAgreedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      balance: balance ?? this.balance,
      isSupplier: isSupplier ?? this.isSupplier,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      tosAgreedAt: tosAgreedAt ?? this.tosAgreedAt,
    );
  }
}