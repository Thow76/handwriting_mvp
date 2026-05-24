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

  // ---------------------------------------------------------------------------
  // Formation-scoring integration tests
  // ---------------------------------------------------------------------------

  group('ScoreIntegrator formation scoring', () {
    // 90×90 all-false mask used for formation tests — formation scorers do not
    // use the reference mask, so only the dimensions matter.
    final ref90 = _mask(90, 90);
    const bounds90 = Rect.fromLTWH(0, 0, 90, 90);

    test('no letter → all four formation fields are null', () {
      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [],
      );

      expect(result.strokeStart, isNull);
      expect(result.strokeDirection, isNull);
      expect(result.compoundStroke, isNull);
      expect(result.strokeBreak, isNull);
    });

    test('unknown letter → all four formation fields are null (defensive)', () {
      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [],
        letter: '0', // digit — not in letterFormationRegistry
      );

      expect(result.strokeStart, isNull);
      expect(result.strokeDirection, isNull);
      expect(result.compoundStroke, isNull);
      expect(result.strokeBreak, isNull);
    });

    test('correct n → all four formation scores attached; start, compound and '
        'break scores are 1.0', () {
      // n has a single compound stroke with waypoints:
      //   topLeft → bottomLeft → top → bottomRight
      // In a 90×90 grid (3×3 cells of 30px each), the cell centres are:
      //   topLeft    = (15, 15)
      //   bottomLeft = (15, 75)
      //   top        = (45, 15)
      //   bottomRight= (75, 75)
      // The stroke visits each centroid exactly, so all 4 waypoints are hit.
      //
      // n's startRect is minX=0, maxX=0.25, minY=0, maxY=0.15.
      // In 90×90 bounds this corresponds to x ∈ [0, 22.5) and y ∈ [0, 13.5).
      // The first point (10, 10) is inside the startRect AND in the topLeft
      // waypoint cell (x < 30, y < 30), so both scorers report 1.0.
      final stroke = Stroke(const [
        Offset(10, 10), // inside n's startRect and in topLeft cell
        Offset(15, 75), // bottomLeft centroid
        Offset(45, 15), // top centroid
        Offset(75, 75), // bottomRight centroid
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'n',
      );

      // All four formation score objects must be attached.
      expect(result.strokeStart, isNotNull);
      expect(result.strokeDirection, isNotNull);
      expect(result.compoundStroke, isNotNull);
      expect(result.strokeBreak, isNotNull);

      // Stroke first point (10, 10) is inside n's startRect → 1.0.
      expect(result.strokeStart!.overallScore, 1.0);

      // n has only compound strokes; StrokeDirectionScorer excludes compound
      // strokes from its mean → overallScore is 0.0 (no direction-scored
      // strokes found).
      expect(result.strokeDirection!.overallScore, 0.0);

      // All 4 waypoints hit in order → 1.0.
      expect(result.compoundStroke!.overallScore, 1.0);

      // 1 stroke provided; minRequiredStrokes = 1 → 1.0.
      expect(result.strokeBreak!.overallScore, 1.0);
    });

    test('clockwise o → strokeDirection score is 0.0', () {
      // o expects an anticlockwise stroke.  Drawing it clockwise (positive
      // shoelace signed area in screen coordinates) should score 0.0.
      // Points form a clockwise oval: top → right → bottom → left.
      final stroke = Stroke(const [
        Offset(45, 5),  // top
        Offset(85, 45), // right
        Offset(45, 85), // bottom
        Offset(5, 45),  // left
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'o',
      );

      // All four formation score objects must be attached.
      expect(result.strokeStart, isNotNull);
      expect(result.strokeDirection, isNotNull);
      expect(result.compoundStroke, isNotNull);
      expect(result.strokeBreak, isNotNull);

      // Clockwise vs expected anticlockwise → opposite pair → 0.0.
      expect(result.strokeDirection!.overallScore, 0.0);

      // o has no compound strokes → vacuously correct → 1.0.
      expect(result.compoundStroke!.overallScore, 1.0);

      // 1 stroke provided; minRequiredStrokes = 1 → 1.0.
      expect(result.strokeBreak!.overallScore, 1.0);
    });
  });
}
