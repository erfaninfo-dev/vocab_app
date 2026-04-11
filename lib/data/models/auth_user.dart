class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatar = 'm1',
    this.studentAccess = false,
  });

  final int id;
  final String email;
  final String? displayName;

  /// Preset id from server: m1–m4 (boy-style), f1–f4 (girl-style).
  final String avatar;

  /// True after redeeming a valid student code (server: `student_access`).
  final bool studentAccess;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final av = json['avatar'] as String?;
    final sa = json['student_access'];
    return AuthUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatar: (av != null && av.isNotEmpty) ? av : 'm1',
      studentAccess: sa == true || sa == 1,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;

  factory AuthSession.fromAuthResponse(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
