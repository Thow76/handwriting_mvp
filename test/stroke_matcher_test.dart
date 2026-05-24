import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_matcher.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

void main() {
  // A 300×300 bounding box centred at the origin for easy mental arithmetic.
  // Thirds: top band y=0–100 (centroid y=50), middle y=100–200 (centroid
  // y=150), bottom y=200–300 (centroid y=250).  Horizontal centre x=150.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // Predefined start rects matching the old vertical-thirds regions.
  const topRect =
      StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0);
  const middleRect = StrokeStartRect(
      minX: 0.0, maxX: 1.0, minY: 1.0 / 3.0, maxY: 2.0 / 3.0);
  const bottomRect =
      StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 2.0 / 3.0, maxY: 1.0);

  // Helper: a non-compound expected stroke with the given start rect.
  ExpectedStroke expectedAt(StrokeStartRect rect) => ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: rect,
      );

  // Helper: a stroke whose bounding-box centroid is at (cx, cy).
  Stroke strokeAtCentroid(double cx, double cy) =>
      Stroke([Offset(cx - 10, cy - 10), Offset(cx + 10, cy + 10)]);

  group('matchStrokes', () {
    // ── 1. Equal-length lists ────────────────────────────────────────────────

    test('equal-length: each observed stroke maps to the correct expected', () {
      // Two expected strokes: top (centroid y=50) and bottom (centroid y=250).
      final expected = [
        expectedAt(topRect),
        expectedAt(bottomRect),
      ];

      // Two observed strokes placed at the matching positions.
      final observed = [
        strokeAtCentroid(150, 50), // near top expected
        strokeAtCentroid(150, 250), // near bottom expected
      ];

      final result = matchStrokes(observed, expected, bounds);

      expect(result, [0, 1]);
    });

    // ── 2. observed.length > expected.length ────────────────────────────────

    test('more observed than expected: surplus observed strokes map to -1', () {
      final expected = [
        expectedAt(topRect),
        expectedAt(bottomRect),
      ];

      // Three observed strokes but only two expected.
      final observed = [
        strokeAtCentroid(150, 50), // matches expected[0] (top)
        strokeAtCentroid(150, 250), // matches expected[1] (bottom)
        strokeAtCentroid(150, 150), // no expected left → -1
      ];

      final result = matchStrokes(observed, expected, bounds);

      expect(result, [0, 1, -1]);
    });

    // ── 3. observed.length < expected.length ────────────────────────────────

    test(
        'fewer observed than expected: unmatched expected strokes are simply '
        'unclaimed', () {
      // Three expected strokes: top, middle, bottom.
      final expected = [
        expectedAt(topRect),
        expectedAt(middleRect),
        expectedAt(bottomRect),
      ];

      // Only two observed strokes: one near top, one near bottom.
      final observed = [
        strokeAtCentroid(150, 50), // closest to expected[0] (top, centroid 50)
        strokeAtCentroid(150, 250), // closest to expected[2] (bottom, centroid 250)
      ];

      final result = matchStrokes(observed, expected, bounds);

      // expected[1] (middle) is never claimed; that is fine — the function
      // only reports mappings for observed strokes.
      expect(result, [0, 2]);
    });

    // ── 4. Reordered strokes ─────────────────────────────────────────────────

    test(
        'reordered: observed drawn as [stroke2, stroke1] still maps to the '
        'correct expected indices', () {
      // Template has stroke 0 at top and stroke 1 at bottom.
      final expected = [
        expectedAt(topRect),    // expected index 0 (centroid y=50)
        expectedAt(bottomRect), // expected index 1 (centroid y=250)
      ];

      // Learner drew the strokes in reverse order:
      //   observed[0] is spatially near the bottom → should match expected[1]
      //   observed[1] is spatially near the top    → should match expected[0]
      final observed = [
        strokeAtCentroid(150, 250), // drawn second stroke first
        strokeAtCentroid(150, 50),  // drawn first stroke second
      ];

      final result = matchStrokes(observed, expected, bounds);

      expect(result, [1, 0]);
    });

    // ── Edge cases ───────────────────────────────────────────────────────────

    test('empty observed list returns an empty result', () {
      final expected = [expectedAt(topRect)];
      final result = matchStrokes([], expected, bounds);
      expect(result, isEmpty);
    });

    test('empty expected list: all observed strokes map to -1', () {
      final observed = [strokeAtCentroid(150, 150)];
      final result = matchStrokes(observed, [], bounds);
      expect(result, [-1]);
    });

    test('observed stroke with no points maps to -1', () {
      final expected = [expectedAt(topRect)];
      final observed = [Stroke([])]; // no points
      final result = matchStrokes(observed, expected, bounds);
      expect(result, [-1]);
    });

    // ── Compound stroke matching ─────────────────────────────────────────────

    test(
        'compound strokes use waypoint centroid for spatial matching', () {
      // Two compound expected strokes:
      //   stroke 0: waypoints [topLeft] → centroid at col 0, row 0 → (50, 50)
      //   stroke 1: waypoints [bottomRight] → centroid at col 2, row 2 → (250, 250)
      final expected = [
        ExpectedStroke(
          primaryDirection: StrokeDirection.compound,
          startRect: topRect,
          waypoints: [WaypointRegion.topLeft],
        ),
        ExpectedStroke(
          primaryDirection: StrokeDirection.compound,
          startRect: bottomRect,
          waypoints: [WaypointRegion.bottomRight],
        ),
      ];

      // Observed in reversed spatial order.
      final observed = [
        strokeAtCentroid(250, 250), // near bottomRight centroid (250, 250)
        strokeAtCentroid(50, 50),   // near topLeft centroid (50, 50)
      ];

      final result = matchStrokes(observed, expected, bounds);

      expect(result, [1, 0]);
    });
  });
}
