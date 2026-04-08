import '../../core/stats/stats_service.dart';
import '../../data/models/grammar_result.dart';

/// One calendar day of quiz metrics (aligned index for charts).
class DailyQuizPair {
  const DailyQuizPair({
    required this.date,
    this.vocabPct,
    this.grammarPct,
  });

  final DateTime date;
  /// Local vocab quiz accuracy % (answers that day), or null if none.
  final double? vocabPct;
  /// Server grammar sessions averaged for that calendar day, or null if none.
  final double? grammarPct;

  String get labelMmDd =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

double? _grammarAccuracy(GrammarResult r) {
  final s = r.score;
  final t = r.totalQuestions;
  if (s == null || t == null || t <= 0) return null;
  return (s / t) * 100;
}

/// Last [days] calendar days (oldest → newest): vocab from [StatsState], grammar from API list.
List<DailyQuizPair> buildDailyQuizPairs({
  required StatsState stats,
  required List<GrammarResult> grammarResults,
  int days = 14,
}) {
  final today = _dateOnly(DateTime.now());
  final byGrammarDay = <String, List<double>>{};
  for (final r in grammarResults) {
    final a = _grammarAccuracy(r);
    if (a == null) continue;
    final raw = r.createdAt.trim();
    if (raw.isEmpty) continue;
    final dt = DateTime.tryParse(raw.contains('T') ? raw : raw.replaceFirst(' ', 'T'));
    if (dt == null) continue;
    final k = _dayKey(_dateOnly(dt));
    byGrammarDay.putIfAbsent(k, () => []).add(a);
  }

  final out = <DailyQuizPair>[];
  for (var i = days - 1; i >= 0; i--) {
    final d = today.subtract(Duration(days: i));
    final k = _dayKey(d);
    final q = stats.quizSessionsPerDay[k];
    double? vPct;
    if (q != null) {
      final tot = q['total'] ?? 0;
      final cor = q['correct'] ?? 0;
      if (tot > 0) vPct = (cor / tot) * 100;
    }
    double? gPct;
    final gs = byGrammarDay[k];
    if (gs != null && gs.isNotEmpty) {
      gPct = gs.reduce((a, b) => a + b) / gs.length;
    }
    out.add(DailyQuizPair(date: d, vocabPct: vPct, grammarPct: gPct));
  }
  return out;
}
