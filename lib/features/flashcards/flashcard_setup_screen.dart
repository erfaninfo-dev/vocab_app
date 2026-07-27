import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../core/widgets/app_jelly_style.dart';
import '../../core/widgets/app_gradient_scaffold.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../words/important_words_controller.dart';
import '../words/word_preferences_controller.dart';
import 'flashcard_deck_builder.dart';
import 'flashcard_prefs.dart';
import 'flashcard_session_storage.dart';
import 'models/flashcard_direction.dart';
import 'models/flashcard_pool.dart';
import 'models/flashcard_session.dart';
import 'widgets/flashcard_empty_state.dart';
import 'widgets/flashcard_resume_dialog.dart';

class FlashcardSetupScreen extends ConsumerStatefulWidget {
  const FlashcardSetupScreen({
    super.key,
    required this.bookId,
    required this.unit,
    this.section,
  });

  final int bookId;
  final int unit;
  final int? section;

  @override
  ConsumerState<FlashcardSetupScreen> createState() =>
      _FlashcardSetupScreenState();
}

class _FlashcardSetupScreenState extends ConsumerState<FlashcardSetupScreen> {
  late FlashcardPool _pool;
  late FlashcardDirection _direction;
  late bool _shuffle;
  late bool _srsEnabled;
  late bool _swipeRatings;
  bool _prefsLoaded = false;

  bool _resumable = false;
  int _resumeCurrent = 0;
  int _resumeTotal = 0;
  bool _checkingResume = false;

  ({int bookId, int unit, int? section}) get _bus => (
        bookId: widget.bookId,
        unit: widget.unit,
        section: widget.section,
      );

  String get _deckKey => flashcardDeckKey(
        widget.bookId,
        widget.unit,
        widget.section,
        _pool,
        _direction,
        _shuffle,
      );

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(flashcardPrefsProvider);
    _pool = prefs.defaultPool;
    _direction = prefs.defaultDirection;
    _shuffle = prefs.shuffle;
    _srsEnabled = prefs.srsEnabled;
    _swipeRatings = prefs.swipeRatings;
    _prefsLoaded = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefsLoaded) {
      _prefsLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshResume());
    }
  }

  void _onSelectionChanged() {
    _savePrefs();
    _refreshResume();
  }

  Future<void> _savePrefs() async {
    final n = ref.read(flashcardPrefsProvider.notifier);
    await n.setPool(_pool);
    await n.setDirection(_direction);
    await n.setShuffle(_shuffle);
    await n.setSrsEnabled(_srsEnabled);
    await n.setSwipeRatings(_swipeRatings);
  }

  Future<void> _refreshResume() async {
    if (!mounted) return;
    setState(() => _checkingResume = true);
    final key = _deckKey;
    final resumable = await FlashcardSessionStorage.hasResumableSession(key);
    int current = 0;
    int total = 0;
    if (resumable) {
      final saved = await FlashcardSessionStorage.loadSession(key);
      if (saved != null) {
        current = saved.currentIndex;
        total = saved.wordIds.length;
      }
    }
    if (!mounted) return;
    setState(() {
      _resumable = resumable;
      _resumeCurrent = current;
      _resumeTotal = total;
      _checkingResume = false;
    });
  }

  String get _sessionRoute {
    final base = widget.section == null
        ? '/books/${widget.bookId}/units/${widget.unit}/flashcards/session'
        : '/books/${widget.bookId}/units/${widget.unit}/sections/${widget.section}/flashcards/session';
    final q = {
      'pool': _pool.key,
      'dir': _direction.key,
      'shuffle': _shuffle ? '1' : '0',
      'srs': _srsEnabled ? '1' : '0',
      'swipe': _swipeRatings ? '1' : '0',
    };
    final pairs = q.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$base?$pairs';
  }

  Future<void> _startOrConfirm({required bool forceFresh}) async {
    final wordsAsync = ref.read(apiWordsProvider(_bus));
    final words = wordsAsync.valueOrNull ?? const [];
    final important = ref.read(importantWordsProvider);
    final favorites = ref.read(wordPreferencesProvider);
    final count = FlashcardDeckBuilder.countForPool(
      source: words,
      pool: _pool,
      isImportant: important.isMarked,
      isFavorite: favorites.isFavorite,
    );
    if (count == 0) return;

    if (!forceFresh && _resumable) {
      final choice = await showFlashcardResumeDialog(
        context: context,
        current: _resumeCurrent,
        total: _resumeTotal,
      );
      if (choice == null) return;
      if (choice == false) {
        await FlashcardSessionStorage.clearSession(_deckKey);
      }
    }
    if (!mounted) return;
    context.push(_sessionRoute);
  }

  Future<void> _continueSession() async {
    if (!_resumable) {
      await _startOrConfirm(forceFresh: false);
      return;
    }
    if (!mounted) return;
    context.push(_sessionRoute);
  }

  Future<void> _startFresh() async {
    await FlashcardSessionStorage.clearSession(_deckKey);
    if (!mounted) return;
    context.push(_sessionRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wordsAsync = ref.watch(apiWordsProvider(_bus));
    final important = ref.watch(importantWordsProvider);
    final favorites = ref.watch(wordPreferencesProvider);

    final appBar = styledAppGradientAppBar(
      context: context,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(l10n.flashcardSetupTitle),
    );
    final topInset = appGradientContentTopInset(context, appBar: appBar, extra: 12);

    return AppGradientScaffold(
      appBar: appBar,
      body: wordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(userFriendlyErrorMessage(e, l10n)),
          ),
        ),
        data: (words) {
          final allCount = words.length;
          final importantCount = words.where(important.isMarked).length;
          final favoritesCount = words.where(favorites.isFavorite).length;
          final selectedCount = switch (_pool) {
            FlashcardPool.all => allCount,
            FlashcardPool.important => importantCount,
            FlashcardPool.favorites => favoritesCount,
          };

          return ListView(
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
            children: [
              _SetupHeader(unit: widget.unit, section: widget.section),
              const SizedBox(height: 18),

              _SectionLabel(text: l10n.flashcardSetupDeck),
              AppJellyCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PoolTile(
                      icon: Icons.style_rounded,
                      title: l10n.flashcardSetupPoolAll,
                      count: allCount,
                      selected: _pool == FlashcardPool.all,
                      onTap: () => setState(() {
                        _pool = FlashcardPool.all;
                        _onSelectionChanged();
                      }),
                    ),
                    _PoolTile(
                      icon: Icons.priority_high_rounded,
                      title: l10n.flashcardSetupPoolImportant,
                      count: importantCount,
                      selected: _pool == FlashcardPool.important,
                      onTap: () => setState(() {
                        _pool = FlashcardPool.important;
                        _onSelectionChanged();
                      }),
                    ),
                    _PoolTile(
                      icon: Icons.star_rounded,
                      title: l10n.flashcardSetupPoolFavorites,
                      count: favoritesCount,
                      selected: _pool == FlashcardPool.favorites,
                      onTap: () => setState(() {
                        _pool = FlashcardPool.favorites;
                        _onSelectionChanged();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _SectionLabel(text: l10n.flashcardSetupOrder),
              AppJellyCard(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  secondary: const Icon(Icons.shuffle_rounded),
                  title: Text(l10n.flashcardSetupShuffle),
                  value: _shuffle,
                  onChanged: (v) => setState(() {
                    _shuffle = v;
                    _onSelectionChanged();
                  }),
                ),
              ),
              const SizedBox(height: 18),

              _SectionLabel(text: l10n.flashcardSetupDirection),
              AppJellyCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    RadioListTile<FlashcardDirection>(
                      value: FlashcardDirection.wordToMeaning,
                      groupValue: _direction,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _direction = v;
                          _onSelectionChanged();
                        });
                      },
                      title: Text(l10n.flashcardSetupDirectionWordToMeaning),
                    ),
                    RadioListTile<FlashcardDirection>(
                      value: FlashcardDirection.meaningToWord,
                      groupValue: _direction,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _direction = v;
                          _onSelectionChanged();
                        });
                      },
                      title: Text(l10n.flashcardSetupDirectionMeaningToWord),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              _SectionLabel(text: l10n.flashcardSetupOptions),
              AppJellyCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.replay_rounded),
                      title: Text(l10n.flashcardSetupSrsToggle),
                      subtitle: Text(l10n.flashcardSetupSrs),
                      value: _srsEnabled,
                      onChanged: (v) => setState(() {
                        _srsEnabled = v;
                        _onSelectionChanged();
                      }),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.swipe_rounded),
                      title: Text(l10n.flashcardSetupSwipeRatings),
                      value: _swipeRatings,
                      onChanged: (v) => setState(() {
                        _swipeRatings = v;
                        _onSelectionChanged();
                      }),
                    ),
                  ],
                ),
              ),

              if (_resumable && selectedCount > 0) ...[
                const SizedBox(height: 20),
                _ResumeCard(
                  current: _resumeCurrent,
                  total: _resumeTotal,
                  onContinue: _continueSession,
                  onStartFresh: _startFresh,
                ),
              ],

              if (selectedCount == 0) ...[
                const SizedBox(height: 24),
                FlashcardEmptyState(
                  kind: switch (_pool) {
                    FlashcardPool.important => FlashcardEmptyKind.important,
                    FlashcardPool.favorites => FlashcardEmptyKind.favorites,
                    FlashcardPool.all => FlashcardEmptyKind.noWords,
                  },
                  onAction: () => Navigator.of(context).maybePop(),
                ),
              ],

              const SizedBox(height: 24),
              _StartButton(
                label: l10n.flashcardSetupStart,
                enabled: selectedCount > 0,
                onTap: () => _startOrConfirm(forceFresh: false),
              ),
              if (_checkingResume) const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({required this.unit, required this.section});

  final int unit;
  final int? section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return AppJellyCard(
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kAppJellyRadius),
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
            child: Row(
              children: [
                AppJellyIconBubble(
                  color: Colors.white.withValues(alpha: 0.35),
                  child: const Icon(
                    Icons.style_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.flashcardSetupTitle,
                        style: tt.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        section == null
                            ? l10n.flashcardSetupUnitTitle(unit)
                            : l10n.flashcardSetupUnitSectionTitle(
                                unit,
                                section!,
                              ),
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PoolTile extends StatelessWidget {
  const _PoolTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.16)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: tt.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected ? scheme.onSurface : scheme.onSurface,
                    ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.14)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off,
                key: ValueKey(selected),
                size: 22,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.current,
    required this.total,
    required this.onContinue,
    required this.onStartFresh,
  });

  final int current;
  final int total;
  final VoidCallback onContinue;
  final VoidCallback onStartFresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return AppJellyCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: scheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.flashcardSetupResumeTitle,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.flashcardSetupResumeBody(current, total),
            style: tt.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.flashcardSetupResumeContinue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStartFresh,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.flashcardSetupResumeFresh),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = [scheme.primary, scheme.tertiary];
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: enabled
                ? gradient
                : [scheme.surfaceContainerHighest, scheme.surfaceContainerHighest],
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: enabled ? Colors.white : scheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled ? Colors.white : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
