/// Model data pengguna yang sedang login.
///
/// Objek ini disimpan di [AuthProvider] dan dapat diakses dari halaman mana
/// pun lewat `context.watch<AuthProvider>().user` (atau `.read`).
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String role;

  /// Kolom opsional — mungkin tidak ada di semua endpoint.
  final String? phone;
  final String? avatar;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return UserProfile(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString().toLowerCase() ?? 'student',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  /// Buat salinan dengan field yang diganti.
  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
    );
  }
}

