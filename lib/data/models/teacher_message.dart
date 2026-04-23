/// Raised by `editTeacherMessage` when the recipient already read the target
/// message (server responds 409). The chat UI turns this into a friendly
/// "You can't edit a message that has been read" snackbar.
class TeacherMessageAlreadyReadException implements Exception {
  const TeacherMessageAlreadyReadException();

  @override
  String toString() => 'TeacherMessageAlreadyReadException';
}

class TeacherMessageRow {
  const TeacherMessageRow({
    required this.id,
    required this.senderUserId,
    required this.body,
    this.readAt,
    this.editedAt,
    required this.createdAt,
  });

  final int id;
  final int senderUserId;
  final String body;
  final String? readAt;

  /// Set when the sender rewrote this message while it was still unread.
  final String? editedAt;
  final String createdAt;

  /// True once the recipient has opened the chat and marked it as read.
  bool get isRead => readAt != null && readAt!.trim().isNotEmpty;

  /// True for messages the sender rewrote after the original send.
  bool get isEdited => editedAt != null && editedAt!.trim().isNotEmpty;

  factory TeacherMessageRow.fromJson(Map<String, dynamic> json) {
    return TeacherMessageRow(
      id: (json['id'] as num).toInt(),
      senderUserId: (json['sender_user_id'] as num).toInt(),
      body: json['body'] as String,
      readAt: json['read_at'] as String?,
      editedAt: json['edited_at'] as String?,
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

/// GET ?student_peers=1 — one row per chat (teacher or admin).
class StudentMessagePeerRow {
  const StudentMessagePeerRow({
    required this.teacherUserId,
    this.displayName,
    required this.unreadCount,
    this.lastMessageAt,
  });

  final int teacherUserId;
  final String? displayName;
  final int unreadCount;
  final String? lastMessageAt;

  factory StudentMessagePeerRow.fromJson(Map<String, dynamic> json) {
    return StudentMessagePeerRow(
      teacherUserId: (json['teacher_user_id'] as num).toInt(),
      displayName: json['display_name'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessageAt: json['last_message_at'] as String?,
    );
  }
}

class TeacherMessagesPreview {
  const TeacherMessagesPreview({
    required this.unreadCount,
    this.lastMessage,
    this.teacher,
    this.peerCount = 1,
  });

  final int unreadCount;
  final TeacherMessageRow? lastMessage;
  final TeacherPeerInfo? teacher;

  /// Distinct chat threads (class teacher + admin, etc.).
  final int peerCount;

  static TeacherMessagesPreview empty() => const TeacherMessagesPreview(
        unreadCount: 0,
        lastMessage: null,
        teacher: null,
        peerCount: 0,
      );

  factory TeacherMessagesPreview.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'];
    return TeacherMessagesPreview(
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessage: last is Map<String, dynamic>
          ? TeacherMessageRow.fromJson(last)
          : null,
      teacher: TeacherPeerInfo.maybeFromJson(json['teacher'] as Map<String, dynamic>?),
      peerCount: (json['peer_count'] as num?)?.toInt() ?? 1,
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
