import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_break_counter.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

/// Helper: creates [count] minimal single-point strokes.
List<Stroke> strokes(int count) =>
    List.generate(count, (_) => Stroke(const [Offset(0, 0)]));

void main() {
  // ---------------------------------------------------------------------------
  // 't' — minRequiredStrokes = 2 (required-lift letter)
  // ---------------------------------------------------------------------------

  group("'t' with minRequiredStrokes = 2", () {
    late StrokeBreakCounter counter;

    setUp(() {
      counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
    });

    test('one stroke → overallScore 0.5', () {
      final result = counter.score(strokes(1));
      expect(result.overallScore, 0.5);
    });

    test('two strokes → overallScore 1.0', () {
      final result = counter.score(strokes(2));
      expect(result.overallScore, 1.0);
    });

    test('three strokes → overallScore 1.0 (over-drawing is fine)', () {
      final result = counter.score(strokes(3));
      expect(result.overallScore, 1.0);
    });

    test('one stroke → single observation produced', () {
      final result = counter.score(strokes(1));
      expect(result.observations.length, 1);
    });

    test('observation expected is the minRequiredStrokes as string', () {
      final result = counter.score(strokes(1));
      expect(result.observations.first.expected, '2');
    });

    test('observation observed is the actualCount as string', () {
      final result = counter.score(strokes(1));
      expect(result.observations.first.observed, '1');
    });

    test('observation note mentions used strokes and required minimum', () {
      final result = counter.score(strokes(1));
      expect(result.observations.first.note, contains('1 stroke'));
      expect(result.observations.first.note, contains('2'));
    });

    test('observation score is 0.5 when one stroke drawn', () {
      final result = counter.score(strokes(1));
      expect(result.observations.first.score, 0.5);
    });

    test('summary asks learner to use at least 2 strokes when below minimum',
        () {
      final result = counter.score(strokes(1));
      expect(result.summary, contains('2'));
    });

    test('summary says correct number when at minimum', () {
      final result = counter.score(strokes(2));
      expect(result.summary, 'Correct number of strokes.');
    });
  });

  // ---------------------------------------------------------------------------
  // 'o' — minRequiredStrokes = 1 (single-stroke letter)
  // ---------------------------------------------------------------------------

  group("'o' with minRequiredStrokes = 1", () {
    late StrokeBreakCounter counter;

    setUp(() {
      counter = StrokeBreakCounter(
        letter: 'o',
        data: letterFormationRegistry['o']!,
      );
    });

    test('one stroke → overallScore 1.0', () {
      final result = counter.score(strokes(1));
      expect(result.overallScore, 1.0);
    });

    test('five strokes → overallScore 1.0 (over-drawing never penalised)', () {
      final result = counter.score(strokes(5));
      expect(result.overallScore, 1.0);
    });

    test('single observation produced', () {
      final result = counter.score(strokes(1));
      expect(result.observations.length, 1);
    });

    test('observation note reads "this letter accepts any number of strokes"',
        () {
      final result = counter.score(strokes(1));
      expect(
        result.observations.first.note,
        'this letter accepts any number of strokes',
      );
    });

    test('observation note for five strokes also reads the optional-lift text',
        () {
      final result = counter.score(strokes(5));
      expect(
        result.observations.first.note,
        'this letter accepts any number of strokes',
      );
    });

    test('summary mentions optional-lift behaviour', () {
      final result = counter.score(strokes(1));
      expect(result.summary, contains('any number of strokes'));
    });
  });

  // ---------------------------------------------------------------------------
  // Revised test list from stroke_formation_scope.md
  // ---------------------------------------------------------------------------

  group('revised test list — scoring formula', () {
    test('actualCount == minRequiredStrokes → 1.0', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      expect(counter.score(strokes(2)).overallScore, 1.0);
    });

    test('actualCount > minRequiredStrokes → 1.0', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      expect(counter.score(strokes(3)).overallScore, 1.0);
    });

    test('extreme over-counting (10× minimum) → 1.0', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      expect(counter.score(strokes(20)).overallScore, 1.0);
    });

    test('actualCount == minRequiredStrokes − 1, min = 2 → 0.5', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      expect(counter.score(strokes(1)).overallScore, 0.5);
    });

    test('actualCount == 1, min = 3 → 0.333…', () {
      // No letter in the registry has minRequiredStrokes = 3, so build a
      // synthetic LetterFormationData. StrokeBreakCounter only reads
      // minRequiredStrokes; the strokes list is unused here.
      final syntheticData = LetterFormationData(
        minRequiredStrokes: 3,
        strokes: [
          ExpectedStroke(
            startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
          ),
          ExpectedStroke(
            startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
          ),
          ExpectedStroke(
            startRect: const StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0),
          ),
        ],
      );
      final counter = StrokeBreakCounter(letter: 'X', data: syntheticData);
      expect(counter.score(strokes(1)).overallScore, closeTo(1 / 3, 1e-9));
    });

    test('actualCount == 0 → 0.0', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      expect(counter.score([]).overallScore, 0.0);
    });

    test('min = 1, actualCount == 1 → 1.0 (common case)', () {
      final counter = StrokeBreakCounter(
        letter: 'o',
        data: letterFormationRegistry['o']!,
      );
      expect(counter.score(strokes(1)).overallScore, 1.0);
    });

    test('min = 1, actualCount == 5 → 1.0 (optional-lift not penalised)', () {
      final counter = StrokeBreakCounter(
        letter: 'o',
        data: letterFormationRegistry['o']!,
      );
      expect(counter.score(strokes(5)).overallScore, 1.0);
    });

    test('result is always in [0.0, 1.0] across various counts', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      for (var n = 0; n <= 10; n++) {
        final score = counter.score(strokes(n)).overallScore;
        expect(score, inInclusiveRange(0.0, 1.0));
      }
    });

    test(
      'result is monotonic up to the minimum and flat at 1.0 thereafter',
      () {
        final counter = StrokeBreakCounter(
          letter: 't',
          data: letterFormationRegistry['t']!,
        );
        const minRequired = 2; // 't'

        final scores = [
          for (var n = 0; n <= 10; n++) counter.score(strokes(n)).overallScore,
        ];

        // Non-decreasing across the full range.
        for (var n = 1; n < scores.length; n++) {
          expect(
            scores[n],
            greaterThanOrEqualTo(scores[n - 1]),
            reason: 'score should not decrease from n=${n - 1} to n=$n',
          );
        }

        // Flat at 1.0 once at or above the minimum.
        for (var n = minRequired; n < scores.length; n++) {
          expect(scores[n], 1.0, reason: 'score(n=$n) should be 1.0');
        }
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Observation shape
  // ---------------------------------------------------------------------------

  group('observation shape', () {
    test('strokeIndex is always 0', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      final result = counter.score(strokes(2));
      expect(result.observations.first.strokeIndex, 0);
    });

    test('observation score equals overallScore', () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      final result = counter.score(strokes(1));
      expect(result.observations.first.score, result.overallScore);
    });
  });
}
