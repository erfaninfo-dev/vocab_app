import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/language_provider.dart';
import '../../../data/models/vocab_entry.dart';
import '../../../l10n/app_localizations.dart';

class WordDetailSheet extends ConsumerWidget {
  const WordDetailSheet({super.key, required this.entry});

  final VocabEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(langProvider);
    final localMeaningTitle = lang == TranslationLang.fa
        ? l10n.translationLangPersian
        : l10n.translationLangKurdishSorani;
    final localMeaning = entry.meaningFor(lang);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.word,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (entry.type.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Chip(label: Text(entry.type)),
                ],
                const SizedBox(height: 16),
                _SectionTitle(title: l10n.englishMeaning),
                Text(entry.meaningEn.isEmpty ? '-' : entry.meaningEn),
                const SizedBox(height: 16),
                _SectionTitle(title: localMeaningTitle),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(localMeaning.isEmpty ? '-' : localMeaning),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: l10n.wordExample),
                Text(entry.example.isEmpty ? '-' : entry.example),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
