import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/feedback/feedback_strings.dart';
import 'package:handwriting_mvp/feedback/scoring_rules.dart';
import 'package:handwriting_mvp/models/completion_checker.dart';
import 'package:handwriting_mvp/models/formation_score.dart';
import 'package:handwriting_mvp/models/score_result.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';

FormationScore _fs(double v) =>
    FormationScore(overallScore: v, observations: const [], summary: '');

const _complete = CompletionResult(complete: true, missingSections: []);
const _missing567 = CompletionResult(
  complete: false,
  missingSections: [5, 6, 7],
);

ScoreResult _result({
  double bitmap = 0.95,
  double? start,
  double? path,
  double? strokes,
  CompletionResult? completion = _complete,
}) => ScoreResult(
  coverage: bitmap,
  precision: bitmap,
  placement: bitmap,
  efficiency: bitmap,
  strokeStart: start == null ? null : _fs(start),
  compoundStroke: path == null ? null : _fs(path),
  strokeBreak: strokes == null ? null : _fs(strokes),
  completion: completion,
);

void main() {
  test('the two lines live in scoring_rules.dart', () {
    expect(okayFrom, 0.50);
    expect(goodFrom, 0.75);
  });

  group('completion guardrail', () {
    test(
      'level 1, all bitmap 0.90+, not complete: More practice with reason',
      () {
        final v = judgeAttempt(
          _result(bitmap: 0.90, completion: _missing567),
          ScoringLevel.shapeOnly,
          'a',
        );
        expect(v.band, FeedbackBand.morePractice);
        expect(v.reason, 'Letter not finished (no ink in zone 5, 6, 7)');
        expect(v.average, closeTo(0.90, 1e-9));
      },
    );

    test('level 1, same scores, complete: Good with no reason', () {
      final v = judgeAttempt(
        _result(bitmap: 0.90),
        ScoringLevel.shapeOnly,
        'a',
      );
      expect(v.band, FeedbackBand.good);
      expect(v.reason, isNull);
    });

    test('applies at every level', () {
      for (final level in ScoringLevel.values) {
        final v = judgeAttempt(
          _result(start: 1, path: 1, strokes: 1, completion: _missing567),
          level,
          'a',
        );
        expect(v.band, FeedbackBand.morePractice, reason: '$level');
      }
    });

    test('already More practice by average: no reason (nothing changed)', () {
      final v = judgeAttempt(
        _result(bitmap: 0.2, completion: _missing567),
        ScoringLevel.shapeOnly,
        'a',
      );
      expect(v.band, FeedbackBand.morePractice);
      expect(v.reason, isNull);
    });

    test(
      'no completion data (letter without formation data): no guardrail',
      () {
        final v = judgeAttempt(
          _result(completion: null),
          ScoringLevel.shapeOnly,
          'a',
        );
        expect(v.band, FeedbackBand.good);
      },
    );
  });

  group('formation guardrail', () {
    test('level 3, Start 1.0 and Path 0.0: Okay with the path reason', () {
      final v = judgeAttempt(
        _result(start: 1.0, path: 0.0),
        ScoringLevel.shapeStartAndPath,
        'a',
      );
      expect(v.band, FeedbackBand.okay);
      expect(v.reason, 'Path was wrong');
    });

    test('level 3, Start 0.0 and Path 1.0: Okay with the start reason', () {
      final v = judgeAttempt(
        _result(start: 0.0, path: 1.0),
        ScoringLevel.shapeStartAndPath,
        'a',
      );
      expect(v.band, FeedbackBand.okay);
      expect(v.reason, 'Start point was wrong');
    });

    test('both wrong: the average is already Okay, so no reason is needed', () {
      final v = judgeAttempt(
        _result(bitmap: 1.0, start: 0.0, path: 0.0),
        ScoringLevel.shapeStartAndPath,
        'a',
      );
      expect(v.band, FeedbackBand.okay);
      expect(v.reason, isNull);
    });

    test('Start is not checked at level 1; Path is not checked at level 2', () {
      expect(
        judgeAttempt(
          _result(start: 0, path: 0),
          ScoringLevel.shapeOnly,
          'a',
        ).band,
        FeedbackBand.good,
      );
      final l2 = judgeAttempt(
        _result(start: 1, path: 0),
        ScoringLevel.shapeAndStart,
        'a',
      );
      expect(l2.band, FeedbackBand.good);
      expect(l2.reason, isNull);
    });

    test('does not lift a band that is already lower', () {
      final v = judgeAttempt(
        _result(bitmap: 0.4, start: 0, path: 0),
        ScoringLevel.shapeStartAndPath,
        'a',
      );
      expect(v.band, FeedbackBand.morePractice);
      expect(v.reason, isNull);
    });
  });

  group('the average', () {
    test('level 4, one-stroke letter: Strokes is left out', () {
      // a needs only one stroke.
      final v = judgeAttempt(
        _result(bitmap: 1, start: 1, path: 1, strokes: 0),
        ScoringLevel.full,
        'a',
      );
      expect(v.average, closeTo(1.0, 1e-9));
      expect(v.band, FeedbackBand.good);
    });

    test('level 4, two-stroke letter: Strokes is in the average', () {
      // f needs two strokes.
      final v = judgeAttempt(
        _result(bitmap: 1, start: 1, path: 1, strokes: 0),
        ScoringLevel.full,
        'f',
      );
      expect(v.average, closeTo(6 / 7, 1e-9));
    });

    test('unknown letter: Strokes stays in the average', () {
      final v = judgeAttempt(
        _result(bitmap: 1, start: 1, path: 1, strokes: 0),
        ScoringLevel.full,
        '?',
      );
      expect(v.average, closeTo(6 / 7, 1e-9));
    });
  });

  group('ring fill', () {
    test('is the average when nothing changed', () {
      final v = judgeAttempt(_result(bitmap: 0.9), ScoringLevel.shapeOnly, 'a');
      expect(v.ringFill, closeTo(0.9, 1e-9));
    });

    test('More practice by guardrail stays below the Okay line', () {
      final v = judgeAttempt(
        _result(bitmap: 0.9, completion: _missing567),
        ScoringLevel.shapeOnly,
        'a',
      );
      expect(v.ringFill, lessThan(okayFrom));
    });

    test('Okay by guardrail stays below the Good line', () {
      final v = judgeAttempt(
        _result(bitmap: 0.95, start: 1, path: 0),
        ScoringLevel.shapeStartAndPath,
        'a',
      );
      expect(v.ringFill, lessThan(goodFrom));
      expect(bandFor(v.ringFill), FeedbackBand.okay);
    });
  });
}
