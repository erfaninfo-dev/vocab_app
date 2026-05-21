import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

/// Distinct accent for quiz FAB (separate from theme primary and home FAB blue).
const Color kBookVocabQuizFabColor = Color(0xFFE65100);
const Color kBookVocabQuizFabForeground = Colors.white;

/// FAB for book/unit vocabulary quiz ([FloatingActionButtonLocation.endFloat]).
class BookVocabQuizFab extends StatelessWidget {
  const BookVocabQuizFab({
    super.key,
    required this.bookId,
    this.unit,
  });

  final int bookId;

  /// When set, quiz is scoped to this unit (sections screen). Otherwise whole book.
  final int? unit;

  /// Bottom-right, 16dp from edges — same as Material [endFloat] / Home FAB.
  static const FloatingActionButtonLocation floatingActionButtonLocation =
      FloatingActionButtonLocation.endFloat;

  static const double _fabHeight = 56;
  static const double _margin = 16;

  static double scrollBottomPadding(BuildContext context) {
    return _margin + _fabHeight + _margin;
  }

  void _open(BuildContext context) {
    if (unit != null) {
      context.push('/books/$bookId/units/$unit/quiz');
    } else {
      context.push('/books/$bookId/vocab-quiz');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final heroTag = unit != null
        ? 'book_vocab_quiz_fab_u${unit!}_b$bookId'
        : 'book_vocab_quiz_fab_b$bookId';

    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: () => _open(context),
      backgroundColor: kBookVocabQuizFabColor,
      foregroundColor: kBookVocabQuizFabForeground,
      elevation: 5,
      highlightElevation: 8,
      tooltip: l10n.quizTitle,
      icon: const Icon(Icons.quiz_rounded),
      label: Text(
        l10n.quizTitle,
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
      ),
    );
  }
}
