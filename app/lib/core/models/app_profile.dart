enum UserRole { owner, staff }

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.workspaceId,
    this.phone,
    this.createdByOwner,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final String workspaceId;
  final String? phone;
  final String? createdByOwner;

  bool get isOwner => role == UserRole.owner;
  bool get isStaff => role == UserRole.staff;

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    final roleValue = map['role'] as String? ?? 'staff';
    return AppProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'User',
      role: roleValue == 'owner' ? UserRole.owner : UserRole.staff,
      isActive: map['is_active'] as bool? ?? false,
      workspaceId: map['workspace_id'] as String? ?? '',
      phone: map['phone'] as String?,
      createdByOwner: map['created_by_owner'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': isOwner ? 'owner' : 'staff',
      'is_active': isActive,
      'workspace_id': workspaceId,
      'phone': phone,
      'created_by_owner': createdByOwner,
    };
  }
}
