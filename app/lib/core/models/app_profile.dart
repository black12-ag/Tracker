enum UserRole { owner, operator }

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isActive;

  bool get isOwner => role == UserRole.owner;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    return AppProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'User',
      role: (map['role'] as String? ?? 'operator') == 'owner'
          ? UserRole.owner
          : UserRole.operator,
      isActive: map['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': isOwner ? 'owner' : 'operator',
      'is_active': isActive,
    };
  }
}
