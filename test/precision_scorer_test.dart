import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/precision_scorer.dart';

/// Helper to build a pixel grid from a visual string representation.
/// '#' = ink present (true), '.' = empty (false).
List<List<bool>> grid(List<String> rows) {
  return rows.map((row) => row.split('').map((c) => c == '#').toList()).toList();
}

void main() {
  group('PrecisionScorer', () {
    // ---------------------------------------------------------------
    // Core behaviour
    // ---------------------------------------------------------------

    test('all stroke pixels inside reference → 100% precision', () {
      final reference = grid([
        '.####.',
        '.####.',
        '.####.',
      ]);
      final strokes = grid([
        '..##..',
        '..##..',
        '..##..',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        1.0,
      );
    });

    test('all stroke pixels outside reference → 0% precision', () {
      final reference = grid([
        '##..',
        '##..',
      ]);
      final strokes = grid([
        '..##',
        '..##',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.0,
      );
    });

    test('half of stroke pixels inside reference → 50% precision', () {
      final reference = grid([
        '##..',
        '##..',
      ]);
      final strokes = grid([
        '.##.',
        '.##.',
      ]);
      // 2 of 4 stroke pixels overlap with reference
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.5,
      );
    });

    test('scribble everywhere — low precision despite full coverage', () {
      final reference = grid([
        '.##.',
        '.##.',
      ]);
      final strokes = grid([
        '####',
        '####',
      ]);
      // 4 of 8 stroke pixels are inside reference
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.5,
      );
    });

    test('identical masks → 100% precision', () {
      final mask = grid([
        '..##..',
        '.####.',
        '..##..',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: mask, strokeMask: mask),
        1.0,
      );
    });

    // ---------------------------------------------------------------
    // Edge cases
    // ---------------------------------------------------------------

    test('no strokes drawn → 0% precision', () {
      final reference = grid([
        '##',
        '##',
      ]);
      final strokes = grid([
        '..',
        '..',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.0,
      );
    });

    test('single stroke pixel inside reference → 100%', () {
      final reference = grid([
        '.#.',
      ]);
      final strokes = grid([
        '.#.',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        1.0,
      );
    });

    test('single stroke pixel outside reference → 0%', () {
      final reference = grid([
        '.#.',
      ]);
      final strokes = grid([
        '#..',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.0,
      );
    });

    // ---------------------------------------------------------------
    // Proportional accuracy
    // ---------------------------------------------------------------

    test('one of four stroke pixels inside reference → 25%', () {
      final reference = grid([
        '#.',
        '..',
      ]);
      final strokes = grid([
        '##',
        '##',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.25,
      );
    });

    test('three of four stroke pixels inside reference → 75%', () {
      final reference = grid([
        '##',
        '#.',
      ]);
      final strokes = grid([
        '##',
        '##',
      ]);
      expect(
        PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.75,
      );
    });

    // ---------------------------------------------------------------
    // Dimension validation
    // ---------------------------------------------------------------

    test('mismatched row counts throws ArgumentError', () {
      final reference = grid([
        '##',
        '##',
      ]);
      final strokes = grid([
        '##',
      ]);
      expect(
        () => PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        throwsArgumentError,
      );
    });

    test('mismatched column counts throws ArgumentError', () {
      final reference = grid([
        '###',
      ]);
      final strokes = grid([
        '##',
      ]);
      expect(
        () => PrecisionScorer.calculate(referenceMask: reference, strokeMask: strokes),
        throwsArgumentError,
      );
    });
  });
}
