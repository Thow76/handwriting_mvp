import 'dart:ui' show Offset, Rect;

import 'formation_score.dart';
import 'letter_formation_data.dart';
import 'match_waypoint_sections.dart';
import 'stroke.dart';

/// Scores whether the learner's pen travelled through the letter's expected
/// [WaypointSection] rectangles in the correct sequential order.
///
/// This is the section-based counterpart to [CompoundStrokeScorer] (which uses
/// the shared 3×3 [WaypointRegion] grid). It evaluates the bespoke per-letter
/// rectangles introduced by the `WaypointSection` migration.
///
/// ## One path per letter
///
/// The letter's full ordered section sequence is gathered across **all** its
/// expected strokes (sorted by [WaypointSection.number]), and every observed
/// point is concatenated in drawing order into a single stream. Matching runs
/// **once** over that stream. A letter drawn with a pen-lift and the same
/// letter drawn as one continuous stroke therefore score identically — whether
/// a lift was required is judged separately by [StrokeBreakCounter], and where
/// strokes start by [StrokeStartScorer].
///
/// ## All-or-nothing
///
/// The path score is `1.0` only when every section is hit in the correct
/// sequential order (`hitCount == sections.length`), and `0.0` otherwise. There
/// is no partial credit for a correct in-order prefix — completing 3 of 6
/// sections scores `0.0`, not `0.5`.
///
/// [matchWaypointSections] still reports the full `hitCount` and per-section hit
/// detail, which the debug view uses to show where the sequence broke; only the
/// pass/fail decision lives here in the scorer.
///
/// When the letter has no sections, returns vacuously correct
/// (`overallScore: 1.0`), matching [CompoundStrokeScorer]'s convention.
class WaypointSectionScorer {
  /// The letter being scored. Used in observations and summaries.
  final String letter;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// The tight bounding box of the letter template.
  ///
  /// Used to map each section's fractional rectangle into absolute coordinates.
  final Rect bounds;

  /// Creates a [WaypointSectionScorer].
  const WaypointSectionScorer({
    required this.letter,
    required this.data,
    required this.bounds,
  });

  /// Scores [observed] strokes against the letter's expected section sequence.
  ///
  /// Returns a [FormationScore] containing:
  /// - [FormationScore.overallScore]: `1.0` if the whole letter path was
  ///   completed in order, else `0.0`. `1.0` when the letter has no sections.
  /// - [FormationScore.observations]: a single observation describing the
  ///   letter's section path and where (if anywhere) it broke.
  /// - [FormationScore.summary]: a learner-facing summary sentence.
  FormationScore score(List<Stroke> observed) {
    // Gather the letter's full ordered section sequence across every expected
    // stroke. The path is one sequence for the whole letter, independent of how
    // many strokes (pen-lifts) it is decomposed into.
    final sections = data.strokes.expand((s) => s.sections).toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    // No sections to evaluate — vacuously correct.
    if (sections.isEmpty) {
      return const FormationScore(
        overallScore: 1.0,
        observations: [],
        summary: 'No section-scored path in this letter.',
      );
    }

    // Concatenate every observed point in drawing order into one stream, so a
    // connected (no-lift) letter and a lifted letter are scored identically.
    final points = <Offset>[for (final s in observed) ...s.points];

    final result = matchWaypointSections(points, sections, bounds);
    final passed = result.hitCount == sections.length;
    final pathScore = passed ? 1.0 : 0.0;

    final expectedStr = sections.map((s) => 'section ${s.number}').join(' → ');
    final observedStr = result.hits
        .map((h) => h.isHit
            ? 'section ${h.section.number}'
            : '[missed section ${h.section.number}]')
        .join(' → ');

    return FormationScore(
      overallScore: pathScore,
      observations: [
        StrokeObservation(
          strokeIndex: 0,
          expected: expectedStr,
          observed: observedStr,
          score: pathScore,
          note: _buildNote(result.hitCount, sections.length),
        ),
      ],
      summary: passed
          ? 'The letter path followed the correct section sequence.'
          : 'The letter path did not follow the correct section sequence.',
    );
  }

  /// Builds a plain-English note for the letter's section path.
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
}
