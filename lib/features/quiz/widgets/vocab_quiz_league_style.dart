import 'package:flutter/material.dart';

/// Matches [LeagueType.vocab] in `league_screen.dart`.
const Color kVocabLeagueAccent = Color(0xFF00A86B);
const Color kVocabLeagueDark = Color(0xFF007A5A);

const LinearGradient kVocabLeagueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF00D084), kVocabLeagueAccent, kVocabLeagueDark],
);

/// Matches [LeagueType.grammar] in `league_screen.dart`.
const Color kGrammarLeagueAccent = Color(0xFF3461FF);

const LinearGradient kGrammarLeagueGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF00C6FF), kGrammarLeagueAccent, Color(0xFF6A5CFF)],
);

ButtonStyle vocabLeagueFilledButtonStyle({EdgeInsetsGeometry? padding}) {
  return FilledButton.styleFrom(
    backgroundColor: kVocabLeagueAccent,
    foregroundColor: Colors.white,
    padding: padding,
  );
}

/// Live points chip in quiz app bars — colors align with the matching league tab.
class QuizLeaguePointsChip extends StatelessWidget {
  const QuizLeaguePointsChip.vocab({super.key, required this.points})
    : gradient = kVocabLeagueGradient,
      shadowColor = kVocabLeagueAccent;

  const QuizLeaguePointsChip.grammar({super.key, required this.points})
    : gradient = kGrammarLeagueGradient,
      shadowColor = kGrammarLeagueAccent;

  final int points;
  final LinearGradient gradient;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 17),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              '$points pts',
              key: ValueKey(points),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
