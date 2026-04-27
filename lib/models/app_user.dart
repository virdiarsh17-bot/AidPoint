

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role;

  AppUser({required this.uid, required this.email, required this.name, required this.role, required this.phone});

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'Unknown',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
    };
  }
}
