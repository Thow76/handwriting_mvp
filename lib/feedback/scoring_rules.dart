import '../models/letter_formation_registry.dart';
import '../models/score_result.dart';
import '../models/scoring_level.dart';
import 'feedback_strings.dart';

/// An average at or above this is "Okay" (below it is "More practice").
const okayFrom = 0.50;

/// An average at or above this is "Good".
const goodFrom = 0.75;

/// A ring is drawn this far short of a band line when a guardrail pulls the
/// band down, so it never looks fuller than the word beside it.
const _ringGap = 0.01;

/// What the learner is told for one attempt, and why.
class BandVerdict {
  const BandVerdict({
    required this.band,
    required this.average,
    this.reason,
    this.shortReason,
  });

  /// The word the learner sees.
  final FeedbackBand band;

  /// The mean of the scores counted at the level (before any guardrail).
  final double average;

  /// Plain-English reason when a guardrail changed the band, else null.
  final String? reason;

  /// [reason] boiled down for the tester's Copy line, else null.
  final String? shortReason;

  /// How full to draw the score ring: the [average], held below the line of
  /// the next band up when a guardrail lowered the band.
  double get ringFill {
    if (reason == null) return average;
    final cap = switch (band) {
      FeedbackBand.morePractice => okayFrom - _ringGap,
      FeedbackBand.okay => goodFrom - _ringGap,
      FeedbackBand.good => 1.0,
    };
    return average < cap ? average : cap;
  }
}

/// Decides the band for [result] at [level] for [letter].
///
/// In order:
/// 1. Completion guardrail (every level): a letter with an empty zone is
///    "More practice".
/// 2. The average of the scores counted at the level. Strokes is left out when
///    the letter needs only one stroke, because lifting the pen is optional
///    there.
/// 3. Formation guardrail: where Start or Path counts, getting one wrong
///    means "Okay" at best.
BandVerdict judgeAttempt(
  ScoreResult result,
  ScoringLevel level,
  String letter,
) {
  final scores = permittedScores(result, level);
  if (letterFormationRegistry[letter]?.minRequiredStrokes == 1) {
    scores.remove(ScoreKind.strokes);
  }
  final average = scores.isEmpty
      ? 0.0
      : scores.values.reduce((a, b) => a + b) / scores.length;
  final averageBand = bandFor(average);

  final completion = result.completion;
  if (completion != null && !completion.complete) {
    final changed = averageBand != FeedbackBand.morePractice;
    return BandVerdict(
      band: FeedbackBand.morePractice,
      average: average,
      reason: changed
          ? 'Letter not finished '
                '(no ink in zone ${completion.missingSections.join(', ')})'
          : null,
      shortReason: changed ? 'letter not finished' : null,
    );
  }

  final wrong = [
    if ((scores[ScoreKind.start] ?? 1.0) < 1.0) 'Start point',
    if ((scores[ScoreKind.path] ?? 1.0) < 1.0) 'Path',
  ];
  if (wrong.isNotEmpty && averageBand == FeedbackBand.good) {
    return BandVerdict(
      band: FeedbackBand.okay,
      average: average,
      reason: '${wrong.join(' was wrong; ')} was wrong',
      shortReason: '${wrong.join(' was wrong; ').toLowerCase()} was wrong',
    );
  }

  return BandVerdict(band: averageBand, average: average);
}
