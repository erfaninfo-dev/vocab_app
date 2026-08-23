import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// 26-letter atlas (A–Z) for cargo glyphs — also drawn via [Canvas.drawRawAtlas].
class WbLetterAtlas {
  WbLetterAtlas._(this.image, this.rects, this.cellSize);

  final ui.Image image;
  final Map<String, Rect> rects;
  final int cellSize;

  Rect? rectFor(String ch) {
    final key = ch.toUpperCase();
    if (key.isEmpty) return null;
    return rects[key[0]];
  }

  void dispose() => image.dispose();

  static Future<WbLetterAtlas> build({
    int cellSize = 64,
    int cols = 8,
    Color fill = const Color(0xFF212121),
  }) async {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rows = (letters.length / cols).ceil();
    final width = cols * cellSize;
    final height = rows * cellSize;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final map = <String, Rect>{};

    for (var i = 0; i < letters.length; i++) {
      final ch = letters[i];
      final col = i % cols;
      final row = i ~/ cols;
      final cell = Rect.fromLTWH(
        col * cellSize.toDouble(),
        row * cellSize.toDouble(),
        cellSize.toDouble(),
        cellSize.toDouble(),
      );
      map[ch] = cell;

      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(
            color: fill,
            fontSize: cellSize * 0.62,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          cell.left + (cell.width - tp.width) * 0.5,
          cell.top + (cell.height - tp.height) * 0.5,
        ),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return WbLetterAtlas._(image, map, cellSize);
  }
}
