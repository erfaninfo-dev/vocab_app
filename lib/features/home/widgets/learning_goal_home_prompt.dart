import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/app_jelly_style.dart';
import '../../you/learning_goal_provider.dart';
import '../home_release_notes_provider.dart';

/// Session-only skip for the Home first-run prompt ("Maybe later").
final learningGoalHomePromptSessionSkipProvider = StateProvider<bool>(
  (ref) => false,
);

/// Logged-in user, hydrated empty goal, no release-notes overlay, not skipped.
final showLearningGoalHomePromptProvider = Provider<bool>((ref) {
  final goal = ref.watch(learningGoalProvider);
  if (ref.watch(learningGoalHomePromptSessionSkipProvider)) return false;
  if (!ref.watch(learningGoalHydratedProvider)) return false;

  final auth = ref.watch(authProvider);
  if (auth.isLoading || auth.valueOrNull == null) return false;
  if (goal != null) return false;

  final notes = ref.watch(homeReleaseNotesProvider);
  if (notes.isLoading || notes.valueOrNull != null) return false;

  return true;
});

class LearningGoalHomePromptGate extends ConsumerWidget {
  const LearningGoalHomePromptGate({
    super.key,
    required this.child,
    this.show = true,
  });

  final Widget child;
  final bool show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = show && ref.watch(showLearningGoalHomePromptProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (visible) const _LearningGoalHomePromptOverlay(),
      ],
    );
  }
}

class _LearningGoalHomePromptOverlay extends ConsumerStatefulWidget {
  const _LearningGoalHomePromptOverlay();

  @override
  ConsumerState<_LearningGoalHomePromptOverlay> createState() =>
      _LearningGoalHomePromptOverlayState();
}

class _LearningGoalHomePromptOverlayState
    extends ConsumerState<_LearningGoalHomePromptOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    ref.read(learningGoalHomePromptSessionSkipProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _skip();
      },
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: scheme.scrim.withValues(alpha: 0.58),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 8 + keyboard),
                      child: _LearningGoalPromptCard(onLater: _skip),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningGoalPromptCard extends ConsumerStatefulWidget {
  const _LearningGoalPromptCard({required this.onLater});

  final VoidCallback onLater;

  @override
  ConsumerState<_LearningGoalPromptCard> createState() =>
      _LearningGoalPromptCardState();
}

class _LearningGoalPromptCardState
    extends ConsumerState<_LearningGoalPromptCard> {
  static const _dayPresets = [30, 60, 90, 180, 365];

  late final TextEditingController _titleController = TextEditingController();
  late final TextEditingController _daysController = TextEditingController(
    text: '90',
  );
  final _titleFocus = FocusNode();
  var _selectedDays = 90;
  var _customDays = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _daysController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _selectSuggestion(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      _titleController.text = value;
      _titleController.selection = TextSelection.collapsed(offset: value.length);
      _error = null;
    });
  }

  void _selectDays(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDays = days;
      _customDays = false;
      _daysController.text = '$days';
      _error = null;
    });
  }

  void _enableCustomDays() {
    HapticFeedback.selectionClick();
    setState(() {
      _customDays = true;
      _error = null;
    });
  }

  int? _parsedDays() {
    final parsed = int.tryParse(_daysController.text.trim());
    if (parsed == null || parsed <= 0 || parsed > 3650) return null;
    return parsed;
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final days = _parsedDays();
    if (title.isEmpty || days == null) {
      setState(() {
        _error = _PromptCopy.of(context).validationError(title.isEmpty, days);
      });
      return;
    }

    HapticFeedback.lightImpact();
    await ref.read(learningGoalProvider.notifier).setGoal(days, title);
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PromptCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    final days = _parsedDays();
    final targetOn = days == null
        ? null
        : DateTime.now().add(Duration(days: days));

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.28),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Color.lerp(
                                scheme.surface,
                                scheme.primaryContainer,
                                0.38,
                              )!,
                              Color.lerp(
                                scheme.surface,
                                scheme.tertiaryContainer,
                                0.28,
                              )!,
                              scheme.surface,
                            ]
                          : [
                              const Color(0xFFF4F7FF),
                              Color.lerp(
                                scheme.primaryContainer,
                                Colors.white,
                                0.42,
                              )!,
                              Color.lerp(
                                scheme.tertiaryContainer,
                                Colors.white,
                                0.55,
                              )!,
                            ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -48,
                right: -36,
                child: _Blob(
                  size: 170,
                  color: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.2),
                ),
              ),
              Positioned(
                bottom: 40,
                left: -56,
                child: _Blob(
                  size: 190,
                  color: scheme.tertiary.withValues(alpha: isDark ? 0.2 : 0.16),
                ),
              ),
              ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: scheme.onSurface.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        AppJellyIconBubble(
                          color: scheme.primary,
                          size: 52,
                          child: Icon(
                            Icons.flag_rounded,
                            color: scheme.onPrimary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            copy.headline,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      copy.subtitle,
                      style: tt.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      copy.goalLabel,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final suggestion in copy.suggestions)
                          _ChoicePill(
                            label: suggestion,
                            selected: _titleController.text.trim() == suggestion,
                            onTap: () => _selectSuggestion(suggestion),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      minLines: 1,
                      maxLines: 2,
                      maxLength: 60,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() => _error = null),
                      decoration: _fieldDecoration(
                        context,
                        hint: copy.goalHint,
                        icon: Icons.edit_rounded,
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      copy.daysLabel,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final days in _dayPresets)
                          _ChoicePill(
                            label: copy.dayPresetLabel(days),
                            selected: !_customDays && _selectedDays == days,
                            onTap: () => _selectDays(days),
                          ),
                        _ChoicePill(
                          label: copy.customDays,
                          selected: _customDays,
                          onTap: _enableCustomDays,
                        ),
                      ],
                    ),
                    if (_customDays) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _daysController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          setState(() {
                            if (parsed != null && parsed > 0) {
                              _selectedDays = parsed;
                            }
                            _error = null;
                          });
                        },
                        onSubmitted: (_) => _submit(),
                        decoration: _fieldDecoration(
                          context,
                          hint: '90',
                          icon: Icons.calendar_month_rounded,
                          label: copy.customDaysHint,
                        ),
                      ),
                    ],
                    if (targetOn != null) ...[
                      const SizedBox(height: 16),
                      _TargetDateBanner(
                        label: copy.targetDate(
                          DateFormat.yMMMd(
                            Localizations.localeOf(context).toString(),
                          ).format(targetOn),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: tt.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          copy.cta,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onLater,
                      child: Text(
                        copy.later,
                        style: tt.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  String? label,
}) {
  final scheme = Theme.of(context).colorScheme;
  final fill = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    hintText: hint,
    labelText: label,
    filled: true,
    fillColor: fill,
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: scheme.primary, width: 1.6),
    ),
    prefixIcon: Icon(icon),
  );
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      scheme.primary,
                      Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.08 : 0.72),
                      scheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.45 : 0.7,
                      ),
                    ],
                  ),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: isDark ? 0.12 : 0.8),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetDateBanner extends StatelessWidget {
  const _TargetDateBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.1),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

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

class _PromptCopy {
  _PromptCopy({
    required this.headline,
    required this.subtitle,
    required this.goalLabel,
    required this.goalHint,
    required this.suggestions,
    required this.daysLabel,
    required this.customDays,
    required this.customDaysHint,
    required this.cta,
    required this.later,
    required this.targetDate,
    required this.goalRequired,
    required this.daysRequired,
    required this.day30,
    required this.day60,
    required this.day90,
    required this.day180,
    required this.day365,
  });

  final String headline;
  final String subtitle;
  final String goalLabel;
  final String goalHint;
  final List<String> suggestions;
  final String daysLabel;
  final String customDays;
  final String customDaysHint;
  final String cta;
  final String later;
  final String Function(String date) targetDate;
  final String goalRequired;
  final String daysRequired;
  final String day30;
  final String day60;
  final String day90;
  final String day180;
  final String day365;

  String dayPresetLabel(int days) {
    return switch (days) {
      30 => day30,
      60 => day60,
      90 => day90,
      180 => day180,
      365 => day365,
      _ => '$days',
    };
  }

  String validationError(bool missingTitle, int? days) {
    if (missingTitle) return goalRequired;
    if (days == null) return daysRequired;
    return goalRequired;
  }

  static _PromptCopy of(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'fa' => _fa,
      'ckb' => _ckb,
      _ => _en,
    };
  }

  static final _en = _PromptCopy(
    headline: 'Set your language mastery goal',
    subtitle:
        'Choose what you are working towards and how many days you want to get there.',
    goalLabel: 'What is your goal?',
    goalHint: 'Or write your own, e.g. IELTS band 7',
    suggestions: const [
      'IELTS band 7',
      'Fluent conversation',
      '500 new words',
      'Academic English',
    ],
    daysLabel: 'How many days?',
    customDays: 'Custom',
    customDaysHint: 'Number of days',
    cta: 'Start my journey',
    later: 'Maybe later',
    targetDate: (date) => 'Target date: $date',
    goalRequired: 'Write or pick your goal first',
    daysRequired: 'Choose a valid number of days (1–3650)',
    day30: '30 days',
    day60: '60 days',
    day90: '90 days',
    day180: '6 months',
    day365: '1 year',
  );

  static final _fa = _PromptCopy(
    headline: 'هدف تسلط به زبانت را مشخص کن',
    subtitle: 'هدفت را انتخاب کن و بگو در چند روز می‌خواهی به آن برسی.',
    goalLabel: 'هدفت چیه؟',
    goalHint: 'یا خودت بنویس، مثلاً نمره ۷ آیلتس',
    suggestions: const [
      'نمره ۷ آیلتس',
      'مکالمه روان',
      '۵۰۰ واژه جدید',
      'انگلیسی آکادمیک',
    ],
    daysLabel: 'چند روز فرصت داری؟',
    customDays: 'دلخواه',
    customDaysHint: 'تعداد روز',
    cta: 'شروع مسیر',
    later: 'بعداً',
    targetDate: (date) => 'تاریخ هدف: $date',
    goalRequired: 'اول هدفت را بنویس یا انتخاب کن',
    daysRequired: 'یک تعداد روز معتبر انتخاب کن (۱ تا ۳۶۵۰)',
    day30: '۳۰ روز',
    day60: '۶۰ روز',
    day90: '۹۰ روز',
    day180: '۶ ماه',
    day365: '۱ سال',
  );

  static final _ckb = _PromptCopy(
    headline: 'ئامانجی شارەزایی زمانەکەت دیاری بکە',
    subtitle: 'ئامانجەکەت هەڵبژێرە و بڵێ لە چەند ڕۆژدا دەتەوێت پێی بگەیت.',
    goalLabel: 'ئامانجەکەت چییە؟',
    goalHint: 'یان خۆت بنووسە، بۆ نموونە نمرەی ٧ی ئایڵتس',
    suggestions: const [
      'نمرەی ٧ی ئایڵتس',
      'قسەکردنی روان',
      '٥٠٠ وشەی نوێ',
      'ئینگلیزی ئەکادیمی',
    ],
    daysLabel: 'چەند ڕۆزت دەوێت؟',
    customDays: 'دڵخواز',
    customDaysHint: 'ژمارەی ڕۆژ',
    cta: 'دەستپێکردنی ڕێگا',
    later: 'دواتر',
    targetDate: (date) => 'بەرواری ئامانج: $date',
    goalRequired: 'سەرەتا ئامانجەکەت بنووسە یان هەڵبژێرە',
    daysRequired: 'ژمارەیەکی دروستی ڕۆژ هەڵبژێرە (١ تا ٣٦٥٠)',
    day30: '٣٠ ڕۆژ',
    day60: '٦٠ ڕۆژ',
    day90: '٩٠ ڕۆژ',
    day180: '٦ مانگ',
    day365: '١ ساڵ',
  );
}
