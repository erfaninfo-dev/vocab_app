import 'dart:math' as math;

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
    this.asChick = false,
  });

  final String char;
  final Offset startGlobal;
  final Offset endGlobal;
  final Color tint;
  double delay;
  double t = 0;
  bool settled = false;

  /// Seconds since this flight became active (after delay). Used for flap/bob.
  double age = 0;

  /// Correct letter-egg hatches a chick that delivers the letter.
  final bool asChick;

  /// Travel duration in seconds (chicks are slower so flap reads clearly).
  double get durationSec => asChick ? 1.18 : 0.68;

  Offset get position {
    final u = Curves.easeInOutCubicEmphasized.transform(t.clamp(0.0, 1.0));
    final arcLift = asChick ? 78.0 : 56.0;
    final mid = Offset(
      (startGlobal.dx + endGlobal.dx) * 0.5,
      (startGlobal.dy + endGlobal.dy) * 0.5 - arcLift,
    );
    final omu = 1 - u;
    var pos = Offset(
      omu * omu * startGlobal.dx + 2 * omu * u * mid.dx + u * u * endGlobal.dx,
      omu * omu * startGlobal.dy + 2 * omu * u * mid.dy + u * u * endGlobal.dy,
    );
    if (asChick && !settled) {
      // Soft hover bob while flapping.
      pos += Offset(0, math.sin(age * math.pi * 5.5) * 3.5);
    }
    return pos;
  }

  double get scale {
    if (t < 0.12) return 0.9 + t / 0.12 * 0.2;
    if (t > 0.88) {
      final s = (t - 0.88) / 0.12;
      return 1.12 - s * 0.12;
    }
    return asChick ? 1.14 : 1.08;
  }

  double get rotation {
    if (!asChick) return (1 - t) * 0.18;
    // Bank into the arc, plus a tiny flap wobble.
    final dx = endGlobal.dx - startGlobal.dx;
    final bank = (dx / 220.0).clamp(-0.35, 0.35);
    final flapWobble = math.sin(age * math.pi * 8) * 0.06;
    return bank * (1 - t) * 0.85 + flapWobble;
  }

  /// Wing angle in radians (−open … +up). ~4 beats / sec.
  double get wingFlap {
    if (settled) return -0.15;
    return math.sin(age * math.pi * 8) * 0.85;
  }
}
