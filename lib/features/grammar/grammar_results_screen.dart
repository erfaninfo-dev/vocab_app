import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../data/models/grammar_result.dart';
import '../../domain/api_providers.dart';

final myGrammarResultsProvider = FutureProvider<List<GrammarResult>>((ref) {
  return ref.read(apiServiceProvider).fetchMyGrammarResults();
});

class GrammarResultsScreen extends ConsumerWidget {
  const GrammarResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Results'),
        ),
        body: const Center(
          child: Text('برای دیدن نتایج، ابتدا وارد حساب کاربری شوید.'),
        ),
      );
    }

    final async = ref.watch(myGrammarResultsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Results'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'دریافت نتایج انجام نشد. لطفاً دوباره تلاش کنید',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('هنوز نتیجه‌ای ثبت نشده است.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = items[i];
              final scoreText = (r.score != null && r.totalQuestions != null)
                  ? '${r.score}/${r.totalQuestions}'
                  : '—';
              final chips = _parseSelected(r.selectedGrammarsRaw);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.quizName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              scoreText,
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.createdAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in chips)
                              Chip(
                                label: Text(c),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<String> _parseSelected(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return const [];
    // Server stores JSON array; fall back to raw string.
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(12)
            .toList();
      }
    } catch (_) {}
    return [s];
  }
}

