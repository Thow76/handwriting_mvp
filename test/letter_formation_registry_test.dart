import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Single-stroke letters — table-driven lookup tests
  //
  // Asserts that:
  //   1. Each letter has a non-null entry in the registry.
  //   2. minRequiredStrokes == 1.
  //   3. Exactly one ExpectedStroke is present.
  //   4. The stroke's primaryDirection matches the Universal Core table.
  //   5. The stroke's startRegion is top.
  // ---------------------------------------------------------------------------

  const cases = {
    'c': StrokeDirection.anticlockwise,
    'e': StrokeDirection.anticlockwise,
    'l': StrokeDirection.topToBottom,
    'o': StrokeDirection.anticlockwise,
    // s uses topToBottom as an interim placeholder — see registry comment.
    's': StrokeDirection.topToBottom,
    'v': StrokeDirection.topToBottom,
    'w': StrokeDirection.topToBottom,
    'z': StrokeDirection.topToBottom,
  };

  group('letterFormationRegistry — single-stroke letters', () {
    for (final entry in cases.entries) {
      final letter = entry.key;
      final expectedDirection = entry.value;

      test('$letter: entry is non-null', () {
        expect(letterFormationRegistry[letter], isNotNull);
      });

      test('$letter: minRequiredStrokes == 1', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.minRequiredStrokes, 1);
      });

      test('$letter: has exactly one ExpectedStroke', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes, hasLength(1));
        expect(data.canonicalStrokeCount, 1);
      });

      test('$letter: primaryDirection is $expectedDirection', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes.first.primaryDirection, expectedDirection);
      });

      test('$letter: startRegion is top', () {
        final data = letterFormationRegistry[letter]!;
        expect(data.strokes.first.startRegion, StrokeStartRegion.top);
      });
    }
  });
}
