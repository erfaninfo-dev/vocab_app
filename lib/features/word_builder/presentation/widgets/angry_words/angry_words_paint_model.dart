import 'package:flutter/material.dart';

import 'angry_words_painter.dart';
import 'angry_words_physics.dart';

/// Mutable paint inputs driven by the board ticker without [setState] (Phase 9).
class AngryWordsPaintModel extends ChangeNotifier {
  AngryWordsPaintModel(this.world);

  final AngryWordsPhysicsWorld world;

  Set<int> selectedIds = const {};
  double wrongFlash = 0;
  double successFlash = 0;
  double prefixFlash = 0;
  double sparkLife = 0;
  List<Offset> trail = const [];
  List<AngryWordsLetterExplosion> explosions = const [];
  bool isDark = false;
  ColorScheme? scheme;
  String? nextLetterHighlight;
  String? peekChar;
  double peekFlash = 0;
  bool allowIdlePulse = true;
  double particleScale = 1;

  void markNeedsPaint() => notifyListeners();
}
