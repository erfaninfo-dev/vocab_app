import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/student/student_code_input.dart';
import '../../data/services/api_service.dart';
import '../../domain/api_providers.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_displayed_books_provider.dart';

Future<void> showRedeemStudentCodeDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final submitted = await showDialog<String>(
    context: context,
    builder: (ctx) => const _RedeemStudentCodeDialog(),
  );
  if (submitted == null || !isValidStudentCode(submitted)) {
    if (context.mounted && submitted != null && submitted.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentCodeFiveDigitsInvalid)),
      );
    }
    return;
  }
  try {
    await ref.read(authProvider.notifier).redeemStudentCode(submitted);
    ref.invalidate(apiPublicBooksForHomeProvider);
    ref.invalidate(apiStudentBooksForHomeProvider);
    ref.invalidate(teacherMessagesPreviewProvider);
    ref.invalidate(teacherMessagesUnreadFabProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentAccessGranted)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidStudentCode)),
      );
    }
  }
}

Future<void> showCreateTeacherStudentCodeDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final session = ref.read(authProvider).valueOrNull;
  if (session == null) return;

  List<String> unused = const [];
  try {
    unused = await ApiService(authToken: session.token)
        .fetchTeacherUnusedStudentCodes();
  } catch (_) {}

  if (!context.mounted) return;

  final registered = await showDialog<String>(
    context: context,
    builder: (ctx) => _CreateTeacherStudentCodeDialog(unusedCodes: unused),
  );

  if (registered != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.teacherStudentCodeRegistered(registered))),
    );
  }
}

class _RedeemStudentCodeDialog extends StatefulWidget {
  const _RedeemStudentCodeDialog();

  @override
  State<_RedeemStudentCodeDialog> createState() => _RedeemStudentCodeDialogState();
}

class _RedeemStudentCodeDialogState extends State<_RedeemStudentCodeDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.redeemStudentCode),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: studentCodeInputFormatters,
        decoration: InputDecoration(
          labelText: l10n.studentCodeLabel,
          hintText: l10n.studentCodeFiveDigitsHint,
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final t = _ctrl.text.trim();
            if (!isValidStudentCode(t)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.studentCodeFiveDigitsInvalid)),
              );
              return;
            }
            Navigator.of(context).pop(t);
          },
          child: Text(l10n.continueLabel),
        ),
      ],
    );
  }
}

class _CreateTeacherStudentCodeDialog extends ConsumerStatefulWidget {
  const _CreateTeacherStudentCodeDialog({required this.unusedCodes});

  final List<String> unusedCodes;

  @override
  ConsumerState<_CreateTeacherStudentCodeDialog> createState() =>
      _CreateTeacherStudentCodeDialogState();
}

class _CreateTeacherStudentCodeDialogState
    extends ConsumerState<_CreateTeacherStudentCodeDialog> {
  late final TextEditingController _ctrl;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final t = _ctrl.text.trim();
    if (!isValidStudentCode(t)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentCodeFiveDigitsInvalid)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final registered =
          await ref.read(authProvider.notifier).createTeacherStudentCode(t);
      if (!mounted) return;
      Navigator.of(context).pop(registered);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.teacherStudentCodeRegisterFailed)),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unused = widget.unusedCodes;

    return AlertDialog(
      title: Text(l10n.createStudentCode),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: studentCodeInputFormatters,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: l10n.studentCodeLabel,
                hintText: l10n.studentCodeFiveDigitsHint,
                counterText: '',
              ),
            ),
            if (unused.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.teacherUnusedCodesTitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unused
                    .take(12)
                    .map(
                      (c) => Chip(
                        label: Text(c),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.continueLabel),
        ),
      ],
    );
  }
}
