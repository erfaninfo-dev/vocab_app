import 'class_schedule_slot.dart';

/// One upcoming weekly-slot occurrence for the teacher dashboard (this calendar week).
class TeacherUpcomingSlotItem {
  const TeacherUpcomingSlotItem({
    required this.studentId,
    required this.studentDisplayLabel,
    required this.studentEmail,
    required this.avatarId,
    required this.startLocal,
    required this.slot,
  });

  final int studentId;
  final String studentDisplayLabel;
  final String studentEmail;
  final String avatarId;

  /// Local start [DateTime] for this occurrence (weekday + start time).
  final DateTime startLocal;
  final ClassScheduleSlot slot;
}
