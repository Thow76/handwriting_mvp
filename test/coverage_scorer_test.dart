import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/coverage_scorer.dart';

/// Helper to build a pixel grid from a visual string representation.
/// '#' = ink present (true), '.' = empty (false).
///
/// Example:
///   grid([
///     '..##..',
///     '.####.',
///     '..##..',
///   ])
List<List<bool>> grid(List<String> rows) {
  return rows.map((row) => row.split('').map((c) => c == '#').toList()).toList();
}

void main() {
  group('CoverageScorer', () {
    // ---------------------------------------------------------------
    // Core behaviour
    // ---------------------------------------------------------------

    test('identical masks → 100% coverage', () {
      final mask = grid([
        '..##..',
        '.####.',
        '..##..',
      ]);
      expect(CoverageScorer.calculate(referenceMask: mask, strokeMask: mask), 1.0);
    });

    test('no strokes drawn → 0% coverage', () {
      final reference = grid([
        '..##..',
        '.####.',
        '..##..',
      ]);
      final empty = grid([
        '......',
        '......',
        '......',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: empty),
        0.0,
      );
    });

    test('half the reference covered → ~50% coverage', () {
      final reference = grid([
        '####',
        '####',
      ]);
      // Cover only the top row
      final strokes = grid([
        '####',
        '....',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.5,
      );
    });

    test('strokes completely outside reference → 0% coverage', () {
      final reference = grid([
        '##..',
        '##..',
      ]);
      final strokes = grid([
        '..##',
        '..##',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.0,
      );
    });

    test('strokes larger than reference but fully covering it → 100% coverage', () {
      final reference = grid([
        '.##.',
        '.##.',
      ]);
      final strokes = grid([
        '####',
        '####',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        1.0,
      );
    });

    // ---------------------------------------------------------------
    // Edge cases
    // ---------------------------------------------------------------

    test('empty reference (no pixels) → 0% coverage', () {
      final reference = grid([
        '....',
        '....',
      ]);
      final strokes = grid([
        '####',
        '####',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.0,
      );
    });

    test('single pixel reference, covered → 100%', () {
      final reference = grid([
        '.#',
      ]);
      final strokes = grid([
        '.#',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        1.0,
      );
    });

    test('single pixel reference, not covered → 0%', () {
      final reference = grid([
        '.#',
      ]);
      final strokes = grid([
        '#.',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.0,
      );
    });

    // ---------------------------------------------------------------
    // Partial coverage — verify proportional accuracy
    // ---------------------------------------------------------------

    test('one of four reference pixels covered → 25%', () {
      final reference = grid([
        '##',
        '##',
      ]);
      final strokes = grid([
        '#.',
        '..',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        0.25,
      );
    });

    test('three of four reference pixels covered → 75%', () {
      final reference = grid([
        '##',
        '##',
      ]);
      final strokes = grid([
        '##',
        '#.',
      ]);
      expect(
        CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
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
        () => CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
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
        () => CoverageScorer.calculate(referenceMask: reference, strokeMask: strokes),
        throwsArgumentError,
      );
    });
  });
}
