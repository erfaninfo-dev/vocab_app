class TemporaryClassScheduleSlot {
  const TemporaryClassScheduleSlot({
    required this.id,
    required this.studentId,
    required this.studentDisplayLabel,
    required this.studentEmail,
    required this.avatarId,
    required this.startLocal,
    required this.endLocal,
    this.label,
  });

  final int id;
  final int studentId;
  final String studentDisplayLabel;
  final String studentEmail;
  final String avatarId;
  final DateTime startLocal;
  final DateTime endLocal;
  final String? label;

  factory TemporaryClassScheduleSlot.fromJson(Map<String, dynamic> json) {
    final labelRaw = json['label']?.toString().trim();
    return TemporaryClassScheduleSlot(
      id: (json['id'] as num).toInt(),
      studentId: (json['student_id'] as num).toInt(),
      studentDisplayLabel: (json['student_display_label'] ?? '').toString(),
      studentEmail: (json['student_email'] ?? '').toString(),
      avatarId: (json['avatar']?.toString().isNotEmpty ?? false)
          ? json['avatar'].toString()
          : 'm1',
      startLocal: DateTime.parse(json['start_at'].toString()).toLocal(),
      endLocal: DateTime.parse(json['end_at'].toString()).toLocal(),
      label: labelRaw != null && labelRaw.isNotEmpty ? labelRaw : null,
    );
  }
}
