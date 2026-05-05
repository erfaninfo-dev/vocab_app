/// Parses `recorded_at` from the API for class sessions.
///
/// Contract: server stores UTC in MySQL and returns ISO-8601 with `Z`. The device
/// shows that instant in the user's local timezone ([DateTime.toLocal]).
///
/// Legacy responses without a zone are treated as UTC (same naive string as DB).
DateTime? parseClassSessionRecordedAtFromApi(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  var n = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  final hasZone = n.endsWith('Z') ||
      RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(n) ||
      RegExp(r'[+-]\d{4}$').hasMatch(n);
  if (!hasZone && n.length >= 19) {
    final date = n.substring(0, 10);
    final time = n.substring(11, 19);
    n = '${date}T${time}Z';
  }
  final dt = DateTime.tryParse(n);
  if (dt == null) return null;
  return dt.toLocal();
}
