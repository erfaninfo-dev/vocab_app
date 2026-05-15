import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/vocab_entry.dart';
import '../../../words/widgets/word_card.dart';
import '../../domain/word_builder_models.dart';

VocabEntry _vocabFromWordBuilderTarget(WordBuilderTargetWord w, int bookKey) {
  final bid = w.bookId.trim().isNotEmpty
      ? w.bookId.trim()
      : (bookKey < 0 ? '0' : '$bookKey');
  final meaningEn = w.meaningEn.trim().isNotEmpty
      ? w.meaningEn.trim()
      : w.pronunciation.trim();
  return VocabEntry(
    rowId: w.rowId,
    bookId: bid,
    word: w.word.trim(),
    type: w.type.trim(),
    meaningEn: meaningEn,
    meaningFa: w.translationFa.trim(),
    meaningKur: w.translationKur.trim(),
    exampleEn: w.exampleEn.trim(),
    exampleFa: w.exampleFa.trim(),
    exampleKur: w.exampleKur.trim(),
    unit: w.unit,
    section: w.section,
  );
}

class WordInfoSheet {
  static Future<void> show(
    BuildContext context,
    WordBuilderTargetWord word, {
    required int bookKey,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _WordInfoSheetBody(
        word: word,
        bookKey: bookKey,
      ),
    );
  }
}

class _WordInfoSheetBody extends ConsumerStatefulWidget {
  const _WordInfoSheetBody({
    required this.word,
    required this.bookKey,
  });

  final WordBuilderTargetWord word;
  final int bookKey;

  @override
  ConsumerState<_WordInfoSheetBody> createState() => _WordInfoSheetBodyState();
}

class _WordInfoSheetBodyState extends ConsumerState<_WordInfoSheetBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padBottom = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final entry = _vocabFromWordBuilderTarget(widget.word, widget.bookKey);

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    final fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);

    final body = Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, padBottom + 16),
            child: WordCard(
              entry: entry,
              showUnitBadge: entry.rowId > 0,
            ),
          ),
        ),
      ),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: body,
      ),
    );
  }
}
