/// Result of scoring a user's drawing against a letter template in Recall mode.
///
/// Always contains 3 category scores + a combined score + feedback message.
/// The third score is either Proportion (full guidelines) or Size (baseline
/// only), determined by the active guideline mode.
class ScoringResult {
  const ScoringResult({
    required this.shapeScore,
    required this.placementScore,
    required this.thirdScore,
    required this.thirdScoreLabel,
    required this.combinedScore,
    required this.feedbackMessage,
    this.rawErrors = const {},
  });

  /// Shape accuracy — how close the drawn form matches the template (1–10).
  final int shapeScore;

  /// Baseline placement — correct vertical position on the guidelines (1–10).
  final int placementScore;

  /// Either Proportion or Size consistency, depending on guideline mode (1–10).
  final int thirdScore;

  /// "Proportion" or "Size" — label for display.
  final String thirdScoreLabel;

  /// Average of the three category scores, rounded (1–10).
  final int combinedScore;

  /// Encouraging feedback based on the combined score.
  final String feedbackMessage;

  /// Raw error values for each category (for debugging / calibration).
  final Map<String, double> rawErrors;

  /// Map combined score → encouragement message.
  static String messageForScore(int score) {
    if (score <= 4) return 'Good try — more practice!';
    if (score <= 6) return 'Getting there — keep practising!';
    if (score <= 9) return 'Well done — your practice is paying off!';
    return 'Excellent — all your hard work has been worth it!';
  }
}
