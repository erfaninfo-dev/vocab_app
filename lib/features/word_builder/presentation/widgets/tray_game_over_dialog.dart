import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/word_builder_game_notifier.dart';
import '../../domain/tray_scenario_kind.dart';

/// Game-over modal — only [try again] and [exit].
class TrayGameOverDialog {
  TrayGameOverDialog._();

  static Future<void> show(
    BuildContext context, {
    required int bookKey,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return PopScope(
          canPop: false,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: _TrayGameOverDialogBody(bookKey: bookKey),
            ),
          ),
        );
      },
    );
  }
}

class _TrayGameOverDialogBody extends ConsumerWidget {
  const _TrayGameOverDialogBody({required this.bookKey});

  final int bookKey;

  static const Color _titleColor = Color(0xFF4E342E);
  static const Color _border = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scenario = ref.watch(
      wordBuilderGameProvider(bookKey).select(
        (async) =>
            async.valueOrNull?.trayScenario ?? TrayScenarioKind.water,
      ),
    );
    final (icon, iconColor, title, body) = switch (scenario) {
      TrayScenarioKind.water => (
        Icons.water_drop_rounded,
        const Color(0xFF4FC3F7).withValues(alpha: 0.9),
        null,
        null,
      ),
      TrayScenarioKind.train => (
        Icons.train_rounded,
        const Color(0xFFE65100).withValues(alpha: 0.92),
        l10n.wordBuilderTrainGameOverTitle,
        l10n.wordBuilderTrainGameOverBody,
      ),
      TrayScenarioKind.prison => (
        Icons.lock_rounded,
        const Color(0xFF8D6E63).withValues(alpha: 0.95),
        l10n.wordBuilderPrisonGameOverTitle,
        l10n.wordBuilderPrisonGameOverBody,
      ),
    };

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
            border: Border.all(color: _border, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: iconColor),
              if (title != null && body != null) ...[
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _titleColor.withValues(alpha: 0.85),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(
                      ref
                          .read(wordBuilderGameProvider(bookKey).notifier)
                          .resetTrayAfterGameOver(),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: Text(
                    l10n.tryAgain,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: _titleColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (context.mounted) context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D4C41),
                    side: BorderSide(
                      color: const Color(0xFF8D6E63).withValues(alpha: 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.exit,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
