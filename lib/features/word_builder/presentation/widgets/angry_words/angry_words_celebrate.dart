import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Progressive slot reveal while letters fly into AnswerSlots (Angry Words).
@immutable
class AngryWordsSlotReveal {
  const AngryWordsSlotReveal({
    required this.wordNorm,
    required this.revealedCount,
  });

  final String wordNorm;
  final int revealedCount;
}

final angryWordsSlotRevealProvider =
    StateProvider<AngryWordsSlotReveal?>((ref) => null);

/// One letter flying from board → answer slot (global coordinates).
class AngryWordsFlightLetter {
  AngryWordsFlightLetter({
    required this.char,
    required this.startGlobal,
    required this.endGlobal,
    required this.tint,
    required this.delay,
  });

  final String char;
  final Offset startGlobal;
  final Offset endGlobal;
  final Color tint;
  double delay;
  double t = 0;
  bool settled = false;

  Offset get position {
    final u = Curves.easeInOutCubicEmphasized.transform(t.clamp(0.0, 1.0));
    final mid = Offset(
      (startGlobal.dx + endGlobal.dx) * 0.5,
      (startGlobal.dy + endGlobal.dy) * 0.5 - 56,
    );
    final omu = 1 - u;
    return Offset(
      omu * omu * startGlobal.dx + 2 * omu * u * mid.dx + u * u * endGlobal.dx,
      omu * omu * startGlobal.dy + 2 * omu * u * mid.dy + u * u * endGlobal.dy,
    );
  }

  double get scale {
    if (t < 0.12) return 0.9 + t / 0.12 * 0.2;
    if (t > 0.88) {
      final s = (t - 0.88) / 0.12;
      return 1.12 - s * 0.12;
    }
    return 1.08;
  }

  double get rotation => (1 - t) * 0.18;
}
