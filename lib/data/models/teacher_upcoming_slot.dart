import 'class_schedule_slot.dart';
import 'schedule_attendance.dart';

/// One upcoming weekly-slot occurrence for the teacher dashboard (this calendar week).
class TeacherUpcomingSlotItem {
  const TeacherUpcomingSlotItem({
    required this.studentId,
    required this.studentDisplayLabel,
    required this.studentEmail,
    required this.avatarId,
    required this.startLocal,
    required this.slot,
    this.isTemporary = false,
    this.temporarySlotId,
    this.temporaryEndLocal,
    this.attendanceMode = ScheduleAttendanceMode.auto,
    this.isManualPending = false,
    this.attendanceOccurrenceId,
  });

  final int studentId;
  final String studentDisplayLabel;
  final String studentEmail;
  final String avatarId;

  /// Local start [DateTime] for this occurrence (weekday + start time).
  final DateTime startLocal;
  final ClassScheduleSlot slot;

  /// True for one-off temporary classes created from the teacher schedule tab.
  final bool isTemporary;
  final int? temporarySlotId;
  final DateTime? temporaryEndLocal;

  final ScheduleAttendanceMode attendanceMode;

  /// True when the class time has passed and the teacher must confirm yes/no.
  final bool isManualPending;
  final int? attendanceOccurrenceId;
}
