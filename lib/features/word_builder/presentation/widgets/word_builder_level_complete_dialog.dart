import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';

enum WordBuilderLevelCompleteAction { next, exit }

class WordBuilderLevelCompleteDialog {
  WordBuilderLevelCompleteDialog._();

  static Future<WordBuilderLevelCompleteAction?> show(BuildContext context) {
    return showGeneralDialog<WordBuilderLevelCompleteAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.48),
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
              child: const _LevelCompleteDialogBody(),
            ),
          ),
        );
      },
    );
  }
}

class _LevelCompleteDialogBody extends StatelessWidget {
  const _LevelCompleteDialogBody();

  static const Color _titleColor = Color(0xFF4E342E);
  static const Color _border = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = GoogleFonts.fredokaTextTheme(Theme.of(context).textTheme);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFDE7), Color(0xFFFFECB3), Color(0xFFFFD54F)],
            ),
            border: Border.all(color: _border, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.38),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              Text(
                l10n.wordBuilderLevelCompleteTitle,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: _titleColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.wordBuilderLevelCompleteBody,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6D4C41),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(WordBuilderLevelCompleteAction.next),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                  label: Text(
                    l10n.wordBuilderNextLevel,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: _titleColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(WordBuilderLevelCompleteAction.exit),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    l10n.exit,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D4C41),
                    side: BorderSide(
                      color: const Color(0xFF8D6E63).withValues(alpha: 0.72),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
