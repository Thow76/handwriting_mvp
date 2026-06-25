import 'dart:ui' show Rect;

import 'formation_score.dart';
import 'letter_formation_data.dart';
import 'match_waypoint_sections.dart';
import 'stroke.dart';
import 'stroke_matcher.dart';

/// Scores whether each section-scored stroke visits the expected
/// [WaypointSection] rectangles in the correct order, as defined by
/// [LetterFormationData].
///
/// This is the section-based counterpart to [CompoundStrokeScorer] (which uses
/// the shared 3×3 [WaypointRegion] grid). It evaluates the new per-letter
/// rectangular sections introduced by the `WaypointSection` migration.
///
/// For each observed stroke matched to an [ExpectedStroke] with a non-empty
/// `sections` list, [matchWaypointSections] is called to scan the stroke's
/// point stream and find how many sections were hit in sequential order.
/// The per-stroke score is `hitCount / sections.length` (partial credit for
/// the in-order prefix). The [FormationScore.overallScore] is the mean of all
/// per-section-stroke scores.
///
/// When the letter has no section-scored expected strokes, returns vacuously
/// correct (`overallScore: 1.0`), matching [CompoundStrokeScorer]'s convention.
class WaypointSectionScorer {
  /// The letter being scored. Used in observations and summaries.
  final String letter;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// The tight bounding box of the letter template.
  ///
  /// Used for spatial stroke matching and section rectangle mapping.
  final Rect bounds;

  /// Creates a [WaypointSectionScorer].
  const WaypointSectionScorer({
    required this.letter,
    required this.data,
    required this.bounds,
  });

  /// Scores [observed] strokes against expected section sequences.
  ///
  /// Returns a [FormationScore] containing:
  /// - [FormationScore.overallScore]: mean of per-section-stroke scores.
  ///   Returns 1.0 when the letter has no section-scored expected strokes.
  /// - [FormationScore.observations]: one [StrokeObservation] per observed
  ///   stroke that was matched to a section-scored expected stroke.
  /// - [FormationScore.summary]: a learner-facing summary sentence.
  FormationScore score(List<Stroke> observed) {
    // If the letter definition has no section-scored expected strokes there is
    // nothing for this scorer to evaluate — vacuously correct.
    final hasSectionStrokes = data.strokes.any((s) => s.sections.isNotEmpty);
    if (!hasSectionStrokes) {
      return const FormationScore(
        overallScore: 1.0,
        observations: [],
        summary: 'No section-scored strokes in this letter.',
      );
    }

    final matchIndices = matchStrokes(observed, data.strokes, bounds);
    final observations = <StrokeObservation>[];
    final scoredValues = <double>[];

    for (var i = 0; i < observed.length; i++) {
      final expectedIndex = matchIndices[i];
      if (expectedIndex == -1) continue;

      final expected = data.strokes[expectedIndex];
      if (expected.sections.isEmpty) continue;

      final sections = expected.sections;
      final result = matchWaypointSections(
        observed[i].points,
        sections,
        bounds,
      );

      final strokeScore = result.hitCount / sections.length;
      scoredValues.add(strokeScore);

      final expectedStr =
          sections.map((s) => 'section ${s.number}').join(' → ');
      final hitLabels = result.hits
          .map((h) =>
              h.isHit ? 'section ${h.section.number}' : '[missed section ${h.section.number}]')
          .join(' → ');

      observations.add(
        StrokeObservation(
          strokeIndex: i,
          expected: expectedStr,
          observed: hitLabels,
          score: strokeScore,
          note: _buildNote(result.hitCount, sections.length),
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

  /// Builds a plain-English note for one section-scored stroke.
  String _buildNote(int hits, int total) {
    if (hits == total) {
      return 'All $total sections hit in the correct order — correct.';
    }
    if (hits == 0) {
      return 'No sections were hit in the expected sequence.';
    }
    final missed = total - hits;
    return '$hits of $total sections hit; $missed missed or out of order.';
  }

  /// Builds a learner-facing summary from the per-stroke scored values.
  String _buildSummary(List<double> scoredValues) {
    if (scoredValues.isEmpty) {
      return 'No section-scored strokes were found to score.';
    }
    if (scoredValues.every((s) => s == 1.0)) {
      return 'All section-scored strokes followed the correct path.';
    }
    if (scoredValues.every((s) => s == 0.0)) {
      return 'No section-scored strokes followed the correct path.';
    }
    return 'One or more section-scored strokes did not follow the correct path.';
  }
}
