import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/placement_scorer.dart';
import 'package:handwriting_mvp/models/stroke.dart';

void main() {
  // A simple zone: expectedTop = 100, expectedBottom = 200 (zone height = 100).
  const expectedTop = 100.0;
  const expectedBottom = 200.0;

  /// Helper: creates strokes whose bounding box spans from [top] to [bottom].
  List<Stroke> strokesInRange(double top, double bottom) {
    return [
      Stroke([Offset(50, top), Offset(50, bottom)]),
    ];
  }

  group('PlacementScorer', () {
    test('perfect placement returns 1.0', () {
      final strokes = strokesInRange(100, 200);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, 1.0);
    });

    test('empty strokes returns 0.0', () {
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: [],
      );
      expect(score, 0.0);
    });

    test('strokes with no points returns 0.0', () {
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: [Stroke([])],
      );
      expect(score, 0.0);
    });

    test('strokes shifted slightly down scores less than 1.0', () {
      // Shifted down by 10px: top=110, bottom=210
      final strokes = strokesInRange(110, 210);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, lessThan(1.0));
      expect(score, greaterThan(0.0));
    });

    test('strokes shifted slightly up scores less than 1.0', () {
      // Shifted up by 10px: top=90, bottom=190
      final strokes = strokesInRange(90, 190);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, lessThan(1.0));
      expect(score, greaterThan(0.0));
    });

    test('strokes shifted down by 10% of zone score 0.9', () {
      // Zone height is 100, shifted by 10px = 10%
      final strokes = strokesInRange(110, 210);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, closeTo(0.9, 0.001));
    });

    test('strokes shifted up by 10% of zone score 0.9', () {
      final strokes = strokesInRange(90, 190);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, closeTo(0.9, 0.001));
    });

    test('strokes too short (top too low) scores less than 1.0', () {
      // Only covers bottom half of zone: top=150, bottom=200
      final strokes = strokesInRange(150, 200);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, lessThan(1.0));
      expect(score, greaterThan(0.0));
    });

    test('strokes too tall (extends beyond both edges) scores less than 1.0', () {
      // Extends 20px above and below: top=80, bottom=220
      final strokes = strokesInRange(80, 220);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, lessThan(1.0));
      expect(score, greaterThan(0.0));
    });

    test('strokes far outside zone clamp to 0.0', () {
      // Completely below the zone: top=300, bottom=400
      final strokes = strokesInRange(300, 400);
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, 0.0);
    });

    test('multiple strokes uses combined bounding box', () {
      // Two strokes that together span the expected zone
      final strokes = [
        Stroke([Offset(50, 100), Offset(50, 150)]),
        Stroke([Offset(60, 150), Offset(60, 200)]),
      ];
      final score = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokes,
      );
      expect(score, 1.0);
    });

    test('score is symmetric for equal shifts up and down', () {
      final shiftedDown = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokesInRange(120, 220),
      );
      final shiftedUp = PlacementScorer.score(
        expectedTop: expectedTop,
        expectedBottom: expectedBottom,
        strokes: strokesInRange(80, 180),
      );
      expect(shiftedDown, closeTo(shiftedUp, 0.001));
    });
  });
}
