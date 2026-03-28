import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_rasterizer.dart';

void main() {
  group('StrokeRasterizer', () {
    test('no strokes → all-false grid', () {
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [],
      );

      expect(grid.length, 10);
      expect(grid.first.length, 10);
      expect(grid.expand((row) => row).every((cell) => !cell), isTrue);
    });

    test('grid dimensions match bounding box', () {
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 20, 15),
        strokes: [],
      );

      expect(grid.length, 15); // rows = height
      expect(grid.first.length, 20); // cols = width
    });

    test('single point inside bounds marks pixel as true', () {
      final stroke = Stroke([const Offset(5, 5)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(grid[5][5], isTrue);
    });

    test('stroke completely outside bounds → all-false grid', () {
      final stroke = Stroke([const Offset(50, 50), const Offset(60, 60)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
      );

      expect(grid.expand((row) => row).every((cell) => !cell), isTrue);
    });

    test('stroke points are mapped relative to bounds origin', () {
      // Bounds start at (100, 100), so a point at (105, 105)
      // should map to grid cell (5, 5).
      final stroke = Stroke([const Offset(105, 105)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(100, 100, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(grid[5][5], isTrue);
    });

    test('horizontal stroke marks pixels along path', () {
      // Draw from (2,5) to (8,5) — should mark cells in row 5.
      final stroke = Stroke([const Offset(2, 5), const Offset(8, 5)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      for (var col = 2; col <= 8; col++) {
        expect(grid[5][col], isTrue, reason: 'cell (5, $col) should be true');
      }
    });

    test('vertical stroke marks pixels along path', () {
      // Draw from (5,2) to (5,8) — should mark cells in column 5.
      final stroke = Stroke([const Offset(5, 2), const Offset(5, 8)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      for (var row = 2; row <= 8; row++) {
        expect(grid[row][5], isTrue, reason: 'cell ($row, 5) should be true');
      }
    });

    test('stroke width > 1 marks neighbouring pixels', () {
      // A single point at (5,5) with strokeWidth 3 should mark
      // a region around (5,5), not just the single pixel.
      final stroke = Stroke([const Offset(5, 5)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 3.0,
      );

      // The centre pixel must be true.
      expect(grid[5][5], isTrue);
      // Adjacent pixels within the stroke radius should also be true.
      expect(grid[4][5], isTrue);
      expect(grid[6][5], isTrue);
      expect(grid[5][4], isTrue);
      expect(grid[5][6], isTrue);
    });

    test('multiple strokes are all rasterized', () {
      final stroke1 = Stroke([const Offset(2, 2)]);
      final stroke2 = Stroke([const Offset(8, 8)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke1, stroke2],
        strokeWidth: 1.0,
      );

      expect(grid[2][2], isTrue);
      expect(grid[8][8], isTrue);
    });

    test('stroke partially outside bounds only rasterizes inside portion', () {
      // Stroke goes from inside (5,5) to outside (15,5).
      // Only the portion within the 10×10 grid should appear.
      final stroke = Stroke([const Offset(5, 5), const Offset(15, 5)]);
      final grid = StrokeRasterizer.rasterize(
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      // Inside portion should be marked.
      expect(grid[5][5], isTrue);
      expect(grid[5][9], isTrue);
      // Grid should not extend beyond bounds.
      expect(grid.first.length, 10);
    });
  });
}
