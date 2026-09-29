import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/scoring_level.dart';

void main() {
  const bitmap = {
    ScoreKind.coverage,
    ScoreKind.precision,
    ScoreKind.placement,
    ScoreKind.efficiency,
  };

  test('level 1 shows only the four bitmap scores', () {
    expect(visibleScores(ScoringLevel.shapeOnly), bitmap);
  });

  test('level 2 adds start', () {
    expect(visibleScores(ScoringLevel.shapeAndStart), {...bitmap, ScoreKind.start});
  });

  test('level 3 adds path', () {
    expect(visibleScores(ScoringLevel.shapeStartAndPath),
        {...bitmap, ScoreKind.start, ScoreKind.path});
  });

  test('level 4 shows all seven', () {
    expect(visibleScores(ScoringLevel.full), ScoreKind.values.toSet());
    expect(visibleScores(ScoringLevel.full).length, 7);
  });

  test('each level is a superset of the previous one', () {
    for (var i = 1; i < ScoringLevel.values.length; i++) {
      expect(
        visibleScores(ScoringLevel.values[i])
            .containsAll(visibleScores(ScoringLevel.values[i - 1])),
        isTrue,
      );
    }
  });

  test('isScoreVisible agrees with visibleScores', () {
    expect(isScoreVisible(ScoringLevel.shapeOnly, ScoreKind.strokes), isFalse);
    expect(isScoreVisible(ScoringLevel.full, ScoreKind.strokes), isTrue);
  });
}
