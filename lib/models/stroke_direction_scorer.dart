import 'dart:ui' show Rect;

import 'formation_score.dart';
import 'letter_formation_data.dart';
import 'stroke.dart';
import 'stroke_formation_enums.dart';
import 'stroke_matcher.dart';

/// Scores whether the observed strokes were drawn in the expected directions
/// as defined by [LetterFormationData].
///
/// Two internal classifiers are used:
/// - Circular strokes (expected [StrokeDirection.clockwise] or
///   [StrokeDirection.anticlockwise]) are classified via the shoelace
///   (signed-area) formula.  Positive signed area → clockwise in screen
///   coordinates (Y increases downward); negative → anticlockwise.
/// - Linear strokes (expected [StrokeDirection.topToBottom] or
///   [StrokeDirection.leftToRight]) are classified by comparing the
///   end-point to the start-point on the dominant axis.
///
/// Scoring per stroke: correct → 1.0; opposite direction → 0.0;
/// any other mismatch → 0.5.
///
/// Strokes with non-empty expected waypoints and [StrokeDirection.dot] strokes
/// are recorded as observations with [StrokeObservation.score] of 0.0 and a
/// note directing the reader to the appropriate scorer; they are excluded from
/// the mean that forms [FormationScore.overallScore].
class StrokeDirectionScorer {
  /// The letter being scored. Used in error messages and summaries.
  final String letter;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// The tight bounding box of the letter template.
  ///
  /// Used for spatial stroke matching.
  final Rect bounds;

  /// Creates a [StrokeDirectionScorer].
  const StrokeDirectionScorer({
    required this.letter,
    required this.data,
    required this.bounds,
  });

  /// Scores [observed] strokes against the expected stroke directions.
  ///
  /// Returns a [FormationScore] containing:
  /// - [FormationScore.overallScore]: mean of per-stroke scores for
  ///   direction-scored strokes only (compound and dot strokes excluded).
  /// - [FormationScore.observations]: one [StrokeObservation] per matched,
  ///   non-empty observed stroke, including skipped compound/dot strokes.
  /// - [FormationScore.summary]: a learner-facing summary sentence.
  FormationScore score(List<Stroke> observed) {
    final matchIndices = matchStrokes(observed, data.strokes, bounds);
    final observations = <StrokeObservation>[];
    final scoredValues = <double>[];

    for (var i = 0; i < observed.length; i++) {
      final expectedIndex = matchIndices[i];
      if (expectedIndex == -1) continue;

      final expected = data.strokes[expectedIndex];
      final dir = expected.primaryDirection;

      // Strokes with authored waypoint sequences are handled by
      // CompoundStrokeScorer regardless of primaryDirection.
      if (expected.waypoints.isNotEmpty) {
        observations.add(
          StrokeObservation(
            strokeIndex: i,
            expected: dir.name,
            observed: dir.name,
            score: 0.0,
            note: 'skipped — handled by CompoundStrokeScorer',
          ),
        );
        continue;
      }

      // Dot/compound strokes without waypoints are handled by other scorers.
      if (dir == StrokeDirection.compound) {
        observations.add(
          StrokeObservation(
            strokeIndex: i,
            expected: dir.name,
            observed: dir.name,
            score: 0.0,
            note: 'skipped — no waypoints defined for CompoundStrokeScorer',
          ),
        );
        continue;
      }

      if (dir == StrokeDirection.dot) {
        observations.add(
          StrokeObservation(
            strokeIndex: i,
            expected: dir.name,
            observed: dir.name,
            score: 0.0,
            note: 'skipped — handled by StrokeBreakCounter',
          ),
        );
        continue;
      }

      if (observed[i].points.isEmpty) continue;

      final String observedDir;
      if (dir == StrokeDirection.clockwise ||
          dir == StrokeDirection.anticlockwise) {
        observedDir = _classifyCircular(observed[i]);
      } else {
        observedDir = _classifyLinear(observed[i]);
      }

      final strokeScore = _scoreDirections(dir.name, observedDir);
      scoredValues.add(strokeScore);
      observations.add(
        StrokeObservation(
          strokeIndex: i,
          expected: dir.name,
          observed: observedDir,
          score: strokeScore,
          note: _buildNote(dir, observedDir, strokeScore),
        ),
      );
    }

    final overallScore = scoredValues.isEmpty
        ? 0.0
        : scoredValues.reduce((a, b) => a + b) / scoredValues.length;

    return FormationScore(
      overallScore: overallScore,
      observations: observations,
      summary: _buildSummary(scoredValues),
    );
  }

  /// Classifies [stroke] as `'clockwise'` or `'anticlockwise'` using the
  /// shoelace (signed-area) formula.
  ///
  /// In screen coordinates (Y increases downward):
  /// - Positive signed area → clockwise.
  /// - Negative signed area → anticlockwise.
  ///
  /// The polygon is implicitly closed by including the term from the last
  /// point back to the first.
  String _classifyCircular(Stroke stroke) {
    final pts = stroke.points;
    if (pts.length < 3) return 'clockwise';
    var sum = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      sum += pts[i].dx * pts[j].dy - pts[j].dx * pts[i].dy;
    }
    return sum >= 0 ? 'clockwise' : 'anticlockwise';
  }

  /// Classifies [stroke] as `'topToBottom'`, `'bottomToTop'`,
  /// `'leftToRight'`, or `'rightToLeft'` by comparing the end-point to the
  /// start-point on the dominant axis.
  ///
  /// The dominant axis is vertical when |Δy| > |Δx|, horizontal otherwise.
  String _classifyLinear(Stroke stroke) {
    final pts = stroke.points;
    if (pts.length < 2) return 'topToBottom';
    final dx = pts.last.dx - pts.first.dx;
    final dy = pts.last.dy - pts.first.dy;
    if (dy.abs() > dx.abs()) {
      return dy > 0 ? 'topToBottom' : 'bottomToTop';
    } else {
      return dx > 0 ? 'leftToRight' : 'rightToLeft';
    }
  }

  /// Returns the score for an observed direction against an expected direction.
  ///
  /// Correct match → 1.0; opposite pair → 0.0; any other mismatch → 0.5.
  ///
  /// Opposite pairs:
  /// - `'clockwise'` ↔ `'anticlockwise'`
  /// - `'topToBottom'` ↔ `'bottomToTop'`
  /// - `'leftToRight'` ↔ `'rightToLeft'`
  double _scoreDirections(String expected, String observed) {
    if (expected == observed) return 1.0;
    if (_isOpposite(expected, observed)) return 0.0;
    return 0.5;
  }

  /// Returns `true` when [a] and [b] are a recognised opposite pair.
  bool _isOpposite(String a, String b) {
    return (a == 'clockwise' && b == 'anticlockwise') ||
        (a == 'anticlockwise' && b == 'clockwise') ||
        (a == 'topToBottom' && b == 'bottomToTop') ||
        (a == 'bottomToTop' && b == 'topToBottom') ||
        (a == 'leftToRight' && b == 'rightToLeft') ||
        (a == 'rightToLeft' && b == 'leftToRight');
  }

  /// Builds a plain-English note describing the direction result for one
  /// stroke.
  ///
  /// The note uses "the circle" for circular strokes and "the stroke" for
  /// linear strokes, and uses lower-case direction descriptions to match the
  /// example in the scope document (e.g. "Drew the circle clockwise; should
  /// be drawn anticlockwise.").
  String _buildNote(
    StrokeDirection expectedDir,
    String observed,
    double strokeScore,
  ) {
    final isCircular =
        expectedDir == StrokeDirection.clockwise ||
        expectedDir == StrokeDirection.anticlockwise;
    final subject = isCircular ? 'the circle' : 'the stroke';
    final observedDesc = _describeDirection(observed);
    final expectedDesc = _describeDirection(expectedDir.name);

    if (strokeScore == 1.0) {
      return 'Drew $subject $observedDesc — correct.';
    }
    return 'Drew $subject $observedDesc; should be drawn $expectedDesc.';
  }

  /// Returns a human-readable description for a direction string.
  String _describeDirection(String dir) {
    return switch (dir) {
      'topToBottom' => 'top to bottom',
      'bottomToTop' => 'bottom to top',
      'leftToRight' => 'left to right',
      'rightToLeft' => 'right to left',
      'clockwise' => 'clockwise',
      'anticlockwise' => 'anticlockwise',
      _ => dir,
    };
  }

  /// Builds a learner-facing summary from the scored stroke values.
  String _buildSummary(List<double> scoredValues) {
    if (scoredValues.isEmpty) {
      return 'No direction-scored strokes were found.';
    }
    if (scoredValues.every((s) => s == 1.0)) {
      return 'All strokes were drawn in the correct direction.';
    }
    if (scoredValues.every((s) => s == 0.0)) {
      return 'All strokes were drawn in the wrong direction.';
    }
    return 'One or more strokes were drawn in the wrong direction.';
  }
}
