import 'formation_score.dart';
import 'letter_formation_data.dart';
import 'stroke.dart';

/// Scores whether the learner produced at least the minimum required number
/// of strokes for a letter, as declared by [LetterFormationData.minRequiredStrokes].
///
/// ## Scoring rule
///
/// - actualCount ≥ minRequiredStrokes → 1.0 (over-counting is never penalised).
/// - 0 < actualCount < minRequiredStrokes → actualCount / minRequiredStrokes
///   (proportional partial credit).
/// - actualCount == 0 → 0.0 (defensive; should not occur in practice).
///
/// ## Observations
///
/// A single [StrokeObservation] is produced per call to [score], describing the
/// minimum required count versus the actual observed count. When
/// [LetterFormationData.minRequiredStrokes] is 1, the note explicitly reads
/// "this letter accepts any number of strokes".
class StrokeBreakCounter {
  /// The letter being scored. Used in summaries.
  final String letter;

  /// The expected formation data for the letter.
  final LetterFormationData data;

  /// Creates a [StrokeBreakCounter].
  const StrokeBreakCounter({
    required this.letter,
    required this.data,
  });

  /// Scores [observed] strokes against the minimum required stroke count.
  ///
  /// Returns a [FormationScore] containing:
  /// - [FormationScore.overallScore]: 1.0 if the observed count meets or
  ///   exceeds [LetterFormationData.minRequiredStrokes]; otherwise
  ///   `actualCount / minRequiredStrokes`.
  /// - [FormationScore.observations]: a single [StrokeObservation] (index 0)
  ///   describing the result.
  /// - [FormationScore.summary]: a learner-facing summary sentence.
  FormationScore score(List<Stroke> observed) {
    final actualCount = observed.length;
    final minRequired = data.minRequiredStrokes;

    final double overallScore;
    if (actualCount == 0) {
      overallScore = 0.0;
    } else if (actualCount >= minRequired) {
      overallScore = 1.0;
    } else {
      overallScore = actualCount / minRequired;
    }

    final observation = StrokeObservation(
      strokeIndex: 0,
      expected: '$minRequired',
      observed: '$actualCount',
      score: overallScore,
      note: _buildNote(actualCount, minRequired),
    );

    return FormationScore(
      overallScore: overallScore,
      observations: [observation],
      summary: _buildSummary(actualCount, minRequired, overallScore),
    );
  }

  /// Builds a plain-English note for the stroke count observation.
  String _buildNote(int actualCount, int minRequired) {
    if (minRequired == 1) {
      return 'this letter accepts any number of strokes';
    }
    if (actualCount >= minRequired) {
      return 'Stroke count meets the minimum of $minRequired — correct.';
    }
    return 'Used $actualCount stroke${actualCount == 1 ? '' : 's'}; '
        'at least $minRequired ${minRequired == 1 ? 'is' : 'are'} required.';
  }

  /// Builds a learner-facing summary.
  String _buildSummary(int actualCount, int minRequired, double overallScore) {
    if (minRequired == 1) {
      return 'Stroke count is fine — this letter accepts any number of strokes.';
    }
    if (overallScore == 1.0) {
      return 'Correct number of strokes.';
    }
    return 'Try to use at least $minRequired strokes for this letter.';
  }
}
