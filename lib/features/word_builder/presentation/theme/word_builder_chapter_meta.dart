/// Chapter labels aligned with Angry Words stage ranges.
///
/// Visual palettes / chrome: see [WbChapterTheme]
/// (`word_builder_chapter_theme.dart`) — Angry Words board only.
abstract final class WbChapterMeta {
  static const chapters = <({String name, int first, int last})>[
    (name: 'Toy Box', first: 1, last: 7),
    (name: 'Street Spray', first: 8, last: 10),
    (name: 'Pellet Party', first: 11, last: 15),
    (name: 'War Band', first: 16, last: 22),
    (name: 'Ice & Fire', first: 23, last: 26),
    (name: 'Piercers', first: 27, last: 32),
    (name: 'Energy Age', first: 33, last: 40),
    (name: 'Boom Brigade', first: 41, last: 45),
    (name: 'Endgame', first: 46, last: 50),
  ];

  static ({String name, int indexInChapter, int chapterLength}) forStage(
    int stage1Based,
  ) {
    final s = stage1Based.clamp(1, 50);
    for (final c in chapters) {
      if (s >= c.first && s <= c.last) {
        return (
          name: c.name,
          indexInChapter: s - c.first + 1,
          chapterLength: c.last - c.first + 1,
        );
      }
    }
    return (name: 'Endgame', indexInChapter: 1, chapterLength: 5);
  }

  static String hudLabel(int stage1Based) {
    final m = forStage(stage1Based);
    return '${m.name} · ${m.indexInChapter}/${m.chapterLength}';
  }
}
