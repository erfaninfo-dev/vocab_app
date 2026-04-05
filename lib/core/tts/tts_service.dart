import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum TtsStatus { idle, speaking }

class TtsState {
  const TtsState({this.status = TtsStatus.idle, this.activeText = ''});
  final TtsStatus status;
  final String activeText;

  bool get isSpeaking => status == TtsStatus.speaking;
  bool isSpeakingText(String text) => isSpeaking && activeText == text;

  TtsState copyWith({TtsStatus? status, String? activeText}) => TtsState(
    status: status ?? this.status,
    activeText: activeText ?? this.activeText,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class TtsNotifier extends StateNotifier<TtsState> {
  TtsNotifier() : super(const TtsState()) {
    _init();
  }

  final _tts = FlutterTts();

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      // status updated in speak()
    });

    _tts.setCompletionHandler(() {
      state = const TtsState();
    });

    _tts.setCancelHandler(() {
      state = const TtsState();
    });

    _tts.setErrorHandler((_) {
      state = const TtsState();
    });
  }

  /// Speak [text]. If [text] is already playing, stops it instead.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    if (state.isSpeakingText(text)) {
      await stop();
      return;
    }

    await _tts.stop();
    state = state.copyWith(status: TtsStatus.speaking, activeText: text);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = const TtsState();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>(
  (_) => TtsNotifier(),
);
