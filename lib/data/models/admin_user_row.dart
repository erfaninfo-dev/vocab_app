class ActiveAppVersion {
  const ActiveAppVersion({
    required this.versionCode,
    required this.versionName,
  });

  final int versionCode;
  final String versionName;

  factory ActiveAppVersion.fromJson(Map<String, dynamic> json) {
    return ActiveAppVersion(
      versionCode: (json['version_code'] as num).toInt(),
      versionName: (json['version_name'] as String? ?? '').trim(),
    );
  }

  String get label {
    final n = versionName;
    if (n.isNotEmpty) return '$n ($versionCode)';
    return '$versionCode';
  }
}

class AdminUsersListResult {
  const AdminUsersListResult({
    required this.users,
    this.activeAppVersion,
  });

  final List<AdminUserRow> users;
  final ActiveAppVersion? activeAppVersion;
}

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
    this.installedAppVersionCode,
    this.installedAppVersionName,
    this.appVersionReportedAt,
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

  final int? installedAppVersionCode;
  final String? installedAppVersionName;
  final DateTime? appVersionReportedAt;

  bool isBehindActive(ActiveAppVersion? active) {
    if (active == null) return false;
    final installed = installedAppVersionCode;
    if (installed == null || installed <= 0) return false;
    return installed < active.versionCode;
  }

  String installedVersionLabel(String unknownLabel) {
    final code = installedAppVersionCode;
    if (code == null || code <= 0) return unknownLabel;
    final name = installedAppVersionName?.trim();
    if (name != null && name.isNotEmpty) return '$name ($code)';
    return '$code';
  }

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

    final ivc = json['installed_app_version_code'];
    final ivn = json['installed_app_version_name'];
    final reported = json['app_version_reported_at'];

    DateTime? reportedAt;
    if (reported is String && reported.trim().isNotEmpty) {
      reportedAt = DateTime.tryParse(reported.trim());
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
      installedAppVersionCode: ivc == null ? null : (ivc as num).toInt(),
      installedAppVersionName: ivn is String ? ivn.trim() : null,
      appVersionReportedAt: reportedAt,
    );
  }
}
