import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../data/models/grammar_result.dart';
import '../../data/models/teacher_student.dart';
import '../../data/models/vocab_quiz_result.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

String _teacherUnitsCsv(List<int> units) {
  if (units.isEmpty) return '—';
  return units.join(', ');
}

String _teacherFormatDate(BuildContext context, String? raw) {
  if (raw == null || raw.trim().isEmpty) return '—';
  final t = raw.trim();
  final normalized = t.contains('T') ? t : t.replaceFirst(' ', 'T');
  final dt = DateTime.tryParse(normalized);
  if (dt == null) return raw;
  final loc = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(loc).add_Hm().format(dt.toLocal());
}

class TeacherStudentDetailScreen extends ConsumerStatefulWidget {
  const TeacherStudentDetailScreen({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<TeacherStudentDetailScreen> createState() =>
      _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState
    extends ConsumerState<TeacherStudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _sessionCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  var _sessionLoaded = false;
  var _savingSessions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future<void>.microtask(() async {
      try {
        final info = await ref
            .read(apiServiceProvider)
            .fetchTeacherStudentSessions(widget.studentId);
        if (!mounted) {
          return;
        }
        setState(() {
          _sessionCtrl.text = '${info.sessionCount}';
          _noteCtrl.text = info.note ?? '';
          _sessionLoaded = true;
        });
      } catch (_) {
        if (mounted) {
          setState(() => _sessionLoaded = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessionCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  TeacherStudentSummary? _resolveStudent(List<TeacherStudentSummary> list) {
    for (final s in list) {
      if (s.id == widget.studentId) {
        return s;
      }
    }
    return null;
  }

  Future<void> _saveSessions(AppLocalizations l10n) async {
    final parsed = int.tryParse(_sessionCtrl.text.trim());
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherSessionInvalid)),
      );
      return;
    }
    setState(() => _savingSessions = true);
    try {
      await ref.read(apiServiceProvider).setTeacherStudentSessions(
            studentId: widget.studentId,
            sessionCount: parsed,
            note: _noteCtrl.text,
          );
      ref.invalidate(teacherStudentSessionsProvider(widget.studentId));
      ref.invalidate(teacherStudentsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherSessionUpdated)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyErrorMessage(e, l10n)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingSessions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final session = ref.watch(authProvider).valueOrNull;

    if (session == null || !session.user.isTeacher) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.teacherStudentDetailTitle),
        ),
        body: Center(child: Text(l10n.teacherAccessDenied)),
      );
    }

    final studentsAsync = ref.watch(teacherStudentsProvider);
    final student = studentsAsync.valueOrNull == null
        ? null
        : _resolveStudent(studentsAsync.valueOrNull!);
    final title = student?.displayLabel ?? l10n.teacherStudentDetailTitle;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_rounded),
            tooltip: l10n.teacherStudentChat,
            onPressed: () {
              final hint = student?.displayLabel;
              if (hint != null && hint.trim().isNotEmpty) {
                context.push(
                  '/teacher/chat/${widget.studentId}',
                  extra: hint.trim(),
                );
              } else {
                context.push('/teacher/chat/${widget.studentId}');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.teacherTabVocabQuiz),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.rule_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.teacherTabGrammar),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _VocabTab(studentId: widget.studentId),
                _GrammarTab(studentId: widget.studentId),
              ],
            ),
          ),
          Material(
            elevation: 8,
            shadowColor: Colors.black26,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.teacherClassSessions,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _sessionCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.teacherSessionCountLabel,
                        border: const OutlineInputBorder(),
                        suffixIcon: _sessionLoaded
                            ? null
                            : const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          color: scheme.secondary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.teacherNoteLabel,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 8000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.teacherNotePlaceholder,
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed:
                          _savingSessions ? null : () => _saveSessions(l10n),
                      icon: _savingSessions
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(l10n.teacherSessionSave),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabTab extends ConsumerWidget {
  const _VocabTab({required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(teacherStudentVocabResultsProvider(studentId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            userFriendlyErrorMessage(e, l10n),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (List<VocabQuizResultSummary> rows) {
        if (rows.isEmpty) {
          return Center(child: Text(l10n.teacherNoResults));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = rows[i];
            final bookTitle =
                (r.bookTitle != null && r.bookTitle!.trim().isNotEmpty)
                    ? r.bookTitle!.trim()
                    : 'Book #${r.bookId}';
            final quizTitle = (r.quizName != null &&
                    r.quizName!.trim().isNotEmpty)
                ? r.quizName!.trim()
                : l10n.vocabularyQuizTitle;
            return Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      quizTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.vocabQuizHistoryUnitsLine(
                        _teacherUnitsCsv(r.units),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.vocabQuizCorrectWrongLine(r.correct, r.wrong),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (r.createdAt != null &&
                        r.createdAt!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          _teacherFormatDate(
                            context,
                            r.createdAt,
                          ),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GrammarTab extends ConsumerWidget {
  const _GrammarTab({required this.studentId});

  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(teacherStudentGrammarResultsProvider(studentId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            userFriendlyErrorMessage(e, l10n),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (List<GrammarResult> rows) {
        if (rows.isEmpty) {
          return Center(child: Text(l10n.teacherNoResults));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = rows[i];
            final pct = (r.score != null &&
                    r.totalQuestions != null &&
                    r.totalQuestions! > 0)
                ? ((r.score! / r.totalQuestions!) * 100).round()
                : null;
            return Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.quizName.isNotEmpty ? r.quizName : l10n.grammarAppBar,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (r.score != null && r.totalQuestions != null) ...[
                      Text(
                        l10n.vocabQuizResultScoreLine(r.score!, r.totalQuestions!),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (pct != null)
                        Text(
                          '$pct%',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _teacherFormatDate(
                        context,
                        r.createdAt.isNotEmpty ? r.createdAt : null,
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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
}
