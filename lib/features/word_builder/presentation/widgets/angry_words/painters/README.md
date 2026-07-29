# Angry Words painter modules

Full `CustomPainter` implementation still lives in
`../angry_words_painter.dart` (~3k lines).

Target layout for a golden-backed split (Phase 1 follow-up):

- `materials/` — per-material / jug / bottle / letter orb drawing
- `guns/` — blaster / hammer / sling silhouettes
- `effects/` — explosions, aim preview, spark, combo
- `angry_words_board_painter.dart` — re-export / orchestration

Do **not** mechanically `part`-split class methods without golden baselines;
a failed attempt caused recursive mixin errors. Prefer mixins or top-level
helpers with `matchesGoldenFile` before/after each extraction.
