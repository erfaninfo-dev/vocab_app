class TeacherStudentSummary {
  const TeacherStudentSummary({
    required this.id,
    required this.email,
    this.displayName,
    this.avatar = 'm1',
    required this.sessionCount,
    this.sessionsUpdatedAt,
    this.teacherNote,
    this.unreadFromStudent = 0,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageFromTeacher,
  });

  final int id;
  final String email;
  final String? displayName;
  final String avatar;
  final int sessionCount;
  final String? sessionsUpdatedAt;

  /// Private note from `teacher_student_sessions.note` (server).
  final String? teacherNote;

  /// When [inbox] list from API: unread messages **from this student** (teacher inbox).
  final int unreadFromStudent;

  /// Latest message time in thread (any direction), from `teacher_students.php?inbox=1`.
  final String? lastMessageAt;

  /// Truncated last message body for inbox row (Telegram-style preview).
  final String? lastMessagePreview;

  /// Whether the latest message in thread was sent by the teacher (`1` in JSON).
  final bool? lastMessageFromTeacher;

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
      unreadFromStudent: (json['unread_from_student'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['last_message_at']?.toString(),
      lastMessagePreview: () {
        final p = json['last_message_preview'];
        if (p == null) return null;
        final s = p.toString().trim();
        return s.isEmpty ? null : s;
      }(),
      lastMessageFromTeacher: () {
        final v = json['last_message_from_teacher'];
        if (v == null) return null;
        if (v == true || v == 1) return true;
        if (v == false || v == 0) return false;
        return null;
      }(),
    );
  }
}

/// One recorded in-person / class session (teacher tapped +).
class ClassSessionEntry {
  const ClassSessionEntry({
    required this.id,
    required this.index,
    required this.recordedAtRaw,
  });

  final int id;

  /// 1-based display index for this student.
  final int index;

  /// Server datetime string for when the session was recorded.
  final String recordedAtRaw;

  factory ClassSessionEntry.fromJson(Map<String, dynamic> json) {
    return ClassSessionEntry(
      id: (json['id'] as num).toInt(),
      index: (json['index'] as num?)?.toInt() ??
          (json['session_index'] as num?)?.toInt() ??
          0,
      recordedAtRaw: (json['recorded_at'] ?? '').toString(),
    );
  }
}

class TeacherSessionInfo {
  const TeacherSessionInfo({
    required this.sessionCount,
    this.updatedAt,
    this.note,
    this.sessions = const [],
  });

  final int sessionCount;
  final String? updatedAt;
  final String? note;

  /// Per-session rows when the server has `teacher_class_session_entries` migrated.
  final List<ClassSessionEntry> sessions;
}
