/// The result of evaluating a single stroke against its expected behaviour.
///
/// Used by all four formation scorers to record what was expected, what was
/// observed, the per-stroke score, and a plain-language explanation.
///
/// [expected] and [observed] are plain strings rather than enum values so the
/// same class can carry single-value comparisons (e.g. "top") as well as
/// waypoint sequences (e.g. "top → bottomLeft → top").
class StrokeObservation {
  /// Zero-based index of the stroke being described.
  final int strokeIndex;

  /// What the scoring rule required for this stroke.
  final String expected;

  /// What the learner's stroke actually showed.
  final String observed;

  /// Per-stroke score in the range 0.0–1.0.
  final double score;

  /// Plain-language explanation of the result, suitable for learner display.
  final String note;

  const StrokeObservation({
    required this.strokeIndex,
    required this.expected,
    required this.observed,
    required this.score,
    required this.note,
  });
}

/// The complete output returned by a formation scorer.
///
/// Aggregates the per-stroke [observations] into an [overallScore] and a
/// short learner-facing [summary] sentence.
class FormationScore {
  /// Headline score for the whole letter, in the range 0.0–1.0.
  final double overallScore;

  /// One [StrokeObservation] per stroke that was examined.
  final List<StrokeObservation> observations;

  /// One or two sentences describing the overall result for the learner.
  final String summary;

  const FormationScore({
    required this.overallScore,
    required this.observations,
    required this.summary,
  });
}
