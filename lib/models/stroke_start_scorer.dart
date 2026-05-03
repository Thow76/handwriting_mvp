import 'dart:ui' show Rect;

import 'formation_score.dart';
import 'letter_formation_data.dart';
import 'stroke.dart';
import 'stroke_formation_enums.dart';
import 'stroke_matcher.dart';

/// Scores how closely the observed strokes' first points match the expected
/// start regions defined by [LetterFormationData].
///
/// Each observed stroke's first point is classified into a vertical third of
/// the template's tight bounding box ([StrokeStartRegion.top],
/// [StrokeStartRegion.middle], or [StrokeStartRegion.bottom]) and compared
/// against the expected start region for the matched [ExpectedStroke].
///
/// Scoring per stroke: exact match → 1.0; adjacent mismatch
/// (top↔middle, middle↔bottom) → 0.5; opposite mismatch (top↔bottom) → 0.0.
/// The [FormationScore.overallScore] is the mean across all scored strokes.
///
/// [StrokeStartRegion.bottom] must never appear as an expected value — it is
/// an observed-error-only value per the scope document. The constructor throws
/// an [ArgumentError] if any [ExpectedStroke.startRegion] is
/// [StrokeStartRegion.bottom].
class StrokeStartScorer {
  /// The letter being scored. Used in error messages.
  final String letter;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// The tight bounding box of the letter template.
  ///
  /// Used to divide the vertical extent into thirds for region classification
  /// and for spatial stroke matching.
  final Rect bounds;

  /// Creates a [StrokeStartScorer].
  ///
  /// Throws an [ArgumentError] if any [ExpectedStroke.startRegion] in [data]
  /// is [StrokeStartRegion.bottom].
  StrokeStartScorer({
    required this.letter,
    required this.data,
    required this.bounds,
  }) {
    for (var i = 0; i < data.strokes.length; i++) {
      if (data.strokes[i].startRegion == StrokeStartRegion.bottom) {
        throw ArgumentError(
          'Letter "$letter", stroke $i: ExpectedStroke.startRegion must not be '
          'StrokeStartRegion.bottom — bottom is an observed-error-only value.',
        );
      }
    }
  }

  /// Scores [observed] strokes against the expected start regions.
  ///
  /// Returns a [FormationScore] containing:
  /// - [FormationScore.overallScore]: mean of per-stroke scores.
  /// - [FormationScore.observations]: one [StrokeObservation] per matched,
  ///   non-empty observed stroke.
  /// - [FormationScore.summary]: a learner-facing summary sentence.
  FormationScore score(List<Stroke> observed) {
    final matchIndices = matchStrokes(observed, data.strokes, bounds);
    final observations = <StrokeObservation>[];

    for (var i = 0; i < observed.length; i++) {
      final expectedIndex = matchIndices[i];
      if (expectedIndex == -1) continue;

      final observedRegion = _classifyFirstPoint(observed[i]);
      if (observedRegion == null) continue;

      final expectedRegion = data.strokes[expectedIndex].startRegion;
      final strokeScore = _scoreRegions(expectedRegion, observedRegion);

      observations.add(StrokeObservation(
        strokeIndex: i,
        expected: expectedRegion.name,
        observed: observedRegion.name,
        score: strokeScore,
        note: _buildNote(expectedRegion, observedRegion),
      ));
    }

    final overallScore = observations.isEmpty
        ? 0.0
        : observations.map((o) => o.score).reduce((a, b) => a + b) /
            observations.length;

    return FormationScore(
      overallScore: overallScore,
      observations: observations,
      summary: _buildSummary(observations),
    );
  }

  /// Classifies the first point of [stroke] into a [StrokeStartRegion] based
  /// on the vertical thirds of [bounds].
  ///
  /// Returns `null` if the stroke has no points.
  StrokeStartRegion? _classifyFirstPoint(Stroke stroke) {
    if (stroke.points.isEmpty) return null;
    final dy = stroke.points.first.dy - bounds.top;
    final thirdH = bounds.height / 3;
    if (dy < thirdH) return StrokeStartRegion.top;
    if (dy < thirdH * 2) return StrokeStartRegion.middle;
    return StrokeStartRegion.bottom;
  }

  /// Returns a score for [observed] relative to [expected].
  ///
  /// Exact match → 1.0; adjacent mismatch (top↔middle, middle↔bottom) → 0.5;
  /// opposite mismatch (top↔bottom) → 0.0.
  double _scoreRegions(StrokeStartRegion expected, StrokeStartRegion observed) {
    if (expected == observed) return 1.0;
    if ((expected == StrokeStartRegion.top &&
            observed == StrokeStartRegion.bottom) ||
        (expected == StrokeStartRegion.bottom &&
            observed == StrokeStartRegion.top)) {
      return 0.0;
    }
    return 0.5;
  }

  /// Builds a learner-readable note describing the result for one stroke.
  String _buildNote(StrokeStartRegion expected, StrokeStartRegion observed) {
    if (expected == observed) {
      return 'Started in the ${expected.name} region — correct.';
    }
    return 'Started at the ${observed.name}; should start at the ${expected.name}.';
  }

  /// Builds a learner-facing summary from all [observations].
  String _buildSummary(List<StrokeObservation> observations) {
    if (observations.isEmpty) {
      return 'No strokes were examined.';
    }
    if (observations.every((o) => o.score == 1.0)) {
      return 'All strokes started in the right place.';
    }
    final wrong = observations.firstWhere((o) => o.score < 1.0);
    return 'The stroke started in the wrong place — try starting at the ${wrong.expected}.';
  }
}
