import '../../data/models/teacher_student.dart';
import 'class_session_recorded_at.dart';

/// 1-based session label within a term: oldest [recordedAt] (then lower [id]) = 1.
int classSessionChronologicalIndexInTerm(
  ClassSessionEntry entry,
  List<ClassSessionEntry> termSessions,
) {
  final sorted = List<ClassSessionEntry>.from(termSessions)
    ..sort((a, b) {
      final da = parseClassSessionRecordedAtFromApi(a.recordedAtRaw);
      final db = parseClassSessionRecordedAtFromApi(b.recordedAtRaw);
      if (da == null && db == null) return a.id.compareTo(b.id);
      if (da == null) return 1;
      if (db == null) return -1;
      final c = da.compareTo(db);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
  for (var i = 0; i < sorted.length; i++) {
    if (sorted[i].id == entry.id) {
      return i + 1;
    }
  }
  return entry.index > 0 ? entry.index : 1;
}
