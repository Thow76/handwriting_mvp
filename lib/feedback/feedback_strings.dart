import '../models/score_result.dart';
import '../models/scoring_level.dart';
import 'scoring_rules.dart' show goodFrom, okayFrom;

/// The three words a learner can be told. Never a number.
enum FeedbackBand { morePractice, okay, good }

/// A score at or above this counts as "done well" for the one-line note.
const _noteGoodFrom = goodFrom;

extension FeedbackBandLabel on FeedbackBand {
  String get word => switch (this) {
    FeedbackBand.morePractice => 'More practice',
    FeedbackBand.okay => 'Okay',
    FeedbackBand.good => 'Good',
  };
}

/// The band for a plain average, using the lines in `scoring_rules.dart`.
/// Screens use `judgeAttempt` instead, which also applies the guardrails.
FeedbackBand bandFor(double overall) {
  if (overall >= goodFrom) return FeedbackBand.good;
  if (overall >= okayFrom) return FeedbackBand.okay;
  return FeedbackBand.morePractice;
}

/// Note shown for each formation score: [needsWork] when it is the weakest
/// thing and below the Good line, [done] when it is the weakest but fine.
class FeedbackNote {
  const FeedbackNote(this.needsWork, this.done);
  final String needsWork;
  final String done;
}

const feedbackNotes = <ScoreKind, FeedbackNote>{
  ScoreKind.start: FeedbackNote(
    'Start point: try beginning at the dot at the top of the letter',
    'Start point: you began in the right place',
  ),
  ScoreKind.path: FeedbackNote(
    'Path: follow the shape of the letter step by step',
    'Path: you followed the shape of the letter',
  ),
  ScoreKind.strokes: FeedbackNote(
    'Strokes: check where the pen should lift',
    'Strokes: pen lifted in the right places',
  ),
};

/// The scores for [kind] in [result], or null when it does not apply.
double? scoreOf(ScoreResult result, ScoreKind kind) => switch (kind) {
  ScoreKind.coverage => result.coverage,
  ScoreKind.precision => result.precision,
  ScoreKind.placement => result.placement,
  ScoreKind.efficiency => result.efficiency,
  ScoreKind.start => result.strokeStart?.overallScore,
  ScoreKind.path => result.compoundStroke?.overallScore,
  ScoreKind.strokes => result.strokeBreak?.overallScore,
};

/// Scores permitted at [level] that exist in [result].
Map<ScoreKind, double> permittedScores(ScoreResult result, ScoringLevel level) {
  final out = <ScoreKind, double>{};
  for (final kind in ScoreKind.values) {
    if (!isScoreVisible(level, kind)) continue;
    final v = scoreOf(result, kind);
    if (v != null) out[kind] = v;
  }
  return out;
}

/// The mean of the scores permitted at [level].
double overallScore(ScoreResult result, ScoringLevel level) {
  final scores = permittedScores(result, level).values;
  if (scores.isEmpty) return 0;
  return scores.reduce((a, b) => a + b) / scores.length;
}

/// One line naming the weakest thing checked at [level], or null when the
/// weakest score is a bitmap score (start / path / strokes only get notes).
String? feedbackNote(ScoreResult result, ScoringLevel level) {
  final scores = permittedScores(result, level);
  ScoreKind? weakest;
  for (final entry in scores.entries) {
    // Strict "<" keeps the earlier kind on a tie, so bitmap scores win ties.
    if (weakest == null || entry.value < scores[weakest]!) {
      weakest = entry.key;
    }
  }
  final note = weakest == null ? null : feedbackNotes[weakest];
  if (note == null) return null;
  return scores[weakest]! >= _noteGoodFrom ? note.done : note.needsWork;
}
