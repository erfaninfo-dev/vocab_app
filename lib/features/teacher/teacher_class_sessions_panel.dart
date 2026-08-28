import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/datetime/class_session_chronological_index.dart';
import '../../core/datetime/class_session_recorded_at.dart';
import '../../core/errors/user_friendly_error.dart';
import '../../core/financial/financial_format.dart';
import '../../core/widgets/app_jelly_style.dart';
import '../../core/widgets/term_payment_status_chip.dart';
import '../../core/widgets/term_title_card.dart';
import '../../data/models/teacher_class_group.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';

List<MapEntry<DateTime, List<ClassSessionEntry>>> _groupByDay(
  List<ClassSessionEntry> sessions,
) {
  final map = <DateTime, List<ClassSessionEntry>>{};
  final unparsed = <ClassSessionEntry>[];
  for (final s in sessions) {
    final dt = parseClassSessionRecordedAtFromApi(s.recordedAtRaw);
    if (dt == null) {
      unparsed.add(s);
      continue;
    }
    final day = DateTime(dt.year, dt.month, dt.day);
    map.putIfAbsent(day, () => []).add(s);
  }
  for (final list in map.values) {
    list.sort((a, b) {
      final da = parseClassSessionRecordedAtFromApi(a.recordedAtRaw);
      final db = parseClassSessionRecordedAtFromApi(b.recordedAtRaw);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
  }
  final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  final out = keys.map((k) => MapEntry(k, map[k]!)).toList();
  if (unparsed.isNotEmpty) {
    out.add(MapEntry(DateTime(1970), unparsed));
  }
  return out;
}

class TeacherClassSessionsPanel extends ConsumerStatefulWidget {
  const TeacherClassSessionsPanel({
    super.key,
    required this.studentId,
    this.groupView,
  });

  final int studentId;

  /// When set, shows read-only sessions for one group class.
  final StudentGroupClassSessionsView? groupView;

  @override
  ConsumerState<TeacherClassSessionsPanel> createState() =>
      _TeacherClassSessionsPanelState();
}

class _TeacherClassSessionsPanelState
    extends ConsumerState<TeacherClassSessionsPanel> {
  var _addingLegacy = false;
  int? _addingForTermId;
  var _addingTerm = false;
  final Set<int> _busyIds = {};
  final Set<int> _busyTermIds = {};

  Future<void> _invalidate() async {
    ref.invalidate(teacherStudentSessionsProvider(widget.studentId));
    ref.invalidate(teacherStudentPricingProvider(widget.studentId));
    ref.invalidate(teacherStudentsProvider);
    ref.invalidate(teacherWeekUpcomingProvider);
    const filters = [
      TeacherFinancialFilters(),
      TeacherFinancialFilters(period: TeacherFinancePeriod.week),
      TeacherFinancialFilters(period: TeacherFinancePeriod.month),
    ];
    for (final f in filters) {
      ref.invalidate(teacherFinancialSummaryProvider(f));
    }
  }

  Future<void> _addLegacy(AppLocalizations l10n) async {
    setState(() => _addingLegacy = true);
    try {
      await ref
          .read(apiServiceProvider)
          .addTeacherClassSession(studentId: widget.studentId);
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teacherClassSessionAdded)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _addingLegacy = false);
    }
  }

  Future<void> _addSessionForTerm(int termId, AppLocalizations l10n) async {
    setState(() => _addingForTermId = termId);
    try {
      final info = await ref.read(apiServiceProvider).addTeacherClassSession(
            studentId: widget.studentId,
            termId: termId,
          );
      await _invalidate();
      if (!mounted) return;
      if (info.financialNotice == 'term_marked_unpaid') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherFinanceTermMarkedUnpaid)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.teacherClassSessionAdded)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _addingForTermId = null);
    }
  }

  Future<void> _showAddTermDialog(AppLocalizations l10n) async {
    final info = ref
        .read(teacherStudentSessionsProvider(widget.studentId))
        .valueOrNull
        ?.personal;
    final defaultFee = info?.effectiveDefaultTermFee ?? 0;
    final capController = TextEditingController(text: '12');
    final feeController = TextEditingController(
      text: defaultFee > 0 ? '${defaultFee.round()}' : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.teacherClassTermsAddButton),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: capController,
                decoration: InputDecoration(
                  labelText: l10n.teacherClassTermCapFieldLabel,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feeController,
                decoration: InputDecoration(
                  labelText: l10n.teacherSessionPriceFieldLabel,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.teacherSessionSave),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final cap = int.tryParse(capController.text.trim()) ?? 0;
    if (cap < 1 || cap > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherSessionInvalid)),
      );
      return;
    }
    final feeText = feeController.text.trim();
    double? termFee;
    if (feeText.isNotEmpty) {
      termFee = double.tryParse(feeText);
      if (termFee == null || termFee < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherSessionInvalid)),
        );
        return;
      }
    }
    setState(() => _addingTerm = true);
    try {
      await ref.read(apiServiceProvider).addTeacherStudentTerm(
            studentId: widget.studentId,
            sessionCap: cap,
            termFee: termFee,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teacherClassTermAdded)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _addingTerm = false);
    }
  }

  Future<void> _editTermCap(ClassSessionTerm term, AppLocalizations l10n) async {
    final controller = TextEditingController(text: '${term.sessionCap}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.teacherClassTermEditCapTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.teacherClassTermCapFieldLabel,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.teacherSessionSave),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    final cap = int.tryParse(controller.text.trim()) ?? 0;
    if (cap < 1 || cap > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherSessionInvalid)),
      );
      return;
    }
    setState(() => _busyTermIds.add(term.id));
    try {
      await ref.read(apiServiceProvider).updateTeacherStudentTerm(
            studentId: widget.studentId,
            termId: term.id,
            sessionCap: cap,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teacherClassTermUpdated)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busyTermIds.remove(term.id));
    }
  }

  Future<void> _toggleTermPayment(
    ClassSessionTerm term,
    AppLocalizations l10n,
  ) async {
    if (_busyTermIds.contains(term.id)) return;
    setState(() => _busyTermIds.add(term.id));
    try {
      await ref.read(apiServiceProvider).setTeacherTermPayment(
            studentId: widget.studentId,
            termId: term.id,
            isPaid: !term.isPaid,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classTermPaymentUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busyTermIds.remove(term.id));
    }
  }

  Future<void> _editTermFee(
    ClassSessionTerm term,
    TeacherSessionInfo info,
    AppLocalizations l10n,
  ) async {
    final initial = term.effectiveTermFee > 0
        ? '${term.effectiveTermFee.round()}'
        : (info.effectiveDefaultTermFee > 0
            ? '${info.effectiveDefaultTermFee.round()}'
            : '');
    final controller = TextEditingController(text: initial);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final pad = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + pad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.teacherTermFeeEdit,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.teacherSessionPriceFieldLabel,
                  suffixText: FinancialFormat.currencyLabel(
                    info.currencyCode,
                    l10n,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.teacherSessionSave),
              ),
            ],
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    final fee = double.tryParse(controller.text.trim());
    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherSessionInvalid)),
      );
      return;
    }
    setState(() => _busyTermIds.add(term.id));
    try {
      await ref.read(apiServiceProvider).updateTeacherStudentTermFee(
            studentId: widget.studentId,
            termId: term.id,
            termFee: fee,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.teacherTermFeeUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busyTermIds.remove(term.id));
    }
  }

  Future<void> _deleteTerm(ClassSessionTerm term, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.teacherClassTermDeleteConfirmTitle),
          content: Text(l10n.teacherClassTermDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: s.error,
                foregroundColor: s.onError,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.teacherClassSessionDelete),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busyTermIds.add(term.id));
    try {
      await ref.read(apiServiceProvider).deleteTeacherStudentTerm(
            studentId: widget.studentId,
            termId: term.id,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teacherClassTermDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _busyTermIds.remove(term.id));
    }
  }

  Future<void> _delete(ClassSessionEntry entry, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.teacherClassSessionDeleteConfirmTitle),
          content: Text(l10n.teacherClassSessionDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: s.error,
                foregroundColor: s.onError,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.teacherClassSessionDelete),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busyIds.add(entry.id));
    try {
      await ref
          .read(apiServiceProvider)
          .deleteTeacherClassSession(
            studentId: widget.studentId,
            sessionId: entry.id,
          );
      await _invalidate();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.teacherClassSessionDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(entry.id));
      }
    }
  }

  Future<void> _edit(
    ClassSessionEntry entry,
    AppLocalizations l10n,
    int displayIndex,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _EditSessionSheet(
        studentId: widget.studentId,
        entry: entry,
        displayIndex: displayIndex,
        onDone: () async {
          await _invalidate();
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.teacherSessionUpdated)));
        },
      ),
    );
  }

  List<Widget> _legacySessionList({
    required List<ClassSessionEntry> sessions,
    required ColorScheme scheme,
    required TextTheme tt,
    required AppLocalizations l10n,
    required String loc,
    bool readOnly = false,
  }) {
    final sortedForIndex = List<ClassSessionEntry>.from(sessions);
    sortedForIndex.sort((a, b) {
      final da = parseClassSessionRecordedAtFromApi(a.recordedAtRaw);
      final db = parseClassSessionRecordedAtFromApi(b.recordedAtRaw);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    final displayIndexFor = <int, int>{};
    for (var i = 0; i < sortedForIndex.length; i++) {
      final e = sortedForIndex[i];
      displayIndexFor[e.id] = e.index > 0 ? e.index : i + 1;
    }
    final grouped = _groupByDay(sessions);
    final dayFmt = DateFormat.yMMMMEEEEd(loc);
    final timeFmt = DateFormat.jm(loc);
    final out = <Widget>[const SizedBox(height: 20)];
    for (final g in grouped) {
      if (g.key.year != 1970) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              dayFmt.format(g.key),
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      } else {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              '—',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      for (final e in g.value) {
        final dt = parseClassSessionRecordedAtFromApi(e.recordedAtRaw);
        final idx = displayIndexFor[e.id] ?? 1;
        final busy = _busyIds.contains(e.id);
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SessionTile(
              displayIndex: idx,
              timeLabel: dt != null
                  ? (g.key.year == 1970
                        ? DateFormat.yMMMd(loc).add_Hm().format(dt)
                        : timeFmt.format(dt))
                  : e.recordedAtRaw,
              scheme: scheme,
              tt: tt,
              l10n: l10n,
              busy: busy,
              onEdit: readOnly || busy ? null : () => _edit(e, l10n, idx),
              onDelete: readOnly || busy ? null : () => _delete(e, l10n),
            ),
          ),
        );
      }
      out.add(const SizedBox(height: 8));
    }
    return out;
  }

  List<Widget> _termsSessionList({
    required List<ClassSessionEntry> termSessions,
    required ColorScheme scheme,
    required TextTheme tt,
    required AppLocalizations l10n,
    required String loc,
    bool readOnly = false,
  }) {
    if (termSessions.isEmpty) {
      return [];
    }
    final grouped = _groupByDay(termSessions);
    final dayFmt = DateFormat.yMMMMEEEEd(loc);
    final timeFmt = DateFormat.jm(loc);
    final out = <Widget>[];
    for (final g in grouped) {
      if (g.key.year != 1970) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 2),
            child: Text(
              dayFmt.format(g.key),
              style: tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      for (final e in g.value) {
        final dt = parseClassSessionRecordedAtFromApi(e.recordedAtRaw);
        final idx = classSessionChronologicalIndexInTerm(e, termSessions);
        final busy = _busyIds.contains(e.id);
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SessionTile(
              displayIndex: idx,
              timeLabel: dt != null
                  ? (g.key.year == 1970
                        ? DateFormat.yMMMd(loc).add_Hm().format(dt)
                        : timeFmt.format(dt))
                  : e.recordedAtRaw,
              scheme: scheme,
              tt: tt,
              l10n: l10n,
              busy: busy,
              onEdit: readOnly || busy ? null : () => _edit(e, l10n, idx),
              onDelete: readOnly || busy ? null : () => _delete(e, l10n),
            ),
          ),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context).toString();
    final async = ref.watch(teacherStudentSessionsProvider(widget.studentId));

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
      data: (split) {
        final readOnly = widget.groupView != null;
        final info = widget.groupView?.sessionInfo ?? split.personal;
        final sessions = info.sessions;
        final useTermsUi = info.usesTermsTable;
        final terms = info.terms;

        final headerSubtitle = readOnly
            ? l10n.teacherGroupClassSessionsTeacherHint
            : useTermsUi
                ? l10n.teacherClassSessionsTabSubtitleTerms
                : l10n.teacherClassSessionsTabSubtitle;
        final headerTitle =
            widget.groupView?.name ?? l10n.teacherClassSessions;

        final children = <Widget>[
          if (!readOnly && !info.pricingAvailable) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                l10n.teacherFinancePricingSetupBody,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onErrorContainer,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (!readOnly && info.financialSummary != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniFinanceChip(
                    label: l10n.teacherTotalReceived,
                    value: FinancialFormat.formatAmount(
                      info.financialSummary!.totalReceived,
                      info.currencyCode,
                      loc,
                      l10n,
                    ),
                    fg: FinancialColors.receivedFg,
                    bg: FinancialColors.receivedBg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniFinanceChip(
                    label: l10n.teacherTotalUnpaid,
                    value: FinancialFormat.formatAmount(
                      info.financialSummary!.totalUnpaid,
                      info.currencyCode,
                      loc,
                      l10n,
                    ),
                    fg: FinancialColors.unpaidFg,
                    bg: FinancialColors.unpaidBg,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: appJellyCardDecoration(context, scheme: scheme),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppJellyIconBubble(
                        color: scheme.primary,
                        child: Icon(
                          Icons.school_outlined,
                          color: scheme.onPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          headerTitle,
                          style: tt.titleMedium,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            '${sessions.length}',
                            style: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    headerSubtitle,
                    style: tt.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if (!readOnly && !useTermsUi) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _addingLegacy
                          ? null
                          : () => _addLegacy(l10n),
                      icon: _addingLegacy
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.primary,
                              ),
                            )
                          : const Icon(Icons.add_rounded),
                      label: Text(l10n.teacherClassSessionsAddButton),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ];

        if (useTermsUi) {
          children.add(const SizedBox(height: 18));
          if (!readOnly) {
            children.add(
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.teacherClassTermsSection,
                      style:
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed:
                        _addingTerm ? null : () => _showAddTermDialog(l10n),
                    icon: _addingTerm
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          )
                        : const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.teacherClassTermsAddButton),
                  ),
                ],
              ),
            );
          } else {
            children.add(
              Text(
                l10n.teacherClassTermsSection,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            );
          }

          if (!readOnly && terms.isEmpty) {
            children.addAll([
              const SizedBox(height: 16),
              Text(
                l10n.teacherClassTermsEmptyHint,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ]);
          }

          for (final term in terms) {
            final termSessions =
                sessions.where((s) => s.termId == term.id).toList();
            if (readOnly && termSessions.isEmpty) {
              continue;
            }
            final termBusy = _busyTermIds.contains(term.id);
            final addingHere = _addingForTermId == term.id;
            children.add(const SizedBox(height: 14));
            children.add(
              Container(
                width: double.infinity,
                decoration: appJellyCardDecoration(context, scheme: scheme),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    TermTitleCard(
                                      title: l10n.teacherClassTermTitle(
                                        term.sortOrder,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TermPaymentStatusChip(
                                      isPaid: term.isPaid,
                                      l10n: l10n,
                                      onTap: readOnly || termBusy
                                          ? null
                                          : () => _toggleTermPayment(
                                                term,
                                                l10n,
                                              ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                    Builder(
                                  builder: (context) {
                                    final termAmount = term.effectiveTermFee;
                                    final showAmount = termAmount > 0;
                                    final amountText = FinancialFormat.formatAmount(
                                      term.isPaid
                                          ? (term.termReceived ?? termAmount)
                                          : (term.termUnpaid ?? termAmount),
                                      info.currencyCode,
                                      loc,
                                      l10n,
                                    );
                                    return Text(
                                      showAmount
                                          ? l10n.teacherTermSessionsAndAmount(
                                              l10n.teacherClassTermSessionsProgress(
                                                term.sessionCount,
                                                term.sessionCap,
                                              ),
                                              amountText,
                                            )
                                          : l10n.teacherClassTermSessionsProgress(
                                              term.sessionCount,
                                              term.sessionCap,
                                            ),
                                      style: tt.bodySmall?.copyWith(
                                        color: term.isPaid
                                            ? FinancialColors.receivedFg
                                            : showAmount && !term.isPaid
                                                ? FinancialColors.unpaidFg
                                                : scheme.onSurfaceVariant,
                                        fontWeight:
                                            showAmount ? FontWeight.w700 : FontWeight.normal,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (!readOnly) ...[
                            IconButton(
                              tooltip: l10n.teacherTermFeeEdit,
                              onPressed: termBusy
                                  ? null
                                  : () => _editTermFee(term, info, l10n),
                              icon: Icon(
                                Icons.payments_outlined,
                                color: scheme.primary,
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.teacherClassSessionEdit,
                              onPressed: termBusy
                                  ? null
                                  : () => _editTermCap(term, l10n),
                              icon: Icon(
                                Icons.edit_outlined,
                                color: scheme.primary,
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.teacherClassSessionDelete,
                              onPressed: termBusy
                                  ? null
                                  : () => _deleteTerm(term, l10n),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: scheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                      ..._termsSessionList(
                        termSessions: termSessions,
                        scheme: scheme,
                        tt: tt,
                        l10n: l10n,
                        loc: loc,
                        readOnly: readOnly,
                      ),
                      if (!readOnly) ...[
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: (term.isFull || addingHere)
                              ? null
                              : () => _addSessionForTerm(term.id, l10n),
                          icon: addingHere
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                )
                              : const Icon(Icons.add_rounded, size: 20),
                          label: Text(l10n.teacherClassTermAddSessionButton),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }
        } else if (sessions.isEmpty) {
          children.addAll([
            const SizedBox(height: 32),
            Icon(
              Icons.event_busy_rounded,
              size: 56,
              color: scheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.youClassSessionsEmpty,
              textAlign: TextAlign.center,
              style: tt.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.teacherClassSessionsHintEmpty,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ]);
        } else {
          children.addAll(
            _legacySessionList(
              sessions: sessions,
              scheme: scheme,
              tt: tt,
              l10n: l10n,
              loc: loc,
              readOnly: readOnly,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: children,
        );
      },
    );
  }
}

/// Tabs for personal vs group class sessions on the teacher student detail screen.
class TeacherStudentClassSessionsTab extends ConsumerStatefulWidget {
  const TeacherStudentClassSessionsTab({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<TeacherStudentClassSessionsTab> createState() =>
      _TeacherStudentClassSessionsTabState();
}

class _TeacherStudentClassSessionsTabState
    extends ConsumerState<TeacherStudentClassSessionsTab>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _syncTabController(int length) {
    if (_tabController != null && _tabController!.length == length) {
      return;
    }
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(teacherStudentSessionsProvider(widget.studentId));

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
      data: (split) {
        if (split.classGroups.isEmpty) {
          return TeacherClassSessionsPanel(studentId: widget.studentId);
        }

        final tabCount = 1 + split.classGroups.length;
        _syncTabController(tabCount);
        final controller = _tabController!;

        final tabs = <Widget>[
          Tab(text: l10n.studentPersonalClassTab),
          ...split.classGroups.map((g) => Tab(text: g.name)),
        ];

        final views = <Widget>[
          TeacherClassSessionsPanel(studentId: widget.studentId),
          ...split.classGroups.map(
            (g) => TeacherClassSessionsPanel(
              studentId: widget.studentId,
              groupView: g,
            ),
          ),
        ];

        return Column(
          children: [
            Material(
              color: scheme.surface,
              child: TabBar(
                controller: controller,
                isScrollable: true,
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                indicatorColor: scheme.primary,
                tabs: tabs,
              ),
            ),
            Expanded(
              child: TabBarView(controller: controller, children: views),
            ),
          ],
        );
      },
    );
  }
}

class _MiniFinanceChip extends StatelessWidget {
  const _MiniFinanceChip({
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
  });

  final String label;
  final String value;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.displayIndex,
    required this.timeLabel,
    required this.scheme,
    required this.tt,
    required this.l10n,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final int displayIndex;
  final String timeLabel;
  final ColorScheme scheme;
  final TextTheme tt;
  final AppLocalizations l10n;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(kAppJellyRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: appJellyCardDecoration(context, scheme: scheme),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppJellyIconBubble(
                color: scheme.primary,
                size: 44,
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(
                        '$displayIndex',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: scheme.onPrimary,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.teacherClassSessionHeading(displayIndex),
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            timeLabel,
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppJellyIconBubble(
                color: scheme.primary,
                size: 32,
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: scheme.onPrimary,
                ),
              ),
              IconButton(
                tooltip: l10n.teacherClassSessionEdit,
                onPressed: busy ? null : onEdit,
                icon: Icon(Icons.edit_outlined, color: scheme.primary),
              ),
              IconButton(
                tooltip: l10n.teacherClassSessionDelete,
                onPressed: busy ? null : onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditSessionSheet extends ConsumerStatefulWidget {
  const _EditSessionSheet({
    required this.studentId,
    required this.entry,
    required this.displayIndex,
    required this.onDone,
  });

  final int studentId;
  final ClassSessionEntry entry;
  final int displayIndex;
  final Future<void> Function() onDone;

  @override
  ConsumerState<_EditSessionSheet> createState() => _EditSessionSheetState();
}

class _EditSessionSheetState extends ConsumerState<_EditSessionSheet> {
  late DateTime _selected;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _selected =
        parseClassSessionRecordedAtFromApi(widget.entry.recordedAtRaw) ??
            DateTime.now();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        d.year,
        d.month,
        d.day,
        _selected.hour,
        _selected.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
    );
    if (t == null || !mounted) return;
    setState(() {
      _selected = DateTime(
        _selected.year,
        _selected.month,
        _selected.day,
        t.hour,
        t.minute,
      );
    });
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(apiServiceProvider)
          .updateTeacherClassSessionTime(
            studentId: widget.studentId,
            sessionId: widget.entry.id,
            recordedAt: _selected,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onDone();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyErrorMessage(e, l10n))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final loc = Localizations.localeOf(context).toString();
    final pad = MediaQuery.paddingOf(context).bottom;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: pad + inset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teacherClassSessionEditTitle,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teacherClassSessionHeading(widget.displayIndex),
              style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.calendar_month_rounded,
                color: scheme.primary,
              ),
              title: Text(l10n.teacherClassSessionDateFieldLabel),
              subtitle: Text(DateFormat.yMMMMEEEEd(loc).format(_selected)),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onTap: _saving ? null : _pickDate,
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule_rounded, color: scheme.primary),
              title: Text(l10n.teacherClassSessionTimeFieldLabel),
              subtitle: Text(DateFormat.jm(loc).format(_selected)),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              onTap: _saving ? null : _pickTime,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : () => _save(l10n),
              child: _saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onInverseSurface,
                      ),
                    )
                  : Text(l10n.teacherSessionSave),
            ),
          ],
        ),
      ),
    );
  }
}
