/// Holds the coverage, precision and placement scores for a handwriting attempt.
class ScoreResult {
  /// Fraction of the reference shape covered by the user's strokes (0.0–1.0).
  final double coverage;

  /// Fraction of the user's strokes that fall inside the reference shape (0.0–1.0).
  final double precision;

  /// How closely the user's strokes match the expected vertical zone (0.0–1.0).
  final double placement;

  /// Ratio of ideal path length to actual path length (0.0–1.0).
  /// High efficiency means the user traced cleanly without excessive movement.
  final double efficiency;

  const ScoreResult({
    required this.coverage,
    required this.precision,
    required this.placement,
    required this.efficiency,
  });
}
