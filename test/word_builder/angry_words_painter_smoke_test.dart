import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_loadout.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_painter.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_physics.dart';

void main() {
  testWidgets('AngryWordsBoardPainter paints without throwing', (tester) async {
    final world = AngryWordsPhysicsWorld(width: 320, height: 480)
      ..loadout = kAngryWordsStageArsenal.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPaint(
            size: const Size(320, 480),
            painter: AngryWordsBoardPainter(
              world: world,
              selectedIds: const {},
              wrongFlash: 0,
              successFlash: 0,
              prefixFlash: 0,
              combo: 0,
              trail: const [],
              sparkLife: 0,
              explosions: const [],
              isDark: false,
              scheme: ColorScheme.fromSeed(seedColor: Colors.orange),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
