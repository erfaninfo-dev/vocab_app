import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── API MODE ──────────────────────────────────────────────────────────────────
import '../../domain/api_providers.dart';

// ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────────
// import '../../domain/vocabulary_providers.dart';
// ─────────────────────────────────────────────────────────────────────────────

class FlashcardsScreen extends ConsumerStatefulWidget {
  // ── API MODE ──────────────────────────────────────────────────────────────
  const FlashcardsScreen({
    super.key,
    required this.bookId,
    required this.unit,
    required this.section, // nullable: null means the unit has no sections
  });
  final int bookId;

  // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
  // const FlashcardsScreen({
  //   super.key,
  //   required this.assetPath,
  //   required this.unit,
  //   required this.section,
  // });
  // final String assetPath;

  final int unit;
  final int? section;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  var _index = 0;
  var _showBack = false;

  @override
  Widget build(BuildContext context) {
    // ── API MODE ──────────────────────────────────────────────────────────────
    final data = ref.watch(
      apiWordsProvider((
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      )),
    );

    // ── LOCAL EXCEL MODE (commented out) ─────────────────────────────────────
    // final data = ref.watch(
    //   wordsByUnitSectionProvider((
    //     assetPath: widget.assetPath,
    //     unit: widget.unit,
    //     section: widget.section,
    //   )),
    // );

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('No words for this section.'));
          }
          final current = words[_index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Card ${_index + 1} of ${words.length}'),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showBack = !_showBack),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _showBack
                          ? _CardFace(
                              key: const ValueKey('back'),
                              title: current.meaningEn.isEmpty
                                  ? '-'
                                  : current.meaningEn,
                              subtitle: current.meaningFa,
                              subtitleRtl: true,
                            )
                          : _CardFace(
                              key: const ValueKey('front'),
                              title: current.word,
                              subtitle: current.type,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index == 0
                            ? null
                            : () => setState(() {
                                _index--;
                                _showBack = false;
                              }),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _index == words.length - 1
                            ? null
                            : () => setState(() {
                                _index++;
                                _showBack = false;
                              }),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleRtl = false,
  });

  final String title;
  final String subtitle;
  final bool subtitleRtl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [scheme.primaryContainer, scheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 14),
              subtitleRtl
                  ? Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
            ],
            const SizedBox(height: 14),
            Text(
              'Tap card to flip',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
