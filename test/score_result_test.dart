import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/score_result.dart';

void main() {
  group('ScoreResult', () {
    test('stores all four bitmap fields correctly', () {
      const result = ScoreResult(
        coverage: 0.8,
        precision: 0.7,
        placement: 0.9,
        efficiency: 0.6,
      );

      expect(result.coverage, 0.8);
      expect(result.precision, 0.7);
      expect(result.placement, 0.9);
      expect(result.efficiency, 0.6);
    });

    test('new formation fields default to null when not provided', () {
      const result = ScoreResult(
        coverage: 0.8,
        precision: 0.7,
        placement: 0.9,
        efficiency: 0.6,
      );

      expect(result.strokeStart, isNull);
      expect(result.strokeDirection, isNull);
      expect(result.compoundStroke, isNull);
      expect(result.strokeBreak, isNull);
    });
  });
}
