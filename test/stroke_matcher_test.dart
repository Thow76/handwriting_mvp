import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/letter_formation_data.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_formation_enums.dart';
import 'package:handwriting_mvp/models/stroke_matcher.dart';
import 'package:handwriting_mvp/models/stroke_start_rect.dart';

void main() {
  // matchStrokes pairs by stroke order (index), not spatial position, so the
  // bounds and the strokes' actual coordinates are irrelevant to the result.
  // They are supplied only because the signature requires them.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  const someRect =
      StrokeStartRect(minX: 0.0, maxX: 1.0, minY: 0.0, maxY: 1.0 / 3.0);

  ExpectedStroke expectedStroke() => ExpectedStroke(
        primaryDirection: StrokeDirection.topToBottom,
        startRect: someRect,
      );

  // A stroke with at least one point, positioned at (cx, cy). Position has no
  // effect on order-based pairing; it only needs to be non-empty.
  Stroke nonEmptyStrokeAt(double cx, double cy) =>
      Stroke([Offset(cx, cy), Offset(cx + 10, cy + 10)]);

  group('matchStrokes — order-based (index) pairing', () {
    test('equal-length: observed[i] maps to expected[i]', () {
      final expected = [expectedStroke(), expectedStroke()];
      final observed = [
        nonEmptyStrokeAt(150, 50),
        nonEmptyStrokeAt(150, 250),
      ];

      expect(matchStrokes(observed, expected, bounds), [0, 1]);
    });

    test('spatial position is ignored: pairing is purely positional', () {
      // observed[0] sits low and observed[1] sits high — spatial matching would
      // have swapped them ([1, 0]).  Order-based pairing keeps [0, 1].
      final expected = [expectedStroke(), expectedStroke()];
      final observed = [
        nonEmptyStrokeAt(150, 250), // visually near the bottom
        nonEmptyStrokeAt(150, 50), // visually near the top
      ];

      expect(matchStrokes(observed, expected, bounds), [0, 1]);
    });

    test('more observed than expected: surplus observed strokes map to -1', () {
      final expected = [expectedStroke(), expectedStroke()];
      final observed = [
        nonEmptyStrokeAt(150, 50),
        nonEmptyStrokeAt(150, 250),
        nonEmptyStrokeAt(150, 150), // surplus → -1
      ];

      expect(matchStrokes(observed, expected, bounds), [0, 1, -1]);
    });

    test(
        'fewer observed than expected: trailing expected strokes are left '
        'unmatched (reported only for observed strokes)', () {
      final expected = [expectedStroke(), expectedStroke(), expectedStroke()];
      final observed = [
        nonEmptyStrokeAt(150, 50),
        nonEmptyStrokeAt(150, 250),
      ];

      // expected[2] has no observed counterpart; the result only spans the two
      // observed strokes, which pair positionally to expected[0] and [1].
      expect(matchStrokes(observed, expected, bounds), [0, 1]);
    });

    test('compound strokes pair positionally too', () {
      final expected = [
        ExpectedStroke(
          primaryDirection: StrokeDirection.compound,
          startRect: someRect,
          waypoints: const [WaypointRegion.topLeft],
        ),
        ExpectedStroke(
          primaryDirection: StrokeDirection.compound,
          startRect: someRect,
          waypoints: const [WaypointRegion.bottomRight],
        ),
      ];
      final observed = [
        nonEmptyStrokeAt(250, 250),
        nonEmptyStrokeAt(50, 50),
      ];

      expect(matchStrokes(observed, expected, bounds), [0, 1]);
    });

    // ── Edge cases ───────────────────────────────────────────────────────────

    test('empty observed list returns an empty result', () {
      expect(matchStrokes([], [expectedStroke()], bounds), isEmpty);
    });

    test('empty expected list: all observed strokes map to -1', () {
      final observed = [nonEmptyStrokeAt(150, 150)];
      expect(matchStrokes(observed, [], bounds), [-1]);
    });

    test('observed stroke with no points maps to -1', () {
      final expected = [expectedStroke()];
      final observed = [Stroke([])];
      expect(matchStrokes(observed, expected, bounds), [-1]);
    });

    test('an empty stroke does not shift the index of later strokes', () {
      final expected = [expectedStroke(), expectedStroke()];
      final observed = [
        Stroke([]), // empty → -1, still occupies index 0
        nonEmptyStrokeAt(150, 250), // index 1 → expected[1]
      ];

      expect(matchStrokes(observed, expected, bounds), [-1, 1]);
    });
  });
}
