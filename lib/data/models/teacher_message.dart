class TeacherMessageRow {
  const TeacherMessageRow({
    required this.id,
    required this.senderUserId,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  final int id;
  final int senderUserId;
  final String body;
  final String? readAt;
  final String createdAt;

  factory TeacherMessageRow.fromJson(Map<String, dynamic> json) {
    return TeacherMessageRow(
      id: (json['id'] as num).toInt(),
      senderUserId: (json['sender_user_id'] as num).toInt(),
      body: json['body'] as String,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class TeacherPeerInfo {
  const TeacherPeerInfo({required this.id, this.displayName});

  final int id;
  final String? displayName;

  static TeacherPeerInfo? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return TeacherPeerInfo(
      id: (json['id'] as num).toInt(),
      displayName: json['display_name'] as String?,
    );
  }
}

class TeacherMessagesPreview {
  const TeacherMessagesPreview({
    required this.unreadCount,
    this.lastMessage,
    this.teacher,
  });

  final int unreadCount;
  final TeacherMessageRow? lastMessage;
  final TeacherPeerInfo? teacher;

  static TeacherMessagesPreview empty() => const TeacherMessagesPreview(
        unreadCount: 0,
        lastMessage: null,
        teacher: null,
      );

  factory TeacherMessagesPreview.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'];
    return TeacherMessagesPreview(
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessage: last is Map<String, dynamic>
          ? TeacherMessageRow.fromJson(last)
          : null,
      teacher: TeacherPeerInfo.maybeFromJson(json['teacher'] as Map<String, dynamic>?),
    );
  }
}

class TeacherMessagesThread {
  const TeacherMessagesThread({
    required this.messages,
    required this.unreadCount,
    this.teacher,
    this.student,
  });

  final List<TeacherMessageRow> messages;
  final int unreadCount;
  final TeacherPeerInfo? teacher;
  final TeacherPeerInfo? student;

  factory TeacherMessagesThread.fromJson(Map<String, dynamic> json) {
    final list = json['messages'] as List<dynamic>? ?? const [];
    return TeacherMessagesThread(
      messages: list
          .map((e) => TeacherMessageRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      teacher: TeacherPeerInfo.maybeFromJson(json['teacher'] as Map<String, dynamic>?),
      student: TeacherPeerInfo.maybeFromJson(json['student'] as Map<String, dynamic>?),
    );
  }
}

/// GET ?summary=1 — counts for home FAB badge.
class TeacherMessagesUnreadSummary {
  const TeacherMessagesUnreadSummary({
    required this.isTeacher,
    required this.teacherStudentsWithUnread,
    required this.studentUnreadFromTeacher,
  });

  final bool isTeacher;
  final int teacherStudentsWithUnread;
  final int studentUnreadFromTeacher;

  factory TeacherMessagesUnreadSummary.fromJson(Map<String, dynamic> json) {
    return TeacherMessagesUnreadSummary(
      isTeacher: json['is_teacher'] == true || json['is_teacher'] == 1,
      teacherStudentsWithUnread:
          (json['teacher_students_with_unread'] as num?)?.toInt() ?? 0,
      studentUnreadFromTeacher:
          (json['student_unread_from_teacher'] as num?)?.toInt() ?? 0,
    );
  }

  /// Badge for current role: distinct students (teacher) or message count (student).
  int badgeForUser({required bool userIsTeacher}) {
    if (userIsTeacher) {
      return teacherStudentsWithUnread;
    }
    return studentUnreadFromTeacher;
  }
}
