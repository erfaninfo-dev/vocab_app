import '../../data/models/grammar_result.dart';

DateTime _grammarResultCreatedAt(GrammarResult r) {
  final t = r.createdAt.trim();
  if (t.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

/// One row per learner for «Most practice»: total quizzes + latest attempt shown.
///
/// Use when the API returns duplicate [userId]s (e.g. legacy server ignoring `sort=practice`).
List<GrammarResult> mergeGrammarPracticeLeaderboard(List<GrammarResult> raw) {
  if (raw.isEmpty) return raw;
  final groups = <String, List<GrammarResult>>{};
  for (final r in raw) {
    final key = r.userId != null
        ? 'u:${r.userId}'
        : 'n:${(r.userName ?? '').trim().toLowerCase()}';
    groups.putIfAbsent(key, () => []).add(r);
  }
  final merged = <GrammarResult>[];
  for (final g in groups.values) {
    g.sort(
      (a, b) =>
          _grammarResultCreatedAt(b).compareTo(_grammarResultCreatedAt(a)),
    );
    final rep = g.first;
    final fromApi = g.map((e) => e.grammarQuizTotal).whereType<int>();
    final total = fromApi.isNotEmpty
        ? fromApi.reduce((a, b) => a > b ? a : b)
        : g.length;
    merged.add(
      GrammarResult(
        id: rep.id,
        userId: rep.userId,
        createdAt: rep.createdAt,
        quizName: rep.quizName,
        score: rep.score,
        totalQuestions: rep.totalQuestions,
        userName: rep.userName,
        bio: rep.bio,
        public: rep.public,
        selectedGrammarsRaw: rep.selectedGrammarsRaw,
        avatar: rep.avatar,
        grammarQuizTotal: total,
      ),
    );
  }
  merged.sort((a, b) {
    final ta = a.grammarQuizTotal ?? 0;
    final tb = b.grammarQuizTotal ?? 0;
    final c = tb.compareTo(ta);
    if (c != 0) return c;
    return _grammarResultCreatedAt(b).compareTo(_grammarResultCreatedAt(a));
  });
  return merged;
}
