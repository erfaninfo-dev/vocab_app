class TeacherStudentSummary {
  const TeacherStudentSummary({
    required this.id,
    required this.email,
    this.displayName,
    this.avatar = 'm1',
    required this.sessionCount,
    this.sessionsUpdatedAt,
    this.teacherNote,
  });

  final int id;
  final String email;
  final String? displayName;
  final String avatar;
  final int sessionCount;
  final String? sessionsUpdatedAt;

  /// Private note from `teacher_student_sessions.note` (server).
  final String? teacherNote;

  String get displayLabel {
    final d = displayName?.trim();
    if (d != null && d.isNotEmpty) {
      return d;
    }
    return email;
  }

  factory TeacherStudentSummary.fromJson(Map<String, dynamic> json) {
    return TeacherStudentSummary(
      id: (json['id'] as num).toInt(),
      email: (json['email'] ?? '').toString(),
      displayName: json['display_name']?.toString(),
      avatar: (json['avatar']?.toString().isNotEmpty ?? false)
          ? json['avatar'].toString()
          : 'm1',
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      sessionsUpdatedAt: json['sessions_updated_at']?.toString(),
      teacherNote: () {
        final n = json['note'];
        if (n == null) return null;
        final s = n.toString().trim();
        return s.isEmpty ? null : s;
      }(),
    );
  }
}

class TeacherSessionInfo {
  const TeacherSessionInfo({
    required this.sessionCount,
    this.updatedAt,
    this.note,
  });

  final int sessionCount;
  final String? updatedAt;
  final String? note;
}
