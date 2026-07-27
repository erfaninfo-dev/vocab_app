/// Short-lived animation beats for the train-escape tray scenario.
enum TrayTrainMoment {
  none,

  /// A rope just snapped after a correct word.
  ropeBreak,

  /// Level complete: character rolls off the rails.
  escape,

  /// Level complete: the train rushes past the freed character.
  trainPass,
}
