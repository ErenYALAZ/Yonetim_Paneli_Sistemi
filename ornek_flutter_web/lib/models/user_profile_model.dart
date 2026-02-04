class UserProfile {
  final String userId;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String? role;
  final String? departmentId;
  final String? departmentName;
  final String? departmentColor;

  UserProfile({
    required this.userId,
    required this.email,
    this.username,
    this.avatarUrl,
    this.role,
    this.departmentId,
    this.departmentName,
    this.departmentColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'role': role,
      'department_id': departmentId,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      avatarUrl: map['avatar_url'],
      role: map['role'],
      departmentId: map['department_id'],
      departmentName: map['departments'] != null ? map['departments']['name'] : null,
      departmentColor: map['departments'] != null ? map['departments']['color'] : null,
    );
  }
} 