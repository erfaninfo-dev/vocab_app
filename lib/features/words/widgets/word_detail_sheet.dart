import 'package:flutter/material.dart';

import '../../../data/models/vocab_entry.dart';

class WordDetailSheet extends StatelessWidget {
  const WordDetailSheet({super.key, required this.entry});

  final VocabEntry entry;

  @override
  Widget build(BuildContext context) {
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
                _SectionTitle(title: 'English Meaning'),
                Text(entry.meaningEn.isEmpty ? '-' : entry.meaningEn),
                const SizedBox(height: 16),
                _SectionTitle(title: 'معنی فارسی'),
                Text(entry.meaningFa.isEmpty ? '-' : entry.meaningFa),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Example'),
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
