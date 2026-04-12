import 'package:flutter/material.dart';
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
import '../grammar/grammar_practice_result_card.dart';
import '../you/class_sessions_strip.dart';
import 'teacher_chat_open_args.dart';

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
  final _noteCtrl = TextEditingController();
  var _noteHydrated = false;
  var _savingNote = false;
  var _addingSession = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _saveNote(AppLocalizations l10n) async {
    setState(() => _savingNote = true);
    try {
      await ref.read(apiServiceProvider).updateTeacherStudentNote(
            studentId: widget.studentId,
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
        setState(() => _savingNote = false);
      }
    }
  }

  Future<void> _addSession(AppLocalizations l10n) async {
    setState(() => _addingSession = true);
    try {
      await ref.read(apiServiceProvider).addTeacherClassSession(widget.studentId);
      ref.invalidate(teacherStudentSessionsProvider(widget.studentId));
      ref.invalidate(teacherStudentsProvider);
      if (!mounted) {
        return;
      }
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
        setState(() => _addingSession = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final session = ref.watch(authProvider).valueOrNull;

    ref.listen(
      teacherStudentSessionsProvider(widget.studentId),
      (prev, next) {
        next.whenData((info) {
          if (!_noteHydrated && mounted) {
            _noteHydrated = true;
            _noteCtrl.text = info.note ?? '';
          }
        });
      },
    );

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
              final s = student;
              final args = s != null
                  ? TeacherChatOpenArgs(
                      displayTitle: s.displayLabel,
                      avatarId: s.avatar,
                      userId: s.id,
                    )
                  : null;
              context.push(
                '/teacher/chat/${widget.studentId}',
                extra: args,
              );
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
                    ref
                        .watch(teacherStudentSessionsProvider(widget.studentId))
                        .when(
                          loading: () => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.teacherClassSessions,
                                  style: tt.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              userFriendlyErrorMessage(e, l10n),
                              style: tt.bodySmall?.copyWith(color: scheme.error),
                            ),
                          ),
                          data: (info) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClassSessionsStrip(
                                sessions: info.sessions,
                                readOnly: false,
                                onAdd: () => _addSession(l10n),
                                isAdding: _addingSession,
                              ),
                              if (info.sessions.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    l10n.teacherClassSessionsHintEmpty,
                                    style: tt.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
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
                      onPressed: _savingNote ? null : () => _saveNote(l10n),
                      icon: _savingNote
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(l10n.teacherSessionSaveNote),
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
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = rows[i];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/grammar/result/${r.id}'),
              child: GrammarPracticeResultCard(
                r: r,
                style: GrammarPracticeResultCardStyle.personal,
              ),
            );
          },
        );
      },
    );
  }
}
