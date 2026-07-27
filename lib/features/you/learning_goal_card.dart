import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'learning_goal_provider.dart';
import 'you_jelly_style.dart';

String learningGoalSectionTitle(BuildContext context) {
  return _GoalCopy.of(context).sectionTitle;
}

class LearningGoalCard extends ConsumerWidget {
  const LearningGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final goal = ref.watch(learningGoalProvider);
    final copy = _GoalCopy.of(context);
    final now = DateTime.now();

    return YouJellyShell(
      onTap: () {
        if (goal == null) {
          _showGoalDaysDialog(context, ref);
        } else {
          _showGoalDetailsSheet(context, ref, goal);
        }
      },
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: youJellyCardSurfaceDecoration(context, scheme: scheme),
      shadows: youJellyCardShadows(context, scheme: scheme),
      child: goal == null
          ? _LearningGoalPrompt(copy: copy, scheme: scheme)
          : _LearningGoalSummary(goal: goal, now: now, copy: copy),
    );
  }
}

class _LearningGoalPrompt extends StatelessWidget {
  const _LearningGoalPrompt({required this.copy, required this.scheme});

  final _GoalCopy copy;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        YouJellyIconBubble(
          color: scheme.primary,
          child: Icon(Icons.flag_rounded, color: scheme.onPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.cardTitle,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                copy.cardPromptSubtitle,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        YouJellyIconBubble(
          color: scheme.secondary,
          size: 36,
          child: Icon(Icons.add_rounded, size: 20, color: scheme.onSecondary),
        ),
      ],
    );
  }
}

class _LearningGoalSummary extends StatelessWidget {
  const _LearningGoalSummary({
    required this.goal,
    required this.now,
    required this.copy,
  });

  final LearningGoal goal;
  final DateTime now;
  final _GoalCopy copy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = goal.progress(now);
    final pct = (progress * 100).round().clamp(0, 100);
    final remaining = goal.remainingDays(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            YouJellyIconBubble(
              color: scheme.primary,
              child: Icon(Icons.auto_awesome_rounded, color: scheme.onPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.cardTitle,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    copy.summarySubtitle(remaining, goal.totalDays),
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            _JellyPercentBadge(pct: pct, compact: true),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _JellyProgressBar(progress: progress.clamp(0.0, 1.0)),
      ],
    );
  }
}

Future<void> _showGoalDaysDialog(BuildContext context, WidgetRef ref) async {
  final copy = _GoalCopy.of(context);

  final days = await showDialog<int>(
    context: context,
    builder: (ctx) => _GoalDaysDialog(copy: copy),
  );

  if (days == null) return;
  if (!context.mounted) return;
  await ref.read(learningGoalProvider.notifier).setGoalDays(days);
}

class _GoalDaysDialog extends StatefulWidget {
  const _GoalDaysDialog({required this.copy});

  final _GoalCopy copy;

  @override
  State<_GoalDaysDialog> createState() => _GoalDaysDialogState();
}

class _GoalDaysDialogState extends State<_GoalDaysDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(int.parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    return AlertDialog(
      title: Text(copy.dialogTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: copy.dialogFieldLabel,
            hintText: '90',
          ),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            if (parsed == null || parsed <= 0) return copy.dialogInvalid;
            if (parsed > 3650) return copy.dialogTooLong;
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(copy.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(copy.save)),
      ],
    );
  }
}

Future<void> _showGoalDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  LearningGoal goal,
) async {
  final copy = _GoalCopy.of(context);
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.74,
        minChildSize: 0.42,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Color.lerp(
                          scheme.surface,
                          scheme.primaryContainer,
                          0.22,
                        )!,
                        Color.lerp(
                          scheme.surface,
                          scheme.tertiaryContainer,
                          0.18,
                        )!,
                        scheme.surface,
                      ]
                    : [
                        const Color(0xFFF4F7FF),
                        Color.lerp(
                          scheme.primaryContainer,
                          Colors.white,
                          0.55,
                        )!,
                        Color.lerp(
                          scheme.tertiaryContainer,
                          Colors.white,
                          0.62,
                        )!,
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -30,
                    child: _JellyBlob(
                      size: 160,
                      color: scheme.primary.withValues(
                        alpha: isDark ? 0.22 : 0.18,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: -50,
                    child: _JellyBlob(
                      size: 180,
                      color: scheme.tertiary.withValues(
                        alpha: isDark ? 0.16 : 0.14,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: 40,
                    child: _JellyBlob(
                      size: 90,
                      color: scheme.secondary.withValues(
                        alpha: isDark ? 0.12 : 0.1,
                      ),
                    ),
                  ),
                  _LearningGoalDetails(
                    goal: goal,
                    copy: copy,
                    scrollController: scrollController,
                    onEdit: () async {
                      Navigator.of(ctx).pop();
                      await _showGoalDaysDialog(context, ref);
                    },
                    onClear: () async {
                      await ref.read(learningGoalProvider.notifier).clearGoal();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _LearningGoalDetails extends StatelessWidget {
  const _LearningGoalDetails({
    required this.goal,
    required this.copy,
    required this.scrollController,
    required this.onEdit,
    required this.onClear,
  });

  final LearningGoal goal;
  final _GoalCopy copy;
  final ScrollController scrollController;
  final VoidCallback onEdit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final elapsed = goal.elapsedDays(now);
    final remaining = goal.remainingDays(now);
    final pct = (goal.progress(now) * 100).round().clamp(0, 100);
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: scheme.onSurface.withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.55),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.detailsTitle,
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.detailsSubtitle(remaining),
                    style: tt.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _JellyPercentBadge(pct: pct),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _GoalMetric(
                label: copy.elapsedLabel,
                value: '$elapsed',
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GoalMetric(
                label: copy.remainingLabel,
                value: '$remaining',
                color: scheme.tertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GoalMetric(
                label: copy.totalLabel,
                value: '${goal.totalDays}',
                color: scheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          copy.targetDate(dateFormat.format(goal.targetOn)),
          style: tt.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        _GoalDaysGrid(totalDays: goal.totalDays, elapsedDays: elapsed),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _JellyActionButton(
                onPressed: onEdit,
                icon: Icons.edit_calendar_rounded,
                label: copy.edit,
                filled: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _JellyActionButton(
                onPressed: onClear,
                icon: Icons.delete_outline_rounded,
                label: copy.clear,
                filled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, isDark ? 0.12 : 0.82)!,
            Color.lerp(color, Colors.white, isDark ? 0.22 : 0.92)!,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.85),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.7),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              color: Color.lerp(color, scheme.onSurface, isDark ? 0.15 : 0.2),
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDaysGrid extends StatelessWidget {
  const _GoalDaysGrid({required this.totalDays, required this.elapsedDays});

  final int totalDays;
  final int elapsedDays;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 18).floor().clamp(10, 22);
        final gap = 5.0;
        final size = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(totalDays, (index) {
            final active = index < elapsedDays;
            return AnimatedContainer(
              duration: Duration(milliseconds: 180 + (index % 8) * 18),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.42),
                gradient: active
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(scheme.primary, Colors.white, 0.35)!,
                          scheme.primary,
                          Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.06 : 0.55),
                          scheme.surfaceContainerHighest.withValues(
                            alpha: isDark ? 0.45 : 0.65,
                          ),
                        ],
                      ),
                border: Border.all(
                  color: active
                      ? Colors.white.withValues(alpha: 0.55)
                      : scheme.outlineVariant.withValues(
                          alpha: isDark ? 0.35 : 0.55,
                        ),
                  width: active ? 1.2 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.45),
                          blurRadius: 10,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.55),
                          blurRadius: 2,
                          offset: const Offset(0, -1),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.12 : 0.04,
                          ),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _JellyPercentBadge extends StatelessWidget {
  const _JellyPercentBadge({required this.pct, this.compact = false});

  final int pct;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padH = compact ? 12.0 : 16.0;
    final padV = compact ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(
              scheme.primaryContainer,
              Colors.white,
              isDark ? 0.05 : 0.35,
            )!,
            Color.lerp(
              scheme.secondaryContainer,
              scheme.primaryContainer,
              0.4,
            )!,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.8),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.75),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Text(
        '$pct%',
        style: (compact ? tt.titleMedium : tt.titleLarge)?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _JellyProgressBar extends StatelessWidget {
  const _JellyProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.45 : 0.55,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * progress.clamp(0.0, 1.0);
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              width: width.clamp(0.0, constraints.maxWidth),
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(scheme.primary, Colors.white, 0.28)!,
                    scheme.primary,
                    Color.lerp(scheme.primary, scheme.tertiary, 0.4)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 2.5),
                  height: 3.5,
                  width: (width - 10).clamp(0.0, double.infinity),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JellyActionButton extends StatelessWidget {
  const _JellyActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.filled,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = BorderRadius.all(Radius.circular(999));

    return YouJellyShell(
      onTap: onPressed,
      borderRadius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(scheme.primary, Colors.white, 0.22)!,
                  scheme.primary,
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.08 : 0.55),
                  scheme.surfaceContainerHighest.withValues(
                    alpha: isDark ? 0.35 : 0.45,
                  ),
                ],
              ),
        border: Border.all(
          color: filled
              ? Colors.white.withValues(alpha: 0.45)
              : scheme.primary.withValues(alpha: 0.35),
          width: 1.3,
        ),
      ),
      shadows: [
        BoxShadow(
          color: (filled ? scheme.primary : scheme.shadow).withValues(
            alpha: filled ? 0.28 : 0.08,
          ),
          blurRadius: filled ? 16 : 10,
          offset: const Offset(0, 6),
        ),
      ],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: filled ? scheme.onPrimary : scheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: filled ? scheme.onPrimary : scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JellyBlob extends StatelessWidget {
  const _JellyBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _GoalCopy {
  const _GoalCopy({
    required this.sectionTitle,
    required this.cardTitle,
    required this.cardPromptSubtitle,
    required this.dialogTitle,
    required this.dialogFieldLabel,
    required this.dialogInvalid,
    required this.dialogTooLong,
    required this.cancel,
    required this.save,
    required this.detailsTitle,
    required this.elapsedLabel,
    required this.remainingLabel,
    required this.totalLabel,
    required this.edit,
    required this.clear,
    required this.summarySubtitle,
    required this.detailsSubtitle,
    required this.targetDate,
  });

  final String sectionTitle;
  final String cardTitle;
  final String cardPromptSubtitle;
  final String dialogTitle;
  final String dialogFieldLabel;
  final String dialogInvalid;
  final String dialogTooLong;
  final String cancel;
  final String save;
  final String detailsTitle;
  final String elapsedLabel;
  final String remainingLabel;
  final String totalLabel;
  final String edit;
  final String clear;
  final String Function(int remaining, int total) summarySubtitle;
  final String Function(int remaining) detailsSubtitle;
  final String Function(String date) targetDate;

  static _GoalCopy of(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'fa' => _fa,
      _ => _en,
    };
  }

  static final _en = _GoalCopy(
    sectionTitle: 'Goal',
    cardTitle: 'Language mastery goal',
    cardPromptSubtitle: 'How many days from now do you want to be fluent?',
    dialogTitle: 'Set your goal',
    dialogFieldLabel: 'Days until fluency',
    dialogInvalid: 'Enter a valid number of days',
    dialogTooLong: 'Choose 3650 days or fewer',
    cancel: 'Cancel',
    save: 'Save',
    detailsTitle: 'Goal timeline',
    elapsedLabel: 'Passed',
    remainingLabel: 'Left',
    totalLabel: 'Total',
    edit: 'Edit',
    clear: 'Clear',
    summarySubtitle: (remaining, total) =>
        '$remaining days left from $total days',
    detailsSubtitle: (remaining) => '$remaining days left to your target',
    targetDate: (date) => 'Target date: $date',
  );

  static final _fa = _GoalCopy(
    sectionTitle: 'هدف',
    cardTitle: 'هدف تسلط به زبان',
    cardPromptSubtitle: 'می‌خواهی تا چند روز دیگر به زبان مسلط شده باشی؟',
    dialogTitle: 'هدف خودت را مشخص کن',
    dialogFieldLabel: 'تعداد روز تا تسلط',
    dialogInvalid: 'یک تعداد روز معتبر وارد کن',
    dialogTooLong: 'حداکثر ۳۶۵۰ روز را انتخاب کن',
    cancel: 'لغو',
    save: 'ذخیره',
    detailsTitle: 'مسیر هدف',
    elapsedLabel: 'گذشته',
    remainingLabel: 'مانده',
    totalLabel: 'کل',
    edit: 'ویرایش',
    clear: 'حذف',
    summarySubtitle: (remaining, total) => '$remaining روز مانده از $total روز',
    detailsSubtitle: (remaining) => '$remaining روز تا هدف تو مانده',
    targetDate: (date) => 'تاریخ هدف: $date',
  );
}
