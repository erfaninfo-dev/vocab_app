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
import 'teacher_chat_open_args.dart';
import 'teacher_class_schedule_panel.dart';
import 'teacher_class_sessions_panel.dart';

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

bool _omitVocabQuizTypeLine(String? rawQuizName, AppLocalizations l10n) {
  final n = rawQuizName?.trim();
  if (n == null || n.isEmpty) return true;
  if (n == l10n.vocabularyQuizTitle) return true;
  if (n == 'Vocabulary quiz') return true;
  return false;
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(authProvider).valueOrNull;

    if (session == null || (!session.user.isTeacher && !session.user.isAdmin)) {
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
              context.push('/teacher/chat/${widget.studentId}', extra: args);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.teacherTabVocabQuiz),
                  ],
                ),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rule_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.teacherTabGrammar),
                  ],
                ),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_available_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.teacherTabClassSessions),
                  ],
                ),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.teacherTabWeeklySchedule),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _VocabTab(studentId: widget.studentId),
          _GrammarTab(studentId: widget.studentId),
          TeacherClassSessionsPanel(studentId: widget.studentId),
          TeacherClassSchedulePanel(studentId: widget.studentId),
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
            final omitQuizType = _omitVocabQuizTypeLine(r.quizName, l10n);
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
                    if (!omitQuizType) ...[
                      Text(
                        r.quizName!.trim(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      bookTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.vocabQuizHistoryUnitsLine(_teacherUnitsCsv(r.units)),
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
                          _teacherFormatDate(context, r.createdAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
