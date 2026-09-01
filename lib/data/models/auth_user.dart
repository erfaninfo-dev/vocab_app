class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.bio,
    this.avatar = 'm1',
    this.studentAccess = false,
    this.isTeacher = false,
    this.isAdmin = false,
    this.teacherUserId,
  });

  final int id;
  final String email;
  final String? displayName;
  final String? bio;

  /// Preset id from server: m1–m4 (boy-style), f1–f4 (girl-style).
  final String avatar;

  /// True after redeeming a valid student code (server: `student_access`).
  final bool studentAccess;

  /// Server `is_teacher` — teacher panel access.
  final bool isTeacher;

  /// App admin — can manage users via admin API (server `is_admin`).
  final bool isAdmin;

  /// Assigned teacher user id for learners (server `teacher_user_id`).
  final int? teacherUserId;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final av = json['avatar'] as String?;
    final sa = json['student_access'];
    final it = json['is_teacher'];
    final ia = json['is_admin'];
    final tuid = json['teacher_user_id'];
    return AuthUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatar: (av != null && av.isNotEmpty) ? av : 'm1',
      studentAccess: sa == true || sa == 1,
      isTeacher: it == true || it == 1,
      isAdmin: ia == true || ia == 1,
      teacherUserId: tuid == null ? null : (tuid as num).toInt(),
    );
  }

  /// Round-trips the user over disk cache / shared_preferences. The keys must
  /// stay identical to the server's `/me.php` payload so [AuthUser.fromJson]
  /// can be reused to rehydrate cached copies.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'display_name': displayName,
    'bio': bio,
    'avatar': avatar,
    'student_access': studentAccess,
    'is_teacher': isTeacher,
    'is_admin': isAdmin,
    'teacher_user_id': teacherUserId,
  };
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;

  factory AuthSession.fromAuthResponse(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['user'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Missing auth token');
    }
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Missing user payload');
    }
    return AuthSession(
      token: token,
      user: AuthUser.fromJson(user),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession.fromAuthResponse(json);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'token': token,
    'user': user.toJson(),
  };
}
