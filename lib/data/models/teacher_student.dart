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

/// One term (ترم) for a teacher–student pair: ordered and capped session count.
class ClassSessionTerm {
  const ClassSessionTerm({
    required this.id,
    required this.sortOrder,
    required this.sessionCap,
    required this.sessionCount,
    this.isPaid = false,
  });

  final int id;
  final int sortOrder;
  final int sessionCap;
  final int sessionCount;

  /// Tuition / fee paid for this term (server `is_paid`).
  final bool isPaid;

  bool get isFull => sessionCount >= sessionCap;

  factory ClassSessionTerm.fromJson(Map<String, dynamic> json) {
    return ClassSessionTerm(
      id: (json['id'] as num).toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
      sessionCap: (json['session_cap'] as num?)?.toInt() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
    );
  }
}

/// One recorded in-person / class session (teacher tapped +).
class ClassSessionEntry {
  const ClassSessionEntry({
    required this.id,
    required this.index,
    required this.recordedAtRaw,
    this.termId,
  });

  final int id;

  /// 1-based display index within the term when [termId] is set; otherwise global.
  final int index;

  /// Server row for `teacher_student_terms` when the API is migrated.
  final int? termId;

  /// Server datetime string for when the session was recorded.
  final String recordedAtRaw;

  factory ClassSessionEntry.fromJson(Map<String, dynamic> json) {
    return ClassSessionEntry(
      id: (json['id'] as num).toInt(),
      index: (json['index'] as num?)?.toInt() ??
          (json['session_index'] as num?)?.toInt() ??
          0,
      recordedAtRaw: (json['recorded_at'] ?? '').toString(),
      termId: (json['term_id'] as num?)?.toInt(),
    );
  }
}

class TeacherSessionInfo {
  const TeacherSessionInfo({
    required this.sessionCount,
    this.updatedAt,
    this.note,
    this.sessions = const [],
    this.terms = const [],
    this.usesTermsTable = false,
  });

  final int sessionCount;
  final String? updatedAt;
  final String? note;

  /// Per-session rows when the server has `teacher_class_session_entries` migrated.
  final List<ClassSessionEntry> sessions;

  /// Present when the server has run `teacher_student_terms_migration.sql`.
  final List<ClassSessionTerm> terms;

  /// True when the API included a `terms` field (even if empty).
  final bool usesTermsTable;
}
