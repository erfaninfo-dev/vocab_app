class AdminUserRow {
  const AdminUserRow({
    required this.id,
    required this.email,
    this.displayName,
    this.studentAccess = false,
    this.isTeacher = false,
    this.isAdmin = false,
    this.teacherUserId,
    this.teacherName,
  });

  final int id;
  final String email;
  final String? displayName;
  final bool studentAccess;
  final bool isTeacher;
  final bool isAdmin;
  final int? teacherUserId;

  /// Resolved teacher label from API (`display_name` or email of assigned teacher).
  final String? teacherName;

  factory AdminUserRow.fromJson(Map<String, dynamic> json) {
    final sa = json['student_access'];
    final it = json['is_teacher'];
    final ia = json['is_admin'];
    final tuid = json['teacher_user_id'];
    final tn = json['teacher_name'];
    String? teacherLabel;
    if (tn is String && tn.trim().isNotEmpty) {
      teacherLabel = tn.trim();
    }
    return AdminUserRow(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      studentAccess: sa == true || sa == 1,
      isTeacher: it == true || it == 1,
      isAdmin: ia == true || ia == 1,
      teacherUserId: tuid == null ? null : (tuid as num).toInt(),
      teacherName: teacherLabel,
    );
  }
}
