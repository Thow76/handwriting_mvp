import 'dart:ui' show Rect;

import 'formation_score.dart';
import 'letter_formation_data.dart';
import 'match_waypoints.dart';
import 'stroke.dart';
import 'stroke_formation_enums.dart';
import 'stroke_matcher.dart';

/// Scores whether each compound stroke visits the expected [WaypointRegion]
/// cells in the correct order, as defined by [LetterFormationData].
///
/// For each observed stroke that is matched to a compound expected stroke,
/// [matchWaypoints] is called to scan the stroke's point stream and find how
/// many waypoints were hit in sequence.  The per-stroke score is
/// `hitCount / waypoints.length`.  The [FormationScore.overallScore] is the
/// mean of all per-compound-stroke scores.
///
/// Non-compound strokes that are matched to compound expected strokes are
/// treated as a score of 0.0.  Compound expected strokes with no waypoints
/// defined also score 0.0.
///
/// ## Tolerance
///
/// Tolerance is `defaultToleranceFraction × min(cellWidth, cellHeight)` where
/// the cell dimensions come from dividing [bounds] into a 3×3 grid.  The
/// fraction is exposed as [defaultToleranceFraction] so callers can read or
/// override it.
class CompoundStrokeScorer {
  /// Default fraction of the smaller cell dimension used as the hit-zone
  /// radius for waypoint matching.
  ///
  /// Value of 0.5 means the hit zone diameter equals one full cell — forgiving
  /// enough to handle natural wobble without being so loose that adjacent cells
  /// bleed into each other.
  static const double defaultToleranceFraction = 0.5;

  /// The letter being scored. Used in observations and summaries.
  final String letter;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// The tight bounding box of the letter template.
  ///
  /// Used for spatial stroke matching and tolerance computation.
  final Rect bounds;

  /// Fraction of the smaller cell dimension used as the hit-zone radius.
  ///
  /// Defaults to [defaultToleranceFraction].
  final double toleranceFraction;

  /// Creates a [CompoundStrokeScorer].
  const CompoundStrokeScorer({
    required this.letter,
    required this.data,
    required this.bounds,
    this.toleranceFraction = defaultToleranceFraction,
  });

  /// Scores [observed] strokes against the expected compound waypoint
  /// sequences.
  ///
  /// Returns a [FormationScore] containing:
  /// - [FormationScore.overallScore]: mean of per-compound-stroke scores
  ///   (0.0 when no compound strokes are present).
  /// - [FormationScore.observations]: one [StrokeObservation] per observed
  ///   stroke that was matched to a compound expected stroke.
  /// - [FormationScore.summary]: a learner-facing summary sentence.
  FormationScore score(List<Stroke> observed) {
    final matchIndices = matchStrokes(observed, data.strokes, bounds);
    final observations = <StrokeObservation>[];
    final scoredValues = <double>[];

    for (var i = 0; i < observed.length; i++) {
      final expectedIndex = matchIndices[i];
      if (expectedIndex == -1) continue;

      final expected = data.strokes[expectedIndex];
      if (expected.primaryDirection != StrokeDirection.compound) continue;

      final waypoints = expected.waypoints;
      if (waypoints.isEmpty) {
        observations.add(StrokeObservation(
          strokeIndex: i,
          expected: 'compound (no waypoints)',
          observed: 'compound',
          score: 0.0,
          note: 'Compound stroke has no waypoints defined — score is 0.',
        ));
        scoredValues.add(0.0);
        continue;
      }

      final result = matchWaypoints(
        observed[i].points,
        waypoints,
        bounds,
        toleranceFraction: toleranceFraction,
      );

      final strokeScore = result.hitCount / waypoints.length;
      scoredValues.add(strokeScore);

      final expectedStr =
          waypoints.map((w) => w.name).join(' → ');
      final hitLabels = result.hits
          .map((h) => h.isHit ? h.waypoint.name : '(missed ${h.waypoint.name})')
          .join(' → ');

      observations.add(StrokeObservation(
        strokeIndex: i,
        expected: expectedStr,
        observed: hitLabels,
        score: strokeScore,
        note: _buildNote(result.hitCount, waypoints.length),
      ));
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

  /// Builds a plain-English note for one compound stroke.
  String _buildNote(int hits, int total) {
    if (hits == total) {
      return 'All $total waypoints hit in the correct order — correct.';
    }
    if (hits == 0) {
      return 'No waypoints were hit in the expected sequence.';
    }
    final missed = total - hits;
    return '$hits of $total waypoints hit; $missed missed or out of order.';
  }

  /// Builds a learner-facing summary from the per-stroke scored values.
  String _buildSummary(List<double> scoredValues) {
    if (scoredValues.isEmpty) {
      return 'No compound strokes were found to score.';
    }
    if (scoredValues.every((s) => s == 1.0)) {
      return 'All compound strokes followed the correct path.';
    }
    if (scoredValues.every((s) => s == 0.0)) {
      return 'No compound strokes followed the correct path.';
    }
    return 'One or more compound strokes did not follow the correct path.';
  }
}
