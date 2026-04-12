import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/efficiency_scorer.dart';
import 'package:handwriting_mvp/models/stroke.dart';

void main() {
  group('idealPathLength', () {
    test('returns 0 for an empty skeleton', () {
      final skeleton = <List<bool>>[];
      expect(EfficiencyScorer.idealPathLength(skeleton), 0.0);
    });

    test('returns 0 for a skeleton with no active pixels', () {
      final skeleton = [
        [false, false, false],
        [false, false, false],
      ];
      expect(EfficiencyScorer.idealPathLength(skeleton), 0.0);
    });

    test('returns 1 for a single skeleton pixel', () {
      final skeleton = [
        [false, false],
        [false, true],
      ];
      expect(EfficiencyScorer.idealPathLength(skeleton), 1.0);
    });

    test('returns count of active pixels for a horizontal line', () {
      final skeleton = [
        [false, false, false, false, false],
        [true, true, true, true, true],
        [false, false, false, false, false],
      ];
      expect(EfficiencyScorer.idealPathLength(skeleton), 5.0);
    });

    test('returns count of active pixels for an L-shape', () {
      // Vertical line of 4, then horizontal line of 3 (corner shared)
      final skeleton = [
        [true, false, false, false],
        [true, false, false, false],
        [true, false, false, false],
        [true, true, true, true],
      ];
      expect(EfficiencyScorer.idealPathLength(skeleton), 7.0);
    });
  });

  group('actualPathLength', () {
    test('returns 0 for empty strokes list', () {
      expect(EfficiencyScorer.actualPathLength([]), 0.0);
    });

    test('returns 0 for a single-point stroke', () {
      final strokes = [
        Stroke([const Offset(10, 20)]),
      ];
      expect(EfficiencyScorer.actualPathLength(strokes), 0.0);
    });

    test('returns correct length for a horizontal stroke', () {
      final strokes = [
        Stroke([const Offset(0, 0), const Offset(10, 0)]),
      ];
      expect(EfficiencyScorer.actualPathLength(strokes), 10.0);
    });

    test('returns correct length for a vertical stroke', () {
      final strokes = [
        Stroke([const Offset(5, 0), const Offset(5, 8)]),
      ];
      expect(EfficiencyScorer.actualPathLength(strokes), 8.0);
    });

    test('returns correct length for a diagonal stroke', () {
      // 3-4-5 right triangle: distance from (0,0) to (3,4) = 5
      final strokes = [
        Stroke([const Offset(0, 0), const Offset(3, 4)]),
      ];
      expect(EfficiencyScorer.actualPathLength(strokes), 5.0);
    });

    test('sums lengths across multiple segments in a stroke', () {
      // Two horizontal segments of length 5 each
      final strokes = [
        Stroke([
          const Offset(0, 0),
          const Offset(5, 0),
          const Offset(10, 0),
        ]),
      ];
      expect(EfficiencyScorer.actualPathLength(strokes), 10.0);
    });

    test('sums lengths across multiple strokes', () {
      final strokes = [
        Stroke([const Offset(0, 0), const Offset(5, 0)]), // length 5
        Stroke([const Offset(0, 0), const Offset(0, 3)]), // length 3
      ];
      expect(EfficiencyScorer.actualPathLength(strokes), 8.0);
    });

    test('handles back-and-forth scribbling', () {
      // Go right 10, then back left 10 — total path length is 20
      final strokes = [
        Stroke([
          const Offset(0, 0),
          const Offset(10, 0),
          const Offset(0, 0),
        ]),
      ];
      expect(EfficiencyScorer.actualPathLength(strokes), 20.0);
    });
  });

  group('calculate', () {
    test('returns 1.0 when actual equals ideal', () {
      expect(
        EfficiencyScorer.calculate(idealPathLength: 100, actualPathLength: 100),
        1.0,
      );
    });

    test('returns 0.5 when actual is double the ideal', () {
      expect(
        EfficiencyScorer.calculate(idealPathLength: 100, actualPathLength: 200),
        0.5,
      );
    });

    test('returns 0.2 when actual is 5x the ideal', () {
      expect(
        EfficiencyScorer.calculate(idealPathLength: 100, actualPathLength: 500),
        closeTo(0.2, 0.001),
      );
    });

    test('clamps to 1.0 when actual is shorter than ideal', () {
      expect(
        EfficiencyScorer.calculate(idealPathLength: 100, actualPathLength: 50),
        1.0,
      );
    });

    test('returns 0.0 when ideal path length is zero', () {
      expect(
        EfficiencyScorer.calculate(idealPathLength: 0, actualPathLength: 100),
        0.0,
      );
    });

    test('returns 0.0 when actual path length is zero', () {
      expect(
        EfficiencyScorer.calculate(idealPathLength: 100, actualPathLength: 0),
        0.0,
      );
    });

    test('returns 0.0 when both are zero', () {
      expect(
        EfficiencyScorer.calculate(idealPathLength: 0, actualPathLength: 0),
        0.0,
      );
    });
  });
}
