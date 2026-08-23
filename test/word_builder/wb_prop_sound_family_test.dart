import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_prop_break_audio.dart';
import 'package:ielts_vocab_app/core/audio/word_builder_sound_service.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart';
import 'package:ielts_vocab_app/features/word_builder/data/prop_archetypes/wb_prop_sound_family.dart';

void main() {
  test('eight families map to existing assets', () {
    expect(WbPropSoundFamily.values.length, 8);
    for (final f in WbPropSoundFamily.values) {
      expect(f.assetPath, isNotEmpty);
      expect(f.fallbackAssetPath, 'assets/audio/pop.WAV');
      expect(f.pitchRange.$1, lessThanOrEqualTo(f.pitchRange.$2));
    }
    expect(WbPropSoundFamily.popSoft.assetPath, contains('pop'));
    expect(WbPropSoundFamily.shatterGlass.assetPath, contains('pot'));
    expect(WbPropSoundFamily.sparkEnergy.assetPath, contains('shot2'));
  });

  test('every archetype pitch sits in its family range', () {
    for (final spec in kWbArchetypes.values) {
      final range = spec.soundFamily.pitchRange;
      expect(
        spec.soundPitch,
        inInclusiveRange(range.$1, range.$2),
        reason: '${spec.id} pitch ${spec.soundPitch} not in $range',
      );
    }
  });

  test('bell HP pitches are explicit (no family-range requirement)', () {
    expect(1.20, greaterThan(WbPropSoundFamily.clangMetal.pitchRange.$2));
    // Destroy pitch for bronzeBell stays inside clang band.
    expect(
      kWbArchetypes[WbPropArchetype.bronzeBell]!.soundPitch,
      inInclusiveRange(0.65, 0.9),
    );
  });

  test('voice cap matches platform fragility', () {
    final audio = AngryWordsPropBreakAudio();
    final expected = WordBuilderSoundService.isFragileDesktopAudio
        ? AngryWordsPropBreakAudio.kMaxVoicesWindows
        : AngryWordsPropBreakAudio.kMaxVoicesMobile;
    expect(audio.voiceCount, expected);
  });

  test('disabled gate drops all plays', () {
    final audio = AngryWordsPropBreakAudio();
    // Should not throw when disabled.
    for (var i = 0; i < 20; i++) {
      audio.play(
        family: WbPropSoundFamily.clangMetal,
        basePitch: 0.8,
        enabled: false,
      );
    }
  });
}
