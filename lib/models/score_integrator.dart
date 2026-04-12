import 'dart:ui' show Offset, Rect;

import 'coverage_scorer.dart';
import 'efficiency_scorer.dart';
import 'precision_scorer.dart';
import 'score_result.dart';
import 'skeletonizer.dart';
import 'stroke.dart';
import 'stroke_rasterizer.dart';

/// Rasterizes user strokes and scores them against a reference mask.
class ScoreIntegrator {
  /// Rasterizes [strokes] into the coordinate space defined by [bounds],
  /// then compares against [referenceMask] to produce normalised coverage
  /// and precision scores.
  ///
  /// Coverage is normalised: the raw coverage is divided by the maximum
  /// achievable coverage for a perfect centre-line trace at the given
  /// [strokeWidth]. This compensates for thin strokes being unable to
  /// fill the entire template shape.
  ///
  /// [referenceMask] must have dimensions matching
  /// `bounds.height.ceil()` × `bounds.width.ceil()`.
  static ScoreResult score({
    required List<List<bool>> referenceMask,
    required Rect bounds,
    required List<Stroke> strokes,
    double strokeWidth = 3.0,
  }) {
    final expectedRows = bounds.height.ceil();
    final expectedCols = bounds.width.ceil();

    if (referenceMask.length != expectedRows) {
      throw ArgumentError('Reference mask has ${referenceMask.length} rows, '
          'but bounds imply $expectedRows');
    }
    for (var row = 0; row < referenceMask.length; row++) {
      if (referenceMask[row].length != expectedCols) {
        throw ArgumentError('Reference mask row $row has '
            '${referenceMask[row].length} columns, '
            'but bounds imply $expectedCols');
      }
    }

    final strokeMask = StrokeRasterizer.rasterize(
      bounds: bounds,
      strokes: strokes,
      strokeWidth: strokeWidth,
    );

    final rawCoverage = CoverageScorer.calculate(
      referenceMask: referenceMask,
      strokeMask: strokeMask,
    );

    // Skeletonize once and reuse for both coverage normalisation and efficiency.
    final skeleton = Skeletonizer.skeletonize(referenceMask);

    // Normalise coverage against the maximum achievable for this stroke width.
    final maxCoverage = _maxAchievableCoverageFromSkeleton(
      skeleton: skeleton,
      referenceMask: referenceMask,
      bounds: bounds,
      strokeWidth: strokeWidth,
    );

    final normalisedCoverage = maxCoverage > 0
        ? (rawCoverage / maxCoverage).clamp(0.0, 1.0)
        : 0.0;

    // Calculate efficiency: ideal path length vs actual path length.
    final idealLength = EfficiencyScorer.idealPathLength(skeleton);
    final actualLength = EfficiencyScorer.actualPathLength(strokes);
    final efficiency = EfficiencyScorer.calculate(
      idealPathLength: idealLength,
      actualPathLength: actualLength,
    );

    return ScoreResult(
      coverage: normalisedCoverage,
      precision: PrecisionScorer.calculate(
        referenceMask: referenceMask,
        strokeMask: strokeMask,
      ),
      placement: 0.0,
      efficiency: efficiency,
    );
  }

  /// Computes the maximum coverage achievable by a perfect centre-line
  /// trace of the reference shape at the given stroke width.
  ///
  /// Uses a pre-computed [skeleton] to avoid redundant skeletonization.
  /// 1. Create synthetic strokes from each skeleton pixel.
  /// 2. Rasterize those strokes at [strokeWidth].
  /// 3. Measure coverage of the ideal trace against the reference.
  static double _maxAchievableCoverageFromSkeleton({
    required List<List<bool>> skeleton,
    required List<List<bool>> referenceMask,
    required Rect bounds,
    required double strokeWidth,
  }) {
    // Convert skeleton pixels to canvas-coordinate stroke points.
    // Each skeleton pixel becomes a single-point stroke at its cell centre.
    final skeletonStrokes = <Stroke>[];
    for (var row = 0; row < skeleton.length; row++) {
      for (var col = 0; col < skeleton[row].length; col++) {
        if (skeleton[row][col]) {
          skeletonStrokes.add(Stroke([
            Offset(bounds.left + col + 0.5, bounds.top + row + 0.5),
          ]));
        }
      }
    }

    if (skeletonStrokes.isEmpty) return 0.0;

    final idealMask = StrokeRasterizer.rasterize(
      bounds: bounds,
      strokes: skeletonStrokes,
      strokeWidth: strokeWidth,
    );

    return CoverageScorer.calculate(
      referenceMask: referenceMask,
      strokeMask: idealMask,
    );
  }
}
