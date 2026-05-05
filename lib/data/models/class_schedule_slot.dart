class ClassScheduleSlot {
  const ClassScheduleSlot({
    required this.id,
    required this.weekday,
    required this.startTime,
    this.endTime,
    this.label,
  });

  final int id;

  /// 1 = Monday … 7 = Sunday ([DateTime.weekday]).
  final int weekday;

  /// `HH:mm` from server.
  final String startTime;

  /// `HH:mm` or null.
  final String? endTime;

  final String? label;

  factory ClassScheduleSlot.fromJson(Map<String, dynamic> json) {
    final end = json['end_time']?.toString().trim();
    final lab = json['label']?.toString().trim();
    return ClassScheduleSlot(
      id: (json['id'] as num).toInt(),
      weekday: (json['weekday'] as num).toInt(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (end != null && end.isNotEmpty) ? end : null,
      label: (lab != null && lab.isNotEmpty) ? lab : null,
    );
  }
}
