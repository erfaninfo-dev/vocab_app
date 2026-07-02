enum WordBuilderTrayVisualMode { water, glassCrack }

extension WordBuilderTrayVisualModeX on WordBuilderTrayVisualMode {
  String get prefsValue => name;

  static WordBuilderTrayVisualMode fromPrefs(String? raw) {
    return WordBuilderTrayVisualMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => WordBuilderTrayVisualMode.water,
    );
  }
}
