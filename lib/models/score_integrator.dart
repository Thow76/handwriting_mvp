import 'dart:ui' show Rect;

import 'coverage_scorer.dart';
import 'precision_scorer.dart';
import 'score_result.dart';
import 'stroke.dart';
import 'stroke_rasterizer.dart';

/// Rasterizes user strokes and scores them against a reference mask.
class ScoreIntegrator {
  /// Rasterizes [strokes] into the coordinate space defined by [bounds],
  /// then compares against [referenceMask] to produce coverage and
  /// precision scores.
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

    return ScoreResult(
      coverage: CoverageScorer.calculate(
        referenceMask: referenceMask,
        strokeMask: strokeMask,
      ),
      precision: PrecisionScorer.calculate(
        referenceMask: referenceMask,
        strokeMask: strokeMask,
      ),
    );
  }
}
