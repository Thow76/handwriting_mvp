import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/score_integrator.dart';
import 'package:handwriting_mvp/models/stroke.dart';

/// Helper to build a [rows]×[cols] mask from a list of (row, col) pairs.
List<List<bool>> _mask(int rows, int cols, [List<(int, int)> active = const []]) {
  final grid = List.generate(rows, (_) => List.filled(cols, false));
  for (final (r, c) in active) {
    grid[r][c] = true;
  }
  return grid;
}

void main() {
  group('ScoreIntegrator', () {
    test('no strokes → 0% coverage, 0% precision', () {
      final ref = _mask(10, 10, [(5, 5), (5, 6), (6, 5), (6, 6)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [],
      );

      expect(result.coverage, 0.0);
      expect(result.precision, 0.0);
    });

    test('stroke perfectly covering reference → 100% coverage, 100% precision', () {
      // Reference is a single pixel at (5,5).
      final ref = _mask(10, 10, [(5, 5)]);

      // Draw at cell centre (5.5, 5.5) so the stroke lands in exactly one pixel.
      final stroke = Stroke([const Offset(5.5, 5.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 1.0);
      expect(result.precision, 1.0);
    });

    test('stroke completely outside reference → 0% coverage, 0% precision', () {
      // Reference in top-left corner.
      final ref = _mask(10, 10, [(0, 0), (0, 1), (1, 0), (1, 1)]);

      // Draw in bottom-right corner.
      final stroke = Stroke([const Offset(8, 8)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 0.0);
      expect(result.precision, 0.0);
    });

    test('stroke covers half the reference → 50% coverage, 100% precision', () {
      // Reference is a 2×1 block at (5,4) and (5,5).
      final ref = _mask(10, 10, [(5, 4), (5, 5)]);

      // Draw at cell centre of (5,5) only.
      final stroke = Stroke([const Offset(5.5, 5.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 0.5);
      expect(result.precision, 1.0);
    });

    test('wide stroke spills outside reference → high coverage, lower precision', () {
      // Reference is a single pixel at (5,5).
      final ref = _mask(10, 10, [(5, 5)]);

      // Draw on that pixel with a wide stroke — covers (5,5) plus neighbours.
      final stroke = Stroke([const Offset(5, 5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 3.0,
      );

      expect(result.coverage, 1.0);
      expect(result.precision, lessThan(1.0));
    });

    test('strokes outside bounds are ignored', () {
      final ref = _mask(10, 10, [(5, 5)]);

      // Stroke is outside the 10×10 bounds.
      final stroke = Stroke([const Offset(20, 20)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 0.0);
      expect(result.precision, 0.0);
    });

    test('bounds offset is applied correctly', () {
      // Reference pixel at grid position (5,5).
      final ref = _mask(10, 10, [(5, 5)]);

      // Bounds start at (100, 100), so canvas point (105.5, 105.5) maps to cell (5,5).
      final stroke = Stroke([const Offset(105.5, 105.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(100, 100, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 1.0);
      expect(result.precision, 1.0);
    });

    test('multiple strokes combine for scoring', () {
      // Reference is two separate pixels.
      final ref = _mask(10, 10, [(2, 2), (8, 8)]);

      // Two strokes, each hitting one pixel at cell centre.
      final stroke1 = Stroke([const Offset(2.5, 2.5)]);
      final stroke2 = Stroke([const Offset(8.5, 8.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke1, stroke2],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 1.0);
      expect(result.precision, 1.0);
    });

    test('mismatched reference mask dimensions throws', () {
      // Reference is 5×5 but bounds imply a 10×10 grid.
      final ref = _mask(5, 5, [(2, 2)]);

      expect(
        () => ScoreIntegrator.score(
          referenceMask: ref,
          bounds: const Rect.fromLTWH(0, 0, 10, 10),
          strokes: [],
        ),
        throwsArgumentError,
      );
    });
  });
}
