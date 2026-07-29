import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_egg_crack_audio.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_gun_audio.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_pop_audio.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_porcelain_break_audio.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_sling_audio.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_sling_snap_audio.dart';
import 'package:ielts_vocab_app/core/audio/angry_words_sling_whoosh_audio.dart';
import 'package:ielts_vocab_app/core/audio/word_builder_sound_service.dart';

/// Required audio assets that must exist (optional train/prison omitted).
void main() {
  test('wired audio assets exist on disk with lowercase filenames', () {
    final declared = <String>{
      ...WordBuilderSoundService.allDeclaredAssetPaths,
      ...AngryWordsGunAudio.declaredAssetPaths,
      AngryWordsPopAudio.assetPath,
      AngryWordsPorcelainBreakAudio.assetPath,
      AngryWordsSlingAudio.assetPath,
      AngryWordsSlingSnapAudio.assetPath,
      AngryWordsSlingWhooshAudio.assetPath,
      AngryWordsEggCrackAudio.assetPath,
      'assets/audio/words_game_bgmusic.mp3',
      'assets/audio/water_pill.mp3',
      'assets/audio/drown2.mp3',
      'assets/audio/drown3.mp3',
      'assets/audio/splash_chime.mp3',
      'assets/audio/page_flip.mp3',
    };

    final missing = <String>[];
    final badCase = <String>[];
    for (final asset in declared) {
      final name = asset.split('/').last;
      if (name != name.toLowerCase()) badCase.add(asset);
      if (!File(asset).existsSync()) missing.add(asset);
    }

    expect(badCase, isEmpty, reason: 'Filenames must be lowercase: $badCase');
    expect(missing, isEmpty, reason: 'Missing audio files: $missing');
  });
}
