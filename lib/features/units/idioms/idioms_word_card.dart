import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/resilient_asset_image.dart';

import '../../../core/language/language_provider.dart';
import '../../../core/tts/tts_service.dart';
import '../../../data/models/vocab_entry.dart';
import '../../../domain/api_providers.dart';
import '../../words/important_words_controller.dart';
import '../../words/word_preferences_controller.dart';
import 'idioms_units_constants.dart';
import 'idioms_word_card_colors.dart';

class IdiomsWordCard extends ConsumerWidget {
  const IdiomsWordCard({
    super.key,
    required this.entry,
    this.number,
    this.showUnitBadge = true,
    this.translationLang,
  });

  final VocabEntry entry;
  final int? number;
  final bool showUnitBadge;
  final TranslationLang? translationLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = IdiomsWordCardColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(wordPreferencesProvider);
    final important = ref.watch(importantWordsProvider);
    final prefsNotifier = ref.read(wordPreferencesProvider.notifier);
    final importantNotifier = ref.read(importantWordsProvider.notifier);
    final api = ref.read(apiServiceProvider);
    final TranslationLang resolvedLang =
        translationLang ?? ref.watch(langProvider);
    final isFav = prefs.isFavorite(entry);
    final isImp = important.isMarked(entry);
    final localMeaning = entry.meaningFor(resolvedLang);
    final localExample = entry.exampleLocalFor(resolvedLang);

    final bookId = int.tryParse(entry.bookId);
    final unitDetails = _unitDetails(ref, bookId, entry.unit);
    final illustrationPath = idiomsUnitAssetPath(
      entry.unit,
      unitDetails: unitDetails,
    );
    final headerTitle = _topicHeaderTitle(unitDetails, entry.unit);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NumberRing(number: number, colors: colors),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IdiomTitleWithSpeak(word: entry.word, colors: colors),
                        if (entry.meaningEn.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.meaningEn,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (localMeaning.isNotEmpty) ...[
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    localMeaning,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: colors.translation,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: colors.border),
              ],
              if (entry.exampleEn.isNotEmpty || localExample.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ExampleBox(
                  word: entry.word,
                  exampleEn: entry.exampleEn,
                  localExample: localExample,
                  colors: colors,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  _ActionCircle(
                    colors: colors,
                    icon: isFav
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isFav ? colors.primary : colors.actionIdle,
                    isActive: isFav,
                    onPressed: entry.rowId <= 0
                        ? null
                        : () => prefsNotifier.toggleFavorite(
                            entry,
                            api.authToken != null ? api : null,
                          ),
                  ),
                  const SizedBox(width: 8),
                  _ActionCircle(
                    colors: colors,
                    icon: isImp
                        ? Icons.local_fire_department_rounded
                        : Icons.local_fire_department_outlined,
                    color: isImp
                        ? const Color(0xFFF97316)
                        : colors.actionIdle,
                    isActive: isImp,
                    onPressed: entry.rowId <= 0
                        ? null
                        : () => importantNotifier.setImportant(
                            entry,
                            !isImp,
                            api.authToken != null ? api : null,
                          ),
                  ),
                  const SizedBox(width: 8),
                  if (showUnitBadge) ...[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: _TopicToolbarBadge(
                              title: headerTitle,
                              illustrationPath: illustrationPath,
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _topicHeaderTitle(String? unitDetails, int unit) {
    final topic = idiomsUnitDisplayTitle(unitDetails);
    if (topic.isNotEmpty) return '$topic Idioms';
    return 'Unit $unit Idioms';
  }

  String? _unitDetails(WidgetRef ref, int? bookId, int unit) {
    if (bookId == null) return null;
    return ref.watch(apiUnitsProvider(bookId)).maybeWhen(
      data: (units) {
        for (final u in units) {
          if (u.unit == unit) return u.unitDetails;
        }
        return null;
      },
      orElse: () => null,
    );
  }
}

class _TopicToolbarBadge extends StatelessWidget {
  const _TopicToolbarBadge({
    required this.title,
    required this.colors,
    this.illustrationPath,
  });

  final String title;
  final IdiomsWordCardColors colors;
  final String? illustrationPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: colors.badgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TopicIllustration(
            assetPath: illustrationPath,
            colors: colors,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicIllustration extends StatelessWidget {
  const _TopicIllustration({required this.colors, this.assetPath});

  final IdiomsWordCardColors colors;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path != null && path.isNotEmpty) {
      return SizedBox(
        width: 28,
        height: 28,
        child: ResilientAssetImage(
          assetPath: path,
          fit: BoxFit.contain,
          fallback: _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 14,
      ),
    );
  }
}

class _NumberRing extends StatelessWidget {
  const _NumberRing({required this.colors, this.number});

  final IdiomsWordCardColors colors;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final n = number;

    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.primary, width: 4),
      ),
      child: n != null && n > 0
          ? Text(
              '$n',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            )
          : null,
    );
  }
}

class _ExampleBox extends StatelessWidget {
  const _ExampleBox({
    required this.word,
    required this.exampleEn,
    required this.localExample,
    required this.colors,
  });

  final String word;
  final String exampleEn;
  final String localExample;
  final IdiomsWordCardColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.exampleBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Example',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (exampleEn.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _ExampleSentenceWithSpeak(
                    sentence: exampleEn,
                    word: word,
                    colors: colors,
                  ),
                ],
                if (localExample.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      localExample,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: colors.translation,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdiomTitleWithSpeak extends ConsumerWidget {
  const _IdiomTitleWithSpeak({required this.word, required this.colors});

  final String word;
  final IdiomsWordCardColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          height: 1.15,
          letterSpacing: -0.3,
        ),
        children: [
          TextSpan(text: word),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _InlineSpeakButton(
                text: word,
                isExample: false,
                colors: colors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleSentenceWithSpeak extends ConsumerWidget {
  const _ExampleSentenceWithSpeak({
    required this.sentence,
    required this.word,
    required this.colors,
  });

  final String sentence;
  final String word;
  final IdiomsWordCardColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: colors.textMuted,
          fontStyle: FontStyle.italic,
          fontSize: 14,
          height: 1.4,
        ),
        children: [
          ..._highlightSpans(
            sentence: sentence,
            word: word,
            highlightColor: colors.primary,
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _InlineSpeakButton(
                text: sentence,
                isExample: true,
                colors: colors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<InlineSpan> _highlightSpans({
  required String sentence,
  required String word,
  required Color highlightColor,
}) {
  final trimmedWord = word.trim();
  if (trimmedWord.isEmpty) {
    return [TextSpan(text: sentence)];
  }

  final lowerSentence = sentence.toLowerCase();
  final lowerWord = trimmedWord.toLowerCase();
  final index = lowerSentence.indexOf(lowerWord);
  if (index < 0) {
    return [TextSpan(text: sentence)];
  }

  return [
    TextSpan(text: sentence.substring(0, index)),
    TextSpan(
      text: sentence.substring(index, index + trimmedWord.length),
      style: TextStyle(
        color: highlightColor,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      ),
    ),
    TextSpan(text: sentence.substring(index + trimmedWord.length)),
  ];
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.colors,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isActive = false,
  });

  final IdiomsWordCardColors colors;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.actionFill,
      elevation: isActive ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: CircleBorder(
        side: BorderSide(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

class _InlineSpeakButton extends ConsumerWidget {
  const _InlineSpeakButton({
    required this.text,
    required this.isExample,
    required this.colors,
  });

  final String text;
  final bool isExample;
  final IdiomsWordCardColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final tts = ref.watch(ttsProvider);
    final notifier = ref.read(ttsProvider.notifier);
    final isSpeaking = tts.isSpeakingText(text);

    return Material(
      color: isSpeaking
          ? colors.primary.withValues(alpha: 0.18)
          : colors.actionFill,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: CircleBorder(
        side: BorderSide(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => notifier.speak(text, showMiniPlayer: false),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            isExample
                ? (isSpeaking
                      ? Icons.record_voice_over_rounded
                      : Icons.record_voice_over_outlined)
                : (isSpeaking
                      ? Icons.volume_up_rounded
                      : Icons.volume_up_outlined),
            color: isSpeaking ? colors.primary : colors.actionIdle,
            size: 18,
          ),
        ),
      ),
    );
  }
}
