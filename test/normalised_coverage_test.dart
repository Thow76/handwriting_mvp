import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/coverage_scorer.dart';
import 'package:handwriting_mvp/models/score_integrator.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_rasterizer.dart';

/// Helper to build a [rows]×[cols] mask filled in a rectangular region.
List<List<bool>> _filledRect(int rows, int cols, int top, int left, int bottom, int right) {
  final grid = List.generate(rows, (_) => List.filled(cols, false));
  for (var r = top; r <= bottom; r++) {
    for (var c = left; c <= right; c++) {
      grid[r][c] = true;
    }
  }
  return grid;
}

void main() {
  group('Normalised coverage', () {
    test('thin stroke tracing centre of fat reference scores high normalised coverage', () {
      // Reference: 7-pixel-wide vertical bar (rows 2–17, cols 7–13) in a 20×20 grid.
      final ref = _filledRect(20, 20, 2, 7, 17, 13);
      final bounds = const Rect.fromLTWH(0, 0, 20, 20);

      // User traces down the centre column (col 10) with a thin stroke.
      final points = <Offset>[];
      for (var row = 2; row <= 17; row++) {
        points.add(Offset(10.5, row + 0.5));
      }
      final stroke = Stroke(points);

      // Get raw coverage for comparison.
      final strokeMask = StrokeRasterizer.rasterize(
        bounds: bounds,
        strokes: [stroke],
        strokeWidth: 3.0,
      );
      final rawCoverage = CoverageScorer.calculate(
        referenceMask: ref,
        strokeMask: strokeMask,
      );

      // Raw coverage should be well below 100% because the stroke is thin.
      expect(rawCoverage, lessThan(0.7));

      // Normalised coverage should be significantly higher.
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: bounds,
        strokes: [stroke],
        strokeWidth: 3.0,
      );
      expect(result.coverage, greaterThan(rawCoverage));
      expect(result.coverage, greaterThan(0.8));
    });

    test('no strokes still yields 0% normalised coverage', () {
      final ref = _filledRect(20, 20, 2, 7, 17, 13);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 20, 20),
        strokes: [],
        strokeWidth: 3.0,
      );
      expect(result.coverage, 0.0);
    });

    test('perfect trace of thin reference scores 100%', () {
      // Reference is a 1-pixel-wide vertical line — already skeletal.
      final ref = _filledRect(10, 10, 1, 5, 8, 5);
      final bounds = const Rect.fromLTWH(0, 0, 10, 10);

      final points = <Offset>[];
      for (var row = 1; row <= 8; row++) {
        points.add(Offset(5.5, row + 0.5));
      }
      final stroke = Stroke(points);

      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: bounds,
        strokes: [stroke],
        strokeWidth: 1.0,
      );
      expect(result.coverage, 1.0);
    });

    test('normalised coverage is clamped to 1.0', () {
      // A wide user stroke on a thin reference could theoretically exceed
      // max achievable coverage. Normalised coverage should not exceed 1.0.
      final ref = _filledRect(10, 10, 1, 4, 8, 6);
      final bounds = const Rect.fromLTWH(0, 0, 10, 10);

      // Draw with a wide stroke that covers more than the skeleton would.
      final points = <Offset>[];
      for (var row = 1; row <= 8; row++) {
        points.add(Offset(5.5, row + 0.5));
      }
      final stroke = Stroke(points);

      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: bounds,
        strokes: [stroke],
        strokeWidth: 5.0,
      );
      expect(result.coverage, lessThanOrEqualTo(1.0));
    });

    test('partial trace scores lower than full trace', () {
      final ref = _filledRect(20, 20, 2, 7, 17, 13);
      final bounds = const Rect.fromLTWH(0, 0, 20, 20);

      // Full trace down the whole height.
      final fullPoints = <Offset>[];
      for (var row = 2; row <= 17; row++) {
        fullPoints.add(Offset(10.5, row + 0.5));
      }
      final fullResult = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: bounds,
        strokes: [Stroke(fullPoints)],
        strokeWidth: 3.0,
      );

      // Partial trace — only half the height.
      final partialPoints = <Offset>[];
      for (var row = 2; row <= 9; row++) {
        partialPoints.add(Offset(10.5, row + 0.5));
      }
      final partialResult = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: bounds,
        strokes: [Stroke(partialPoints)],
        strokeWidth: 3.0,
      );

      // Full trace should have higher normalised coverage.
      expect(fullResult.coverage, greaterThan(partialResult.coverage));
    });

    test('existing single-pixel tests unaffected by normalisation', () {
      // Single pixel reference — skeleton is the pixel itself.
      // Max coverage with width 1.0 should be 1.0.
      final grid = List.generate(10, (_) => List.filled(10, false));
      grid[5][5] = true;

      final stroke = Stroke([const Offset(5.5, 5.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: grid,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );
      expect(result.coverage, 1.0);
      expect(result.precision, 1.0);
    });
  });
}
