/// Holds the coverage and precision scores for a handwriting attempt.
class ScoreResult {
  /// Fraction of the reference shape covered by the user's strokes (0.0–1.0).
  final double coverage;

  /// Fraction of the user's strokes that fall inside the reference shape (0.0–1.0).
  final double precision;

  const ScoreResult({required this.coverage, required this.precision});
}
