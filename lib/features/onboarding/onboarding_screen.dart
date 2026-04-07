import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/onboarding/onboarding_prefs.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    icon: Icons.auto_stories_rounded,
    title: 'Books & words',
    body:
        'Start from Home: pick a book, open units, then browse words. Use flashcards and quizzes inside each unit to study the way you like.',
  ),
  _Slide(
    icon: Icons.rule_rounded,
    title: 'Grammar practice',
    body:
        'Open the Grammar tab below. Select one or more topics and start a session — each run uses 20 random questions with explanations.',
  ),
  _Slide(
    icon: Icons.loop_rounded,
    title: 'Daily review',
    body:
        'Review uses spaced repetition for words you\'ve practiced. Check the badge on the tab when cards are due.',
  ),
  _Slide(
    icon: Icons.bar_chart_rounded,
    title: 'Your progress',
    body:
        'Progress shows streaks and activity. Keep a steady rhythm to build a habit.',
  ),
  _Slide(
    icon: Icons.tune_rounded,
    title: 'Make it yours',
    body:
        'In Settings: theme, translation language (Persian / Kurdish), reminders, and more.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await setOnboardingCompleted();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = _page >= _slides.length - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.12),
              scheme.secondary.withValues(alpha: 0.08),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, index) {
                    final s = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: scheme.primaryContainer.withValues(
                                alpha: 0.65,
                              ),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Icon(
                              s.icon,
                              size: 48,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            s.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  height: 1.45,
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i == _page
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        onPressed: () {
                          _controller.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: const Text('Back'),
                      )
                    else
                      const SizedBox(width: 72),
                    Expanded(
                      child: FilledButton(
                        onPressed: last
                            ? _finish
                            : () {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(last ? 'Get started' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
