import 'dart:ui' show Offset, Rect;

import 'compound_stroke_scorer.dart';
import 'coverage_scorer.dart';
import 'efficiency_scorer.dart';
import 'formation_score.dart';
import 'letter_formation_registry.dart';
import 'precision_scorer.dart';
import 'score_result.dart';
import 'skeletonizer.dart';
import 'stroke.dart';
import 'stroke_break_counter.dart';
import 'stroke_direction_scorer.dart';
import 'stroke_rasterizer.dart';
import 'stroke_start_scorer.dart';

/// Rasterizes user strokes and scores them against a reference mask.
class ScoreIntegrator {
  /// Rasterizes [strokes] into the coordinate space defined by [bounds],
  /// then compares against [referenceMask] to produce normalised coverage
  /// and precision scores.
  ///
  /// If [letter] is provided, also scores the strokes against the expected
  /// formation for that letter using the four formation scorers.  If no
  /// formation data exists for [letter] (defensive — should not happen after
  /// stage 2), the four formation fields in the returned [ScoreResult] are
  /// left null.
  ///
  /// Coverage is normalised: the raw coverage is divided by the maximum
  /// achievable coverage for a perfect centre-line trace at the given
  /// [strokeWidth]. This compensates for thin strokes being unable to
  /// fill the entire template shape.
  ///
  /// [referenceMask] must have dimensions matching
  /// `bounds.height.ceil()` × `bounds.width.ceil()`.
  ///
  /// [formationBounds] is the bounding rect passed to the formation scorers
  /// ([StrokeStartScorer], [StrokeDirectionScorer], [CompoundStrokeScorer]).
  /// If not supplied, it defaults to [bounds].
  static ScoreResult score({
    required List<List<bool>> referenceMask,
    required Rect bounds,
    required List<Stroke> strokes,
    double strokeWidth = 3.0,
    String? letter,
    Rect? formationBounds,
  }) {
    formationBounds ??= bounds;
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

    // Formation scoring — only when a target letter is supplied and has
    // authored formation data.
    FormationScore? strokeStart;
    FormationScore? strokeDirection;
    FormationScore? compoundStroke;
    FormationScore? strokeBreak;

    if (letter != null) {
      final data = letterFormationRegistry[letter];
      if (data != null) {
        strokeStart = StrokeStartScorer(
          letter: letter,
          data: data,
          bounds: formationBounds,
        ).score(strokes);

        strokeDirection = StrokeDirectionScorer(
          letter: letter,
          data: data,
          bounds: formationBounds,
        ).score(strokes);

        compoundStroke = CompoundStrokeScorer(
          letter: letter,
          data: data,
          bounds: formationBounds,
        ).score(strokes);

        strokeBreak = StrokeBreakCounter(
          letter: letter,
          data: data,
        ).score(strokes);
      }
    }

    // The four formation scores are kept independent in ScoreResult and are
    // displayed separately in the UI. They are NOT combined into a single
    // headline formation score, so a StrokeDirectionScorer result of 0.0
    // (returned when all strokes are waypoint-routed and scoredValues is empty)
    // does not penalise any aggregate score.
    return ScoreResult(
      coverage: normalisedCoverage,
      precision: PrecisionScorer.calculate(
        referenceMask: referenceMask,
        strokeMask: strokeMask,
      ),
      placement: 0.0,
      efficiency: efficiency,
      strokeStart: strokeStart,
      strokeDirection: strokeDirection,
      compoundStroke: compoundStroke,
      strokeBreak: strokeBreak,
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
