/// Visual scenario rendered inside the letter-tray center.
///
/// Gameplay (letters, validation, coins, hints) is identical for all
/// scenarios; only the center-of-tray visuals/audio differ.
enum TrayScenarioKind { water, train, prison }

const List<TrayScenarioKind> _trayScenarioCycle = [
  TrayScenarioKind.water,
  TrayScenarioKind.train,
  TrayScenarioKind.prison,
];

/// Rotates the tray scenario per level so consecutive levels never repeat:
/// water → train → prison → water → …
TrayScenarioKind trayScenarioForLevelIndex(int levelIndex) =>
    _trayScenarioCycle[levelIndex % _trayScenarioCycle.length];
