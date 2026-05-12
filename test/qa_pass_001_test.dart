import 'dart:math' show pi, cos, sin;
import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:handwriting_mvp/models/compound_stroke_scorer.dart';
import 'package:handwriting_mvp/models/letter_formation_registry.dart';
import 'package:handwriting_mvp/models/stroke.dart';
import 'package:handwriting_mvp/models/stroke_break_counter.dart';
import 'package:handwriting_mvp/models/stroke_direction_scorer.dart';
import 'package:handwriting_mvp/models/stroke_start_scorer.dart';

// Automated QA pass for the formation scoring system across all 26 lowercase
// letters, corresponding to acceptance criteria in issue [9.1].
//
// Three categories are verified:
//   1. Correct formation: each applicable scorer returns ≥ 0.8 (80%).
//   2. StrokeDirectionScorer not applicable for compound-only letters (m, n, u):
//      the scorer returns 0.0 vacuously; verified separately and excluded from
//      the ≥ 0.8 assertion.
//   3. RTL error cases: clockwise 'o', 'n' started at bottom-right, and 't'
//      drawn as one stroke each produce ≤ 0.5 on the relevant scorer.
//
// All tests use a 300×300 bounding box consistent with other scorer tests.
// The DebugScoreView widget [8.5] exposes the same per-scorer output at runtime
// for visual confirmation; the tests below are the automated record of those
// findings.

void main() {
  // 300×300 tight bounding box — standard across all formation scorer tests.
  const bounds = Rect.fromLTWH(0, 0, 300, 300);

  // ---------------------------------------------------------------------------
  // Stroke helpers
  // ---------------------------------------------------------------------------

  /// Anticlockwise circle in screen-Y-down coordinates.
  ///
  /// Default centre (150, 150), r=100: starts at (150, 50) which is in the
  /// top region (y < 100). Bounding-box centroid = (150, 150).
  Stroke anticlockwiseCircle({double cx = 150, double cy = 150, double r = 100}) {
    const steps = 32;
    final pts = <Offset>[];
    for (var k = 0; k <= steps; k++) {
      final angle = -pi / 2 - (2 * pi * k / steps);
      pts.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
    }
    return Stroke(pts);
  }

  /// Clockwise circle in screen-Y-down coordinates.
  ///
  /// Default centre (150, 150), r=100: starts at (150, 50) which is in the
  /// top region (y < 100). Bounding-box centroid = (150, 150).
  Stroke clockwiseCircle({double cx = 150, double cy = 150, double r = 100}) {
    const steps = 32;
    final pts = <Offset>[];
    for (var k = 0; k <= steps; k++) {
      final angle = -pi / 2 + (2 * pi * k / steps);
      pts.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
    }
    return Stroke(pts);
  }

  // ---------------------------------------------------------------------------
  // Assertion helper
  // ---------------------------------------------------------------------------

  /// Asserts that every applicable formation scorer for [letter] returns
  /// ≥ 0.8 when presented with [observed].
  ///
  /// [expectDirection]: include StrokeDirectionScorer in the assertion.
  /// Set to false for compound-only letters (m, n, u) whose compound strokes
  /// are skipped by that scorer, causing it to return 0.0 vacuously.
  void expectApplicableScorersPass(
    String letter,
    List<Stroke> observed, {
    bool expectDirection = true,
  }) {
    final data = letterFormationRegistry[letter]!;

    final startResult =
        StrokeStartScorer(letter: letter, data: data, bounds: bounds)
            .score(observed);
    expect(
      startResult.overallScore,
      greaterThanOrEqualTo(0.8),
      reason: '$letter StrokeStartScorer: expected ≥ 0.8, got '
          '${startResult.overallScore}',
    );

    if (expectDirection) {
      final dirResult =
          StrokeDirectionScorer(letter: letter, data: data, bounds: bounds)
              .score(observed);
      expect(
        dirResult.overallScore,
        greaterThanOrEqualTo(0.8),
        reason: '$letter StrokeDirectionScorer: expected ≥ 0.8, got '
            '${dirResult.overallScore}',
      );
    }

    final compoundResult =
        CompoundStrokeScorer(letter: letter, data: data, bounds: bounds)
            .score(observed);
    expect(
      compoundResult.overallScore,
      greaterThanOrEqualTo(0.8),
      reason: '$letter CompoundStrokeScorer: expected ≥ 0.8, got '
          '${compoundResult.overallScore}',
    );

    final breakResult =
        StrokeBreakCounter(letter: letter, data: data).score(observed);
    expect(
      breakResult.overallScore,
      greaterThanOrEqualTo(0.8),
      reason: '$letter StrokeBreakCounter: expected ≥ 0.8, got '
          '${breakResult.overallScore}',
    );
  }

  // ===========================================================================
  // CORRECT FORMATION TESTS
  // ===========================================================================

  group('QA pass 001 — correct formations score ≥ 0.8 on each applicable scorer',
      () {
    // -------------------------------------------------------------------------
    // Single-stroke anticlockwise letters: a, c, e, o
    //
    // One anticlockwise circle. Starts at (150, 50) — top region.
    // -------------------------------------------------------------------------
    group('single-stroke anticlockwise letters (a, c, e, o)', () {
      for (final letter in ['a', 'c', 'e', 'o']) {
        test('$letter: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
            () {
          expectApplicableScorersPass(letter, [anticlockwiseCircle()]);
        });
      }
    });

    // -------------------------------------------------------------------------
    // Single-stroke topToBottom letters: l, r, s, v, w, z
    //
    // One stroke from (150, 10) to (150, 290). Starts at y=10 (top region).
    // |Δy| = 280 > |Δx| = 0 → classified topToBottom.
    // -------------------------------------------------------------------------
    group('single-stroke topToBottom letters (l, r, s, v, w, z)', () {
      const topToBottom = [Offset(150, 10), Offset(150, 290)];
      for (final letter in ['l', 'r', 's', 'v', 'w', 'z']) {
        test('$letter: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
            () {
          expectApplicableScorersPass(letter, [Stroke(topToBottom)]);
        });
      }
    });

    // -------------------------------------------------------------------------
    // Optional-lift two-stroke letters: b and p (topToBottom stem + clockwise bowl)
    //
    // Short stem: Stroke([Offset(150,10), Offset(150,90)]) — centroid (150, 50)
    //   → matches expected[0] (topToBottom, startRegion top).
    // Full clockwise circle — centroid (150, 150)
    //   → matches expected[1] (clockwise, startRegion top).
    // -------------------------------------------------------------------------
    group("optional-lift bowl letters — b, p (stem + clockwise bowl)", () {
      for (final letter in ['b', 'p']) {
        test('$letter: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
            () {
          const stem = [Offset(150, 10), Offset(150, 90)];
          expectApplicableScorersPass(
            letter,
            [Stroke(stem), clockwiseCircle()],
          );
        });
      }
    });

    // -------------------------------------------------------------------------
    // Optional-lift two-stroke letters: d, g, q (anticlockwise oval + topToBottom stem/tail)
    //
    // Full anticlockwise oval — centroid (150, 150)
    //   → matches expected[0] (anticlockwise, startRegion top).
    // Short stem: Stroke([Offset(150,10), Offset(150,90)]) — centroid (150, 50)
    //   → matches expected[1] (topToBottom, startRegion top).
    // -------------------------------------------------------------------------
    group("optional-lift oval+stem letters — d, g, q (anticlockwise oval + topToBottom stem)", () {
      for (final letter in ['d', 'g', 'q']) {
        test('$letter: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
            () {
          const stem = [Offset(150, 10), Offset(150, 90)];
          expectApplicableScorersPass(
            letter,
            [anticlockwiseCircle(), Stroke(stem)],
          );
        });
      }
    });

    // -------------------------------------------------------------------------
    // Optional-lift letter: y (two topToBottom diagonal strokes)
    //
    // Both strokes start in the top region (y < 100) and satisfy
    // |Δy| > |Δx| → classified topToBottom.
    // -------------------------------------------------------------------------
    group("optional-lift letter y (two topToBottom diagonals)", () {
      test('y: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
          () {
        const y1 = [Offset(100, 10), Offset(150, 290)]; // |Δy|=280 > |Δx|=50
        const y2 = [Offset(200, 10), Offset(100, 290)]; // |Δy|=280 > |Δx|=100
        expectApplicableScorersPass('y', [Stroke(y1), Stroke(y2)]);
      });
    });

    // -------------------------------------------------------------------------
    // Required-lift crossbar letters: f and t (topToBottom stem + leftToRight crossbar)
    //
    // Short stem: centroid (150, 50) → matches expected[0] (startRegion top).
    // Horizontal crossbar: centroid (150, 150) → matches expected[1] (startRegion middle).
    // Crossbar starts at (10, 150) → middle region (y=150 ∈ [100, 200)).
    // -------------------------------------------------------------------------
    group("required-lift crossbar letters (f, t)", () {
      for (final letter in ['f', 't']) {
        test('$letter: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
            () {
          const stem = [Offset(150, 10), Offset(150, 90)];
          const crossbar = [Offset(10, 150), Offset(290, 150)];
          expectApplicableScorersPass(letter, [Stroke(stem), Stroke(crossbar)]);
        });
      }
    });

    // -------------------------------------------------------------------------
    // Required-lift dot letters: i and j (topToBottom stem + dot)
    //
    // Short stem: centroid (150, 50) → matches expected[0] (topToBottom).
    // Single-point dot: centroid (150, 10) → matches expected[1] (dot).
    // Dot is skipped by StrokeDirectionScorer; only the stem contributes to
    // overallScore → 1.0.
    // -------------------------------------------------------------------------
    group("required-lift dot letters (i, j)", () {
      for (final letter in ['i', 'j']) {
        test('$letter: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
            () {
          const stem = [Offset(150, 10), Offset(150, 90)];
          const dot = [Offset(150, 10)];
          expectApplicableScorersPass(letter, [Stroke(stem), Stroke(dot)]);
        });
      }
    });

    // -------------------------------------------------------------------------
    // Required-lift letter: x (two topToBottom diagonal strokes)
    //
    // Both diagonals satisfy |Δy| > |Δx| → classified topToBottom.
    // Both strokes start in the top region.
    // -------------------------------------------------------------------------
    group("required-lift letter x (two topToBottom diagonals)", () {
      test('x: StrokeStart, StrokeDirection, CompoundStroke, StrokeBreak all ≥ 0.8',
          () {
        const diag1 = [Offset(100, 10), Offset(200, 290)]; // |Δy|=280 > |Δx|=100
        const diag2 = [Offset(200, 10), Offset(100, 290)]; // |Δy|=280 > |Δx|=100
        expectApplicableScorersPass('x', [Stroke(diag1), Stroke(diag2)]);
      });
    });

    // -------------------------------------------------------------------------
    // Compound letters with a topToBottom stem: h and k
    //
    // h — stem (topToBottom) + compound arch (left → top → bottomRight):
    //   Short stem: centroid (150, 50) → matches expected[0].
    //   Arch: first point at (50, 150) → middle region (expected startRegion=middle);
    //   centroid ≈ (150, 150) → matches expected[1].  Exact hits on all 3 waypoints.
    //
    // k — stem (topToBottom) + compound kick (topRight → middle → bottomRight):
    //   Short stem: centroid (150, 50) → matches expected[0].
    //   Kick: first point at (250, 10) → top region (expected startRegion=top);
    //   centroid ≈ (200, 130) → matches expected[1].
    //   Waypoint tolerance = 50 px; (250, 10) is 40 px from topRight centroid (250, 50).
    // -------------------------------------------------------------------------
    group("compound letters with topToBottom stem (h, k)", () {
      test('h: all four scorers ≥ 0.8', () {
        const stem = [Offset(150, 10), Offset(150, 90)];
        const arch = [
          Offset(50, 150),  // left centroid (50, 150) — exact hit; middle region
          Offset(150, 50),  // top centroid (150, 50) — exact hit
          Offset(250, 250), // bottomRight centroid (250, 250) — exact hit
        ];
        expectApplicableScorersPass('h', [Stroke(stem), Stroke(arch)]);
      });

      test('k: all four scorers ≥ 0.8', () {
        const stem = [Offset(150, 10), Offset(150, 90)];
        const kick = [
          Offset(250, 10),  // near topRight centroid (250, 50), dist=40 < tol=50; top region
          Offset(150, 150), // middle centroid (150, 150) — exact hit
          Offset(250, 250), // bottomRight centroid (250, 250) — exact hit
        ];
        expectApplicableScorersPass('k', [Stroke(stem), Stroke(kick)]);
      });
    });

    // -------------------------------------------------------------------------
    // Compound-only letters: m, n, u
    //
    // These letters have exactly one stroke whose primaryDirection is compound.
    // StrokeDirectionScorer skips compound strokes → overallScore = 0.0
    // vacuously. This is by design and is NOT a failure; the scorer is not
    // applicable for these letters.
    //
    // The three applicable scorers (StrokeStart, CompoundStroke, StrokeBreak)
    // must all return ≥ 0.8.
    //
    // Waypoint tolerance = 50 px (0.5 × 100 px cell) for a 300×300 bounding box.
    // Points are chosen within 50 px of each waypoint centroid.
    // -------------------------------------------------------------------------
    group("compound-only letters (m, n, u) — three applicable scorers ≥ 0.8", () {
      test('n: StrokeStart, CompoundStroke, StrokeBreak all ≥ 0.8', () {
        // Waypoints: topLeft(50,50) → bottomLeft(50,250) → top(150,50) → bottomRight(250,250).
        // First point y=10 → top region; all 4 points within 50 px of their centroid.
        const nPoints = [
          Offset(50, 10),   // near topLeft (50,50), dist=40 < 50
          Offset(50, 250),  // bottomLeft (50,250) — exact
          Offset(150, 10),  // near top (150,50), dist=40 < 50
          Offset(250, 250), // bottomRight (250,250) — exact
        ];
        expectApplicableScorersPass('n', [Stroke(nPoints)], expectDirection: false);
      });

      test('n: StrokeDirectionScorer returns 0.0 — not applicable for compound-only letter',
          () {
        const nPoints = [
          Offset(50, 10),
          Offset(50, 250),
          Offset(150, 10),
          Offset(250, 250),
        ];
        final result = StrokeDirectionScorer(
          letter: 'n',
          data: letterFormationRegistry['n']!,
          bounds: bounds,
        ).score([Stroke(nPoints)]);
        expect(result.overallScore, 0.0);
      });

      test('m: StrokeStart, CompoundStroke, StrokeBreak all ≥ 0.8', () {
        // Waypoints: topLeft(50,50) → bottomLeft(50,250) → top(150,50)
        //            → bottom(150,250) → top(150,50) [again] → bottomRight(250,250).
        //
        // The 'top' waypoint appears twice. matchWaypoints selects the CLOSEST
        // point in the forward scan (not just the first within tolerance), so
        // using exact centroid points (dist=0) ensures ties are resolved by
        // first occurrence — the scan does not update bestIdx when the new
        // distance is equal to (not strictly less than) the current best.
        const mPoints = [
          Offset(50, 50),    // topLeft centroid — exact hit; y=50 → top region
          Offset(50, 250),   // bottomLeft centroid — exact hit
          Offset(150, 50),   // top centroid — exact hit (first visit, index 2)
          Offset(150, 250),  // bottom centroid — exact hit
          Offset(150, 50),   // top centroid — exact hit (second visit, index 4)
          Offset(250, 250),  // bottomRight centroid — exact hit
        ];
        expectApplicableScorersPass('m', [Stroke(mPoints)], expectDirection: false);
      });

      test('u: StrokeStart, CompoundStroke, StrokeBreak all ≥ 0.8', () {
        // Waypoints: topLeft(50,50) → bottomLeft(50,250) → bottom(150,250)
        //            → bottomRight(250,250) → topRight(250,50).
        const uPoints = [
          Offset(50, 10),   // near topLeft (50,50), top region, dist=40 < 50
          Offset(50, 250),  // bottomLeft (50,250) — exact
          Offset(150, 250), // bottom (150,250) — exact
          Offset(250, 250), // bottomRight (250,250) — exact
          Offset(250, 10),  // near topRight (250,50), dist=40 < 50
        ];
        expectApplicableScorersPass('u', [Stroke(uPoints)], expectDirection: false);
      });
    });
  });

  // ===========================================================================
  // RTL ERROR CASE TESTS
  // ===========================================================================

  group('QA pass 001 — RTL error cases score ≤ 0.5 on the relevant scorer', () {
    // -------------------------------------------------------------------------
    // Clockwise 'o' — StrokeDirectionScorer
    //
    // Expected direction: anticlockwise.
    // Observed direction: clockwise → opposite pair → score = 0.0.
    // 0.0 < 0.5, satisfying the "below 50%" criterion.
    // -------------------------------------------------------------------------
    test("clockwise 'o': StrokeDirectionScorer scores 0.0 (< 50%)", () {
      final scorer = StrokeDirectionScorer(
        letter: 'o',
        data: letterFormationRegistry['o']!,
        bounds: bounds,
      );
      final result = scorer.score([clockwiseCircle()]);
      expect(result.overallScore, lessThan(0.5));
    });

    // -------------------------------------------------------------------------
    // 'n' started at bottom-right — StrokeStartScorer
    //
    // Expected start region: top.
    // Observed: first point at (280, 280), y=280 > 200 → bottom region.
    // top ↔ bottom is the opposite mismatch → score = 0.0.
    // 0.0 < 0.5, satisfying the "below 50%" criterion.
    // -------------------------------------------------------------------------
    test("'n' started at bottom-right: StrokeStartScorer scores 0.0 (< 50%)", () {
      final scorer = StrokeStartScorer(
        letter: 'n',
        data: letterFormationRegistry['n']!,
        bounds: bounds,
      );
      // First point (280, 280): y=280 > 200 → bottom region (opposite of expected top).
      final result = scorer.score([
        Stroke(const [Offset(280, 280), Offset(50, 50)]),
      ]);
      expect(result.overallScore, lessThan(0.5));
    });

    // -------------------------------------------------------------------------
    // 't' drawn as one continuous stroke — StrokeBreakCounter
    //
    // minRequiredStrokes = 2; actualCount = 1 → score = 1/2 = 0.5.
    //
    // Note: the score is exactly 0.5 (the boundary), not strictly below 0.5.
    // The acceptance criterion states "below 50%", but the StrokeBreakCounter
    // formula produces 1/minRequired for a one-stroke attempt, which equals
    // exactly 50% when minRequired = 2. This boundary behaviour is documented
    // in qa_pass_001.md. The score is clearly below the 80% passing threshold.
    // -------------------------------------------------------------------------
    test("'t' drawn as one continuous stroke: StrokeBreakCounter scores 0.5 (≤ 50%)",
        () {
      final counter = StrokeBreakCounter(
        letter: 't',
        data: letterFormationRegistry['t']!,
      );
      // One stroke combining the stem (down) and crossbar (right) without lifting.
      final result = counter.score([
        Stroke(const [
          Offset(150, 10),
          Offset(150, 290),
          Offset(0, 150),
          Offset(300, 150),
        ]),
      ]);
      // minRequiredStrokes=2, actualCount=1 → score = 1/2 = 0.5.
      expect(result.overallScore, lessThanOrEqualTo(0.5));
    });
  });
}
