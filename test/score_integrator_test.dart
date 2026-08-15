import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/score_integrator.dart';
import 'package:handwriting_mvp/models/stroke.dart';

/// Helper to build a [rows]×[cols] mask from a list of (row, col) pairs.
List<List<bool>> _mask(
  int rows,
  int cols, [
  List<(int, int)> active = const [],
]) {
  final grid = List.generate(rows, (_) => List.filled(cols, false));
  for (final (r, c) in active) {
    grid[r][c] = true;
  }
  return grid;
}

void main() {
  group('ScoreIntegrator', () {
    test('no strokes → 0% coverage, 0% precision', () {
      final ref = _mask(10, 10, [(5, 5), (5, 6), (6, 5), (6, 6)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [],
      );

      expect(result.coverage, 0.0);
      expect(result.precision, 0.0);
    });

    test(
      'stroke perfectly covering reference → 100% coverage, 100% precision',
      () {
        // Reference is a single pixel at (5,5).
        final ref = _mask(10, 10, [(5, 5)]);

        // Draw at cell centre (5.5, 5.5) so the stroke lands in exactly one pixel.
        final stroke = Stroke([const Offset(5.5, 5.5)]);
        final result = ScoreIntegrator.score(
          referenceMask: ref,
          bounds: const Rect.fromLTWH(0, 0, 10, 10),
          strokes: [stroke],
          strokeWidth: 1.0,
        );

        expect(result.coverage, 1.0);
        expect(result.precision, 1.0);
      },
    );

    test('stroke completely outside reference → 0% coverage, 0% precision', () {
      // Reference in top-left corner.
      final ref = _mask(10, 10, [(0, 0), (0, 1), (1, 0), (1, 1)]);

      // Draw in bottom-right corner.
      final stroke = Stroke([const Offset(8, 8)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 0.0);
      expect(result.precision, 0.0);
    });

    test('stroke covers half the reference → 50% coverage, 100% precision', () {
      // Reference is a 2×1 block at (5,4) and (5,5).
      final ref = _mask(10, 10, [(5, 4), (5, 5)]);

      // Draw at cell centre of (5,5) only.
      final stroke = Stroke([const Offset(5.5, 5.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 0.5);
      expect(result.precision, 1.0);
    });

    test(
      'wide stroke spills outside reference → high coverage, lower precision',
      () {
        // Reference is a single pixel at (5,5).
        final ref = _mask(10, 10, [(5, 5)]);

        // Draw on that pixel with a wide stroke — covers (5,5) plus neighbours.
        final stroke = Stroke([const Offset(5, 5)]);
        final result = ScoreIntegrator.score(
          referenceMask: ref,
          bounds: const Rect.fromLTWH(0, 0, 10, 10),
          strokes: [stroke],
          strokeWidth: 3.0,
        );

        expect(result.coverage, 1.0);
        expect(result.precision, lessThan(1.0));
      },
    );

    test('strokes outside bounds are ignored', () {
      final ref = _mask(10, 10, [(5, 5)]);

      // Stroke is outside the 10×10 bounds.
      final stroke = Stroke([const Offset(20, 20)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 0.0);
      expect(result.precision, 0.0);
    });

    test('bounds offset is applied correctly', () {
      // Reference pixel at grid position (5,5).
      final ref = _mask(10, 10, [(5, 5)]);

      // Bounds start at (100, 100), so canvas point (105.5, 105.5) maps to cell (5,5).
      final stroke = Stroke([const Offset(105.5, 105.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(100, 100, 10, 10),
        strokes: [stroke],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 1.0);
      expect(result.precision, 1.0);
    });

    test('multiple strokes combine for scoring', () {
      // Reference is two separate pixels.
      final ref = _mask(10, 10, [(2, 2), (8, 8)]);

      // Two strokes, each hitting one pixel at cell centre.
      final stroke1 = Stroke([const Offset(2.5, 2.5)]);
      final stroke2 = Stroke([const Offset(8.5, 8.5)]);
      final result = ScoreIntegrator.score(
        referenceMask: ref,
        bounds: const Rect.fromLTWH(0, 0, 10, 10),
        strokes: [stroke1, stroke2],
        strokeWidth: 1.0,
      );

      expect(result.coverage, 1.0);
      expect(result.precision, 1.0);
    });

    test('mismatched reference mask dimensions throws', () {
      // Reference is 5×5 but bounds imply a 10×10 grid.
      final ref = _mask(5, 5, [(2, 2)]);

      expect(
        () => ScoreIntegrator.score(
          referenceMask: ref,
          bounds: const Rect.fromLTWH(0, 0, 10, 10),
          strokes: [],
        ),
        throwsArgumentError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Formation-scoring integration tests
  // ---------------------------------------------------------------------------

  group('ScoreIntegrator formation scoring', () {
    // 90×90 all-false mask used for formation tests — formation scorers do not
    // use the reference mask, so only the dimensions matter.
    final ref90 = _mask(90, 90);
    const bounds90 = Rect.fromLTWH(0, 0, 90, 90);

    test('no letter → all three formation fields are null', () {
      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [],
      );

      expect(result.strokeStart, isNull);
      expect(result.compoundStroke, isNull);
      expect(result.strokeBreak, isNull);
    });

    test('unknown letter → all three formation fields are null (defensive)', () {
      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [],
        letter: '0', // digit — not in letterFormationRegistry
      );

      expect(result.strokeStart, isNull);
      expect(result.compoundStroke, isNull);
      expect(result.strokeBreak, isNull);
    });

    test('correct n → all three formation scores attached; start, compound and '
        'break scores are 1.0', () {
      // n uses section-based scoring (WaypointSectionScorer) with 4 sections:
      //   section 1: top-left     [0, 0.33) × [0, 0.33)
      //   section 2: bottom-left  [0, 0.33) × [0.67, 1.0)
      //   section 3: top-centre   [0.33, 0.67) × [0, 0.33)
      //   section 4: bottom-right [0.67, 1.0) × [0.67, 1.0)
      // In a 90×90 grid, the absolute pixel ranges are:
      //   section 1: x[0, 29.7) y[0, 29.7)
      //   section 2: x[0, 29.7) y[60.3, 90)
      //   section 3: x[29.7, 60.3) y[0, 29.7)
      //   section 4: x[60.3, 90) y[60.3, 90)
      // The stroke visits each section exactly, so all 4 are hit in order.
      //
      // n's startRect is minX=0, maxX=0.30, minY=0, maxY=0.20.
      // In 90×90 bounds this corresponds to x ∈ [0, 27) and y ∈ [0, 18).
      // The first point (10, 10) is inside the startRect AND section 1.
      final stroke = Stroke(const [
        Offset(10, 10), // inside n's startRect and section 1
        Offset(15, 75), // section 2 (bottom-left)
        Offset(45, 15), // section 3 (top-centre arch)
        Offset(75, 75), // section 4 (bottom-right)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'n',
      );

      // All three formation score objects must be attached.
      expect(result.strokeStart, isNotNull);
      expect(result.compoundStroke, isNotNull);
      expect(result.strokeBreak, isNotNull);

      // Stroke first point (10, 10) is inside n's startRect → 1.0.
      expect(result.strokeStart!.overallScore, 1.0);

      // All 4 sections hit in order → 1.0 (section scorer, all-or-nothing).
      expect(result.compoundStroke!.overallScore, 1.0);

      // 1 stroke provided; minRequiredStrokes = 1 → 1.0.
      expect(result.strokeBreak!.overallScore, 1.0);
    });

    test('incomplete n path (2 of 4 sections) → compoundStroke score is 0.0',
        () {
      // Only hits section 1 and section 2, misses sections 3 and 4.
      // All-or-nothing scoring: incomplete → 0.0.
      final stroke = Stroke(const [
        Offset(10, 10), // section 1 (top-left)
        Offset(15, 75), // section 2 (bottom-left)
        Offset(15, 80), // still in section 2, never reaches 3 or 4
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'n',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('out-of-order n path (section 1 → 3 → 2 → 4) → compoundStroke '
        'score is 0.0', () {
      // Hits sections out of sequential order: 1 then 3 (skipping 2).
      // The sequential match breaks at section 2 → 0.0.
      final stroke = Stroke(const [
        Offset(10, 10), // section 1 (top-left)
        Offset(45, 15), // section 3 (top-centre) — out of order
        Offset(15, 75), // section 2 (bottom-left) — too late
        Offset(75, 75), // section 4 (bottom-right)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'n',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('anticlockwise o oval path → compoundStroke score is 1.0', () {
      // o uses waypoint routing: topRight → left → bottom → right.
      // This path visits those cells in the authored order.
      final stroke = Stroke(const [
        Offset(75, 15), // topRight centroid
        Offset(15, 45), // left centroid
        Offset(45, 75), // bottom centroid
        Offset(75, 45), // right centroid
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'o',
      );

      // All three formation score objects must be attached.
      expect(result.strokeStart, isNotNull);
      expect(result.compoundStroke, isNotNull);
      expect(result.strokeBreak, isNotNull);

      // All 4 waypoints are hit in order.
      expect(result.compoundStroke!.overallScore, 1.0);

      // 1 stroke provided; minRequiredStrokes = 1 → 1.0.
      expect(result.strokeBreak!.overallScore, 1.0);
    });

    test(
      'straight vertical stroke for o scores below 0.5 on compoundStroke',
      () {
        final stroke = Stroke(const [Offset(45, 5), Offset(45, 85)]);

        final result = ScoreIntegrator.score(
          referenceMask: ref90,
          bounds: bounds90,
          strokes: [stroke],
          letter: 'o',
        );

        expect(result.compoundStroke, isNotNull);
        expect(result.compoundStroke!.overallScore, lessThan(0.5));
      },
    );

    test('clockwise o oval path scores near 0 on compoundStroke', () {
      // Clockwise loop: top → right → bottom → left.
      final stroke = Stroke(const [
        Offset(45, 5),
        Offset(85, 45),
        Offset(45, 85),
        Offset(5, 45),
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'o',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, lessThanOrEqualTo(0.25));
    });

    // -------------------------------------------------------------------------
    // 'a' — section-based scoring (WaypointSectionScorer)
    // -------------------------------------------------------------------------

    test('correct a (anticlockwise oval) → compoundStroke score is 1.0', () {
      // a uses section-based scoring with 4 sections:
      //   section 1: upper-right  [0.55, 1.00) × [0.00, 0.30)
      //   section 2: left         [0.00, 0.35) × [0.25, 0.70)
      //   section 3: bottom       [0.20, 0.80) × [0.70, 1.00)
      //   section 4: right        [0.65, 1.00) × [0.30, 0.75)
      // In a 90×90 grid:
      //   section 1: x[49.5, 90) y[0, 27)
      //   section 2: x[0, 31.5) y[22.5, 63)
      //   section 3: x[18, 72) y[63, 90)
      //   section 4: x[58.5, 90) y[27, 67.5)
      final stroke = Stroke(const [
        Offset(70, 10), // section 1 (upper-right)
        Offset(15, 45), // section 2 (left)
        Offset(45, 80), // section 3 (bottom)
        Offset(75, 50), // section 4 (right)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'a',
      );

      // All three formation score objects must be attached.
      expect(result.strokeStart, isNotNull);
      expect(result.compoundStroke, isNotNull);
      expect(result.strokeBreak, isNotNull);

      // Stroke first point (70, 10) is inside a's startRect → 1.0.
      expect(result.strokeStart!.overallScore, 1.0);

      // All 4 sections hit in order → 1.0 (section scorer, all-or-nothing).
      expect(result.compoundStroke!.overallScore, 1.0);

      // 1 stroke provided; minRequiredStrokes = 1 → 1.0.
      expect(result.strokeBreak!.overallScore, 1.0);
    });

    test('incomplete a path (2 of 4 sections) → compoundStroke score is 0.0',
        () {
      // Only hits section 1 and section 2, misses sections 3 and 4.
      final stroke = Stroke(const [
        Offset(70, 10), // section 1 (upper-right)
        Offset(15, 45), // section 2 (left)
        Offset(15, 50), // still left, never reaches bottom or right
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'a',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('out-of-order a path (section 1 → 3 → 2 → 4) → compoundStroke '
        'score is 0.0', () {
      // Hits sections out of sequential order: 1 then 3 (skipping 2).
      final stroke = Stroke(const [
        Offset(70, 10), // section 1 (upper-right)
        Offset(45, 80), // section 3 (bottom) — out of order
        Offset(15, 45), // section 2 (left) — too late
        Offset(75, 50), // section 4 (right)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'a',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('correct c (open anticlockwise arc) → compoundStroke score is 1.0',
        () {
      // c uses section-based scoring (WaypointSectionScorer) with 3 sections:
      //   section 1: upper-right  [0.55, 1.00) × [0.00, 0.30)
      //   section 2: left         [0.00, 0.35) × [0.25, 0.75)
      //   section 3: bottom       [0.20, 0.80) × [0.70, 1.00)
      // In a 90×90 grid:
      //   section 1: x[49.5, 90) y[0, 27)
      //   section 2: x[0, 31.5) y[22.5, 67.5)
      //   section 3: x[18, 72) y[63, 90)
      final stroke = Stroke(const [
        Offset(70, 10), // section 1 (upper-right)
        Offset(15, 45), // section 2 (left)
        Offset(45, 80), // section 3 (bottom)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'c',
      );

      expect(result.strokeStart, isNotNull);
      expect(result.compoundStroke, isNotNull);
      expect(result.strokeBreak, isNotNull);

      // Stroke first point (70, 10) is inside c's startRect → 1.0.
      expect(result.strokeStart!.overallScore, 1.0);

      // All 3 sections hit in order → 1.0 (section scorer, all-or-nothing).
      expect(result.compoundStroke!.overallScore, 1.0);

      // 1 stroke provided; minRequiredStrokes = 1 → 1.0.
      expect(result.strokeBreak!.overallScore, 1.0);
    });

    test('incomplete c path (1 of 3 sections) → compoundStroke score is 0.0',
        () {
      // Only hits section 1, never reaches left or bottom.
      final stroke = Stroke(const [
        Offset(70, 10), // section 1 (upper-right)
        Offset(70, 15), // still upper-right, never reaches left or bottom
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'c',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('out-of-order c path (section 1 → 3 → 2) → compoundStroke '
        'score is 0.0', () {
      // Hits sections out of sequential order: 1 then 3 (skipping 2).
      final stroke = Stroke(const [
        Offset(70, 10), // section 1 (upper-right)
        Offset(45, 80), // section 3 (bottom) — out of order
        Offset(15, 45), // section 2 (left) — too late
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'c',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    // -------------------------------------------------------------------------
    // 'e' — section-based scoring (WaypointSectionScorer)
    // -------------------------------------------------------------------------

    // e's 7-section design (issue #149 — full replacement of the PR #141
    // design, whose closing section was copied from a's closed-loop point
    // and was never reachable by a real e, since e ends in an open curl).
    // Measured against the real Andika glyph (scripts/measure_e_glyph.py):
    //   section 1: tongue left     [0.00, 0.48) × [0.35, 0.55)
    //   section 2: tongue right    [0.48, 0.95) × [0.35, 0.55)
    //   section 3: top-right       [0.55, 1.00) × [0.00, 0.30)
    //   section 4: top-middle      [0.10, 0.60) × [0.00, 0.20)
    //   section 5: left edge       [0.00, 0.35) × [0.10, 0.85)
    //   section 6: bottom-middle   [0.15, 0.65) × [0.80, 1.00)
    //   section 7: bottom-right    [0.65, 1.00) × [0.65, 0.85)  (open finish)
    // In a 90×90 grid:
    //   section 1: x[0, 43.2) y[31.5, 49.5)
    //   section 2: x[43.2, 85.5) y[31.5, 49.5)
    //   section 3: x[49.5, 90) y[0, 27)
    //   section 4: x[9, 54) y[0, 18)
    //   section 5: x[0, 31.5) y[9, 76.5)
    //   section 6: x[13.5, 58.5) y[72, 90)
    //   section 7: x[58.5, 90) y[58.5, 76.5)
    //
    // Test strokes below use a realistic multi-point curved path — not a
    // single hand-placed centre point per section — since a hand-placed
    // point per section is exactly the kind of shortcut that let the
    // original (broken) design pass its own tests without ever being
    // checked against a real stroke shape.
    test(
        'correct e (tongue + anticlockwise sweep to open terminal) → '
        'compoundStroke score is 1.0', () {
      final stroke = Stroke(const [
        Offset(8, 44), // e's startRect / tongue left
        Offset(16, 43),
        Offset(24, 42),
        Offset(32, 41),
        Offset(40, 40), // section 1 (tongue left)
        Offset(48, 40),
        Offset(56, 39),
        Offset(64, 38),
        Offset(72, 36), // section 2 (tongue right)
        Offset(79, 29),
        Offset(84, 20),
        Offset(87, 12), // section 3 (top-right)
        Offset(78, 4),
        Offset(68, 1),
        Offset(56, 0),
        Offset(44, 1), // section 4 (top-middle)
        Offset(32, 3),
        Offset(22, 7),
        Offset(14, 13),
        Offset(8, 22),
        Offset(5, 34),
        Offset(4, 46),
        Offset(5, 58),
        Offset(9, 68), // section 5 (left edge)
        Offset(15, 76),
        Offset(24, 83),
        Offset(35, 87),
        Offset(46, 88), // section 6 (bottom-middle)
        Offset(56, 85),
        Offset(64, 79),
        Offset(71, 71),
        Offset(77, 63), // section 7 (bottom-right, open finish)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'e',
      );

      expect(result.strokeStart, isNotNull);
      expect(result.compoundStroke, isNotNull);
      expect(result.strokeBreak, isNotNull);

      // Stroke first point (8, 44) is inside e's startRect → 1.0.
      expect(result.strokeStart!.overallScore, 1.0);

      // All 7 sections hit in order → 1.0 (section scorer, all-or-nothing).
      expect(result.compoundStroke!.overallScore, 1.0);

      // 1 stroke provided; minRequiredStrokes = 1 → 1.0.
      expect(result.strokeBreak!.overallScore, 1.0);
    });

    test(
        'reversed tongue e (right to left) → compoundStroke score is 0.0',
        () {
      // The tongue is drawn right-to-left instead of left-to-right: section
      // 1 (tongue left) still ends up hit eventually (later in the point
      // stream than section 2's rectangle), but by then the cursor is past
      // the only points that fall inside section 2's rectangle, so section 2
      // is never reached in order and the sequence breaks there.
      final stroke = Stroke(const [
        Offset(56, 39), // tongue right, drawn first — reversed
        Offset(64, 38),
        Offset(40, 41), // tongue left, drawn second — reversed
        Offset(24, 43),
        Offset(10, 44),
        Offset(20, 15), // curves away without re-entering the tongue-right
        Offset(40, 3), // rectangle, so section 2 can never be matched
        Offset(70, 6),
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'e',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('tongue only, no oval e → compoundStroke score is 0.0', () {
      // The tongue (sections 1-2) is drawn correctly left to right, but the
      // stroke stops there — the oval (sections 3-7) is never attempted.
      final stroke = Stroke(const [
        Offset(8, 44),
        Offset(16, 43),
        Offset(24, 42),
        Offset(32, 41), // section 1 (tongue left)
        Offset(48, 40),
        Offset(56, 39),
        Offset(64, 38), // section 2 (tongue right)
        Offset(72, 36), // still in the tongue band, never curves up
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stroke],
        letter: 'e',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    final stem = Stroke(const [Offset(45, 15), Offset(45, 75)]);
    final clockwiseBowl = Stroke(const [
      Offset(75, 15), // topRight centroid
      Offset(75, 45), // right centroid
      Offset(45, 75), // bottom centroid
      Offset(15, 45), // left centroid
    ]);
    final straightBowl = Stroke(const [Offset(15, 5), Offset(15, 85)]);
    final anticlockwiseBowl = Stroke(const [
      Offset(15, 45), // left centroid
      Offset(45, 75), // bottom centroid
      Offset(75, 45), // right centroid
      Offset(75, 15), // topRight centroid
    ]);

    double compoundScoreFor(String letter, Stroke bowl) {
      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [stem, bowl],
        letter: letter,
      );
      expect(result.compoundStroke, isNotNull);
      return result.compoundStroke!.overallScore;
    }

    for (final letter in ['p']) {
      test('clockwise $letter bowl path scores 1.0 on compoundStroke', () {
        expect(compoundScoreFor(letter, clockwiseBowl), 1.0);
      });

      test('straight $letter bowl stroke scores 0.5 on compoundStroke', () {
        expect(compoundScoreFor(letter, straightBowl), 0.5);
      });

      test(
        'anticlockwise $letter bowl path scores 0.625 on compoundStroke',
        () {
          expect(compoundScoreFor(letter, anticlockwiseBowl), 0.625);
        },
      );
    }

    // -------------------------------------------------------------------------
    // b — section-based scoring integration tests
    // -------------------------------------------------------------------------
    // b uses WaypointSectionScorer (sections on both strokes).
    // Stem stroke (stroke 0): 2 sections — top-left [0,0.30)×[0,0.20) and
    //   bottom-left [0,0.30)×[0.80,1.0).
    // Bowl stroke (stroke 1): 4 sections — mid-left, top-right, bottom-right,
    //   bottom-left (clockwise path).
    // In a 90×90 grid:
    //   stem section 1: x[0, 27) y[0, 18)
    //   stem section 2: x[0, 27) y[72, 90)
    //   bowl section 1: x[0, 31.5) y[31.5, 49.5)
    //   bowl section 2: x[45, 90) y[31.5, 54)
    //   bowl section 3: x[45, 90) y[67.5, 90)
    //   bowl section 4: x[0, 31.5) y[67.5, 90)

    test('correct b (stem + bowl) → routes through WaypointSectionScorer '
        'and compoundStroke is 1.0', () {
      // Stem visits section 1 then section 2 in order.
      final bStem = Stroke(const [
        Offset(10, 10), // stem section 1 (top-left)
        Offset(10, 80), // stem section 2 (bottom-left)
      ]);
      // Bowl visits all 4 sections in clockwise order.
      final bBowl = Stroke(const [
        Offset(10, 40), // bowl section 1 (mid-left)
        Offset(70, 40), // bowl section 2 (top-right)
        Offset(70, 80), // bowl section 3 (bottom-right)
        Offset(10, 80), // bowl section 4 (bottom-left)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [bStem, bBowl],
        letter: 'b',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 1.0);
    });

    test('b bowl out-of-order → compoundStroke is 0.0', () {
      // Stem is correct but bowl visits sections out of order, so the single
      // letter path (sections 1–6) breaks → 0.0. No partial credit.
      final bStem = Stroke(const [
        Offset(10, 10), // section 1
        Offset(10, 80), // section 2
      ]);
      // Bowl: section 3 → section 6 (skips 4 and 5) → breaks the sequence.
      final bBowl = Stroke(const [
        Offset(10, 40), // section 3 (mid-left)
        Offset(10, 80), // section 6 (bottom-left) — out of order
        Offset(70, 40), // section 4 — too late
        Offset(70, 80), // section 5
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [bStem, bBowl],
        letter: 'b',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('b stem only (bowl never drawn) → compoundStroke is 0.0', () {
      // Drawing only the stem completes sections 1–2 but not the bowl (3–6),
      // so the letter path is incomplete → 0.0, not 100%.
      final bStem = Stroke(const [
        Offset(10, 10), // section 1
        Offset(10, 80), // section 2
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [bStem],
        letter: 'b',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('connected b (one no-lift stroke, full path) → compoundStroke is 1.0',
        () {
      // A single continuous stroke through all six sections in order scores
      // identically to the lifted two-stroke form — lifts are judged separately.
      final bConnected = Stroke(const [
        Offset(10, 10), // section 1 (stem top)
        Offset(10, 80), // section 2 (stem bottom)
        Offset(10, 40), // section 3 (bowl mid-left)
        Offset(70, 40), // section 4 (bowl right)
        Offset(70, 80), // section 5 (bowl bottom-right)
        Offset(10, 80), // section 6 (bowl bottom-left)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [bConnected],
        letter: 'b',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 1.0);
    });

    // -------------------------------------------------------------------------
    // d — section-based scoring integration tests (horizontal mirror of b)
    // -------------------------------------------------------------------------
    // d uses WaypointSectionScorer (sections on both strokes).
    // Stem stroke (stroke 0): 2 sections — top-right [0.70,1.00)×[0,0.20) and
    //   bottom-right [0.70,1.00)×[0.80,1.0).
    // Bowl stroke (stroke 1): 4 sections — mid-right, top-left, bottom-left,
    //   bottom-right (anticlockwise path).
    // In a 90×90 grid:
    //   stem section 1: x[63, 90) y[0, 18)
    //   stem section 2: x[63, 90) y[72, 90)
    //   bowl section 3: x[58.5, 90) y[31.5, 49.5)
    //   bowl section 4: x[0, 45) y[31.5, 54)
    //   bowl section 5: x[0, 45) y[67.5, 90)
    //   bowl section 6: x[58.5, 90) y[67.5, 90)

    test('correct d (stem + bowl) → routes through WaypointSectionScorer '
        'and compoundStroke is 1.0', () {
      // Stem visits section 1 then section 2 in order.
      final dStem = Stroke(const [
        Offset(80, 10), // stem section 1 (top-right)
        Offset(80, 80), // stem section 2 (bottom-right)
      ]);
      // Bowl visits all 4 sections in anticlockwise order.
      final dBowl = Stroke(const [
        Offset(80, 40), // bowl section 3 (mid-right)
        Offset(20, 40), // bowl section 4 (top-left)
        Offset(20, 80), // bowl section 5 (bottom-left)
        Offset(80, 80), // bowl section 6 (bottom-right)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [dStem, dBowl],
        letter: 'd',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 1.0);
    });

    test('d bowl out-of-order → compoundStroke is 0.0', () {
      // Stem is correct but bowl visits sections out of order, so the single
      // letter path (sections 1–6) breaks → 0.0. No partial credit.
      final dStem = Stroke(const [
        Offset(80, 10), // section 1
        Offset(80, 80), // section 2
      ]);
      // Bowl: section 3 → section 6 (skips 4 and 5) → breaks the sequence.
      final dBowl = Stroke(const [
        Offset(80, 40), // section 3 (mid-right)
        Offset(80, 80), // section 6 (bottom-right) — out of order
        Offset(20, 40), // section 4 — too late
        Offset(20, 80), // section 5
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [dStem, dBowl],
        letter: 'd',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('d stem only (bowl never drawn) → compoundStroke is 0.0', () {
      // Drawing only the stem completes sections 1–2 but not the bowl (3–6),
      // so the letter path is incomplete → 0.0, not 100%.
      final dStem = Stroke(const [
        Offset(80, 10), // section 1
        Offset(80, 80), // section 2
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [dStem],
        letter: 'd',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('connected d (one no-lift stroke, full path) → compoundStroke is 1.0',
        () {
      // A single continuous stroke through all six sections in order scores
      // identically to the lifted two-stroke form — lifts are judged separately.
      final dConnected = Stroke(const [
        Offset(80, 10), // section 1 (stem top)
        Offset(80, 80), // section 2 (stem bottom)
        Offset(80, 40), // section 3 (bowl mid-right)
        Offset(20, 40), // section 4 (bowl top-left)
        Offset(20, 80), // section 5 (bowl bottom-left)
        Offset(80, 80), // section 6 (bowl bottom-right)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [dConnected],
        letter: 'd',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 1.0);
    });

    // -------------------------------------------------------------------------
    // f — section-based scoring integration tests
    // -------------------------------------------------------------------------
    // f uses WaypointSectionScorer (sections on both strokes). See
    // docs/waypoint_section_definitions.md for the design.
    // Stem stroke (stroke 0): 3 sections — hook top-right, hook meets stem,
    //   stem body.
    // Crossbar stroke (stroke 1): 2 sections — left, right.
    // In a 90×90 grid:
    //   section 1 (hook top-right):  x[41.4, 90) y[0, 27)
    //   section 2 (hook meets stem): x[23.4, 41.4) y[0, 27)
    //   section 3 (stem body):       x[23.4, 41.4) y[27, 90)
    //   section 4 (crossbar left):   x[0, 23.4) y[27, 90)
    //   section 5 (crossbar right):  x[41.4, 90) y[27, 90)

    test('correct f (hooked stem + crossbar) → routes through '
        'WaypointSectionScorer and compoundStroke is 1.0', () {
      final fStem = Stroke(const [
        Offset(70, 10), // section 1 (hook top-right)
        Offset(30, 10), // section 2 (hook meets stem)
        Offset(30, 60), // section 3 (stem body)
      ]);
      final fCrossbar = Stroke(const [
        Offset(10, 50), // section 4 (crossbar left)
        Offset(70, 50), // section 5 (crossbar right)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [fStem, fCrossbar],
        letter: 'f',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 1.0);
    });

    test('f crossbar drawn right to left → compoundStroke is 0.0', () {
      // Stem is correct, but the crossbar hits section 5 before section 4,
      // so the letter path breaks after section 4 (found late) and never
      // reaches section 5.
      final fStem = Stroke(const [
        Offset(70, 10), // section 1
        Offset(30, 10), // section 2
        Offset(30, 60), // section 3
      ]);
      final fCrossbar = Stroke(const [
        Offset(70, 50), // section 5 (right) — out of order
        Offset(10, 50), // section 4 (left) — too late
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [fStem, fCrossbar],
        letter: 'f',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('f stem drawn without the hook → compoundStroke is 0.0', () {
      // A straight downward stem never enters section 1 (hook top-right),
      // which is the gatekeeper for the whole letter path. Even a correct
      // crossbar afterwards cannot recover the score.
      final fStraightStem = Stroke(const [
        Offset(30, 10), // stays in the stem column — never reaches section 1
        Offset(30, 60),
      ]);
      final fCrossbar = Stroke(const [
        Offset(10, 50), // section 4
        Offset(70, 50), // section 5
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [fStraightStem, fCrossbar],
        letter: 'f',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('f stem only (crossbar never drawn) → compoundStroke is 0.0', () {
      // Drawing only the stem completes sections 1–3 but not the crossbar
      // (4–5), so the letter path is incomplete → 0.0, not 100%.
      final fStem = Stroke(const [
        Offset(70, 10), // section 1
        Offset(30, 10), // section 2
        Offset(30, 60), // section 3
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [fStem],
        letter: 'f',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    // -------------------------------------------------------------------------
    // g — section-based scoring integration tests
    // -------------------------------------------------------------------------
    // g uses WaypointSectionScorer (sections on both strokes). See
    // docs/waypoint_section_definitions.md for the design.
    // Bowl stroke (stroke 0): 3 sections — top-right, top-left, bottom.
    // Descender stroke (stroke 1): 3 sections — stem top, stem bottom, hook.
    // In a 90×90 grid:
    //   section 1 (bowl top-right): x[70.2, 90) y[0, 36)
    //   section 2 (bowl top-left):  x[0, 70.2) y[0, 36)
    //   section 3 (bowl bottom):    x[0, 70.2) y[36, 58.5)
    //   section 4 (stem top):       x[70.2, 90) y[36, 58.5)
    //   section 5 (stem bottom):    x[70.2, 90) y[58.5, 90)
    //   section 6 (descender hook): x[0, 70.2) y[58.5, 90)

    test('correct g (bowl + descender) → routes through '
        'WaypointSectionScorer and compoundStroke is 1.0', () {
      final gBowl = Stroke(const [
        Offset(80, 10), // section 1 (bowl top-right)
        Offset(30, 10), // section 2 (bowl top-left)
        Offset(30, 45), // section 3 (bowl bottom)
      ]);
      final gDescender = Stroke(const [
        Offset(80, 45), // section 4 (stem top)
        Offset(80, 70), // section 5 (stem bottom)
        Offset(30, 70), // section 6 (hook)
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [gBowl, gDescender],
        letter: 'g',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 1.0);
    });

    test('g clockwise bowl (reversed) with correct descender → '
        'compoundStroke is 0.0', () {
      // Bowl drawn clockwise: top-right → bottom → top-left, instead of the
      // expected anticlockwise top-right → top-left → bottom. The path
      // breaks looking for section 3, which is never reached.
      final gClockwiseBowl = Stroke(const [
        Offset(80, 10), // section 1
        Offset(30, 45), // intended bottom — out of order
        Offset(30, 10), // section 2, found late
      ]);
      final gDescender = Stroke(const [
        Offset(80, 45), // section 4
        Offset(80, 70), // section 5
        Offset(30, 70), // section 6
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [gClockwiseBowl, gDescender],
        letter: 'g',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('g correct bowl with reversed descender stem → compoundStroke '
        'is 0.0', () {
      // Bowl is correct, but the descender draws stem-bottom before
      // stem-top, so the path breaks looking for section 5.
      final gBowl = Stroke(const [
        Offset(80, 10), // section 1
        Offset(30, 10), // section 2
        Offset(30, 45), // section 3
      ]);
      final gReversedDescender = Stroke(const [
        Offset(80, 70), // intended stem bottom — out of order
        Offset(80, 45), // section 4, found late
        Offset(30, 70), // never reaches section 5, so section 6 is unreachable
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [gBowl, gReversedDescender],
        letter: 'g',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('g bowl only (descender never drawn) → compoundStroke is 0.0', () {
      // Drawing only the bowl completes sections 1–3 but not the descender
      // (4–6), so the letter path is incomplete → 0.0, not 100%.
      final gBowl = Stroke(const [
        Offset(80, 10), // section 1
        Offset(30, 10), // section 2
        Offset(30, 45), // section 3
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [gBowl],
        letter: 'g',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });

    test('g correct bowl with straight stem and no hook → compoundStroke '
        'is 0.0', () {
      // The descender stays in the stem column the whole way down and never
      // hooks left into section 6, so the path is incomplete.
      final gBowl = Stroke(const [
        Offset(80, 10), // section 1
        Offset(30, 10), // section 2
        Offset(30, 45), // section 3
      ]);
      final gStraightStem = Stroke(const [
        Offset(80, 45), // section 4
        Offset(80, 80), // section 5 — stays at x=80, never hooks left
      ]);

      final result = ScoreIntegrator.score(
        referenceMask: ref90,
        bounds: bounds90,
        strokes: [gBowl, gStraightStem],
        letter: 'g',
      );

      expect(result.compoundStroke, isNotNull);
      expect(result.compoundStroke!.overallScore, 0.0);
    });
  });
}
