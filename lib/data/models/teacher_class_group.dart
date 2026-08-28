import 'teacher_student.dart';

class TeacherClassGroupSummary {
  const TeacherClassGroupSummary({
    required this.id,
    required this.name,
    this.note,
    required this.memberCount,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? note;
  final int memberCount;
  final String? createdAt;
  final String? updatedAt;

  factory TeacherClassGroupSummary.fromJson(Map<String, dynamic> json) {
    return TeacherClassGroupSummary(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      note: () {
        final n = json['note'];
        if (n == null) return null;
        final s = n.toString().trim();
        return s.isEmpty ? null : s;
      }(),
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class TeacherClassGroupMember {
  const TeacherClassGroupMember({
    required this.studentId,
    required this.displayName,
    required this.email,
    this.avatar = 'm1',
    this.addedAt,
  });

  final int studentId;
  final String displayName;
  final String email;
  final String avatar;
  final String? addedAt;

  factory TeacherClassGroupMember.fromJson(Map<String, dynamic> json) {
    return TeacherClassGroupMember(
      studentId: (json['student_id'] as num).toInt(),
      displayName: (json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatar: (json['avatar']?.toString().isNotEmpty ?? false)
          ? json['avatar'].toString()
          : 'm1',
      addedAt: json['added_at']?.toString(),
    );
  }
}

class TeacherClassGroupDetail {
  const TeacherClassGroupDetail({
    required this.id,
    required this.name,
    this.note,
    required this.memberCount,
    this.members = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? note;
  final int memberCount;
  final List<TeacherClassGroupMember> members;
  final String? createdAt;
  final String? updatedAt;

  factory TeacherClassGroupDetail.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? const [];
    return TeacherClassGroupDetail(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      note: () {
        final n = json['note'];
        if (n == null) return null;
        final s = n.toString().trim();
        return s.isEmpty ? null : s;
      }(),
      memberCount: (json['member_count'] as num?)?.toInt() ?? rawMembers.length,
      members: rawMembers
          .map(
            (e) => TeacherClassGroupMember.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class TeacherClassGroupSessionResult {
  const TeacherClassGroupSessionResult({
    required this.studentId,
    required this.ok,
    this.sessionId,
    this.error,
  });

  final int studentId;
  final bool ok;
  final int? sessionId;
  final String? error;

  factory TeacherClassGroupSessionResult.fromJson(Map<String, dynamic> json) {
    return TeacherClassGroupSessionResult(
      studentId: (json['student_id'] as num).toInt(),
      ok: json['ok'] == true,
      sessionId: (json['session_id'] as num?)?.toInt(),
      error: json['error']?.toString(),
    );
  }
}

class TeacherClassGroupSessionBulkResponse {
  const TeacherClassGroupSessionBulkResponse({
    required this.group,
    required this.addedCount,
    this.results = const [],
  });

  final TeacherClassGroupDetail group;
  final int addedCount;
  final List<TeacherClassGroupSessionResult> results;

  factory TeacherClassGroupSessionBulkResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];
    return TeacherClassGroupSessionBulkResponse(
      group: TeacherClassGroupDetail.fromJson(
        json['group'] as Map<String, dynamic>,
      ),
      addedCount: (json['added_count'] as num?)?.toInt() ?? 0,
      results: rawResults
          .map(
            (e) => TeacherClassGroupSessionResult.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

/// Student view: personal sessions + per-group class tabs ([my_class_sessions.php]).
class StudentMyClassSessionsResponse {
  const StudentMyClassSessionsResponse({
    required this.personal,
    this.classGroups = const [],
  });

  final TeacherSessionInfo personal;
  final List<StudentGroupClassSessionsView> classGroups;

  int get totalSessionCount =>
      personal.sessionCount +
      classGroups.fold<int>(0, (sum, g) => sum + g.sessionInfo.sessionCount);

  /// Personal + all group sessions (for schedule/attendance checks).
  List<ClassSessionEntry> get allSessions => [
        ...personal.sessions,
        for (final g in classGroups) ...g.sessionInfo.sessions,
      ];

  factory StudentMyClassSessionsResponse.fromJson(
    Map<String, dynamic> json,
    TeacherSessionInfo Function(Map<String, dynamic>) parseSessionInfo,
  ) {
    if (json.containsKey('personal') || json.containsKey('class_groups')) {
      final personalMap =
          (json['personal'] as Map<String, dynamic>?) ?? const {};
      final rawGroups = json['class_groups'] as List<dynamic>? ?? const [];
      return StudentMyClassSessionsResponse(
        personal: parseSessionInfo(personalMap),
        classGroups: rawGroups
            .map(
              (e) => StudentGroupClassSessionsView.fromJson(
                e as Map<String, dynamic>,
                parseSessionInfo,
              ),
            )
            .toList(),
      );
    }
    return StudentMyClassSessionsResponse(
      personal: parseSessionInfo(json),
      classGroups: const [],
    );
  }
}

class StudentGroupClassSessionsView {
  const StudentGroupClassSessionsView({
    required this.id,
    required this.name,
    this.note,
    required this.sessionInfo,
  });

  final int id;
  final String name;
  final String? note;
  final TeacherSessionInfo sessionInfo;

  factory StudentGroupClassSessionsView.fromJson(
    Map<String, dynamic> json,
    TeacherSessionInfo Function(Map<String, dynamic>) parseSessionInfo,
  ) {
    return StudentGroupClassSessionsView(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      note: () {
        final n = json['note'];
        if (n == null) return null;
        final s = n.toString().trim();
        return s.isEmpty ? null : s;
      }(),
      sessionInfo: parseSessionInfo(json),
    );
  }
}
