import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/features/word_builder/domain/word_builder_game_logic.dart';
import 'package:ielts_vocab_app/features/word_builder/domain/word_builder_models.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_loadout.dart';
import 'package:ielts_vocab_app/features/word_builder/presentation/widgets/angry_words/angry_words_physics.dart';
import 'package:ielts_vocab_app/features/word_builder/word_builder_campaign_session_key.dart';

WordBuilderTargetWord _tw(String w) => WordBuilderTargetWord(
      word: w,
      translationFa: w,
      exampleEn: w,
    );

WordBuilderLevel _level(List<String> words) => WordBuilderLevel(
      levelId: 1,
      difficulty: WordBuilderDifficulty.beginner,
      category: 'test',
      letters: words.expand((w) => w.split('')).toList(),
      targetWords: [for (final w in words) _tw(w)],
    );

void main() {
  group('pullPowerCurve', () {
    test('maps 0→0 and 1→1', () {
      expect(AngryWordsPhysicsWorld.pullPowerCurve(0), 0);
      expect(AngryWordsPhysicsWorld.pullPowerCurve(1), closeTo(1, 1e-9));
    });

    test('is monotonic increasing on [0,1]', () {
      var prev = AngryWordsPhysicsWorld.pullPowerCurve(0);
      for (var i = 1; i <= 100; i++) {
        final t = i / 100;
        final v = AngryWordsPhysicsWorld.pullPowerCurve(t);
        expect(v, greaterThanOrEqualTo(prev), reason: 'at t=$t');
        prev = v;
      }
    });

    test('powerNormFromPullDistance at min/mid/max pull', () {
      const minP = AngryWordsPhysicsWorld.minPull;
      const maxP = AngryWordsPhysicsWorld.maxPull;
      expect(AngryWordsPhysicsWorld.powerNormFromPullDistance(minP), 0);
      expect(
        AngryWordsPhysicsWorld.powerNormFromPullDistance(maxP),
        closeTo(1, 1e-9),
      );
      final mid = AngryWordsPhysicsWorld.powerNormFromPullDistance(
        (minP + maxP) / 2,
      );
      expect(mid, greaterThan(0.4));
      expect(mid, lessThan(0.9));
    });
  });

  group('AngryWordsLoadout.forSession', () {
    test('stage indices map to expected guns', () {
      AngryWordsLoadout loadFor(int stage1Based) {
        final key = encodeWordBuilderCampaignSessionKey(
          WordBuilderDifficulty.beginner,
          stage1Based,
        );
        return AngryWordsLoadout.forSession(bookKey: key, levelIndex: 0);
      }

      expect(loadFor(1).label, 'Peashooter');
      expect(loadFor(9).label, 'Uzi');
      expect(loadFor(9).spillsYolk, isTrue);
      expect(loadFor(22).isPorcelainOnlyWall, isTrue);
      expect(loadFor(23).isBottleOnlyWall, isTrue);
      expect(loadFor(35).usesEmojiProps, isTrue);
      expect(loadFor(50).label, 'Doomsday MG');
    });

    test('earlySparseSkipChance tapers through ~stage 25', () {
      expect(kAngryWordsStageArsenal[0].earlySparseSkipChance, greaterThan(0.4));
      expect(kAngryWordsStageArsenal[16].earlySparseSkipChance, greaterThan(0));
      expect(kAngryWordsStageArsenal[20].earlySparseSkipChance, greaterThan(0));
      expect(kAngryWordsStageArsenal[24].earlySparseSkipChance, greaterThan(0));
      expect(kAngryWordsStageArsenal[25].earlySparseSkipChance, 0);
      expect(
        kAngryWordsStageArsenal[3].earlySparseSkipChance,
        greaterThan(kAngryWordsStageArsenal[16].earlySparseSkipChance),
      );
    });

    test('difficulty densifies wall and intermediate mounts twin guns', () {
      final beginnerKey = encodeWordBuilderCampaignSessionKey(
        WordBuilderDifficulty.beginner,
        10,
      );
      final interKey = encodeWordBuilderCampaignSessionKey(
        WordBuilderDifficulty.intermediate,
        10,
      );
      final advKey = encodeWordBuilderCampaignSessionKey(
        WordBuilderDifficulty.advanced,
        10,
      );

      final b = AngryWordsLoadout.forSession(bookKey: beginnerKey, levelIndex: 0);
      final i = AngryWordsLoadout.forSession(bookKey: interKey, levelIndex: 0);
      final a = AngryWordsLoadout.forSession(bookKey: advKey, levelIndex: 0);

      expect(b.gunMounts, 1);
      expect(i.gunMounts, 2);
      expect(a.gunMounts, 1);
      expect(i.effectiveCols, greaterThanOrEqualTo(b.effectiveCols));
      expect(a.effectiveCols, greaterThanOrEqualTo(i.effectiveCols));
      expect(a.densityScale, greaterThan(b.densityScale));
    });
  });

  group('rollMaterial weighted distribution', () {
    test('1000 samples stay near wallMix weights', () {
      final loadout = kAngryWordsStageArsenal.first;
      final rng = Random(42);
      final counts = <AngryWordsPropMaterial, int>{};
      const n = 1000;
      for (var i = 0; i < n; i++) {
        final m = loadout.rollMaterial(rng);
        counts[m] = (counts[m] ?? 0) + 1;
      }
      var totalW = 0.0;
      for (final w in loadout.wallMix) {
        totalW += w.weight;
      }
      for (final w in loadout.wallMix) {
        final expected = w.weight / totalW;
        final actual = (counts[w.material] ?? 0) / n;
        expect(
          actual,
          closeTo(expected, 0.08),
          reason: '${w.material}: actual=$actual expected=$expected',
        );
      }
    });
  });

  group('PREFIX / catalog helpers', () {
    test('correct next letter for active prefix', () {
      final level = _level(['hit', 'cat']);
      expect(isValidNextLetterForActiveSlots(level, {}, '', 'h'), isTrue);
      expect(isValidNextLetterForActiveSlots(level, {}, 'h', 'i'), isTrue);
      expect(isValidNextLetterForActiveSlots(level, {}, 'hi', 't'), isTrue);
    });

    test('wrong next letter rejected', () {
      final level = _level(['hit']);
      expect(isValidNextLetterForActiveSlots(level, {}, 'h', 'x'), isFalse);
    });

    test('after shorter word solved, longer prefix stays live (hi→hit)', () {
      final level = _level(['hi', 'hit']);
      final solved = {'hi'};
      expect(isValidUnsolvedTargetPrefix(level, solved, 'h'), isTrue);
      expect(isValidUnsolvedTargetPrefix(level, solved, 'hi'), isTrue);
      expect(isValidNextLetterForActiveSlots(level, solved, 'hi', 't'), isTrue);
      expect(findUnsolvedTargetMatchingBuilt(level, solved, 'hit')?.word, 'hit');
    });
  });
}
