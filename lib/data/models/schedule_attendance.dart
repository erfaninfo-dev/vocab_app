enum ScheduleAttendanceMode {
  auto,
  manual;

  static ScheduleAttendanceMode fromJson(Object? value) {
    return value?.toString() == 'auto'
        ? ScheduleAttendanceMode.auto
        : ScheduleAttendanceMode.manual;
  }

  String get apiValue =>
      this == ScheduleAttendanceMode.manual ? 'manual' : 'auto';
}

class ScheduleAttendanceDueOccurrence {
  const ScheduleAttendanceDueOccurrence({
    required this.studentId,
    required this.sourceType,
    required this.sourceId,
    required this.startAt,
    this.endAt,
    this.label,
  });

  final int studentId;
  final String sourceType;
  final int sourceId;
  final DateTime startAt;
  final DateTime? endAt;
  final String? label;

  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'source_type': sourceType,
    'source_id': sourceId,
    'start_at': startAt.toUtc().toIso8601String(),
    if (endAt != null) 'end_at': endAt!.toUtc().toIso8601String(),
    if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
  };
}

class ScheduleAttendancePendingOccurrence {
  const ScheduleAttendancePendingOccurrence({
    required this.id,
    required this.studentId,
    required this.studentDisplayLabel,
    required this.studentEmail,
    required this.avatarId,
    required this.sourceType,
    required this.sourceId,
    required this.startLocal,
    this.endLocal,
    this.label,
  });

  final int id;
  final int studentId;
  final String studentDisplayLabel;
  final String studentEmail;
  final String avatarId;
  final String sourceType;
  final int sourceId;
  final DateTime startLocal;
  final DateTime? endLocal;
  final String? label;

  factory ScheduleAttendancePendingOccurrence.fromJson(
    Map<String, dynamic> json,
  ) {
    final labelRaw = json['label']?.toString().trim();
    final endRaw = json['end_at']?.toString();
    return ScheduleAttendancePendingOccurrence(
      id: (json['id'] as num).toInt(),
      studentId: (json['student_id'] as num).toInt(),
      studentDisplayLabel: (json['student_display_label'] ?? '').toString(),
      studentEmail: (json['student_email'] ?? '').toString(),
      avatarId: (json['avatar']?.toString().isNotEmpty ?? false)
          ? json['avatar'].toString()
          : 'm1',
      sourceType: (json['source_type'] ?? 'weekly').toString(),
      sourceId: (json['source_id'] as num?)?.toInt() ?? 0,
      startLocal: DateTime.parse(json['start_at'].toString()).toLocal(),
      endLocal: endRaw != null && endRaw.isNotEmpty
          ? DateTime.parse(endRaw).toLocal()
          : null,
      label: labelRaw != null && labelRaw.isNotEmpty ? labelRaw : null,
    );
  }
}

class ScheduleAttendanceState {
  const ScheduleAttendanceState({
    this.policies = const {},
    this.pending = const [],
  });

  final Map<int, ScheduleAttendanceMode> policies;
  final List<ScheduleAttendancePendingOccurrence> pending;

  ScheduleAttendanceMode modeFor(int studentId) {
    return policies[studentId] ?? ScheduleAttendanceMode.manual;
  }

  factory ScheduleAttendanceState.fromJson(Map<String, dynamic> json) {
    final rawPolicies = json['policies'] as Map<String, dynamic>? ?? const {};
    final policies = <int, ScheduleAttendanceMode>{};
    for (final entry in rawPolicies.entries) {
      final id = int.tryParse(entry.key);
      if (id == null) continue;
      policies[id] = ScheduleAttendanceMode.fromJson(entry.value);
    }
    final rawPending = json['pending'] as List<dynamic>? ?? const [];
    return ScheduleAttendanceState(
      policies: policies,
      pending: rawPending
          .map(
            (e) => ScheduleAttendancePendingOccurrence.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
