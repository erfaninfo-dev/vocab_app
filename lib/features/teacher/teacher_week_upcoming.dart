import '../../core/datetime/class_session_recorded_at.dart';
import '../../data/models/class_schedule_slot.dart';
import '../../data/models/teacher_student.dart';
import '../../data/models/teacher_upcoming_slot.dart';
import '../class_schedule/schedule_time_format.dart';

bool _sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Next calendar hit for [sl.weekday] + start time strictly after [afterLocal].
DateTime? nextWeeklySlotOccurrence(
  ClassScheduleSlot sl,
  DateTime afterLocal,
) {
  final tod = parseScheduleHm(sl.startTime);
  if (tod == null) return null;
  final wd = sl.weekday.clamp(1, 7);
  var day = DateTime(afterLocal.year, afterLocal.month, afterLocal.day);
  for (var i = 0; i < 14; i++) {
    final cand = DateTime(day.year, day.month, day.day, tod.hour, tod.minute);
    if (cand.weekday == wd && cand.isAfter(afterLocal)) {
      return cand;
    }
    day = day.add(const Duration(days: 1));
  }
  return null;
}

/// Whether [sessions] contains a recorded class that covers this weekly occurrence.
bool slotOccurrenceHasRecordedSession({
  required ClassScheduleSlot slot,
  required DateTime occurrenceStartLocal,
  required List<ClassSessionEntry> sessions,
}) {
  final endParsed = slot.endTime != null && slot.endTime!.trim().isNotEmpty
      ? parseScheduleHm(slot.endTime!)
      : null;
  final startM = occurrenceStartLocal.hour * 60 + occurrenceStartLocal.minute;
  final endM = endParsed != null
      ? endParsed.hour * 60 + endParsed.minute
      : startM + 150;
  const tolerance = 45;

  for (final e in sessions) {
    final dt = parseClassSessionRecordedAtFromApi(e.recordedAtRaw);
    if (dt == null) continue;
    if (!_sameCalendarDay(dt, occurrenceStartLocal)) continue;
    final sm = dt.hour * 60 + dt.minute;
    if (sm >= startM - tolerance && sm <= endM + tolerance) {
      return true;
    }
  }
  return false;
}

/// Upcoming weekly-slot occurrences in the **next 7 days** from [nowLocal]
/// (rolling window, fixes “Sunday night → Monday class” vs ISO week cutoff).
/// Excludes occurrences already covered by a logged class session.
List<TeacherUpcomingSlotItem> computeTeacherWeekUpcomingForStudent({
  required DateTime nowLocal,
  required TeacherStudentSummary student,
  required List<ClassScheduleSlot> slots,
  required List<ClassSessionEntry> sessions,
}) {
  final horizonExclusive = nowLocal.add(const Duration(days: 7));
  final out = <TeacherUpcomingSlotItem>[];

  for (final sl in slots) {
    final occ = nextWeeklySlotOccurrence(sl, nowLocal);
    if (occ == null) continue;
    if (!occ.isBefore(horizonExclusive)) continue;
    if (slotOccurrenceHasRecordedSession(
      slot: sl,
      occurrenceStartLocal: occ,
      sessions: sessions,
    )) {
      continue;
    }
    out.add(
      TeacherUpcomingSlotItem(
        studentId: student.id,
        studentDisplayLabel: student.displayLabel,
        studentEmail: student.email,
        avatarId: student.avatar,
        startLocal: occ,
        slot: sl,
      ),
    );
  }
  return out;
}
