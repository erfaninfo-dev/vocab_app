import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/user_friendly_error.dart';
import '../../core/financial/financial_format.dart';
import '../../core/profile/profile_avatar.dart';
import '../../data/models/teacher_student.dart';
import '../../domain/api_full_refresh.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import 'teacher_chat_ui.dart';

class TeacherFinanceTab extends ConsumerStatefulWidget {
  const TeacherFinanceTab({
    super.key,
    required this.l10n,
    required this.scheme,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;

  @override
  ConsumerState<TeacherFinanceTab> createState() => _TeacherFinanceTabState();
}

class _TeacherFinanceTabState extends ConsumerState<TeacherFinanceTab> {
  TeacherFinancePeriod _period = TeacherFinancePeriod.lifetime;
  TeacherFinancePaymentFilter _paymentFilter = TeacherFinancePaymentFilter.all;
  DateTime? _customFrom;
  DateTime? _customTo;

  TeacherFinancialFilters get _filters => TeacherFinancialFilters(
        period: _period,
        from: _customFrom,
        to: _customTo,
        paymentStatus: _paymentFilter,
      );

  Future<void> _refresh() async {
    await refreshAllRemoteApiData(ref);
    ref.invalidate(teacherFinancialSummaryProvider(_filters));
    await ref.read(teacherFinancialSummaryProvider(_filters).future);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final from = await showDatePicker(
      context: context,
      initialDate: _customFrom ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: widget.l10n.teacherFinanceFromDate,
    );
    if (!mounted || from == null) return;
    final to = await showDatePicker(
      context: context,
      initialDate: _customTo ?? now,
      firstDate: from,
      lastDate: now,
      helpText: widget.l10n.teacherFinanceToDate,
    );
    if (!mounted || to == null) return;
    setState(() {
      _period = TeacherFinancePeriod.custom;
      _customFrom = from;
      _customTo = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toString();
    final async = ref.watch(teacherFinancialSummaryProvider(_filters));

    return DecoratedBox(
      decoration: TeacherChatUi.teacherPanelBackground(widget.scheme),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: async.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _FilterSection(
                l10n: widget.l10n,
                scheme: widget.scheme,
                period: _period,
                paymentFilter: _paymentFilter,
                onPeriodChanged: (p) => setState(() => _period = p),
                onPaymentChanged: (f) => setState(() => _paymentFilter = f),
                onCustomRange: _pickCustomRange,
              ),
              const SizedBox(height: 16),
              const _FinanceHeroSkeleton(),
            ],
          ),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              _FilterSection(
                l10n: widget.l10n,
                scheme: widget.scheme,
                period: _period,
                paymentFilter: _paymentFilter,
                onPeriodChanged: (p) => setState(() => _period = p),
                onPaymentChanged: (f) => setState(() => _paymentFilter = f),
                onCustomRange: _pickCustomRange,
              ),
              const SizedBox(height: 24),
              Text(
                userFriendlyErrorMessage(err, widget.l10n),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: _refresh,
                  child: Text(widget.l10n.retry),
                ),
              ),
            ],
          ),
          data: (report) {
            if (!report.pricingAvailable) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 64,
                    color: widget.scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.l10n.teacherFinancePricingSetupTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.l10n.teacherFinancePricingSetupBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                ],
              );
            }

            final currency = report.currencyCode;
            final receivedText = FinancialFormat.formatAmount(
              report.totals.received,
              currency,
              localeName,
              widget.l10n,
            );
            final unpaidText = FinancialFormat.formatAmount(
              report.totals.unpaid,
              currency,
              localeName,
              widget.l10n,
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _FilterSection(
                  l10n: widget.l10n,
                  scheme: widget.scheme,
                  period: _period,
                  paymentFilter: _paymentFilter,
                  onPeriodChanged: (p) => setState(() => _period = p),
                  onPaymentChanged: (f) => setState(() => _paymentFilter = f),
                  onCustomRange: _pickCustomRange,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HeroAmountCard(
                        title: widget.l10n.teacherTotalReceived,
                        amount: receivedText,
                        icon: Icons.trending_up_rounded,
                        fg: FinancialColors.receivedFg,
                        bg: FinancialColors.receivedBg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroAmountCard(
                        title: widget.l10n.teacherTotalUnpaid,
                        amount: unpaidText,
                        icon: Icons.warning_amber_rounded,
                        fg: FinancialColors.unpaidFg,
                        bg: FinancialColors.unpaidBg,
                      ),
                    ),
                  ],
                ),
                if (report.periodLabel.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    report.periodLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: widget.scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  widget.l10n.teacherFinanceBreakdownStudents,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                if (report.byStudent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      widget.l10n.teacherFinanceEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: widget.scheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ...report.byStudent.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudentFinanceCard(
                        row: row,
                        currencyCode: currency,
                        l10n: widget.l10n,
                        scheme: widget.scheme,
                        localeName: localeName,
                        onTap: () => context.push('/teacher/student/${row.studentId}'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.l10n,
    required this.scheme,
    required this.period,
    required this.paymentFilter,
    required this.onPeriodChanged,
    required this.onPaymentChanged,
    required this.onCustomRange,
  });

  final AppLocalizations l10n;
  final ColorScheme scheme;
  final TeacherFinancePeriod period;
  final TeacherFinancePaymentFilter paymentFilter;
  final ValueChanged<TeacherFinancePeriod> onPeriodChanged;
  final ValueChanged<TeacherFinancePaymentFilter> onPaymentChanged;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CompactFilterPill(
                label: l10n.teacherFinancePeriodToday,
                selected: period == TeacherFinancePeriod.today,
                scheme: scheme,
                onTap: () => onPeriodChanged(TeacherFinancePeriod.today),
              ),
              _CompactFilterPill(
                label: l10n.teacherFinancePeriodWeek,
                selected: period == TeacherFinancePeriod.week,
                scheme: scheme,
                onTap: () => onPeriodChanged(TeacherFinancePeriod.week),
              ),
              _CompactFilterPill(
                label: l10n.teacherFinancePeriodMonth,
                selected: period == TeacherFinancePeriod.month,
                scheme: scheme,
                onTap: () => onPeriodChanged(TeacherFinancePeriod.month),
              ),
              _CompactFilterPill(
                label: l10n.teacherFinancePeriodAll,
                selected: period == TeacherFinancePeriod.lifetime,
                scheme: scheme,
                onTap: () => onPeriodChanged(TeacherFinancePeriod.lifetime),
              ),
              _CompactFilterPill(
                label: l10n.teacherFinancePeriodCustom,
                selected: period == TeacherFinancePeriod.custom,
                scheme: scheme,
                icon: Icons.calendar_today_rounded,
                onTap: onCustomRange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<TeacherFinancePaymentFilter>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: TeacherFinancePaymentFilter.all,
                label: Text(
                  l10n.teacherFinanceFilterAll,
                  style: tt.labelSmall,
                ),
              ),
              ButtonSegment(
                value: TeacherFinancePaymentFilter.paid,
                label: Text(
                  l10n.teacherFinanceFilterPaid,
                  style: tt.labelSmall,
                ),
              ),
              ButtonSegment(
                value: TeacherFinancePaymentFilter.unpaid,
                label: Text(
                  l10n.teacherFinanceFilterUnpaid,
                  style: tt.labelSmall,
                ),
              ),
            ],
            selected: {paymentFilter},
            onSelectionChanged: (next) => onPaymentChanged(next.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFilterPill extends StatelessWidget {
  const _CompactFilterPill({
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final bg = selected ? scheme.primaryContainer : scheme.surfaceContainerHighest;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAmountCard extends StatelessWidget {
  const _HeroAmountCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.fg,
    required this.bg,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withValues(alpha: 0.55)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
          ),
        ],
      ),
    );
  }
}

class _StudentFinanceCard extends StatelessWidget {
  const _StudentFinanceCard({
    required this.row,
    required this.currencyCode,
    required this.l10n,
    required this.scheme,
    required this.localeName,
    required this.onTap,
  });

  final StudentFinancialRow row;
  final String currencyCode;
  final AppLocalizations l10n;
  final ColorScheme scheme;
  final String localeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final received = FinancialFormat.formatAmount(
      row.received,
      currencyCode,
      localeName,
      l10n,
    );
    final unpaid = FinancialFormat.formatAmount(
      row.unpaid,
      currencyCode,
      localeName,
      l10n,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ProfileAvatar(
                avatarId: row.avatar,
                userId: row.studentId,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      received,
                      style: const TextStyle(
                        color: FinancialColors.receivedFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (row.unpaid > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        unpaid,
                        style: const TextStyle(
                          color: FinancialColors.unpaidFg,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (row.unpaid > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FinancialColors.unpaidBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: FinancialColors.unpaidFg.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    l10n.teacherFinanceStudentUnpaidBadge,
                    style: const TextStyle(
                      color: FinancialColors.unpaidFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceHeroSkeleton extends StatelessWidget {
  const _FinanceHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Row(
      children: [
        Expanded(child: _box(base)),
        const SizedBox(width: 12),
        Expanded(child: _box(base)),
      ],
    );
  }

  Widget _box(Color base) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
